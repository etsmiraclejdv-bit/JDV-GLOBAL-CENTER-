-- Achats fournisseurs : fonctions ATOMIQUES (tout est enregistré, ou rien).
-- Chacune vérifie que l'appelant est administrateur de l'entreprise (ou concepteur), puis s'appuie sur
-- les contrôles existants (jdvcrm_process_goods_receipt_v1 / jdvcrm_process_supplier_payment_v1) : si l'un
-- d'eux refuse, toute la transaction est annulée et aucune réception ni aucun paiement « fantôme » ne subsiste.

-- 1) Créer une commande fournisseur avec ses lignes
create or replace function public.jdvcrm_create_purchase_order_v1(
  p_supplier_id uuid,
  p_expected_date date,
  p_notes text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_status text;
  v_item jsonb;
  v_article uuid;
  v_qty numeric;
  v_cost numeric;
  v_total numeric := 0;
  v_po uuid;
  v_prefix text;
  v_seq integer;
  v_number text;
  v_lines integer := 0;
  v_seen uuid[] := '{}';
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select organization_id, status into v_org, v_status from public.suppliers where id = p_supplier_id;
  if v_org is null then raise exception 'Fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_org)) then raise exception 'Accès refusé'; end if;
  if v_status <> 'active' then raise exception 'Ce fournisseur n''est pas actif'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La commande doit contenir au moins une ligne';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'Trop de lignes (200 maximum)'; end if;
  if p_expected_date is not null and p_expected_date < current_date then
    raise exception 'La date de livraison prévue est dans le passé';
  end if;

  -- Contrôle des lignes et calcul du total
  for v_item in select value from jsonb_array_elements(p_items) loop
    begin
      v_article := (v_item ->> 'article_id')::uuid;
      v_qty := (v_item ->> 'quantity')::numeric;
      v_cost := coalesce((v_item ->> 'unit_cost')::numeric, 0);
    exception when others then
      raise exception 'Ligne de commande invalide';
    end;
    if v_article is null or v_qty is null or v_qty <= 0 or v_cost < 0 then raise exception 'Ligne de commande invalide'; end if;
    if v_qty > 1000000000 or v_cost > 100000000000 then raise exception 'Valeur trop élevée dans une ligne de commande'; end if;
    if v_article = any (v_seen) then raise exception 'Un article apparaît deux fois dans la commande'; end if;
    v_seen := v_seen || v_article;
    if not exists (select 1 from public.articles where id = v_article and organization_id = v_org) then
      raise exception 'Article introuvable dans cette entreprise';
    end if;
    v_total := v_total + round(v_qty * v_cost, 2);
  end loop;

  -- Numérotation CF-AAAAMMJJ-001, protégée contre deux créations simultanées
  perform pg_advisory_xact_lock(hashtext('jdvcrm_po:' || v_org::text));
  v_prefix := 'CF-' || to_char(current_date, 'YYYYMMDD') || '-';
  select coalesce(max((substring(order_number from '(\d+)$'))::integer), 0) + 1
    into v_seq
    from public.purchase_orders
   where organization_id = v_org and order_number like v_prefix || '%';
  v_number := v_prefix || lpad(v_seq::text, 3, '0');

  insert into public.purchase_orders
    (organization_id, supplier_id, order_number, order_date, expected_date,
     subtotal, discount_amount, tax_amount, total_amount, status, notes, created_by)
  values
    (v_org, p_supplier_id, v_number, current_date, p_expected_date,
     v_total, 0, 0, v_total, 'confirmed', nullif(left(trim(coalesce(p_notes, '')), 1000), ''), auth.uid())
  returning id into v_po;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::numeric;
    v_cost := coalesce((v_item ->> 'unit_cost')::numeric, 0);
    insert into public.purchase_order_items
      (organization_id, purchase_order_id, article_id, quantity, unit_cost, discount_amount, tax_amount, total_amount)
    values
      (v_org, v_po, (v_item ->> 'article_id')::uuid, v_qty, v_cost, 0, 0, round(v_qty * v_cost, 2));
    v_lines := v_lines + 1;
  end loop;

  return jsonb_build_object('success', true, 'purchase_order_id', v_po, 'order_number', v_number,
                            'total_amount', v_total, 'lines', v_lines);
end;
$$;

-- 2) Réceptionner (totalement ou partiellement) une commande : entrée en stock
create or replace function public.jdvcrm_receive_purchase_order_v1(
  p_purchase_order_id uuid,
  p_items jsonb,
  p_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_item jsonb;
  v_article uuid;
  v_qty numeric;
  v_cost numeric;
  v_receipt uuid;
  v_prefix text;
  v_seq integer;
  v_number text;
  v_res jsonb;
  v_new_status text;
  v_seen uuid[] := '{}';
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status not in ('draft', 'sent', 'confirmed', 'partial') then
    raise exception 'Cette commande ne peut plus être réceptionnée (statut : %)', po.status;
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Indiquez au moins une quantité reçue';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'Trop de lignes (200 maximum)'; end if;

  perform pg_advisory_xact_lock(hashtext('jdvcrm_br:' || po.organization_id::text));
  v_prefix := 'BR-' || to_char(current_date, 'YYYYMMDD') || '-';
  select coalesce(max((substring(receipt_number from '(\d+)$'))::integer), 0) + 1
    into v_seq
    from public.goods_receipts
   where organization_id = po.organization_id and receipt_number like v_prefix || '%';
  v_number := v_prefix || lpad(v_seq::text, 3, '0');

  insert into public.goods_receipts
    (organization_id, purchase_order_id, receipt_number, receipt_date, status, notes, received_by)
  values
    (po.organization_id, po.id, v_number, current_date, 'received',
     nullif(left(trim(coalesce(p_notes, '')), 1000), ''), auth.uid())
  returning id into v_receipt;

  for v_item in select value from jsonb_array_elements(p_items) loop
    begin
      v_article := (v_item ->> 'article_id')::uuid;
      v_qty := (v_item ->> 'quantity_received')::numeric;
    exception when others then
      raise exception 'Ligne de réception invalide';
    end;
    if v_article is null or v_qty is null or v_qty <= 0 then raise exception 'Quantité reçue invalide'; end if;
    if v_qty > 1000000000 then raise exception 'Quantité reçue trop élevée'; end if;
    -- un même article deux fois contournerait le contrôle de quantité commandée
    if v_article = any (v_seen) then raise exception 'Un article apparaît deux fois dans la réception'; end if;
    v_seen := v_seen || v_article;
    select unit_cost into v_cost
      from public.purchase_order_items
     where purchase_order_id = po.id and article_id = v_article
     order by created_at limit 1;
    if not found then raise exception 'Article absent de la commande fournisseur'; end if;
    insert into public.goods_receipt_items (organization_id, receipt_id, article_id, quantity_received, unit_cost)
    values (po.organization_id, v_receipt, v_article, v_qty, v_cost);
  end loop;

  -- Contrôle des quantités et entrée en stock (lève une erreur, donc annule tout, si la réception dépasse la commande)
  v_res := public.jdvcrm_process_goods_receipt_v1(v_receipt);
  select status into v_new_status from public.purchase_orders where id = po.id;

  return jsonb_build_object('success', true, 'receipt_id', v_receipt, 'receipt_number', v_number,
                            'order_status', v_new_status, 'quantity_added', v_res -> 'quantity_added');
end;
$$;

-- 3) Enregistrer un paiement fournisseur sur une commande
create or replace function public.jdvcrm_pay_purchase_order_v1(
  p_purchase_order_id uuid,
  p_amount numeric,
  p_method text,
  p_reference text,
  p_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_payment uuid;
  v_res jsonb;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status = 'cancelled' then raise exception 'Cette commande est annulée'; end if;
  if p_amount is null or p_amount <= 0 or p_amount > 100000000000 then raise exception 'Montant du paiement invalide'; end if;
  if p_method is null or p_method not in ('cash', 'mobile_money', 'bank_transfer', 'cheque', 'other') then
    raise exception 'Mode de paiement invalide';
  end if;

  insert into public.supplier_payments
    (organization_id, supplier_id, purchase_order_id, amount, currency, payment_method,
     provider_reference, status, recorded_by, notes)
  values
    (po.organization_id, po.supplier_id, po.id, round(p_amount, 2), 'XOF', p_method,
     nullif(left(trim(coalesce(p_reference, '')), 120), ''), 'paid', auth.uid(),
     nullif(left(trim(coalesce(p_notes, '')), 1000), ''))
  returning id into v_payment;

  -- Lève une erreur (et annule tout) si le total payé dépasse le montant de la commande
  v_res := public.jdvcrm_process_supplier_payment_v1(v_payment);

  return jsonb_build_object('success', true, 'payment_id', v_payment,
                            'paid_total', v_res -> 'paid_total', 'remaining', v_res -> 'remaining');
end;
$$;

-- 4) Annuler une commande (impossible si des marchandises ont été reçues ou des paiements enregistrés)
create or replace function public.jdvcrm_cancel_purchase_order_v1(p_purchase_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status = 'cancelled' then raise exception 'Cette commande est déjà annulée'; end if;
  if exists (select 1 from public.goods_receipts where purchase_order_id = po.id and status = 'received') then
    raise exception 'Impossible d''annuler : des marchandises ont déjà été reçues';
  end if;
  if exists (select 1 from public.supplier_payments where purchase_order_id = po.id and status = 'paid') then
    raise exception 'Impossible d''annuler : des paiements ont déjà été enregistrés';
  end if;
  update public.purchase_orders set status = 'cancelled' where id = po.id;
  return jsonb_build_object('success', true, 'status', 'cancelled');
end;
$$;

revoke all on function public.jdvcrm_create_purchase_order_v1(uuid, date, text, jsonb) from public, anon;
revoke all on function public.jdvcrm_receive_purchase_order_v1(uuid, jsonb, text) from public, anon;
revoke all on function public.jdvcrm_pay_purchase_order_v1(uuid, numeric, text, text, text) from public, anon;
revoke all on function public.jdvcrm_cancel_purchase_order_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_create_purchase_order_v1(uuid, date, text, jsonb) to authenticated;
grant execute on function public.jdvcrm_receive_purchase_order_v1(uuid, jsonb, text) to authenticated;
grant execute on function public.jdvcrm_pay_purchase_order_v1(uuid, numeric, text, text, text) to authenticated;
grant execute on function public.jdvcrm_cancel_purchase_order_v1(uuid) to authenticated;

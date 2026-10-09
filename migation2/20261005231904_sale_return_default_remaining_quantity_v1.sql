-- Sans liste d'articles, le retour porte sur la quantité encore retournable (vendue - déjà retournée).
create or replace function public.jdvcrm_create_sale_return_v1(
  p_sale_id uuid,
  p_items jsonb default null,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_sale public.sales%rowtype;
  v_return_id uuid;
  v_number text;
  v_items jsonb;
  v_item record;
  v_unit numeric;
  v_line numeric;
  v_refund numeric := 0;
  v_updated integer;
  v_already numeric;
  v_left numeric;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into v_sale from public.sales where id = p_sale_id;
  if not found then raise exception 'Vente introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_sale.organization_id)) then
    raise exception 'Accès refusé : administrateur requis';
  end if;
  if not private.is_super_admin() and not private.has_active_subscription(v_sale.organization_id) then
    raise exception 'Abonnement requis';
  end if;
  if v_sale.status = 'cancelled' then raise exception 'Vente annulée : retour impossible'; end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    select coalesce(sum(i.quantity), 0) into v_already
    from public.sales_return_items i
    join public.sales_returns sr on sr.id = i.return_id
    where sr.sale_id = v_sale.id and sr.status in ('approved', 'processed') and i.article_id = v_sale.article_id;
    v_left := coalesce(v_sale.quantity, 0) - v_already;
    if v_left <= 0 then raise exception 'Cette vente est déjà entièrement retournée'; end if;
    v_items := jsonb_build_array(jsonb_build_object('quantity', v_left));
  else
    v_items := p_items;
  end if;

  v_unit := case when v_sale.sale_type = 'cash' then v_sale.cash_price else v_sale.credit_price end;
  v_number := 'RET-' || to_char(now() at time zone 'utc', 'YYMMDD') || '-'
              || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

  insert into public.sales_returns(organization_id, sale_id, client_id, return_number, reason, refund_amount, status, created_by)
  values (v_sale.organization_id, v_sale.id, v_sale.client_id, v_number, p_reason, 0, 'pending', v_uid)
  returning id into v_return_id;

  for v_item in
    select x.article_id, x.quantity, x.serial_number_id, x.refund_amount
    from jsonb_to_recordset(v_items) as x(article_id uuid, quantity numeric, serial_number_id uuid, refund_amount numeric)
  loop
    if v_item.quantity is null or v_item.quantity <= 0 or v_item.quantity <> trunc(v_item.quantity) then
      raise exception 'Quantité de retour invalide';
    end if;
    v_line := coalesce(v_item.refund_amount, v_unit * v_item.quantity);
    insert into public.sales_return_items(organization_id, return_id, article_id, quantity, refund_amount, serial_number_id)
    values (v_sale.organization_id, v_return_id, coalesce(v_item.article_id, v_sale.article_id),
            v_item.quantity, v_line, v_item.serial_number_id);
    v_refund := v_refund + v_line;
  end loop;

  update public.sales_returns set refund_amount = v_refund, status = 'approved' where id = v_return_id;
  perform public.jdvcrm_process_sale_return(v_return_id);

  select count(*) into v_updated from public.commissions
  where sale_id = v_sale.id and calculation_snapshot ->> 'last_return_id' = v_return_id::text;

  return jsonb_build_object('return_id', v_return_id, 'return_number', v_number, 'status', 'processed',
                            'refund_amount', v_refund, 'commissions_updated', v_updated);
end;
$function$;
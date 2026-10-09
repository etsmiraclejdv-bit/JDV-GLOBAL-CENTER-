create or replace function public.jdvcrm_process_goods_receipt_v1(p_receipt_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare r goods_receipts%rowtype; i record; s stocks%rowtype; po purchase_orders%rowtype; v_count integer:=0; v_total_received numeric:=0; v_order_qty numeric; v_received_before numeric; v_new_status text;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into r from goods_receipts where id=p_receipt_id for update;
 if not found then raise exception 'Réception introuvable'; end if;
 if not (private.is_super_admin() or private.is_org_admin(r.organization_id)) then raise exception 'Accès refusé'; end if;
 if r.status<>'received' then raise exception 'La réception doit être au statut received'; end if;
 select * into po from purchase_orders where id=r.purchase_order_id for update;
 if not found or po.organization_id<>r.organization_id then raise exception 'Commande fournisseur incompatible'; end if;
 for i in select * from goods_receipt_items where receipt_id=r.id order by id loop
   select coalesce(sum(quantity_received),0) into v_received_before
   from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id
   where gr.purchase_order_id=r.purchase_order_id and gr.organization_id=r.organization_id and gri.article_id=i.article_id and gr.id<>r.id and gr.status='received';
   select coalesce(sum(quantity),0) into v_order_qty from purchase_order_items where purchase_order_id=r.purchase_order_id and organization_id=r.organization_id and article_id=i.article_id;
   if v_order_qty=0 then raise exception 'Article % absent de la commande fournisseur',i.article_id; end if;
   if v_received_before+i.quantity_received>v_order_qty then raise exception 'Réception supérieure à la quantité commandée pour l''article %',i.article_id; end if;
   if exists(select 1 from stock_movements where organization_id=r.organization_id and reference_type='goods_receipt' and reference_id=r.id and article_id=i.article_id) then continue; end if;
   select * into s from stocks where organization_id=r.organization_id and article_id=i.article_id for update;
   if found then update stocks set quantity=quantity+i.quantity_received,updated_at=now() where id=s.id;
   else insert into stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at) values(r.organization_id,i.article_id,i.quantity_received,0,0,now()); end if;
   insert into stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   values(r.organization_id,i.article_id,'entry',i.quantity_received,'goods_receipt',r.id,'supplier','stock_principal','Entrée liée à la réception '||r.receipt_number,coalesce(r.received_by,auth.uid()),now());
   v_count:=v_count+1; v_total_received:=v_total_received+i.quantity_received;
 end loop;
 update purchase_orders po2 set status=case when not exists(select 1 from purchase_order_items poi where poi.purchase_order_id=po2.id and poi.organization_id=po2.organization_id and poi.quantity>(select coalesce(sum(gri.quantity_received),0) from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id where gr.purchase_order_id=po2.id and gr.organization_id=po2.organization_id and gr.status='received' and gri.article_id=poi.article_id)) then 'received' when exists(select 1 from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id where gr.purchase_order_id=po2.id and gr.organization_id=po2.organization_id and gr.status='received') then 'partial' else po2.status end,updated_at=now() where po2.id=r.purchase_order_id;
 return jsonb_build_object('success',true,'receipt_id',r.id,'processed_items',v_count,'quantity_added',v_total_received);
end $$;

create or replace function public.jdvcrm_validate_supplier_payment_v2()
returns trigger language plpgsql security definer set search_path=public
as $$
declare po_org uuid; sup_org uuid;
begin
 if new.amount<=0 then raise exception 'Montant du paiement fournisseur invalide'; end if;
 select organization_id,supplier_id into po_org,sup_org from purchase_orders where id=new.purchase_order_id;
 if po_org is null or po_org<>new.organization_id then raise exception 'Commande fournisseur incompatible avec l''organisation'; end if;
 if sup_org<>new.supplier_id then raise exception 'Fournisseur incompatible avec la commande'; end if;
 if not exists(select 1 from suppliers where id=new.supplier_id and organization_id=new.organization_id) then raise exception 'Fournisseur incompatible avec l''organisation'; end if;
 return new;
end $$;
drop trigger if exists trg_jdvcrm_validate_supplier_payment_v1 on public.supplier_payments;
create trigger trg_jdvcrm_validate_supplier_payment_v2 before insert or update on public.supplier_payments for each row execute function public.jdvcrm_validate_supplier_payment_v2();

create or replace function public.jdvcrm_process_supplier_payment_v1(p_payment_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare p supplier_payments%rowtype; po purchase_orders%rowtype; v_paid numeric; v_total numeric;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into p from supplier_payments where id=p_payment_id for update;
 if not found then raise exception 'Paiement fournisseur introuvable'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p.organization_id)) then raise exception 'Accès refusé'; end if;
 if p.status<>'paid' then raise exception 'Le paiement doit être au statut paid'; end if;
 select * into po from purchase_orders where id=p.purchase_order_id for update;
 if not found or po.organization_id<>p.organization_id or po.supplier_id<>p.supplier_id then raise exception 'Commande fournisseur incompatible'; end if;
 select coalesce(sum(amount),0) into v_paid from supplier_payments where purchase_order_id=p.purchase_order_id and organization_id=p.organization_id and status='paid' and id<>p.id;
 v_total:=coalesce(po.total_amount,0);
 if v_paid+p.amount>v_total then raise exception 'Le total des paiements dépasse le montant de la commande'; end if;
 return jsonb_build_object('success',true,'payment_id',p.id,'paid_total',v_paid+p.amount,'order_total',v_total,'remaining',greatest(v_total-(v_paid+p.amount),0));
end $$;

create or replace function public.jdvcrm_validate_goods_receipt_item_v1()
returns trigger language plpgsql security definer set search_path=public
as $$
declare v_org uuid; v_article_org uuid; v_status text;
begin
 select organization_id,status into v_org,v_status from goods_receipts where id=new.receipt_id;
 select organization_id into v_article_org from articles where id=new.article_id;
 if v_org is null or v_org<>new.organization_id then raise exception 'Ligne de réception incompatible avec la réception'; end if;
 if v_article_org is not null and v_article_org<>new.organization_id then raise exception 'Article incompatible avec la réception'; end if;
 if new.quantity_received<=0 then raise exception 'Quantité reçue invalide'; end if;
 if v_status='cancelled' then raise exception 'Impossible d''ajouter une ligne à une réception annulée'; end if;
 return new;
end $$;
drop trigger if exists trg_jdvcrm_validate_goods_receipt_item_v1 on public.goods_receipt_items;
create trigger trg_jdvcrm_validate_goods_receipt_item_v2 before insert or update on public.goods_receipt_items for each row execute function public.jdvcrm_validate_goods_receipt_item_v1();

-- Un retour de vente remet la marchandise dans le stock du prospecteur (déjà fait par jdvcrm_process_sale_return).
-- Il faut aussi restaurer la « marchandise confiée » (reste à vendre), sinon le stock est compté mais invendable
-- et non suivi pour le retour à l'entrepôt.
create or replace function public.jdvcrm_restore_holdings_after_return_v1(p_return_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  r public.sales_returns%rowtype;
  v_sale public.sales%rowtype;
  i record;
  h record;
  v_left numeric;
  v_give numeric;
begin
  select * into r from public.sales_returns where id = p_return_id;
  if not found then return; end if;
  select * into v_sale from public.sales where id = r.sale_id;
  if not found or v_sale.prospecteur_id is null then return; end if;

  for i in
    select article_id, sum(quantity) as qty
    from public.sales_return_items
    where return_id = r.id
    group by article_id
  loop
    v_left := i.qty;
    for h in
      select id, quantity, remaining_quantity
      from public.prospecteur_stock_holdings
      where organization_id = r.organization_id
        and prospecteur_id = v_sale.prospecteur_id
        and article_id = i.article_id
        and status in ('active', 'overdue', 'sold')
        and remaining_quantity < quantity
      order by supplied_at desc, created_at desc
      for update
    loop
      exit when v_left <= 0;
      v_give := least(h.quantity - h.remaining_quantity, v_left);
      update public.prospecteur_stock_holdings
         set remaining_quantity = remaining_quantity + v_give,
             status = case when status = 'sold' then 'active' else status end,
             sold_at = null,
             updated_at = now()
       where id = h.id;
      v_left := v_left - v_give;
    end loop;
  end loop;
end;
$function$;

revoke all on function public.jdvcrm_restore_holdings_after_return_v1(uuid) from public, anon, authenticated;

create or replace function public.jdvcrm_return_commission_trigger_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.status = 'processed' and old.status is distinct from 'processed' then
    perform public.jdvcrm_cancel_return_commissions_v1(new.id);
    perform public.jdvcrm_restore_holdings_after_return_v1(new.id);
  end if;
  return new;
end;
$function$;
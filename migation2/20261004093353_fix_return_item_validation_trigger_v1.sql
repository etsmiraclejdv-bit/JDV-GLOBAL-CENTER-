create or replace function public.jdvcrm_validate_sale_return()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_return public.sales_returns%rowtype;
  v_sale public.sales%rowtype;
  v_returned numeric;
begin
  if new.quantity is null or new.quantity <= 0 then
    raise exception 'Quantité de retour invalide';
  end if;

  select * into v_return
  from public.sales_returns
  where id = new.return_id
  for update;

  if not found then
    raise exception 'Retour introuvable';
  end if;

  select * into v_sale
  from public.sales
  where id = v_return.sale_id
  for update;

  if not found then
    raise exception 'Vente introuvable';
  end if;

  if v_sale.organization_id <> new.organization_id
     or v_return.organization_id <> new.organization_id then
    raise exception 'Organisation incohérente';
  end if;

  if v_return.client_id is not null
     and v_return.client_id <> v_sale.client_id then
    raise exception 'Client incohérent avec la vente';
  end if;

  select coalesce(sum(i.quantity),0)
    into v_returned
  from public.sales_return_items i
  join public.sales_returns r on r.id = i.return_id
  where r.sale_id = v_return.sale_id
    and r.status in ('approved','processed')
    and i.article_id = new.article_id
    and r.id <> new.return_id;

  if v_returned + new.quantity > coalesce(v_sale.quantity,0) then
    raise exception 'Quantité retournée supérieure à la quantité vendue';
  end if;

  return new;
end
$function$;
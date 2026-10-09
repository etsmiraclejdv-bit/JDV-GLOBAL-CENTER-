drop trigger if exists trg_jdvcrm_audit_payment on public.payments;

create or replace function public.jdvcrm_audit_sale()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $function$
declare
    v_user_id uuid;
begin
    v_user_id := auth.uid();
    insert into public.audit_logs (organization_id,user_id,action,entity_type,entity_id,old_data,new_data)
    values (new.organization_id,v_user_id,case when tg_op='INSERT' then 'sale_created' else 'sale_updated' end,'sale',new.id,case when tg_op='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));
    return new;
end;
$function$;

create or replace function public.jdvcrm_audit_stock_movement()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $function$
begin
    insert into public.audit_logs (organization_id,user_id,action,entity_type,entity_id,new_data)
    values (new.organization_id,new.created_by,'stock_movement_created','stock_movement',new.id,to_jsonb(new));
    return new;
end;
$function$;

drop policy if exists audit_insert on public.audit_logs;
revoke insert, update, delete on public.audit_logs from anon, authenticated;

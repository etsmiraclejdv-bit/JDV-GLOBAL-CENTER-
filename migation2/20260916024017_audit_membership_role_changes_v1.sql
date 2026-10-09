-- BLOCK 13: immutable audit trail for organization membership and role changes.
create or replace function public.jdvcrm_audit_organization_member()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
begin
  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data
  )
  values (
    coalesce(new.organization_id, old.organization_id),
    auth.uid(),
    case
      when tg_op = 'INSERT' then 'organization_member_created'
      when tg_op = 'UPDATE' then
        case
          when old.role is distinct from new.role then 'organization_member_role_changed'
          when old.status is distinct from new.status then 'organization_member_status_changed'
          when old.user_id is distinct from new.user_id then 'organization_member_user_changed'
          else 'organization_member_updated'
        end
      when tg_op = 'DELETE' then 'organization_member_deleted'
    end,
    'organization_member',
    coalesce(new.id, old.id),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) else null end
  );

  return coalesce(new, old);
end;
$$;

revoke execute on function public.jdvcrm_audit_organization_member() from public, anon, authenticated, service_role;

-- Trigger execution does not require client-side RPC access; it runs from the table change.
drop trigger if exists trg_jdvcrm_audit_organization_member on public.organization_members;
create trigger trg_jdvcrm_audit_organization_member
after insert or update or delete on public.organization_members
for each row execute function public.jdvcrm_audit_organization_member();

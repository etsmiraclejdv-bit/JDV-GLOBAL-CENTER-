create or replace function private.has_active_subscription(p_org_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, private
as $$
begin
  if auth.uid() is null or p_org_id is null then
    return false;
  end if;

  if private.is_super_admin() then
    return true;
  end if;

  if not exists (
    select 1
    from public.organization_members om
    where om.organization_id = p_org_id
      and om.user_id = auth.uid()
      and om.status = 'active'
  ) then
    return false;
  end if;

  return exists (
    select 1
    from public.organization_subscriptions os
    where os.organization_id = p_org_id
      and os.status in ('trial','active','past_due')
      and (os.expires_at is null or os.expires_at > now())
  );
end;
$$;

revoke execute on function private.has_active_subscription(uuid) from public, anon;
grant execute on function private.has_active_subscription(uuid) to authenticated;

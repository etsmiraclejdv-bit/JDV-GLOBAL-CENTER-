create or replace function private.has_active_subscription(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select
    private.is_super_admin()
    or exists (
      select 1
      from public.organization_subscriptions os
      where os.organization_id = p_org_id
        and os.status in ('trial','active','past_due')
        and (os.expires_at is null or os.expires_at > now())
    );
$$;

revoke execute on function private.has_active_subscription(uuid) from public, anon, authenticated;

do $$
declare
  v_table text;
  v_tables text[] := array[
    'article_categories','article_serial_assignments','articles',
    'call_center_tasks','call_logs','clients','commissions','daily_tokens',
    'documents','field_visits','follow_up_reminders',
    'goods_receipt_items','goods_receipts','payment_refunds',
    'payment_schedules','payments','prospect_activities','prospect_assignments',
    'prospect_followups','prospect_status_history','prospecteur_stocks',
    'prospecteurs','prospects','purchase_order_items','purchase_orders',
    'sale_items','sales','sales_return_items','sales_returns','serial_numbers',
    'stock_movements','stock_transfer_items','stock_transfers','stocks',
    'supplier_payments','suppliers','warehouse_inventory','warehouses'
  ];
begin
  foreach v_table in array v_tables loop
    if exists (
      select 1 from pg_class c
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public'
        and c.relname=v_table
        and c.relkind='r'
        and c.relrowsecurity=true
    ) and exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name=v_table and column_name='organization_id'
    ) then
      execute format('drop policy if exists subscription_access_guard on public.%I', v_table);
      execute format(
        'create policy subscription_access_guard on public.%I as restrictive for all to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id))',
        v_table
      );
    end if;
  end loop;
end $$;

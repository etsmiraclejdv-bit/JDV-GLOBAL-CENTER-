begin;

-- Remove legacy policies whose broader predicates would override the intended
-- portfolio isolation through PostgreSQL's OR-combination of permissive policies.
drop policy if exists payments_select on public.payments;
drop policy if exists schedules_select on public.payment_schedules;
drop policy if exists schedules_update on public.payment_schedules;
drop policy if exists schedules_insert on public.payment_schedules;

-- Remove redundant copies now superseded by the hardened policies.
drop policy if exists payments_insert on public.payments;
drop policy if exists payments_prospecteur_insert on public.payments;
drop policy if exists payments_prospecteur_select on public.payments;
drop policy if exists sales_insert on public.sales;
drop policy if exists sales_select on public.sales;
drop policy if exists sales_update on public.sales;
drop policy if exists sales_prospecteur_insert on public.sales;
drop policy if exists sales_prospecteur_select on public.sales;
drop policy if exists sales_prospecteur_update on public.sales;
drop policy if exists sale_items_admin_access on public.sale_items;
drop policy if exists sale_items_prospecteur_insert on public.sale_items;
drop policy if exists sale_items_prospecteur_select on public.sale_items;
drop policy if exists sale_items_prospecteur_update on public.sale_items;
drop policy if exists commissions_select on public.commissions;

commit;

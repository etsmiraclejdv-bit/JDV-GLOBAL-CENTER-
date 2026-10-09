begin;

-- ============================================================
-- 1. INDEXES FOR FINANCIAL/CRM QUERIES AND COMMISSION IDEMPOTENCY
-- ============================================================
create index if not exists idx_jdvcrm_sales_org_prospecteur_status
  on public.sales(organization_id, prospecteur_id, status, sale_date desc);

create index if not exists idx_jdvcrm_sale_items_sale
  on public.sale_items(sale_id, organization_id);

create index if not exists idx_jdvcrm_schedules_sale_due
  on public.payment_schedules(sale_id, due_date, status);

create index if not exists idx_jdvcrm_payments_sale_status_date
  on public.payments(sale_id, status, payment_date desc);

create index if not exists idx_jdvcrm_payments_schedule_status
  on public.payments(schedule_id, status);

create unique index if not exists ux_jdvcrm_commission_sale_prospecteur
  on public.commissions(sale_id, prospecteur_id)
  where sale_id is not null and prospecteur_id is not null;

-- ============================================================
-- 2. HARDEN PAYMENT VALIDATION
--    - derive sale from schedule
--    - derive client/prospecteur from sale when omitted
--    - enforce organization consistency
--    - successful payments cannot exceed sale total
-- ============================================================
create or replace function public.jdvcrm_validate_payment_v43()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $function$
declare
  v_sale_org uuid;
  v_sale_client uuid;
  v_sale_prospecteur uuid;
  v_schedule_sale uuid;
  v_schedule_org uuid;
  v_schedule_status text;
  v_sale_total numeric(14,2);
  v_existing_paid numeric(14,2);
begin
  if auth.uid() is null then
    raise exception 'Authentification requise';
  end if;

  if new.amount is null or new.amount <= 0 then
    raise exception 'Le montant du paiement doit être supérieur à 0.';
  end if;

  if new.organization_id is null then
    raise exception 'organization_id obligatoire pour un paiement.';
  end if;

  if new.schedule_id is not null then
    select sale_id, organization_id, status
      into v_schedule_sale, v_schedule_org, v_schedule_status
    from public.payment_schedules
    where id = new.schedule_id
    for update;

    if not found then
      raise exception 'Échéance introuvable : %', new.schedule_id;
    end if;

    if v_schedule_org <> new.organization_id then
      raise exception 'L''échéance et le paiement appartiennent à des organisations différentes.';
    end if;

    if v_schedule_status = 'cancelled' then
      raise exception 'Impossible d''enregistrer un paiement sur une échéance annulée.';
    end if;

    if new.sale_id is null then
      new.sale_id := v_schedule_sale;
    elsif new.sale_id <> v_schedule_sale then
      raise exception 'L''échéance ne correspond pas à la vente.';
    end if;
  end if;

  if new.sale_id is not null then
    select
      organization_id,
      client_id,
      prospecteur_id,
      case
        when lower(coalesce(sale_type,'credit')) = 'credit'
          then coalesce(credit_price,0) * coalesce(quantity,0)
        else coalesce(cash_price,0) * coalesce(quantity,0)
      end
    into v_sale_org, v_sale_client, v_sale_prospecteur, v_sale_total
    from public.sales
    where id = new.sale_id
    for update;

    if not found then
      raise exception 'Vente introuvable : %', new.sale_id;
    end if;

    if v_sale_org <> new.organization_id then
      raise exception 'Le paiement et la vente appartiennent à des organisations différentes.';
    end if;

    if new.client_id is null then
      new.client_id := v_sale_client;
    elsif v_sale_client is not null and new.client_id <> v_sale_client then
      raise exception 'Le client du paiement ne correspond pas à celui de la vente.';
    end if;

    if new.prospecteur_id is null then
      new.prospecteur_id := v_sale_prospecteur;
    elsif v_sale_prospecteur is not null and new.prospecteur_id <> v_sale_prospecteur then
      raise exception 'Le prospecteur du paiement ne correspond pas au prospecteur de la vente.';
    end if;

    if lower(coalesce(new.status,'')) = 'successful' then
      select coalesce(sum(amount),0)
        into v_existing_paid
      from public.payments
      where sale_id = new.sale_id
        and lower(coalesce(status,'')) = 'successful'
        and id is distinct from new.id;

      if v_existing_paid + new.amount > v_sale_total then
        raise exception 'Paiement refusé : cumul %.2f supérieur au total de la vente %.2f.',
          v_existing_paid + new.amount, v_sale_total;
      end if;
    end if;
  end if;

  if new.client_id is not null and not exists (
    select 1 from public.clients c
    where c.id = new.client_id
      and c.organization_id = new.organization_id
  ) then
    raise exception 'Le client du paiement n''appartient pas à cette organisation.';
  end if;

  if new.prospecteur_id is not null and not exists (
    select 1 from public.prospecteurs p
    where p.id = new.prospecteur_id
      and p.organization_id = new.organization_id
  ) then
    raise exception 'Le prospecteur du paiement n''appartient pas à cette organisation.';
  end if;

  return new;
end;
$function$;

-- ============================================================
-- 3. HARDEN SALE VALIDATION / ORGANIZATION CONSISTENCY
-- ============================================================
create or replace function public.jdvcrm_validate_sale_prospecteur_v41()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $function$
declare
  v_org uuid;
begin
  if new.prospecteur_id is not null then
    select organization_id into v_org
    from public.prospecteurs
    where id = new.prospecteur_id;

    if not found or v_org <> new.organization_id then
      raise exception 'Le prospecteur de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  if new.client_id is not null then
    if not exists (
      select 1 from public.clients c
      where c.id = new.client_id
        and c.organization_id = new.organization_id
    ) then
      raise exception 'Le client de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  if new.article_id is not null then
    if not exists (
      select 1 from public.articles a
      where a.id = new.article_id
        and a.organization_id = new.organization_id
    ) then
      raise exception 'L''article de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  return new;
end;
$function$;

-- ============================================================
-- 4. RLS: SALES
--    SUPER ADMIN global; ADMIN organization; PROSPECTEUR own sales.
-- ============================================================
drop policy if exists sales_super_admin_all on public.sales;
drop policy if exists sales_admin_all on public.sales;
drop policy if exists sales_prospecteur_select on public.sales;
drop policy if exists sales_prospecteur_insert on public.sales;
drop policy if exists sales_prospecteur_update on public.sales;
drop policy if exists sales_prospecteur_delete on public.sales;

create policy sales_super_admin_all on public.sales
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

create policy sales_admin_all on public.sales
  for all to authenticated
  using (private.is_org_admin(organization_id))
  with check (private.is_org_admin(organization_id));

create policy sales_prospecteur_select on public.sales
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sales_prospecteur_insert on public.sales
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sales_prospecteur_update on public.sales
  for update to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  )
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

-- ============================================================
-- 5. RLS: SALE ITEMS
-- ============================================================
drop policy if exists sale_items_super_admin_all on public.sale_items;
drop policy if exists sale_items_admin_all on public.sale_items;
drop policy if exists sale_items_prospecteur_select on public.sale_items;
drop policy if exists sale_items_prospecteur_insert on public.sale_items;
drop policy if exists sale_items_prospecteur_update on public.sale_items;

create policy sale_items_super_admin_all on public.sale_items
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

create policy sale_items_admin_all on public.sale_items
  for all to authenticated
  using (private.is_org_admin(organization_id))
  with check (private.is_org_admin(organization_id));

create policy sale_items_prospecteur_select on public.sale_items
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sale_items_prospecteur_insert on public.sale_items
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sale_items_prospecteur_update on public.sale_items
  for update to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  )
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

-- ============================================================
-- 6. RLS: PAYMENT SCHEDULES
--    Prospecteurs can read their own portfolio schedules only.
--    Creation/modification stays ADMIN/SUPER ADMIN because schedules
--    are generated by trusted database functions.
-- ============================================================
drop policy if exists payment_schedules_super_admin_all on public.payment_schedules;
drop policy if exists payment_schedules_admin_all on public.payment_schedules;
drop policy if exists payment_schedules_prospecteur_select on public.payment_schedules;

create policy payment_schedules_super_admin_all on public.payment_schedules
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

create policy payment_schedules_admin_all on public.payment_schedules
  for all to authenticated
  using (private.is_org_admin(organization_id))
  with check (private.is_org_admin(organization_id));

create policy payment_schedules_prospecteur_select on public.payment_schedules
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1
      from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = payment_schedules.sale_id
        and s.organization_id = payment_schedules.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

-- ============================================================
-- 7. RLS: PAYMENTS
-- ============================================================
drop policy if exists payments_super_admin_all on public.payments;
drop policy if exists payments_admin_all on public.payments;
drop policy if exists payments_prospecteur_select on public.payments;
drop policy if exists payments_prospecteur_insert on public.payments;
drop policy if exists payments_prospecteur_update on public.payments;

create policy payments_super_admin_all on public.payments
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

create policy payments_admin_all on public.payments
  for all to authenticated
  using (private.is_org_admin(organization_id))
  with check (private.is_org_admin(organization_id));

create policy payments_prospecteur_select on public.payments
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = payments.prospecteur_id
        and p.organization_id = payments.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy payments_prospecteur_insert on public.payments
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = payments.prospecteur_id
        and p.organization_id = payments.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

-- Prospecteur must never modify an existing payment after recording it.
-- Corrections/refunds remain an ADMIN/SUPER ADMIN operation.

-- ============================================================
-- 8. RLS: COMMISSIONS
--    Prospecteur read-only on own commissions.
-- ============================================================
drop policy if exists commissions_super_admin_all on public.commissions;
drop policy if exists commissions_admin_all on public.commissions;
drop policy if exists commissions_prospecteur_select on public.commissions;

create policy commissions_super_admin_all on public.commissions
  for all to authenticated
  using (private.is_super_admin())
  with check (private.is_super_admin());

create policy commissions_admin_all on public.commissions
  for all to authenticated
  using (private.is_org_admin(organization_id))
  with check (private.is_org_admin(organization_id));

create policy commissions_prospecteur_select on public.commissions
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = commissions.prospecteur_id
        and p.organization_id = commissions.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

-- ============================================================
-- 9. PAYMENT STATUS NORMALIZATION / CLIENT ACTIVITY
--    Only 'successful' has financial effect in JDV CRM.
-- ============================================================
create or replace function public.jdvcrm_update_client_payment_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  if new.client_id is not null
     and lower(coalesce(new.status,'')) = 'successful' then
    update public.clients
    set last_payment_at = greatest(coalesce(last_payment_at, new.payment_date), new.payment_date),
        last_activity_at = greatest(coalesce(last_activity_at, new.payment_date), new.payment_date),
        status = case
          when status = 'debtor' and not exists (
            select 1
            from public.payment_schedules ps
            join public.sales s on s.id = ps.sale_id
            where s.client_id = new.client_id
              and ps.organization_id = new.organization_id
              and ps.status = 'late'
              and ps.paid_amount < ps.expected_amount
          ) then 'active'
          else status
        end,
        updated_at = now()
    where id = new.client_id
      and organization_id = new.organization_id;
  end if;
  return new;
end;
$function$;

-- ============================================================
-- 10. KEEP THE V43 FINANCIAL PIPELINE AS THE SINGLE AUTHORITATIVE
--     PAYMENT PROCESSOR. Remove only clearly obsolete payment
--     triggers that reference statuses forbidden by the current
--     payments CHECK constraint and duplicate the newer pipeline.
-- ============================================================
drop trigger if exists trg_jdvcrm_client_payment_activity on public.payments;
drop trigger if exists trg_jdvcrm_after_payment_v43 on public.payments;

create trigger trg_jdvcrm_after_payment_v43
  after insert or update on public.payments
  for each row execute function public.jdvcrm_after_payment_v43();

-- Replace the client activity trigger with the current successful-only logic.
drop trigger if exists trg_jdv_update_client_activity_payment on public.payments;
create trigger trg_jdv_update_client_activity_payment
  after insert or update of status, payment_date, client_id on public.payments
  for each row execute function public.jdvcrm_update_client_payment_activity();

-- The V43 pipeline already recalculates sale totals and schedules.
-- Remove obsolete duplicate financial sync triggers only; audit/activity
-- history triggers are intentionally preserved for now.
drop trigger if exists trg_jdvcrm_payment_client_activity_v41 on public.payments;

-- ============================================================
-- 11. SECURE FUNCTION EXECUTION
-- ============================================================
revoke all on function public.jdvcrm_process_payment_v43(uuid) from public, anon;
grant execute on function public.jdvcrm_process_payment_v43(uuid) to authenticated;

revoke all on function public.jdvcrm_recalculate_sale(uuid) from public, anon;
grant execute on function public.jdvcrm_recalculate_sale(uuid) to authenticated;

commit;

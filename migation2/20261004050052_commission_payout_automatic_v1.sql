-- JDV CRM automatic commission payout queue v1
create table if not exists public.commission_payouts (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 commission_id uuid not null references public.commissions(id) on delete restrict,
 prospecteur_id uuid not null references public.prospecteurs(id) on delete restrict,
 amount numeric(14,2) not null check (amount > 0),
 currency text not null default 'XOF',
 phone_number text not null,
 payout_mode text,
 provider text not null default 'fedapay',
 provider_payout_id text,
 provider_reference text,
 status text not null default 'queued' check (status in ('queued','processing','pending','paid','failed','cancelled')),
 failure_reason text,
 requested_at timestamptz,
 paid_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(commission_id)
);
create index if not exists commission_payouts_org_status_idx on public.commission_payouts(organization_id,status,created_at desc);
create index if not exists commission_payouts_prospecteur_idx on public.commission_payouts(prospecteur_id,created_at desc);
alter table public.commission_payouts enable row level security;
grant select on public.commission_payouts to authenticated;
drop policy if exists commission_payouts_org_select on public.commission_payouts;
create policy commission_payouts_org_select on public.commission_payouts for select to authenticated using (
 exists(select 1 from public.organization_members om where om.organization_id=commission_payouts.organization_id and om.user_id=(select auth.uid()) and om.status='active' and (om.role in ('business_admin','manager','accountant') or (om.role='prospecteur' and exists(select 1 from public.prospecteurs p where p.id=commission_payouts.prospecteur_id and p.user_id=(select auth.uid())))))
);
alter table public.prospecteurs add column if not exists commission_payout_mode text;
comment on column public.prospecteurs.commission_payout_mode is 'FedaPay payout mode, e.g. mtn_open, moov, sbin';
create or replace function public.jdvcrm_queue_commission_payout_v1()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_phone text;
begin
 if new.status is distinct from 'pending' or new.commission_amount is null or new.commission_amount <= 0 then return new; end if;
 select p.phone into v_phone from public.prospecteurs p where p.id=new.prospecteur_id;
 if v_phone is null or btrim(v_phone)='' then return new; end if;
 insert into public.commission_payouts(organization_id,commission_id,prospecteur_id,amount,currency,phone_number,payout_mode,status)
 select new.organization_id,new.id,new.prospecteur_id,new.commission_amount,'XOF',v_phone,p.commission_payout_mode,'queued'
 from public.prospecteurs p where p.id=new.prospecteur_id
 on conflict(commission_id) do nothing;
 return new;
end; $$;
revoke execute on function public.jdvcrm_queue_commission_payout_v1() from public,anon,authenticated;
drop trigger if exists trg_queue_commission_payout on public.commissions;
create trigger trg_queue_commission_payout after insert on public.commissions for each row execute function public.jdvcrm_queue_commission_payout_v1();

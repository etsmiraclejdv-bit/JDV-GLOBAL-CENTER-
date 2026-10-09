create index if not exists idx_jdvcrm_payment_schedules_late_due on public.payment_schedules (organization_id,due_date) where status in ('pending','partial','late');
create index if not exists idx_jdvcrm_commissions_status_prospecteur on public.commissions (organization_id,prospecteur_id,status);

create or replace function public.jdvcrm_mark_late_schedules_v44()
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_count integer:=0;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 update public.payment_schedules ps set status='late',updated_at=now()
 where ps.due_date < current_date and ps.status in ('pending','partial') and ps.paid_amount < ps.expected_amount;
 get diagnostics v_count=row_count; return v_count;
end; $$;
revoke all on function public.jdvcrm_mark_late_schedules_v44() from public,anon,authenticated;
grant execute on function public.jdvcrm_mark_late_schedules_v44() to authenticated;

create or replace function public.jdvcrm_get_payment_followups_v44(p_organization_id uuid)
returns table(schedule_id uuid,sale_id uuid,installment_number integer,due_date date,expected_amount numeric,paid_amount numeric,remaining_amount numeric,status text,client_id uuid,client_name text,client_phone text,prospecteur_id uuid,days_late integer)
language sql security definer set search_path=public,private as $$
 select ps.id,ps.sale_id,ps.installment_number,ps.due_date,ps.expected_amount,ps.paid_amount,
 greatest(ps.expected_amount-ps.paid_amount,0),ps.status,s.client_id,
 trim(concat(c.first_name,' ',coalesce(c.last_name,''))),c.phone,s.prospecteur_id,
 greatest(current_date-ps.due_date,0)
 from public.payment_schedules ps join public.sales s on s.id=ps.sale_id
 left join public.clients c on c.id=s.client_id and c.organization_id=s.organization_id
 where ps.organization_id=p_organization_id and ps.status in ('partial','late','pending') and ps.paid_amount<ps.expected_amount
 and (private.is_super_admin() or private.is_org_admin(p_organization_id) or (private.is_prospecteur(p_organization_id) and exists(select 1 from public.prospecteurs p where p.id=s.prospecteur_id and p.user_id=auth.uid() and p.status='active')))
 order by ps.due_date,ps.installment_number;
$$;
revoke all on function public.jdvcrm_get_payment_followups_v44(uuid) from public,anon,authenticated;
grant execute on function public.jdvcrm_get_payment_followups_v44(uuid) to authenticated;

create or replace function public.jdvcrm_settle_commission_v1(p_commission_id uuid)
returns jsonb language plpgsql security definer set search_path=public,private as $$
declare v public.commissions%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into v from public.commissions where id=p_commission_id for update;
 if not found then raise exception 'Commission introuvable'; end if;
 if not (private.is_super_admin() or private.is_org_admin(v.organization_id)) then raise exception 'Accès refusé'; end if;
 if v.status='cancelled' then raise exception 'Commission annulée'; end if;
 update public.commissions set status='paid',paid_at=coalesce(paid_at,now()),updated_at=now() where id=v.id;
 return jsonb_build_object('success',true,'commission_id',v.id,'status','paid','paid_at',coalesce(v.paid_at,now()));
end; $$;
revoke all on function public.jdvcrm_settle_commission_v1(uuid) from public,anon,authenticated;
grant execute on function public.jdvcrm_settle_commission_v1(uuid) to authenticated;

create or replace function public.jdvcrm_create_unpaid_followup_reminders_v1(p_organization_id uuid)
returns integer language plpgsql security definer set search_path=public,private as $$
declare v_count integer:=0; r record;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 for r in select ps.id schedule_id,s.client_id,s.prospecteur_id,ps.due_date,greatest(ps.expected_amount-ps.paid_amount,0) remaining from public.payment_schedules ps join public.sales s on s.id=ps.sale_id where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount loop
   if not exists(select 1 from public.follow_up_reminders f where f.organization_id=p_organization_id and f.client_id=r.client_id and f.reminder_at::date=current_date and f.status='pending' and coalesce(f.message,'') like 'Échéance%') then
     insert into public.follow_up_reminders(organization_id,client_id,user_id,reminder_at,channel,status,message)
     values(p_organization_id,r.client_id,(select p.user_id from public.prospecteurs p where p.id=r.prospecteur_id),now(),'app','pending',format('Échéance impayée : reste %s XOF, échéance du %s.',r.remaining,r.due_date));
     v_count:=v_count+1;
   end if;
 end loop; return v_count;
end; $$;
revoke all on function public.jdvcrm_create_unpaid_followup_reminders_v1(uuid) from public,anon,authenticated;
grant execute on function public.jdvcrm_create_unpaid_followup_reminders_v1(uuid) to authenticated;

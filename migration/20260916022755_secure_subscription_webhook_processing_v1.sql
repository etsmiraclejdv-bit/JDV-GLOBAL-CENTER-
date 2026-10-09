create unique index if not exists uq_subscription_payments_provider_reference on public.subscription_payments(provider, provider_reference) where provider_reference is not null;

create or replace function public.jdvcrm_process_subscription_webhook_v1(
  p_provider text,
  p_external_event_id text,
  p_event_type text,
  p_subscription_id uuid,
  p_amount numeric,
  p_currency text,
  p_provider_reference text,
  p_payment_method text default null,
  p_payload jsonb default '{}'::jsonb
)
returns public.subscription_payments
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_event public.payment_webhook_events;
  v_payment public.subscription_payments;
  v_sub public.organization_subscriptions;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  if nullif(trim(p_provider),'') is null then raise exception 'PROVIDER_REQUIRED'; end if;
  if nullif(trim(p_external_event_id),'') is null then raise exception 'EXTERNAL_EVENT_ID_REQUIRED'; end if;
  if nullif(trim(p_event_type),'') is null then raise exception 'EVENT_TYPE_REQUIRED'; end if;
  if nullif(trim(p_provider_reference),'') is null then raise exception 'PROVIDER_REFERENCE_REQUIRED'; end if;

  insert into public.payment_webhook_events(
    provider, external_event_id, event_type, payload, status
  ) values (
    trim(p_provider), trim(p_external_event_id), trim(p_event_type), coalesce(p_payload,'{}'::jsonb), 'received'
  )
  on conflict (provider, external_event_id) where external_event_id is not null
  do update set payload=excluded.payload, event_type=excluded.event_type
  returning * into v_event;

  if v_event.status = 'processed' then
    select * into v_payment
    from public.subscription_payments
    where provider=trim(p_provider)
      and provider_reference=trim(p_provider_reference)
    limit 1;
    if found then return v_payment; end if;
    raise exception 'WEBHOOK_ALREADY_PROCESSED_PAYMENT_NOT_FOUND';
  end if;

  if lower(trim(p_event_type)) not in ('payment.success','payment.succeeded','payment.completed','transaction.approved','approved') then
    update public.payment_webhook_events
       set status='ignored', processed_at=now(), error_message=null
     where id=v_event.id;
    return null;
  end if;

  select * into v_sub
  from public.organization_subscriptions
  where id=p_subscription_id
  for update;
  if not found then raise exception 'SUBSCRIPTION_NOT_FOUND'; end if;

  begin
    v_payment := public.jdvcrm_confirm_subscription_payment_v1(
      p_subscription_id,
      p_amount,
      p_currency,
      p_provider,
      p_provider_reference,
      p_payment_method,
      p_payload
    );
  exception when others then
    update public.payment_webhook_events
       set status='failed', error_message=sqlerrm
     where id=v_event.id;
    raise;
  end;

  update public.payment_webhook_events
     set status='processed', processed_at=now(), error_message=null
   where id=v_event.id;

  insert into public.payment_provider_events(
    organization_id, provider, event_type, provider_event_id, provider_reference,
    status, payload, processed_at
  ) values (
    v_sub.organization_id, trim(p_provider), trim(p_event_type), trim(p_external_event_id),
    trim(p_provider_reference), 'processed', coalesce(p_payload,'{}'::jsonb), now()
  )
  on conflict (provider, provider_event_id) where provider_event_id is not null do nothing;

  return v_payment;
end;
$$;

revoke execute on function public.jdvcrm_process_subscription_webhook_v1(text,text,text,uuid,numeric,text,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.jdvcrm_process_subscription_webhook_v1(text,text,text,uuid,numeric,text,text,text,jsonb) to service_role;

revoke execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) to service_role;

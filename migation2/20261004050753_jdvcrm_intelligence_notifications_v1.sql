create or replace function public.jdvcrm_notify_intelligence_alert_v1()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.user_id is not null then
    insert into public.notifications(organization_id,user_id,title,message,type,metadata)
    values(
      new.organization_id,new.user_id,new.title,coalesce(new.recommendation,new.message),'intelligence',
      jsonb_build_object('alert_id',new.id,'category',new.category,'severity',new.severity,'entity_type',new.entity_type,'entity_id',new.entity_id)
    );
  end if;
  return new;
end;
$$;
drop trigger if exists trg_intelligence_alert_notification on public.intelligence_alerts;
create trigger trg_intelligence_alert_notification after insert on public.intelligence_alerts for each row execute function public.jdvcrm_notify_intelligence_alert_v1();
revoke all on function public.jdvcrm_notify_intelligence_alert_v1() from public,anon,authenticated;

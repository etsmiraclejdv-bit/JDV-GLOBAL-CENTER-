do $$ begin
 if not exists(select 1 from pg_constraint where conname='prospects_status_check_jdv_v1') then
  alter table public.prospects add constraint prospects_status_check_jdv_v1 check(status in ('new','contacted','interested','converted','lost','inactive','closed','archived'));
 end if;
 if not exists(select 1 from pg_constraint where conname='prospects_temperature_check_jdv_v1') then
  alter table public.prospects add constraint prospects_temperature_check_jdv_v1 check(temperature in ('hot','warm','cold'));
 end if;
 if not exists(select 1 from pg_constraint where conname='clients_status_check_jdv_v1') then
  alter table public.clients add constraint clients_status_check_jdv_v1 check(status in ('active','inactive','prospect','client','debtor','completed','archived'));
 end if;
 if not exists(select 1 from pg_constraint where conname='clients_temperature_check_jdv_v1') then
  alter table public.clients add constraint clients_temperature_check_jdv_v1 check(temperature is null or temperature in ('hot','warm','cold'));
 end if;
 if not exists(select 1 from pg_constraint where conname='prospecteurs_status_check_jdv_v1') then
  alter table public.prospecteurs add constraint prospecteurs_status_check_jdv_v1 check(status in ('active','inactive','suspended','blocked'));
 end if;
end $$;

-- Une visite ne peut concerner qu'un prospect ou un client rattaché au même prospecteur et à la même entreprise.
-- Sans ce contrôle, un prospecteur pouvait enregistrer une visite sur le prospect d'un collègue : la fonction
-- jdvcrm_refresh_prospect_visit_v1 (SECURITY DEFINER) modifiait alors la fiche de ce collègue (compteur de visites,
-- dernier contact, prochaine relance). Le concepteur (support) reste exempté pour pouvoir corriger des données.
create or replace function public.jdvcrm_validate_field_visit_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if private.is_super_admin() then
    return new;
  end if;

  if new.prospect_id is not null then
    if not exists (
      select 1 from public.prospects p
       where p.id = new.prospect_id
         and p.organization_id = new.organization_id
         and p.prospecteur_id = new.prospecteur_id
    ) then
      raise exception 'Ce prospect n''appartient pas à ce prospecteur';
    end if;
  end if;

  if new.client_id is not null then
    if not exists (
      select 1 from public.clients c
       where c.id = new.client_id
         and c.organization_id = new.organization_id
         and c.prospecteur_id = new.prospecteur_id
    ) then
      raise exception 'Ce client n''appartient pas à ce prospecteur';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.jdvcrm_validate_field_visit_v1() from public, anon, authenticated;

drop trigger if exists trg_jdvcrm_validate_field_visit on public.field_visits;
create trigger trg_jdvcrm_validate_field_visit
  before insert or update of organization_id, prospecteur_id, prospect_id, client_id
  on public.field_visits
  for each row execute function public.jdvcrm_validate_field_visit_v1();
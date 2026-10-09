-- NOTE: déjà appliquée sur Supabase (version 20261006051235).
-- Le propriétaire d'une entreprise en est l'administrateur (business_admin), comme pour toute entreprise.
-- Sans cette ligne, les pages de la branche Admin qui lisent organization_members refusent l'accès au concepteur.
insert into public.organization_members (organization_id, user_id, role, status, joined_at)
select o.id, o.owner_user_id, 'business_admin', 'active', now()
from public.organizations o
join public.super_admins sa on sa.user_id = o.owner_user_id and sa.status = 'active' and coalesce(sa.actif, true) = true
where o.owner_user_id is not null
  and not exists (
    select 1 from public.organization_members om
    where om.organization_id = o.id and om.user_id = o.owner_user_id
  );

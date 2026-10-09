-- JDV CRM RBAC catalog and authorization helper
create unique index if not exists permissions_code_key on public.permissions(code);
create unique index if not exists role_permissions_role_permission_key
  on public.role_permissions(role, permission_id);

insert into public.permissions(code,name,description,module)
select v.code, v.name, v.description, v.module
from (values
 ('users.read','Lire les utilisateurs','Consulter les comptes utilisateurs','users'),
 ('users.create','Créer les utilisateurs','Créer un compte utilisateur','users'),
 ('users.update','Modifier les utilisateurs','Modifier le profil ou le rôle opérationnel','users'),
 ('users.disable','Désactiver les utilisateurs','Suspendre ou désactiver un compte','users'),
 ('organizations.read','Lire les organisations','Consulter les organisations accessibles','organizations'),
 ('organizations.update','Modifier les organisations','Modifier les paramètres d’organisation','organizations'),
 ('warehouses.read','Lire les entrepôts','Consulter les entrepôts accessibles','warehouses'),
 ('warehouses.create','Créer les entrepôts','Créer un entrepôt','warehouses'),
 ('warehouses.update','Modifier les entrepôts','Modifier un entrepôt','warehouses'),
 ('stock.receive','Réceptionner le stock','Enregistrer une réception de stock','stock'),
 ('stock.issue','Sortir du stock','Enregistrer une sortie de stock','stock'),
 ('stock.transfer','Transférer le stock','Transférer du stock entre emplacements','stock'),
 ('stock.adjust','Ajuster le stock','Effectuer un ajustement contrôlé','stock'),
 ('stock.view','Consulter le stock','Consulter les niveaux et mouvements de stock','stock'),
 ('supply.read','Lire les approvisionnements','Consulter les demandes d’approvisionnement','supply'),
 ('supply.create','Créer un approvisionnement','Créer une demande d’approvisionnement','supply'),
 ('supply.approve','Approuver un approvisionnement','Valider une demande d’approvisionnement','supply'),
 ('supply.receive','Recevoir un approvisionnement','Réceptionner un approvisionnement','supply'),
 ('prospects.read','Lire les prospects','Consulter les prospects accessibles','prospects'),
 ('prospects.create','Créer les prospects','Créer un prospect','prospects'),
 ('prospects.update','Modifier les prospects','Modifier un prospect','prospects'),
 ('clients.read','Lire les clients','Consulter les clients accessibles','clients'),
 ('clients.create','Créer les clients','Créer un client','clients'),
 ('clients.update','Modifier les clients','Modifier un client','clients'),
 ('sales.read','Lire les ventes','Consulter les ventes accessibles','sales'),
 ('sales.create','Créer les ventes','Créer une vente','sales'),
 ('sales.update','Modifier les ventes','Modifier une vente','sales'),
 ('returns.read','Lire les retours','Consulter les retours','returns'),
 ('returns.create','Créer les retours','Créer un retour','returns'),
 ('returns.approve','Approuver les retours','Valider un retour','returns'),
 ('reports.read','Lire les rapports','Consulter les rapports autorisés','reports'),
 ('reports.export','Exporter les rapports','Exporter les rapports autorisés','reports'),
 ('settings.read','Lire les paramètres','Consulter les paramètres autorisés','settings'),
 ('settings.update','Modifier les paramètres','Modifier les paramètres autorisés','settings')
) as v(code,name,description,module)
where not exists (select 1 from public.permissions p where p.code=v.code);

insert into public.role_permissions(role, permission_id)
select v.role, p.id
from (values
 ('business_admin','users.read'),('business_admin','users.create'),('business_admin','users.update'),('business_admin','users.disable'),('business_admin','organizations.read'),('business_admin','organizations.update'),('business_admin','warehouses.read'),('business_admin','warehouses.create'),('business_admin','warehouses.update'),('business_admin','stock.receive'),('business_admin','stock.issue'),('business_admin','stock.transfer'),('business_admin','stock.adjust'),('business_admin','stock.view'),('business_admin','supply.read'),('business_admin','supply.create'),('business_admin','supply.approve'),('business_admin','supply.receive'),('business_admin','prospects.read'),('business_admin','prospects.create'),('business_admin','prospects.update'),('business_admin','clients.read'),('business_admin','clients.create'),('business_admin','clients.update'),('business_admin','sales.read'),('business_admin','sales.create'),('business_admin','sales.update'),('business_admin','returns.read'),('business_admin','returns.create'),('business_admin','returns.approve'),('business_admin','reports.read'),('business_admin','reports.export'),('business_admin','settings.read'),('business_admin','settings.update'),
 ('manager','users.read'),('manager','users.update'),('manager','organizations.read'),('manager','warehouses.read'),('manager','warehouses.update'),('manager','stock.receive'),('manager','stock.issue'),('manager','stock.transfer'),('manager','stock.adjust'),('manager','stock.view'),('manager','supply.read'),('manager','supply.create'),('manager','supply.approve'),('manager','supply.receive'),('manager','prospects.read'),('manager','prospects.create'),('manager','prospects.update'),('manager','clients.read'),('manager','clients.create'),('manager','clients.update'),('manager','sales.read'),('manager','sales.create'),('manager','sales.update'),('manager','returns.read'),('manager','returns.create'),('manager','returns.approve'),('manager','reports.read'),('manager','reports.export'),
 ('supervisor','users.read'),('supervisor','organizations.read'),('supervisor','warehouses.read'),('supervisor','stock.view'),('supervisor','stock.receive'),('supervisor','stock.issue'),('supervisor','stock.transfer'),('supervisor','supply.read'),('supervisor','prospects.read'),('supervisor','prospects.create'),('supervisor','prospects.update'),('supervisor','clients.read'),('supervisor','sales.read'),('supervisor','sales.create'),('supervisor','returns.read'),('supervisor','reports.read'),
 ('prospecteur','organizations.read'),('prospecteur','warehouses.read'),('prospecteur','stock.view'),('prospecteur','supply.read'),('prospecteur','supply.create'),('prospecteur','prospects.read'),('prospecteur','prospects.create'),('prospecteur','prospects.update'),('prospecteur','clients.read'),('prospecteur','clients.create'),('prospecteur','sales.read'),
 ('commercial','organizations.read'),('commercial','warehouses.read'),('commercial','stock.view'),('commercial','prospects.read'),('commercial','prospects.update'),('commercial','clients.read'),('commercial','clients.create'),('commercial','clients.update'),('commercial','sales.read'),('commercial','sales.create'),('commercial','sales.update'),
 ('accountant','organizations.read'),('accountant','sales.read'),('accountant','returns.read'),('accountant','reports.read'),('accountant','reports.export'),('accountant','clients.read'),('accountant','prospects.read'),
 ('viewer','organizations.read'),('viewer','warehouses.read'),('viewer','stock.view'),('viewer','prospects.read'),('viewer','clients.read'),('viewer','sales.read'),('viewer','reports.read')
) as v(role,code)
join public.permissions p on p.code=v.code
on conflict do nothing;

create or replace function private.has_permission(p_permission_code text, p_org_id uuid default null)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select private.is_super_admin()
  or exists (
    select 1
    from public.organization_members om
    join public.role_permissions rp on rp.role = lower(om.role)
    join public.permissions p on p.id = rp.permission_id
    where om.user_id = (select auth.uid())
      and om.status = 'active'
      and p.code = p_permission_code
      and (p_org_id is null or om.organization_id = p_org_id)
  );
$function$;

revoke all on function private.has_permission(text, uuid) from public;
grant execute on function private.has_permission(text, uuid) to authenticated;

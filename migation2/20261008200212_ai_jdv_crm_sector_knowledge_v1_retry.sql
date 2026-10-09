create table if not exists public.ai_jdv_knowledge (
 id uuid primary key default gen_random_uuid(),
 scope text not null check (scope in ('sector','module')),
 topic text not null,
 content text not null,
 active boolean not null default true,
 updated_at timestamptz not null default now(),
 unique(scope,topic)
);
alter table public.ai_jdv_knowledge enable row level security;
revoke all on public.ai_jdv_knowledge from anon;
grant select on public.ai_jdv_knowledge to authenticated;
drop policy if exists ai_jdv_knowledge_read on public.ai_jdv_knowledge;
create policy ai_jdv_knowledge_read on public.ai_jdv_knowledge for select to authenticated using (active=true);

insert into public.ai_jdv_knowledge(scope,topic,content) values
('sector','agriculture','Gestion d''intrants, semences, engrais, équipements et consommables. Utiliser les catégories, unités et stocks par emplacement; suivre les lots ou références dans les notes si le CRM ne possède pas de champ dédié.'),
('sector','agroalimentaire','Gérer matières, produits finis, emballages et consommables. Structurer les articles par famille et unité, surveiller les entrées, sorties, retours et niveaux minimum.'),
('sector','distribution','Structurer un catalogue multi-familles, plusieurs points de stockage et une force commerciale. Relier prospection, clients, ventes, stock et retours.'),
('sector','quincaillerie','Classer visserie, outillage, plomberie, électricité et accessoires. Utiliser des codes articles stables et des unités cohérentes pour éviter les erreurs de vente et d''inventaire.'),
('sector','materiaux de construction','Gérer ciment, fer, peinture, plomberie et autres matériaux par unité de vente pertinente. Suivre les transferts entre entrepôt et sous-entrepôts.'),
('sector','pharmacie','Organiser le catalogue par familles et unités avec une vigilance renforcée sur la traçabilité. Ne jamais inventer une indication médicale ou une donnée réglementaire absente de la fiche article.'),
('sector','cosmetique','Classer soins, hygiène, parfumerie et accessoires. Utiliser les descriptions réelles des articles et relier catalogue, stock, vente et retours.'),
('sector','textile','Structurer vêtements, tissus et accessoires. Lorsque le CRM ne gère pas une variante spécifique, conserver la référence exacte dans le code ou la description validée par l''administrateur.'),
('sector','electronique','Gérer téléphones, accessoires, équipements et consommables avec des codes précis. Les informations techniques doivent provenir de la fiche article ou d''une source validée.'),
('sector','pieces_detachees','Utiliser des codes article et descriptions très précis. Relier les ventes aux retours et contrôler les mouvements de stock pour éviter les confusions entre références proches.'),
('sector','boissons_alimentation','Gérer familles, unités de vente, stocks et points de distribution. Utiliser les retours et inventaires pour maintenir la qualité des données.'),
('sector','equipements_professionnels','Décrire clairement l''équipement, son unité et sa catégorie. L''IA peut expliquer le processus CRM mais ne doit pas inventer une spécification technique.'),
('sector','services_b2b','Le catalogue peut représenter des prestations ou offres. Adapter l''explication à la logique de prospection, client, vente et suivi, sans inventer des fonctionnalités de facturation.'),
('sector','logistique','Utiliser entrepôts, sous-entrepôts, transferts et journal de mouvements pour suivre les flux. Les responsables doivent contrôler les écarts lors des inventaires et clôtures.'),
('sector','energie','Structurer équipements, consommables et composants selon les références réelles. Pour les données de sécurité ou de conformité, renvoyer à la documentation officielle de l''article.'),
('sector','hygiene_entretien','Classer produits d''entretien, hygiène et consommables avec unités et niveaux minimum cohérents. Relier approvisionnement, stock, vente et retours.'),
('module','organisation','Création d''entreprise : créer et paramétrer l''organisation, puis préparer ses utilisateurs, rôles et structures opérationnelles avant les ventes.'),
('module','utilisateurs','Utilisateurs et rôles : attribuer les rôles selon les responsabilités et appliquer le principe du moindre privilège.'),
('module','entrepots','Entrepôts et sous-entrepôts : créer l''entrepôt principal puis ses sous-entrepôts pour représenter les emplacements opérationnels et contrôler les flux.'),
('module','articles','Articles : créer un code stable, un nom, une description utile, une catégorie et une unité. Les prix et paramètres commerciaux doivent rester ceux validés par l''organisation.'),
('module','prospection','Prospection : le prospecteur crée et suit les prospects, planifie les relances et transforme progressivement les opportunités en clients.'),
('module','clients','Clients : centraliser les informations du client et son historique afin de préparer les ventes et le suivi commercial.'),
('module','ventes','Ventes : relier client, prospecteur, article, quantité, prix, paiement et statut, puis assurer le suivi jusqu''à la finalisation.'),
('module','approvisionnement','Approvisionnement : créer et suivre les demandes d''approvisionnement, réceptionner les marchandises et contrôler les quantités reçues.'),
('module','stock','Stock et mouvements : suivre entrées, sorties, transferts et ajustements; le journal permet de comprendre qui a fait quoi et quand.'),
('module','retours','Retours de marchandises : tracer l''agent ou prospecteur, la date/heure, le code article, la quantité, l''emplacement, le motif et la réception.'),
('module','tracabilite','Traçabilité et inventaire : comparer le stock théorique au stock physique et documenter les écarts avant clôture.'),
('module','pilotage','Rapports et pilotage : utiliser les indicateurs disponibles pour suivre l''activité et décider des actions opérationnelles.')
on conflict(scope,topic) do update set content=excluded.content,active=true,updated_at=now();
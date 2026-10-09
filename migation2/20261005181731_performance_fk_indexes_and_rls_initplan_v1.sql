-- NOTE: déjà appliquée sur Supabase (version 20261005181731).
-- 1) Index sur les 22 clés étrangères non couvertes
create index if not exists idx_fk_commission_adjustments_commission_type_id on public.commission_adjustments (commission_type_id);
create index if not exists idx_fk_commission_adjustments_organization_id on public.commission_adjustments (organization_id);
create index if not exists idx_fk_commission_adjustments_prospecteur_id on public.commission_adjustments (prospecteur_id);
create index if not exists idx_fk_commission_rules_commission_type_id on public.commission_rules (commission_type_id);
create index if not exists idx_fk_commissions_commission_type_id on public.commissions (commission_type_id);
create index if not exists idx_fk_commissions_rule_id on public.commissions (rule_id);
create index if not exists idx_fk_intelligence_alerts_prospecteur_id on public.intelligence_alerts (prospecteur_id);
create index if not exists idx_fk_organization_application_documents_uploaded_by on public.organization_application_documents (uploaded_by);
create index if not exists idx_fk_organization_application_reviews_application_id on public.organization_application_reviews (application_id);
create index if not exists idx_fk_organization_application_reviews_reviewer_user_id on public.organization_application_reviews (reviewer_user_id);
create index if not exists idx_fk_organization_application_tokens_application_id on public.organization_application_tokens (application_id);
create index if not exists idx_fk_organization_applications_reviewed_by on public.organization_applications (reviewed_by);
create index if not exists idx_fk_prospecteur_stock_holdings_article_id on public.prospecteur_stock_holdings (article_id);
create index if not exists idx_fk_prospecteur_stock_holdings_prospecteur_id on public.prospecteur_stock_holdings (prospecteur_id);
create index if not exists idx_fk_prospecteur_stock_holdings_supply_request_id on public.prospecteur_stock_holdings (supply_request_id);
create index if not exists idx_fk_prospecteur_stock_holdings_warehouse_id on public.prospecteur_stock_holdings (warehouse_id);
create index if not exists idx_fk_prospecteur_supply_request_items_article_id on public.prospecteur_supply_request_items (article_id);
create index if not exists idx_fk_prospecteur_supply_request_items_organization_id on public.prospecteur_supply_request_items (organization_id);
create index if not exists idx_fk_prospecteur_supply_requests_organization_id on public.prospecteur_supply_requests (organization_id);
create index if not exists idx_fk_prospecteur_supply_requests_processed_by on public.prospecteur_supply_requests (processed_by);
create index if not exists idx_fk_prospecteur_supply_requests_warehouse_id on public.prospecteur_supply_requests (warehouse_id);
create index if not exists idx_fk_prospecteur_warehouse_assignments_warehouse_id on public.prospecteur_warehouse_assignments (warehouse_id);

-- 2) Index en double (la contrainte prospecteur_stocks_prospecteur_id_article_id_key est conservée)
drop index if exists public.uq_prospecteur_stock_article;

-- 3) RLS : évaluer auth.uid()/auth.role()/auth.jwt() une seule fois par requête, et non par ligne.
--    Transformation strictement équivalente : auth.uid() -> (select auth.uid())
do $$
declare r record; v_sql text; v_q text; v_c text;
begin
  for r in
    select policyname, tablename, qual, with_check
    from pg_policies
    where schemaname = 'public'
      and (qual ~* '(?<!select )auth\.(uid|role|jwt)\(\)' or with_check ~* '(?<!select )auth\.(uid|role|jwt)\(\)')
  loop
    v_q := regexp_replace(r.qual,       '(?<!select )auth\.(uid|role|jwt)\(\)', '(select auth.\1())', 'gi');
    v_c := regexp_replace(r.with_check, '(?<!select )auth\.(uid|role|jwt)\(\)', '(select auth.\1())', 'gi');
    v_sql := format('alter policy %I on public.%I', r.policyname, r.tablename);
    if r.qual is not null then v_sql := v_sql || format(' using (%s)', v_q); end if;
    if r.with_check is not null then v_sql := v_sql || format(' with check (%s)', v_c); end if;
    execute v_sql;
  end loop;
end $$;
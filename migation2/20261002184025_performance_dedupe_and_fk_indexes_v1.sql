-- 1) Supprime les index strictement identiques (mêmes colonnes, classes, prédicat, unicité).
--    On garde toujours un exemplaire : celui adossé à une contrainte s'il existe, sinon le premier par nom.
--    Aucun index lié à une clé primaire ou à une contrainte n'est supprimé.
-- 2) Crée un index sur chaque clé étrangère du schéma public qui n'en a pas.
do $$
declare
  r record;
begin
  for r in
    with idx as (
      select i.indexrelid, c.relname as idx, i.indisprimary,
             exists (select 1 from pg_constraint k where k.conindid = i.indexrelid) as sert_contrainte,
             i.indrelid, i.indkey::text as cols, i.indclass::text as cls, i.indisunique,
             coalesce(pg_get_expr(i.indpred, i.indrelid), '') as pred,
             coalesce(pg_get_expr(i.indexprs, i.indrelid), '') as expr
      from pg_index i
      join pg_class c on c.oid = i.indexrelid
      where c.relnamespace = 'public'::regnamespace and i.indisvalid
    ),
    ranked as (
      select idx, sert_contrainte, indisprimary,
             row_number() over (
               partition by indrelid, cols, cls, pred, expr, indisunique
               order by (sert_contrainte or indisprimary) desc, idx
             ) as rang
      from idx
    )
    select idx from ranked where rang > 1 and not sert_contrainte and not indisprimary
  loop
    execute format('drop index if exists public.%I', r.idx);
  end loop;

  for r in
    with fk as (
      select c.conrelid, c.conkey, cl.relname as tbl,
             (select string_agg(quote_ident(a.attname), ', ' order by k.ord)
                from unnest(c.conkey) with ordinality k(attnum, ord)
                join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum) as cols,
             (select string_agg(a.attname, '_' order by k.ord)
                from unnest(c.conkey) with ordinality k(attnum, ord)
                join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum) as cols_nom
      from pg_constraint c
      join pg_class cl on cl.oid = c.conrelid
      where c.contype = 'f' and c.connamespace = 'public'::regnamespace
    )
    select tbl, cols,
           case when length('idx_fk_' || tbl || '_' || cols_nom) > 63
                then left('idx_fk_' || tbl || '_' || cols_nom, 54) || '_' || left(md5('idx_fk_' || tbl || '_' || cols_nom), 8)
                else 'idx_fk_' || tbl || '_' || cols_nom end as nom
    from fk
    where not exists (
      select 1 from pg_index i
      where i.indrelid = fk.conrelid and i.indisvalid
        and (string_to_array(i.indkey::text, ' ')::int2[])[1:cardinality(fk.conkey)] = fk.conkey
    )
  loop
    execute format('create index if not exists %I on public.%I (%s)', r.nom, r.tbl, r.cols);
  end loop;
end
$$;

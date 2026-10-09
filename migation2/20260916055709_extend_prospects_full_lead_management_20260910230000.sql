BEGIN;

ALTER TABLE public.prospects
  ADD COLUMN IF NOT EXISTS category TEXT;

ALTER TABLE public.prospects
  ADD COLUMN IF NOT EXISTS purchase_date_planned DATE;

ALTER TABLE public.prospects
  ADD COLUMN IF NOT EXISTS estimated_amount NUMERIC(12,2);

CREATE INDEX IF NOT EXISTS idx_prospects_organization_phone
ON public.prospects (organization_id, phone);

CREATE INDEX IF NOT EXISTS idx_prospects_organization_temperature
ON public.prospects (organization_id, temperature);

CREATE INDEX IF NOT EXISTS idx_prospects_organization_category
ON public.prospects (organization_id, category);

CREATE INDEX IF NOT EXISTS idx_prospects_next_follow_up
ON public.prospects (organization_id, next_follow_up_at);

CREATE INDEX IF NOT EXISTS idx_prospects_purchase_date
ON public.prospects (organization_id, purchase_date_planned);

UPDATE public.prospects
SET temperature = 'hot'
WHERE lower(temperature) IN ('chaud')
  AND temperature <> 'hot';

UPDATE public.prospects
SET temperature = 'warm'
WHERE lower(temperature) IN ('tiede', 'tiède')
  AND temperature <> 'warm';

UPDATE public.prospects
SET temperature = 'cold'
WHERE lower(temperature) IN ('froid')
  AND temperature <> 'cold';

ALTER TABLE public.prospects
  ALTER COLUMN temperature SET DEFAULT 'cold';

COMMENT ON COLUMN public.prospects.category IS
'Catégorie commerciale personnalisée du prospect.';

COMMENT ON COLUMN public.prospects.purchase_date_planned IS
'Date prévisionnelle à laquelle le prospect prévoit d''acheter.';

COMMENT ON COLUMN public.prospects.estimated_amount IS
'Montant commercial potentiel estimé pour le prospect.';

DROP POLICY IF EXISTS "enterprise_members_read_all_prospects"
ON public.prospects;

DROP POLICY IF EXISTS "organization_members_read_all_prospects"
ON public.prospects;

CREATE POLICY "organization_members_read_all_prospects"
ON public.prospects
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = prospects.organization_id
      AND om.user_id = auth.uid()
      AND om.status = 'active'
  )
);

CREATE INDEX IF NOT EXISTS idx_prospects_phone
ON public.prospects (phone)
WHERE phone IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_prospects_first_name
ON public.prospects (first_name);

CREATE INDEX IF NOT EXISTS idx_prospects_last_name
ON public.prospects (last_name);

COMMIT;

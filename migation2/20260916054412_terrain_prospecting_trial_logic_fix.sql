BEGIN;
UPDATE public.organizations o
SET status = CASE
  WHEN os.status='active' AND sp.code='TRIAL' AND os.expires_at>now() THEN 'trial'
  WHEN os.status='active' AND sp.code<>'TRIAL' AND os.expires_at>now() THEN 'active'
  WHEN os.status='active' AND os.expires_at<=now() THEN 'expired'
  ELSE o.status END,
subscription_status = CASE
  WHEN os.status='active' AND sp.code='TRIAL' AND os.expires_at>now() THEN 'trial'
  WHEN os.status='active' AND sp.code<>'TRIAL' AND os.expires_at>now() THEN 'active'
  WHEN os.status='active' AND os.expires_at<=now() THEN 'expired'
  ELSE o.subscription_status END,
updated_at=now()
FROM public.organization_subscriptions os
JOIN public.subscription_plans sp ON sp.id=os.plan_id
WHERE os.organization_id=o.id
  AND os.id=(SELECT os2.id FROM public.organization_subscriptions os2 WHERE os2.organization_id=o.id ORDER BY os2.created_at DESC LIMIT 1);
COMMIT;

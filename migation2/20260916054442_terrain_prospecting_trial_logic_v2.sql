BEGIN;

ALTER TABLE public.prospects ADD COLUMN IF NOT EXISTS category text;
ALTER TABLE public.prospects ADD COLUMN IF NOT EXISTS purchase_date_planned date;

COMMENT ON COLUMN public.prospects.category IS 'Catégorie/type du prospect pour le suivi commercial.';
COMMENT ON COLUMN public.prospects.purchase_date_planned IS 'Date prévisionnelle d''achat du prospect.';

CREATE INDEX IF NOT EXISTS idx_prospects_organization_id ON public.prospects (organization_id);
CREATE INDEX IF NOT EXISTS idx_prospects_prospecteur_id ON public.prospects (prospecteur_id);
CREATE INDEX IF NOT EXISTS idx_prospects_status ON public.prospects (status);
CREATE INDEX IF NOT EXISTS idx_prospects_temperature ON public.prospects (temperature);
CREATE INDEX IF NOT EXISTS idx_prospects_next_follow_up_at ON public.prospects (next_follow_up_at);
CREATE INDEX IF NOT EXISTS idx_prospects_purchase_date_planned ON public.prospects (purchase_date_planned);

INSERT INTO public.subscription_plans(code,name,description,price,currency,duration_days,max_admins,max_prospecteurs,max_clients,features,active)
SELECT 'TRIAL','Essai gratuit 14 jours','Accès gratuit complet à JDV CRM pendant 14 jours.',0,'USD',14,1,10,100,
jsonb_build_object('trial',true,'duration_days',14,'stock_management',true,'prospecting',true,'field_visits',true,'sales',true,'daily_tokens',true,'payments',true,'commissions',true,'reports',true),true
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE code='TRIAL');

UPDATE public.subscription_plans SET name='Essai gratuit 14 jours',description='Accès gratuit complet à JDV CRM pendant 14 jours.',price=0,currency='USD',duration_days=14,max_admins=1,max_prospecteurs=10,max_clients=100,
features=jsonb_build_object('trial',true,'duration_days',14,'stock_management',true,'prospecting',true,'field_visits',true,'sales',true,'daily_tokens',true,'payments',true,'commissions',true,'reports',true),active=true,updated_at=now()
WHERE code='TRIAL';

CREATE OR REPLACE FUNCTION private.start_organization_trial()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE v_plan_id uuid; v_start timestamptz; v_end timestamptz;
BEGIN
 SELECT id INTO v_plan_id FROM public.subscription_plans WHERE code='TRIAL' AND active=true LIMIT 1;
 IF v_plan_id IS NULL THEN RETURN NEW; END IF;
 v_start:=now(); v_end:=v_start+interval '14 days';
 IF NOT EXISTS (SELECT 1 FROM public.organization_subscriptions WHERE organization_id=NEW.id) THEN
  INSERT INTO public.organization_subscriptions(organization_id,plan_id,status,started_at,expires_at,auto_renew)
  VALUES(NEW.id,v_plan_id,'active',v_start,v_end,false);
  UPDATE public.organizations SET status='trial',subscription_status='trial',updated_at=now() WHERE id=NEW.id;
 END IF;
 RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.start_organization_trial() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.start_organization_trial() FROM authenticated;

DROP TRIGGER IF EXISTS trg_start_organization_trial ON public.organizations;
CREATE TRIGGER trg_start_organization_trial AFTER INSERT ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.start_organization_trial();

CREATE OR REPLACE FUNCTION public.check_organization_access(p_organization_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$
DECLARE v_user_id uuid; v_org_status text; v_subscription_status text; v_subscription_id uuid; v_plan_code text; v_subscription_state text; v_started_at timestamptz; v_expires_at timestamptz; v_days_remaining integer; v_is_member boolean; v_is_super_admin boolean;
BEGIN
 v_user_id:=auth.uid();
 IF v_user_id IS NULL THEN RETURN jsonb_build_object('access',false,'status','unauthenticated','days_remaining',0); END IF;
 SELECT EXISTS(SELECT 1 FROM public.super_admins sa WHERE sa.user_id=v_user_id AND sa.status='active' AND COALESCE(sa.actif,true)=true) INTO v_is_super_admin;
 SELECT EXISTS(SELECT 1 FROM public.organization_members om WHERE om.organization_id=p_organization_id AND om.user_id=v_user_id AND om.status='active') INTO v_is_member;
 IF NOT v_is_member AND NOT v_is_super_admin THEN RETURN jsonb_build_object('access',false,'status','forbidden','days_remaining',0); END IF;
 SELECT o.status,o.subscription_status INTO v_org_status,v_subscription_status FROM public.organizations o WHERE o.id=p_organization_id;
 IF v_org_status IS NULL THEN RETURN jsonb_build_object('access',false,'status','organization_not_found','days_remaining',0); END IF;
 IF v_org_status IN('suspended','blocked') THEN RETURN jsonb_build_object('access',false,'status',v_org_status,'days_remaining',0); END IF;
 SELECT os.id,sp.code,os.status,os.started_at,os.expires_at INTO v_subscription_id,v_plan_code,v_subscription_state,v_started_at,v_expires_at
 FROM public.organization_subscriptions os JOIN public.subscription_plans sp ON sp.id=os.plan_id
 WHERE os.organization_id=p_organization_id ORDER BY os.created_at DESC LIMIT 1;
 IF v_subscription_id IS NULL THEN RETURN jsonb_build_object('access',false,'status','inactive','days_remaining',0,'subscription_id',null,'plan_code',null); END IF;
 IF v_expires_at IS NOT NULL AND now()>=v_expires_at AND v_subscription_state IN('active','past_due','trial') THEN
  UPDATE public.organization_subscriptions SET status='expired',updated_at=now() WHERE id=v_subscription_id;
  UPDATE public.organizations SET subscription_status='expired',status='expired',updated_at=now() WHERE id=p_organization_id;
  RETURN jsonb_build_object('access',false,'status','expired','days_remaining',0,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
 END IF;
 IF v_subscription_state='active' THEN
  v_days_remaining:=CASE WHEN v_expires_at IS NULL THEN 0 ELSE GREATEST(0,CEIL(EXTRACT(EPOCH FROM(v_expires_at-now()))/86400))::integer END;
  IF v_plan_code='TRIAL' THEN
   UPDATE public.organizations SET status='trial',subscription_status='trial',updated_at=now() WHERE id=p_organization_id AND status NOT IN('suspended','blocked');
   RETURN jsonb_build_object('access',true,'status','trial','days_remaining',v_days_remaining,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
  END IF;
  UPDATE public.organizations SET status='active',subscription_status='active',updated_at=now() WHERE id=p_organization_id AND status NOT IN('suspended','blocked');
  RETURN jsonb_build_object('access',true,'status','active','days_remaining',v_days_remaining,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
 END IF;
 RETURN jsonb_build_object('access',false,'status',COALESCE(v_subscription_state,'inactive'),'days_remaining',0,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
END;
$$;
REVOKE ALL ON FUNCTION public.check_organization_access(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_organization_access(uuid) TO authenticated;

CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_org ON public.organization_subscriptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_status ON public.organization_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_expires ON public.organization_subscriptions(expires_at);

INSERT INTO public.organization_subscriptions(organization_id,plan_id,status,started_at,expires_at,auto_renew)
SELECT o.id,sp.id,'active',COALESCE(o.created_at,now()),COALESCE(o.created_at,now())+interval '14 days',false
FROM public.organizations o CROSS JOIN LATERAL(SELECT id FROM public.subscription_plans WHERE code='TRIAL' AND active=true LIMIT 1) sp
WHERE NOT EXISTS(SELECT 1 FROM public.organization_subscriptions os WHERE os.organization_id=o.id);

UPDATE public.organizations o
SET status=CASE WHEN os.status='active' AND sp.code='TRIAL' AND os.expires_at>now() THEN 'trial' WHEN os.status='active' AND sp.code<>'TRIAL' AND os.expires_at>now() THEN 'active' WHEN os.status='active' AND os.expires_at<=now() THEN 'expired' ELSE o.status END,
subscription_status=CASE WHEN os.status='active' AND sp.code='TRIAL' AND os.expires_at>now() THEN 'trial' WHEN os.status='active' AND sp.code<>'TRIAL' AND os.expires_at>now() THEN 'active' WHEN os.status='active' AND os.expires_at<=now() THEN 'expired' ELSE o.subscription_status END,
updated_at=now()
FROM public.organization_subscriptions os
JOIN public.subscription_plans sp ON sp.id=os.plan_id
WHERE os.organization_id=o.id
AND os.id=(SELECT os2.id FROM public.organization_subscriptions os2 WHERE os2.organization_id=o.id ORDER BY os2.created_at DESC LIMIT 1);

COMMENT ON FUNCTION public.check_organization_access(uuid) IS 'Vérifie de manière sécurisée si un utilisateur peut accéder à une organisation JDV CRM. Gère trial 14 jours, abonnements actifs, expirations et suspensions.';
COMMIT;

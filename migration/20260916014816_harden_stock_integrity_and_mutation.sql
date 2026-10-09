BEGIN;

-- Conserver une seule validation complète par table de stock.
DROP TRIGGER IF EXISTS trg_jdv_validate_stock_quantity ON public.stocks;
DROP TRIGGER IF EXISTS trg_jdv_validate_prospecteur_stock ON public.prospecteur_stocks;

-- Le stock prospecteur est alimenté par les opérations de distribution/transfert,
-- il ne doit pas être modifiable arbitrairement par le prospecteur.
DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_delete ON public.prospecteur_stocks;
DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_modify ON public.prospecteur_stocks;
DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_update ON public.prospecteur_stocks;

-- Les mouvements de stock sont des écritures comptables/inventaire :
-- seuls ADMIN et SUPER ADMIN peuvent les créer directement.
DROP POLICY IF EXISTS stock_movements_insert ON public.stock_movements;
CREATE POLICY stock_movements_admin_insert ON public.stock_movements
FOR INSERT TO authenticated
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

-- Renforcer la cohérence organisationnelle d'un mouvement.
CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_movement()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_article_org uuid;
    v_prospecteur_org uuid;
BEGIN
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'JDV CRM: la quantité d''un mouvement de stock doit être supérieure à zéro';
    END IF;

    IF NEW.organization_id IS NULL THEN
        RAISE EXCEPTION 'JDV CRM: organization_id obligatoire pour un mouvement de stock';
    END IF;

    IF NEW.article_id IS NULL THEN
        RAISE EXCEPTION 'JDV CRM: article_id obligatoire pour un mouvement de stock';
    END IF;

    SELECT organization_id INTO v_article_org
    FROM public.articles
    WHERE id = NEW.article_id;

    IF NOT FOUND OR v_article_org <> NEW.organization_id THEN
        RAISE EXCEPTION 'JDV CRM: l''article et le mouvement doivent appartenir à la même organisation';
    END IF;

    IF NEW.prospecteur_id IS NOT NULL THEN
        SELECT organization_id INTO v_prospecteur_org
        FROM public.prospecteurs
        WHERE id = NEW.prospecteur_id;

        IF NOT FOUND OR v_prospecteur_org <> NEW.organization_id THEN
            RAISE EXCEPTION 'JDV CRM: le prospecteur et le mouvement doivent appartenir à la même organisation';
        END IF;
    END IF;

    RETURN NEW;
END;
$function$;

COMMIT;

-- Doublon des tables agri_farms / agri_products (schéma plus complet, conservé).
-- Les tables agriculture_* (migration jdv_agriculture_interface_foundation, 20260920035228) étaient vides,
-- sans vue ni fonction dépendante.
drop table if exists public.agriculture_products;
drop table if exists public.agriculture_farms;

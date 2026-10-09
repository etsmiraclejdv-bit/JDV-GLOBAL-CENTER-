-- Doublon "JOIE DE VIVRE " (2026-09-23, type commerce) vs "Joie de vivre" (2026-09-24, type company) :
-- même propriétaire, même pays. On conserve la plus récente (519e49a6-0fb5-40e8-8b27-0116d380930f).
-- L'ancienne n'avait que sa ligne de membre (suppression en cascade).
delete from public.organizations where id = '091d69b6-a0ee-4bed-86df-1b365742b2f0';

-- BLOCK 14: remove one exact duplicate updated_at trigger.
-- Both functions only assign NEW.updated_at = now(); keep the shared JDV trigger.
drop trigger if exists trg_jdv_super_admin_modules_updated_at on public.super_admin_modules;

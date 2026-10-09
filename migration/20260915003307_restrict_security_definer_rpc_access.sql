-- verify_current_super_admin : uniquement les utilisateurs connectés
revoke execute on function public.verify_current_super_admin() from anon;
revoke execute on function public.verify_current_super_admin() from public;

-- register_company : uniquement les utilisateurs connectés (la fonction exige déjà auth.uid())
revoke execute on function public.register_company(text, text, text, text, text) from anon;
revoke execute on function public.register_company(text, text, text, text, text) from public;

-- rls_auto_enable : fonction interne (event trigger), aucun rôle API ne doit pouvoir l'appeler
revoke execute on function public.rls_auto_enable() from anon;
revoke execute on function public.rls_auto_enable() from authenticated;
revoke execute on function public.rls_auto_enable() from public;

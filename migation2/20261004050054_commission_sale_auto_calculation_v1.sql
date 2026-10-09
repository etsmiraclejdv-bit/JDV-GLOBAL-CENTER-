-- Activate automatic commission calculation at sale creation
drop trigger if exists trg_apply_sale_commissions on public.sales;
create trigger trg_apply_sale_commissions after insert on public.sales for each row execute function public.jdvcrm_create_sale_commission();

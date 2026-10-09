CREATE OR REPLACE FUNCTION public.jdvcrm_mark_late_schedules_v44()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path='public','private'
AS $$
DECLARE v_count integer:=0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
  END IF;
  IF NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'SUPER_ADMIN_REQUIRED';
  END IF;
  UPDATE public.payment_schedules ps
  SET status='late', updated_at=now()
  WHERE ps.due_date < current_date
    AND ps.status IN ('pending','partial')
    AND ps.paid_amount < ps.expected_amount;
  GET DIAGNOSTICS v_count=row_count;
  RETURN v_count;
END;
$$;
REVOKE ALL ON FUNCTION public.jdvcrm_mark_late_schedules_v44() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.jdvcrm_mark_late_schedules_v44() TO authenticated;

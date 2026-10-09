import { supabase } from '@/lib/supabase/client';
import { parseDashboard, type CommissionRow, type FinancialDashboard, type ProspecteurRow } from '@/lib/finances/helpers';

/** Indicateurs financiers de la période (administrateur de l'entreprise ou concepteur uniquement). */
export async function fetchDashboard(
  organizationId: string,
  start: string,
  end: string
): Promise<{ data: FinancialDashboard | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_financial_dashboard_v1', {
    p_organization_id: organizationId,
    p_start_date: start,
    p_end_date: end,
  });
  if (error) return { data: null, error: error.message };
  return { data: parseDashboard(data), error: null };
}

export async function fetchByProspecteur(
  organizationId: string,
  start: string,
  end: string
): Promise<{ data: ProspecteurRow[]; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_financial_dashboard_by_prospecteur_v1', {
    p_organization_id: organizationId,
    p_start_date: start,
    p_end_date: end,
  });
  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as ProspecteurRow[], error: null };
}

export async function fetchCommissions(
  organizationId: string,
  start: string,
  end: string
): Promise<{ data: CommissionRow[]; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_report_commissions_v1', {
    p_organization_id: organizationId,
    p_start_date: start,
    p_end_date: end,
  });
  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as CommissionRow[], error: null };
}

/** Marque une commission comme payée (action irréversible côté application). */
export async function settleCommission(commissionId: string): Promise<{ paidAt: string | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_settle_commission_v1', { p_commission_id: commissionId });
  if (error) return { paidAt: null, error: error.message };
  const result = (data ?? {}) as { success?: boolean; paid_at?: string };
  if (result.success !== true) return { paidAt: null, error: 'Le règlement a été refusé.' };
  return { paidAt: result.paid_at ?? new Date().toISOString(), error: null };
}

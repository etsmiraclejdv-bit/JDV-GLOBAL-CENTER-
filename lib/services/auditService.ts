import { supabase } from '@/lib/supabase/client';

export interface AuditLog {
  id: string;
  organization_id?: string;
  user_id?: string;
  action: string;
  entity_type: string;
  entity_id?: string;
  old_data?: Record<string, unknown>;
  new_data?: Record<string, unknown>;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
}

export async function fetchAuditLogs(filters?: {
  organizationId?: string;
  entityType?: string;
  action?: string;
  userId?: string;
  dateFrom?: string;
  dateTo?: string;
}, limit = 50) {
  let query = supabase
    .from('audit_logs' as never)
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (filters?.organizationId) query = (query as ReturnType<typeof supabase.from>).eq('organization_id', filters.organizationId);
  if (filters?.entityType) query = (query as ReturnType<typeof supabase.from>).eq('entity_type', filters.entityType);
  if (filters?.action) query = (query as ReturnType<typeof supabase.from>).eq('action', filters.action);
  if (filters?.userId) query = (query as ReturnType<typeof supabase.from>).eq('user_id', filters.userId);
  if (filters?.dateFrom) query = (query as ReturnType<typeof supabase.from>).gte('created_at', filters.dateFrom);
  if (filters?.dateTo) query = (query as ReturnType<typeof supabase.from>).lte('created_at', filters.dateTo);

  const { data, error } = await query;
  return { data: data as AuditLog[] | null, error };
}

import { supabase } from '@/lib/supabase/client';

export interface Notification {
  id: string;
  organization_id?: string;
  user_id: string;
  title: string;
  message: string;
  type: string;
  read_at?: string | null;
  metadata?: Record<string, unknown>;
  created_at: string;
}

export async function fetchNotifications(userId: string, limit = 10) {
  const { data, error } = await supabase
    .from('notifications' as never)
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  return { data: data as Notification[] | null, error };
}

export async function fetchUnreadCount(userId: string): Promise<number> {
  const { count, error } = await supabase
    .from('notifications' as never)
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is('read_at', null);
  if (error) return 0;
  return count ?? 0;
}

export async function markNotificationRead(notificationId: string) {
  const { error } = await supabase
    .from('notifications' as never)
    .update({ read_at: new Date().toISOString() })
    .eq('id', notificationId);
  return { error };
}

export async function markAllNotificationsRead(userId: string) {
  const { error } = await supabase
    .from('notifications' as never)
    .update({ read_at: new Date().toISOString() })
    .eq('user_id', userId)
    .is('read_at', null);
  return { error };
}

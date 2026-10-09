'use client';

import { useEffect, useRef } from 'react';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';
import { usePathname } from 'next/navigation';

export default function IntelligencePresenceTracker() {
  const pathname = usePathname();
  const sessionIdRef = useRef<string | null>(null);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);

  useEffect(() => {
    let cancelled = false;
    let heartbeat: ReturnType<typeof setInterval> | null = null;
    let currentUserId: string | null = null;

    const start = async () => {
      const { data: auth } = await supabase.auth.getUser();
      if (!auth.user || cancelled) return;
      currentUserId = auth.user.id;

      const { data: profile } = await fetchOrgProfile();
      if (!profile?.organization_id || cancelled) return;

      const { data: membership } = await supabase
        .from('organization_members')
        .select('role')
        .eq('organization_id', profile.organization_id)
        .eq('user_id', auth.user.id)
        .eq('status', 'active')
        .maybeSingle();

      const prospecteurId = profile.prospecteur_id ?? null;
      const { data: session, error } = await supabase
        .from('user_activity_sessions')
        .insert({
          organization_id: profile.organization_id,
          user_id: auth.user.id,
          prospecteur_id: prospecteurId,
          role: membership?.role ?? null,
          last_route: pathname,
        })
        .select('id')
        .single();

      if (error || !session || cancelled) return;
      sessionIdRef.current = session.id;

      const touch = async () => {
        const id = sessionIdRef.current;
        if (!id) return;
        await supabase.rpc('jdvcrm_touch_activity_session_v1', {
          p_session_id: id,
          p_route: window.location.pathname,
        });
      };

      heartbeat = setInterval(touch, 60_000);
      await touch();

      const channel = supabase.channel(`jdv-presence-${profile.organization_id}`, {
        config: { presence: { key: auth.user.id } },
      });

      channel.on('presence', { event: 'sync' }, () => {}).on('presence', { event: 'join' }, () => {}).on('presence', { event: 'leave' }, () => {});
      channel.subscribe(async status => {
        if (status === 'SUBSCRIBED') {
          await channel.track({
            user_id: auth.user.id,
            prospecteur_id: prospecteurId,
            role: membership?.role ?? null,
            route: window.location.pathname,
            online_at: new Date().toISOString(),
          });
        }
      });
      channelRef.current = channel;
    };

    start();

    return () => {
      cancelled = true;
      if (heartbeat) clearInterval(heartbeat);
      const id = sessionIdRef.current;
      if (id) {
        void supabase
          .from('user_activity_sessions')
          .update({ ended_at: new Date().toISOString() })
          .eq('id', id)
          .eq('user_id', currentUserId ?? '');
      }
      if (channelRef.current) {
        void channelRef.current.untrack();
        void supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, [pathname]);

  return null;
}

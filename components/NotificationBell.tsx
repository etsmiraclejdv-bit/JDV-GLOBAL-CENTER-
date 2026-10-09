'use client';
import React, { useState, useEffect } from 'react';
import { Bell, X, Check, CheckCheck } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchNotifications, fetchUnreadCount, markNotificationRead, markAllNotificationsRead, Notification } from '@/lib/services/notificationsService';

export default function NotificationBell() {
  const [open, setOpen] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [userId, setUserId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) {
        setUserId(data.user.id);
        fetchUnreadCount(data.user.id).then(setUnreadCount);
      }
    });
  }, []);

  useEffect(() => {
    if (open && userId) {
      setLoading(true);
      fetchNotifications(userId, 10).then(({ data }) => {
        setNotifications(data ?? []);
        setLoading(false);
      });
    }
  }, [open, userId]);

  async function handleMarkRead(id: string) {
    await markNotificationRead(id);
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, read_at: new Date().toISOString() } : n));
    setUnreadCount(prev => Math.max(0, prev - 1));
  }

  async function handleMarkAllRead() {
    if (!userId) return;
    await markAllNotificationsRead(userId);
    setNotifications(prev => prev.map(n => ({ ...n, read_at: new Date().toISOString() })));
    setUnreadCount(0);
  }

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(v => !v)}
        className="relative p-2.5 rounded-xl bg-[#0A1628] border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white transition-all"
        aria-label="Notifications"
      >
        <Bell size={16} />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] flex items-center justify-center rounded-full bg-red-500 text-white text-[10px] font-bold px-1">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-full mt-2 w-80 bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl shadow-2xl z-50 overflow-hidden">
            <div className="flex items-center justify-between px-4 py-3 border-b border-[#D4AF37]/10">
              <span className="font-semibold text-white text-sm">Notifications</span>
              <div className="flex items-center gap-2">
                {unreadCount > 0 && (
                  <button
                    onClick={handleMarkAllRead}
                    className="text-xs text-[#D4AF37] hover:underline flex items-center gap-1"
                  >
                    <CheckCheck size={12} />
                    Tout lire
                  </button>
                )}
                <button onClick={() => setOpen(false)} className="text-[#718096] hover:text-white">
                  <X size={14} />
                </button>
              </div>
            </div>

            <div className="max-h-80 overflow-y-auto">
              {loading ? (
                <div className="py-8 text-center text-[#718096] text-sm">Chargement...</div>
              ) : notifications.length === 0 ? (
                <div className="py-8 text-center text-[#718096] text-sm">
                  <Bell size={24} className="mx-auto mb-2 opacity-40" />
                  Aucune notification
                </div>
              ) : (
                notifications.map(n => (
                  <div
                    key={n.id}
                    className={`px-4 py-3 border-b border-[#D4AF37]/5 hover:bg-[#0A1628]/50 transition-colors cursor-pointer ${!n.read_at ? 'bg-[#D4AF37]/5' : ''}`}
                    onClick={() => !n.read_at && handleMarkRead(n.id)}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <p className={`text-sm font-medium truncate ${!n.read_at ? 'text-white' : 'text-[#A0AEC0]'}`}>
                          {n.title}
                        </p>
                        <p className="text-xs text-[#718096] mt-0.5 line-clamp-2">{n.message}</p>
                        <p className="text-xs text-[#718096] mt-1">
                          {new Date(n.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                        </p>
                      </div>
                      {!n.read_at && (
                        <button
                          onClick={e => { e.stopPropagation(); handleMarkRead(n.id); }}
                          className="flex-shrink-0 p-1 rounded-lg text-[#D4AF37] hover:bg-[#D4AF37]/10"
                          title="Marquer comme lu"
                        >
                          <Check size={12} />
                        </button>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

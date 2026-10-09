'use client';
import AuditLogView from '@/components/AuditLogView';

export default function BusinessAuditPage() {
  return <AuditLogView isSuperAdmin={false} />;
}

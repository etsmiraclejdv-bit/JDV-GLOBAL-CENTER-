'use client';
import AuditLogView from '@/components/AuditLogView';

export default function SuperAdminAuditPage() {
  return <AuditLogView isSuperAdmin={true} />;
}

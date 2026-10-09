'use client';
import { useParams } from 'next/navigation';
import PurchaseOrderDetailView from '@/components/PurchaseOrderDetailView';
import ErrorState from '@/components/ui/ErrorState';

export default function BusinessPurchaseOrderPage() {
  const params = useParams();
  const raw = params?.id;
  const id = Array.isArray(raw) ? raw[0] : raw;
  if (!id || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
    return <ErrorState message="Identifiant de commande invalide." />;
  }
  return <PurchaseOrderDetailView orderId={id} />;
}

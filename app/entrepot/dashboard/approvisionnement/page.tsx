'use client';

import { useCallback, useEffect, useState } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { useWarehouse } from '@/components/entrepot/WarehouseContext';
import {
  Banner,
  Card,
  PageTitle,
  btnGhost,
  btnGold,
  dateFr,
  inputCls,
  num,
  useBanner,
} from '@/components/entrepot/common';

type Req = {
  id: string;
  reference: string;
  target: 'supplier' | 'admin';
  supplier_id: string | null;
  status: string;
  notes: string | null;
  response_notes: string | null;
  requested_at: string;
  warehouse_supply_request_items: Array<{
    id: string;
    article_id: string;
    quantity: number;
    received_quantity: number;
  }>;
};

type Opt = { id: string; label: string };
type Line = { article_id: string; quantity: string };

const STATUS: Record<string, string> = {
  sent: 'Envoyée',
  approved: 'Approuvée par l’admin',
  ordered: 'Commandée',
  partially_received: 'Reçue partiellement',
  received: 'Reçue',
  rejected: 'Refusée',
  cancelled: 'Annulée',
};

export default function EntrepotApprovisionnementPage() {
  const { current } = useWarehouse();
  const { banner, ok, fail } = useBanner();

  const [reqs, setReqs] = useState<Req[]>([]);
  const [articles, setArticles] = useState<Opt[]>([]);
  const [suppliers, setSuppliers] = useState<Opt[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [target, setTarget] = useState<'supplier' | 'admin'>('supplier');
  const [supplierId, setSupplierId] = useState('');
  const [lines, setLines] = useState<Line[]>([
    { article_id: '', quantity: '1' },
  ]);
  const [notes, setNotes] = useState('');
  const [receiving, setReceiving] = useState<string | null>(null);
  const [recvQty, setRecvQty] = useState<Record<string, string>>({});

  const load = useCallback(async () => {
    if (!current) return;

    setLoading(true);
    const id = current.warehouse_id;

    const [requestsResult, stockResult, suppliersResult] = await Promise.all([
      supabase
        .from('warehouse_supply_requests')
        .select(
          'id,reference,target,supplier_id,status,notes,response_notes,requested_at,warehouse_supply_request_items(id,article_id,quantity,received_quantity)',
        )
        .eq('warehouse_id', id)
        .order('requested_at', { ascending: false })
        .limit(100),
      supabase.rpc('jdvcrm_warehouse_stock_v1', {
        p_warehouse_id: id,
      }),
      supabase.rpc('jdvcrm_warehouse_suppliers_v1', {
        p_warehouse_id: id,
      }),
    ]);

    const error =
      requestsResult.error || stockResult.error || suppliersResult.error;

    if (error) {
      fail(error.message);
    }

    setReqs((requestsResult.data ?? []) as unknown as Req[]);
    setArticles(
      ((stockResult.data ?? []) as Array<{
        article_id: string;
        article_name: string;
      }>).map((item) => ({
        id: item.article_id,
        label: item.article_name,
      })),
    );
    setSuppliers(
      ((suppliersResult.data ?? []) as Array<{
        supplier_id: string;
        name: string;
      }>).map((item) => ({
        id: item.supplier_id,
        label: item.name,
      })),
    );
    setLoading(false);
  }, [current, fail]);

  useEffect(() => {
    void load();
  }, [load]);

  const aName = (id: string) =>
    articles.find((article) => article.id === id)?.label ?? 'Produit';

  const sName = (id: string | null) =>
    suppliers.find((supplier) => supplier.id === id)?.label ?? '—';

  async function submit() {
    if (!current) return;

    const items = lines
      .filter((line) => line.article_id)
      .map((line) => ({
        article_id: line.article_id,
        quantity: Number(line.quantity),
      }));

    if (!items.length) {
      fail('Sélectionnez au moins un produit.');
      return;
    }

    if (
      items.some(
        (item) => !Number.isInteger(item.quantity) || item.quantity < 1,
      )
    ) {
      fail('Quantités invalides.');
      return;
    }

    if (target === 'supplier' && !supplierId) {
      fail('Choisissez un fournisseur.');
      return;
    }

    setBusy(true);

    const { data, error } = await supabase.rpc(
      'jdvcrm_warehouse_request_supply_v1',
      {
        p_warehouse_id: current.warehouse_id,
        p_target: target,
        p_supplier_id: target === 'supplier' ? supplierId : null,
        p_items: items,
        p_notes: notes.trim() || null,
      },
    );

    setBusy(false);

    if (error) {
      fail(error.message);
      return;
    }

    const result = data as { reference: string };
    ok('Demande ' + result.reference + ' envoyée.');
    setShowForm(false);
    setLines([{ article_id: '', quantity: '1' }]);
    setNotes('');
    void load();
  }

  async function action(
    request: Req,
    actionName: 'cancel' | 'mark_ordered',
  ) {
    if (
      actionName === 'cancel' &&
      !window.confirm('Annuler la demande ' + request.reference + ' ?')
    ) {
      return;
    }

    setBusy(true);

    const { error } = await supabase.rpc(
      'jdvcrm_warehouse_update_supply_v1',
      {
        p_request_id: request.id,
        p_action: actionName,
        p_notes: null,
      },
    );

    setBusy(false);

    if (error) {
      fail(error.message);
      return;
    }

    ok(
      actionName === 'cancel'
        ? 'Demande annulée.'
        : 'Demande marquée comme commandée.',
    );
    void load();
  }

  async function receive(request: Req) {
    const items = request.warehouse_supply_request_items
      .map((item) => ({
        article_id: item.article_id,
        quantity: Number(
          recvQty[item.id] ??
            Number(item.quantity) - Number(item.received_quantity),
        ),
      }))
      .filter((item) => item.quantity > 0);

    if (!items.length) {
      fail('Indiquez au moins une quantité reçue.');
      return;
    }

    if (items.some((item) => !Number.isInteger(item.quantity))) {
      fail('Quantités invalides.');
      return;
    }

    setBusy(true);

    const { data, error } = await supabase.rpc(
      'jdvcrm_warehouse_receive_supply_v1',
      {
        p_request_id: request.id,
        p_items: items,
      },
    );

    setBusy(false);

    if (error) {
      fail(error.message);
      return;
    }

    const result = data as {
      received_units: number;
      status: string;
    };

    ok(
      num(result.received_units) +
        ' unité(s) ajoutées au stock de l’entrepôt (' +
        (STATUS[result.status] ?? result.status).toLowerCase() +
        ').',
    );

    setReceiving(null);
    setRecvQty({});
    void load();
  }

  return (
    <div className="p-6 space-y-6 text-white">
      <PageTitle
        title="Approvisionnement"
        subtitle="Demandez du stock directement à votre fournisseur ou à l’administrateur, et enregistrez les réceptions."
      >
        <button
          onClick={() => setShowForm(!showForm)}
          className={btnGold}
        >
          <Plus size={14} className="inline mr-1" />
          Nouvelle demande
        </button>
      </PageTitle>

      <Banner state={banner} />

      {showForm && (
        <Card
          title="Nouvelle demande d’approvisionnement"
          className="border-[#D4AF37]/40"
        >
          <div className="flex flex-wrap gap-4 text-sm mb-4">
            <label>
              <input
                type="radio"
                checked={target === 'supplier'}
                onChange={() => setTarget('supplier')}
              />{' '}
              À mon fournisseur
            </label>
            <label>
              <input
                type="radio"
                checked={target === 'admin'}
                onChange={() => setTarget('admin')}
              />{' '}
              À l’administrateur
            </label>
          </div>

          {target === 'supplier' && (
            <select
              className={inputCls + ' max-w-sm mb-4'}
              value={supplierId}
              onChange={(event) => setSupplierId(event.target.value)}
            >
              <option value="">Choisir le fournisseur</option>
              {suppliers.map((supplier) => (
                <option key={supplier.id} value={supplier.id}>
                  {supplier.label}
                </option>
              ))}
            </select>
          )}

          <div className="space-y-2">
            {lines.map((line, index) => (
              <div
                key={index}
                className="flex flex-wrap items-center gap-2"
              >
                <select
                  className={inputCls + ' max-w-sm'}
                  value={line.article_id}
                  onChange={(event) =>
                    setLines(
                      lines.map((item, itemIndex) =>
                        itemIndex === index
                          ? {
                              ...item,
                              article_id: event.target.value,
                            }
                          : item,
                      ),
                    )
                  }
                >
                  <option value="">Choisir un produit</option>
                  {articles.map((article) => (
                    <option key={article.id} value={article.id}>
                      {article.label}
                    </option>
                  ))}
                </select>

                <input
                  type="number"
                  min={1}
                  className={inputCls + ' w-24'}
                  value={line.quantity}
                  onChange={(event) =>
                    setLines(
                      lines.map((item, itemIndex) =>
                        itemIndex === index
                          ? {
                              ...item,
                              quantity: event.target.value,
                            }
                          : item,
                      ),
                    )
                  }
                />

                {lines.length > 1 && (
                  <button
                    onClick={() =>
                      setLines(
                        lines.filter(
                          (_, itemIndex) => itemIndex !== index,
                        ),
                      )
                    }
                    className="text-red-400"
                    type="button"
                  >
                    <Trash2 size={16} />
                  </button>
                )}
              </div>
            ))}
          </div>

          <button
            onClick={() =>
              setLines([...lines, { article_id: '', quantity: '1' }])
            }
            className="mt-3 text-sm text-[#D4AF37]"
            type="button"
          >
            <Plus size={14} className="inline mr-1" />
            Ajouter un produit
          </button>

          <input
            className={inputCls + ' mt-4'}
            placeholder="Message (optionnel)"
            value={notes}
            onChange={(event) => setNotes(event.target.value)}
          />

          <div className="mt-4 flex gap-2">
            <button
              onClick={() => setShowForm(false)}
              className={btnGhost}
              type="button"
            >
              Annuler
            </button>
            <button
              disabled={busy}
              onClick={submit}
              className={btnGold}
              type="button"
            >
              Envoyer la demande
            </button>
          </div>
        </Card>
      )}

      <Card title="Mes demandes">
        {loading ? (
          <p className="text-sm text-slate-400">Chargement…</p>
        ) : (
          <div className="space-y-4">
            {reqs.map((request) => (
              <div
                key={request.id}
                className="rounded-xl border border-white/10 p-4 text-sm"
              >
                <div className="flex justify-between">
                  <span className="font-semibold">{request.reference}</span>
                  <span className="rounded-full bg-[#0F2347] px-3 py-1 text-xs">
                    {STATUS[request.status] ?? request.status}
                  </span>
                </div>

                <div className="text-slate-400">
                  {request.target === 'supplier'
                    ? 'Fournisseur : ' + sName(request.supplier_id)
                    : 'Administrateur'}{' '}
                  · {dateFr(request.requested_at)}
                </div>

                <ul className="mt-3 space-y-2">
                  {request.warehouse_supply_request_items.map((item) => {
                    const remaining =
                      Number(item.quantity) -
                      Number(item.received_quantity);

                    return (
                      <li
                        key={item.id}
                        className="flex flex-wrap items-center justify-between gap-2"
                      >
                        <span>{aName(item.article_id)}</span>

                        {receiving === request.id &&
                        request.target === 'supplier' &&
                        remaining > 0 ? (
                          <input
                            type="number"
                            min={1}
                            max={remaining}
                            className={inputCls + ' w-28'}
                            value={recvQty[item.id] ?? String(remaining)}
                            onChange={(event) =>
                              setRecvQty({
                                ...recvQty,
                                [item.id]: event.target.value,
                              })
                            }
                          />
                        ) : (
                          <span>
                            reçu {num(item.received_quantity)} /{' '}
                            {num(item.quantity)}
                          </span>
                        )}
                      </li>
                    );
                  })}
                </ul>

                <div className="mt-3 flex flex-wrap gap-2">
                  {request.target === 'supplier' &&
                    request.status === 'sent' && (
                      <button
                        disabled={busy}
                        onClick={() => action(request, 'mark_ordered')}
                        className={btnGhost}
                        type="button"
                      >
                        Marquer commandée
                      </button>
                    )}

                  {request.target === 'supplier' &&
                    ['sent', 'ordered', 'partially_received'].includes(
                      request.status,
                    ) &&
                    (receiving === request.id ? (
                      <>
                        <button
                          onClick={() => setReceiving(null)}
                          className={btnGhost}
                          type="button"
                        >
                          Annuler
                        </button>
                        <button
                          disabled={busy}
                          onClick={() => receive(request)}
                          className={btnGold}
                          type="button"
                        >
                          Valider la réception
                        </button>
                      </>
                    ) : (
                      <button
                        onClick={() => setReceiving(request.id)}
                        className={btnGold}
                        type="button"
                      >
                        Réceptionner
                      </button>
                    ))}

                  {['sent', 'approved', 'ordered'].includes(
                    request.status,
                  ) && (
                    <button
                      disabled={busy}
                      onClick={() => action(request, 'cancel')}
                      className={btnGhost + ' text-red-400'}
                      type="button"
                    >
                      Annuler la demande
                    </button>
                  )}
                </div>
              </div>
            ))}

            {!reqs.length && (
              <p className="text-sm text-slate-500">
                Aucune demande.
              </p>
            )}
          </div>
        )}
      </Card>
    </div>
  );
}

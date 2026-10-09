import test from 'node:test';
import assert from 'node:assert/strict';
import {
  orderStatusLabel, canReceive, canCancelOrder, canPay, paymentMethodLabel, nextSupplierCode,
  lineTotal, orderTotal, validateOrderLines, toOrderItemsPayload,
  receivedByArticle, remainingByArticle, receiptProgress, validateReceiptInputs,
  paidTotal, remainingToPay, paymentState, validatePaymentAmount, balancesBySupplier, friendlyDbError,
} from '../src/lib/purchases/helpers.ts';

test('statuts et droits d\'action', () => {
  assert.equal(orderStatusLabel('partial'), 'Partiellement reçue');
  assert.equal(orderStatusLabel('autre'), 'autre');
  for (const s of ['draft', 'sent', 'confirmed', 'partial']) assert.equal(canReceive(s), true, s);
  for (const s of ['received', 'cancelled', 'closed']) assert.equal(canReceive(s), false, s);
  assert.equal(canCancelOrder('confirmed', 0), true);
  assert.equal(canCancelOrder('confirmed', 100), false, 'déjà un paiement');
  assert.equal(canCancelOrder('partial', 0), false, 'marchandise reçue');
  assert.equal(canPay('received', 500), true);
  assert.equal(canPay('received', 0), false);
  assert.equal(canPay('cancelled', 500), false);
  assert.equal(paymentMethodLabel('mobile_money'), 'Mobile Money');
  assert.equal(paymentMethodLabel(null), '—');
});

test('nextSupplierCode ignore les autres formats', () => {
  assert.equal(nextSupplierCode([]), 'F-0001');
  assert.equal(nextSupplierCode(['F-0001', 'F-0007', 'f-0003']), 'F-0008');
  assert.equal(nextSupplierCode(['SUP-12', 'AUTRE', '']), 'F-0001');
  assert.equal(nextSupplierCode(['F-9999']), 'F-10000');
});

test('totaux de commande arrondis au centime', () => {
  assert.equal(lineTotal({ quantity: '3', unit_cost: '1250.5' }), 3751.5);
  assert.equal(lineTotal({ quantity: 'x', unit_cost: 10 }), 0);
  assert.equal(orderTotal([{ article_id: 'a', quantity: 10, unit_cost: 1000 }, { article_id: 'b', quantity: 5, unit_cost: 2000 }]), 20000);
  assert.equal(orderTotal([{ article_id: 'a', quantity: 3, unit_cost: 0.1 }]), 0.3);
  assert.equal(orderTotal([]), 0);
});

test('validateOrderLines', () => {
  const ok = { article_id: 'a', quantity: '2', unit_cost: '500' };
  assert.equal(validateOrderLines([ok]), null);
  assert.match(validateOrderLines([]), /au moins un article/);
  assert.match(validateOrderLines([{ ...ok, article_id: '' }]), /Ligne 1 : choisissez un article/);
  assert.match(validateOrderLines([ok, { ...ok }]), /Ligne 2 : cet article est déjà/);
  assert.match(validateOrderLines([{ ...ok, quantity: '0' }]), /quantité/);
  assert.match(validateOrderLines([{ ...ok, quantity: '-3' }]), /quantité/);
  assert.match(validateOrderLines([{ ...ok, unit_cost: '' }]), /coût unitaire/);
  assert.match(validateOrderLines([{ ...ok, unit_cost: '-1' }]), /coût unitaire/);
  assert.equal(validateOrderLines([{ ...ok, unit_cost: '0' }]), null, 'un coût nul est permis (échantillon)');
  assert.deepEqual(toOrderItemsPayload([ok]), [{ article_id: 'a', quantity: 2, unit_cost: 500 }]);
});

const items = [{ article_id: 'a', quantity: 10 }, { article_id: 'b', quantity: '5' }];
const receipts = [
  { status: 'received', goods_receipt_items: [{ article_id: 'a', quantity_received: 4 }] },
  { status: 'cancelled', goods_receipt_items: [{ article_id: 'a', quantity_received: 99 }] },
  { status: 'draft', goods_receipt_items: [{ article_id: 'b', quantity_received: 3 }] },
  { status: 'received', goods_receipt_items: null },
];

test('quantités reçues et restantes (seules les réceptions « received » comptent)', () => {
  assert.deepEqual(receivedByArticle(receipts), { a: 4 });
  assert.deepEqual(remainingByArticle(items, receipts), { a: 6, b: 5 });
  assert.deepEqual(remainingByArticle(items, [{ status: 'received', goods_receipt_items: [{ article_id: 'a', quantity_received: 50 }] }]), { a: 0, b: 5 });
  assert.equal(receiptProgress(items, receipts), 27); // 4 / 15
  assert.equal(receiptProgress([], []), 0);
  assert.equal(receiptProgress(items, [{ status: 'received', goods_receipt_items: [{ article_id: 'a', quantity_received: 50 }, { article_id: 'b', quantity_received: 5 }] }]), 100);
});

test('validateReceiptInputs', () => {
  const remaining = { a: 6, b: 5 };
  assert.deepEqual(validateReceiptInputs(remaining, { a: '4', b: '' }), { error: null, items: [{ article_id: 'a', quantity_received: 4 }] });
  assert.deepEqual(validateReceiptInputs(remaining, { a: '2,5', b: '0' }).items, [{ article_id: 'a', quantity_received: 2.5 }]);
  assert.match(validateReceiptInputs(remaining, { a: '7' }).error, /dépasse/);
  assert.match(validateReceiptInputs(remaining, { a: 'abc' }).error, /invalide/);
  assert.match(validateReceiptInputs(remaining, { a: '-1' }).error, /invalide/);
  assert.match(validateReceiptInputs(remaining, { a: '', b: '0' }).error, /au moins une quantité/);
  assert.match(validateReceiptInputs(remaining, { zzz: '1' }).error, /dépasse/, 'article inconnu = reste 0');
});

test('paiements : totaux, état, validation', () => {
  const pays = [{ amount: 5000, status: 'paid' }, { amount: '1000', status: 'failed' }, { amount: 2500.5, status: 'paid' }, { amount: 999, status: 'pending' }];
  assert.equal(paidTotal(pays), 7500.5);
  assert.equal(remainingToPay(20000, pays), 12499.5);
  assert.equal(remainingToPay(1000, pays), 0);
  assert.equal(paymentState(20000, []), 'unpaid');
  assert.equal(paymentState(20000, pays), 'partial');
  assert.equal(paymentState(7500.5, pays), 'paid');
  assert.deepEqual(validatePaymentAmount('5 000', 10000), { error: null, amount: 5000 });
  assert.deepEqual(validatePaymentAmount('2500,5', 10000), { error: null, amount: 2500.5 });
  assert.match(validatePaymentAmount('0', 10000).error, /supérieur à 0/);
  assert.match(validatePaymentAmount('abc', 10000).error, /supérieur à 0/);
  assert.match(validatePaymentAmount('10001', 10000).error, /dépasse/);
  assert.equal(validatePaymentAmount('10000', 10000).error, null, 'solder exactement est permis');
});

test('balancesBySupplier : annulées exclues, seuls les paiements payés comptent', () => {
  const orders = [
    { id: 'o1', supplier_id: 's1', total_amount: 20000, status: 'received' },
    { id: 'o2', supplier_id: 's1', total_amount: 5000, status: 'confirmed' },
    { id: 'o3', supplier_id: 's1', total_amount: 9999, status: 'cancelled' },
    { id: 'o4', supplier_id: 's2', total_amount: '3000', status: 'partial' },
  ];
  const pays = [
    { supplier_id: 's1', purchase_order_id: 'o1', amount: 15000, status: 'paid' },
    { supplier_id: 's1', purchase_order_id: 'o1', amount: 500, status: 'failed' },
    { supplier_id: 's1', purchase_order_id: 'o3', amount: 7777, status: 'paid' },
    { supplier_id: 's2', purchase_order_id: null, amount: 100, status: 'paid' },
  ];
  assert.deepEqual(balancesBySupplier(orders, pays), { s1: 10000, s2: 3000 });
  assert.deepEqual(balancesBySupplier([], []), {});
});

test('friendlyDbError remplace les identifiants par le nom de l\'article', () => {
  const id = '83b86666-aff5-495e-8113-e0ed1187ff21';
  assert.equal(
    friendlyDbError(`Réception supérieure à la quantité commandée pour l'article ${id}`, { [id]: 'Riz 25 kg' }),
    "Réception supérieure à la quantité commandée pour l'article « Riz 25 kg »"
  );
  assert.equal(friendlyDbError(`Article ${id} absent`, {}), 'Article cet article absent');
  assert.equal(friendlyDbError('Accès refusé', {}), 'Accès refusé');
  assert.equal(friendlyDbError(`x ${id.toUpperCase()}`, { [id]: 'A' }), 'x « A »');
});

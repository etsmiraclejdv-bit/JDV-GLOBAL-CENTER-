import test from 'node:test';
import assert from 'node:assert/strict';
import {
  paymentStatusLabel, webhookStatusLabel, eventTypeLabel, summarizePayments, summarizeWebhooks,
  webhookHealth, shortId, formatMoney, formatDateTimeFr,
} from '../src/lib/platform/paymentsHelpers.ts';

test('libellés avec repli sur la valeur brute', () => {
  assert.equal(paymentStatusLabel('successful'), 'Réussi');
  assert.equal(paymentStatusLabel('inconnu'), 'inconnu');
  assert.equal(webhookStatusLabel('failed'), 'Échec');
  assert.equal(eventTypeLabel('transaction.approved'), 'Paiement approuvé');
  assert.equal(eventTypeLabel('autre.chose'), 'autre.chose');
  assert.equal(eventTypeLabel(null), '—');
});

test('summarizePayments : compte par statut, somme XOF des réussis seulement', () => {
  const s = summarizePayments([
    { status: 'successful', amount: 30000, currency: 'XOF' },
    { status: 'successful', amount: '90000', currency: null },
    { status: 'successful', amount: 50, currency: 'EUR' },
    { status: 'pending', amount: 30000, currency: 'XOF' },
    { status: 'failed', amount: 30000, currency: 'XOF' },
    { status: 'refunded', amount: 30000, currency: 'XOF' },
  ]);
  assert.deepEqual(s, { total: 6, successful: 3, pending: 1, failed: 1, successfulAmountXof: 120000, otherCurrencies: true });
  assert.equal(summarizePayments([]).successfulAmountXof, 0);
});

test('summarizeWebhooks et dernier reçu', () => {
  const s = summarizeWebhooks([
    { status: 'processed', created_at: '2026-10-01T10:00:00Z' },
    { status: 'failed', created_at: '2026-10-03T08:30:00Z' },
    { status: 'ignored', created_at: '2026-10-02T09:00:00Z' },
    { status: 'received', created_at: '2026-10-01T09:00:00Z' },
  ]);
  assert.deepEqual(s, { total: 4, processed: 1, ignored: 1, failed: 1, lastReceivedAt: '2026-10-03T08:30:00Z' });
  assert.equal(summarizeWebhooks([]).lastReceivedAt, null);
});

test('webhookHealth : aucun, erreurs, ok', () => {
  assert.equal(webhookHealth({ total: 0, processed: 0, ignored: 0, failed: 0, lastReceivedAt: null }).state, 'none');
  assert.match(webhookHealth({ total: 0, processed: 0, ignored: 0, failed: 0, lastReceivedAt: null }).message, /adresse du webhook/);
  const err = webhookHealth({ total: 3, processed: 2, ignored: 0, failed: 1, lastReceivedAt: 'x' });
  assert.equal(err.state, 'errors');
  assert.match(err.message, /^1 webhook/);
  assert.equal(webhookHealth({ total: 3, processed: 2, ignored: 1, failed: 0, lastReceivedAt: 'x' }).state, 'ok');
});

test('shortId', () => {
  assert.equal(shortId('abcdefghijklmnopqrstuvwxyz'), 'abcdefghij…');
  assert.equal(shortId('court'), 'court');
  assert.equal(shortId(''), '—');
  assert.equal(shortId(null), '—');
  assert.equal(shortId('12345678901'), '12345678901', 'à peine plus long que la limite : inchangé');
});

test('formatMoney', () => {
  assert.match(formatMoney(30000, 'XOF'), /^30\D000 XOF$/);
  assert.match(formatMoney('90000', null), /^90\D000 XOF$/);
  assert.match(formatMoney(12.5, 'eur'), /^12,5 EUR$/);
  assert.equal(formatMoney('abc', 'XOF'), '0 XOF');
});

test('formatDateTimeFr dans un fuseau donné', () => {
  assert.equal(formatDateTimeFr('2026-10-03T14:05:00Z', 'UTC'), '03/10/2026 14:05');
  assert.equal(formatDateTimeFr('2026-10-03T14:05:00Z', 'Africa/Porto-Novo'), '03/10/2026 15:05');
  assert.equal(formatDateTimeFr(null), '—');
  assert.equal(formatDateTimeFr('pas une date'), '—');
});

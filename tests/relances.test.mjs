import test from 'node:test';
import assert from 'node:assert/strict';
import {
  toNumber, formatXof, formatDateFr, displayStatus, summarize, filterFollowups,
  toTelHref, toWhatsAppHref, buildReminderMessage,
} from '../src/lib/relances/helpers.ts';

const mk = (o = {}) => ({
  schedule_id: 's1', sale_id: 'v1', installment_number: 1, due_date: '2026-10-01',
  expected_amount: 10000, paid_amount: 0, remaining_amount: 10000, status: 'pending',
  client_id: 'c1', client_name: 'Awa Diallo', client_phone: '+229 01 97 00 00 00',
  prospecteur_id: 'p1', days_late: 0, ...o,
});

test('toNumber est tolérant', () => {
  assert.equal(toNumber('12.5'), 12.5);
  assert.equal(toNumber(null), 0);
  assert.equal(toNumber('abc'), 0);
  assert.equal(toNumber(undefined), 0);
});

test('formatXof arrondit et ajoute l\'unité', () => {
  assert.match(formatXof(1500000), /^1\D500\D000 XOF$/);
  assert.equal(formatXof('0'), '0 XOF');
  assert.equal(formatXof(99.6), '100 XOF');
});

test('formatDateFr sans décalage de fuseau', () => {
  assert.equal(formatDateFr('2026-10-12'), '12/10/2026');
  assert.equal(formatDateFr('2026-10-12T22:00:00Z'), '12/10/2026');
  assert.equal(formatDateFr(null), '—');
  assert.equal(formatDateFr('n/a'), '—');
});

test('displayStatus se base sur le retard réel, pas sur le statut stocké', () => {
  assert.equal(displayStatus({ days_late: 3, status: 'pending' }), 'overdue');
  assert.equal(displayStatus({ days_late: 0, status: 'partial' }), 'partial');
  assert.equal(displayStatus({ days_late: 0, status: 'pending' }), 'upcoming');
  assert.equal(displayStatus({ days_late: 0, status: 'late' }), 'upcoming');
});

test('summarize', () => {
  const s = summarize([
    mk({ days_late: 5, remaining_amount: 4000, client_id: 'c1' }),
    mk({ schedule_id: 's2', days_late: 12, remaining_amount: 6000, client_id: 'c1' }),
    mk({ schedule_id: 's3', days_late: 0, remaining_amount: 1000, client_id: 'c2' }),
  ]);
  assert.deepEqual(s, { count: 3, overdueCount: 2, totalRemaining: 11000, overdueRemaining: 10000, clients: 2, maxDaysLate: 12 });
  assert.equal(summarize([]).count, 0);
});

test('filterFollowups : filtre, recherche et tri', () => {
  const list = [
    mk({ schedule_id: 'a', days_late: 2, client_name: 'Awa Diallo' }),
    mk({ schedule_id: 'b', days_late: 30, client_name: 'Koffi Mensah', client_phone: '0707070707' }),
    mk({ schedule_id: 'c', days_late: 0, status: 'partial', client_name: 'Zoé Traoré' }),
    mk({ schedule_id: 'd', days_late: 0, client_name: 'Yao Kouassi' }),
  ];
  assert.deepEqual(filterFollowups(list, {}).map((f) => f.schedule_id), ['b', 'a', 'c', 'd']);
  assert.deepEqual(filterFollowups(list, { filter: 'overdue' }).map((f) => f.schedule_id), ['b', 'a']);
  assert.deepEqual(filterFollowups(list, { filter: 'partial' }).map((f) => f.schedule_id), ['c']);
  assert.deepEqual(filterFollowups(list, { filter: 'upcoming' }).map((f) => f.schedule_id), ['d']);
  assert.deepEqual(filterFollowups(list, { search: 'koffi' }).map((f) => f.schedule_id), ['b']);
  assert.deepEqual(filterFollowups(list, { search: '0707' }).map((f) => f.schedule_id), ['b']);
  assert.deepEqual(filterFollowups(list, { search: '  ' }).length, 4);
  assert.deepEqual(filterFollowups(list, { search: 'inconnu' }), []);
});

test('toTelHref', () => {
  assert.equal(toTelHref('+229 01 97 00 00 00'), 'tel:+22901970000 00'.replace(' ', ''));
  assert.equal(toTelHref('07 07 07 07 07'), 'tel:0707070707');
  assert.equal(toTelHref('123'), '');
  assert.equal(toTelHref(null), '');
  assert.equal(toTelHref('javascript:alert(1)'), '', 'aucun schéma dangereux : il ne reste que des chiffres');
});

test('toWhatsAppHref', () => {
  assert.equal(toWhatsAppHref('+229 97 00 00 00', 'Salut'), 'https://wa.me/22997000000?text=Salut');
  assert.equal(toWhatsAppHref('00229 97 00 00 00', 'x'), 'https://wa.me/22997000000?text=x');
  assert.equal(toWhatsAppHref('07 07 07 07 07', 'x', '225'), 'https://wa.me/225707070707?text=x');
  assert.equal(toWhatsAppHref('07 07 07 07 07', 'x'), 'https://wa.me/0707070707?text=x');
  assert.equal(toWhatsAppHref('+0707070707', 'x', '225'), 'https://wa.me/0707070707?text=x', 'un numéro avec + n\'est jamais modifié');
  assert.equal(toWhatsAppHref('12', 'x'), '');
  assert.match(toWhatsAppHref('+22997000000', 'a b&c'), /text=a%20b%26c$/);
});

test('buildReminderMessage', () => {
  const late = buildReminderMessage(mk({ days_late: 4, remaining_amount: 25000 }));
  assert.match(late, /^Bonjour Awa Diallo, petit rappel/);
  assert.match(late, /n°1 était attendue le 01\/10\/2026/);
  assert.match(late, /25\D000 XOF/);
  const soon = buildReminderMessage(mk({ days_late: 0, client_name: null }));
  assert.match(soon, /^Bonjour, petit rappel/);
  assert.match(soon, /est prévue le/);
});

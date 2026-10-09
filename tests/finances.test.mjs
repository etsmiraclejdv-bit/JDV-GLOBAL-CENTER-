import test from 'node:test';
import assert from 'node:assert/strict';
import {
  periodForPreset, isValidPeriod, parseDashboard, totalsByProspecteur, sortProspecteurRows,
  percent, commissionLabel, canSettle, unpaidCommissionTotal, formatRate,
} from '../src/lib/finances/helpers.ts';

test('periodForPreset : mois courant, mois dernier, 3 mois, année', () => {
  const d = new Date(2026, 9, 15); // 15 octobre 2026
  assert.deepEqual(periodForPreset('month', d), { start: '2026-10-01', end: '2026-10-15' });
  assert.deepEqual(periodForPreset('lastMonth', d), { start: '2026-09-01', end: '2026-09-30' });
  assert.deepEqual(periodForPreset('last3Months', d), { start: '2026-08-01', end: '2026-10-15' });
  assert.deepEqual(periodForPreset('year', d), { start: '2026-01-01', end: '2026-10-15' });
});

test('periodForPreset : passages de janvier et février bissextile', () => {
  const jan = new Date(2027, 0, 10);
  assert.deepEqual(periodForPreset('lastMonth', jan), { start: '2026-12-01', end: '2026-12-31' });
  assert.deepEqual(periodForPreset('last3Months', jan), { start: '2026-11-01', end: '2027-01-10' });
  const mar = new Date(2028, 2, 5);
  assert.deepEqual(periodForPreset('lastMonth', mar), { start: '2028-02-01', end: '2028-02-29' });
});

test('isValidPeriod', () => {
  assert.equal(isValidPeriod('2026-10-01', '2026-10-31'), true);
  assert.equal(isValidPeriod('2026-10-05', '2026-10-05'), true);
  assert.equal(isValidPeriod('2026-10-31', '2026-10-01'), false, 'fin avant début');
  assert.equal(isValidPeriod('2026-02-30', '2026-03-05'), false, 'date inexistante');
  assert.equal(isValidPeriod('2026/10/01', '2026-10-31'), false, 'mauvais format');
  assert.equal(isValidPeriod('', ''), false);
  assert.equal(isValidPeriod('2015-01-01', '2026-01-01'), false, 'plus de 5 ans');
});

test('parseDashboard : valeurs manquantes ou invalides valent 0', () => {
  const d = parseDashboard({ period_start: '2026-10-01', sales_total: '125000.50', cash_collected: null, commission_unpaid: 'x' });
  assert.equal(d.periodStart, '2026-10-01');
  assert.equal(d.salesTotal, 125000.5);
  assert.equal(d.cashCollected, 0);
  assert.equal(d.commissionUnpaid, 0);
  assert.equal(d.salesCount, 0);
  assert.equal(parseDashboard(null).salesTotal, 0);
  assert.equal(parseDashboard('texte').overdueAmount, 0);
});

const row = (o) => ({ prospecteur_id: 'p', sales_count: 0, sales_total: 0, collected: 0, outstanding: 0, commission_total: 0, commission_paid: 0, commission_unpaid: 0, ...o });

test('totalsByProspecteur et tri', () => {
  const rows = [
    row({ prospecteur_id: 'b', sales_count: 2, sales_total: '1000', collected: 400, outstanding: 600, commission_total: 100, commission_paid: 40, commission_unpaid: 60 }),
    row({ prospecteur_id: 'a', sales_count: 5, sales_total: 3000, collected: 3000, commission_total: 300, commission_paid: 300 }),
    row({ prospecteur_id: 'c', sales_count: 1, sales_total: 1000 }),
  ];
  assert.deepEqual(totalsByProspecteur(rows), { salesCount: 8, salesTotal: 5000, collected: 3400, outstanding: 600, commissionTotal: 400, commissionPaid: 340, commissionUnpaid: 60 });
  assert.deepEqual(sortProspecteurRows(rows).map((r) => r.prospecteur_id), ['a', 'b', 'c']);
  assert.equal(rows[0].prospecteur_id, 'b', 'le tableau d\'origine n\'est pas modifié');
  assert.equal(totalsByProspecteur([]).salesTotal, 0);
});

test('percent est borné et sûr', () => {
  assert.equal(percent(50, 200), 25);
  assert.equal(percent(5, 0), 0);
  assert.equal(percent(300, 200), 100);
  assert.equal(percent(-5, 200), 0);
  assert.equal(percent('abc', 100), 0);
});

test('commissions : libellés et règlement', () => {
  assert.equal(commissionLabel('pending'), 'En attente');
  assert.equal(commissionLabel('inconnu'), 'inconnu');
  assert.equal(canSettle('pending'), true);
  assert.equal(canSettle('approved'), true);
  assert.equal(canSettle('paid'), false);
  assert.equal(canSettle('cancelled'), false);
  const rows = [
    { commission_id: '1', prospecteur_id: 'p', sale_id: 's', rate: 0.05, base_amount: 1000, commission_amount: 50, status: 'pending', paid_at: null },
    { commission_id: '2', prospecteur_id: 'p', sale_id: 's', rate: 5, base_amount: 2000, commission_amount: '100', status: 'approved', paid_at: null },
    { commission_id: '3', prospecteur_id: 'p', sale_id: 's', rate: 5, base_amount: 4000, commission_amount: 200, status: 'paid', paid_at: '2026-10-01' },
    { commission_id: '4', prospecteur_id: 'p', sale_id: 's', rate: 5, base_amount: 4000, commission_amount: 999, status: 'cancelled', paid_at: null },
  ];
  assert.equal(unpaidCommissionTotal(rows), 150);
});

test('formatRate accepte fraction et pourcentage', () => {
  assert.equal(formatRate(0.05), '5 %');
  assert.equal(formatRate(5), '5 %');
  assert.equal(formatRate(2.5), '2,5 %');
  assert.equal(formatRate(0.025), '2,5 %');
  assert.equal(formatRate(null), '0 %');
});

test('sortProspecteurRows tolère une vente sans prospecteur (identifiant nul)', () => {
  const rows = [row({ prospecteur_id: null, sales_total: 500 }), row({ prospecteur_id: 'z', sales_total: 500 }), row({ prospecteur_id: 'a', sales_total: 900 })];
  assert.deepEqual(sortProspecteurRows(rows).map((r) => r.prospecteur_id), ['a', null, 'z']);
});

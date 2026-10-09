import test from 'node:test';
import assert from 'node:assert/strict';
import {
  visitResultLabel, validateVisit, summarizeVisits, prospectsDueForFollowUp, mapsUrl, toDatetimeLocal, fromDatetimeLocal,
} from '../src/lib/visits/helpers.ts';

const now = new Date('2026-10-15T12:00:00Z');
const ok = {
  prospect_id: 'p1', visit_date: '2026-10-15T10:00:00Z', result: 'interested', notes: 'RAS',
  next_follow_up_at: '', address: '', latitude: null, longitude: null,
};

test('visitResultLabel', () => {
  assert.equal(visitResultLabel('sold'), 'Vente conclue');
  assert.equal(visitResultLabel('inconnu'), 'inconnu');
  assert.equal(visitResultLabel(null), '—');
});
test('validateVisit : cas valide et GPS', () => {
  assert.equal(validateVisit(ok, now), null);
  assert.equal(validateVisit({ ...ok, latitude: 6.37, longitude: 2.39 }, now), null);
  assert.equal(validateVisit({ ...ok, next_follow_up_at: '2026-10-20T09:00:00Z' }, now), null);
});
test('validateVisit : refus', () => {
  assert.match(validateVisit({ ...ok, prospect_id: '' }, now), /prospect/);
  assert.match(validateVisit({ ...ok, visit_date: 'pas une date' }, now), /invalide/);
  assert.match(validateVisit({ ...ok, visit_date: '2026-10-16T12:00:00Z' }, now), /futur/);
  assert.equal(validateVisit({ ...ok, visit_date: '2026-10-15T12:03:00Z' }, now), null, 'tolérance de 5 minutes');
  assert.match(validateVisit({ ...ok, result: '' }, now), /résultat/);
  assert.match(validateVisit({ ...ok, result: 'inventé' }, now), /résultat/);
  assert.match(validateVisit({ ...ok, notes: 'x'.repeat(2001) }, now), /trop longues/);
  assert.match(validateVisit({ ...ok, next_follow_up_at: '2026-10-15T10:00:00Z' }, now), /postérieure/);
  assert.match(validateVisit({ ...ok, next_follow_up_at: '2026-10-14T10:00:00Z' }, now), /postérieure/);
  assert.match(validateVisit({ ...ok, next_follow_up_at: 'x' }, now), /relance est invalide/);
  assert.match(validateVisit({ ...ok, latitude: 6.37, longitude: null }, now), /incomplète/);
  assert.match(validateVisit({ ...ok, latitude: 91, longitude: 2 }, now), /latitude/);
  assert.match(validateVisit({ ...ok, latitude: 6, longitude: 181 }, now), /longitude/);
  assert.match(validateVisit({ ...ok, latitude: NaN, longitude: 2 }, now), /latitude/);
});
test('summarizeVisits', () => {
  const s = summarizeVisits([
    { visit_date: '2026-10-14T10:00:00Z', prospect_id: 'a', result: 'interested' },
    { visit_date: '2026-10-10T10:00:00Z', prospect_id: 'a', result: 'sold' },
    { visit_date: '2026-10-02T10:00:00Z', prospect_id: 'b', result: 'interested' },
    { visit_date: '2026-09-28T10:00:00Z', prospect_id: 'c', result: null },
    { visit_date: 'invalide', prospect_id: 'd', result: 'sold' },
  ], now);
  assert.deepEqual(s, { total: 5, thisMonth: 3, last7Days: 2, distinctProspects: 3, byResult: { interested: 2, sold: 1, other: 1 } });
  assert.equal(summarizeVisits([], now).total, 0);
});
test('prospectsDueForFollowUp : échus, hors statuts clos, plus ancien en tête', () => {
  const list = [
    { id: 'a', status: 'new', next_follow_up_at: '2026-10-14T09:00:00Z' },
    { id: 'b', status: 'interested', next_follow_up_at: '2026-10-10T09:00:00Z' },
    { id: 'c', status: 'converted', next_follow_up_at: '2026-10-01T09:00:00Z' },
    { id: 'd', status: 'new', next_follow_up_at: '2026-10-20T09:00:00Z' },
    { id: 'e', status: 'contacted', next_follow_up_at: null },
    { id: 'f', status: 'lost', next_follow_up_at: '2026-10-01T09:00:00Z' },
  ];
  assert.deepEqual(prospectsDueForFollowUp(list, now).map((p) => p.id), ['b', 'a']);
});
test('mapsUrl', () => {
  assert.equal(mapsUrl(6.3703, 2.3912), 'https://www.google.com/maps?q=6.3703,2.3912');
  assert.equal(mapsUrl('6.37', '2.39'), 'https://www.google.com/maps?q=6.37,2.39');
  assert.equal(mapsUrl(null, 2), '');
  assert.equal(mapsUrl('', ''), '');
  assert.equal(mapsUrl(95, 2), '');
  assert.equal(mapsUrl('abc', 2), '');
});
test('conversion datetime-local <-> ISO', () => {
  const d = new Date(2026, 9, 3, 14, 5);
  assert.equal(toDatetimeLocal(d), '2026-10-03T14:05');
  assert.equal(new Date(fromDatetimeLocal('2026-10-03T14:05')).getTime(), d.getTime(), 'aller-retour sans décalage');
  assert.equal(fromDatetimeLocal(''), '');
  assert.equal(fromDatetimeLocal('n/a'), '');
});
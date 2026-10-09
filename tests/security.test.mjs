import test from 'node:test';
import assert from 'node:assert/strict';
import { sanitizeString, sanitizeEmail, sanitizeUUID, sanitizeNumber } from '../src/lib/security/sanitize.ts';
import { getClientIp } from '../src/lib/middleware/clientIp.ts';
import { checkRateLimit } from '../src/lib/middleware/memoryRateLimit.ts';

const req = (headers) => ({ headers: { get: (k) => headers[k.toLowerCase()] ?? null } });

test('sanitizeString retire les balises et garde l\'apostrophe', () => {
  assert.equal(sanitizeString("<script>alert(1)</script>N'Diaye"), "alert(1)N'Diaye");
  assert.equal(sanitizeString('a"b`c;d\\e'), 'abcde');
  assert.equal(sanitizeString(42), '');
  assert.equal(sanitizeString('x'.repeat(900)).length, 500);
});

test('sanitizeEmail', () => {
  assert.equal(sanitizeEmail('  Jean@Exemple.COM '), 'jean@exemple.com');
  assert.equal(sanitizeEmail('pas-un-email'), '');
  assert.equal(sanitizeEmail('a b@c.d'), '');
  assert.equal(sanitizeEmail(null), '');
});

test('sanitizeUUID', () => {
  assert.equal(sanitizeUUID('123e4567-e89b-12d3-a456-426614174000'), '123e4567-e89b-12d3-a456-426614174000');
  assert.equal(sanitizeUUID("1' OR '1'='1"), '');
  assert.equal(sanitizeUUID(undefined), '');
});

test('sanitizeNumber borne et gère NaN', () => {
  assert.equal(sanitizeNumber('abc'), 0);
  assert.equal(sanitizeNumber(250), 100);
  assert.equal(sanitizeNumber(-5), 0);
  assert.equal(sanitizeNumber('12.5'), 12.5);
});

test('getClientIp privilégie les en-têtes de la plateforme au x-forwarded-for forgeable', () => {
  assert.equal(getClientIp(req({ 'x-nf-client-connection-ip': '1.1.1.1', 'x-forwarded-for': '6.6.6.6' })), '1.1.1.1');
  assert.equal(getClientIp(req({ 'x-real-ip': '2.2.2.2', 'x-forwarded-for': '6.6.6.6' })), '2.2.2.2');
  assert.equal(getClientIp(req({ 'x-forwarded-for': '3.3.3.3, 4.4.4.4' })), '3.3.3.3');
  assert.equal(getClientIp(req({})), 'unknown');
});

test('limiteur mémoire : bloque au-delà de la limite puis repart après la fenêtre', async () => {
  const opts = { limit: 3, windowMs: 80 };
  assert.equal(checkRateLimit('t:a', opts).allowed, true);
  assert.equal(checkRateLimit('t:a', opts).allowed, true);
  const third = checkRateLimit('t:a', opts);
  assert.equal(third.allowed, true);
  assert.equal(third.remaining, 0);
  assert.equal(checkRateLimit('t:a', opts).allowed, false);
  assert.equal(checkRateLimit('t:autre', opts).allowed, true, 'un autre identifiant n\'est pas affecté');
  await new Promise((r) => setTimeout(r, 100));
  assert.equal(checkRateLimit('t:a', opts).allowed, true, 'la fenêtre a expiré');
});

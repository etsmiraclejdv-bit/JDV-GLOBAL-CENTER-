import test from 'node:test';
import assert from 'node:assert/strict';
import { validateNewPassword, friendlyAuthError, PASSWORD_MIN_LENGTH } from '../src/lib/security/password.ts';

test('validateNewPassword : cas valide', () => {
  assert.equal(validateNewPassword('ancien', 'NouveauMdp2026', 'NouveauMdp2026'), null);
  assert.equal(PASSWORD_MIN_LENGTH, 10);
});

test('validateNewPassword : refus', () => {
  assert.match(validateNewPassword('', 'NouveauMdp2026', 'NouveauMdp2026'), /actuel/);
  assert.match(validateNewPassword('a', 'Court1', 'Court1'), /au moins 10 caractères/);
  assert.match(validateNewPassword('a', 'uniquementlettres', 'uniquementlettres'), /lettre et un chiffre/);
  assert.match(validateNewPassword('a', '1234567890123', '1234567890123'), /lettre et un chiffre/);
  assert.match(validateNewPassword('MotDePasse123', 'MotDePasse123', 'MotDePasse123'), /différent/);
  assert.match(validateNewPassword('a', 'NouveauMdp2026', 'NouveauMdp2027'), /confirmation/);
});

test('validateNewPassword : limite bcrypt de 72 octets (accents comptés en octets)', () => {
  assert.equal(validateNewPassword('a', 'A1' + 'x'.repeat(70), 'A1' + 'x'.repeat(70)), null, '72 octets : permis');
  assert.match(validateNewPassword('a', 'A1' + 'x'.repeat(71), 'A1' + 'x'.repeat(71)), /trop long/, '73 octets : refusé');
  const accents = 'A1' + 'é'.repeat(36); // 2 + 72 octets = 74
  assert.match(validateNewPassword('a', accents, accents), /trop long/);
});

test('friendlyAuthError', () => {
  assert.equal(friendlyAuthError('Invalid login credentials'), 'Mot de passe actuel incorrect.');
  assert.match(friendlyAuthError('New password should be different from the old password.'), /différent/);
  assert.match(friendlyAuthError('Password is known to be weak and easy to guess'), /plus robuste/);
  assert.match(friendlyAuthError('email rate limit exceeded'), /Trop de tentatives/);
  assert.match(friendlyAuthError('jwt malformed at /secret/path'), /Impossible de changer/, 'aucun détail technique affiché');
  assert.match(friendlyAuthError(null), /Impossible de changer/);
});

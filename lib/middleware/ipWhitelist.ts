/**
 * Liste blanche d'IP facultative pour le webhook FedaPay.
 *
 * La sécurité repose sur la signature officielle + la relecture de la transaction auprès de FedaPay.
 * Les adresses IP de FedaPay changent : aucune liste n'est codée en dur ici.
 * Pour restreindre malgré tout, définissez FEDAPAY_IP_WHITELIST (adresses séparées par des virgules,
 * à copier depuis la documentation FedaPay).
 */
export function isFedaPayIp(ip: string): boolean {
  const envWhitelist = process.env.FEDAPAY_IP_WHITELIST;
  if (!envWhitelist) return true;
  const allowed = envWhitelist.split(',').map(s => s.trim()).filter(Boolean);
  return allowed.includes(ip);
}

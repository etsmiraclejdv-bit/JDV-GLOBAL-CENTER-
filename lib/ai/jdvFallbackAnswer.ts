// Réponses de l'assistant JDV CRM sans clé IA : base de connaissances + contexte CRM réel.
type Row = { scope?: string | null; topic?: string | null; content?: string | null };
type PageContext = { pathname?: string; section?: string };
const STOP = new Set(['les','des','une','aux','que','qui','quoi','quel','quels','quelle','quelles','comment','est','sont','mon','mes','ton','tes','votre','vos','notre','nos','pour','par','sur','dans','avec','sans','pas','plus','moins','faire','fait','dois','peut','peux','puis','alors','donc','mais','ainsi','cela','cette','ces','cet','il','elle','nous','vous','ils','elles','tout','tous','aussi','etre','avoir','veux','voir','explique','expliquer','moi','svp','merci','bonjour','salut']);
const norm = (s: unknown) => String(s ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
const tokens = (s: unknown) => Array.from(new Set(norm(s).split(/[^a-z0-9]+/).filter(t => t.length >= 3 && !STOP.has(t))));
const NEXT_STEPS: Array<[RegExp,string]> = [
 [/retour/,'Après un retour, vérifiez la réintégration en stock, puis la clôture journalière.'],
 [/cloture|inventaire|tracabilite/,'Une fois la clôture faite, relisez le journal de stock et les rapports.'],
 [/transfert|sous.?entrepot|sous.?branche/,'Ensuite, contrôlez le stock de chaque sous-entrepôt et son responsable.'],
 [/entrepot|agence/,'Ensuite, définissez les sous-entrepôts, leurs responsables et les prospecteurs rattachés.'],
 [/stock|approvisionnement|fournisseur/,'Surveillez les seuils minimum, puis préparez un approvisionnement ou un transfert si besoin.'],
 [/article|catalogue|categorie|unite/,'Rattachez ensuite chaque article à un entrepôt avec son stock minimum.'],
 [/vente|paiement|credit/,'Après la vente, contrôlez l’impact sur le stock et l’encaissement.'],
 [/client|portefeuille/,'Ensuite, enregistrez une vente pour ce client.'],
 [/prospect/,'Une fois le prospect qualifié, convertissez-le en client.']
];
export function buildKnowledgeAnswer(input: { question: string; pageContext?: PageContext; knowledge: Row[]; live: any; base: { mission: string; modules: string[] } }): string {
 const q=tokens(input.question), page=tokens(`${input.pageContext?.section ?? ''} ${input.pageContext?.pathname ?? ''}`);
 const scored=(input.knowledge??[]).map(r=>{const topic=norm(r.topic),content=norm(r.content);let score=0;for(const t of q){if(topic.includes(t))score+=3;if(content.includes(t))score+=1;}if(score>0)for(const t of page)if(topic.includes(t))score+=1;return {r,score};}).filter(x=>x.score>0).sort((a,b)=>b.score-a.score).slice(0,3);
 const parts:string[]=[];
 if(scored.length){for(const {r} of scored){const body=String(r.content??'').trim();parts.push(`${r.topic??'Information'}\n${body.length>800?body.slice(0,800).trimEnd()+'…':body}`);}}
 else parts.push(`Je n’ai pas de fiche précise sur ce point. JDV CRM couvre notamment : ${input.base.modules.slice(0,8).join(' ; ')}. Reformulez votre question avec le nom du module (par exemple « retours », « stock », « sous-entrepôt »).`);
 const live=input.live, qn=norm(input.question);
 if(live?.mode==='authenticated'){
  const lines:string[]=[];
  const wantsStock=/stock|inventaire|quantite|rupture|seuil/.test(qn), wantsCounts=/combien|prospect|client|vente|total/.test(qn), wantsWarehouse=/entrepot|agence|sous|branche|responsable|chef/.test(qn), wantsArticle=/article|produit|catalogue|reference/.test(qn);
  if(wantsCounts)lines.push(`Votre organisation compte ${live.counts?.prospects??0} prospect(s), ${live.counts?.clients??0} client(s) et ${live.counts?.sales??0} vente(s).`);
  if(wantsWarehouse){const w=(live.warehouses??[]).filter((x:any)=>x.active!==false).map((x:any)=>x.name||x.code).filter(Boolean);const s=(live.subwarehouses??[]).filter((x:any)=>x.active!==false).map((x:any)=>x.name||x.code).filter(Boolean);lines.push(w.length?`Entrepôts actifs : ${w.slice(0,10).join(', ')}.`:'Aucun entrepôt actif n’est enregistré : c’est un point à vérifier.');if(s.length)lines.push(`Sous-entrepôts actifs : ${s.slice(0,12).join(', ')}.`);}
  if(wantsArticle&&(live.article_matches??[]).length)lines.push('Articles correspondant à votre question : '+live.article_matches.slice(0,8).map((a:any)=>`${a.code??''} ${a.name??''}`.trim()).join(' ; ')+'.');
  if(wantsStock){const low=(live.inventory??[]).filter((x:any)=>Number(x.minimum)>0&&Number(x.quantity)<=Number(x.minimum));lines.push(low.length?`Articles au niveau minimum ou en dessous : ${low.slice(0,8).map((x:any)=>`${x.article??'article'} (${x.quantity}/${x.minimum})`).join(', ')}.`:'Aucun article n’est actuellement sous son seuil minimum dans les données disponibles.');}
  if(lines.length)parts.push('Dans votre organisation :\n'+lines.join('\n'));
 }
 const next=NEXT_STEPS.find(([re])=>re.test(qn)||scored.some(({r})=>re.test(norm(r.topic))));
 if(next)parts.push(`Étape suivante : ${next[1]}`);
 parts.push('(Mode guide : l’assistant IA complet n’est pas activé ; cette réponse vient de la base de connaissances JDV CRM.)');
 return parts.join('\n\n');
}

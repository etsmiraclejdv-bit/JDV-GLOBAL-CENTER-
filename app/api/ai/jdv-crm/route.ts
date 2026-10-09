import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { checkRateLimitShared, getClientIp } from '@/lib/middleware/rateLimiter';
import { sanitizeString } from '@/lib/security/sanitize';
import { JDV_CRM_KNOWLEDGE } from '@/lib/ai/jdvCrmKnowledge';
import { buildKnowledgeAnswer } from '@/lib/ai/jdvFallbackAnswer';

type OrgMember = { organization_id: string; role: string };
type PageContext = { pathname?: string; section?: string };
const safeLike = (value: string) => value.replace(/[%,()]/g, ' ').replace(/'/g, "''").trim().slice(0, 80);

export async function POST(req: NextRequest) {
  const ip = getClientIp(req);
  const rl = await checkRateLimitShared('jdv-ai:' + ip, { limit: 20, windowMs: 15 * 60 * 1000 });
  if (!rl.allowed) return NextResponse.json({ error: 'Trop de demandes. Réessayez dans quelques minutes.' }, { status: 429 });

  try {
    const body = await req.json();
    const raw = Array.isArray(body?.messages) ? body.messages : [];
    const messages = raw.slice(-12).map((m: any) => ({
      role: m?.role === 'user' ? 'user' : 'assistant',
      content: sanitizeString(m?.content).slice(0, 6000),
    })).filter((m: any) => m.content);
    if (!messages.length) return NextResponse.json({ error: 'Question vide.' }, { status: 400 });

    const pageContext: PageContext = {
      pathname: sanitizeString(body?.page_context?.pathname).slice(0, 180),
      section: sanitizeString(body?.page_context?.section).slice(0, 120),
    };
    const lastUser = messages.filter((m: any) => m.role === 'user').at(-1)?.content || '';
    const apiKey = process.env.OPENAI_API_KEY;

    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!supabaseUrl || !serviceKey || !anonKey) {
      return NextResponse.json({ error: 'Configuration Supabase serveur incomplète.' }, { status: 503 });
    }

    const admin = createClient(supabaseUrl, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
    const { data: knowledgeRows, error: knowledgeError } = await admin
      .from('ai_jdv_knowledge').select('scope,topic,content').eq('active', true).order('scope').order('topic');
    if (knowledgeError) throw knowledgeError;
    const knowledgeContext = knowledgeRows ?? [];

    const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
    let liveContext: any = { mode: 'public', synchronized_at: new Date().toISOString(), page: pageContext };

    if (token) {
      const userClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: 'Bearer ' + token } },
        auth: { autoRefreshToken: false, persistSession: false },
      });
      const { data: { user } } = await userClient.auth.getUser(token);
      if (user) {
        const { data: members, error: memberError } = await admin
          .from('organization_members').select('organization_id,role')
          .eq('user_id', user.id).eq('status', 'active');
        if (memberError) throw memberError;

        // Ne charger que l’organisation principale pour éviter tout mélange entre organisations.
        const primaryMember = (members as OrgMember[] | null)?.[0];
        if (primaryMember) {
          const primary = primaryMember.organization_id;
          const [{ data: org }, { data: warehouses }, { data: subwarehouses }, { data: articles },
            { count: prospectCount }, { count: clientCount }, { count: saleCount }] = await Promise.all([
            admin.from('organizations').select('id,name,legal_name,country,currency,timezone,status,subscription_status').eq('id', primary).maybeSingle(),
            admin.from('warehouses').select('id,code,name,city,active,manager_user_id').eq('organization_id', primary).order('name').limit(100),
            admin.from('warehouse_subwarehouses').select('id,code,name,parent_warehouse_id,city,zone,active,manager_user_id').eq('organization_id', primary).order('name').limit(200),
            admin.from('articles').select('id,code,name,description,category,unit,active').eq('organization_id', primary).eq('active', true).order('updated_at', { ascending: false }).limit(300),
            admin.from('prospects').select('*', { count: 'exact', head: true }).eq('organization_id', primary),
            admin.from('clients').select('*', { count: 'exact', head: true }).eq('organization_id', primary),
            admin.from('sales').select('*', { count: 'exact', head: true }).eq('organization_id', primary),
          ]);

          let articleMatches: any[] = [];
          const terms = lastUser.split(/\s+/).map((x: string) => safeLike(x)).filter((x: string) => x.length >= 3).slice(0, 6);
          const filters = terms.flatMap((term: string) => ['code.ilike.%' + term + '%', 'name.ilike.%' + term + '%']).join(',');
          if (filters) {
            const { data: matches } = await admin.from('articles').select('id,code,name,description,category,unit,active')
              .eq('organization_id', primary).eq('active', true).or(filters).limit(20);
            articleMatches = matches ?? [];
          }
          const articleMap = new Map((articles ?? []).map((a: any) => [a.id, a]));
          const { data: inventory } = await admin.from('warehouse_inventory')
            .select('warehouse_id,subwarehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at')
            .eq('organization_id', primary).limit(1000);

          liveContext = {
            mode: 'authenticated',
            synchronized_at: new Date().toISOString(),
            page: pageContext,
            user: {
              role: primaryMember.role ?? 'unknown',
              permissions_hint: primaryMember.role === 'business_admin' ? 'administration complète'
                : primaryMember.role === 'manager' || primaryMember.role === 'supervisor' ? 'pilotage opérationnel'
                : 'accès limité selon permissions',
            },
            organization: org ?? { id: primary },
            warehouses: warehouses ?? [],
            subwarehouses: subwarehouses ?? [],
            articles: (articles ?? []).map((a: any) => ({ code: a.code, name: a.name, description: a.description, category: a.category, unit: a.unit })),
            article_matches: articleMatches.map((a: any) => ({ code: a.code, name: a.name, description: a.description, category: a.category, unit: a.unit })),
            inventory: (inventory ?? []).map((x: any) => ({
              warehouse_id: x.warehouse_id, subwarehouse_id: x.subwarehouse_id,
              article: x.article_id ? articleMap.get(x.article_id)?.code ?? null : null,
              quantity: x.quantity, reserved: x.reserved_quantity, minimum: x.minimum_quantity, updated_at: x.updated_at,
            })),
            counts: { prospects: prospectCount ?? 0, clients: clientCount ?? 0, sales: saleCount ?? 0 },
          };
        }
      }
    }

    // Réponse de secours utile lorsque la clé OpenAI n'est pas configurée.
    if (!apiKey) {
      const content = buildKnowledgeAnswer({
        question: lastUser, pageContext, knowledge: knowledgeContext as any[], live: liveContext,
        base: { mission: JDV_CRM_KNOWLEDGE.mission, modules: JDV_CRM_KNOWLEDGE.modules },
      });
      return NextResponse.json({ content, synchronized_at: liveContext.synchronized_at, mode: 'knowledge' });
    }

    const system = "Tu es l’Agent IA officiel de JDV CRM, formateur, copilote métier, conseiller opérationnel et guide de navigation. Explique le CRM de bout en bout avec une logique progressive et des transitions naturelles. Réponds en français professionnel, clair et pédagogique. Tiens compte de la section actuellement ouverte. Pour chaque procédure importante : objectif, étapes, contrôles, puis lien vers l’étape suivante. Utilise des transitions naturelles. Pour les articles, aide l’administrateur à comprendre catégorie, unité, usage, stock, vente, retour et contrôle. Adapte les exemples au secteur demandé à partir de la base sectorielle, sans inventer de caractéristiques techniques. Le contexte CRM ci-dessous est la source de vérité : si une donnée n’y figure pas, dis-le. Ne prétends jamais avoir effectué une action. Ne révèle jamais secrets, clés, données privées ou informations d’une autre organisation. Personnalise selon le rôle et les données de la seule organisation affichée. Signale les incohérences et les données manquantes. Pour les actions sensibles, explique la procédure sans simuler l’exécution. Base fonctionnelle : " + JSON.stringify(JDV_CRM_KNOWLEDGE) + " Base de connaissances sectorielle et modules : " + JSON.stringify(knowledgeContext) + " Contexte CRM synchronisé : " + JSON.stringify(liveContext);

    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + apiKey },
      body: JSON.stringify({ model: process.env.OPENAI_MODEL || 'gpt-6-luna', instructions: system, input: messages }),
    });
    const json = await response.json();
    if (!response.ok) return NextResponse.json({ error: json?.error?.message || 'Le service IA est indisponible.' }, { status: 502 });
    return NextResponse.json({ content: json.output_text || 'Je n’ai pas pu produire une réponse. Pouvez-vous reformuler votre question ?', synchronized_at: liveContext.synchronized_at });
  } catch (e) {
    return NextResponse.json({ error: e instanceof Error ? e.message : 'Erreur inattendue.' }, { status: 500 });
  }
}
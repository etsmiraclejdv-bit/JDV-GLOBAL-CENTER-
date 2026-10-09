import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "POST requis" }), { status: 405, headers: cors });

  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Authentification requise" }), { status: 401, headers: cors });
  }

  const openaiKey = Deno.env.get("OPENAI_API_KEY");
  if (!openaiKey) {
    return new Response(JSON.stringify({ error: "OPENAI_API_KEY non configurée dans les secrets de la fonction" }), { status: 503, headers: cors });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } }
  );

  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) return new Response(JSON.stringify({ error: "Session invalide" }), { status: 401, headers: cors });

  let body: any;
  try { body = await req.json(); } catch {
    return new Response(JSON.stringify({ error: "JSON invalide" }), { status: 400, headers: cors });
  }

  const conversationId = body?.conversation_id;
  const message = typeof body?.message === "string" ? body.message.trim() : "";
  const requestedModel = typeof body?.model === "string" && body.model.trim() ? body.model.trim() : null;
  const scope = typeof body?.scope === "string" ? body.scope.trim().toLowerCase() : "";
  const query = typeof body?.query === "string" ? body.query.trim() : null;

  if (!conversationId || !message) {
    return new Response(JSON.stringify({ error: "conversation_id et message sont obligatoires" }), { status: 400, headers: cors });
  }

  if (scope && !["clients", "products", "sales", "prospects", "wallets"].includes(scope)) {
    return new Response(JSON.stringify({ error: "Scope IA non autorisé" }), { status: 400, headers: cors });
  }

  const { data: rateLimit, error: rateError } = await supabase.rpc("ai_check_rate_limit", { p_max_requests: 30, p_window_seconds: 60 });
  if (rateError) return new Response(JSON.stringify({ error: "Contrôle de fréquence indisponible" }), { status: 503, headers: cors });
  if (!rateLimit?.allowed) return new Response(JSON.stringify({ error: "Trop de requêtes IA. Réessayez dans quelques instants.", rate_limit: rateLimit }), { status: 429, headers: cors });

  const { data: policy, error: policyError } = await supabase.rpc("ai_get_policy", { p_model: requestedModel ?? "gpt-5.6-luna" });
  if (policyError) return new Response(JSON.stringify({ error: "Politique IA indisponible" }), { status: 503, headers: cors });
  if (!policy.enabled) return new Response(JSON.stringify({ error: "JDV IA est désactivée pour cette organisation" }), { status: 403, headers: cors });

  const model = requestedModel || policy.default_model;
  if (!policy.model_allowed) {
    return new Response(JSON.stringify({ error: "Modèle IA non autorisé", requested_model: model, default_model: policy.default_model, allowed_models: policy.allowed_models }), { status: 400, headers: cors });
  }
  if (!policy.within_quota) return new Response(JSON.stringify({ error: "Quota IA mensuel atteint", policy }), { status: 429, headers: cors });

  const { data: userMsg, error: userMsgError } = await supabase.rpc("ai_add_message", {
    p_conversation_id: conversationId, p_role: "user", p_content: message, p_provider: "openai", p_model: model
  });
  if (userMsgError) return new Response(JSON.stringify({ error: userMsgError.message }), { status: 403, headers: cors });

  const { data: context, error: contextError } = await supabase.rpc("ai_get_context");
  if (contextError) return new Response(JSON.stringify({ error: "Contexte JDV indisponible" }), { status: 500, headers: cors });

  let businessData: any = null;
  if (scope) {
    const { data, error } = await supabase.rpc("ai_query_business", { p_scope: scope, p_query: query, p_limit: 20 });
    if (error) return new Response(JSON.stringify({ error: "Données métier indisponibles" }), { status: 403, headers: cors });
    businessData = data;
  }

  const { data: history, error: historyError } = await supabase
    .from("ai_messages")
    .select("role,content")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true })
    .limit(50);

  if (historyError) return new Response(JSON.stringify({ error: historyError.message }), { status: 500, headers: cors });

  const input = [
    {
      role: "system",
      content: "Tu es JDV IA, assistant interne de JDV GLOBAL CENTER. Réponds en français par défaut. Utilise uniquement le contexte et les données JDV fournis. N'invente aucun chiffre, client, produit, vente, prospect ou solde. Ne révèle jamais de secret, clé API, token ou donnée clinique confidentielle. Si une donnée n'est pas fournie, dis-le clairement. Contexte JDV: " +
        JSON.stringify(context) +
        (businessData ? "\nDonnées métier autorisées: " + JSON.stringify(businessData) : "")
    },
    ...(history ?? [])
      .map((m: any) => ({ role: m.role === "tool" ? "assistant" : m.role, content: m.content }))
      .filter((m: any) => ["user", "assistant", "system"].includes(m.role))
  ];

  const aiRes = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: { "Authorization": `Bearer ${openaiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model, input })
  });

  const aiJson = await aiRes.json();
  if (!aiRes.ok) {
    return new Response(JSON.stringify({ error: "Fournisseur IA indisponible", provider_status: aiRes.status }), { status: 502, headers: cors });
  }

  const answer = typeof aiJson?.output_text === "string"
    ? aiJson.output_text
    : (aiJson?.output ?? [])
        .flatMap((item: any) => item?.content ?? [])
        .map((part: any) => part?.text ?? "")
        .join("");

  if (!answer.trim()) return new Response(JSON.stringify({ error: "Réponse IA vide" }), { status: 502, headers: cors });

  const usage = aiJson?.usage ?? {};
  const inputTokens = Number(usage.input_tokens ?? 0);
  const outputTokens = Number(usage.output_tokens ?? 0);

  const { data: estimatedCost, error: costError } = await supabase.rpc("ai_estimate_cost", {
    p_provider: "openai", p_model: model, p_tokens_input: inputTokens, p_tokens_output: outputTokens
  });
  if (costError) return new Response(JSON.stringify({ error: "Calcul du coût IA indisponible" }), { status: 503, headers: cors });

  const { error: assistantError } = await supabase.rpc("ai_add_message", {
    p_conversation_id: conversationId, p_role: "assistant", p_content: answer, p_provider: "openai",
    p_model: model, p_token_input: inputTokens, p_token_output: outputTokens
  });
  if (assistantError) return new Response(JSON.stringify({ error: assistantError.message }), { status: 500, headers: cors });

  const { error: usageError } = await supabase.rpc("ai_record_usage", {
    p_provider: "openai", p_model: model, p_tokens_input: inputTokens, p_tokens_output: outputTokens,
    p_estimated_cost: Number(estimatedCost ?? 0), p_conversation_id: conversationId,
    p_request_reference: aiJson?.id ?? null
  });
  if (usageError) return new Response(JSON.stringify({ error: usageError.message }), { status: 500, headers: cors });

  await supabase.rpc("ai_log_access", {
    p_action_type: "message", p_scope: scope || null, p_conversation_id: conversationId,
    p_result_count: businessData?.count ?? null, p_success: true
  });

  return new Response(JSON.stringify({
    conversation_id: conversationId, message_id: userMsg, answer, model,
    usage: { input_tokens: inputTokens, output_tokens: outputTokens, estimated_cost: Number(estimatedCost ?? 0) }
  }), { status: 200, headers: cors });
});

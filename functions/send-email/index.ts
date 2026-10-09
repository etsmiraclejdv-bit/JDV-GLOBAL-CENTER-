import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

declare const Deno: { env: { get(key: string): string | undefined } };

const ADMIN_ROLES = ["business_admin", "admin"];

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { status: 200, headers: CORS_HEADERS });
  if (req.method !== "POST") return json({ error: "Méthode non autorisée" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const siteUrl = (Deno.env.get("SITE_URL") ?? "https://imaginative-rabanadas-afe4e7.netlify.app").replace(/\/+$/, "");
  const from = Deno.env.get("EMAIL_FROM") ?? "JDV CRM <onboarding@resend.dev>";

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("[send-email] configuration Supabase incomplète");
    return json({ error: "Service email non configuré" }, 500);
  }

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) return json({ error: "Authentification requise" }, 401);

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: caller, error: callerError } = await supabase.auth.getUser(token);
  if (callerError || !caller?.user) return json({ error: "Session invalide" }, 401);

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let payload: { type?: unknown; to?: unknown; application_id?: unknown; company_name?: unknown; professional_email?: unknown };
  try { payload = await req.json(); } catch { return json({ error: "Requête invalide" }, 400); }

  const type = String(payload.type ?? "");
  if (!["prospecteur_welcome", "company_approval", "company_received"].includes(type)) {
    return json({ error: "Type d'email non pris en charge" }, 400);
  }

  if (type === "company_received") {
    const applicationId = typeof payload.application_id === "string" ? payload.application_id : "";
    if (!/^[0-9a-f-]{36}$/i.test(applicationId)) return json({ error: "Application invalide" }, 400);

    const { data: application, error: appError } = await supabaseAdmin
      .from("organization_applications")
      .select("id,applicant_user_id,professional_email,company_name,representative_first_name,status")
      .eq("id", applicationId).maybeSingle();

    if (appError || !application) return json({ error: "Demande introuvable" }, 404);
    if (application.applicant_user_id !== caller.user.id) return json({ error: "Accès refusé" }, 403);
    if (!["pending","submitted","under_review"].includes(String(application.status))) {
      return json({ error: "Statut de demande invalide" }, 409);
    }

    const recipient = application.professional_email;
    const name = application.representative_first_name || "Responsable";
    const html = `
      <div style="font-family:Arial,sans-serif;max-width:620px;margin:0 auto;background:#0A1628;color:#E2E8F0;padding:40px;border-radius:14px">
        <h1 style="color:#D4AF37;text-align:center;margin:0 0 8px">JDV CRM</h1>
        <p style="color:#718096;text-align:center;margin:0 0 28px">Bienvenue sur la plateforme JDV CRM</p>
        <h2 style="color:#fff">Bienvenue ${escapeHtml(name)} !</h2>
        <p style="color:#A0AEC0;line-height:1.7">Nous avons bien reçu votre demande de création de compte d'entreprise pour <strong style="color:#fff">${escapeHtml(application.company_name)}</strong>.</p>
        <p style="color:#A0AEC0;line-height:1.7">Votre dossier va maintenant être examiné par le Concepteur JDV CRM.</p>
        <p style="color:#A0AEC0;line-height:1.7"><strong style="color:#fff">Vous recevrez prochainement un message de confirmation</strong> contenant les instructions pour terminer la création de votre entreprise et activer votre espace.</p>
        <div style="margin:28px 0;padding:18px;border:1px solid #D4AF37;border-radius:10px;color:#A0AEC0">
          <strong style="color:#D4AF37">Ne créez pas un nouveau dossier.</strong><br/>
          Conservez simplement cet email et attendez le message de confirmation JDV CRM.
        </div>
        <p style="color:#718096;font-size:12px;text-align:center;margin-top:28px">© ${new Date().getFullYear()} JDV CRM</p>
      </div>`;

    if (!resendKey) return json({ error: "Service email non configuré" }, 500);
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from,
        to: [recipient],
        subject: "Bienvenue sur JDV CRM — Votre demande a bien été reçue",
        html,
      }),
    });
    if (!res.ok) {
      const details = await res.text();
      console.error("[send-email] réception entreprise refusée", res.status, details);
      return json({ error: "Envoi impossible" }, 502);
    }
    return json({ success: true, type, email: recipient });
  }

  if (type === "company_approval") {
    const applicationId = typeof payload.application_id === "string" ? payload.application_id : "";
    if (!/^[0-9a-f-]{36}$/i.test(applicationId)) return json({ error: "Application invalide" }, 400);

    const { data: sa } = await supabaseAdmin
      .from("super_admins").select("id,status,actif")
      .eq("user_id", caller.user.id).eq("status", "active").limit(1).maybeSingle();

    if (!sa || sa.actif === false) return json({ error: "Accès refusé" }, 403);

    const { data: application, error: appError } = await supabaseAdmin
      .from("organization_applications")
      .select("id,applicant_user_id,professional_email,company_name,representative_first_name,representative_last_name,status")
      .eq("id", applicationId).maybeSingle();

    if (appError || !application) return json({ error: "Demande introuvable" }, 404);
    if (application.status !== "approved_pending_email") {
      return json({ error: "La demande doit être approuvée avant l'envoi du lien" }, 409);
    }

    const redirectTo = `${siteUrl}/business/finalize-account?application_id=${encodeURIComponent(applicationId)}`;
    let finalizationUrl: string | null = null;

    const { data: linkData, error: linkError } = await supabaseAdmin.auth.admin.generateLink({
      type: "recovery",
      email: application.professional_email,
      options: { redirectTo },
    });
    if (!linkError) finalizationUrl = linkData?.properties?.action_link ?? null;

    if (!finalizationUrl) {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(
        application.professional_email,
        { redirectTo },
      );
      if (resetError) {
        console.error("[send-email] fallback Auth reset échoué", resetError.message);
        return json({ error: "Impossible de générer le lien de finalisation" }, 502);
      }
    }

    if (resendKey && finalizationUrl) {
      const name = `${application.representative_first_name ?? ""} ${application.representative_last_name ?? ""}`.trim() || "Responsable";
      const html = `
        <div style="font-family:Arial,sans-serif;max-width:620px;margin:0 auto;background:#0A1628;color:#E2E8F0;padding:40px;border-radius:14px">
          <h1 style="color:#D4AF37;text-align:center;margin:0 0 8px">JDV CRM</h1>
          <p style="color:#718096;text-align:center;margin:0 0 28px">Validation de votre entreprise</p>
          <h2 style="color:#fff">Félicitations ${escapeHtml(name)} !</h2>
          <p style="color:#A0AEC0;line-height:1.7">Le Concepteur de JDV CRM a validé la demande de création de <strong style="color:#fff">${escapeHtml(application.company_name)}</strong>.</p>
          <p style="color:#A0AEC0;line-height:1.7">Votre prochaine étape est de finaliser votre compte. Cliquez sur le bouton ci-dessous pour définir votre mot de passe et activer votre espace entreprise.</p>
          <div style="text-align:center;margin:32px 0"><a href="${escapeHtml(finalizationUrl)}" style="background:#D4AF37;color:#0A1628;padding:14px 28px;border-radius:9px;text-decoration:none;font-weight:700">Finaliser mon compte</a></div>
          <p style="color:#718096;font-size:12px;line-height:1.5">Ce lien est personnel. Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
          <p style="color:#718096;font-size:12px;text-align:center;margin-top:28px">© ${new Date().getFullYear()} JDV CRM</p>
        </div>`;

      const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from,
          to: [application.professional_email],
          subject: `JDV CRM — Votre entreprise ${application.company_name} est validée`.slice(0, 200),
          html,
        }),
      });
      if (!res.ok) {
        console.error("[send-email] Resend a refusé l'envoi", res.status);
        return json({ error: "Envoi impossible" }, 502);
      }
    }

    if (!resendKey) {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(
        application.professional_email,
        { redirectTo },
      );
      if (resetError) {
        console.error("[send-email] envoi Auth de secours échoué", resetError.message);
        return json({ error: "Impossible d'envoyer le lien de finalisation" }, 502);
      }
    }

    return json({ success: true, type, email: application.professional_email });
  }

  const to = typeof payload.to === "string" ? payload.to.trim().toLowerCase().slice(0, 254) : "";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) return json({ error: "Destinataire invalide" }, 400);

  const { data: memberships } = await supabase
    .from("organization_members").select("organization_id")
    .eq("user_id", caller.user.id).eq("status", "active").in("role", ADMIN_ROLES);
  const orgIds = (memberships ?? []).map((m: { organization_id: string }) => m.organization_id);
  if (orgIds.length === 0) return json({ error: "Accès refusé" }, 403);

  const { data: prospecteur } = await supabase
    .from("prospecteurs").select("first_name,last_name,organization_id")
    .eq("email", to).in("organization_id", orgIds).limit(1).maybeSingle();
  if (!prospecteur) return json({ error: "Destinataire non autorisé" }, 403);

  const { data: org } = await supabase.from("organizations").select("name").eq("id", prospecteur.organization_id).maybeSingle();
  const name = `${prospecteur.first_name ?? ""} ${prospecteur.last_name ?? ""}`.trim() || to;
  const orgName = org?.name ?? "votre entreprise";
  const loginUrl = `${siteUrl}/terrain/login`;

  const html = `
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#0A1628;color:#E2E8F0;padding:40px;border-radius:12px">
      <h1 style="color:#D4AF37;font-size:28px;margin:0 0 8px;text-align:center">JDV CRM</h1>
      <p style="color:#718096;font-size:14px;text-align:center;margin:0 0 32px">Portail Prospecteur</p>
      <h2 style="color:#fff;font-size:20px">Bienvenue, ${escapeHtml(name)} !</h2>
      <p style="color:#A0AEC0;line-height:1.6">Un compte prospecteur a été créé pour vous sur JDV CRM par l'entreprise <strong style="color:#fff">${escapeHtml(orgName)}</strong>.</p>
      <p style="color:#A0AEC0;line-height:1.6">Votre identifiant est cette adresse email : <strong style="color:#fff">${escapeHtml(to)}</strong>. Votre administrateur vous communiquera votre mot de passe de façon sécurisée.</p>
      <div style="text-align:center;margin:32px 0"><a href="${escapeHtml(loginUrl)}" style="background:#D4AF37;color:#0A1628;padding:14px 32px;border-radius:8px;text-decoration:none;font-weight:bold">Se connecter</a></div>
      <p style="color:#718096;font-size:12px;text-align:center">© ${new Date().getFullYear()} JDV CRM</p>
    </div>`;

  if (!resendKey) return json({ error: "Service email non configuré" }, 500);
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from, to: [to], subject: `Bienvenue sur JDV CRM — ${orgName}`.slice(0, 200), html }),
  });
  if (!res.ok) return json({ error: "Envoi impossible" }, 502);
  return json({ success: true });
});

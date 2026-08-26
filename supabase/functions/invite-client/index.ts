// ============================================================
// BlueWave Digital - Edge Function: invite-client
// Securely creates a client's login + client record, links them,
// and emails a branded "set your password" invite via Resend.
//
// Only callable by a logged-in admin/staff user.
// Holds the SERVICE ROLE key as a secret (never exposed to the browser).
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SERVICE_KEY  = Deno.env.get("SERVICE_ROLE_KEY");
    const ANON_KEY     = Deno.env.get("SUPABASE_ANON_KEY");
    const RESEND_KEY   = Deno.env.get("RESEND_API_KEY");
    const FROM_EMAIL   = Deno.env.get("FROM_EMAIL") || "BlueWave Digital <hello@bluewaveagency.online>";
    const SITE_URL     = Deno.env.get("SITE_URL") || "https://bluewaveagency.online";

    // 1) Verify the CALLER is a logged-in admin/staff
    const authHeader = req.headers.get("Authorization") || "";
    const caller = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: userData } = await caller.auth.getUser();
    if (!userData?.user) return json({ error: "Not authenticated" }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_KEY);
    const { data: prof } = await admin.from("profiles").select("role").eq("id", userData.user.id).single();
    if (!prof || (prof.role !== "admin" && prof.role !== "staff"))
      return json({ error: "Not authorised" }, 403);

    // 2) Read input
    const { name, email, country, phone } = await req.json();
    if (!name || !email) return json({ error: "Name and email are required" }, 400);

    // 3) Create the client record
    const { data: client, error: cErr } = await admin
      .from("clients")
      .insert({ name, email, country, phone })
      .select()
      .single();
    if (cErr) return json({ error: "Could not create client: " + cErr.message }, 400);

    // 4) Invite the user by email (creates auth user + sends set-password link)
    const redirectTo = `${SITE_URL}/set-password/`;
    const { data: invited, error: iErr } = await admin.auth.admin.inviteUserByEmail(email, {
      redirectTo,
      data: { full_name: name },
    });

    let actionLink = null;
    if (iErr) {
      // If the user already exists, generate a recovery link instead
      const { data: linkData, error: lErr } = await admin.auth.admin.generateLink({
        type: "recovery", email, options: { redirectTo },
      });
      if (lErr) return json({ error: "Could not invite user: " + iErr.message }, 400);
      actionLink = linkData?.properties?.action_link || null;
    }

    // 5) Find the user id and link + set role = client
    let userId = invited?.user?.id;
    if (!userId) {
      const { data: list } = await admin.auth.admin.listUsers();
      const u = list?.users?.find((x) => x.email?.toLowerCase() === email.toLowerCase());
      userId = u?.id;
    }
    if (userId) {
      await admin.from("profiles").update({ role: "client", client_id: client.id, full_name: name }).eq("id", userId);
    }

    // 6) Send a branded invite email via Resend (in addition to Supabase's, or as the main one)
    if (RESEND_KEY) {
      const link = actionLink || `${SITE_URL}/login/`;
      const html = brandedEmail(name, link, SITE_URL);
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: FROM_EMAIL,
          to: [email],
          subject: "Welcome to BlueWave Digital - set up your account",
          html,
        }),
      });
    }

    return json({ ok: true, client_id: client.id, user_id: userId }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(obj, status) {
  return new Response(JSON.stringify(obj), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

function brandedEmail(name, link, site) {
  return `<!DOCTYPE html><html><body style="margin:0;background:#04213f;font-family:Arial,Helvetica,sans-serif;color:#eaf4fb">
  <div style="max-width:520px;margin:0 auto;padding:32px 24px">
    <div style="text-align:center;margin-bottom:24px">
      <img src="https://i.ibb.co/MDHS2J5v/Blue-Wave-Digital-New-Logo.png" alt="BlueWave Digital" style="height:56px">
    </div>
    <div style="background:#062a4f;border-radius:16px;padding:28px">
      <h1 style="font-size:20px;margin:0 0 12px;color:#fff">Welcome aboard, ${escapeHtml(name)}</h1>
      <p style="color:#bcd9ee;font-size:15px;line-height:1.6;margin:0 0 20px">
        Your BlueWave Digital client account is ready. Click below to set your password and access your project dashboard.
      </p>
      <a href="${link}" style="display:inline-block;background:#1e8bd4;color:#fff;text-decoration:none;font-weight:bold;padding:12px 22px;border-radius:999px">Set your password</a>
      <p style="color:#8fb4d0;font-size:13px;line-height:1.6;margin:22px 0 0">
        If the button doesn't work, copy this link into your browser:<br>
        <span style="color:#3aa3e0;word-break:break-all">${link}</span>
      </p>
    </div>
    <p style="text-align:center;color:#8fb4d0;font-size:12px;margin-top:20px">
      BlueWave Digital · <a href="${site}" style="color:#3aa3e0">bluewaveagency.online</a> · Seychelles
    </p>
  </div></body></html>`;
}
function escapeHtml(s){return String(s).replace(/[&<>"]/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));}

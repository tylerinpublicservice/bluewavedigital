// ============================================================
// BlueWave Digital - Edge Function: manage-accounts
// One secure endpoint for ALL account admin actions, so staff
// never need to touch the Supabase backend directly.
//
// Actions (POST JSON { action, ... }):
//   invite        {name,email,country,phone}  -> create client+login, email invite
//   resend        {email}                     -> resend set-password / recovery link
//   reset         {email}                     -> send password reset link
//   set_role      {email, role}               -> admin|staff|client
//   status        {}                          -> list users + whether password is set
//   delete_login  {email}                     -> remove the auth login (keeps client row)
//
// Only callable by a logged-in admin/staff. Holds SERVICE_ROLE_KEY as a secret.
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const j = (o: unknown, s = 200) =>
  new Response(JSON.stringify(o), { status: s, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const URL = Deno.env.get("SUPABASE_URL")!;
    const SERVICE = Deno.env.get("SERVICE_ROLE_KEY")!;
    const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
    const RESEND = Deno.env.get("RESEND_API_KEY");
    const FROM = Deno.env.get("FROM_EMAIL") || "BlueWave Digital <hello@bluewaveagency.online>";
    const SITE = Deno.env.get("SITE_URL") || "https://bluewaveagency.online";

    // ---- verify caller is admin/staff ----
    const authHeader = req.headers.get("Authorization") || "";
    const caller = createClient(URL, ANON, { global: { headers: { Authorization: authHeader } } });
    const { data: ud } = await caller.auth.getUser();
    if (!ud?.user) return j({ error: "Not authenticated" }, 401);

    const admin = createClient(URL, SERVICE);
    const { data: prof } = await admin.from("profiles").select("role").eq("id", ud.user.id).single();
    if (!prof || (prof.role !== "admin" && prof.role !== "staff")) return j({ error: "Not authorised" }, 403);

    const body = await req.json();
    const action = body.action;
    const redirectTo = `${SITE}/set-password/`;

    const findUser = async (email: string) => {
      const { data } = await admin.auth.admin.listUsers();
      return data?.users?.find((u) => u.email?.toLowerCase() === email?.toLowerCase());
    };
    const emailInvite = async (name: string, email: string, link: string) => {
      if (!RESEND) return;
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${RESEND}`, "Content-Type": "application/json" },
        body: JSON.stringify({ from: FROM, to: [email], subject: "Your BlueWave Digital account", html: tpl(name, link, SITE, "Set your password") }),
      });
    };
    const emailReset = async (name: string, email: string, link: string) => {
      if (!RESEND) return;
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${RESEND}`, "Content-Type": "application/json" },
        body: JSON.stringify({ from: FROM, to: [email], subject: "Reset your BlueWave password", html: tpl(name, link, SITE, "Reset password") }),
      });
    };

    // ---------------- ACTIONS ----------------
    if (action === "invite") {
      const { name, email, country, phone } = body;
      if (!name || !email) return j({ error: "Name and email required" }, 400);
      const { data: client, error: cErr } = await admin.from("clients").insert({ name, email, country, phone }).select().single();
      if (cErr) return j({ error: "Client: " + cErr.message }, 400);

      let link = `${SITE}/login/`;
      const { data: inv, error: iErr } = await admin.auth.admin.inviteUserByEmail(email, { redirectTo, data: { full_name: name } });
      let uid = inv?.user?.id;
      if (iErr) {
        const { data: gl } = await admin.auth.admin.generateLink({ type: "recovery", email, options: { redirectTo } });
        link = gl?.properties?.action_link || link;
        uid = (await findUser(email))?.id;
      } else if (inv?.properties?.action_link) {
        link = inv.properties.action_link;
      }
      if (uid) await admin.from("profiles").update({ role: "client", client_id: client.id, full_name: name }).eq("id", uid);
      await emailInvite(name, email, link);
      return j({ ok: true, client_id: client.id, user_id: uid });
    }

    if (action === "resend") {
      const { email } = body;
      const u = await findUser(email);
      const type = u?.last_sign_in_at ? "recovery" : "invite";
      const { data: gl, error } = await admin.auth.admin.generateLink({ type, email, options: { redirectTo } });
      if (error) return j({ error: error.message }, 400);
      await emailInvite(u?.user_metadata?.full_name || "there", email, gl?.properties?.action_link || `${SITE}/login/`);
      return j({ ok: true });
    }

    if (action === "reset") {
      const { email } = body;
      const { data: gl, error } = await admin.auth.admin.generateLink({ type: "recovery", email, options: { redirectTo } });
      if (error) return j({ error: error.message }, 400);
      await emailReset("there", email, gl?.properties?.action_link || `${SITE}/login/`);
      return j({ ok: true });
    }

    if (action === "set_role") {
      const { email, role } = body;
      if (!["admin", "staff", "client"].includes(role)) return j({ error: "Bad role" }, 400);
      const u = await findUser(email);
      if (!u) return j({ error: "User not found" }, 404);
      await admin.from("profiles").update({ role }).eq("id", u.id);
      return j({ ok: true });
    }

    if (action === "delete_login") {
      const { email } = body;
      const u = await findUser(email);
      if (!u) return j({ error: "User not found" }, 404);
      await admin.auth.admin.deleteUser(u.id);
      return j({ ok: true });
    }

    if (action === "status") {
      const { data } = await admin.auth.admin.listUsers();
      const users = (data?.users || []).map((u) => ({
        email: u.email,
        confirmed: !!u.email_confirmed_at,
        has_signed_in: !!u.last_sign_in_at,
        // "awaiting password" = invited but never signed in
        state: u.last_sign_in_at ? "active" : (u.email_confirmed_at ? "active" : "invited"),
      }));
      return j({ ok: true, users });
    }

    return j({ error: "Unknown action" }, 400);
  } catch (e) {
    return j({ error: String(e) }, 500);
  }
});

function tpl(name: string, link: string, site: string, cta: string) {
  return `<!DOCTYPE html><html><body style="margin:0;background:#04213f;font-family:Arial,Helvetica,sans-serif;color:#eaf4fb">
  <div style="max-width:520px;margin:0 auto;padding:32px 24px">
    <div style="text-align:center;margin-bottom:24px"><img src="https://i.ibb.co/MDHS2J5v/Blue-Wave-Digital-New-Logo.png" alt="BlueWave Digital" style="height:56px"></div>
    <div style="background:#062a4f;border-radius:16px;padding:28px">
      <h1 style="font-size:20px;margin:0 0 12px;color:#fff">Hello ${esc(name)}</h1>
      <p style="color:#bcd9ee;font-size:15px;line-height:1.6;margin:0 0 20px">Click below to ${cta.toLowerCase()} for your BlueWave Digital account.</p>
      <a href="${link}" style="display:inline-block;background:#1e8bd4;color:#fff;text-decoration:none;font-weight:bold;padding:12px 22px;border-radius:999px">${cta}</a>
      <p style="color:#8fb4d0;font-size:13px;line-height:1.6;margin:22px 0 0">If the button doesn't work, paste this link:<br><span style="color:#3aa3e0;word-break:break-all">${link}</span></p>
    </div>
    <p style="text-align:center;color:#8fb4d0;font-size:12px;margin-top:20px">BlueWave Digital · <a href="${site}" style="color:#3aa3e0">bluewaveagency.online</a></p>
  </div></body></html>`;
}
function esc(s: string) { return String(s).replace(/[&<>"]/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[m]!)); }

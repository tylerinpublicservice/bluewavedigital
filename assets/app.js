/* ============================================================
   BlueWave Digital - shared app script
   Loads Supabase, builds the nav/footer/loader, provides auth
   helpers and small utilities used across every page.
   ============================================================ */

// ---- CONFIG (safe to expose: anon key is protected by RLS) ----
const SUPABASE_URL = "https://teckviugfrdpqpxbsgjt.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlY2t2aXVnZnJkcHFweGJzZ2p0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3MjgzMDAsImV4cCI6MjEwMzMwNDMwMH0.RkAlslAeDa5dkfwZ9vAdpJ_g04sT0CCldI6OfnYPFpk";
const LOGO = "https://i.ibb.co/MDHS2J5v/Blue-Wave-Digital-New-Logo.png";

const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// ---- Currency ----
const RATES = { SCR:{rate:1,sym:'SCR '}, USD:{rate:0.070,sym:'$'}, EUR:{rate:0.065,sym:'\u20AC'}, GBP:{rate:0.055,sym:'\u00A3'} };
function convert(scr,cur){const r=RATES[cur]||RATES.SCR;return r.sym+Math.round((scr||0)*r.rate).toLocaleString('en-US');}
function money(n,c){return (c||'SCR')+' '+Number(n||0).toLocaleString('en-US');}
function esc(s){return (s==null?'':String(s)).replace(/[&<>"]/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[m]));}

// ---- Loader ----
function mountLoader(){
  if(document.getElementById('loader'))return;
  const l=document.createElement('div');l.id='loader';
  l.innerHTML=`<div class="loader-badge"><span class="ripple"></span><span class="ripple"></span><span class="ripple"></span><img src="${LOGO}" alt="BlueWave Digital"/></div>
  <div class="loader-word">BlueWave Digital</div>
  <div class="loader-waves" aria-hidden="true">
    <svg class="lw1" viewBox="0 0 1440 140" preserveAspectRatio="none"><path fill="#1e8bd4" d="M0,70 C240,30 480,110 720,70 C960,30 1200,110 1440,70 L1440,140 L0,140 Z"/></svg>
    <svg class="lw2" viewBox="0 0 1440 140" preserveAspectRatio="none"><path fill="#3aa3e0" d="M0,90 C240,50 480,120 720,90 C960,55 1200,120 1440,85 L1440,140 L0,140 Z"/></svg>
  </div>`;
  document.body.prepend(l);
  const hide=()=>l.classList.add('hidden');
  window.addEventListener('load',()=>setTimeout(hide,700));
  setTimeout(hide,3500);
}

// ---- Public nav + footer ----
const NAV_LINKS=[['/services/','Services'],['/work/','Work'],['/pricing/','Pricing'],['/about/','About'],['/insights/','Insights'],['/contact/','Contact']];
function mountNav(){
  const host=document.getElementById('nav');if(!host)return;
  host.outerHTML=`<header class="nav"><div class="wrap nav-inner">
    <a class="brand" href="/"><img src="${LOGO}" alt="BlueWave Digital"/><span>BlueWave Digital</span></a>
    <nav class="links">${NAV_LINKS.map(l=>`<a href="${l[0]}">${l[1]}</a>`).join('')}</nav>
    <div class="nav-cta">
      <a class="btn btn-ghost btn-sm" href="/login/">Client Login</a>
      <a class="btn btn-primary btn-sm" href="/quote/">Start a Project</a>
      <button class="menu-btn" onclick="var m=document.getElementById('mnav');m.style.display=m.style.display==='block'?'none':'block'">&#9776;</button>
    </div></div>
    <div id="mnav">${NAV_LINKS.map(l=>`<a href="${l[0]}">${l[1]}</a>`).join('')}<a href="/login/" style="color:var(--bright)">Client Login</a></div>
  </header>`;
}
function mountFooter(){
  const host=document.getElementById('footer');if(!host)return;
  host.outerHTML=`<footer class="site"><div class="wrap">
    <div class="foot-grid">
      <div class="foot-brand"><img src="${LOGO}" alt="BlueWave Digital"/><p>Modern websites for businesses in Seychelles and around the world. Registered in Seychelles.</p></div>
      <div><h5>BlueWave</h5><a href="/about/">About</a><a href="/work/">Work</a><a href="/process/">Process</a><a href="/pricing/">Pricing</a></div>
      <div><h5>Services</h5><a href="/services/">Websites</a><a href="/services/">E-Commerce</a><a href="/care/">Maintenance</a><a href="/services/">SEO</a></div>
      <div><h5>Resources</h5><a href="/insights/">Insights</a><a href="/faq/">FAQ</a><a href="/support/">Support</a></div>
      <div><h5>Legal</h5><a href="/contact/">Contact</a><a href="/privacy/">Privacy</a><a href="/terms/">Terms</a></div>
    </div>
    <div class="foot-bottom">&copy; <span id="yr"></span> BlueWave Digital. All rights reserved.</div>
  </div></footer>`;
  const y=document.getElementById('yr');if(y)y.textContent=new Date().getFullYear();
}

// ---- Scroll reveal ----
function mountReveal(){
  const obs=new IntersectionObserver(es=>{es.forEach(en=>{if(en.isIntersecting){en.target.classList.add('in');obs.unobserve(en.target)}})},{threshold:.12});
  document.querySelectorAll('.reveal').forEach(el=>obs.observe(el));
}

// ---- Auth helpers ----
async function currentUser(){const{data}=await db.auth.getUser();return data?data.user:null;}
async function currentProfile(){
  const u=await currentUser();if(!u)return null;
  const{data}=await db.from('profiles').select('*').eq('id',u.id).single();
  return data?{...data,email:u.email}:null;
}
async function signIn(email,password){return db.auth.signInWithPassword({email,password});}
async function signOut(){await db.auth.signOut();location.href='/login/';}
// Guard a page: role = 'client' | 'staff'
async function requireRole(role){
  const p=await currentProfile();
  if(!p){location.href='/login/';return null;}
  if(role==='staff' && !(p.role==='staff'||p.role==='admin')){location.href='/portal/';return null;}
  if(role==='client' && !(p.role==='client'||p.role==='staff'||p.role==='admin')){location.href='/login/';return null;}
  return p;
}

// ---- Auto-init on every page ----
document.addEventListener('DOMContentLoaded',()=>{
  mountLoader();mountNav();mountFooter();mountReveal();
});

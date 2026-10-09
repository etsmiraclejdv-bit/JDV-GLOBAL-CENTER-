import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const fedapayKey = Deno.env.get("FEDAPAY_API_KEY") || "";
const fedapayMode = Deno.env.get("FEDAPAY_PAYOUT_MODE") || "mtn_open";
const fedapayBase = (Deno.env.get("FEDAPAY_API_BASE_URL") || "https://api.fedapay.com/v1").replace(/\/$/,"");

const admin = createClient(supabaseUrl, serviceKey, {auth:{autoRefreshToken:false,persistSession:false}});

async function fail(id:string,msg:string){
  await admin.rpc("tontine_record_dispatch_failure",{p_dispatch_id:id,p_error:msg,p_retry_after_minutes:15});
}
async function processOne(id:string){
  const claim = await admin.rpc("tontine_claim_due_dispatch",{p_dispatch_id:id});
  if(claim.error) throw claim.error;
  if(!claim.data?.claimed) return {id,skipped:true};
  if(!fedapayKey) { await fail(id,"FEDAPAY_API_KEY_NOT_CONFIGURED"); return {id,configured:false}; }

  const d = claim.data;
  try {
    const createRes = await fetch(fedapayBase + "/payouts", {
      method:"POST",
      headers:{"Authorization":`Bearer ${fedapayKey}`,"Content-Type":"application/json"},
      body:JSON.stringify({
        amount:Number(d.amount),
        currency:{iso:"XOF"},
        mode:fedapayMode,
        customer:{phone_number:d.phone},
        merchant_reference:d.idempotency_key
      })
    });
    const createText = await createRes.text();
    if(!createRes.ok) throw new Error(`FEDAPAY_CREATE_${createRes.status}: ${createText.slice(0,1000)}`);
    const created = JSON.parse(createText);
    const payout = created?.v1?.payout || created?.payout || created?.data || created;
    const providerId = String(payout?.id ?? payout?.payout_id ?? "");
    const providerRef = payout?.reference ? String(payout.reference) : null;
    if(!providerId) throw new Error("FEDAPAY_CREATE_NO_ID");

    const startRes = await fetch(fedapayBase + "/payouts/start", {
      method:"PUT",
      headers:{"Authorization":`Bearer ${fedapayKey}`,"Content-Type":"application/json"},
      body:JSON.stringify({payout_ids:[Number(providerId)]})
    });
    const startText = await startRes.text();
    if(!startRes.ok) throw new Error(`FEDAPAY_START_${startRes.status}: ${startText.slice(0,1000)}`);
    await admin.rpc("tontine_record_dispatch_sent",{p_dispatch_id:id,p_provider_request_id:providerId,p_provider_reference:providerRef});
    return {id,sent:true,provider_id:providerId};
  } catch(e) {
    await fail(id,e instanceof Error?e.message:String(e));
    return {id,sent:false,error:e instanceof Error?e.message:String(e)};
  }
}

Deno.serve(async (req)=>{
  try {
    if(req.method!=="POST") return Response.json({error:"POST_REQUIRED"},{status:405});
    const body = await req.json().catch(()=>({}));
    const {data:queued,error:qerr}=await admin.rpc("tontine_queue_due_payouts");
    if(qerr) throw qerr;
    const {data:dispatches,error:derr}=await admin.from("tontine_payout_dispatches")
      .select("id")
      .eq("status","queued")
      .lte("next_attempt_at",new Date().toISOString())
      .order("queued_at",{ascending:true})
      .limit(20);
    if(derr) throw derr;
    const results=[];
    for(const row of (dispatches||[])) results.push(await processOne(row.id));
    return Response.json({ok:true,queued:queued??0,processed:results.length,results,request:body});
  } catch(e) {
    return Response.json({ok:false,error:e instanceof Error?e.message:String(e)},{status:500});
  }
});

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const admin=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{auth:{autoRefreshToken:false,persistSession:false}});
const webhookSecret=Deno.env.get("FEDAPAY_WEBHOOK_SECRET")||"";

function hex(buf:ArrayBuffer){return [...new Uint8Array(buf)].map(b=>b.toString(16).padStart(2,"0")).join("")}
async function sign(body:string){const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(webhookSecret),{name:"HMAC",hash:"SHA-256"},false,["sign"]);return hex(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(body)))}
function constantTime(a:string,b:string){if(a.length!==b.length)return false;let x=0;for(let i=0;i<a.length;i++)x|=a.charCodeAt(i)^b.charCodeAt(i);return x===0}
function walk(v:any,keys:string[]):any{if(v==null)return null;if(typeof v==="object"){for(const k of keys)if(v[k]!=null)return v[k];for(const x of Object.values(v)){const r=walk(x,keys);if(r!=null)return r}}return null}
function asAmount(v:any):number|null{if(v==null)return null;if(typeof v==="number")return Number.isFinite(v)?v:null;if(typeof v==="string"){const n=Number(v);return Number.isFinite(n)?n:null}if(typeof v==="object"){const n=Number(v.amount??v.value??v.value_in_xof);return Number.isFinite(n)?n:null}return null}
function asCurrencyCode(v:any):string|null{if(v==null)return null;if(typeof v==="string")return v.trim().toUpperCase()||null;if(typeof v==="object"){const x=v.code??v.currency??v.iso_code??v.isoCode;return x==null?null:String(x).trim().toUpperCase()||null}return String(v).trim().toUpperCase()||null}

Deno.serve(async(req)=>{
 if(req.method!=="POST")return Response.json({error:"POST_REQUIRED"},{status:405});
 const raw=await req.text();
 if(!webhookSecret)return Response.json({error:"WEBHOOK_SECRET_NOT_CONFIGURED"},{status:503});
 const supplied=(req.headers.get("x-fedapay-signature")||"").replace(/^sha256=/i,"").trim();
 const expected=await sign(raw);
 if(!constantTime(supplied,expected))return Response.json({error:"INVALID_SIGNATURE"},{status:401});

 try{
  const payload=JSON.parse(raw);
  const providerId=String(walk(payload,["id","payout_id","payoutId"])??"");
  const reference=walk(payload,["reference","provider_reference","merchant_reference"]);
  const status=String(walk(payload,["status","state"])??"").toLowerCase();
  const providerAmount=asAmount(walk(payload,["amount","payout_amount","amount_xof"]));
  const providerCurrency=asCurrencyCode(walk(payload,["currency","currency_code","currencyCode"]));
  const payloadHash=hex(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(raw)));

  let query=admin.from("tontine_payout_dispatches").select("id,payout_id,status,reconciliation_status");
  if(providerId)query=query.eq("provider_request_id",providerId);
  else if(reference)query=query.eq("provider_reference",String(reference));
  else return Response.json({ok:true,ignored:true,reason:"NO_PROVIDER_IDENTIFIER"});

  const {data:dispatch,error}=await query.maybeSingle();
  if(error)throw error;
  if(!dispatch)return Response.json({ok:true,ignored:true,reason:"DISPATCH_NOT_FOUND"});

  const finalSuccess=["paid","success","successful","confirmed","completed"].includes(status);
  const finalFailure=["failed","error","cancelled","canceled","rejected"].includes(status);
  const reversed=["reversed","refunded","refund","chargeback"].includes(status);
  const intermediate=["sent","pending","processing","scheduled","created"].includes(status);

  if(finalSuccess){
   if(providerAmount===null||!providerCurrency)return Response.json({ok:false,error:"FINAL_STATUS_REQUIRES_AMOUNT_AND_CURRENCY",dispatch_id:dispatch.id},{status:422});
   const rec=await admin.rpc("tontine_reconcile_dispatch",{p_dispatch_id:dispatch.id,p_provider_reference:reference?String(reference):(providerId||null),p_provider_request_id:providerId||null,p_provider_amount:providerAmount,p_provider_currency_code:providerCurrency,p_provider_status:status,p_provider_payload_hash:payloadHash});
   if(rec.error)throw rec.error;
   if(!rec.data?.ok)return Response.json({ok:false,error:"PAYOUT_RECONCILIATION_FAILED",reconciliation:rec.data},{status:409});
   const confirmed=await admin.rpc("tontine_confirm_dispatch",{p_dispatch_id:dispatch.id,p_provider_reference:reference?String(reference):(providerId||"UNKNOWN"),p_provider_request_id:providerId||null});
   if(confirmed.error)throw confirmed.error;
   return Response.json({ok:true,dispatch_id:dispatch.id,status,provider_amount:providerAmount,provider_currency:providerCurrency,confirmed:confirmed.data});
  }

  if(reversed){
   if(providerAmount===null||!providerCurrency)return Response.json({ok:false,error:"REVERSAL_REQUIRES_AMOUNT_AND_CURRENCY",dispatch_id:dispatch.id},{status:422});
   const rr=await admin.rpc("tontine_reverse_dispatch",{p_dispatch_id:dispatch.id,p_provider_reference:reference?String(reference):(providerId||"UNKNOWN"),p_provider_request_id:providerId||null,p_returned_amount:providerAmount,p_provider_currency_code:providerCurrency,p_reason:"FEDAPAY_STATUS_"+status});
   if(rr.error)throw rr.error;
   return Response.json({ok:true,dispatch_id:dispatch.id,status,reversal:rr.data});
  }

  if(finalFailure){
   const r=await admin.rpc("tontine_record_dispatch_failure",{p_dispatch_id:dispatch.id,p_error:"FEDAPAY_STATUS_"+status,p_retry_after_minutes:60});
   if(r.error)throw r.error;
   return Response.json({ok:true,dispatch_id:dispatch.id,status,failure:r.data});
  }

  if(intermediate){
   const r=await admin.rpc("tontine_record_dispatch_sent",{p_dispatch_id:dispatch.id,p_provider_request_id:providerId||null,p_provider_reference:reference?String(reference):null});
   if(r.error)throw r.error;
   return Response.json({ok:true,dispatch_id:dispatch.id,status,intermediate:true});
  }

  return Response.json({ok:true,dispatch_id:dispatch.id,status,ignored:true,reason:"UNMAPPED_PROVIDER_STATUS"});
 }catch(e){return Response.json({ok:false,error:e instanceof Error?e.message:String(e)},{status:500})}
});

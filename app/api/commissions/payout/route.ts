import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { fedapayBaseUrl } from '@/lib/fedapay';

export async function POST(req: NextRequest) {
  const secretKey = process.env.FEDAPAY_SECRET_KEY;
  if (!secretKey) return NextResponse.json({ error: 'FedaPay payout non configuré.' }, { status: 503 });
  const token=(req.headers.get('authorization')||'').replace(/^Bearer\s+/i,'').trim();
  if(!token) return NextResponse.json({error:'Authentification requise'},{status:401});
  let body: { saleId?: unknown };
  try { body=await req.json(); } catch { return NextResponse.json({error:'Requête invalide'},{status:400}); }
  const saleId=typeof body.saleId==='string'?body.saleId:'';
  if(!saleId) return NextResponse.json({error:'saleId requis'},{status:400});

  const url=process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const opts={auth:{autoRefreshToken:false,persistSession:false}};
  const userClient=createClient(url,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,opts);
  const {data:{user},error:userError}=await userClient.auth.getUser(token);
  if(userError||!user) return NextResponse.json({error:'Session invalide'},{status:401});
  const admin=createClient(url,process.env.SUPABASE_SERVICE_ROLE_KEY!,opts);

  const {data:sale,error:saleError}=await admin.from('sales').select('id,organization_id,prospecteur_id').eq('id',saleId).single();
  if(saleError||!sale) return NextResponse.json({error:'Vente introuvable'},{status:404});
  const {data:member}=await admin.from('organization_members').select('role').eq('organization_id',sale.organization_id).eq('user_id',user.id).eq('status','active').maybeSingle();
  const {data:pros}=await admin.from('prospecteurs').select('id,user_id').eq('id',sale.prospecteur_id).maybeSingle();
  if(!member || !(['business_admin','manager','accountant'].includes(member.role) || pros?.user_id===user.id))
    return NextResponse.json({error:'Accès refusé'},{status:403});

  const {data:rows,error:rowsError}=await admin.from('commission_payouts').select('*').eq('organization_id',sale.organization_id).eq('prospecteur_id',sale.prospecteur_id).in('status',['queued','failed']).in('commission_id',(
    await admin.from('commissions').select('id').eq('sale_id',saleId)
  ).data?.map((x:{id:string})=>x.id)||[]);
  if(rowsError) return NextResponse.json({error:rowsError.message},{status:500});
  if(!rows?.length) return NextResponse.json({processed:0,message:'Aucun versement en attente.'});

  const base=fedapayBaseUrl(secretKey);
  const headers={Authorization:`Bearer ${secretKey}`,'Content-Type':'application/json'};
  const results=[];
  for(const p of rows){
    if(!p.payout_mode){
      results.push({id:p.id,status:'failed',error:'Mode Mobile Money non configuré pour ce prospecteur.'});
      await admin.from('commission_payouts').update({status:'failed',failure_reason:'Mode Mobile Money non configuré',updated_at:new Date().toISOString()}).eq('id',p.id);
      continue;
    }
    await admin.from('commission_payouts').update({status:'processing',requested_at:new Date().toISOString(),updated_at:new Date().toISOString()}).eq('id',p.id).in('status',['queued','failed']);
    try{
      const create=await fetch(`${base}/payouts`,{method:'POST',headers,body:JSON.stringify({
        amount:Math.round(Number(p.amount)),currency:{iso:p.currency||'XOF'},mode:p.payout_mode,
        customer:{phone_number:{number:p.phone_number,country:'bj'}}
      })});
      const cj=await create.json().catch(()=>({}));
      if(!create.ok){throw new Error(typeof cj?.message==='string'?cj.message:'FedaPay payout refusé');}
      const payoutId=String(cj?.id??cj?.payout?.id??'');
      if(!payoutId) throw new Error('Identifiant payout FedaPay absent');
      const start=await fetch(`${base}/payouts/start`,{method:'PUT',headers,body:JSON.stringify({payouts:[{id:Number(payoutId)||payoutId}]})});
      const sj=await start.json().catch(()=>({}));
      if(!start.ok) throw new Error(typeof sj?.message==='string'?sj.message:'Impossible de démarrer le payout');
      await admin.from('commission_payouts').update({status:'pending',provider_payout_id:payoutId,provider_reference:String(sj?.reference??payoutId),failure_reason:null,updated_at:new Date().toISOString()}).eq('id',p.id);
      results.push({id:p.id,status:'pending',provider_payout_id:payoutId});
    }catch(e){
      const msg=e instanceof Error?e.message:'Erreur payout';
      await admin.from('commission_payouts').update({status:'failed',failure_reason:msg,updated_at:new Date().toISOString()}).eq('id',p.id);
      results.push({id:p.id,status:'failed',error:msg});
    }
  }
  return NextResponse.json({processed:results.length,results});
}
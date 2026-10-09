import { supabase } from '@/lib/supabase/client';

export type SupplyAssignment = {
  id:string; organization_id:string; prospecteur_id:string; warehouse_id:string;
  department:string|null; city:string|null; is_primary:boolean; active:boolean;
  warehouses?: { id:string; code:string; name:string; address:string|null; city:string|null; country:string|null };
};

export async function getMyProspecteurContext() {
  const { data:{ user } } = await supabase.auth.getUser();
  if (!user) return { data:null,error:new Error('Session utilisateur introuvable') };
  const { data,error } = await supabase.from('prospecteurs').select('id,organization_id,first_name,last_name').eq('user_id',user.id).maybeSingle();
  if (error || !data) return { data:null,error:error ?? new Error('Compte prospecteur introuvable') };
  return { data,error:null };
}

export async function getMyWarehouse(prospecteurId:string) {
  const { data,error } = await supabase.from('prospecteur_warehouse_assignments')
    .select('*, warehouses(id,code,name,address,city,country)')
    .eq('prospecteur_id',prospecteurId).eq('active',true).eq('is_primary',true).maybeSingle();
  return { data:data as SupplyAssignment|null,error };
}

export async function getWarehouseCatalog(organizationId:string,warehouseId:string) {
  const { data,error } = await supabase.from('warehouse_inventory')
    .select('article_id,quantity,reserved_quantity,minimum_quantity,articles(id,code,name,category,unit,cash_price,credit_price,fixed_price,active)')
    .eq('organization_id',organizationId).eq('warehouse_id',warehouseId);
  return { data:data ?? [],error };
}

export async function getMyStock(prospecteurId:string,organizationId:string) {
  const { data,error } = await supabase.from('prospecteur_stocks')
    .select('article_id,quantity,articles(id,code,name,category,unit,cash_price,credit_price,fixed_price)')
    .eq('organization_id',organizationId).eq('prospecteur_id',prospecteurId).order('updated_at',{ascending:false});
  return { data:data ?? [],error };
}

export async function getMyStockHoldings(prospecteurId:string,organizationId:string) {
  const { data,error } = await supabase.from('prospecteur_stock_holdings')
    .select('id,article_id,warehouse_id,supply_request_id,quantity,remaining_quantity,supplied_at,return_due_at,hard_due_at,sold_at,returned_at,status,notes,articles(id,code,name)')
    .eq('organization_id',organizationId).eq('prospecteur_id',prospecteurId)
    .gt('remaining_quantity',0).order('return_due_at',{ascending:true});
  return { data:data ?? [],error };
}

export async function returnProspecteurStock(holdingId:string) {
  const { data,error } = await supabase.rpc('jdvcrm_return_prospecteur_stock_v1',{p_holding_id:holdingId});
  return { data,error };
}

export async function getMySupplyRequests(prospecteurId:string,organizationId:string) {
  const { data,error } = await supabase.from('prospecteur_supply_requests')
    .select('id,warehouse_id,status,requested_at,processed_at,notes,prospecteur_supply_request_items(quantity,article_id,articles(code,name))')
    .eq('organization_id',organizationId).eq('prospecteur_id',prospecteurId).order('requested_at',{ascending:false});
  return { data:data ?? [],error };
}

export async function requestSupply(
  organizationId:string,
  _prospecteurId:string,
  warehouseId:string,
  items:{article_id:string;quantity:number}[]
) {
  if (!items.length) return { data:null,error:new Error('Sélectionnez au moins un article') };

  // Le prospecteur ne demande plus une validation à l'administrateur.
  // Le réapprovisionnement est exécuté atomiquement depuis son entrepôt
  // principal affecté par la fonction SQL sécurisée.
  const { data,error } = await supabase.rpc('jdvcrm_request_prospecteur_supply_v1',{
    p_warehouse_id: warehouseId,
    p_items: items,
  });

  return { data,error };
}

export async function getMySales(organizationId:string,prospecteurId:string) {
  const { data,error } = await supabase.from('sales')
    .select('id,sale_number,sale_date,article_id,client_id,quantity,sale_type,cash_price,credit_price,amount_paid,amount_remaining,status')
    .eq('organization_id',organizationId).eq('prospecteur_id',prospecteurId)
    .order('sale_date',{ascending:false});
  if (error) return { data:null,error };
  const [articles,clients] = await Promise.all([
    supabase.from('articles').select('id,code,name').eq('organization_id',organizationId),
    supabase.from('clients').select('id,first_name,last_name,phone').eq('organization_id',organizationId)
  ]);
  const am=new Map((articles.data??[]).map((x:any)=>[x.id,x]));
  const cm=new Map((clients.data??[]).map((x:any)=>[x.id,x]));
  return { data:(data??[]).map((s:any)=>({...s,article:am.get(s.article_id),client:cm.get(s.client_id)})),error:null };
}

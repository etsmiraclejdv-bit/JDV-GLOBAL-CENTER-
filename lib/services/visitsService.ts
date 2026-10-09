import { supabase } from '@/lib/supabase/client';
import type { VisitInput } from '@/lib/visits/helpers';

export interface VisitRecord {
  id: string;
  prospecteur_id: string;
  prospect_id: string | null;
  client_id: string | null;
  visit_date: string;
  latitude: number | null;
  longitude: number | null;
  address: string | null;
  result: string | null;
  notes: string | null;
  next_follow_up_at: string | null;
  contact_name: string;
  contact_phone: string | null;
}

export interface ProspectOption {
  id: string;
  name: string;
  phone: string | null;
  status: string;
  next_follow_up_at: string | null;
  address: string | null;
  city: string | null;
}

interface Person { first_name: string | null; last_name: string | null; phone: string | null; }
interface VisitRaw {
  id: string; prospecteur_id: string; prospect_id: string | null; client_id: string | null; visit_date: string;
  latitude: number | string | null; longitude: number | string | null; address: string | null; result: string | null; notes: string | null;
  next_follow_up_at: string | null; prospects: Person | Person[] | null; clients: Person | Person[] | null;
}
const one = <T,>(v: T | T[] | null): T | null => (Array.isArray(v) ? (v[0] ?? null) : v);
const fullName = (p: Person | null) => (p ? `${p.first_name ?? ''} ${p.last_name ?? ''}`.trim() : '');

export async function fetchVisits(organizationId: string, prospecteurId?: string): Promise<{ data: VisitRecord[]; error: string | null }> {
  let query = supabase.from('field_visits').select('id, prospecteur_id, prospect_id, client_id, visit_date, latitude, longitude, address, result, notes, next_follow_up_at, prospects(first_name, last_name, phone), clients(first_name, last_name, phone)').eq('organization_id', organizationId).order('visit_date', { ascending: false }).limit(300);
  if (prospecteurId) query = query.eq('prospecteur_id', prospecteurId);
  const { data, error } = await query;
  if (error) return { data: [], error: error.message };
  const rows = (data ?? []) as unknown as VisitRaw[];
  return { data: rows.map((r) => {
    const person = one(r.prospects) ?? one(r.clients);
    return { id:r.id, prospecteur_id:r.prospecteur_id, prospect_id:r.prospect_id, client_id:r.client_id, visit_date:r.visit_date,
      latitude:r.latitude===null?null:Number(r.latitude), longitude:r.longitude===null?null:Number(r.longitude), address:r.address, result:r.result,
      notes:r.notes, next_follow_up_at:r.next_follow_up_at, contact_name:fullName(person)||'Contact sans nom', contact_phone:person?.phone??null };
  }), error:null };
}

export async function fetchProspectOptions(organizationId: string, prospecteurId: string): Promise<{ data: ProspectOption[]; error: string | null }> {
  const { data, error } = await supabase.from('prospects').select('id, first_name, last_name, phone, status, next_follow_up_at, address, city').eq('organization_id', organizationId).eq('prospecteur_id', prospecteurId).not('status','in','(converted,archived)').order('created_at',{ascending:false}).limit(500);
  if (error) return { data: [], error: error.message };
  return { data: ((data ?? []) as (Person & {id:string;status:string;next_follow_up_at:string|null;address:string|null;city:string|null})[]).map((p)=>({id:p.id,name:fullName(p)||'Sans nom',phone:p.phone,status:p.status,next_follow_up_at:p.next_follow_up_at,address:p.address,city:p.city})), error:null };
}

export async function createVisit(organizationId: string, prospecteurId: string, v: VisitInput): Promise<{ error: string | null }> {
  const { error } = await supabase.from('field_visits').insert({
    organization_id: organizationId, prospecteur_id: prospecteurId, prospect_id: v.prospect_id, visit_date: v.visit_date, result: v.result,
    notes: v.notes.trim()===''?null:v.notes.trim(), next_follow_up_at:v.next_follow_up_at||null, address:v.address.trim()===''?null:v.address.trim(),
    latitude:v.latitude, longitude:v.longitude,
  });
  return { error:error?error.message:null };
}
export default async () => {
  const url = Netlify.env.get('NEXT_PUBLIC_SUPABASE_URL');
  const key = Netlify.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) {
    console.error('JDV intelligence scan: Supabase environment variables are missing');
    return;
  }

  const response = await fetch(`${url}/rest/v1/rpc/jdvcrm_run_intelligence_scan_v1`, {
    method: 'POST',
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: '{}',
  });

  if (!response.ok) {
    console.error('JDV intelligence scan failed:', await response.text());
    return;
  }

  console.log('JDV intelligence scan:', await response.text());
};

export const config = {
  schedule: '*/15 * * * *',
};

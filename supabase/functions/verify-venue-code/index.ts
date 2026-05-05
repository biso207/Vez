// deno-lint-ignore-file
/// <reference lib="deno.ns" />

type VerifyVenueCodePayload = {
user_id?: string;
verification_code?: string;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsxonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const payload = (await req.json()) as VerifyVenueCodePayload;
    const userId = requiredString(payload.user_id, 'user_id');
    const code = requiredString(payload.verification_code, 'verification_code')
      .toUpperCase();

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const supabaseKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const request = await fetchSingleRow(
      supabaseUrl,
      supabaseKey,
      `/rest/v1/venue_verification_requests?user_id=eq.${encodeURIComponent(userId)}&status=in.(pending,code_sent)&select=request_id,verification_code&limit=1`,
    );

    if (!request) return jsonResponse({ error: 'Request not found' }, 404);
    if (stringValue(request.verification_code).toUpperCase() !== code) {
      return jsonResponse({ error: 'Invalid code' }, 401);
    }

    await supabaseRequest(
      supabaseUrl,
      supabaseKey,
      `/rest/v1/venue_verification_requests?request_id=eq.${encodeURIComponent(stringValue(request.request_id))}`,
      {
        method: 'PATCH',
        body: {
          status: 'code_confirmed',
          verification_code_confirmed_at: new Date().toISOString(),
        },
      },
    );

    return jsonResponse({ ok: true });
  } catch (error) {
    console.error(error);
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      500,
    );
  }
});

async function fetchSingleRow(
  supabaseUrl: string,
  supabaseKey: string,
  path: string,
) {
  const rows = await supabaseRequest(supabaseUrl, supabaseKey, path, {
    method: 'GET',
  }) as Record<string, unknown>[];
  return rows[0] ?? null;
}

async function supabaseRequest(
  supabaseUrl: string,
  supabaseKey: string,
  path: string,
  options: { method: string; body?: Record<string, unknown> },
) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    method: options.method,
    headers: {
      apikey: supabaseKey,
      authorization: `Bearer ${supabaseKey}`,
      'content-type': 'application/json',
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Supabase ${options.method} failed: ${response.status} ${text}`);
  }
  return text ? JSON.parse(text) : {};
}

function requiredString(value: unknown, name: string) {
  const trimmed = stringValue(value);
  if (!trimmed) throw new Error(`Missing ${name}`);
  return trimmed;
}

function stringValue(value: unknown) {
  return typeof value === 'string' ? value.trim() : '';
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env var: ${name}`);
  return value;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  });
}

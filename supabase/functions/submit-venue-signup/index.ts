type VenueSignupPayload = {
  username?: string;
  email?: string;
  password?: string;
  language?: string;
  venue_name?: string;
  legal_name?: string;
  vat_number?: string;
  address?: string;
  city?: string;
  country?: string;
  public_email?: string;
  public_phone?: string;
  website_url?: string;
  instagram_url?: string;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const passwordSalt = 'biso207_and_lasagnezio_the_best';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const payload = (await req.json()) as VenueSignupPayload;
    const username = requiredString(payload.username, 'username');
    const email = requiredString(payload.email, 'email');
    const password = requiredString(payload.password, 'password');
    const venueName = requiredString(payload.venue_name, 'venue_name');
    const legalName = requiredString(payload.legal_name, 'legal_name');
    const vatNumber = requiredString(payload.vat_number, 'vat_number');
    const address = requiredString(payload.address, 'address');
    const city = stringValue(payload.city);
    const country = stringValue(payload.country) || 'IT';
    const publicEmail = requiredString(payload.public_email, 'public_email');

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const supabaseKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const hashPsw = await sha256Hex(password + passwordSalt);
    const verificationCode = `VZ-${crypto.getRandomValues(new Uint32Array(1))[0] % 90000 + 10000}`;

    const userRows = await supabaseRequest(supabaseUrl, supabaseKey, '/rest/v1/users', {
      method: 'POST',
      headers: { prefer: 'return=representation' },
      body: {
        username,
        email,
        hash_psw: hashPsw,
        date_of_birth: '1900-01-01',
        city,
        profile_photo: '',
        bio: '',
        account_type: 'venue',
        account_state: 'pending_verification',
        num_created_events: 0,
        num_participated_events: 0,
        language: stringValue(payload.language) || 'en',
      },
    });

    const user = Array.isArray(userRows) ? userRows[0] : null;
    const userId = stringValue(user?.user_id);
    if (!userId) throw new Error('User creation failed');

    await supabaseRequest(
      supabaseUrl,
      supabaseKey,
      '/rest/v1/venue_verification_requests',
      {
        method: 'POST',
        body: {
          user_id: userId,
          venue_name: venueName,
          legal_name: legalName,
          vat_number: vatNumber,
          address,
          city,
          country,
          public_email: publicEmail,
          public_phone: stringValue(payload.public_phone),
          website_url: stringValue(payload.website_url),
          instagram_url: stringValue(payload.instagram_url),
          verification_code: verificationCode,
          status: 'pending',
        },
      },
    );

    return jsonResponse({ ok: true, user_id: userId }, 201);
  } catch (error) {
    console.error(error);
    const message = error instanceof Error ? error.message : 'Unknown error';
    const status = message.includes('duplicate key') ? 409 : 400;
    return jsonResponse({ error: message }, status);
  }
});

async function supabaseRequest(
  supabaseUrl: string,
  supabaseKey: string,
  path: string,
  options: {
    method: string;
    headers?: Record<string, string>;
    body?: Record<string, unknown>;
  },
) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    method: options.method,
    headers: {
      apikey: supabaseKey,
      authorization: `Bearer ${supabaseKey}`,
      'content-type': 'application/json',
      ...(options.headers ?? {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Supabase ${options.method} failed: ${response.status} ${text}`);
  }

  return text ? JSON.parse(text) : {};
}

async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
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

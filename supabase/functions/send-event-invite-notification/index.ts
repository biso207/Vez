type InvitePayload = {
  event_id?: string;
  invited_user_id?: string;
  inviter_user_id?: string;
};

type SupabaseRow = Record<string, unknown>;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const inviteLines = [
  'Hey {name}, {host} ti ha appena invitato a {event}. Ci sta un salto?',
  '{name}, nuovo invito su Vez: {event}. Dai un occhio, promette bene.',
  'Yo {name}, sei nella lista per {event}. {host} ti aspetta su Vez.',
  '{host} ti ha chiamato per {event}, {name}. Tocca vedere che vibe e.',
  'Nuovo piano in arrivo, {name}: {event}. Ti ha invitato {host}.',
  '{name}, hai un invito fresco fresco: {event}. Apri Vez e guarda.',
  'Plot twist della giornata: {host} ti ha invitato a {event}, {name}.',
  '{name}, {event} ti aspetta. Invito mandato da {host}, tutto su Vez.',
  'Hai un nuovo invito, {name}: {event}. Sembra una bella mossa.',
  '{host} vuole vederti a {event}, {name}. Che fai, ci sei?',
];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const payload = (await req.json()) as InvitePayload;
    const eventId = payload.event_id?.trim();
    const invitedUserId = payload.invited_user_id?.trim();
    const inviterUserId = payload.inviter_user_id?.trim();

    if (!eventId || !invitedUserId) {
      return jsonResponse({ error: 'Missing event_id or invited_user_id' }, 400);
    }

    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const supabaseKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');

    const [event, invitedUser, inviterUser] = await Promise.all([
      fetchSingleRow(
        supabaseUrl,
        supabaseKey,
        `/rest/v1/events?event_id=eq.${encodeURIComponent(eventId)}&select=event_id,title,creator_user_id&limit=1`,
      ),
      fetchSingleRow(
        supabaseUrl,
        supabaseKey,
        `/rest/v1/users?user_id=eq.${encodeURIComponent(invitedUserId)}&select=user_id,username,fcm_token&limit=1`,
      ),
      inviterUserId
        ? fetchSingleRow(
            supabaseUrl,
            supabaseKey,
            `/rest/v1/users?user_id=eq.${encodeURIComponent(inviterUserId)}&select=user_id,username&limit=1`,
          )
        : Promise.resolve(null),
    ]);

    if (!event) return jsonResponse({ error: 'Event not found' }, 404);
    if (!invitedUser) return jsonResponse({ error: 'Invited user not found' }, 404);

    const fcmToken = stringValue(invitedUser.fcm_token);
    if (!fcmToken) {
      return jsonResponse({ skipped: true, reason: 'Invited user has no FCM token' });
    }

    const eventTitle = stringValue(event.title) || 'un evento';
    const invitedName = stringValue(invitedUser.username) || 'vez';
    const hostName =
      stringValue(inviterUser?.username) ||
      (await getCreatorUsername(supabaseUrl, supabaseKey, event)) ||
      'un amico';
    const body = buildInviteBody(invitedName, hostName, eventTitle);

    const result = await sendFcmMessage({
      token: fcmToken,
      title: 'Nuovo invito su Vez',
      body,
      data: {
        type: 'event_invite',
        event_id: eventId,
      },
    });

    return jsonResponse({ ok: true, fcm: result });
  } catch (error) {
    console.error(error);
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      500,
    );
  }
});

function buildInviteBody(name: string, host: string, event: string) {
  const template = inviteLines[Math.floor(Math.random() * inviteLines.length)];
  return template
    .replaceAll('{name}', name)
    .replaceAll('{host}', host)
    .replaceAll('{event}', event);
}

async function fetchSingleRow(
  supabaseUrl: string,
  supabaseKey: string,
  path: string,
) {
  const response = await fetch(`${supabaseUrl}${path}`, {
    headers: {
      apikey: supabaseKey,
      authorization: `Bearer ${supabaseKey}`,
    },
  });

  if (!response.ok) {
    throw new Error(`Supabase read failed: ${response.status} ${await response.text()}`);
  }

  const rows = (await response.json()) as SupabaseRow[];
  return rows[0] ?? null;
}

async function getCreatorUsername(
  supabaseUrl: string,
  supabaseKey: string,
  event: SupabaseRow,
) {
  const creatorUserId = stringValue(event.creator_user_id);
  if (!creatorUserId) return '';

  const creator = await fetchSingleRow(
    supabaseUrl,
    supabaseKey,
    `/rest/v1/users?user_id=eq.${encodeURIComponent(creatorUserId)}&select=username&limit=1`,
  );
  return stringValue(creator?.username);
}

async function sendFcmMessage({
  token,
  title,
  body,
  data,
}: {
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  const projectId = requiredEnv('FIREBASE_PROJECT_ID');
  const accessToken = await getGoogleAccessToken();

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'vez_events',
              sound: 'default',
            },
          },
        },
      }),
    },
  );

  const responseText = await response.text();
  if (!response.ok) {
    throw new Error(`FCM send failed: ${response.status} ${responseText}`);
  }

  return responseText ? JSON.parse(responseText) : {};
}

async function getGoogleAccessToken() {
  const clientEmail = requiredEnv('FIREBASE_CLIENT_EMAIL');
  const privateKey = requiredEnv('FIREBASE_PRIVATE_KEY').replaceAll('\\n', '\n');
  const now = Math.floor(Date.now() / 1000);
  const jwt = await createJwt({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }, privateKey);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(`Google token failed: ${response.status} ${JSON.stringify(body)}`);
  }

  return body.access_token as string;
}

async function createJwt(payload: Record<string, unknown>, privateKeyPem: string) {
  const encoder = new TextEncoder();
  const header = { alg: 'RS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await importPrivateKey(privateKeyPem);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncode(signature)}`;
}

async function importPrivateKey(privateKeyPem: string) {
  const pemContents = privateKeyPem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replaceAll(/\s/g, '');
  const binary = Uint8Array.from(atob(pemContents), (char) => char.charCodeAt(0));

  return crypto.subtle.importKey(
    'pkcs8',
    binary,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );
}

function base64UrlEncode(value: string | ArrayBuffer) {
  const bytes = typeof value === 'string'
    ? new TextEncoder().encode(value)
    : new Uint8Array(value);
  let binary = '';
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
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
    headers: {
      ...corsHeaders,
      'content-type': 'application/json',
    },
  });
}

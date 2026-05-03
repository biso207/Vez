# send-event-invite-notification

Supabase Edge Function that sends an Android FCM push when a Vez user is invited
to an event.

## Required secrets

Set these Supabase function secrets before deploying:

```text
FIREBASE_PROJECT_ID=vezz-5d354
FIREBASE_CLIENT_EMAIL=<client_email from Firebase service account JSON>
FIREBASE_PRIVATE_KEY=<private_key from Firebase service account JSON>
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are available automatically on
hosted Supabase projects. If they are missing in your project, add them as
function secrets too.

## Where to get Firebase values

Firebase Console -> Project settings -> Service accounts -> Generate new
private key.

Use the downloaded JSON values:

```json
{
  "project_id": "vezz-5d354",
  "client_email": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
}
```

Keep this JSON private. Do not put it in the Flutter app or commit it.

## Deploy

With Supabase CLI:

```bash
supabase functions deploy send-event-invite-notification
```

Then set secrets either from the Supabase dashboard or with:

```bash
supabase secrets set FIREBASE_PROJECT_ID=vezz-5d354
supabase secrets set FIREBASE_CLIENT_EMAIL="..."
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

After deploy, `SetDBService.addOrUpdateEventInvite()` calls this function after
the invite is saved.

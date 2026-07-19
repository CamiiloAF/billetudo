// HU-07 (docs/requirements/05-auth-sync.md): deletes a user's account and all
// their data, synchronously and immediately — a legal requirement (Apple/
// Google), never deferred to the tombstone cleanup cron.
//
// `verify_jwt: true` (set at deploy time) makes the platform gateway reject
// requests without a valid Supabase JWT before this code ever runs. We still
// extract the user from that JWT ourselves via `auth.getUser` — never trust a
// client-supplied user id in the request body, the caller can only ever
// delete their own account.
//
// Deletion order: `delete_account_data` (a Postgres function, atomic by
// definition — see the migration that created it) removes the 12 mirrored
// tables first; `auth.admin.deleteUser` runs only if that succeeds. If the
// admin delete failed after the data was gone, we would strand a userless
// account row — better than deleting the user and leaving orphaned data with
// no owner able to reach it again.
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace(/^Bearer\s+/i, '');
  if (!jwt) {
    return new Response(JSON.stringify({ error: 'missing bearer token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: userResult, error: userError } = await admin.auth.getUser(jwt);
  if (userError || !userResult?.user) {
    return new Response(JSON.stringify({ error: 'invalid session' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  const userId = userResult.user.id;

  const { error: dataError } = await admin.rpc('delete_account_data', {
    p_user_id: userId,
  });
  if (dataError) {
    return new Response(
      JSON.stringify({ error: `data deletion failed: ${dataError.message}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  const { error: userDeleteError } = await admin.auth.admin.deleteUser(userId);
  if (userDeleteError) {
    // Data is already gone at this point; the account row is stranded but
    // retryable — surface this distinctly so the client can tell the user to
    // try again rather than reporting a clean success.
    return new Response(
      JSON.stringify({
        error: `account data deleted but user removal failed: ${userDeleteError.message}`,
        dataDeleted: true,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});

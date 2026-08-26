// Caller identification, extracted from the pattern `delete-account` set.
//
// These functions deploy with `verify_jwt: true`, so the platform gateway
// already rejects a request without a valid Supabase JWT before this code
// runs. We still resolve the user from that JWT ourselves: the request body is
// never trusted to say who is calling, so a caller can only ever act as
// themselves.

import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import { AiHttpError } from './errors.ts';

export interface CallerContext {
  readonly userId: string;
  /// Service-role client. In the AI functions it only ever touches
  /// `ai_access`, `ai_feature_flags` and `ai_usage_log` — never a financial
  /// table. That restriction is the whole point of the stateless-broker
  /// design; if a change here starts selecting from `transactions`, the
  /// privacy policy stops being true.
  readonly admin: SupabaseClient;
}

export function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
}

export async function requireUser(req: Request): Promise<CallerContext> {
  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace(/^Bearer\s+/i, '');
  if (!jwt) {
    throw new AiHttpError('unauthenticated', 'missing bearer token');
  }

  const admin = adminClient();
  const { data, error } = await admin.auth.getUser(jwt);
  if (error || !data?.user) {
    throw new AiHttpError('unauthenticated', 'invalid session');
  }

  return { userId: data.user.id, admin };
}

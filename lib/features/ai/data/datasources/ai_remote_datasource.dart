import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything [AiRemoteDatasource] can fail with, in one shape.
///
/// [status] is the HTTP status when the server actually answered, and `null`
/// when it never did (no signal, DNS, a socket dropped mid-flight). The
/// repository needs that difference: an answered `403` hides the assistant's
/// entry point, an unanswered call only earns a retry button.
///
/// [payload] is the parsed body — `{"error": {"code", "message",
/// "retryAfterSeconds"?}}` for this function family. It stays untouched here:
/// mapping it to a `Failure` is the repository's job, not the transport's.
class AiRemoteException implements Exception {
  const AiRemoteException({
    this.status,
    this.payload,
    this.cause,
    this.stackTrace,
  });

  final int? status;
  final Object? payload;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AiRemoteException(status: $status)';
}

/// The two remote calls the assistant makes: one turn of conversation against
/// the `ai-chat` Edge Function, and the server-side access gate.
///
/// Nothing is interpreted here. The body goes out as the repository built it
/// and the response comes back as a raw map, so the wire contract
/// (`supabase/functions/README.md`) has exactly one owner —
/// `AiRepositoryImpl` — instead of being half-implemented in two layers.
@lazySingleton
class AiRemoteDatasource {
  const AiRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const String _function = 'ai-chat';

  /// The `auth.uid()`-scoped wrapper. The parameterised `ai_access_state(uuid)`
  /// underneath is `SECURITY DEFINER` and deliberately not executable by
  /// `authenticated` — calling it with someone else's id would be a textbook
  /// IDOR (see `20260825120000_ai_assistant_access_and_usage.sql`).
  static const String _accessRpc = 'my_ai_access_state';

  /// Posts one turn. [body] is the full request document, already serialized.
  ///
  /// `functions.invoke` attaches the current session's JWT on its own (via
  /// `SupabaseClient`'s internal `AuthHttpClient`), so no `Authorization`
  /// header is built by hand — same as `AuthRepositoryImpl.deleteAccount`. The
  /// function is `verify_jwt: true` and resolves the user from that token; the
  /// body never carries a user id.
  ///
  /// Throws [AiRemoteException] for every failure mode, so the repository has
  /// a single `on` clause instead of three.
  Future<Map<String, Object?>> sendTurn(Map<String, Object?> body) async {
    try {
      final response = await _supabase.functions.invoke(_function, body: body);
      final data = _asMap(response.data);
      if (data == null) {
        throw AiRemoteException(
            status: response.status, payload: response.data);
      }
      return data;
    } on FunctionException catch (e, stackTrace) {
      throw AiRemoteException(
        status: e.status,
        payload: e.details,
        cause: e,
        stackTrace: stackTrace,
      );
    } on AiRemoteException {
      rethrow;
    } on Object catch (e, stackTrace) {
      // No status: the server never answered. Typically a `SocketException` or
      // a `ClientException` with no network at all.
      throw AiRemoteException(cause: e, stackTrace: stackTrace);
    }
  }

  /// Reads the access gate. `null` means the RPC returned no row at all, which
  /// the repository must read as denied — never as allowed.
  ///
  /// The function is declared `returns table (...)`, so PostgREST treats it as
  /// a set: it normally arrives as a list of rows, but a single-row set can
  /// come back as the bare object depending on what the client negotiated.
  /// Both are handled rather than betting on one.
  Future<Map<String, Object?>?> checkAccess() async {
    try {
      final data = await _supabase.rpc<dynamic>(_accessRpc);
      if (data is List) {
        return data.isEmpty ? null : _asMap(data.first);
      }
      return _asMap(data);
    } on PostgrestException catch (e, stackTrace) {
      throw AiRemoteException(
        // PostgREST reports the HTTP status in `code` as a string for
        // transport-level rejections (401 without a session, 404 when the
        // migration has not been applied yet).
        status: int.tryParse(e.code ?? ''),
        payload: e.message,
        cause: e,
        stackTrace: stackTrace,
      );
    } on Object catch (e, stackTrace) {
      throw AiRemoteException(cause: e, stackTrace: stackTrace);
    }
  }

  static Map<String, Object?>? _asMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return <String, Object?>{
        for (final entry in raw.entries) '${entry.key}': entry.value,
      };
    }
    return null;
  }
}

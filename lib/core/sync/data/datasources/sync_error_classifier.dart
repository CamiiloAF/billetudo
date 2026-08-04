import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sync_failure_kind.dart';

/// Decides whether a failed upload should be retried or quarantined.
///
/// This replaces the previous "fatal response codes" regex list, which only
/// knew about `22xxx`, `23xxx` and `42501`. Everything else — including
/// PostgREST's own schema-cache errors — fell through to "transient", was
/// rethrown, and was retried forever. That is exactly what happened when
/// Postgres was missing `debts.closed_at`: PostgREST answered `PGRST204`, the
/// operation was retried indefinitely and, because the upload queue is FIFO,
/// it blocked every later write of every table for three days with no symptom
/// in the app. 89 unsynced changes were lost when the app was reinstalled.
///
/// So the classification is now explicit and closed: unknown codes are still
/// treated as transient (dropping user data on a code we do not understand
/// would be worse), but the two families that can never succeed on retry are
/// recognised by name.
///
/// That leaves one hole open by design — an unforeseen code still retries
/// forever — and it is the retry watchdog (`SyncRetryWatchdog`), not this
/// class, that closes it: [isConnectivityFailure] is the line it needs to tell
/// "the network is down" from "the backend keeps rejecting this and we do not
/// know why".
abstract final class SyncErrorClassifier {
  const SyncErrorClassifier._();

  /// The client writes a column/table Postgres does not have. A deployment
  /// bug: the app shipped ahead of the database migration.
  static const Set<String> _brokenSchemaCodes = <String>{
    'PGRST204', // column not found in the schema cache
    'PGRST205', // table not found in the schema cache
    '42703', // undefined_column
    '42P01', // undefined_table
  };

  /// Codes that look permanent but are not: the client only has to get a
  /// fresh token and try again.
  static const Set<String> _transientCodes = <String>{
    'PGRST301', // JWT expired / not yet authenticated
    '408', // request timeout
    '429', // too many requests
  };

  /// Invalid data or permission, matched by Postgres class:
  ///  - `22xxx` data exception (bad value, out of range, invalid text...)
  ///  - `23xxx` integrity constraint violation (FK, unique, not null)
  ///  - `42501` insufficient privilege (an RLS policy said no)
  static final List<RegExp> _invalidDataPatterns = <RegExp>[
    RegExp(r'^22...$'),
    RegExp(r'^23...$'),
    RegExp(r'^42501$'),
  ];

  static SyncFailureKind classify(Object error) {
    // Anything that is not a backend rejection (socket errors, timeouts,
    // TLS handshakes, the platform going offline mid-request) is transient by
    // definition: the server never got to judge the write.
    if (error is! PostgrestException) {
      return SyncFailureKind.transient;
    }
    final code = error.code;
    if (code == null) {
      return SyncFailureKind.transient;
    }
    if (_brokenSchemaCodes.contains(code)) {
      return SyncFailureKind.brokenSchema;
    }
    if (_transientCodes.contains(code)) {
      return SyncFailureKind.transient;
    }
    // The backend is down or broken on its side — always worth retrying.
    if (_isServerErrorStatus(code)) {
      return SyncFailureKind.transient;
    }
    if (_invalidDataPatterns.any((pattern) => pattern.hasMatch(code))) {
      return SyncFailureKind.invalidData;
    }
    return SyncFailureKind.transient;
  }

  /// Whether the failure means "we could not reach the backend at all", as
  /// opposed to "the backend answered and rejected the write".
  ///
  /// Only used by the retry watchdog, and the whole reason it can exist: a
  /// user on a plane or behind a dead backend accumulates retries that are
  /// perfectly legitimate, and quarantining those would turn an outage into
  /// perceived data loss. So these are never counted, no matter how many.
  ///
  /// It is an allow-list on purpose. The inverse rule ("count only what we
  /// recognise as a server answer") would leave the original hole open: an
  /// unforeseen deterministic client-side failure — a bug in the uploader, a
  /// serialization error on one row — is not a network problem and would block
  /// the FIFO queue forever again. Anything not listed here counts, and the
  /// watchdog's second gate (elapsed time) keeps a miscategorised transport
  /// error from quarantining anything during a normal outage.
  static bool isConnectivityFailure(Object error) {
    // dart:io transport layer: no route, DNS failure, TLS handshake, socket
    // closed mid-request. `HttpException` also covers a connection dropped
    // before any response arrived.
    if (error is SocketException ||
        error is TlsException ||
        error is HttpException) {
      return true;
    }
    // `http` (what postgrest-dart uses underneath) wraps transport failures in
    // `ClientException`; a request that ran out of time never got an answer.
    if (error is http.ClientException || error is TimeoutException) {
      return true;
    }
    // No session, or a token that could not be refreshed: nothing was ever
    // judged by the backend, and signing in again fixes it.
    if (error is AuthException) {
      return true;
    }
    if (error is PostgrestException) {
      final code = error.code;
      // `PGRST301` is "not authenticated / JWT expired" — same case as above.
      // `408` is a timeout the gateway reports; the write never ran.
      return code == 'PGRST301' || code == '408';
    }
    return false;
  }

  /// The backend error code for reporting, when it exposes one.
  static String? codeOf(Object error) =>
      error is PostgrestException ? error.code : null;

  /// Some PostgREST failures surface the HTTP status as the code instead of a
  /// Postgres SQLSTATE.
  static bool _isServerErrorStatus(String code) {
    final status = int.tryParse(code);
    return status != null && status >= 500 && status < 600;
  }
}

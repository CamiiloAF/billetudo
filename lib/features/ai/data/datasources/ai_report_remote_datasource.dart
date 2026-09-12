import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when a report could not be filed. [isUnauthenticated] separates the
/// one case the UI must phrase differently — reporting needs an account — from
/// "it did not go through, try again".
class AiReportException implements Exception {
  const AiReportException({
    required this.isUnauthenticated,
    this.cause,
    this.stackTrace,
  });

  final bool isUnauthenticated;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'AiReportException(isUnauthenticated: $isUnauthenticated)';
}

/// Inserts into `public.ai_reports` over PostgREST.
///
/// No Edge Function on purpose: the row is written as the user, RLS already
/// restricts the insert to `user_id = auth.uid()`, and there is nothing to
/// validate server-side that a policy does not cover. A function here would
/// only add a service-role path into a table that must never accept a row on
/// anyone else's behalf.
///
/// This is the only place in the assistant that sends conversation content
/// anywhere. See `AiReport` (domain) and the migration
/// `20260825140000_ai_reports.sql` for why that exception exists and what
/// keeps it honest — chiefly that the UI has to warn before this runs.
@lazySingleton
class AiReportRemoteDatasource {
  const AiReportRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const String _table = 'ai_reports';

  /// [row] carries every column except `user_id`, which is read from the live
  /// session here rather than accepted from the caller: an id that travels
  /// through the app is an id that can be wrong, and RLS would reject it
  /// anyway.
  Future<void> insertReport(Map<String, Object?> row) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const AiReportException(isUnauthenticated: true);
    }

    try {
      await _supabase.from(_table).insert(<String, Object?>{
        ...row,
        'user_id': userId,
      });
    } on PostgrestException catch (e, stackTrace) {
      throw AiReportException(
        // A rejected policy (`42501`) or an expired token both mean the same
        // thing to the person holding the phone: this account cannot file the
        // report right now.
        isUnauthenticated: e.code == '42501' || e.code == '401',
        cause: e,
        stackTrace: stackTrace,
      );
    } on Object catch (e, stackTrace) {
      throw AiReportException(
        isUnauthenticated: false,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}

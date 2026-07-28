import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/sync_log_entry.dart';
import '../../domain/usecases/export_sync_log.dart';
import '../../domain/usecases/watch_sync_log.dart';
import 'sync_log_state.dart';

/// Drives the "Registro técnico" sheet — the one and only surface where the
/// raw vocabulary of sync (codes, table names, ISO timestamps) is allowed.
/// Its reader is support, not the user, which is why it also has to be
/// copyable as plain text.
@injectable
class SyncLogCubit extends Cubit<SyncLogState> {
  SyncLogCubit(this._watchSyncLog, this._exportSyncLog)
      : super(const SyncLogState());

  final WatchSyncLog _watchSyncLog;
  final ExportSyncLog _exportSyncLog;

  StreamSubscription<List<SyncLogEntry>>? _sub;

  Future<void> start() async {
    await _sub?.cancel();
    _sub = _watchSyncLog().listen((entries) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(entries: entries, isLoading: false));
    });
  }

  /// The plain-text rendering, oldest first. `null` when it could not be
  /// produced — the sheet then says nothing rather than copying a lie.
  Future<String?> exportAsText() async {
    final result = await _exportSyncLog();
    return result.getRight().toNullable();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

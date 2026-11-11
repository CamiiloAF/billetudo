import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../core/crash/crash_reporter.dart';
import '../../../core/error/result.dart';
import '../domain/entities/pending_capture.dart';
import '../domain/usecases/drain_and_ingest_captures.dart';
import '../domain/usecases/watch_incoming_captures.dart';

/// Keeps the inbox in sync with the phone **while the app is running**.
///
/// The native listener parks captures in its own buffer, which only Flutter
/// can turn into `PendingCaptures` rows. Before this class there were exactly
/// two moments that drained it: a cold start and opening Avisos. Everything
/// else — the common case of receiving a bank notification while the app is
/// already open or in the background — stayed invisible until one of those two
/// happened, so the bell showed no badge and Avisos said "Todo al día". That is
/// the "la app no está escuchando" report this closes, and it is why the
/// requirement that the pending count be visible **without opening the inbox**
/// now holds.
///
/// Two triggers, both cheap because they only drain when the native buffer has
/// something:
///
///  - the native → Dart doorbell (`onCaptureBuffered`), fired the instant a
///    notification becomes a capture;
///  - `AppLifecycleState.resumed`, the safety net for a doorbell lost while the
///    engine was detached and for captures buffered while the OS kept the
///    process but Flutter was not listening.
///
/// It never creates a `Transaction`: `DrainAndIngestCaptures` only fills the
/// review inbox. And it is deliberately app-wide (started once from
/// `bootstrap`), not owned by a screen: the badge has to update on Home, where
/// no inbox cubit is alive.
@lazySingleton
class CaptureIngestObserver with WidgetsBindingObserver {
  CaptureIngestObserver(
    this._drainAndIngest,
    this._watchIncoming,
    this._crash,
  );

  final DrainAndIngestCaptures _drainAndIngest;
  final WatchIncomingCaptures _watchIncoming;
  final CrashReporter _crash;

  StreamSubscription<void>? _incomingSub;
  bool _started = false;

  /// Coalescing state: a burst of notifications must become one drain, but an
  /// event arriving *during* a drain must not be lost, or the last capture of
  /// the burst would wait for the next resume.
  bool _ingesting = false;
  bool _drainAgain = false;

  /// Wires the doorbell and the lifecycle observer. The cold-start drain stays
  /// in `bootstrap`, which needs it **before** mounting the app so the first
  /// frame already shows the badge.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _incomingSub = _watchIncoming().listen(
      (_) => unawaited(drainNow()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(drainNow());
    }
  }

  /// Drains the native buffer into the inbox, coalescing overlapping calls.
  ///
  /// A failure is reported and swallowed: capture is additive, and neither the
  /// app nor an already-rendered inbox may go down because a drain failed.
  Future<void> drainNow() async {
    if (_ingesting) {
      _drainAgain = true;
      return;
    }
    _ingesting = true;
    try {
      do {
        _drainAgain = false;
        final Result<List<PendingCapture>> result = await _drainAndIngest();
        if (result case Left(value: final Failure failure)) {
          await _crash.recordFailure(
            failure,
            context: 'drainAndIngestCaptures',
          );
        }
      } while (_drainAgain);
    } finally {
      _ingesting = false;
    }
  }

  /// Detaches the observer. Only used by tests and by a full app teardown;
  /// the singleton lives for the whole process.
  Future<void> stop() async {
    if (!_started) {
      return;
    }
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _incomingSub?.cancel();
    _incomingSub = null;
  }
}

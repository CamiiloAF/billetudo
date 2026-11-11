import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/capture_background_health.dart';
import '../../domain/entities/issuer_app.dart';
import '../../domain/usecases/get_capture_background_health.dart';
import '../../domain/usecases/get_issuer_apps.dart';
import '../../domain/usecases/is_notification_access_granted.dart';
import '../../domain/usecases/is_notification_capture_supported.dart';
import '../../domain/usecases/mark_capture_configured.dart';
import '../../domain/usecases/open_capture_autostart_settings.dart';
import '../../domain/usecases/request_battery_optimization_exemption.dart';
import '../../domain/usecases/snooze_capture_background_alert.dart';
import '../../domain/usecases/watch_incoming_captures.dart';
import 'capture_background_state.dart';

/// Drives the "background capture may have stopped" surfaces of Avisos
/// (HU-09): the degraded card, the contextual empty state and the sheet.
///
/// **It reads, it never assumes.** Every `start()`/`refresh()` asks the system
/// for the real permission, the native issuer list and the health snapshot;
/// nothing is cached between calls, because all of it can change while the app
/// sits in the background (the user revokes the permission, disables the last
/// issuer or Android kills the listener).
///
/// Talks only to use cases, never to a repository or a DAO. `configuredAt`
/// and the snooze date are read inside `GetCaptureBackgroundHealth`, the one
/// place that owns the formula; the cubit only exposes the resulting facts to
/// the three surfaces.
@injectable
class CaptureBackgroundCubit extends Cubit<CaptureBackgroundState> {
  CaptureBackgroundCubit(
    this._health,
    this._isSupported,
    this._isGranted,
    this._getIssuerApps,
    this._snooze,
    this._requestBatteryExemption,
    this._openAutostart,
    this._markConfigured,
    this._watchIncomingCaptures,
  ) : super(const CaptureBackgroundState());

  final GetCaptureBackgroundHealth _health;
  final IsNotificationCaptureSupported _isSupported;
  final IsNotificationAccessGranted _isGranted;
  final GetIssuerApps _getIssuerApps;
  final SnoozeCaptureBackgroundAlert _snooze;
  final RequestBatteryOptimizationExemption _requestBatteryExemption;
  final OpenCaptureAutostartSettings _openAutostart;
  final MarkCaptureConfigured _markConfigured;
  final WatchIncomingCaptures _watchIncomingCaptures;

  StreamSubscription<void>? _incomingSub;

  /// Detects a reload that is no longer the latest one. `start()`, the live
  /// doorbell and the resume refresh can overlap; without this, an older
  /// snapshot could be emitted after a newer one and briefly show attention
  /// the device no longer has (or hide it).
  int _reloadGeneration = 0;

  bool _isStale(int generation) =>
      isClosed || generation != _reloadGeneration;

  /// Initial read. Shows the loading state, since the card appearing a beat
  /// after the captures section is fine and the alternative (a stale card
  /// from a previous visit) is not.
  ///
  /// It also subscribes to the live capture doorbell: a new capture is the
  /// fastest possible proof that capture is alive again, so the degraded card
  /// has to clear without waiting for the next visit.
  Future<void> start() async {
    _incomingSub ??= _watchIncomingCaptures().listen(
      (_) => unawaited(refresh()),
    );
    await _reload();
  }

  /// Re-read after returning to foreground. Silent: the surfaces keep the
  /// last snapshot on screen until the new one is ready.
  Future<void> refresh() => _reload(silent: true);

  /// "Ahora no" — hides the card and the degraded empty state for fourteen
  /// days and nothing else. A failed write leaves the card exactly where it
  /// was instead of pretending the user silenced it.
  Future<void> snooze() async {
    final Result<Unit> result = await _snooze();
    if (result case Left(value: final Failure failure)) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(failure: failure));
      return;
    }
    await _reload(silent: true);
  }

  /// Opens the battery-optimization exemption screen. The app cannot grant
  /// it, so the state is re-read right after opening; the page refreshes again
  /// when the user comes back.
  Future<void> requestBatteryExemption() =>
      _openSystemSetting(_requestBatteryExemption.call);

  /// Opens the manufacturer's autostart screen (or the app's details page as
  /// fallback). Same public shape as the battery action, because the sheet
  /// treats both rows identically.
  Future<void> openAutostart() => _openSystemSetting(_openAutostart.call);

  /// "Listo, ya lo activé": re-reads the **real** diagnostics and answers
  /// `true` only when the battery exemption is actually granted.
  ///
  /// It never trusts what the user says, and it emits what it read. Note that
  /// closing the sheet is all a `true` answer allows: the degraded state only
  /// clears when the formula says so (e.g. a new capture arrives), because
  /// granting an exemption is not proof that the listener is listening again.
  Future<bool> confirmActivated() async {
    await _reload(silent: true);
    return state.diagnostics?.batteryOptimizationExempt ?? false;
  }

  Future<void> _openSystemSetting(FutureResult<Unit> Function() open) async {
    final Result<Unit> result = await open();
    if (result case Left(value: final Failure failure)) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(failure: failure));
      return;
    }
    await _reload(silent: true);
  }

  Future<void> _reload({bool silent = false}) async {
    if (isClosed) {
      return;
    }
    final int generation = ++_reloadGeneration;

    final bool supported = _isSupported();
    if (!supported) {
      emit(
        const CaptureBackgroundState(isLoading: false),
      );
      return;
    }

    if (!silent) {
      emit(
        state.copyWith(
          isSupported: true,
          isLoading: true,
          showsAttention: false,
          degraded: false,
          clearSnoozedUntil: true,
          clearDiagnostics: true,
          clearFailure: true,
        ),
      );
    }

    final Result<bool> granted = await _isGranted();
    if (_isStale(generation)) {
      return;
    }
    final bool permissionGranted = switch (granted) {
      Right(value: final bool value) => value,
      Left() => false,
    };

    // The permission state takes precedence over any stale native diagnostics:
    // a revoked permission cannot be "degraded", it is simply off.
    if (!permissionGranted) {
      emit(
        const CaptureBackgroundState(
          isSupported: true,
          isLoading: false,
        ),
      );
      return;
    }

    final Result<List<IssuerApp>> apps = await _getIssuerApps();
    if (_isStale(generation)) {
      return;
    }
    final List<IssuerApp> issuers;
    switch (apps) {
      case Right(value: final List<IssuerApp> value):
        issuers = value;
      case Left(value: final Failure failure):
        emit(
          state.copyWith(
            isSupported: true,
            isLoading: false,
            showsAttention: false,
            degraded: false,
            clearSnoozedUntil: true,
            clearDiagnostics: true,
            permissionGranted: true,
            enabledCount: 0,
            failure: failure,
          ),
        );
        return;
    }

    final int enabledCount =
        issuers.where((IssuerApp issuer) => issuer.enabled).length;

    // No enabled issuer is the "elige apps" state, which has its own surface
    // and precedence: the degraded card must not compete with it.
    if (enabledCount == 0) {
      emit(
        const CaptureBackgroundState(
          isSupported: true,
          isLoading: false,
          permissionGranted: true,
        ),
      );
      return;
    }

    // Migration guard (2026-11-11): installations configured **before** HU-09
    // existed never got `configuredAt`, so the rule below reads "not
    // configured" and the app stays silent forever — the exact "Todo al día
    // mientras la captura está muerta" report this closes. Now that the two
    // preconditions are verified, latch the date (idempotent, evidence-based:
    // see `MarkCaptureConfigured`). A failed write is intentionally ignored:
    // it only means the next visit tries again, and it must never turn a
    // healthy capture into an error surface.
    await _markConfigured();
    if (_isStale(generation)) {
      return;
    }

    final Result<CaptureBackgroundHealth> health = await _health();
    if (_isStale(generation)) {
      return;
    }
    switch (health) {
      case Left(value: final Failure failure):
        emit(
          state.copyWith(
            isSupported: true,
            isLoading: false,
            showsAttention: false,
            degraded: false,
            clearSnoozedUntil: true,
            clearDiagnostics: true,
            permissionGranted: true,
            enabledCount: enabledCount,
            failure: failure,
          ),
        );
      case Right(value: final CaptureBackgroundHealth value):
        emit(
          CaptureBackgroundState(
            isSupported: true,
            isLoading: false,
            // The preconditions were just verified above, so a stale
            // `showsAttention` from the native side can never leak through.
            showsAttention: value.showsAttention,
            degraded: value.degraded,
            snoozedUntil: value.snoozedUntil,
            diagnostics: value.diagnostics,
            permissionGranted: true,
            enabledCount: enabledCount,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _incomingSub?.cancel();
    return super.close();
  }
}

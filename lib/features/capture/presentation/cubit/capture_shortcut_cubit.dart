import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/capture_shortcut.dart';
import '../../domain/usecases/get_initial_capture_shortcut.dart';
import '../../domain/usecases/watch_capture_shortcuts.dart';
import 'capture_shortcut_state.dart';

/// Holds the shortcut tapped on the home-screen widget until the app has
/// navigated to it (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// A singleton for the whole process: the tap can arrive before the first
/// frame (cold start) or long after it (the app was in the background), and
/// both have to land on the same queue. It never writes anything — the widget
/// is navigation, so the transaction the user ends up saving is still
/// `source = manual`.
@lazySingleton
class CaptureShortcutCubit extends Cubit<CaptureShortcutState> {
  CaptureShortcutCubit(
    this._getInitialCaptureShortcut,
    this._watchCaptureShortcuts,
  ) : super(const CaptureShortcutState());

  final GetInitialCaptureShortcut _getInitialCaptureShortcut;
  final WatchCaptureShortcuts _watchCaptureShortcuts;
  StreamSubscription<CaptureShortcut>? _subscription;

  /// Reads the launching shortcut (if the widget started this process) and
  /// subscribes to the ones arriving later. Safe to call more than once.
  Future<void> start() async {
    _subscription ??= _watchCaptureShortcuts().listen(_enqueue);
    final result = await _getInitialCaptureShortcut();
    // A failure here means the platform could not tell us how the app was
    // launched — the app simply opens where it always does (HU-01: never an
    // error).
    result.fold((_) {}, (shortcut) {
      if (shortcut != null) {
        _enqueue(shortcut);
      }
    });
  }

  /// Called by the listener once it has navigated (or deliberately decided
  /// not to), so the same tap is never replayed.
  void consumed() {
    if (state.pending != null) {
      emit(const CaptureShortcutState());
    }
  }

  void _enqueue(CaptureShortcut shortcut) =>
      emit(CaptureShortcutState(pending: shortcut));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

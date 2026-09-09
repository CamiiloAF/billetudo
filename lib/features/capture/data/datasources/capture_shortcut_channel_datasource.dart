import 'dart:async';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Platform-channel bridge with the native home-screen widgets
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Written by hand instead of pulling in `home_widget` (pending decision #4
/// of the requirement, resolved here): with the pure-shortcut scope there is
/// no shared data store to write, so the bridge is one string in one
/// direction — not worth a third-party dependency in a finance app.
///
/// Contract, mirrored in `QuickCaptureWidgetBridge.kt` (Android) and
/// `AppDelegate.swift` (iOS):
/// - Dart → native `getInitialShortcut` returns the shortcut id the app was
///   launched with, or `null`, and clears it so a later hot restart or a
///   resume does not replay it.
/// - Native → Dart `onShortcut` carries the shortcut id tapped while the app
///   was already running.
@lazySingleton
class CaptureShortcutChannelDatasource {
  CaptureShortcutChannelDatasource(
    @Named('captureShortcutChannel') this._channel,
  ) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Shortcut ids tapped while the app was already running.
  Stream<String> get shortcutIds => _controller.stream;

  /// The shortcut id the app was launched with, `null` on a normal launch.
  Future<String?> initialShortcutId() =>
      _channel.invokeMethod<String>('getInitialShortcut');

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != 'onShortcut') {
      return;
    }
    final id = call.arguments;
    if (id is String && id.isNotEmpty) {
      _controller.add(id);
    }
  }
}

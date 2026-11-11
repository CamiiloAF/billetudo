import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Thin wrapper over the `com.billetudo.app/capture` method channel — the only
/// door between Flutter and `BilletudoNotificationListenerService`.
///
/// It does no mapping and no error translation on purpose: it returns platform
/// shapes, the repository turns them into entities and `Failure`s. Every
/// method is a no-op with the "off" answer on non-Android platforms, since
/// this feature exists only there.
///
/// Besides the request/response calls it owns the one **push** the native side
/// sends: `onCaptureBuffered`, fired after a notification became a capture
/// while this process is alive. It is exposed as a stream and carries no
/// payload — the capture itself is only readable through
/// `drainPendingCaptures`, which empties the native buffer atomically.
@lazySingleton
class CaptureMethodChannelDatasource {
  CaptureMethodChannelDatasource()
      : _channel = const MethodChannel(channelName) {
    _listenForIncomingCaptures();
  }

  /// Injects a mock channel. The production constructor takes no arguments on
  /// purpose: the channel is not a container dependency.
  @visibleForTesting
  CaptureMethodChannelDatasource.withChannel(this._channel) {
    _listenForIncomingCaptures();
  }

  /// Must match `CaptureChannelHandler.CHANNEL` on the Kotlin side.
  static const String channelName = 'com.billetudo.app/capture';

  /// Must match the method name `CaptureChannelHandler` invokes.
  static const String incomingCaptureMethod = 'onCaptureBuffered';

  final MethodChannel _channel;
  final StreamController<void> _incoming = StreamController<void>.broadcast();

  /// Fires once per capture the native listener parks while the app runs.
  ///
  /// Broadcast so the app-level ingester and any screen that wants to refresh
  /// (the HU-09 card) can listen without stealing the event from each other.
  /// Never emits off Android: there is no native side to fire it.
  Stream<void> get incomingCaptures => _incoming.stream;

  /// Registers the native → Dart doorbell.
  ///
  /// Nothing is invoked from here: the platform sends
  /// [incomingCaptureMethod] on its own, and a failed decode or an unknown
  /// method is ignored rather than surfaced, because this is a "there may be
  /// something new" hint and never a source of truth.
  void _listenForIncomingCaptures() {
    if (!_isSupported) {
      return;
    }
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == incomingCaptureMethod) {
        _incoming.add(null);
      }
      return null;
    });
  }

  /// The one piece of platform truth that is not a channel call, so it stays
  /// correct even in a build with no native side at all.
  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  bool get _isSupported => isSupported;

  Future<bool> isPermissionGranted() async {
    if (!_isSupported) {
      return false;
    }
    final bool? granted =
        await _channel.invokeMethod<bool>('isPermissionGranted');
    return granted ?? false;
  }

  Future<void> openPermissionSettings() async {
    if (!_isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('openPermissionSettings');
  }

  Future<List<String>> getEnabledIssuers() async {
    if (!_isSupported) {
      return const <String>[];
    }
    final List<Object?>? issuers =
        await _channel.invokeMethod<List<Object?>>('getEnabledIssuers');
    return <String>[
      for (final Object? issuer in issuers ?? const <Object?>[])
        if (issuer is String) issuer,
    ];
  }

  Future<void> setEnabledIssuers(List<String> issuerIds) async {
    if (!_isSupported) {
      return;
    }
    await _channel.invokeMethod<void>(
      'setEnabledIssuers',
      <String, Object?>{'issuerIds': issuerIds},
    );
  }

  /// Returns the buffered captures and clears the buffer in the same call, so
  /// a capture cannot be read twice nor lost between two calls.
  Future<List<Map<Object?, Object?>>> drainPendingCaptures() async {
    if (!_isSupported) {
      return const <Map<Object?, Object?>>[];
    }
    final List<Object?>? raw =
        await _channel.invokeMethod<List<Object?>>('drainPendingCaptures');
    return <Map<Object?, Object?>>[
      for (final Object? entry in raw ?? const <Object?>[])
        if (entry is Map<Object?, Object?>) entry,
    ];
  }

  /// Catalogued issuers whose app is installed on this device.
  Future<List<Map<Object?, Object?>>> getInstalledIssuerApps() async {
    if (!_isSupported) {
      return const <Map<Object?, Object?>>[];
    }
    final List<Object?>? raw =
        await _channel.invokeMethod<List<Object?>>('getInstalledIssuerApps');
    return <Map<Object?, Object?>>[
      for (final Object? entry in raw ?? const <Object?>[])
        if (entry is Map<Object?, Object?>) entry,
    ];
  }

  /// Phone-side facts behind HU-09. Answers an empty map off Android, which
  /// the model maps to the empty diagnostics entity — the feature is Android
  /// only and a probe must never fail just because the platform is not.
  Future<Map<Object?, Object?>> getDiagnostics() async {
    if (!_isSupported) {
      return const <Object?, Object?>{};
    }
    final Map<Object?, Object?>? raw =
        await _channel.invokeMapMethod<Object?, Object?>('getDiagnostics');
    return raw ?? const <Object?, Object?>{};
  }

  /// Opens the battery-optimization exemption screen. No-op off Android.
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!_isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
  }

  /// Opens the OEM autostart screen (or the app details fallback). No-op off
  /// Android.
  Future<void> openAutostartSettings() async {
    if (!_isSupported) {
      return;
    }
    await _channel.invokeMethod<void>('openAutostartSettings');
  }
}

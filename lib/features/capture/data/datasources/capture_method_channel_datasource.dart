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
@lazySingleton
class CaptureMethodChannelDatasource {
  const CaptureMethodChannelDatasource()
      : _channel = const MethodChannel(channelName);

  /// Injects a mock channel. The production constructor takes no arguments on
  /// purpose: the channel is not a container dependency.
  @visibleForTesting
  const CaptureMethodChannelDatasource.withChannel(this._channel);

  /// Must match `CaptureChannelHandler.CHANNEL` on the Kotlin side.
  static const String channelName = 'com.billetudo.app/capture';

  final MethodChannel _channel;

  bool get _isSupported => defaultTargetPlatform == TargetPlatform.android;

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
}

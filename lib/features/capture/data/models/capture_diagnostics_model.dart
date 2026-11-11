import '../../domain/entities/capture_diagnostics.dart';

/// Maps the native `getDiagnostics` payload into [CaptureDiagnostics].
///
/// The payload crosses a method channel, which is an untyped boundary: a key
/// can be missing, `null`, or carry a different type after a native/Flutter
/// version skew. Every one of those cases falls back to the safe value instead
/// of throwing — a diagnostics probe is exactly the thing that must not take
/// the Avisos screen down with it.
abstract final class CaptureDiagnosticsModel {
  /// Returns [CaptureDiagnostics.empty] for a missing or empty payload.
  static CaptureDiagnostics fromMap(Map<Object?, Object?> map) {
    return CaptureDiagnostics(
      lastCaptureAtEpochMs: _asInt(map['lastCaptureAtEpochMs']),
      lastListenerConnectedAt: _asDateTime(
        map['lastListenerConnectedAtEpochMs'],
      ),
      listenerConnectedNow: _asBool(map['listenerConnectedNow']),
      batteryOptimizationExempt: _asBool(map['batteryOptimizationExempt']),
      manufacturer: _asString(map['manufacturer']),
      autostartAvailable: _asBool(map['autostartAvailable']),
    );
  }

  /// Accepts an `int` (normal), a `num` (Kotlin `Long`/`Double` skew) or a
  /// numeric string; anything else is "never captured".
  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Epoch milliseconds into a `DateTime`, tolerating the same shapes as
  /// [_asInt]. A missing, non-numeric or non-positive value means "the listener
  /// never connected", which is the safe reading: it can only ever make HU-09
  /// watch the device sooner, never claim coverage the app does not have.
  static DateTime? _asDateTime(Object? value) {
    final int? epochMs = _asInt(value);
    if (epochMs == null || epochMs <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(epochMs);
  }

  /// Only `true` and its unambiguous string form count. Everything else —
  /// including a numeric `1` — answers `false`, so an unexpected payload can
  /// never claim a state the phone is not in (an exemption it does not have, or
  /// a listener bound when it is not).
  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  static String _asString(Object? value) => value is String ? value : '';
}

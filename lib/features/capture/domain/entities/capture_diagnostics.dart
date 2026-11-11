import 'package:equatable/equatable.dart';

/// The phone-side facts behind background capture (HU-09), read from the
/// Android listener on demand.
///
/// Everything here is about **this device**, never synced: the notification
/// permission, the battery exemption and the manufacturer's autostart screen
/// are properties of the phone, and a second device with nothing granted must
/// not inherit them. That is why this is a plain entity over
/// `SharedPreferences`/`PowerManager`, not a Drift row.
///
/// [lastCaptureAtEpochMs] is a timestamp, not a notification: the listener
/// writes it when a capture is produced, and no content is involved.
class CaptureDiagnostics extends Equatable {
  const CaptureDiagnostics({
    required this.lastCaptureAtEpochMs,
    this.lastListenerConnectedAt,
    required this.batteryOptimizationExempt,
    required this.manufacturer,
    required this.autostartAvailable,
    this.listenerConnectedNow = false,
  });

  /// Nothing is known: the "off" answer on a platform without the native side,
  /// or the safe value when a read failed. The health decision must never be
  /// derived from it as if it were real data.
  const CaptureDiagnostics.empty()
      : lastCaptureAtEpochMs = null,
        lastListenerConnectedAt = null,
        batteryOptimizationExempt = false,
        manufacturer = '',
        autostartAvailable = false,
        listenerConnectedNow = false;

  /// Epoch milliseconds of the last capture the listener produced, or `null`
  /// when nothing was ever captured on this device.
  final int? lastCaptureAtEpochMs;

  /// When the system last bound the notification listener, or `null` when it
  /// never got to bind on this device.
  ///
  /// This is the **direct** signal of HU-09 and it is not derivable from
  /// [lastCaptureAtEpochMs]: a manufacturer that rejects the bind (MIUI/HyperOS
  /// does) leaves both timestamps `null`, but only this one distinguishes "the
  /// listener never got to listen" from "it listened and the banks sent
  /// nothing". The listener writes it in `onListenerConnected`, before any
  /// notification exists, so no content is involved.
  final DateTime? lastListenerConnectedAt;

  /// Whether the listener is bound to the system in the process that answered
  /// the probe. Live state, never persisted: `false` on a cold start simply
  /// means nothing has been bound yet.
  final bool listenerConnectedNow;

  /// Whether Android is already exempting the app from battery optimization.
  /// Read from `PowerManager`, never from a cached flag.
  final bool batteryOptimizationExempt;

  /// The device's manufacturer, used to name the brand in the sheet copy
  /// ("En Xiaomi, para que vuelva a escuchar").
  final String manufacturer;

  /// Whether this manufacturer has an autostart screen worth opening. `false`
  /// means the sheet must hide the whole row rather than invent a destination.
  final bool autostartAvailable;

  /// True only when the app provably captured something and the result carries
  /// that proof. Lets callers tell "never captured" from "we could not read
  /// anything", which lead to different copy.
  bool get hasCaptureHistory => lastCaptureAtEpochMs != null;

  /// [lastCaptureAtEpochMs] as a `DateTime`, in the device's local zone.
  DateTime? get lastCaptureAt => lastCaptureAtEpochMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastCaptureAtEpochMs!);

  @override
  List<Object?> get props => <Object?>[
        lastCaptureAtEpochMs,
        lastListenerConnectedAt,
        listenerConnectedNow,
        batteryOptimizationExempt,
        manufacturer,
        autostartAvailable,
      ];
}

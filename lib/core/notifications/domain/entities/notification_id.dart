import 'app_notification_channel.dart';

/// Turns a domain entity id (a UUID string) into the **stable** 32-bit
/// integer the OS keys a scheduled notification by.
///
/// Two properties matter and both are load-bearing:
///  - **Deterministic.** Rescheduling a reminder must land on the same id or
///    every `nextDate` advance would leave the previous notification alive and
///    the user would get one alert per past cycle.
///  - **Channel-partitioned.** Ids are allocated in a distinct block per
///    [AppNotificationChannel], so "cancel everything on this channel" is a
///    range check over the pending ids — `flutter_local_notifications` does
///    not report which channel a pending request belongs to.
///
/// Collisions inside a block are theoretically possible (a 23-bit space).
/// The consequence is bounded and non-destructive: two templates would share
/// one reminder slot, so one of the two notices is lost — never a wrong
/// notice for a deleted payment, and never data loss.
abstract final class NotificationId {
  /// Size of each channel's id block. Keeps every id well inside the signed
  /// 32-bit range Android requires.
  static const int blockSize = 8000000;

  static int blockStart(AppNotificationChannel channel) =>
      channel.index * blockSize;

  /// Whether [id] was allocated for [channel].
  static bool belongsTo(int id, AppNotificationChannel channel) {
    final start = blockStart(channel);
    return id >= start && id < start + blockSize;
  }

  /// Stable id for [key] (typically an entity UUID) inside [channel]'s block.
  static int forKey(String key, AppNotificationChannel channel) {
    // FNV-1a: tiny, dependency-free and well distributed over short strings.
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = (hash ^ unit) & 0xffffffff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return blockStart(channel) + hash % blockSize;
  }
}

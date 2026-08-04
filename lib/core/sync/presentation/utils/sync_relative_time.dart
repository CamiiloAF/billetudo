import '../../../l10n/gen/app_localizations.dart';

/// Renders elapsed time the way this feature contracts it: always relative
/// ("hace 3 días"), never an absolute date.
///
/// An absolute timestamp asks the user to do the subtraction, and the whole
/// point of the screen is that nobody noticed three days had passed.
abstract final class SyncRelativeTime {
  const SyncRelativeTime._();

  /// The bare duration ("3 días"), for sentences that already provide the
  /// preposition ("Lleva 3 días esperando").
  static String elapsed(AppLocalizations l10n, Duration duration) {
    if (duration.inMinutes < 1) {
      return l10n.syncDurationMoment;
    }
    if (duration.inHours < 1) {
      return l10n.syncDurationMinutes(duration.inMinutes);
    }
    if (duration.inDays < 1) {
      return l10n.syncDurationHours(duration.inHours);
    }
    return l10n.syncDurationDays(duration.inDays);
  }

  /// The same duration as a past reference ("hace 3 días").
  static String ago(AppLocalizations l10n, Duration duration) =>
      l10n.syncTimeAgo(elapsed(l10n, duration));

  /// "hace 3 días" for a point in time, clamping the future to "hace un
  /// momento": a device clock that jumped ahead must not print "hace -2 días".
  static String since(
    AppLocalizations l10n,
    DateTime moment, {
    required DateTime now,
  }) {
    final elapsedSince = now.difference(moment);
    return ago(l10n, elapsedSince.isNegative ? Duration.zero : elapsedSince);
  }
}

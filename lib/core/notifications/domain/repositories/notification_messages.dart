import '../entities/app_notification_channel.dart';

/// Localized copy for everything that leaves the app as a system
/// notification.
///
/// Exists because notifications are composed far away from a `BuildContext`
/// (a use case, a bootstrap catch-up run), and `AppLocalizations` is the only
/// allowed source of UI strings. Domain depends on this interface; `data/`
/// resolves it against the device locale.
///
/// Tone rule (`CLAUDE.md`, and it is the whole point here): inform and
/// enable, never alarm or scold. "Netflix se cobra en 3 días" — never
/// "cuidado, te van a cobrar".
abstract class NotificationMessages {
  /// User-visible Android channel name, shown in system settings.
  String channelName(AppNotificationChannel channel);

  String channelDescription(AppNotificationChannel channel);

  /// Title of a due-date reminder: the template's own name.
  String scheduledPaymentReminderTitle(String templateName);

  /// Body of a due-date reminder. [leadDays] is 0 for "the day of".
  /// [formattedAmount] arrives already money-formatted (never a `double`).
  String scheduledPaymentReminderBody({
    required int leadDays,
    required String formattedAmount,
    required String accountName,
  });

  /// Fallback title for a template with no note (mirrors
  /// `l10n.scheduledPaymentUntitled`).
  String get scheduledPaymentUntitled;
}

/// How much notice the user asked for before a scheduled payment's due date
/// (HU-08).
///
/// Persisted as the plain day count in `ScheduledPayments.reminderLeadDays`
/// (int, nullable) — an int column instead of another text enum because the
/// value is genuinely arithmetic (`nextDate - leadDays`), and because adding
/// an option later must not need a schema change.
///
/// `null` (no member of this enum) means **no reminder**, and it is the
/// default: the app does not assume everyone wants push.
enum ScheduledPaymentReminder {
  onDueDate(0),
  oneDayBefore(1),
  threeDaysBefore(3),
  oneWeekBefore(7);

  const ScheduledPaymentReminder(this.leadDays);

  /// Days before the due date this option fires. 0 = the day of the payment.
  final int leadDays;

  /// Local hour of day every reminder is delivered at. A single constant on
  /// purpose: a per-reminder time is not part of HU-08, and mid-morning is
  /// the least intrusive slot for a notice about money.
  static const int fireHour = 9;

  /// Resolves a stored lead-day count back to an option. Returns `null` for
  /// `null` (no reminder) **and** for any value outside the offered set — a
  /// row written by a future version with an option this build does not know
  /// degrades to "no reminder" instead of crashing.
  static ScheduledPaymentReminder? fromLeadDays(int? leadDays) {
    if (leadDays == null) {
      return null;
    }
    for (final option in values) {
      if (option.leadDays == leadDays) {
        return option;
      }
    }
    return null;
  }

  /// Whether [leadDays] is one of the offered options — the rule
  /// `ScheduledPaymentDraft.validated()` enforces so a template can never
  /// persist a lead the UI cannot render.
  static bool isSupportedLead(int leadDays) =>
      values.any((option) => option.leadDays == leadDays);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scheduled_payment.dart';

/// Shared, localized formatting for the "próximos vencimientos" and "por
/// confirmar" rows, kept in one place so `ScheduledCard` and
/// `ScheduledPendingRow` read identically (same precedent as
/// `BudgetFormat`).
abstract final class ScheduledPaymentFormat {
  const ScheduledPaymentFormat._();

  /// The amount's tone: income in `income-text` (green), expense in the
  /// brand's neutral `text-primary` (never red, MASTER.md), transfer neutral
  /// too — it moves money between the user's own accounts, it is not a gain
  /// or a loss.
  static Color amountColor(AppColors colors, ScheduledPaymentType type) =>
      switch (type) {
        ScheduledPaymentType.income => colors.incomeText,
        ScheduledPaymentType.expense => colors.textPrimary,
        ScheduledPaymentType.transfer => colors.textPrimary,
      };

  /// The frequency chip's text: "cada mes", "cada año"... or "Pago único"
  /// for a `once` template.
  static String frequencyLabel(
    AppLocalizations l10n,
    ScheduledPaymentFrequency frequency,
  ) =>
      switch (frequency) {
        ScheduledPaymentFrequency.once => l10n.scheduledOnceBadge,
        ScheduledPaymentFrequency.daily => l10n.scheduledFrequencyDaily,
        ScheduledPaymentFrequency.weekly => l10n.scheduledFrequencyWeekly,
        ScheduledPaymentFrequency.monthly => l10n.scheduledFrequencyMonthly,
        ScheduledPaymentFrequency.yearly => l10n.scheduledFrequencyYearly,
      };

  /// The icon for the frequency chip: a loop for anything recurring, a plain
  /// calendar for a one-off payment.
  static IconData frequencyIcon(ScheduledPaymentFrequency frequency) =>
      frequency == ScheduledPaymentFrequency.once
          ? LucideIcons.calendar1
          : LucideIcons.repeat;

  /// The "en N días" pill, comparing [nextDate] against [today] (both
  /// truncated to the day so a due date later today still reads as "Vence
  /// hoy" instead of "en 0 días").
  static String dueInLabel(
    AppLocalizations l10n,
    DateTime nextDate, {
    required DateTime today,
  }) {
    final from = DateTime(today.year, today.month, today.day);
    final to = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final days = to.difference(from).inDays;
    if (days <= 0) {
      return l10n.scheduledDueToday;
    }
    if (days == 1) {
      return l10n.scheduledDueInOneDay;
    }
    return l10n.scheduledDueInDays(days);
  }

  static String dateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(date);
  }

  /// The long form used by the detail hero's recurrence sentence, e.g.
  /// "13 de julio de 2026".
  static String longDateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// The natural-language sentence under the detail hero describing how a
  /// template repeats (or not): "Pago único el 13 de julio" for a one-off,
  /// "Se repite cada mes desde el 13 de julio, para siempre" for an
  /// open-ended recurring one, or "... hasta el 13 de julio de 2027" when it
  /// has an [ScheduledPayment.endDate].
  ///
  /// The template has no separate "first payment" field distinct from
  /// [ScheduledPayment.nextDate] (it advances only when the generator
  /// processes it — see that field's doc), so `nextDate` doubles as the
  /// anchor date for "desde el...".
  static String recurrencePhrase(
    BuildContext context,
    AppLocalizations l10n,
    ScheduledPayment payment,
  ) {
    final date = longDateLabel(context, payment.nextDate);
    if (payment.frequency == ScheduledPaymentFrequency.once) {
      return l10n.scheduledPaymentDetailRecurrenceOnce(date);
    }
    final unit =
        _recurrenceUnitPhrase(l10n, payment.frequency, payment.interval);
    final endDate = payment.endDate;
    if (endDate == null) {
      return l10n.scheduledPaymentDetailRecurrenceForever(unit, date);
    }
    return l10n.scheduledPaymentDetailRecurrenceUntil(
      unit,
      date,
      longDateLabel(context, endDate),
    );
  }

  static String _recurrenceUnitPhrase(
    AppLocalizations l10n,
    ScheduledPaymentFrequency frequency,
    int interval,
  ) =>
      switch (frequency) {
        ScheduledPaymentFrequency.once => '',
        ScheduledPaymentFrequency.daily => interval <= 1
            ? l10n.scheduledRecurrenceUnitDaily
            : l10n.scheduledRecurrenceUnitDailyInterval(interval),
        ScheduledPaymentFrequency.weekly => interval <= 1
            ? l10n.scheduledRecurrenceUnitWeekly
            : l10n.scheduledRecurrenceUnitWeeklyInterval(interval),
        ScheduledPaymentFrequency.monthly => interval <= 1
            ? l10n.scheduledRecurrenceUnitMonthly
            : l10n.scheduledRecurrenceUnitMonthlyInterval(interval),
        ScheduledPaymentFrequency.yearly => interval <= 1
            ? l10n.scheduledRecurrenceUnitYearly
            : l10n.scheduledRecurrenceUnitYearlyInterval(interval),
      };

  /// A template has no `name` field of its own (see `ScheduledPayment`): its
  /// display name is the category, falling back to the account(s) involved —
  /// same fallback `ScheduledCard` uses for its title, reused here so the
  /// confirmation sheet's head and the Posponer context line read identically.
  static String templateTitle({
    required String? categoryName,
    required bool isTransfer,
    required String accountName,
    String? transferAccountName,
  }) =>
      categoryName ??
      (isTransfer
          ? '$accountName → ${transferAccountName ?? ''}'
          : accountName);
}

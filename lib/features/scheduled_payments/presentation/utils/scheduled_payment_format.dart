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

  /// The icon for the frequency chip: a loop for anything recurring,
  /// `calendar-check` for a one-off payment (page spec — never the generic
  /// calendar, which reads as "a date" instead of "done, just once").
  static IconData frequencyIcon(ScheduledPaymentFrequency frequency) =>
      frequency == ScheduledPaymentFrequency.once
          ? LucideIcons.calendarCheck
          : LucideIcons.repeat;

  /// The "en N días" pill, comparing [nextDate] against [today] (both
  /// truncated to the day so a due date later today still reads as "Vence
  /// hoy" instead of "en 0 días").
  ///
  /// A date already in the past reads "hace N días": collapsing everything
  /// overdue into "Vence hoy" was honest only for an occurrence that just
  /// came due, and plainly wrong on a template whose date passed weeks ago.
  static String dueInLabel(
    AppLocalizations l10n,
    DateTime nextDate, {
    required DateTime today,
  }) {
    final from = DateTime(today.year, today.month, today.day);
    final to = DateTime(nextDate.year, nextDate.month, nextDate.day);
    final days = to.difference(from).inDays;
    if (days == 0) {
      return l10n.scheduledDueToday;
    }
    if (days < 0) {
      final ago = -days;
      return ago == 1
          ? l10n.scheduledDueOneDayAgo
          : l10n.scheduledDueDaysAgo(ago);
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
  /// "13 de julio de 2026" — spelled-out month so it reads as prose next to
  /// the sentence's other date, never "13 jul 2026".
  static String longDateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  /// The compact form with a year ("15 jun 2026") the "Ya generados" rows
  /// use: they span years, but the sub-line competes with the amount for
  /// width, so the month stays abbreviated there.
  static String shortDateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// The detail hero's big date, "13 de agosto, 2026" (`OY2Kj`).
  ///
  /// `yMMMMd` renders Spanish as "13 de agosto de 2026", so Spanish uses the
  /// design's explicit pattern; every other locale keeps the ICU default.
  static String heroDateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    if (locale.startsWith('es')) {
      return DateFormat("d 'de' MMMM, y", locale).format(date);
    }
    return DateFormat.yMMMMd(locale).format(date);
  }

  /// The day-and-month form the hero's natural-language sentence uses ("26 de
  /// julio"): the year is already implied by the big date above it.
  static String phraseDateLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMMd(locale).format(date);
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
    final date = phraseDateLabel(context, payment.nextDate);
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

  /// The display name of a template in the list card, the "por confirmar"
  /// rows, the detail identity strip and the confirmation/snooze sheets: the
  /// user-written [note] when there is one (the design's "Netflix", "Arriendo"),
  /// else a transfer's "origen → destino" route, else the generic [fallback]
  /// label (`l10n.scheduledPaymentUntitled`).
  ///
  /// Deliberately never falls back to the **category** name: a template has no
  /// `name` field of its own, but showing the category as the big title read as
  /// "Food & drink" where the user expected the payment's name (bugfix items
  /// 3/19). The category stays the row's *subtitle* ([accountCategoryLine]).
  static String templateName({
    required String? note,
    required bool isTransfer,
    required String accountName,
    required String fallback,
    String? transferAccountName,
  }) {
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    if (isTransfer) {
      return '$accountName → ${transferAccountName ?? ''}';
    }
    return fallback;
  }

  /// The sub-line of a card/row: "Cuenta · Categoría", or "origen → destino"
  /// for a transfer (the account data HU-04 asks for, not redundancy — see
  /// the page spec).
  static String accountCategoryLine({
    required String accountName,
    required String? categoryName,
    required bool isTransfer,
    String? transferAccountName,
  }) {
    if (isTransfer) {
      return '$accountName → ${transferAccountName ?? ''}';
    }
    if (categoryName == null || categoryName.isEmpty) {
      return accountName;
    }
    return '$accountName · $categoryName';
  }
}

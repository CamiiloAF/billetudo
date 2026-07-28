import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/goal_contribution.dart';

/// Shared, localized formatting for the Metas read screens, so the list card,
/// the detail hero and the movement rows read identically (same precedent as
/// `DebtFormat`). Never returns a `Widget`; only strings and formatted
/// amounts.
abstract final class GoalFormat {
  const GoalFormat._();

  static const MoneyFormatter _money = MoneyFormatter();

  /// The unicode minus (U+2212), matching a signed "−$50.000" — never the
  /// hyphen-minus, which reads thinner next to the `$`.
  static const String _minus = '−';

  /// A read-only positive amount, e.g. "$3.600.000".
  static String amount(int amountMinor, String currency) =>
      _money.formatSymbol(amountMinor, currencyCode: currency);

  /// A signed movement amount, "+$300.000" / "−$50.000".
  static String signedAmount(GoalContribution movement, String currency) {
    final magnitude = amount(movement.amountMinor, currency);
    return movement.direction == GoalMovementDirection.withdrawal
        ? '$_minus$magnitude'
        : '+$magnitude';
  }

  /// Compact day-and-month, "5 jul".
  static String dateShort(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(date);
  }

  /// Day-month-year, "30 dic 2027".
  static String dateLong(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Full month name, "12 de julio de 2026" — the movement detail sheet's
  /// own "Fecha" row (`N8Dv2e`), more formal than [dateLong]'s abbreviation.
  static String dateFull(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  /// "Hoy, 22 jul" when [date] is today, the plain "22 jul" otherwise — the
  /// sheets' date-field label.
  static String relativeDate(
    BuildContext context,
    AppLocalizations l10n,
    DateTime date,
  ) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final short = dateShort(context, date);
    return isToday ? l10n.goalDateToday(short) : short;
  }

  /// "en marzo" / "en marzo de 2028" — the projection's estimated month, per
  /// HU-05's "a tu ritmo, llegas en marzo" copy.
  static String monthYear(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    return date.year == now.year
        ? DateFormat.MMMM(locale).format(date)
        : DateFormat.yMMMM(locale).format(date);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_ledger_entry.dart';

/// Shared, localized formatting for the Deudas read screens, kept in one place
/// so `DebtCard`, the detail hero and the ledger rows read identically (same
/// precedent as `ScheduledPaymentFormat`).
///
/// Never returns a `Widget`; only strings, icons and formatted amounts.
abstract final class DebtFormat {
  const DebtFormat._();

  static const MoneyFormatter _money = MoneyFormatter();

  /// The unicode minus (U+2212), matching the mockup's "−$1.000.000" — never
  /// the hyphen-minus, which reads thinner next to the `$`.
  static const String _minus = '−';

  /// "Yo debo" / "Me deben".
  static String directionLabel(
    AppLocalizations l10n,
    DebtDirection direction,
  ) =>
      direction == DebtDirection.iOwe
          ? l10n.debtDirectionIOwe
          : l10n.debtDirectionOwedToMe;

  /// The directional arrow of the pill: up-right when the user owes, down-left
  /// when they are owed. Never color alone (MASTER: tone of voice).
  static IconData directionIcon(DebtDirection direction) =>
      direction == DebtDirection.iOwe
          ? LucideIcons.arrowUpRight
          : LucideIcons.arrowDownLeft;

  /// The default list icon when the debt carries none of its own (the domain
  /// `Debt` has no icon field): a hand of coins for money the user owes, a
  /// person for a loan the user gave.
  static IconData debtIcon(DebtDirection direction) =>
      direction == DebtDirection.iOwe
          ? LucideIcons.handCoins
          : LucideIcons.userRound;

  /// "X% pagado" for a debt the user owes, "X% cobrado" for one owed to them.
  static String progressLabel(
    AppLocalizations l10n,
    DebtDirection direction,
    int pct,
  ) =>
      direction == DebtDirection.iOwe
          ? l10n.debtProgressPaid(pct)
          : l10n.debtProgressCollected(pct);

  /// The single word under the hero's big percentage: "pagado" / "cobrado".
  static String progressWord(
    AppLocalizations l10n,
    DebtDirection direction,
  ) =>
      direction == DebtDirection.iOwe
          ? l10n.debtDetailPaidLabel
          : l10n.debtDetailCollectedLabel;

  /// A read-only positive amount, e.g. "$28.500.000".
  static String amount(int amountMinor, String currency) =>
      _money.formatSymbol(amountMinor, currencyCode: currency);

  /// A signed ledger amount, "+$42.000.000" / "−$1.000.000". The sign is drawn
  /// by hand (magnitude formatted, sign prepended) because the formatter would
  /// otherwise place the minus between `$` and the digits.
  static String signedAmount(int effectMinor, String currency) {
    final magnitude = _money.formatSymbol(effectMinor.abs(), currencyCode: currency);
    return effectMinor < 0 ? '$_minus$magnitude' : '+$magnitude';
  }

  /// Compact day-and-month, "5 jul" — the card meta and the ledger row date.
  static String dateShort(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('d MMM', locale).format(date);
  }

  /// Day-month-year, "30 dic 2027" — the detail meta card's due row, which has
  /// room for the year.
  static String dateLong(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  /// The date-field label of the sheets: "Hoy, 22 jul" when [date] is today,
  /// the plain "22 jul" otherwise.
  static String relativeDate(
    BuildContext context,
    AppLocalizations l10n,
    DateTime date,
  ) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final short = dateShort(context, date);
    return isToday ? l10n.debtDateToday(short) : short;
  }

  /// "Crédito vehicular · Yo debo": the debt name + its direction, the context
  /// subtitle of the abono / actualizar-saldo sheets and the link banner.
  static String context(
    AppLocalizations l10n,
    String name,
    DebtDirection direction,
  ) =>
      l10n.debtContext(name, directionLabel(l10n, direction));

  /// The ledger row's title, derived from its kind and the debt's direction
  /// (an owedToMe reduction is a "Pago recibido", not an "Abono").
  static String ledgerTitle(
    AppLocalizations l10n,
    DebtLedgerEntry entry,
    DebtDirection direction,
  ) {
    switch (entry.kind) {
      case DebtLedgerKind.opening:
        return l10n.debtLedgerOpening;
      case DebtLedgerKind.cashDisbursement:
      case DebtLedgerKind.ledgerDisbursement:
        return l10n.debtLedgerDisbursement;
      case DebtLedgerKind.cashPayment:
      case DebtLedgerKind.ledgerPayment:
        return direction == DebtDirection.iOwe
            ? l10n.debtLedgerPaymentOwe
            : l10n.debtLedgerPaymentOwed;
      case DebtLedgerKind.interestAccrual:
        return l10n.debtLedgerInterest;
      case DebtLedgerKind.manualAdjustment:
        return l10n.debtLedgerAdjustment;
    }
  }

  /// The ledger row icon, matching the design's per-kind glyphs.
  static IconData ledgerIcon(DebtLedgerKind kind) {
    switch (kind) {
      case DebtLedgerKind.opening:
      case DebtLedgerKind.cashDisbursement:
      case DebtLedgerKind.ledgerDisbursement:
        return LucideIcons.banknoteArrowUp;
      case DebtLedgerKind.cashPayment:
      case DebtLedgerKind.ledgerPayment:
        return LucideIcons.banknoteArrowDown;
      case DebtLedgerKind.interestAccrual:
        return LucideIcons.trendingUp;
      case DebtLedgerKind.manualAdjustment:
        return LucideIcons.slidersHorizontal;
    }
  }

  /// The small tag on a solo-deuda row ("Estimado" for interest, "No afecta
  /// cuentas" for cash-less events); `null` for cash rows, which need no tag.
  static String? ledgerTag(AppLocalizations l10n, DebtLedgerEntry entry) {
    if (entry.isCashEvent) {
      return null;
    }
    return entry.kind == DebtLedgerKind.interestAccrual
        ? l10n.debtLedgerTagEstimated
        : l10n.debtLedgerTagNoAccount;
  }
}

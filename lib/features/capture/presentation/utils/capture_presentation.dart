import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// The amount label of a pending capture (`Rhix1`).
///
/// Deliberately **not** `signedAmountLabel`: the frame prints an expense
/// capture unsigned (`$58.470`) and only an income keeps its `+`. A `-` would
/// read as money already subtracted, which is exactly what a capture is not.
/// The attenuation to `$text-secondary` is the widget's job, not this
/// function's.
String captureAmountLabel({
  required int amountMinor,
  required String currencyCode,
  required TransactionType type,
}) {
  final formatted = const MoneyFormatter().formatSymbol(
    amountMinor,
    currencyCode: currencyCode,
  );
  return type == TransactionType.income ? '+$formatted' : formatted;
}

/// "Hoy, 8:32 a. m." — the day, relative when it is today or yesterday, plus
/// the time the issuer said the movement was posted.
String captureWhenLabel(AppLocalizations l10n, DateTime postedAt) {
  final today = DateUtils.dateOnly(clock.now());
  final day = DateUtils.dateOnly(postedAt);
  final String dayLabel;
  if (DateUtils.isSameDay(day, today)) {
    dayLabel = l10n.transactionsGroupToday;
  } else if (DateUtils.isSameDay(day, today.subtract(const Duration(days: 1)))) {
    dayLabel = l10n.transactionsGroupYesterday;
  } else {
    dayLabel = DateFormat("d 'de' MMMM", 'es_CO').format(day);
  }
  return '$dayLabel, ${DateFormat('h:mm a', 'es_CO').format(postedAt)}';
}

/// The icon inside a capture card's tile (`W5UTdc`).
///
/// An income shows the incoming arrow; everything else keeps `bell-ring`, the
/// mark of "this arrived as a notice, it is not a movement yet". The frame
/// also draws an outgoing arrow on one specific mockup row (a Bre-B
/// transfer), but nothing on `PendingCapture` distinguishes that from an
/// ordinary expense — a capture can never be a `transfer` — so deriving it
/// would mean guessing from the merchant text.
IconData captureIcon(TransactionType type) => type == TransactionType.income
    ? LucideIcons.arrowDownLeft
    : LucideIcons.bellRing;

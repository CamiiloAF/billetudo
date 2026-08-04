import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';

/// The signed amount label shown by every transaction row (Movimientos,
/// Inicio): expense `-$X`, income `+$X`, transfer unsigned. Shared by
/// `TransactionRow` and `RecentActivityRow` so the sign convention only lives
/// in one place.
String transactionAmountLabel(Transaction transaction) => signedAmountLabel(
      amountMinor: transaction.amountMinor,
      currencyCode: transaction.currency,
      type: transaction.type,
    );

/// The same sign convention as [transactionAmountLabel], but for any
/// `amountMinor`/`currencyCode`/`type` triple — e.g. a date group's summed
/// total (`transaction_group_total.dart`), not just a single [Transaction].
String signedAmountLabel({
  required int amountMinor,
  required String currencyCode,
  required TransactionType type,
}) {
  final formatted = const MoneyFormatter().formatSymbol(
    amountMinor,
    currencyCode: currencyCode,
  );
  return switch (type) {
    TransactionType.income => '+$formatted',
    TransactionType.expense => '-$formatted',
    TransactionType.transfer => formatted,
  };
}

/// An expense reads in `$text-primary`, not red — red is reserved for
/// destructive actions ("Eliminar"), never for a normal expense amount.
Color transactionAmountColor(AppColors colors, TransactionType type) =>
    switch (type) {
      TransactionType.income => colors.incomeText,
      TransactionType.expense => colors.textPrimary,
      TransactionType.transfer => colors.textPrimary,
    };

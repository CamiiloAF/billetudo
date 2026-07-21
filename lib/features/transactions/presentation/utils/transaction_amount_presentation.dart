import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction.dart';

/// The signed amount label shown by every transaction row (Movimientos,
/// Inicio): expense `-$X`, income `+$X`, transfer unsigned. Shared by
/// `TransactionRow` and `RecentActivityRow` so the sign convention only lives
/// in one place.
String transactionAmountLabel(Transaction transaction) {
  final formatted = const MoneyFormatter().formatSymbol(
    transaction.amountMinor,
    currencyCode: transaction.currency,
  );
  return switch (transaction.type) {
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

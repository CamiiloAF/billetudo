import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/account_balance.dart';

/// How much of a card's credit limit is in use.
///
/// Over the limit the bar fills completely and turns `$expense`: there is no
/// "more than full", and the colour is the one case where red is the honest
/// signal (a real overspend), not a judgement on spending.
class CreditUsageBar extends StatelessWidget {
  const CreditUsageBar({
    required this.balance,
    required this.creditLimitMinor,
    this.height = 8,
    super.key,
  });

  final AccountBalance balance;
  final int creditLimitMinor;
  final double height;

  /// 0..1 of the limit that is owed.
  double get usedFraction {
    if (balance.overLimit) {
      return 1;
    }
    if (creditLimitMinor <= 0) {
      return 0;
    }
    // Integer cents in, a ratio out: the division is for painting only, never
    // for money.
    return (balance.debtMinor / creditLimitMinor).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: usedFraction,
        minHeight: height,
        backgroundColor: colors.muted,
        valueColor: AlwaysStoppedAnimation<Color>(
          balance.overLimit ? colors.expense : colors.primary,
        ),
      ),
    );
  }
}

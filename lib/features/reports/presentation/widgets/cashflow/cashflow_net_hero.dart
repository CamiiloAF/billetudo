import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../utils/reports_money_format.dart';
import 'cashflow_hero_stat.dart';
import 'cashflow_negative_balance_explainer.dart';

/// The `Cashflow Net Hero` component (`hLmoN`): the headline net figure of
/// HU-01, plus its explanation and outward link — **off by default**, only
/// shown for a negative balance (see "Balance negativo" in
/// `design-system/billetudo/pages/graficas.md`).
///
/// Color is never a judgement: a positive net is `$income-text`, a negative
/// one is `$text-primary` — **never `$expense`** (criterion 26). Short
/// history (HU-06) overrides the label to "Balance de tus primeros N días"
/// regardless of sign.
class CashflowNetHero extends StatelessWidget {
  const CashflowNetHero({
    required this.netMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.periodPhrase,
    this.isShortHistory = false,
    this.shortHistoryDays = 0,
    this.onViewCategories,
    this.currencyCode = 'COP',
    super.key,
  });

  final int netMinor;
  final int incomeMinor;
  final int expenseMinor;

  /// Prebuilt phrase such as "los últimos 6 meses" (see
  /// `ReportsPeriodFormat`/l10n `reportsCashflowPeriodPhrase*`).
  final String periodPhrase;

  final bool isShortHistory;
  final int shortHistoryDays;
  final VoidCallback? onViewCategories;
  final String currencyCode;

  bool get _isNegative => netMinor < 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    final valueColor = _isNegative ? colors.textPrimary : colors.incomeText;
    final (icon, label) = isShortHistory
        ? (
            LucideIcons.sparkles,
            l10n.reportsCashflowShortHistoryLabel(shortHistoryDays),
          )
        : _isNegative
            ? (LucideIcons.scale, l10n.reportsCashflowNegativeLabel(periodPhrase))
            : (
                LucideIcons.trendingUp,
                l10n.reportsCashflowPositiveLabel(periodPhrase),
              );
    final iconColor = _isNegative || isShortHistory
        ? colors.textSecondary
        : colors.incomeText;

    final semanticsLabel = '$label. ${ReportsMoneyFormat.signed(
      netMinor,
      currencyCode: currencyCode,
    )}. ${l10n.reportsCashflowIncomeLabel}: '
        '${money.formatSymbol(incomeMinor, currencyCode: currencyCode)}. '
        '${l10n.reportsCashflowExpenseLabel}: '
        '${money.formatSymbol(expenseMinor, currencyCode: currencyCode)}.';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              ReportsMoneyFormat.signed(netMinor, currencyCode: currencyCode),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                CashflowHeroStat(
                  label: l10n.reportsCashflowIncomeLabel,
                  value: money.formatSymbol(incomeMinor, currencyCode: currencyCode),
                ),
                const SizedBox(width: 20),
                CashflowHeroStat(
                  label: l10n.reportsCashflowExpenseLabel,
                  value: money.formatSymbol(expenseMinor, currencyCode: currencyCode),
                ),
              ],
            ),
            if (_isNegative && onViewCategories != null) ...[
              const SizedBox(height: 6),
              CashflowNegativeBalanceExplainer(
                explanation: l10n.reportsCashflowNegativeExplainer(
                  money.formatSymbol(expenseMinor - incomeMinor, currencyCode: currencyCode),
                  periodPhrase,
                ),
                onViewCategories: onViewCategories!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

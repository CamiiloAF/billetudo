import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_balance.dart';
import '../utils/debt_format.dart';
import 'debt_direction_pill.dart';
import 'debt_progress_bar.dart';

/// The detail's compact hero (`E7TQkJ`): direction pill + currency chip, the
/// outstanding balance big, the percentage paid/collected as co-protagonist,
/// and the progress bar.
class DebtHeroCard extends StatelessWidget {
  const DebtHeroCard({required this.debt, required this.balance, super.key});

  final Debt debt;
  final DebtBalance balance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final pct = (balance.progress * 100).round();
    final hasInterest = balance.interestAccruedMinor > 0;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fix 5: once the debt is closed, the pill switches to the
              // neutral/past-tense treatment — same rule `DebtCard` already
              // applies in the closed tab (`debt_direction_pill.dart`).
              DebtDirectionPill(
                  direction: debt.direction, closed: debt.isClosed),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  debt.currency,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.debtDetailBalanceLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      DebtFormat.amount(
                          balance.outstandingMinor, debt.currency),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (balance.displayTotalMinor > 0)
                      Text(
                        l10n.debtAmountOf(
                          DebtFormat.amount(
                            balance.displayTotalMinor,
                            debt.currency,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.debtPercentValue(pct),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: colors.primaryOnSoft,
                    ),
                  ),
                  Text(
                    DebtFormat.progressWord(
                      l10n,
                      debt.direction,
                      hasInterest: hasInterest,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          DebtProgressBar(value: balance.progress, height: 14),
          if (hasInterest) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 13,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.debtInterestAccruedNote(
                      DebtFormat.amount(
                        balance.interestAccruedMinor,
                        debt.currency,
                      ),
                    ),
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
          ],
        ],
      ),
    );
  }
}

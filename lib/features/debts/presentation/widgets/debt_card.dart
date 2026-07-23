import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/debt_with_balance.dart';
import '../utils/debt_format.dart';
import 'debt_direction_pill.dart';
import 'debt_installment_badge.dart';
import 'debt_progress_bar.dart';

/// One row of the debts list (`xSpw7`): icon-wrap, name + direction pill,
/// counterparty, outstanding balance over the original, progress bar, and — on
/// the meta row — the percentage paid/collected next to either the "Cuota ·
/// <fecha>" badge (`tHLtM`, when the debt has a linked cuota) or the "Vence …"
/// line (when it only has a `dueDate`).
class DebtCard extends StatelessWidget {
  const DebtCard({required this.entry, this.onTap, super.key});

  final DebtWithBalance entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final debt = entry.debt;
    final balance = entry.balance;
    final pct = (balance.progress * 100).round();
    final dueDate = debt.dueDate;
    final installment = entry.installment;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      DebtFormat.debtIcon(debt.direction),
                      size: 22,
                      color: colors.primaryOnSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DebtDirectionPill(direction: debt.direction),
                          ],
                        ),
                        if (debt.counterparty != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            debt.counterparty!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      DebtFormat.amount(balance.outstandingMinor, debt.currency),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (balance.totalIncreasesMinor > 0)
                    Text(
                      l10n.debtAmountOf(
                        DebtFormat.amount(
                          balance.totalIncreasesMinor,
                          debt.currency,
                        ),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DebtProgressBar(value: balance.progress),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: installment != null
                          ? DebtInstallmentBadge(
                              label: l10n.debtInstallmentBadge(
                                DebtFormat.dateShort(
                                  context,
                                  installment.nextDate,
                                ),
                              ),
                            )
                          : dueDate != null
                              ? Text(
                                  l10n.debtDueOn(
                                    DebtFormat.dateShort(context, dueDate),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DebtFormat.progressLabel(l10n, debt.direction, pct),
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
        ),
      ),
    );
  }
}

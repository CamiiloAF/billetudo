import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/debt_with_balance.dart';
import '../utils/debt_format.dart';
import 'debt_closed_status_badge.dart';
import 'debt_direction_pill.dart';
import 'debt_installment_badge.dart';
import 'debt_progress_bar.dart';

/// One row of the debts list (`xSpw7`): icon-wrap, name + direction pill,
/// counterparty, outstanding balance over the original, progress bar, and — on
/// the meta row — the percentage paid/collected next to either the "Cuota ·
/// <fecha>" badge (`tHLtM`, when the debt has a linked cuota) or the "Vence …"
/// line (when it only has a `dueDate`).
///
/// [closed] (extension, HU-07) swaps the direction pill and the meta badge for
/// their closed-tab treatment (`vaNHd`): a past-tense neutral pill, a
/// "Pagada"/"Cerrada" status badge instead of the cuota/vencimiento one, and a
/// dimmed progress bar when the debt closed with a balance still pending.
class DebtCard extends StatelessWidget {
  const DebtCard({
    required this.entry,
    this.onTap,
    this.closed = false,
    super.key,
  });

  final DebtWithBalance entry;
  final VoidCallback? onTap;
  final bool closed;

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
    final closedAt = debt.closedAt;

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
                      color: closed ? colors.muted : colors.primarySoft,
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
                            DebtDirectionPill(
                              direction: debt.direction,
                              closed: closed,
                            ),
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
                      DebtFormat.amount(
                          balance.outstandingMinor, debt.currency),
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
                  if (balance.displayTotalMinor > 0)
                    Text(
                      l10n.debtAmountOf(
                        DebtFormat.amount(
                          balance.displayTotalMinor,
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
              DebtProgressBar(
                value: balance.progress,
                color: closed && !balance.settled ? colors.textSecondary : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: closed && closedAt != null
                          ? DebtClosedStatusBadge(
                              settled: balance.settled,
                              label: balance.settled
                                  ? l10n.debtCardStatusPaid(
                                      DebtFormat.dateShort(context, closedAt),
                                    )
                                  : l10n.debtCardStatusClosed(
                                      DebtFormat.dateShort(context, closedAt),
                                    ),
                            )
                          : installment != null
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
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
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

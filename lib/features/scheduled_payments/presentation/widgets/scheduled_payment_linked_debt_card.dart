import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/scheduled_payment_linked_debt.dart';

/// The "Deuda Enlazada" card (`M7Ijh`) shown on a cuota's detail (HU-03): a
/// `landmark` icon, a "Cuota de" label over "<debt> · <direction>", and a
/// chevron. Tapping it deep-links into the owning debt's detail. Same chrome
/// as the detail's Ficha card.
class ScheduledPaymentLinkedDebtCard extends StatelessWidget {
  const ScheduledPaymentLinkedDebtCard({
    required this.debt,
    required this.onTap,
    super.key,
  });

  final ScheduledPaymentLinkedDebt debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.landmark,
                  size: 20,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scheduledPaymentDetailLinkedDebtLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.debtContext(
                        debt.name,
                        debt.iOwe
                            ? l10n.debtDirectionIOwe
                            : l10n.debtDirectionOwedToMe,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction_edit_impact.dart';

/// HU-04's edit-impact warning: shown when a pending edit would desync the
/// transaction from a linked scheduled-payment/goal/debt. Never blocks the save —
/// only [onConfirm] does it, informed.
class EditImpactWarningSheet extends StatelessWidget {
  const EditImpactWarningSheet({
    required this.impact,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final TransactionEditImpact impact;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.amberSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(LucideIcons.link, color: colors.amber, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.transactionEditImpactTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (impact.affectsScheduledPayment)
              Text(
                l10n.transactionEditImpactScheduled,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            if (impact.affectsGoal)
              Text(
                l10n.transactionEditImpactGoal,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            if (impact.affectsDebt)
              Text(
                l10n.transactionEditImpactDebt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: Text(l10n.transactionEditImpactConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

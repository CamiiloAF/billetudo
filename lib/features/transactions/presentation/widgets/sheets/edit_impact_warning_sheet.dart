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
                // Informative, not destructive (`L9DJI`): the same
                // `primary-soft`/`primary-on-soft` treatment as the rest of
                // this feature's informational states — never the warning
                // amber, which is reserved for genuinely risky actions.
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                LucideIcons.link2,
                color: colors.primaryOnSoft,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Pencil (`L9DJI`/`j8W9a`) has no separate title here — the
            // `Sheet Icon Header`'s title (`lmN3k`) is left disabled, only
            // its 15/500 message (`FxD3p`) is shown, as a single paragraph
            // naming every linked relation that applies.
            Text(
              l10n.transactionEditImpactMessage(_links(l10n)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textPrimary,
              ),
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
                    child: Text(l10n.commonContinue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Joins the localized names of every linked relation that applies, in
  /// prose form ("a, b y c" / "a, b and c"), for the message placeholder.
  String _links(AppLocalizations l10n) {
    final fragments = [
      if (impact.affectsScheduledPayment)
        l10n.transactionEditImpactLinkScheduled,
      if (impact.affectsGoal) l10n.transactionEditImpactLinkGoal,
      if (impact.affectsDebt) l10n.transactionEditImpactLinkDebt,
    ];
    if (fragments.length <= 1) {
      return fragments.join();
    }
    final allButLast = fragments.sublist(0, fragments.length - 1).join(', ');
    return '$allButLast ${l10n.commonAnd} ${fragments.last}';
  }
}

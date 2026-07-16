import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';

/// HU-05's delete confirmation. Shown from `TransactionDetailState.deletePrompt`
/// — the caller must clear that flag in the very same emission that also
/// signals the delete went through, or this reopens on the way out (see
/// `TransactionDetailCubit.confirmDelete`).
class ConfirmDeleteTransactionSheet extends StatelessWidget {
  const ConfirmDeleteTransactionSheet({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

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
                color: colors.muted,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.delete_outline,
                color: colors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.transactionDeleteTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.transactionDeleteMessage,
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
                    child: Text(l10n.commonDelete),
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

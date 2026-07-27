import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

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

  /// Opens the sheet via [BottomSheetBase.show], which covers the bottom
  /// nav bar even when the detail page sits under a nested navigator.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => ConfirmDeleteTransactionSheet(
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.triangleAlert,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          message: l10n.transactionDeleteMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: onCancel,
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(backgroundColor: colors.expense),
            icon: const Icon(LucideIcons.trash2),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}

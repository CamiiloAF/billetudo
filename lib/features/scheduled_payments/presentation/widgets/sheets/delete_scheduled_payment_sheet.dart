import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-05's delete confirmation: stopping future generation while preserving
/// the historical reference on transactions already generated (criterion
/// 12) — the copy makes that explicit so the user does not fear losing their
/// history.
class DeleteScheduledPaymentSheet extends StatelessWidget {
  const DeleteScheduledPaymentSheet({
    required this.onConfirm,
    required this.onCancel,
    this.isInstallment = false,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  /// When this template is a debt's cuota (`debtId != null`, HU-03), the
  /// confirmation copy talks about the cuota and its debt instead of a plain
  /// scheduled payment — matching the "Eliminar cuota" wording of the action
  /// that opened it.
  final bool isInstallment;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
    bool isInstallment = false,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => DeleteScheduledPaymentSheet(
          onConfirm: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          onCancel: Navigator.of(context).pop,
          isInstallment: isInstallment,
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
          // Destructive, so it wears the destructive tone: `$expense` on
          // `$expense-soft` with an `alert-triangle`. A delete that looks
          // exactly like "Confirmar" is the risk this avoids.
          icon: LucideIcons.triangleAlert,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          title: isInstallment
              ? l10n.scheduledDeleteSheetTitleInstallment
              : l10n.scheduledDeleteSheetTitle,
          message: isInstallment
              ? l10n.scheduledDeleteSheetMessageInstallment
              : l10n.scheduledDeleteSheetMessage,
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(
              onPressed: onCancel, child: Text(l10n.commonCancel)),
          right: FilledButton.icon(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: colors.expense,
              foregroundColor: colors.onPrimary,
            ),
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}

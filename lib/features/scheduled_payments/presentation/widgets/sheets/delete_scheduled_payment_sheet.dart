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
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => DeleteScheduledPaymentSheet(
          onConfirm: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          onCancel: Navigator.of(context).pop,
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
          icon: LucideIcons.trash,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.scheduledDeleteSheetTitle,
          message: l10n.scheduledDeleteSheetMessage,
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(onPressed: onCancel, child: Text(l10n.commonCancel)),
          right: FilledButton(onPressed: onConfirm, child: Text(l10n.commonDelete)),
        ),
      ],
    );
  }
}

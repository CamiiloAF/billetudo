import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/bottom_sheet_base.dart';
import '../../../../widgets/sheet_buttons_row.dart';

/// Confirms discarding one quarantined operation (`qZvmL`).
///
/// The only genuinely destructive sheet of this feature, so it wears
/// `$expense` like `ConfirmDeleteAccountSheet`. Its message is explicit about
/// scope on purpose: this drops the local record of *one* held-back write,
/// not the rest of what is on the phone.
class ConfirmDiscardQuarantinedChangeSheet extends StatelessWidget {
  const ConfirmDiscardQuarantinedChangeSheet({super.key});

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const ConfirmDiscardQuarantinedChangeSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.triangleAlert,
          iconColor: colors.expense,
          iconBackground: colors.expenseSoft,
          title: l10n.syncDiscardConfirmTitle,
          message: l10n.syncDiscardConfirmMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.expense),
            icon: const Icon(LucideIcons.trash2),
            label: Text(l10n.syncDetailDiscard),
          ),
        ),
      ],
    );
  }
}

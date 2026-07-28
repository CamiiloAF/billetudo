import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// Confirms deleting a single goal movement (`arr2T`/`H2ND7O`/`xCNxM`,
/// + their transfer/manual/meta-cumplida copy variants built by
/// `GoalMovementDeleteCopy`). Unlike `ConfirmDeleteGoalSheet`, the primary
/// button keeps the brand `$primary` (not `$expense`) — this is Pencil's own
/// choice for this sheet, not an oversight (see `billetudo.pen`'s `qfTBg`
/// override on these three frames).
class ConfirmDeleteGoalMovementSheet extends StatelessWidget {
  const ConfirmDeleteGoalMovementSheet({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) =>
            ConfirmDeleteGoalMovementSheet(title: title, message: message),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.trash2,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: title,
          message: message,
          messageColor: colors.textSecondary,
          messageFontSize: 14,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.trash2),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}

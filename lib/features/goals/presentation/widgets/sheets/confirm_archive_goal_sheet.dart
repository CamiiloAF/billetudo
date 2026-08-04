import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-09: confirms archiving/unarchiving a goal. Never destructive — the
/// primary button keeps the brand `$primary` tone (unlike delete's `$expense`).
class ConfirmArchiveGoalSheet extends StatelessWidget {
  const ConfirmArchiveGoalSheet({required this.archiving, super.key});

  /// `true` = archiving a goal in progress; `false` = bringing one back.
  final bool archiving;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context, {required bool archiving}) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => ConfirmArchiveGoalSheet(archiving: archiving),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: archiving ? LucideIcons.archive : LucideIcons.archiveRestore,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: archiving
              ? l10n.goalArchiveSheetTitle
              : l10n.goalUnarchiveSheetTitle,
          message: archiving
              ? l10n.goalArchiveSheetMessage
              : l10n.goalUnarchiveSheetMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              archiving ? l10n.goalArchiveConfirm : l10n.goalUnarchiveConfirm,
            ),
          ),
        ),
      ],
    );
  }
}

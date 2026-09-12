import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// Confirms turning "Dejar que el asistente lea mis notas" **on**
/// (`AppSettings.aiNotesAccessEnabled`).
///
/// Only the ON direction is confirmed: this is the moment the free-text note
/// starts travelling to a third party (Google Gemini), named explicitly here
/// rather than after the fact. Turning it back off never asks — withdrawing a
/// permission is immediate by design.
///
/// A sheet, not a centred dialog: confirmations on mobile are always sheets
/// (`design-system/billetudo/MASTER.md`). The icon is the assistant's own
/// `sparkles` in `$primary`, not a warning triangle — enabling this is a
/// choice the user is entitled to make, not a mistake to scare them out of.
class AiNotesAccessSheet extends StatelessWidget {
  const AiNotesAccessSheet({super.key});

  /// Resolves to `true` when the user confirms turning the access on.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const AiNotesAccessSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.sparkles,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.settingsAiNotesAccessSheetTitle,
          message: l10n.settingsAiNotesAccessSheetMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsAiNotesAccessSheetConfirm),
          ),
        ),
      ],
    );
  }
}

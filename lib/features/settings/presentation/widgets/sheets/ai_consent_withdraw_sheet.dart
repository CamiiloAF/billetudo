import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// Confirms withdrawing the AI assistant's data-sharing consent
/// (`AppSettings.aiConsentAcceptedAt`) — RGPD art. 7.3.
///
/// A sheet, not a centred dialog: confirmations on mobile are always sheets
/// (`design-system/billetudo/MASTER.md`). No `billetudo.pen` frame covers this
/// yet — the whole "Asistente de IA" block of Ajustes predates any frame — so
/// it is built from the exact pieces `AiNotesAccessSheet` already uses:
/// `Bottom Sheet Base` (`PqTUt`) + `Sheet Icon Header` + `Sheet Buttons Row`
/// (`Ot4yI`).
///
/// Deliberately **not** the `Delete Link` treatment (`u0THG`, `$expense-text`
/// + trash): nothing is being destroyed and nobody is making a mistake.
/// Withdrawing a permission is a legitimate choice, so the icon is a neutral
/// `shield-off` on `$muted` and the confirming button is the plain neutral
/// one, not a red destructive CTA. The copy states the two real consequences
/// (the assistant closes, the notes switch turns off) and that it can be
/// turned back on.
class AiConsentWithdrawSheet extends StatelessWidget {
  const AiConsentWithdrawSheet({super.key});

  /// Resolves to `true` when the user confirms the withdrawal.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (context) => const AiConsentWithdrawSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.shieldOff,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          title: l10n.settingsAiConsentWithdrawSheetTitle,
          message: l10n.settingsAiConsentWithdrawSheetMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsAiConsentWithdrawSheetConfirm),
          ),
        ),
      ],
    );
  }
}

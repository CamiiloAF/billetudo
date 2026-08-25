import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// HU-02/HU-03, the inverse of HU-04: blocks completing a Google/Apple
/// sign-in when this device already holds local data owned by a *different*
/// account.
///
/// Genuinely blocking, unlike every other sheet in this feature (no
/// Pencil frame exists yet for this exact composition — it reuses the same
/// `Sheet Icon Header`/`Sheet Buttons Row` pattern `ConfirmDeleteAccountSheet`
/// and `ConfirmDiscardQuarantinedChangeSheet` already use in `billetudo.pen`,
/// pending a dedicated frame/fidelity pass): no scrim tap, no drag-to-dismiss,
/// no Android back button/edge-swipe can close it — only its own two buttons
/// do (`BottomSheetBase.show` with `isDismissible`/`enableDrag: false`).
///
/// Neither button is preselected: both render with the same weight the
/// pattern already gives OutlinedButton/FilledButton, no `autofocus`. The
/// message never names or hints at which account owns the conflicting data.
class ConfirmAccountConflictSheet extends StatelessWidget {
  const ConfirmAccountConflictSheet({super.key});

  /// Resolves to `true` when the user picks "Borrar y continuar" (wipe this
  /// device and complete the sign-in), `false` when they cancel (close the
  /// just-exchanged session and keep this device's existing data). Never
  /// resolves to `null` — there is no dismissible path out of this sheet.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => const ConfirmAccountConflictSheet(),
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
          title: l10n.authAccountConflictTitle,
          message: l10n.authAccountConflictMessage,
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
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.authAccountConflictConfirmCta,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

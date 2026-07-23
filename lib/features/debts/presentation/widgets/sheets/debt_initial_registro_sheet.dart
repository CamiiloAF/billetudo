import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// What the user chose on the registro-inicial sheet (`EXQfv`, item 2).
enum DebtInitialRegistroChoice {
  /// "No, solo la deuda": create the debt with its opening figure, no movement.
  soloDeuda,

  /// "Sí, elegir cuenta": pick an account and create the debt with an opening
  /// movement that moves it.
  chooseAccount,
}

/// Asks whether to create a registro inicial when saving a new debt (item 2,
/// `EXQfv`). Not destructive, so the header wears the brand `wallet` in
/// `$primary`/`$primary-soft` — never `$expense`. Dismissing the sheet resolves
/// to `null` (abort: nothing is created).
class DebtInitialRegistroSheet extends StatelessWidget {
  const DebtInitialRegistroSheet({super.key});

  /// Resolves to the chosen action, or `null` when dismissed.
  static Future<DebtInitialRegistroChoice?> show(BuildContext context) =>
      BottomSheetBase.show<DebtInitialRegistroChoice>(
        context,
        builder: (context) => const DebtInitialRegistroSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.wallet,
          iconColor: colors.primary,
          iconBackground: colors.primarySoft,
          title: l10n.debtInitialRegistroTitle,
          message: l10n.debtInitialRegistroMessage,
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(
              DebtInitialRegistroChoice.soloDeuda,
            ),
            child: Text(l10n.debtInitialRegistroSoloDeuda),
          ),
          right: FilledButton(
            onPressed: () => Navigator.of(context).pop(
              DebtInitialRegistroChoice.chooseAccount,
            ),
            child: Text(l10n.debtInitialRegistroChooseAccount),
          ),
        ),
      ],
    );
  }
}

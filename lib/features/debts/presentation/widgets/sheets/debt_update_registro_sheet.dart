import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// Confirms syncing a debt's linked opening movement after its opening figure
/// changed on edit (item 2b, `hLe9z`). Neutral action → `arrow-left-right` in
/// `$primary`/`$primary-soft`. Resolves to `true` when the user confirms.
class DebtUpdateRegistroSheet extends StatelessWidget {
  const DebtUpdateRegistroSheet({
    required this.fromLabel,
    required this.toLabel,
    super.key,
  });

  /// Already-formatted current and new amounts, for the "de $X a $Y" message.
  final String fromLabel;
  final String toLabel;

  /// Resolves to `true` when the user chooses to update the movement too.
  static Future<bool?> show(
    BuildContext context, {
    required String fromLabel,
    required String toLabel,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => DebtUpdateRegistroSheet(
          fromLabel: fromLabel,
          toLabel: toLabel,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.arrowLeftRight,
          iconColor: colors.primary,
          iconBackground: colors.primarySoft,
          title: l10n.debtUpdateRegistroTitle,
          message: l10n.debtUpdateRegistroMessage(fromLabel, toLabel),
        ),
        const SizedBox(height: 24),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.check),
            label: Text(l10n.debtUpdateRegistroConfirm),
          ),
        ),
      ],
    );
  }
}

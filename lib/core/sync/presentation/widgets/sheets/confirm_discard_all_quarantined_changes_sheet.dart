import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/bottom_sheet_base.dart';
import '../../../../widgets/sheet_buttons_row.dart';

/// Confirms discarding every quarantined operation at once (`EtwDY`).
///
/// Same destructive pattern as `ConfirmDiscardQuarantinedChangeSheet`
/// (`qZvmL`) — `$expense` icon and button — but pluralized around [count]:
/// the title and message spell out how many writes are about to go, and are
/// explicit that this drops only the local record of *those specific*
/// operations, never the rest of what is on the phone. The confirm button
/// says "Descartar todo" without the count, unlike the single-change sheet.
class ConfirmDiscardAllQuarantinedChangesSheet extends StatelessWidget {
  const ConfirmDiscardAllQuarantinedChangesSheet({required this.count, super.key});

  final int count;

  /// Resolves to `true` when the user confirms.
  static Future<bool?> show(BuildContext context, {required int count}) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) =>
            ConfirmDiscardAllQuarantinedChangesSheet(count: count),
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
          title: l10n.syncDiscardAllConfirmTitle(count),
          message: l10n.syncDiscardAllConfirmMessage(count),
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
            label: Text(l10n.syncDiscardAllConfirmButton),
          ),
        ),
      ],
    );
  }
}

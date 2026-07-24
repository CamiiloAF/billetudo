import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_menu_row.dart';

/// What the detail's overflow ("⋮") offers (extension, HU-07, `Tt2e7`).
enum DebtActionsSheetAction { edit, close, delete }

/// The debt detail's overflow menu (`g57hEW`): a bottom sheet with the debt's
/// name as its title and three `Menu Row`s — never a Material
/// `PopupMenuButton`.
class DebtActionsSheet extends StatelessWidget {
  const DebtActionsSheet({required this.debtName, super.key});

  final String debtName;

  static Future<DebtActionsSheetAction?> show(
    BuildContext context, {
    required String debtName,
  }) =>
      BottomSheetBase.show<DebtActionsSheetAction>(
        context,
        builder: (context) => DebtActionsSheet(debtName: debtName),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            debtName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        SheetMenuRow(
          icon: LucideIcons.pencil,
          label: l10n.debtEditTooltip,
          onTap: () => Navigator.of(context).pop(DebtActionsSheetAction.edit),
        ),
        SheetMenuRow(
          icon: LucideIcons.flag,
          label: l10n.debtActionClose,
          onTap: () => Navigator.of(context).pop(DebtActionsSheetAction.close),
        ),
        SheetMenuRow(
          icon: LucideIcons.trash2,
          label: l10n.debtFormDelete,
          foreground: colors.expenseText,
          showChevron: false,
          onTap: () => Navigator.of(context).pop(DebtActionsSheetAction.delete),
        ),
      ],
    );
  }
}

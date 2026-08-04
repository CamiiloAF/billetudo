import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_menu_row.dart';

/// What the detail's overflow ("⋮") offers (extension, HU-07, `Tt2e7`).
enum DebtActionsSheetAction { edit, close, delete }

/// The debt detail's overflow menu (`g57hEW`): a bottom sheet with the debt's
/// name as its title and up to three `Menu Row`s — never a Material
/// `PopupMenuButton`.
class DebtActionsSheet extends StatelessWidget {
  const DebtActionsSheet({
    required this.debtName,
    this.showCloseAction = true,
    this.settled = false,
    super.key,
  });

  final String debtName;

  /// Whether the "Cerrar deuda"/"Completar deuda" row is offered at all.
  /// `false` once the debt is already closed (fix 5): re-closing an already
  /// closed debt only produces `debtActionError`, so the option must not be
  /// offered — `CloseDebt` still rejects it in domain as defense in depth.
  final bool showCloseAction;

  /// Whether the close row reads "Completar deuda" (outstanding balance
  /// reached 0 but the debt isn't closed yet) instead of "Cerrar deuda"
  /// (fix 5). Ignored when [showCloseAction] is `false`.
  final bool settled;

  static Future<DebtActionsSheetAction?> show(
    BuildContext context, {
    required String debtName,
    bool showCloseAction = true,
    bool settled = false,
  }) =>
      BottomSheetBase.show<DebtActionsSheetAction>(
        context,
        builder: (context) => DebtActionsSheet(
          debtName: debtName,
          showCloseAction: showCloseAction,
          settled: settled,
        ),
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
        if (showCloseAction)
          SheetMenuRow(
            icon: LucideIcons.flag,
            label: settled ? l10n.debtActionComplete : l10n.debtActionClose,
            showChevron: false,
            onTap: () =>
                Navigator.of(context).pop(DebtActionsSheetAction.close),
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

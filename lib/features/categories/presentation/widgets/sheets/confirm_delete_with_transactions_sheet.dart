import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/budget_usage_notice.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/usecases/delete_category.dart';
import '../parent_category_picker_sheet.dart';
import 'delete_resolution_radio_card.dart';

/// HU-04 case 2: the category has associated transactions (`snXFk`).
///
/// Header keeps the neutral `trash-2` on `$primary-soft` — this step never
/// escalates to red, it only chooses what happens to the existing movements
/// before the actual delete runs. Reassigning to another category of the
/// same [kind] (opens [ParentCategoryPickerSheet], unfiltered per the
/// pending note in `categorias.md`) is the default option; the confirm
/// button reads "Continuar" since this step doesn't delete by itself.
class ConfirmDeleteWithTransactionsSheet extends StatefulWidget {
  const ConfirmDeleteWithTransactionsSheet({
    required this.transactionCount,
    required this.kind,
    required this.excludingId,
    this.budgetCount = 0,
    super.key,
  });

  final int transactionCount;
  final CategoryKind kind;

  /// Budgets whose scope references this category (Presupuestos HU-06).
  final int budgetCount;

  /// The category being deleted: never offered as its own reassign target.
  final String excludingId;

  /// Resolves to the chosen [TransactionResolution], or `null` if dismissed.
  static Future<TransactionResolution?> show(
    BuildContext context, {
    required int transactionCount,
    required CategoryKind kind,
    required String excludingId,
    int budgetCount = 0,
  }) =>
      BottomSheetBase.show<TransactionResolution>(
        context,
        useRootNavigator: true,
        builder: (context) => ConfirmDeleteWithTransactionsSheet(
          transactionCount: transactionCount,
          kind: kind,
          excludingId: excludingId,
          budgetCount: budgetCount,
        ),
      );

  @override
  State<ConfirmDeleteWithTransactionsSheet> createState() =>
      _ConfirmDeleteWithTransactionsSheetState();
}

enum _Choice { reassign, clear }

class _ConfirmDeleteWithTransactionsSheetState
    extends State<ConfirmDeleteWithTransactionsSheet> {
  _Choice _choice = _Choice.reassign;
  String? _targetCategoryId;

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
          title: l10n.categoryDeleteTransactionsTitle,
          message: l10n.categoryDeleteTransactionsCount(
            widget.transactionCount,
          ),
        ),
        BudgetUsageNotice(count: widget.budgetCount),
        const SizedBox(height: 16),
        DeleteResolutionRadioCard(
          selected: _choice == _Choice.reassign,
          label: l10n.categoryDeleteReassignOption,
          onTap: () => unawaited(_onChoiceChanged(context, _Choice.reassign)),
        ),
        const SizedBox(height: 12),
        DeleteResolutionRadioCard(
          selected: _choice == _Choice.clear,
          label: l10n.categoryDeleteClearOption,
          onTap: () => unawaited(_onChoiceChanged(context, _Choice.clear)),
        ),
        const SizedBox(height: 20),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton.icon(
            onPressed: _choice == _Choice.reassign && _targetCategoryId == null
                ? null
                : () => Navigator.of(context).pop(
                      _choice == _Choice.reassign
                          ? TransactionResolution.reassign(
                              _targetCategoryId!,
                            )
                          : const TransactionResolution.clear(),
                    ),
            icon: const Icon(LucideIcons.arrowRight),
            label: Text(l10n.commonContinue),
          ),
        ),
      ],
    );
  }

  /// [_Choice.clear] resolves right away; [_Choice.reassign] opens the
  /// target picker first — the selection only "sticks" once the user
  /// actually picked a category, so tapping it and backing out of the
  /// picker leaves the previous choice in place.
  Future<void> _onChoiceChanged(BuildContext context, _Choice value) async {
    if (value == _Choice.clear) {
      setState(() => _choice = _Choice.clear);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final picked = await ParentCategoryPickerSheet.show(
      context,
      kind: widget.kind,
      excludingId: widget.excludingId,
      selectedId: _targetCategoryId,
      rootsOnly: false,
      title: l10n.categoryReassignTransactionsPickerTitle,
    );
    if (picked != null && mounted) {
      setState(() {
        _choice = _Choice.reassign;
        _targetCategoryId = picked.id;
      });
    }
  }
}

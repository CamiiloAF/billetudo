import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/usecases/delete_category.dart';
import '../parent_category_picker_sheet.dart';

/// HU-04 case 2: the category has associated transactions (`snXFk`).
///
/// Same neutral `trash-2` treatment as the simple sheet, plus the movement
/// count and 2 radio options: reassign them to another category of the same
/// [kind] (opens [ParentCategoryPickerSheet], unfiltered per the pending
/// note in `categorias.md`), or leave them without one.
class ConfirmDeleteWithTransactionsSheet extends StatefulWidget {
  const ConfirmDeleteWithTransactionsSheet({
    required this.transactionCount,
    required this.kind,
    required this.excludingId,
    super.key,
  });

  final int transactionCount;
  final CategoryKind kind;

  /// The category being deleted: never offered as its own reassign target.
  final String excludingId;

  /// Resolves to the chosen [TransactionResolution], or `null` if dismissed.
  static Future<TransactionResolution?> show(
    BuildContext context, {
    required int transactionCount,
    required CategoryKind kind,
    required String excludingId,
  }) =>
      showModalBottomSheet<TransactionResolution>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ConfirmDeleteWithTransactionsSheet(
          transactionCount: transactionCount,
          kind: kind,
          excludingId: excludingId,
        ),
      );

  @override
  State<ConfirmDeleteWithTransactionsSheet> createState() =>
      _ConfirmDeleteWithTransactionsSheetState();
}

enum _Choice { reassign, clear }

class _ConfirmDeleteWithTransactionsSheetState
    extends State<ConfirmDeleteWithTransactionsSheet> {
  _Choice _choice = _Choice.clear;
  String? _targetCategoryId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.delete_outline, color: colors.primaryOnSoft, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.categoryDeleteTransactionsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryDeleteTransactionsCount(widget.transactionCount),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            RadioGroup<_Choice>(
              groupValue: _choice,
              onChanged: (value) => unawaited(_onChoiceChanged(context, value)),
              child: Column(
                children: [
                  RadioListTile<_Choice>(
                    contentPadding: EdgeInsets.zero,
                    value: _Choice.reassign,
                    title: Text(l10n.categoryDeleteReassignOption),
                  ),
                  RadioListTile<_Choice>(
                    contentPadding: EdgeInsets.zero,
                    value: _Choice.clear,
                    title: Text(l10n.categoryDeleteClearOption),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _choice == _Choice.reassign &&
                            _targetCategoryId == null
                        ? null
                        : () => Navigator.of(context).pop(
                              _choice == _Choice.reassign
                                  ? TransactionResolution.reassign(
                                      _targetCategoryId!,
                                    )
                                  : const TransactionResolution.clear(),
                            ),
                    child: Text(l10n.commonDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// [_Choice.clear] resolves right away; [_Choice.reassign] opens the
  /// target picker first — the selection only "sticks" once the user
  /// actually picked a category, so tapping it and backing out of the
  /// picker leaves the previous choice in place.
  Future<void> _onChoiceChanged(BuildContext context, _Choice? value) async {
    if (value == null) {
      return;
    }
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

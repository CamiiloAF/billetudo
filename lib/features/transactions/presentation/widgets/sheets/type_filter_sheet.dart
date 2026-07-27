import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../domain/entities/transaction.dart';
import 'category_filter_header_action.dart';
import 'type_filter_row.dart';

/// Display order for the type rows (`rjjfw`/`haoOi`): Gasto, Ingreso,
/// Transferencia — deliberately not [TransactionType.values]' declaration
/// order, which is a domain-layer concern this sheet must not reorder.
const _typeOrder = [
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
];

/// HU-06's type filter sheet: income/expense/transfer, multiple selection.
class TypeFilterSheet extends StatefulWidget {
  const TypeFilterSheet({required this.initialSelected, super.key});

  final Set<TransactionType> initialSelected;

  static Future<Set<TransactionType>?> show(
    BuildContext context, {
    required Set<TransactionType> initialSelected,
  }) =>
      BottomSheetBase.show<Set<TransactionType>>(
        context,
        builder: (context) => TypeFilterSheet(initialSelected: initialSelected),
      );

  @override
  State<TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<TypeFilterSheet> {
  final Set<TransactionType> _selected = {};

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      TransactionType.expense: l10n.transactionTypeExpense,
      TransactionType.income: l10n.transactionTypeIncome,
      TransactionType.transfer: l10n.transactionTypeTransfer,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              // A sheet title is 17/700 in billetudo.pen (`ivU3E` in
              // `rjjfw`), which is what `SheetHead` renders.
              child: SheetHead(title: l10n.typeFilterSheetTitle),
            ),
            CategoryFilterHeaderAction(
              label: l10n.accountFilterSelectAll,
              onTap: () => setState(() => _selected.addAll(_typeOrder)),
            ),
            Text(
              ' · ',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: context.colors.textSecondary),
            ),
            CategoryFilterHeaderAction(
              label: l10n.accountFilterSelectNone,
              onTap: () => setState(_selected.clear),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final type in _typeOrder) ...[
          TypeFilterRow(
            type: type,
            label: labels[type]!,
            selected: _selected.contains(type),
            onTap: () => setState(() {
              if (!_selected.remove(type)) {
                _selected.add(type);
              }
            }),
          ),
          if (type != _typeOrder.last) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: Text(l10n.commonApply),
          ),
        ),
      ],
    );
  }
}

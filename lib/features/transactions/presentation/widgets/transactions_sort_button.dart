import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_filter.dart';
import '../utils/transaction_sort_label.dart';
import 'sort/transaction_sort_menu_option_row.dart';
import 'sort/transaction_sort_menu_section_label.dart';

/// The Search Row's sort button (`B3GGa`/`xAk6Y`), opening the `Sort Menu`
/// popover (`xXWi0`/`dbTXb`) with the 4 [TransactionSortOrder] options the
/// repository already knows how to apply, grouped as "FECHA"/"MONTO"
/// (HU-06). Switches to its active look (`fill:$primary-soft`,
/// `stroke:$primary`) the instant [sortOrder] leaves the default
/// [TransactionSortOrder.dateDesc] (`tigaH`/`Q8gSaB`).
class TransactionsSortButton extends StatelessWidget {
  const TransactionsSortButton({
    required this.sortOrder,
    required this.onSelect,
    super.key,
  });

  final TransactionSortOrder sortOrder;
  final ValueChanged<TransactionSortOrder> onSelect;

  static const double _menuWidth = 226;
  static const double _buttonSize = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final active = transactionSortIsActive(sortOrder);

    return PopupMenuButton<TransactionSortOrder>(
      tooltip: transactionSortOptionLabel(l10n, sortOrder),
      onSelected: onSelect,
      borderRadius: BorderRadius.circular(16),
      // The popover's right edge lines up with the button's right edge
      // (`R4JwQ`), 8px below it — `showMenu`'s default "under" offset only
      // aligns left edges, so the extra width difference is shifted left.
      offset: const Offset(-(_menuWidth - _buttonSize), _buttonSize + 8),
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      constraints:
          const BoxConstraints(minWidth: _menuWidth, maxWidth: _menuWidth),
      menuPadding: const EdgeInsets.all(4),
      itemBuilder: (context) => [
        PopupMenuItem<TransactionSortOrder>(
          enabled: false,
          height: 34,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuSectionLabel(
            label: l10n.transactionsSortSectionDate,
            topPadding: 10,
          ),
        ),
        PopupMenuItem<TransactionSortOrder>(
          value: TransactionSortOrder.dateDesc,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuOptionRow(
            label: l10n.transactionsSortDateDesc,
            selected: sortOrder == TransactionSortOrder.dateDesc,
          ),
        ),
        PopupMenuItem<TransactionSortOrder>(
          value: TransactionSortOrder.dateAsc,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuOptionRow(
            label: l10n.transactionsSortDateAsc,
            selected: sortOrder == TransactionSortOrder.dateAsc,
          ),
        ),
        PopupMenuItem<TransactionSortOrder>(
          enabled: false,
          height: 1,
          padding: EdgeInsets.zero,
          child: Container(color: colors.border),
        ),
        PopupMenuItem<TransactionSortOrder>(
          enabled: false,
          height: 34,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuSectionLabel(
            label: l10n.transactionsSortSectionAmount,
            topPadding: 14,
          ),
        ),
        PopupMenuItem<TransactionSortOrder>(
          value: TransactionSortOrder.amountDesc,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuOptionRow(
            label: l10n.transactionsSortAmountDesc,
            selected: sortOrder == TransactionSortOrder.amountDesc,
          ),
        ),
        PopupMenuItem<TransactionSortOrder>(
          value: TransactionSortOrder.amountAsc,
          padding: EdgeInsets.zero,
          child: TransactionSortMenuOptionRow(
            label: l10n.transactionsSortAmountAsc,
            selected: sortOrder == TransactionSortOrder.amountAsc,
          ),
        ),
      ],
      child: Container(
        width: _buttonSize,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.primarySoft : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? colors.primary : colors.border),
        ),
        child: Icon(
          LucideIcons.arrowUpDown,
          size: 20,
          color: active ? colors.primaryOnSoftStrong : colors.textSecondary,
        ),
      ),
    );
  }
}

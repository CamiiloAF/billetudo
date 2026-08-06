import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../transactions/presentation/widgets/filter_chip_pill.dart';
import '../../../transactions/presentation/widgets/sheets/account_filter_sheet.dart';

/// Gráficas' cuentas filter (criteria 2-8, `design-system/billetudo/pages/
/// graficas.md`): rendered on Flujo, Patrimonio and Categorías only — never
/// on Resumen (D2). Reuses Movimientos' own `Account Chip`/`FilterChipPill`
/// and `AccountFilterSheet` (HU-06a) instead of a new component: same
/// multi-selection sheet, same "Todas"/"N cuentas" contract, applied here to
/// scope Gráficas' aggregates rather than a transaction list.
class AccountFilterRow extends StatelessWidget {
  const AccountFilterRow({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Inclusive-empty: an empty set means "todas las cuentas" (the default,
  /// no badge).
  final Set<String> selected;

  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFiltered = selected.isNotEmpty;
    final label = isFiltered
        ? l10n.reportsAccountFilterSelected(selected.length)
        : l10n.reportsAccountFilterAll;

    return Align(
      alignment: Alignment.centerLeft,
      child: FilterChipPill(
        label: label,
        active: isFiltered,
        leadingIcon: isFiltered ? LucideIcons.layers : LucideIcons.wallet,
        trailingIcon: LucideIcons.chevronDown,
        onTap: () async {
          final result = await AccountFilterSheet.show(
            context,
            initialSelected: selected,
          );
          if (result != null) {
            onChanged(result);
          }
        },
      ),
    );
  }
}

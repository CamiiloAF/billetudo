import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import 'circular_icon_chip.dart';
import 'filter_chip_pill.dart';

/// Issue #7: the account filter moves out of the unified filters sheet and
/// into its own row of chips in the Movimientos filter bar — a leading
/// toggle chip, one pill per active account, all multi-selection
/// (`nMKtn`'s `Chips Row`).
///
/// [selected] is inclusive-empty, the same rule as
/// `TransactionFilter.accountIds`: an empty set means every active account
/// is implicitly selected (HU-06a's untouched "Todas" default) — rendered
/// with every chip active, never with none.
///
/// Issue #incidencias-pruebas-manuales: the row used to carry two circular
/// chips — a leading "Todas" (`check-check`) that always emitted an empty
/// set, and a trailing "Limpiar" (`x`) that emitted the exact same empty
/// set — so both did the same thing and neither ever visibly reacted to the
/// filter already being "all selected". `TransactionFilter.accountIds` has
/// no way to represent "no accounts" (empty is read as "no filter" all the
/// way down to the SQL `WHERE`, see `TransactionsLocalDatasource`), so a
/// real "select none" state isn't representable — and per the individual
/// pill's own [_toggled] rule, at least one account always stays selected
/// anyway. The two redundant chips collapse into one real toggle instead:
///
/// * Not every account is selected yet → `check-check`, "Todas" — tap emits
///   the *explicit* full id set (not empty) so the resulting state is
///   distinguishable by equality from the implicit-empty default and the
///   chip can tell it's now "all selected".
/// * Every account is already selected (implicit empty or explicit full
///   set) → `x`, "Limpiar" (rendered `active`, matching the pills) — tap
///   emits a single-account set (the first active account), the same floor
///   [_toggled] already enforces, instead of a "zero selected" state the
///   rest of the domain can't express.
class AccountFilterChipRow extends StatelessWidget {
  const AccountFilterChipRow({
    required this.accounts,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<AccountWithBalance> accounts;
  final Set<String> selected;

  /// Fired with the next `accountIds` to apply — already resolved by this
  /// widget's own toggle rule (HU-06a: never zero, collapses back to the
  /// inclusive-empty default once every account ends up selected again).
  final ValueChanged<Set<String>> onChanged;

  bool _isActive(String accountId) =>
      selected.isEmpty || selected.contains(accountId);

  /// Never leaves zero accounts selected: deselecting the last remaining one
  /// (explicit or implicit via the "Todas" default) is a no-op, and reaching
  /// the complete active set again collapses back to the inclusive-empty
  /// default instead of an explicit full list — the same "no filter" shape
  /// `TransactionFilter.accountIds` already uses.
  Set<String> _toggled(String accountId) {
    final allIds = {for (final entry in accounts) entry.account.id};
    final effective = selected.isEmpty ? allIds : selected;
    if (effective.length <= 1 && effective.contains(accountId)) {
      return effective;
    }
    final next = Set<String>.of(effective);
    if (!next.remove(accountId)) {
      next.add(accountId);
    }
    return allIds.isNotEmpty && next.length >= allIds.length
        ? const <String>{}
        : next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final allIds = {for (final entry in accounts) entry.account.id};
    final isAllSelected = selected.isEmpty || selected.length >= allIds.length;

    return Row(
      children: [
        CircularIconChip(
          icon: isAllSelected ? LucideIcons.x : LucideIcons.checkCheck,
          semanticLabel:
              isAllSelected ? l10n.commonClear : l10n.accountFilterSelectAll,
          tooltip:
              isAllSelected ? l10n.commonClear : l10n.accountFilterSelectAll,
          active: isAllSelected,
          onTap: () => onChanged(
            isAllSelected
                ? (accounts.isEmpty
                    ? const <String>{}
                    : {accounts.first.account.id})
                : allIds,
          ),
        ),
        const SizedBox(width: 8),
        for (final entry in accounts) ...[
          FilterChipPill(
            label: entry.account.name,
            active: _isActive(entry.account.id),
            // `bIg7X`/`rHkkz`: the account chip's icon lives inside its own
            // tinted circle, coloured by account type — not the flat
            // `leadingIcon` every other chip uses, so this needs
            // `leadingWidget` instead (see `FilterChipPill` doc comment).
            leadingWidget: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: entry.account.type.softColor(colors),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.account.type.icon,
                size: 12,
                color: entry.account.type.color(colors),
              ),
            ),
            onTap: () => onChanged(_toggled(entry.account.id)),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import 'filter_chip_pill.dart';

/// Issue #7: the account filter moves out of the unified filters sheet and
/// into its own row of chips in the Movimientos filter bar — one pill per
/// active account plus "Todas" (`check-check`) and "Limpiar" (`x`), all
/// multi-selection.
///
/// [selected] is inclusive-empty, the same rule as
/// `TransactionFilter.accountIds`: an empty set means every active account
/// is implicitly selected (HU-06a's untouched "Todas" default) — rendered
/// with every chip active, never with none.
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

    return Row(
      children: [
        for (final entry in accounts) ...[
          FilterChipPill(
            label: entry.account.name,
            active: _isActive(entry.account.id),
            leadingIcon: entry.account.type.icon,
            onTap: () => onChanged(_toggled(entry.account.id)),
          ),
          const SizedBox(width: 8),
        ],
        FilterChipPill(
          label: l10n.accountFilterSelectAll,
          active: selected.isEmpty,
          leadingIcon: LucideIcons.checkCheck,
          onTap: () => onChanged(const <String>{}),
        ),
        const SizedBox(width: 8),
        FilterChipPill(
          label: l10n.commonClear,
          active: false,
          leadingIcon: LucideIcons.x,
          onTap: () => onChanged(const <String>{}),
        ),
      ],
    );
  }
}

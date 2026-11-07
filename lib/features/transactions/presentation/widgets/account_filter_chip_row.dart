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
/// toggle chip, one pill per active account.
///
/// [selected] is inclusive-empty, the same rule as
/// `TransactionFilter.accountIds`: an empty set means every active account
/// is implicitly selected (HU-06a's untouched "Todas" default) — rendered
/// with every chip active, never with none.
///
/// 2026-11-07 — two selection modes (explicit user request):
/// * **Single-select (default):** a plain tap on an account chip replaces the
///   whole filter with that account alone. Asking for one account used to
///   require two taps from the all-selected default (deselect the others),
///   which the user reported as the wrong default.
/// * **Multi-select:** a **long press** on any account chip enters this mode,
///   **keeping the current selection and adding the long-pressed account**
///   (e.g. with "Nequi" selected, long-pressing "TC Nu" leaves both active),
///   so the next taps add/remove accounts one by one ("select 1, 2 or 3
///   depending on the taps"). While the mode is active a long press does
///   nothing; it turns itself off as soon as the selection drops back to a
///   single account (multi-select is meaningless with one), and the leading
///   toggle chip also leaves it.
///
/// Issue #incidencias-pruebas-manuales: the row used to carry two circular
/// chips — a leading "Todas" (`check-check`) that always emitted an empty
/// set, and a trailing "Limpiar" (`x`) that emitted the exact same empty
/// set — so both did the same thing and neither ever visibly reacted to the
/// filter already being "all selected". `TransactionFilter.accountIds` has
/// no way to represent "no accounts" (empty is read as "no filter" all the
/// way down to the SQL `WHERE`, see `TransactionsLocalDatasource`), so a
/// real "select none" state isn't representable — and per the individual
/// pill's own toggle rule, at least one account always stays selected
/// anyway. The two redundant chips collapse into one real toggle instead:
///
/// * Not every account is selected yet → `check-check`, "Todas" — tap emits
///   the *explicit* full id set (not empty) so the resulting state is
///   distinguishable by equality from the implicit-empty default and the
///   chip can tell it's now "all selected".
/// * Every account is already selected (implicit empty or explicit full
///   set) → `x`, "Limpiar" (rendered `active`, matching the pills) — tap
///   emits a single-account set (the first active account), the same floor
///   the row's toggle rule already enforces, instead of a "zero selected" state the
///   rest of the domain can't express.
class AccountFilterChipRow extends StatefulWidget {
  const AccountFilterChipRow({
    required this.accounts,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<AccountWithBalance> accounts;
  final Set<String> selected;

  /// Fired with the next `accountIds` to apply — already resolved by this
  /// widget's own selection rule (HU-06a: never zero, collapses back to the
  /// inclusive-empty default once every account ends up selected again).
  final ValueChanged<Set<String>> onChanged;

  @override
  State<AccountFilterChipRow> createState() => _AccountFilterChipRowState();
}

class _AccountFilterChipRowState extends State<AccountFilterChipRow> {
  /// Whether taps toggle accounts instead of replacing the selection.
  ///
  /// Pure UI state: it never reaches `TransactionFilter`, so the filter stays
  /// the single source of truth for which accounts are shown. Starts in the
  /// default single-select mode and is only flipped by a long press / the
  /// leading toggle chip.
  bool _multiSelect = false;

  Set<String> get _allIds => {
        for (final entry in widget.accounts) entry.account.id,
      };

  bool get _isAllSelected =>
      widget.selected.isEmpty || widget.selected.length >= _allIds.length;

  bool _isActive(String accountId) =>
      widget.selected.isEmpty || widget.selected.contains(accountId);

  void _onAccountTap(String accountId) {
    if (!_multiSelect) {
      widget.onChanged({accountId});
      return;
    }
    final next = _toggled(accountId);
    final count = next.isEmpty ? _allIds.length : next.length;
    // 2026-11-07 refinement: multi-select turns itself off the moment the
    // selection is back to a single account — from then on a tap is the
    // ordinary single-select replace again.
    if (count <= 1) {
      setState(() => _multiSelect = false);
    }
    widget.onChanged(next);
  }

  /// Enters multi-selection **adding** [accountId] to the current selection
  /// (the user's example: "Nequi" selected + long press "TC Nu" → both
  /// active). While the mode is already active this gesture does nothing
  /// (2026-11-07 refinement); it is left automatically when the selection
  /// drops back to one account, or by the leading toggle chip.
  void _onAccountLongPress(String accountId) {
    if (_multiSelect) {
      return;
    }
    final allIds = _allIds;
    final effective = widget.selected.isEmpty ? allIds : widget.selected;
    final union = {...effective, accountId};
    // Same inclusive-empty collapse as the tap toggle: the whole active set
    // means "no account filter", not an explicit full list.
    final next = allIds.isNotEmpty && union.length >= allIds.length
        ? const <String>{}
        : union;
    final count = next.isEmpty ? allIds.length : next.length;
    if (count < 2) {
      return;
    }
    setState(() => _multiSelect = true);
    widget.onChanged(next);
  }

  /// Never leaves zero accounts selected: deselecting the last remaining one
  /// (explicit or implicit via the "Todas" default) is a no-op, and reaching
  /// the complete active set again collapses back to the inclusive-empty
  /// default instead of an explicit full list — the same "no filter" shape
  /// `TransactionFilter.accountIds` already uses.
  Set<String> _toggled(String accountId) {
    final allIds = _allIds;
    final effective = widget.selected.isEmpty ? allIds : widget.selected;
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

  void _onLeadingChipTap() {
    setState(() => _multiSelect = false);
    widget.onChanged(
      _isAllSelected
          ? (widget.accounts.isEmpty
              ? const <String>{}
              : {widget.accounts.first.account.id})
          : _allIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Row(
      children: [
        CircularIconChip(
          icon: _isAllSelected ? LucideIcons.x : LucideIcons.checkCheck,
          semanticLabel:
              _isAllSelected ? l10n.commonClear : l10n.accountFilterSelectAll,
          tooltip:
              _isAllSelected ? l10n.commonClear : l10n.accountFilterSelectAll,
          active: _isAllSelected,
          onTap: _onLeadingChipTap,
        ),
        const SizedBox(width: 8),
        for (final entry in widget.accounts) ...[
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
            // Multi-select mode is invisible otherwise: a check on every
            // selected pill is the same "selected" marker the account filter
            // rows already use, and makes "taps now toggle" discoverable.
            trailingIcon: _multiSelect && _isActive(entry.account.id)
                ? LucideIcons.check
                : null,
            semanticHint: _multiSelect
                ? l10n.accountFilterMultiSelectActiveHint
                : l10n.accountFilterMultiSelectHint,
            onTap: () => _onAccountTap(entry.account.id),
            onLongPress: () => _onAccountLongPress(entry.account.id),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

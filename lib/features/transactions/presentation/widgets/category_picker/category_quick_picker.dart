import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/forms/keyboard.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../cubit/category_quick_picker_cubit.dart';
import '../../cubit/category_quick_picker_state.dart';
import 'category_more_tile.dart';
import 'category_picker_chip.dart';
import 'category_select_sheet.dart';

/// The `Category Quick Picker` (`EIoVx`): an optional label ("Categoría"), a
/// row of up to 3 most-used category tiles of the current [kind], and a
/// trailing outline "Ver más"/"Otra" tile that opens the full
/// [CategorySelectSheet]. Shared by Transacciones and Pagos Programados —
/// the only difference between the two screens is [showLabel] (Pagos
/// Programados draws its own label above this widget) and [moreLabel].
///
/// Owns its [CategoryQuickPickerCubit] (resolved from `getIt`) so it can load
/// the most-used set and keep the selection resolved — a self-contained
/// control the form drops in for Gasto/Ingreso (Transferencia carries no
/// category). Tapping a tile selects it directly; "Ver más"/"Otra" opens the
/// sheet.
class CategoryQuickPicker extends StatefulWidget {
  const CategoryQuickPicker({
    required this.kind,
    required this.selectedId,
    required this.onSelected,
    this.accountId,
    this.errorText,
    this.showLabel = true,
    this.moreLabel,
    super.key,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Scopes the most-used set to this account (e.g. the form's currently
  /// selected account), so switching accounts recomputes its own top-3.
  /// `null` keeps the unscoped, kind-only usage count.
  final String? accountId;

  /// Reports the category the user picked (chip or sheet) back to the form.
  final ValueChanged<Category> onSelected;

  /// Set when the field failed validation (HU-01/02 criterion: a category is
  /// required for expense/income). Same message pattern as `AccountFormField`
  /// (`$expense`-colored text below the control).
  final String? errorText;

  /// Whether to render the "Categoría" label above the chip row. Some call
  /// sites (e.g. Pagos Programados) already draw that label themselves right
  /// above this widget, so they set this to `false` to avoid a duplicate.
  final bool showLabel;

  /// Overrides the trailing chip's text (defaults to
  /// `l10n.categorySelectMore`, "Ver más"). Pagos Programados uses "Otra"
  /// instead, matching its own copy of the `mK8oI` component.
  final String? moreLabel;

  @override
  State<CategoryQuickPicker> createState() => _CategoryQuickPickerState();
}

class _CategoryQuickPickerState extends State<CategoryQuickPicker> {
  late final CategoryQuickPickerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<CategoryQuickPickerCubit>();
    unawaited(
      _cubit.start(
        kind: widget.kind,
        selectedId: widget.selectedId,
        accountId: widget.accountId,
      ),
    );
  }

  @override
  void didUpdateWidget(CategoryQuickPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind != oldWidget.kind) {
      unawaited(_cubit.setKind(widget.kind, selectedId: widget.selectedId));
    } else if (widget.selectedId != oldWidget.selectedId) {
      unawaited(_cubit.syncSelection(widget.selectedId));
    }
    if (widget.accountId != oldWidget.accountId) {
      unawaited(_cubit.setAccount(widget.accountId));
    }
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _pick(Category category) {
    // Selecting a chip is a selector action: drop the system keyboard so a
    // note the user was typing does not keep it up.
    FocusScope.of(context).unfocus();
    _cubit.select(category);
    widget.onSelected(category);
  }

  Future<void> _openSheet() async {
    // Drop the system keyboard before opening the sheet so it does not spring
    // back when the sheet closes.
    await dismissSystemKeyboard(context);
    if (!mounted) {
      return;
    }
    final picked = await CategorySelectSheet.show(
      context,
      kind: widget.kind,
      selectedId: _cubit.state.selectedId,
    );
    if (picked != null) {
      _pick(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<CategoryQuickPickerCubit, CategoryQuickPickerState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showLabel) ...[
                Text(
                  l10n.transactionFormCategoryLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final category in state.displayCategories)
                    CategoryPickerChip(
                      category: category,
                      selected: category.id == state.selectedId,
                      onTap: () => _pick(category),
                    ),
                  CategoryMoreTile(
                    label: widget.moreLabel ?? l10n.categorySelectMore,
                    onTap: _openSheet,
                  ),
                ],
              ),
              if (widget.errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.errorText!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.expense),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../cubit/category_quick_picker_cubit.dart';
import '../../cubit/category_quick_picker_state.dart';
import 'category_picker_chip.dart';
import 'category_select_sheet.dart';

/// The `Category Quick Picker` (`EIoVx`) of the transaction form: a label
/// ("Categoría"), a row of the 3 most-used category chips of the current
/// [kind], and a trailing outline "Ver más" chip that opens the full
/// [CategorySelectSheet].
///
/// Owns its [CategoryQuickPickerCubit] (resolved from `getIt`) so it can load
/// the most-used set and keep the selection resolved — a self-contained
/// control the form drops in for Gasto/Ingreso (Transferencia carries no
/// category). Tapping a chip selects it directly; "Ver más" opens the sheet.
class CategoryQuickPicker extends StatefulWidget {
  const CategoryQuickPicker({
    required this.kind,
    required this.selectedId,
    required this.onSelected,
    this.errorText,
    super.key,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Reports the category the user picked (chip or sheet) back to the form.
  final ValueChanged<Category> onSelected;

  /// Set when the field failed validation (HU-01/02 criterion: a category is
  /// required for expense/income). Same message pattern as `AccountFormField`
  /// (`$expense`-colored text below the control).
  final String? errorText;

  @override
  State<CategoryQuickPicker> createState() => _CategoryQuickPickerState();
}

class _CategoryQuickPickerState extends State<CategoryQuickPicker> {
  late final CategoryQuickPickerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<CategoryQuickPickerCubit>();
    unawaited(_cubit.start(kind: widget.kind, selectedId: widget.selectedId));
  }

  @override
  void didUpdateWidget(CategoryQuickPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.kind != oldWidget.kind) {
      unawaited(_cubit.setKind(widget.kind, selectedId: widget.selectedId));
    } else if (widget.selectedId != oldWidget.selectedId) {
      unawaited(_cubit.syncSelection(widget.selectedId));
    }
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _pick(Category category) {
    _cubit.select(category);
    widget.onSelected(category);
  }

  Future<void> _openSheet() async {
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
              Text(
                l10n.transactionFormCategoryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in state.displayCategories)
                    CategoryPickerChip(
                      category: category,
                      selected: category.id == state.selectedId,
                      onTap: () => _pick(category),
                    ),
                  Material(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: InkWell(
                      onTap: _openSheet,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.ellipsis,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.categorySelectMore,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

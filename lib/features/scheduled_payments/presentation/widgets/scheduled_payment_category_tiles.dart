import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../../transactions/presentation/cubit/category_quick_picker_cubit.dart';
import '../../../transactions/presentation/cubit/category_quick_picker_state.dart';
import '../../../transactions/presentation/widgets/category_picker/category_select_sheet.dart';

/// The template form's category selector (`J0DSIm`): vertical icon-over-label
/// tiles (`mK8oI`), unlike Transacciones' horizontal pill chips
/// (`CategoryQuickPicker`/`EIoVx`). Both features share the same most-used +
/// selection cubit ([CategoryQuickPickerCubit]) and the same full-catalog
/// sheet ([CategorySelectSheet]) — only the chip's shape differs per screen,
/// so this widget owns its own cubit instance the same way
/// `CategoryQuickPicker` does, and only replaces the rendering.
class ScheduledPaymentCategoryTiles extends StatefulWidget {
  const ScheduledPaymentCategoryTiles({
    required this.kind,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Reports the category the user picked (tile or sheet) back to the form.
  final ValueChanged<Category> onSelected;

  @override
  State<ScheduledPaymentCategoryTiles> createState() =>
      _ScheduledPaymentCategoryTilesState();
}

class _ScheduledPaymentCategoryTilesState
    extends State<ScheduledPaymentCategoryTiles> {
  late final CategoryQuickPickerCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<CategoryQuickPickerCubit>();
    unawaited(_cubit.start(kind: widget.kind, selectedId: widget.selectedId));
  }

  @override
  void didUpdateWidget(ScheduledPaymentCategoryTiles oldWidget) {
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
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<CategoryQuickPickerCubit, CategoryQuickPickerState>(
        builder: (context, state) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final category in state.displayCategories)
                ScheduledPaymentCategoryTile(
                  label: category.name,
                  icon: CategoryAppearance.iconFor(category.icon),
                  categoryColor: category.color,
                  selected: category.id == state.selectedId,
                  onTap: () => _pick(category),
                ),
              ScheduledPaymentCategoryTile(
                label: l10n.scheduledPaymentFormCategoryMoreLabel,
                icon: LucideIcons.ellipsis,
                categoryColor: null,
                selected: false,
                onTap: _openSheet,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One tile of [ScheduledPaymentCategoryTiles] (`mK8oI`): a 52x52 rounded
/// icon wrap above a centered two-line label, both togglable between the
/// neutral and selected fill/border/text scheme. The icon always keeps the
/// category's own decorative color (only the wrap's fill/border and the
/// label react to [selected]) — the "more categories" tile has no
/// [categoryColor] and keeps a fixed neutral icon.
class ScheduledPaymentCategoryTile extends StatelessWidget {
  const ScheduledPaymentCategoryTile({
    required this.label,
    required this.icon,
    required this.categoryColor,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;

  /// The category's decorative color token (e.g. `mint`), or `null` for the
  /// "more categories" tile, which has no category behind it.
  final String? categoryColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final iconColor = categoryColor == null
        ? colors.textSecondary
        : CategoryAppearance.colorFor(colors, categoryColor);
    final wrapColor = selected
        ? CategoryAppearance.softColorFor(colors, categoryColor)
        : colors.muted;
    final wrapBorder = selected
        ? Border.all(color: CategoryAppearance.colorFor(colors, categoryColor))
        : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: wrapColor,
                borderRadius: BorderRadius.circular(16),
                border: wrapBorder,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';

/// The user's alert-threshold choice. A distinct type because "no alert" (`pct`
/// null) is a real, savable value — not the same as dismissing the sheet, which
/// returns a null [BudgetThresholdChoice].
class BudgetThresholdChoice {
  const BudgetThresholdChoice(this.pct);

  /// Whole percent 1-100, or null for "don't alert me" (HU-08).
  final int? pct;
}

/// The alert threshold sheet (`m3jomu`): presets 70/80/90 + Custom + "Don't
/// alert me", default 80 (HU-08). Custom nudges the value in steps of 5.
class BudgetThresholdSheet extends StatefulWidget {
  const BudgetThresholdSheet({required this.selected, super.key});

  final int? selected;

  static const List<int> presets = [70, 80, 90];

  static Future<BudgetThresholdChoice?> show(
    BuildContext context, {
    required int? selected,
  }) =>
      BottomSheetBase.show<BudgetThresholdChoice>(
        context,
        builder: (context) => BudgetThresholdSheet(selected: selected),
      );

  @override
  State<BudgetThresholdSheet> createState() => _BudgetThresholdSheetState();
}

class _BudgetThresholdSheetState extends State<BudgetThresholdSheet> {
  late int _customValue = BudgetThresholdSheet.presets.contains(widget.selected)
      ? 85
      : (widget.selected ?? 85);

  bool get _customActive =>
      widget.selected != null &&
      !BudgetThresholdSheet.presets.contains(widget.selected);

  void _nudge(int delta) => setState(
        () => _customValue = (_customValue + delta).clamp(1, 100),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.budgetThresholdTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final preset in BudgetThresholdSheet.presets)
          BudgetThresholdOption(
            label: l10n.budgetPercent(preset),
            selected: widget.selected == preset,
            onTap: () =>
                Navigator.of(context).pop(BudgetThresholdChoice(preset)),
          ),
        ListTile(
          title: Text(l10n.budgetThresholdCustom),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _customValue > 1 ? () => _nudge(-5) : null,
                icon: const Icon(LucideIcons.minus),
              ),
              Text(
                l10n.budgetPercent(_customValue),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _customActive ? colors.primary : null,
                ),
              ),
              IconButton(
                onPressed: _customValue < 100 ? () => _nudge(5) : null,
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
          onTap: () =>
              Navigator.of(context).pop(BudgetThresholdChoice(_customValue)),
        ),
        BudgetThresholdOption(
          label: l10n.budgetFormThresholdOff,
          selected: widget.selected == null,
          onTap: () =>
              Navigator.of(context).pop(const BudgetThresholdChoice(null)),
        ),
      ],
    );
  }
}

/// One row of the threshold sheet: a label and a check when selected.
class BudgetThresholdOption extends StatelessWidget {
  const BudgetThresholdOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        title: Text(label),
        trailing: selected
            ? Icon(LucideIcons.check, color: context.colors.primary)
            : null,
      );
}

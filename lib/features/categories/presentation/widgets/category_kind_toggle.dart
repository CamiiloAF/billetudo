import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../domain/entities/category.dart';

/// The `Segmented Control` toggle (`hFu41`), Gasto/Ingreso only — categories
/// never apply to transfers, so that 3rd segment stays hidden.
///
/// "Gasto" renders in `$text-primary`, never `$expense`: labeling it red
/// felt punitive (`categorias.md`). Wraps the shared [SegmentedControl] so
/// the listing toggle and the form's "Tipo" field render the exact same
/// component instead of two hand-rolled pills.
class CategoryKindToggle extends StatelessWidget {
  const CategoryKindToggle({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final CategoryKind selected;
  final ValueChanged<CategoryKind> onChanged;

  /// `false` renders the toggle visually locked (caller wraps it in an
  /// `Opacity` + caption for the condicional lock treatment) but keeps
  /// forwarding taps disabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedControl<CategoryKind>(
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
      segments: [
        SegmentedControlOption(
          value: CategoryKind.expense,
          label: l10n.categoryKindExpense,
        ),
        SegmentedControlOption(
          value: CategoryKind.income,
          label: l10n.categoryKindIncome,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The left-aligned title header shared by every root destination of the Tab
/// Bar (Movimientos, Más — and matching `BudgetsPageHeader`/Inicio). Unlike
/// the shared `PageHeader` (centered, with a back button for detail/form
/// screens), a tab root has no back button, so its title sits on the left
/// (`700`/24px, `textPrimary`) and the global `AppBarTheme.centerTitle` never
/// applies here.
///
/// Put it in the body as the first item above the content, not in
/// `Scaffold(appBar: ...)` — it is not a `PreferredSizeWidget`.
///
/// `Presupuestos`/`Inicio` still keep their own headers today; they can migrate
/// to this widget later.
class RootTabHeader extends StatelessWidget {
  const RootTabHeader({
    required this.title,
    this.actions = const <Widget>[],
    this.leading,
    super.key,
  });

  /// Header title. Rendered left-aligned, bold, `textPrimary`.
  final String title;

  /// Optional right-side action buttons (e.g. 44x44 circular buttons). Laid
  /// out at the end of the row, after the title.
  final List<Widget> actions;

  /// Optional left-side widget before the title (e.g. a back button). A tab
  /// root has none; a screen reusing this header in a stacked mode (Movimientos
  /// in Deudas link mode) passes a back button so it is never a dead end.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leading = this.leading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

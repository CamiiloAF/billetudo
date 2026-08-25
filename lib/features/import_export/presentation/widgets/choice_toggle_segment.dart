import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One pill segment of `RestoreChoiceToggle`: raised `$surface` when
/// [selected] in light mode; in dark mode the raised/track pair loses almost
/// all contrast (`design-system/billetudo/pages/import-export.md`), so a
/// selected segment also gets an explicit `$text-secondary` stroke there.
class ChoiceToggleSegment extends StatelessWidget {
  const ChoiceToggleSegment({
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: selected && isDark
                  ? Border.all(color: colors.textSecondary)
                  : null,
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

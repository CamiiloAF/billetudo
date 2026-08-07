import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `MonthPickerSheet`'s year stepper's plain icon button (`k7kv4`, `Prev`/
/// `Next`): no fill, unlike `PageHeaderCircleButton`'s solid `$surface`
/// circle — those frames carry no `fill` of their own, just a centered
/// `$text-primary` icon in a 44×44 tap target. `onPressed: null` renders it
/// disabled (the caller also dims it to 35% opacity at the year bound, per
/// the design).
class YearNavButton extends StatelessWidget {
  const YearNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

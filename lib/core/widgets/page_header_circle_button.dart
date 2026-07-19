import 'package:flutter/material.dart';

/// The shared 44x44 circular icon button used by `PageHeader`'s back and
/// trailing action slots (Pencil `Dtm0X`): a filled circle wrap with a
/// single 18px icon, centered.
class PageHeaderCircleButton extends StatelessWidget {
  const PageHeaderCircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 18,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String tooltip;

  /// `Dtm0X` draws its icons at 18; the budgets list header (`ymsmU`) uses the
  /// same 44pt circle with a 20pt icon.
  final double iconSize;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: iconSize, color: foreground),
          ),
        ),
      ),
    );
  }
}

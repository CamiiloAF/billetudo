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
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String tooltip;

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
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

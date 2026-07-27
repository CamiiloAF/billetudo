import 'package:flutter/material.dart';

/// A circular 44x44 action button of a page header (`Dtm0X`): a filled wrap
/// with a single 18px icon. Used both by the form's page header (back/save)
/// and the detail page's back button.
class TransactionHeaderButton extends StatelessWidget {
  const TransactionHeaderButton({
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

  /// Null disables the button (e.g. save while already saving).
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

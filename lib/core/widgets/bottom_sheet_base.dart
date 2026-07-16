import 'package:flutter/material.dart';

/// The `Bottom Sheet Base` component: the chrome every sheet of this feature
/// shares.
///
/// Scrim, the `[28,28,0,0]` radius and the handle come from
/// `bottomSheetTheme` (`showDragHandle: true`), so this only owns the padding
/// and the content slot. The base imposes no title: some sheets open with one,
/// others with an icon and a message.
///
/// Confirmations on mobile are always sheets, never centred dialogs
/// (MASTER.md).
class BottomSheetBase extends StatelessWidget {
  const BottomSheetBase({required this.child, super.key});

  final Widget child;

  /// Opens [child] as a modal sheet with the feature's chrome.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        builder: (context) => BottomSheetBase(child: builder(context)),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: child,
      ),
    );
  }
}

/// The icon + title + message body the confirmation sheets share.
class SheetMessage extends StatelessWidget {
  const SheetMessage({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Both already localized.
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

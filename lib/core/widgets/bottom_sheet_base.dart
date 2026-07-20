import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
  ///
  /// [useRootNavigator] defaults to `false` (existing callers' behaviour
  /// unchanged); pass `true` when the sheet opens from a page nested under a
  /// shell route with a bottom nav bar, so the sheet covers it instead of
  /// stopping above it.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool useRootNavigator = false,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: useRootNavigator,
        builder: (context) => BottomSheetBase(child: builder(context)),
      );

  @override
  Widget build(BuildContext context) {
    // The keyboard inset lifts the whole sheet instead of covering it, so the
    // search field of a filtering sheet stays visible while typing.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: child,
        ),
      ),
    );
  }
}

/// The icon + optional title + message body the confirmation sheets share.
///
/// Not every sheet opens with a title: the plain `alert-triangle` delete
/// pattern (`o9116/qsjbj` in `billetudo.pen`) only has icon + message.
class SheetMessage extends StatelessWidget {
  const SheetMessage({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.message,
    this.title,
    this.messageColor,
    this.messageFontSize = 15,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Already localized. `null` renders no title (icon + message only).
  final String? title;

  /// Already localized.
  final String message;

  /// Defaults to `$text-primary` / 15, the component's own values (`FxD3p` in
  /// `XPjIZ`). "Cerrar sesión" (HU-06) overrides both to `$text-secondary`/14
  /// in `billetudo.pen`, so the instance can say so instead of the shared
  /// widget guessing.
  final Color? messageColor;
  final double messageFontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
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
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 16),
        if (title case final title?) ...[
          Text(
            title,
            textAlign: TextAlign.center,
            // `Sheet Icon Header`'s title (`lmN3k` in `XPjIZ`) is 17/700 with
            // a 1.3 line height, not the theme's 22/500 `titleLarge`.
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: messageColor ?? colors.textPrimary,
            fontSize: messageFontSize,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

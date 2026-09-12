import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The chasis shared by `skjlg`, `EqRlj`, `RSizy` and `YliJD`'s siblings:
/// `$surface` fill + `$border` 1px + radius 16, **zero tint** — identical to
/// `Notice Card` (`cYVQm`). The only thing that varies between the capture
/// subfamilies is [railColor], a 4px accent on the left edge: `$primary-on-
/// soft` for an ordinary or grouped capture, `$amber-text` for a possible
/// duplicate.
///
/// Layered with a [Stack] rather than a single `BoxDecoration.border`:
/// Flutter's border painter refuses a `borderRadius` on a [Border] whose
/// sides are not uniform ("A borderRadius can only be given on borders with
/// uniform colors") — the `.pen` calls for exactly that non-uniform border
/// ("`Border(left: BorderSide(width: 4))`"), so a plain `BoxDecoration.border`
/// crashes at paint time the moment a rounded corner meets the rail. The
/// stack instead paints a uniform-bordered background, then a thin
/// [ColoredBox] rail on top, both clipped to the same rounded rect — same
/// pixels, no crash.
///
/// [onTap] makes the whole card the tap target when set. Left `null` for
/// `EqRlj`: that card has two exclusive actions and no single destination, so
/// nothing on the chasis itself may respond to a tap.
class CaptureCardShell extends StatelessWidget {
  const CaptureCardShell({
    required this.railColor,
    required this.child,
    this.onTap,
    super.key,
  });

  final Color railColor;
  final Widget child;
  final VoidCallback? onTap;

  static const _radius = 16.0;
  static const _railWidth = 4.0;
  static const _padding = EdgeInsets.fromLTRB(18, 14, 14, 14);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(_radius);
    final onTap = this.onTap;
    final content = Padding(padding: _padding, child: child);
    final tappableContent = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, child: content),
          );

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.border),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _railWidth,
            child: ColoredBox(color: railColor),
          ),
          tappableContent,
        ],
      ),
    );
  }
}

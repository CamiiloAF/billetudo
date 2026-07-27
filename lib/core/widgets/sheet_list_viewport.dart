import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A fixed-height, clipped scroll area for the list of a picker sheet.
///
/// Sheets that filter as the user types must not resize on every keystroke:
/// the design gives these lists a fixed viewport that the content scrolls
/// inside of (`bY9ZB` 420 in `Q55fEz`, `osdvZ` 320 in `lAxmS`), instead of a
/// `shrinkWrap` list that grows and shrinks with the number of matches.
///
/// [height] is the design height. It is capped at [maxViewportFraction] of the
/// space left above the keyboard so an open keyboard cannot push the search
/// field off screen; the cap only depends on the keyboard inset, so it stays
/// stable while the query changes.
class SheetListViewport extends StatelessWidget {
  const SheetListViewport({
    required this.height,
    required this.child,
    this.maxViewportFraction = 0.5,
    super.key,
  });

  /// The viewport height taken from the frame.
  final double height;

  /// Share of the space above the keyboard the viewport may take at most.
  final double maxViewportFraction;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return SizedBox(
      height: math.min(height, available * maxViewportFraction),
      child: child,
    );
  }
}

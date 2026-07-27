import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single `$skeleton` block. A public widget (not a helper that returns a
/// Widget) so the Deudas loading placeholders can compose their geometry
/// without private widget builders.
class DebtSkeletonBox extends StatelessWidget {
  const DebtSkeletonBox({
    this.width,
    required this.height,
    this.radius = 4,
    super.key,
  });

  /// `null` fills the available width (for full-width bars like the track).
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

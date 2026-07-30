import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// A single placeholder rectangle inside the chart skeleton hero: a rounded
/// block sized by [width]/[height], with a pill radius for thin bars and a
/// fixed radius for taller ones.
class ChartSkeletonBlock extends StatelessWidget {
  const ChartSkeletonBlock({
    required this.width,
    required this.height,
    super.key,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.skeleton,
        borderRadius: BorderRadius.circular(height >= 20 ? 8 : height / 2),
      ),
    );
  }
}

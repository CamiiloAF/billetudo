import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The Goal Ring (`EB2TX` hero / `q1qGr` mini): an arc track (`$track`) with a
/// progress fill, capped at 100%. The fill is `$primary`, or `$income-text`
/// once the goal is completed (HU-07's "arco lleno").
///
/// A hero-sized ring optionally centers a `child` (the "%" label).
class GoalProgressRing extends StatelessWidget {
  const GoalProgressRing({
    required this.percent,
    required this.size,
    this.completed = false,
    this.strokeWidth = 10,
    this.child,
    super.key,
  });

  /// 0-100, already clamped by the domain (frozen at 100 once completed).
  final int percent;
  final double size;
  final bool completed;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoalRingPainter(
          percent: percent.clamp(0, 100),
          strokeWidth: strokeWidth,
          track: colors.track,
          fill: completed ? colors.incomeText : colors.primary,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  const _GoalRingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.track,
    required this.fill,
  });

  final int percent;
  final double strokeWidth;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (percent <= 0) {
      return;
    }
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Starts at 12 o'clock (-90°), sweeps clockwise proportionally to percent.
    final sweep = 2 * math.pi * (percent / 100);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.track != track ||
      oldDelegate.fill != fill;
}

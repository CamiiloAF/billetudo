import 'package:flutter/material.dart';

import '../categories/category_donut_chart.dart';
import 'chart_skeleton_view.dart';

/// The plot placeholder inside [ChartSkeletonView], drawn per [shape] so a
/// tab's "carga" matches its own real chart's geometry (see
/// [ChartSkeletonShape]'s doc): uniform bars for Flujo, two flat strokes for
/// Patrimonio's `LineChart`, and a ring for Categorías' donut. None of the
/// three insinuates real data — uniform bar heights, perfectly flat lines,
/// an untouched ring.
class ChartSkeletonPlot extends StatelessWidget {
  const ChartSkeletonPlot({
    required this.shape,
    required this.columnCount,
    required this.skeletonColor,
    super.key,
  });

  final ChartSkeletonShape shape;
  final int columnCount;
  final Color skeletonColor;

  /// Matches `CategoryDonutChart`'s default `size` so the placeholder
  /// occupies roughly the same footprint as the real donut it stands in for.
  static const double _donutDiameter = CategoryDonutChart.defaultSize;

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case ChartSkeletonShape.bars:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < columnCount; i++)
              Container(
                width: 13,
                height: 250,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        );
      case ChartSkeletonShape.line:
        return CustomPaint(
          size: Size.infinite,
          painter: _ChartSkeletonLinePainter(color: skeletonColor),
        );
      case ChartSkeletonShape.donut:
        return Center(
          child: Container(
            width: _donutDiameter,
            height: _donutDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: skeletonColor, width: 32),
            ),
          ),
        );
    }
  }
}

/// Draws Patrimonio's line placeholder: two flat horizontal strokes (one per
/// series — líquido/total) spanning the plot width. Flat on purpose: a
/// wavy/sloped line would insinuate a real trend, breaking the "uniform"
/// rule the bars variant already follows.
class _ChartSkeletonLinePainter extends CustomPainter {
  const _ChartSkeletonLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final firstY = size.height * 0.42;
    final secondY = size.height * 0.62;
    canvas.drawLine(Offset(4, firstY), Offset(size.width - 4, firstY), paint);
    canvas.drawLine(
      Offset(4, secondY),
      Offset(size.width - 4, secondY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartSkeletonLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

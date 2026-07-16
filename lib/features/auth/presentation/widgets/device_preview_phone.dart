import 'package:flutter/material.dart';

class DevicePreviewPhone extends StatelessWidget {
  const DevicePreviewPhone({
    required this.width,
    required this.height,
    required this.background,
    required this.border,
    required this.accent,
    this.highlightAmount = false,
    super.key,
  });

  final double width;
  final double height;
  final Color background;
  final Color border;
  final Color accent;
  final bool highlightAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 8,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          if (highlightAmount)
            Container(
              width: width - 24,
              height: 18,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Container(
              width: (width - 24) * 0.7,
              height: 10,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(height: 6),
          Container(
            width: (width - 24) * 0.5,
            height: 10,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

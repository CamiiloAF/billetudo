import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The history list's loading placeholder (`billetudo.pen` `rVldq`): the
/// silhouette of a real `ConversationRow` (title/meta lines + footer bar),
/// shown five times while the first batch loads.
class ConversationSkeletonRow extends StatelessWidget {
  const ConversationSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 220,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.skeleton,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.skeleton,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            alignment: Alignment.centerRight,
            child: Container(
              width: 70,
              height: 14,
              decoration: BoxDecoration(
                color: colors.skeleton,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

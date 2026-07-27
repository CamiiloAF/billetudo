import 'package:flutter/material.dart';

import 'debt_skeleton_box.dart';

/// Loading placeholder for `DebtLedgerRow` (`Sp8IY`): the same geometry in
/// `$skeleton`.
class DebtLedgerSkeletonRow extends StatelessWidget {
  const DebtLedgerSkeletonRow({
    this.nameWidth = 130,
    this.metaWidth = 90,
    this.amountWidth = 80,
    this.runningWidth = 60,
    super.key,
  });

  final double nameWidth;
  final double metaWidth;
  final double amountWidth;
  final double runningWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          const DebtSkeletonBox(width: 44, height: 44, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DebtSkeletonBox(width: nameWidth, height: 14),
                const SizedBox(height: 8),
                DebtSkeletonBox(width: metaWidth, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DebtSkeletonBox(width: amountWidth, height: 14),
              const SizedBox(height: 6),
              DebtSkeletonBox(width: runningWidth, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

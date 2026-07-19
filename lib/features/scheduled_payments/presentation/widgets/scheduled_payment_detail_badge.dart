import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A small pill badge (once/inactive/pending) used on the detail page header.
class ScheduledPaymentDetailBadge extends StatelessWidget {
  const ScheduledPaymentDetailBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primaryOnSoftStrong,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

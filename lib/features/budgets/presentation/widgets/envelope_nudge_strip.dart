import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The hero's nudge strip (`eZMPq`): a `$primary-soft` band with `sparkles`
/// that invites the next step. Always encouraging — it never scolds the user
/// for what is still unassigned or over-assigned.
class EnvelopeNudgeStrip extends StatelessWidget {
  const EnvelopeNudgeStrip({required this.message, super.key});

  /// Already localized.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, size: 18, color: colors.primaryOnSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

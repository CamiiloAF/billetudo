import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tag.dart';
import 'scheduled_payment_tags_field.dart' show ScheduledPaymentTagChip;

/// The detail's read-only "Etiquetas" row inside `InfoCard`: same padding
/// language as `InfoRow`, but stacks the label above a `Wrap` of read-only
/// `Tag Chip`s instead of a single-line value, since a template can carry
/// several tags at once.
class ScheduledPaymentDetailTagsRow extends StatelessWidget {
  const ScheduledPaymentDetailTagsRow({required this.tags, super.key});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.scheduledPaymentDetailTagsLabel,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (tags.isEmpty)
            Text(
              l10n.scheduledPaymentDetailTagsEmpty,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  ScheduledPaymentTagChip(
                    label: tag.name,
                    removable: false,
                    onTap: () {},
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tag.dart';
import 'transaction_form_tag_chip.dart';

/// The "Etiquetas" section of HU-08's detail screen: never shown for a
/// transfer (the caller is responsible for that), and hidden entirely — not
/// just an empty row — when the transaction carries no tags.
class TransactionDetailTagsSection extends StatelessWidget {
  const TransactionDetailTagsSection({required this.tags, super.key});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionDetailTagsLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              // Read-only detail: no "x" to remove, so the tap is a no-op.
              TransactionFormTagChip(
                label: tag.name,
                removable: false,
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The transaction list's empty state (HU-06/HU-06b): neutral, never an
/// error — an unfiltered empty account and a filtered/searched period with no
/// matches both land here, only the [message] differs.
class TransactionsEmptyState extends StatelessWidget {
  const TransactionsEmptyState({
    required this.message,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ctaLabel = this.ctaLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(44),
              ),
              child: Icon(
                LucideIcons.receipt,
                size: 40,
                color: colors.primaryOnSoft,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCta,
                icon: const Icon(LucideIcons.plus),
                label: Text(ctaLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

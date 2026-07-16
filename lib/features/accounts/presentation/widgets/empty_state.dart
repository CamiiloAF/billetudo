import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Empty State` component: icon circle + message + optional CTA.
///
/// The CTA is optional because not every empty state has an action to offer —
/// archived accounts, for one, cannot be archived from there.
///
/// Lives in the feature until a second one needs it, per the promotion rule for
/// `core/widgets`.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final IconData icon;

  /// Already localized, and written in a neutral tone: an empty state states a
  /// fact, it never blames the user (MASTER.md).
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
              child: Icon(icon, size: 40, color: colors.primaryOnSoft),
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
                icon: const Icon(Icons.add),
                label: Text(ctaLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

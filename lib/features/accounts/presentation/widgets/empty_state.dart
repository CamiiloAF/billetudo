import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    this.description,
    this.ctaLabel,
    this.onCta,
    super.key,
  });

  final IconData icon;

  /// Already localized, and written in a neutral tone: an empty state states a
  /// fact, it never blames the user (MASTER.md).
  final String message;

  /// Optional second line, for the empty states whose title alone would leave
  /// out what the user still has (already localized).
  final String? description;

  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final ctaLabel = this.ctaLabel;
    final description = this.description;

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
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
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

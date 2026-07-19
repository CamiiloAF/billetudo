import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';

/// The `Empty State` component (`jmQO5`): icon circle + message + optional
/// subtitle + optional CTA.
///
/// Shared across features, so it lives in `core/widgets` next to `AppFab`
/// rather than inside any one feature.
///
/// The CTA is optional because not every empty state has an action to offer —
/// archived accounts, for one, cannot be archived from there.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.description,
    this.ctaLabel,
    this.ctaIcon = LucideIcons.plus,
    this.onCta,
    super.key,
  });

  /// The frame caps the message and the subtitle at this width so they wrap
  /// into a short, readable column instead of spanning the whole screen. Used
  /// as a *maximum* rather than a fixed width: on a 320pt screen the 20pt side
  /// padding already leaves less than this, and at a large text scale the copy
  /// must be free to grow taller.
  static const double _textMaxWidth = 260;

  /// `OQJ6H` sets the CTA to 220pt wide. Applied as a minimum so the button
  /// keeps that width for normal labels but still grows for a long label or a
  /// large text scale instead of overflowing.
  static const double _ctaMinWidth = 220;

  final IconData icon;

  /// Already localized, and written in a neutral tone: an empty state states a
  /// fact, it never blames the user (MASTER.md).
  final String message;

  /// Optional second line, for the empty states whose title alone would leave
  /// out what the user still has (already localized).
  final String? description;

  final String? ctaLabel;
  final IconData ctaIcon;
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
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _textMaxWidth),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _textMaxWidth),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
            if (ctaLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCta,
                // The theme only imposes the height, so this CTA has to ask for
                // its 220pt width from the frame. A minimum rather than a fixed
                // width, so a long label or a large text scale grows it instead
                // of overflowing.
                style: FilledButton.styleFrom(
                  minimumSize: const Size(_ctaMinWidth, 52),
                ),
                icon: Icon(ctaIcon, size: 18),
                label: Text(ctaLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

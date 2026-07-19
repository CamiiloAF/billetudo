import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The `Error State` component (`ECG7D`): a neutral card with a retry.
///
/// Shared across every list that can fail to read. Each feature only supplies
/// its own [title]; the reassurance line and the retry label are the same
/// everywhere, because the reason is the same everywhere.
///
/// The icon is deliberately **neutral** (`$muted` / `$text-secondary`, never
/// `$expense`): a failed read is not a financial alarm. And the copy says out
/// loud that the data is still on the device — that is what local-first means
/// to the user.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.onRetry,
    this.description,
    super.key,
  });

  /// `KrwhD` caps the reassurance line at this width so it wraps into two short
  /// centered lines. A maximum rather than a fixed width, so a large text scale
  /// grows the card taller instead of overflowing it.
  static const double _descriptionMaxWidth = 260;

  /// Already localized. Names what failed to load, in the user's words.
  final String title;

  /// Already localized. Defaults to the shared local-first reassurance.
  final String? description;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          // The card spans the available width (350pt in the frame). Without
          // this it would hug its widest child, since the retry button no
          // longer stretches.
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  LucideIcons.triangleAlert,
                  color: colors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _descriptionMaxWidth),
                child: Text(
                  description ?? l10n.accountsErrorLocalFirst,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // `inZFU` hugs its label, which is what the theme gives by
              // default: it imposes the 52pt height and the 20pt side padding,
              // never a width.
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

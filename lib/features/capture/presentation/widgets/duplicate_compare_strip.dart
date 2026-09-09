import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../../transactions/presentation/utils/transaction_amount_presentation.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';

/// `Q1lB88` — the movement **already registered** that a capture may be
/// repeating.
///
/// For comparison only: not tappable, not editable from here. Unlike the
/// capture above it, this one *is* money, which is why its amount reads in
/// the ordinary signed convention and in `$text-primary` rather than
/// attenuated — the contrast between the two rows is the whole point of the
/// comparison.
class DuplicateCompareStrip extends StatelessWidget {
  const DuplicateCompareStrip({required this.duplicate, super.key});

  final CaptureDuplicateView duplicate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CategoryAppearance.softColorFor(
                colors,
                duplicate.categoryColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CategoryAppearance.iconFor(duplicate.categoryIcon),
              size: 16,
              color: CategoryAppearance.colorFor(
                colors,
                duplicate.categoryColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  duplicate.title ?? l10n.captureNoMerchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l10n.captureDuplicateExistingSubtitle(
                    duplicate.accountName ?? l10n.captureNoAccount,
                    captureWhenLabel(l10n, duplicate.date),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            signedAmountLabel(
              amountMinor: duplicate.amountMinor,
              currencyCode: duplicate.currency,
              type: duplicate.type,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// `S8ZNdf`/`BcmBd` — one of the two answers to a possible duplicate.
///
/// A separate widget so the two are provably identical: same fill, same
/// stroke, same label color, same width. "Es la misma" used to be a solid
/// `$primary` button, which let the color decide for the user exactly where
/// a false positive erases a real expense and silently unbalances an
/// account. Deliberately without a default.
class DuplicateActionButton extends StatelessWidget {
  const DuplicateActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 44,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.primaryOnSoft),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `xJOKJ` — the "Posible duplicado" badge.
///
/// `$amber-text` on a `$surface` pill: attention, not alarm. Never
/// `$expense`, which here would read as an accusation about something the
/// user has not even done yet.
class DuplicateBadge extends StatelessWidget {
  const DuplicateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.gitCompare, size: 12, color: colors.amberText),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context).captureDuplicatePill,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.amberText,
                ),
          ),
        ],
      ),
    );
  }
}

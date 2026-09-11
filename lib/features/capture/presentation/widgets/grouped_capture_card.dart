import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';
import 'capture_card_shell.dart';
import 'capture_guarantee_kicker.dart';

/// `RSizy` — a capture grouped with its wallet/bank counterpart (HU-07,
/// high-confidence case, 2026-08-27 decision). One NFC payment fires two
/// notifications — the wallet's and the card's issuing bank's — and this
/// card presents them as ONE proposed movement instead of two rows.
///
/// **Not the possible-duplicate card.** This is high confidence (same
/// amount, same instant, known complementary issuer kinds), not heuristic:
/// there is nothing for the user to resolve, so it keeps the ordinary
/// `$primary-on-soft` rail (never `$amber-text`), is tappable end to end like
/// `PendingCaptureCard`, and has exactly one destination — the pre-filled
/// transaction form. Grouping is not confirming: the card still carries
/// every "not money yet" guarantee ([CaptureGuaranteeKicker], the attenuated
/// amount).
///
/// The source strip is what makes the merge legible: it names both issuers so
/// the user understands why one card answers for two notifications, and it
/// never invents a field neither notification actually sent.
class GroupedCaptureCard extends StatelessWidget {
  const GroupedCaptureCard(
      {required this.item, required this.onTap, super.key});

  final CaptureReviewItem item;

  /// Opens the pre-filled transaction form, exactly as an ordinary capture
  /// would. Never writes a `Transaction` on its own.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final capture = item.capture;
    final group = item.group;
    if (group == null) {
      return const SizedBox.shrink();
    }

    return CaptureCardShell(
      railColor: colors.primaryOnSoft,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // The wallet leg usually formats the merchant better;
                      // never invented when both legs left it empty.
                      group.merchantRaw ??
                          capture.merchantRaw ??
                          l10n.captureNoMerchant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // The account hint here comes from the bank leg, which
                      // is the one that actually knows the card.
                      l10n.captureSubtitle(
                        item.accountName ?? l10n.captureNoAccount,
                        captureWhenLabel(l10n, capture.postedAt),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const CaptureGuaranteeKicker(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                captureAmountLabel(
                  amountMinor: capture.amountMinor,
                  currencyCode: capture.currency,
                  type: capture.entryType,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.layers,
                    size: 12, color: colors.segmentInactiveText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    captureGroupSourceLabel(l10n, group),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: colors.segmentInactiveText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

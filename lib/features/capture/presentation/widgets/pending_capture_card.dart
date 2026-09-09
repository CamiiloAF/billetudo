import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import 'capture_card_header.dart';
import 'capture_status_pill.dart';

/// `vRWd5` — the single card for a capture waiting to be reviewed
/// (HU-04/HU-05).
///
/// One component for both surfaces: the Avisos centre shows it with the
/// "Confirmar" affordance, the movements list turns it off ([showAction] is
/// `false`, mirroring `w5AfEL enabled:false`) because there the card sits
/// among real movements and must not compete with them. Everything else —
/// including the pill — is identical by design; the earlier split into two
/// components had already let the issuer weight and the pill copy drift.
///
/// Five redundant signals say this is **not money**: the `$primary-soft`
/// fill, the `bell-ring` tile, the attenuated amount, the "No suma a tu
/// saldo" pill, and the "Aviso de X" issuer line. None of them is decorative.
class PendingCaptureCard extends StatelessWidget {
  const PendingCaptureCard({
    required this.item,
    required this.onTap,
    this.showAction = true,
    super.key,
  });

  final CaptureReviewItem item;

  /// Opens the ordinary transaction form, pre-filled. Never a parallel
  /// "quick confirm" with rules of its own.
  final VoidCallback onTap;

  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final issuerName = item.issuerName;

    return Material(
      color: colors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // `$primary-on-soft` 1px: the whole card is the tap target, and
        // `$primary-soft` on `$background` is 1.06:1 — WCAG 1.4.11 asks 3:1
        // for a control's boundary.
        side: BorderSide(color: colors.primaryOnSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CaptureCardHeader(item: item),
              const SizedBox(height: 10),
              Row(
                children: [
                  const CaptureStatusPill(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issuerName == null
                          ? ''
                          : l10n.captureIssuerLabel(issuerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (showAction) ...[
                    const SizedBox(width: 8),
                    Text(
                      l10n.captureConfirmAction,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryOnSoftStrong,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: colors.primaryOnSoftStrong,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

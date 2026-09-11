import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import 'movement_pending_capture_card.dart';

/// `vNjim` — the "Pendientes de confirmar" block that opens the movements
/// list (HU-04).
///
/// Captures are pinned **all together at the very top, before the first day
/// group**, never interleaved chronologically: mixed into a long history they
/// simply got lost. Living outside the day groups is also what keeps them
/// out of every daily total — which is why "Hoy" went back to reading "3
/// movimientos" flat, with no "sin confirmar" caveat to explain itself.
///
/// They are still not `Transaction`s: nothing here reaches a balance, a
/// budget, a goal or a chart. Being visible in this list is a UI decision,
/// not a promotion. [MovementPendingCaptureCard] carries no "Confirmar"
/// affordance so it does not compete with the real movements it sits above,
/// but its "No suma a tu saldo" pill is identical — this is the surface where
/// confusing a proposal with money would cost the most.
///
/// The whole block disappears when there are no pending captures.
class PendingCapturesBlock extends StatelessWidget {
  const PendingCapturesBlock({
    required this.items,
    required this.onTap,
    super.key,
  });

  final List<CaptureReviewItem> items;
  final ValueChanged<CaptureReviewItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.captureGhostBlockTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                // States a fact and nothing else. Never a count of what the
                // user has "left undone".
                l10n.captureGhostBlockCount(items.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          for (final item in items) ...[
            const SizedBox(height: 16),
            MovementPendingCaptureCard(item: item, onTap: () => onTap(item)),
          ],
        ],
      ),
    );
  }
}

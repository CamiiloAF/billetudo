import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `YliJD` — the captures section's block-action row: "Revisar las N
/// capturas". Neutral chasis (`$surface` + `$border`, zero tint — same
/// family look as `PendingCaptureCard`).
///
/// **Reviews, never accepts.** This is the only thing the section ever
/// renders past the cap set by `NoticesState.captureLimit`, and it opens the
/// guided review — one capture at a time — never a bulk "confirmar todas",
/// which HU-05 prohibits without exception. The whole row is the tap target;
/// the chevron is a visual close, not a separate control.
class CaptureBlockActionRow extends StatelessWidget {
  const CaptureBlockActionRow({
    required this.captureCount,
    required this.onTap,
    super.key,
  });

  /// The total number of captures the row stands for — always the full
  /// queue, not just what is hidden, so "Revisar las N capturas" states the
  /// whole job the guided flow will walk through.
  final int captureCount;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.listChecks,
                    size: 16,
                    color: colors.primaryOnSoftStrong,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)
                        .captureBlockReviewAction(captureCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryOnSoftStrong,
                        ),
                  ),
                ],
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: colors.primaryOnSoftStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';

/// `krE9G` / `S0iyTP` — the contextual empty state that replaces "Todo al día"
/// when background capture may have stopped and there is nothing to review
/// (HU-09).
///
/// It exists only in the degraded state: the ordinary empty state promises
/// calm ("no tienes nada por revisar"), and making that promise while the
/// listener may be dead is exactly the lie HU-09 forbids. Same `Empty State`
/// component (`jmQO5`), with the shield in `$amber-text` on `$amber-soft` and a
/// single CTA that opens the sheet.
///
/// The copy explains rather than alarms: what the phone does, and that two
/// system settings are enough to keep reading. It never accuses the user of
/// breaking anything.
class CaptureDegradedEmptyView extends StatelessWidget {
  const CaptureDegradedEmptyView({required this.onReview, super.key});

  /// Opens the sheet with the two system settings.
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        // Same frame as the other Avisos empty states (`MEkB8`): the section
        // padding, not a page-wide one.
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: EmptyState(
          icon: LucideIcons.shieldAlert,
          iconColor: colors.amberText,
          iconBackground: colors.amberSoft,
          message: l10n.captureBackgroundEmptyTitle,
          description: l10n.captureBackgroundEmptyDescription,
          ctaLabel: l10n.captureBackgroundEmptyCta,
          ctaIcon: LucideIcons.shieldAlert,
          onCta: onReview,
        ),
      ),
    );
  }
}

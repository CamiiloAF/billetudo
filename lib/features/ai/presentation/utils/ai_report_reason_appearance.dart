import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/ai_report.dart';

/// Icon + already-localized label for each [AiReportReason] (`Afl5e`'s five
/// instances in `billetudo.pen`'s `Reason Grid`). `AiReportReason` has no
/// color pairing of its own — see `Afl5e`'s "entidad sin color" pattern — so
/// this deliberately returns no color, only the icon and copy that a chip
/// then paints in whatever tone its selected state calls for.
abstract final class AiReportReasonAppearance {
  const AiReportReasonAppearance._();

  static const Map<AiReportReason, IconData> _icons = {
    AiReportReason.offensive: LucideIcons.frown,
    AiReportReason.wrong: LucideIcons.xCircle,
    AiReportReason.harmful: LucideIcons.shieldAlert,
    AiReportReason.privacy: LucideIcons.lock,
    AiReportReason.other: LucideIcons.moreHorizontal,
  };

  static IconData icon(AiReportReason reason) => _icons[reason]!;

  static String label(AppLocalizations l10n, AiReportReason reason) =>
      switch (reason) {
        AiReportReason.offensive => l10n.aiReportReasonOffensive,
        AiReportReason.wrong => l10n.aiReportReasonWrong,
        AiReportReason.harmful => l10n.aiReportReasonHarmful,
        AiReportReason.privacy => l10n.aiReportReasonPrivacy,
        AiReportReason.other => l10n.aiReportReasonOther,
      };
}

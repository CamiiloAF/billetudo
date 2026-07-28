import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/coming_soon_badge.dart';
import '../../../widgets/settings_field.dart';
import 'sheets/sync_log_sheet.dart';
import 'sync_section_header.dart';

/// The diagnostics block: the technical log, plus "Exportar a Excel" marked as
/// coming soon in the calm states.
///
/// Excel is deliberately absent from the attention state: it is a read format,
/// not a safety net, and sitting next to "Guardar una copia" while the risk is
/// being named would invite confusing which of the two protects anything.
class SyncDiagnosticsSection extends StatelessWidget {
  const SyncDiagnosticsSection({
    required this.showExcel,
    required this.onOpenComingSoon,
    this.title,
    super.key,
  });

  /// Already localized: "Diagnóstico" in the attention states, where the copy
  /// row sits above with the hero and this block is its own section. `null` in
  /// the calm states, where these rows live under the single "Copia y
  /// diagnóstico" header the copy row already opened.
  final String? title;
  final bool showExcel;
  final ValueChanged<String> onOpenComingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title case final title?) ...[
          SyncSectionHeader(title: title),
          const SizedBox(height: 10),
        ],
        SettingsField(
          icon: LucideIcons.fileText,
          iconColor: colors.textSecondary,
          iconBackground: colors.muted,
          label: l10n.syncTechnicalLogTitle,
          sublabel: l10n.syncTechnicalLogSubtitle,
          onTap: () => unawaited(SyncLogSheet.show(context)),
        ),
        if (showExcel)
          SettingsField(
            icon: LucideIcons.fileSpreadsheet,
            iconColor: colors.textSecondary,
            iconBackground: colors.muted,
            label: l10n.syncExportExcelTitle,
            sublabel: l10n.syncExportExcelSubtitle,
            badge: ComingSoonBadge(label: l10n.comingSoonBadge),
            showChevron: false,
            onTap: () => onOpenComingSoon(l10n.syncExportExcelTitle),
          ),
      ],
    );
  }
}

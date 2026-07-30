import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import 'copy_status_row.dart';

/// The "Copia local" hero card of the Import/Export hub (`oSWz9`/`qDCvi`/
/// `Am9cg` — Variant B "Copia protagonista"): last-saved status plus the
/// save-copy CTA.
class LocalCopyHeroCard extends StatelessWidget {
  const LocalCopyHeroCard({required this.lastSavedAt, required this.onSaveCopy, super.key});

  final DateTime? lastSavedAt;
  final VoidCallback onSaveCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.teal, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: colors.tealSoft, shape: BoxShape.circle),
                child: Icon(LucideIcons.shieldCheck, size: 22, color: colors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.importExportHeroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.cloud, size: 16, color: colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.importExportCloudNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.importExportHeroBody,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CopyStatusRow(
            lastSavedLabel: lastSavedAt == null
                ? null
                : l10n.importExportCopyStatusLastSaved(
                    DateFormat.yMMMMd(l10n.localeName).format(lastSavedAt!),
                  ),
            neverSavedLabel: l10n.importExportCopyStatusNeverSaved,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: NeutralButton(
              label: l10n.importExportSaveCopyCta,
              icon: LucideIcons.download,
              onPressed: onSaveCopy,
            ),
          ),
        ],
      ),
    );
  }
}

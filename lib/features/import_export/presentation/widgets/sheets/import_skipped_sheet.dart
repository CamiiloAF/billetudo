import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/import_summary.dart';

/// "Ver N omitidas y por qué" (`XRBVa`/`Aa1ek`, finding-4 of the fidelity
/// audit): the closing summary always exposes *why* rows were skipped, not
/// only the count — same standard as "Ver N filas con error" in the preview
/// step.
class ImportSkippedSheet extends StatelessWidget {
  const ImportSkippedSheet({required this.summary, super.key});

  final ImportSummary summary;

  static Future<void> show(BuildContext context, {required ImportSummary summary}) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => ImportSkippedSheet(summary: summary),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.importExportSkippedSheetTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (summary.rowsSkippedDuplicate > 0)
          _SkippedReasonRow(
            icon: LucideIcons.copy,
            color: colors.amberText,
            text: l10n.importExportSkippedDuplicateReason(summary.rowsSkippedDuplicate),
          ),
        if (summary.rowsSkippedDuplicate > 0 && summary.rowsSkippedError > 0)
          const SizedBox(height: 12),
        if (summary.rowsSkippedError > 0)
          _SkippedReasonRow(
            icon: LucideIcons.circleX,
            color: colors.expenseText,
            text: l10n.importExportSkippedErrorReason(summary.rowsSkippedError),
          ),
      ],
    );
  }
}

class _SkippedReasonRow extends StatelessWidget {
  const _SkippedReasonRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

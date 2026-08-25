import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/import_summary.dart';
import '../skipped_reason_row.dart';

/// "Ver N omitidas y por qué" (`XRBVa`/`Aa1ek`, finding-4 of the fidelity
/// audit): the closing summary always exposes *why* rows were skipped, not
/// only the count — same standard as "Ver N filas con error" in the preview
/// step.
class ImportSkippedSheet extends StatelessWidget {
  const ImportSkippedSheet({required this.summary, super.key});

  final ImportSummary summary;

  static Future<void> show(BuildContext context,
          {required ImportSummary summary}) =>
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
          SkippedReasonRow(
            icon: LucideIcons.copy,
            color: colors.amberText,
            text: l10n.importExportSkippedDuplicateReason(
                summary.rowsSkippedDuplicate),
          ),
        if (summary.rowsSkippedDuplicate > 0 && summary.rowsSkippedError > 0)
          const SizedBox(height: 12),
        if (summary.rowsSkippedError > 0)
          SkippedReasonRow(
            icon: LucideIcons.circleX,
            color: colors.expenseText,
            text: l10n.importExportSkippedErrorReason(summary.rowsSkippedError),
          ),
      ],
    );
  }
}

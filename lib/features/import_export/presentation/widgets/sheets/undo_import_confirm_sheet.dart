import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/import_batch.dart';
import '../privacy_note_strip.dart';

/// HU-08's "Deshacer esta importación" confirmation (`l1twf`/`r59P4P`).
///
/// The destructive CTA ("Deshacer importación") uses `$expense` (undo trashes
/// rows, coherent with `03-transacciones.md`'s trash semantics) and, per the
/// spec's "CTA destructivo con label largo" rule, stacks vertically instead
/// of shrinking when the label does not fit the row's 50/50 split.
class UndoImportConfirmSheet extends StatelessWidget {
  const UndoImportConfirmSheet({required this.batch, super.key});

  final ImportBatch batch;

  static Future<bool?> show(BuildContext context, {required ImportBatch batch}) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) => UndoImportConfirmSheet(batch: batch),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: colors.expenseSoft, shape: BoxShape.circle),
          child: Icon(LucideIcons.undo2, color: colors.expenseText, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.importExportUndoConfirmTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.importExportUndoConfirmBody(batch.fileName, batch.rowsImported),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // `KGHzS`: what happens to accounts/categories this batch created —
        // never mentioned before, and a real question for anyone who kept
        // using them since ("¿deshacer también borra la cuenta que creó?").
        PrivacyNoteStrip(text: l10n.importExportUndoConfirmKeepNote),
        const SizedBox(height: 16),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colors.expense),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(LucideIcons.undo2, size: 18),
                label: Text(l10n.importExportUndoConfirmCta),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

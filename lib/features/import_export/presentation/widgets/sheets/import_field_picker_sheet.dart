import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/sheet_action_row.dart';
import '../../../domain/entities/column_mapping.dart';

/// Sentinel [ImportFieldPickerSheet] pops for "No usar", distinct from
/// `null` (sheet dismissed without choosing) even though both leave the
/// column unmapped.
const Object clearedImportField = Object();

/// Picker sheet for which canonical [ImportField] a CSV column maps to
/// (HU-05/06 mapping step), opened from `ImportMappingStep`.
class ImportFieldPickerSheet extends StatelessWidget {
  const ImportFieldPickerSheet({required this.currentMapping, super.key});

  final ColumnMapping currentMapping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.importExportFieldPickerTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SheetActionRow.bare(
          icon: LucideIcons.ban,
          title: l10n.importExportFieldNotUsed,
          onTap: () => Navigator.of(context).pop(clearedImportField),
        ),
        for (final field in ImportField.values)
          SheetActionRow.bare(
            icon: LucideIcons.circleCheck,
            title: _labelFor(l10n, field),
            onTap: () => Navigator.of(context).pop(field),
          ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, ImportField field) => switch (field) {
        ImportField.id => l10n.importExportFieldId,
        ImportField.date => l10n.importExportFieldDate,
        ImportField.amount => l10n.importExportFieldAmount,
        ImportField.type => l10n.importExportFieldType,
        ImportField.currency => l10n.importExportFieldCurrency,
        ImportField.account => l10n.importExportFieldAccount,
        ImportField.transferAccount => l10n.importExportFieldTransferAccount,
        ImportField.category => l10n.importExportFieldCategory,
        ImportField.subcategory => l10n.importExportFieldSubcategory,
        ImportField.note => l10n.importExportFieldNote,
        ImportField.tags => l10n.importExportFieldTags,
      };
}

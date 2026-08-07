import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/sheet_action_row.dart';
import '../../../domain/entities/named_entity.dart';

/// Sheet listing existing entities the user can map an unresolved CSV name
/// to (HU-06 "mapear a existente"), opened from `UnresolvedDestinationRow`.
class ExistingDestinationPickerSheet extends StatelessWidget {
  const ExistingDestinationPickerSheet({required this.options, super.key});

  final List<NamedEntity> options;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (options.isEmpty) {
      return Text(l10n.importExportDestinationsPickerEmpty);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          SheetActionRow.bare(
            icon: LucideIcons.check,
            title: option.name,
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    );
  }
}

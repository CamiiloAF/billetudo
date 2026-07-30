import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../domain/entities/import_destination.dart';
import '../../domain/entities/named_entity.dart';
import '../pages/import_destinations_step.dart';
import 'destination_resolve_row.dart';
import 'sheets/existing_destination_picker_sheet.dart';

/// One [UnresolvedDestination] row within [ImportDestinationsStep] (HU-06):
/// resolves to "crear nueva" (default) or "mapear a existente".
class UnresolvedDestinationRow extends StatefulWidget {
  const UnresolvedDestinationRow({
    required this.item,
    required this.overrides,
    required this.onOverride,
    required this.loadExisting,
    super.key,
  });

  final UnresolvedDestination item;
  final Map<String, ImportDestination> overrides;
  final void Function(String key, ImportDestination destination) onOverride;
  final Future<List<NamedEntity>> Function() loadExisting;

  @override
  State<UnresolvedDestinationRow> createState() => _UnresolvedDestinationRowState();
}

class _UnresolvedDestinationRowState extends State<UnresolvedDestinationRow> {
  NamedEntity? _mapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final override = widget.overrides[widget.item.key];
    final creatingNew = override is! ExistingImportDestination;

    return DestinationResolveRow(
      icon: widget.item.icon,
      name: widget.item.name,
      subtitle: l10n.importExportDestinationNotFound,
      createLabel: l10n.importExportDestinationCreateNew,
      mapLabel: l10n.importExportDestinationMapExisting,
      creatingNew: creatingNew,
      mappedValue: _mapped?.name,
      onToggle: (toCreate) {
        if (toCreate) {
          widget.onOverride(widget.item.key, NewImportDestination(widget.item.name));
        } else {
          unawaited(_openPicker());
        }
      },
      onTapMapped: () => unawaited(_openPicker()),
    );
  }

  Future<void> _openPicker() async {
    final options = await widget.loadExisting();
    if (!mounted) {
      return;
    }
    final selected = await BottomSheetBase.show<NamedEntity>(
      context,
      builder: (context) => ExistingDestinationPickerSheet(options: options),
    );
    if (selected != null) {
      setState(() => _mapped = selected);
      widget.onOverride(widget.item.key, ExistingImportDestination(selected.id));
    }
  }
}

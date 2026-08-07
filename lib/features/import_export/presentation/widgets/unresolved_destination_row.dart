import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../transactions/presentation/widgets/category_picker/category_select_sheet.dart';
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
    // Categories/subcategories reuse the app's real `Category Select Sheet`
    // (`SfSln`) — it already solves hierarchy, search and single-select;
    // `ExistingDestinationPickerSheet`'s flat `SheetActionRow.bare` list has
    // neither and produced a real overflow bug in production
    // (`design-system/billetudo/pages/import-export.md`). Accounts and tags
    // have no equivalent picker in the system, so they keep the generic one.
    final isCategoryKind = widget.item.kind == DestinationKind.category ||
        widget.item.kind == DestinationKind.subcategory;
    if (isCategoryKind) {
      final selected = await CategorySelectSheet.show(
        context,
        kind: widget.item.isExpense ? CategoryKind.expense : CategoryKind.income,
      );
      if (selected != null && mounted) {
        setState(
          () => _mapped = NamedEntity(id: selected.id, name: selected.name),
        );
        widget.onOverride(widget.item.key, ExistingImportDestination(selected.id));
      }
      return;
    }

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

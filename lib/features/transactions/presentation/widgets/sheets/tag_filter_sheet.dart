import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/tag_filter_cubit.dart';
import 'category_filter_header_action.dart';
import 'new_tag_sheet.dart';
import 'tag_filter_row.dart';

/// The multi-select tag sheet (`FL1gK`, "Sheet - Filtro de Etiqueta"):
/// selection over the live tag list plus creating a new tag on the fly.
/// Reused in two contexts with the same body but different copy and header
/// action:
///
/// - the transactions list filter (HU-06): title "Filtrar por etiqueta",
///   confirm "Aplicar", header shows "Todas · Ninguna";
/// - a field's Etiquetas picker (HU-07, also reused by Pagos Programados):
///   title "Etiquetas", confirm "Listo", header shows a "+" to create a tag.
///
/// [title]/[confirmLabel] default to the filter copy so existing callers keep
/// working unchanged; passing them switches the header to the "+" action.
class TagFilterSheet extends StatelessWidget {
  const TagFilterSheet({
    required this.initialSelected,
    this.title,
    this.confirmLabel,
    super.key,
  });

  final Set<String> initialSelected;

  /// Sheet heading. Falls back to the filter copy when null.
  final String? title;

  /// Confirm button label. Falls back to "Aplicar" when null.
  final String? confirmLabel;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
    String? title,
    String? confirmLabel,
  }) =>
      BottomSheetBase.show<Set<String>>(
        context,
        builder: (context) => TagFilterSheet(
          initialSelected: initialSelected,
          title: title,
          confirmLabel: confirmLabel,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<TagFilterCubit>();
        unawaited(cubit.start(initialSelected));
        return cubit;
      },
      child: TagFilterSheetBody(title: title, confirmLabel: confirmLabel),
    );
  }
}

class TagFilterSheetBody extends StatefulWidget {
  const TagFilterSheetBody({this.title, this.confirmLabel, super.key});

  final String? title;
  final String? confirmLabel;

  @override
  State<TagFilterSheetBody> createState() => _TagFilterSheetBodyState();
}

class _TagFilterSheetBodyState extends State<TagFilterSheetBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final heading = widget.title ?? l10n.tagFilterSheetTitle;
    final confirm = widget.confirmLabel ?? l10n.commonApply;
    // The "+" header action only shows up in the selection-for-a-field
    // context (a title override is passed); the plain list filter keeps
    // "Todas"/"Ninguna" (`FL1gK`'s `Actions` block).
    final showCreateAction = widget.title != null;
    final query = _query.trim().toLowerCase();

    return BlocBuilder<TagFilterCubit, TagFilterState>(
      builder: (context, state) {
        final cubit = context.read<TagFilterCubit>();
        final tags = query.isEmpty
            ? state.tags
            : state.tags
                .where((tag) => tag.name.toLowerCase().contains(query))
                .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    heading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (showCreateAction)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () async {
                        final name = await NewTagSheet.show(context);
                        if (name != null && name.trim().isNotEmpty) {
                          await cubit.createTag(name);
                        }
                      },
                      icon: const Icon(LucideIcons.plus, size: 18),
                      color: colors.primaryOnSoft,
                      tooltip: l10n.transactionFormAddTag,
                    ),
                  )
                else ...[
                  CategoryFilterHeaderAction(
                    label: l10n.accountFilterSelectAll,
                    onTap: cubit.selectAll,
                  ),
                  Text(
                    ' · ',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: colors.border),
                  ),
                  CategoryFilterHeaderAction(
                    label: l10n.accountFilterSelectNone,
                    onTap: cubit.selectNone,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.muted,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: colors.textSecondary,
                ),
                hintText: l10n.tagFilterSearchHint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in tags)
                    TagFilterRow(
                      name: tag.name,
                      selected: state.selected.contains(tag.id),
                      onTap: () => cubit.toggle(tag.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(state.selected),
                icon: const Icon(LucideIcons.check, size: 18),
                label: Text(confirm),
              ),
            ),
          ],
        );
      },
    );
  }
}

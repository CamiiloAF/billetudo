import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/tag_filter_cubit.dart';
import 'new_tag_sheet.dart';

/// The multi-select tag sheet (`FL1gK`): selection over the live tag list plus
/// creating a new tag on the fly. Reused in two contexts with the same body but
/// different copy:
///
/// - the transactions list filter (HU-06): title "Filtrar por etiqueta",
///   confirm "Aplicar";
/// - the transaction form's Etiquetas field (HU-07): title "Etiquetas", confirm
///   "Listo".
///
/// [title]/[confirmLabel] default to the filter copy so existing callers keep
/// working unchanged.
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

class TagFilterSheetBody extends StatelessWidget {
  const TagFilterSheetBody({this.title, this.confirmLabel, super.key});

  final String? title;
  final String? confirmLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final heading = title ?? l10n.tagFilterSheetTitle;
    final confirm = confirmLabel ?? l10n.commonApply;
    return BlocBuilder<TagFilterCubit, TagFilterState>(
      builder: (context, state) {
        final cubit = context.read<TagFilterCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    heading,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final name = await NewTagSheet.show(context);
                    if (name != null && name.trim().isNotEmpty) {
                      await cubit.createTag(name);
                    }
                  },
                  icon: const Icon(LucideIcons.plus),
                  tooltip: l10n.transactionFormAddTag,
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final tag in state.tags)
                    CheckboxListTile(
                      value: state.selected.contains(tag.id),
                      onChanged: (_) => cubit.toggle(tag.id),
                      title: Text(tag.name),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(state.selected),
              child: Text(confirm),
            ),
          ],
        );
      },
    );
  }
}

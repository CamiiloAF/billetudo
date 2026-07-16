import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../cubit/tag_filter_cubit.dart';
import 'new_tag_sheet.dart';

/// HU-06/HU-07's tag filter sheet: multiple selection over the live tag
/// list, plus creating a new tag on the fly.
class TagFilterSheet extends StatelessWidget {
  const TagFilterSheet({required this.initialSelected, super.key});

  final Set<String> initialSelected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
  }) =>
      showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => TagFilterSheet(initialSelected: initialSelected),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<TagFilterCubit>();
        unawaited(cubit.start(initialSelected));
        return cubit;
      },
      child: const TagFilterSheetBody(),
    );
  }
}

class TagFilterSheetBody extends StatelessWidget {
  const TagFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TagFilterCubit, TagFilterState>(
      builder: (context, state) {
        final cubit = context.read<TagFilterCubit>();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.tagFilterSheetTitle,
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
                  child: Text(l10n.commonApply),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

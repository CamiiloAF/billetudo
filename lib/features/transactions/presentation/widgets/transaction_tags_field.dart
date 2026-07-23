import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/forms/keyboard.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/tag_filter_cubit.dart';
import 'sheets/tag_filter_sheet.dart';
import 'transaction_form_tag_chip.dart';

/// The Etiquetas section of the transaction form (HU-07), shown for expense and
/// income only (transfers carry no tags).
///
/// The form cubit owns the selected ids; this widget hosts a [TagFilterCubit]
/// purely to resolve those ids into names for the chips and to reuse the tag
/// picker sheet — composing another cubit for read-only display is fine.
class TransactionTagsField extends StatelessWidget {
  const TransactionTagsField({
    required this.selectedIds,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<TagFilterCubit>();
        unawaited(cubit.start(selectedIds));
        return cubit;
      },
      child: TransactionTagsFieldBody(
        selectedIds: selectedIds,
        onChanged: onChanged,
      ),
    );
  }
}

class TransactionTagsFieldBody extends StatelessWidget {
  const TransactionTagsFieldBody({
    required this.selectedIds,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TagFilterCubit, TagFilterState>(
      builder: (context, state) {
        final names = {for (final tag in state.tags) tag.id: tag.name};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.transactionFormTagsLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in selectedIds)
                  TransactionFormTagChip(
                    label: names[id] ?? '',
                    onTap: () => onChanged({...selectedIds}..remove(id)),
                  ),
                TransactionFormTagChip(
                  label: l10n.transactionFormTagNew,
                  icon: LucideIcons.plus,
                  removable: false,
                  neutral: true,
                  onTap: () async {
                    // Drop the system keyboard before opening the sheet so it
                    // does not spring back when the sheet closes.
                    await dismissSystemKeyboard(context);
                    if (!context.mounted) {
                      return;
                    }
                    final result = await TagFilterSheet.show(
                      context,
                      initialSelected: selectedIds,
                      title: l10n.transactionFormTagsSheetTitle,
                      confirmLabel: l10n.commonDone,
                    );
                    if (result != null) {
                      onChanged(result);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

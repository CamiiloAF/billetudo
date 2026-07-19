import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../transactions/presentation/widgets/sheets/tag_filter_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_form_tag_chip.dart';
import '../cubit/scheduled_payment_tag_picker_cubit.dart';

/// The Etiquetas section of the template form (criterion 2), mirroring
/// `transactions/presentation/widgets/transaction_tags_field.dart` for this
/// feature's own `Tag`/`ScheduledPaymentTags` table. Never rendered for a
/// `transfer` (criterion 16) — the form page only includes it when
/// `!state.isTransfer`.
class ScheduledPaymentTagsField extends StatelessWidget {
  const ScheduledPaymentTagsField({
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
        final cubit = getIt<ScheduledPaymentTagPickerCubit>();
        unawaited(cubit.start(selectedIds));
        return cubit;
      },
      child: ScheduledPaymentTagsFieldBody(
        selectedIds: selectedIds,
        onChanged: onChanged,
      ),
    );
  }
}

class ScheduledPaymentTagsFieldBody extends StatelessWidget {
  const ScheduledPaymentTagsFieldBody({
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
    return BlocBuilder<ScheduledPaymentTagPickerCubit,
        ScheduledPaymentTagPickerState>(
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
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
    return BlocBuilder<ScheduledPaymentTagPickerCubit, ScheduledPaymentTagPickerState>(
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
                  ScheduledPaymentTagChip(
                    label: names[id] ?? '',
                    onTap: () => onChanged({...selectedIds}..remove(id)),
                  ),
                ScheduledPaymentTagChip(
                  label: l10n.transactionFormTagNew,
                  icon: LucideIcons.plus,
                  removable: false,
                  neutral: true,
                  onTap: () async {
                    final result = await ScheduledPaymentTagPickerSheet.show(
                      context,
                      initialSelected: selectedIds,
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

/// A `Tag Chip`, same visual language as Transacciones' own, but with its tap
/// target padded to 44pt (documented deuda técnica in the design spec, unlike
/// the transaction form's chip which was shipped without it).
class ScheduledPaymentTagChip extends StatelessWidget {
  const ScheduledPaymentTagChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.removable = true,
    this.neutral = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool removable;
  final bool neutral;
  final VoidCallback onTap;

  static const double _radius = 18;
  static const double _minTapTarget = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final fill = neutral ? colors.muted : colors.primarySoft;
    final foreground = neutral ? colors.textSecondary : colors.primaryOnSoftStrong;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTapTarget),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (removable) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.x, size: 12, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The multi-select tag sheet for the template form, mirroring
/// `transactions/presentation/widgets/sheets/tag_filter_sheet.dart`.
class ScheduledPaymentTagPickerSheet extends StatelessWidget {
  const ScheduledPaymentTagPickerSheet({
    required this.initialSelected,
    super.key,
  });

  final Set<String> initialSelected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
  }) =>
      showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ScheduledPaymentTagPickerSheet(
          initialSelected: initialSelected,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<ScheduledPaymentTagPickerCubit>();
        unawaited(cubit.start(initialSelected));
        return cubit;
      },
      child: const ScheduledPaymentTagPickerSheetBody(),
    );
  }
}

class ScheduledPaymentTagPickerSheetBody extends StatelessWidget {
  const ScheduledPaymentTagPickerSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScheduledPaymentTagPickerCubit, ScheduledPaymentTagPickerState>(
      builder: (context, state) {
        final cubit = context.read<ScheduledPaymentTagPickerCubit>();
        return BottomSheetBase(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactionFormTagsSheetTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final name = await _promptNewTagName(context);
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
                child: Text(l10n.commonDone),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _promptNewTagName(BuildContext context) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transactionFormAddTag),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

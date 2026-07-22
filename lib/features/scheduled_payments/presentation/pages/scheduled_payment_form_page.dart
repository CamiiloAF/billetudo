import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/delete_link.dart';
import '../../../transactions/presentation/pages/transaction_form_page.dart'
    show AccountPickerField;
import '../../../transactions/presentation/widgets/category_picker/category_quick_picker.dart';
import '../../../transactions/presentation/widgets/transaction_header_button.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/entities/scheduled_payment_draft.dart';
import '../cubit/scheduled_payment_form_cubit.dart';
import '../cubit/scheduled_payment_form_state.dart';
import '../widgets/scheduled_payment_amount_fixed_zone.dart';
import '../widgets/scheduled_payment_date_field.dart';
import '../widgets/scheduled_payment_frequency_unit_chips.dart';
import '../widgets/scheduled_payment_interval_stepper.dart';
import '../widgets/scheduled_payment_mode_radio_card.dart';
import '../widgets/scheduled_payment_tags_field.dart';
import '../widgets/sheets/delete_scheduled_payment_sheet.dart';

/// Create/edit template form (HU-01/HU-05): a companion of `once`
/// (frequency/interval/endDate collapse away), the confirmation-mode radio
/// cards (criterion 6), and a transfer that drops category/tags entirely
/// (criterion 16).
class ScheduledPaymentFormPage extends StatelessWidget {
  const ScheduledPaymentFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ScheduledPaymentFormStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == ScheduledPaymentFormStatus.deleted) {
          // The template that owned this route no longer exists: replace the
          // whole stack (form + the detail page underneath it) instead of
          // popping back into a detail screen with nothing left to show.
          GoRouter.of(context).go(AppRoutes.scheduledPayments);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final cubit = context.read<ScheduledPaymentFormCubit>();
        final colors = context.colors;
        return Scaffold(
          appBar: AppBar(
            leadingWidth: 60,
            // `J0DSIm` draws the form's ✕ as a bare icon — unlike the
            // detail's `arrow-left`/⋮, which do sit in a `$muted` circle.
            // The difference is intentional; do not unify them.
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                color: colors.textPrimary,
                tooltip: l10n.commonCancel,
                onPressed: Navigator.of(context).pop,
              ),
            ),
            title: Text(
              state.isEditing
                  ? l10n.scheduledPaymentFormEditTitle
                  : l10n.scheduledPaymentFormNewTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TransactionHeaderButton(
                  icon: LucideIcons.check,
                  background: colors.primary,
                  foreground: colors.onPrimary,
                  tooltip: l10n.commonSave,
                  onPressed: state.isSaving ? null : cubit.submit,
                ),
              ),
            ],
          ),
          body: state.status == ScheduledPaymentFormStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(child: ScheduledPaymentFormBody(state: state)),
                      ScheduledPaymentAmountFixedZone(
                        amountMinor:
                            MoneyFormatter.parseMinor(state.amountText) ?? 0,
                        currency: state.currency,
                        onChanged: cubit.amountChanged,
                        errorText: state.failedField ==
                                ScheduledPaymentDraft.fieldAmountMinor
                            ? l10n.scheduledPaymentErrorAmount
                            : null,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class ScheduledPaymentFormBody extends StatelessWidget {
  const ScheduledPaymentFormBody({required this.state, super.key});

  final ScheduledPaymentFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<ScheduledPaymentFormCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        ScheduledPaymentTypeSegmentedControl(
          type: state.type,
          onChanged: cubit.typeSelected,
        ),
        const SizedBox(height: 12),
        AccountPickerField(
          label: l10n.transactionFormAccountLabel,
          selectedId: state.accountId,
          selectedName: state.accountName,
          onSelected: cubit.accountSelected,
          excludingId: state.transferAccountId,
          errorText:
              state.failedField == ScheduledPaymentDraft.fieldAccountId
                  ? l10n.scheduledPaymentErrorAccount
                  : null,
        ),
        if (state.isTransfer) ...[
          const SizedBox(height: 8),
          AccountPickerField(
            label: l10n.transactionFormTransferAccountLabel,
            selectedId: state.transferAccountId,
            selectedName: state.transferAccountName,
            onSelected: cubit.transferAccountSelected,
            excludingId: state.accountId,
            errorText: state.failedField ==
                    ScheduledPaymentDraft.fieldTransferAccountId
                ? l10n.scheduledPaymentErrorTransferAccount
                : null,
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            l10n.transactionFormCategoryLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          CategoryQuickPicker(
            kind: state.type == ScheduledPaymentType.income
                ? CategoryKind.income
                : CategoryKind.expense,
            selectedId: state.categoryId,
            accountId: state.accountId,
            showLabel: false,
            moreLabel: l10n.scheduledPaymentFormCategoryMoreLabel,
            onSelected: (category) => cubit.categorySelected(
              category.id,
              category.kind,
              category.name,
            ),
            errorText:
                state.failedField == ScheduledPaymentDraft.fieldCategoryId
                    ? l10n.scheduledPaymentErrorCategory
                    : null,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.scheduledPaymentFormFrequencyLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ScheduledPaymentFrequencyUnitChips(
          frequency: state.frequency,
          onChanged: cubit.frequencyChanged,
        ),
        if (state.showRecurrenceOptions) ...[
          const SizedBox(height: 12),
          ScheduledPaymentIntervalStepper(
            interval: state.interval,
            onChanged: cubit.intervalChanged,
          ),
        ],
        const SizedBox(height: 8),
        ScheduledPaymentDateField(
          // The label itself is part of the `once` disclosure (spec
          // §"Disclosure condicional de la frecuencia"): with no recurrence
          // there is no "primer" pago, just *the* payment date.
          label: state.showRecurrenceOptions
              ? l10n.scheduledPaymentFormNextDateLabel
              : l10n.scheduledPaymentFormOnceDateLabel,
          date: state.nextDate,
          onChanged: cubit.nextDateChanged,
        ),
        if (state.showRecurrenceOptions) ...[
          const SizedBox(height: 8),
          ScheduledPaymentDateField(
            label: l10n.scheduledPaymentFormEndDateLabel,
            date: state.endDate,
            placeholder: l10n.scheduledPaymentFormEndDateNone,
            onChanged: cubit.endDateChanged,
            onCleared: () => cubit.endDateChanged(null),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.scheduledPaymentFormModeSectionLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ScheduledPaymentModeRadioCard(
          selected: !state.requiresConfirmation,
          icon: LucideIcons.zap,
          title: l10n.scheduledPaymentFormModeAutomaticTitle,
          subtitle: l10n.scheduledPaymentFormModeAutomaticSubtitle,
          onTap: () => cubit.requiresConfirmationChanged(false),
        ),
        const SizedBox(height: 8),
        ScheduledPaymentModeRadioCard(
          selected: state.requiresConfirmation,
          icon: LucideIcons.bell,
          title: l10n.scheduledPaymentFormModeManualTitle,
          subtitle: l10n.scheduledPaymentFormModeManualSubtitle,
          onTap: () => cubit.requiresConfirmationChanged(true),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.transactionFormNoteLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.note,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.transactionFormNoteLabel),
          onChanged: cubit.noteChanged,
        ),
        if (!state.isTransfer) ...[
          const SizedBox(height: 8),
          ScheduledPaymentTagsField(
            selectedIds: state.tagIds,
            onChanged: cubit.tagsChanged,
          ),
        ],
        if (state.isEditing) ...[
          const SizedBox(height: 28),
          DeleteLink(
            label: l10n.scheduledPaymentFormDeleteAction,
            onTap: () => unawaited(
              DeleteScheduledPaymentSheet.show(context,
                  onConfirm: cubit.delete),
            ),
          ),
        ],
      ],
    );
  }
}

/// Same three values as `TransactionType`, kept as this feature's own enum
/// (see `ScheduledPayment` doc); this control is its own small widget instead
/// of reusing `TransactionTypeSegmentedControl` to avoid mapping between two
/// enums just for a 3-segment pill.
class ScheduledPaymentTypeSegmentedControl extends StatelessWidget {
  const ScheduledPaymentTypeSegmentedControl({
    required this.type,
    required this.onChanged,
    super.key,
  });

  final ScheduledPaymentType type;
  final ValueChanged<ScheduledPaymentType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labels = <ScheduledPaymentType, String>{
      ScheduledPaymentType.expense: l10n.transactionTypeExpense,
      ScheduledPaymentType.income: l10n.transactionTypeIncome,
      ScheduledPaymentType.transfer: l10n.transactionTypeTransfer,
    };
    final types = labels.keys.toList();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        children: [
          for (var i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Material(
                color: types[i] == type ? colors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => onChanged(types[i]),
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      labels[types[i]]!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: types[i] == type
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

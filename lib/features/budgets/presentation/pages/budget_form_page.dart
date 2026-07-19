import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../accounts/presentation/widgets/sheets/currency_picker_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/account_filter_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/category_filter_sheet.dart';
import '../cubit/budget_form_cubit.dart';
import '../cubit/budget_form_state.dart';
import '../utils/budget_format.dart';
import '../widgets/budget_amount_field.dart';
import '../widgets/budget_field_label.dart';
import '../widgets/budget_form_bottom_bar.dart';
import '../widgets/budget_icon_button.dart';
import '../widgets/budget_name_field.dart';
import '../widgets/budget_nav_field.dart';
import '../widgets/budget_period_chips.dart';
import '../widgets/budget_scope_hint.dart';
import '../widgets/sheets/budget_icon_sheet.dart';
import '../widgets/sheets/budget_threshold_sheet.dart';

/// Create / edit budget (`a3gGPM`, HU-01/HU-03/HU-09).
///
/// Section order comes straight from `a3gGPM/lBpTl`: Ícono y nombre → Monto →
/// Alcance → Repetir → Periodicidad → Inicio → Repetir hasta / Fin → Umbral,
/// with the CTA pinned in its own bottom bar. "Repetir" conditions
/// "Periodicidad" (HU-03) and the scope reveals its rows only in
/// "Personalizado"; the CTA is gated on a valid name and a positive amount.
class BudgetFormPage extends StatelessWidget {
  const BudgetFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetFormCubit, BudgetFormState>(
      listenWhen: (previous, current) => previous.savedId != current.savedId,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final loading = state.status == BudgetFormStatus.loading;
        final cubit = context.read<BudgetFormCubit>();
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                PageHeader(
                  title: state.isEditing
                      ? l10n.budgetFormEditTitle
                      : l10n.budgetFormNewTitle,
                ),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : const BudgetFormBody(),
                ),
                if (!loading)
                  BudgetFormBottomBar(
                    label: state.isEditing
                        ? l10n.budgetFormSaveCta
                        : l10n.budgetFormCreateCta,
                    onPressed: state.canSubmit && !state.submitting
                        ? cubit.submit
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

/// The form's fields. Stateful only for the scope disclosure ("Todo" vs.
/// "Personalizado"), which cannot be derived from the selection alone (a custom
/// scope with nothing picked is still global).
class BudgetFormBody extends StatefulWidget {
  const BudgetFormBody({super.key});

  @override
  State<BudgetFormBody> createState() => _BudgetFormBodyState();
}

class _BudgetFormBodyState extends State<BudgetFormBody> {
  bool? _scopeCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BudgetFormCubit>();
    final state = context.watch<BudgetFormCubit>().state;
    final scopeCustom = _scopeCustom ??= state.isCustomScope;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      children: [
        // -- Icon + name (one section, one label on the margin) --
        BudgetFieldLabel(text: l10n.budgetFormIconNameLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            BudgetIconButton(
              icon: state.icon,
              onTap: () async {
                final picked =
                    await BudgetIconSheet.show(context, selected: state.icon);
                if (picked != null) {
                  cubit.iconSelected(picked);
                }
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BudgetNameField(
                initialValue: state.name,
                hint: l10n.budgetFormNameHint,
                onChanged: cubit.nameChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // -- Amount (with the currency pill anchored inside the box) --
        BudgetFieldLabel(text: l10n.budgetFormAmountLabel),
        const SizedBox(height: 6),
        BudgetAmountField(
          amountMinor: state.amountMinor,
          currency: state.currency,
          onChanged: cubit.amountChanged,
          onCurrencyTap: () async {
            final picked = await CurrencyPickerSheet.show(
              context,
              selected: state.currency,
            );
            if (picked != null) {
              cubit.currencyChanged(picked);
            }
          },
        ),
        const SizedBox(height: 12),

        // -- Scope --
        BudgetFieldLabel(text: l10n.budgetFormScopeLabel),
        const SizedBox(height: 8),
        SegmentedControl<bool>(
          segments: [
            SegmentedControlOption(
              value: false,
              label: l10n.budgetFormScopeAll,
            ),
            SegmentedControlOption(
              value: true,
              label: l10n.budgetFormScopeCustom,
            ),
          ],
          selected: scopeCustom,
          onChanged: (custom) {
            setState(() => _scopeCustom = custom);
            if (!custom) {
              cubit
                ..accountsSelected(const {})
                ..categoriesSelected(const {});
            }
          },
        ),
        const SizedBox(height: 8),
        if (scopeCustom) ...[
          BudgetNavField(
            label: l10n.budgetFormAccountsRow,
            icon: LucideIcons.wallet,
            value: state.accountIds.isEmpty
                ? l10n.budgetScopeAllAccounts
                : l10n.budgetScopeAccounts(state.accountIds.length),
            onTap: () async {
              final picked = await AccountFilterSheet.show(
                context,
                initialSelected: state.accountIds,
              );
              if (picked != null) {
                cubit.accountsSelected(picked);
              }
            },
          ),
          const SizedBox(height: 8),
          BudgetNavField(
            label: l10n.budgetFormCategoriesRow,
            icon: LucideIcons.tag,
            value: state.categoryIds.isEmpty
                ? l10n.budgetScopeAllCategories
                : l10n.budgetScopeCategories(state.categoryIds.length),
            onTap: () async {
              final picked = await CategoryFilterSheet.show(
                context,
                initialSelected: state.categoryIds,
              );
              if (picked != null) {
                cubit.categoriesSelected(picked);
              }
            },
          ),
        ] else
          const BudgetScopeHint(),
        const SizedBox(height: 12),

        // -- Repeat (before Frequency) --
        BudgetFieldLabel(text: l10n.budgetFormRepeatLabel),
        const SizedBox(height: 8),
        SegmentedControl<bool>(
          segments: [
            SegmentedControlOption(
              value: true,
              label: l10n.budgetFormRepeatPeriodic,
            ),
            SegmentedControlOption(
              value: false,
              label: l10n.budgetFormRepeatOneOff,
            ),
          ],
          selected: state.recurring,
          onChanged: (recurring) =>
              cubit.recurringChanged(recurring: recurring),
        ),
        const SizedBox(height: 12),

        // -- Frequency (periodic only) --
        if (state.recurring) ...[
          BudgetFieldLabel(text: l10n.budgetFormPeriodLabel),
          const SizedBox(height: 8),
          BudgetPeriodChips(
            selected: state.period,
            onChanged: cubit.periodSelected,
          ),
          const SizedBox(height: 12),
        ],

        // -- Start date --
        BudgetNavField(
          label: l10n.budgetFormStartLabel,
          icon: LucideIcons.calendar,
          value: BudgetFormat.longDate(state.startDate),
          onTap: () => _pickStartDate(context, cubit, state),
        ),
        const SizedBox(height: 12),

        // -- "Repetir hasta" (periodic) / "Fin" (one-off) --
        if (state.recurring)
          BudgetNavField(
            label: l10n.budgetFormRepeatUntilLabel,
            icon: LucideIcons.repeat,
            value: state.endDate == null
                ? l10n.budgetFormForever
                : BudgetFormat.longDate(state.endDate!),
            onTap: () => _pickEndDate(context, cubit, state),
            onCleared: state.endDate == null
                ? null
                : () => cubit.endDateSelected(null),
          )
        else
          BudgetNavField(
            label: l10n.budgetFormEndLabel,
            icon: LucideIcons.calendarCheck,
            value: state.endDate == null
                ? l10n.budgetFormEndHint
                : BudgetFormat.longDate(state.endDate!),
            onTap: () => _pickEndDate(context, cubit, state),
          ),
        const SizedBox(height: 12),

        // -- Alert threshold --
        BudgetNavField(
          icon: LucideIcons.bell,
          value: state.alertThresholdPct == null
              ? l10n.budgetFormThresholdOff
              : l10n.budgetFormThresholdRow(state.alertThresholdPct!),
          onTap: () async {
            final choice = await BudgetThresholdSheet.show(
              context,
              selected: state.alertThresholdPct,
            );
            if (choice != null) {
              cubit.thresholdSelected(choice.pct);
            }
          },
        ),
      ],
    );
  }

  Future<void> _pickStartDate(
    BuildContext context,
    BudgetFormCubit cubit,
    BudgetFormState state,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: state.startDate,
    );
    if (picked != null) {
      cubit.startDateSelected(picked);
    }
  }

  Future<void> _pickEndDate(
    BuildContext context,
    BudgetFormCubit cubit,
    BudgetFormState state,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: state.endDate ?? state.startDate,
    );
    if (picked != null) {
      cubit.endDateSelected(picked);
    }
  }
}

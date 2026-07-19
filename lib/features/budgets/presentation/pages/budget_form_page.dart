import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../accounts/presentation/widgets/account_form_field.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../../transactions/presentation/widgets/sheets/account_filter_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/category_filter_sheet.dart';
import '../../domain/entities/budget.dart';
import '../cubit/budget_form_cubit.dart';
import '../cubit/budget_form_state.dart';
import '../utils/budget_format.dart';
import '../widgets/sheets/budget_icon_sheet.dart';
import '../widgets/sheets/budget_threshold_sheet.dart';

/// Create / edit budget (`a3gGPM`, HU-01/HU-03/HU-09). "Repetir" comes before
/// "Periodicidad" and conditions it; the scope reveals its rows only in
/// "Personalizado"; the CTA is gated on a valid name and positive amount.
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
                  child: state.status == BudgetFormStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : const BudgetFormBody(),
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

  static final DateFormat _dateLabel = DateFormat('d MMM y', 'es_CO');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BudgetFormCubit>();
    final state = context.watch<BudgetFormCubit>().state;
    final scopeCustom = _scopeCustom ??= state.isCustomScope;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        // -- Icon + Name --
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
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
            const SizedBox(width: 12),
            Expanded(
              child: AccountFormField.text(
                label: l10n.budgetFormNameLabel,
                hint: l10n.budgetFormNameHint,
                initialValue: state.name,
                maxLength: 100,
                onChanged: cubit.nameChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // -- Amount --
        AccountFormField.text(
          label: l10n.budgetFormAmountLabel,
          icon: LucideIcons.wallet,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          initialValue: state.amountMinor == null
              ? null
              // The currency's own decimals (Pencil shows a whole `$0`): COP
              // has none, so a prefilled amount must not read `4.500.000,00`.
              : const MoneyFormatter().formatAmount(
                  state.amountMinor!,
                  decimalDigits:
                      MoneyFormatter.currencyDecimals(state.currency),
                ),
          onChanged: (value) =>
              cubit.amountChanged(MoneyFormatter.parseMinor(value)),
        ),
        const SizedBox(height: 18),

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
        const SizedBox(height: 18),

        // -- Frequency (periodic only) --
        if (state.recurring) ...[
          BudgetFieldLabel(text: l10n.budgetFormPeriodLabel),
          const SizedBox(height: 8),
          SegmentedControl<BudgetPeriod>(
            segments: [
              for (final period in const [
                BudgetPeriod.weekly,
                BudgetPeriod.biweekly,
                BudgetPeriod.monthly,
                BudgetPeriod.yearly,
              ])
                SegmentedControlOption(
                  value: period,
                  label: BudgetFormat.periodLabel(l10n, period),
                ),
            ],
            selected: state.period,
            onChanged: cubit.periodSelected,
          ),
          const SizedBox(height: 18),
        ],

        // -- Start date --
        AccountFormField.selector(
          label: l10n.budgetFormStartLabel,
          icon: LucideIcons.calendar,
          value: _dateLabel.format(state.startDate),
          onTap: () => _pickStartDate(context, cubit, state),
        ),
        const SizedBox(height: 18),

        // -- End / Repeat until --
        if (state.recurring)
          BudgetRepeatUntilField(
            endDate: state.endDate,
            label: l10n.budgetFormRepeatUntilLabel,
            foreverLabel: l10n.budgetFormForever,
            untilLabel: l10n.budgetFormUntilDate,
            valueLabel: state.endDate == null
                ? null
                : _dateLabel.format(state.endDate!),
            onForever: () => cubit.endDateSelected(null),
            onPickDate: () => _pickEndDate(context, cubit, state),
          )
        else
          AccountFormField.selector(
            label: l10n.budgetFormEndLabel,
            icon: LucideIcons.calendarCheck,
            value: state.endDate == null
                ? null
                : _dateLabel.format(state.endDate!),
            hint: l10n.budgetFormEndLabel,
            onTap: () => _pickEndDate(context, cubit, state),
          ),
        const SizedBox(height: 18),

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
        if (scopeCustom) ...[
          const SizedBox(height: 12),
          AccountFormField.selector(
            label: l10n.budgetFormAccountsRow,
            icon: LucideIcons.landmark,
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
          const SizedBox(height: 12),
          AccountFormField.selector(
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
        ],
        const SizedBox(height: 18),

        // -- Alert threshold --
        AccountFormField.selector(
          label: l10n.budgetThresholdTitle,
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
        const SizedBox(height: 28),

        // -- CTA --
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                state.canSubmit && !state.submitting ? cubit.submit : null,
            child: Text(
              state.isEditing
                  ? l10n.budgetFormSaveCta
                  : l10n.budgetFormCreateCta,
            ),
          ),
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

/// A section label above a field group.
class BudgetFieldLabel extends StatelessWidget {
  const BudgetFieldLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      );
}

/// The neutral icon-wrap button that opens the budget icon picker (no color).
class BudgetIconButton extends StatelessWidget {
  const BudgetIconButton({required this.icon, required this.onTap, super.key});

  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            CategoryAppearance.iconFor(icon),
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// "Repetir hasta": Forever vs. a picked date, for a periodic budget (HU-03).
class BudgetRepeatUntilField extends StatelessWidget {
  const BudgetRepeatUntilField({
    required this.endDate,
    required this.label,
    required this.foreverLabel,
    required this.untilLabel,
    required this.valueLabel,
    required this.onForever,
    required this.onPickDate,
    super.key,
  });

  final DateTime? endDate;
  final String label;
  final String foreverLabel;
  final String untilLabel;
  final String? valueLabel;
  final VoidCallback onForever;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetFieldLabel(text: label),
        const SizedBox(height: 8),
        SegmentedControl<bool>(
          segments: [
            SegmentedControlOption(value: false, label: foreverLabel),
            SegmentedControlOption(value: true, label: untilLabel),
          ],
          selected: endDate != null,
          onChanged: (untilDate) {
            if (untilDate) {
              onPickDate();
            } else {
              onForever();
            }
          },
        ),
        if (endDate != null) ...[
          const SizedBox(height: 12),
          AccountFormField.selector(
            label: untilLabel,
            icon: LucideIcons.calendarCheck,
            value: valueLabel,
            onTap: onPickDate,
          ),
        ],
      ],
    );
  }
}

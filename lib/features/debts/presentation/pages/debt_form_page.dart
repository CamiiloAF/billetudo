import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_input_formatter.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_draft.dart';
import '../cubit/debt_form_cubit.dart';
import '../cubit/debt_form_state.dart';
import '../utils/debt_format.dart';
import '../widgets/debt_amount_hero_field.dart';
import '../widgets/debt_direction_toggle.dart';
import '../widgets/debt_form_field.dart';
import '../widgets/sheets/confirm_delete_debt_sheet.dart';
import '../widgets/sheets/debt_account_picker_sheet.dart';
import '../widgets/sheets/debt_currency_picker_sheet.dart';
import '../widgets/sheets/debt_initial_registro_sheet.dart';
import '../widgets/sheets/debt_update_registro_sheet.dart';

/// Crear / editar deuda (`dUryC`, variante B "monto héroe", HU-01/HU-05): the
/// opening balance as the héroe, the direction toggle, name, optional
/// counterparty / due date / interest, and a fixed "Crear deuda" CTA. Editing
/// prefills every field and reveals the "Eliminar deuda" link (papelera/undo).
///
/// Pops with `true` when the debt was deleted, so the caller can also close the
/// detail behind it; pops with nothing on a plain save (the list/detail streams
/// update on their own).
class DebtFormPage extends StatelessWidget {
  const DebtFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtFormCubit, DebtFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.prompt != current.prompt,
      listener: (context, state) {
        // A pending prompt (item 2 / 2b) takes precedence: open its sheet.
        if (state.prompt != null) {
          unawaited(_handlePrompt(context, state));
          return;
        }
        switch (state.status) {
          case DebtFormStatus.saved:
            Navigator.of(context).pop();
          case DebtFormStatus.deleted:
            Navigator.of(context).pop(true);
          case DebtFormStatus.loading:
          case DebtFormStatus.ready:
          case DebtFormStatus.saving:
          case DebtFormStatus.failure:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                DebtFormHeader(isEditing: state.isEditing),
                Expanded(
                  child: state.status == DebtFormStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : DebtFormBody(state: state),
                ),
                DebtFormBottomBar(state: state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Opens the sheet a pending [DebtFormState.prompt] asks for (item 2 / 2b) and
  /// routes the user's answer back into the cubit. Dismissing any sheet aborts
  /// without creating or changing anything.
  Future<void> _handlePrompt(BuildContext context, DebtFormState state) async {
    final cubit = context.read<DebtFormCubit>();
    final prompt = state.prompt;

    switch (prompt) {
      case DebtChooseRegistroPrompt():
        final choice = await DebtInitialRegistroSheet.show(context);
        if (!context.mounted) {
          return;
        }
        switch (choice) {
          case null:
            cubit.cancelPrompt();
          case DebtInitialRegistroChoice.soloDeuda:
            unawaited(cubit.chooseSoloDeuda());
          case DebtInitialRegistroChoice.chooseAccount:
            // Defensive (edge case E): the registro prompt is only offered when
            // there is at least one account (see `DebtFormCubit.submit`), so
            // "elegir cuenta" can never reach an empty picker. If the set became
            // empty meanwhile, abort instead of opening a blank picker.
            if (state.accounts.isEmpty) {
              cubit.cancelPrompt();
              return;
            }
            final accountId = await DebtAccountPickerSheet.show(
              context,
              accounts: state.accounts,
              // Creating a debt must not pre-select an account: the opening
              // movement lands real money on whichever account the user picks,
              // so that choice is explicit (unlike the abono sheet, which may
              // remember a previous account).
              selectedId: null,
            );
            if (!context.mounted) {
              return;
            }
            if (accountId == null) {
              cubit.cancelPrompt();
            } else {
              unawaited(cubit.createWithOpeningMovement(accountId));
            }
        }
      case DebtConfirmUpdateRegistroPrompt(:final fromMinor, :final toMinor):
        final confirmed = await DebtUpdateRegistroSheet.show(
          context,
          fromLabel: DebtFormat.amount(fromMinor, state.currency),
          toLabel: DebtFormat.amount(toMinor, state.currency),
        );
        if (!context.mounted) {
          return;
        }
        if (confirmed ?? false) {
          unawaited(cubit.confirmUpdateRegistro());
        } else {
          cubit.dismissUpdateRegistro();
        }
      case null:
        break;
    }
  }
}

/// The form header (`lvAed`): an "x" close on the left and a centered title,
/// no trailing action — the CTA lives at the thumb zone.
class DebtFormHeader extends StatelessWidget {
  const DebtFormHeader({required this.isEditing, super.key});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          PageHeaderCircleButton(
            icon: LucideIcons.x,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonCancel,
            onPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: Text(
              isEditing ? l10n.debtFormEditTitle : l10n.debtFormNewTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class DebtFormBody extends StatelessWidget {
  const DebtFormBody({required this.state, super.key});

  final DebtFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<DebtFormCubit>();
    final dueDate = state.dueDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      children: [
        // Field Dirección.
        Text(
          l10n.debtFormDirectionLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        DebtDirectionToggle(
          direction: state.direction,
          onChanged: cubit.directionChanged,
        ),
        const SizedBox(height: 14),
        // Amount héroe (opening balance) + currency pill.
        DebtAmountHeroField(
          key: ValueKey('opening-${state.id ?? 'new'}'),
          fieldKey: const ValueKey('debt-amount-opening'),
          label: l10n.debtFormOpeningBalanceLabel,
          currency: state.currency,
          initialAmountMinor: state.amountMinor,
          onChanged: cubit.amountChanged,
          errorText: state.failedField == DebtDraft.fieldPrincipalMinor
              ? l10n.debtFormErrorAmountZero
              : null,
          boxed: true,
          currencyLabel: l10n.debtCurrencyPill(
            state.currency,
            _currencyName(l10n, state.currency),
          ),
          onTapCurrency: () => _pickCurrency(context, cubit, state.currency),
        ),
        const SizedBox(height: 14),
        // Nombre.
        DebtFormField.text(
          key: ValueKey('name-${state.id ?? 'new'}'),
          label: l10n.debtFormNameLabel,
          hint: l10n.debtFormNameHint,
          initialValue: state.name,
          textCapitalization: TextCapitalization.sentences,
          maxLength: DebtDraft.maxNameLength,
          errorText: state.failedField == DebtDraft.fieldName
              ? l10n.debtFormNameRequired
              : null,
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: 14),
        // Contraparte (label is directional: "Le debo a" / "Me debe").
        DebtFormField.text(
          key: ValueKey('counterparty-${state.id ?? 'new'}'),
          label: state.direction == DebtDirection.iOwe
              ? l10n.debtFormCounterpartyLabelIOwe
              : l10n.debtFormCounterpartyLabelOwedToMe,
          icon: LucideIcons.building2,
          hint: l10n.debtFormCounterpartyHint,
          initialValue: state.counterparty,
          textCapitalization: TextCapitalization.words,
          maxLength: DebtDraft.maxCounterpartyLength,
          onChanged: cubit.counterpartyChanged,
        ),
        const SizedBox(height: 14),
        // Fecha (start date): required, defaults to today, never in the future
        // and never cleared (no "×"), so it always shows a value.
        DebtFormField.selector(
          label: l10n.debtFormStartDateLabel,
          icon: LucideIcons.calendar,
          value: state.startDate == null
              ? null
              : DebtFormat.relativeDate(context, l10n, state.startDate!),
          onTap: () => _pickStartDate(context, cubit, state.startDate),
        ),
        const SizedBox(height: 14),
        // Fecha de vencimiento (optional, clearable, may be in the future).
        DebtFormField.selector(
          label: l10n.debtFormDueDateLabel,
          icon: LucideIcons.calendar,
          hint: l10n.debtFormDueDateHint,
          value: dueDate == null
              ? null
              : DebtFormat.dateLong(context, dueDate),
          errorText: state.failedField == DebtDraft.fieldDueDate
              ? l10n.debtFormErrorDueBeforeStart
              : null,
          onTap: () => _pickDueDate(context, cubit, dueDate),
          // A cleared due date returns the debt to "Sin fecha" (item 1e).
          onClear: dueDate == null ? null : () => cubit.dueDateChanged(null),
        ),
        const SizedBox(height: 14),
        // Card Interés.
        DebtInterestCard(state: state, cubit: cubit),
        if (state.isEditing) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => unawaited(_confirmDelete(context, cubit)),
              style: TextButton.styleFrom(foregroundColor: colors.expense),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(l10n.debtFormDelete),
            ),
          ),
        ],
      ],
    );
  }

  static String _currencyName(AppLocalizations l10n, String code) =>
      code == 'USD' ? l10n.currencyUsdName : l10n.currencyCopName;

  Future<void> _pickCurrency(
    BuildContext context,
    DebtFormCubit cubit,
    String current,
  ) async {
    final picked =
        await DebtCurrencyPickerSheet.show(context, selected: current);
    if (picked != null) {
      cubit.currencyChanged(picked);
    }
  }

  Future<void> _pickStartDate(
    BuildContext context,
    DebtFormCubit cubit,
    DateTime? current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current ?? DateTime.now(),
      // A debt cannot start in the future; no lower bound.
      disabledAfter: DateTime.now(),
    );
    if (picked != null) {
      cubit.startDateChanged(picked);
    }
  }

  Future<void> _pickDueDate(
    BuildContext context,
    DebtFormCubit cubit,
    DateTime? current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current ?? DateTime.now(),
    );
    if (picked != null) {
      cubit.dueDateChanged(picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context, DebtFormCubit cubit) async {
    final confirmed = await ConfirmDeleteDebtSheet.show(context);
    if ((confirmed ?? false) && context.mounted) {
      await cubit.delete();
    }
  }
}

/// The interest card (`Ulfjr`): the optional annual rate, the Manual/Automático
/// accrual mode (`hFu41`), and a hint explaining what each mode does.
class DebtInterestCard extends StatelessWidget {
  const DebtInterestCard({required this.state, required this.cubit, super.key});

  final DebtFormState state;
  final DebtFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DebtFormField.text(
            key: ValueKey('rate-${state.id ?? 'new'}'),
            label: l10n.debtFormInterestLabel,
            icon: LucideIcons.percent,
            hint: l10n.debtFormInterestHint,
            initialValue: state.rateText,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [
              // A rate is a scaled percentage, so it accepts two decimals but
              // never a thousands separator.
              MoneyInputFormatter(decimals: 2, maxIntegerDigits: 3),
            ],
            trailingText: '%',
            errorText: state.failedField == DebtDraft.fieldInterestRateBps
                ? l10n.debtFormInterestError
                : null,
            onChanged: cubit.rateChanged,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.debtFormAccrualModeLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedControl<DebtAccrualMode>(
            selected: state.accrualMode,
            onChanged: cubit.accrualModeChanged,
            segments: [
              SegmentedControlOption(
                value: DebtAccrualMode.manual,
                label: l10n.debtFormAccrualManual,
              ),
              SegmentedControlOption(
                value: DebtAccrualMode.auto,
                label: l10n.debtFormAccrualAuto,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.debtFormAccrualHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The fixed bottom bar with the primary "Crear deuda" / "Guardar cambios" CTA.
class DebtFormBottomBar extends StatelessWidget {
  const DebtFormBottomBar({required this.state, super.key});

  final DebtFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: FilledButton.icon(
        onPressed: state.isSaving
            ? null
            : context.read<DebtFormCubit>().submit,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(LucideIcons.check, size: 18),
        label: Text(
          state.isEditing ? l10n.debtFormSaveCta : l10n.debtFormCreateCta,
        ),
      ),
    );
  }
}

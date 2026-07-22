import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/account_draft.dart';
import '../cubit/account_form_cubit.dart';
import '../cubit/account_form_state.dart';
import '../widgets/account_form_field.dart';
import '../widgets/account_money_field.dart';
import '../widgets/account_type_grid.dart';
import '../widgets/account_type_pill.dart';
import '../widgets/card_details_section.dart';
import '../widgets/sheets/confirm_type_or_currency_change_sheet.dart';
import '../widgets/sheets/currency_picker_sheet.dart';
import '../widgets/sheets/day_picker_sheet.dart';

/// Add / edit account (`CwiKu`/`xdLeB`/`jg9DA`).
///
/// One page, two shapes: creating shows the neutral type grid outright, editing
/// collapses the type into a pill that expands the same grid inline.
class AccountFormPage extends StatelessWidget {
  const AccountFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.needsConfirmation != current.needsConfirmation,
      listener: (context, state) {
        if (state.status == AccountFormStatus.saved) {
          Navigator.of(context).pop();
          return;
        }
        if (state.needsConfirmation) {
          unawaited(_confirmChange(context));
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                PageHeader(
                  title: state.isEditing
                      ? l10n.accountFormEditTitle
                      : l10n.accountFormNewTitle,
                  onBack: Navigator.of(context).pop,
                  trailing: PageHeaderCircleButton(
                    icon: LucideIcons.check,
                    background: colors.primary,
                    foreground: colors.onPrimary,
                    tooltip: l10n.commonSave,
                    onPressed: state.status == AccountFormStatus.saving
                        ? null
                        : context.read<AccountFormCubit>().submit,
                  ),
                ),
                Expanded(
                  child: state.status == AccountFormStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : AccountFormBody(state: state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// HU-06: the use case refused the change until the user says so. Asking and
  /// re-submitting with the answer is the whole flow.
  Future<void> _confirmChange(BuildContext context) async {
    final cubit = context.read<AccountFormCubit>();
    final confirmed = await ConfirmTypeOrCurrencyChangeSheet.show(context);
    if (confirmed ?? false) {
      await cubit.submit(confirmed: true);
    }
  }
}

/// The form's fields. Which ones exist depends on the type: only a card asks for
/// a credit limit, only an account that may keep a number asks for one.
class AccountFormBody extends StatelessWidget {
  const AccountFormBody({required this.state, super.key});

  final AccountFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AccountFormCubit>();
    final type = state.type;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          l10n.accountFormTypeLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        // The pill/grid swap animates its own height, so the fields below slide
        // instead of jumping.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: state.showTypeGrid || type == null
              ? AccountTypeGrid(selected: type, onSelected: cubit.typeSelected)
              : AccountTypePill(type: type, onChange: cubit.toggleTypePicker),
        ),
        if (state.failedField == AccountFormState.fieldType) ...[
          const SizedBox(height: 8),
          FormFieldError(message: l10n.accountErrorType),
        ],
        const SizedBox(height: 18),
        AccountFormField.text(
          label: l10n.accountFormNameLabel,
          icon: LucideIcons.pencilLine,
          hint: l10n.accountFormNameHint,
          initialValue: state.name,
          errorText: _errorFor(l10n, state, AccountDraft.fieldName),
          maxLength: AccountDraft.maxNameLength,
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: 16),
        AccountFormField.text(
          label: l10n.accountFormInstitutionLabel,
          icon: LucideIcons.landmark,
          hint: l10n.accountFormInstitutionHint,
          initialValue: state.institution,
          errorText: _errorFor(l10n, state, AccountDraft.fieldInstitution),
          maxLength: AccountDraft.maxInstitutionLength,
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.institutionChanged,
        ),
        // A card's debt lives only in "Datos de la tarjeta" (`Deuda actual`),
        // not as a top-level money field — `xdLeB`/`jg9DA` go from Moneda
        // straight into that section, with no field in between.
        //
        // Mejora #1: the opening balance is only editable while **creating**.
        // On an existing account the balance is derived, and moving it now
        // goes through "Ajustar saldo" on the detail (controlled), never a
        // silent rewrite of the opening figure here.
        if (!state.isCard && !state.isEditing) ...[
          const SizedBox(height: 16),
          AccountMoneyField(
            label: l10n.accountFormInitialBalanceLabel,
            icon: LucideIcons.banknote,
            hint: l10n.accountFormAmountHint,
            currency: state.currency,
            text: state.initialBalanceText,
            errorText:
                _errorFor(l10n, state, AccountFormState.fieldInitialBalance),
            allowNegative: true,
            onChanged: cubit.initialBalanceChanged,
          ),
        ],
        const SizedBox(height: 16),
        AccountFormField.selector(
          label: l10n.accountFormCurrencyLabel,
          icon: LucideIcons.circleDollarSign,
          value: state.currency,
          errorText: _errorFor(l10n, state, AccountDraft.fieldCurrency),
          onTap: () => _pickCurrency(context),
        ),
        if (state.showFullNumberField) ...[
          const SizedBox(height: 16),
          AccountNumberField(state: state),
        ],
        if (state.showLast4Field) ...[
          const SizedBox(height: 16),
          AccountFormField.text(
            label: l10n.accountFormLast4Label,
            icon: LucideIcons.tag,
            hint: l10n.accountFormLast4Hint,
            initialValue: state.last4,
            errorText: _errorFor(l10n, state, AccountDraft.fieldLast4),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 4,
            onChanged: cubit.last4Changed,
          ),
        ],
        if (state.showInterestRateField) ...[
          const SizedBox(height: 16),
          AccountFormField.text(
            label: l10n.accountFormInterestRateLabel,
            hint: l10n.accountFormInterestRateHint,
            initialValue: state.interestRateText,
            errorText:
                _errorFor(l10n, state, AccountDraft.fieldInterestRateBps),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: cubit.interestRateChanged,
          ),
        ],
        if (state.isCard) ...[
          const SizedBox(height: 24),
          CardDetailsSection(
            currency: state.currency,
            creditLimitText: state.creditLimitText,
            // Mejora #1: a new card names its starting debt here; on an
            // existing card the debt is derived and only "Ajustar saldo"
            // changes it, so the field is hidden when editing.
            showDebtField: !state.isEditing,
            debtText: state.initialBalanceText,
            debtError:
                _errorFor(l10n, state, AccountFormState.fieldInitialBalance),
            onDebtChanged: cubit.initialBalanceChanged,
            statementDay: state.statementDay,
            paymentDueDay: state.paymentDueDay,
            creditLimitError:
                _errorFor(l10n, state, AccountDraft.fieldCreditLimitMinor),
            statementDayError:
                _errorFor(l10n, state, AccountDraft.fieldStatementDay),
            paymentDueDayError:
                _errorFor(l10n, state, AccountDraft.fieldPaymentDueDay),
            onCreditLimitChanged: cubit.creditLimitChanged,
            onStatementDayTap: () => _pickDay(
              context,
              title: l10n.accountFormStatementDayLabel,
              selected: state.statementDay,
              onPicked: cubit.statementDaySelected,
            ),
            onPaymentDueDayTap: () => _pickDay(
              context,
              title: l10n.accountFormPaymentDueDayLabel,
              selected: state.paymentDueDay,
              onPicked: cubit.paymentDueDaySelected,
            ),
          ),
        ],
        const SizedBox(height: 24),
        // `Button/Primary` "Guardar cuenta" (`DuS3K`/`vR0Ex` in `CwiKu`/
        // `xdLeB`), full-width at the end of the content — in addition to the
        // check icon in the `Page Header`, not instead of it.
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                state.status == AccountFormStatus.saving ? null : cubit.submit,
            icon: const Icon(LucideIcons.check),
            label: Text(l10n.accountFormSaveCta),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final cubit = context.read<AccountFormCubit>();
    final picked =
        await CurrencyPickerSheet.show(context, selected: state.currency);
    if (picked != null) {
      cubit.currencySelected(picked);
    }
  }

  Future<void> _pickDay(
    BuildContext context, {
    required String title,
    required int? selected,
    required ValueChanged<int> onPicked,
  }) async {
    final picked =
        await DayPickerSheet.show(context, title: title, selected: selected);
    if (picked != null) {
      onPicked(picked);
    }
  }
}

/// HU-03: the full number field.
///
/// Prefilled when editing, obscured by default, same as the detail. It only
/// ever exists for types allowed to keep a number: a card gets the `last4`
/// field instead.
///
/// When secure storage could not return the stored number the field comes up
/// empty, and an empty field is indistinguishable from "this account has no
/// number" — so it says out loud why, instead of letting the user assume their
/// number is gone.
class AccountNumberField extends StatelessWidget {
  const AccountNumberField({required this.state, super.key});

  final AccountFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AccountFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccountFormField.text(
          label: l10n.accountFormNumberLabel,
          icon: LucideIcons.hash,
          hint: l10n.accountFormNumberHint,
          helperText: l10n.accountFormNumberHelp,
          initialValue: state.fullAccountNumber,
          errorText:
              _errorFor(l10n, state, AccountDraft.fieldFullAccountNumber),
          keyboardType: TextInputType.number,
          obscureText: !state.numberVisible,
          trailing: IconButton(
            onPressed: cubit.toggleNumberVisibility,
            tooltip: state.numberVisible
                ? l10n.accountNumberHide
                : l10n.accountNumberReveal,
            icon: Icon(
              state.numberVisible ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 20,
            ),
          ),
          onChanged: cubit.fullAccountNumberChanged,
        ),
        if (state.isNumberUnknown) ...[
          const SizedBox(height: 6),
          FormFieldError(message: l10n.accountFormNumberReadError),
        ],
      ],
    );
  }
}

/// The error message of a field that is not a `Form Field` (the type grid).
class FormFieldError extends StatelessWidget {
  const FormFieldError({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: context.colors.expense),
      );
}

/// Maps the failing field the domain named to the message for that field.
///
/// The domain's `message` is technical English for logs; the user gets the
/// localized string, and only on the field that actually failed.
String? _errorFor(AppLocalizations l10n, AccountFormState state, String field) {
  if (state.failedField != field) {
    return null;
  }
  return switch (field) {
    AccountDraft.fieldName => l10n.accountErrorName,
    AccountDraft.fieldCurrency => l10n.accountErrorCurrency,
    AccountDraft.fieldInstitution => l10n.accountErrorInstitution,
    AccountDraft.fieldFullAccountNumber => l10n.accountErrorFullNumber,
    AccountDraft.fieldLast4 => l10n.accountErrorLast4,
    AccountDraft.fieldInterestRateBps => l10n.accountErrorInterestRate,
    AccountDraft.fieldCreditLimitMinor => l10n.accountErrorCreditLimit,
    AccountDraft.fieldStatementDay => l10n.accountErrorStatementDay,
    AccountDraft.fieldPaymentDueDay => l10n.accountErrorPaymentDueDay,
    AccountFormState.fieldInitialBalance => l10n.accountErrorInitialBalance,
    AccountFormState.fieldType => l10n.accountErrorType,
    _ => null,
  };
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/forms/form_error_scroll_controller.dart';
import '../../../../core/forms/keyboard.dart';
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
class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key});

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final FormErrorScrollController _errorScroll = FormErrorScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.needsConfirmation != current.needsConfirmation ||
          previous.failedField != current.failedField,
      listener: (context, state) {
        if (state.status == AccountFormStatus.saved) {
          Navigator.of(context).pop();
          return;
        }
        if (state.needsConfirmation) {
          unawaited(_confirmChange(context));
        }
        _errorScroll.scrollToField(state.failedField);
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
                      : AccountFormBody(
                          state: state,
                          errorScroll: _errorScroll,
                        ),
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
class AccountFormBody extends StatefulWidget {
  const AccountFormBody({
    required this.state,
    required this.errorScroll,
    super.key,
  });

  final AccountFormState state;
  final FormErrorScrollController errorScroll;

  @override
  State<AccountFormBody> createState() => _AccountFormBodyState();
}

class _AccountFormBodyState extends State<AccountFormBody> {
  // Focus is chained explicitly across the text fields, in VISIBLE order, so
  // "siguiente" jumps to the next text input while skipping the selectors
  // (currency, statement/payment day) that sit between them — traversal would
  // otherwise land on a focusable selector. Which nodes are live depends on the
  // type, so the chain is recomputed on every build (see [_textFieldChain]).
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _institutionFocus = FocusNode();
  final FocusNode _initialBalanceFocus = FocusNode();
  final FocusNode _fullNumberFocus = FocusNode();
  final FocusNode _last4Focus = FocusNode();
  final FocusNode _interestRateFocus = FocusNode();
  final FocusNode _creditLimitFocus = FocusNode();
  final FocusNode _cardDebtFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _institutionFocus.dispose();
    _initialBalanceFocus.dispose();
    _fullNumberFocus.dispose();
    _last4Focus.dispose();
    _interestRateFocus.dispose();
    _creditLimitFocus.dispose();
    _cardDebtFocus.dispose();
    super.dispose();
  }

  /// The focus nodes of the currently visible text fields, in the order they
  /// appear on screen. Conditional fields (initial balance, full number, last
  /// 4, interest rate, card credit limit / debt) are included only when their
  /// state predicate says they are rendered — matching [build] exactly.
  List<FocusNode> _textFieldChain(AccountFormState state) => <FocusNode>[
        _nameFocus,
        _institutionFocus,
        if (!state.isCard && !state.isEditing) _initialBalanceFocus,
        if (state.showFullNumberField) _fullNumberFocus,
        if (state.showLast4Field) _last4Focus,
        if (state.showInterestRateField) _interestRateFocus,
        if (state.isCard) _creditLimitFocus,
        if (state.isCard && !state.isEditing) _cardDebtFocus,
      ];

  /// "listo" on the last visible text field, "siguiente" on the rest.
  TextInputAction _actionFor(FocusNode node, List<FocusNode> chain) =>
      node == chain.last ? TextInputAction.done : TextInputAction.next;

  /// What confirming the keyboard action does: move to the next visible text
  /// field, or dismiss the keyboard when this is the last one.
  VoidCallback _submitFor(FocusNode node, List<FocusNode> chain) {
    final index = chain.indexOf(node);
    if (index == chain.length - 1) {
      return () => FocusScope.of(context).unfocus();
    }
    return chain[index + 1].requestFocus;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final errorScroll = widget.errorScroll;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AccountFormCubit>();
    final type = state.type;
    final chain = _textFieldChain(state);

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
        KeyedSubtree(
          key: errorScroll.keyFor(AccountFormState.fieldType),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: state.showTypeGrid || type == null
                ? AccountTypeGrid(
                    selected: type,
                    onSelected: (selected) {
                      FocusScope.of(context).unfocus();
                      cubit.typeSelected(selected);
                    },
                  )
                : AccountTypePill(
                    type: type,
                    onChange: () {
                      FocusScope.of(context).unfocus();
                      cubit.toggleTypePicker();
                    },
                  ),
          ),
        ),
        if (state.failedField == AccountFormState.fieldType) ...[
          const SizedBox(height: 8),
          FormFieldError(message: l10n.accountErrorType),
        ],
        const SizedBox(height: 18),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldName),
          child: AccountFormField.text(
            label: l10n.accountFormNameLabel,
            icon: LucideIcons.pencilLine,
            hint: l10n.accountFormNameHint,
            initialValue: state.name,
            errorText: _errorFor(l10n, state, AccountDraft.fieldName),
            maxLength: AccountDraft.maxNameLength,
            textCapitalization: TextCapitalization.words,
            onChanged: cubit.nameChanged,
            focusNode: _nameFocus,
            textInputAction: _actionFor(_nameFocus, chain),
            onSubmitted: _submitFor(_nameFocus, chain),
          ),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldInstitution),
          child: AccountFormField.text(
            label: l10n.accountFormInstitutionLabel,
            icon: LucideIcons.landmark,
            hint: l10n.accountFormInstitutionHint,
            initialValue: state.institution,
            errorText: _errorFor(l10n, state, AccountDraft.fieldInstitution),
            maxLength: AccountDraft.maxInstitutionLength,
            textCapitalization: TextCapitalization.words,
            onChanged: cubit.institutionChanged,
            focusNode: _institutionFocus,
            textInputAction: _actionFor(_institutionFocus, chain),
            onSubmitted: _submitFor(_institutionFocus, chain),
          ),
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
          KeyedSubtree(
            key: errorScroll.keyFor(AccountFormState.fieldInitialBalance),
            child: AccountMoneyField(
              label: l10n.accountFormInitialBalanceLabel,
              icon: LucideIcons.banknote,
              hint: l10n.accountFormAmountHint,
              currency: state.currency,
              text: state.initialBalanceText,
              errorText:
                  _errorFor(l10n, state, AccountFormState.fieldInitialBalance),
              allowNegative: true,
              onChanged: cubit.initialBalanceChanged,
              focusNode: _initialBalanceFocus,
              textInputAction: _actionFor(_initialBalanceFocus, chain),
              onSubmitted: _submitFor(_initialBalanceFocus, chain),
            ),
          ),
        ],
        const SizedBox(height: 16),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldCurrency),
          child: AccountFormField.selector(
            label: l10n.accountFormCurrencyLabel,
            icon: LucideIcons.circleDollarSign,
            value: state.currency,
            errorText: _errorFor(l10n, state, AccountDraft.fieldCurrency),
            onTap: () => _pickCurrency(context),
          ),
        ),
        if (state.showFullNumberField) ...[
          const SizedBox(height: 16),
          KeyedSubtree(
            key: errorScroll.keyFor(AccountDraft.fieldFullAccountNumber),
            child: AccountNumberField(
              state: state,
              focusNode: _fullNumberFocus,
              textInputAction: _actionFor(_fullNumberFocus, chain),
              onSubmitted: _submitFor(_fullNumberFocus, chain),
            ),
          ),
        ],
        if (state.showLast4Field) ...[
          const SizedBox(height: 16),
          KeyedSubtree(
            key: errorScroll.keyFor(AccountDraft.fieldLast4),
            child: AccountFormField.text(
              label: l10n.accountFormLast4Label,
              icon: LucideIcons.tag,
              hint: l10n.accountFormLast4Hint,
              initialValue: state.last4,
              errorText: _errorFor(l10n, state, AccountDraft.fieldLast4),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              onChanged: cubit.last4Changed,
              focusNode: _last4Focus,
              textInputAction: _actionFor(_last4Focus, chain),
              onSubmitted: _submitFor(_last4Focus, chain),
            ),
          ),
        ],
        if (state.showInterestRateField) ...[
          const SizedBox(height: 16),
          KeyedSubtree(
            key: errorScroll.keyFor(AccountDraft.fieldInterestRateBps),
            child: AccountFormField.text(
              label: l10n.accountFormInterestRateLabel,
              hint: l10n.accountFormInterestRateHint,
              initialValue: state.interestRateText,
              errorText:
                  _errorFor(l10n, state, AccountDraft.fieldInterestRateBps),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: cubit.interestRateChanged,
              focusNode: _interestRateFocus,
              textInputAction: _actionFor(_interestRateFocus, chain),
              onSubmitted: _submitFor(_interestRateFocus, chain),
            ),
          ),
        ],
        if (state.isCard) ...[
          const SizedBox(height: 24),
          CardDetailsSection(
            errorScroll: errorScroll,
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
            creditLimitFocusNode: _creditLimitFocus,
            creditLimitTextInputAction: _actionFor(_creditLimitFocus, chain),
            onCreditLimitSubmitted: _submitFor(_creditLimitFocus, chain),
            debtFocusNode: _cardDebtFocus,
            debtTextInputAction: _actionFor(_cardDebtFocus, chain),
            onDebtSubmitted: _submitFor(_cardDebtFocus, chain),
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
    // A selector must not leave a text field focused behind the sheet, or the
    // keyboard springs back the moment the sheet closes.
    final cubit = context.read<AccountFormCubit>();
    await dismissSystemKeyboard(context);
    if (!context.mounted) {
      return;
    }
    final picked = await CurrencyPickerSheet.show(
      context,
      selected: widget.state.currency,
    );
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
    // Same as the currency selector: drop the keyboard before the sheet opens.
    await dismissSystemKeyboard(context);
    if (!context.mounted) {
      return;
    }
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
  const AccountNumberField({
    required this.state,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final AccountFormState state;

  /// Focus wiring so the form can chain the keyboard action into and out of the
  /// number field like any other text input.
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;

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
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
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
    // Empty -> required, over the limit -> too long (validated in that
    // order): an empty field must not show the length copy (fix #15b).
    AccountDraft.fieldName => state.name.trim().isEmpty
        ? l10n.accountErrorNameRequired
        : l10n.accountErrorName,
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

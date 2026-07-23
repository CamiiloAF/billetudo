import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/forms/form_error_scroll_controller.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/account_draft.dart';
import '../cubit/account_form_state.dart';
import 'account_form_field.dart';
import 'account_money_field.dart';

/// The "Datos de la tarjeta" group of the form: credit limit, statement day and
/// payment due day (HU-02).
///
/// Only rendered when the type is `card`; HU-02 makes all three mandatory
/// there, and the draft nulls them out for any other type.
class CardDetailsSection extends StatelessWidget {
  const CardDetailsSection({
    required this.errorScroll,
    required this.currency,
    required this.creditLimitText,
    required this.statementDay,
    required this.paymentDueDay,
    required this.onCreditLimitChanged,
    required this.onStatementDayTap,
    required this.onPaymentDueDayTap,
    this.showDebtField = false,
    this.debtText = '',
    this.debtError,
    this.onDebtChanged,
    this.creditLimitError,
    this.statementDayError,
    this.paymentDueDayError,
    this.creditLimitFocusNode,
    this.creditLimitTextInputAction,
    this.onCreditLimitSubmitted,
    this.debtFocusNode,
    this.debtTextInputAction,
    this.onDebtSubmitted,
    super.key,
  });

  /// Registers each card field so a validation error scrolls it into view.
  final FormErrorScrollController errorScroll;

  /// The selected currency's ISO code, so the limit is grouped as that
  /// currency is typed — COP takes no cents — and re-rendered when the user
  /// switches currency with a figure already typed.
  final String currency;

  final String creditLimitText;

  /// Mejora #1: the "Deuda actual" field, shown only while creating a card.
  /// Bound to the same `initialBalanceText` the cubit negates on save.
  final bool showDebtField;
  final String debtText;
  final String? debtError;
  final ValueChanged<String>? onDebtChanged;

  final int? statementDay;
  final int? paymentDueDay;
  final ValueChanged<String> onCreditLimitChanged;
  final VoidCallback onStatementDayTap;
  final VoidCallback onPaymentDueDayTap;
  final String? creditLimitError;
  final String? statementDayError;
  final String? paymentDueDayError;

  /// Focus wiring for the two money fields, so the form can chain the keyboard
  /// "siguiente"/"listo" action across them like the top-level text fields.
  final FocusNode? creditLimitFocusNode;
  final TextInputAction? creditLimitTextInputAction;
  final VoidCallback? onCreditLimitSubmitted;
  final FocusNode? debtFocusNode;
  final TextInputAction? debtTextInputAction;
  final VoidCallback? onDebtSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountFormCardSectionTitle,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldCreditLimitMinor),
          child: AccountMoneyField(
            label: l10n.accountFormCreditLimitLabel,
            icon: LucideIcons.creditCard,
            hint: l10n.accountFormAmountHint,
            currency: currency,
            text: creditLimitText,
            errorText: creditLimitError,
            focusNode: creditLimitFocusNode,
            textInputAction: creditLimitTextInputAction,
            onSubmitted: onCreditLimitSubmitted,
            onChanged: onCreditLimitChanged,
          ),
        ),
        if (showDebtField && onDebtChanged != null) ...[
          const SizedBox(height: 16),
          KeyedSubtree(
            key: errorScroll.keyFor(AccountFormState.fieldInitialBalance),
            child: AccountMoneyField(
              label: l10n.accountDebtLabel,
              icon: LucideIcons.banknote,
              hint: l10n.accountFormAmountHint,
              currency: currency,
              text: debtText,
              errorText: debtError,
              focusNode: debtFocusNode,
              textInputAction: debtTextInputAction,
              onSubmitted: onDebtSubmitted,
              onChanged: onDebtChanged!,
            ),
          ),
        ],
        const SizedBox(height: 16),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldStatementDay),
          child: AccountFormField.selector(
            label: l10n.accountFormStatementDayLabel,
            icon: LucideIcons.calendar,
            hint: l10n.accountFormSelectHint,
            value: statementDay == null
                ? null
                : l10n.accountDayOfMonthValue(statementDay!),
            errorText: statementDayError,
            onTap: onStatementDayTap,
          ),
        ),
        const SizedBox(height: 16),
        KeyedSubtree(
          key: errorScroll.keyFor(AccountDraft.fieldPaymentDueDay),
          child: AccountFormField.selector(
            label: l10n.accountFormPaymentDueDayLabel,
            icon: LucideIcons.calendarCheck,
            hint: l10n.accountFormSelectHint,
            value: paymentDueDay == null
                ? null
                : l10n.accountDayOfMonthValue(paymentDueDay!),
            errorText: paymentDueDayError,
            onTap: onPaymentDueDayTap,
          ),
        ),
      ],
    );
  }
}

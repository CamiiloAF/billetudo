import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import 'account_form_field.dart';
import 'account_money_field.dart';

/// The "Datos de la tarjeta" group of the form: credit limit, statement day and
/// payment due day (HU-02).
///
/// Only rendered when the type is `card`; HU-02 makes all three mandatory
/// there, and the draft nulls them out for any other type.
class CardDetailsSection extends StatelessWidget {
  const CardDetailsSection({
    required this.currency,
    required this.creditLimitText,
    required this.statementDay,
    required this.paymentDueDay,
    required this.onCreditLimitChanged,
    required this.onStatementDayTap,
    required this.onPaymentDueDayTap,
    this.creditLimitError,
    this.statementDayError,
    this.paymentDueDayError,
    super.key,
  });

  /// The selected currency's ISO code, so the limit is grouped as that
  /// currency is typed — COP takes no cents — and re-rendered when the user
  /// switches currency with a figure already typed.
  final String currency;

  final String creditLimitText;
  final int? statementDay;
  final int? paymentDueDay;
  final ValueChanged<String> onCreditLimitChanged;
  final VoidCallback onStatementDayTap;
  final VoidCallback onPaymentDueDayTap;
  final String? creditLimitError;
  final String? statementDayError;
  final String? paymentDueDayError;

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
        AccountMoneyField(
          label: l10n.accountFormCreditLimitLabel,
          icon: LucideIcons.creditCard,
          hint: l10n.accountFormAmountHint,
          currency: currency,
          text: creditLimitText,
          errorText: creditLimitError,
          onChanged: onCreditLimitChanged,
        ),
        const SizedBox(height: 16),
        AccountFormField.selector(
          label: l10n.accountFormStatementDayLabel,
          icon: LucideIcons.calendar,
          hint: l10n.accountFormSelectHint,
          value: statementDay == null
              ? null
              : l10n.accountDayOfMonthValue(statementDay!),
          errorText: statementDayError,
          onTap: onStatementDayTap,
        ),
        const SizedBox(height: 16),
        AccountFormField.selector(
          label: l10n.accountFormPaymentDueDayLabel,
          icon: LucideIcons.calendarCheck,
          hint: l10n.accountFormSelectHint,
          value: paymentDueDay == null
              ? null
              : l10n.accountDayOfMonthValue(paymentDueDay!),
          errorText: paymentDueDayError,
          onTap: onPaymentDueDayTap,
        ),
      ],
    );
  }
}

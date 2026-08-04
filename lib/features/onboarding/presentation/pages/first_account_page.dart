import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/forms/form_error_scroll_controller.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/domain/entities/account_draft.dart';
import '../../../accounts/presentation/cubit/account_form_cubit.dart';
import '../../../accounts/presentation/cubit/account_form_state.dart';
import '../../../accounts/presentation/widgets/account_form_field.dart';
import '../../../accounts/presentation/widgets/account_money_field.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../../accounts/presentation/widgets/card_details_section.dart';
import '../../../accounts/presentation/widgets/sheets/account_type_picker_sheet.dart';
import '../../../accounts/presentation/widgets/sheets/currency_picker_sheet.dart';
import '../../../accounts/presentation/widgets/sheets/day_picker_sheet.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/onboarding_status_badge.dart';
import '../widgets/onboarding_wallet_fan.dart';

/// HU-02 (`G7vDVK`/`c2wua2`, credit-card variant `O2QbEF`/`yClJt`): "Tu
/// primera cuenta", pre-filled and skippable.
///
/// Reuses [AccountFormCubit] (Cuentas HU-01/HU-02) directly — the router
/// creates and pre-fills the very same cubit `AccountFormPage` uses, through
/// nothing but its already-public setters (`typeSelected`, `nameChanged`,
/// `currencySelected`), so every validation rule (including HU-02's
/// card-fields requirement) runs unmodified. This page only renders a
/// **subset** of that cubit's fields — name, institution (`showInstitutionField`
/// — hidden for cash, same as the full form), type, currency, balance, plus
/// the card section when `type == card` — hiding number/interest rate/icon/
/// colour, per `13-onboarding.md` HU-02's "reutiliza el formulario ...
/// simplificado por defecto".
///
/// **Divergence from `O2QbEF`, documented:** Pencil's card variant shows
/// "Deuda actual" in the top row next to "Moneda". This page instead keeps
/// it inside [CardDetailsSection] (`showDebtField`), exactly where Cuentas'
/// own full form puts it — reusing that section as-is instead of rebuilding
/// its layout was judged the better trade against the alternative of a
/// second, onboarding-only card-fields layout.
class FirstAccountPage extends StatefulWidget {
  const FirstAccountPage({
    required this.onCreated,
    required this.onSkip,
    super.key,
  });

  /// Called once the account is saved (`AccountFormStatus.saved`).
  final VoidCallback onCreated;

  /// "Omitir por ahora": leaves the flow without creating an account.
  final VoidCallback onSkip;

  @override
  State<FirstAccountPage> createState() => _FirstAccountPageState();
}

class _FirstAccountPageState extends State<FirstAccountPage> {
  final FormErrorScrollController _errorScroll = FormErrorScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountFormCubit, AccountFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AccountFormStatus.saved,
      listener: (context, state) => widget.onCreated(),
      child: BlocBuilder<AccountFormCubit, AccountFormState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final cubit = context.read<AccountFormCubit>();
          final colors = context.colors;
          final type = state.type;

          return OnboardingScaffold(
            stepIndex: 1,
            centerContent: false,
            isPrimaryLoading: state.status == AccountFormStatus.saving,
            primaryLabel: l10n.onboardingAccountCta,
            primaryIcon: LucideIcons.check,
            onPrimary: cubit.submit,
            secondaryLabel: l10n.onboardingAccountSkip,
            onSecondary: widget.onSkip,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OnboardingWalletFan(
                  cardCount: 2,
                  badge: OnboardingBadgeKind.plus,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.onboardingAccountHeadline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingAccountSubhead,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                AccountFormField.selector(
                  label: l10n.accountFormTypeLabel,
                  value: type?.label(l10n),
                  hint: l10n.accountFormSelectHint,
                  errorText: _errorFor(l10n, state, AccountFormState.fieldType),
                  onTap: () => _pickType(context),
                ),
                const SizedBox(height: 16),
                AccountFormField.text(
                  label: l10n.accountFormNameLabel,
                  hint: l10n.accountFormNameHint,
                  initialValue: state.name,
                  maxLength: AccountDraft.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  errorText: _errorFor(l10n, state, AccountDraft.fieldName),
                  onChanged: cubit.nameChanged,
                ),
                if (state.showInstitutionField) ...[
                  const SizedBox(height: 16),
                  AccountFormField.text(
                    label: l10n.accountFormInstitutionLabel,
                    icon: LucideIcons.landmark,
                    hint: l10n.accountFormInstitutionHint,
                    initialValue: state.institution,
                    maxLength: AccountDraft.maxInstitutionLength,
                    textCapitalization: TextCapitalization.words,
                    errorText:
                        _errorFor(l10n, state, AccountDraft.fieldInstitution),
                    onChanged: cubit.institutionChanged,
                  ),
                ],
                const SizedBox(height: 16),
                if (type == null || !type.isCard)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AccountFormField.selector(
                          label: l10n.accountFormCurrencyLabel,
                          icon: LucideIcons.coins,
                          value: state.currency,
                          errorText: _errorFor(
                            l10n,
                            state,
                            AccountDraft.fieldCurrency,
                          ),
                          onTap: () => _pickCurrency(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AccountMoneyField(
                          label: l10n.accountFormInitialBalanceLabel,
                          icon: LucideIcons.banknote,
                          currency: state.currency,
                          text: state.initialBalanceText,
                          hint: l10n.accountFormAmountHint,
                          allowNegative: true,
                          errorText: _errorFor(
                            l10n,
                            state,
                            AccountFormState.fieldInitialBalance,
                          ),
                          onChanged: cubit.initialBalanceChanged,
                        ),
                      ),
                    ],
                  )
                else
                  AccountFormField.selector(
                    label: l10n.accountFormCurrencyLabel,
                    icon: LucideIcons.coins,
                    value: state.currency,
                    errorText:
                        _errorFor(l10n, state, AccountDraft.fieldCurrency),
                    onTap: () => _pickCurrency(context),
                  ),
                if (type != null && type.isCard) ...[
                  const SizedBox(height: 20),
                  CardDetailsSection(
                    errorScroll: _errorScroll,
                    currency: state.currency,
                    creditLimitText: state.creditLimitText,
                    creditLimitError: _errorFor(
                      l10n,
                      state,
                      AccountDraft.fieldCreditLimitMinor,
                    ),
                    showDebtField: true,
                    debtText: state.initialBalanceText,
                    debtError: _errorFor(
                      l10n,
                      state,
                      AccountFormState.fieldInitialBalance,
                    ),
                    onDebtChanged: cubit.initialBalanceChanged,
                    statementDay: state.statementDay,
                    paymentDueDay: state.paymentDueDay,
                    statementDayError: _errorFor(
                      l10n,
                      state,
                      AccountDraft.fieldStatementDay,
                    ),
                    paymentDueDayError: _errorFor(
                      l10n,
                      state,
                      AccountDraft.fieldPaymentDueDay,
                    ),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickType(BuildContext context) async {
    final cubit = context.read<AccountFormCubit>();
    final picked = await AccountTypePickerSheet.show(
      context,
      selected: cubit.state.type,
    );
    if (picked != null) {
      cubit.typeSelected(picked);
    }
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final cubit = context.read<AccountFormCubit>();
    final picked = await CurrencyPickerSheet.show(
      context,
      selected: cubit.state.currency,
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
    final picked =
        await DayPickerSheet.show(context, title: title, selected: selected);
    if (picked != null) {
      onPicked(picked);
    }
  }
}

/// Maps the domain's failing field to its localized message — a smaller copy
/// of `account_form_page.dart`'s own `_errorFor`, covering only the fields
/// this simplified form shows.
String? _errorFor(AppLocalizations l10n, AccountFormState state, String field) {
  if (state.failedField != field) {
    return null;
  }
  return switch (field) {
    AccountDraft.fieldName => state.name.trim().isEmpty
        ? l10n.accountErrorNameRequired
        : l10n.accountErrorName,
    AccountDraft.fieldCurrency => l10n.accountErrorCurrency,
    AccountDraft.fieldInstitution => l10n.accountErrorInstitution,
    AccountDraft.fieldCreditLimitMinor => l10n.accountErrorCreditLimit,
    AccountDraft.fieldStatementDay => l10n.accountErrorStatementDay,
    AccountDraft.fieldPaymentDueDay => l10n.accountErrorPaymentDueDay,
    AccountFormState.fieldInitialBalance => l10n.accountErrorInitialBalance,
    AccountFormState.fieldType => l10n.accountErrorType,
    _ => null,
  };
}

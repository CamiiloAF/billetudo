import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';
import '../../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../../../categories/domain/entities/category.dart';
import '../../../../transactions/presentation/widgets/category_picker/category_select_sheet.dart';
import '../../../domain/entities/debt.dart';
import '../../cubit/debt_payment_cubit.dart';
import '../../cubit/debt_payment_state.dart';
import '../../utils/debt_format.dart';
import '../debt_amount_hero_field.dart';
import '../debt_cash_switch.dart';
import '../debt_form_field.dart';
import 'debt_account_picker_sheet.dart';

/// Registrar abono (`xbsY3` Sí / `V6Z9ln` No / `olYUm` link, HU-02): the amount
/// héroe, the "¿Agregar a una cuenta?" switch (revealing the account + category
/// when on, hiding them when off), fecha/nota, and the "Enlaza un movimiento"
/// escape hatch into Movimientos.
class DebtPaymentSheet extends StatelessWidget {
  const DebtPaymentSheet({required this.onLinkExisting, super.key});

  /// Fired after the sheet closes to jump into Movimientos in link mode (the
  /// router wires it). Kept as a callback so the sheet never navigates itself.
  final VoidCallback onLinkExisting;

  /// Opens the sheet for [debt].
  static Future<void> show(
    BuildContext context, {
    required Debt debt,
    required VoidCallback onLinkExisting,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<DebtPaymentCubit>();
            unawaited(cubit.start(debt));
            return cubit;
          },
          child: DebtPaymentSheet(onLinkExisting: onLinkExisting),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtPaymentCubit, DebtPaymentState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DebtPaymentStatus.saved) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state.status == DebtPaymentStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return DebtPaymentSheetBody(
          state: state,
          onLinkExisting: onLinkExisting,
        );
      },
    );
  }
}

class DebtPaymentSheetBody extends StatelessWidget {
  const DebtPaymentSheetBody({
    required this.state,
    required this.onLinkExisting,
    super.key,
  });

  final DebtPaymentState state;
  final VoidCallback onLinkExisting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<DebtPaymentCubit>();
    final debt = state.debt;

    // The submit CTA is pinned as a footer below a scrolling field area, not
    // the last child of one big scroll view: on a phone-sized screen the "Sí"
    // sheet is tall enough that, once the héroe autofocuses the soft keyboard,
    // a bottom-of-scroll CTA slips under the fold and can neither be seen nor
    // tapped without scrolling (the shorter "No"/actualizar-saldo sheets keep
    // it visible, which is why only the cash abono broke). `BottomSheetBase`
    // already lifts the whole sheet by the keyboard inset, so a pinned footer
    // sits right above the keyboard and stays reachable at any sheet height.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header.
                Text(
                  l10n.debtPaymentTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DebtFormat.context(l10n, debt.name, debt.direction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Amount héroe.
                DebtAmountHeroField(
                  fieldKey: const ValueKey('debt-amount-abono'),
                  label: l10n.debtPaymentAmountLabel,
                  currency: debt.currency,
                  initialAmountMinor: state.amountMinor,
                  onChanged: cubit.amountChanged,
                  autofocus: true,
                ),
                // The "Enlaza un movimiento" escape hatch only makes sense when
                // the abono hits an account: linking an existing movement means
                // the money already moved in a cuenta, which contradicts the
                // sin-caja mode (switch off). Frame `olYUm` shows it only with
                // the toggle on; `V6Z9ln` (off) hides it.
                if (state.addToAccount) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: DebtLinkExistingButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        onLinkExisting();
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Switch row.
                DebtAddToAccountRow(state: state, cubit: cubit),
                if (state.addToAccount) ...[
                  const SizedBox(height: 10),
                  DebtSelectedAccountRow(
                    account: state.selectedAccount,
                    onTap: () => unawaited(_pickAccount(context, cubit, state)),
                  ),
                ],
                const SizedBox(height: 16),
                // Fecha.
                DebtFormField.selector(
                  label: l10n.debtPaymentDateLabel,
                  icon: LucideIcons.calendar,
                  value: DebtFormat.relativeDate(context, l10n, state.date),
                  onTap: () => unawaited(
                    _pickDate(context, cubit, state.date, debt.effectiveStartDate),
                  ),
                ),
                const SizedBox(height: 14),
                // Nota.
                DebtFormField.text(
                  key: const ValueKey('abono-note'),
                  label: l10n.debtPaymentNoteLabel,
                  icon: LucideIcons.pencil,
                  hint: l10n.debtPaymentNoteHint,
                  initialValue: state.note,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: cubit.noteChanged,
                ),
                if (state.addToAccount) ...[
                  const SizedBox(height: 14),
                  DebtFormField.selector(
                    label: l10n.debtPaymentCategoryLabel,
                    icon: LucideIcons.tag,
                    value: state.categoryName,
                    hint: l10n.debtPaymentCategoryNone,
                    onTap: () =>
                        unawaited(_pickCategory(context, cubit, state)),
                  ),
                ],
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.debtPaymentError,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.expenseText),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('debt-abono-submit'),
            onPressed: state.canSubmit ? cubit.submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.debtPaymentCta),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAccount(
    BuildContext context,
    DebtPaymentCubit cubit,
    DebtPaymentState state,
  ) async {
    final picked = await DebtAccountPickerSheet.show(
      context,
      accounts: state.accounts,
      selectedId: state.selectedAccountId,
    );
    if (picked != null) {
      cubit.accountSelected(picked);
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    DebtPaymentCubit cubit,
    DateTime current,
    DateTime floorDate,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      // An abono can never predate the debt's start date (HU-02): the loan did
      // not exist before it started.
      disabledBefore: DateUtils.dateOnly(floorDate),
      disabledAfter: DateTime.now(),
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }

  Future<void> _pickCategory(
    BuildContext context,
    DebtPaymentCubit cubit,
    DebtPaymentState state,
  ) async {
    // The abono's category kind follows the debt's direction: paying a debt you
    // owe is an expense (a cuota), collecting one owed to you is an income.
    final kind = state.debt.direction == DebtDirection.iOwe
        ? CategoryKind.expense
        : CategoryKind.income;
    final picked = await CategorySelectSheet.show(
      context,
      kind: kind,
      selectedId: state.categoryId,
    );
    if (picked != null) {
      cubit.categorySelected(id: picked.id, name: picked.name);
    }
  }
}

/// The "¿Agregar a una cuenta?" row: label + consequence hint + the switch.
/// The hint text swaps with the state; both are 13/`$text-secondary`.
class DebtAddToAccountRow extends StatelessWidget {
  const DebtAddToAccountRow(
      {required this.state, required this.cubit, super.key});

  final DebtPaymentState state;
  final DebtPaymentCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.debtPaymentAddToAccountLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                state.addToAccount
                    ? l10n.debtPaymentAddToAccountHintYes
                    : l10n.debtPaymentAddToAccountHintNo,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        DebtCashSwitch(
          value: state.addToAccount,
          onChanged: cubit.addToAccountChanged,
        ),
      ],
    );
  }
}

/// The revealed account row (`X3tZG`): the selected account's avatar, name over
/// type, its balance, and a chevron that opens the picker.
class DebtSelectedAccountRow extends StatelessWidget {
  const DebtSelectedAccountRow({
    required this.account,
    required this.onTap,
    super.key,
  });

  final AccountWithBalance? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final entry = account;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (entry != null) ...[
                  AccountTypeAvatar(type: entry.account.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.account.type.label(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    const MoneyFormatter().formatSymbol(
                      entry.balance.balanceMinor,
                      currencyCode: entry.account.currency,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: entry.balance.balanceMinor < 0
                          ? colors.expenseText
                          : colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else
                  Expanded(
                    child: Text(
                      l10n.debtPaymentSelectAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "¿Ya lo registraste? Enlaza un movimiento" link (`olYUm`): a `link-2`
/// glyph + the prompt in `$primary-on-soft`, jumping into Movimientos link
/// mode to attribute an existing movement instead of creating a new one.
class DebtLinkExistingButton extends StatelessWidget {
  const DebtLinkExistingButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: colors.primaryOnSoft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 40),
      ),
      icon: Icon(LucideIcons.link2, size: 15, color: colors.primaryOnSoft),
      label: Text(
        l10n.debtPaymentLinkExisting,
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.primaryOnSoft,
        ),
      ),
    );
  }
}

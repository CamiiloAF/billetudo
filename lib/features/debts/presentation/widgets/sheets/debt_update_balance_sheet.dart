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
import '../../../domain/entities/debt.dart';
import '../../cubit/debt_update_balance_cubit.dart';
import '../../cubit/debt_update_balance_state.dart';
import '../../utils/debt_format.dart';
import '../debt_amount_hero_field.dart';
import '../debt_form_field.dart';

/// Actualizar saldo (`DEWMf`, HU-06): a "Nuevo saldo" héroe, a reconciliation
/// card (saldo estimado hoy vs. the adjustment that will be recorded), and a
/// `$primary-soft` strip saying it moves no account.
class DebtUpdateBalanceSheet extends StatelessWidget {
  const DebtUpdateBalanceSheet({super.key});

  /// Opens the sheet for [debt] with its current derived [outstandingMinor].
  static Future<void> show(
    BuildContext context, {
    required Debt debt,
    required int outstandingMinor,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider(
          create: (context) => getIt<DebtUpdateBalanceCubit>()
            ..start(debt: debt, currentOutstandingMinor: outstandingMinor),
          child: const DebtUpdateBalanceSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtUpdateBalanceCubit, DebtUpdateBalanceState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DebtUpdateBalanceStatus.saved) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) => DebtUpdateBalanceSheetBody(state: state),
    );
  }
}

class DebtUpdateBalanceSheetBody extends StatelessWidget {
  const DebtUpdateBalanceSheetBody({required this.state, super.key});

  final DebtUpdateBalanceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<DebtUpdateBalanceCubit>();
    final debt = state.debt;

    // The submit CTA is pinned as a footer below a scrolling field area, not
    // the last child of one big scroll view — same reasoning as the abono sheet
    // (`debt_payment_sheet.dart`): on a phone-sized screen the héroe autofocuses
    // the soft keyboard, `BottomSheetBase` lifts the whole sheet by that inset,
    // and a bottom-of-scroll CTA would slip under the fold out of reach. A
    // pinned footer sits right above the keyboard and stays reachable at any
    // sheet height.
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
                Text(
                  l10n.debtUpdateBalanceTitle,
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
                DebtAmountHeroField(
                  fieldKey: const ValueKey('debt-amount-nuevoSaldo'),
                  label: l10n.debtUpdateBalanceNewLabel,
                  currency: debt.currency,
                  initialAmountMinor: state.targetMinor,
                  onChanged: cubit.targetChanged,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DebtReconciliationCard(state: state),
                const SizedBox(height: 16),
                DebtNoAccountStrip(text: l10n.debtUpdateBalanceHint),
                const SizedBox(height: 16),
                DebtFormField.selector(
                  label: l10n.debtUpdateBalanceDateLabel,
                  icon: LucideIcons.calendar,
                  value: DebtFormat.relativeDate(context, l10n, state.date),
                  onTap: () => unawaited(_pickDate(context, cubit, state.date)),
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.debtUpdateBalanceError,
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
            key: const ValueKey('debt-nuevo-saldo-submit'),
            onPressed: state.canSubmit ? cubit.submit : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.debtUpdateBalanceCta),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DebtUpdateBalanceCubit cubit,
    DateTime current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      disabledAfter: DateTime.now(),
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }
}

/// The reconciliation card (`VcDF8`): "Saldo estimado hoy" over "Ajuste que se
/// registra", the adjustment signed but always in a neutral tone.
class DebtReconciliationCard extends StatelessWidget {
  const DebtReconciliationCard({required this.state, super.key});

  final DebtUpdateBalanceState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final currency = state.debt.currency;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.debtUpdateBalanceEstimatedLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                money.formatSymbol(
                  state.currentOutstandingMinor,
                  currencyCode: currency,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.debtUpdateBalanceAdjustLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                _signedAmount(money, state.adjustmentMinor, currency),
                // Neutral, never `$expense` — even the "+$X" grow direction
                // (deudas.md).
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "−$180.000" / "+$180.000" / "$0", with the unicode minus that matches the
  /// mockup (never the thin hyphen next to the `$`).
  static String _signedAmount(
      MoneyFormatter money, int minor, String currency) {
    final magnitude = money.formatSymbol(minor.abs(), currencyCode: currency);
    if (minor > 0) {
      return '+$magnitude';
    }
    if (minor < 0) {
      return '−$magnitude';
    }
    return magnitude;
  }
}

/// The `$primary-soft` strip reassuring that no account moves (`spuO6`).
class DebtNoAccountStrip extends StatelessWidget {
  const DebtNoAccountStrip({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 18, color: colors.primaryOnSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.hintText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

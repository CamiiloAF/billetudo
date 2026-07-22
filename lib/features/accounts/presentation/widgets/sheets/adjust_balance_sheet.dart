import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_balance_adjustment.dart';
import '../../cubit/adjust_balance_cubit.dart';
import '../../cubit/adjust_balance_state.dart';
import '../account_money_field.dart';
import '../balance_adjust_mode_option.dart';

/// "Ajustar saldo" sheet (Mejora #1): reconciles the account balance to a
/// figure the user names, either by registering a movement for the difference
/// or by correcting the opening balance.
///
/// A card names its **debt** here, not its balance; the copy and the sign
/// conversion follow from that (see [AccountBalanceAdjustment]).
class AdjustBalanceSheet extends StatelessWidget {
  const AdjustBalanceSheet({super.key});

  /// Opens the sheet for [account] with its current real [currentBalanceMinor].
  static Future<void> show(
    BuildContext context, {
    required Account account,
    required int currentBalanceMinor,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider(
          create: (context) => getIt<AdjustBalanceCubit>()
            ..start(
              account: account,
              currentBalanceMinor: currentBalanceMinor,
            ),
          child: const AdjustBalanceSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdjustBalanceCubit, AdjustBalanceState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AdjustBalanceStatus.saved) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;
        final cubit = context.read<AdjustBalanceCubit>();
        const money = MoneyFormatter();
        final adjustment = state.adjustment;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountBalanceAdjustTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              (state.isCard
                  ? l10n.accountBalanceAdjustCurrentDebt
                  : l10n.accountBalanceAdjustCurrent)(
                money.formatSymbol(
                  state.displayedCurrentMinor,
                  currencyCode: state.currency,
                ),
              ),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            AccountMoneyField(
              label: state.isCard
                  ? l10n.accountBalanceAdjustNewDebtLabel
                  : l10n.accountBalanceAdjustNewLabel,
              icon: LucideIcons.banknote,
              hint: l10n.accountFormAmountHint,
              currency: state.currency,
              text: state.newBalanceText,
              allowNegative: !state.isCard,
              onChanged: cubit.newBalanceChanged,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.accountBalanceAdjustHowLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            BalanceAdjustModeOption(
              title: l10n.accountBalanceAdjustRegisterTitle,
              body: l10n.accountBalanceAdjustRegisterBody(
                _signedAmount(
                  money,
                  adjustment?.diffMinor ?? 0,
                  state.currency,
                ),
              ),
              selected: state.mode == BalanceAdjustmentMode.registerMovement,
              onTap: () =>
                  cubit.modeSelected(BalanceAdjustmentMode.registerMovement),
            ),
            const SizedBox(height: 12),
            BalanceAdjustModeOption(
              title: l10n.accountBalanceAdjustCorrectTitle,
              body: l10n.accountBalanceAdjustCorrectBody,
              selected: state.mode == BalanceAdjustmentMode.correctInitial,
              onTap: () =>
                  cubit.modeSelected(BalanceAdjustmentMode.correctInitial),
            ),
            if (state.status == AdjustBalanceStatus.failure) ...[
              const SizedBox(height: 12),
              Text(
                l10n.accountBalanceAdjustError,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.expenseText),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.canApply
                    ? () => cubit.apply(note: l10n.accountBalanceAdjustNote)
                    : null,
                icon: const Icon(LucideIcons.check),
                label: Text(l10n.accountBalanceAdjustApplyCta),
              ),
            ),
          ],
        );
      },
    );
  }

  /// A signed money figure: `+$320.000` / `-$120.000`, or `$0` when unchanged.
  String _signedAmount(MoneyFormatter money, int minor, String currency) {
    final formatted =
        money.formatSymbol(minor.abs(), currencyCode: currency);
    if (minor > 0) {
      return '+$formatted';
    }
    if (minor < 0) {
      return '-$formatted';
    }
    return formatted;
  }
}

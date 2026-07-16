import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_with_balance.dart';
import '../cubit/account_detail_cubit.dart';
import '../cubit/account_detail_state.dart';
import '../widgets/account_number_row.dart';
import '../widgets/account_type_avatar.dart';
import '../widgets/accounts_error_view.dart';
import '../widgets/balance_card_hero.dart';
import '../widgets/balance_card_simple.dart';
import '../widgets/info_card.dart';
import '../widgets/info_row.dart';
import '../widgets/sheets/cannot_delete_last_account_sheet.dart';
import '../widgets/sheets/confirm_archive_account_sheet.dart';
import '../widgets/sheets/confirm_delete_account_sheet.dart';

/// Account detail (`ZCSCc`/`G5PvVM`/`qhp7k`).
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    required this.onEdit,
    required this.onAddAccount,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Offered by the "cannot delete the last account" sheet.
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AccountDetailCubit, AccountDetailState>(
      listenWhen: (previous, current) =>
          previous.prompt != current.prompt ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == AccountDetailStatus.closed) {
          Navigator.of(context).pop();
          return;
        }
        unawaited(_handlePrompt(context, state));
      },
      builder: (context, state) {
        final account = state.account;
        return Scaffold(
          appBar: AppBar(
            title: Text(account?.name ?? l10n.accountsTitle),
            actions: [
              if (account != null)
                IconButton(
                  onPressed: () => onEdit(account.id),
                  tooltip: l10n.commonEdit,
                  icon: const Icon(LucideIcons.pencil),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state.status) {
              AccountDetailStatus.loading ||
              AccountDetailStatus.closed =>
                const Center(child: CircularProgressIndicator()),
              AccountDetailStatus.failure => AccountsErrorView(
                  onRetry: () =>
                      context.read<AccountDetailCubit>().start(account!.id),
                ),
              AccountDetailStatus.ready => AccountDetailBody(
                  entry: state.entry!,
                  revealedNumber: state.revealedNumber,
                ),
            },
          ),
        );
      },
    );
  }

  /// Opens the sheet the cubit asked for and reports the answer back to it.
  Future<void> _handlePrompt(
    BuildContext context,
    AccountDetailState state,
  ) async {
    final cubit = context.read<AccountDetailCubit>();
    switch (state.prompt) {
      case AccountDetailPrompt.none:
        return;
      case AccountDetailPrompt.archive:
        final confirmed = await ConfirmArchiveAccountSheet.show(context);
        if (confirmed ?? false) {
          await cubit.confirmArchive();
        } else {
          cubit.dismissPrompt();
        }
      case AccountDetailPrompt.delete:
        final confirmed = await ConfirmDeleteAccountSheet.show(
          context,
          impact: state.impact!,
        );
        if (confirmed ?? false) {
          await cubit.confirmDelete();
        } else {
          cubit.dismissPrompt();
        }
      case AccountDetailPrompt.cannotDelete:
        final create = await CannotDeleteLastAccountSheet.show(context);
        cubit.dismissPrompt();
        if (create ?? false) {
          onAddAccount();
        }
    }
  }
}

/// The detail's content: headline balance, information and the actions anchored
/// at the bottom.
class AccountDetailBody extends StatelessWidget {
  const AccountDetailBody({
    required this.entry,
    required this.revealedNumber,
    super.key,
  });

  final AccountWithBalance entry;
  final String? revealedNumber;

  @override
  Widget build(BuildContext context) {
    final account = entry.account;
    final creditLimitMinor = account.creditLimitMinor;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                if (account.isCard && creditLimitMinor != null)
                  BalanceCardHero(
                    balance: entry.balance,
                    currency: account.currency,
                    creditLimitMinor: creditLimitMinor,
                    view: account.cardBalancePrimary ?? CardBalanceView.debt,
                    onViewChanged:
                        context.read<AccountDetailCubit>().cardViewChanged,
                  )
                else
                  BalanceCardSimple(
                    balanceMinor: entry.balance.balanceMinor,
                    currency: account.currency,
                  ),
                const SizedBox(height: 18),
                AccountInfoSection(
                  account: account,
                  revealedNumber: revealedNumber,
                ),
              ],
            ),
          ),
        ),
        AccountDetailActions(account: account),
      ],
    );
  }
}

/// The information rows of the detail.
class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({
    required this.account,
    required this.revealedNumber,
    super.key,
  });

  final Account account;
  final String? revealedNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AccountDetailCubit>();
    final institution = account.institution;
    final interestRateBps = account.interestRateBps;
    final statementDay = account.statementDay;
    final paymentDueDay = account.paymentDueDay;
    final last4 = account.last4;

    return InfoCard(
      children: [
        if (institution != null)
          InfoRow(label: l10n.accountInfoInstitution, value: institution),
        InfoRow(label: l10n.accountInfoType, value: account.type.label(l10n)),
        if (last4 != null)
          AccountNumberRow(
            last4: last4,
            isCard: account.isCard,
            revealedNumber: revealedNumber,
            onReveal: cubit.revealNumber,
            onHide: cubit.hideNumber,
            onCopy: () => _copy(context),
          ),
        if (statementDay != null)
          InfoRow(
            label: l10n.accountInfoStatementDay,
            value: l10n.accountDayOfMonthValue(statementDay),
          ),
        if (paymentDueDay != null)
          InfoRow(
            label: l10n.accountInfoPaymentDueDay,
            value: l10n.accountDayOfMonthValue(paymentDueDay),
          ),
        if (interestRateBps != null)
          InfoRow(
            label: l10n.accountInfoInterestRate,
            // Basis points are integers all the way: 2450 -> "24,50%".
            value: l10n.accountInterestRateValue(
              const MoneyFormatter().formatAmount(interestRateBps),
            ),
          ),
      ],
    );
  }

  /// Copies through the cubit and confirms it, telling the user the clipboard
  /// clears itself (HU-03).
  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final copied = await context.read<AccountDetailCubit>().copyNumber();
    if (copied) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountNumberCopied)),
      );
    }
  }
}

/// Archive and delete, anchored above the safe area.
class AccountDetailActions extends StatelessWidget {
  const AccountDetailActions({required this.account, super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AccountDetailCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: cubit.promptArchive,
            icon: const Icon(LucideIcons.archive),
            label: Text(l10n.accountArchiveAction),
          ),
          TextButton(
            onPressed: cubit.promptDelete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.accountDeleteAction,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        // `expense-text`, not `expense`: a normal-sized
                        // destructive link needs the calibrated token to clear
                        // 4.5:1 (MASTER.md).
                        color: colors.expenseText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 18, color: colors.expenseText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

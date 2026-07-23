import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/debt.dart';
import '../cubit/debt_detail_cubit.dart';
import '../cubit/debt_detail_state.dart';
import '../widgets/debt_configure_installment_card.dart';
import '../widgets/debt_hero_card.dart';
import '../widgets/debt_installment_card.dart';
import '../widgets/debt_ledger_row.dart';
import '../widgets/debt_ledger_skeleton_row.dart';
import '../widgets/debt_meta_card.dart';
import '../widgets/debt_skeleton_box.dart';
import '../widgets/sheets/debt_account_picker_sheet.dart';
import '../widgets/sheets/debt_payment_sheet.dart';
import '../widgets/sheets/debt_update_balance_sheet.dart';

/// One debt's detail (`cUzp6`/`ZQIPe`/`tVUoU`): hero, meta card, the linked
/// installment (when any), the running-balance ledger, and a fixed "Registrar
/// abono" button. A stacked screen with a `Page Header` and no `Tab Bar`.
///
/// The write flows open from here: the fixed CTA opens the abono sheet, the
/// meta card's "Actualizar saldo" row opens the reconciliation sheet, and the
/// pencil opens the crear/editar form. Navigation intents (edit, the linked
/// cuota, and Movimientos link mode) are delegated to the router; the sheets
/// are shown in place, the same pattern the rest of the app uses.
class DebtDetailPage extends StatelessWidget {
  const DebtDetailPage({
    required this.onEdit,
    required this.onOpenInstallment,
    required this.onConfigureInstallment,
    required this.onLinkExisting,
    required this.onOpenTransaction,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Cross-link into Pagos programados for the linked cuota (HU-03).
  final ValueChanged<String> onOpenInstallment;

  /// Opens a cash ledger row's underlying `Transaction` detail (HU-04). Only
  /// rows with a `transactionId` navigate; solo-deuda rows stay inert.
  final ValueChanged<String> onOpenTransaction;

  /// Opens the Configurar-cuota screen for this debt (HU-03), shown when the
  /// debt has no cuota configured yet. Carries the current outstanding so the
  /// cuota form can cap the cuota amount to it (fix 4a-ii).
  final void Function(Debt debt, int outstandingMinor) onConfigureInstallment;

  /// Jumps into Movimientos link mode to attribute an existing movement to the
  /// debt (HU-02); the router wires the navigation.
  final ValueChanged<Debt> onLinkExisting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DebtDetailCubit, DebtDetailState>(
          builder: (context, state) {
            final detail = state.detail;
            return Column(
              children: [
                PageHeader(
                  title: detail?.debt.name ?? '',
                  trailing: detail == null
                      ? null
                      : PageHeaderCircleButton(
                          icon: LucideIcons.pencil,
                          background: colors.muted,
                          foreground: colors.textPrimary,
                          tooltip: l10n.debtEditTooltip,
                          onPressed: () => onEdit(detail.debt.id),
                        ),
                ),
                Expanded(
                  child: switch (state.status) {
                    DebtDetailStatus.loading => const DebtDetailLoadingView(),
                    DebtDetailStatus.failure => DebtDetailErrorView(
                        onRetry: () => unawaited(
                          context.read<DebtDetailCubit>().retry(),
                        ),
                      ),
                    DebtDetailStatus.ready when detail != null =>
                      DebtDetailReadyView(
                        state: state,
                        onOpenInstallment: onOpenInstallment,
                        onConfigureInstallment: onConfigureInstallment,
                        onLinkExisting: onLinkExisting,
                        onOpenTransaction: onOpenTransaction,
                      ),
                    DebtDetailStatus.ready => const SizedBox.shrink(),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DebtDetailReadyView extends StatelessWidget {
  const DebtDetailReadyView({
    required this.state,
    required this.onOpenInstallment,
    required this.onConfigureInstallment,
    required this.onLinkExisting,
    required this.onOpenTransaction,
    super.key,
  });

  final DebtDetailState state;
  final ValueChanged<String> onOpenInstallment;
  final void Function(Debt debt, int outstandingMinor) onConfigureInstallment;
  final ValueChanged<Debt> onLinkExisting;
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final detail = state.detail!;
    final debt = detail.debt;
    final ledger = detail.ledger;
    final installment = state.installment;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            children: [
              DebtHeroCard(debt: debt, balance: detail.balance),
              const SizedBox(height: 12),
              DebtMetaCard(
                debt: debt,
                dailyGrowthMinor: state.dailyGrowthMinor,
                onUpdateBalance: () => unawaited(
                  DebtUpdateBalanceSheet.show(
                    context,
                    debt: debt,
                    outstandingMinor: detail.balance.outstandingMinor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (installment != null)
                DebtInstallmentCard(
                  installment: installment,
                  onTap: () =>
                      onOpenInstallment(installment.scheduledPaymentId),
                )
              else
                DebtConfigureInstallmentCard(
                  onTap: () => onConfigureInstallment(
                    debt,
                    detail.balance.outstandingMinor,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                l10n.debtDetailMovementsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < ledger.length; index++) ...[
                if (index > 0) const SizedBox(height: 4),
                DebtLedgerRow(
                  entry: ledger[index],
                  direction: debt.direction,
                  runningMinor: index < state.runningBalances.length
                      ? state.runningBalances[index]
                      : 0,
                  currency: debt.currency,
                  onOpenTransaction: onOpenTransaction,
                  initialTransactionId: debt.initialTransactionId,
                  onLinkOpening: () => _showOpeningLinkSnackbar(context),
                ),
              ],
            ],
          ),
        ),
        DebtDetailBottomBar(
          onRegisterPayment: () => unawaited(
            DebtPaymentSheet.show(
              context,
              debt: debt,
              onLinkExisting: () => onLinkExisting(debt),
            ),
          ),
        ),
      ],
    );
  }

  /// Item 2 (retro-link): the synthetic opening row was tapped. It looks like a
  /// dead row today, so we explain it and offer to link an account. Neutral
  /// snackbar (no guilt): "Saldo inicial · sin cuenta enlazada" + "Enlazar".
  void _showOpeningLinkSnackbar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.debtOpeningLinkSnackbar),
          action: SnackBarAction(
            label: l10n.debtOpeningLinkAction,
            onPressed: () => unawaited(_pickAccountForOpening(context)),
          ),
        ),
      );
  }

  Future<void> _pickAccountForOpening(BuildContext context) async {
    final cubit = context.read<DebtDetailCubit>();
    final accounts = cubit.state.accounts;
    final accountId = await DebtAccountPickerSheet.show(
      context,
      accounts: accounts,
      selectedId: accounts.isEmpty ? null : accounts.first.account.id,
    );
    if (accountId == null || !context.mounted) {
      return;
    }
    final linked = await cubit.attributeOpeningToAccount(accountId);
    if (!linked && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).debtLinkError)),
        );
    }
  }
}

/// The fixed "Registrar abono" button at the thumb zone (`wubqC`).
class DebtDetailBottomBar extends StatelessWidget {
  const DebtDetailBottomBar({required this.onRegisterPayment, super.key});

  final VoidCallback onRegisterPayment;

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
        onPressed: onRegisterPayment,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(l10n.debtDetailRegisterPayment),
      ),
    );
  }
}

class DebtDetailErrorView extends StatelessWidget {
  const DebtDetailErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: AppLocalizations.of(context).debtDetailErrorTitle,
      onRetry: onRetry,
    );
  }
}

/// Loading: skeletons for the hero, meta card, cuota card, the ledger rows and
/// the CTA (`ZQIPe`).
class DebtDetailLoadingView extends StatelessWidget {
  const DebtDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.all(18),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DebtSkeletonBox(width: 70, height: 20, radius: 8),
                        DebtSkeletonBox(width: 40, height: 18, radius: 8),
                      ],
                    ),
                    SizedBox(height: 14),
                    DebtSkeletonBox(width: 130, height: 13),
                    SizedBox(height: 8),
                    DebtSkeletonBox(width: 180, height: 28),
                    SizedBox(height: 14),
                    DebtSkeletonBox(height: 14, radius: 7),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final width in const [130.0, 160.0, 150.0]) ...[
                      Row(
                        children: [
                          const DebtSkeletonBox(width: 18, height: 18),
                          const SizedBox(width: 10),
                          DebtSkeletonBox(width: width, height: 12),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(height: 1, color: colors.border),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        DebtSkeletonBox(width: 18, height: 18),
                        SizedBox(width: 10),
                        DebtSkeletonBox(width: 120, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Cuota card placeholder (`jsdH9`): icon wrap, a name/amount top
              // row over a meta + badge sub row, and a chevron.
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: const Row(
                  children: [
                    DebtSkeletonBox(width: 40, height: 40, radius: 12),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DebtSkeletonBox(width: 120, height: 14),
                              DebtSkeletonBox(width: 90, height: 14),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              DebtSkeletonBox(width: 50, height: 11),
                              SizedBox(width: 6),
                              DebtSkeletonBox(width: 80, height: 16, radius: 6),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    DebtSkeletonBox(width: 16, height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const DebtSkeletonBox(width: 90, height: 14),
              const SizedBox(height: 8),
              for (final row in const [
                [130.0, 90.0, 80.0, 60.0],
                [150.0, 100.0, 70.0, 56.0],
                [110.0, 80.0, 90.0, 66.0],
                [140.0, 85.0, 78.0, 58.0],
              ])
                DebtLedgerSkeletonRow(
                  nameWidth: row[0],
                  metaWidth: row[1],
                  amountWidth: row[2],
                  runningWidth: row[3],
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: const DebtSkeletonBox(height: 49, radius: 16),
        ),
      ],
    );
  }
}

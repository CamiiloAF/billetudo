import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../cubit/cashflow_cubit.dart';
import '../../cubit/cashflow_state.dart';
import '../../cubit/reports_shell_cubit.dart';
import '../../cubit/reports_shell_state.dart';
import '../../models/reports_period_selection.dart';
import '../../utils/reports_period_format.dart';
import '../account_filter_row.dart';
import '../chart_period_row.dart';
import '../sheets/period_selector_sheet.dart';
import '../states/chart_sync_notice_strip.dart';
import 'cashflow_card_content.dart';
import 'cashflow_debt_toggle.dart';

/// HU-01: the Flujo de caja tab. Orchestrates [CashflowCubit] against the
/// shared period/toggle held by [ReportsShellCubit].
class CashflowTabView extends StatefulWidget {
  const CashflowTabView({
    required this.onAddMovement,
    required this.onViewCategories,
    required this.onOpenSyncStatus,
    this.cardBoundaryKey,
    super.key,
  });

  final VoidCallback onAddMovement;
  final VoidCallback onViewCategories;
  final VoidCallback onOpenSyncStatus;

  /// See `ReportCard.boundaryKey` — forwarded to the tab's own card so
  /// `ChartExport` can capture just it.
  final GlobalKey? cardBoundaryKey;

  @override
  State<CashflowTabView> createState() => _CashflowTabViewState();
}

class _CashflowTabViewState extends State<CashflowTabView> {
  @override
  void initState() {
    super.initState();
    _load(context.read<ReportsShellCubit>().state);
  }

  void _load(ReportsShellState shell) {
    unawaited(
      context.read<CashflowCubit>().load(
        range: shell.period.range,
        includeDebtMovements: shell.includeDebtMovements,
        accountIds: shell.accountIds,
      ),
    );
  }

  Future<void> _openPeriodSelector(ReportsPeriodSelection current) async {
    final selection = await PeriodSelectorSheet.show(context, initial: current);
    if (selection != null && mounted) {
      context.read<ReportsShellCubit>().updatePeriod(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    return BlocListener<ReportsShellCubit, ReportsShellState>(
      listenWhen: (previous, current) =>
          previous.period != current.period ||
          previous.includeDebtMovements != current.includeDebtMovements ||
          previous.accountIds != current.accountIds,
      listener: (context, shell) => _load(shell),
      child: BlocBuilder<ReportsShellCubit, ReportsShellState>(
        builder: (context, shell) {
          return BlocBuilder<CashflowCubit, CashflowState>(
            builder: (context, state) {
              final series = state.series;
              // HU-06 "Flujo — vacío" (`NPXSP`): no `Report Card` chrome and
              // no "Separar movimientos de deuda" toggle below it — see
              // `CashflowCardContent`'s empty branch for the card side.
              final isEmptyState = series != null && series.isEmpty;
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChartPeriodRow(
                      selectorLabel: ReportsPeriodFormat.selectorLabel(
                        l10n,
                        shell.period,
                        locale,
                      ),
                      rangeCaption: series != null && series.bounds.isClamped
                          ? ReportsPeriodFormat.historyCaption(l10n, series.bounds)
                          : ReportsPeriodFormat.rangeCaption(
                              shell.period.range,
                              locale,
                            ),
                      onTapSelector: () => _openPeriodSelector(shell.period),
                    ),
                    const SizedBox(height: 8),
                    AccountFilterRow(
                      selected: shell.accountIds,
                      onChanged: (accountIds) => context
                          .read<ReportsShellCubit>()
                          .updateAccountFilter(accountIds),
                    ),
                    const SizedBox(height: 8),
                    if (shell.hasSyncNotice) ...[
                      ChartSyncNoticeStrip(onTap: widget.onOpenSyncStatus),
                      const SizedBox(height: 8),
                    ],
                    CashflowCardContent(
                      state: state,
                      shell: shell,
                      onAddMovement: widget.onAddMovement,
                      onViewCategories: widget.onViewCategories,
                      boundaryKey: widget.cardBoundaryKey,
                    ),
                    if (!isEmptyState) ...[
                      const SizedBox(height: 8),
                      CashflowDebtToggle(
                        includeDebtMovements: shell.includeDebtMovements,
                        onChanged: (value) => context
                            .read<ReportsShellCubit>()
                            .toggleDebtMovements(value: value),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

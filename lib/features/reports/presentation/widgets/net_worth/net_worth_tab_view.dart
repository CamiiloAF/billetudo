import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../cubit/net_worth_cubit.dart';
import '../../cubit/net_worth_state.dart';
import '../../cubit/reports_shell_cubit.dart';
import '../../cubit/reports_shell_state.dart';
import '../../models/reports_period_selection.dart';
import '../../utils/reports_period_format.dart';
import '../chart_period_row.dart';
import '../sheets/period_selector_sheet.dart';
import '../states/chart_sync_notice_strip.dart';
import 'net_worth_archived_toggle.dart';
import 'net_worth_card_content.dart';
import 'net_worth_interest_note.dart';

/// HU-02: the Patrimonio tab.
class NetWorthTabView extends StatefulWidget {
  const NetWorthTabView({
    required this.onAddMovement,
    required this.onOpenSyncStatus,
    this.cardBoundaryKey,
    super.key,
  });

  final VoidCallback onAddMovement;
  final VoidCallback onOpenSyncStatus;

  /// See `ReportCard.boundaryKey`.
  final GlobalKey? cardBoundaryKey;

  @override
  State<NetWorthTabView> createState() => _NetWorthTabViewState();
}

class _NetWorthTabViewState extends State<NetWorthTabView> {
  @override
  void initState() {
    super.initState();
    _load(context.read<ReportsShellCubit>().state);
  }

  void _load(ReportsShellState shell) {
    unawaited(
      context.read<NetWorthCubit>().load(
        range: shell.period.range,
        includeArchivedAccounts: shell.includeArchivedAccounts,
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
          previous.includeArchivedAccounts != current.includeArchivedAccounts,
      listener: (context, shell) => _load(shell),
      child: BlocBuilder<ReportsShellCubit, ReportsShellState>(
        builder: (context, shell) {
          return BlocBuilder<NetWorthCubit, NetWorthState>(
            builder: (context, state) {
              final series = state.series;
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
                    if (shell.hasSyncNotice) ...[
                      ChartSyncNoticeStrip(onTap: widget.onOpenSyncStatus),
                      const SizedBox(height: 8),
                    ],
                    NetWorthCardContent(
                      state: state,
                      onAddMovement: widget.onAddMovement,
                      boundaryKey: widget.cardBoundaryKey,
                    ),
                    const SizedBox(height: 8),
                    const NetWorthInterestNote(),
                    const SizedBox(height: 8),
                    NetWorthArchivedToggle(
                      includeArchivedAccounts: shell.includeArchivedAccounts,
                      onChanged: (value) => context
                          .read<ReportsShellCubit>()
                          .toggleArchivedAccounts(value),
                    ),
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

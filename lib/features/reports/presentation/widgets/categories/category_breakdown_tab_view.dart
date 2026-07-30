import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../cubit/category_breakdown_cubit.dart';
import '../../cubit/category_breakdown_state.dart';
import '../../cubit/reports_shell_cubit.dart';
import '../../cubit/reports_shell_state.dart';
import '../../models/reports_period_selection.dart';
import '../../utils/reports_period_format.dart';
import '../chart_period_row.dart';
import '../sheets/period_selector_sheet.dart';
import '../states/chart_sync_notice_strip.dart';
import 'category_breakdown_card_content.dart';

/// HU-03: the Categorías tab.
class CategoryBreakdownTabView extends StatefulWidget {
  const CategoryBreakdownTabView({
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
  State<CategoryBreakdownTabView> createState() =>
      _CategoryBreakdownTabViewState();
}

class _CategoryBreakdownTabViewState extends State<CategoryBreakdownTabView> {
  @override
  void initState() {
    super.initState();
    _load(context.read<ReportsShellCubit>().state);
  }

  void _load(ReportsShellState shell) {
    unawaited(
      context.read<CategoryBreakdownCubit>().load(range: shell.period.range),
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
      listenWhen: (previous, current) => previous.period != current.period,
      listener: (context, shell) => _load(shell),
      child: BlocBuilder<ReportsShellCubit, ReportsShellState>(
        builder: (context, shell) {
          return BlocBuilder<CategoryBreakdownCubit, CategoryBreakdownState>(
            builder: (context, state) {
              final rangeCaption =
                  ReportsPeriodFormat.rangeCaption(shell.period.range, locale);
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
                      rangeCaption: rangeCaption,
                      onTapSelector: () => _openPeriodSelector(shell.period),
                    ),
                    const SizedBox(height: 8),
                    if (shell.hasSyncNotice) ...[
                      ChartSyncNoticeStrip(onTap: widget.onOpenSyncStatus),
                      const SizedBox(height: 8),
                    ],
                    CategoryBreakdownCardContent(
                      state: state,
                      rangeCaption: rangeCaption,
                      onAddMovement: widget.onAddMovement,
                      // TODO(graficas): wire once "Ver subcategorías" has a
                      // destination — not designed yet (pendiente 3,
                      // design-system/billetudo/pages/graficas.md). Leaving
                      // onViewSubcategories unset renders the link inert.
                      boundaryKey: widget.cardBoundaryKey,
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

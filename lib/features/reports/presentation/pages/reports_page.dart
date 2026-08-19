import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../../accounts/presentation/utils/show_account_gate_if_needed.dart';
import '../../../accounts/presentation/widgets/account_gate_copy.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../goals/domain/entities/goal_with_progress.dart';
import '../../domain/entities/chart_view.dart';
import '../../domain/entities/date_range.dart';
import '../cubit/reports_shell_cubit.dart';
import '../cubit/reports_shell_state.dart';
import '../utils/chart_export.dart';
import '../widgets/cashflow/cashflow_tab_view.dart';
import '../widgets/categories/category_breakdown_tab_view.dart';
import '../widgets/chart_tabs.dart';
import '../widgets/dashboard/reports_dashboard_tab_view.dart';
import '../widgets/net_worth/net_worth_tab_view.dart';

/// The Gráficas e informes shell (HU-01 to HU-06): `Status Bar` + `Page
/// Header` + `Chart Tabs` stay **outside** every tab's own scrollable (D1,
/// `design-system/billetudo/pages/graficas.md`) — only the active tab body
/// scrolls.
class ReportsPage extends StatefulWidget {
  const ReportsPage({
    required this.onAddMovement,
    required this.onOpenSyncStatus,
    required this.onOpenBudget,
    required this.onCreateBudget,
    required this.onOpenGoal,
    required this.onCreateGoal,
    required this.onOpenDebts,
    this.onOpenCategoryMovements,
    super.key,
  });

  final VoidCallback onAddMovement;
  final VoidCallback onOpenSyncStatus;
  final ValueChanged<BudgetWithProgress> onOpenBudget;
  final VoidCallback onCreateBudget;
  final ValueChanged<GoalWithProgress> onOpenGoal;
  final VoidCallback onCreateGoal;
  final VoidCallback onOpenDebts;

  /// Navigates to Movimientos filtered by a tapped category row, the active
  /// Gráficas period and the active cuentas filter, from the Categorías tab.
  final void Function(String categoryId, DateRange range, Set<String> accountIds)?
      onOpenCategoryMovements;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _cashflowCardKey = GlobalKey();
  final _netWorthCardKey = GlobalKey();
  final _categoriesCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ReportsShellCubit>().start());
  }

  /// `15-gate-cuenta.md` HU-04: the dashboard's "Crear presupuesto" CTA
  /// pushes the same `/presupuestos/nuevo` route as the Presupuestos tab's
  /// own "+" — without any active account it must open the bridge sheet
  /// here too, instead of letting the route push happen first and flash an
  /// empty screen behind it while `AccountGatedRoute` resolves the same
  /// check. Mirrors `BudgetsPage._addBudget`.
  Future<void> _createBudget(BuildContext context) async {
    final canProceed = await showAccountGateIfNeeded(
      context,
      AccountGateSurface.budget,
    );
    if (canProceed && context.mounted) {
      widget.onCreateBudget();
    }
  }

  Future<void> _export(ChartViewId activeTab) async {
    final key = switch (activeTab) {
      ChartViewId.cashflow => _cashflowCardKey,
      ChartViewId.netWorth => _netWorthCardKey,
      ChartViewId.categoryBreakdown => _categoriesCardKey,
      ChartViewId.dashboard => null,
    };
    if (key == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tabLabel = switch (activeTab) {
      ChartViewId.dashboard => l10n.reportsTabSummary,
      ChartViewId.cashflow => l10n.reportsTabCashflow,
      ChartViewId.netWorth => l10n.reportsTabNetWorth,
      ChartViewId.categoryBreakdown => l10n.reportsTabCategories,
    };
    final ok = await getIt<ChartExport>().exportAndShare(
      boundaryKey: key,
      fileName: 'billetudo-grafica-${activeTab.name}.png',
      shareText: l10n.reportsExportShareText(tabLabel),
    );
    if (!ok && mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(AppSnackBar(content: Text(l10n.reportsExportError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ReportsShellCubit, ReportsShellState>(
          builder: (context, shell) {
            return Column(
              children: [
                PageHeader(
                  title: l10n.moreReports,
                  trailing: shell.activeTab == ChartViewId.dashboard
                      ? null
                      : PageHeaderCircleButton(
                          icon: LucideIcons.imageDown,
                          background: colors.muted,
                          foreground: colors.primaryOnSoftStrong,
                          tooltip: l10n.reportsExportTooltip,
                          onPressed: () => _export(shell.activeTab),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ChartTabs(
                    active: shell.activeTab,
                    onSelected: (tab) =>
                        context.read<ReportsShellCubit>().selectTab(tab),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: switch (shell.activeTab) {
                      ChartViewId.dashboard => ReportsDashboardTabView(
                          onTapBudget: widget.onOpenBudget,
                          onCreateBudget: () =>
                              unawaited(_createBudget(context)),
                          onTapGoal: widget.onOpenGoal,
                          onCreateGoal: widget.onCreateGoal,
                          onOpenDebts: widget.onOpenDebts,
                        ),
                      ChartViewId.cashflow => CashflowTabView(
                          onAddMovement: widget.onAddMovement,
                          onViewCategories: () => context
                              .read<ReportsShellCubit>()
                              .selectTab(ChartViewId.categoryBreakdown),
                          onOpenSyncStatus: widget.onOpenSyncStatus,
                          cardBoundaryKey: _cashflowCardKey,
                        ),
                      ChartViewId.netWorth => NetWorthTabView(
                          onAddMovement: widget.onAddMovement,
                          onOpenSyncStatus: widget.onOpenSyncStatus,
                          cardBoundaryKey: _netWorthCardKey,
                        ),
                      ChartViewId.categoryBreakdown => CategoryBreakdownTabView(
                          onAddMovement: widget.onAddMovement,
                          onOpenSyncStatus: widget.onOpenSyncStatus,
                          onOpenCategoryMovements:
                              widget.onOpenCategoryMovements,
                          cardBoundaryKey: _categoriesCardKey,
                        ),
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

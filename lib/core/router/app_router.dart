import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/domain/entities/account.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/accounts/presentation/cubit/account_detail_cubit.dart';
import '../../features/accounts/presentation/cubit/account_form_cubit.dart';
import '../../features/accounts/presentation/cubit/accounts_list_cubit.dart';
import '../../features/accounts/presentation/cubit/archived_accounts_cubit.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/account_form_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/archived_accounts_page.dart';
import '../../features/accounts/presentation/widgets/account_gate_copy.dart';
import '../../features/accounts/presentation/widgets/account_gated_route.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/entities/delete_account_scope.dart';
import '../../features/auth/domain/entities/sign_out_outcome.dart';
import '../../features/auth/domain/usecases/sign_out_with_local_data_choice.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/merge_cubit.dart';
import '../../features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import '../../features/auth/presentation/pages/account_deleted_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/merge_confirmation_page.dart';
import '../../features/auth/presentation/widgets/delete_account_flow.dart';
import '../../features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
import '../../features/budgets/presentation/cubit/archived_budgets_cubit.dart';
import '../../features/budgets/presentation/cubit/budget_detail_cubit.dart';
import '../../features/budgets/presentation/cubit/budget_form_cubit.dart';
import '../../features/budgets/presentation/cubit/budgets_list_cubit.dart';
import '../../features/budgets/presentation/cubit/zero_based_summary_cubit.dart';
import '../../features/budgets/presentation/pages/archived_budgets_page.dart';
import '../../features/budgets/presentation/pages/budget_detail_page.dart';
import '../../features/budgets/presentation/pages/budget_form_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/categories/domain/entities/category.dart';
import '../../features/categories/presentation/cubit/categories_list_cubit.dart';
import '../../features/categories/presentation/cubit/category_form_cubit.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_form_page.dart';
import '../../features/debts/domain/entities/debt.dart';
import '../../features/debts/presentation/cubit/debt_detail_cubit.dart';
import '../../features/debts/presentation/cubit/debt_form_cubit.dart';
import '../../features/debts/presentation/cubit/debt_link_cubit.dart';
import '../../features/debts/presentation/cubit/debts_list_cubit.dart';
import '../../features/debts/presentation/pages/debt_detail_page.dart';
import '../../features/debts/presentation/pages/debt_form_page.dart';
import '../../features/debts/presentation/pages/debt_link_mode_page.dart';
import '../../features/debts/presentation/pages/debts_list_page.dart';
import '../../features/goals/domain/entities/goal_contribution.dart';
import '../../features/goals/domain/entities/goal_with_progress.dart';
import '../../features/goals/domain/services/goal_starter_templates.dart';
import '../../features/goals/domain/usecases/archive_goal.dart';
import '../../features/goals/presentation/cubit/archived_goals_cubit.dart';
import '../../features/goals/presentation/cubit/goal_detail_cubit.dart';
import '../../features/goals/presentation/cubit/goal_form_cubit.dart';
import '../../features/goals/presentation/cubit/goal_link_cubit.dart';
import '../../features/goals/presentation/cubit/goals_list_cubit.dart';
import '../../features/goals/presentation/pages/archived_goals_page.dart';
import '../../features/goals/presentation/pages/goal_completed_celebration_page.dart';
import '../../features/goals/presentation/pages/goal_detail_page.dart';
import '../../features/goals/presentation/pages/goal_form_page.dart';
import '../../features/goals/presentation/pages/goal_link_mode_page.dart';
import '../../features/goals/presentation/pages/goals_list_page.dart';
import '../../features/goals/presentation/widgets/goal_milestone_sheet.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/home/presentation/pages/more_page.dart';
import '../../features/import_export/presentation/cubit/export_cubit.dart';
import '../../features/import_export/presentation/cubit/import_batches_cubit.dart';
import '../../features/import_export/presentation/cubit/import_export_hub_cubit.dart';
import '../../features/import_export/presentation/cubit/import_flow_cubit.dart';
import '../../features/import_export/presentation/pages/export_page.dart';
import '../../features/import_export/presentation/pages/import_batches_page.dart';
import '../../features/import_export/presentation/pages/import_export_hub_page.dart';
import '../../features/import_export/presentation/pages/import_flow_page.dart';
import '../../features/import_export/presentation/widgets/sheets/import_pick_sheet.dart';
import '../../features/import_export/presentation/widgets/sheets/restore_sheet.dart';
import '../../features/import_export/presentation/widgets/sheets/save_copy_sheet.dart';
import '../../features/onboarding/domain/entities/onboarding_progress.dart';
import '../../features/onboarding/domain/entities/onboarding_step.dart';
import '../../features/onboarding/domain/usecases/resolve_default_currency_for_locale.dart';
import '../../features/onboarding/presentation/cubit/onboarding_flow_cubit.dart';
import '../../features/onboarding/presentation/pages/backup_intro_page.dart';
import '../../features/onboarding/presentation/pages/closing_page.dart';
import '../../features/onboarding/presentation/pages/first_account_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/reports/domain/entities/chart_view.dart';
import '../../features/reports/presentation/cubit/cashflow_cubit.dart';
import '../../features/reports/presentation/cubit/category_breakdown_cubit.dart';
import '../../features/reports/presentation/cubit/net_worth_cubit.dart';
import '../../features/reports/presentation/cubit/reports_dashboard_cubit.dart';
import '../../features/reports/presentation/cubit/reports_shell_cubit.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import '../../features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import '../../features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import '../../features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart';
import '../../features/scheduled_payments/presentation/pages/pending_occurrences_page.dart';
import '../../features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart';
import '../../features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart';
import '../../features/scheduled_payments/presentation/pages/scheduled_payments_page.dart';
import '../../features/settings/presentation/cubit/app_settings_cubit.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/domain/usecases/has_any_transaction.dart';
import '../../features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import '../../features/transactions/presentation/cubit/transaction_form_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_list_cubit.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../di/injection.dart';
import '../error/result.dart';
import '../l10n/gen/app_localizations.dart';
import '../preferences/balance_carousel_cubit.dart';
import '../sync/presentation/cubit/sync_status_cubit.dart';
import '../sync/presentation/pages/pending_sync_changes_page.dart';
import '../sync/presentation/pages/sync_status_page.dart';
import '../widgets/coming_soon_page.dart';

/// App routes. Each feature registers its own here. Paths stay in Spanish
/// because they are user-visible URLs.
///
/// The app is a five-tab shell (Inicio, Movimientos, Presupuestos, Pagos
/// programados, Más).
/// List/hub pages live inside their tab branch (the tab bar stays visible);
/// stacked forms and detail pages render on the root navigator, above the tab
/// bar (MASTER: a `Page Header` and the `Tab Bar` are mutually exclusive).
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String onboarding = '/bienvenida';
  static const String onboardingAccount = '/bienvenida/cuenta';
  static const String onboardingBackup = '/bienvenida/respaldo';
  static const String onboardingClosing = '/bienvenida/cierre';
  static const String onboardingLogin = '/bienvenida/iniciar-sesion';
  static const String onboardingMergeConfirmation =
      '/bienvenida/iniciar-sesion/fusion';
  static const String budgets = '/presupuestos';
  static const String newBudget = '/presupuestos/nuevo';
  static const String budgetsHistory = '/presupuestos/historico';
  static const String goals = '/metas';
  static const String newGoal = '/metas/nueva';
  static const String archivedGoals = '/metas/archivadas';
  static const String more = '/mas';
  static const String comingSoon = '/mas/proximamente';
  static const String accounts = '/cuentas';
  static const String newAccount = '/cuentas/nueva';
  static const String archivedAccounts = '/cuentas/archivadas';
  static const String categories = '/categorias';
  static const String transactions = '/movimientos';
  static const String newTransaction = '/movimientos/nuevo';
  static const String settings = '/mas/ajustes';
  static const String login = '/mas/ajustes/respaldar';
  static const String syncStatus = '/mas/ajustes/sincronizacion';
  static const String pendingSyncChanges =
      '/mas/ajustes/sincronizacion/cambios';
  static const String mergeConfirmation = '/mas/ajustes/respaldar/fusion';
  static const String accountDeleted = '/mas/cuenta-eliminada';
  static const String debts = '/deudas';
  static const String newDebt = '/deudas/nueva';
  static const String scheduledPayments = '/pagos-programados';
  static const String newScheduledPayment = '/pagos-programados/nuevo';
  static const String reports = '/graficas';
  static const String pendingScheduledPayments =
      '/pagos-programados/por-confirmar';
  static const String importExport = '/mas/importar-exportar';
  static const String exportCsv = '$importExport/exportar';
  static const String importCsv = '$importExport/importar';
  static const String importBatches = '$importExport/importaciones';

  /// The new-movement form preselecting [accountId] — used when the movements
  /// list is filtered down to a single account (HU-06a). The form still lets
  /// the user change it.
  static String newTransactionForAccount(String accountId) =>
      '$newTransaction?accountId=${Uri.encodeQueryComponent(accountId)}';

  /// The onboarding login screen (HU-06 from Bienvenida, HU-07 "Activar
  /// respaldo" from Respalda tus datos) — same route, same reused
  /// [LoginPage], but [closesFlow] decides what a successful sign-in does
  /// next: HU-06 closes the whole flow, HU-07 continues to Cierre.
  static String onboardingLoginFrom({required bool closesFlow}) =>
      '$onboardingLogin?closesFlow=$closesFlow';

  /// The onboarding merge-confirmation screen, carrying the same
  /// [closesFlow] flag through from [onboardingLoginFrom].
  static String onboardingMergeConfirmationFrom({required bool closesFlow}) =>
      '$onboardingMergeConfirmation?closesFlow=$closesFlow';

  /// A stacked "Próximamente" page titled with a destination's name.
  static String comingSoonTitled(String title) =>
      '$comingSoon?title=${Uri.encodeQueryComponent(title)}';

  /// Detail of one budget: `/presupuestos/<id>`.
  static String budget(String id) => '$budgets/$id';

  /// Edit form of one budget: `/presupuestos/<id>/editar`.
  static String editBudget(String id) => '$budgets/$id/editar';

  /// Detail of one goal: `/metas/<id>`.
  static String goal(String id) => '$goals/$id';

  /// Edit form of one goal: `/metas/<id>/editar`.
  static String editGoal(String id) => '$goals/$id/editar';

  /// Detail of one debt: `/deudas/<id>`.
  static String debt(String id) => '$debts/$id';

  /// Edit form of one debt: `/deudas/<id>/editar`.
  static String editDebt(String id) => '$debts/$id/editar';

  /// Configurar cuota of one debt (HU-03): `/deudas/<id>/cuota`, optionally
  /// editing the existing linked template via `?spId=`. Reuses the Pagos
  /// Programados form in cuota mode; the debt context rides in `extra` as a
  /// [DebtInstallmentContext].
  static String debtInstallment(String debtId, {String? spId}) {
    final base = '$debts/$debtId/cuota';
    return spId == null ? base : '$base?spId=${Uri.encodeQueryComponent(spId)}';
  }

  /// Movimientos in Deudas link mode: `/movimientos/enlazar-deuda/<debtId>`
  /// (HU-02). The `Debt` itself rides in the route's `extra` for the banner.
  static String linkTransactionToDebt(String debtId) =>
      '$transactions/enlazar-deuda/$debtId';

  /// Movimientos in Metas link mode: `/movimientos/enlazar-meta/<goalId>`
  /// (HU-03 "Enlazar un movimiento"). The [GoalLinkContext] rides in the
  /// route's `extra` for the banner and the movement direction.
  static String linkTransactionToGoal(String goalId) =>
      '$transactions/enlazar-meta/$goalId';

  /// Detail of one account: `/cuentas/<id>`.
  static String account(String id) => '$accounts/$id';

  /// Edit form of one account: `/cuentas/<id>/editar`.
  static String editAccount(String id) => '$accounts/$id/editar';

  /// New root category, optionally starting on `kind`'s Tipo segment.
  static String newCategory({CategoryKind kind = CategoryKind.expense}) =>
      '$categories/nueva?kind=${kind.name}';

  /// Edit form of one category (root or sub): `/categorias/<id>/editar`.
  static String editCategory(String id) => '$categories/$id/editar';

  /// New subcategory of the root category [parentId].
  static String newSubcategory(String parentId) =>
      '$categories/$parentId/subcategoria-nueva';

  /// Detail of one transaction: `/movimientos/<id>`.
  static String transaction(String id) => '$transactions/$id';

  /// Edit form of one transaction: `/movimientos/<id>/editar`.
  static String editTransaction(String id) => '$transactions/$id/editar';

  /// Detail of one scheduled payment template: `/pagos-programados/<id>`.
  static String scheduledPayment(String id) => '$scheduledPayments/$id';

  /// Edit form of one template: `/pagos-programados/<id>/editar`.
  static String editScheduledPayment(String id) =>
      '$scheduledPayments/$id/editar';

  /// HU-06/criterion 14: the puente from a future-dated new transaction to a
  /// brand-new `once` template, prefilled via query params — the router is
  /// the only layer allowed to translate a `TransactionFormState` into
  /// this, so neither feature's domain depends on the other.
  static String newScheduledPaymentFromTransaction({
    required String accountId,
    required String accountName,
    required int amountMinor,
    required String currency,
    required String type,
    required DateTime nextDate,
    String? categoryId,
    String? categoryKind,
    String? categoryName,
    String? note,
    List<String> tagIds = const <String>[],
  }) {
    final params = <String, String>{
      'accountId': accountId,
      'accountName': accountName,
      'amountMinor': amountMinor.toString(),
      'currency': currency,
      'type': type,
      'nextDate': nextDate.toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryKind != null) 'categoryKind': categoryKind,
      if (categoryName != null) 'categoryName': categoryName,
      if (note != null && note.isNotEmpty) 'note': note,
      if (tagIds.isNotEmpty) 'tagIds': tagIds.join(','),
    };
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    return '$newScheduledPayment?$query';
  }
}

/// The debt context the Configurar-cuota route needs (HU-03), passed as
/// `extra`. Built by whichever screen launches the flow — the debt detail
/// (from its `Debt`) or the Pagos Programados detail (from its
/// `ScheduledPaymentLinkedDebt`) — so the reused Pagos Programados form gets
/// the debt's name and direction without this feature's domains depending on
/// each other. The router is the only layer that assembles it.
class DebtInstallmentContext {
  const DebtInstallmentContext({
    required this.debtId,
    required this.debtName,
    required this.iOwe,
    this.debtCreatedAt,
    this.debtOutstandingMinor,
    this.debtDueDate,
  });

  final String debtId;
  final String debtName;

  /// `DebtDirection.iOwe` → the cuota is an expense; `owedToMe` → income.
  final bool iOwe;

  /// The debt's creation date, when the flow starts from the debt detail
  /// (Deudas fix 4a-i): the cuota's first payment cannot be dated before it.
  /// Null on the secondary entry (editing from a Pago Programado detail), where
  /// the derived outstanding is not cheaply available — the bounds are simply
  /// not enforced there.
  final DateTime? debtCreatedAt;

  /// The debt's current derived outstanding balance (Deudas fix 4a-ii): the
  /// cuota amount cannot exceed it. Null on the secondary entry (see above).
  final int? debtOutstandingMinor;

  /// The debt's due date, when the flow starts from the debt detail: the
  /// cuota form prefills "fecha en que termina" with it for a brand-new
  /// cuota. Null when the debt has no due date, or on the secondary entry
  /// (editing from a Pago Programado detail).
  final DateTime? debtDueDate;
}

/// The goal context the Enlazar-un-movimiento route needs (HU-03), passed as
/// `extra`. Built by `GoalContributionSheet` (from the goal it is open on)
/// so the reused Movimientos list gets the goal's name and the movement
/// direction it was open on, without either feature's domain depending on
/// the other. The router is the only layer that assembles it.
class GoalLinkContext {
  const GoalLinkContext({
    required this.goalId,
    required this.goalName,
    required this.direction,
  });

  final String goalId;
  final String goalName;
  final GoalMovementDirection direction;
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// The Movimientos tab's index in the shell's `branches` list below — the
/// bottom tab bar's `onSelectBranch` hook uses it to clear a stale "volver a
/// Gráficas" flag when the user reaches Movimientos this way.
const int _movimientosBranchIndex = 1;

/// Builds the app [GoRouter]. Instantiated once during bootstrap.
///
/// [initialLocation] defaults to [AppRoutes.home] — `bootstrap.dart` passes
/// [AppRoutes.onboarding] instead when `ShouldShowOnboarding` (evaluated
/// exactly once, before this router exists) says the welcome flow has not
/// run yet (`13-onboarding.md`, "El gate se evalúa una sola vez por
/// arranque, tras el bootstrap"). This is a one-shot decision, not a
/// reactive `redirect`: nothing here re-checks the latch on every
/// navigation, so a remote change to `onboardingCompleted` arriving mid-
/// session (it syncs) never yanks the user out of the screen they are on.
GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShellPage(
          navigationShell: navigationShell,
          // Tapping the Movimientos tab directly (not through Gráficas'
          // categories drill-down) clears a stale "volver a Gráficas" flag
          // left over from an earlier visit — see `_movimientosBranch` and
          // `_reportsRoute`'s `onOpenCategoryMovements`.
          onSelectBranch: (index) {
            if (index == _movimientosBranchIndex) {
              getIt<TransactionsListCubit>().clearArrivedFromReports();
            }
          },
          // System back from Movimientos' root, when it was reached through
          // Gráficas' categories drill-down, must return to Gráficas instead
          // of falling through to `HomeShellPage`'s default "jump to
          // Inicio" — see `HomeShellPage.onInterceptBranchBack`'s doc for why
          // `TransactionsPage`'s own `PopScope` can never catch this itself.
          // Mirrors `_movimientosBranch`'s `onBackToReports` exactly.
          onInterceptBranchBack: (index) {
            if (index != _movimientosBranchIndex) {
              return null;
            }
            final cubit = getIt<TransactionsListCubit>();
            if (!cubit.state.arrivedFromReports) {
              return null;
            }
            return () {
              cubit.clearArrivedFromReports();
              context.go(
                AppRoutes.reports,
                extra: ChartViewId.categoryBreakdown,
              );
            };
          },
        ),
        branches: [
          _inicioBranch(),
          _movimientosBranch(), // index 1 — see `_movimientosBranchIndex`.
          _presupuestosBranch(),
          _metasBranch(),
          _masBranch(),
        ],
      ),
      // Reachable from both the "Más" hub and Inicio's quick-access row, but
      // deliberately outside every StatefulShellBranch: a top-level branch
      // route can only use its own branch's navigator (go_router asserts
      // `parentNavigatorKey == null || parentNavigatorKey == branch.navigatorKey`
      // for the *first-level* routes of a branch — unlike routes nested a
      // level deeper, e.g. Ajustes under `more`, see `_settingsRoute()`).
      // Declaring these as siblings of the shell route itself is the
      // documented go_router pattern for screens that must render without the
      // tab bar regardless of which tab launched them. Pagos Programados is
      // here (not a tab anymore): Metas recovered its slot, so Pagos
      // Programados is reached from Inicio's quick access and the "Más" hub
      // as a stacked screen.
      _accountsRoute(),
      _categoriesRoute(),
      _pagosProgramadosRoute(),
      _debtsRoute(),
      _debtLinkModeRoute(),
      _goalLinkModeRoute(),
      _importExportRoute(),
      _reportsRoute(),
      // The welcome flow (`13-onboarding.md`): a sibling of the shell route,
      // same reasoning as the routes above — it must render without the tab
      // bar, and unlike them it is also the *only* screen reachable while
      // active (nothing links to the shell routes until the flow closes and
      // pushes/goes to `AppRoutes.home` itself).
      _onboardingRoute(),
    ],
  );
}

StatefulShellBranch _inicioBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(getIt<HomeCubit>(), (c) => c.start()),
            child: HomePage(
              onAddTransaction: () => context.push(AppRoutes.newTransaction),
              // Reached through the ordinary path, not Gráficas' drill-down:
              // clears a stale "volver a Gráficas" flag left over from an
              // earlier visit (see `_movimientosBranch`/`_reportsRoute`).
              onSeeAllTransactions: () {
                getIt<TransactionsListCubit>().clearArrivedFromReports();
                context.go(AppRoutes.transactions);
              },
              onOpenTransaction: (id) =>
                  context.push<String>(AppRoutes.transaction(id)),
              onCreateBudget: () => context.go(AppRoutes.budgets),
              // Criterion 6: tapping the hero with a featured budget opens
              // that budget's own detail — same destination as Gráficas'
              // `onOpenBudget`.
              onOpenBudget: (id) => context.push(AppRoutes.budget(id)),
              onOpenAccounts: () => context.push(AppRoutes.accounts),
              // Bugfix item 8: tapping an account's mini-card pins the
              // Movimientos account filter (HU-06a) to just that account —
              // reusing the list cubit's own `updateFilter`, which persists it
              // — then switches to the Movimientos tab so it arrives filtered.
              // `TransactionsListCubit` is a lazySingleton, so this reaches the
              // same live instance the tab holds, whether or not it was opened
              // yet this session. Also clears a stale "volver a Gráficas" flag
              // (see `onSeeAllTransactions` above).
              onOpenAccountMovements: (accountId) {
                final cubit = getIt<TransactionsListCubit>();
                cubit.clearArrivedFromReports();
                unawaited(cubit.filterByAccount(accountId));
                context.go(AppRoutes.transactions);
              },
              // Pagos Programados is no longer a tab: stack it on the root
              // navigator.
              onOpenScheduledPayments: () =>
                  context.push(AppRoutes.scheduledPayments),
              onOpenDebts: () => context.push(AppRoutes.debts),
              // Inicio's quick-access chip is a "start fresh" entry point:
              // reset the shared shell before pushing, so a stale
              // period/cuentas selection from an earlier visit never shows
              // up here — `ReportsShellCubit`'s class doc.
              onOpenReports: () {
                getIt<ReportsShellCubit>().resetToDefault();
                unawaited(context.push(AppRoutes.reports));
              },
              // Bugfix item 6: offline with no session → back up / sign in.
              onOpenLogin: () => context.push(AppRoutes.login),
              onOpenSyncStatus: () => context.push(AppRoutes.syncStatus),
              // NOTE(gate-cuenta run): `HomePage` on disk no longer declares
              // `onOpenBudget` — this callsite was left dangling by something
              // outside this task's scope (a build break present before any
              // of this run's edits, see the run's closing notes). Dropped
              // here only to keep the tree compiling; the "home-hero-period-
              // stepper" item 7 feature itself needs a real look, not a
              // silent re-add.
            ),
          ),
        ),
      ],
    );

StatefulShellBranch _movimientosBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.transactions,
          builder: (context, state) {
            final listCubit =
                _started(getIt<TransactionsListCubit>(), (c) => c.start());
            final carouselCubit =
                _started(getIt<BalanceCarouselCubit>(), (c) => c.load());
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: listCubit),
                BlocProvider.value(value: carouselCubit),
              ],
              child: TransactionsPage(
                onAddTransaction: (accountId) => context.push(
                  accountId == null
                      ? AppRoutes.newTransaction
                      : AppRoutes.newTransactionForAccount(accountId),
                ),
                onOpenTransaction: (id) =>
                    context.push<String>(AppRoutes.transaction(id)),
                onOpenAccount: (id) => context.push(AppRoutes.account(id)),
                // Wired unconditionally: `TransactionsPage` only shows this
                // as the header's leading button while
                // `TransactionsListState.arrivedFromReports` is true. This
                // `GoRoute`'s `builder` is not guaranteed to re-run on every
                // navigation here — `StatefulShellRoute.indexedStack` skips
                // rebuilding an already-visited branch's Navigator when the
                // new and previous `RouteMatchList`s compare equal, and that
                // comparison never looks at `GoRouterState.extra` — so a
                // constructor-time null/non-null decision (the previous
                // approach, keyed off `state.extra`) would go stale after
                // the branch's first visit. The cubit's own state does not
                // have that problem: Gráficas' drill-down
                // (`_reportsRoute`/`onOpenCategoryMovements`) flags the live
                // `TransactionsListCubit` singleton directly before
                // navigating, so `BlocConsumer` picks it up on rebuild
                // regardless of whether this `builder` itself re-runs.
                onBackToReports: () {
                  getIt<TransactionsListCubit>().clearArrivedFromReports();
                  // Passes which tab to reopen: `_reportsRoute`'s `GoRoute`
                  // (unlike this branch's) *does* re-run its `builder` on
                  // every visit, so reading `state.extra` there is safe and
                  // restores "Categorías" instead of resetting to Resumen.
                  // Every other entry point into `/graficas` (the "Más" hub,
                  // Inicio's chip) omits `extra`, so they keep resetting to
                  // Resumen as before.
                  context.go(
                    AppRoutes.reports,
                    extra: ChartViewId.categoryBreakdown,
                  );
                },
              ),
            );
          },
          routes: [
            // Declared before ':id' so "nuevo" is never read as an id.
            GoRoute(
              path: 'nuevo',
              parentNavigatorKey: _rootNavigatorKey,
              // HU-04 of `15-gate-cuenta.md`: a direct/deep-linked visit gets
              // the same bridge a FAB tap gets instead of an unusable form.
              builder: (context, state) => AccountGatedRoute(
                surface: AccountGateSurface.movement,
                builder: (context) => BlocProvider(
                  create: (context) => _started(
                    getIt<TransactionFormCubit>(),
                    (c) => c.load(
                      null,
                      type: _typeFromQuery(state.uri),
                      accountId: state.uri.queryParameters['accountId'],
                    ),
                  ),
                  child: TransactionFormPage(
                    // pushReplacement, not push: the transaction form must leave
                    // the stack as the scheduled-payment form opens, so popping
                    // the PP form (after saving it) returns to the movements
                    // list — the origin — instead of reappearing on the
                    // now-abandoned transaction form (bugfix item 2-iii).
                    onConvertToScheduledPayment: (formState) =>
                        context.pushReplacement(
                      AppRoutes.newScheduledPaymentFromTransaction(
                        accountId: formState.accountId ?? '',
                        accountName: formState.accountName ?? '',
                        amountMinor: formState.amountMinor,
                        currency: formState.currency,
                        type: formState.type.name,
                        nextDate: formState.date,
                        categoryId: formState.categoryId,
                        categoryKind: formState.categoryKind?.name,
                        categoryName: formState.categoryName,
                        note: formState.note,
                        tagIds: formState.tagIds.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<TransactionDetailCubit>(),
                  (c) => c.start(state.pathParameters['id']!),
                ),
                child: TransactionDetailPage(
                  onEdit: (id) => context.push(AppRoutes.editTransaction(id)),
                  onOpenDebt: (id) => context.push(AppRoutes.debt(id)),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'editar',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => BlocProvider(
                    create: (context) => _started(
                      getIt<TransactionFormCubit>(),
                      (c) => c.load(state.pathParameters['id']),
                    ),
                    child: const TransactionFormPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

StatefulShellBranch _presupuestosBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.budgets,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    _started(getIt<BudgetsListCubit>(), (c) => c.start()),
              ),
              BlocProvider(
                create: (context) =>
                    _started(getIt<AppSettingsCubit>(), (c) => c.start()),
              ),
              BlocProvider(
                create: (context) => _started(
                  getIt<ZeroBasedSummaryCubit>(),
                  (c) => c.start(),
                ),
              ),
            ],
            child: BudgetsPage(
              onAddBudget: () => context.push(AppRoutes.newBudget),
              onOpenBudget: (id) => context.push(AppRoutes.budget(id)),
              onOpenHistory: () => context.push(AppRoutes.budgetsHistory),
            ),
          ),
          routes: [
            // Declared before ':id' so "nuevo"/"historico" are never read as ids.
            GoRoute(
              path: 'nuevo',
              parentNavigatorKey: _rootNavigatorKey,
              // 15-gate-cuenta.md: toda la creación de presupuestos exige
              // cuenta, incluido el alcance "Todo" (decisión de producto
              // revertida 2026-08-06) — cubre el FAB y cualquier deep link.
              builder: (context, state) => AccountGatedRoute(
                surface: AccountGateSurface.budget,
                builder: (context) => BlocProvider(
                  create: (context) => _started(
                    getIt<BudgetFormCubit>(),
                    (c) => c.load(null),
                  ),
                  child: const BudgetFormPage(),
                ),
              ),
            ),
            GoRoute(
              path: 'historico',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    _started(getIt<ArchivedBudgetsCubit>(), (c) => c.start()),
                child: const ArchivedBudgetsPage(),
              ),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => _started(
                      getIt<BudgetDetailCubit>(),
                      (c) => c.start(state.pathParameters['id']!),
                    ),
                  ),
                  // Pushed via `parentNavigatorKey` onto the root navigator,
                  // so it does not inherit the branch root's own
                  // `AppSettingsCubit` (`_presupuestosBranch`) — the "Destacar
                  // en Inicio" action needs its own instance to read/write
                  // `featuredBudgetId`.
                  BlocProvider(
                    create: (context) =>
                        _started(getIt<AppSettingsCubit>(), (c) => c.start()),
                  ),
                ],
                child: BudgetDetailPage(
                  onEdit: (id) => context.push(AppRoutes.editBudget(id)),
                  onClosed: () => context.pop(),
                  onOpenTransaction: (id) =>
                      context.push<String>(AppRoutes.transaction(id)),
                  onOpenScheduledPayment: (id) =>
                      context.push(AppRoutes.scheduledPayment(id)),
                  // Pagos Programados is no longer a tab root: stack it.
                  onSeeAllScheduled: () =>
                      context.push(AppRoutes.scheduledPayments),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'editar',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => BlocProvider(
                    create: (context) => _started(
                      getIt<BudgetFormCubit>(),
                      (c) => c.load(state.pathParameters['id']),
                    ),
                    child: const BudgetFormPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

// Metas (HU-11/12/13): a bottom-nav tab again (it recovered its slot from
// Pagos Programados). The list is the branch root, so it renders inside the
// shell with the `Tab Bar` and — crucially — **without** `parentNavigatorKey`
// (a branch-root route can only use its own branch's navigator; go_router
// asserts this at construction time). Its stacked children ("archivadas",
// "nueva", ":id" and their sub-forms) keep `parentNavigatorKey:
// _rootNavigatorKey` so they still push above the tab bar on the root
// navigator — same pattern as Movimientos/Presupuestos.
StatefulShellBranch _metasBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.goals,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<GoalsListCubit>(), (c) => c.start()),
            child: GoalsListPage(
              onAddGoal: ([template]) =>
                  context.push(AppRoutes.newGoal, extra: template),
              onOpenGoal: (id) => context.push(AppRoutes.goal(id)),
              onOpenArchived: () => context.push(AppRoutes.archivedGoals),
            ),
          ),
          routes: [
            GoRoute(
              path: 'archivadas',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    _started(getIt<ArchivedGoalsCubit>(), (c) => c.start()),
                child: ArchivedGoalsPage(
                  onOpenGoal: (id) => context.push(AppRoutes.goal(id)),
                ),
              ),
            ),
            // Declared before ':id' so "nueva" is never read as an id.
            GoRoute(
              path: 'nueva',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<GoalFormCubit>(),
                  (c) => c.load(
                    null,
                    template: state.extra as GoalStarterTemplate?,
                  ),
                ),
                child: const GoalFormPage(),
              ),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<GoalDetailCubit>(),
                  (c) => c.start(state.pathParameters['id']!),
                ),
                child: GoalDetailPage(
                  onEdit: (id) async {
                    final deleted =
                        await context.push<bool>(AppRoutes.editGoal(id));
                    if ((deleted ?? false) && context.mounted) {
                      context.pop();
                    }
                  },
                  onOpenCompletedCelebration: (progress) => unawaited(
                    _openGoalCompletedCelebration(context, progress),
                  ),
                  onOpenMilestone: (goalName, milestonePct) => unawaited(
                    GoalMilestoneSheet.show(
                      context,
                      goalName: goalName,
                      milestonePct: milestonePct,
                    ),
                  ),
                  onOpenTransaction: (id) =>
                      context.push<String>(AppRoutes.transaction(id)),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'editar',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => BlocProvider(
                    create: (context) => _started(
                      getIt<GoalFormCubit>(),
                      (c) => c.load(state.pathParameters['id']),
                    ),
                    child: const GoalFormPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// HU-07: the 100% full-screen celebration, pushed on top of the detail once
/// a contribution crosses the last milestone. "Crear la próxima meta" opens
/// the form; "Archivar meta" archives this one — both pop back to the detail,
/// which then reflects the fresh state on its own via its stream.
Future<void> _openGoalCompletedCelebration(
  BuildContext context,
  GoalWithProgress progress,
) async {
  final goal = progress.goal;
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (context) => GoalCompletedCelebrationPage(
        goalName: goal.name,
        savedMinor: progress.savedMinor,
        currency: goal.currency,
        onCreateNext: () {
          Navigator.of(context).pop();
          unawaited(context.push(AppRoutes.newGoal));
        },
        onArchive: () async {
          await getIt<ArchiveGoal>()(goal.id);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    ),
  );
}

StatefulShellBranch _masBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.more,
          builder: (context, state) => BlocProvider.value(
            value: _started(getIt<AuthCubit>(), (c) async => c.start()),
            child: BlocBuilder<AuthCubit, AuthSession>(
              builder: (context, session) => MorePage(
                onOpenAccounts: () => context.push(AppRoutes.accounts),
                onOpenCategories: () => context.push(AppRoutes.categories),
                onOpenDebts: () => context.push(AppRoutes.debts),
                // Pagos Programados is no longer a tab: stack it.
                onOpenScheduledPayments: () =>
                    context.push(AppRoutes.scheduledPayments),
                // Metas is a tab root now: switch to its branch.
                onOpenGoals: () => context.go(AppRoutes.goals),
                onOpenImportExport: () => context.push(AppRoutes.importExport),
                // The "Más" hub is a "start fresh" entry point too — see the
                // matching comment on Inicio's chip above.
                onOpenReports: () {
                  getIt<ReportsShellCubit>().resetToDefault();
                  unawaited(context.push(AppRoutes.reports));
                },
                onOpenComingSoon: (title) =>
                    context.push(AppRoutes.comingSoonTitled(title)),
                onOpenSettings: () => context.push(AppRoutes.settings),
                isSignedIn: session.isSignedIn,
                onSignOut: () => _confirmSignOut(context),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'proximamente',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => ComingSoonPage(
                title: state.uri.queryParameters['title'] ??
                    AppLocalizations.of(context).moreTitle,
              ),
            ),
            GoRoute(
              path: 'cuenta-eliminada',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => AccountDeletedPage(
                // Defaults to `cloudAndLocal` (the truthful "cloud + local"
                // copy) if this route is somehow reached without `extra` —
                // `DeleteAccountFlow.start` always pushes it below.
                scope: state.extra is DeleteAccountScope
                    ? state.extra! as DeleteAccountScope
                    : DeleteAccountScope.cloudAndLocal,
                onGoHome: () => context.go(AppRoutes.home),
              ),
            ),
            _settingsRoute(),
          ],
        ),
      ],
    );

/// HU-06: shows the sheet and turns the outcome into UI. The ordering rule
/// (sign out first, wipe second) and the "wipe failed but the session is gone"
/// case live in [SignOutWithLocalDataChoice], where they can be tested.
Future<void> _confirmSignOut(BuildContext context) async {
  final cubit = getIt<SignOutSheetCubit>();
  unawaited(cubit.start());

  final choice = await ConfirmSignOutSheet.show(context, cubit);
  await cubit.close();
  if (choice == null) {
    return; // cancelled
  }

  final outcome = await getIt<SignOutWithLocalDataChoice>()(choice);
  if (!context.mounted) {
    return;
  }
  switch (outcome) {
    case SignedOutKeepingData():
    case SignedOutAndWiped():
      break;
    case SignedOutButWipeFailed():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).authSignOutWipeErrorMessage),
        ),
      );
    case SignOutFailed():
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).authSignOutFailedMessage),
        ),
      );
  }
}

// Nested under `more` (not a branch-root route): Ajustes has a `Page Header`
// and no `Tab Bar` (MASTER: the two are mutually exclusive), so it — and
// everything reached from it — renders on the root navigator, stacked above
// the tab shell instead of as one more tab-branch destination.
GoRoute _settingsRoute() => GoRoute(
      path: 'ajustes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<AuthCubit>()),
          BlocProvider(
            create: (context) =>
                _started(getIt<AppSettingsCubit>(), (c) => c.start()),
          ),
          // Feeds the "Estado de sincronización" row its own sublabel — the
          // last successful sync, which HU-08 wants visible before the user
          // even opens the screen.
          BlocProvider(
            create: (context) =>
                _started(getIt<SyncStatusCubit>(), (c) => c.start()),
          ),
        ],
        child: SettingsPage(
          onOpenLogin: () => context.push(AppRoutes.login),
          onOpenDeleteAccount: () => DeleteAccountFlow.start(
            context,
            onFinished: (scope) =>
                context.push(AppRoutes.accountDeleted, extra: scope),
          ),
          onOpenComingSoon: (title) =>
              context.push(AppRoutes.comingSoonTitled(title)),
          onOpenSyncStatus: () => context.push(AppRoutes.syncStatus),
        ),
      ),
      routes: [
        _syncStatusRoute(),
        GoRoute(
          path: 'respaldar',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => getIt<LoginCubit>(),
            child: LoginPage(
              onSignedIn: () => context.push(AppRoutes.mergeConfirmation),
              onSkip: () => context.pop(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'fusion',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    _started(getIt<MergeCubit>(), (c) => c.start()),
                child: MergeConfirmationPage(
                  onDone: () => context.go(AppRoutes.home),
                ),
              ),
            ),
          ],
        ),
      ],
    );

// "Estado de sincronización" (HU-08) and its full pending list. Both are
// stacked pages with a `Page Header`, so they live on the root navigator.
//
// Each route builds its own `SyncStatusCubit`: they are separate entries of the
// root navigator, so neither can inherit the other's provider, and the cubit
// only reads local streams.
//
// `isSignedIn` is resolved here, in the composition root, and handed down —
// `core/sync` must not depend on the auth feature to know whether there is a
// session.
GoRoute _syncStatusRoute() => GoRoute(
      path: 'sincronizacion',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<AuthCubit>()),
          BlocProvider(
            create: (context) =>
                _started(getIt<SyncStatusCubit>(), (c) => c.start()),
          ),
        ],
        child: BlocBuilder<AuthCubit, AuthSession>(
          builder: (context, session) => SyncStatusPage(
            isSignedIn: session.isSignedIn,
            onSignIn: () => context.push(AppRoutes.login),
            onSeeAllPending: () => context.push(AppRoutes.pendingSyncChanges),
            // The local copy is Importar y exportar's flow, never a sheet of
            // its own: two surfaces for the same thing would eventually drift
            // apart on the very wording (copy vs. backup) this screen cannot
            // afford to blur.
            onSaveCopy: () => context.push(AppRoutes.importExport),
            onOpenComingSoon: (title) =>
                context.push(AppRoutes.comingSoonTitled(title)),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'cambios',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<SyncStatusCubit>(), (c) => c.start()),
            child: const PendingSyncChangesPage(),
          ),
        ),
      ],
    );

GoRoute _accountsRoute() => GoRoute(
      path: AppRoutes.accounts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider(
        create: (context) =>
            _started(getIt<AccountsListCubit>(), (c) => c.start()),
        child: AccountsPage(
          onAddAccount: () => context.push(AppRoutes.newAccount),
          onOpenAccount: (id) => context.push(AppRoutes.account(id)),
          onOpenArchived: () => context.push(AppRoutes.archivedAccounts),
        ),
      ),
      routes: [
        GoRoute(
          path: 'nueva',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<AccountFormCubit>(), (c) => c.load(null)),
            child: const AccountFormPage(),
          ),
        ),
        GoRoute(
          path: 'archivadas',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<ArchivedAccountsCubit>(), (c) => c.start()),
            child: const ArchivedAccountsPage(),
          ),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(
              getIt<AccountDetailCubit>(),
              (c) => c.start(state.pathParameters['id']!),
            ),
            child: AccountDetailPage(
              onEdit: (id) => context.push(AppRoutes.editAccount(id)),
              onAddAccount: () => context.push(AppRoutes.newAccount),
            ),
          ),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<AccountFormCubit>(),
                  (c) => c.load(state.pathParameters['id']),
                ),
                child: const AccountFormPage(),
              ),
            ),
          ],
        ),
      ],
    );

// Gráficas e informes (HU-01 to HU-06, Nivel 0): reached from the "Más" hub
// row and Inicio's quick-access chip, rendered as a stacked screen — a `Page
// Header` (no `Tab Bar`) hosting `ReportsPage`'s own 4-tab shell. One
// `ReportsShellCubit` plus the 4 per-tab cubits, all provided once for the
// life of the page so switching tabs never re-fetches (the shared period).
GoRoute _reportsRoute() => GoRoute(
      path: AppRoutes.reports,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        // Only Movimientos' "volver a Gráficas" flow passes `extra` (see
        // `_movimientosBranch`'s `onBackToReports`) — every other entry
        // point (the "Más" hub, Inicio's chip) leaves it null, so this
        // `builder` re-running on every visit only restores the tab for
        // that one flow, never changing the default-to-Resumen behaviour
        // elsewhere.
        final initialTab =
            state.extra is ChartViewId ? state.extra as ChartViewId : null;
        // `BlocProvider.value` (not `create:`): `ReportsShellCubit` is
        // `@lazySingleton` — `create:` would make `BlocProvider` call
        // `.close()` on it when this widget is disposed (e.g. navigating to
        // Movimientos), leaving `GetIt` holding a closed instance that
        // throws `StateError` on the next `emit` when Gráficas is revisited
        // (Sentry BILLETUDO-B). `.value` leaves its lifecycle to `GetIt`,
        // which is the whole point of it being a singleton.
        final shellCubit = getIt<ReportsShellCubit>();
        if (initialTab != null) {
          shellCubit.selectTab(initialTab);
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: shellCubit),
            BlocProvider(create: (context) => getIt<CashflowCubit>()),
            BlocProvider(create: (context) => getIt<NetWorthCubit>()),
            BlocProvider(create: (context) => getIt<CategoryBreakdownCubit>()),
            BlocProvider(create: (context) => getIt<ReportsDashboardCubit>()),
          ],
          child: ReportsPage(
            onAddMovement: () => context.push(AppRoutes.newTransaction),
            onOpenSyncStatus: () => context.push(AppRoutes.syncStatus),
            onOpenBudget: (entry) =>
                context.push(AppRoutes.budget(entry.budget.id)),
            onCreateBudget: () => context.push(AppRoutes.newBudget),
            onOpenGoal: (entry) => context.push(AppRoutes.goal(entry.goal.id)),
            onCreateGoal: () => context.push(AppRoutes.newGoal),
            onOpenDebts: () => context.push(AppRoutes.debts),
            // Categorías drill-down: tapping a `CategoryBreakdownRow` filters
            // Movimientos by that category id, the date range active in
            // Gráficas at the moment of the tap — `DateRange.endExclusive` is
            // half-open, so it maps to `DatePeriodFilter.custom`'s inclusive
            // `endInclusive` by stepping back one day — and Gráficas' own
            // cuentas filter (criterion 7; inclusive-empty, so "todas"
            // applies no account restriction downstream, criterion 8).
            onOpenCategoryMovements: (categoryId, range, accountIds) {
              final transactionsCubit = getIt<TransactionsListCubit>();
              unawaited(
                transactionsCubit.filterByCategoryAndRange(
                  categoryId: categoryId,
                  start: range.start,
                  endInclusive:
                      range.endExclusive.subtract(const Duration(days: 1)),
                  accountIds: accountIds,
                ),
              );
              // Flags the live `TransactionsListCubit` singleton itself,
              // rather than passing `extra` on the `go` below, so Movimientos'
              // "volver a Gráficas" button shows up even when its `GoRoute`
              // `builder` does not re-run for this navigation — see the
              // comment on `onBackToReports` in `_movimientosBranch`.
              transactionsCubit.markArrivedFromReports();
              context.go(AppRoutes.transactions);
            },
          ),
        );
      },
    );

// Deudas (HU-04, Nivel 0): reached from Inicio's quick-access "Deudas" chip and
// rendered as a stacked screen on the root navigator — a `Page Header` with a
// back button, no `Tab Bar`. The read screens (list + detail) plus the write
// flows (crear/editar, abono, actualizar saldo) live here; configurar cuota is
// a later phase.
GoRoute _debtsRoute() => GoRoute(
      path: AppRoutes.debts,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider(
        create: (context) =>
            _started(getIt<DebtsListCubit>(), (c) => c.start()),
        child: DebtsListPage(
          onAddDebt: () => context.push(AppRoutes.newDebt),
          onOpenDebt: (id) => context.push(AppRoutes.debt(id)),
        ),
      ),
      routes: [
        // Declared before ':id' so "nueva" is never read as an id.
        GoRoute(
          path: 'nueva',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<DebtFormCubit>(), (c) => c.load(null)),
            child: const DebtFormPage(),
          ),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(
              getIt<DebtDetailCubit>(),
              (c) => c.start(state.pathParameters['id']!),
            ),
            child: DebtDetailPage(
              // Editing pops with `true` when the debt was deleted, so the
              // detail closes back to the list behind it.
              onEdit: (id) async {
                final deleted =
                    await context.push<bool>(AppRoutes.editDebt(id));
                if ((deleted ?? false) && context.mounted) {
                  context.pop();
                }
              },
              // Cross-link into Pagos programados for the linked cuota (HU-03).
              onOpenInstallment: (id) =>
                  context.push(AppRoutes.scheduledPayment(id)),
              // Configure the debt's cuota (HU-03): reuses the Pagos Programados
              // form in cuota mode; the debt context rides in `extra`. The
              // debt's creation date and current outstanding travel with it so
              // the cuota form can bound the first-payment date and the cuota
              // amount (Deudas fixes 4a).
              onConfigureInstallment: (debt, outstandingMinor) => context.push(
                AppRoutes.debtInstallment(debt.id),
                extra: DebtInstallmentContext(
                  debtId: debt.id,
                  debtName: debt.name,
                  iOwe: debt.direction == DebtDirection.iOwe,
                  debtCreatedAt: debt.createdAt,
                  debtOutstandingMinor: outstandingMinor,
                  debtDueDate: debt.dueDate,
                ),
              ),
              // Attribute an existing movement to the debt (HU-02): the debt
              // rides in `extra` so the banner needs no extra fetch.
              onLinkExisting: (debt) => context.push(
                AppRoutes.linkTransactionToDebt(debt.id),
                extra: debt,
              ),
              // Open a cash ledger row's movement detail (HU-04).
              onOpenTransaction: (id) =>
                  context.push<String>(AppRoutes.transaction(id)),
            ),
          ),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<DebtFormCubit>(),
                  (c) => c.load(state.pathParameters['id']),
                ),
                child: const DebtFormPage(),
              ),
            ),
            // Configurar cuota (HU-03): the Pagos Programados form reused in
            // cuota mode. The debt context arrives in `extra`; `?spId=` is set
            // when editing an existing cuota (deep-link from its PP detail).
            GoRoute(
              path: 'cuota',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final debtContext = state.extra! as DebtInstallmentContext;
                final spId = state.uri.queryParameters['spId'];
                return AccountGatedRoute(
                  surface: AccountGateSurface.scheduledPayment,
                  builder: (context) => BlocProvider(
                    create: (context) => _startedDebtInstallmentForm(
                      debtContext,
                      spId,
                    ),
                    child: const ScheduledPaymentFormPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

/// HU-03: opens the Pagos Programados form in cuota mode for [debtContext],
/// editing [scheduledPaymentId] when set (deep-link back from a cuota's PP
/// detail) or creating a fresh cuota otherwise. Keeps the two features'
/// domains decoupled: only plain values cross here.
ScheduledPaymentFormCubit _startedDebtInstallmentForm(
  DebtInstallmentContext debtContext,
  String? scheduledPaymentId,
) {
  final cubit = getIt<ScheduledPaymentFormCubit>();
  unawaited(
    cubit.loadForDebtCuota(
      debtId: debtContext.debtId,
      debtName: debtContext.debtName,
      debtIsIOwe: debtContext.iOwe,
      scheduledPaymentId: scheduledPaymentId,
      debtCreatedAt: debtContext.debtCreatedAt,
      debtOutstandingMinor: debtContext.debtOutstandingMinor,
      debtDueDate: debtContext.debtDueDate,
    ),
  );
  return cubit;
}

// Movimientos in Deudas link mode (HU-02): the existing Movimientos list reused
// with a `TransactionsLinkMode` — a banner, no FAB, no carousel, and row taps
// that attribute the movement to the debt. Stacked on the root navigator above
// the tab bar. The `Debt` arrives in `state.extra`.
GoRoute _debtLinkModeRoute() => GoRoute(
      path: AppRoutes.linkTransactionToDebt(':debtId'),
      parentNavigatorKey: _rootNavigatorKey,
      // HU-03/HU-04 of `15-gate-cuenta.md`: without any active account there
      // are no movements to list, so the bridge (`oHAVJ`, "Aún no hay
      // movimientos para enlazar") replaces the empty list instead of
      // leaving the user to guess why it's empty.
      builder: (context, state) {
        final debt = state.extra! as Debt;
        return AccountGatedRoute(
          surface: AccountGateSurface.linkMovement,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: _started(
                  getIt<TransactionsListCubit>(),
                  (c) => c.start(),
                ),
              ),
              BlocProvider.value(
                value:
                    _started(getIt<BalanceCarouselCubit>(), (c) => c.load()),
              ),
              BlocProvider.value(value: getIt<DebtLinkCubit>()..start(debt)),
            ],
            child: DebtLinkModePage(debt: debt),
          ),
        );
      },
    );

// Movimientos in Metas link mode (HU-03 "Enlazar un movimiento"): the
// existing Movimientos list reused with a `TransactionsLinkMode` — a banner,
// no FAB, no carousel, and row taps that attribute the movement to the goal.
// Stacked on the root navigator above the tab bar. The `GoalLinkContext`
// arrives in `state.extra`.
GoRoute _goalLinkModeRoute() => GoRoute(
      path: AppRoutes.linkTransactionToGoal(':goalId'),
      parentNavigatorKey: _rootNavigatorKey,
      // Same bridge as `_debtLinkModeRoute` (`15-gate-cuenta.md` HU-03/HU-04).
      builder: (context, state) {
        final linkContext = state.extra! as GoalLinkContext;
        return AccountGatedRoute(
          surface: AccountGateSurface.linkMovement,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: _started(
                  getIt<TransactionsListCubit>(),
                  (c) => c.start(),
                ),
              ),
              BlocProvider.value(
                value:
                    _started(getIt<BalanceCarouselCubit>(), (c) => c.load()),
              ),
              BlocProvider.value(
                value: getIt<GoalLinkCubit>()
                  ..start(
                    goalId: linkContext.goalId,
                    goalName: linkContext.goalName,
                    direction: linkContext.direction,
                  ),
              ),
            ],
            child: GoalLinkModePage(
              goalId: linkContext.goalId,
              goalName: linkContext.goalName,
              direction: linkContext.direction,
            ),
          ),
        );
      },
    );

// Import/Export (`docs/requirements/11-import-export.md`): the hub is
// reached from "Más" → Gestión and from Sincronización's "Guardar una copia"
// row, so it lives as a root-navigator sibling like Cuentas/Categorías —
// never inside a `StatefulShellBranch` (a `Page Header` and the `Tab Bar`
// are mutually exclusive, MASTER.md).
GoRoute _importExportRoute() => GoRoute(
      path: AppRoutes.importExport,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider(
        create: (context) =>
            _started(getIt<ImportExportHubCubit>(), (c) => c.start()),
        // `Builder`, not the outer `context`: that one is the route
        // builder's own context, an ANCESTOR of the `BlocProvider` above
        // (it's the context the provider is inserted *below*), so
        // `context.read<ImportExportHubCubit>()` from it can never find the
        // cubit — ancestor lookup only walks up, never down. `_saveCopy`
        // needs a context that is a descendant of the provider instead.
        child: Builder(
          builder: (context) => ImportExportHubPage(
            onSaveCopy: () => unawaited(_saveCopy(context)),
            onExportCsv: () => context.push(AppRoutes.exportCsv),
            onImportCsv: () => unawaited(_openImportFlow(context)),
            onRestore: () => unawaited(RestoreSheet.show(context)),
            onSeeImportHistory: () => context.push(AppRoutes.importBatches),
            onOpenBatch: (_) => context.push(AppRoutes.importBatches),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'exportar',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) {
              final cubit = getIt<ExportCubit>();
              unawaited(
                getIt<HasAnyTransaction>().call().first.then(
                      (hasAnyTransactions) => cubit.start(
                        hasAnyTransactions: hasAnyTransactions,
                      ),
                    ),
              );
              return cubit;
            },
            child: const ExportPage(),
          ),
        ),
        GoRoute(
          path: 'importar',
          parentNavigatorKey: _rootNavigatorKey,
          // `state.extra` is always the already-parsed `ImportFlowCubit`
          // `ImportPickSheet.show` handed to `_openImportFlow` — this route
          // is only ever pushed from there (`onImportCsv` above), never
          // linked to directly.
          builder: (context, state) => BlocProvider<ImportFlowCubit>.value(
            value: state.extra! as ImportFlowCubit,
            child: ImportFlowPage(onDone: () => context.pop()),
          ),
        ),
        GoRoute(
          path: 'importaciones',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<ImportBatchesCubit>(), (c) => c.start()),
            child: const ImportBatchesPage(),
          ),
        ),
      ],
    );

/// Opens `SaveCopySheet`, then feeds its result straight back to the hub's
/// already-mounted `ImportExportHubCubit` (`context.read`, same context the
/// route builder gave the hub page) so the hero card reflects "última copia"
/// without waiting for a full [ImportExportHubCubit.start] refresh — the hub
/// route provides that cubit, but `showModalBottomSheet` does not hand it
/// down into the sheet's own subtree, so `SaveCopySheet` cannot reach it
/// itself (same reasoning `RestoreSheet`/`ExportRunSheet`/`ImportRunSheet`
/// already follow, each providing what its sheet needs explicitly).
Future<void> _saveCopy(BuildContext context) async {
  final hubCubit = context.read<ImportExportHubCubit>();
  final savedAt = await SaveCopySheet.show(context);
  if (savedAt != null) {
    hubCubit.markBackupJustSaved(savedAt);
  }
}

/// Drives `ImportPickSheet` (native file picker, then its own error sheet on
/// an unreadable file) and only pushes the wizard route once a file actually
/// parsed — `ImportPickSheet` never touches `AppRoutes` itself. Closes the
/// cubit either way: if nothing was returned there is nothing to close
/// besides what `ImportPickSheet` already closed, and once the pushed route
/// pops back off the stack the wizard is done with it too.
Future<void> _openImportFlow(BuildContext context) async {
  final cubit = await ImportPickSheet.show(context);
  if (cubit == null) {
    return;
  }
  if (!context.mounted) {
    await cubit.close();
    return;
  }
  await context.push(AppRoutes.importCsv, extra: cubit);
  await cubit.close();
}

// The welcome flow (`13-onboarding.md`): four screens under `/bienvenida`,
// each its own `GoRoute` (not a `PageView` inside one route) so the Android
// back button gets ordinary stack-pop behavior between steps for free, and
// so "Ya tengo cuenta"/"Activar respaldo" can reuse the *exact* `LoginPage`/
// `MergeConfirmationPage` routes (just with onboarding-flavored callbacks)
// instead of a parallel login implementation. All stacked on the root
// navigator, outside the tab shell — nothing here has a `Tab Bar`.
GoRoute _onboardingRoute() => GoRoute(
      path: AppRoutes.onboarding,
      parentNavigatorKey: _rootNavigatorKey,
      // `BlocProvider.value` (not `create:`): `OnboardingFlowCubit` is
      // `@lazySingleton`, same reasoning as `ReportsShellCubit` — `create:`
      // would close the singleton on dispose and leave `GetIt` handing out
      // a closed instance on a later visit (Sentry BILLETUDO-B). Every
      // nested onboarding route below already uses `.value`; this was the
      // one outlier.
      builder: (context, state) => BlocProvider.value(
        value: getIt<OnboardingFlowCubit>()..stepped(OnboardingStep.welcome),
        child: WelcomePage(
          onComenzar: () => context.push(AppRoutes.onboardingAccount),
          onYaTengoCuenta: () => context.push(
            AppRoutes.onboardingLoginFrom(closesFlow: true),
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: 'cuenta',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: getIt<OnboardingFlowCubit>()
                  ..stepped(OnboardingStep.account),
              ),
              BlocProvider(
                create: (_) => _startedOnboardingAccountForm(
                  defaultName:
                      AppLocalizations.of(context).onboardingAccountDefaultName,
                ),
              ),
            ],
            child: FirstAccountPage(
              onCreated: () {
                getIt<OnboardingFlowCubit>().accountCreated();
                unawaited(context.push(AppRoutes.onboardingBackup));
              },
              onSkip: () {
                getIt<OnboardingFlowCubit>().accountSkipped();
                unawaited(context.push(AppRoutes.onboardingBackup));
              },
            ),
          ),
        ),
        GoRoute(
          path: 'respaldo',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider.value(
            value: getIt<OnboardingFlowCubit>()..stepped(OnboardingStep.backup),
            child: BackupIntroPage(
              onActivarRespaldo: () => context.push(
                AppRoutes.onboardingLoginFrom(closesFlow: false),
              ),
              onDespues: () => context.push(AppRoutes.onboardingClosing),
            ),
          ),
        ),
        GoRoute(
          path: 'cierre',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final cubit = getIt<OnboardingFlowCubit>()
              ..stepped(OnboardingStep.closing);
            return BlocProvider.value(
              value: cubit,
              child: BlocBuilder<OnboardingFlowCubit, OnboardingProgress>(
                builder: (context, progress) => ClosingPage(
                  accountSkipped: progress.accountSkipped,
                  onPrimary: () => unawaited(
                    _finishOnboardingThen(
                      context,
                      progress.accountSkipped
                          ? AppRoutes.newAccount
                          : AppRoutes.newTransaction,
                    ),
                  ),
                  onSkip: () => unawaited(_finishOnboardingThen(context, null)),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: 'iniciar-sesion',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final closesFlow =
                state.uri.queryParameters['closesFlow'] == 'true';
            return BlocProvider(
              create: (context) => getIt<LoginCubit>(),
              child: LoginPage(
                onSignedIn: () => context.push(
                  AppRoutes.onboardingMergeConfirmationFrom(
                    closesFlow: closesFlow,
                  ),
                ),
                onSkip: () => context.pop(),
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'fusion',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final closesFlow =
                    state.uri.queryParameters['closesFlow'] == 'true';
                return BlocProvider(
                  create: (context) =>
                      _started(getIt<MergeCubit>(), (c) => c.start()),
                  child: MergeConfirmationPage(
                    // `closesFlow: false` (HU-07, "Activar respaldo" from
                    // step 3) does NOT go to Home/finanzas — it returns to
                    // Cierre (step 4). "Ir a mis finanzas" would mislead the
                    // user there, so this path gets the generic "Continuar"
                    // instead; `closesFlow: true` keeps the default label.
                    ctaLabel: closesFlow
                        ? null
                        : AppLocalizations.of(context).commonContinue,
                    onDone: () => unawaited(
                      _finishOnboardingAfterLogin(
                        context,
                        closesFlow: closesFlow,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

/// HU-02: pre-fills the exact `AccountFormCubit` `AccountFormPage` uses
/// (`docs/requirements/13-onboarding.md` — "reutiliza el formulario ...
/// mismas validaciones, mismos widgets") through its own public setters —
/// name "Ahorros" (localized), type `savings`, currency from the device
/// region (`ResolveDefaultCurrencyForLocale`). No new use case, no second
/// form implementation.
///
/// [defaultName] is resolved by the caller (the route's own `builder`
/// context, a normal build-phase context) rather than looked up here: this
/// function runs inside a `BlocProvider.create`, and `AppLocalizations.of`
/// calls `dependOnInheritedWidgetOfExactType`, which Flutter forbids from
/// `create` — that life-cycle never re-runs, so it can never react to a
/// dependency change, and throws instead of silently ignoring it.
AccountFormCubit _startedOnboardingAccountForm({required String defaultName}) {
  final cubit = getIt<AccountFormCubit>();
  unawaited(_loadOnboardingAccountForm(cubit, defaultName: defaultName));
  return cubit;
}

/// `13-onboarding.md`, "Interrupción a mitad": if the app died right after
/// step 2 created the account on a previous attempt, the account survives
/// (it is a normal row, never tagged "created in onboarding") and this step
/// must show it instead of silently re-offering the "Ahorros" default —
/// which would look identical to a fresh account and invite a duplicate.
Future<void> _loadOnboardingAccountForm(
  AccountFormCubit cubit, {
  required String defaultName,
}) async {
  final accountsResult =
      await getIt<AccountRepository>().watchActiveAccounts().first;
  final existing = switch (accountsResult) {
    Right(value: final accounts) when accounts.isNotEmpty =>
      accounts.first.account,
    _ => null,
  };
  if (existing != null) {
    await cubit.load(existing.id);
    return;
  }

  await cubit.load(null);
  final currency = getIt<ResolveDefaultCurrencyForLocale>()(null);
  cubit
    ..typeSelected(AccountType.savings)
    ..nameChanged(defaultName)
    ..currencySelected(currency);
}

/// HU-04: acting on the closing screen — registering or skipping — is what
/// turns the `onboardingCompleted` latch on, regardless of which one the user
/// picked (`13-onboarding.md`, "Persistencia y ciclo de vida del flujo").
/// [nextRoute] is pushed on top of Home afterward when the CTA itself opens
/// something (the transaction form, or the create-account bridge); `null`
/// for the plain skip.
Future<void> _finishOnboardingThen(
  BuildContext context,
  String? nextRoute,
) async {
  await getIt<OnboardingFlowCubit>().finish();
  if (!context.mounted) {
    return;
  }
  context.go(AppRoutes.home);
  if (nextRoute != null) {
    unawaited(context.push(nextRoute));
  }
}

/// HU-06 (`closesFlow: true`, from Bienvenida's "Ya tengo cuenta"): a
/// successful sign-in + merge closes the whole flow and enters Home directly
/// — "no se le vuelve a pedir crear una cuenta a alguien que acaba de
/// recuperar las suyas".
///
/// HU-07 (`closesFlow: false`, from Respalda tus datos' "Activar respaldo"):
/// "Activar respaldo aquí no termina el onboarding a la fuerza" — the flow
/// continues to Cierre with normalcy instead, which is the one that actually
/// finishes it.
Future<void> _finishOnboardingAfterLogin(
  BuildContext context, {
  required bool closesFlow,
}) async {
  final cubit = getIt<OnboardingFlowCubit>()..authenticated();
  if (!closesFlow) {
    context.go(AppRoutes.onboardingClosing);
    return;
  }
  await cubit.finish();
  if (!context.mounted) {
    return;
  }
  context.go(AppRoutes.home);
}

GoRoute _categoriesRoute() => GoRoute(
      path: AppRoutes.categories,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BlocProvider(
        create: (context) =>
            _started(getIt<CategoriesListCubit>(), (c) => c.start()),
        child: CategoriesPage(
          onAddCategory: (kind) =>
              context.push(AppRoutes.newCategory(kind: kind)),
          onAddSubcategory: (rootId) =>
              context.push(AppRoutes.newSubcategory(rootId)),
          onOpenCategory: (id) => context.push(AppRoutes.editCategory(id)),
        ),
      ),
      routes: [
        GoRoute(
          path: 'nueva',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(
              getIt<CategoryFormCubit>(),
              (c) => c.load(kind: _kindFromQuery(state.uri)),
            ),
            child: const CategoryFormPage(),
          ),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(
              getIt<CategoryFormCubit>(),
              (c) => c.load(id: state.pathParameters['id']),
            ),
            child: const CategoryFormPage(),
          ),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<CategoryFormCubit>(),
                  (c) => c.load(id: state.pathParameters['id']),
                ),
                child: const CategoryFormPage(),
              ),
            ),
            GoRoute(
              path: 'subcategoria-nueva',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<CategoryFormCubit>(),
                  (c) => c.load(parentId: state.pathParameters['id']),
                ),
                child: const CategoryFormPage(),
              ),
            ),
          ],
        ),
      ],
    );

// Pagos Programados (HU-01/02/03/04/05/06/07): no longer a tab (Metas
// recovered its slot). It stays a real Nivel 0 destination reachable from
// Inicio's quick access and the "Más" hub, rendered as a stacked screen on
// the root navigator — hence its own `Page Header` with a back button,
// unlike when it was a tab root.
GoRoute _pagosProgramadosRoute() => GoRoute(
      path: AppRoutes.scheduledPayments,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => _started(
              getIt<ScheduledPaymentsListCubit>(),
              (c) => c.start(),
            ),
          ),
          BlocProvider(
            create: (context) => _started(
              getIt<PendingOccurrencesCubit>(),
              (c) => c.start(),
            ),
          ),
        ],
        child: ScheduledPaymentsPage(
          onAddScheduledPayment: () =>
              context.push(AppRoutes.newScheduledPayment),
          onOpenScheduledPayment: (id) =>
              context.push(AppRoutes.scheduledPayment(id)),
          onOpenPending: () => context.push(AppRoutes.pendingScheduledPayments),
        ),
      ),
      routes: [
        // Declared before ':id' so "nuevo"/"por-confirmar" are never read as
        // ids.
        GoRoute(
          path: 'nuevo',
          parentNavigatorKey: _rootNavigatorKey,
          // HU-04 of `15-gate-cuenta.md`: same bridge as a direct/deep-linked
          // visit to `/movimientos/nuevo`.
          builder: (context, state) => AccountGatedRoute(
            surface: AccountGateSurface.scheduledPayment,
            builder: (context) => BlocProvider(
              create: (context) => _startedScheduledPaymentForm(state.uri),
              child: const ScheduledPaymentFormPage(),
            ),
          ),
        ),
        GoRoute(
          path: 'por-confirmar',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) =>
                _started(getIt<PendingOccurrencesCubit>(), (c) => c.start()),
            child: const PendingOccurrencesPage(),
          ),
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (context) => _started(
              getIt<ScheduledPaymentDetailCubit>(),
              (c) => c.start(state.pathParameters['id']!),
            ),
            child: ScheduledPaymentDetailPage(
              onEdit: (id) => context.push(AppRoutes.editScheduledPayment(id)),
              onOpenTransaction: (id) =>
                  context.push<String>(AppRoutes.transaction(id)),
              // Cross-link into the owning debt's detail (HU-03).
              onOpenDebt: (debtId) => context.push(AppRoutes.debt(debtId)),
              // Editing a cuota deep-links back to the debt's
              // Configurar-cuota screen (its home), not the plain form.
              onEditInstallment: (debt, spId) => context.push(
                AppRoutes.debtInstallment(debt.id, spId: spId),
                extra: DebtInstallmentContext(
                  debtId: debt.id,
                  debtName: debt.name,
                  iOwe: debt.iOwe,
                ),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'editar',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<ScheduledPaymentFormCubit>(),
                  (c) => c.load(state.pathParameters['id']),
                ),
                child: const ScheduledPaymentFormPage(),
              ),
            ),
          ],
        ),
      ],
    );

/// HU-06/criterion 14: when the "nuevo" template route carries the puente's
/// query params (see `AppRoutes.newScheduledPaymentFromTransaction`), starts
/// the form prefilled from them instead of empty.
ScheduledPaymentFormCubit _startedScheduledPaymentForm(Uri uri) {
  final cubit = getIt<ScheduledPaymentFormCubit>();
  final accountId = uri.queryParameters['accountId'];
  if (accountId == null || accountId.isEmpty) {
    unawaited(cubit.load(null));
    return cubit;
  }
  final typeRaw = uri.queryParameters['type'];
  final type = ScheduledPaymentType.values.firstWhere(
    (value) => value.name == typeRaw,
    orElse: () => ScheduledPaymentType.expense,
  );
  final categoryKindRaw = uri.queryParameters['categoryKind'];
  final categoryKind = categoryKindRaw == null
      ? null
      : CategoryKind.values.firstWhere(
          (value) => value.name == categoryKindRaw,
          orElse: () => CategoryKind.expense,
        );
  cubit.loadFromBridge(
    accountId: accountId,
    accountName: uri.queryParameters['accountName'] ?? '',
    amountMinor: int.tryParse(uri.queryParameters['amountMinor'] ?? '') ?? 0,
    currency: uri.queryParameters['currency'] ?? 'COP',
    type: type,
    nextDate: DateTime.tryParse(uri.queryParameters['nextDate'] ?? '') ??
        DateTime.now(),
    categoryId: uri.queryParameters['categoryId'],
    categoryKind: categoryKind,
    categoryName: uri.queryParameters['categoryName'],
    note: uri.queryParameters['note'],
    tagIds: (uri.queryParameters['tagIds'] ?? '')
        .split(',')
        .where((id) => id.isNotEmpty)
        .toSet(),
  );
  return cubit;
}

TransactionType _typeFromQuery(Uri uri) {
  final raw = uri.queryParameters['type'];
  return TransactionType.values.firstWhere(
    (type) => type.name == raw,
    orElse: () => TransactionType.expense,
  );
}

CategoryKind _kindFromQuery(Uri uri) =>
    uri.queryParameters['kind'] == CategoryKind.income.name
        ? CategoryKind.income
        : CategoryKind.expense;

/// Kicks off a cubit's initial load and hands it straight to `BlocProvider`.
///
/// The load is intentionally not awaited — the cubit emits its loading state
/// synchronously and the page renders it — but it goes through `unawaited` so
/// that stays a decision, not an oversight.
T _started<T>(T cubit, Future<void> Function(T cubit) start) {
  unawaited(start(cubit));
  return cubit;
}

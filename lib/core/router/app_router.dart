import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/cubit/account_detail_cubit.dart';
import '../../features/accounts/presentation/cubit/account_form_cubit.dart';
import '../../features/accounts/presentation/cubit/accounts_list_cubit.dart';
import '../../features/accounts/presentation/cubit/archived_accounts_cubit.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/account_form_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/presentation/pages/archived_accounts_page.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/login_cubit.dart';
import '../../features/auth/presentation/cubit/merge_cubit.dart';
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
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/home/presentation/pages/more_page.dart';
import '../../features/settings/presentation/cubit/app_settings_cubit.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import '../../features/transactions/presentation/cubit/transaction_form_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_list_cubit.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../di/injection.dart';
import '../l10n/gen/app_localizations.dart';
import '../widgets/coming_soon_page.dart';

/// App routes. Each feature registers its own here. Paths stay in Spanish
/// because they are user-visible URLs.
///
/// The app is a five-tab shell (Inicio, Movimientos, Presupuestos, Metas, Más).
/// List/hub pages live inside their tab branch (the tab bar stays visible);
/// stacked forms and detail pages render on the root navigator, above the tab
/// bar (MASTER: a `Page Header` and the `Tab Bar` are mutually exclusive).
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String budgets = '/presupuestos';
  static const String newBudget = '/presupuestos/nuevo';
  static const String budgetsHistory = '/presupuestos/historico';
  static const String goals = '/metas';
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
  static const String mergeConfirmation = '/mas/ajustes/respaldar/fusion';
  static const String accountDeleted = '/mas/cuenta-eliminada';

  /// A stacked "Próximamente" page titled with a destination's name.
  static String comingSoonTitled(String title) =>
      '$comingSoon?title=${Uri.encodeQueryComponent(title)}';

  /// Detail of one budget: `/presupuestos/<id>`.
  static String budget(String id) => '$budgets/$id';

  /// Edit form of one budget: `/presupuestos/<id>/editar`.
  static String editBudget(String id) => '$budgets/$id/editar';

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
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the app [GoRouter]. Instantiated once during bootstrap.
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShellPage(navigationShell: navigationShell),
        branches: [
          _inicioBranch(),
          _movimientosBranch(),
          _presupuestosBranch(),
          _metasBranch(),
          _masBranch(),
        ],
      ),
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
              onSeeAllTransactions: () => context.go(AppRoutes.transactions),
              onOpenTransaction: (id) =>
                  context.push(AppRoutes.transaction(id)),
              onCreateBudget: () => context.go(AppRoutes.budgets),
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
            return BlocProvider.value(
              value: listCubit,
              child: TransactionsPage(
                onAddTransaction: () => context.push(AppRoutes.newTransaction),
                onOpenTransaction: (id) =>
                    context.push<String>(AppRoutes.transaction(id)),
              ),
            );
          },
          routes: [
            // Declared before ':id' so "nuevo" is never read as an id.
            GoRoute(
              path: 'nuevo',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<TransactionFormCubit>(),
                  (c) => c.load(null, type: _typeFromQuery(state.uri)),
                ),
                child: const TransactionFormPage(),
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
              builder: (context, state) => BlocProvider(
                create: (context) =>
                    _started(getIt<BudgetFormCubit>(), (c) => c.load(null)),
                child: const BudgetFormPage(),
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
              builder: (context, state) => BlocProvider(
                create: (context) => _started(
                  getIt<BudgetDetailCubit>(),
                  (c) => c.start(state.pathParameters['id']!),
                ),
                child: BudgetDetailPage(
                  onEdit: (id) => context.push(AppRoutes.editBudget(id)),
                  onClosed: () => context.pop(),
                  onOpenInTransactions: () => context.go(AppRoutes.transactions),
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

StatefulShellBranch _metasBranch() => StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.goals,
          builder: (context, state) => ComingSoonPage(
            title: AppLocalizations.of(context).navGoals,
            showAppBar: false,
          ),
        ),
      ],
    );

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
                onGoHome: () => context.go(AppRoutes.home),
              ),
            ),
            _settingsRoute(),
          ],
        ),
        _accountsRoute(),
        _categoriesRoute(),
      ],
    );

Future<void> _confirmSignOut(BuildContext context) async {
  final confirmed = await ConfirmSignOutSheet.show(context);
  if (confirmed == true) {
    await getIt<AuthCubit>().signOut();
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
        ],
        child: SettingsPage(
          onOpenLogin: () => context.push(AppRoutes.login),
          onOpenDeleteAccount: () => DeleteAccountFlow.start(
            context,
            onFinished: () => context.push(AppRoutes.accountDeleted),
          ),
          onOpenComingSoon: (title) =>
              context.push(AppRoutes.comingSoonTitled(title)),
        ),
      ),
      routes: [
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

GoRoute _accountsRoute() => GoRoute(
      path: AppRoutes.accounts,
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

GoRoute _categoriesRoute() => GoRoute(
      path: AppRoutes.categories,
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

import 'dart:async';

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
import '../../features/categories/domain/entities/category.dart';
import '../../features/categories/presentation/cubit/categories_list_cubit.dart';
import '../../features/categories/presentation/cubit/category_form_cubit.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_form_page.dart';
import '../di/injection.dart';
import 'bootstrap_home_page.dart';

/// App routes. Each feature registers its own here (Accounts, Categories,
/// Transactions). Paths stay in Spanish because they are user-visible URLs.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String accounts = '/cuentas';
  static const String newAccount = '/cuentas/nueva';
  static const String archivedAccounts = '/cuentas/archivadas';
  static const String categories = '/categorias';
  static const String transactions = '/movimientos';

  /// Detail of one account: `/cuentas/<id>`.
  static String account(String id) => '$accounts/$id';

  /// Edit form of one account: `/cuentas/<id>/editar`.
  static String editAccount(String id) => '$accounts/$id/editar';

  /// New root category, optionally starting on `kind`'s Tipo segment
  /// (whichever Toggle segment was active when `+` was tapped).
  static String newCategory({CategoryKind kind = CategoryKind.expense}) =>
      '$categories/nueva?kind=${kind.name}';

  /// Edit form of one category (root or sub): `/categorias/<id>/editar`.
  static String editCategory(String id) => '$categories/$id/editar';

  /// New subcategory of the root category [parentId].
  static String newSubcategory(String parentId) =>
      '$categories/$parentId/subcategoria-nueva';
}

/// Builds the app [GoRouter]. Instantiated once during bootstrap.
///
/// Every route owns its cubit: `BlocProvider` builds it from `getIt` and starts
/// it there, so no page ever reaches into the container itself.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const BootstrapHomePage(),
      ),
      GoRoute(
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
          // Declared before ':id' so "nueva"/"archivadas" are never read as an
          // account id.
          GoRoute(
            path: 'nueva',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  _started(getIt<AccountFormCubit>(), (c) => c.load(null)),
              child: const AccountFormPage(),
            ),
          ),
          GoRoute(
            path: 'archivadas',
            builder: (context, state) => BlocProvider(
              create: (context) =>
                  _started(getIt<ArchivedAccountsCubit>(), (c) => c.start()),
              child: const ArchivedAccountsPage(),
            ),
          ),
          GoRoute(
            path: ':id',
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
      ),
      GoRoute(
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
          // Declared before ':id' so "nueva" is never read as a category id.
          GoRoute(
            path: 'nueva',
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
      ),
    ],
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

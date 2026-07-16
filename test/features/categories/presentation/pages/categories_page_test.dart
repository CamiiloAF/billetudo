import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:billetudo/features/categories/presentation/pages/categories_page.dart';
import 'package:billetudo/features/categories/presentation/widgets/categories_empty_state.dart';
import 'package:billetudo/features/categories/presentation/widgets/categories_error_view.dart';
import 'package:billetudo/features/categories/presentation/widgets/category_accordion_row.dart';
import 'package:billetudo/features/categories/presentation/widgets/skeleton_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/usecases/category_repository_mock.dart';

class MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

void main() {
  setUpAll(() => registerFallbackValue(CategoryKind.expense));

  late MockCategoriesListCubit cubit;

  final nodes = [
    CategoryNode(
      root: buildCategory(id: 'root-1'),
      subcategories: [
        buildCategory(id: 'sub-1', name: 'Restaurantes', parentId: 'root-1'),
      ],
    ),
  ];

  setUp(() => cubit = MockCategoriesListCubit());

  /// Drives the page straight from the cubit's state: each of the four
  /// states (loading/empty/error/with data) is one stubbed value, same
  /// pattern as `accounts_page_test.dart`.
  Future<void> pumpPage(
    WidgetTester tester,
    CategoriesListState state, {
    ValueChanged<CategoryKind>? onAddCategory,
    ValueChanged<String>? onAddSubcategory,
    ValueChanged<String>? onOpenCategory,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CategoriesListCubit>.value(
          value: cubit,
          child: CategoriesPage(
            onAddCategory: onAddCategory ?? (_) {},
            onAddSubcategory: onAddSubcategory ?? (_) {},
            onOpenCategory: onOpenCategory ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('carga: 6 Skeleton Row, sin lista ni error', (tester) async {
    await pumpPage(tester, const CategoriesListState());

    expect(find.byType(CategorySkeletonRow), findsNWidgets(6));
    expect(find.byType(CategoryAccordionRow), findsNothing);
    expect(find.byType(CategoriesErrorView), findsNothing);
  });

  testWidgets('vacío: mensaje neutral y CTA de agregar', (tester) async {
    await pumpPage(
      tester,
      const CategoriesListState(status: CategoriesListStatus.ready),
    );

    expect(find.byType(CategoriesEmptyState), findsOneWidget);
    expect(find.text('Aún no tienes categorías de gasto'), findsOneWidget);
    expect(find.byType(CategorySkeletonRow), findsNothing);
  });

  testWidgets('con datos: una raíz en acordeón, expandida o colapsada '
      'según expandedRootIds', (tester) async {
    await pumpPage(
      tester,
      CategoriesListState(status: CategoriesListStatus.ready, nodes: nodes),
    );

    expect(find.byType(CategoryAccordionRow), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.byType(CategoriesEmptyState), findsNothing);
    // Collapsed by default (expandedRootIds is empty): the subcategory row
    // does not render.
    expect(find.text('Restaurantes'), findsNothing);
  });

  testWidgets('con datos: una raíz expandida muestra su subcategoría', (
    tester,
  ) async {
    await pumpPage(
      tester,
      CategoriesListState(
        status: CategoriesListStatus.ready,
        nodes: nodes,
        expandedRootIds: const {'root-1'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restaurantes'), findsOneWidget);
  });

  testWidgets('error: icono neutral, mensaje local-first y Reintentar', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const CategoriesListState(status: CategoriesListStatus.failure),
    );

    expect(find.byType(CategoriesErrorView), findsOneWidget);
    expect(find.text('No pudimos cargar tus categorías'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Reintentar vuelve a pedir la carga del kind activo', (
    tester,
  ) async {
    when(() => cubit.start(kind: any(named: 'kind'))).thenAnswer((_) async {});
    await pumpPage(
      tester,
      const CategoriesListState(status: CategoriesListStatus.failure),
    );

    await tester.tap(find.text('Reintentar'));
    // ignore: avoid_redundant_argument_values
    verify(() => cubit.start(kind: CategoryKind.expense)).called(1);
  });

  testWidgets('tocar el toggle Ingreso cambia el kind vía selectKind', (
    tester,
  ) async {
    when(() => cubit.selectKind(any())).thenAnswer((_) async {});
    await pumpPage(
      tester,
      const CategoriesListState(status: CategoriesListStatus.ready),
    );

    await tester.tap(find.text('Ingreso'));
    verify(() => cubit.selectKind(CategoryKind.income)).called(1);
  });

  testWidgets('tocar "+" en el app bar crea una raíz del kind activo', (
    tester,
  ) async {
    CategoryKind? added;
    await pumpPage(
      tester,
      CategoriesListState(
        status: CategoriesListStatus.ready,
        kind: CategoryKind.income,
        nodes: nodes,
      ),
      onAddCategory: (kind) => added = kind,
    );

    await tester.tap(find.byIcon(Icons.add));
    expect(added, CategoryKind.income);
  });

  testWidgets('tocar el ícono de editar de una raíz abre esa categoría', (
    tester,
  ) async {
    String? opened;
    await pumpPage(
      tester,
      CategoriesListState(status: CategoriesListStatus.ready, nodes: nodes),
      onOpenCategory: (id) => opened = id,
    );

    await tester.tap(find.byTooltip('Editar'));
    expect(opened, 'root-1');
  });
}

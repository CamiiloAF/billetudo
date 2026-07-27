import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:billetudo/features/transactions/presentation/widgets/category_picker/category_select_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

/// Bugfix item 13: the `Category Select Sheet`'s inline "+" opens the *full*
/// create-category flow (`CategoryFormPage` via the `newCategory` route) on the
/// sheet's kind — not a name-only prompt — and, on success, pops with the
/// created category so the picker leaves it selected.
void main() {
  late _MockCategoriesListCubit cubit;

  final created = Category(
    id: 'new-cat',
    name: 'Suscripciones',
    kind: CategoryKind.expense,
    sortOrder: 0,
    createdAt: DateTime(2026),
    updatedAt: 0,
  );

  setUp(() {
    cubit = _MockCategoriesListCubit();
    when(() => cubit.state).thenReturn(
      const CategoriesListState(
        status: CategoriesListStatus.ready,
        nodes: <CategoryNode>[],
      ),
    );
  });

  // The sheet reserves a fixed 420px list viewport, so a taller-than-default
  // surface keeps the scroll-controlled modal from overflowing in the harness.
  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views;
    for (final v in view) {
      v.resetPhysicalSize();
      v.resetDevicePixelRatio();
    }
  });

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 2;
  }

  // A GoRouter whose home opens the sheet as a modal (so `_createCategory`'s
  // final pop returns to it), and whose `newCategory` route records the visited
  // location and immediately pops [created] back — standing in for the real
  // `CategoryFormPage`.
  Widget buildApp({
    required CategoryKind kind,
    required void Function(String location) onFormVisited,
    required void Function(Category? picked) onPicked,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    final picked = await showModalBottomSheet<Category>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      builder: (_) => BlocProvider<CategoriesListCubit>.value(
                        value: cubit,
                        child: CategorySelectSheetBody(
                          kind: kind,
                          selectedId: null,
                        ),
                      ),
                    );
                    onPicked(picked);
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/categorias/nueva',
          builder: (context, state) {
            onFormVisited(state.uri.toString());
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.pop(created),
                  child: const Text('guardar-fake'),
                ),
              ),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('el header muestra un botón "+" para crear categoría',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      buildApp(
        kind: CategoryKind.expense,
        onFormVisited: (_) {},
        onPicked: (_) {},
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets('tocar "+" navega al flujo completo con el kind de gasto',
      (tester) async {
    String? visited;
    useTallSurface(tester);
    await tester.pumpWidget(
      buildApp(
        kind: CategoryKind.expense,
        onFormVisited: (location) => visited = location,
        onPicked: (_) {},
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    expect(visited, isNotNull);
    expect(visited, contains('/categorias/nueva'));
    expect(visited, contains('kind=expense'));
  });

  testWidgets('el selector de ingreso crea la categoría como ingreso',
      (tester) async {
    String? visited;
    useTallSurface(tester);
    await tester.pumpWidget(
      buildApp(
        kind: CategoryKind.income,
        onFormVisited: (location) => visited = location,
        onPicked: (_) {},
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    expect(visited, contains('kind=income'));
  });

  testWidgets('al guardar, el sheet devuelve la categoría creada (seleccionada)',
      (tester) async {
    Category? picked;
    useTallSurface(tester);
    await tester.pumpWidget(
      buildApp(
        kind: CategoryKind.expense,
        onFormVisited: (_) {},
        onPicked: (value) => picked = value,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();

    await tester.tap(find.text('guardar-fake'));
    await tester.pumpAndSettle();

    expect(picked, created);
  });
}

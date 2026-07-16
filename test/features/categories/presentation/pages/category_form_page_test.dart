import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_deletion_impact.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:billetudo/features/categories/presentation/pages/category_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../usecase_mocks.dart';

/// Regression test for HU-04 case 1's delete flow, reproduced deterministically
/// against a *real* `CategoryFormCubit` (not a mocked one): a real
/// `DeleteCategory` call that resolves asynchronously used to expose a bug
/// where `CategoryFormPage`'s `BlocConsumer` re-invoked `_handlePrompt` — and
/// thus re-showed the just-answered confirm-delete sheet — because
/// `_finishDelete`'s first emit (`status: saving`) changed `status` while
/// leaving `deletePrompt` at its previous (non-`none`) value, which still
/// satisfied `listenWhen`. Caught first via a real-device Patrol run
/// (`integration_test/categories_patrol_test.dart`, HU-04 caso 1). Fixed by
/// clearing `deletePrompt` in that same first emit; kept here as a permanent
/// regression guard, not a known-red test.
void main() {
  setUpAll(registerCategoryPresentationFallbacks);

  late MockGetCategory getCategory;
  late MockGetCategoryDeletionImpact getDeletionImpact;
  late MockDeleteCategory deleteCategory;
  late MockCreateCategory createCategory;
  late MockUpdateCategory updateCategory;
  late CategoryFormCubit cubit;

  final category = Category(
    id: 'cat-1',
    name: 'Borrame test',
    kind: CategoryKind.expense,
    sortOrder: 0,
    createdAt: DateTime(2026, 7, 15),
    updatedAt: DateTime(2026, 7, 15),
  );

  setUp(() {
    getCategory = MockGetCategory();
    getDeletionImpact = MockGetCategoryDeletionImpact();
    deleteCategory = MockDeleteCategory();
    createCategory = MockCreateCategory();
    updateCategory = MockUpdateCategory();

    when(() => getCategory('cat-1')).thenAnswer((_) async => Right(category));
    when(() => getDeletionImpact('cat-1')).thenAnswer(
      (_) async => const Right(
        CategoryDeletionImpact(
          hasActiveSubcategories: false,
          transactionCount: 0,
        ),
      ),
    );
    // The async gap that exposes the bug: on a real device the delete write
    // never resolves in the same microtask as the sheet's `pop`, so the
    // fake must not either.
    when(
      () => deleteCategory(
        'cat-1',
        transactionResolution: any(named: 'transactionResolution'),
        subcategoryResolution: any(named: 'subcategoryResolution'),
      ),
    ).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), () => const Right(unit)),
    );

    cubit = CategoryFormCubit(
      createCategory,
      updateCategory,
      getCategory,
      getDeletionImpact,
      deleteCategory,
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider<CategoryFormCubit>.value(
                      value: cubit,
                      child: const CategoryFormPage(),
                    ),
                  ),
                ),
                child: const Text('marker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('marker'));
    // Not `pumpAndSettle`: the form starts in `loading`, rendering a
    // `CircularProgressIndicator`, whose animation never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await cubit.load(id: 'cat-1');
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'HU-04 caso 1: confirmar en la hoja simple borra y vuelve a la pantalla '
    'anterior, sin re-mostrar la hoja de confirmación',
    (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Eliminar categoría'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar esta categoría?'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      // Let the delayed `deleteCategory` future and every listener rebuild
      // settle, same as the extra pump the Patrol e2e already needed.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(
        find.byType(CategoryFormPage),
        findsNothing,
        reason: 'the form must have been popped off the navigator after the '
            'delete completes',
      );
      expect(find.text('marker'), findsOneWidget);
    },
  );
}

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_state.dart';
import 'package:billetudo/features/categories/presentation/pages/category_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryFormCubit extends MockCubit<CategoryFormState>
    implements CategoryFormCubit {}

/// Fix #15b: the name field must show a "required" message when it's empty,
/// never the length copy — which is reserved for a name over the limit.
void main() {
  late MockCategoryFormCubit cubit;

  const requiredMsg = 'Ingresa un nombre para la categoría.';
  const lengthMsg = 'Escribe un nombre de hasta 100 caracteres.';

  setUp(() => cubit = MockCategoryFormCubit());

  Future<void> pumpForm(WidgetTester tester, CategoryFormState state) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CategoryFormCubit>.value(
          value: cubit,
          child: const CategoryFormPage(),
        ),
      ),
    );
    await tester.pump();
  }

  CategoryFormState failedWith(String name) => CategoryFormState(
        status: CategoryFormStatus.ready,
        name: name,
        failure: const ValidationFailure(
          'category name is required',
          field: CategoryDraft.fieldName,
        ),
      );

  testWidgets('an empty name shows the required message, not the length one',
      (tester) async {
    await pumpForm(tester, failedWith(''));

    expect(find.text(requiredMsg), findsOneWidget);
    expect(find.text(lengthMsg), findsNothing);
  });

  testWidgets('a whitespace-only name is still treated as empty',
      (tester) async {
    await pumpForm(tester, failedWith('   '));

    expect(find.text(requiredMsg), findsOneWidget);
    expect(find.text(lengthMsg), findsNothing);
  });

  testWidgets('a name over the limit shows the length message', (tester) async {
    await pumpForm(tester, failedWith('a' * 101));

    expect(find.text(lengthMsg), findsOneWidget);
    expect(find.text(requiredMsg), findsNothing);
  });
}

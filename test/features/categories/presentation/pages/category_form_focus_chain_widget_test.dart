import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/presentation/cubit/category_form_cubit.dart';
import 'package:billetudo/features/categories/presentation/pages/category_form_page.dart';
import 'package:billetudo/features/categories/presentation/widgets/appearance_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../usecase_mocks.dart';

/// The keyboard action of the crear/editar category form: the name is the only
/// text input, so it declares "listo" (done), which dismisses the keyboard.
/// Tapping the apariencia selector unfocuses first so the keyboard does not
/// reopen when its sheet closes. Driven against a real cubit with mocked
/// use cases.
void main() {
  setUpAll(registerCategoryPresentationFallbacks);

  late CategoryFormCubit cubit;

  setUp(() {
    cubit = CategoryFormCubit(
      MockCreateCategory(),
      MockUpdateCategory(),
      MockGetCategory(),
      MockGetCategoryDeletionImpact(),
      MockDeleteCategory(),
      MockSuggestSubcategoryIcon(),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    await cubit.load();
    await tester.pump();
  }

  final Finder name = find.byType(EditableText);

  bool hasFocus(WidgetTester tester) =>
      tester.widget<EditableText>(name).focusNode.hasFocus;

  bool anyFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((field) => field.focusNode.hasFocus);

  testWidgets('el único input (Nombre) declara "listo" y cierra el teclado',
      (tester) async {
    await pumpForm(tester);

    expect(
      tester.widget<EditableText>(name).textInputAction,
      TextInputAction.done,
    );

    await tester.enterText(name, 'Mercado');
    await tester.pump();
    expect(hasFocus(tester), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      anyFieldFocused(tester),
      isFalse,
      reason: '"listo" cierra el teclado',
    );
  });

  testWidgets('tocar el selector de apariencia deja el foco en nada',
      (tester) async {
    await pumpForm(tester);

    await tester.enterText(name, 'Mercado');
    await tester.pump();
    expect(hasFocus(tester), isTrue);

    await tester.tap(find.byType(AppearanceField));
    await tester.pumpAndSettle();

    expect(
      anyFieldFocused(tester),
      isFalse,
      reason: 'tocar el selector de apariencia cierra el teclado antes de '
          'abrir la hoja',
    );
  });
}

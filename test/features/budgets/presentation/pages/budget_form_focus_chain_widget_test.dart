import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_amount_field.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_icon_button.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_name_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetFormCubit extends MockCubit<BudgetFormState>
    implements BudgetFormCubit {}

/// The keyboard "siguiente"/"listo" chain in the crear/editar budget form: the
/// two system-keyboard text inputs (name → amount) are wired so "siguiente"
/// moves focus to the amount, and "listo" on the amount dismisses the keyboard.
/// Tapping a selector unfocuses first so the keyboard does not reopen.
void main() {
  late MockBudgetFormCubit cubit;

  setUp(() {
    cubit = MockBudgetFormCubit();
    when(() => cubit.nameChanged(any())).thenReturn(null);
    when(() => cubit.amountChanged(any())).thenReturn(null);
  });

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    when(() => cubit.state).thenReturn(
      BudgetFormState(
        status: BudgetFormStatus.ready,
        startDate: DateTime(2025, 7, 21),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<BudgetFormCubit>.value(
          value: cubit,
          child: const BudgetFormPage(),
        ),
      ),
    );
  }

  Finder editableOf(Type fieldType) => find.descendant(
        of: find.byType(fieldType),
        matching: find.byType(EditableText),
      );

  final Finder name = editableOf(BudgetNameField);
  final Finder amount = editableOf(BudgetAmountField);

  bool hasFocus(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).focusNode.hasFocus;

  TextInputAction? actionOf(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).textInputAction;

  bool anyFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((field) => field.focusNode.hasFocus);

  testWidgets(
      '"siguiente" encadena Nombre → Monto y "listo" en Monto cierra el '
      'teclado', (tester) async {
    await pumpForm(tester);

    // The declared keyboard actions: the name says "siguiente" (next), the
    // amount (last text field) says "listo" (done).
    expect(actionOf(tester, name), TextInputAction.next);
    expect(actionOf(tester, amount), TextInputAction.done);

    // Focus the name by typing into it, then press "siguiente".
    await tester.enterText(name, 'Mercado');
    await tester.pump();
    expect(hasFocus(tester, name), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, amount), isTrue, reason: 'Nombre → Monto');
    expect(hasFocus(tester, name), isFalse);

    // "listo" on the amount dismisses the keyboard: no text field keeps focus.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      anyFieldFocused(tester),
      isFalse,
      reason: '"listo" en el último campo cierra el teclado',
    );
  });

  testWidgets('tocar un selector deja el foco en nada', (tester) async {
    await pumpForm(tester);

    await tester.enterText(name, 'Mercado');
    await tester.pump();
    expect(hasFocus(tester, name), isTrue);

    await tester.tap(find.byType(BudgetIconButton));
    await tester.pumpAndSettle();

    expect(
      anyFieldFocused(tester),
      isFalse,
      reason: 'tocar el selector de ícono cierra el teclado antes de abrir '
          'la hoja',
    );
  });
}

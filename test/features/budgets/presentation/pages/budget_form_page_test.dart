import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/keyboard_done_toolbar.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_form_bottom_bar.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_icon_button.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_name_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetFormCubit extends MockCubit<BudgetFormState>
    implements BudgetFormCubit {}

void main() {
  late MockBudgetFormCubit cubit;

  setUp(() {
    cubit = MockBudgetFormCubit();
  });

  Future<void> pumpForm(WidgetTester tester, BudgetFormState state) async {
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
        home: BlocProvider<BudgetFormCubit>.value(
          value: cubit,
          child: const BudgetFormPage(),
        ),
      ),
    );
  }

  BudgetFormState ready({Failure? failure}) => BudgetFormState(
        status: BudgetFormStatus.ready,
        startDate: DateTime(2025, 7, 21),
        failure: failure,
      );

  group('CTA siempre activa (no un botón gris que no hace nada)', () {
    testWidgets('un formulario vacío deja la CTA activa', (tester) async {
      await pumpForm(tester, ready());

      final bottomBar = tester.widget<BudgetFormBottomBar>(
        find.byType(BudgetFormBottomBar),
      );
      expect(bottomBar.onPressed, isNotNull);
    });

    testWidgets('mientras guarda, la CTA se deshabilita', (tester) async {
      await pumpForm(
        tester,
        BudgetFormState(
          status: BudgetFormStatus.ready,
          startDate: DateTime(2025, 7, 21),
          submitting: true,
        ),
      );

      final bottomBar = tester.widget<BudgetFormBottomBar>(
        find.byType(BudgetFormBottomBar),
      );
      expect(bottomBar.onPressed, isNull);
    });

    testWidgets('tocar la CTA en un formulario inválido llama submit',
        (tester) async {
      when(() => cubit.submit()).thenAnswer((_) async {});
      await pumpForm(tester, ready());

      await tester.tap(find.byType(BudgetFormBottomBar));
      await tester.pump();

      verify(() => cubit.submit()).called(1);
    });
  });

  group('feedback de validación visible', () {
    testWidgets('nombre vacío muestra el error de nombre', (tester) async {
      await pumpForm(
        tester,
        ready(
          failure: const ValidationFailure(
            'name required',
            field: BudgetDraft.fieldName,
          ),
        ),
      );

      expect(
        find.text('Escribe un nombre para el presupuesto.'),
        findsOneWidget,
      );
    });

    testWidgets('monto en cero muestra el error de monto', (tester) async {
      await pumpForm(
        tester,
        ready(
          failure: const ValidationFailure(
            'amount required',
            field: BudgetDraft.fieldAmount,
          ),
        ),
      );

      expect(find.text('Ingresa un monto mayor a cero.'), findsOneWidget);
    });

    testWidgets('sin fallas, ningún mensaje de error se muestra',
        (tester) async {
      await pumpForm(tester, ready());

      expect(
        find.text('Escribe un nombre para el presupuesto.'),
        findsNothing,
      );
      expect(find.text('Ingresa un monto mayor a cero.'), findsNothing);
    });
  });

  group('alineación ícono + nombre en estado de error (item 15a)', () {
    testWidgets(
        'el ícono queda anclado al tope de la caja del nombre, no descentrado '
        'por el texto de error', (tester) async {
      await pumpForm(
        tester,
        ready(
          failure: const ValidationFailure(
            'name required',
            field: BudgetDraft.fieldName,
          ),
        ),
      );

      // The row that holds the icon must top-align its children, so the error
      // text growing the name column can't shove the icon off the box top.
      final row = tester.widget<Row>(
        find.ancestor(
          of: find.byType(BudgetIconButton),
          matching: find.byType(Row),
        ),
      );
      expect(row.crossAxisAlignment, CrossAxisAlignment.start);

      // And it actually reads as aligned: the icon top matches the name box
      // top even with the error text present below it.
      // BudgetNameField is a top-aligned Column whose first child is the box,
      // so its top-left is the box top.
      final iconTop = tester.getTopLeft(find.byType(BudgetIconButton)).dy;
      final boxTop = tester.getTopLeft(find.byType(BudgetNameField)).dy;
      expect(iconTop, moreOrLessEquals(boxTop, epsilon: 0.5));
    });
  });

  group('toolbar "Listo" del teclado numérico (item 9b)', () {
    testWidgets(
        'en iOS, enfocar el monto muestra "Listo" y tocarlo baja '
        'el teclado', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await pumpForm(tester, ready());

        expect(find.text('Listo'), findsNothing);

        // The amount field is the input wrapped in the accessory (the name
        // field is a plain single-line input and is not); focusing it must
        // surface "Listo".
        final amountField = find.descendant(
          of: find.byType(KeyboardDoneToolbar),
          matching: find.byType(TextField),
        );
        await tester.tap(amountField);
        await tester.pump();
        expect(find.text('Listo'), findsOneWidget);

        await tester.tap(find.text('Listo'));
        await tester.pump();
        expect(find.text('Listo'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}

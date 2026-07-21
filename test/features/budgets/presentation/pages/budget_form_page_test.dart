import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_form_page.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_form_bottom_bar.dart';
import 'package:bloc_test/bloc_test.dart';
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
}

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_tag_picker_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_date_field.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledPaymentFormCubit extends MockCubit<ScheduledPaymentFormState>
    implements ScheduledPaymentFormCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockScheduledPaymentTagPickerCubit
    extends MockCubit<ScheduledPaymentTagPickerState>
    implements ScheduledPaymentTagPickerCubit {}

/// Keyboard-UX guard (device bug): Nota is the form's only system-keyboard text
/// field, so its action is "listo" (`TextInputAction.done`); and tapping any
/// selector drops the system focus so the keyboard does not spring back when a
/// picker sheet closes.
void main() {
  late MockScheduledPaymentFormCubit cubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockScheduledPaymentTagPickerCubit tagPickerCubit;

  setUpAll(() {
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    cubit = MockScheduledPaymentFormCubit();

    categoryQuickPickerCubit = MockCategoryQuickPickerCubit();
    when(
      () => categoryQuickPickerCubit.start(
        kind: any(named: 'kind'),
        selectedId: any(named: 'selectedId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.setAccount(any()))
        .thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.state).thenReturn(
      const CategoryQuickPickerState(status: CategoryQuickPickerStatus.ready),
    );

    tagPickerCubit = MockScheduledPaymentTagPickerCubit();
    when(() => tagPickerCubit.start(any())).thenAnswer((_) async {});
    when(() => tagPickerCubit.state)
        .thenReturn(ScheduledPaymentTagPickerState());

    getIt
      ..registerFactory<CategoryQuickPickerCubit>(
          () => categoryQuickPickerCubit)
      ..registerFactory<ScheduledPaymentTagPickerCubit>(() => tagPickerCubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpForm(
    WidgetTester tester,
    ScheduledPaymentFormState state,
  ) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<ScheduledPaymentFormState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<ScheduledPaymentFormCubit>.value(
          value: cubit,
          child: const ScheduledPaymentFormPage(),
        ),
      ),
    );
  }

  bool anyTextFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((editable) => editable.focusNode.hasFocus);

  // The note is the form's single free-text TextFormField (the amount is the
  // anchored keypad); it renders exactly one TextField.
  Finder noteField() => find.byType(TextField);

  testWidgets('Nota (único campo del sistema) usa la acción "listo"',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    final field = tester.widget<TextField>(noteField());
    expect(field.textInputAction, TextInputAction.done);
  });

  testWidgets(
      'tocar el selector de Primer pago cierra el teclado: ningún campo de '
      'texto queda enfocado al cerrarse el picker', (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    await tester.enterText(noteField(), 'Renta de julio, apartamento');
    await tester.pump();
    expect(
      anyTextFieldFocused(tester),
      isTrue,
      reason: 'precondition: Nota must hold focus (keyboard up)',
    );

    // The first ScheduledPaymentDateField is "Primer pago"; the selector defers
    // opening by one tick (it unfocuses first), so settle open and closed.
    await tester.tap(find.byType(ScheduledPaymentDateField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(
      anyTextFieldFocused(tester),
      isFalse,
      reason: 'the keyboard must not reappear after the date picker closes',
    );
  });

  testWidgets('tocar un radio de Modo cierra el teclado del sistema',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    await tester.enterText(noteField(), 'Nota larga de prueba');
    await tester.pump();
    expect(anyTextFieldFocused(tester), isTrue);

    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    expect(anyTextFieldFocused(tester), isFalse);
  });
}

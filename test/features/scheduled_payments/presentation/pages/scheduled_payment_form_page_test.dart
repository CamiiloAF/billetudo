import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_tag_picker_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_mode_radio_card.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_header_button.dart';
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

void main() {
  late MockScheduledPaymentFormCubit cubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockScheduledPaymentTagPickerCubit tagPickerCubit;

  setUpAll(() {
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    cubit = MockScheduledPaymentFormCubit();

    // Both `CategoryQuickPicker` and `ScheduledPaymentTagsField` resolve
    // their own cubit through `getIt` and start loading as soon as they
    // build (see their doc comments), so the container needs them
    // registered for the form to render at all — same pattern as
    // `transaction_form_page_test.dart`.
    categoryQuickPickerCubit = MockCategoryQuickPickerCubit();
    when(
      () => categoryQuickPickerCubit.start(
        kind: any(named: 'kind'),
        selectedId: any(named: 'selectedId'),
      ),
    ).thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.state).thenReturn(
      const CategoryQuickPickerState(status: CategoryQuickPickerStatus.ready),
    );

    tagPickerCubit = MockScheduledPaymentTagPickerCubit();
    when(() => tagPickerCubit.start(any())).thenAnswer((_) async {});
    when(() => tagPickerCubit.state)
        .thenReturn(ScheduledPaymentTagPickerState());

    getIt
      ..registerFactory<CategoryQuickPickerCubit>(() => categoryQuickPickerCubit)
      ..registerFactory<ScheduledPaymentTagPickerCubit>(() => tagPickerCubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpForm(
    WidgetTester tester,
    ScheduledPaymentFormState state, {
    Brightness brightness = Brightness.light,
  }) async {
    // The form is a long ListView (type/account/category/amount/frequency/
    // mode/note/tags/delete link); a tall viewport keeps everything on
    // screen without needing per-test scrolling.
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<ScheduledPaymentFormState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
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

  testWidgets('smoke: crear plantilla renderiza sin crashear, título "Nuevo"',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    expect(find.text('Nuevo pago programado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke: editar plantilla muestra el Delete Link', (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        id: 'sp-1',
        accountId: 'acc-1',
        accountName: 'Bancolombia',
      ),
    );

    expect(find.text('Editar pago programado'), findsOneWidget);
    expect(find.text('Eliminar pago programado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crear plantilla NO muestra el Delete Link (nada que borrar aún)',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    expect(find.text('Eliminar pago programado'), findsNothing);
  });

  testWidgets(
      'cambiar de modo automático a manual llama requiresConfirmationChanged(true)',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    // Both radio cards are always visible; automatic starts selected.
    expect(find.byType(ScheduledPaymentModeRadioCard), findsNWidgets(2));

    await tester.tap(find.text('Manual'));
    await tester.pump();

    verify(() => cubit.requiresConfirmationChanged(true)).called(1);
  });

  testWidgets('cambiar de modo manual a automático llama requiresConfirmationChanged(false)',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        requiresConfirmation: true,
      ),
    );

    await tester.tap(find.text('Automático'));
    await tester.pump();

    verify(() => cubit.requiresConfirmationChanged(false)).called(1);
  });

  testWidgets('una transferencia oculta la sección de Etiquetas (criterio 16)',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        type: ScheduledPaymentType.transfer,
      ),
    );

    expect(find.text('Etiquetas'), findsNothing);
  });

  testWidgets('un gasto (no transferencia) SÍ muestra la sección de Etiquetas',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
    );

    expect(find.text('Etiquetas'), findsOneWidget);
  });

  testWidgets(
      'tema oscuro: los botones x/check del header resuelven AppColors.dark, no los de light',
      (tester) async {
    await pumpForm(
      tester,
      ScheduledPaymentFormState(status: ScheduledPaymentFormStatus.ready),
      brightness: Brightness.dark,
    );

    final buttons = tester.widgetList<TransactionHeaderButton>(
      find.byType(TransactionHeaderButton),
    );
    expect(buttons, hasLength(2));

    final cancelButton =
        buttons.firstWhere((button) => button.tooltip == 'Cancelar');
    expect(cancelButton.background, AppColors.dark.muted);
    expect(cancelButton.background, isNot(AppColors.light.muted));
    expect(cancelButton.foreground, AppColors.dark.textPrimary);
    expect(cancelButton.foreground, isNot(AppColors.light.textPrimary));

    final saveButton = buttons.firstWhere((button) => button.tooltip == 'Guardar');
    expect(saveButton.background, AppColors.dark.primary);
    expect(saveButton.background, isNot(AppColors.light.primary));
    expect(saveButton.foreground, AppColors.dark.onPrimary);
  });
}

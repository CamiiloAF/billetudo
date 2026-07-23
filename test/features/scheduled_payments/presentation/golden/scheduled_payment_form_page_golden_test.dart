import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/tag.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_tag_picker_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockScheduledPaymentFormCubit extends MockCubit<ScheduledPaymentFormState>
    implements ScheduledPaymentFormCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockScheduledPaymentTagPickerCubit
    extends MockCubit<ScheduledPaymentTagPickerState>
    implements ScheduledPaymentTagPickerCubit {}

/// The create/edit template form (HU-01/HU-05): once vs. repeating
/// (interval/endDate collapse away), the two always-visible mode radio
/// cards, and a transfer that drops category/tags entirely (criterion 16).
///
/// Pencil rows: `create_expense_automatic`/`create_manual_mode`/
/// `create_transfer`/`edit_expense` → `J0DSIm` (formulario repetible) ·
/// `create_income_once` → `jJhpW` (formulario de pago único, con el
/// companion `once`).
/// `CategoryQuickPicker`/`ScheduledPaymentTagsField` resolve their own cubit
/// through `getIt` as soon as they build (see `scheduled_payment_form_page_test.dart`),
/// so both are registered here even though this suite never taps them.
void main() {
  late MockScheduledPaymentFormCubit cubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockScheduledPaymentTagPickerCubit tagPickerCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
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
    when(() => tagPickerCubit.state).thenReturn(
      ScheduledPaymentTagPickerState(
        status: ScheduledPaymentTagPickerStatus.ready,
        tags: [
          Tag(
            id: 't-1',
            name: 'Hogar',
            createdAt: DateTime(2026, 7, 15),
            updatedAt: DateTime(2026, 7, 15).millisecondsSinceEpoch,
          ),
        ],
      ),
    );

    getIt
      ..registerFactory<CategoryQuickPickerCubit>(
          () => categoryQuickPickerCubit)
      ..registerFactory<ScheduledPaymentTagPickerCubit>(() => tagPickerCubit);
  });

  tearDown(getIt.reset);

  Future<void> golden(
    WidgetTester tester,
    ScheduledPaymentFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<ScheduledPaymentFormState>.empty());
    await pumpGolden(
      tester,
      BlocProvider<ScheduledPaymentFormCubit>.value(
        value: cubit,
        child: const ScheduledPaymentFormPage(),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1700),
    );
    await expectLater(
      find.byType(ScheduledPaymentFormPage),
      matchesGoldenFile('goldens/scheduled_payment_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('crear, gasto, modo automático ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-1',
          categoryKind: CategoryKind.expense,
          categoryName: 'Suscripciones',
          amountText: '10000',
        ),
        'create_expense_automatic_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear, ingreso, pago único ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          type: ScheduledPaymentType.income,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-2',
          categoryKind: CategoryKind.income,
          categoryName: 'Salario',
          amountText: '250000',
          frequency: ScheduledPaymentFrequency.once,
        ),
        'create_income_once_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear, transferencia: sin categoría ni etiquetas ($suffix)',
        (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          type: ScheduledPaymentType.transfer,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          transferAccountId: 'acc-2',
          transferAccountName: 'Nequi',
          amountText: '50000',
        ),
        'create_transfer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('crear, modo manual seleccionado ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-1',
          categoryKind: CategoryKind.expense,
          categoryName: 'Suscripciones',
          amountText: '10000',
          requiresConfirmation: true,
        ),
        'create_manual_mode_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'editar plantilla: título "Editar" y Delete Link visible ($suffix)',
        (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          id: 'sp-1',
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-1',
          categoryKind: CategoryKind.expense,
          categoryName: 'Suscripciones',
          amountText: '10000',
          note: 'Netflix + Spotify',
          tagIds: const {'t-1'},
        ),
        'edit_expense_$suffix',
        brightness: brightness,
      );
    });

    // Deudas HU-03, "Configurar cuota" (`s9gXs`): the same form driven with a
    // `debtId` → the type segmented control is hidden, the header carries the
    // "Crédito vehicular · Yo debo" context subtitle, and the cross-link
    // installment banner shows below the mode cards.
    testWidgets('config de cuota de deuda, crear ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          debtId: 'd1',
          debtName: 'Crédito vehicular',
          debtIsIOwe: true,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-1',
          categoryKind: CategoryKind.expense,
          categoryName: 'Cuota crédito',
          amountText: '680000',
        ),
        'installment_create_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('config de cuota de deuda, editar ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentFormState(
          status: ScheduledPaymentFormStatus.ready,
          id: 'sp-9',
          debtId: 'd1',
          debtName: 'Crédito vehicular',
          debtIsIOwe: true,
          accountId: 'acc-1',
          accountName: 'Bancolombia',
          categoryId: 'cat-1',
          categoryKind: CategoryKind.expense,
          categoryName: 'Cuota crédito',
          amountText: '680000',
        ),
        'installment_edit_$suffix',
        brightness: brightness,
      );
    });
  }
}

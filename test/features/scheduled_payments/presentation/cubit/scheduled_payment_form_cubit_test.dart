import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockCreateScheduledPayment createScheduledPayment;
  late MockUpdateScheduledPayment updateScheduledPayment;
  late MockGetScheduledPaymentDetail getScheduledPaymentDetail;
  late MockSetScheduledPaymentTags setScheduledPaymentTags;
  late MockDeleteScheduledPayment deleteScheduledPayment;

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    createScheduledPayment = MockCreateScheduledPayment();
    updateScheduledPayment = MockUpdateScheduledPayment();
    getScheduledPaymentDetail = MockGetScheduledPaymentDetail();
    setScheduledPaymentTags = MockSetScheduledPaymentTags();
    deleteScheduledPayment = MockDeleteScheduledPayment();
  });

  ScheduledPaymentFormCubit build() => ScheduledPaymentFormCubit(
        createScheduledPayment,
        updateScheduledPayment,
        getScheduledPaymentDetail,
        setScheduledPaymentTags,
        deleteScheduledPayment,
      );

  group('HU-01: crear plantilla', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'submit valida, crea la plantilla y guarda sus etiquetas',
      setUp: () {
        when(() => createScheduledPayment(any()))
            .thenAnswer((_) async => Right(buildScheduledPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.accountSelected('acc-1', 'Bancolombia');
        cubit.amountTextChanged('100');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
        verify(() => createScheduledPayment(any())).called(1);
        verify(() => setScheduledPaymentTags(any(), any())).called(1);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'sin cuenta, submit falla sin llamar el caso de uso',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        verifyNever(() => createScheduledPayment(any()));
      },
    );
  });

  group('HU-05: eliminar plantilla desde el formulario', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'delete tombstona la plantilla y emite status=deleted',
      setUp: () {
        when(() => deleteScheduledPayment('sp-1'))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        id: 'sp-1',
      ),
      act: (cubit) => cubit.delete(),
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.deleted);
        verify(() => deleteScheduledPayment('sp-1')).called(1);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'sin plantilla cargada (creación), delete no llama el caso de uso',
      build: build,
      act: (cubit) => cubit.delete(),
      verify: (cubit) {
        verifyNever(() => deleteScheduledPayment(any()));
      },
    );
  });

  group('criterion 16: transferencia no admite categoría ni etiquetas', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'elegir tipo transferencia limpia categoría y etiquetas seleccionadas',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.categorySelected('cat-1', null, 'Arriendo');
        cubit.tagsChanged({'tag-1'});
        cubit.typeSelected(ScheduledPaymentType.transfer);
      },
      verify: (cubit) {
        expect(cubit.state.categoryId, isNull);
        expect(cubit.state.tagIds, isEmpty);
        expect(cubit.state.isTransfer, isTrue);
      },
    );
  });

  group('Fix: "Primer pago" no cambia solo (firstPaymentDate vs. nextDate)',
      () {
    // The cursor has already advanced past the immutable first payment date
    // — the exact drift the fix must not surface in the form.
    final firstPaymentDate = DateTime(2026, 1, 15);
    final advancedCursor = DateTime(2026, 4, 15);

    ScheduledPayment loadedPayment() => buildScheduledPayment(
          id: 'sp-1',
          firstPaymentDate: firstPaymentDate,
          nextDate: advancedCursor,
        );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'load() puebla el campo mostrado con firstPaymentDate, no con nextDate',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load('sp-1'),
      verify: (cubit) {
        expect(cubit.state.nextDate, firstPaymentDate);
        expect(cubit.state.originalNextDate, advancedCursor);
        expect(cubit.state.nextDateEdited, isFalse);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'guardar sin tocar la fecha preserva el cursor original, no lo resetea',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
        when(() => updateScheduledPayment(any()))
            .thenAnswer((_) async => Right(loadedPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('sp-1');
        // No nextDateChanged() call: the user never touched the date field.
        await cubit.submit();
      },
      verify: (cubit) {
        final captured =
            verify(() => updateScheduledPayment(captureAny())).captured;
        final draft = captured.single as ScheduledPaymentDraft;
        expect(draft.nextDate, advancedCursor);
        expect(draft.nextDate, isNot(firstPaymentDate));
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'editar explícitamente la fecha y guardar usa el valor editado',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
        when(() => updateScheduledPayment(any()))
            .thenAnswer((_) async => Right(loadedPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('sp-1');
        cubit.nextDateChanged(DateTime(2026, 6));
        await cubit.submit();
      },
      verify: (cubit) {
        final captured =
            verify(() => updateScheduledPayment(captureAny())).captured;
        final draft = captured.single as ScheduledPaymentDraft;
        expect(draft.nextDate, DateTime(2026, 6));
      },
    );
  });

  group('HU-06/criterion 14: puente desde Transacciones', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'loadFromBridge prellena cuenta/monto/categoría/nota y frequency=once',
      build: build,
      act: (cubit) => cubit.loadFromBridge(
        accountId: 'acc-1',
        accountName: 'Bancolombia',
        amountMinor: 50000,
        currency: 'COP',
        type: ScheduledPaymentType.expense,
        nextDate: DateTime(2026, 8, 1),
        categoryId: 'cat-1',
        categoryName: 'Arriendo',
        note: 'Arriendo de agosto',
        tagIds: {'tag-1'},
      ),
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.frequency, ScheduledPaymentFrequency.once);
        expect(cubit.state.nextDate, DateTime(2026, 8, 1));
        expect(cubit.state.categoryId, 'cat-1');
        expect(cubit.state.note, 'Arriendo de agosto');
        expect(cubit.state.tagIds, {'tag-1'});
        expect(cubit.state.status, ScheduledPaymentFormStatus.ready);
      },
    );
  });
}

import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/tag.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_detail_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart' as tx;
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

class MockScheduledPaymentDetailCubit
    extends MockCubit<ScheduledPaymentDetailState>
    implements ScheduledPaymentDetailCubit {}

/// The hybrid "próximo pago + configuración" detail (HU-05): active/manual
/// with a pending occurrence badge, active/automatic, inactive (tombstoned)
/// and transfer variants, each with a bit of generation history so the
/// history rows render too.
void main() {
  late MockScheduledPaymentDetailCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockScheduledPaymentDetailCubit());

  // `ScheduledDueInChip` compares `nextDate` against `DateTime.now()` at
  // render time, so a fixture date built relative to "today" keeps the "en N
  // días" text stable across days instead of drifting with a hardcoded date.
  DateTime inDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  final history = [
    tx.Transaction(
      id: 'tx-1',
      accountId: 'acc-1',
      amountMinor: 10000,
      currency: 'COP',
      type: tx.TransactionType.expense,
      date: DateTime(2026, 6, 15),
      source: tx.TransactionSource.scheduled,
      createdAt: testInstant,
      updatedAt: testInstantMillis,
      scheduledPaymentId: 'sp-1',
    ),
    tx.Transaction(
      id: 'tx-2',
      accountId: 'acc-1',
      amountMinor: 10000,
      currency: 'COP',
      type: tx.TransactionType.expense,
      date: DateTime(2026, 5, 15),
      source: tx.TransactionSource.scheduled,
      createdAt: testInstant,
      updatedAt: testInstantMillis,
      scheduledPaymentId: 'sp-1',
    ),
  ];

  ScheduledPaymentDetail buildDetail({
    ScheduledPaymentType type = ScheduledPaymentType.expense,
    bool requiresConfirmation = false,
    bool isDeleted = false,
    bool withPending = false,
    List<Tag> tags = const [],
    List<tx.Transaction> historyRows = const [],
  }) =>
      ScheduledPaymentDetail(
        scheduledPayment: buildScheduledPayment(
          type: type,
          transferAccountId: type == ScheduledPaymentType.transfer ? 'acc-2' : null,
          requiresConfirmation: requiresConfirmation,
          nextDate: inDays(5),
          tombstonedAt: isDeleted ? DateTime(2026, 8) : null,
          endDate: inDays(200),
        ),
        accountName: 'Bancolombia',
        transferAccountName: type == ScheduledPaymentType.transfer ? 'Nequi' : null,
        categoryName: type == ScheduledPaymentType.transfer ? null : 'Suscripciones',
        categoryIcon: type == ScheduledPaymentType.transfer ? null : 'wifi',
        categoryColor: type == ScheduledPaymentType.transfer ? null : 'indigo',
        tags: tags,
        historyTotalCount: historyRows.length,
        history: historyRows,
        pendingOccurrence: withPending
            ? buildPendingOccurrence(
                scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
                categoryName: 'Suscripciones',
                categoryIcon: 'wifi',
                categoryColor: 'indigo',
              )
            : null,
      );

  Future<void> golden(
    WidgetTester tester,
    ScheduledPaymentDetailState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ScheduledPaymentDetailCubit>.value(
        value: cubit,
        child: ScheduledPaymentDetailPage(onEdit: (_) {}, onOpenTransaction: (_) {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1300),
      settle: settle,
    );
    await expectLater(
      find.byType(ScheduledPaymentDetailPage),
      matchesGoldenFile('goldens/scheduled_payment_detail_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledPaymentDetailState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('active, automatic mode, with history ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(historyRows: history),
          history: history,
        ),
        'active_automatic_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('active, manual mode, pending occurrence badge ($suffix)',
        (tester) async {
      await golden(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(
            requiresConfirmation: true,
            withPending: true,
            tags: [
              Tag(id: 't-1', name: 'Hogar', createdAt: testInstant, updatedAt: testInstantMillis),
            ],
          ),
        ),
        'active_manual_pending_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('inactive (tombstoned) ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(isDeleted: true),
        ),
        'inactive_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('transfer, no category/tags row ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentDetailState(
          status: ScheduledPaymentDetailStatus.ready,
          detail: buildDetail(type: ScheduledPaymentType.transfer),
        ),
        'transfer_$suffix',
        brightness: brightness,
      );
    });
  }
}

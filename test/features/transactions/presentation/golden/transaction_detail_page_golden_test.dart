import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_detail_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../transaction_fixtures.dart';

class MockTransactionDetailCubit extends MockCubit<TransactionDetailState>
    implements TransactionDetailCubit {}

void main() {
  late MockTransactionDetailCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockTransactionDetailCubit());

  Future<void> golden(
    WidgetTester tester,
    TransactionDetailState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<TransactionDetailCubit>.value(
        value: cubit,
        child: TransactionDetailPage(onEdit: (_) {}),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1100),
      settle: settle,
    );
    await expectLater(
      find.byType(TransactionDetailPage),
      matchesGoldenFile('goldens/transaction_detail_page_$name.png'),
    );
  }

  TransactionDetailState readyState(TransactionWithDetails entry) =>
      TransactionDetailState(
        status: TransactionDetailStatus.ready,
        entry: entry,
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const TransactionDetailState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const TransactionDetailState(status: TransactionDetailStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('expense, with note and tags ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(
          TransactionWithDetails(
            transaction: buildTransaction(
              amountMinor: 4500000,
              note: 'Almuerzo con el equipo',
            ),
            accountName: 'Efectivo',
            categoryName: 'Comida',
            categoryIcon: 'utensils',
            categoryColor: 'coral',
            tags: [buildTag(), buildTag(id: 'tag-2', name: 'trabajo')],
          ),
        ),
        'expense_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('expense, no note and no tags ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(
          TransactionWithDetails(
            transaction: buildTransaction(amountMinor: 1500000),
            accountName: 'Efectivo',
            categoryName: 'Transporte',
            categoryIcon: 'car',
            categoryColor: 'sky',
          ),
        ),
        'expense_minimal_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('income ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(
          TransactionWithDetails(
            transaction: buildTransaction(
              type: TransactionType.income,
              amountMinor: 350000000,
            ),
            accountName: 'Bancolombia',
            categoryName: 'Salario',
            categoryIcon: 'briefcase',
            categoryColor: 'mint',
          ),
        ),
        'income_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('transfer, origin and destination account ($suffix)',
        (tester) async {
      await golden(
        tester,
        readyState(
          TransactionWithDetails(
            transaction: buildTransaction(
              type: TransactionType.transfer,
              transferAccountId: 'acc-2',
              amountMinor: 10000000,
            ),
            accountName: 'Efectivo',
            transferAccountName: 'Bancolombia',
          ),
        ),
        'transfer_$suffix',
        brightness: brightness,
      );
    });
  }
}

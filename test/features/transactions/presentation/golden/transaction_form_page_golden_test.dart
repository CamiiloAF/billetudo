import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockTransactionFormCubit extends MockCubit<TransactionFormState>
    implements TransactionFormCubit {}

class MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

class MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

final DateTime _instant = DateTime(2026, 7, 15);
final int _instantMillis = _instant.millisecondsSinceEpoch;

Account _buildAccount({String id = 'acc-1', String name = 'Efectivo'}) =>
    Account(
      id: id,
      name: name,
      type: AccountType.cash,
      currency: 'COP',
      initialBalanceMinor: 0,
      archived: false,
      sortOrder: 0,
      createdAt: _instant,
      updatedAt: _instantMillis,
    );

AccountWithBalance _buildAccountWithBalance({
  String id = 'acc-1',
  String name = 'Efectivo',
}) {
  final account = _buildAccount(id: id, name: name);
  return AccountWithBalance(
    account: account,
    balance:
        AccountBalance.fromMovements(account: account, movements: const []),
  );
}

Category _buildCategory({
  String id = 'cat-1',
  String name = 'Comida',
  CategoryKind kind = CategoryKind.expense,
}) =>
    Category(
      id: id,
      name: name,
      kind: kind,
      sortOrder: 0,
      createdAt: _instant,
      updatedAt: _instantMillis,
    );

void main() {
  late MockTransactionFormCubit cubit;
  late MockAccountsListCubit accountsListCubit;
  late MockCategoriesListCubit categoriesListCubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockTagFilterCubit tagFilterCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    cubit = MockTransactionFormCubit();

    accountsListCubit = MockAccountsListCubit();
    when(() => accountsListCubit.start()).thenAnswer((_) async {});
    when(() => accountsListCubit.state).thenReturn(
      AccountsListState(
        status: AccountsListStatus.ready,
        accounts: [
          _buildAccountWithBalance(),
          _buildAccountWithBalance(id: 'acc-2', name: 'Bancolombia'),
        ],
      ),
    );

    categoriesListCubit = MockCategoriesListCubit();
    when(() => categoriesListCubit.start(kind: any(named: 'kind')))
        .thenAnswer((_) async {});
    when(() => categoriesListCubit.state).thenReturn(
      CategoriesListState(
        status: CategoriesListStatus.ready,
        nodes: [CategoryNode(root: _buildCategory())],
      ),
    );

    // The account/category picker sheets and the Etiquetas field resolve
    // their own cubits through `getIt` (they compose other features'
    // presentation layers, or a sub-cubit not owned by this page), so the DI
    // container needs these registered for the form to build at all — same
    // setup as `transaction_form_page_test.dart`.
    categoryQuickPickerCubit = MockCategoryQuickPickerCubit();
    when(
      () => categoryQuickPickerCubit.start(
        kind: any(named: 'kind'),
        selectedId: any(named: 'selectedId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => categoryQuickPickerCubit.setKind(
        any(),
        selectedId: any(named: 'selectedId'),
      ),
    ).thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.syncSelection(any()))
        .thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.state).thenReturn(
      const CategoryQuickPickerState(status: CategoryQuickPickerStatus.ready),
    );

    tagFilterCubit = MockTagFilterCubit();
    when(() => tagFilterCubit.start(any())).thenAnswer((_) async {});
    when(() => tagFilterCubit.state).thenReturn(TagFilterState());

    getIt
      ..registerFactory<AccountsListCubit>(() => accountsListCubit)
      ..registerFactory<CategoriesListCubit>(() => categoriesListCubit)
      ..registerFactory<CategoryQuickPickerCubit>(
        () => categoryQuickPickerCubit,
      )
      ..registerFactory<TagFilterCubit>(() => tagFilterCubit);
  });

  tearDown(getIt.reset);

  Future<void> golden(
    WidgetTester tester,
    TransactionFormState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<TransactionFormCubit>.value(
        value: cubit,
        child: const TransactionFormPage(),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(TransactionFormPage),
      matchesGoldenFile('goldens/transaction_form_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('create expense, empty ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
        'create_expense_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('create income, empty ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: TransactionType.income,
        ),
        'create_income_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('create transfer, empty ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: TransactionType.transfer,
        ),
        'create_transfer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('edit expense, filled ($suffix)', (tester) async {
      await golden(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          id: 'tx-1',
          accountId: 'acc-1',
          accountName: 'Efectivo',
          categoryId: 'cat-1',
          categoryName: 'Comida',
          categoryKind: CategoryKind.expense,
          amountMinor: 4500000,
          note: 'Almuerzo con el equipo',
        ),
        'edit_expense_filled_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('amount field focused, anchored keypad open ($suffix)',
        (tester) async {
      await golden(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          amountMinor: 1250000,
          focusedField: TransactionFormFocusedField.amount,
        ),
        'keypad_open_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('validation errors: account and category ($suffix)',
        (tester) async {
      await golden(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          failure: const ValidationFailure(
            'an account is required',
            field: TransactionDraft.fieldAccountId,
          ),
        ),
        'validation_error_account_$suffix',
        brightness: brightness,
      );
    });

    // The Nota field's active state (`transacciones.md`'s Zona Fija
    // show/hide-by-focus mechanism): `focusedField: note` collapses the
    // amount zone to its narrow bar via `TransactionFormState.isKeypadVisible`
    // (state-driven), but `TransactionNoteField`'s own `$primary` 2px focus
    // ring is owned by its internal `FocusNode`, not by the cubit — so this
    // golden also drives a real `tester.tap` on the field after pumping to
    // capture genuine focus, not just the collapsed zone on its own.
    testWidgets('note field focused, amount zone collapsed ($suffix)',
        (tester) async {
      when(() => cubit.state).thenReturn(
        TransactionFormState(
          status: TransactionFormStatus.ready,
          amountMinor: 4500000,
          note: 'Almuerzo con el equipo',
          focusedField: TransactionFormFocusedField.note,
        ),
      );
      await pumpGolden(
        tester,
        BlocProvider<TransactionFormCubit>.value(
          value: cubit,
          child: const TransactionFormPage(),
        ),
        brightness: brightness,
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(TransactionFormPage),
        matchesGoldenFile('goldens/transaction_form_page_note_active_$suffix.png'),
      );
    });
  }
}

import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
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
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionFormCubit extends MockCubit<TransactionFormState>
    implements TransactionFormCubit {}

class MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

class MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

final DateTime _instant = DateTime(2026, 7, 15);
final int _instantMillis = _instant.millisecondsSinceEpoch;

Account _buildAccount({
  String id = 'acc-1',
  String name = 'Efectivo',
}) =>
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

  setUpAll(() {
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
        nodes: [
          CategoryNode(root: _buildCategory()),
        ],
      ),
    );

    // The account/category picker sheets resolve their own cubit through
    // `getIt` (they compose another feature's presentation layer, see
    // `transaction_form_page.dart`), so the DI container needs these
    // registered for the sheets to build at all.
    getIt
      ..registerFactory<AccountsListCubit>(() => accountsListCubit)
      ..registerFactory<CategoriesListCubit>(() => categoriesListCubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpForm(WidgetTester tester, TransactionFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<TransactionFormCubit>.value(
          value: cubit,
          child: const TransactionFormPage(),
        ),
      ),
    );
  }

  group('regresión: el picker muestra el nombre elegido, no el label estático',
      () {
    testWidgets('cuenta sin elegir muestra el label "Cuenta"', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.text('Cuenta'), findsOneWidget);
      expect(find.text('Efectivo'), findsNothing);
    });

    testWidgets(
        'con accountId y accountName en el estado, el botón muestra el '
        'nombre de la cuenta', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Efectivo',
        ),
      );

      expect(find.text('Efectivo'), findsOneWidget);
      // El label estático "Cuenta" ya no debe seguir mostrándose en su lugar.
      expect(find.text('Cuenta'), findsNothing);
    });

    testWidgets(
        'elegir una cuenta en el bottom sheet se lo reporta al cubit con su '
        'nombre', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.text('Cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Bancolombia'), findsOneWidget);

      await tester.tap(find.text('Bancolombia'));
      await tester.pumpAndSettle();

      verify(() => cubit.accountSelected('acc-2', 'Bancolombia')).called(1);
    });

    testWidgets('categoría sin elegir muestra el placeholder "Sin categoría"',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.text('Sin categoría'), findsOneWidget);
      expect(find.text('Comida'), findsNothing);
    });

    testWidgets(
        'con categoryId y categoryName en el estado, el botón muestra el '
        'nombre de la categoría', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          categoryId: 'cat-1',
          categoryName: 'Comida',
          categoryKind: CategoryKind.expense,
        ),
      );

      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Sin categoría'), findsNothing);
    });

    testWidgets(
        'elegir una categoría en el bottom sheet se lo reporta al cubit con '
        'su nombre', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.text('Sin categoría'));
      await tester.pumpAndSettle();
      expect(find.text('Comida'), findsOneWidget);

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      verify(
        () => cubit.categorySelected('cat-1', CategoryKind.expense, 'Comida'),
      ).called(1);
    });
  });

  group('los 3 tipos renderizan los campos correctos', () {
    testWidgets('gasto: cuenta + categoría, sin segunda cuenta',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.byType(AccountPickerField), findsOneWidget);
      expect(find.byType(CategoryPickerField), findsOneWidget);
      expect(find.text('Nuevo gasto'), findsOneWidget);
    });

    testWidgets('ingreso: cuenta + categoría, sin segunda cuenta',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: TransactionType.income,
        ),
      );

      expect(find.byType(AccountPickerField), findsOneWidget);
      expect(find.byType(CategoryPickerField), findsOneWidget);
      expect(find.text('Nuevo ingreso'), findsOneWidget);
    });

    testWidgets('transferencia: dos cuentas (origen y destino), sin categoría',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: TransactionType.transfer,
        ),
      );

      expect(find.byType(AccountPickerField), findsNWidgets(2));
      expect(find.byType(CategoryPickerField), findsNothing);
      expect(find.text('Cuenta destino'), findsOneWidget);
      expect(find.text('Nueva transferencia'), findsOneWidget);
    });
  });

  group('teclado numérico anclado (HU-01/02/03 criterio 11)', () {
    testWidgets('con Monto enfocado, el teclado anclado se muestra',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          focusedField: TransactionFormFocusedField.amount,
        ),
      );

      expect(find.byType(NumericKeypad), findsOneWidget);
    });

    testWidgets('con Nota enfocada, el teclado anclado se oculta',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          focusedField: TransactionFormFocusedField.note,
        ),
      );

      expect(find.byType(NumericKeypad), findsNothing);
    });

    testWidgets('sin ningún campo enfocado, el teclado anclado no aparece',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.byType(NumericKeypad), findsNothing);
    });

    testWidgets('tocar el monto le pide foco de Monto al cubit',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.text('0,00'));
      await tester.pump();

      verify(() => cubit.amountFocused()).called(1);
    });

    testWidgets('tocar Nota le pide foco de Nota al cubit, no de Monto',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      verify(() => cubit.noteFocused()).called(1);
    });
  });
}

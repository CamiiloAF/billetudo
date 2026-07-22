import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
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
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/category_picker/category_quick_picker.dart';
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_amount_fixed_zone.dart';
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

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

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
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockTagFilterCubit tagFilterCubit;

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
    // The Etiquetas section resolves its own `TagFilterCubit` through `getIt`
    // to turn the form's selected tag ids into chip names (see
    // `transaction_tags_field.dart`).
    // The `CategoryQuickPicker` owns its own `CategoryQuickPickerCubit` through
    // `getIt` to load the most-used chips and resolve the selection. By default
    // it is ready with one most-used category ("Comida").
    categoryQuickPickerCubit = MockCategoryQuickPickerCubit();
    when(
      () => categoryQuickPickerCubit.start(
        kind: any(named: 'kind'),
        selectedId: any(named: 'selectedId'),
        accountId: any(named: 'accountId'),
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
    when(() => categoryQuickPickerCubit.setAccount(any()))
        .thenAnswer((_) async {});
    when(() => categoryQuickPickerCubit.state).thenReturn(
      const CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
      ),
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

  Future<void> pumpForm(WidgetTester tester, TransactionFormState state) async {
    // A phone-sized viewport: the anchored keypad's rows are sized by width, so
    // the default 800px-wide test window would blow the amount zone up past the
    // screen. Reset after the test to not leak into others.
    tester.view.physicalSize = const Size(1170, 2532);
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
      // El `Form Field` conserva su label "Cuenta" arriba del valor elegido
      // (patrón de diseño), y muestra el nombre de la cuenta como valor.
      expect(find.text('Cuenta'), findsOneWidget);
    });

    testWidgets(
        'elegir una cuenta en el bottom sheet se lo reporta al cubit con su '
        'nombre', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      // The label "Cuenta" now sits outside the tappable box (design `wOlOA`);
      // the placeholder value is what opens the picker sheet.
      await tester.tap(find.text('Elegir cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Bancolombia'), findsOneWidget);

      await tester.tap(find.text('Bancolombia'));
      await tester.pumpAndSettle();

      verify(() => cubit.accountSelected('acc-2', 'Bancolombia')).called(1);
    });

    testWidgets(
        'el quick picker muestra la etiqueta "Categoría" y el chip "Ver más"',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.byType(CategoryQuickPicker), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Ver más'), findsOneWidget);
    });

    testWidgets('las categorías más usadas se muestran como chips',
        (tester) async {
      when(() => categoryQuickPickerCubit.state).thenReturn(
        CategoryQuickPickerState(
          status: CategoryQuickPickerStatus.ready,
          mostUsed: [_buildCategory()],
        ),
      );
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.text('Comida'), findsOneWidget);
    });

    testWidgets('tocar un chip de categoría se lo reporta al cubit',
        (tester) async {
      when(() => categoryQuickPickerCubit.state).thenReturn(
        CategoryQuickPickerState(
          status: CategoryQuickPickerStatus.ready,
          mostUsed: [_buildCategory()],
        ),
      );
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.text('Comida'));
      await tester.pump();

      verify(
        () => cubit.categorySelected('cat-1', CategoryKind.expense, 'Comida'),
      ).called(1);
    });

    testWidgets(
        'elegir "Ver más" abre el sheet y elegir una categoría lo reporta al '
        'cubit con su nombre', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      await tester.tap(find.text('Ver más'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir categoría'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      verify(
        () => cubit.categorySelected('cat-1', CategoryKind.expense, 'Comida'),
      ).called(1);
    });
  });

  group('quick picker filtrado por cuenta (HU quick-picker-most-used)', () {
    testWidgets('el accountId del estado se propaga al arrancar el picker',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Efectivo',
        ),
      );

      verify(
        () => categoryQuickPickerCubit.start(
          kind: CategoryKind.expense,
          selectedId: null,
          accountId: 'acc-1',
        ),
      ).called(1);
    });

    testWidgets(
        'cambiar de cuenta en el formulario le propaga el nuevo accountId '
        'al picker sin perder la categoría elegida en el widget',
        (tester) async {
      final initial = TransactionFormState(
        status: TransactionFormStatus.ready,
        accountId: 'acc-1',
        accountName: 'Efectivo',
        categoryId: 'cat-1',
      );
      final afterAccountSwitch = initial.copyWith(
        accountId: 'acc-2',
        accountName: 'Bancolombia',
      );
      whenListen(
        cubit,
        Stream<TransactionFormState>.fromIterable([afterAccountSwitch]),
        initialState: initial,
      );
      when(() => categoryQuickPickerCubit.state).thenReturn(
        CategoryQuickPickerState(
          status: CategoryQuickPickerStatus.ready,
          mostUsed: [_buildCategory()],
          selected: _buildCategory(),
        ),
      );
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      // Lets the stream's single emission (the account switch) reach the
      // widget tree.
      await tester.pump();

      verify(() => categoryQuickPickerCubit.setAccount('acc-2')).called(1);
      // The chip for the already-selected category ("Comida") is still
      // shown — the account switch never cleared it.
      expect(find.text('Comida'), findsOneWidget);
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
      expect(find.byType(CategoryQuickPicker), findsOneWidget);
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
      expect(find.byType(CategoryQuickPicker), findsOneWidget);
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
      expect(find.byType(CategoryQuickPicker), findsNothing);
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

      // Resting state shows the collapsed amount bar; tapping it reopens the
      // keypad by asking the cubit for amount focus.
      await tester.tap(find.byType(TransactionAmountCollapsedBar));
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

  group('errores de validación (bug fixes 8 y 11a)', () {
    testWidgets(
        'sin cuenta seleccionada y falla de fieldAccountId, el selector de '
        'cuenta muestra el mensaje de error', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          failure: const ValidationFailure(
            'an account is required',
            field: TransactionDraft.fieldAccountId,
          ),
        ),
      );

      expect(find.text('Elige una cuenta.'), findsOneWidget);
    });

    testWidgets(
        'sin categoría seleccionada y falla de fieldCategoryId, el selector '
        'de categoría muestra el mensaje de error', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Efectivo',
          failure: const ValidationFailure(
            'a category is required',
            field: TransactionDraft.fieldCategoryId,
          ),
        ),
      );

      expect(find.text('Elige una categoría.'), findsOneWidget);
    });

    testWidgets(
        'monto en cero y falla de fieldAmountMinor, la zona de monto muestra '
        'el mensaje de error', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          accountId: 'acc-1',
          accountName: 'Efectivo',
          failure: const ValidationFailure(
            'the amount must be positive',
            field: TransactionDraft.fieldAmountMinor,
          ),
        ),
      );

      expect(find.text('Ingresa un monto mayor a cero.'), findsOneWidget);
    });

    testWidgets(
        'transferencia sin destino y falla de fieldTransferAccountId, el '
        'selector de destino muestra el mensaje de error', (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: TransactionType.transfer,
          accountId: 'acc-1',
          accountName: 'Efectivo',
          failure: const ValidationFailure(
            'a transfer requires a destination account',
            field: TransactionDraft.fieldTransferAccountId,
          ),
        ),
      );

      expect(find.text('Elige la cuenta de destino.'), findsOneWidget);
    });

    testWidgets('sin fallas, ningún mensaje de error se muestra',
        (tester) async {
      await pumpForm(
        tester,
        TransactionFormState(status: TransactionFormStatus.ready),
      );

      expect(find.text('Elige una cuenta.'), findsNothing);
      expect(find.text('Elige una categoría.'), findsNothing);
      expect(find.text('Ingresa un monto mayor a cero.'), findsNothing);
    });
  });
}

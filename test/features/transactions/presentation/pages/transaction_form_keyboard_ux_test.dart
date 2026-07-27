import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_note_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionFormCubit extends MockCubit<TransactionFormState>
    implements TransactionFormCubit {}

class MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

final DateTime _instant = DateTime(2026, 7, 15);

AccountWithBalance _buildAccountWithBalance({
  String id = 'acc-1',
  String name = 'Efectivo',
}) {
  final account = Account(
    id: id,
    name: name,
    type: AccountType.cash,
    currency: 'COP',
    initialBalanceMinor: 0,
    archived: false,
    sortOrder: 0,
    createdAt: _instant,
    updatedAt: _instant.millisecondsSinceEpoch,
  );
  return AccountWithBalance(
    account: account,
    balance:
        AccountBalance.fromMovements(account: account, movements: const []),
  );
}

/// Keyboard-UX guard (device bug): Nota is the form's only system-keyboard text
/// field, so its action is "listo" (`TextInputAction.done`); and tapping any
/// selector drops the system focus so the keyboard does not spring back when a
/// picker sheet closes.
void main() {
  late MockTransactionFormCubit cubit;
  late MockAccountsListCubit accountsListCubit;
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
      const CategoryQuickPickerState(status: CategoryQuickPickerStatus.ready),
    );

    tagFilterCubit = MockTagFilterCubit();
    when(() => tagFilterCubit.start(any())).thenAnswer((_) async {});
    when(() => tagFilterCubit.state).thenReturn(TagFilterState());

    getIt
      ..registerFactory<AccountsListCubit>(() => accountsListCubit)
      ..registerFactory<CategoryQuickPickerCubit>(
        () => categoryQuickPickerCubit,
      )
      ..registerFactory<TagFilterCubit>(() => tagFilterCubit);
  });

  tearDown(getIt.reset);

  Future<void> pumpForm(WidgetTester tester, TransactionFormState state) async {
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

  bool anyTextFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((editable) => editable.focusNode.hasFocus);

  Finder noteField() => find.descendant(
        of: find.byType(TransactionNoteField),
        matching: find.byType(TextField),
      );

  testWidgets('Nota (único campo del sistema) usa la acción "listo"',
      (tester) async {
    await pumpForm(
      tester,
      TransactionFormState(status: TransactionFormStatus.ready),
    );

    final field = tester.widget<TextField>(noteField());
    expect(field.textInputAction, TextInputAction.done);
  });

  testWidgets(
      'tocar el selector de Fecha cierra el teclado: ningún campo de texto '
      'queda enfocado al cerrarse el picker', (tester) async {
    await pumpForm(
      tester,
      TransactionFormState(status: TransactionFormStatus.ready),
    );

    // Type into Nota, which focuses it and raises the keyboard.
    await tester.enterText(noteField(), 'Café con Andrés');
    await tester.pump();
    expect(
      anyTextFieldFocused(tester),
      isTrue,
      reason: 'precondition: Nota must hold focus (keyboard up)',
    );

    // Fecha shows "Hoy, ..." on a fresh form; the selector defers opening by one
    // tick (it unfocuses first), so settle the sheet fully open and closed.
    await tester.tap(find.textContaining('Hoy,').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(
      anyTextFieldFocused(tester),
      isFalse,
      reason: 'the keyboard must not reappear after the date picker closes',
    );
  });

  testWidgets(
      'tocar el selector de tipo (Gasto/Ingreso) cierra el teclado del sistema',
      (tester) async {
    await pumpForm(
      tester,
      TransactionFormState(status: TransactionFormStatus.ready),
    );

    await tester.enterText(noteField(), 'Nota larga de prueba');
    await tester.pump();
    expect(anyTextFieldFocused(tester), isTrue);

    await tester.tap(find.text('Ingreso'));
    await tester.pumpAndSettle();

    expect(anyTextFieldFocused(tester), isFalse);
  });
}

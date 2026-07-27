import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/widgets/date_range_picker_sheet.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_edit_impact.dart';
import 'package:billetudo/features/transactions/presentation/cubit/account_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/date_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/account_filter_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/category_filter_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/confirm_delete_transaction_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/date_filter_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/edit_impact_warning_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/future_date_scheduled_payment_prompt_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/new_tag_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/tag_filter_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/type_filter_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../transaction_fixtures.dart';

class MockAccountFilterCubit extends MockCubit<AccountFilterState>
    implements AccountFilterCubit {}

class MockCategoryFilterCubit extends MockCubit<CategoryFilterState>
    implements CategoryFilterCubit {}

class MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

class MockDateFilterCubit extends MockCubit<DateFilterState>
    implements DateFilterCubit {}

final DateTime _instant = DateTime(2026, 7, 15);
final int _instantMillis = _instant.millisecondsSinceEpoch;

AccountWithBalance _buildAccountWithBalance({
  String id = 'acc-1',
  String name = 'Efectivo',
  int balanceMinor = 450050,
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
    updatedAt: _instantMillis,
  );
  return AccountWithBalance(
    account: account,
    balance: AccountBalance.fromBalance(
        account: account, balanceMinor: balanceMinor),
  );
}

Category _buildCategory({
  String id = 'cat-1',
  String name = 'Comida',
  CategoryKind kind = CategoryKind.expense,
  String? parentId,
  // Every fixture category passes its own real icon: leaving this null falls
  // back to `CategoryAppearance.defaultIconName` ("sparkles"), which would
  // make every row in this golden render the same generic icon instead of
  // Comida's fork/knife, Transporte's bus, etc. — not representative of what
  // the real category list actually looks like.
  String icon = 'utensils-crossed',
}) =>
    Category(
      id: id,
      name: name,
      kind: kind,
      parentId: parentId,
      icon: icon,
      sortOrder: 0,
      createdAt: _instant,
      updatedAt: _instantMillis,
    );

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  tearDown(getIt.reset);

  /// Opens [openSheet] through a real trigger button (mirrors how a sheet
  /// actually reaches the screen — scrim, drag handle and the `[28,28,0,0]`
  /// bottom sheet theme included) and captures the whole screen. Mirrors
  /// `accounts`' `sheets_golden_test.dart`.
  Future<void> golden(
    WidgetTester tester,
    Future<void> Function(BuildContext context) openSheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openSheet(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    group('account filter ($suffix)', () {
      setUp(() {
        final cubit = MockAccountFilterCubit();
        when(() => cubit.start(any())).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          AccountFilterState(
            status: AccountFilterStatus.ready,
            accounts: [
              _buildAccountWithBalance(),
              _buildAccountWithBalance(
                id: 'acc-2',
                name: 'Bancolombia',
                balanceMinor: -45000000,
              ),
            ],
          ),
        );
        getIt.registerFactory<AccountFilterCubit>(() => cubit);
      });

      testWidgets('with accounts', (tester) async {
        await golden(
          tester,
          (context) =>
              AccountFilterSheet.show(context, initialSelected: const {}),
          'account_filter_$suffix',
          brightness: brightness,
        );
      });
    });

    group('category filter ($suffix)', () {
      setUp(() {
        final cubit = MockCategoryFilterCubit();
        when(() => cubit.start(any())).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          CategoryFilterState(
            status: CategoryFilterStatus.ready,
            expenseNodes: [
              CategoryNode(
                root: _buildCategory(
                  id: 'cat-food',
                  name: 'Comida',
                  icon: 'utensils-crossed',
                ),
                subcategories: [
                  _buildCategory(
                    id: 'cat-food-1',
                    name: 'Restaurantes',
                    parentId: 'cat-food',
                    icon: 'coffee',
                  ),
                ],
              ),
              CategoryNode(
                root: _buildCategory(
                  id: 'cat-transport',
                  name: 'Transporte',
                  icon: 'bus',
                ),
              ),
            ],
            incomeNodes: [
              CategoryNode(
                root: _buildCategory(
                  id: 'cat-salary',
                  name: 'Salario',
                  kind: CategoryKind.income,
                  icon: 'briefcase',
                ),
              ),
            ],
            selected: const {'cat-food', 'cat-food-1'},
            expandedRootIds: const {'cat-food'},
          ),
        );
        getIt.registerFactory<CategoryFilterCubit>(() => cubit);
      });

      testWidgets('expense and income trees, one expanded', (tester) async {
        await golden(
          tester,
          (context) =>
              CategoryFilterSheet.show(context, initialSelected: const {}),
          'category_filter_$suffix',
          brightness: brightness,
        );
      });
    });

    group('tag filter ($suffix)', () {
      final tags = [buildTag(), buildTag(id: 'tag-2', name: 'trabajo')];

      testWidgets('list filter context, with tags', (tester) async {
        final cubit = MockTagFilterCubit();
        when(() => cubit.start(any())).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          TagFilterState(status: TagFilterStatus.ready, tags: tags),
        );
        getIt.registerFactory<TagFilterCubit>(() => cubit);

        await golden(
          tester,
          (context) => TagFilterSheet.show(context, initialSelected: const {}),
          'tag_filter_list_$suffix',
          brightness: brightness,
        );
      });

      testWidgets('field-picker context (Etiquetas), with a selection',
          (tester) async {
        final cubit = MockTagFilterCubit();
        when(() => cubit.start(any())).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          TagFilterState(
            status: TagFilterStatus.ready,
            tags: tags,
            selected: const {'tag-1'},
          ),
        );
        getIt.registerFactory<TagFilterCubit>(() => cubit);

        await golden(
          tester,
          (context) => TagFilterSheet.show(
            context,
            initialSelected: const {'tag-1'},
            title: 'Etiquetas',
            confirmLabel: 'Listo',
          ),
          'tag_filter_picker_$suffix',
          brightness: brightness,
        );
      });

      testWidgets('no tags yet, empty state', (tester) async {
        final cubit = MockTagFilterCubit();
        when(() => cubit.start(any())).thenAnswer((_) async {});
        when(() => cubit.state).thenReturn(
          TagFilterState(status: TagFilterStatus.ready),
        );
        getIt.registerFactory<TagFilterCubit>(() => cubit);

        await golden(
          tester,
          (context) => TagFilterSheet.show(context, initialSelected: const {}),
          'tag_filter_empty_$suffix',
          brightness: brightness,
        );
      });
    });

    group('date filter ($suffix)', () {
      testWidgets('this month (default granular period)', (tester) async {
        final cubit = MockDateFilterCubit();
        when(() => cubit.state)
            .thenReturn(DateFilterState(filter: DatePeriodFilter.thisMonth()));
        getIt.registerFactory<DateFilterCubit>(() => cubit);

        await golden(
          tester,
          (context) async {
            await DateFilterSheet.show(
              context,
              initial: DatePeriodFilter.thisMonth(),
            );
          },
          'date_filter_month_$suffix',
          brightness: brightness,
        );
      });

      testWidgets('custom range', (tester) async {
        final range = DatePeriodFilter.custom(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 15),
        );
        final cubit = MockDateFilterCubit();
        when(() => cubit.state).thenReturn(DateFilterState(filter: range));
        getIt.registerFactory<DateFilterCubit>(() => cubit);

        await golden(
          tester,
          (context) async {
            await DateFilterSheet.show(context, initial: range);
          },
          'date_filter_custom_range_$suffix',
          brightness: brightness,
        );
      });

      // The app's own range calendar (`Sheet - Rango Personalizado`/`OFdj4`),
      // opened from "Personalizado" instead of Material's
      // `showDateRangePicker` — the two "Desde"/"Hasta" fields, the
      // range-highlighted `MonthCalendar` grid (solid `primary` endpoints,
      // `primary-soft` days in between) and the single "Aplicar".
      testWidgets('custom range picker sheet, a range already selected',
          (tester) async {
        await golden(
          tester,
          (context) => DateRangePickerSheet.show(
            context,
            initialStart: DateTime(2026, 7, 3),
            initialEnd: DateTime(2026, 7, 9),
          ),
          'date_range_picker_$suffix',
          brightness: brightness,
        );
      });
    });

    group('type filter ($suffix)', () {
      testWidgets('none selected', (tester) async {
        await golden(
          tester,
          (context) => TypeFilterSheet.show(context, initialSelected: const {}),
          'type_filter_none_$suffix',
          brightness: brightness,
        );
      });

      testWidgets('expense and income selected', (tester) async {
        await golden(
          tester,
          (context) => TypeFilterSheet.show(
            context,
            initialSelected: const {
              TransactionType.expense,
              TransactionType.income,
            },
          ),
          'type_filter_some_selected_$suffix',
          brightness: brightness,
        );
      });
    });

    testWidgets('confirm delete transaction ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => ConfirmDeleteTransactionSheet.show(
          context,
          onConfirm: () {},
          onCancel: () {},
        ),
        'confirm_delete_transaction_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('future date -> scheduled payment prompt ($suffix)',
        (tester) async {
      await golden(
        tester,
        FutureDateScheduledPaymentPromptSheet.show,
        'future_date_scheduled_payment_prompt_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('new tag ($suffix)', (tester) async {
      await golden(
        tester,
        NewTagSheet.show,
        'new_tag_$suffix',
        brightness: brightness,
      );
    });

    group('edit impact warning ($suffix)', () {
      testWidgets('affects scheduled payment, goal and debt', (tester) async {
        await golden(
          tester,
          (context) => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => EditImpactWarningSheet(
              impact: const TransactionEditImpact(
                affectsScheduledPayment: true,
                affectsGoal: true,
                affectsDebt: true,
              ),
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
          'edit_impact_warning_all_$suffix',
          brightness: brightness,
        );
      });

      testWidgets('affects only scheduled payment', (tester) async {
        await golden(
          tester,
          (context) => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => EditImpactWarningSheet(
              impact: const TransactionEditImpact(
                affectsScheduledPayment: true,
                affectsGoal: false,
                affectsDebt: false,
              ),
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
          'edit_impact_warning_scheduled_only_$suffix',
          brightness: brightness,
        );
      });
    });
  }
}

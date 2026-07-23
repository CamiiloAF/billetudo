import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_select_row.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/repositories/debt_repository.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_form_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_ledger_row.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_account_picker_sheet.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget-level reproduction of the device bug, narrowed to the real cause:
/// the SYNTHETIC "Saldo de apertura" ledger row (the "No, solo la deuda" path,
/// which writes no `Transaction`) was dated on `debt.createdAt` (≈ today) in
/// `DebtBalanceCalculator.buildLedger` instead of the debt's start date — so a
/// debt started in the past showed its opening dated today, and editing the
/// "Fecha" never moved it.
///
/// Also guards fix #2: the account picker of the "Sí, elegir cuenta" create
/// path must open with NO account pre-selected.
///
/// Driven through the real form + detail over the real DI graph, off emulator.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
    final tempDir = await Directory.systemTemp.createTemp('billetudo_startd');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

  // The PowerSync file persists across tests in this process, so wipe the
  // tables this suite touches before each scenario to keep them independent.
  Future<void> clearTables() async {
    final db = getIt<AppDatabase>();
    await db.delete(db.transactions).go();
    await db.delete(db.debtEntries).go();
    await db.delete(db.debts).go();
    await db.delete(db.accounts).go();
  }

  Future<void> seedAccount() async {
    final db = getIt<AppDatabase>();
    await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.cash,
            currency: 'COP',
          ),
        );
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    bool Function() found, {
    String? reason,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!found()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for: ${reason ?? 'condition'}');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  Future<List<Debt>> readDebts() async {
    final db = getIt<AppDatabase>();
    return db.select(db.debts).get();
  }

  Future<List<Transaction>> readTransactions() async {
    final db = getIt<AppDatabase>();
    return db.select(db.transactions).get();
  }

  /// Pumps bounded frames until at least one debt row exists, then returns its
  /// id — reading the DB inside [WidgetTester.runAsync] between frames.
  Future<String> pumpUntilDebt(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (true) {
      var debts = <Debt>[];
      await tester.runAsync(() async => debts = await readDebts());
      if (debts.isNotEmpty) {
        return debts.first.id;
      }
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for the debt to persist');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  /// The opening ledger entry the read side derives for [debtId] (via the real
  /// repository + `buildLedger`), or null while it is not there yet.
  Future<DebtLedgerEntry?> openingEntry(String debtId) async {
    final result = await getIt<DebtRepository>().watchDebtDetail(debtId).first;
    return result.fold(
      (_) => null,
      (detail) {
        for (final entry in detail.ledger) {
          if (entry.kind == DebtLedgerKind.opening) {
            return entry;
          }
        }
        return null;
      },
    );
  }

  Future<DebtLedgerEntry> pumpUntilOpening(
    WidgetTester tester,
    String debtId,
    bool Function(DebtLedgerEntry) ready, {
    required String reason,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (true) {
      DebtLedgerEntry? entry;
      await tester.runAsync(() async => entry = await openingEntry(debtId));
      final found = entry;
      if (found != null && ready(found)) {
        return found;
      }
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for: $reason');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  Future<DebtFormCubit> pumpForm(WidgetTester tester, String? debtId) async {
    final cubit = getIt<DebtFormCubit>();
    unawaited(cubit.load(debtId));
    addTearDown(cubit.close);

    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DebtFormCubit>.value(
          value: cubit,
          child: const DebtFormPage(),
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      () => find.byType(DebtAmountHeroField).evaluate().isNotEmpty,
      reason: 'form ready',
    );
    return cubit;
  }

  /// Mounts the real detail page for [debtId] and waits for its ledger to show.
  Future<void> pumpDetail(WidgetTester tester, String debtId) async {
    final detailCubit = getIt<DebtDetailCubit>();
    unawaited(detailCubit.start(debtId));
    addTearDown(detailCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DebtDetailCubit>.value(
          value: detailCubit,
          child: DebtDetailPage(
            onEdit: (_) {},
            onOpenInstallment: (_) {},
            onConfigureInstallment: (_, __) {},
            onLinkExisting: (_) {},
            onOpenTransaction: (_) {},
          ),
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      () => find.byType(DebtLedgerRow).evaluate().isNotEmpty,
      reason: 'detail ledger rendered',
    );
  }

  Future<void> enterAmountAndName(WidgetTester tester) async {
    final amountField = find.descendant(
      of: find.byType(DebtAmountHeroField),
      matching: find.byType(TextField),
    );
    await tester.enterText(amountField, '500000');
    await tester.pump();

    final nameField = find.descendant(
      of: find.ancestor(
        of: find.text('Crédito vehicular, préstamo a Andrés…'),
        matching: find.byType(DebtFormField),
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(nameField, 'Préstamo a Andrés');
    await tester.pump();
  }

  /// Opens the "Fecha" (start date) selector, pages to the previous month and
  /// taps day 15 there (always in the past), then confirms. Returns the picked
  /// day at day precision.
  Future<DateTime> pickStartDatePreviousMonth15(WidgetTester tester) async {
    await pumpUntilFound(
      tester,
      () => find.textContaining('Hoy,').evaluate().isNotEmpty,
      reason: 'start-date field showing today',
    );
    await tester.tap(find.textContaining('Hoy,').first);
    // The selector defers opening by one tick (it unfocuses the keyboard before
    // pushing the sheet), so settle instead of a fixed slide-in pump.
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.chevronLeft));
    await tester.pump();
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350)); // sheet slide-out

    final now = DateTime.now();
    return DateTime(now.year, now.month - 1, 15);
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  testWidgets(
      'crear "No, solo la deuda" con Fecha pasada: la fila de apertura del '
      'ledger queda con la fecha pasada, no con hoy', (tester) async {
    await tester.runAsync(() async {
      await clearTables();
      await seedAccount();
    });

    await pumpForm(tester, null);
    await enterAmountAndName(tester);
    final picked = await pickStartDatePreviousMonth15(tester);

    // Crear deuda -> "No, solo la deuda" (no Transaction is written).
    await tester.tap(find.text('Crear deuda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('No, solo la deuda'));
    await tester.pump();

    final debtId = await pumpUntilDebt(tester);

    late final List<Transaction> txns;
    await tester.runAsync(() async => txns = await readTransactions());
    expect(txns, isEmpty, reason: 'solo-deuda writes no opening Transaction');

    // The synthetic opening row is dated on the picked start date, not today.
    final entry = await pumpUntilOpening(
      tester,
      debtId,
      (_) => true,
      reason: 'opening ledger row derived',
    );
    expect(
      isSameDay(entry.date, picked),
      isTrue,
      reason: 'the synthetic opening row must show the picked start date',
    );
    expect(
      isSameDay(entry.date, DateTime.now()),
      isFalse,
      reason: 'it must not fall back to today (createdAt)',
    );

    // And the real detail page renders that opening row.
    await pumpDetail(tester, debtId);
    expect(find.text('Saldo de apertura'), findsOneWidget);
  });

  testWidgets(
      'editar la Fecha de una deuda solo-deuda: la fila de apertura del '
      'ledger se mueve a la nueva fecha (derivada, sin Transaction)',
      (tester) async {
    late final String debtId;
    late final DateTime originalDate;
    await tester.runAsync(() async {
      await clearTables();
      final db = getIt<AppDatabase>();
      final now = DateTime.now();
      originalDate = DateTime(now.year, now.month - 2, 10);
      final debt = await db.into(db.debts).insertReturning(
            DebtsCompanion.insert(
              name: 'Préstamo a Andrés',
              direction: DebtDirection.iOwe,
              principalMinor: 500000,
              currency: 'COP',
              startDate: drift.Value(originalDate),
            ),
          );
      debtId = debt.id;
    });

    await pumpForm(tester, debtId);

    // The loaded start-date field is not "today".
    expect(find.textContaining('Hoy,'), findsNothing);

    // Open the start-date picker (it opens on the debt's current start month)
    // and pick a new day 15 in that month.
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is DebtFormSelectorBox &&
            w.icon == LucideIcons.calendar &&
            w.value != null &&
            w.value!.contains(_monthShort(originalDate.month)),
      ),
    );
    // The selector defers opening by one tick (it unfocuses the keyboard before
    // pushing the sheet), so settle instead of a fixed slide-in pump.
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final newDate = DateTime(originalDate.year, originalDate.month, 15);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    final entry = await pumpUntilOpening(
      tester,
      debtId,
      (e) => isSameDay(e.date, newDate),
      reason: "the opening row's derived date must follow the edited Fecha",
    );
    expect(isSameDay(entry.date, newDate), isTrue);
    expect(isSameDay(entry.date, originalDate), isFalse);
  });

  testWidgets(
      'crear con "Sí, elegir cuenta": el picker de cuenta abre sin ninguna '
      'cuenta pre-seleccionada', (tester) async {
    await tester.runAsync(() async {
      await clearTables();
      await seedAccount();
    });

    await pumpForm(tester, null);
    await enterAmountAndName(tester);

    await tester.tap(find.text('Crear deuda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Sí, elegir cuenta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await pumpUntilFound(
      tester,
      () => find.byType(DebtAccountPickerSheet).evaluate().isNotEmpty,
      reason: 'account picker open',
    );

    final rows = tester.widgetList<AccountSelectRow>(
      find.byType(AccountSelectRow),
    );
    expect(rows, isNotEmpty);
    expect(
      rows.every((row) => !row.selected),
      isTrue,
      reason: 'creating a debt must not pre-select an account',
    );
  });
}

String _monthShort(int month) {
  const names = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return names[month - 1];
}

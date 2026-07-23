import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget-level reproduction of the Patrol "HU-02 abono con caja" scenario
/// against the real DI graph over a real PowerSync-backed [AppDatabase]: the
/// real [DebtDetailPage], the real abono sheet opened from its bottom bar, the
/// real amount héroe typed into. Off-emulator.
///
/// `pumpAndSettle` is avoided on purpose: the loading skeleton/spinner animate
/// forever and would hang it. I/O hops run inside [WidgetTester.runAsync] and
/// UI is advanced with bounded [WidgetTester.pump]s.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
    final tempDir = await Directory.systemTemp.createTemp('billetudo_abonow');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

  Future<String> seedDebtAndAccount() async {
    final db = getIt<AppDatabase>();
    await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.cash,
            currency: 'COP',
          ),
        );
    final debt = await db.into(db.debts).insertReturning(
          DebtsCompanion.insert(
            name: 'Crédito carro',
            direction: DebtDirection.iOwe,
            principalMinor: 60000,
            currency: 'COP',
            accrualMode: const Value(DebtAccrualMode.manual),
          ),
        );
    return debt.id;
  }

  /// Pumps bounded frames until [found] is satisfied (or a deadline), letting
  /// real async I/O (PowerSync streams) run between frames.
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

  testWidgets('HU-02 abono con caja: el saldo baja \$600 -> \$400 en el detalle',
      (tester) async {
    late final String debtId;
    await tester.runAsync(() async => debtId = await seedDebtAndAccount());

    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    // Detail loads from the live stream: wait for the opening balance to show.
    await pumpUntilFound(
      tester,
      () => find.text(r'$600').evaluate().isNotEmpty,
      reason: 'detail hero at opening balance',
    );

    // Open the abono sheet from the fixed bottom bar.
    await tester.tap(find.text('Registrar abono'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350)); // sheet slide-in

    // The sheet's cubit loads accounts; wait for the amount héroe to mount.
    await pumpUntilFound(
      tester,
      () => find.byType(DebtAmountHeroField).evaluate().isNotEmpty,
      reason: 'abono sheet ready',
    );

    // Type $200 into the héroe.
    final amountField = find.descendant(
      of: find.byType(DebtAmountHeroField),
      matching: find.byType(TextField),
    );
    await tester.enterText(amountField, '200');
    await tester.pump();

    // Submit via the sheet's check-icon CTA.
    await tester.tap(
      find.descendant(
        of: find.byType(DebtPaymentSheetBody),
        matching: find.byIcon(LucideIcons.check),
      ),
    );
    await tester.pump();

    // The write + sheet pop + detail re-emit are async hops.
    await pumpUntilFound(
      tester,
      () => find.text(r'$400').evaluate().isNotEmpty,
      reason: 'the detail must show the reduced balance \$400 after the abono',
    );

    // And the write really landed: one Transaction with the debt id.
    late final List<Transaction> txns;
    await tester.runAsync(() async {
      final db = getIt<AppDatabase>();
      txns = await db.select(db.transactions).get();
    });
    expect(txns.length, 1);
    expect(txns.single.debtId, isNotNull);
    expect(txns.single.amountMinor, 20000);
  });

  testWidgets(
      'HU-02 abono con caja en pantalla de teléfono con teclado: el CTA de '
      'la hoja "Sí" sigue alcanzable', (tester) async {
    late final String debtId;
    await tester.runAsync(() async => debtId = await seedDebtAndAccount());

    // A realistic small phone viewport (Pixel-ish logical size), NOT the tall
    // 1800px canvas the happy-path test uses — on a real screen the taller
    // "Sí" sheet plus the soft keyboard squeezes the submit CTA below the fold.
    tester.view.physicalSize = const Size(393 * 2.0, 786 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

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
      () => find.text(r'$600').evaluate().isNotEmpty,
      reason: 'detail hero at opening balance',
    );

    await tester.tap(find.text('Registrar abono'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await pumpUntilFound(
      tester,
      () => find.byType(DebtAmountHeroField).evaluate().isNotEmpty,
      reason: 'abono sheet ready',
    );

    // The héroe autofocuses on a real device -> the soft keyboard is up. Fake
    // that inset so the sheet lifts exactly as it would on the phone.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.0);
    await tester.pump();

    final amountField = find.descendant(
      of: find.byType(DebtAmountHeroField),
      matching: find.byType(TextField),
    );
    await tester.enterText(amountField, '200');
    await tester.pump();

    // Try to submit exactly as the e2e does: tap the sheet's check-icon CTA.
    final submit = find.descendant(
      of: find.byType(DebtPaymentSheetBody),
      matching: find.byIcon(LucideIcons.check),
    );
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();

    await pumpUntilFound(
      tester,
      () => find.text(r'$400').evaluate().isNotEmpty,
      reason: 'the detail must show \$400 after the abono is submitted from a '
          'sheet whose CTA sits under the keyboard',
    );
  });
}

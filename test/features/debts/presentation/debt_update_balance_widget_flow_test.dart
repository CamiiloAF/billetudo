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
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget-level regression for "actualizar saldo" (HU-06), the sibling of the
/// abono sheet fix: on a phone viewport with the soft keyboard up, the sheet's
/// "Guardar saldo" CTA must stay reachable (it now lives in a pinned footer,
/// not the bottom of a single scroll view). Real DI over a real PowerSync
/// [AppDatabase]. Off-emulator.
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
    final tempDir = await Directory.systemTemp.createTemp('billetudo_updbal');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

  Future<String> seedDebt() async {
    final db = getIt<AppDatabase>();
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

  testWidgets(
      'HU-06 actualizar saldo en pantalla de teléfono con teclado: el CTA '
      '"Guardar saldo" sigue alcanzable', (tester) async {
    late final String debtId;
    await tester.runAsync(() async => debtId = await seedDebt());

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
            onConfigureInstallment: (_) {},
            onLinkExisting: (_) {},
          ),
        ),
      ),
    );

    await pumpUntilFound(
      tester,
      () => find.text(r'$600').evaluate().isNotEmpty,
      reason: 'detail hero at opening balance',
    );

    // Open "Actualizar saldo" from the meta card (unambiguous before the sheet,
    // whose title shares the text, is up).
    await tester.tap(find.text('Actualizar saldo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await pumpUntilFound(
      tester,
      () => find.byType(DebtAmountHeroField).evaluate().isNotEmpty,
      reason: 'actualizar-saldo sheet ready',
    );

    // The héroe autofocuses -> soft keyboard up. Fake the inset so the sheet
    // lifts exactly as on a real phone.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.0);
    await tester.pump();

    final amountField = find.descendant(
      of: find.byType(DebtAmountHeroField),
      matching: find.byType(TextField),
    );
    await tester.enterText(amountField, '400');
    await tester.pump();

    // Submit via the pinned "Guardar saldo" CTA (unique text on this sheet).
    await tester.tap(find.text('Guardar saldo'), warnIfMissed: false);
    await tester.pump();

    // The reconciliation adjustment lands and the live detail reads $400.
    await pumpUntilFound(
      tester,
      () => find.text(r'$400').evaluate().isNotEmpty,
      reason: 'the detail must show \$400 after "Guardar saldo" is tapped on a '
          'sheet whose CTA sits under the keyboard',
    );

    expect(
      detailCubit.state.detail?.balance.outstandingMinor,
      40000,
    );
  });
}

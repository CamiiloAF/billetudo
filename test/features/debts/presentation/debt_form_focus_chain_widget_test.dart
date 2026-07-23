import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_form_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The keyboard "siguiente"/"listo" chain in the crear/editar debt form: the
/// four text fields (opening balance → name → counterparty → interest) are
/// wired so "siguiente" moves focus to the next TEXT field, skipping the
/// selectors (Fecha / Vencimiento) between them, and "listo" on the last field
/// dismisses the keyboard. Driven through the real form over the DI graph.
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
    final tempDir = await Directory.systemTemp.createTemp('billetudo_focus');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

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

  Future<void> pumpForm(WidgetTester tester) async {
    final cubit = getIt<DebtFormCubit>();
    unawaited(cubit.load(null));
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
  }

  // The inner EditableText of a field, located by the stable ValueKey each field
  // carries in create mode.
  Finder editableOf(Key key) => find.descendant(
        of: find.byKey(key),
        matching: find.byType(EditableText),
      );

  final Finder opening = editableOf(const ValueKey('debt-amount-opening'));
  final Finder name = editableOf(const ValueKey('name-new'));
  final Finder counterparty = editableOf(const ValueKey('counterparty-new'));
  final Finder interest = editableOf(const ValueKey('rate-new'));

  bool hasFocus(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).focusNode.hasFocus;

  TextInputAction? actionOf(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).textInputAction;

  bool anyFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((field) => field.focusNode.hasFocus);

  testWidgets(
      '"siguiente" encadena Saldo → Nombre → Le debo a → Interés (saltando '
      'los selectores) y "listo" en Interés cierra el teclado', (tester) async {
    await pumpForm(tester);

    // The declared keyboard actions: the first three text fields say
    // "siguiente" (next), the last says "listo" (done).
    expect(actionOf(tester, opening), TextInputAction.next);
    expect(actionOf(tester, name), TextInputAction.next);
    expect(actionOf(tester, counterparty), TextInputAction.next);
    expect(actionOf(tester, interest), TextInputAction.done);

    // Focus the opening héroe by typing into it, then press "siguiente".
    await tester.enterText(opening, '100000');
    await tester.pump();
    expect(hasFocus(tester, opening), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, name), isTrue, reason: 'Saldo → Nombre');
    expect(hasFocus(tester, opening), isFalse);

    // Nombre → Le debo a.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, counterparty), isTrue, reason: 'Nombre → Le debo a');

    // Le debo a → Interés, skipping the Fecha / Vencimiento selectors.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      hasFocus(tester, interest),
      isTrue,
      reason: 'Le debo a → Interés (los selectores no reciben el foco)',
    );

    // Interés "listo" dismisses the keyboard: no text field keeps focus.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      anyFieldFocused(tester),
      isFalse,
      reason: '"listo" en el último campo cierra el teclado',
    );
  });
}

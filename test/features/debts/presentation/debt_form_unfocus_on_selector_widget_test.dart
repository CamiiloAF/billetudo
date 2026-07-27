import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_form_cubit.dart';
import 'package:billetudo/features/debts/presentation/pages/debt_form_page.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_currency_picker_sheet.dart';
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

/// Keyboard UX guard (device bug): every selector field of the form calls
/// `FocusScope.unfocus()` before opening its sheet/picker, so a text field the
/// user was typing into loses focus and the keyboard does NOT reappear when the
/// sheet closes. Without the unfocus, the focused `TextField` survives the sheet
/// and the soft keyboard springs back up on dismiss.
///
/// Driven through the real form over the real DI graph, off emulator.
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
    final tempDir = await Directory.systemTemp.createTemp('billetudo_unfocus');
    addTearDown(() => tempDir.delete(recursive: true));
    await openPowerSyncDatabase(path: p.join(tempDir.path, 'test.sqlite'));
  });

  setUp(configureDependencies);
  tearDown(getIt.reset);

  Future<DebtFormCubit> pumpForm(WidgetTester tester) async {
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

    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (find.byType(DebtAmountHeroField).evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for the form to be ready');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
    return cubit;
  }

  bool anyTextFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((editable) => editable.focusNode.hasFocus);

  /// Types into the "Nombre" field, which focuses it and raises the keyboard.
  Future<void> focusNameField(WidgetTester tester) async {
    final nameField = find.descendant(
      of: find.ancestor(
        of: find.text('Crédito vehicular, préstamo a Andrés…'),
        matching: find.byType(DebtFormField),
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(nameField, 'Préstamo a Andrés');
    await tester.pump();
    expect(
      anyTextFieldFocused(tester),
      isTrue,
      reason: 'precondition: the name field must hold focus (keyboard up)',
    );
  }

  testWidgets(
      'tocar el selector de Fecha cierra el teclado: ningún campo de texto '
      'queda enfocado al cerrarse el picker', (tester) async {
    await pumpForm(tester);
    await focusNameField(tester);

    // Fecha (start date) shows "Hoy, ..." on a fresh debt. The selector defers
    // opening by one tick (it unfocuses first), so settle the sheet open/close.
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
      'tocar el selector de Fecha de vencimiento cierra el teclado: ningún '
      'campo de texto queda enfocado al cerrarse el picker', (tester) async {
    await pumpForm(tester);
    await focusNameField(tester);

    // Due date is the calendar selector with no value yet (only a hint).
    final dueSelector = find.byWidgetPredicate(
      (w) =>
          w is DebtFormSelectorBox &&
          w.icon == LucideIcons.calendar &&
          w.value == null,
    );
    await tester.tap(dueSelector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(
      anyTextFieldFocused(tester),
      isFalse,
      reason: 'the keyboard must not reappear after the due-date picker closes',
    );
  });

  testWidgets(
      'tocar la píldora de moneda cierra el teclado: ningún campo de texto '
      'queda enfocado al cerrarse la hoja', (tester) async {
    await pumpForm(tester);
    await focusNameField(tester);

    await tester.tap(find.byType(DebtCurrencyPill));
    await tester.pumpAndSettle();
    // Pick a currency row to close the sheet.
    await tester.tap(
      find.descendant(
        of: find.byType(DebtCurrencyRow),
        matching: find.text('USD'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      anyTextFieldFocused(tester),
      isFalse,
      reason: 'the keyboard must not reappear after the currency sheet closes',
    );
  });
}

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_form_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_form_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountFormCubit extends MockCubit<AccountFormState>
    implements AccountFormCubit {}

/// The keyboard "siguiente"/"listo" chain in the crear/editar account form: the
/// visible TEXT fields are wired so "siguiente" moves focus to the next text
/// field — skipping the selectors (moneda, día de corte/pago) between them —
/// and "listo" on the last one dismisses the keyboard. Also: tapping a selector
/// drops the keyboard so it does not spring back when the sheet closes.
void main() {
  late MockAccountFormCubit cubit;

  setUp(() => cubit = MockAccountFormCubit());

  // A ListView needs a tall viewport or the fields below the fold are never
  // built; a real phone builds them as the user scrolls.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1200, 4000);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Future<void> pumpForm(WidgetTester tester, AccountFormState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountFormCubit>.value(
          value: cubit,
          child: const AccountFormPage(),
        ),
      ),
    );
  }

  // The inner EditableText of the field carrying [label], located through the
  // AccountFormField that owns that label.
  Finder editableByLabel(String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(AccountFormField),
        ),
        matching: find.byType(EditableText),
      );

  // The tappable box of the selector field carrying [label] (the label Text
  // itself is not tappable; the InkWell box below it is).
  Finder selectorBoxByLabel(String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(AccountFormField),
        ),
        matching: find.byType(AccountFormSelectorBox),
      );

  bool hasFocus(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).focusNode.hasFocus;

  TextInputAction? actionOf(WidgetTester tester, Finder editable) =>
      tester.widget<EditableText>(editable).textInputAction;

  bool anyFieldFocused(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((field) => field.focusNode.hasFocus);

  testWidgets(
      'banco (alta): "siguiente" encadena Nombre → Institución → Saldo inicial '
      '→ Número → Últimos 4 → Tasa (saltando Moneda) y "listo" cierra el '
      'teclado', (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
      ),
    );

    final name = editableByLabel('Nombre de la cuenta');
    final institution = editableByLabel('Institución (opcional)');
    final balance = editableByLabel('Saldo inicial');
    final number = editableByLabel('Número de cuenta');
    final last4 = editableByLabel('Últimos 4 dígitos');
    final rate = editableByLabel('Tasa de interés');

    // The declared keyboard actions: every field but the last says "siguiente"
    // (next); the last says "listo" (done).
    expect(actionOf(tester, name), TextInputAction.next);
    expect(actionOf(tester, institution), TextInputAction.next);
    expect(actionOf(tester, balance), TextInputAction.next);
    expect(actionOf(tester, number), TextInputAction.next);
    expect(actionOf(tester, last4), TextInputAction.next);
    expect(actionOf(tester, rate), TextInputAction.done);

    // Walk the chain: focus the first field, then press "siguiente" each time.
    await tester.enterText(name, 'Cuenta');
    await tester.pump();
    expect(hasFocus(tester, name), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, institution), isTrue,
        reason: 'Nombre → Institución');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, balance), isTrue,
        reason: 'Institución → Saldo inicial');

    // Saldo inicial → Número, skipping the Moneda selector between them.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, number), isTrue,
        reason: 'Saldo inicial → Número (Moneda no recibe el foco)');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, last4), isTrue, reason: 'Número → Últimos 4');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, rate), isTrue, reason: 'Últimos 4 → Tasa');

    // "listo" on the last field dismisses the keyboard: nothing keeps focus.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(anyFieldFocused(tester), isFalse,
        reason: '"listo" en el último campo cierra el teclado');
  });

  testWidgets(
      'tarjeta (alta): la cadena atraviesa los campos condicionales de la '
      'tarjeta (Cupo máximo, Deuda actual) y "listo" queda en Deuda actual',
      (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.card,
      ),
    );

    final name = editableByLabel('Nombre de la cuenta');
    final institution = editableByLabel('Institución (opcional)');
    final last4 = editableByLabel('Últimos 4 dígitos');
    final rate = editableByLabel('Tasa de interés');
    final creditLimit = editableByLabel('Cupo máximo');
    final debt = editableByLabel('Deuda actual');

    // A card keeps only the last 4 (no full number field) and adds the card
    // money fields; the chain reflects that visible order.
    expect(actionOf(tester, name), TextInputAction.next);
    expect(actionOf(tester, institution), TextInputAction.next);
    expect(actionOf(tester, last4), TextInputAction.next);
    expect(actionOf(tester, rate), TextInputAction.next);
    expect(actionOf(tester, creditLimit), TextInputAction.next);
    expect(actionOf(tester, debt), TextInputAction.done);

    await tester.enterText(name, 'Visa');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, institution), isTrue);

    // Institución → Últimos 4, skipping the Moneda selector.
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, last4), isTrue,
        reason: 'Institución → Últimos 4 (Moneda no recibe el foco)');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, rate), isTrue, reason: 'Últimos 4 → Tasa');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, creditLimit), isTrue, reason: 'Tasa → Cupo máximo');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(hasFocus(tester, debt), isTrue,
        reason: 'Cupo máximo → Deuda actual');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(anyFieldFocused(tester), isFalse,
        reason: '"listo" en Deuda actual cierra el teclado');
  });

  testWidgets(
      'al tocar el selector de Moneda el foco queda en nada (el teclado no '
      'reaparece)', (tester) async {
    when(() => cubit.currencySelected(any())).thenReturn(null);
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
      ),
    );

    final name = editableByLabel('Nombre de la cuenta');
    await tester.enterText(name, 'Cuenta');
    await tester.pump();
    expect(hasFocus(tester, name), isTrue);

    // Tapping the currency selector unfocuses before opening the sheet; the
    // async unfocus lands and the sheet fully opens before we assert (settled
    // state, so the field cannot silently regain focus a tick later).
    await tester.tap(selectorBoxByLabel('Moneda'));
    await tester.pumpAndSettle();
    expect(anyFieldFocused(tester), isFalse,
        reason: 'el selector suelta el foco antes de abrir la hoja');
  });

  testWidgets(
      'al tocar el selector de Día de corte el foco queda en nada',
      (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.card,
      ),
    );

    final name = editableByLabel('Nombre de la cuenta');
    await tester.enterText(name, 'Visa');
    await tester.pump();
    expect(hasFocus(tester, name), isTrue);

    await tester.tap(selectorBoxByLabel('Día de corte'));
    await tester.pumpAndSettle();
    expect(anyFieldFocused(tester), isFalse,
        reason: 'el selector de día suelta el foco antes de abrir la hoja');
  });
}

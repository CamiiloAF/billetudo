import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/page_header_circle_button.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_form_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_form_field.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_type_grid.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_type_pill.dart';
import 'package:billetudo/features/accounts/presentation/widgets/card_details_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountFormCubit extends MockCubit<AccountFormState>
    implements AccountFormCubit {}

void main() {
  late MockAccountFormCubit cubit;

  setUp(() => cubit = MockAccountFormCubit());

  // El formulario es una ListView: sin un viewport alto, los campos de abajo
  // (número de cuenta, datos de la tarjeta) ni siquiera se construyen y el test
  // no vería lo que sí existe en un teléfono real al hacer scroll.
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

  testWidgets('alta: título "Nueva cuenta" y grid de tipo sin seleccionar',
      (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(status: AccountFormStatus.ready),
    );

    expect(find.text('Nueva cuenta'), findsOneWidget);
    expect(find.byType(AccountTypeGrid), findsOneWidget);
    expect(find.byType(AccountTypePill), findsNothing);
    // Sin tipo elegido no hay campos condicionales de ningún tipo.
    expect(find.byType(CardDetailsSection), findsNothing);
    expect(find.text('Número de cuenta'), findsNothing);
  });

  testWidgets('edición: título "Editar cuenta" y tipo colapsado en el pill',
      (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        id: 'acc-1',
        type: AccountType.bank,
        name: 'Bancolombia',
      ),
    );

    expect(find.text('Editar cuenta'), findsOneWidget);
    expect(find.byType(AccountTypePill), findsOneWidget);
    expect(find.byType(AccountTypeGrid), findsNothing);
  });

  testWidgets('"Cambiar" expande el grid inline', (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        id: 'acc-1',
        type: AccountType.bank,
        typePickerExpanded: true,
      ),
    );

    expect(find.byType(AccountTypeGrid), findsOneWidget);
    expect(find.byType(AccountTypePill), findsNothing);
  });

  group('campos condicionales por tipo (HU-02/HU-03)', () {
    testWidgets(
        'tarjeta: aparecen los datos de la tarjeta y NO el número '
        'completo', (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.card,
        ),
      );

      expect(find.byType(CardDetailsSection), findsOneWidget);
      expect(find.text('Cupo máximo'), findsOneWidget);
      expect(find.text('Día de corte'), findsOneWidget);
      expect(find.text('Día de pago'), findsOneWidget);
      // HU-03: de una tarjeta jamás se pide el PAN, solo los últimos 4.
      expect(find.byType(AccountNumberField), findsNothing);
      expect(find.text('Últimos 4 dígitos'), findsOneWidget);
    });

    testWidgets('banco: número completo, sin datos de tarjeta', (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.bank,
        ),
      );

      expect(find.byType(CardDetailsSection), findsNothing);
      expect(find.text('Cupo máximo'), findsNothing);
      expect(find.byType(AccountNumberField), findsOneWidget);
      expect(find.text('Número de cuenta'), findsOneWidget);
      expect(
        find.text('Se guarda solo en este dispositivo, nunca en la nube.'),
        findsOneWidget,
      );
    });

    testWidgets('efectivo: ni número, ni últimos 4, ni datos de tarjeta',
        (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.cash,
        ),
      );

      expect(find.byType(AccountNumberField), findsNothing);
      expect(find.text('Últimos 4 dígitos'), findsNothing);
      expect(find.byType(CardDetailsSection), findsNothing);
    });

    testWidgets('el número completo arranca oculto, con ojo para revelarlo',
        (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.bank,
          fullAccountNumber: '1234567890',
        ),
      );

      final field = tester.widget<AccountFormField>(
        find.descendant(
          of: find.byType(AccountNumberField),
          matching: find.byType(AccountFormField),
        ),
      );
      expect(field.obscureText, isTrue);
      expect(
        find.descendant(
          of: find.byType(AccountNumberField),
          matching: find.byIcon(LucideIcons.eye),
        ),
        findsOneWidget,
      );
    });

    // Regresión (HU-03): un campo vacío y mudo se lee como "esta cuenta no
    // tiene número". El usuario tiene que enterarse de que no se pudo leer.
    testWidgets('si no se pudo leer el número, el campo lo explica',
        (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.bank,
          numberReadFailed: true,
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AccountNumberField),
          matching: find.byType(FormFieldError),
        ),
        findsOneWidget,
      );
    });

    testWidgets('con el número leído no hay aviso de lectura fallida',
        (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.bank,
          fullAccountNumber: '1234567890',
        ),
      );

      expect(
        find.descendant(
          of: find.byType(AccountNumberField),
          matching: find.byType(FormFieldError),
        ),
        findsNothing,
      );
    });
  });

  group('saldo inicial / deuda actual (Mejora #1)', () {
    testWidgets('alta de banco: aparece "Saldo inicial"', (tester) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.bank,
        ),
      );

      expect(find.text('Saldo inicial'), findsOneWidget);
    });

    testWidgets('edición de banco: NO aparece "Saldo inicial"', (tester) async {
      // Al editar, el saldo ya no se teclea a mano: se reconcilia con
      // "Ajustar saldo" desde el detalle.
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          id: 'acc-1',
          type: AccountType.bank,
          name: 'Bancolombia',
          initialBalanceText: '450050',
        ),
      );

      expect(find.text('Saldo inicial'), findsNothing);
    });

    testWidgets('alta de tarjeta: aparece "Deuda actual", no "Saldo inicial"', (
      tester,
    ) async {
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          type: AccountType.card,
        ),
      );

      expect(find.text('Deuda actual'), findsOneWidget);
      expect(find.text('Saldo inicial'), findsNothing);
    });

    testWidgets('edición de tarjeta: NO aparece "Deuda actual"',
        (tester) async {
      // En una tarjeta existente la deuda es derivada; solo se ajusta desde el
      // detalle, nunca se reescribe en el formulario.
      await pumpForm(
        tester,
        const AccountFormState(
          status: AccountFormStatus.ready,
          id: 'card-1',
          type: AccountType.card,
          name: 'Visa Oro',
        ),
      );

      expect(find.text('Deuda actual'), findsNothing);
      expect(find.text('Saldo inicial'), findsNothing);
    });
  });

  testWidgets(
      'un nombre vacío muestra el error de obligatorio, no el de longitud '
      '(fix #15b)', (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
        failure: ValidationFailure('nope', field: 'name'),
      ),
    );

    expect(find.text('Ingresa un nombre para la cuenta.'), findsOneWidget);
    expect(
      find.text('Escribe un nombre de hasta 100 caracteres.'),
      findsNothing,
    );
  });

  testWidgets('un nombre que excede el límite muestra el error de longitud',
      (tester) async {
    await pumpForm(
      tester,
      AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
        name: 'a' * 101,
        failure: const ValidationFailure('nope', field: 'name'),
      ),
    );

    expect(
      find.text('Escribe un nombre de hasta 100 caracteres.'),
      findsOneWidget,
    );
    expect(find.text('Ingresa un nombre para la cuenta.'), findsNothing);
  });

  testWidgets('sin tipo elegido, el error apunta al selector de tipo',
      (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        failure: ValidationFailure('nope', field: AccountFormState.fieldType),
      ),
    );

    expect(find.text('Elige el tipo de cuenta.'), findsOneWidget);
  });

  testWidgets('guardar en el header pide el submit al cubit', (tester) async {
    when(() => cubit.submit(confirmed: any(named: 'confirmed')))
        .thenAnswer((_) async {});
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
      ),
    );

    // Dos íconos LucideIcons.check en pantalla: el del header y el del botón
    // "Guardar cuenta" al final del cuerpo. Se distingue por el ancestro.
    await tester.tap(
      find.ancestor(
        of: find.byIcon(LucideIcons.check),
        matching: find.byType(PageHeaderCircleButton),
      ),
    );
    verify(() => cubit.submit()).called(1);
  });

  testWidgets('guardar en el botón del cuerpo pide el submit al cubit',
      (tester) async {
    when(() => cubit.submit(confirmed: any(named: 'confirmed')))
        .thenAnswer((_) async {});
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.ready,
        type: AccountType.bank,
      ),
    );

    expect(find.text('Guardar cuenta'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar cuenta'));
    await tester.tap(find.text('Guardar cuenta'));
    verify(() => cubit.submit()).called(1);
  });

  testWidgets('mientras guarda, el botón queda deshabilitado', (tester) async {
    await pumpForm(
      tester,
      const AccountFormState(
        status: AccountFormStatus.saving,
        type: AccountType.bank,
      ),
    );

    final save = tester.widget<PageHeaderCircleButton>(
      find.ancestor(
        of: find.byIcon(LucideIcons.check),
        matching: find.byType(PageHeaderCircleButton),
      ),
    );
    expect(save.onPressed, isNull);
  });
}

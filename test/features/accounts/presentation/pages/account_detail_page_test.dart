import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/page_header_circle_button.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_number_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';

class MockAccountDetailCubit extends MockCubit<AccountDetailState>
    implements AccountDetailCubit {}

void main() {
  late MockAccountDetailCubit cubit;

  final eye = find.byIcon(LucideIcons.eye);
  final eyeOff = find.byIcon(LucideIcons.eyeOff);
  final copy = find.byIcon(LucideIcons.copy);

  const fullNumber = '00123456784321';

  /// A card, identified only by its last 4 (HU-03: a card never stores a PAN).
  final card = buildAccount(
    id: 'card-1',
    name: 'Visa Oro',
    type: AccountType.card,
    last4: '4321',
    creditLimitMinor: 300000000,
    statementDay: 15,
    paymentDueDay: 5,
    cardBalancePrimary: CardBalanceView.debt,
  );

  /// A bank account, which *does* keep a full number in secure storage.
  final bank = buildAccount(name: 'Bancolombia', last4: '4321');

  setUp(() => cubit = MockAccountDetailCubit());

  Future<void> pumpDetail(WidgetTester tester, AccountDetailState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountDetailCubit>.value(
          value: cubit,
          child: AccountDetailPage(onEdit: (_) {}, onAddAccount: () {}),
        ),
      ),
    );
  }

  AccountDetailState readyState(Account account, {String? revealedNumber}) =>
      AccountDetailState(
        status: AccountDetailStatus.ready,
        entry: buildAccountWithBalance(
          account: account,
          balanceMinor: account.isCard ? -45000000 : 450050,
        ),
        revealedNumber: revealedNumber,
      );

  group('HU-03 — el detalle de una tarjeta no ofrece PAN', () {
    testWidgets(
        'ni número completo, ni ojo, ni copiar: la tarjeta solo muestra last4',
        (tester) async {
      await pumpDetail(tester, readyState(card));

      // La fila existe (el last4 identifica la tarjeta)...
      expect(find.byType(AccountNumberRow), findsOneWidget);
      expect(find.text('••••••• 4321'), findsOneWidget);

      // ...pero la página la arma en modo tarjeta: sin nada que revelar.
      final row =
          tester.widget<AccountNumberRow>(find.byType(AccountNumberRow));
      expect(row.isCard, isTrue);
      expect(eye, findsNothing);
      expect(eyeOff, findsNothing);
      expect(copy, findsNothing);
      expect(find.text(fullNumber), findsNothing);
    });

    testWidgets('la tarjeta nunca le pide el número al almacén seguro',
        (tester) async {
      await pumpDetail(tester, readyState(card));

      // Sin ojo no hay forma de disparar la lectura: el PAN de una tarjeta no
      // existe, así que el detalle jamás debe intentar leerlo ni copiarlo.
      expect(
        find.byType(PageHeaderCircleButton),
        findsNWidgets(2),
      ); // volver + "Editar", nada de acciones sobre el número
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      verifyNever(cubit.revealNumber);
      verifyNever(cubit.copyNumber);
    });
  });

  group('HU-03 — el detalle de una cuenta bancaria sí ofrece el número', () {
    testWidgets('arranca enmascarado, con ojo y copiar', (tester) async {
      await pumpDetail(tester, readyState(bank));

      final row =
          tester.widget<AccountNumberRow>(find.byType(AccountNumberRow));
      expect(row.isCard, isFalse);
      expect(find.text('••••••• 4321'), findsOneWidget);
      expect(find.text(fullNumber), findsNothing);
      expect(eye, findsOneWidget);
      expect(copy, findsOneWidget);
    });

    testWidgets('el ojo le pide al cubit revelar el número', (tester) async {
      when(cubit.revealNumber).thenAnswer((_) async {});
      await pumpDetail(tester, readyState(bank));

      await tester.tap(eye);
      await tester.pump();

      verify(cubit.revealNumber).called(1);
    });

    testWidgets('revelado muestra el número entero y ofrece ocultarlo',
        (tester) async {
      await pumpDetail(tester, readyState(bank, revealedNumber: fullNumber));

      expect(find.text(fullNumber), findsOneWidget);
      expect(eyeOff, findsOneWidget);
      expect(eye, findsNothing);
    });

    testWidgets('copiar pasa por el cubit (que usa SecureClipboard)',
        (tester) async {
      when(cubit.copyNumber).thenAnswer((_) async => true);
      await pumpDetail(tester, readyState(bank));

      await tester.tap(copy);
      await tester.pump();

      verify(cubit.copyNumber).called(1);
    });
  });

  testWidgets('una cuenta sin número no muestra la fila', (tester) async {
    // `buildAccount` no trae last4: efectivo, por ejemplo, no lleva número.
    await pumpDetail(tester, readyState(buildAccount()));

    expect(find.byType(AccountNumberRow), findsNothing);
  });
}

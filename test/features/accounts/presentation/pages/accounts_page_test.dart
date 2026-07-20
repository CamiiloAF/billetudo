import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/empty_state.dart';
import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/accounts_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_card.dart';
import 'package:billetudo/features/accounts/presentation/widgets/accounts_error_view.dart';
import 'package:billetudo/features/accounts/presentation/widgets/accounts_total_card.dart';
import 'package:billetudo/features/accounts/presentation/widgets/credit_card_account_row.dart';
import 'package:billetudo/features/accounts/presentation/widgets/skeleton_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';

class MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

void main() {
  late MockAccountsListCubit cubit;

  final entries = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a', name: 'Bancolombia'),
      balanceMinor: 450050,
    ),
    buildAccountWithBalance(
      account:
          buildCard(id: 'b', name: 'Visa Oro', creditLimitMinor: 300000000),
      balanceMinor: -45000000,
    ),
  ];

  setUp(() => cubit = MockAccountsListCubit());

  /// Drives the page straight from the cubit's state: each of the four states
  /// is one stubbed value.
  Future<void> pumpPage(WidgetTester tester, AccountsListState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountsListCubit>.value(
          value: cubit,
          child: AccountsPage(
            onAddAccount: () {},
            onOpenAccount: (_) {},
            onOpenArchived: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('carga: 4 Skeleton Row, sin lista ni error', (tester) async {
    await pumpPage(tester, const AccountsListState());

    expect(find.byType(SkeletonRow), findsNWidgets(4));
    expect(find.byType(AccountCard), findsNothing);
    expect(find.byType(AccountsErrorView), findsNothing);
  });

  testWidgets('vacío: mensaje neutral y CTA "Agregar cuenta"', (tester) async {
    await pumpPage(
      tester,
      const AccountsListState(status: AccountsListStatus.ready),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Aún no has agregado ninguna cuenta'), findsOneWidget);
    // Botón del header + CTA del estado vacío.
    expect(find.text('Agregar cuenta'), findsOneWidget);
    expect(find.byType(SkeletonRow), findsNothing);
  });

  testWidgets('con datos: Total Card, fila normal y fila de tarjeta',
      (tester) async {
    await pumpPage(
      tester,
      AccountsListState(
        status: AccountsListStatus.ready,
        accounts: entries,
        overview: AccountsOverview.from(entries),
      ),
    );

    expect(find.byType(AccountsTotalCard), findsOneWidget);
    expect(find.text('Patrimonio total'), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
    expect(find.byType(CreditCardAccountRow), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('error: icono neutral, recordatorio local-first y Reintentar',
      (tester) async {
    await pumpPage(
      tester,
      const AccountsListState(status: AccountsListStatus.failure),
    );

    expect(find.byType(AccountsErrorView), findsOneWidget);
    expect(find.text('No pudimos cargar tus cuentas'), findsOneWidget);
    expect(
      find.text(
        'Tus datos siguen guardados en tu dispositivo. Intenta de nuevo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('Reintentar vuelve a pedir la carga', (tester) async {
    when(cubit.start).thenAnswer((_) async {});
    await pumpPage(
      tester,
      const AccountsListState(status: AccountsListStatus.failure),
    );

    await tester.tap(find.text('Reintentar'));
    verify(cubit.start).called(1);
  });

  testWidgets(
      'el Total Card no suma monedas distintas: un subtotal por cada '
      'una', (tester) async {
    final mixed = [
      buildAccountWithBalance(
        account: buildAccount(id: 'a', name: 'COP'),
        balanceMinor: 100000,
      ),
      buildAccountWithBalance(
        account: buildAccount(id: 'b', name: 'USD', currency: 'USD'),
        balanceMinor: 20000,
      ),
    ];
    await pumpPage(
      tester,
      AccountsListState(
        status: AccountsListStatus.ready,
        accounts: mixed,
        overview: AccountsOverview.from(mixed),
      ),
    );

    // Dos subtotales, uno por moneda, y ninguna cifra cruzada inventada.
    expect(find.byType(CurrencySubtotalLine), findsNWidgets(2));
  });

  testWidgets('tocar una cuenta la abre', (tester) async {
    when(() => cubit.state).thenReturn(
      AccountsListState(status: AccountsListStatus.ready, accounts: entries),
    );
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AccountsListCubit>.value(
          value: cubit,
          child: AccountsPage(
            onAddAccount: () {},
            onOpenAccount: (id) => opened = id,
            onOpenArchived: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Bancolombia'));
    expect(opened, 'a');
  });
}

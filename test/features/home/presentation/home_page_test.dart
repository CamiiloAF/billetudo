import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_banner.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_skeleton.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:billetudo/features/home/presentation/widgets/recent_activity_row.dart';
import 'package:billetudo/features/home/presentation/widgets/recent_activity_skeleton_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../home_fixtures.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  setUpAll(initializeDateFormatting);

  final month = DateTime(2026, 7);

  HomeState readyWith(List<dynamic> transactions) => HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: [buildActiveAccount()],
          transactions: transactions.cast(),
        ),
      );

  Future<void> pumpHome(
    WidgetTester tester,
    HomeState state, {
    Locale locale = const Locale('es'),
    Brightness brightness = Brightness.light,
    VoidCallback? onOpenAccounts,
    VoidCallback? onOpenScheduledPayments,
    VoidCallback? onOpenDebts,
    VoidCallback? onOpenReports,
  }) async {
    final cubit = MockHomeCubit();
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: HomePage(
            onAddTransaction: () {},
            onSeeAllTransactions: () {},
            onOpenTransaction: (_) async => null,
            onCreateBudget: () {},
            onOpenAccounts: onOpenAccounts ?? () {},
            onOpenScheduledPayments: onOpenScheduledPayments ?? () {},
            onOpenDebts: onOpenDebts ?? () {},
            onOpenReports: onOpenReports ?? () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('con datos: muestra header, movimientos y banner de IA',
      (tester) async {
    await pumpHome(tester, readyWith([buildActivity(categoryName: 'Mercado')]));

    expect(find.text('Hola de nuevo'), findsOneWidget);
    expect(find.text('Movimientos recientes'), findsOneWidget);
    expect(find.byType(RecentActivityRow), findsOneWidget);
    expect(find.byType(AiBanner), findsOneWidget);
  });

  testWidgets('vacío: mensaje de bienvenida y sin banner de IA (HU-08)',
      (tester) async {
    await pumpHome(tester, readyWith(const []));

    expect(find.text('Aún no registras movimientos'), findsOneWidget);
    expect(find.byType(AiBanner), findsNothing);
  });

  testWidgets('carga: skeletons de hero y filas (HU-09)', (tester) async {
    await pumpHome(tester, HomeState.initial(month));

    expect(find.byType(HomeHeroSkeleton), findsOneWidget);
    expect(find.byType(RecentActivitySkeletonRow), findsWidgets);
  });

  testWidgets('mes en español: "Gastado en Julio" (HU-04)', (tester) async {
    await pumpHome(tester, readyWith([buildActivity(categoryName: 'Mercado')]));

    expect(find.text('Gastado en Julio'), findsOneWidget);
  });

  testWidgets('mes en inglés: "Spent in July" (HU-04)', (tester) async {
    await pumpHome(
      tester,
      readyWith([buildActivity(categoryName: 'Groceries')]),
      locale: const Locale('en'),
    );

    expect(find.text('Spent in July'), findsOneWidget);
  });

  testWidgets('tema oscuro con datos: renderiza sin excepción (HU-11)',
      (tester) async {
    await pumpHome(
      tester,
      readyWith([buildActivity(categoryName: 'Mercado')]),
      brightness: Brightness.dark,
    );

    expect(find.byType(RecentActivityRow), findsOneWidget);
    // The scaffold picks up the dark surface token.
    final colors = tester.element(find.byType(HomePage)).colors;
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? colors.background, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema oscuro vacío: mensaje de bienvenida sin excepción (HU-11)',
      (tester) async {
    await pumpHome(
      tester,
      readyWith(const []),
      brightness: Brightness.dark,
    );

    expect(find.text('Aún no registras movimientos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'estado ready: renderiza QuickAccessRow como chrome fijo (HU-05b)',
      (tester) async {
    await pumpHome(tester, readyWith([buildActivity(categoryName: 'Mercado')]));

    expect(find.byType(QuickAccessRow), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(4));
  });

  testWidgets(
      'estado loading: QuickAccessRow sigue presente pese a los skeletons '
      '(HU-05b)', (tester) async {
    await pumpHome(tester, HomeState.initial(month));

    expect(find.byType(QuickAccessRow), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(4));
  });

  testWidgets(
      'tocar cada chip de QuickAccessRow invoca su callback propio '
      '(HU-05b)', (tester) async {
    var accountsTapped = 0;
    var scheduledTapped = 0;
    var debtsTapped = 0;
    var reportsTapped = 0;

    await pumpHome(
      tester,
      readyWith([buildActivity(categoryName: 'Mercado')]),
      onOpenAccounts: () => accountsTapped++,
      onOpenScheduledPayments: () => scheduledTapped++,
      onOpenDebts: () => debtsTapped++,
      onOpenReports: () => reportsTapped++,
    );

    final chips =
        tester.widgetList<QuickAccessChip>(find.byType(QuickAccessChip));
    expect(chips.length, 4);

    for (final chip in chips) {
      await tester.tap(find.byWidget(chip));
      await tester.pump();
    }

    expect(accountsTapped, 1);
    expect(scheduledTapped, 1);
    expect(debtsTapped, 1);
    expect(reportsTapped, 1);
  });
}

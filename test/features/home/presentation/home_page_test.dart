import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/home/presentation/widgets/ai_banner.dart';
import 'package:billetudo/features/home/presentation/widgets/home_header.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_skeleton.dart';
import 'package:billetudo/features/home/presentation/widgets/month_selector_chip.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_settings_button.dart';
import 'package:billetudo/features/home/presentation/widgets/recent_activity_row.dart';
import 'package:billetudo/features/home/presentation/widgets/recent_activity_skeleton_row.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/month_picker_sheet.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/sync_status_sheet.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../home_fixtures.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

void main() {
  setUpAll(initializeDateFormatting);

  final month = DateTime(2026, 7);

  HomeState readyWith(
    List<dynamic> transactions, {
    BudgetWithProgress? budgetProgress,
  }) =>
      HomeState(
        status: HomeStatus.ready,
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: [buildActiveAccount()],
          transactions: transactions.cast(),
          budgetProgress: budgetProgress,
        ),
      );

  Future<void> pumpHome(
    WidgetTester tester,
    HomeState state, {
    Locale locale = const Locale('es'),
    Brightness brightness = Brightness.light,
    VoidCallback? onOpenAccounts,
    ValueChanged<String>? onOpenAccountMovements,
    VoidCallback? onOpenScheduledPayments,
    VoidCallback? onOpenDebts,
    VoidCallback? onOpenReports,
    VoidCallback? onOpenQuickAccessOrder,
    VoidCallback? onOpenLogin,
    VoidCallback? onAddTransaction,
    ValueChanged<String>? onOpenBudget,
    MockHomeCubit? cubit,
  }) async {
    final homeCubit = cubit ?? MockHomeCubit();
    when(() => homeCubit.state).thenReturn(state);
    whenListen(
      homeCubit,
      const Stream<HomeState>.empty(),
      initialState: state,
    );

    final appSettingsCubit = MockAppSettingsCubit();
    when(() => appSettingsCubit.state).thenReturn(const AppSettingsState());
    whenListen(
      appSettingsCubit,
      const Stream<AppSettingsState>.empty(),
      initialState: const AppSettingsState(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<HomeCubit>.value(value: homeCubit),
            BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
          ],
          child: HomePage(
            onAddTransaction: onAddTransaction ?? () {},
            onSeeAllTransactions: () {},
            onOpenTransaction: (_) async => null,
            onCreateBudget: () {},
            onOpenBudget: onOpenBudget ?? (_) {},
            onOpenAccounts: onOpenAccounts ?? () {},
            onOpenAccountMovements: onOpenAccountMovements ?? (_) {},
            onOpenScheduledPayments: onOpenScheduledPayments ?? () {},
            onOpenDebts: onOpenDebts ?? () {},
            onOpenReports: onOpenReports ?? () {},
            onOpenQuickAccessOrder: onOpenQuickAccessOrder ?? () {},
            onOpenLogin: onOpenLogin ?? () {},
            onOpenSyncStatus: () {},
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
    // The balance strip (bugfix item 8) adds height above the feed, so the AI
    // banner at the bottom of the sliver list can start below the cache
    // extent; scroll the vertical list until it builds.
    await tester.scrollUntilVisible(
      find.byType(AiBanner),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.byType(QuickAccessChip), findsNWidgets(3));
  });

  testWidgets(
      'estado loading: QuickAccessRow sigue presente pese a los skeletons '
      '(HU-05b)', (tester) async {
    await pumpHome(tester, HomeState.initial(month));

    expect(find.byType(QuickAccessRow), findsOneWidget);
    expect(find.byType(QuickAccessChip), findsNWidgets(3));
  });

  testWidgets(
      'tocar la ruedita de QuickAccessRow invoca onOpenQuickAccessOrder, '
      'no un callback de destino', (tester) async {
    var orderTapped = 0;
    var scheduledTapped = 0;

    await pumpHome(
      tester,
      readyWith([buildActivity(categoryName: 'Mercado')]),
      onOpenScheduledPayments: () => scheduledTapped++,
      onOpenQuickAccessOrder: () => orderTapped++,
    );

    await tester.tap(find.byType(QuickAccessSettingsButton));
    await tester.pump();

    expect(orderTapped, 1);
    expect(scheduledTapped, 0);
  });

  testWidgets(
      'tocar cada chip de QuickAccessRow invoca su callback propio '
      '(HU-05b)', (tester) async {
    var scheduledTapped = 0;
    var debtsTapped = 0;
    var reportsTapped = 0;

    await pumpHome(
      tester,
      readyWith([buildActivity(categoryName: 'Mercado')]),
      onOpenScheduledPayments: () => scheduledTapped++,
      onOpenDebts: () => debtsTapped++,
      onOpenReports: () => reportsTapped++,
    );

    final chips =
        tester.widgetList<QuickAccessChip>(find.byType(QuickAccessChip));
    expect(chips.length, 3);

    for (final chip in chips) {
      await tester.tap(find.byWidget(chip));
      await tester.pump();
    }

    expect(scheduledTapped, 1);
    expect(debtsTapped, 1);
    expect(reportsTapped, 1);
  });

  group('icono de sync interactivo (bugfix item 6)', () {
    const user = AuthUser(
      id: 'u-1',
      displayName: 'Camila',
      provider: AuthProvider.google,
    );

    testWidgets('offline sin sesión: navega a login, sin abrir sheet',
        (tester) async {
      var loginTapped = 0;
      await pumpHome(
        tester,
        readyWith(const []).copyWith(syncStatus: HomeSyncStatus.offline),
        onOpenLogin: () => loginTapped++,
      );

      await tester.tap(find.byType(SyncIndicator));
      await tester.pumpAndSettle();

      expect(loginTapped, 1);
      expect(find.text('Sin conexión'), findsNothing);
    });

    testWidgets('offline con sesión: abre el sheet "Sin conexión", no login',
        (tester) async {
      var loginTapped = 0;
      await pumpHome(
        tester,
        readyWith(const []).copyWith(
          syncStatus: HomeSyncStatus.offline,
          user: user,
          updateUser: true,
        ),
        onOpenLogin: () => loginTapped++,
      );

      await tester.tap(find.byType(SyncIndicator));
      await tester.pumpAndSettle();

      expect(loginTapped, 0);
      expect(find.byType(SyncStatusSheet), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);
    });

    testWidgets('sincronizado: abre el sheet "Todo a salvo"', (tester) async {
      await pumpHome(
        tester,
        readyWith(const []).copyWith(syncStatus: HomeSyncStatus.synced),
      );

      await tester.tap(find.byType(SyncIndicator));
      await tester.pumpAndSettle();

      expect(find.byType(SyncStatusSheet), findsOneWidget);
      expect(find.text('Todo a salvo'), findsOneWidget);
    });
  });

  group('gate de cuenta en el FAB (15-gate-cuenta.md HU-02/HU-04)', () {
    void registerAccountGate({required bool hasAny}) {
      final hasAnyActiveAccount = MockHasAnyActiveAccount();
      when(hasAnyActiveAccount.call).thenAnswer((_) => Stream.value(hasAny));
      getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
      final watchActiveAccountsCount = MockWatchActiveAccountsCount();
      when(watchActiveAccountsCount.call)
          .thenAnswer((_) => Stream.value(hasAny ? 1 : 0));
      getIt.registerFactory<WatchActiveAccountsCount>(
        () => watchActiveAccountsCount,
      );
    }

    tearDown(getIt.reset);

    testWidgets(
        'con al menos una cuenta activa, tocar el FAB invoca '
        'onAddTransaction directamente, sin mostrar el puente', (tester) async {
      registerAccountGate(hasAny: true);
      var tapped = 0;
      await pumpHome(
        tester,
        readyWith([buildActivity(categoryName: 'Mercado')]),
        onAddTransaction: () => tapped++,
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.byType(AccountGateBridgeSheet), findsNothing);
    });

    testWidgets(
        'sin ninguna cuenta activa, tocar el FAB abre el puente en vez de '
        'invocar onAddTransaction — el control nunca aparece deshabilitado',
        (tester) async {
      registerAccountGate(hasAny: false);
      var tapped = 0;
      await pumpHome(
        tester,
        readyWith([buildActivity(categoryName: 'Mercado')]),
        onAddTransaction: () => tapped++,
      );

      // `AppFab.onPressed` is non-nullable (unlike Material's own
      // `FloatingActionButton`), so the control is never disabled by
      // construction — tapping it always reaches the gate check below.
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      expect(tapped, 0);
    });

    testWidgets(
        'cancelar el puente ("Ahora no") deja al usuario en Home sin '
        'invocar onAddTransaction (HU-01: exactamente donde estaba)',
        (tester) async {
      registerAccountGate(hasAny: false);
      var tapped = 0;
      await pumpHome(
        tester,
        readyWith([buildActivity(categoryName: 'Mercado')]),
        onAddTransaction: () => tapped++,
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AccountGateBridgeSheet));
      final l10n = AppLocalizations.of(context);
      await tester.tap(find.text(l10n.accountGateNotNow));
      await tester.pumpAndSettle();

      expect(tapped, 0);
      expect(find.byType(AccountGateBridgeSheet), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('hero con presupuesto destacado — stepper de período (HU-05)', () {
    testWidgets(
        'sin presupuesto destacado: hay MonthSelectorChip (HU-04), nunca el '
        'stepper de presupuesto', (tester) async {
      await pumpHome(tester, readyWith([buildActivity()]));

      expect(find.byType(HeroPeriodStepper), findsNothing);
      expect(find.byType(MonthSelectorChip), findsOneWidget);
    });

    testWidgets(
        'con presupuesto destacado: el stepper reemplaza el '
        'MonthSelectorChip', (tester) async {
      final budgetProgress = buildHomeBudgetProgress();
      await pumpHome(
        tester,
        readyWith([buildActivity()], budgetProgress: budgetProgress),
      );

      expect(find.byType(HeroPeriodStepper), findsOneWidget);
      expect(find.byType(MonthSelectorChip), findsNothing);
    });

    testWidgets('criterio 6: tocar el hero navega a AppRoutes.budget(id)',
        (tester) async {
      final budgetProgress = buildHomeBudgetProgress(id: 'budget-42');
      var openedId = '';
      await pumpHome(
        tester,
        readyWith([buildActivity()], budgetProgress: budgetProgress),
        onOpenBudget: (id) => openedId = id,
      );

      await tester.tap(find.byType(HomeHeroCard));
      await tester.pump();

      expect(openedId, 'budget-42');
    });

    testWidgets(
        'criterio 4: los chevrons del stepper llaman a '
        'HomeCubit.previousPeriod/nextPeriod', (tester) async {
      final cubit = MockHomeCubit();
      when(cubit.previousPeriod).thenReturn(null);
      when(cubit.nextPeriod).thenReturn(null);
      final budgetProgress = buildHomeBudgetProgress();
      await pumpHome(
        tester,
        readyWith([buildActivity()], budgetProgress: budgetProgress),
        cubit: cubit,
      );

      // The fixture window has `hasNext: true` — only the trailing chevron
      // is enabled.
      await tester.tap(find.byType(HeroPeriodChevron).last);
      await tester.pump();

      verify(cubit.nextPeriod).called(1);
      verifyNever(cubit.previousPeriod);
    });
  });

  group('picker de mes del hero, sin presupuesto destacado (HU-04)', () {
    testWidgets(
        'tocar el MonthSelectorChip abre MonthPickerSheet, seeded con el '
        'mes visible del snapshot', (tester) async {
      await pumpHome(tester, readyWith([buildActivity()]));

      await tester.tap(find.byType(MonthSelectorChip));
      await tester.pumpAndSettle();

      expect(find.byType(MonthPickerSheet), findsOneWidget);
      // `readyWith`'s snapshot month is July 2026 (`month` at the top of
      // this file) — the sheet must seed its selection from it, not "now".
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets(
        'elegir un mes en la hoja llama a HomeCubit.selectMonth y cierra '
        'la hoja', (tester) async {
      final cubit = MockHomeCubit();
      when(() => cubit.selectMonth(any())).thenReturn(null);
      await pumpHome(
        tester,
        readyWith([buildActivity()]),
        cubit: cubit,
      );

      await tester.tap(find.byType(MonthSelectorChip));
      await tester.pumpAndSettle();
      expect(find.byType(MonthPickerSheet), findsOneWidget);

      // Julio is already selected (the fixture month); tap a different,
      // enabled month cell — Junio ("Jun"), one column to the left.
      await tester.tap(find.text('Jun'));
      await tester.pumpAndSettle();

      verify(() => cubit.selectMonth(DateTime(2026, 6))).called(1);
      expect(find.byType(MonthPickerSheet), findsNothing);
    });
  });
}

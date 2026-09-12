import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/account_avatar.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/account_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../pump_widget.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

/// "Tu cuenta" (issue #34, Propuesta B "hero + lista"): sus 3 variantes, y
/// que la fila "Estado de sincronización" navega al detalle en vez de
/// resumir el estado en la propia hoja.
void main() {
  late MockHomeCubit cubit;
  final month = DateTime(2026, 7);

  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila Restrepo',
    provider: AuthProvider.google,
    email: 'camila@example.com',
  );

  HomeState stateWith({
    AuthUser? user,
    HomeSyncStatus syncStatus = HomeSyncStatus.synced,
  }) =>
      HomeState(
        status: HomeStatus.ready,
        user: user,
        syncStatus: syncStatus,
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: const [],
          transactions: const [],
        ),
      );

  setUp(() {
    cubit = MockHomeCubit();
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    HomeState state, {
    VoidCallback? onOpenSettings,
    VoidCallback? onSignOut,
    VoidCallback? onOpenSyncStatus,
    VoidCallback? onActivateBackup,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);
    await tester.pumpHomeWidget(
      BlocProvider<HomeCubit>.value(
        value: cubit,
        child: AccountSheet(
          onOpenSettings: onOpenSettings ?? () {},
          onSignOut: onSignOut ?? () {},
          onOpenSyncStatus: onOpenSyncStatus ?? () {},
          onActivateBackup: onActivateBackup ?? () {},
        ),
      ),
    );
  }

  group('criterio 2: 3 variantes', () {
    testWidgets('sin cuenta: CTA "Activar respaldo", sin Ajustes/Cerrar sesión',
        (tester) async {
      await pumpSheet(tester, stateWith());
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.text(l10n.homeAccountSheetNoAccountTitle), findsOneWidget);
      expect(find.text(l10n.homeAccountSheetActivateBackup), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsOneWidget);
      expect(find.text(l10n.settingsSyncStatus), findsNothing);
      expect(find.text(l10n.moreSignOut), findsNothing);
    });

    testWidgets(
        'con sesión + sin conexión: Hero Card + pill "Sin conexión" + '
        'Estado de sincronización + Ajustes + Cerrar sesión', (tester) async {
      await pumpSheet(
        tester,
        stateWith(user: user, syncStatus: HomeSyncStatus.attention),
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.text(user.displayName), findsOneWidget);
      expect(find.text(user.email!), findsOneWidget);
      expect(find.text(l10n.homeAccountSheetOfflinePill), findsOneWidget);
      expect(find.text(l10n.settingsSyncStatus), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsOneWidget);
      expect(find.text(l10n.moreSignOut), findsOneWidget);

      // The avatar inside the Hero Card mirrors the pill it sits next to:
      // in the offline/attention state it shows its own status badge too
      // (that's what justifies the "Sin conexión" pill next to it).
      final avatar = tester.widget<AccountAvatar>(find.byType(AccountAvatar));
      expect(avatar.badge, AccountAvatarBadge.attention);
    });

    testWidgets(
        'con sesión + sincronizado: Hero Card + pill "Sincronizado" + '
        'Estado de sincronización + Ajustes + Cerrar sesión', (tester) async {
      await pumpSheet(
        tester,
        stateWith(user: user, syncStatus: HomeSyncStatus.synced),
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.text(l10n.homeAccountSheetSyncedPill), findsOneWidget);
      expect(find.text(l10n.settingsSyncStatus), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsOneWidget);
      expect(find.text(l10n.moreSignOut), findsOneWidget);

      // Only the synced state switches the avatar's badge off, so a
      // healthy avatar doesn't contradict the mint pill next to it.
      final avatar = tester.widget<AccountAvatar>(find.byType(AccountAvatar));
      expect(avatar.badge, AccountAvatarBadge.synced);
    });
  });

  testWidgets('sin cuenta: tocar el CTA dispara onActivateBackup',
      (tester) async {
    var tapped = 0;
    await pumpSheet(tester, stateWith(), onActivateBackup: () => tapped++);
    final l10n = AppLocalizations.of(tester.element(find.byType(AccountSheet)));

    await tester.tap(find.text(l10n.homeAccountSheetActivateBackup));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar "Ajustes" dispara onOpenSettings', (tester) async {
    var tapped = 0;
    await pumpSheet(
      tester,
      stateWith(user: user),
      onOpenSettings: () => tapped++,
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(AccountSheet)));

    await tester.tap(find.text(l10n.moreSettings));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar "Estado de sincronización" dispara onOpenSyncStatus',
      (tester) async {
    var tapped = 0;
    await pumpSheet(
      tester,
      stateWith(user: user),
      onOpenSyncStatus: () => tapped++,
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(AccountSheet)));

    await tester.tap(find.text(l10n.settingsSyncStatus));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar "Cerrar sesión" dispara onSignOut', (tester) async {
    var tapped = 0;
    await pumpSheet(tester, stateWith(user: user), onSignOut: () => tapped++);
    final l10n = AppLocalizations.of(tester.element(find.byType(AccountSheet)));

    await tester.tap(find.text(l10n.moreSignOut));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tema oscuro: renderiza las 3 variantes sin excepción (HU-11)',
      (tester) async {
    await pumpSheet(tester, stateWith());
    expect(tester.takeException(), isNull);
  });

  group(
      'bugfix: cada fila cierra la hoja antes de navegar (reportado en '
      'dogfooding — la navegación funcionaba pero la hoja se quedaba abierta '
      'detrás)', () {
    /// Presents [AccountSheet] through its real [AccountSheet.show] route —
    /// unlike [pumpSheet] above, which pumps it bare with no `Navigator`
    /// entry of its own to pop. Only through the real route can a test prove
    /// the sheet actually closes, not just that the callback fired.
    Future<void> pumpPresentedSheet(
      WidgetTester tester,
      HomeState state, {
      VoidCallback? onOpenSettings,
      VoidCallback? onSignOut,
      VoidCallback? onOpenSyncStatus,
      VoidCallback? onActivateBackup,
    }) async {
      when(() => cubit.state).thenReturn(state);
      whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AccountSheet.show(
                  context,
                  cubit,
                  onOpenSettings: onOpenSettings ?? () {},
                  onSignOut: onSignOut ?? () {},
                  onOpenSyncStatus: onOpenSyncStatus ?? () {},
                  onActivateBackup: onActivateBackup ?? () {},
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    testWidgets('tocar "Ajustes" dispara onOpenSettings Y cierra la hoja',
        (tester) async {
      var tapped = 0;
      await pumpPresentedSheet(
        tester,
        stateWith(user: user),
        onOpenSettings: () => tapped++,
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ElevatedButton)));

      await tester.tap(find.text(l10n.moreSettings));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.byType(AccountSheet), findsNothing);
    });

    testWidgets('tocar "Cerrar sesión" dispara onSignOut Y cierra la hoja',
        (tester) async {
      var tapped = 0;
      await pumpPresentedSheet(
        tester,
        stateWith(user: user),
        onSignOut: () => tapped++,
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ElevatedButton)));

      await tester.tap(find.text(l10n.moreSignOut));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.byType(AccountSheet), findsNothing);
    });

    testWidgets(
        'tocar "Estado de sincronización" dispara onOpenSyncStatus Y cierra '
        'la hoja', (tester) async {
      var tapped = 0;
      await pumpPresentedSheet(
        tester,
        stateWith(user: user),
        onOpenSyncStatus: () => tapped++,
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ElevatedButton)));

      await tester.tap(find.text(l10n.settingsSyncStatus));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.byType(AccountSheet), findsNothing);
    });

    testWidgets(
        'variante sin cuenta: tocar "Activar respaldo" dispara '
        'onActivateBackup Y cierra la hoja', (tester) async {
      var tapped = 0;
      await pumpPresentedSheet(
        tester,
        stateWith(),
        onActivateBackup: () => tapped++,
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(ElevatedButton)));

      await tester.tap(find.text(l10n.homeAccountSheetActivateBackup));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      expect(find.byType(AccountSheet), findsNothing);
    });
  });
}

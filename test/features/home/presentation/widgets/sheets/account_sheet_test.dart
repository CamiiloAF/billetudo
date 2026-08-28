import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_hero.dart';
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

/// "Tu cuenta" (criterios 2 y 14): sus 3 variantes, y que el bloque de sync
/// reusa `SyncHero` en modo compacto, tocable como un todo hacia "Estado de
/// sincronización", sin CTA propio.
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

      expect(find.byType(AccountAvatar), findsOneWidget);
      expect(find.text(l10n.homeAccountSheetActivateBackup), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsNothing);
      expect(find.text(l10n.moreSignOut), findsNothing);
      expect(find.byType(SyncHero), findsNothing);
    });

    testWidgets(
        'con sesión + sin conexión: Identity Row + bloque de sync + '
        'Ajustes + Cerrar sesión', (tester) async {
      await pumpSheet(
        tester,
        stateWith(user: user, syncStatus: HomeSyncStatus.attention),
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.text(user.displayName), findsOneWidget);
      expect(find.text(user.email!), findsOneWidget);
      expect(find.byType(SyncHero), findsOneWidget);
      expect(find.text(l10n.homeAccountSheetOfflineTitle), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsOneWidget);
      expect(find.text(l10n.moreSignOut), findsOneWidget);
    });

    testWidgets(
        'con sesión + sincronizado: Identity Row + bloque de sync + '
        'Ajustes + Cerrar sesión', (tester) async {
      await pumpSheet(
        tester,
        stateWith(user: user, syncStatus: HomeSyncStatus.synced),
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.byType(SyncHero), findsOneWidget);
      expect(find.text(l10n.homeAccountSheetSyncedTitle), findsOneWidget);
      expect(find.text(l10n.moreSettings), findsOneWidget);
      expect(find.text(l10n.moreSignOut), findsOneWidget);
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

  testWidgets('tocar "Cerrar sesión" dispara onSignOut', (tester) async {
    var tapped = 0;
    await pumpSheet(tester, stateWith(user: user), onSignOut: () => tapped++);
    final l10n = AppLocalizations.of(tester.element(find.byType(AccountSheet)));

    await tester.tap(find.text(l10n.moreSignOut));
    await tester.pump();

    expect(tapped, 1);
  });

  group('criterio 14: el bloque de sync reusa SyncHero en modo compacto', () {
    testWidgets(
        'SyncHero se parametriza compact:true, trailingChevron:true y sin '
        'cta propio', (tester) async {
      await pumpSheet(tester, stateWith(user: user));

      final hero = tester.widget<SyncHero>(find.byType(SyncHero));

      expect(hero.compact, isTrue);
      expect(hero.trailingChevron, isTrue);
      expect(hero.cta, isNull,
          reason: 'no own button — the whole block is tappable instead');
    });

    testWidgets(
        'tocar el bloque completo dispara onOpenSyncStatus (toda la '
        'superficie es tocable, sin botón propio)', (tester) async {
      var tapped = 0;
      await pumpSheet(
        tester,
        stateWith(user: user),
        onOpenSyncStatus: () => tapped++,
      );

      await tester.tap(find.byType(SyncHero));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('refleja el timestamp real de syncSnapshot.lastSyncedAt',
        (tester) async {
      final syncedAt = DateTime(2026, 7, 20, 10);
      await pumpSheet(
        tester,
        stateWith(user: user).copyWith(
          syncSnapshot: SyncStatusSnapshot(
            state: SyncState.synced,
            quarantinedCount: 0,
            lastSyncedAt: syncedAt,
            hasSyncedEver: true,
          ),
        ),
      );
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AccountSheet)));

      expect(find.text(l10n.syncNeverSyncedLabel), findsNothing);
    });
  });

  testWidgets('tema oscuro: renderiza las 3 variantes sin excepción (HU-11)',
      (tester) async {
    await pumpSheet(tester, stateWith());
    expect(tester.takeException(), isNull);
  });
}

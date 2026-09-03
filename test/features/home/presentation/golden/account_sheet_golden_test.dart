import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/account_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

/// "Tu cuenta" (criterio 2), sus 3 variantes: sin cuenta, con sesión + sin
/// conexión, con sesión + sincronizado.
void main() {
  final month = DateTime(2026, 7);
  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila Restrepo',
    provider: AuthProvider.google,
    email: 'camila@example.com',
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  HomeState stateWith({
    AuthUser? user,
    HomeSyncStatus syncStatus = HomeSyncStatus.synced,
  }) =>
      HomeState(
        status: HomeStatus.ready,
        user: user,
        syncStatus: syncStatus,
        syncSnapshot: SyncStatusSnapshot(
          state: syncStatus == HomeSyncStatus.attention
              ? SyncState.offline
              : SyncState.synced,
          quarantinedCount: 0,
          lastSyncedAt: goldenReferenceNow.subtract(const Duration(minutes: 5)),
          hasSyncedEver: true,
        ),
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: const [],
          transactions: const [],
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    HomeState state,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockHomeCubit();
    whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);

    await withClock(Clock.fixed(goldenReferenceNow), () async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AccountSheet.show(
                context,
                cubit,
                onOpenSettings: () {},
                onSignOut: () {},
                onOpenSyncStatus: () {},
                onActivateBackup: () {},
              ),
              child: const Text('open'),
            ),
          ),
          brightness: brightness,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/account_sheet_$name.png'),
      );
    });
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('account sheet — sin cuenta ($suffix)', (tester) async {
      await golden(tester, stateWith(), 'no_account_$suffix',
          brightness: brightness);
    });

    testWidgets('account sheet — con sesión, sin conexión ($suffix)',
        (tester) async {
      await golden(
        tester,
        stateWith(user: user, syncStatus: HomeSyncStatus.attention),
        'offline_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('account sheet — con sesión, sincronizado ($suffix)',
        (tester) async {
      await golden(
        tester,
        stateWith(user: user),
        'synced_$suffix',
        brightness: brightness,
      );
    });
  }
}

import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/sync_status_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  final month = DateTime(2026, 7);

  HomeState stateWith(HomeSyncStatus status) => HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        syncStatus: status,
      );

  /// Opens the reactive [SyncStatusSheet] through a real trigger (scrim, drag
  /// handle and `BottomSheetBase` chrome included) with the cubit pinned to
  /// [status], then captures the whole screen — the same choreography as the
  /// other sheet goldens (bugfix item 6).
  Future<void> golden(
    WidgetTester tester,
    HomeSyncStatus status,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: stateWith(status),
    );

    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SyncStatusSheet.show(context, cubit),
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
      matchesGoldenFile('goldens/sync_status_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sync status sheet — synced ($suffix)', (tester) async {
      await golden(
        tester,
        HomeSyncStatus.synced,
        'synced_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status sheet — syncing ($suffix)', (tester) async {
      await golden(
        tester,
        HomeSyncStatus.syncing,
        'syncing_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status sheet — offline ($suffix)', (tester) async {
      await golden(
        tester,
        HomeSyncStatus.offline,
        'offline_$suffix',
        brightness: brightness,
      );
    });
  }
}

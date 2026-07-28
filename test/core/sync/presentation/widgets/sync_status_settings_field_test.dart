import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_status_settings_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_sync.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// La entrada en Ajustes → "Cuenta y respaldo" (`STxah`): lleva la última
/// sincronización en su propio sublabel, para que el dato esté visible antes
/// de que el usuario abra la pantalla.
void main() {
  final now = DateTime.now();

  Future<void> pumpField(
    WidgetTester tester, {
    Duration? syncedAgo,
    VoidCallback? onTap,
  }) async {
    final cubit = MockSyncStatusCubit();
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: SyncStatusState(
        status: SyncStatusStatus.ready,
        snapshot: SyncStatusSnapshot(
          state: SyncState.synced,
          quarantinedCount: 0,
          lastSyncedAt: syncedAgo == null ? null : now.subtract(syncedAgo),
          hasSyncedEver: syncedAgo != null,
        ),
      ),
    );
    await tester.pumpSyncWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: cubit,
        child: SyncStatusSettingsField(onTap: onTap ?? () {}),
      ),
    );
  }

  testWidgets('muestra el título y la última sincronización en relativo',
      (tester) async {
    await pumpField(tester, syncedAgo: const Duration(minutes: 5));

    expect(find.text('Estado de sincronización'), findsOneWidget);
    expect(find.text('Última sincronización: hace 5 minutos'), findsOneWidget);
  });

  testWidgets('a los tres días sigue siendo relativo, nunca una fecha',
      (tester) async {
    await pumpField(tester, syncedAgo: const Duration(days: 3));

    expect(find.text('Última sincronización: hace 3 días'), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('sin haber sincronizado nunca lo dice, no muestra un vacío',
      (tester) async {
    await pumpField(tester);

    expect(find.text('Aún no se ha sincronizado'), findsOneWidget);
  });

  testWidgets('tocar la fila abre la pantalla', (tester) async {
    var taps = 0;
    await pumpField(
      tester,
      syncedAgo: const Duration(minutes: 5),
      onTap: () => taps++,
    );

    await tester.tap(find.text('Estado de sincronización'));
    expect(taps, 1);
  });
}

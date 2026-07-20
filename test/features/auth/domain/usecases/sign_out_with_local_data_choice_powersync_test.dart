import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/database/powersync_schema.dart';
import 'package:billetudo/features/auth/data/datasources/apple_auth_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_summary_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/powersync_connector.dart';
import 'package:billetudo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/entities/sign_out_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out_with_local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoogleAuthDatasource extends Mock implements GoogleAuthDatasource {}

class MockAppleAuthDatasource extends Mock implements AppleAuthDatasource {}

class MockLocalDataSummaryDatasource extends Mock
    implements LocalDataSummaryDatasource {}

class MockLocalDataOwnershipDatasource extends Mock
    implements LocalDataOwnershipDatasource {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPowerSyncConnector extends Mock implements PowerSyncConnector {}

/// Contrato "la nube no se toca" de HU-06, sobre una [PowerSyncDatabase]
/// **real** y el caso de uso completo que corre el usuario.
///
/// Por que no `NativeDatabase`: el bug de perdida de datos (commit c5bfd28)
/// vivia justo en lo que `NativeDatabase` no tiene. Con PowerSync cada tabla
/// del esquema es en realidad una *vista* con triggers `INSTEAD OF`, y cada
/// escritura que pasa por Drift queda encolada en `ps_crud` para subirse a
/// Postgres. El wipe viejo borraba fila por fila con Drift, asi que dejaba la
/// cola llena de `DELETE`s que al reconectar borraban la copia en la nube. En
/// una BD en memoria sin vistas ni `ps_crud` ese mecanismo es invisible y
/// cualquier test pasa igual.
///
/// La asercion que reproduce el bug es `SELECT count(*) FROM ps_crud == 0`.
/// El resto del archivo la acompana: que efectivamente borre las 14 tablas, y
/// que con `LocalDataChoice.keep` no borre nada.
void main() {
  late Directory tempDir;
  late PowerSyncDatabase powerSync;
  late AppDatabase db;
  late AuthRepositoryImpl repository;
  late SignOutWithLocalDataChoice signOutWithChoice;
  late MockGoogleAuthDatasource google;
  late MockGoTrueClient auth;
  late StreamController<AuthState> authStateChanges;

  /// Nombres reales de las tablas tal como las declara el esquema de
  /// PowerSync. Se derivan del esquema, no se escriben a mano: agregar una
  /// tabla nueva al cliente la mete automaticamente en la cobertura de abajo,
  /// y si el wipe no la limpia el test falla solo.
  final syncedTables = powerSyncSchema.tables.map((t) => t.name).toList();

  Future<int> pendingUploads() async {
    final rows = await powerSync.getAll('SELECT id FROM ps_crud');
    return rows.length;
  }

  Future<int> rowsIn(String table) async {
    final rows = await powerSync.getAll('SELECT id FROM $table');
    return rows.length;
  }

  /// Siembra una fila en **cada** tabla sincronizada, escribiendo por la vista
  /// igual que lo hace la app. Devuelve nada: lo que importa es que despues
  /// del wipe no quede ninguna.
  Future<void> seedOneRowPerTable() async {
    for (final table in syncedTables) {
      await powerSync.execute(
        'INSERT INTO $table(id) VALUES(?)',
        ['seed-$table'],
      );
    }
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'sign_out_with_local_data_choice_powersync_test',
    );
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    db = AppDatabase(driftConnection(powerSync));

    google = MockGoogleAuthDatasource();
    auth = MockGoTrueClient();
    final supabase = MockSupabaseClient();
    final connector = MockPowerSyncConnector();
    authStateChanges = StreamController<AuthState>.broadcast();

    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.onAuthStateChange)
        .thenAnswer((_) => authStateChanges.stream);
    when(() => google.signOutSilently()).thenAnswer((_) async {});
    when(connector.fetchCredentials).thenAnswer((_) async => null);
    when(connector.getCredentialsCached).thenAnswer((_) async => null);
    when(connector.prefetchCredentials).thenAnswer((_) async => null);

    // Cada pieza que toca datos locales es real: el datasource del wipe, el
    // repositorio, y los dos casos de uso que HU-06 encadena. Solo se mockea
    // lo que sale a la red (Google, Supabase, el connector de sync).
    repository = AuthRepositoryImpl(
      google,
      MockAppleAuthDatasource(),
      MockLocalDataSummaryDatasource(),
      LocalDataWipeDatasource(powerSync),
      MockLocalDataOwnershipDatasource(),
      supabase,
      powerSync,
      connector,
    );
    signOutWithChoice = SignOutWithLocalDataChoice(
      SignOut(repository),
      WipeLocalData(repository),
    );
  });

  tearDown(() async {
    await repository.dispose();
    await authStateChanges.close();
    await db.close();
    await powerSync.close();
    await tempDir.delete(recursive: true);
  });

  group('HU-06 delete: la cola de subida a la nube', () {
    test(
      'queda vacia tras el flujo completo, asi que nada borra la copia en la '
      'nube al volver a entrar',
      () async {
        await db.into(db.accounts).insert(
              AccountsCompanion.insert(
                name: 'Cuenta',
                type: AccountType.bank,
                currency: 'COP',
              ),
            );
        // Precondicion del test: escribir por Drift SI encola (si esto fuera
        // 0, el test de abajo pasaria por la razon equivocada).
        expect(
          await pendingUploads(),
          greaterThan(0),
          reason: 'escribir por Drift debe encolar en ps_crud; si no, este '
              'test no esta corriendo sobre PowerSync de verdad',
        );

        final outcome = await signOutWithChoice(LocalDataChoice.delete);

        expect(outcome, isA<SignedOutAndWiped>());
        expect(
          await pendingUploads(),
          0,
          reason: 'cada DELETE local encolado se sube al reconectar y borra '
              'la fila en Postgres: es exactamente el bug de perdida de '
              'datos de c5bfd28',
        );
      },
    );

    test(
      'queda vacia aunque se hayan escrito filas en las 14 tablas',
      () async {
        await seedOneRowPerTable();
        expect(await pendingUploads(), greaterThan(0));

        await signOutWithChoice(LocalDataChoice.delete);

        expect(await pendingUploads(), 0);
      },
    );

    test('tampoco quedan filas marcadas como pendientes en ps_updated_rows',
        () async {
      await seedOneRowPerTable();

      await signOutWithChoice(LocalDataChoice.delete);

      final rows = await powerSync.getAll('SELECT * FROM ps_updated_rows');
      expect(rows, isEmpty);
    });
  });

  group('HU-06 delete: cobertura de todas las tablas del esquema', () {
    // Parametrizado sobre el esquema entero a proposito. El wipe viejo solo
    // borraba 9 de 14 tablas y su test pasaba igual porque miraba solo
    // accounts/categories/transactions — tres de las que si borraba. Se le
    // escapaban app_settings, budget_accounts, budget_categories,
    // scheduled_payment_tags y scheduled_payment_occurrences.
    for (final table in powerSyncSchema.tables.map((t) => t.name)) {
      test('$table queda vacia', () async {
        await seedOneRowPerTable();
        expect(
          await rowsIn(table),
          1,
          reason: 'la siembra debe dejar una fila en $table',
        );

        await signOutWithChoice(LocalDataChoice.delete);

        expect(
          await rowsIn(table),
          0,
          reason: 'el usuario pidio borrar TODO de este telefono; $table '
              'quedo con datos suyos',
        );
      });
    }

    test(
      'el esquema de PowerSync cubre exactamente las tablas de AppDatabase, '
      'para que este grupo no se quede corto al agregar una tabla',
      () {
        final driftTables = db.allTables.map((t) => t.actualTableName).toSet();

        expect(
          syncedTables.toSet(),
          driftTables,
          reason: 'toda tabla de AppDatabase debe estar en '
              'powersync_schema.dart (si no, ni sincroniza ni la cubre el '
              'wipe, y este test es el unico que lo nota)',
        );
      },
    );
  });

  group('HU-06 keep: no se borra nada', () {
    test('los datos locales siguen ahi despues de cerrar sesion', () async {
      await seedOneRowPerTable();

      final outcome = await signOutWithChoice(LocalDataChoice.keep);

      expect(outcome, isA<SignedOutKeepingData>());
      for (final table in syncedTables) {
        expect(await rowsIn(table), 1, reason: '$table se borro sin permiso');
      }
    });

    test(
      'la cola de subida se conserva: lo escrito offline debe subir en la '
      'proxima sesion',
      () async {
        await db.into(db.accounts).insert(
              AccountsCompanion.insert(
                name: 'Cuenta',
                type: AccountType.bank,
                currency: 'COP',
              ),
            );
        final queuedBefore = await pendingUploads();

        await signOutWithChoice(LocalDataChoice.keep);

        expect(await pendingUploads(), queuedBefore);
      },
    );
  });

  group('HU-06: la sesion se cierra igual', () {
    test('delete desconecta el sync y cierra sesion en Supabase', () async {
      await signOutWithChoice(LocalDataChoice.delete);

      expect(powerSync.connected, isFalse);
      verify(() => auth.signOut()).called(1);
      verify(() => google.signOutSilently()).called(1);
    });
  });
}

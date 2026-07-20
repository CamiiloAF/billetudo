import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard estatico anti-regresion del bug de perdida de datos (commit c5bfd28).
///
/// **Por que esta prohibido borrar filas con Drift en el camino de logout:**
/// con PowerSync, cada tabla del esquema no es una tabla sino una *vista* con
/// triggers `INSTEAD OF`. Esos triggers registran toda escritura hecha por
/// esa vista en la cola de subida `ps_crud`. Entonces un `DELETE` "local" se
/// encola como un `DELETE` para Postgres y se sube en la siguiente conexion:
/// el usuario pide "borrar los datos de este telefono" y termina perdiendo
/// tambien los de la nube. La unica forma correcta de vaciar el dispositivo
/// es `PowerSyncDatabase.disconnectAndClear()`, que ademas limpia la cola.
///
/// Este test es texto sobre archivos a proposito: un test de comportamiento
/// solo atrapa el error si alguien acordo de escribirlo, mientras que la
/// diferencia entre una vista y una tabla es justo lo que se olvida. Es
/// barato y dura.
///
/// Si esto falla, **no relajes el guard**: el codigo del camino de logout debe
/// delegar en `LocalDataWipeDatasource.wipeAll()`.
void main() {
  /// Cada archivo que participa en cerrar sesion / borrar cuenta (HU-06, HU-07).
  const logoutPathFiles = <String>[
    'lib/features/auth/data/datasources/local_data_wipe_datasource.dart',
    'lib/features/auth/data/repositories/auth_repository_impl.dart',
    'lib/features/auth/domain/usecases/sign_out.dart',
    'lib/features/auth/domain/usecases/sign_out_with_local_data_choice.dart',
    'lib/features/auth/domain/usecases/wipe_local_data.dart',
    'lib/features/auth/domain/usecases/delete_account.dart',
  ];

  const datasourcesDir = 'lib/features/auth/data/datasources';

  /// Los unicos datasources de auth a los que se les permite hablar Drift, y
  /// por que: ambos solo LEEN o estampan `user_id`, nunca borran. Cualquier
  /// otro que aparezca aqui hay que revisarlo a mano antes de sumarlo — el
  /// wipe en particular no debe estar nunca en esta lista.
  const driftAllowlist = <String>{
    'local_data_summary_datasource.dart',
    'local_data_ownership_datasource.dart',
  };

  /// Quita comentarios de linea para que la prosa que explica la regla no
  /// dispare la regla.
  String codeOnly(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test(
    'el datasource del wipe NO conoce AppDatabase: vaciar el dispositivo por '
    'Drift encola DELETEs que borran tambien la nube',
    () {
      final code = codeOnly(
        File(
          '$datasourcesDir/local_data_wipe_datasource.dart',
        ).readAsStringSync(),
      );

      expect(
        code.contains('app_database.dart') ||
            code.contains('AppDatabase') ||
            code.contains('package:drift/drift.dart'),
        isFalse,
        reason: 'local_data_wipe_datasource.dart volvio a depender de Drift. '
            'PROHIBIDO: Drift escribe a traves de las vistas de PowerSync, '
            'cuyos triggers INSTEAD OF encolan cada escritura en ps_crud; un '
            'DELETE "local" se sube a Postgres al reconectar y borra la copia '
            'en la nube que el usuario NO pidio borrar (bug c5bfd28). El wipe '
            'se hace SOLO con PowerSyncDatabase.disconnectAndClear().',
      );
    },
  );

  test(
    'ningun datasource nuevo de auth arrastra Drift al area de logout sin '
    'revision',
    () {
      final dir = Directory(datasourcesDir);
      expect(
        dir.existsSync(),
        isTrue,
        reason: '$datasourcesDir se movio; actualiza este guard en vez de '
            'dejarlo mirando una ruta que ya no existe',
      );

      final usingDrift = <String>[];
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final code = codeOnly(file.readAsStringSync());
        if (code.contains('app_database.dart') || code.contains('AppDatabase')) {
          usingDrift.add(file.uri.pathSegments.last);
        }
      }

      expect(
        usingDrift.toSet().difference(driftAllowlist),
        isEmpty,
        reason: 'Datasources de auth que usan Drift sin estar en la '
            'allowlist: ${usingDrift.toSet().difference(driftAllowlist)}.\n\n'
            'Cerca del logout, Drift es peligroso: escribe sobre las vistas '
            'de PowerSync y cada escritura queda encolada en ps_crud para '
            'subirse a Postgres. Leer o estampar user_id esta bien (por eso '
            'la allowlist); BORRAR no lo esta nunca — para eso existe '
            'PowerSyncDatabase.disconnectAndClear() (bug c5bfd28). Si el '
            'archivo nuevo solo lee, agregalo a la allowlist explicando por '
            'que.',
      );
    },
  );

  test(
    'ningun archivo del camino de logout borra filas (ni por Drift ni por SQL '
    'crudo)',
    () {
      // `delete(`/`deleteAll(`/`deleteWhere(` = API de borrado de Drift.
      // `DELETE FROM` = SQL crudo por customStatement/execute, que pasa por la
      // misma vista y encola igual.
      final forbidden = RegExp(
        r'\bdelete\s*\(|\bdeleteAll\s*\(|\bdeleteWhere\s*\(|DELETE\s+FROM',
      );

      // La lista explicita (para que renombrar un archivo rompa el guard en
      // vez de vaciarlo) mas todo el directorio de datasources de auth (para
      // que un archivo nuevo quede cubierto sin que nadie se acuerde).
      final paths = <String>{
        ...logoutPathFiles,
        ...Directory(datasourcesDir)
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((path) => path.endsWith('.dart'))
            // El connector SI borra, y debe: es el uploader que aplica en
            // Postgres las operaciones ya encoladas en ps_crud (incluidas las
            // de un borrado real hecho por el usuario). Lo que este guard
            // prohibe es *generar* esas operaciones al vaciar el dispositivo.
            .where((path) => !path.endsWith('powersync_connector.dart')),
      };

      final offenders = <String>[];
      for (final path in paths) {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: '$path se movio o se renombro; actualiza esta lista para '
              'que el guard siga cubriendo el camino de logout',
        );
        final code = codeOnly(file.readAsStringSync());
        for (final match in forbidden.allMatches(code)) {
          offenders.add('$path: ${match.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Borrado de filas en el camino de logout:\n'
            '${offenders.join('\n')}\n\n'
            'Cada DELETE aqui queda encolado en ps_crud y se sube a Postgres '
            'al reconectar, borrando los datos en la nube (bug c5bfd28). '
            'El wipe local se hace SOLO con '
            'PowerSyncDatabase.disconnectAndClear().',
      );
    },
  );

  test(
    'LocalDataWipeDatasource sigue delegando en disconnectAndClear',
    () {
      final code = File(
        'lib/features/auth/data/datasources/local_data_wipe_datasource.dart',
      ).readAsStringSync();

      expect(
        codeOnly(code).contains('disconnectAndClear'),
        isTrue,
        reason: 'es la unica primitiva que vacia el dispositivo sin dejar '
            'operaciones pendientes en ps_crud',
      );
    },
  );
}

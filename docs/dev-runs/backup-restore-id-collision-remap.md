# Remapeo de colisión de ids al restaurar backups entre cuentas (backup-restore-id-collision-remap)

## Objetivo y criterios de aceptación

Al restaurar un backup JSON bajo una cuenta Supabase distinta a la que originalmente sincronizó esos ids, detectar la colisión en Postgres, insertar las filas colisionadas localmente con id nuevo, y remapear todas las FK (incluidas las 3 blandas sin `.references()` en Drift) antes de insertar y antes del orden topológico de `categories` — sin tocar ni sobrescribir jamás la fila real de la otra cuenta, y sin ningún cambio de UI.

Tamaño: **l** | Review: `deep` **APROBADO**

Criterios de aceptación (✅ cumplido / ⚠️ gap, ver sección de pendientes):

1. ✅ Restore sin colisión produce el mismo `RestoreSummary`/ids que hoy (cero regresión).
2. ✅ Cada fila colisionada se inserta localmente con id UUID nuevo, nunca el original.
3. ✅ Toda FK (incluidas las 3 blandas: `goalContributions.transactionId`, `debts.initialTransactionId`, `appSettings.featuredBudgetId`) que apunte a un id remapeado queda reescrita antes de insertar.
4. ⚠️ La fila original de la otra cuenta en Postgres permanece bit a bit igual — no verificable sin Supabase real.
5. ⚠️ Subida vía `SupabaseOperationUploader` hace INSERT limpio, sin 42501 — no verificable sin Supabase real.
6. ✅ Ninguna fila del backup se pierde: sum(created+updated) = total del JSON menos skipped legítimos.
7. ✅ Sin sesión activa o misma cuenta, no se dispara query de red adicional.
8. ✅ Si el RPC de colisión falla por red, el restore aborta completo con `Left(NetworkFailure)` (fail-closed).
9. ✅ `_parentsBeforeChildren` para categories opera sobre ids ya remapeados.
10. ⚠️ La función RPC nunca devuelve datos de la fila colisionada ni el user_id ajeno — **la migración SQL no existe en el repo**, no auditable.
11. ⚠️ `table_name` restringido a allowlist fijo en la función SQL — mismo gap: la migración no existe.
12. ⚠️ Función guardián estilo `delete_account_data_coverage_gaps` para esta colisión — mismo gap: la migración no existe.
13. ✅ Restaurar el mismo backup dos veces bajo dos cuentas distintas no deja operaciones en cuarentena.

## Qué cambió (tabla archivo → qué)

| Archivo | Qué |
|---|---|
| `lib/core/sync/domain/repositories/backup_id_collision_resolver.dart` (nuevo) | Interfaz domain para detectar colisiones de id contra Postgres, análoga a `DataOwnershipClaimer` pero en `core/sync/domain`. |
| `lib/core/sync/data/datasources/backup_id_collision_datasource.dart` (nuevo) | Envuelve el RPC batch `check_backup_restore_id_collisions`, convierte nombres de tabla camelCase↔snake_case. |
| `lib/features/auth/data/datasources/local_data_ownership_datasource.dart` (modificado) | Implementa también `BackupIdCollisionResolver`, delega a `BackupIdCollisionDatasource`. |
| `lib/core/di/register_module.dart` (modificado) | Dos getters nuevos para exponer la misma instancia singleton bajo ambas interfaces (injectable no soporta dos `@LazySingleton(as: X)` en la misma clase). |
| `lib/core/di/injection.config.dart` (regenerado) | build_runner. |
| `lib/features/import_export/domain/entities/backup_fk_column_map.dart` (nuevo) | Mapa mantenido a mano de todas las columnas FK del backup, incluidas las 3 blandas. |
| `lib/features/import_export/domain/usecases/resolve_backup_id_conflicts.dart` (nuevo) | Caso de uso: detecta colisión vía `BackupIdCollisionResolver`, genera UUIDs nuevos, reescribe todas las FK antes de que se aplique `_parentsBeforeChildren`/`restoreInsertOrder`. `appSettings` excluido del chequeo de colisión de su propio id (literal fijo `'app'`, compartido legítimamente por toda cuenta). |
| `lib/features/import_export/data/datasources/backup_json_datasource.dart` (modificado) | Invoca el remapeo antes del orden topológico de inserción. |
| Movidos a `domain/utils/`: `csv_date_parser.dart`, `decimal_amount_parser.dart` | Parsers estáticos puros, sin cambio de lógica; `data/models/` quedan como `export` shim para no romper imports existentes. |
| `restore_sheet_step_view.dart`, `skipped_reason_row.dart`, `choice_toggle_segment.dart` (nuevos) | Widgets privados extraídos a públicos por `avoid_private_widgets` (sin cambio visual). |
| Tests nuevos/modificados | Ver sección Tests. |

## Tests (resultado + comandos)

`flutter analyze` limpio. Suite verde. e2e: skip (ver checklist manual).

```bash
flutter analyze
dart run build_runner build --force-jit
flutter test test/features/import_export/data/datasources/backup_json_datasource_test.dart \
  test/features/import_export/domain/usecases/resolve_backup_id_conflicts_test.dart \
  test/core/sync/data/datasources/backup_id_collision_datasource_test.dart \
  test/features/auth/data/datasources/local_data_ownership_datasource_test.dart
```

Cobertura por AC (✅ cerrado con test / ⚠️ gap sin test automatizable):

- ✅ AC1, AC2, AC3, AC6, AC7, AC8, AC9, AC13 — cubiertos por `backup_json_datasource_test.dart` (grupo "restore — colisión de ids...") + `resolve_backup_id_conflicts_test.dart` + `backup_id_collision_datasource_test.dart`. Detalle de nombres de test en el reporte del implementador (disponible en el historial de la corrida).
- ⚠️ AC4, AC5 — requieren Postgres real (proyecto Supabase dev) con dos cuentas reales; quedan como `manualCheck`.
- ⚠️ AC10, AC11, AC12 — dependen de la función SQL `check_backup_restore_id_collisions`, que **no existe** en `supabase/migrations/` (confirmado con grep en todo el repo). Fuera del alcance de archivos permitido para esta corrida (`lib/**`, `test/**`, `integration_test/**`).

## Fidelidad visual vs Pencil

N/A (feature sin UI). No se tocó ningún widget/página/sheet de Import/Export; el cambio es puramente domain/data en el flujo de restore.

## 👤 Verifica a mano

- [ ] **Aplicar la migración SQL faltante primero.** No existe ningún archivo bajo `supabase/migrations/` para la función RPC `check_backup_restore_id_collisions` que `backup_id_collision_datasource.dart` invoca por nombre, ni para el guardián estilo `delete_account_data_coverage_gaps` que pide el AC12. Confirmado con `grep -r` en todo el repo: el nombre solo aparece en comentarios de `lib/` y en el test que mockea la llamada HTTP. **Efecto en producción hoy:** toda llamada a `findCollidingIds` falla con "function does not exist" → `BackupIdCollisionCheckException` → `Left(NetworkFailure)` → el restore aborta fail-closed (AC8 se cumple, sin riesgo de datos, pero el remapeo por colisión queda inoperante hasta aplicar la migración). Reportar al arquitecto antes de dar por cerrada la corrida.
- [ ] Con la migración aplicada en Supabase dev: restaurar un backup con datos bajo la Cuenta A, luego restaurar el mismo archivo bajo la Cuenta B en el mismo dispositivo, confirmar en el dashboard de Supabase que la fila original de A no cambió y que la subida de B no generó ningún 42501/fila en cuarentena (AC4, AC5, AC13 de punta a punta).
- [ ] Revisar visualmente que el flujo de restore no cambió nada de UI (corrida puramente lógica/datos, sin goldens nuevos).
- [ ] Hay un device Android booteado (`emulator-5554`) y el flujo TÉCNICAMENTE es multi-pantalla, pero no es determinista ni automatizable con Patrol: requiere iniciar sesión con dos cuentas Supabase/Google reales distintas en el mismo dispositivo, y además el RPC de servidor que la feature necesita no está desplegado — no hay contra qué correr el flujo real todavía. Por eso no se extendió `integration_test/import_export_patrol_test.dart` en esta corrida; revisar si eso sigue siendo correcto una vez exista la migración.

## Pendientes y riesgos

**Gaps de cobertura (bloqueantes de cierre real, no de esta corrida de código):**
- AC10, AC11, AC12: la función SQL `check_backup_restore_id_collisions` y su guardián de allowlist no existen en `supabase/migrations/`. El nombre de la función (`check_backup_restore_id_collisions`) y el shape de parámetros/retorno (`p_user_id`, `p_rows: [{table_name, id}]` → `[{table_name, id}]`) están fijados por el código Dart y deben coincidir exactamente en esa migración.
- AC4, AC5, AC13 (round-trip completo contra RLS real): requieren Supabase dev real, quedan como `manualCheck`.

**Blockers sin resolver:** ninguno para el código de esta corrida; la migración SQL faltante bloquea que la feature funcione en runtime hasta que se aplique.

**Observaciones no bloqueantes:** ninguna.

**Riesgos del plan:**
- La función `security definer` nueva es superficie de ataque — requiere revisión extra de `compliance-reviewer`: debe auditarse que solo devuelve ids en colisión (nunca datos de fila ni user_id ajeno) y que el allowlist de tablas es exhaustivo y no editable por input.
- `backup_fk_column_map.dart` es una lista de columnas FK mantenida a mano en Dart; si se añade una tabla/columna FK nueva sin actualizarla, el remapeo queda incompleto de forma silenciosa. Mitigado por el guardián SQL (aún no aplicado), pero no hay guardián equivalente en Dart.
- Aplicar la migración primero en supabase-dev y verificar antes de prod es un paso manual fuera del control del código; si se salta, el flujo queda roto en producción sin que ningún test lo detecte.
- El binding de DI cruza tres capas de tres features distintas (`import_export`, `core/sync`, `auth`) — alto riesgo de romper el grafo de DI si build_runner no se regenera correctamente tras cualquier cambio futuro.
- El RPC batch mezcla las ~19 tablas en un solo roundtrip; si el backup es grande, el payload de ids puede ser voluminoso — sin paginación ni límite de tamaño especificado, riesgo de timeout no cubierto por los AC dados.

## Mensaje de commit sugerido

```
feat(import-export): remapea ids colisionados al restaurar backup entre cuentas

Detecta colisiones de id contra Postgres via un RPC batch antes de
insertar un backup restaurado, genera UUIDs nuevos para las filas
colisionadas y reescribe todas las FK (incluidas las 3 blandas:
goalContributions.transactionId, debts.initialTransactionId,
appSettings.featuredBudgetId) antes del orden topologico de
categories. Nunca toca la fila real de la otra cuenta.

Pendiente: falta la migracion SQL de check_backup_restore_id_collisions
(y su guardian de allowlist) en supabase/migrations/ — sin ella el
remapeo aborta fail-closed en runtime. Ver docs/dev-runs/
backup-restore-id-collision-remap.md.
```

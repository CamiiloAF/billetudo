# Capturas que se ven un segundo y desaparecen al abrir la campana (Sync Stream incompleto)

**Fecha:** 2026-11-07 · **Estado:** causa raíz confirmada, remediación manual pendiente del lado del usuario (dashboard de PowerSync) · **Severidad:** alta — pérdida silenciosa de datos locales del usuario.

## Síntoma reportado

Android, build **release con sesión de Google iniciada**. La lectura de notificaciones bancarias funciona (la captura se detecta), pero al abrir la campana (Centro de avisos, `/avisos`) las tarjetas de "Capturas por confirmar" **se muestran ~1 segundo y desaparecen**. Al reabrir la campana la bandeja queda vacía **para siempre**.

Pista decisiva del reporte: pasa solo en el build release que usa la cuenta real (sync activo). Nunca se vio en tests ni en un emulador, porque ninguno de los dos corre con sesión + sync real.

## Causa raíz

**`pending_captures` y `merchant_category_learning` no están registradas en los Sync Streams de PowerSync** (ni en dev ni en prod). El usuario lo confirmó en el dashboard: la query `SELECT * FROM pending_captures WHERE user_id = auth.user_id()` no existe en el stream `user_data`.

Con la tabla fuera de todo stream, PowerSync borra la copia local de cualquier fila nueva en cuanto termina de subirla. No es un bug de `NoticesCubit` ni de la bandeja: es el modelo de consistencia de PowerSync, documentado explícitamente.

### El mecanismo, paso a paso

1. La notificación llega con la app **abierta** (el servicio nativo la bufferiza; no hay listener live en Dart).
2. Al abrir la campana, `NoticesCubit.start()` → `_ingestBufferedCaptures()` drena ese buffer y **inserta la fila** vía Drift. La fila queda en `ps_data__pending_captures`, en `ps_crud` (cola de subida) y en `ps_updated_rows`.
3. El stream de Drift reemite y la tarjeta aparece. ✅
4. ~1 s después, `PowerSyncConnector.uploadData()` sube la fila por PostgREST (con `user_id` estampado al vuelo por `SupabaseOperationUploader._ownedPayload`) y llama `transaction.complete()`. **La fila sale de `ps_crud`.**
5. Como `pending_captures` no pertenece a ningún stream, el servidor nunca la devuelve en un checkpoint. En el siguiente checkpoint completo PowerSync materializa el estado local **exactamente** con lo sincronizado y **elimina la fila local** que está en `ps_updated_rows` pero no en los datos sincronizados.
6. La campana queda vacía para siempre: la fila sí está en Postgres (subió bien), pero nunca vuelve a bajar.

Citas textuales de la documentación de PowerSync que fijan el comportamiento:

- `ps_updated_rows`: *"Tracks rows written locally or affected by removed sync operations. When the client SDK applies a complete sync, it uses these entries to update or **remove** the matching rows in `ps_data__<table>`, then clears this table."* — <https://docs.powersync.com/architecture/client-architecture>
- Local-only usage: *"The client SDK also stores one entry in the `ps_updated_rows` table for each row written locally. […] **When the app syncs, the client SDK uses them to find local rows that are missing from the synced data and removes those rows.**"* — <https://docs.powersync.com/client-sdks/advanced/local-only-usage>
- Consistency: *"The client only updates its local state when it has all the data matching a checkpoint, and then it **updates the state to exactly match that of the checkpoint**."* — <https://docs.powersync.com/architecture/consistency>

### Por qué no lo detectó nada de lo que ya existe

| Verificación | Por qué no lo ve |
|---|---|
| `flutter test` de la bandeja / repositorio | Corre sobre `NativeDatabase` (tablas reales de Drift), no sobre las vistas de PowerSync ni con sync. |
| Patrol e2e (`capture_inbox_patrol_test.dart`) | Flavor `dev` **sin sesión**: sin sync no hay checkpoint que materialice ni borre nada. |
| `schema_parity_test.dart` | Compara `powerSyncSchema` contra Postgres. El Sync Stream vive **fuera del repo** (dashboard de PowerSync) y no se compara contra nada. |
| Búsqueda de código | Correcta: **ningún código Dart** borra `PendingCaptures` automáticamente. Los únicos caminos de borrado son acciones del usuario (descartar/deshacer/confirmar) y casos de uso muertos (`DiscardCapturesBefore`, `PurgeDiscardedCaptures`, `DeleteAllCaptureData`, sin llamadores en producción). |

Esto es la **cuarta vez** que el proyecto se topa con una pieza de sincronización que vive fuera del repo: decisiones #17, #20, #21, #22 y #24 de `docs/requirements/fase-1/05-auth-sync.md` documentan el mismo patrón con columnas y tablas. La deuda estructural (que una tabla nueva exija "cuatro piezas" y la cuarta no sea verificable desde el repo) ya estaba anotada; este incidente la vuelve a confirmar, con un agravante: aquí la pieza faltante **destruye datos locales** en vez de solo desincronizarlos.

## Remediación (pasos exactos)

1. **Dashboard de PowerSync → instancia de PROD → Sync Streams → stream `user_data`.** Agregar, junto a las demás queries del stream:
   ```sql
   SELECT * FROM pending_captures WHERE user_id = auth.user_id();
   SELECT * FROM merchant_category_learning WHERE user_id = auth.user_id();
   ```
   Y **desplegar** el cambio.
2. Repetir **idéntico en la instancia de DEV**.
3. Verificación en el dispositivo (release, con sesión):
   - Recibir una notificación de banco con la app abierta, abrir la campana y comprobar que la tarjeta **sigue ahí** después de 10-15 s (el punto donde antes desaparecía).
   - Cerrar y reabrir la campana: sigue.
   - Matar la app y volver a abrir con red: sigue (ahora sí baja del servidor).
   - Reinstalar la app (o abrir en un segundo dispositivo con la misma cuenta): la captura reaparece.
4. Efecto secundario esperado y bueno: las capturas que ya se habían subido y "desaparecido" **siguen en Postgres**, así que al desplegar el stream bajan de nuevo y vuelven a la bandeja del usuario. No hay que recuperar nada a mano.
5. Corroborar del lado de Supabase (cualquiera de los dos proyectos):
   ```sql
   select count(*), max(created_at) from public.pending_captures;
   ```
   Debe haber filas con `user_id` = el usuario de la prueba. Si saliera **0**, además del stream habría un rechazo de subida (quarantine) y hay que revisar `Ajustes → Sincronización → Registro técnico` (`/mas/ajustes/sincronizacion`) y la pantalla de cambios pendientes antes de cerrar esto.

## Por qué la subida sí funcionó (y por qué eso importa para la recuperación)

`SupabaseOperationUploader._ownedPayload` estampa `user_id` con la sesión actual **en el borde HTTP**, así que la fila sube con dueño y pasa RLS. Por eso el stream, una vez desplegado, la puede bajar en la primera sincronización del usuario. Si la tabla hubiera fallado RLS/FK, la fila no estaría en Postgres y la recuperación dependería del quarantine (que guarda el payload y permite reintentar a mano).

## Deuda y seguimiento (no parte de este fix)

1. **`tutorial_views` sigue fuera del stream**, y ya estaba documentado así en `docs/dev-runs/minitutoriales.md`. Mismo riesgo, misma verificación, mismo arreglo.
2. **`_SyncColumns.userId` nunca se estampa en las filas locales**: solo se agrega en el payload HTTP (`_ownedPayload`). El contrato del repo (`docs/requirements/fase-1/05-auth-sync.md`, decisión #7) dice que las filas nacen sin dueño y se reclaman en la fusión post-login; lo que falta es estampar la sesión **en la creación** cuando ya hay sesión. Hoy se autosana tras la primera bajada del servidor (la fila llega con `user_id`), pero cualquier lógica local que dependa de `userId` ve `NULL` en el mientras tanto. Anotado como follow-up, sin tocar en este fix.
3. **La causa de fondo (config externa no verificable desde el repo) sigue abierta.** La mitigación barata que este incidente deja sobre la mesa: versionar en el repo una copia canónica de las queries del stream (aunque el dashboard siga siendo la fuente real) para que un cambio de esquema produzca un diff visible, y que `drift-migration-helper`/`/drift-schema-change` no cierren un cambio de tabla nueva sin confirmación explícita de que la línea del stream está desplegada en dev **y** prod. La segunda parte quedó aplicada en este mismo cambio.
4. **La misma consecuencia aplica a un rechazo permanente de la subida (quarantine), no solo al stream faltante.** `PowerSyncConnector.uploadData()` decide — a propósito y por el incidente de las 89 filas de la decisión #22 — cuarentenar una operación rechazada y **completar** la transacción para que la cola FIFO no se trabe. Eso saca la fila de `ps_crud`, y si el servidor nunca la recibe, la materialización del checkpoint también la borra del SQLite local: el quarantine conserva el payload en JSON para reintentarlo a mano, pero la fila ya no está en la tabla y la UI no la muestra. Es la contrapartida asumida de esa decisión, no un bug nuevo; queda anotada porque el efecto es el mismo (pérdida local silenciosa) y cualquier rechazo permanente de `pending_captures`/`merchant_category_learning` que aparezca tras desplegar el stream se vería igual en la campana.

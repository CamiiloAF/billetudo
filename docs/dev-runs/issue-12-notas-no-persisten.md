# Issue #12 — "Dejar que el asistente lea mis notas" no persiste

**Estado al 2026-08-29: sin reproducir, sin fix. Documentado para retomar.**

## El reporte

El interruptor de notas en Ajustes vuelve a aparecer apagado tras cerrar y
reabrir la app, aunque se haya activado. El usuario confirmó que **tenía
sesión iniciada** (login con Google) en el momento en que lo vio fallar.

## Descartado con evidencia real (no es una suposición)

**Toda la capa local del proyecto** (widget → cubit → caso de uso →
repositorio → datasource → migración → esquema PowerSync → columna en
Postgres) — verificado por lectura y por un repro real: escribir, cerrar la
conexión de Drift, abrir una instancia **nueva** contra el mismo archivo,
leer de vuelta. Persiste correctamente.

**La hipótesis de carrera de sincronización** (una descarga del servidor
pisando una subida local todavía pendiente en la cola tras un reinicio) —
**refutada por el propio paquete `powersync` 2.3.3**, no por lectura del
código del proyecto:
- `bucket_storage.dart`: el `target_checkpoint_request_id` solo avanza cuando
  `ps_crud` queda vacío. Mientras haya algo pendiente de subir, ningún
  checkpoint entrante se aplica.
- `ps_crud` es una tabla persistida en SQLite, no estado en memoria — la
  protección sobrevive un reinicio de proceso completo.
- Hay un test real del paquete que ejercita exactamente este escenario
  (`in_memory_sync_test.dart:505`, `'handles checkpoints during the upload
  process'`): escribe localmente, llega un checkpoint del servidor con datos
  distintos mientras la subida sigue en curso, y el checkpoint **no se
  aplica** hasta que la subida se confirma.
- El throttle de subida (`crudThrottleTime`) es de 10ms por defecto, y el
  proyecto no lo cambia — no hay ventana ampliada por batching.

## La pista que queda, sin confirmar

`LocalDataOwnershipDatasource.claimUnownedRows` (el "claim" de HU-04, que
corre una vez al iniciar sesión por primera vez en un dispositivo) hace un
`UPDATE app_settings SET user_id = ?, updated_at = ? WHERE user_id IS NULL`
— `app_settings` sí está en la lista de tablas que reclama
(`synced_tables.dart`). Pero:
- Solo toca `user_id` y `updated_at`, nunca `ai_notes_access_enabled` ni
  ninguna otra columna — no debería poder revertir el interruptor por sí
  mismo.
- El `WHERE user_id IS NULL` lo vuelve un no-op en cualquier reapertura
  normal de una cuenta ya reclamada — no calza con "cerrar y reabrir con la
  misma sesión de siempre", que es como se reportó el bug.

No se investigó más a fondo esta noche. Es la pista más concreta que queda,
pero no explica el escenario reportado tal cual está — antes de tocar código
hay que confirmar si `claimUnownedRows` se está disparando en algún momento
que no debería (ej. en cada arranque en vez de solo en el primer login), no
asumir que es la causa.

## Qué se necesita para seguir

- Reproducirlo en un dispositivo/emulador real: activar el interruptor,
  matar la app inmediatamente, reabrir, verificar si sigue activo.
- Si se reproduce, logs de PowerSync a nivel debug (`powerSync.logger`)
  mostrando el orden real de operaciones alrededor del reinicio — sube vs.
  descarga vs. cualquier llamada a `claimUnownedRows`.
- Confirmar si el dispositivo donde se vio el bug había iniciado sesión
  *recientemente* (cerca de cuando se vio el fallo) o si ya llevaba tiempo
  con sesión activa — esto distingue si `claimUnownedRows` es siquiera
  plausible como causa.

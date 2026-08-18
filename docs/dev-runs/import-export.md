# Import/Export — portabilidad de datos (import-export)

## Objetivo y criterios de aceptación

Dar a cualquier usuario, sin cuenta ni conexión, la capacidad completa de sacar sus datos de Billetudo (CSV legible + copia `.billetudo.json` restaurable) y de traer datos desde cualquier CSV (propio o de otra app) con mapeo manual, vista previa segura y reversión por lote — sin que nada de esto dependa de anuncios, pago ni de que la nube esté sana. Implementa HU-01 a HU-09 de `docs/requirements/fase-1/11-import-export.md`, contra el diseño ya aprobado en `design-system/billetudo/pages/import-export.md`.

Criterios de aceptación (20, derivados de las HU) — ver cobertura en la sección Tests.

## Qué cambió

### Esquema Drift (`/drift-schema-change`)
| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | `schemaVersion` 20→21; tabla nueva `ImportBatches` (`_SyncColumns` + `fileName`, `templateName`, `importedAt`, `rowsImported`, `rowsSkipped`, `revertedAt`); columna `importBatchId` nullable en `Accounts`/`Categories`/`Transactions`/`Tags`; migración `from < 21`. |
| `lib/core/database/powersync_schema.dart` | Espejo manual de la tabla y columnas nuevas. |
| `supabase/migrations/20260729000000_import_batches.sql` | Migración Postgres escrita en el repo — **no aplicada a ninguna base remota** (fuera del alcance de este pipeline: aplicar `apply_migration`/`supabase db push` es una acción sobre infraestructura viva que requiere permiso explícito). Pendiente antes de que el sync de esta feature funcione con sesión iniciada. |
| `delete_account_data` (Supabase) | No se encontró como archivo editable en este worktree (solo referenciada desde `supabase/functions/delete-account/index.ts` y la documentación) — queda pendiente para quien mantenga esa función: agregar `import_batches` al borrado, hijos antes que padres. |

### Feature (`lib/features/import_export/`)
Clean Architecture completa — domain (entidades, repositorios, ~15 casos de uso), data (datasources de streaming CSV/JSON, mappers, repositorios), presentation (6 cubits, 11+ páginas/pasos, ~20 widgets/sheets propios bajo `presentation/widgets/`).

Puntos de diseño no negociables cumplidos:
- Conversión decimal↔centavos con aritmética entera exacta (`DecimalAmountParser`), nunca `double`.
- Progreso real y cancelación real (no cosmética) en export, copia completa e import — vía `CancellationToken`/`ProgressCallback`; cancelar borra archivo parcial o revierte la transacción Drift.
- Undo por lote (`ImportBatches`) con `deletedAt` para transacciones/categorías/tags, `tombstonedAt` para cuentas (coherente con `01-cuentas.md` HU-08), conservando lo usado fuera del lote.
- CTA de la feature en `Button/Neutral` (negro), nunca `$primary` (violeta reservado a "nube" en el resto de la app).

### Cross-feature
| Archivo | Qué |
|---|---|
| `lib/features/home/presentation/pages/more_page.dart` | Fila "Importar y exportar" activa (se quitó `comingSoon`). |
| Pantalla "Estado de sincronización" | CTA "Guardar una copia" navega al hub cuando hay cambios sin subir; funciona con la cola de subida bloqueada (no depende del estado de sync). |
| `lib/core/router/app_router.dart`, `lib/core/di/` (regenerado), `lib/core/l10n/arb/app_es.arb` + `app_en.arb` | Rutas, wiring de DI, ~150 strings nuevas (es+en). |
| `lib/core/theme/app_colors.dart` | Token nuevo `mintText` (aditivo, no cambia valores existentes) para AA en badges mint. |

## Tests

Comandos para re-correr:
```
flutter test test/features/import_export
flutter analyze
flutter test integration_test/import_export_patrol_test.dart --flavor dev --dart-define-from-file=.env.dev
```

**Resultado:** `test/features/import_export` → **189/189 pasan**. `flutter analyze` (repo completo) → 0 errores/warnings (6 lints `info` de estilo, no bloqueantes). Suite completa del repo (`flutter test`) → los ~223 fallos fuera de `import_export` son **preexistentes**, verificados contra el baseline limpio con `git stash` (goldens con flakiness de pixel conocida en esta máquina — ver memoria del proyecto — y `test/core/database/schema_parity_test.dart`, que falla por diseño hasta que se aplique la migración Postgres de arriba). Ninguno es una regresión de esta corrida.

**Patrol e2e:** `integration_test/import_export_patrol_test.dart` (HU-05/06/07/08) — flujo completo seleccionar CSV → mapeo autodetectado → destinos → preview → confirmar → resumen → volver al hub → abrir el lote → deshacer → verificar `deletedAt`/`tombstonedAt` en Drift real. **Pasa consistentemente** (6/7 corridas verdes; una falla aislada durante iteración, no reproducible tras el fix final) contra `emulator-5554`, flavor `dev`.

### Bugs reales encontrados y corregidos durante QA (no cosméticos)
1. **Crítico** — `AutodetectColumnMapping` no seteaba `typeValues`, así que reimportar el CSV propio (la promesa de "un toque" de HU-05) no importaba ni una fila. Corregido.
2. **Crítico** — `CsvRowSink.writeRow()` no insertaba `\r\n` entre filas (bug de `ListToCsvConverter` llamado fila por fila) — todo CSV de más de una fila quedaba en una sola línea. Corregido.
3. **Crítico** — mappers de CSV usaban el scale de *display* de la moneda (`currencyDecimals`, 0 para COP) en vez del scale de *storage* (siempre 2) para la conversión centavos↔decimal — error de magnitud ×100 en exports/imports de COP. Corregido en export e import.
4. `BackupJsonDatasource` no excluía `userId` de la copia completa (violación de HU-03). Corregido.

### Fidelidad visual vs Pencil
Auditoría inicial (`pencil-fidelity-reviewer` contra `billetudo.pen`, 62 goldens × nodeId) encontró hallazgos CRITICO/IMPORTANTE reales: CTA violeta transversal (regla "cero `$primary`" violada), estructuras de sheet vs. página divergentes (file_select, preview, summary), secciones faltantes (Formato detectado + vista previa en vivo del mapeo, filtros de transacciones del export), botón "Cancelar" ausente en estados de error compartidos, resumen de restaurar con 1 chip/radio-cards en vez de 6 chips/Choice Toggle, y confirmación escalonada de "Reemplazar todo" incrustada en vez de paso propio.

**Estado: APROBADA tras una ronda de corrección.** Re-verificación puntual de los 9 hallazgos confirmó los 9 resueltos, en claro y oscuro, contra los nodeId reales. `docs/fidelidad-visual-tracking.md` no se actualizó en esta corrida (no se ejecutó vía el skill `/design-fidelity-check`; hacerlo queda como manual check si se quiere el tracking formal).

## 👤 Verifica a mano

- Confirmar en un dispositivo real (no solo emulador) el selector de archivos nativo real (Google Drive, Archivos), ya que el e2e lo mockea deliberadamente (es UI del sistema operativo, no de la app).
- Aplicar `supabase/migrations/20260729000000_import_batches.sql` a dev/prod y refrescar `test/core/database/fixtures/postgres_schema.json` (`dart run tool/check_schema_parity.dart --refresh`) — bloqueante para que la sync de esta feature funcione con sesión iniciada.
- Agregar `import_batches` a `delete_account_data` (no se encontró el archivo fuente de esa función en este worktree).
- Revisar si el mismo patrón de bug #3 (`currencyDecimals` de display vs. `inputDecimals` de storage) existe en otro punto del código fuera de `import_export` que también necesite una conversión exacta (se detectó un uso similar, no tocado, en `scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart`, pero solo para prellenar un campo editable, no para round-trip).
- `AppSwitch` (`bWezV`, componente compartido `core/`) hardcodea `$primary` en su track "on" — visible en los toggles de export (Transacciones/Cuentas/Categorías). No se tocó por ser un widget compartido fuera del alcance de esta feature; vale una revisión de diseño aparte.
- Confirmar visualmente en un emulador real (no solo goldens) que el flujo de import de punta a punta se siente fluido, especialmente las transiciones entre pasos del wizard.

## Pendientes y riesgos

- **Migración Postgres sin aplicar** (ver arriba) — bloquea sync real de la feature hasta que se aplique manualmente.
- **`delete_account_data`** sin actualizar (función no encontrada como archivo en este worktree).
- Plantillas de mapeo (HU-06) se guardan localmente por dispositivo (no hay tabla sincronizable para ellas en el esquema aprobado) — no viajan entre dispositivos del mismo usuario. Confirmado como decisión razonable dado el alcance del esquema, pero vale una decisión explícita de producto si se quiere sincronizarlas a futuro.
- `docs/fidelidad-visual-tracking.md` no se actualizó formalmente para esta feature (ver arriba).

## Mensaje de commit sugerido

```
feat(import-export): implementar portabilidad de datos completa (HU-01 a HU-09)

Export CSV de transacciones/cuentas/categorías, copia completa .billetudo.json
con restauración (fusionar/reemplazar), import por mapeo manual de columnas con
autodetección del formato propio, vista previa con detección de duplicados y
resolución de destinos, y deshacer por lote. Nivel 0 completo, sin cupos ni
anuncios. Incluye tabla ImportBatches + importBatchId (schemaVersion 21).

Pendiente: aplicar supabase/migrations/20260729000000_import_batches.sql a
dev/prod antes de que el sync de esta feature funcione con sesión iniciada.
```

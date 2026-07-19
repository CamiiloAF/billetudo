# Pagos programados (pagos-programados)

- **Fecha:** 2026-07-19
- **Tamaño:** L
- **Review:** deep — APROBADO
- **Actualización 2026-07-19 (post-cierre):** 4 rondas de corrección de fidelidad visual contra `billetudo.pen` + 1 ronda de corrección del patrón de color por categoría, todas fuera de la corrida original de `feature-dev`. Ver "Fidelidad visual — historial de correcciones" más abajo.

## Objetivo y criterios de aceptación

Implementar Pagos programados (Nivel 0) completa: plantillas de transacciones futuras (únicas o repetibles), generación automática al vencer, modo de confirmación manual con verificación obligatoria (nunca a ciegas), posponer/omitir ocurrencias de forma reversible, vista de próximos vencimientos, edición/eliminación de plantillas con historial, y el puente desde Transacciones para convertir un gasto con fecha futura en pago programado. El diseño (`design-system/billetudo/pages/pagos-programados.md`) ya estaba cerrado en ambos temas antes de esta corrida — aquí solo se implementó.

1. Crear plantilla (HU-01) persiste `accountId`, `categoryId` opcional, `amountMinor`, `currency`, `type`, `transferAccountId` (obligatorio solo si `type=transfer`), `note`, `frequency`, `interval` (ignorado si `frequency=once`), `nextDate`, `endDate` opcional y `requiresConfirmation`; sin límite de plantillas activas.
2. Etiquetas vía tabla puente `ScheduledPaymentTags` (N:N con `Tags`, misma mecánica que `TransactionTags`); nunca permitidas si `type=transfer`.
3. En modo automático, al llegar `nextDate` se genera una `Transaction` con `source=scheduled` y `scheduledPaymentId`, sin intervención del usuario; las etiquetas se copian puntualmente a `TransactionTags`.
4. `once` → tras generar queda inactiva/histórica y `nextDate` no avanza; repetible → `nextDate` avanza según `frequency`/`interval`; `endDate` alcanzado → deja de generar sin borrarse.
5. Catch-up al reabrir la app: todas las ocurrencias vencidas se generan (automático) o se listan como pendientes acumuladas (manual, chip ×N), sin perder ninguna y sin duplicar ante interrupción a medias.
6. Modo manual: llegar a `nextDate` no afecta el saldo hasta que el usuario confirma.
7. Confirmar SIEMPRE abre primero una vista de verificación editable (date/accountId/amountMinor editables; categoryId/note/type/currency de solo lectura); ningún camino de un toque la evita, tampoco en revisión guiada por lote.
8. Confirmar aplica la transacción con los valores finales + `source=scheduled` + `scheduledPaymentId`; editar en la confirmación no muta la plantilla.
9. Omitir descarta sin generar transacción, avanza a la siguiente, es reversible (Snackbar + Deshacer) y solo vive dentro de la hoja/flujo de verificación.
10. Posponer mueve solo esa ocurrencia a una fecha posterior (mínimo `max(fecha original, hoy)`), sin afectar saldo ni cadencia de la plantilla; reversible; disponible desde detalle y desde la hoja de confirmación.
11. Próximos vencimientos (HU-04): plantillas activas ordenadas por `nextDate` ascendente; una plantilla con pendiente no se repite; contador "Activos · N" cuenta todas las activas.
12. Editar plantilla (HU-05) no toca transacciones ya generadas, solo ocurrencias futuras; eliminar detiene la generación futura preservando `scheduledPaymentId` como referencia histórica.
13. Detalle de plantilla muestra historial (`source=scheduled`) con 3 filas iniciales y "Ver historial completo (N)" que expande in-place; cada fila enlaza al detalle de esa transacción.
14. Guardar un movimiento con fecha futura en Transacciones pregunta si es pago programado antes de persistir; aceptar abre el flujo prellenado sin acoplar dominios; rechazar conserva el comportamiento normal.
15. `schemaVersion` 10 → 11, migración `onUpgrade` aditiva sin pérdida de datos, con paridad en el esquema espejo de PowerSync.
16. Plantilla `type=transfer` exige `transferAccountId`, no admite categoría ni etiquetas (ni en plantilla ni en confirmación).

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/database/app_database.dart` | `schemaVersion` 10→11; nuevo enum `ScheduledOccurrenceStatus`; tablas `ScheduledPaymentTags` y `ScheduledPaymentOccurrences` (ledger de idempotencia/estado de ocurrencia); migración `onUpgrade` aditiva `if (from < 11)`. |
| `lib/core/database/powersync_schema.dart` | Espejo de ambas tablas nuevas en snake_case + `_syncColumns`. |
| `lib/features/scheduled_payments/domain/**` | Entidades (`ScheduledPayment`, `ScheduledPaymentOccurrence`, `Tag`, `ScheduledPaymentDraft`, `ScheduledPaymentSummary`, `PendingScheduledOccurrence`, `ScheduledPaymentDetail`), `ScheduledPaymentRepository` y 17 casos de uso (crear/editar/eliminar/listar/detalle/historial/pendientes/generar-vencidos/confirmar/omitir+deshacer/posponer+deshacer/proyectar/tags). |
| `lib/features/scheduled_payments/data/**` | Mappers, datasources locales (plantillas + tags) y `ScheduledPaymentRepositoryImpl`. |
| `lib/features/scheduled_payments/presentation/**` | 8 cubits (list, pending, confirmation sheet, guided review, snooze sheet, form, detail, tag picker), 4 páginas, 3 widgets (`ScheduledCard`, `ScheduledPendingRow`, `ScheduledPaymentTagsField`) y 3 sheets (confirmation con variante guiada, snooze, delete). |
| `lib/features/transactions/presentation/widgets/sheets/future_date_scheduled_payment_prompt_sheet.dart`, `transaction_form_state.dart`, `transaction_form_page.dart` | Puente HU-06: `isFutureDate` intercepta Guardar en movimientos nuevos y abre el prompt; aceptar navega vía callback resuelto por el router (sin import cruzado de dominios). |
| `lib/core/router/app_router.dart` | Rutas `/pagos-programados` (lista, nuevo, `:id`, `:id/editar`, por-confirmar) bajo Más; arma la URL del puente con query params. |
| `lib/features/home/presentation/pages/more_page.dart` | Navega de verdad a Pagos programados (ya no "Próximamente"). |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` (+ gen) | Strings nuevos, reutilizando `transactionForm*`/`common*` existentes donde aplicaba. |
| `lib/core/di/injection.config.dart` | Regenerado con las 8 nuevas entradas de DI de la feature. |
| `test/features/scheduled_payments/**`, `test/features/transactions/presentation/pages/transaction_form_page_test.dart`, `test/features/home/presentation/pages/more_page_test.dart` | Suite nueva/actualizada (ver sección Tests). |

## Tests

Resultado: `flutter analyze` limpio, suite unit/widget en verde. E2E (Patrol) en skip — no se corrió en esta pasada.

```bash
flutter analyze
flutter test
flutter test test/features/scheduled_payments/
flutter test test/features/transactions/presentation/pages/transaction_form_page_test.dart
flutter test test/features/home/presentation/pages/more_page_test.dart
# e2e (no corrido en esta corrida):
# patrol test
```

Escritos en esta corrida: `test/features/scheduled_payments/presentation/cubit/guided_review_cubit_test.dart`, `test/features/scheduled_payments/data/scheduled_payment_repository_impl_test.dart` (más el resto de la suite listada en el change map).

### Cobertura por criterio

| AC | Estado | Evidencia |
|---|---|---|
| 1 | ✅ | `create_scheduled_payment_test.dart`, `scheduled_payment_repository_impl_test.dart` |
| 2 | ✅ | `scheduled_payment_repository_impl_test.dart` (criterio 16 transfer + copia de etiquetas) |
| 3 | ✅ | `scheduled_payment_repository_impl_test.dart` (modo automático genera y copia etiquetas) |
| 4 | ✅ | `scheduled_payment_repository_impl_test.dart` (once inactiva / endDate detiene) |
| 5 | ✅ | `scheduled_payment_repository_impl_test.dart` (automático y manual, chip ×N) |
| 6 | ✅ | `scheduled_payment_repository_impl_test.dart` (modo manual no afecta saldo) |
| 7 | ✅ | `confirmation_sheet_cubit_test.dart`, `guided_review_cubit_test.dart` |
| 8 | ✅ | `scheduled_payment_repository_impl_test.dart`, `confirmation_sheet_cubit_test.dart`, `guided_review_cubit_test.dart` |
| 9 | ✅ | `scheduled_pending_row_test.dart`, `pending_occurrences_page_test.dart` (confirma que no hay gesto de un toque que omita) |
| 10 | ✅ | `snooze_scheduled_occurrence_test.dart`, `confirmation_sheet_cubit_test.dart`, `guided_review_cubit_test.dart`, `scheduled_payment_repository_impl_test.dart` |
| 11 | ✅ | `scheduled_payments_list_cubit_test.dart`, `scheduled_payment_repository_impl_test.dart` |
| 12 | ✅ | `scheduled_payment_repository_impl_test.dart` (no toca generadas / borra vía `tombstonedAt`) |
| 13 | ✅ | `scheduled_payment_repository_impl_test.dart` (historial paginado) |
| 14 | ✅ | `transaction_form_page_test.dart`, `scheduled_payment_form_cubit_test.dart` |
| 15 | ⚠️ GAP (sigue abierto) | `app_database.dart` confirma `schemaVersion=11` y migración aditiva; verificación solo indirecta (tests abren DB en memoria ya en v11). Sin test explícito de migración v10→v11: confirmado que no existe `test/core/database/` ni infraestructura de schema snapshots en todo el repo — gap sistémico preexistente, no solo de esta feature; construir esa infraestructura se dejó fuera de alcance a propósito. Paridad con `powersync_schema.dart` sin test automatizado. |
| 16 | ✅ | `scheduled_payment_draft_test.dart`, `scheduled_payment_form_cubit_test.dart`, `scheduled_payment_repository_impl_test.dart` |

## 👤 Verifica a mano

- [ ] Hoja de confirmación y revisión guiada, ambos temas (claro/oscuro), contra `design-system/billetudo/pages/pagos-programados.md`.
- [ ] Gestos reales (swipe/tap) en `ScheduledPendingRow`/`pending_occurrences_page`: confirmar que ningún gesto de un toque omite o aplica sin pasar por la hoja (AC7/AC9).
- [ ] Generación al reabrir la app tras cerrarla varios días (AC5) con la app realmente cerrada por el SO, no solo simulada con `now:` en tests.
- [ ] Paridad línea por línea `app_database.dart` ↔ `powersync_schema.dart` para `ScheduledPayments`/`ScheduledPaymentTags`/`ScheduledPaymentOccurrences` (AC15).
- [ ] Migración real device-a-device: usuario en schemaVersion 10 actualiza y conserva sus datos.
- [ ] e2e quedó en skip — correr `patrol test` en emulador si se quiere automatizar.

## Pendientes y riesgos

**Blockers sin resolver:** ninguno.

**Gaps de cobertura:**
- ~~AC9: falta widget test de "no hay omitir de un toque" en la UI real de la fila pendiente.~~ Cerrado.
- AC15: sin test de migración explícito (gap sistémico del repo — no hay infraestructura de schema snapshots en `test/core/database/` para ninguna feature, confirmado); paridad PowerSync sin verificación automatizada. Sigue abierto.
- ~~`bloc_test` de `ScheduledPaymentDetailCubit`/`SnoozeSheetCubit` (0% cobertura).~~ Cerrado: 11 + 6 `bloc_test`s respectivamente.
- ~~Widgets sin test: `SnoozeSheet`, `ScheduledPaymentHistoryRow`, `DeleteScheduledPaymentSheet`, `ScheduledCard`, `finished_scheduled_payments_page.dart`, `pending_occurrences_section.dart`, `scheduled_count_pill.dart`.~~ Cerrado, los 7.
- Nuevo: tema oscuro de los widgets tocados en la ronda 5/6 de fidelidad visual (`ScheduledPaymentCategoryTiles`, `ScheduledPaymentFrequencyUnitChip`, `ScheduledPaymentModeRadioCard`, header del formulario, `CategoryPickerChip` de Transacciones) verificado con tests dedicados — confirman que resuelven `AppColors.dark`, no `light`, en modo oscuro. ~80 tests nuevos en total (`flutter test test/features/scheduled_payments test/features/transactions` → 400/400 verde).

**Riesgos del plan (documentados durante la corrida):**
- Se usó `tombstonedAt` (no `deletedAt`) para eliminar una plantilla, porque `ScheduledPayments.id` es referenciado por `Transactions.scheduledPaymentId` y CLAUDE.md prohíbe `deletedAt` para mantener viva una fila por un FK — desviación deliberada del texto literal del doc de requisitos, siguiendo el precedente de Cuentas (HU-08).
- El modelo de estado por ocurrencia (`ScheduledPaymentOccurrences`, tabla ledger con `uniqueKeys(scheduledPaymentId, occurrenceDate)`) no estaba explícito en el doc de requisitos (solo cubría `ScheduledPaymentTags`); se decidió en la etapa de esquema y se documentó su razonamiento (idempotencia del catch-up, soporte de N pendientes acumuladas, separación del ancla original vs. posponer).
- `generate_due_scheduled_payments` debe seguir siendo idempotente y transaccional ante interrupciones; cubierto por test pero sin prueba de crash real a medias.
- El puente HU-06 pasa el borrador vía query params de navegación (no dependencia domain→domain).
- "Revisar todas" (revisión guiada) es estrictamente secuencial — no existe aplicar-N-de-un-golpe; verificado en `guided_review_cubit_test.dart`.
- Deuda de diseño señalada para `pencil-designer`/`ui-ux-reviewer`: tap targets de "+ Etiqueta" y "×" del Tag Chip deben quedar en 44pt (hoy 36px/12px); el label del Tag Chip debe usar `$primary-on-soft-strong` local en vez del token global (falla AA).
- Zona horaria: la comparación contra "hoy" (vencimiento y piso de Posponer) usa medianoche local de forma consistente; verificar en dispositivo real si hay dudas de huso horario.
- Fuera de alcance a propósito (seam dejado listo): consumo de `project_upcoming_occurrences` por Presupuestos (HU-12) y notificaciones locales de vencimiento (Fase 2).
- Bloqueo de entorno preexistente (no introducido por esta corrida): `dart run build_runner build` fallaba por `hook/build.dart` de native assets (`powersync`/`sqlite3`) incompatible con este SDK; se resolvió con `--force-jit`, ahora documentado de forma durable en el README (sección "Generar el código de Drift"). Causa raíz sigue sin resolverse (bug del SDK/toolchain, no de este repo).
- ~~Deuda de fidelidad visual: ... componentes Material genéricos en vez de replicar 1:1 los frames de Pencil ...~~ Cerrada en las rondas 5-6 (ver "Fidelidad visual — historial de correcciones" arriba). Las clases privadas dentro de archivos de página/sheet (violación deliberada de `avoid_widget_functions`/`avoid_private_widgets`) no se auditaron de nuevo en esta pasada — sigue siendo deuda técnica menor, no visual.
- ~~Edición de monto en la hoja de confirmación usa `AlertDialog` + `TextField`~~ Cerrado en la ronda 2: ahora expande el teclado calculadora real in-situ (`ScheduledPaymentEditableAmountField` + `CalculatorAmountBuffer`), igual que Transacciones.
- ~~Pendiente real para `qa-automator`: `bloc_test` de ... `SnoozeSheetCubit`, `ScheduledPaymentDetailCubit` ..., y widget tests de las 4 páginas nuevas.~~ Cerrado (ver "Gaps de cobertura" arriba) salvo AC15, que sigue abierto.
- Warning no bloqueante de `drift_dev`: "Duplicate orderings/filters ... scheduledPaymentsRefs on table $AccountsTable" — `ScheduledPayments.accountId`/`transferAccountId` no usan `@ReferenceName` a diferencia de `Transactions`; corregir cuando se vuelva a tocar esa tabla.

## Fidelidad visual — historial de correcciones (posterior al cierre original)

La corrida original de `feature-dev` entregó la feature funcionalmente completa pero con deriva visual real frente a `billetudo.pen` (componentes Material genéricos en vez de los frames citados en el change map — ver "Deuda de fidelidad visual" arriba). Motivó la regla del gate de Pencil que hoy vive en `CLAUDE.md` ("antes de implementar UI diseñada, un agente con acceso real al `.pen` debe confirmarlo"). Se corrigió en rondas separadas, todas verificadas por lectura directa de `billetudo.pen` (no solo contra los `.md` de spec):

1. **Ronda 1-4 (auditoría inicial + 3 pasadas de fix):** lista, tarjetas, hoja de confirmación, revisión guiada, hoja de posponer, página de detalle y formulario — reescritos contra los frames reales (`Zona — PAGOS PROGRAMADOS`). Cerró: teclado calculadora real (no `AlertDialog`), tarjetas de radio para modo de confirmación (no `SwitchListTile`), bottom sheet para acciones (no `PopupMenuButton`), Hero + Identity Strip en detalle, Zona Fija de monto anclada en el formulario, estructura de la Card de Pendientes. De paso se cerró una deuda sistémica de l10n (59 claves de `scheduledPayments*` ausentes en `app_en.arb`).
2. **Ronda 5 (formulario de creación, `PP Form V3 — Resumen natural` / `jJhpW`+`J0DSIm`):** el flujo de creación/edición no había recibido la misma pasada — header (`AppBar` por defecto + texto "Save" → botones circulares `x`/`check` del patrón `Dtm0X`), selector de categoría (reusaba el pill horizontal de Transacciones, `EIoVx`, en vez del tile vertical `mK8oI` propio de Pagos Programados), color del chip de frecuencia seleccionado (violeta sólido → borde+texto sobre fondo `-soft` compartido) y estructura de las tarjetas Automático/Manual (radio a la izquierda → ícono-avatar fijo por modo + check circular al final, según `rVgOE`/`XM8VF`/`K5DTrf`).
3. **Ronda 6 (patrón de color por categoría, alcance ampliado a todo el sistema):** se detectó que `mK8oI`/`EIoVx` en el `.pen` estaban monocromáticos (violeta/gris) mientras el código real (`category_picker_chip.dart`, ya en producción en Transacciones) siempre usó el color propio de cada categoría — y que el propio `MASTER.md` ya documentaba el comportamiento con color, solo que el `.pen` no lo cumplía. Se decidió que el código manda (preferencia explícita del usuario) y se corrigió el `.pen` para que coincida, en cascada: `mK8oI`/`EIoVx` (Category Chip), `E9jSG` + 2 duplicados de tema oscuro/pantalla (tipo de cuenta), `F6niu`/`XddDb` + 15 instancias + 1 frame duplicado no-instanciado + 3 instancias de `SLfJW` en el sheet "Elegir categoría" (subcategorías). En código: `category_picker_chip.dart` (Transacciones) y `scheduled_payment_category_tiles.dart` (Pagos Programados, nuevo desde la ronda 5) corregidos para que el ícono conserve siempre el color propio de la categoría, nunca se repinte violeta al seleccionar.

Detalle completo de cada ronda solo en la conversación original (no se generó un `dev-runs/*.md` por ronda, al ser correcciones directas fuera del flujo `feature-dev`).

## Mensaje de commit sugerido

```
feat(pagos-programados): implementar plantillas, generación automática/manual, confirmación con verificación obligatoria y puente desde Transacciones

Cierra los 16 criterios de aceptación de Pagos programados (Nivel 0): plantillas
únicas/repetibles con etiquetas propias (ScheduledPaymentTags), catch-up
idempotente de ocurrencias vencidas, confirmación siempre editable vía hoja de
verificación (individual y revisión guiada), posponer/omitir reversibles,
próximos vencimientos, historial en el detalle, y el puente HU-06 desde el
formulario de Transacciones. schemaVersion 10→11 (ScheduledPaymentTags,
ScheduledPaymentOccurrences) con migración aditiva y espejo en PowerSync.

Gap conocido restante: sin test de migración explícito (AC15, gap sistémico
preexistente del repo — no hay infraestructura de schema snapshots).
```

## Commit de esta pasada (fidelidad visual + color por categoría + tests + docs)

```
fix(pagos-programados): fidelidad visual del formulario, color por categoría en todo el sistema y cobertura de tests

Corrige el formulario de creación/edición (header, selector de categoría,
chips de frecuencia, tarjetas Automático/Manual) contra el frame real de
Pencil (`PP Form V3`), tras detectar que no había recibido la misma pasada de
fidelidad visual que el resto de la feature.

De ahí se extiende un hallazgo más amplio: el componente `Category Chip`
(`mK8oI`/`EIoVx`) en billetudo.pen estaba monocromático (violeta/gris) pese a
que el código real y el propio MASTER.md ya usaban/documentaban color propio
por categoría. Se corrige el .pen para que coincida con el código (decisión
explícita: el código manda), en cascada sobre selector de tipo de cuenta y
filas/sheets de subcategoría — 20+ nodos e instancias corregidos en el .pen.

Cierra los gaps de cobertura documentados en dev-runs/pagos-programados.md:
bloc_test de ScheduledPaymentDetailCubit/SnoozeSheetCubit, widget tests de 7
componentes sin cobertura, verificación de tema oscuro en los widgets
tocados. AC15 (test de migración de esquema) sigue abierto — gap sistémico
del repo, no de esta feature.

Documenta el flag --force-jit para el bug conocido de build_runner en el
README.
```

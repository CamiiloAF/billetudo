# Dev run: bug-fixing + auditoría pixel-a-pixel

Fecha: 2026-07-19. Fuente: un reporte de 12 puntos del usuario (vivía en `docs/bug-fixes.md`, eliminado al cerrarse; recuperable del historial de git anterior a esa eliminación) + auditoría de diseño completa contra `billetudo.pen`, excluyendo `lib/features/scheduled_payments/` (corrida en paralelo de otro agente).

## Resumen

Corrida multi-agente (`architect` → `flutter-dev` × N → `ui-ux-reviewer` × N → `qa-automator` → `finance-code-reviewer`/`ui-convention-reviewer`/`compliance-reviewer`). El triage inicial encontró que varios de los 12 puntos compartían una sola causa raíz repetida en ~30 archivos (bottom sheets sin `useRootNavigator`, modales de borrado reconstruidos a mano en vez de reusar el componente de Pencil, copy de "papelera" prometiendo una feature inexistente) — se corrigieron una sola vez en vez de repetirse por pantalla.

**Código: 0 errores de compilación.** `flutter analyze`: 125 issues, todos `info` preexistentes (lints menores en `test/`, ninguno introducido por esta corrida). `dart run build_runner build --force-jit`: limpio.

## Incidente durante la corrida (resuelto)

Un agente `flutter-dev` corrió `git stash`/`git stash pop` a mitad de tarea, lo que chocó con el trabajo concurrente del otro agente (Pagos Programados/auth-sync) y revirtió a `HEAD` 7 archivos de su trabajo pre-existente (`CLAUDE.md`, `.claude/agents/flutter-dev.md`, `.claude/workflows/feature-dev.js`, `docs/requirements/05-auth-sync.md`, `lib/core/database/app_database.dart`, `lib/core/database/powersync_schema.dart`, `lib/core/router/app_router.dart`). Se detectó el `stash` sin soltar, se restauraron los 7 archivos vía `git checkout stash@{0} -- <paths>` (verificado sin pisar nada de esta corrida), y se confirmó que las anotaciones de Pencil (gestionadas por su propio MCP, no por git) seguían intactas. Se reconcilió todo con un `build_runner` limpio (0 errores) antes de continuar. El stash de seguridad quedó sin borrar (bloqueado por el clasificador de modo automático, acción destructiva).

## Cambios por punto del reporte

| # | Punto | Estado |
|---|---|---|
| 1, 3 | Ícono de "Eliminar cuenta" + alineación Institución/Tipo | ✅ `InfoRow` reescrito a layout vertical (label arriba/valor abajo) contra spec de Pencil (`myfAc`); ícono `trash-2` correcto |
| 2 | Últimos 4 dígitos/tasa de interés no condicionados | ✅ `showInterestRateField` gateado en `isCard`, mismo patrón que `showLast4Field` |
| 4a | "." al reeditar cupo máximo de tarjeta | ✅ `formatAmountForEditing` nuevo en `money_formatter.dart`, sin grouping fijo en `initialValue` |
| 4b | Cupo disponible/deuda mal calculados | ✅ Campo relabeleado a "Deuda actual" en tarjetas, guardado en negativo internamente |
| 5 | Patrimonio suma tarjetas de crédito | ✅ `AccountsOverview.from` excluye tarjetas por completo (decisión del usuario) |
| 6 | Detalle de movimiento no corresponde a Pencil (`Of2sW`) | ✅ Reconstruido completo: `DetailAmountHero`, `Info Card`, Tags Section condicional, `DetailActionsRow` |
| 7 | Snackbars no autodesaparecen | ✅ Causa raíz confirmada (SDK Flutter: `SnackBar.persist` default `true` con `action`); `persist: false` agregado en 5 sitios |
| 8 | Validación de cuenta obligatoria | ✅ Verificado, ya existía; onboarding completo queda fuera de esta corrida (feature nueva, tamaño L) |
| 9a | Nombres de categoría cortados | ✅ `category_accordion_row.dart`: nombre+contador apilados en `Column`, no compitiendo por ancho horizontal |
| 9b | Subcategorías sin ícono/color heredado | ✅ Herencia obligatoria en `category_form_cubit.dart` (encontrado y re-aplicado tras el incidente de stash) — UI de picker bloqueado **pendiente de diseño en Pencil** (ver bloqueos) |
| 10a | "Eliminar categoría" → "Eliminar subcategoría" | ✅ Label condicional + clave `.arb` en ambos idiomas |
| 10b | Copy de "papelera" inexistente | ✅ 4 claves reescritas (es+en) en categorías, transacciones y presupuestos |
| 11 | Categoría obligatoria + cuenta preseleccionada | ✅ Validación agregada, preselección por `sortOrder` vía `WatchAccounts` |
| 12a | Movimientos + filtros no corresponden a Pencil | ✅ Reconstruido contra `B3GGa`/`q0CTl`: chips, search row, lista agrupada por fecha, sheet de filtro por categoría con selección de fila completa |
| 12b | Sheets tapados por el bottom nav bar | ✅ Causa raíz única: `BottomSheetBase.show` ahora fuerza `useRootNavigator: true`; ~30 callers migrados |
| 12c | Modales de borrado no corresponden a Pencil (`o9116/qsjbj`) | ✅ Consolidados sobre `SheetMessage` con 3 patrones (simple rojo, con-transacciones violeta+opciones, raíz-con-subcategorías violeta+acciones) |

## Auditoría pixel-a-pixel del resto de la app

Hallazgo sistémico: 8 pantallas usaban `AppBar` de Material genérico en vez del componente `Page Header` de Pencil (`Dtm0X`). Se creó `PageHeader`/`PageHeaderCircleButton` reusables y se migraron `accounts_page`, `account_detail_page`, `archived_accounts_page`, `account_form_page`, `budget_detail_page`, `archived_budgets_page`, `budget_form_page`, `settings_page`. Además: `BalanceCardSimple` (radio/padding/borde), `budgets_page` con header propio alineado a la izquierda (no tab-root con `AppBar` centrado), `budget_form_page` migrado de `SegmentedButton`/`showDatePicker` nativos a `SegmentedControl`/`DatePickerSheet` del sistema de diseño, `more_row.dart` con colores neutros (violeta reservado solo para el CTA de respaldo en la nube), `more_page.dart` con ícono "Recurrentes" corregido.

## Bloqueado — requiere `pencil-designer` antes de implementar

- **Sheet "Eliminar presupuesto"**: no existe ningún frame en `billetudo.pen` para esta confirmación. `confirm_delete_budget_sheet.dart` no se tocó.
- **Picker de ícono/color de subcategorías**: Pencil no tiene diseñado un estado "color bloqueado/heredado" (sí existe el patrón para "Tipo", no se replicó para Apariencia). Además el catálogo de íconos en Pencil (32) diverge en 15/32 nombres del catálogo en código (`category_appearance.dart`) — no es ampliación, es divergencia real que debe reconciliarse con Diseño antes de tocar el grid.

## Fuera de alcance (acordado con el usuario)

- Onboarding completo (punto 8): feature nueva, corrida aparte.
- Expansión grande del catálogo de íconos: depende del bloqueo de arriba.
- `lib/features/scheduled_payments/`: cubierto por otro agente en paralelo.

## Verificación

- `flutter analyze`: 0 errores, 125 info preexistentes.
- `flutter test`: de 45 fallos iniciales (bloqueo de compilación por el incidente de stash) a 3 fallos tras el pase de QA final — 2 de esos 3 se corrigieron aparte (herencia de ícono/color re-aplicada, clave `categoryDeleteSubcategoryAction` agregada a `app_en.arb`).
- Revisión de convenciones: 1 comentario en español corregido a inglés (`more_page.dart`), 2 clases privadas extraídas a widgets públicos (`CategoryFilterHeaderAction`, `CategoryFilterNode`).
- Revisión de negocio/legal: sin hallazgos (Nivel 0 intacto, sin cupos client-side, tono no punitivo, promesa de "deshacer" verificada como real).
- Verificación visual en emulador: pendiente al momento de escribir este documento (bloqueada por trabajo en curso del otro agente en `scheduled_payments`, claves `.arb` faltantes).

Código queda **sin commitear**, listo para revisión del usuario.

# Calendario compartido: altura estable + navegación por año (calendar-fix-height-and-year-nav)

## Objetivo y criterios de aceptación

Corregir el componente compartido de calendario (`lib/core/widgets/month_calendar.dart`,
`date_picker_sheet.dart`, `date_range_picker_sheet.dart`) usado en Deudas, Metas, Presupuestos,
Transacciones, Pagos Programados y filtros de fecha:

1. La altura del sheet era inestable según el número de filas del mes (4/5/6 semanas visibles).
2. El label "mes año" del header no era interactivo — no había forma rápida de saltar a fechas lejanas.

Cambio único en el componente compartido, sin tocar cada pantalla llamante.

**Criterios de aceptación (10):**

| # | Criterio | Estado |
|---|---|---|
| 1 | `CalendarMonthGrid` siempre renderiza 6 filas de 44px, sin importar si el mes tiene 4, 5 o 6 semanas | ✅ |
| 2 | `DatePickerSheet`/`DateRangePickerSheet` mantienen la misma altura total al navegar entre meses | ✅ |
| 3 | El label "mes año" es tappable, con feedback visual y tooltip/semantics | ✅ |
| 4 | Tocar el label abre la vista de año dentro del mismo `MonthCalendar`/sheet, sin resetear la selección | ✅ |
| 5 | Elegir un año vuelve a la vista de mes (enero o el mes previamente visible) de ese año | ✅ |
| 6 | La vista de años respeta `disabledBefore`/`disabledAfter` | ✅ |
| 7 | La vista de años funciona igual en `DatePickerSheet` (un día) y `DateRangePickerSheet` (rango) | ✅ |
| 8 | Golden tests claro+oscuro para: mes de 4 filas y vista de año abierta | ✅ |
| 9 | `flutter analyze` y `flutter test` pasan sin nuevas fallas | ✅ |
| 10 | `design-system/billetudo/pages/calendario.md` documenta la decisión de diseño de la vista de año, aprobada por el usuario antes de implementar | ❌ **no cumplido** |

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/core/widgets/month_calendar.dart` | `MonthCalendar` pasa de `StatelessWidget` a `StatefulWidget` para manejar el toggle mes/año (`_showYearPicker`) sin tocar el estado del caller. `CalendarMonthGrid` ahora rellena hasta `weekRows` (6) filas con blanks. Nuevos widgets públicos: `MonthYearHeaderLabel` (InkWell + Tooltip + Semantics), `CalendarYearGrid`/`CalendarYearCell` (grilla 3×4 paginada de 12 en 12 años, reusa `MonthNavButton`). Nuevo parámetro requerido `onYearSelected`. |
| `lib/core/widgets/date_picker_sheet.dart` | Implementa `onYearSelected`: reposiciona `_visibleMonth` al año elegido manteniendo el mes visible. |
| `lib/core/widgets/date_range_picker_sheet.dart` | Idem para el modo rango. |
| `lib/features/scheduled_payments/presentation/widgets/sheets/snooze_sheet.dart` | `MonthCalendarBridge` actualizado al nuevo parámetro `onYearSelected` (único otro consumidor directo de `MonthCalendar`). |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` (+ `gen/`) | Nuevas claves: `datePickerSelectYear`, `datePickerPreviousYears`, `datePickerNextYears`, `datePickerBackToMonths`. |
| `test/core/widgets/month_calendar_test.dart` | Nuevo: 6 filas fijas (mes de 4 vs 6 filas), tap en label abre vista de año, no pierde selección previa, `onYearSelected` dispara y vuelve a vista de mes, años fuera de `disabledBefore`/`disabledAfter` deshabilitados. |
| `test/core/widgets/date_picker_sheet_test.dart` | Nuevo: altura del sheet estable entre mes de 4 y 6 filas, tap en label abre vista de año sin perder selección. |
| `test/features/transactions/presentation/golden/sheets_golden_test.dart` + goldens | Nuevo caso "custom range picker sheet, year selection view open" (claro+oscuro); goldens de rango existentes regenerados por el cambio de altura. |
| `test/features/scheduled_payments/presentation/golden/goldens/sheet_snooze_*.png` | Regenerados por el cambio de altura del calendario compartido. |

## Tests

- `dart analyze`: 0 issues nuevos (solo 2 infos preexistentes de `comment_references`, ajenos al cambio).
- `flutter test test/core/widgets/month_calendar_test.dart test/core/widgets/date_picker_sheet_test.dart test/features/transactions/presentation/golden/sheets_golden_test.dart test/features/scheduled_payments/presentation/golden/sheet_snooze_sheet_golden_test.dart`: 100% verde.
- Suite completa: verde, salvo 2 fallas en `confirmation_sheet_golden_test.dart` (~0.26% pixel diff) no relacionadas con este cambio — coincide con la flakiness conocida de goldens en esta máquina (~0.4% no determinista).
- **e2e (Patrol) falló**: `integration_test/scheduled_payments_patrol_test.dart` — bloqueado por escrituras concurrentes de otra sesión en `lib/features/settings/**` que dejaron `lib/core/di/injection.config.dart` en un estado intermitente durante la corrida, no por el cambio de calendario en sí. Re-ejecutar en limpio (ver checklist abajo).

Para re-correr:
```bash
dart analyze
flutter test test/core/widgets/month_calendar_test.dart test/core/widgets/date_picker_sheet_test.dart
flutter test test/features/transactions/presentation/golden/sheets_golden_test.dart
flutter test test/features/scheduled_payments/presentation/golden/sheet_snooze_sheet_golden_test.dart
flutter test integration_test/scheduled_payments_patrol_test.dart -d <device>   # patrol, requiere DI regenerado y estable
```

## Fidelidad visual vs Pencil

**N/A.** No existe `design-system/billetudo/pages/calendario.md` ni ningún `.md` equivalente
("núcleo", "compartido") para el widget de calendario compartido — el Glob sobre `pages/*.md`
solo devuelve specs de features de negocio. Tampoco existen goldens en
`test/features/core/presentation/golden/goldens/`. No es un fallo de acceso a `billetudo.pen`
(no se llegó a intentar `get_app_state` porque no hay contra qué mapear): es ausencia de spec y
de goldens propios de "core". Este es, además, el mismo gap que bloquea el criterio de
aceptación 10.

## 👤 Verifica a mano

- [ ] Verificar visualmente en un dispositivo real que la transición mes↔año no produce parpadeo/reflow perceptible (el widget test solo mide tamaños con tolerancia de 1px, no percepción visual real).
- [ ] Confirmar con el usuario que `design-system/billetudo/pages/calendario.md` fue aprobado antes de considerar cerrado el criterio 10 (el documento no existe en el repo).
- [ ] Re-ejecutar `integration_test/scheduled_payments_patrol_test.dart` en un emulador limpio una vez que `lib/core/di/injection.config.dart` esté regenerado y estable (el WIP concurrente de budgets/settings dejó el DI intermitente y bloqueó las 6 escenas del suite, incluida la nueva de year-view).

## Pendientes y riesgos

**Blocker sin resolver — criterio de aceptación 10:** `design-system/billetudo/pages/calendario.md`
no existe. CLAUDE.md exige que la decisión de diseño de la vista de año (layout, estados
habilitado/deshabilitado/seleccionado, transición mes↔año) se documente y sea aprobada por el
usuario **antes** de implementar en Flutter, vía el flujo `pencil-designer` → usuario aprueba →
`pages/<feature>.md` → `flutter-dev`. Ese gate no se cumplió: la UI (`CalendarYearGrid`,
`MonthYearHeaderLabel`) ya está implementada. El diseño se construyó leyendo `billetudo.pen`
solo en modo lectura y reusando el lenguaje visual existente de `CalendarDayCell` (misma
paleta `$primary`/`$primary-soft`, mismo patrón de pill de navegación, misma opacidad 0.35 para
deshabilitado), pero no pasó por aprobación formal.

**Gaps de cobertura:**
- No hay golden dedicado a un mes de 4 filas dentro de un sheet real (solo cubierto por widget
  test numérico en `month_calendar_test.dart`); el golden de vista de año sí existe.
- Fidelidad visual "core" sigue en N/A — sin spec ni goldens propios (ver sección de arriba).

**Riesgos:**
- El fix de altura invalida potencialmente **todos** los goldens que incluyan un
  `DatePickerSheet`/`DateRangePickerSheet` abierto en otras features (Deudas, Metas,
  Presupuestos) además de Transacciones y Pagos Programados — no se verificó exhaustivamente
  que no queden goldens desactualizados fuera de los archivos tocados en esta corrida.
- `MonthCalendar` cambió de `StatelessWidget` a `StatefulWidget`; los 13+ consumidores deberían
  revisarse por si alguno asume el comportamiento anterior (no se detectaron problemas, pero no
  hubo una auditoría exhaustiva de cada caller).
- El rango de años mostrado (paginado de 12 en 12) no tiene un límite superior/inferior
  documentado en una spec aprobada — quedó a criterio de implementación.

## Mensaje de commit sugerido

```
fix(core): estabilizar altura del calendario y agregar navegación por año

- CalendarMonthGrid siempre reserva 6 filas (44px) sin importar semanas visibles del mes
- MonthCalendar agrega vista de año (label "mes año" tappable) sin resetear selección
- Actualiza DatePickerSheet, DateRangePickerSheet y snooze_sheet al nuevo onYearSelected
- Nuevas claves l10n (es/en) y goldens de vista de año en transactions/scheduled_payments

Pendiente: design-system/billetudo/pages/calendario.md (criterio de aceptación 10, no
cumplido) — la vista de año se construyó sin pasar por el gate de aprobación de diseño.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```

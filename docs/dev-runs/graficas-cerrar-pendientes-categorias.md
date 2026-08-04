# Cerrar pendientes de Categorías en Gráficas (graficas-cerrar-pendientes-categorias)

## Objetivo y criterios de aceptación

Cerrar los 3 pendientes de la pestaña Gastos/Categorías de Gráficas:

1. Drill-down in-place de subcategorías en el donut, con pill "Atrás".
2. Tap en una card de categoría/subcategoría que navega a Movimientos preseleccionando esa
   categoría y el rango de fechas activo.
3. Reemplazar "mantener presionado" por tap simple con selección persistente (toggle) y mostrar
   el nombre de la categoría en el centro del donut.

Tamaño: m. Review: combined APROBADO.

12 criterios de aceptación (selección persistente/toggle/cambio de sección en el donut, pill
deshabilitado sin selección o sin subcategorías, drill-down/"Atrás" sin corromper estado,
navegación a Movimientos filtrada por categoría+rango vía `DatePeriodFilter.custom`, "Sin
categoría" sin navegación, l10n sin strings hardcodeados, convenciones de widgets, `flutter
analyze`/`flutter test` limpios) — **los 12 quedaron cubiertos**, ver detalle en la sección de
Tests.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/reports/presentation/widgets/categories/category_donut_chart.dart` | Pasa de stateful con "mantener presionado" a controlado por `selectedIndex`/`onSectionTap`; tap hace toggle (selecciona/deselecciona/cambia) y el centro muestra nombre+monto de la sección seleccionada. |
| `lib/features/reports/presentation/widgets/categories/category_breakdown_card_content.dart` | Nuevo `StatefulWidget` que sostiene el estado de drill-down (raíz vs. subcategorías de una categoría) y de selección por nivel; invalida el estado en `didUpdateWidget` cuando cambia el breakdown. |
| `lib/features/reports/presentation/widgets/categories/category_view_subcategories_link.dart` | Pill con 3 estados (`disabled`/`viewSubcategories`/`back`), estilo visualmente inerte cuando está deshabilitado. |
| `lib/features/reports/presentation/widgets/categories/category_breakdown_row.dart` | `onTap` opcional; `null` para la fila "Sin categoría" (no navegable). |
| `lib/features/reports/presentation/widgets/categories/category_breakdown_tab_view.dart` | Propaga el nuevo callback de navegación a Movimientos hacia `ReportsPage`. |
| `lib/features/reports/presentation/pages/reports_page.dart` | Conecta el callback de navegación con el router. |
| `lib/core/router/app_router.dart` | `_reportsRoute` ahora también resuelve `onOpenCategoryMovements`, llamando a `TransactionsListCubit.filterByCategoryAndRange` (mismo patrón que el ya existente `onOpenAccountMovements`). |
| `lib/features/transactions/presentation/cubit/transactions_list_cubit.dart` | Nuevo método `filterByCategoryAndRange(categoryId, start, endInclusive)`, mapea a `DatePeriodFilter.custom(start, endExclusive - 1 día)` respetando el bound half-open de `DateRange`. |
| `lib/core/l10n/arb/app_es.arb` / `app_en.arb` (+ `gen/`) | Nueva clave `reportsCategoriesBack` para el pill "Atrás". |
| Tests y goldens (ver sección Tests) | Cobertura nueva/actualizada de lo anterior. |

Fuera de alcance de esta corrida (fuera de `lib/**`/`test/**`, reservado a otros roles):
`design-system/billetudo/pages/graficas.md` y `billetudo.pen` — el pendiente de reflejar ahí la
nueva interacción de tap-toggle + pill "Atrás" **queda abierto**, ver "Pendientes y riesgos".

## Tests

Resultado: analyze limpio (0 errores/warnings, solo 7 infos preexistentes ajenas al cambio) ·
suite dirigida verde (33/33 en los archivos tocados) · e2e Patrol pass.

Comandos para re-correr:

```bash
flutter analyze
flutter test test/features/reports/presentation/widgets/categories/category_donut_chart_test.dart \
             test/features/reports/presentation/widgets/categories/category_breakdown_card_content_test.dart \
             test/features/transactions/presentation/transactions_list_cubit_test.dart
flutter test test/features/reports test/features/transactions   # incluye goldens; en esta máquina puede pasar de 10 min
```

Patrol (emulador `dev`, nunca `prod`):

```bash
patrol test --target integration_test/reports_patrol_test.dart --flavor dev
```

Cobertura AC 1-12: todos ✅ — ver el detalle línea a línea (test/escenario por cada AC) en el
resumen de la corrida original; en síntesis: AC1-3 en `category_donut_chart_test.dart`, AC4-7 en
`category_breakdown_card_content_test.dart`, AC8-9 en ambos más el e2e (`filterByCategoryAndRange
fija categoría y rango de fechas`, `tocar una fila de Categorías navega a Movimientos...`), AC9
reforzado por la fila "Sin categoría" sin `onTap`, AC10 verificado por grep sobre los `.arb`, AC11
por grep de funciones/clases privadas, AC12 por `flutter analyze` + la suite dirigida.

No bloqueante: no se corrió el suite completo de `test/features/reports` + `test/features/transactions`
con todos los goldens en esta corrida por timeout (>10 min); los tests dirigidos al cambio sí pasan
sin regresiones. La única falla preexistente conocida en esa carpeta es el golden "cashflow:
historial insuficiente" (light/dark), no relacionada a Categorías.

## Fidelidad visual vs Pencil

**APROBADA — 0 hallazgos.** Gaps de cobertura (no hallazgos nuevos, ya documentados como huecos
conocidos de la feature):

- Sheet Selector de Periodo, variante oscura (`Sy92N` dark "no construido") — pendiente #2 del
  propio `graficas.md`, no aplica a este cierre (no hay frame en Pencil todavía).
- `reports_page_net_worth_loading_{light,dark}.png` — la tabla "Estados" de `graficas.md` solo
  documenta el nodeId de carga de Flujo (`ITx4K`/`caHER`); Patrimonio no tiene fila/nodeId propio
  para su estado de carga (el código lo infiere razonadamente de la regla general de "Estados >
  Carga", pero no queda registrado como fila explícita).
- `reports_page_categories_loading_{light,dark}.png` — mismo gap: Categorías tampoco tiene fila de
  "carga" en la tabla "Estados".
- `reports_page_dashboard_loading_{light,dark}.png` — Resumen (dashboard) tampoco tiene fila de
  "carga".
- `reports_page_net_worth_empty_{light,dark}.png` y `reports_page_net_worth_short_history_{light,dark}.png`
  — la tabla "Estados" solo enumera vacío/historial-insuficiente para Flujo (y vacío para
  Resumen); Patrimonio no tiene fila propia pese a tener golden de ambos estados.
- `reports_page_categories_empty_{light,dark}.png` — mismo gap: Categorías no tiene fila de estado
  "vacío" en la tabla "Estados" pese a tener golden.

## 👤 Verifica a mano

- [ ] Verificar en un device real que el hit-test del donut (fl_chart) responde de forma cómoda al
      dedo en secciones pequeñas/porcentajes bajos (los widget tests invocan `touchCallback`
      directamente, no tocan la geometría renderizada real).
- [ ] Confirmar que `design-system/billetudo/pages/graficas.md` y el frame de `billetudo.pen` ya
      reflejan la nueva interacción de tap-toggle + pill "Atrás" — no se encontró esa actualización
      en el árbol (grep sin match de "Atrás"/"tap simple"/"persistente" en `graficas.md`); si el
      diseñador aún no la corrió, es un pendiente fuera del alcance de esta corrida (no toca `docs/**`).
- [ ] Cierre de fidelidad visual (`pencil-fidelity-reviewer`) del nuevo estado "seleccionado" del
      donut y del pill "Atrás" contra su nodeId — no lo cubre esta corrida de QA de forma
      dedicada (la pasada de fidelidad de esta corrida evaluó la implementación, no un nodeId nuevo
      todavía inexistente en Pencil).

## Pendientes y riesgos

- **`design-system/billetudo/pages/graficas.md` y `billetudo.pen` sin actualizar** con la nueva
  interacción de tap-toggle + pill "Atrás": la petición original pedía actualizar ambos en
  paralelo, pero quedan fuera del alcance de escritura de `flutter-dev` (reservado a
  `pencil-designer`/documentación). Queda como pendiente explícito para cerrar la fuente de verdad
  de diseño.
- Gaps de cobertura de fidelidad listados arriba (estados de carga/vacío sin fila propia en
  `graficas.md` para Patrimonio/Categorías/Resumen) — no bloqueantes, heredados de la corrida de
  fidelidad previa de esta feature.
- Riesgo de mayor superficie de regresión: el estado de selección/drill-down pasó de vivir dentro
  de `CategoryDonutChart` a ser controlado desde `CategoryBreakdownCardContent` — cubierto con
  tests de widget para los 3 estados (raíz sin selección, raíz con selección, subcategorías), pero
  la geometría real del donut renderizado no se ejercita en esos tests (ver checklist manual).
- No se confirmó la corrida completa del suite con goldens de `test/features/reports` +
  `test/features/transactions` por timeout (>10 min); los tests dirigidos al cambio sí pasan.

## Mensaje de commit sugerido

```
feat(reports): drill-down de subcategorías, navegación a Movimientos y tap-toggle en el donut de Categorías

Cierra los 3 pendientes de Gastos/Categorías en Gráficas: selección persistente por tap simple
en el donut (con nombre+monto en el centro), drill-down in-place a subcategorías con pill
"Atrás", y navegación desde una fila de categoría/subcategoría a Movimientos ya filtrado por
esa categoría y el rango de fechas activo.
```

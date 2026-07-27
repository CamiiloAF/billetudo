# Presupuestos — ajustar el monto para un solo período

Análisis del ítem 6 de `docs/bugfixes.md` (2026-07-20). Diseño completo (2 rondas) en Pencil,
listo para construir en código.

## Problema

Pedido del usuario: "tal vez hice un trabajo extra y me gané 2 millones más, y por consiguiente
mi presupuesto para el próximo mes será mayor, pero el resto de meses seguirá siendo igual."

Hoy `Budgets.amountMinor` vive directo en la fila de la plantilla — no hay concepto de "período"
persistido. `BudgetPeriodCalculator` deriva las ventanas `[start, endExclusive)` matemáticamente
desde `startDate` + `period`, sin snapshots por mes. Editar el monto afecta pasado, presente y
futuro por igual. Es una decisión ya documentada, no un vacío accidental: `docs/requirements/
06-presupuestos.md` HU-05/HU-09 dice explícito que "en Fase 0 el cálculo usa los valores vigentes
del presupuesto (no se congela por periodo)" y "editar no recalcula retroactivamente el histórico".

HU-07 (Rollover, diferido a Fase 3) ya anticipa esta misma tensión: "el arrastre exige estado
por-periodo... interactúa con la edición del monto y obliga a reglas de retroactividad — el tipo
de mecánica de fricción que nuestro diferenciador evita hacer obligatoria", con dos rutas
abiertas para cuando se implemente: "recompute determinístico desde `startDate` vs. tabla
`BudgetPeriods` con snapshots inmutables". Lo que pide el usuario es un subconjunto del mismo
problema (override de monto por período, sin arrastre automático).

## Dos enfoques evaluados

**A — Tabla `BudgetOverrides` nueva** (budgetId FK, periodStart, amountMinor). Modelo "correcto"
a largo plazo, pero con costo oculto real: `Budgets` usa hoy `deletedAt` (papelera reversible)
precisamente **porque ninguna otra tabla la referencia por FK** (HU-11). Agregar
`BudgetOverrides.budgetId → Budgets.id` obligaría a migrar ese borrado a `tombstonedAt` — cambio
de esquema y de lógica sobre una feature ya construida y probada. Edge cases sin resolver:
¿override sobre un mes ya cerrado (`archivedAt`)? ¿qué pasa si luego se mueve `startDate` de la
plantilla? En la práctica es construir la infraestructura de "estado por-período" que HU-07 ya
difirió a Fase 3, no un ajuste puntual.

**B — Fork manual, sin esquema nuevo (elegido)**: cerrar el presupuesto actual (`endDate` al
cierre del período vigente, deja de renovarse) y crear uno nuevo con el mismo alcance/periodicidad
pero `startDate` anclado al próximo ciclo y el monto ajustado. Reutiliza 100% del código
existente (`BudgetPeriodCalculator`, `CreateBudget`/`UpdateBudget` ya implementados). Cero riesgo
sobre `deletedAt`/`tombstonedAt`, cero migración Drift. Costo real: UX — hay que diseñar en
Pencil un flujo guiado de un toque ("Ajustar monto solo el próximo período") que haga esto bajo
el capó, y dejar claro en la lista que ahora son dos presupuestos relacionados (no uno con una
excepción).

## Diseño (enfoque B, resuelto en Pencil — 2026-07-20)

`pencil-designer` construyó el flujo completo en `billetudo.pen`, claro + oscuro, documentado en
`design-system/billetudo/pages/presupuestos.md` (sección "Ajustar monto — solo el próximo
período"). Node IDs: sheet de acciones actualizado `JR1Xp`/`Z72OIH` (4ª fila "Ajustar monto —
próximo período"), sheet de ajuste `A8ZfHd`/`D0EoN`, banner de detalle `reulY`/`ujbZf`.

Decisiones tomadas en diseño:
- Entrada en el `⋮` del detalle (no botón propio ni fila en la lista) — acción poco frecuente.
- Un solo sheet con un campo (monto actual de solo lectura + monto nuevo), sin sheet de
  confirmación aparte — mismo criterio que el sheet de Umbral de alerta, efecto reversible.
- El copy explicita la mecánica completa ("vuelve solo") en una sola tira informativa, sin dejarlo
  implícito.
- El detalle gana un banner "Ajuste programado" (reusa el lenguaje visual de `Programado — Entry`
  de HU-12) que, al tocarse, reabre el mismo sheet prefilled — no hay una acción de "cancelar"
  separada, revertir el monto ahí alcanza.
- La lista de presupuestos NO cambia mientras el período vigente sigue activo — el ajuste solo se
  ve reflejado cuando el ciclo rueda al presupuesto siguiente.

## Ronda 2 de diseño (resuelve los 3 hallazgos de `ui-ux-reviewer` — 2026-07-20)

`ui-ux-reviewer` encontró 3 hallazgos IMPORTANTE en la ronda 1: sin forma de cancelar el ajuste
programado, riesgo de confusión de copy con el banner "Programado" de HU-12, y duplicación de
componente. Los 3 resueltos:

1. **Cancelar**: el sheet gana una variante "editar/cancelar" (`k6fKsZ`/`PPzUv`), que se abre al
   tocar el banner del detalle cuando ya hay un fork pendiente. Botón secundario "Quitar ajuste"
   (icono `rotate-ccw`, neutral, no rojo) + primario "Aplicar cambios". Quitar ajuste cancela el
   fork, el ciclo siguiente vuelve solo al monto original.
2. **Confusión con HU-12**: el banner pasó de "Ajuste programado" a **"Ajuste de monto próximo"**
   (sin la palabra "programado"), manteniendo el ícono ya distinto (`repeat-1` vs `calendar-clock`
   de HU-12).
3. **Duplicación**: el banner ya no copia la geometría de `Programado — Entry` a mano — ambos
   instancian el mismo componente genérico `Entry Row` (`s09qcC`, ahora tratado como reusable
   compartido entre HU-12 y este flujo).

Documentado completo en `design-system/billetudo/pages/presupuestos.md`, sección "Ajustar monto —
solo el próximo período". Node IDs finales: sheet crear `A8ZfHd`/`D0EoN`, sheet editar/cancelar
`k6fKsZ`/`PPzUv`, banner `AYsw7`/`s0ZlV` (dentro de `reulY`/`ujbZf`).

**Regla de negocio para un segundo ajuste sobre un fork ya pendiente**: resuelto en diseño como
"editar el fork existente" (reabre prefilled, permite cambiar o quitar) — nunca acumula forks.
`flutter-dev` debe implementar exactamente ese criterio: si ya existe un fork pendiente para el
presupuesto, la acción del `⋮` reabre en modo editar; si no existe, en modo crear.

## Plan para retomar (enfoque B)

Tamaño estimado: **M**. No toca esquema Drift ni `deletedAt`/`tombstonedAt`.

1. ~~`pencil-designer`: diseñar el flujo~~ — hecho, ver arriba (2 rondas).
2. ~~`ui-ux-reviewer`: auditar el flujo~~ — hecho, los 3 hallazgos resueltos en ronda 2.
3. `flutter-dev`: nuevo caso de uso (ej. `SplitBudgetForNextPeriod` en
   `lib/features/budgets/domain/usecases/`) que orqueste el cierre del presupuesto actual +
   creación del nuevo (próximo período, ajustado) + creación del tercero (desde el período
   siguiente, monto original, indefinido); caso de uso de cancelación que revierte el fork
   pendiente; expuestos desde el cubit de detalle existente. Claves l10n nuevas. Mirar los frames
   de Pencil arriba antes de implementar (gate obligatorio).
4. `qa-automator`: tests del caso de uso + goldens del flujo nuevo.
5. Reviews finales (finance-code-reviewer, ui-convention-reviewer, compliance-reviewer — Nivel 0
   sigue intacto, esto no debe quedar detrás de ningún gate).

No requiere `/drift-schema-change`.

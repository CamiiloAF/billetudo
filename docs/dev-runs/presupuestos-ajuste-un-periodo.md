# Presupuestos — ajustar el monto para un solo período

Análisis del ítem 6 de `docs/bugfixes.md` (2026-07-20). Pendiente de implementar — plan para
retomar en otra sesión, **no construido todavía**.

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

## Plan para mañana (enfoque B)

Tamaño estimado: **M**. No toca esquema Drift ni `deletedAt`/`tombstonedAt`. Sí requiere:

1. **`pencil-designer`**: diseñar el flujo "Ajustar monto solo el próximo período" — no existe
   frame hoy en `billetudo.pen`/`design-system/billetudo/pages/presupuestos.md`. Definir:
   - Punto de entrada (¿acción en el detalle del presupuesto? ¿en el menú de opciones?).
   - Copy que explique claramente que se crean dos presupuestos relacionados (evitar confusión
     al ver "de repente hay 2 presupuestos de Comida" en la lista).
   - Si el usuario debe poder elegir "solo el próximo período" vs. "desde el próximo período en
     adelante" (fork permanente) — el pedido original habla de "1 sola vez", así que el flujo
     por defecto debería volver al monto original después de un ciclo, pero confirmar con el
     usuario si hace falta un tercer presupuesto automático para eso o si el usuario reactiva
     manualmente el original.
2. **`ui-ux-reviewer`**: auditar el flujo antes de pasar a construir.
3. **`flutter-dev`**: nuevo caso de uso (ej. `SplitBudgetForNextPeriod` en
   `lib/features/budgets/domain/usecases/`) que orqueste el cierre del presupuesto actual +
   creación del nuevo, expuesto desde el cubit de detalle existente. Claves l10n nuevas.
4. **`qa-automator`**: tests del caso de uso + goldens del flujo nuevo.
5. Reviews finales (finance-code-reviewer, ui-convention-reviewer, compliance-reviewer — Nivel 0
   sigue intacto, esto no debe quedar detrás de ningún gate).

No requiere `/drift-schema-change`.

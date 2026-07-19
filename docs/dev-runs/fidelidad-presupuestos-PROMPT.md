# Prompt: auditoría de fidelidad de Presupuestos contra Pencil

Corrida equivalente a la que se hizo con Pagos programados el 2026-07-19. Pega el bloque
de abajo en una sesión nueva de Claude Code, en la raíz del repo.

**Antes de arrancar, verifica que no haya trabajo en vuelo sobre `billetudo.pen`
ni sobre `lib/core/l10n/arb/`** — son los dos recursos que no toleran dos escritores.

---

## Prompt

```
Necesito una auditoría de fidelidad visual completa de la feature Presupuestos
(`lib/features/budgets/`, requisitos en `docs/requirements/06-presupuestos.md`)
contra su diseño real en `billetudo.pen`, y que se apliquen las correcciones.

Sospecho deriva amplia: hay indicios de que esta feature se implementó sin acceso
real a Pencil. Trátalo como una auditoría, no como un vistazo — en Pagos programados
el mismo ejercicio encontró 11 hallazgos críticos, incluidos componentes del sistema
reemplazados por Material genérico, datos que el diseño muestra y el código no, y
una acción destructiva pintada con el color de marca.

Punto de partida:
- `design-system/billetudo/pages/presupuestos.md` ya tiene tabla de nodeIds.
- La feature tiene CERO goldens hoy. 4 páginas (`budgets_page`, `budget_detail_page`,
  `budget_form_page`, `archived_budgets_page`) y 4 sheets (`budget_detail_actions`,
  `budget_icon`, `budget_threshold`, `confirm_delete_budget`). Construir esa cobertura
  es la mayor parte del paso 1.

Corre `/design-fidelity-check presupuestos` y luego aplica las correcciones.
```

---

## Lecciones de la corrida de Pagos programados — dáselas al agente si no las aplica solo

1. **Las tandas de corrección van secuenciales, no en paralelo.** Comparten
   `lib/core/l10n/arb/*.arb`. Partir por áreas de pantalla (lista → sheets → detalle/formulario)
   funcionó bien: 3-4 tandas de `flutter-dev`, cada una con su regeneración de goldens.
2. **Re-verificar al final con `pencil-fidelity-reviewer`.** La segunda pasada encontró
   deriva *nueva* introducida por las propias correcciones, además de tres decisiones que
   los desarrolladores tomaron por su cuenta sin frame que las respaldara.
3. **Pedir explícitamente que responda preguntas puntuales contra el `.pen`.** Ej.:
   "¿existe el token X?", "¿qué icono usa este nodo?". `flutter-dev` no ve Pencil y adivina;
   el reviewer sí puede dirimir. En esta corrida así se descubrió que el spec escrito
   estaba mal (decía `chevron-down` donde el componente usa `chevron-up`).
4. **Marcar explícitamente lo que NO debe tocar.** Los cambios transversales
   (`money_formatter`, componentes de `lib/core/`) deben salir del alcance de las tandas
   y decidirse aparte, o un agente los cambia para toda la app sin que nadie lo revise.
5. **Los gaps de cobertura valen tanto como los hallazgos.** Preguntar al final:
   qué goldens no tienen fila en el `.md`, qué filas del `.md` no tienen golden, y qué
   reglas del spec no están ejercitadas por ningún fixture. En Pagos programados la regla
   más específica de la pantalla no estaba cubierta por ningún test.
6. **Ojo con las pantallas que existen en código pero no en Pencil.** Apareció una
   (`FinishedScheduledPaymentsPage`) que nunca se diseñó; auditarla era imposible. Si sale
   una equivalente en Presupuestos, es trabajo de `pencil-designer` y decisión del usuario,
   no algo que el auditor pueda resolver.
7. **Actualizar `pages/presupuestos.md` al cerrar** con lo que la auditoría descubra:
   filas de nodeId faltantes, reglas que el `.pen` contradice, y deuda técnica ya resuelta.

## Estado de dependencias cruzadas

- **Signo de los gastos:** ya se alineó a Pencil en toda la app (gasto sin signo, ingreso
  con `+`). `budget_activity_row.dart` fue uno de los call sites corregidos. No revertir.
- **`AppFab` (`lib/core/widgets/app_fab.dart`):** existe y es el FAB del sistema de diseño
  (`H5mzN`). Si `budgets_page` usa `FloatingActionButton` de Material, arrastra la misma
  deriva y debe migrar.
- **`Error State` (`ECG7D`):** su título por defecto se corrigió en el `.pen`
  ("información" con tilde) y se centró. Afecta a cualquier feature que lo instancie.

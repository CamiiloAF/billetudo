# Fidelidad visual — Presupuestos

Corrida `/design-fidelity-check presupuestos` (2026-07-20), ítem 9 de `docs/bugfixes.md`.

El prompt de auditoría preparado con antelación (`docs/dev-runs/fidelidad-presupuestos-PROMPT.md`)
sospechaba deriva amplia, con Pagos Programados (11 críticos) como referencia de severidad
esperada, y asumía "cero goldens" en la feature. Ambas premisas resultaron desactualizadas: ya
existían 86 goldens (generados en trabajo previo del mismo día), y la feature no necesitó ningún
ajuste por los fixes transversales aplicados hoy en otras features (`formatSymbol()`, signo en
gastos, `SegmentedControl`/`PageHeader` compartidos) — ya estaba alineada de antes.

## Auditoría — resultado

**1 hallazgo IMPORTANTE**, ningún CRÍTICO. Contraste directo con Pagos Programados: la acción
destructiva reversible (eliminar presupuesto) usa correctamente violeta neutral (`$primary`), no
rojo — exactamente el tipo de error que sí ocurrió en esa auditoría y aquí no. `AppFab` del
sistema de diseño en uso, no `FloatingActionButton` de Material.

**Hallazgo:** el `Error State` compartido (`ECG7D`) trunca su subtítulo en las 3 pantallas de
Presupuestos con estado de error (lista, histórico, detalle): mostraba "Tus datos siguen
guardados en tu dispositivo" en vez del texto completo "Tus datos siguen guardados en tu
dispositivo. Intenta de nuevo." — la clave l10n compartida (`accountsErrorLocalFirst`, reusada
también por Cuentas y Categorías) tenía el texto recortado en los `.arb`.

## Fix

Una sola clave l10n corregida (`accountsErrorLocalFirst`, es/en) — sin cambios en `lib/`, el
widget de Presupuestos ya reutilizaba correctamente la clave compartida. El fix cascadeó
automáticamente a Cuentas y Categorías, que tenían el mismo texto truncado (no detectado antes
porque Cuentas nunca se cerró formalmente contra el gate de fidelidad y Categorías se auditó
antes de esta pasada sin cubrir ese estado específico). Goldens de error regenerados en las 3
features (10 PNGs); un widget test de Cuentas con el string viejo hardcodeado también corregido.

## Veredicto final

**✅ Aprobada.** Sin hallazgos CRÍTICO/IMPORTANTE pendientes tras el fix. Reviews finales
(finance-code-reviewer, compliance-reviewer): sin hallazgos.

### Gaps de documentación, no bloqueantes

- Presupuestos no tiene ninguna instancia de `Error State` (`ECG7D`) colocada en el `.pen` (a
  diferencia de Cuentas/Categorías/Movimientos/Pagos programados/Metas, que sí la tienen) — el
  título usado en código ("No pudimos cargar tus presupuestos") es plausible por analogía pero
  nunca se verificó literalmente contra un frame. Recomendado para `pencil-designer`.
- Varios estados sin fila propia en `presupuestos.md` (error, vacío de histórico, carga, "editar",
  variantes de sobres/stepper) — todos con golden, ninguno bloqueante, mismo patrón de "estado
  razonable sin frame dedicado" ya visto en otras features hoy.
- Sheet "¿Qué es el modo sobres?" (`eBwb0`/`gAetG`) documentado en el `.md` sin golden — pendiente
  de cobertura, no de fidelidad.
- Nota de higiene para `qa-automator`: 3 fixtures de golden (`overspentEntry`,
  `scheduledHealthyEntry`, `scheduledRiskEntry`) usan `startDate` anclado al día 1, coincidiendo
  visualmente por casualidad con el patrón del bug de "mes calendario" ya corregido — no es una
  regresión (el cálculo respeta la fecha de anclaje real), pero vale la pena anclarlas a otro día
  para no obligar a un futuro auditor a rastrear el código cada vez.

### Hallazgo colateral, fuera de alcance de esta corrida

`transactionsErrorLocalFirst` usa una redacción distinta ("Tus datos siguen a salvo en este
dispositivo.") en vez del texto estándar de `ECG7D` — detectado al revisar la clave compartida,
pero Transacciones ya se cerró en el ítem 2 de este mismo backlog. Pendiente para una futura
pasada sobre esa feature.

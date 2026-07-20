# Track de fidelidad visual contra Pencil

Estado de la auditoría de fidelidad (`/design-fidelity-check` vía `pencil-fidelity-reviewer`, o
la auditoría manual equivalente) por feature, contra `billetudo.pen`. Actualizar esta tabla
cada vez que se cierre o se agende una pasada — es el único lugar que consolida el estado,
los `docs/dev-runs/*.md` quedan como el detalle de cada corrida.

## Cómo leer la tabla

- **Estado**: ✅ Aprobada · 🟡 Parcial (cubre parte de la pantalla o quedó pendiente de re-verificación) · ⏳ Agendada (hay prompt/plan listo, no corrida) · ❌ Sin auditar · ⬜️ N/A (feature sin UI aún o sin frame en Pencil)
- **Goldens**: si la feature tiene cobertura golden (`test/features/<feature>/presentation/golden/`), prerrequisito técnico para que `pencil-fidelity-reviewer` pueda comparar sin emulador.
- **Fuente**: el dev-run o documento donde se registró el resultado.

| Feature | Estado | Fecha | Goldens | Fuente | Notas |
|---|---|---|---|---|---|
| Cuentas | 🟡 Parcial | 2026-07-19 | ✅ (`test/features/accounts/.../golden`) | `docs/dev-runs/bug-fixes-pixel-audit.md` | Auditoría pixel-a-pixel corrigió 8 pantallas migradas a `PageHeader`, `BalanceCardSimple`, detalle de movimiento (`Of2sW`), etc. No hubo un cierre formal vía `/design-fidelity-check` después de esas correcciones — falta re-verificación con `pencil-fidelity-reviewer` para pasar a ✅. |
| Pagos programados | ✅ Aprobada | 2026-07-19 | ✅ (`test/features/scheduled_payments/.../golden`) | `docs/dev-runs/pagos-programados.md` (sección "Fidelidad visual — historial de correcciones") | 7 rondas: 4 de auditoría/fix inicial + color por categoría (alcance ampliado a todo el sistema) + unificación de componentes compartidos con Transacciones. Cierre más completo que existe hasta hoy. |
| Categorías | 🟡 Parcial | 2026-07-15 | ✅ (`test/features/categories/.../golden`) | `docs/dev-runs/categorias-feature.md` | Solo se cerraron los 3 bottom sheets de borrado (golden que detecta regresión de píxel, no que valide fidelidad inicial contra el `.pen` — eso seguía pendiente de `ui-ux-reviewer`). El resto de la pantalla (lista, formulario, picker de ícono/color) no tuvo pasada de fidelidad. `docs/bugfixes.md` (2026-07-20) todavía la lista como pendiente (punto 3). Bloqueo abierto: catálogo de íconos diverge 15/32 entre Pencil y código (`bug-fixes-pixel-audit.md`). |
| Presupuestos | ⏳ Agendada | — | ✅ (`test/features/budgets/.../golden`, generados en la corrida de 2026-07-20) | `docs/dev-runs/fidelidad-presupuestos-PROMPT.md` | Prompt de auditoría completo ya redactado (equivalente al de Pagos Programados), listo para pegar en una sesión nueva. Sospecha explícita de deriva amplia — no corrido todavía. El segmento "programado" (HU-12, `docs/dev-runs/budgets-scheduled-progress.md`) no tiene frame en Pencil, así que quedará fuera del alcance de esa auditoría hasta que exista. |
| Transacciones | ❌ Sin auditar | — | ❌ | `docs/dev-runs/transacciones-core.md`, `docs/bugfixes.md` (punto 2) | El dev-run original dice explícitamente que el diseño "no fue auditado contra `billetudo.pen`". La auditoría pixel-a-pixel del 2026-07-19 sí tocó partes (lista/filtros `B3GGa`/`q0CTl`, detalle `Of2sW`, `CategoryPickerChip` reconstruido en la ronda 7 de Pagos Programados) pero no fue una pasada dedicada — sigue en el backlog de `docs/bugfixes.md`. |
| Home / Dashboard | ❌ Sin auditar | — | ❌ | `docs/dev-runs/inicio-home.md`, `docs/bugfixes.md` (punto 8) | Sin mención de fidelidad en el dev-run original ni goldens. Pendiente explícito en `docs/bugfixes.md`. |
| Auth (login/merge/HU-06/HU-07) | 🟡 Parcial | 2026-07-20 | ✅ (`test/features/auth/.../goldens`, 28 generados) | corrida `/design-fidelity-check auth` del 2026-07-20 | **HU-06 (Cerrar sesión) ✅ aprobada sin hallazgos** en sus 6 goldens (los 3 estados × 2 temas fieles a `wlVUL`/`c87DpD`/`dpxOS` y sus oscuros; el header que recorta su mensaje al activar el opt-in quedó verificado). El resto de auth tiene pendientes de fidelidad **preexistentes, ajenos a HU-06**: 1 CRÍTICO (la hoja de datos locales de HU-07 `K8SAG` omite el Icon Header y alinea a la izquierda), 4 IMPORTANTES (label del botón de Google en carga; "Eliminar cuenta" envuelve a 2 líneas; "Reintentar" outlined en vez de primario; "Continuar" deshabilitado gris en vez de violeta 0.4) y 2 MENORES de copy. |
| Configuración (Settings) | ❌ Sin auditar | — | ✅ (`test/features/settings/.../golden`) | — | Hay goldens (incluye el sheet de cerrar sesión) pero ningún dev-run registra una auditoría contra Pencil. |
| Deudas, Metas, Reportes, Captura, Improvement | ⬜️ N/A | — | ❌ | — | Sin implementación en `lib/features/` (solo `.gitkeep`) o sin pantallas propias todavía — no aplica auditoría de fidelidad. |

## Pendientes activos (backlog, `docs/bugfixes.md` al 2026-07-20)

1. Ejecutar pasada de fidelidad en **Transacciones**.
2. Ejecutar pasada de fidelidad en **Categorías**.
3. Ejecutar pasada de fidelidad en **Home/Dashboard**.
4. Correr el prompt ya redactado para **Presupuestos** (`docs/dev-runs/fidelidad-presupuestos-PROMPT.md`).
5. Re-verificar **Cuentas** con `pencil-fidelity-reviewer` tras las correcciones del 2026-07-19 (nunca se cerró formalmente con el gate de fidelidad, solo con la auditoría pixel-a-pixel manual).

## Lecciones ya documentadas para las próximas corridas

Ver `docs/dev-runs/fidelidad-presupuestos-PROMPT.md` (sección "Lecciones de la corrida de Pagos programados") — aplican a cualquier feature nueva que se audite: tandas secuenciales (no paralelas) por compartir `.arb`, re-verificar al final con `pencil-fidelity-reviewer`, preguntar puntualmente contra el `.pen` en vez de que `flutter-dev` adivine, acotar el alcance de cambios transversales, y revisar gaps de cobertura golden tanto como hallazgos.

# Deudas — progreso de refinamiento + diseño (handoff)

> **Estado:** en curso. Requisitos cerrados; diseño Pencil a mitad (2 de ~6 pantallas aprobadas, sin estados ni tema oscuro). **No** existe `pages/deudas.md` todavía (se documenta recién cuando el diseño esté 100% aprobado — ver memoria "aprobar-diseño-antes-de-documentar").
> **Última sesión:** 2026-07-21. **Retomar por:** el form de crear/editar deuda (ver "Lo que falta").
> **Feature NO construida** en `lib/` (`lib/features/debts/` vacío); la tabla `Debts` ya existe.

---

## 1. Decisiones de producto/requisitos — CERRADAS

Ya reflejadas en los requirements (fuente de verdad, no repetir acá):
- **`docs/requirements/08-deudas.md`** — reescrito completo.
- **`docs/requirements/09-pagos-programados.md`** — nota de integración + columna `debtId`.
- **`docs/requirements/10-graficas-informes.md`** — cambió la regla de exclusión (línea de `debtId`).
- **`docs/plan-cuentas-tipos-y-transferencias-presupuestables.md`** — Decisión A-1 reabierta.

Resumen de lo decidido (el detalle vive en esos docs):
- **Costura:** la tarjeta de crédito se queda como **cuenta** (`AccountType.card`, instrumento de gasto). **Todo lo demás que se debe o te deben** —informal (préstamo al primo, gota a gota) y formal/institucional (crédito vehicular, hipoteca)— vive en la **feature Deudas**. Se retiraron los tipos de cuenta `loan`/`mortgage`.
- **Modelo:** la deuda es un **ledger de asientos**; el saldo se **deriva** (apertura + desembolsos + intereses + ajustes − abonos). Dos naturalezas: **caja** (`Transaction` con `debtId`, mueve cuenta) vs **solo-deuda** (interés y ajuste, NO tocan cuenta → tabla nueva `DebtEntries`). El signo lo decide `direction × type`.
- **Estadísticas:** desembolso = ingreso real, cuota = gasto real → afectan **saldos y presupuestos**. Solo el **reporte de flujo** puede separarlos opcionalmente ("movimientos de deuda"). El interés (solo-deuda) no toca caja.
- **Registro de caja opcional por evento** (toggle "¿agregar a una cuenta?"), con default recordado **por deuda** (pref local por `debtId` + fallback global + default "Sí").
- **Cuota** = reúso del motor de **Pagos Programados** (link `debtId`). Configurar en Deudas; confirmar/omitir/posponer en la bandeja de Pagos Programados; cross-link en ambos sentidos (badge en lista/detalle → detalle de la deuda).
- **Interés:** manual ("Actualizar saldo" reconcilia a la cifra del banco) o automático (interés simple diario sobre el saldo, `saldo × tasa/365`, compone). Con **tasa fija + cuota fija se calcula todo** (crecimiento diario, payoff estimado, split interés/capital) — la amortización francesa NO es motor aparte, emerge de simular el mismo modelo. Todo rotulado **"estimado"**. Tasa/cuota variable → Fase 1.
- **Abono ad-hoc vs cuota programada:** cualquier deuda puede tener cuota o no; los abonos sueltos van al historial de la deuda pero no a Pagos Programados.

---

## 2. Diseño en Pencil (`billetudo.pen`) — progreso

### Pantallas APROBADAS (tema claro, sin marcador de revisión)
| Pantalla | nodeId | Notas |
|---|---|---|
| **Lista / resumen** | `rPgbX` | Variante A ("Resumen + lista plana"). Summary card (`u2Xje`, Yo debo/Me deben + chip COP), lista plana de `Debt Card` con pill de dirección, barra de avance, badge de cuota o "Vence …". |
| **Detalle de deuda** | `cUzp6` | Variante C. Hero compacto `E7TQkJ`, meta card (contraparte, vencimiento, "Crece ~$/día · estimado", "Actualizar saldo"), card de próxima cuota (badge "Pago programado", cross-link), **botón "Registrar abono" fijo abajo**, ledger con **saldo corrido por fila**. |

### Componentes reusables creados para Deudas
- `xSpw7` — **Debt Card** (usado por la lista, 5 instancias).
- `JAmxJ` — **Debt Ledger Row · Running** (fila de asiento con saldo corrido, usado por el detalle). Distingue caja (icon-wrap `$primary-soft` + monto `$text-primary` + cuenta) vs solo-deuda (`$muted` + monto atenuado + tag "estimado").

### Decisiones de diseño tomadas (para no re-litigar)
- **Lista:** se eligió variante A sobre B (tabs), C (secciones por dirección) y D (resumen+avance con pill). La A da el doble total de un vistazo + pills + badge de cuota, sin saturar.
- **Detalle:** se eligió variante C sobre A (hero plano) y B (avance radial). C = compacto + acción fija + ledger con saldo corrido.
- **Hero del detalle:** `E7TQkJ` (Compact) sobre `sdd15` — cruzado entre asistente y `ui-ux-reviewer`, coinciden: compacto (deja aire al ledger), % co-protagonista, mejor contraste. `sdd15` borrado.
- **Icono "Actualizar saldo":** `refresh-cw` → **`sliders-horizontal`** (evita el falso "recargar/sincronizar"; iguala el asiento "Saldo actualizado"; no choca con el lápiz de "editar").
- **Tono/accesibilidad:** NO usar `$expense` ni violeta como alarma para "Yo debo"; dirección por texto+ícono+color (no solo color). Avance en `$primary` para ambas direcciones. Fuente `$font-body` (Plus Jakarta Sans), nunca "Inter" literal.

### Fixes de auditoría ya aplicados a la lista (`rPgbX`)
- `fontFamily "Inter"` → `$font-body` en `xSpw7` y la summary card.
- Icon wrap `DTrIU`: `$muted` → `$primary-soft`.
- Card "Le presté a Andrés" (`B1iFTl`) muestra el estado "Vence 30 dic" (demuestra el estado alterno al badge de cuota).

---

## 3. Lo que FALTA (orden sugerido para retomar)

### Diseño (tema claro primero)
1. **Form crear/editar deuda** ← **empezar acá.** Campos: nombre, dirección (Yo debo/Me deben), principal, moneda, contraparte, vencimiento, tasa (`interestRateBps`), modo de interés (manual/auto, `accrualMode`). Reusar `Form Field`, selectores como componentes.
2. **Hoja de registrar abono** — con el toggle "¿agregar a una cuenta?" (HU-02) + selector de cuenta. Reusar `Bottom Sheet Base`, `Account Select Sheet`.
3. **Hoja de actualizar saldo** (reconciliación) — teclea la cifra real → asiento de ajuste solo-deuda. Simple.
4. **Config de cuota** — reusar patrón de Pagos Programados (frecuencia, monto, auto/manual, cuenta).

### Cierre de diseño
5. **Estados** por pantalla: vacío/onboarding, carga (skeleton), error local-first.
6. **Tema oscuro** (al final, componentizando lo repetido). Verificar los contrastes que el reviewer marcó como marginales en oscuro: pill "Me deben" y badge de cuota (lila-sobre-lila).
7. **`pages/deudas.md`** — documentar la spec recién cuando todo lo anterior esté aprobado.

### Implementación (después del diseño)
8. **`/drift-schema-change`:** tabla nueva `DebtEntries` (asientos solo-deuda: kind interestAccrual/manualAdjustment, amountMinor con signo, entryDate) + `Debts.accrualMode` + `ScheduledPayments.debtId` + bump de `schemaVersion` (**coordinar el número**: CLAUDE.md dice 9, `09-pagos` reclama 10→11; secuenciar). Paridad Supabase/PowerSync.
9. **`flutter-dev`** (Clean Architecture: domain/data/presentation) + **`qa-automator`** (unit/widget/golden/Patrol).
10. **`/design-fidelity-check deudas`** al final.

---

## 4. Notas de proceso
- **Pencil.dev estuvo inestable** (el puente MCP se cayó varias veces con timeouts). Regla: si un agente de UI reporta que Pencil no responde, **cortar de inmediato**, no dejarlo terminar a ciegas (memoria "cortar-agente-sin-acceso-pencil"). Para destrabar: reconectar el MCP (`/mcp`), reabrir el `.pen`, o reiniciar Pencil.
- Node IDs clave para retomar: lista `rPgbX`, detalle `cUzp6`, componentes `xSpw7` / `JAmxJ`.

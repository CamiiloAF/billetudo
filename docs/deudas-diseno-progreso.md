# Deudas — progreso de refinamiento + diseño (handoff)

> **Estado:** ✅ **DISEÑO CERRADO** + ✅ **IMPLEMENTADA** (2026-07-22). Diseño en `pages/deudas.md` + `billetudo.pen` (claro+oscuro). Requisitos en `08-deudas.md` (+ `09`, `10`, `plan-cuentas`).
>
> **Implementación (commiteada en `dev`):**
> - **Esquema v14** (`bc6f607`): `DebtEntries` (kinds `interestAccrual`/`manualAdjustment`/`payment`/`disbursement`), `Debts.accrualMode`, `ScheduledPayments.debtId`. Supabase-dev **migrado** (RLS + grants + publicación FOR ALL TABLES); `powersync_schema.dart` (mirror) actualizado.
> - **Domain + data** (`e206c2a`): ledger derivado (`DebtBalanceCalculator`), interés (`DebtInterestCalculator`), 11 casos de uso, repo. Revisado por `finance-code-reviewer` (sólido, sin críticos).
> - **Presentación** (`65046e3`/`4b413b0`/`5808ab2`): lista, detalle, form crear/editar, hoja de abono (Sí/No + **enlazar movimiento existente** vía Movimientos en modo selección), actualizar saldo, config de cuota (reusa el motor de PP), cross-link con Pagos Programados en ambos sentidos.
> - **Fix** (`c405237`): la `Transaction` generada por una cuota hereda `debtId` (la cuota reduce la deuda).
> - **Fidelidad** (`6b1bb08`, `/design-fidelity-check deudas`): fidelidad alta, cero crítico; 1 IMPORTANTE (badge cuota/vence en la lista) corregido. Ver `docs/fidelidad-visual-tracking.md`.
> - **Golden** 40+ (claro/oscuro). **Patrol e2e** 17 escenarios (2 suites) escritos; corrida en emulador `dev` en curso.
>
> **Pendientes conocidos:** (1) **sync rules de PowerSync** (dashboard, lado usuario) — agregar `debt_entries`. (2) **Tema oscuro** de modo enlazar (`g0x859`) y abono con enlace (`olYUm`) en Pencil. (3) **UI de papelera/restaurar** deuda (`RestoreDebt` existe en domain, sin pantalla). (4) Distintivo visual de "deuda saldada" (a validar con diseño). (5) Copy "Eliminar cuota" en la hoja de acciones ⋮ del PP (el link del form ya es consistente).

## ⚠️ RETOMAR MAÑANA — fallas del Patrol e2e (corrida 2026-07-22, emulator-5554: 9/17 pasan)

La primera corrida real en device surfaceó cosas que los unit/widget tests NO atraparon. Ver detalle en `docs/patrol-e2e-tracking.md` (fila Deudas). Orden de ataque sugerido:

1. **[ALTA — probable bug real] El abono desde la hoja no reduce el saldo.** Los 3 flujos de abono vía `DebtPaymentSheet` (`_submitAbono`: con caja, sin caja, "Me deben") fallan el assert del saldo nuevo (`debts_patrol_test.dart:303/216/379`). **Pero "enlazar movimiento existente" SÍ baja el saldo** — misma stream del detalle, distinta ruta de escritura. Sospecha: el submit de `DebtPaymentCubit` (`RegisterDebtCashEvent`/`RegisterDebtLedgerEvent`) no se refleja en el detalle, o el saldo no se recalcula tras cerrar la hoja. Arrastra HU-07 saldada (`:500`) y Ledger completo (`:609`). **Empezar acá** — los unit tests del use case pasan, así que revisar el cableado presentation (cubit del abono → repo → stream del detalle) y si la hoja emite antes de cerrarse. Confirmar si es bug de app o de timing del test.
2. **[cuotas/PP] Chip "Deuda" no aparece en PP tras configurar cuota** (`ScheduledDebtChip`, `:300`) y **deep-link de editar cuota no muestra el nombre de la deuda** (`:412`). El cross-link inverso y la confirmación de ocurrencia SÍ pasan, así que el cableado base funciona — falta el render del chip en la lista de PP y el destino del deep-link de edición. Puede ser `Key`/tipo faltante o bug de integración.
3. **[test, para qa-automator] Finders de scroll ambiguos** en `_scrollUntilVisible` (`:216`): "Too many elements" (abono sin caja) y "No element" (interés auto). El segundo puede ser que la estimación de interés no se renderice — verificar.

Todo lo demás de Deudas quedó commiteado y verde en la suite unit/widget/golden. El emulador se cerró al terminar la corrida.

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

### Pantallas EN REVISIÓN del usuario (tema claro, con marcador — falta aprobación explícita)
| Pantalla | nodeId | Notas |
|---|---|---|
| **Form crear/editar deuda** | `dUryC` | Variante B ("Monto héroe"). Saldo de apertura como héroe ~38px/800 + caret de edición, pill de moneda `$primary-on-soft-strong`, toggle de dirección `qCUup` con label "¿Debes o te deben?", contraparte/vencimiento/tasa+modo interés. CTA "Crear deuda" fijo abajo. Fixes de auditoría ya aplicados. |
| **Hoja de registrar abono** | `xbsY3` (Sí) / `V6Z9ln` (No) | Variante A ("Switch + revelación inline"), HU-02. Héroe de monto + caret. Toggle switch "¿Agregar a una cuenta?": **Sí** revela fila de cuenta (`X3tZG`) + afecta estadísticas; **No** oculta cuenta y muestra copy "no moverá ninguna cuenta". Categoría **solo en Sí** (en No no hay dónde persistir `categoryId` — no es `Transaction`). Fixes de auditoría aplicados (knob OFF con sombra iOS, hints unificados 13px). Switch componentizado → `bWezV` (`reusable:true`). |

### Componentes reusables creados para Deudas
- `xSpw7` — **Debt Card** (usado por la lista, 5 instancias).
- `JAmxJ` — **Debt Ledger Row · Running** (fila de asiento con saldo corrido, usado por el detalle). Distingue caja (icon-wrap `$primary-soft` + monto `$text-primary` + cuenta) vs solo-deuda (`$muted` + monto atenuado + tag "estimado").
- `qCUup` — **Debt Direction Toggle** (Yo debo / Me deben; texto+ícono direccional+forma, sin color de alarma). Usado por el form.
- `bWezV` — **Switch** (`reusable:true`, ON/OFF por override; knob con stroke `$border` + sombra iOS para contraste en OFF). Usado por la hoja de abono; reusable en ajustes.
- `s9gXs` — **Page Header · Con subtítulo** (`reusable:true`, título + subtítulo de contexto). Creado para el header de config de cuota; se creó aparte (no como slot en `Dtm0X`) por la regla de no reestructurar componentes con overrides — ver `MASTER.md`.
- ~~`eYSlI` (Cadence Selector)~~ — BORRADO: era un duplicado incorrecto de las Freq Chips del PP form. La config de cuota reusa el form real de Pagos Programados, no un selector propio.

### Regla del sistema: monto-héroe (criterio de 3 condiciones) — DECIDIDA
Al diseñar el form de crear/editar deuda se eligió la variante **B** (monto de apertura elevado a **héroe** centrado grande, ~38px/800, igual que el form de transacción). Eso abrió la pregunta de si "form cuyo dato central es un monto → héroe" debe ser regla global. Se probó aplicando el mismo héroe al form de **Presupuesto** (preview `evhnj`, ya borrado) y **empeoró** el UX. Conclusión, auditada por `ui-ux-reviewer`:

> **El monto sube a héroe SOLO si se cumplen las tres condiciones:**
> - **(a) Único** — es el único dato definitorio, no co-central con un alcance/scope.
> - **(b) Sujeto** — es lo que el usuario *vino a registrar*, no un parámetro de configuración entre varios.
> - **(c) Corto** — el form es corto, así el héroe no obliga a comprimir el resto.
>
> Si el monto compite con un alcance o es un parámetro entre varios → **Form Field enfatizado (~22px/800)**, no héroe.

| Form | (a) único | (b) sujeto | (c) corto | Héroe |
|---|---|---|---|---|
| Transacción | ✓ | ✓ | ✓ | Sí |
| **Deuda** | ✓ | ✓ | ✓ | **Sí (variante B)** |
| Presupuesto | ✗ (compite con alcance) | ✗ (es config) | ✗ (denso) | No — se queda como `a3gGPM`, monto 22px/800 |
| **Meta** | probable ✓ | probable ✓ | probable ✓ | **← EVALUAR contra las 3 condiciones al diseñar Meta** |

**NO se comprometió como regla global** (a pedido del usuario: "solo toquemos deuda"). El criterio se documenta acá para **revisarlo en Meta** cuando le toque su turno de diseño. La redacción final va a `pages/deudas.md` + nota en `MASTER.md` recién cuando el diseño de Deudas esté aprobado (ver memoria "aprobar-diseño-antes-de-documentar").

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

### Diseño (tema claro primero) — ✅ HAPPY PATH COMPLETO
1. ~~**Form crear/editar deuda**~~ ✅ APROBADO (variante B `dUryC`).
2. ~~**Hoja de registrar abono**~~ ✅ APROBADO (variante A, estados Sí `xbsY3` / No `V6Z9ln`).
3. ~~**Hoja de actualizar saldo**~~ ✅ HECHO (reconciliación `DEWMf`, reviewer la marcó lista; en revisión del usuario). Héroe de monto + tarjeta de reconciliación (saldo estimado vs. ajuste) + "no mueve ninguna cuenta". Asiento de ajuste solo-deuda.
4. ~~**Config de cuota**~~ ✅ HECHO (`P1kiP`, en revisión del usuario). **Clon del form real de Pagos Programados** (`J0DSIm`, "PP Form V3 — Resumen natural"), NO una pantalla inventada: reusa sus componentes tal cual (Freq Chips inline Único/Día/Semana/Mes/Año, Interval Stepper, Modo Block radio auto/manual, `ofg07` Zona Fija de monto abajo, `EIoVx` categoría chips, `wOlOA` fields). **Adaptaciones de deuda:** (a) segmented de tipo OCULTO — el tipo se deriva de `Debt.direction` (Yo debo→expense, Me deben→income); (b) banner cross-link "se crea un pago programado enlazado a esta deuda"; (c) header con subtítulo "Crédito vehicular · Yo debo" vía componente nuevo `s9gXs`.
   - **Decisión de modelo (cerrada):** **cuota = pago programado** (opcional por deuda). Configurar cuota SIEMPRE crea un `ScheduledPayment`; la proyección de payoff (HU-06) lee la cuota de ahí. NO se soporta "cuota solo informativa sin pago programado" (pagar sin agendar = abono ad-hoc, otra hoja). Default Auto = coincide con `requiresConfirmation=false` del motor.
   - **Lección aplicada:** el primer intento (`UMk8F`) inventó componentes (`eYSlI` "Cadence Selector" con "Quincenal" inexistente, monto como field, segmented auto/manual) en vez de reusar el form real → BORRADO. Regla: la config de cuota debe ser IGUAL al form de Pagos Programados.

**Estados de ajuste inverso pendiente:** en actualizar saldo, cuando el saldo real es MAYOR → ajuste "+$X" (la deuda sube); renderizar también en `$text-primary` neutral, nunca `$expense`. Va en la fase de estados.

### Cross-link PP → Deuda (definido, NO diseñado) — pendiente
Definido en `08-deudas.md` HU-03 y `09-pagos-programados.md` línea 111, pero **falta en las pantallas de Pagos Programados** (viven fuera del cluster de Deudas):
- **Detalle del PP** (`OY2Kj` "Híbrido A+C" y las demás variantes de "PP Detalle"): añadir un **card de deuda enlazada** ("Cuota de: Crédito vehicular") que al tocarlo navega al detalle de la deuda (`cUzp6`). Hoy el contenido es Identity Strip → Próximo Pago Hero → Ficha Card → Historial, sin card de deuda.
- **Lista de PP + tarjeta** (`tit0W` Scheduled Card): añadir un **badge/banner** que identifique que ese pago corresponde a una deuda.
- Editar la plantilla de una cuota debe **deep-linkear de vuelta a la deuda** (su hogar), no editarse como plantilla suelta.
- Solo cuando el detalle del PP tiene `debtId`. Reusar componentes existentes; tocar las pantallas de PP con cuidado (muchas variantes claro/oscuro). Hacer como paso aparte de los estados de Deudas.

### Cierre de diseño — ✅ COMPLETO
5. ~~**Estados**~~ ✅ HECHO (lista vacío/carga/error, detalle carga/error).
6. ~~**Tema oscuro**~~ ✅ HECHO (14 frames, contrastes marginales verificados y pasan; auditado por `ui-ux-reviewer`).
7. ~~**`pages/deudas.md`**~~ ✅ ESCRITO (spec completa con todos los nodeIds claro/oscuro, componentes, decisiones y notas de implementación).

**Fixes de sistema aplicados de paso:** texto de error del `Form Field` → `$expense-text` (afectaba todas las features, ver `MASTER.md`). **Tracked como tema de sistema (no bloquea):** contraste de la barra de avance en oscuro (~2.75:1, sistémico en todas las features — nota en `MASTER.md`).

### Implementación (después del diseño)
8. **`/drift-schema-change`:** tabla nueva `DebtEntries` (asientos solo-deuda: kind interestAccrual/manualAdjustment, amountMinor con signo, entryDate) + `Debts.accrualMode` + `ScheduledPayments.debtId` + bump de `schemaVersion` (**coordinar el número**: CLAUDE.md dice 9, `09-pagos` reclama 10→11; secuenciar). Paridad Supabase/PowerSync.
9. **`flutter-dev`** (Clean Architecture: domain/data/presentation) + **`qa-automator`** (unit/widget/golden/Patrol).
10. **`/design-fidelity-check deudas`** al final.

---

## 4. Notas de proceso
- **Pencil.dev estuvo inestable** (el puente MCP se cayó varias veces con timeouts). Regla: si un agente de UI reporta que Pencil no responde, **cortar de inmediato**, no dejarlo terminar a ciegas (memoria "cortar-agente-sin-acceso-pencil"). Para destrabar: reconectar el MCP (`/mcp`), reabrir el `.pen`, o reiniciar Pencil.
- Node IDs clave para retomar: lista `rPgbX`, detalle `cUzp6`, componentes `xSpw7` / `JAmxJ`.

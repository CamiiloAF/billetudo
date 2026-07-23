# Pagina: Deudas

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras varias rondas de auditoria adversarial con `ui-ux-reviewer` y correccion con `pencil-designer`. Requisitos en `docs/requirements/08-deudas.md`. Cross-link con Pagos Programados: ver `09-pagos-programados.md`.

## Frames

Todas las piezas existen en tema Claro y en su copia Oscuro (`Copy()+theme:{mode:"dark"}`, mismo contenido/estructura, solo recolorea).

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) |
|---|---|---|
| Lista / resumen — con datos | `rPgbX` | `fXBWg` |
| Lista — vacio / onboarding | `qfpUI` | `DK17R` |
| Lista — carga (skeleton) | `hp9rU` | `F3cM6k` |
| Lista — error (local-first) | `d64hv` | `m0YsRp` |
| Detalle de deuda | `cUzp6` | `ruler` |
| Detalle — carga (skeleton) | `ZQIPe` | `wstnU` |
| Detalle — error (local-first) | `tVUoU` | `wvoMB` |
| Form crear/editar deuda | `dUryC` | `q5T1Kc` |
| Hoja registrar abono — toggle Si | `xbsY3` | `TOlMJ` |
| Hoja registrar abono — toggle No | `V6Z9ln` | `qfZiZ` |
| Hoja actualizar saldo (reconciliacion) | `DEWMf` | `NBuGV` |
| Config de cuota | `P1kiP` | `fn49Q` |
| Hoja registrar abono — con enlace "Enlazar un movimiento" | `olYUm` | _(oscuro pendiente)_ |
| Movimientos · modo enlazar (banner + tap=enlazar) | `g0x859` | _(oscuro pendiente)_ |
| **Cross-link:** PP Detalle con card de deuda | `nDmnf` | `Y5D7c` |
| **Cross-link:** Scheduled Card con badge "Deuda" (demo) | `F3srst` | `Jlosw` |

**Estados/piezas sin frame propio en el `.pen` (por diseño o reusables genéricos):**
- **Detalle sin cuota** (`DebtConfigureInstallmentCard`): no tiene frame — solo se diseñó el estado *con* cuota (`cUzp6`). El widget reusa la geometría de la card de cuota. Gap de cobertura conocido, no deriva.
- **Detalle saldada** (100% pagado, $0): variación de dato de `cUzp6` (barra llena), sin frame dedicado.
- **Sheet confirmar borrado** de deuda: reusa el patrón destructivo del sistema (icono `trash-2` rojo + Cancelar/Eliminar), sin frame propio en `deudas.md`.
- **Pickers de cuenta y moneda** de las hojas: reusan `Account Select Sheet`/`Currency Row` genéricos.
- **Modo enlazar / abono con enlace** (`g0x859`/`olYUm`): diseñados en claro; falta generar su copia oscura.

**Navegacion:** la Lista y el Detalle usan `Page Header` (boton atras) SIN `Tab Bar` — Deudas es una subseccion apilada. Las hojas (abono, actualizar saldo) son bottom sheets (`Bottom Sheet Base`). El Form y la Config de cuota son pantallas apiladas con `Page Header`.

**Organizacion del canvas:** zona CLARA de Deudas arriba, zona OSCURA muy por debajo y separada (regla "canvas-hygiene": el oscuro se genera solo cuando el claro esta 100% aprobado, nunca en paralelo; oscuras abajo separadas de las claras). Los frames del cross-link viven junto al cluster de PP Detalle en claro; su oscuro se agrupo con la fila oscura de Deudas para auditarlos juntos.

## Componentes creados para Deudas

- **`xSpw7` — Debt Card** (usado por la lista): icon-wrap `$primary-soft`, nombre, pill de direccion, barra de avance en `$primary` (ambas direcciones), badge de cuota o "Vence …".
- **`JAmxJ` — Debt Ledger Row · Running** (usado por el detalle): fila de asiento con saldo corrido. Distingue **caja** (icon-wrap `$primary-soft` + monto `$text-primary` + cuenta) de **solo-deuda** (`$muted` + monto atenuado `$text-secondary` + tag "estimado").
- **`qCUup` — Debt Direction Toggle** (`reusable:true`): Yo debo / Me deben. Direccion por **texto + icono direccional (`arrow-up-right`/`arrow-down-left`) + forma seleccionada**, NUNCA solo color; sin `$expense` ni violeta de alarma. Segmentos con tap target 44px.
- **`bWezV` — Switch** (`reusable:true`, ON/OFF por override): knob con `stroke $border` + sombra iOS para separarlo del track (contraste del knob OFF). Usado por la hoja de abono; reusable en ajustes.
- **`s9gXs` — Page Header · Con subtitulo** (`reusable:true`): titulo + subtitulo de contexto (`$text-secondary` 13/500, centrado). Usado por la Config de cuota ("Configurar cuota" + "Credito vehicular · Yo debo"). Creado APARTE de `Dtm0X` (no como slot opcional) por la regla de no reestructurar componentes con overrides — ver MASTER.
- **`J2icQQ` — Debt Card Skeleton** y **`Sp8IY` — Debt Ledger Skeleton Row**: skeletons en `$skeleton` con la geometria real de `xSpw7`/`JAmxJ`.

## Regla de sistema: monto-heroe (3 condiciones)

El **monto se eleva a heroe** (centrado grande ~38px/800, `$text-primary`, con caret de edicion) SOLO cuando se cumplen las tres:
- **(a) Unico** — es el unico dato definitorio, no compite con un alcance/scope.
- **(b) Sujeto** — es lo que el usuario vino a registrar, no un parametro de configuracion entre varios.
- **(c) Corto** — el form es corto, el heroe no obliga a comprimir el resto.

Si compite con un alcance o es un parametro entre varios → **Form Field enfatizado (~22px/800)**, no heroe.

| Pantalla | Heroe |
|---|---|
| Form crear deuda (saldo de apertura) | **Si** |
| Hoja de abono (monto del abono) | **Si** |
| Hoja actualizar saldo (nuevo saldo) | **Si** |
| Config de cuota (monto de cuota) | **No** — clona el form de Pagos Programados (`ofg07` Zona Fija) |

(Se probo el heroe en el form de Presupuesto y empeoro: el monto compite con el alcance. La regla tambien aplicaria a Meta — evaluar al diseñarla. Cuenta se queda plana: manda la identidad, no el saldo.)

## Lista / resumen (`rPgbX`)

Variante A ("Resumen + lista plana"). `Page Header` "Deudas" + `+`. **Summary card** (`u2Xje`): "Yo debo" (neutral) vs "Me deben" (`$income-text` verde) segmentado por moneda (chip COP) — multi-moneda Fase 0 no normaliza. Lista plana de `Debt Card` con pill de direccion, barra de avance, y badge de cuota ("Cuota · 5 ago") o estado "Vence 30 dic".

### Estados
- **Vacio** (`qfpUI`): `Empty State` (icono `hand-coins`, "Aun no tienes deudas registradas" + subtitulo de progreso + CTA "Agregar deuda"). Tono positivo, nunca punitivo.
- **Carga** (`hp9rU`): skeleton de la summary card + 4× `Debt Card Skeleton`, anchos variados.
- **Error** (`d64hv`): `Error State`, "No pudimos cargar tus deudas" + recordatorio local-first ("Tus datos siguen guardados en tu dispositivo") + Reintentar. Icono neutral, no alarmista.

## Detalle de deuda (`cUzp6`)

Variante C. **Hero Compact** (`E7TQkJ`): pill direccion + chip moneda, saldo pendiente grande, % pagado co-protagonista, barra de avance. **Meta card**: contraparte, vencimiento, "Crece ~$X/dia · estimado", y fila "Actualizar saldo" (icono **`sliders-horizontal`**, no `refresh-cw` — evita el falso "recargar/sincronizar"). **Card de proxima cuota** (badge "Pago programado", cross-link al flujo de confirmacion). **Boton "Registrar abono" fijo abajo**. **Ledger** con `Debt Ledger Row · Running` (saldo corrido por fila).

### Estados
- **Carga** (`ZQIPe`): skeleton del hero + meta card + cuota card + `Debt Ledger Skeleton Row` + skeleton del CTA.
- **Error** (`tVUoU`): `Error State` con el header del detalle. (No hay "ledger vacio": una deuda siempre tiene al menos el asiento de apertura.)

## Form crear/editar deuda (`dUryC`)

Variante B ("Monto heroe"). Saldo de apertura como **heroe** + caret + pill de moneda (`$primary-on-soft-strong` para contraste). Toggle de direccion `qCUup` con label "¿Debes o te deben?". Nombre, contraparte, vencimiento, tasa de interes (%), y modo de interes (Manual/Automatico, `hFu41`) revelado. CTA "Crear deuda" fijo abajo (zona del pulgar; se prefirio sobre el check en el header).

## Hoja registrar abono (`xbsY3` Si / `V6Z9ln` No)

Variante A ("Switch + revelacion inline"), HU-02. Heroe de monto + caret. Toggle **switch** `bWezV` "¿Agregar a una cuenta?":
- **Si** (`xbsY3`): revela la fila de cuenta (`Filter Account Row` con saldo) + hint "Movera el saldo y contara en tus estadisticas". Crea una `Transaction` con `debtId`. Categoria visible.
- **No** (`V6Z9ln`): la fila de cuenta **se remueve del layout** (no se atenua) + copy "Este abono baja el saldo de la deuda pero no movera ninguna cuenta". **Categoria OCULTA** — en No el evento no es una `Transaction`, `categoryId` no tiene donde vivir y contradiria el copy.
- Hints de consecuencia identicos en ambos estados (13px, `$text-secondary`, sin icono). Fecha + Nota visibles en ambos.

## Hoja actualizar saldo (`DEWMf`)

Reconciliacion (HU-06). Heroe de monto ("Nuevo saldo") + caret. **Tarjeta de reconciliacion**: "Saldo estimado hoy" vs "Ajuste que se registra" (ej. "−$180.000", en `$text-primary` **neutral, nunca `$expense`** — aplica tambien al ajuste inverso "+$X" cuando el saldo real es mayor). Tira `$primary-soft` "No mueve ninguna cuenta". Sin toggle de cuenta (nunca toca caja). Registra un asiento de ajuste solo-deuda (`DebtEntries`).

## Config de cuota (`P1kiP`)

**Clon del form real de Pagos Programados** (`J0DSIm`, "PP Form V3 — Resumen natural"), NO una pantalla inventada. Reusa sus componentes tal cual: **Freq Chips inline** (Unico/Dia/Semana/Mes/Año = `ScheduleFrequency`), Interval Stepper ("Repetir cada"), Modo Block radio (Automatico/Manual), `ofg07` Zona Fija de monto abajo, `EIoVx` categoria chips, `wOlOA` fields.

**Adaptaciones de deuda** (solo estas, el resto identico al PP form):
1. **Segmented de tipo OCULTO** — el `EntryType` se deriva de `Debt.direction` (Yo debo → expense, Me deben → income), el usuario no lo elige.
2. **Banner cross-link** (`$primary-soft`, icono `calendar-clock`): "Se crea un pago programado enlazado a esta deuda. Confirmalo o pospónlo en Pagos programados."
3. **Header con subtitulo** (`s9gXs`): "Configurar cuota" + "Credito vehicular · Yo debo".

**Decision de modelo (cerrada): cuota = pago programado** (opcional por deuda). Configurar cuota SIEMPRE crea un `ScheduledPayment`; la proyeccion de payoff (HU-06) lee la cuota de ahi. NO se soporta "cuota solo informativa sin pago programado" (pagar sin agendar = abono ad-hoc, otra hoja). Default Automatico = coincide con `requiresConfirmation=false` del motor (`09-pagos-programados.md`).

## Cross-link Pago Programado → Deuda

Definido en `08-deudas.md` HU-03 y `09-pagos-programados.md` linea 111. Diseñado como adicion a las pantallas de Pagos Programados (aplica solo cuando el `ScheduledPayment` tiene `debtId`):

- **Detalle del PP** (`nDmnf`, variante nueva del canonico `OY2Kj`): **card "Deuda Enlazada"** (`M7Ijh`) entre la Ficha Card y el Historial — icono `landmark` (`$primary-on-soft-strong`) + "Cuota de / Credito vehicular · Yo debo" + `chevron-right` → navega al detalle de la deuda. Mismo chrome que la Ficha Card. El detalle **scrollea** (tiene "Ver historial completo (N)" que expande in-place), asi que el card se agrega sin recortar contenido: el excedente queda bajo el fold. El canonico `OY2Kj` (PP sin deuda) queda intacto.
- **Lista / Scheduled Card** (`tit0W`): nodo opcional **`Y5FQT` "Deuda Chip"** (`enabled:false` por default) apendido a la fila de chips, sin reestructurar el componente (regla de overrides). Badge sutil `$primary-soft` + icono `landmark` + "Deuda" (`$primary-on-soft-strong`). Demo en contexto: `F3srst`.
- Editar la plantilla de una cuota debe **deep-linkear de vuelta a la deuda** (su hogar), no editarse como plantilla suelta (comportamiento, no pantalla).

## Notas de implementacion (para flutter-dev)

- **Caret del heroe de monto** = convencion de mockup para "editable"; en Flutter la editabilidad real es el teclado/keypad al enfocar.
- **Tap target del switch** = fila completa, no solo el pill de 48×28.
- **Fila de chips de la Scheduled Card** (Freq Chip + Deuda Chip + fecha): en Flutter con `Expanded`/`ellipsis` para textos largos.
- **Tipo del `ScheduledPayment`** de una cuota se deriva de `Debt.direction`, no se expone como control.
- **Contraste de la barra de avance en oscuro** (~2.75:1) es un tema sistemico pendiente, no de Deudas — ver MASTER.

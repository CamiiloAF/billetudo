# Pagina: Deudas

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** aprobado y terminado (claro + oscuro), tras varias rondas de auditoria adversarial con `ui-ux-reviewer` y correccion con `pencil-designer`. Incluye la extension de cierre/completar deuda (menu overflow, sheet de acciones, cierre manual, felicitacion al 100%, tab "Cerradas") aprobada 2026-07-24. Requisitos en `docs/requirements/fase-1/08-deudas.md` HU-02/HU-07. Cross-link con Pagos Programados: ver `09-pagos-programados.md`.

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
| Form crear/editar deuda (Yo debo) | `dUryC` | `qEkJE` |
| Form crear deuda — variante "Me deben" | `B36jV` | `pn5Qx` |
| Sheet "registro inicial" post-crear | `EXQfv` | `gcOj9` |
| Hoja confirmar actualizar registro (2b) | `hLe9z` | `G9qHX` |
| Hoja registrar abono — toggle Si | `xbsY3` | `TOlMJ` |
| Hoja registrar abono — toggle No | `V6Z9ln` | `qfZiZ` |
| Hoja actualizar saldo (reconciliacion) | `DEWMf` | `NBuGV` |
| Config de cuota | `P1kiP` | `fn49Q` |
| Hoja registrar abono — con enlace "Enlazar un movimiento" | `olYUm` | `Q95HyJ` |
| Movimientos · modo enlazar (banner + tap=enlazar) | `g0x859` | `V4OiMq` |
| **Cross-link:** PP Detalle con card de deuda | `nDmnf` | `Y5D7c` |
| **Cross-link:** Scheduled Card con badge "Deuda" (demo) | `F3srst` | `Jlosw` |
| Detalle — entry point cierre (menu overflow) | `Tt2e7` | `ulorV` |
| Sheet Acciones de la deuda (Editar/Cerrar/Eliminar) | `g57hEW` | `TjCfr` |
| Sheet Confirmar cierre manual | `R97gF` | `WLz5x` |
| Sheet Felicitacion al 100% | `C28Zt` | `h0zie` |
| Lista — tab Activas/Cerradas, viendo Cerradas | `vaNHd` | `nusfh` |
| Sheet Movimiento — Editar (ledger sin cuenta) | `v4RJC` | `L5KbhU` |
| Sheet Movimiento — Interés | `ldTrt` | `hVah4` |

**Estados/piezas sin frame propio en el `.pen` (por diseño o reusables genéricos):**
- **Detalle sin cuota** (`DebtConfigureInstallmentCard`): no tiene frame — solo se diseñó el estado *con* cuota (`cUzp6`). El widget reusa la geometría de la card de cuota. Gap de cobertura conocido, no deriva.
- **Detalle saldada** (100% pagado, $0): variación de dato de `cUzp6` (barra llena), sin frame dedicado.
- **Sheet confirmar borrado** de deuda: reusa el patrón destructivo del sistema (icono `trash-2` rojo + Cancelar/Eliminar), sin frame propio en `deudas.md`.
- **Pickers de cuenta y moneda** de las hojas: reusan `Account Select Sheet`/`Currency Row` genéricos.
- **Modo enlazar / abono con enlace** (`g0x859`/`olYUm`): banner del modo enlazar dice **"Enlazar a Crédito vehicular"** (sin "· Yo debo", que confundía) + cuerpo **"Elige un movimiento que ya registraste; lo atribuimos a esta deuda, no creamos uno nuevo."** (imperativo, era "Elegí"). Tema oscuro en generación (`V4OiMq`/`Q95HyJ`, sincronizados con este copy).

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

**"Ver más" del ledger** (sincronizado 2026-07-29, ambos temas, claro `cUzp6` / oscuro `ruler`): el ledger ya no se muestra completo sin paginación. Debajo de `Ledger List` (`FKoQC`) se instancia el componente reusable **`Load More · Ver más`** (`oadHE`, master vive dentro de `NloPT` en Presupuestos — mismo patrón de higiene de canvas que `s09qcC`): pill `$muted`, label "Ver más" + `chevron-down`, ambos `$primary-on-soft-strong`. Mismo componente que usan Presupuestos/Pagos Programados/Metas — unificación de paginación de ledgers en las 4 features (8 iniciales + 8 por carga; ver `docs/dev-runs/` de la corrida de código correspondiente). El mockup solo dibuja 3 filas de ejemplo antes del botón (se quitó la fila "Ajuste" del dato de muestra para que cupiera en el viewport de 972px) — el conteo real lo controla el código, no el `.pen`.

**Reconciliación de los montos de muestra (corregido 2026-07-29):** al quitar la fila "Ajuste" en la corrida anterior, el saldo corrido saltaba de $42.000.000 (apertura) a $29.500.000 (tras el interés) sin ninguna fila que explicara la baja de ~$12.860.000 — se leía como un movimiento fantasma. Los 3 montos de muestra ahora reconcilian matemáticamente entre sí en orden cronológico: apertura +$42.000.000 (saldo $42.000.000) → interés +$360.000 (saldo $42.360.000) → abono −$13.860.000 (saldo $28.500.000), coincidiendo con el "Saldo pendiente" del hero ($28.500.000 de $42.000.000, 32% pagado). Aplicado en ambos temas (`cUzp6`/`ruler`).

## Form crear/editar deuda (`dUryC` Yo debo / `B36jV` Me deben)

Variante B ("Monto heroe"). Saldo de apertura como **heroe** + caret + pill de moneda (`$primary-on-soft-strong` para contraste). Toggle de direccion `qCUup`. Campos: **"Nombre de la deuda"**, contraparte con **label direccional** ("Yo debo" → **"Le debo a"**; "Me deben" → **"Me debe"** — variante `B36jV`), y **DOS campos de fecha**:
- **"Fecha"** (fecha inicial: cuándo empezó la deuda) — **requerida, default "Hoy", sin "×"** (no admite "Sin fecha"). Semánticamente **≤ hoy, nunca futuro** (validacion de codigo). Es el **piso** de las fechas de abonos/ajustes (nada anterior a esta fecha) y la fecha del registro inicial. Filas: `UiDmq` (`dUryC`) / `RqP11` (`B36jV`).
- **"Fecha de vencimiento"** (cuándo se debe pagar) — **opcional, con "×" para limpiar** (placeholder "Sin fecha"), **puede ser futura**. (Antes se llamaba solo "Vencimiento".)

Luego tasa de interes (%) y modo de interes (Manual/Automatico, `hFu41`) revelado. CTA "Crear deuda" fijo abajo (zona del pulgar).

**El form NO lleva toggle de caja inline.** La decision de registrar el saldo de apertura en una cuenta (item 2, "registro inicial") NO vive en el form: se pregunta en un **sheet post-crear** al pulsar "Crear deuda" (ver abajo). Esto se decidio asi para no saturar el form.

## Sheet "registro inicial" post-crear (`EXQfv`)

Al pulsar **"Crear deuda"** se levanta este sheet (`PqTUt` Bottom Sheet Base + `XPjIZ` Sheet Icon Header con icono `wallet`):
- Titulo **"¿Quieres crear un registro inicial para esta deuda?"**, cuerpo **"Si lo creas, cambiara el saldo de la cuenta que elijas."** (copy **direccional-agnostico** → un solo sheet, no dos variantes).
- Acciones: **"No, solo la deuda"** (secundario) crea la deuda sin mover cuentas; **"Si, elegir cuenta"** (primario) abre el **selector de cuentas existente** (`fcVZN` Account Select Sheet) para elegir a que cuenta se atribuye el registro.
- Comportamiento (direccional en codigo, no en copy): el registro mueve la cuenta por el saldo de apertura — **ingreso** si "Yo debo" (recibiste el dinero), **egreso** si "Me deben" (prestaste el dinero). El modelo de datos que evita el doble-conteo del saldo de la deuda lo define el plan de implementacion (architect) — ver `docs/fixes/improvements_debts.md` item 2.

## Sheet confirmar actualizar registro (`hLe9z`)

Item 2b. Al **editar** una deuda que ya tiene un registro inicial enlazado y cambiar el saldo de apertura, se levanta esta hoja de confirmacion (`PqTUt` + `Ot4yI` Sheet Buttons Row): titulo **"¿Actualizar tambien el registro?"**, mensaje con los montos ("... de $X a $Y"), acciones Cancelar / Actualizar. Tono informativo, no punitivo.

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

## Cierre / completar deuda (extension, aprobada 2026-07-24)

Cubre HU-02 (felicitacion al saldar) y HU-07 (cierre manual con saldo pendiente). Todas las piezas en Claro; Oscuro generado por `Copy()+theme:{mode:"dark"}` tras aprobacion explicita, sin ajustes manuales de color.

### Entry point: menu overflow (`Tt2e7`/`pWKji`)

El acceso a cerrar/eliminar una deuda vive en el **menu overflow (⋮)** del header del Detalle, **NO** en un boton de accion visible permanentemente. Usa el patron "Menu Button" ya establecido en ~20 instancias del resto de la app (fondo `$muted`, icono `$text-primary`, `ellipsis-vertical`) — deliberadamente **no** el `Action Button` violeta solido que usa el FAB de otras pantallas, para no sugerir que cerrar/eliminar es la accion primaria de la pantalla (esa sigue siendo "Registrar abono").

Al pulsar, abre **`g57hEW`** — Sheet Acciones de la deuda, 3 filas `Menu Row` (`hIbs3` instanciado):
- **Editar deuda** (icono `pencil`, neutral) → Form crear/editar deuda.
- **Cerrar deuda** (icono `flag`, neutral) → abre `R97gF`.
- **Eliminar deuda** (icono `trash-2`, `$expense-text`/`$expense-soft`, **sin chevron**) → reusa el patron destructivo del sistema.

### Sheet confirmar cierre manual (`R97gF`)

Bottom Sheet Base (`PqTUt`) con `Sheet Icon Header` (icono `flag`, neutral) + Info Card (`$primary-soft`, saldo pendiente en `$primary-on-soft-strong` — NO `$primary-on-soft`, falla AA a 12px/600) + `Sheet Buttons Row` (Cancelar / Cerrar deuda).

Copy final: **"¿Cerrar esta deuda?"** / **"Le debes {monto} a {contraparte}. Al cerrarla, dejará de aparecer en tus deudas activas y no te seguirá recordando pagarla."**

**Decision de producto explicita: cerrar una deuda manualmente con saldo pendiente NO genera ningun asiento contable.** No se crea un `DebtEntry` de condonacion/ajuste — el saldo residual simplemente se congela, la deuda cambia de estado/visibilidad (pasa a la lista de Cerradas), nada mas se mueve. El % mostrado en el historial de esa deuda queda congelado al momento del cierre. Para dominio: esto sugiere un campo tipo `closedAt`/`archivedAt` en la entidad `Debt` (no un evento de `DebtEntries`); la query de lista filtra Activas/Cerradas por ese campo.

CTA "Cerrar deuda" en **violeta** (`Button/Primary`), no destructivo — cerrar una deuda no es lo mismo que eliminarla; el copy y el color comunican una accion neutral/de progreso, coherente con el tono de marca.

### Sheet Felicitacion al 100% (`C28Zt`)

Se dispara cuando el saldo pendiente de una deuda llega a 0 o menos (ver HU-02/HU-07 en `docs/requirements/fase-1/08-deudas.md`), tipicamente tras registrar un abono que salda el total. Bottom Sheet Base con `Sheet Icon Header` (icono `party-popper`, icon-wrap 72px violeta) + fila de 2 stats (`$primary-soft` + texto `$primary-on-soft-strong`, no `$primary-on-soft` — a este tamaño no alcanza 4.5:1) + `Sheet Buttons Row`.

Copy diseñado en el `.pen` para direccion `iOwe`: **"¡Felicidades! Ya no debes nada"** / **"Terminaste de pagar {nombre}. En total pagaste {monto} en {duración}."** Stats: "Total pagado" y "Duración". **Para direccion `owedToMe` el copy cambia de verbo** (misma pieza visual, texto por l10n segun direccion): "Terminaste de cobrar {nombre}. En total cobraste {monto} en {duración}." — no se disena una segunda variante visual, solo el string cambia por parametro de direccion (a resolver en `flutter-dev` via l10n, no en Pencil).

Botones: **"Ahora no"** (dismiss, secundario) / **"Completar"** (primario, icono `check`) — archiva la deuda ahi mismo, sin navegacion adicional ni pantalla de confirmacion extra.

### Tab "Activas"/"Cerradas" en la Lista (`vaNHd`)

Reusa **`qCUup`** (Debt Direction Toggle) relabeleado como segmented control generico de 2 opciones ("Activas"/"Cerradas") en vez de direccion de deuda — mismo componente, contenido distinto por override. **Reemplaza al `Section Header`** que tenia la lista de activas (se borro, no se dejo deshabilitado/oculto).

**Summary card** (`v49eY6`) cambia sus labels a tiempo pasado: **"Pagué"** / **"Me pagaron"**, con valores recalculados sobre el conjunto de deudas cerradas — **no reusa los totales de la vista Activas**. Tratamiento de color con **asimetria intencional** (decision explicita del usuario, no "corregir" sin preguntar):
- **"Pagué"**: neutro, `$text-secondary`.
- **"Me pagaron"**: se mantiene en verde vivo, `$income-text`.

**Debt Card en estado cerrado**: pill de direccion **neutro** (`$muted`/`$text-primary`, labels en pasado — "Debía"/"Me debían" en vez de "Yo debo"/"Me deben"). Barra de progreso:
- **Atenuada** (`$text-secondary`) cuando queda saldo remanente sin cobrar/pagar (perdon parcial) — la barra NO llega al 100%, y el atenuado comunica que quedo un residuo sin resolver.
- **Llena en `$primary`** cuando la deuda se cerro al 100% pagada — esa si es la lectura correcta de "completado", se mantiene el tratamiento normal de `xSpw7`.

### Regla de negocio para dominio (resumen)

Cerrar una deuda manualmente con saldo pendiente es un **cambio de estado puro**, nunca un evento contable. No crea `DebtEntry`. El % historico se congela. Cerrar ≠ eliminar ≠ saldar automaticamente al 100% — son 3 flujos distintos con 3 entry points distintos (menu overflow → Cerrar deuda / menu overflow → Eliminar deuda / abono que llega a 0 → sheet de felicitacion → Completar).

## Cross-link Pago Programado → Deuda

Definido en `08-deudas.md` HU-03 y `09-pagos-programados.md` linea 111. Diseñado como adicion a las pantallas de Pagos Programados (aplica solo cuando el `ScheduledPayment` tiene `debtId`):

- **Detalle del PP** (`nDmnf`, variante nueva del canonico `OY2Kj`): **card "Deuda Enlazada"** (`M7Ijh`) entre la Ficha Card y el Historial — icono `landmark` (`$primary-on-soft-strong`) + "Cuota de / Credito vehicular · Yo debo" + `chevron-right` → navega al detalle de la deuda. Mismo chrome que la Ficha Card. El detalle **scrollea** (tiene "Ver historial completo (N)" que expande in-place), asi que el card se agrega sin recortar contenido: el excedente queda bajo el fold. El canonico `OY2Kj` (PP sin deuda) queda intacto.
- **Lista / Scheduled Card** (`tit0W`): nodo opcional **`Y5FQT` "Deuda Chip"** (`enabled:false` por default) apendido a la fila de chips, sin reestructurar el componente (regla de overrides). Badge sutil `$primary-soft` + icono `landmark` + "Deuda" (`$primary-on-soft-strong`). Demo en contexto: `F3srst`.
- Editar la plantilla de una cuota debe **deep-linkear de vuelta a la deuda** (su hogar), no editarse como plantilla suelta (comportamiento, no pantalla).

## Sheet Movimiento — Editar / Interés (`v4RJC` Editar / `ldTrt` Interés)

Reemplazan el flujo anterior de 2 pasos (ver detalle → editar), fusionado en uno solo para reducir taps — decisión de producto. Se abren directo al tocar una fila del ledger sin cuenta vinculada (`Debt Ledger Row · Running` en su variante "solo-deuda": abono, desembolso o ajuste manual). Ambas variantes navegan desde su acción de eliminar al sheet de confirmar eliminar movimiento (reusa el patrón destructivo genérico del sistema, mismo criterio que la nota de "Sheet confirmar borrado" de deuda arriba — sin frame propio dedicado en este documento).

### Editar (`v4RJC` / `L5KbhU`)

Bottom Sheet Base (`PqTUt`). **Header** (título "Editar movimiento" + contexto de la deuda, ej. "Crédito vehicular · Yo debo") + **Amount Hero** (monto héroe editable, label según tipo de movimiento — ej. "Abono" — con caret) + fila **"Saldo después"** (solo lectura) + `Form Field` **"Fecha"** (icono `calendar`, editable) + `Form Field` **"Nota (opcional)"** (icono `pencil`, editable) + CTA primario `Button/Primary` **"Guardar cambios"** (`$primary`, icono `check`) + **`Delete Link`** (`u0THG`) **"Eliminar movimiento"** debajo del CTA.

### Interés (`ldTrt` / `hVah4`)

Misma Bottom Sheet Base, estructura distinta para movimientos `interestAccrual` (generados automáticamente por el modo de interés automático de la deuda). **Header Row** con icon-wrap + icono `trending-up` + título "Interés" + tag "Estimado" (reemplaza el contexto de deuda del header de Editar). **Amount Hero** idéntico visualmente (mismo componente héroe+caret) pero de solo lectura. Fila "Saldo después" igual. **Info Card** con Fecha y Nota como **`Info Row` (`myfAc`) de solo lectura** (sin caja de input, sin `chevron`/affordance de tap) — ej. Nota: "Interés calculado automáticamente sobre el saldo pendiente al corte del {fecha}." **Sin botón "Guardar cambios".** Único CTA: `Button/Primary` **"Eliminar"** a ancho completo, en **`$expense`** (es el único botón de la hoja y es destructivo), icono `trash-2`.

### Regla de negocio (no se lee del frame — flutter-dev debe conocerla)

**Los movimientos de tipo `interestAccrual` nunca son editables, solo eliminables.** El monto héroe con caret en `ldTrt`/`hVah4` es puramente visual (reusa el mismo componente que la variante editable) — en Flutter no debe llevar foco/teclado, y por eso Fecha/Nota se renderizan con `Info Row` en vez de `Form Field`: no hay affordance de tap porque no hay nada que tocar. No existe CTA "Guardar cambios" para interés porque no hay nada que guardar: el único camino para "corregir" un interés generado automáticamente es eliminar el asiento (el motor lo recalcula) o cambiar el modo de interés de la deuda a Manual desde el form crear/editar. Si en el futuro se soporta interés manual editable, será una tercera variante de este sheet, no una extensión de `ldTrt`.

## Notas de implementacion (para flutter-dev)

- **Caret del heroe de monto** = convencion de mockup para "editable"; en Flutter la editabilidad real es el teclado/keypad al enfocar.
- **Tap target del switch** = fila completa, no solo el pill de 48×28.
- **Fila de chips de la Scheduled Card** (Freq Chip + Deuda Chip + fecha): en Flutter con `Expanded`/`ellipsis` para textos largos.
- **Tipo del `ScheduledPayment`** de una cuota se deriva de `Debt.direction`, no se expone como control.
- **Contraste de la barra de avance en oscuro** (~2.75:1) es un tema sistemico pendiente, no de Deudas — ver MASTER.

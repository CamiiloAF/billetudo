# Feature: Gráficas e informes esenciales

**Nivel:** 0 (gratis, sin anuncios) — límite: solo el **set esencial**. Vistas avanzadas (comparativas entre periodos, tendencias, desglose por etiquetas, proyecciones, export a PDF) son Nivel 1 (Modo anuncios) o Nivel 2 (Premium). Ver `docs/Plan_Monetizacion_y_Tecnico.md`.
**Librería:** `fl_chart`
**Fuente de datos:** `Transactions`, `Accounts`, `Categories`, `Budgets`, `Goals`, `Debts`, `DebtEntries`
**Ruta:** vive en el hub **"Más"** (`04-inicio.md` HU-01) y tiene chip de acceso rápido en Inicio (`04-inicio.md` HU-05b).
**Diseño:** aún no diseñado en `billetudo.pen`. Antes de implementar, seguir el flujo de diseño de `CLAUDE.md` (Pencil primero, `pages/graficas.md` después de aprobar).

## Contexto

Este es el único punto de la Fase 0 donde existe un límite deliberado de producto (no técnico): el set esencial es gratis para siempre, pero las vistas "avanzadas" quedan reservadas para Nivel 1/2. El criterio de qué es "esencial" debe quedar explícito para no bloquear por error algo que CLAUDE.md protege como Nivel 0.

Es también la pantalla donde **convergen** las reglas de conteo de toda la app: transferencias presupuestables (`plan-cuentas-tipos-y-transferencias-presupuestables.md` §3), movimientos de deuda (`08-deudas.md` §Estadísticas) y patrimonio total vs. líquido. Esas reglas se centralizan aquí (ver "Reglas de conteo") y el resto de docs las referencian; si un documento y este difieren, **manda este**.

### Alcance de construcción (decisión 2026-07-24)

Se construyen **solo las vistas esenciales** (HU-01 a HU-05). Las vistas avanzadas **no se construyen ni se dejan ocultas** tras una bandera, porque:

- El límite de Nivel 1 se cuenta **en el servidor** (backend + AdMob SSV + RevenueCat = **Fase 4**). UI avanzada construida antes queda o sin cerradura (regalando Cubo B) o muerta hasta Fase 4.
- Cada vista apagada arrastra diseño en Pencil (claro + oscuro + estados), goldens, Patrol y l10n es/en que derivan sin que ningún test lo atrape, porque la pantalla no se abre.

Lo que **sí** se construye ahora es la **costura** que evita el retrofit (ver "Costura para Nivel 1/2").

## Reglas de conteo (transversales: aplican a todas las HU salvo que una diga lo contrario)

Estas reglas son la fuente de verdad de "qué transacción entra en qué número". Antes existían dispersas y contradictorias entre `03`, `04`, `06`, `08` y este doc.

### Filas incluidas

- Se **excluyen** siempre: transacciones con `deletedAt` o `tombstonedAt`, y las de cuentas con `tombstonedAt`.
- Las cuentas **archivadas** se excluyen por defecto de los agregados; HU-02 ofrece incluirlas como opción explícita.

### Transferencias (`type = transfer`)

- **Sin `countsInBudget`** (default): **no cuentan** ni como ingreso ni como gasto en ninguna vista. El saldo ya se movió en ambas cuentas; contarlas sería doble conteo.
- **Con `countsInBudget = true`**: cuenta **solo el lado origen, como gasto** de su `categoryId`, en flujo de caja (HU-01) y estructura de gasto (HU-03).
  - **El lado destino NO entra como ingreso en reportes.** Ese "ingreso en el destino" es un concepto exclusivo del **alcance por cuenta de los presupuestos** (`BudgetAccounts`), donde casi nunca se ven ambos lados. Un reporte global **siempre** ve ambos: aplicar la regla simétrica inflaría ingreso y gasto del mismo mes y netearía a cero — el peor de dos mundos. Lectura correcta: *ahorrar es un uso de tu plata del mes*.
  - Esto precisa (no contradice) el requisito anotado en `plan-cuentas-tipos-y-transferencias-presupuestables.md` §3, que dejó el criterio de reportes abierto.

### Movimientos de deuda (`Transactions.debtId != null`)

- **Cuentan por defecto** como ingreso o gasto según su `type`. **Esto invierte la regla anterior** que los excluía igual que un `transfer`: pagar la cuota del carro *es* un gasto real del mes y desaparecerlo sería mentirle al usuario (ver `08-deudas.md` §Estadísticas).
- HU-01 ofrece un **toggle "movimientos de deuda"** que los **segrega como serie aparte** (no los oculta — ocultarlos descuadraría el gráfico contra los saldos reales).
- Los asientos de **solo-deuda** (`DebtEntries`: interés, ajuste manual, y los abonos/desembolsos sin caja) **nunca** entran a flujo ni a estructura de gasto: no son caja, no mueven ninguna cuenta. Sí afectan patrimonio (HU-02).

### Categoría ausente

`categoryId` es **opcional** en transacciones con `debtId` (`08-deudas.md` §Categorías), así que HU-03 necesita un bucket **"Sin categoría"** explícito. En gasto/ingreso normales la categoría es obligatoria (`03-transacciones.md`), así que ese bucket solo debería poblarse con movimientos de deuda.

### Moneda

- Si el usuario tiene **una sola moneda** (caso mayoritario): no hay conversión, ningún rótulo de aproximación.
- Si tiene **varias** y hay tasa cacheada (`12-multi-moneda.md`): se normaliza a la moneda base y se **rotula visiblemente como cifra aproximada/convertida**.
- Si tiene varias y **no** hay tasa cacheada (offline en el primer arranque, o antes de que exista la fuente FX): se **segmenta por moneda** — nunca se inventa un número ni se suman monedas distintas. Es el mismo criterio que ya usa `08-deudas.md` HU-04 en Fase 0.

### Fechas y agregación

- El corte de periodo usa la **zona horaria local del dispositivo**, coherente con cómo se guardó `date` en la transacción.
- La agregación se hace **en SQL (Drift)**, no iterando en Dart: un usuario con años de historial no puede cargar todas las transacciones en memoria para pintar un gráfico.

## Historias de usuario

### HU-01 — Ver flujo de caja del periodo
Como usuario quiero ver una gráfica de ingresos vs. gastos a lo largo del tiempo (ej. por mes), para entender si estoy gastando más de lo que gano.

**Criterios de aceptación:**
- Aplica íntegras las "Reglas de conteo": transferencias fuera salvo `countsInBudget` (solo lado origen, como gasto); movimientos con `debtId` dentro por defecto; `DebtEntries` fuera por construcción.
- **Toggle "movimientos de deuda"** (default: **integrados**). Al activarlo, los movimientos con `debtId` se muestran como **serie/segmento aparte** en vez de sumarse a ingreso y gasto. Motivo: un préstamo de 50M entra como "ingreso" que no se ganó, y las cuotas suman más que el préstamo por los intereses — el toggle deja responder "¿gané más de lo que gasté?" sin esa distorsión. Segrega, **no oculta**.
- **Rango:** por defecto últimos 6 o 12 meses agregados por mes; el usuario puede acotar el rango. El rango es un **parámetro de la vista** desde el día 1 (así "comparativa entre periodos" de Nivel 1 no obliga a reescribir la capa de datos después).
- Es parte del **set esencial gratis** (Nivel 0), sin límite de vistas ni de rango de fechas.

### HU-02 — Ver patrimonio a lo largo del tiempo
Como usuario quiero ver la evolución de lo que tengo en el tiempo, para saber si mi patrimonio crece o decrece.

**Criterios de aceptación:**
- Se presentan **dos cifras distinguidas**, no una:
  - **Patrimonio líquido / disponible** = Σ saldos de cuentas activas (el saldo de una tarjeta ya es negativo, así que resta solo).
  - **Patrimonio total** = líquido − Σ saldo pendiente de deudas `iOwe` + Σ saldo pendiente de deudas `owedToMe`.
- **Las deudas entran al patrimonio total** (una hipoteca de 200M resta; lo que me debe el primo suma como cuenta por cobrar) pero **no** al líquido/gastable — es el "tracking account" de YNAB nombrado con honestidad (`08-deudas.md` §Patrimonio). La separación líquido/total es justo lo que ese doc pide explicitar.
- El saldo de cada cuenta en un punto del tiempo se reconstruye con `initialBalanceMinor` + transacciones acumuladas hasta esa fecha. El saldo de cada deuda se reconstruye **desde su ledger** (apertura + asientos de caja + `DebtEntries` hasta esa fecha), nunca desde un número guardado.
- **El interés de una deuda baja el patrimonio sin aparecer en el flujo de caja (HU-01).** No es una inconsistencia: no es caja. Si la vista deja ver ambas curvas, debe poder explicarse (copy corto o tooltip), o el usuario la lee como un bug.
- Opción de **incluir cuentas archivadas** (excluidas por defecto).
- Multi-moneda: según las "Reglas de conteo" (una moneda → directo; varias con tasa → normalizado y rotulado aproximado; varias sin tasa → segmentado).
- Es parte del **set esencial gratis** (Nivel 0).

### HU-03 — Ver estructura de gasto por categoría
Como usuario quiero ver un desglose (ej. gráfica de dona/barras) de en qué categorías gasté más en un periodo, para identificar dónde puedo ajustar.

**Criterios de aceptación:**
- Agrupa por **categoría raíz**, con opción de expandir a subcategorías.
- Incluye, además del gasto normal: las **transferencias presupuestables** (lado origen, con su categoría) y las **cuotas/abonos de deuda** con caja (son gasto real). Excluye transferencias sin `countsInBudget` y todos los `DebtEntries`.
- Bucket **"Sin categoría"** para los movimientos con `debtId` que no la llevan.
- Periodo seleccionable (mes actual, mes anterior, rango personalizado). **Sin límite de rango** — el set esencial no se recorta por fechas.
- Es parte del **set esencial gratis** (Nivel 0).

### HU-04 — Ver progreso de presupuestos y metas en un vistazo
Como usuario quiero una vista resumen que combine el estado de mis presupuestos activos y mis metas, para revisar mi situación financiera en segundos.

**Criterios de aceptación:**
- Reutiliza los cálculos de `06-presupuestos.md` (HU-03) y `07-metas.md` (HU-04); esta feature solo los presenta agregados. **No reimplementa** ninguna de las dos lógicas.
- **Deudas no tienen bloque propio aquí** (decisión 2026-07-24): el avance "pagado / total" es el corazón de la feature Deudas y construirlo dos veces la duplica. Se resuelve con un **cross-link** a Deudas (`08-deudas.md` HU-04), coherente con el chip de acceso rápido de Inicio.
- **Delimitación contra el Home (`04-inicio.md`):** el Home responde *"¿cómo voy hoy?"* (gasto del mes en curso + actividad reciente, un solo mes, sin desglose). Esta vista responde *"¿cómo voy en conjunto?"* (todos los presupuestos activos y todas las metas, sin feed de actividad). No se comparten widgets de presentación, sí los casos de uso de `06` y `07`.
- Es parte del **set esencial gratis** (Nivel 0).

### HU-05 — Exportar una gráfica como imagen
Como usuario quiero poder guardar/compartir una imagen de una gráfica del set esencial, para respaldarla o compartirla informalmente (no confundir con export a PDF de informes avanzados, que es Nivel 1/2).

**Criterios de aceptación:**
- Exporta la **vista actual** como PNG con capacidades nativas de Flutter (`RepaintBoundary` → `toImage`), sin generar un documento de informe compuesto (eso es Cubo B/C).
- La imagen se entrega vía **share sheet del sistema** (y opción de guardar), sin requerir permisos de almacenamiento adicionales donde el share nativo baste.
- La imagen respeta el tema activo (claro/oscuro) y no filtra datos que la vista no muestre.

### HU-06 — Estados de la pantalla
Como usuario nuevo o sin datos suficientes quiero una pantalla que me oriente, en vez de un gráfico vacío o engañoso.

**Criterios de aceptación:**
- **Carga:** skeleton del gráfico (la agregación en SQL es local pero no instantánea con historial largo).
- **Vacío** (cero transacciones en el rango): mensaje orientador + CTA a registrar un movimiento. Nunca un gráfico de ceros.
- **Historial insuficiente** (ej. 3 días de uso con un rango de 12 meses): la vista **no finge** una serie larga. Acota automáticamente el rango a lo que existe e indica desde cuándo hay datos. Es la primera impresión de la pantalla para un usuario nuevo.
- **Offline / error de sync:** los datos salen de Drift, así que la pantalla funciona completa sin conexión; un fallo de sync no la vacía ni la bloquea (mismo criterio que `04-inicio.md` HU-10).
- Tono positivo en todos los estados; nunca avergonzar por el gasto ni por no tener datos.

## Costura para Nivel 1/2 (se construye en Fase 0, sin UI avanzada)

Para que añadir una vista avanzada en Fase 4 sea **aditivo** y no un retrofit sobre datos y UI ya escritos:

- **Catálogo declarativo de vistas** en `domain`: cada vista se declara con su identificador, su tipo y un campo `tier` (`essential` | `advanced`). Hoy todas las entradas son `essential`.
- **Un único punto de guarda** (`ChartAccessGuard` o equivalente) que consulta el `tier` antes de abrir una vista. En Fase 0 siempre deja pasar porque no existe ninguna `advanced`; en Fase 4 se le conecta la verificación de cupo **server-side** sin tocar las vistas.
- **El rango de fechas es parámetro** de cada vista desde el día 1 (HU-01), no una constante — es lo que después habilita comparativas y tendencias sin reescribir la capa de datos.
- **Nada de UI avanzada apagada**: no se agregan pantallas, rutas ni entradas de menú para vistas que no existen.

## Reglas de negocio y edge cases (crítico: no romper Nivel 0)

- **Definición cerrada del set esencial** (Nivel 0, para no derivarlo mal en implementación): flujo de caja (HU-01), patrimonio (HU-02), estructura de gasto por categoría (HU-03), y el dashboard de presupuestos/metas (HU-04), más el export PNG (HU-05). Todo lo que sea comparativas entre periodos, tendencias con proyección, desglose por etiquetas, o export a PDF **no** es Nivel 0 — pertenece a `Plan_Monetizacion_y_Tecnico.md` Cubo B.
- El límite de Nivel 1 se cuenta por **vistas nuevas generadas**, no por reaperturas: una vista avanzada ya desbloqueada este mes debe seguir viéndose sin gastar cupo. Es responsabilidad del backend (Fase 4); lo que esta feature aporta desde ya es la costura de arriba.
- Ninguna gráfica del set esencial puede quedar detrás de anuncio o pago bajo ninguna circunstancia (regla explícita de Nivel 0 en CLAUDE.md), ni recortada por rango de fechas o número de vistas.
- Todas las gráficas se calculan **100% en el dispositivo** (costo marginal $0), agregando en SQL.
- **Tono:** positivo y de progreso. Un mes con flujo negativo o una categoría alta se comunican con neutralidad, nunca avergonzando.
- Textos solo desde `AppLocalizations` (es + en); colores solo desde variables del `.pen` — ninguna serie de `fl_chart` con hex hardcodeado.

## Coherencia con otros documentos

Las "Reglas de conteo" de este doc son la fuente de verdad. Estos documentos se alinearon con ellas:

| Documento | Qué decía | Estado |
|---|---|---|
| `03-transacciones.md` HU-03 / Reglas | Una transacción con `debtId` no cuenta en los totales de gráficas; transferencias nunca cuentan | **Corregido** — deuda cuenta por defecto; transferencias con `countsInBudget` cuentan como gasto en el origen |
| `04-inicio.md` HU-03 / Reglas | El total del hero excluye `debtId` | **Corregido** — la cuota de deuda es gasto real del mes y debe aparecer |
| `06-presupuestos.md` | Las transferencias nunca cuentan para ningún presupuesto | **Corregido** — excepción `countsInBudget` (ver plan §3) |
| `08-deudas.md` §Estadísticas | Ya definía el toggle en flujo | Consistente |
| `plan-cuentas-...` §3 | Dejó el criterio de reportes abierto ("tratarlas como gasto/ingreso según el mismo criterio de alcance") | **Precisado aquí**: en reportes solo cuenta el lado origen |

## Fases

- **Fase 0 (esta HU):** HU-01 a HU-06 + la costura de tiers. Requiere que existan Transacciones, Cuentas, Categorías, Presupuestos, Metas y Deudas.
- **Dependencia blanda:** HU-01/HU-03 solo cambian de comportamiento cuando exista `countsInBudget` (Fase B1 del plan de transferencias). Si esta feature se implementa antes, la regla queda escrita y sin efecto — no es bloqueante.
- **Fase 4:** vistas avanzadas (Cubo B) enchufadas al catálogo + verificación de cupo server-side + AdMob SSV / RevenueCat.

## Cumplimiento (Nivel 0 / legal / tono)

- Todo el set esencial es **Nivel 0 gratis**, ilimitado y sin anuncios. Nada de banners ni interstitials ambientales en esta pantalla.
- Dinero siempre en **centavos** (enteros); ninguna agregación intermedia en `double`.
- Sin llamadas de red ni IA: todo se calcula local. No aplica el disclaimer de "no es asesoría financiera" mientras no haya insight generado por IA — si alguna vista añade un texto interpretativo automático, lo requiere.

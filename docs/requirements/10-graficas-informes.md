# Feature: Gráficas e informes esenciales

**Nivel:** 0 (gratis, sin anuncios) — límite: solo el **set esencial**. Vistas avanzadas (comparativas entre periodos, tendencias, desglose por etiquetas, proyecciones, export a PDF) son Nivel 1 (Modo anuncios) o Nivel 2 (Premium). Ver `docs/Plan_Monetizacion_y_Tecnico.md`.
**Librería:** `fl_chart`
**Fuente de datos:** `Transactions`, `Accounts`, `Categories`, `Budgets`

## Contexto

Este es el único punto de la Fase 0 donde existe un límite deliberado de producto (no técnico): el set esencial es gratis para siempre, pero las vistas "avanzadas" quedan reservadas para Nivel 1/2. El criterio de qué es "esencial" debe quedar explícito para no bloquear por error algo que CLAUDE.md protege como Nivel 0.

## Historias de usuario

### HU-01 — Ver flujo de caja del periodo
Como usuario quiero ver una gráfica de ingresos vs. gastos a lo largo del tiempo (ej. por mes), para entender si estoy gastando más de lo que gano.

**Criterios de aceptación:**
- Excluye transacciones `type = transfer` del cálculo (no son ni ingreso ni gasto real).
- **Transacciones con `debtId` asignado: cuentan por defecto, pero se pueden separar (toggle "movimientos de deuda").** Cambia la regla previa que las excluía siempre como `transfer`: por decisión de producto (ver `08-deudas.md`, sección "Estadísticas"), un desembolso/abono de deuda **sí** afecta saldos y presupuestos. El único riesgo es este gráfico de flujo —un préstamo entra como "ingreso" que no se ganó, y las cuotas suman más que el préstamo por los intereses—, así que la vista ofrece un **toggle opcional** para segregarlas como "movimientos de deuda" y no distorsionar el "¿gané más de lo que gasté?". Los asientos de **interés** de una deuda no son transacciones (son solo-deuda, tabla `DebtEntries`), así que quedan fuera de este cálculo por construcción.
- Periodo por defecto: últimos 6 o 12 meses, agregado por mes; el usuario puede acotar el rango.
- Es parte del **set esencial gratis** (Nivel 0), sin límite de vistas ni de rango de fechas.

### HU-02 — Ver balance / patrimonio a lo largo del tiempo
Como usuario quiero ver la evolución de mi saldo total (suma de todas las cuentas) en el tiempo, para ver si mi patrimonio crece o decrece.

**Criterios de aceptación:**
- Suma los saldos de todas las cuentas no archivadas (u ofrece incluir archivadas como opción) en cada punto del tiempo, considerando `initialBalanceMinor` + transacciones acumuladas hasta esa fecha.
- Multi-moneda: se normaliza a una moneda base para el gráfico agregado (ver `12-multi-moneda.md`); se indica claramente que es una conversión aproximada según tasa cacheada.
- Es parte del **set esencial gratis** (Nivel 0).

### HU-03 — Ver estructura de gasto por categoría
Como usuario quiero ver un desglose (ej. gráfica de dona/barras) de en qué categorías gasté más en un periodo, para identificar dónde puedo ajustar.

**Criterios de aceptación:**
- Agrupa por categoría raíz (con opción de expandir a subcategorías), excluyendo transferencias.
- Periodo seleccionable (mes actual, mes anterior, rango personalizado dentro de lo que cubre el "set esencial" — ver Reglas de negocio).
- Es parte del **set esencial gratis** (Nivel 0).

### HU-04 — Ver progreso de presupuestos y metas en un vistazo
Como usuario quiero una vista resumen que combine el estado de mis presupuestos activos y mis metas, para revisar mi situación financiera en segundos.

**Criterios de aceptación:**
- Reutiliza los cálculos de `06-presupuestos.md` (HU-03) y `07-metas.md` (HU-04); esta feature solo los presenta agregados en un dashboard.
- Es parte del **set esencial gratis** (Nivel 0).

### HU-05 — Exportar una gráfica como imagen
Como usuario quiero poder guardar/compartir una imagen de una gráfica del set esencial, para respaldarla o compartirla informalmente (no confundir con export a PDF de informes avanzados, que es Nivel 1/2).

**Criterios de aceptación:**
- Exporta la vista actual como imagen (PNG) usando capacidades nativas de `fl_chart`/Flutter, sin generar un documento de informe compuesto (eso es Cubo B/C).

## Reglas de negocio y edge cases (crítico: no romper Nivel 0)

- **Definición cerrada del set esencial** (Nivel 0, para no derivarlo mal en implementación): flujo de caja (HU-01), balance/patrimonio (HU-02), estructura de gasto por categoría (HU-03), y el dashboard de presupuestos/metas (HU-04). Todo lo que sea comparativas entre periodos, tendencias con proyección, desglose por etiquetas, o export a PDF **no** es Nivel 0 — pertenece a `Plan_Monetizacion_y_Tecnico.md` Cubo B.
- El límite de Nivel 1 se cuenta por **vistas nuevas generadas**, no por reaperturas: una vista avanzada ya desbloqueada este mes debe seguir viéndose sin gastar cupo — esto es responsabilidad del backend/lógica de cupos (Fase 4), no de esta feature de Fase 0, pero el modelo de datos y la UI deben distinguir claramente "esencial" de "avanzado" desde ya para no tener que retrofit-ear el límite después.
- Ninguna gráfica del set esencial puede quedar detrás de anuncio o pago bajo ninguna circunstancia (regla explícita de Nivel 0 en CLAUDE.md).
- Todas las gráficas se calculan 100% en el dispositivo (costo marginal $0).

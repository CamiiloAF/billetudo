# Feature: Multi-moneda

**Estado (2026-07-28): diferida a Fase 1b.** No entra en el alcance de Fase 1 / Nivel 0. Lo que Fase 1 sí garantiza está en "Qué queda en Fase 1" abajo.
**Nivel (cuando llegue):** 0 (gratis, sin anuncios) — costo marginal ~$0 (una llamada de tasas FX al día para *todos* los usuarios, no por usuario). Diferirla es una decisión de **secuencia**, no de monetización: al implementarse no queda detrás de anuncio ni pago.
**Campos relevantes:** `currency` en `Accounts`, `Transactions`, `Budgets`, `Goals`, `Debts`, `ScheduledPayments`.

## Contexto

Feature muy pedida y mal cubierta según la investigación de mercado, relevante para freelancers que cobran en USD, expatriados y remesas en LatAm. Cada tabla ya tiene su propio campo `currency` en el esquema — el diseño multi-moneda es "cada entidad vive en su moneda", con conversión solo para agregación en reportes.

## Por qué se difiere a Fase 1b

- **Lo caro no es el campo `currency`, es la conversión.** El modelo "cada entidad vive en su moneda" ya está en el esquema y funciona hoy. Lo que falta —y lo que cuesta— es la infraestructura de tasas: una fuente FX, un job diario compartido, caché local, tasa manual por transacción, y la regla de redondeo a entero en cada punto donde se convierte.
- **Toca todas las features a la vez.** Conversión implica reabrir saldos, presupuestos, metas, deudas, reportes y el importador. Es un cambio transversal sobre features que apenas se están terminando de construir.
- **La app ya se comporta correctamente sin ella.** Fase 1 nunca suma monedas distintas: segmenta por moneda. Eso es honesto y no bloquea a nadie — el usuario multi-moneda puede registrar todo, solo no ve un total consolidado.
- **El usuario mayoritario del arranque es de una sola moneda**, así que el costo de esperar recae sobre una minoría, y sin pérdida de datos: todo lo que registre hoy en varias monedas se conserva íntegro y se podrá consolidar cuando llegue la conversión.

**Sin conexión a este diferimiento:** nada de lo que Fase 1 escribe hay que migrar después. Los montos ya se guardan con su `currency` original.

## Qué queda en Fase 1 (ya definido en otras features, no se toca)

- **Cada entidad vive en su moneda.** El `currency` se elige al crear la cuenta (`01-cuentas.md` HU-01) y las demás entidades heredan o fijan el suyo. No hay conversión en ninguna escritura.
- **Nunca se suman monedas distintas.** Donde habría un total agregado, se **segmenta por moneda**: saldos de cuentas (`01-cuentas.md` HU-04), totales del periodo (`03-transacciones.md`), deudas (`08-deudas.md` HU-04), metas (`07-metas.md`) y patrimonio/balance (`10-graficas-informes.md` §Reglas de conteo).
- **Presupuestos:** un presupuesto tiene una sola `currency` y su progreso suma **solo** transacciones de esa misma moneda; se advierte en la UI si su alcance incluye cuentas de otra (`06-presupuestos.md`).
- **Import/export:** cada fila lleva su moneda original, sin conversión. Una fila cuya moneda no coincide con la de la cuenta destino se importa igual (`11-import-export.md`).
- **Decimales:** los inputs permiten decimales en toda moneda y el almacenamiento sigue en centavos enteros; COP muestra decimales solo cuando existen. **Esto ya está implementado y no depende de esta feature.**
- **No existe "moneda base"** como ajuste de la app en Fase 1. El onboarding tampoco la pide (`13-onboarding.md`).

## Historias de usuario (Fase 1b)

### HU-01 — Registrar transacciones en distintas monedas
Como usuario quiero registrar una transacción en una moneda distinta a la de la cuenta (ej. pago en USD desde una cuenta en COP), para reflejar operaciones reales en moneda extranjera.

**Criterios de aceptación:**
- El campo `currency` de la transacción es independiente del `currency` de la cuenta.
- Si difieren, la app pide o sugiere una tasa de conversión (ver HU-02) para calcular el efecto real en el saldo de la cuenta, que siempre se contabiliza en la moneda de la cuenta.
- El monto original ingresado y su moneda quedan guardados sin pérdida (`amountMinor` + `currency` de la transacción), aunque el efecto en saldo se aplique convertido.

### HU-02 — Tasas de cambio cacheadas
Como usuario quiero que la app use tasas de cambio actualizadas automáticamente, sin tener que buscarlas yo mismo, para no perder tiempo ni cometer errores de conversión.

**Criterios de aceptación:**
- Las tasas se obtienen de una fuente FX externa una vez al día (compartida para todos los usuarios, no por usuario — costo marginal ~$0) y se cachean localmente para uso offline.
- Si no hay conexión y no hay tasa cacheada reciente para el par de monedas requerido, se le pide al usuario ingresar la tasa manualmente para esa transacción puntual.
- El usuario puede ver y, si lo desea, sobrescribir manualmente la tasa aplicada a una transacción específica (ej. si usó una casa de cambio con tasa distinta a la de mercado).

### HU-03 — Transferencias entre cuentas de distinta moneda
Como usuario quiero transferir entre una cuenta en una moneda y otra en moneda distinta, para reflejar cambios de divisa reales (ej. cambié USD a COP en efectivo).

**Criterios de aceptación:**
- Al registrar la transferencia (`03-transacciones.md` HU-03) con cuentas de monedas distintas, se solicita la tasa aplicada (sugerida por HU-02, editable) para calcular cuánto entra en la cuenta destino.
- Ambos montos (origen convertido y destino) quedan trazables en el detalle de la transacción.

### HU-04 — Reportes agregados multi-moneda
Como usuario quiero ver un balance total consolidado aunque tenga cuentas en varias monedas, para saber mi patrimonio total en una sola cifra.

**Criterios de aceptación:**
- El usuario define una "moneda base" para reportes agregados (configuración de la app).
- Las gráficas de balance/patrimonio (`10-graficas-informes.md` HU-02) convierten cada cuenta a la moneda base usando la tasa cacheada más reciente, indicando visualmente que es una cifra aproximada/convertida.
- Las gráficas que no agregan entre monedas (ej. estructura de gasto de una sola cuenta) no requieren conversión.
- **Mientras esta HU no exista, el comportamiento vigente es segmentar por moneda** — ya especificado en `10-graficas-informes.md` §Reglas de conteo, y no es un estado degradado sino la respuesta correcta sin tasas.

### HU-05 — Elegir moneda de una cuenta al crearla — **ya en Fase 1**
Como usuario quiero elegir la moneda de cada cuenta de forma independiente, para modelar cuentas que legítimamente viven en distintas divisas.

**Criterios de aceptación:**
- Ver `01-cuentas.md` HU-01; el código ISO-4217 se fija al crear la cuenta. **Esto ya funciona hoy** y no depende del diferimiento.
- Cambiar la moneda de una cuenta con transacciones existentes exige un flujo explícito de confirmación/conversión (no un cambio silencioso que distorsione el historial). **La rama con conversión es Fase 1b**; en Fase 1 el cambio de moneda con historial simplemente no se ofrece.

## Reglas de negocio y edge cases

- Nunca usar `double` para montos ni para tasas de conversión aplicadas a montos: el monto convertido resultante se guarda como entero en centavos; la tasa en sí puede ser un factor decimal pero el cálculo final se redondea a entero antes de persistir.
- **Decimales en la entrada y visualización (fix item 4, `docs/fixes/bugfixes-0.0.1.md`):** todos los inputs de monto **permiten teclear decimales**, también en COP (antes COP estaba fijado a 0 decimales de entrada). El **almacenamiento sigue en centavos enteros** (`amountMinor`, ×100 — regla intacta). En la **visualización**, COP muestra los decimales **solo cuando existen** (`$1.234` si es entero, `$1.234,50` si hay centavos) — no se fuerza `,00` en montos enteros, respetando la convención colombiana. Las monedas que convencionalmente usan 2 decimales (USD, EUR, …) los muestran siempre. **Ya implementado; no se difiere.**
- La llamada a la fuente de tasas FX es una sola por día para toda la base de usuarios (no por usuario), manteniendo el costo marginal en cero — detalle de arquitectura de `Plan_Monetizacion_y_Tecnico.md` Cubo A.
- Sin conexión, la app debe seguir funcionando con la última tasa cacheada (o pedir la tasa manual) — coherente con el principio offline-first.
- **Toda cifra convertida se rotula como aproximada.** Nunca se presenta un consolidado convertido como si fuera exacto.

## Condiciones para retomarla

Se reabre cuando se cumpla al menos una:

1. **Demanda real de usuarios** con cuentas en más de una moneda (hoy es una hipótesis de mercado, no un dato del producto).
2. Las features de Fase 1 están cerradas y estables — conversión toca todas, y hacerlo sobre features en construcción multiplica el retrabajo.
3. Existe la infraestructura de backend para el job diario de tasas (Supabase Edge Functions), que hoy no está cableada.

**Al retomarla, revisar primero** las reglas de segmentación por moneda ya escritas en `01`, `03`, `06`, `07`, `08`, `10` y `11`: la conversión no las reemplaza, se suma como una vista alternativa rotulada como aproximada.

# Feature: Multi-moneda

**Nivel:** 0 (gratis, sin anuncios) — costo marginal ~$0 (una llamada de tasas FX al día para *todos* los usuarios, no por usuario).
**Campos relevantes:** `currency` en `Accounts`, `Transactions`, `Budgets`, `Goals`, `Debts`, `Recurrings`.

## Contexto

Feature muy pedida y mal cubierta según la investigación de mercado, relevante para freelancers que cobran en USD, expatriados y remesas en LatAm. Cada tabla ya tiene su propio campo `currency` en el esquema — el diseño multi-moneda es "cada entidad vive en su moneda", con conversión solo para agregación en reportes.

## Historias de usuario

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
- Las gráficas de balance/patrimonio (`08-graficas-informes.md` HU-02) convierten cada cuenta a la moneda base usando la tasa cacheada más reciente, indicando visualmente que es una cifra aproximada/convertida.
- Las gráficas que no agregan entre monedas (ej. estructura de gasto de una sola cuenta) no requieren conversión.

### HU-05 — Elegir moneda de una cuenta al crearla
Como usuario quiero elegir la moneda de cada cuenta de forma independiente, para modelar cuentas que legítimamente viven en distintas divisas.

**Criterios de aceptación:**
- Ver `01-cuentas.md` HU-01; el código ISO-4217 se fija al crear la cuenta.
- Cambiar la moneda de una cuenta con transacciones existentes exige un flujo explícito de confirmación/conversión (no un cambio silencioso que distorsione el historial).

## Reglas de negocio y edge cases

- Nunca usar `double` para montos ni para tasas de conversión aplicadas a montos: el monto convertido resultante se guarda como entero en centavos; la tasa en sí puede ser un factor decimal pero el cálculo final se redondea a entero antes de persistir.
- La llamada a la fuente de tasas FX es una sola por día para toda la base de usuarios (no por usuario), manteniendo el costo marginal en cero — detalle de arquitectura de `Plan_Monetizacion_y_Tecnico.md` Cubo A.
- Sin conexión, la app debe seguir funcionando con la última tasa cacheada (o pedir la tasa manual) — coherente con el principio offline-first.

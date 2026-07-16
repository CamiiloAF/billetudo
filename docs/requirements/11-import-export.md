# Feature: Import/Export CSV

**Nivel:** 0 (gratis, ilimitado, sin anuncios) — feature de **confianza**, deliberadamente gratis.
**Fuente/destino de datos:** `Accounts`, `Categories`, `Transactions`

## Contexto

Diferenciador de posicionamiento explícito: "nunca te sentirás atrapado". Tras el cierre de Mint, millones de usuarios temieron perder su historial — esta feature es la promesa contraria. Incluye compatibilidad con formatos de Wallet/Mint para facilitar la migración de usuarios que vienen de esas apps.

## Historias de usuario

### HU-01 — Exportar todas mis transacciones a CSV
Como usuario quiero exportar todas mis transacciones (o un rango filtrado) a un archivo CSV, para tener un respaldo propio o llevarlas a otra herramienta.

**Criterios de aceptación:**
- Exporta columnas legibles: fecha, cuenta, categoría (con jerarquía si aplica), tipo, monto (en unidades normales, ej. `12.34`, no en centavos — el CSV es para humanos/otras apps), moneda, nota, etiquetas.
- Permite exportar todo el histórico o un rango filtrado (reutiliza los filtros de `03-transacciones.md` HU-06: cuenta, categoría, tipo, fechas, etiqueta).
- El archivo se puede compartir/guardar usando los mecanismos nativos del dispositivo (compartir, guardar en almacenamiento local).
- Sin límite de tamaño ni de frecuencia de exportación (Nivel 0).

### HU-02 — Exportar cuentas y categorías
Como usuario quiero exportar también mi estructura de cuentas y categorías, para tener un respaldo completo de mi configuración, no solo de los movimientos.

**Criterios de aceptación:**
- Exports separados o incluidos como hojas/secciones adicionales del mismo flujo (a definir en diseño de UI), cubriendo `Accounts` y `Categories` con su jerarquía (`parentId`).

### HU-03 — Importar transacciones desde CSV
Como usuario quiero importar transacciones desde un archivo CSV (propio o de otra app), para no perder mi historial al migrar a esta app.

**Criterios de aceptación:**
- Soporta un formato propio documentado (mismo esquema del export, HU-01) como caso base.
- Soporta explícitamente los formatos de exportación de **Wallet (BudgetBakers)** y **Mint**, mapeando sus columnas a los campos de `Transactions`/`Accounts`/`Categories` (detección de formato automática o selección manual por el usuario).
- Antes de confirmar la importación, se muestra una vista previa (cuántas transacciones, a qué cuentas/categorías se mapearán, cuántas son nuevas vs. posibles duplicados).
- Categorías o cuentas que no existan se crean automáticamente (o se ofrece mapearlas a una existente) — nunca se pierde una fila por falta de categoría/cuenta destino.
- Los montos del CSV (decimales) se convierten a enteros en centavos (`amountMinor`) de forma segura, sin errores de redondeo.
- Al finalizar, se muestra un resumen: filas importadas, filas omitidas y por qué (ej. fila malformada, moneda no reconocida).

### HU-04 — Detectar y evitar duplicados al importar
Como usuario quiero que la app me avise si estoy por importar transacciones que ya tengo, para no duplicar mi historial al reimportar un archivo por error.

**Criterios de aceptación:**
- Heurística de duplicado razonable (ej. misma cuenta + mismo monto + misma fecha + nota similar) marca candidatos a duplicado en la vista previa (HU-03) para que el usuario decida incluir u omitir.
- No se bloquea la importación completa por sospecha de duplicados — es una advertencia, decisión final del usuario.

## Reglas de negocio y edge cases

- Esta feature nunca puede quedar bloqueada tras anuncio o pago — es Nivel 0 explícito y central al posicionamiento de confianza del producto (CLAUDE.md, `docs/Viabilidad_App_Finanzas_Personales.md` sección 3.2).
- El export/import es 100% local (lee/escribe archivos en el dispositivo); no depende de conexión ni de backend.
- La compatibilidad con Wallet/Mint es best-effort: documentar claramente qué columnas de esos formatos se soportan y cuáles se ignoran, para no prometer una migración 1:1 perfecta que no se pueda cumplir.

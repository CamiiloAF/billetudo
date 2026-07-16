# Feature: Auth + Sync (respaldo en la nube)

**Nivel:** 0 (el respaldo/sync en sí es gratis desde el día 1 — no es una feature de monetización; solo IA/gráficas avanzadas se monetizan).
**Piezas técnicas:** Supabase Auth (social), PowerSync ↔ Supabase Postgres.

## Contexto

Local-first estricto: la app es 100% usable sin cuenta. El login se ofrece **después**, como invitación a respaldar/sincronizar, nunca como requisito de entrada. Al iniciar sesión, los datos locales existentes se **fusionan** con la cuenta, sin pérdida. Auth es solo social (nunca email/contraseña): Android → solo Google; iOS → Google + Sign in with Apple (requisito Apple 4.8).

## Historias de usuario

### HU-01 — Usar la app sin cuenta
Como usuario nuevo quiero poder usar todas las features de Nivel 0 sin crear cuenta ni iniciar sesión, para empezar a registrar mis finanzas de inmediato sin fricción.

**Criterios de aceptación:**
- Ninguna pantalla de login bloquea el acceso a cuentas, transacciones, presupuestos, metas, deudas, gráficas esenciales o import/export.
- Todos los datos se guardan localmente en Drift/SQLite desde el primer uso, sin requerir red.

### HU-02 — Iniciar sesión con Google (Android e iOS)
Como usuario quiero poder iniciar sesión con mi cuenta de Google cuando yo decida, para respaldar mis datos en la nube y poder recuperarlos si cambio de dispositivo.

**Criterios de aceptación:**
- Login vía Supabase Auth con proveedor Google, disponible en ambas plataformas.
- No se solicita email/contraseña en ningún punto de la app (regla no negociable de CLAUDE.md).
- Tras autenticar, se inicia el flujo de fusión de datos (HU-04).

### HU-03 — Iniciar sesión con Apple (solo iOS)
Como usuario de iPhone quiero poder iniciar sesión con Sign in with Apple, para cumplir mi preferencia de privacidad y la exigencia de Apple de ofrecer esta alternativa cuando hay login social de terceros.

**Criterios de aceptación:**
- Disponible únicamente en iOS (no aplica en Android).
- Presente como alternativa visible junto a Google en la pantalla de login de iOS, cumpliendo la guía 4.8 de App Store.

### HU-04 — Fusionar datos locales al iniciar sesión por primera vez
Como usuario que ya venía usando la app sin cuenta, quiero que al iniciar sesión mis datos locales se conserven y se suban a la nube, para no perder nada de lo que ya registré.

**Criterios de aceptación:**
- Al autenticar por primera vez en un dispositivo con datos locales existentes, esos datos se asocian al usuario y se sincronizan hacia Supabase vía PowerSync — nunca se sobrescriben ni se descartan.
- Si el usuario inicia sesión en un segundo dispositivo que ya tiene una cuenta con datos en la nube, y ese dispositivo también tiene datos locales previos (creados sin sesión), ambos conjuntos se fusionan sin duplicar (los UUID de cada tabla, generados con `clientDefault`, evitan colisión de IDs entre dispositivos).
- El usuario recibe una confirmación clara de que la fusión ocurrió y puede ver sus datos combinados.

### HU-05 — Sincronización bidireccional continua
Como usuario con sesión iniciada quiero que mis cambios se sincronicen automáticamente entre mis dispositivos, para tener la misma información en todos lados.

**Criterios de aceptación:**
- PowerSync mantiene la SQLite local en sync bidireccional con Supabase Postgres, con reconciliación automática al reconectar tras estar offline.
- La app sigue siendo utilizable offline con sesión iniciada; los cambios se encolan y sincronizan al recuperar conexión, sin pérdida de datos.
- **Las sync rules deben replicar el filtro `tombstonedAt IS NULL`.** Ver "Lápidas y sync rules" abajo: sin ese filtro, las cuentas borradas reaparecen en la UI.

### Lápidas de integridad referencial y sync rules

> Detectado al implementar Cuentas (2026-07-15). **Hay que resolverlo antes de cablear PowerSync**, no después: define el esquema de Postgres y las sync rules.

Dos columnas con significados distintos que no se pueden confundir (ver CLAUDE.md → Borrado):

- **`deletedAt`** — papelera/undo de UX. Reversible. PowerSync propaga el DELETE real por su cuenta.
- **`tombstonedAt`** — lápida de integridad referencial. Irreversible. La fila **debe sobrevivir** porque otras tablas la referencian (`Transactions.accountId` necesita que su cuenta exista aunque el usuario la haya borrado). El cliente la oculta filtrando `tombstonedAt IS NULL`.

Decisiones (2026-07-16):

1. **Las sync rules replican el filtro `tombstonedAt IS NULL`.** Toda bucket definition de PowerSync que exponga una tabla con `_SyncColumns` debe repetir ese filtro — igual que el cliente. Sin esto, una fila lápida resucita en la UI de cualquier dispositivo nuevo.
2. **DELETE real vía job de limpieza periódico en el servidor.** Un cron en Supabase recorre las tablas con lápidas y emite `DELETE` real sobre las filas `tombstonedAt IS NOT NULL` que ya no tienen ninguna fila viva referenciándolas por FK (p. ej. una `Account` tombstoneada sin `Transactions` que la referencien). Se prefiere sobre el borrado en cascada al momento porque no depende de acertar el trigger exacto en cada flujo del cliente, y sobre "permanente para siempre" porque evita crecimiento indefinido de lápidas. Pendiente de implementación cuando se cablee Supabase (fuera del alcance de esta ronda de diseño de UI).
3. **`accountNumberEnc` se elimina del esquema.** Era columna muerta (siempre NULL por diseño) y un riesgo de fuga si alguien la escribía por error. Ver migración de esquema (schemaVersion 5).
4. **`updatedAt` pasa a epoch millis (`IntColumn`).** Reemplaza el `DateTimeColumn` de segundos en `_SyncColumns` para que el desempate de conflictos de PowerSync sea preciso incluso con dos escrituras en el mismo segundo. Ver migración de esquema (schemaVersion 5). `createdAt` se mantiene igual (no participa en resolución de conflictos).
5. **HU-07 (borrado de cuenta) ignora el job de limpieza.** El borrado de cuenta llama al Edge Function que borra *todas* las filas del usuario en Supabase, lápidas incluidas, de forma síncrona e inmediata — no espera al cron del punto 2.

### HU-06 — Cerrar sesión
Como usuario quiero poder cerrar sesión sin perder mis datos localmente, para dejar de sincronizar en este dispositivo si lo comparto con alguien más.

**Criterios de aceptación:**
- Cerrar sesión detiene la sincronización pero conserva los datos ya presentes localmente en el dispositivo (no se borran).
- Se advierte al usuario que, sin sesión, los cambios futuros en este dispositivo no se sincronizarán hasta volver a iniciar sesión.

### HU-07 — Borrar cuenta dentro de la app
Como usuario quiero poder borrar completamente mi cuenta y mis datos en la nube desde dentro de la app, para ejercer mi derecho a que no quede rastro mío en el servidor.

**Criterios de aceptación:**
- Requisito legal obligatorio de Apple y Google para cualquier app con creación de cuenta — debe estar disponible en la Fase 1/0, no postergarse.
- La acción borra los datos del usuario en Supabase (no solo cierra sesión ni es un borrado lógico); se le advierte al usuario que es irreversible antes de confirmar.
- Tras el borrado, los datos locales en el dispositivo actual quedan bajo control del usuario (se le pregunta si desea conservarlos localmente sin cuenta o borrarlos también).

## Reglas de negocio y edge cases

- Nunca ofrecer login por email/contraseña — regla no negociable (CLAUDE.md).
- El login nunca es requisito para usar ninguna feature de Nivel 0 — es siempre una invitación posterior a "respaldar y sincronizar".
- El borrado de cuenta (HU-07) debe implementarse junto con el Auth, no dejarse para el final del roadmap — riesgo legal directo de rechazo en las tiendas.
- Los límites/cupos de IA y anuncios (Nivel 1/2) se validan en el servidor, nunca en el cliente — aplica a features futuras que dependan de esta cuenta, no a esta feature en sí.

# Auditoría de tratamiento de datos — billetudo

**Fecha:** 2026-08-07 · **Actualizada:** 2026-08-17 (revisión de vigencia: esquema
en `schemaVersion` 28 y dos columnas nuevas §1.1; estado real de B1 y B3 §0;
**Fase 2 especificada pero NO implementada** §10.2 y
[`checklist-fase-2.md`](checklist-fase-2.md))
· 2026-08-08 (identidad del responsable §10.1; alojamiento de proveedores §4.5;
decisiones confirmadas de jurisdicción, edad, vigencia, marca y cuentas de
tienda §11; retención y data scrubbing de Sentry §4.3)
**Versión de la app auditada:** `0.0.5+8` (`pubspec.yaml:4`)
**Alcance:** todo `lib/`, `android/`, `ios/`, `supabase/`, `pubspec.yaml`, más verificación
en vivo contra el proyecto Supabase de **producción** (`dlmocmvddzygltjgkwka`).

> **Estado del árbol al 2026-08-17.** Esta revisión se hizo contra el *working
> tree*, que tiene trabajo sin commitear: `lib/core/database/app_database.dart`
> (schemaVersion 26 → 28), `lib/core/crash/sentry_redaction.dart` (nuevo),
> `supabase/migrations/20260808000000_delete_account_cascade_missing_tables.sql`
> (nuevo) y `web/` (el sitio legal estático). Nada de eso está en un binario
> publicado todavía, así que **no** puede afirmarse en los documentos públicos
> como si ya estuviera vigente. Ver B1 y B3.

Este documento es la evidencia detrás de `politica-de-privacidad.md`,
`terminos-de-uso.md` y `declaraciones-tiendas.md`. Cada afirmación de esos tres
documentos tiene que poder rastrearse hasta una línea de aquí. Si algo no se
pudo verificar, aparece como `[VERIFICAR: ...]` y **no** se afirma en los
documentos públicos.

> **No es asesoría jurídica.** Esta auditoría verifica que los documentos sean
> exactos respecto al software y completos respecto a los requisitos de tienda.
> La revisión legal formal la tiene que hacer una persona abogada.

---

## 0. Bloqueantes encontrados (leer primero)

### B1 — ✅ RESUELTO (2026-08-08): el borrado de cuenta fallaba para usuarios con presupuestos por periodo o metas con montos rápidos

> **Estado: cerrado.** Corregido por la migración
> `supabase/migrations/20260808000000_delete_account_cascade_missing_tables.sql`,
> **aplicada en dev y en producción**. El hallazgo se conserva abajo porque
> documenta el fallo real y la evidencia con que se detectó.
>
> Qué se hizo:
> - `ON DELETE CASCADE` estructural en las FK que estaban en `NO ACTION`
>   (`budget_period_overrides` → `budgets`, `goal_quick_amounts` → `goals`) y
>   FK nuevas donde no había ninguna (`debt_entries` → `debts` y `user_id`,
>   `import_batches` → `user_id`).
> - `delete_account_data` reescrita con los cinco `delete` que faltaban, hijos
>   antes que padres.
> - Se añadió `delete_account_data_coverage_gaps()`, que compara las tablas con
>   `user_id` contra las que la función borra, para que la próxima tabla nueva
>   no repita este fallo en silencio. **Probada en negativo**: se creó una tabla
>   ficticia, se confirmó que la detecta y se eliminó.
> - Verificado tras aplicar en producción: 0 filas huérfanas y 0 pérdida de
>   datos de otros usuarios.

**Verificado en vivo contra Postgres de producción**, no por lectura de código.

La Edge Function `delete-account` llama al RPC `delete_account_data`, que hoy
borra **15 tablas** (verificado con `pg_get_functiondef` sobre el proyecto de
producción). El esquema real tiene **21 tablas** con `user_id`. Faltan cinco:

| Tabla huérfana | FK hacia | `ON DELETE` | Consecuencia real |
|---|---|---|---|
| `budget_period_overrides` | `budgets` | **NO ACTION** | **El `delete from budgets` FALLA.** Como el RPC es atómico, **revierte el borrado entero de la cuenta.** |
| `goal_quick_amounts` | `goals` | **NO ACTION** | **El `delete from goals` FALLA.** Mismo efecto: revierte todo. |
| `debt_entries` | *(sin FK)* | — | Sobrevive al borrado. Contiene montos, fechas y **notas de texto libre**. |
| `tutorial_views` | *(sin FK)* | — | Sobrevive al borrado. |
| `goal_contributions` | `goals` | `CASCADE` | OK, se borra sola. |

Evidencia (SQL ejecutado contra prod):

```sql
-- definición vigente del RPC: 15 deletes, sin las tablas de arriba
select pg_get_functiondef(oid) from pg_proc where proname = 'delete_account_data';

-- reglas de borrado reales
budget_period_overrides_budget_id_fkey → budgets, delete_rule = NO ACTION
goal_quick_amounts_goal_id_fkey        → goals,   delete_rule = NO ACTION
goal_contributions_goal_id_fkey        → goals,   delete_rule = CASCADE
-- debt_entries y tutorial_views: sin ninguna FK
```

En producción **hoy** hay 2 filas en `budget_period_overrides` y 22 en
`debt_entries` (`list_tables`), es decir el caso que rompe no es hipotético.

**Por qué bloquea la publicación:** el borrado de cuenta dentro de la app es
requisito obligatorio de Apple (Guideline 5.1.1(v)) y de Google Play. La
política de privacidad va a prometer que el borrado elimina todos los datos del
usuario; hoy esa promesa es falsa en dos sentidos (falla entero para algunos
usuarios, y deja filas atrás para el resto).

**Es exactamente la misma clase de bug ya vivida y documentada** en
`docs/requirements/fase-1/05-auth-sync.md:~270` (`scheduled_payment_occurrences` /
`scheduled_payment_tags` quedaron fuera del RPC al crearse y revertían el
borrado completo). Volvió a pasar con las tablas creadas después.

**Acción:** actualizar `delete_account_data` en **dev y prod** para cubrir las
21 tablas, con las hijas antes que las padres, y re-probar contra una cuenta
real que tenga presupuesto por periodo, meta con montos rápidos, deuda con
entradas y tutoriales vistos. No publicar la política antes de esto.

**Estado al 2026-08-17 — corrección escrita, aplicación sin confirmar.** Existe
`supabase/migrations/20260808000000_delete_account_cascade_missing_tables.sql`
(sin commitear). No se limita a extender la lista de `DELETE`: convierte las
relaciones en `ON DELETE CASCADE` para que una tabla hija desaparezca con su
padre aunque alguien olvide tocar la función — que es la clase de bug que ya
reincidió cuatro veces. Cubre las cinco tablas del cuadro de arriba.

El bloqueante **sigue abierto** hasta que se confirmen dos cosas que no se
pueden leer en el repo:
`[VERIFICAR: que la migración esté efectivamente aplicada en Supabase dev Y prod — comprobar con pg_get_functiondef sobre delete_account_data y con information_schema.referential_constraints que las cinco FK quedaron en CASCADE]`
`[VERIFICAR: re-prueba del borrado de cuenta con un usuario real que tenga presupuesto por periodo, meta con montos rápidos, deuda con entradas y tutoriales vistos]`

Mientras eso no esté confirmado, el ⛔ del punto 3 de `declaraciones-tiendas.md`
§0 se mantiene.

### B2 — ALTO: el número de cuenta bancaria sobrevive al borrado de cuenta y al borrado local

`AccountNumberLocalDatasource`
(`lib/features/accounts/data/datasources/account_number_local_datasource.dart:16`)
guarda el número de cuenta completo en Keychain/Keystore con la clave
`account_number_<accountId>`. `SecureStorageService`
(`lib/core/security/secure_storage_service.dart`) **no expone `deleteAll`**, y
`LocalDataWipeDatasource.wipeAll()`
(`lib/features/auth/data/datasources/local_data_wipe_datasource.dart:44`) solo
llama a `_powerSync.disconnectAndClear()`.

Resultado: si el usuario elige "Borrar también los datos de este dispositivo",
sus números de cuenta bancaria **quedan en el llavero del sistema**, sin
ninguna fila que los referencie. Solo se borran uno a uno al eliminar cada
cuenta bancaria desde la UI
(`lib/features/accounts/data/repositories/account_repository_impl.dart:179`).

**Acción:** borrar las claves `account_number_*` dentro del wipe local. Mientras
no se haga, la política **no puede** decir que el borrado local elimina todo.
El texto redactado hoy dice la verdad actual y quedará desactualizado (a mejor)
cuando se corrija.

### B3 — PARCIAL: Sentry está activo en producción sin consentimiento ni forma de desactivarlo

> **Estado: mitigado a medias (2026-08-08).** La parte de "sin ningún filtro de
> PII" quedó cerrada: existe `lib/core/crash/sentry_redaction.dart`, cableado
> como `beforeSend` en `applySentryOptions` junto con `sendDefaultPii = false`,
> que limpia los valores de fila del texto libre (mensajes de excepción,
> mensaje del evento y breadcrumbs) **antes de que el evento salga del
> dispositivo**. El módulo documenta explícitamente qué **no** cubre.
>
> **Sigue abierto:** no hay consentimiento previo ni un ajuste que permita
> apagarlo. Eso es lo que resta de este hallazgo.


- Se activa en el arranque si hay DSN (`lib/core/bootstrap.dart:46-52`), y el
  DSN **está poblado en producción** (`.env.prod`, host `ingest.us.sentry.io`).
- `applySentryOptions` (`lib/core/crash/sentry_crash_reporter.dart:89-97`) **no
  define `beforeSend`**: no hay ningún scrubbing **del lado del cliente**. (Sí
  hay scrubbing del lado del servidor desde el 2026-08-08 — ver §4.3 —, pero eso
  limpia el dato **al recibirlo**, no evita que salga del dispositivo. Un
  `beforeSend` está en implementación; hasta que exista, este hallazgo sigue
  abierto.)
- El conector de sync manda a Sentry el mensaje crudo de errores de Postgres
  (`lib/features/auth/data/datasources/powersync_connector.dart:142-147,
  181-189, 212-218`). Un `PostgrestException` puede traer en `details`/`hint`
  valores de la fila rechazada — es decir, potencialmente montos, notas o
  nombres de contraparte.
- No existe ninguna pantalla ni ajuste que lo apague.

**Acción recomendada (no bloqueante para publicar, sí para cumplir bien):**
~~añadir un `beforeSend`~~ — ✅ hecho, ver el recuadro de estado arriba. Lo que
queda es ofrecer un interruptor al usuario.

- ✅ **Hecho (2026-08-08):** *Prevent Storing of IP Addresses* + *Require Data
  Scrubber* + *Require Using Default Scrubbers* activos en la organización de
  Sentry (§4.3).
- ⏳ **Escrito, no publicado (2026-08-17):** el `beforeSend` **ya existe en el
  working tree**. `lib/core/crash/sentry_crash_reporter.dart` ahora fija
  `sendDefaultPii = false` explícito y `beforeSend = (event, hint) =>
  redactSentryEvent(event)`, y `lib/core/crash/sentry_redaction.dart` (nuevo, con
  tests en `test/core/crash/`) recorta del texto libre del evento los valores de
  fila que meten Postgres (`Key (...)=(...)`, `Failing row contains (...)`) y
  `sqlite3` (`, parameters: ...`), más los literales entre comillas simples.
  Su propio doc de módulo enumera lo que **no** cubre (valores interpolados en
  prosa sin comillas, `contexts`/`extra`, stack frames, crashes nativos).
  **Nada de esto está commiteado ni publicado**, así que §5.3 de la política
  sigue diciendo la verdad de hoy ("estamos trabajando para que ese filtrado
  también ocurra en la app"). La reescritura de ese párrafo se hace **cuando el
  cambio esté en la versión publicada**, no antes — ver el recuadro de abajo.

> **Frase que se podrá reforzar cuando el `beforeSend` esté en release.** Hoy
> §5.3 de la política dice: *"Ese filtrado ocurre en los servidores de Sentry, al
> recibir el reporte […] Estamos trabajando para que ese filtrado también ocurra
> en la app, antes de que el reporte salga del dispositivo."* Con el `beforeSend`
> desplegado, ese párrafo pasa a poder afirmar que los datos sensibles se
> **redactan en el dispositivo antes de enviarse**, y el bullet de "lo que no
> podemos garantizar al 100%" sobre los mensajes crudos de Postgres se puede
> acotar al caso residual. **No modificar esa redacción antes de que el cambio
> esté efectivamente en la versión publicada.**

### B4 — MEDIO: falta `PrivacyInfo.xcprivacy` en el target de iOS

`find ios -name "*.xcprivacy"` no devuelve ningún manifiesto propio del target
`Runner`. Apple lo exige cuando la app usa APIs de "required reason" —
`path_provider`, `sqlite3_flutter_libs` y `file_picker` acceden a disco y a
timestamps de archivo, que caen en esa categoría. Los pods traen el suyo, pero
el target de la app no.

**Acción:** crear `ios/Runner/PrivacyInfo.xcprivacy` declarando
`NSPrivacyAccessedAPICategoryFileTimestamp` (razón `C617.1`) y
`NSPrivacyAccessedAPICategoryUserDefaults` (razón `CA92.1`, por
`shared_preferences`), `NSPrivacyTracking = false` y `NSPrivacyCollectedDataTypes`
coherente con `declaraciones-tiendas.md`.
`[VERIFICAR: confirmar las razones exactas contra la documentación vigente de Apple al momento del envío]`

### B5 — BAJO: no hay enlace a la política de privacidad dentro de la app

`grep -rn "https://" --include=*.dart lib/` devuelve **una sola** coincidencia,
y es un comentario (`lib/core/config/env.dart:5`). No existe pantalla "Acerca
de" ni fila de "Privacidad" en Ajustes
(`lib/features/settings/presentation/pages/settings_page.dart`).

Play lo exige en la consola (no necesariamente in-app) y Apple exige el enlace
en la ficha; pero varios marcos (RGPD, Ley 1581) esperan que el aviso sea
accesible **en el momento de la recolección**, y el onboarding ya afirma cosas
sobre privacidad (`app_es.arb:4296`: *"Tus datos viven en tu teléfono…"*) sin
enlazar a nada.

**Acción recomendada:** añadir en Ajustes → una sección "Legal" con
"Política de privacidad" y "Términos de uso" apuntando a las URLs publicadas.

### B6 — BAJO: los archivos temporales de export no se borran tras compartir

`export_cubit.dart:145,274-276` y `save_copy_cubit.dart:30,82-84` escriben el
CSV/ZIP/JSON en `getTemporaryDirectory()` y solo limpian el estado del cubit.
Los archivos —que contienen el historial financiero completo en claro— quedan
en el sandbox temporal hasta que el sistema operativo los purgue.

Está dentro del sandbox de la app, así que no es una fuga hacia otras apps. Se
declara tal cual en la política; conviene borrarlos igual.

---

## 1. Qué datos existen y dónde viven

### 1.1 Fuente de verdad: SQLite local (Drift)

`lib/core/database/app_database.dart`, `schemaVersion` **28** al 2026-08-17 (el
`@DriftDatabase` está en `:844`). **20 tablas** —el mismo número que en la
auditoría original: v27 y v28 añadieron columnas, no tablas—, todas con el mixin
`_SyncColumns` (`:129-181`):
`id` (UUID texto), `createdAt`, `updatedAt` (epoch ms), `deletedAt`,
`tombstonedAt`, `userId` (nullable — nulo mientras no haya sesión).

| # | Tabla (línea) | Datos personales o financieros |
|---|---|---|
| 1 | `Accounts` (:192) | `name`, `type`, `currency`, `initialBalanceMinor`, **`institution`** (:212, nombre del banco), **`last4`** (:215), `interestRateBps`, `creditLimitMinor`, `statementDay`, `paymentDueDay`, `archived`, `icon`, `color` |
| 2 | `Categories` (:243) | `name` (texto libre), `kind`, `parentId`, `icon`, `color` |
| 3 | `Transactions` (:263) | `accountId`, `categoryId`, **`amountMinor`**, `currency`, `type`, **`date`**, **`note`** (:274, texto libre), `source`, `transferAccountId`, `goalId`, `debtId`, `countsInBudget` |
| 4 | `Budgets` (:312) | `name`, `amountMinor`, `currency`, `period`, fechas, `alertThresholdPct`, `rollover` |
| 5 | `Goals` (:352) | `name` (meta de ahorro, texto libre), `targetMinor`, `currency`, `accountId`, `targetDate`, `completedAt` |
| 6 | `GoalContributions` (:391) | `goalId`, `amountMinor`, `direction`, `date`, **`note`** (:412) |
| 7 | `Debts` (:416) | `name`, `direction`, `principalMinor`, `currency`, `interestRateBps`, **`counterparty`** (:426, **nombre de un tercero identificable**), `dueDate`, `startDate`, `closedAt` |
| 8 | `DebtEntries` (:484) | `debtId`, `kind`, `amountMinor`, `entryDate`, **`note`** (:493) |
| 9 | `ScheduledPayments` (:502) | cuenta, categoría, `amountMinor`, `currency`, `type`, **`note`** (:508), frecuencia, fechas, `debtId`, **`goalId`** (:550, **nuevo en v28**: enlaza la plantilla con una meta cuando es un aporte recurrente — es una FK interna, no un dato personal nuevo) |
| 10 | `ScheduledPaymentOccurrences` (:656) | fecha, `status`, `snoozedToDate`, `generatedTransactionId` |
| 11 | `GoalQuickAmounts` (:568) | `goalId`, `amountMinor` |
| 12 | `Tags` (:576) | `name` (etiqueta libre), `color` |
| 13-14 | `TransactionTags` (:618), `ScheduledPaymentTags` (:632) | solo relaciones |
| 15 | `ImportBatches` (:592) | **`fileName`** (:594, nombre del archivo del usuario), `templateName`, `importedAt`, conteos |
| 16-18 | `BudgetAccounts` (:687), `BudgetCategories` (:700), `BudgetPeriodOverrides` (:724) | relaciones y montos |
| 19 | `AppSettings` (:750) | preferencias (`zeroBasedEnabled`, `onboardingCompleted`, `featuredBudgetId`, **`quickAccessOrder`** :810 — **nueva en v27**: el orden de los accesos rápidos de Inicio, texto separado por comas tipo `scheduledPayments,debts,reports`) — no personales, pero **sincronizan**, así que entran en "Other actions" / "Product Interaction" igual que el resto de preferencias |
| 20 | `TutorialViews` (:835) | clave del tutorial visto — uso local mínimo |

**Ubicación física:** `getApplicationDocumentsDirectory()`
(`lib/core/database/database_connection.dart:34`), dentro del sandbox de la app.

> **Revisión de vigencia de las dos columnas nuevas (2026-08-17).** Ninguna
> obliga a cambiar una declaración de tienda: `ScheduledPayments.goalId` es una
> clave foránea interna (no describe a una persona) y `AppSettings.quickAccessOrder`
> es una preferencia de UI del mismo tipo que las ya declaradas. Sí obligan a un
> ajuste menor de redacción en `politica-de-privacidad.md` §4.1, donde la fila
> "Preferencias" ahora nombra también el orden de los accesos rápidos: la
> política enumera lo que se guarda, y esa enumeración tiene que ser completa.
> **Recordatorio operativo, no legal:** las dos columnas exigen paridad en
> Postgres (`ALTER TABLE` en dev **y** prod) o el sync entra en cuarentena con
> `PGRST204`.

### 1.2 Llavero del sistema (`flutter_secure_storage`)

**Se guarda exactamente una cosa: el número de cuenta bancaria completo.**

`lib/features/accounts/data/datasources/account_number_local_datasource.dart:6-11`
— *"The only place in the app that touches a full account number (HU-03). The
number lives exclusively in the device's Keychain/Keystore, keyed by the account
id. It is never written to Drift (`accountNumberEnc` stays NULL) and therefore
never reaches Supabase/PowerSync"*.

- Clave: `account_number_<accountId>` (`:16,21`).
- iOS: `KeychainAccessibility.first_unlock_this_device`
  (`lib/core/di/register_module.dart:36-40`) — el comentario dice explícitamente
  *"never backed up to iCloud"*. Android: Keystore.
- La columna `accountNumberEnc` fue **eliminada del esquema** por muerta:
  `lib/core/database/app_database.dart:951`.
- Confirmado que tampoco sale en exportaciones:
  `docs/requirements/fase-1/11-import-export.md:61`.

### 1.3 Preferencias del dispositivo (`shared_preferences`)

Tema claro/oscuro (decisión de `docs/requirements/fase-1/14-apariencia.md`) y la sesión
de Supabase, que `supabase_flutter` persiste por su cuenta
(`lib/features/auth/data/repositories/auth_repository_impl.dart:79-89`).

### 1.4 Cuarentena de sync

`lib/core/sync/data/models/quarantined_operation_dto.dart:19` guarda el
**payload completo de la fila** rechazada, en JSON plano, bajo
`<app documents>/sync/`. Contiene los mismos datos financieros que la fila
original.

---

## 2. Qué sale del dispositivo, cuándo y hacia dónde

### 2.1 Antes de iniciar sesión — sí hay tráfico, contra la intuición local-first

Tres flujos salen del dispositivo sin que exista ninguna cuenta:

1. **Catálogo de categorías semilla (bloqueante en el primer arranque).**
   `lib/core/bootstrap.dart:135` → `SeedDefaultCategories` →
   `lib/features/categories/data/datasources/category_seeds_remote_datasource.dart:47`
   `await _supabase.from('category_seeds').select()`. El comentario en `:22-26`
   confirma que la política RLS es pública (`anon`) precisamente porque *"seeding
   happens before the user ever logs in"*.
   Es una **lectura**, no sube datos del usuario — pero implica una conexión a
   Supabase con la anon key, así que **la IP y los metadatos de red del
   dispositivo llegan al servidor desde el primer segundo**.
   Si falla, la app **se bloquea** con `FirstLaunchOfflineGate`
   (`lib/core/bootstrap.dart:160-164`): **la app no es usable sin conexión en su
   primerísimo arranque**. Es la excepción documentada al "funciona sin
   conexión" (`docs/requirements/fase-1/05-auth-sync.md:273`).
2. **Sentry**, si hay DSN — ver §4.3.
3. **Refresh de token** de Supabase si ya existía una sesión persistida en disco.

**Ninguna fila financiera sale antes del login.** La subida solo ocurre por
`PowerSyncConnector.uploadData`
(`lib/features/auth/data/datasources/powersync_connector.dart:101`), que exige
conexión establecida, y el estampado de dueño exige sesión
(`lib/core/sync/data/datasources/supabase_operation_uploader.dart:43-46`). El
conector sin sesión devuelve credenciales nulas a propósito (`:50-63`:
*"Not signed in: HU-01, local-first, no error — just nothing to sync"*).

### 2.2 Al iniciar sesión — el sync arranca solo, sin interruptor

**No existe ningún ajuste `syncEnabled`.** El sync está atado 1:1 a la sesión;
el único control del usuario es iniciar o cerrar sesión.

`_connectPowerSync()`
(`lib/features/auth/data/repositories/auth_repository_impl.dart:237-242`) se
llama desde tres sitios:
- `:94` `_restoreSession()`, **en el constructor del repositorio** — o sea, en
  el arranque, si `supabase_flutter` restauró un token de disco. Reconecta sin
  intervención del usuario.
- `:117,123` en cambios de estado de auth.
- `:222` tras `signInWithIdToken`.

**El momento clave para la política:** al iniciar sesión por primera vez,
`mergeLocalData()` reclama las filas locales sin dueño y **sube todo el
historial creado antes del login** (HU-04,
`docs/requirements/fase-1/05-auth-sync.md:38`). El usuario tiene que entenderlo antes
de tocar el botón.

### 2.3 Tablas que se sincronizan

`lib/core/database/powersync_schema.dart:46-284` — **20 tablas**, las mismas de
§1.1, con columnas comunes `created_at`, `updated_at`, `deleted_at`,
`tombstoned_at`, `user_id` (`:37-43`). El proyecto de producción tiene 21 tablas
(`list_tables`), incluida `category_seeds`, que es catálogo compartido, no dato
de usuario.

**Los datos "borrados" se sincronizan igual y persisten en Postgres.**
`docs/requirements/fase-1/05-auth-sync.md:61`: las sync rules **no filtran**
`tombstonedAt` ni `deletedAt`. Y el mismo documento reconoce que *"las filas en
papelera no se purgan nunca"* y que el cron de limpieza de lápidas (decisión #2)
**no está implementado**.

### 2.4 Endpoints salientes — lista completa

No hay `Dio`, ni `http.get/post`, ni ninguna `Uri.parse('http…')` en `lib/`. El
paquete `http` está declarado solo por el tipo `ClientException`
(`pubspec.yaml:112-119`). La superficie completa es:

| # | Destino | Origen en código |
|---|---|---|
| 1 | Supabase Auth (`signInWithIdToken`, refresh) | `auth_repository_impl.dart:189` |
| 2 | PowerSync sync stream | `powersync_connector.dart:72-76` |
| 3 | PostgREST (upsert/update/delete de las tablas) | `supabase_operation_uploader.dart:16-27` |
| 4 | `SELECT` sobre `category_seeds` (**anónimo, pre-login**) | `category_seeds_remote_datasource.dart:47` |
| 5 | `SELECT id` sobre `categories` (merge post-login) | `seed_category_ownership_remote_datasource.dart:40-44` |
| 6 | Edge Function `delete-account` | `auth_repository_impl.dart:378` |
| 7 | Sentry ingest (`ingest.us.sentry.io`) | `bootstrap.dart:46-52` |
| 8 | Google / Apple (identidad) | `google_auth_datasource.dart`, `apple_auth_datasource.dart` |

**Solo existe una Edge Function** en todo el proyecto: `delete-account`
(confirmado con `list_edge_functions` contra producción).

---

## 3. Autenticación

Solo social. `lib/features/auth/domain/entities/auth_user.dart:8` es explícito:
*"no password, no phone number — auth is social-only"*.

### Google (`google_auth_datasource.dart`)
- **No pide scopes explícitos** (`:62` llama `authenticate()` sin `scopes:`) →
  solo los de OpenID por defecto: `openid`, `email`, `profile`. Nonce SHA-256
  por intento (`:37,:59`).
- Devuelve y se mapea (`:65-72`): `id` (sub), `displayName`, `email`,
  `photoUrl` → `avatarUrl`, `idToken`.

### Apple (`apple_auth_datasource.dart`)
- Scopes explícitos: `fullName` y `email` (`:23-26`).
- Devuelve (`:31-36`): `userIdentifier`, nombre concatenado, `email`,
  `identityToken`. **Sin foto.** Apple solo entrega nombre y correo en la
  **primera** autorización (`:16`).
- Soporta el relay `@privaterelay.appleid.com` ("Ocultar mi correo"); el riesgo
  de cuenta fragmentada está documentado en
  `docs/requirements/fase-1/05-auth-sync.md:92`.

### Qué se persiste realmente

| Dato | Drift local | Supabase | Llavero | Solo memoria |
|---|---|---|---|---|
| `id` de usuario (UUID) | Sí, como `_SyncColumns.userId` (`app_database.dart:181`) en las 20 tablas | Sí (`auth.users` + `user_id`) | No | — |
| Correo | **No** | Sí (`auth.users.email`, gestionado por Supabase) | No | Sí |
| Nombre | **No** | Sí (`user_metadata`) | No | Sí |
| Foto | **No** | Sí (`user_metadata.avatar_url`) | No | Sí, pero **nunca se descarga ni se muestra** |
| Token de sesión | No | — | No (`flutter_secure_storage`) | `supabase_flutter` lo persiste en SharedPreferences |

**No existe ninguna tabla Drift de usuario.** Verificado: `AuthUser` no se
serializa a Drift en ningún punto.

**Qué se muestra en la UI:** el nombre, en dos sitios
(`settings_session_card.dart:64` y `home_header.dart:57`, saludo por nombre de
pila) y las **iniciales** dibujadas localmente (`settings_session_card.dart:25-28`).
El correo **no** se muestra. La **foto no se descarga nunca**: no hay ningún
`Image.network`/`NetworkImage` que consuma `avatarUrl`.

> Recomendación: si no se usa la foto, dejar de mapearla
> (`auth_repository_impl.dart:141,218`) reduce lo que hay que declarar.

---

## 4. Terceros — activos vs. planeados

### 4.1 Activos y en el binario

| Tercero | Paquete | Rol | Evidencia |
|---|---|---|---|
| Supabase | `supabase_flutter: ^2.5.6` | Auth + base de datos en la nube + Edge Function | `bootstrap.dart:103` |
| PowerSync (JourneyApps) | `powersync: ^2.3.1` | Servicio de sincronización | `powersync_connector.dart:72` |
| Sentry | `sentry_flutter: ^9.24.0` | Reporte de errores | `bootstrap.dart:46` |
| Google | `google_sign_in: ^7.2.0` | Inicio de sesión | `google_auth_datasource.dart` |
| Apple | `sign_in_with_apple: ^7.0.1` | Inicio de sesión (solo iOS) | `apple_auth_datasource.dart` |

### 4.2 Deliberadamente NO enviados (comentados en `pubspec.yaml`)

`pubspec.yaml:71-87` — comentados con su justificación escrita:

- `google_mobile_ads: ^5.1.0` — **anuncios: no están en el binario.** El
  comentario del repo dice que se dejan fuera porque *"sus plugins inyectan
  permisos y frameworks en el build fusionado que las tiendas detectan y
  preguntan (BILLING de Play Billing, AD_ID de AdMob)"*.
- `purchases_flutter: ^10.4.1` — RevenueCat / suscripciones: no está.
- `speech_to_text`, `google_mlkit_text_recognition` — captura por voz y OCR: no
  están. *"arrastran declaraciones de privacidad (micrófono, cámara) que todavía
  no hay qué justificar"*.

**Confirmado en el manifiesto fusionado real**, no solo en el pubspec: el
merged manifest de la app
(`build/app/intermediates/merged_manifest/devDebug/processDevDebugMainManifest/AndroidManifest.xml`)
contiene exactamente `INTERNET`, `USE_BIOMETRIC`, `USE_FINGERPRINT`,
`REORDER_TASKS` y un permiso de receiver dinámico. **No aparece
`com.google.android.gms.permission.AD_ID`** — prueba directa de que no hay SDK
publicitario.

### 4.3 Sentry — configuración exacta

`lib/core/crash/sentry_crash_reporter.dart:89-97`:

```dart
options
  ..dsn = Env.sentryDsn
  ..environment = Env.environment
  ..debug = Env.isDev
  ..tracesSampleRate = Env.isProduction ? 0.2 : 1.0
  ..enableAutoSessionTracking = true;
```

- **Región: Estados Unidos, confirmado.** El DSN de `.env.prod` usa el host
  `ingest.us.sentry.io`, y `sentry.properties` contiene un token cuyo payload
  incluye `"region_url":"https://us.sentry.io","org":"camilo-agudelo"`.
- **`sendDefaultPii` no se configura** → queda en el default del SDK (`false`),
  o sea el SDK no adjunta IP ni usuario automáticamente. Eso es el cliente; el
  **servidor** de Sentry podía registrar la IP de origen del evento — ver el
  punto siguiente, que ya lo cierra.
- **Data scrubbing de organización: ACTIVO.** ✅ Cerrado el 2026-08-08, confirmado
  por el usuario en Sentry → Settings → Security & Privacy (org
  `camilo-agudelo`). Los tres ajustes están encendidos:
  - *Require Data Scrubber* — filtrado del lado del servidor exigido en todos los
    proyectos de la organización.
  - *Require Using Default Scrubbers* — elimina contraseñas, números de tarjeta y
    patrones equivalentes.
  - *Prevent Storing of IP Addresses* — no se almacenan direcciones IP.

  **Dos precisiones que la redacción pública no puede perder** (son la diferencia
  entre una afirmación exacta y una falsa):
  1. Según la propia descripción del ajuste en Sentry, el bloqueo de IPs aplica
     **solo a eventos nuevos**. Los eventos ya almacenados conservan la IP hasta
     que expire la retención de 30 días. La política **no puede** decir que nunca
     se han almacenado IPs.
  2. El scrubbing es **del lado del servidor**: el dato sale igual del dispositivo
     y llega a Sentry, y se limpia al recibirlo. No equivale a no enviarlo. Ver
     el hallazgo B3 — cuando exista el `beforeSend` en la app, la afirmación se
     podrá reforzar a "se redacta antes de salir del teléfono", y no antes.
- **Retención: 30 días.** ✅ Cerrado el 2026-08-08. La cuenta está en el plan
  **Developer (gratuito)**, cuya retención de eventos es de **30 días**. La
  retención es un atributo del plan, no un ajuste configurable — por eso no
  aparece en Security & Privacy. Los **90 días** que se decían antes son el tope
  de los planes **Team/Business**, no un default universal; Enterprise es
  personalizada. Declarar 90 habría prometido conservar los datos más tiempo del
  que realmente se conservan.

  > **Pendiente de mantenimiento, no un `[VERIFICAR]`:** el valor depende del
  > plan. Si la cuenta sube alguna vez a Team, Business o Enterprise, hay que
  > corregir §5.3 y §9 de `politica-de-privacidad.md` y la nota de
  > `declaraciones-tiendas.md`.
- **`beforeSend` no existe.** Cero scrubbing propio.
- **`setUser` / `clearUser` existen** (`:76-84`) **pero no tienen ningún call
  site en `lib/`** — hoy los eventos de Sentry no llevan el UUID del usuario.
- `attachScreenshot` y `attachViewHierarchy` no se activan (defaults `false`).
- Errores: 100%. Trazas de rendimiento: 20% en producción.
- **Sin DSN, es un no-op**: `NoopCrashReporter`
  (`lib/core/di/register_module.dart:45-46`).

> **Nota de seguridad, fuera del alcance legal:** `sentry.properties` contiene
> un auth token de Sentry en claro. Está en `.gitignore:43`, pero sigue en
> disco. `[VERIFICAR: rotarlo si alguna vez estuvo versionado]`

### 4.5 Dónde se aloja cada proveedor

Verificado fuera del repo (el código solo trae los endpoints; el país sale de
resolver esos hosts y de la configuración de la organización).

| Proveedor | País | Cómo se confirmó |
|---|---|---|
| Sentry | **Estados Unidos** | La organización `camilo-agudelo` reporta `regionUrl: https://us.sentry.io`; el DSN de `.env.prod` apunta a `ingest.us.sentry.io` |
| PowerSync | **Estados Unidos** | La instancia de producción (`6a5a48fa7f33bac37ef7a745.powersync.journeyapps.com`) resuelve a `107.21.156.74` y `184.73.222.43`; whois: `NetName: AMAZON-EC2-8`, `Country: US` |
| Supabase | **Estados Unidos** | El endpoint de producción responde desde un bloque IPv6 `2600:1f14:…` de AWS asignado en Norteamérica |

**Precisión deliberada:** se afirma el **país**, no la región de AWS. Inferir
`us-east-1` (o cualquier otra) a partir de un rango de IP no es evidencia
suficiente para un documento vinculante, y para una transferencia internacional
lo jurídicamente relevante es el país de destino, no el datacenter. Por eso la
política de privacidad dice "Estados Unidos" y punto. Los tres puntos anteriores
cierran los `[VERIFICAR]` de región que estaban abiertos.

### 4.4 Ausencias verificadas

- **Analítica de producto: ninguna.** Sin `firebase_analytics`, `amplitude`,
  `posthog`, `mixpanel`. Sin `google-services.json` ni `GoogleService-Info.plist`.
- **Notificaciones push: ninguna.** Sin `firebase_messaging`,
  `flutter_local_notifications`, sin `UIBackgroundModes`.
- **Publicidad: ninguna.** Ver §4.2.
- **Rastreo entre apps / IDFA: ninguno.** No hay
  `NSUserTrackingUsageDescription` en `Info.plist` → la app nunca muestra el
  prompt de ATT.

---

## 5. Permisos del sistema

### Android
- `android/app/src/main/AndroidManifest.xml` — **cero `uses-permission`**
  declarados por la app. Solo un bloque `<queries>` con `PROCESS_TEXT` (`:39-44`),
  que es boilerplate del engine de Flutter.
- `debug` y `profile` declaran `INTERNET` explícitamente (`:6` en ambos).
- En el manifiesto **fusionado** (release incluido) entran, vía los plugins:
  `INTERNET`, `USE_BIOMETRIC` + `USE_FINGERPRINT` (de `flutter_secure_storage`),
  `REORDER_TASKS` (de `google_sign_in`) y el permiso de receiver dinámico.

> Recomendación menor: declarar `INTERNET` explícitamente en el manifiesto
> principal para que manifiesto y política digan lo mismo sin depender del merger.

### iOS
- `ios/Runner/Info.plist` **no contiene ni un solo `NS*UsageDescription`**
  (verificado sobre el archivo completo). Sin cámara, micrófono, ubicación,
  contactos, fotos ni seguimiento.
- Sí contiene `GIDClientID` y el `CFBundleURLTypes` con el reversed client id de
  Google Sign-In (`:73-85`) — identificadores de la app, no del usuario.
- Sin `NSAppTransportSecurity` → ATS por defecto, HTTPS obligatorio.
- **Falta `PrivacyInfo.xcprivacy`** — ver B4.

---

## 6. Import / Export

Ruta UI: **Más → Importar y exportar** (`app_router.dart:176`; etiqueta
`"Importar y exportar"` / *"Guarda una copia o trae tus datos"*,
`app_es.arb:1557,1559`).

- **Lectura de archivos:** `file_picker` (SAF en Android, UIDocumentPicker en
  iOS) — `import_flow_cubit.dart:81-84` (`allowedExtensions: ['csv']`),
  `restore_cubit.dart:28-31` (`['json']`). El usuario elige el archivo; la app
  no navega el sistema de archivos por su cuenta.
- **Entrega de archivos:** **share sheet nativo**, nunca escritura directa a
  Descargas o galería. `export_cubit.dart:263-273` lo dice literal: *"HU-01:
  'sin pedir permisos de almacenamiento donde el share nativo baste'"*.
- **Permisos requeridos: ninguno.** Confirmado en §5.
- **Temporales:** `getTemporaryDirectory()` — `export_cubit.dart:145`,
  `save_copy_cubit.dart:30,34`, `chart_export.dart:48`. No se borran (B6).
- **Contenido de una copia completa** (`backup_json_datasource.dart:27-46`):
  **19 tablas**, incluyendo filas en papelera y lápidas (`:81-84`). Cabecera con
  `formatVersion`, `schemaVersion`, `appVersion`, `createdAt` (`:105-109`).
- **CSV de transacciones** (`csv_vocabulary.dart:13-27`): incluye la **nota de
  texto libre**.
- **CSV de cuentas** (`:30-45`): incluye **institución** y **`last4`**. **No**
  incluye el número de cuenta completo (`docs/requirements/fase-1/11-import-export.md:61`).
- **Log técnico de sync** compartible como texto
  (`sync_log_sheet.dart:40-52,60-70`). El propio texto de la app promete
  (`app_es.arb:3499`): *"El registro no incluye montos ni los nombres de tus
  movimientos: solo fechas, códigos y reintentos."*

---

## 7. Borrado de cuenta — camino en la UI y comportamiento

### Camino exacto (literal, como lo ve el usuario)

Ruta técnica: `/mas` → `/mas/ajustes` → hojas → `/mas/cuenta-eliminada`
(`app_router.dart:154,162,168,1016`).

1. Barra de pestañas → **"Más"** (`app_es.arb:1075`).
2. Fila **"Ajustes"**, sublabel *"Preferencias y tu cuenta"* (`app_es.arb:1561,1563`).
3. Pantalla **"Ajustes"**. Al final del scroll, bloque en rojo con icono de
   papelera: **"Eliminar cuenta"**
   (`settings_page.dart:135,157` → `app_es.arb:1732`).
4. **Paso 1** — hoja **"Eliminar tu cuenta"** (`confirm_delete_account_sheet.dart:74-75`):
   *"Esta acción es irreversible. Se borrarán para siempre todos tus datos en la
   nube: cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta."*
   (`app_es.arb:1644`). Botones **"Cancelar"** y **"Eliminar cuenta"**.
5. **Paso 2** — hoja **"¿Qué hacemos con tus datos en este teléfono?"**
   (`local_data_choice_sheet.dart:58-87`): **"Conservar mis datos en este
   dispositivo"** vs **"Borrar también los datos de este dispositivo"**, y
   **"Continuar"** (`app_es.arb:1663-1681`).
6. **Paso 3** — pantalla **"Listo, tu cuenta fue eliminada"**, botón **"Ir al
   inicio"** (`app_es.arb:1683,1701`).

**Alcanzable sin haber iniciado sesión**: en ese caso borra solo lo local y lo
dice (`app_es.arb:1664`). Cumple el requisito de Apple/Google de que la opción
exista dentro de la app, sin llamadas ni correos.

### Qué hace en el servidor

`auth_repository_impl.dart:378` → `_supabase.functions.invoke('delete-account')`
→ `supabase/functions/delete-account/index.ts`:
- `verify_jwt: true` y re-validación con `admin.auth.getUser(jwt)` (`:42`) —
  *"never trust a client-supplied user id"* (`:7-9`). El usuario solo puede
  borrarse a sí mismo.
- `admin.rpc('delete_account_data', {p_user_id})` (`:51`) — atómico.
- `admin.auth.admin.deleteUser(userId)` (`:61`) — **sí borra la fila de
  `auth.users`**, no solo los datos.

**Es un borrado real y síncrono, no un borrado lógico.** Pero ver **B1**: la
cobertura del RPC está incompleta y hoy revierte para algunos usuarios.

### Cerrar sesión ≠ borrar cuenta

`sign_out.dart:6`: *"stops sync on this device without touching local data."*
La hoja de cerrar sesión ofrece un toggle **desmarcado por defecto** —
*"Borrar también los datos de este teléfono"*, con la aclaración *"Tu cuenta en
la nube no se toca: al volver a entrar, los recuperas."* (`app_es.arb:1619,1621`).
Si hay cambios sin subir, avisa (`:1623`).

---

## 8. Menores, edad y consentimiento

**No existe ninguna verificación de edad.** Búsqueda exhaustiva en `lib/`,
`docs/` y los `.arb` de `edad|birth|age|parental|coppa|menor de|13 años|18 años`:
cero coincidencias reales. No hay pantalla de edad, ni gate, ni consentimiento
parental, ni bandera de contenido dirigido a niños.

**Consecuencia:** la app **no** puede declararse dirigida a niños en Play
(Families) ni en App Store, y la edad mínima sólo puede ser **contractual**, no
verificada. **Decisión confirmada: 16 años.** Está reflejada en
`terminos-de-uso.md` §4 (edad mínima + autorización parental entre los 16 y la
mayoría de edad), en `politica-de-privacidad.md` §16 y en
`declaraciones-tiendas.md` §1.1 (grupos 16-17 y 18+) y §2.3 (clasificación 16+).

Queda un flanco derivado, no de código: marcar el grupo **16-17** en Play
significa declarar menores en la audiencia, y la ayuda de Play no aclara si eso
activa por sí solo los requisitos de la Política de Familias. Hoy la exigencia
que suele morder —SDK de anuncios autocertificados— es inaplicable porque no hay
publicidad en el binario.
`[VERIFICAR: si marcar 16-17 en Play activa los requisitos de Families Policy]`

---

## 9. Onboarding y ajustes — qué se pide

Onboarding, 4 pantallas (`lib/features/onboarding/`):
1. Bienvenida — *"Tus datos viven en tu teléfono. El respaldo en la nube es
   opcional."* (`app_es.arb:4296`).
2. Primera cuenta — nombre, tipo, moneda, institución y saldo inicial. **Omitible**
   (*"Omitir por ahora"*, `:4314`).
3. Respaldo — ofrece iniciar sesión; **"Activar respaldo"** / **"Después"**
   (`:4322,4324`).
4. Cierre.

- **No se pide el nombre del usuario, ni correo, ni teléfono, ni país, ni edad.**
- La moneda se deriva del locale del dispositivo
  (`resolve_default_currency_for_locale.dart`), no de la ubicación física.
- Ajustes solo tiene preferencias: apariencia, moneda (hoy "Próximamente"),
  modo sobres, presupuesto destacado, mostrar ayuda.

---

## 10. Features NO implementadas (no declarar como existentes)

`lib/features/capture/` y `lib/features/improvement/` **están vacías** (0
archivos). Confirmado también en `docs/marketing/plan-fichas-de-tienda.md:44-45`.

No existen hoy: IA/coach, captura por voz, OCR de recibos, lectura de
notificaciones bancarias, anuncios, suscripciones, analítica, notificaciones push.

La política los menciona **solo** en la sección "Lo que hoy no hacemos", dejando
claro que no están activos y que su activación exigirá actualizar la política
— nunca como funcionalidad presente.

### 10.2 Fase 2 (captura sin fricción): especificada, NO implementada

El 2026-08-17 se escribieron los requerimientos de Fase 2 —captura por voz
(`docs/requirements/fase-2/17-captura-voz.md`), OCR de recibos
(`18-captura-ocr.md`), lectura de notificaciones bancarias en Android
(`19-notificaciones-bancarias.md`) y widget de captura rápida
(`20-widget-captura-rapida.md`)—. **Especificar no es implementar**, y las
declaraciones vigentes ante Play y App Store se hacen sobre el binario.

Evidencia de que **hoy nada de eso existe en el código** (re-verificado el
2026-08-17, uno por uno):

| Qué exigiría Fase 2 | Estado real hoy | Evidencia |
|---|---|---|
| Código de captura | No existe | `lib/features/capture/` contiene un único archivo: `.gitkeep` (0 bytes) |
| Reconocimiento de voz | No enlazado | `speech_to_text` **comentado** en `pubspec.yaml:86` |
| OCR | No enlazado | `google_mlkit_text_recognition` **comentado** en `pubspec.yaml:87` |
| Permiso de micrófono / cámara / notificaciones (Android) | No declarado | `android/app/src/main/AndroidManifest.xml` no tiene **ni un** `uses-permission`, ni un `<service>` de `NotificationListenerService` |
| Permisos de iOS | No declarados | `ios/Runner/Info.plist` no tiene **ninguna** clave `*UsageDescription` |
| Tablas `PendingCaptures` / `TransactionAttachments` | No existen | El `@DriftDatabase` (`app_database.dart:844`) lista 20 tablas y ninguna es esa |
| Widget de pantalla de inicio | No existe | Sin extensión WidgetKit en `ios/`, sin `AppWidgetProvider` en `android/` |

**Conclusión operativa:** las respuestas de `declaraciones-tiendas.md` §1.2 y
§2.2 (Audio files = No, Photos and videos = No, Messages = No, cero permisos
sensibles) **siguen siendo exactas** y no se tocan. Lo que sí hacía falta era
dejar escrito qué cambia el día que Fase 2 exista: eso está en
[`checklist-fase-2.md`](checklist-fase-2.md) y, resumido campo por campo, en
`declaraciones-tiendas.md` §7.

**Riesgo que este documento deja señalado:** el mayor no es olvidar un permiso,
es publicar con las declaraciones viejas. `docs/requirements/README.md`
("Bloqueante de publicación") y las cuatro HU de privacidad de Fase 2
(`17-captura-voz.md` HU-06/HU-07, `18-captura-ocr.md` HU-09,
`19-notificaciones-bancarias.md` HU-08) apuntan a estos mismos archivos.

---

## 10.1 El responsable es una persona natural — puntos cerrados

**Dato de fondo confirmado por el usuario (8 de agosto de 2026):** billetudo lo
desarrolla y opera una **persona natural** de forma independiente. No existe
razón social, NIT/RUT, domicilio comercial ni sociedad constituida. Esto no se
puede verificar en el código —no es un dato del software— pero es una
declaración del responsable y determina cómo se identifica en los documentos.

**Consecuencia en los entregables:** el responsable se identifica con **nombre
de la persona natural + correo de contacto**, y nada más. Se eliminaron de
`politica-de-privacidad.md` y `terminos-de-uso.md` los campos de razón social,
identificación fiscal, domicilio y país de constitución. **No aplican**; no se
sustituyeron por otra cosa.

### 10.1.1 Registro Nacional de Bases de Datos (RNBD) de la SIC — NO APLICA

**Cerrado. No reabrir.**

El **Decreto 090 de 2018** redujo el universo de obligados a inscribir bases de
datos en el RNBD. Quedan obligadas únicamente:

- las sociedades y entidades sin ánimo de lucro con **activos totales
  superiores a 100.000 UVT**, y
- las personas jurídicas de naturaleza **pública**.

Las **personas naturales quedaron expresamente excluidas** de la obligación.
Como el responsable de billetudo es persona natural, **no debe inscribirse en el
RNBD** y la política no debe prometer una inscripción que no existirá.

Fuentes: [Decreto 90 de 2018 — Gestor Normativo, Función
Pública](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=85039)
· [SIC — Gobierno Nacional reduce universo de
obligados](https://www.sic.gov.co/gobierno-nacional-reduce-universo-de-obligados-a-cumplir-el-registro-de-bases-de-datos-ante-superintendencia-de-industria-y-comercio)

Ojo con lo que **sí** sigue aplicando: no estar obligado al RNBD **no** exime de
la Ley 1581 de 2012. La autorización previa, la finalidad informada, la atención
de consultas y reclamos y el derecho de *habeas data* siguen intactos, y la SIC
sigue siendo la autoridad competente ante un reclamo.

### 10.1.2 Delegado de protección de datos (DPO / encarregado) — NO SE DESIGNA

**Cerrado.** Ninguno de los cuatro marcos obliga a designarlo en este caso:

| Marco | Regla | Por qué no aplica |
|---|---|---|
| **RGPD (UE/España)** | Art. 37: obligatorio para autoridades públicas, observación sistemática a gran escala, o tratamiento a gran escala de categorías especiales del art. 9 | billetudo no es autoridad pública, no perfila ni monitorea de forma sistemática, y los datos financieros del usuario **no** son categoría especial del art. 9 |
| **LGPD (Brasil)** | Art. 41 exige *encarregado*, pero la **Resolución CD/ANPD n.º 2 de 2022** dispensa de indicarlo a los *agentes de tratamento de pequeno porte*, siempre que exista un canal de contacto con el titular | El responsable es una persona natural con un proyecto individual; el canal es camiiloagudelo92@gmail.com. Designarlo sería buena práctica de gobernanza (art. 52 §1º IX), no obligación |
| **Ley 1581 (Colombia)** | Decreto 1377, art. 23: designar un área o persona que atienda consultas y reclamos | La persona natural responsable **es** ese punto de contacto; no hay estructura donde delegar |
| **LFPDPPP (México)** | Art. 30: designar una persona o departamento de datos personales | Igual: el responsable mismo cumple ese rol |

Fuente LGPD: [Resolución CD/ANPD n.º 2 de
2022](https://www.gov.br/anpd/pt-br/acesso-a-informacao/institucional/atos-normativos/regulamentacoes_anpd/resolucao-cd-anpd-no-2-de-27-de-janeiro-de-2022)

`politica-de-privacidad.md` §11 explica esto al usuario en lenguaje llano, en
vez de dejar el tema en silencio.

> **Observación no bloqueante (Brasil).** La misma Resolución CD/ANPD n.º 2 de
> 2022 duplica los plazos de atención al titular para agentes de pequeño porte.
> La política promete hoy **30 días** para Brasil, que es más exigente que el
> mínimo legal aplicable. Se deja así a propósito: prometer menos plazo del que
> la ley permite es cumplir de más, no de menos. Si alguna vez el volumen de
> solicitudes lo hiciera inviable, ese número se puede relajar — pero entonces
> hay que actualizar la política, no incumplirla en silencio.

### 10.1.3 Lo que ser persona natural **no** resuelve

Ser persona natural evita el RNBD y el DPO, pero **no** evita que las tiendas
exijan identidad y publiquen datos de contacto. Eso se documenta en detalle en
`declaraciones-tiendas.md` §5, con fuentes. Resumen:

- **Google Play** verifica identidad con documento oficial y una dirección
  legal tomada del perfil de pagos, y **no acepta apartados postales ni
  oficinas virtuales** para cuentas personales. Publica nombre legal, país y
  correo de desarrollador; **si la cuenta monetiza (compras integradas), publica
  la dirección completa**.
- **App Store Connect** usa el **nombre legal** como *seller* para cuentas de
  individuo —no se puede sustituir por una marca, y el *developer name* se fija
  al crear la primera app y no se edita después—. Y si el desarrollador se
  declara *trader* bajo el Reglamento de Servicios Digitales de la UE, Apple
  publica **dirección o apartado postal, teléfono y correo** en la ficha de la
  app en la UE.

Es decir: la decisión de no publicar domicilio en la política es válida, pero
**la exposición del domicilio se decide realmente al elegir monetización y
mercados**, no al redactar la política.

---

## 11. Lista consolidada de `[VERIFICAR: ...]`

Estos son los huecos que bloquean la publicación. Ninguno se puede resolver
leyendo el código.

### Identidad del responsable (obligatorio en los 4 marcos)
1. Juan Camilo Agudelo Franco — es también el nombre público
   del desarrollador en ambas tiendas: Apple no permite otro para cuentas de
   individuo y Play muestra el nombre legal aunque se use un alias
   (`declaraciones-tiendas.md` §5).
2. ✅ Correo de contacto: camiiloagudelo92@gmail.com
3. ✅ **Cerrado — no aplica:** razón social, NIT/RUT/identificación fiscal,
   domicilio o dirección física, y país de constitución. El responsable es una
   **persona natural**, no una empresa (§10.1). Estos campos se eliminaron de
   los documentos; no se sustituyeron.

### Jurisdicción y publicación
4. ✅ **Cerrado: ley aplicable y jurisdicción = Colombia**, confirmado por el
   responsable. Nota: se afirma la **ley aplicable**, no el domicilio ni la
   residencia concreta del titular — eso último no se declara en ningún
   documento y no hace falta. **No se fija ciudad**: los
   términos remiten a "los jueces y tribunales competentes de la República de
   Colombia" y dejan que las reglas de competencia territorial hagan su trabajo.
   Fijar una ciudad habría sido peor: una cláusula de foro exclusivo frente a
   consumidores es de dudosa validez (Estatuto del Consumidor colombiano, RGPD
   art. 79.2, y los estatutos de consumo de México y Brasil), y de todas formas
   la cláusula ya reconoce que el consumidor puede demandar en su domicilio.
5. ✅ URL de la política: https://camiiloaf.github.io/billetudo/
6. ✅ URL de los términos: https://camiiloaf.github.io/billetudo/terminos.html
7. ✅ **Cerrado: fecha de entrada en vigor = 8 de agosto de 2026**, igual que la
   de última actualización. Política y términos pasan a **versión 1.2**.

### Infraestructura (dashboards, no el repo)
8. ✅ **Cerrado: Supabase de producción está en Estados Unidos.** Ver §4.5. Se
   afirma el país; la región exacta de AWS **no** se afirma y no hace falta.
9. ✅ **Cerrado: la instancia PowerSync de producción está en Estados Unidos.**
   Ver §4.5, mismo criterio: país sí, región de AWS no.
10. ✅ **Cerrado: retención de Sentry = 30 días, y data scrubbing activo.** Ver
    §4.3. La cuenta está en el plan **Developer (gratuito)**, cuya retención es
    de 30 días; los 90 días son el tope de Team/Business, no un default. Están
    activos *Require Data Scrubber*, *Require Using Default Scrubbers* y
    *Prevent Storing of IP Addresses*.
    **Recordatorio de mantenimiento:** la retención depende del plan — si sube
    de plan, hay que corregir §5.3 y §9 de la política. Y dos matices que la
    redacción pública debe conservar: el bloqueo de IP aplica solo a eventos
    nuevos, y el scrubbing es del lado del servidor.
11. `[VERIFICAR: retención de los backups automáticos de Supabase (PITR / daily backups) tras un borrado de cuenta]`

### Decisiones de producto
12. ✅ **Cerrado: edad mínima = 16 años.** Ver §8. Deriva un pendiente nuevo, el
    21.
13. ✅ **Cerrado — no aplica: billetudo NO es marca registrada.** El placeholder
    se eliminó y la cláusula de propiedad intelectual de los términos se
    **reescribió**, no se rellenó: ya no se reclaman derechos de marca
    registrada. Lo que sí se conserva es la protección por derecho de autor
    sobre código, diseño e identidad visual, y una prohibición de uso del nombre
    que induzca a confusión —que no depende de tener registro—. **No reabrir
    salvo que se registre la marca**, en cuyo caso hay que volver a tocar ese
    párrafo.
14. `[VERIFICAR: si se ofrecerá algún canal de soporte además del correo]`
15. `[VERIFICAR: decisión sobre monetización vs. exposición del domicilio
    residencial]` — las cuentas de tienda **ya están creadas** como persona
    natural, así que esto ya no es "decidir antes de abrirlas" sino decidir
    antes de activar la primera compra integrada: eso convierte la cuenta de
    Play en *merchant* y hace pública la dirección completa
    (`declaraciones-tiendas.md` §5.1).

### Cumplimiento por país
16. ✅ **Cerrado — no aplica: RNBD de la SIC (Colombia).** El Decreto 090 de 2018
    excluyó a las personas naturales de la obligación de inscribir bases de
    datos. Ver §10.1.1 con fuentes. **No reabrir.**
17. ✅ **Cerrado — no se designa: DPO / encargado / *encarregado*.** Ningún
    marco lo exige en este caso. Ver §10.1.2 con la regla de cada ley.

### Tiendas
18. `[VERIFICAR: cuenta de prueba de Google o Apple para el equipo de revisión]`
    — no bloqueante (la app funciona sin login), pero facilita que el revisor
    valide el borrado de cuenta de la Guideline 5.1.1(v).
19. `[VERIFICAR: declaración de estado de trader en la UE ante Apple]` —
    relevante si se distribuye en España; ver `declaraciones-tiendas.md` §5.2.
20. `[VERIFICAR: si Play Console exige declaración de trader del RSD para
    distribuir en la UE]` — la documentación pública consultada no lo confirma;
    ver `declaraciones-tiendas.md` §5.3.
21. `[VERIFICAR: si marcar el grupo 16-17 en Play activa los requisitos de Families Policy]` —
    **nuevo**, consecuencia de fijar la edad mínima en 16. Ver §8 y
    `declaraciones-tiendas.md` §1.1.

### Identidad del desarrollador — ya no es una decisión
22. ✅ **Cerrado — hecho consumado:** las cuentas de **Google Play** y **App
    Store Connect** ya están creadas, ambas como **persona natural**. El
    *developer name* de Apple quedó fijado con el nombre legal y **no se puede
    editar**. Todo el texto que trataba esto como una decisión previa se
    reescribió en `declaraciones-tiendas.md` §0 y §5.

### Fase 2 — bloqueantes de declaración (abiertos, no resolubles en el código)

Estos **no** afectan a la publicación de hoy: la app no tiene ninguna de esas
capacidades (§10.2). Se listan aquí para que no se pierdan cuando Fase 2 se
implemente. El detalle está en [`checklist-fase-2.md`](checklist-fase-2.md).

23. `[VERIFICAR: qué hace la app cuando el reconocimiento de voz on-device NO está disponible]` —
    **el más urgente de todos.** `17-captura-voz.md` HU-06 lo deja sin decidir.
    Si la app degrada al reconocimiento en la nube del sistema operativo, el
    audio del usuario **sale del dispositivo** hacia Apple o Google aunque no se
    guarde nada. *No guardar no es no transmitir.* Hasta que esa decisión exista,
    **no se puede escribir** ni la sección de voz de la política ni la respuesta
    de "Audio" en Data Safety / App Privacy. Es un bloqueante de declaración,
    no de implementación, y no lo resuelve este documento.
24. `[VERIFICAR: si Play exige una declaración de uso específica —formulario y/o video— para BIND_NOTIFICATION_LISTENER_SERVICE al momento del envío]` —
    la política pública "Permissions and APIs that Access Sensitive Information"
    consultada el 2026-08-17 **no lista** el acceso a notificaciones entre sus
    permisos con formulario de declaración (sí SMS/Call Log, ubicación,
    accesibilidad, VPN, alarmas exactas). No se afirma que no exista: no se
    encontró documentada. Play Protect sí lo trata como señal de alto riesgo
    cuando se combina con SMS o accesibilidad. Hay que revisarlo en la consola
    antes de subir el build.
25. `[VERIFICAR: alcance final de galería en OCR]` — si el flujo termina usando
    el **Photo Picker** de Android no hace falta `READ_MEDIA_IMAGES` ni el
    formulario de permisos de fotos y video de Play; si usa el picker antiguo,
    sí. Determina una respuesta de tienda, así que se decide antes de declarar.
26. `[VERIFICAR: incluir PendingCaptures y TransactionAttachments en delete_account_data, en la misma migración que las crea]` —
    es exactamente el bug B1, que ya reincidió cuatro veces. Con las tablas
    sincronizando, dejarlas fuera del RPC vuelve a hacer falsa la promesa de
    borrado total.

---

## 12. Qué queda fuera de esta auditoría

- La revisión jurídica formal de la redacción.
- Los acuerdos de encargo de tratamiento (DPA) con Supabase, PowerSync y Sentry:
  hay que firmarlos/aceptarlos en cada consola.
  `[VERIFICAR: estado de los DPA con cada proveedor]`
- El contenido exacto de los formularios de tienda al momento del envío: cambian
  seguido. `declaraciones-tiendas.md` documenta el porqué de cada respuesta, así
  que si el formulario cambia se puede recomponer sin re-auditar.

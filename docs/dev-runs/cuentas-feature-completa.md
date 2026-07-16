# Cuentas — feature completa (cuentas-feature-completa)

Fecha: 2026-07-15 · Tamaño: L · Review: deep (con blockers pendientes) · **Nada commiteado**

## Objetivo y criterios de aceptación

Implementar la feature completa de **Cuentas** (Nivel 0, HU-01 a HU-04 y HU-06 a HU-09) sobre el esquema Drift ya existente: dominio con cálculo de saldo/cupo disponible y validaciones, capa de datos sobre `AppDatabase` + `SecureStorageService`, y las 19 pantallas/estados ya aprobados en `billetudo.pen` (claro + oscuro).

- **HU-05** (vista combinada multi-cuenta) queda **fuera** por decisión del propio spec de diseño: pertenece a Transacciones.
- Sin migración de esquema. No se tocó `app_database.dart` (solo se leyó).
- Cierre exigido: `flutter analyze` + `dart run custom_lint` + `flutter test` en verde.

Criterios de aceptación y su cobertura (los 20 en ✅):

| AC | Qué exige | Dónde se verifica |
|---|---|---|
| 1 | HU-04 saldo = inicial + ingresos − gastos + transf. entrantes − salientes, ignorando `deletedAt` | `test/features/accounts/domain/account_balance_test.dart` ("los cuatro signos de movimiento", "ignora los movimientos con deletedAt"); + SQL real en `data/account_repository_impl_test.dart` |
| 2 | HU-02/04 `availableCreditMinor` = límite + saldo, piso 0, `overLimit` + `excessMinor` | `domain/account_balance_test.dart`: cupo libre / deuda igual al cupo (0, aún no sobrecupo) / sobrecupo |
| 3 | HU-02 validación de tarjeta → `Left(ValidationFailure)` con `field` | `domain/usecases/create_account_test.dart` (sin cupo, días nulos, días fuera de 1..31, bordes 1 y 31, campos nulos si no es tarjeta) |
| 4 | HU-01 nombre vacío/>100 y currency != 3 ISO-4217 | `create_account_test.dart`, grupos de nombre y moneda (incluye bordes 1 y 100) |
| 5 | Dinero y tasas enteros ('24,5' → 2450; '0,01' → 1) | `test/core/money_parse_test.dart` + grupo "dinero y tasas enteros" |
| 6 | HU-03 número completo solo en SecureStorage, `accountNumberEnc` NULL | `data/account_repository_impl_test.dart` (Drift en memoria real) |
| 7 | HU-03 `last4` derivado / manual / rechazo no numérico | `create_account_test.dart` (4 tests) |
| 8 | HU-03 PAN de tarjeta prohibido + UI sin número/ojo/copiar | dominio: `create_account_test.dart`; UI: `presentation/pages/account_detail_page_test.dart` |
| 9 | HU-03 revelar efímero + copiar con limpieza a 60s | `account_detail_cubit_test.dart` + `test/core/security/secure_clipboard_test.dart` |
| 10 | HU-06 `updatedAt` sube al editar | `account_repository_impl_test.dart` ("sube updatedAt", "no toca createdAt") |
| 11 | HU-06 cambio de tipo/moneda con confirmación; limpieza al salir de card; exigencias al entrar a card | `update_account_test.dart` + repo test |
| 12 | HU-07 archivar/desarchivar y streams limpios | repo test + `archived_accounts_cubit_test.dart` + `accounts_list_cubit_test.dart` |
| 13 | HU-08 borrado lógico (FK intacto) + borra el número de SecureStorage | `account_repository_impl_test.dart` (3 tests) |
| 14 | HU-08 impacto + bloqueo de última cuenta + hoja con 'Entendido' primario | `delete_account_test.dart`, `get_account_deletion_impact_test.dart`, `cannot_delete_last_account_sheet_test.dart` |
| 15 | HU-09 `sortOrder` contiguo 0..n−1 y listado ordenado | repo test + grupo "reordenar (HU-09)" del cubit |
| 16 | Multi-moneda del Total Card sin suma cruzada | `domain/accounts_overview_test.dart` + `accounts_page_test.dart` |
| 17 | 4 estados de la lista (datos / vacío / carga con 4 Skeleton Row / error) | `presentation/pages/accounts_page_test.dart` |
| 18 | Sin funciones-Widget, sin widgets privados, sin strings literales; paridad .arb | `dart run custom_lint` aparte → limpio; `test/core/l10n/arb_parity_test.dart` |
| 19 | Nivel 0 intacto (sin ads/RevenueCat, sin límite de cuentas) | `test/features/accounts/tier0_test.dart` (4 tests, mutation-probeado) |
| 20 | Los 3 comandos en verde, nada commiteado | ver sección Tests |

## Qué cambió

### Dominio (`lib/features/accounts/domain/`)

| Archivo | Qué |
|---|---|
| `entities/account.dart` | Entidad pura de cuenta. Enums propios (`AccountType`, `CardBalanceView`), sin depender de Drift |
| `entities/account_balance.dart` | **Única** implementación de la regla de saldo/cupo (signos, soft-delete, `overLimit`, `excessMinor`). También `AccountMovement`/`MovementKind` (input de la regla) |
| `entities/account_with_balance.dart` | Cuenta + saldo: es lo que devuelven los streams |
| `entities/accounts_overview.dart` | Subtotales por moneda + deuda de tarjetas. **No expone total cruzado** |
| `entities/account_deletion_impact.dart` | Conteos de transacciones/metas/deudas + `isLastAccount` |
| `entities/account_draft.dart` | Invariante de validación HU-01/02/03 en `validated()`; devuelve draft normalizado o `Left(ValidationFailure)` con `field`. Claves de campo como constantes |
| `repositories/account_repository.dart` | Contrato |
| `usecases/*.dart` (13) | `watch_accounts`, `watch_accounts_overview`, `watch_archived_accounts`, `watch_account_detail`, `create_account`, `update_account`, `archive_account`, `unarchive_account`, `delete_account`, `get_account_deletion_impact`, `reorder_accounts`, `get_account_number`, `set_card_balance_primary` |

### Datos (`lib/features/accounts/data/`)

| Archivo | Qué |
|---|---|
| `datasources/accounts_local_datasource.dart` | Queries Drift (filtro `deletedAt IS NULL`), LEFT JOIN de movimientos crudos |
| `datasources/account_number_local_datasource.dart` | Número completo → SecureStorage bajo clave derivada del id; `null` = borrar entrada |
| `models/account_mapper.dart` | Drift ↔ dominio; verifica paridad de nombres de enums |
| `repositories/account_repository_impl.dart` | Implementación; `accountNumberEnc` **siempre NULL** por diseño |

### Presentación (`lib/features/accounts/presentation/`)

4 cubits + states (`accounts_list`, `account_detail`, `account_form`, `archived_accounts`), 4 páginas (`accounts_page`, `account_detail_page`, `account_form_page`, `archived_accounts_page`) y 23 widgets, incluidos 6 sheets (`confirm_delete_account`, `confirm_archive_account`, `confirm_type_or_currency_change`, `currency_picker`, `day_picker`, `cannot_delete_last_account`). Verificado por grep: presentation **no importa** `data/`, drift ni repositorios; cero imports de ads/RevenueCat/paywall; ningún `double` toca dinero.

### Transversal

| Archivo | Qué |
|---|---|
| `lib/core/utils/money_formatter.dart` | **Nuevos** `parseMinor`/`parseRateBps` con aritmética entera pura (el `toMinor(num)` existente pasaba por `double`, incompatible con AC-5). Acepta `1.234,56`, `24,5`, `$ 1.234,56`, negativos; **rechaza** `12,34,56` (en es-CO la coma nunca agrupa) |
| `lib/core/router/app_router.dart`, `bootstrap_home_page.dart` | Rutas de la feature |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` + `gen/*` | Todas las claves nuevas, con paridad |
| `lib/core/di/injection.config.dart` | Cableado de la feature |

### Decisiones que vale la pena conocer

1. **Saldo con una sola implementación**: el datasource devuelve filas crudas y el dominio aplica signos y filtro de soft-delete. Se rechazó el `SUM` en SQL: duplicar una regla financiera en SQL y en dominio es exactamente como se desincronizan. Coste: las filas se materializan en Dart.
2. **Efectivo también rechaza número completo** (doc HU-03), no solo tarjeta.
3. `isLastAccount` = la cuenta está activa Y no queda otra activa. Borrar una archivada nunca se bloquea.
4. Errores de stream se emiten como `Left` en vez de matar la suscripción (habilita el estado de error de la lista).
5. **Gap de diseño resuelto**: el spec no lista campo de número en el formulario, pero los AC 6/7 lo exigen. Se agregó condicionado por tipo: efectivo → ninguno; tarjeta → solo `last4`; resto → número completo + `last4` solo si el número está vacío.

## Tests

Resultado: **verde**. 247 tests (231 baseline + 16 nuevos). `analyze` limpio. e2e: **skip**.

```bash
flutter analyze                 # No issues found!
dart run custom_lint            # No issues found!  (paso APARTE, obligatorio)
flutter test                    # All tests passed!  (247)

# subconjuntos útiles
flutter test test/features/accounts
flutter test test/core/money_parse_test.dart test/core/l10n/arb_parity_test.dart
flutter test test/features/accounts/tier0_test.dart

# e2e (no ejecutado en esta corrida): bootea un emulador y
# patrol test
```

Tests nuevos añadidos en la fase de QA:
- `test/features/accounts/presentation/pages/account_detail_page_test.dart` — el AC-8 exigía el test sobre el **detalle**; solo existía sobre `AccountNumberRow` aislado, sin cubrir el wiring `isCard: account.isCard`.
- `test/core/security/secure_clipboard_test.dart` — antes solo se verificaba la delegación al clipboard; el timer real de 60s no se ejercitaba.
- `test/features/accounts/tier0_test.dart` — no existía **ningún** chequeo automatizado del AC-19. Mutation-probeado: plantando `isPremium`/`maxAccounts` en `create_account.dart` el guard falla correctamente; `lib/` restaurado byte-idéntico.

## 👤 Verifica a mano

- [ ] **Tema oscuro de las 19 pantallas**: ningún test asserta color o contraste real. Verificar visualmente claro + oscuro contra `billetudo.pen` (los widget tests solo usan `AppTheme.light()`).
- [ ] **Gesto real de reordenar en dispositivo**: los tests verifican que `reorderAccounts` persiste `sortOrder` 0..n−1, pero no el drag&drop real ni el feedback háptico/animación.
- [ ] **Carrusel del Balance Card Hero** (swipe entre cupo disponible y deuda): la discoverability con solo 2 puntos como affordance fue un riesgo aceptado por vos; validar con dedo real.
- [ ] **Limpieza del portapapeles a los 60s en el SO real**: el test corre sobre reloj falso con el canal de plataforma mockeado; confirmar en Android/iOS que el número deja de pegarse de verdad.
- [ ] **Persistencia real del número en Keychain/Keystore** del dispositivo (los tests usan un `SecureStorageService` mockeado, no el almacén nativo).
- [ ] **Redacción y tono en es/en**: la paridad de claves está testeada, pero que la traducción sea correcta y no punitiva ("nunca avergonzar por el gasto") lo juzga un humano.
- [ ] **e2e quedó en skip**: si querés automatizarlo, bootea un emulador y corré `patrol test`.

## Pendientes y riesgos

### 🚫 Blockers sin resolver (review deep) — decidir antes de commitear

**1. `presentation/cubit/account_form_cubit.dart` — un fallo de lectura del almacén seguro se traga a `null` y borra el número guardado del usuario en el siguiente guardado.**
`_formFor` hace `final number = await _getAccountNumber(account.id);` y luego `fullAccountNumber: number.getOrElse((_) => null)`. `SecureStorageService.read` (`lib/core/security/secure_storage_service.dart:35`) devuelve `Left(SecureStorageFailure)` ante cualquier excepción de plataforma — escenario real en Android, donde un error de descifrado del Keystore es un modo de fallo conocido de `flutter_secure_storage`. `getOrElse` colapsa ese `Left` en el mismo `null` que significa "la cuenta no tiene número".
Flujo: el usuario abre una cuenta bancaria a editar → la lectura del Keychain/Keystore falla → el formulario se renderiza con el campo vacío y sin error → el usuario cambia solo el nombre y guarda → `_buildDraft` pasa `fullAccountNumber: null` → `AccountRepositoryImpl.updateAccount` (líneas 100-102) → `_numbers.write(id, null)` → `AccountNumberLocalDatasource.write` (línea 27) enruta `null` a `delete(accountId)`. El número se pierde para siempre: HU-03 dice que nunca sale del dispositivo, así que no hay copia en la nube; el usuario debe retipearlo y nunca se le avisa.
**Arreglo**: distinguir "lectura fallida" de "no hay número guardado" — mostrar el fallo (bloquear el guardado o dejar el campo ausente/intacto) en vez de mapearlo al centinela que significa borrar.

**2. `data/repositories/account_repository_impl.dart` — `createAccount` devuelve `Left` con la fila ya insertada: el reintento del usuario crea una cuenta duplicada.**
La fila se inserta primero (`await _local.insertAccount(...)`, línea 61) y solo después se escribe el número:
```dart
final stored = await _numbers.write(row.id, draft.fullAccountNumber);
if (stored case Left(value: final failure)) {
  return Left(failure);
}
```
No hay rollback, así que un fallo del almacén seguro devuelve `Left` para una cuenta que sí existe en Drift. `AccountFormCubit.submit` (líneas 155-165) mapea ese `Left` a `status: AccountFormStatus.ready` con el fallo visible: el formulario queda abierto y se lee como "no se guardó". Guardar de nuevo corre `createAccount` otra vez (`state.isEditing` sigue en false porque `state.id` nunca se pobló) e inserta una **segunda** fila con UUID nuevo. Dos cuentas idénticas, la primera sin número, ambas en el listado y en los subtotales del Total Card.
**Arreglo**: borrar la fila recién insertada antes de devolver `Left`, o devolver `Right(account)` con el fallo de almacenamiento como advertencia no fatal para que el cubit no reenvíe.

**3. `data/repositories/account_repository_impl.dart` — `deletedAt` se usa como lápida permanente, ni papelera/undo ni DELETE real, con la consecuencia de PowerSync sin resolver.**
CLAUDE.md dice: *"Borrado: `deletedAt` es solo para papelera/undo de UX; PowerSync sincroniza los DELETE reales por su cuenta."* `softDeleteAccount` estampa `deletedAt` (vía `AccountMapper.deletedCompanion`) como lápida de integridad referencial: cada query filtra `deletedAt IS NULL` (`accounts_local_datasource.dart:42, 63, 149`), no existe un un-delete en toda la feature (`unarchive_account.dart` solo invierte `archived`) y la línea 150 borra el número del almacén seguro, lo que lo hace irreversible por diseño. No es papelera/undo.
El código lo documenta como excepción deliberada (líneas 125-138) y la intención es defendible: `Transactions.accountId` necesita que su referente sobreviva. Lo que **no** está resuelto lo señala la propia nota del autor (líneas 135-138): PowerSync propaga los DELETE reales por su cuenta, así que estas lápidas vivirán en Supabase para siempre y nada decide si eventualmente reciben un DELETE real (cuando ninguna transacción las referencie) o si las sync rules las filtran. Tal cual, las cuentas borradas se acumulan en Postgres y se re-sincronizan a cada dispositivo nuevo; el filtro local `deletedAt IS NULL` es lo **único** que las oculta — una sync rule que no replique el filtro resucitaría cuentas borradas en la UI.
**Arreglo**: o documentar la excepción explícitamente en la regla de Borrado de CLAUDE.md (para que una feature futura no copie el patrón por analogía), o introducir una columna distinta (p. ej. `tombstonedAt`) para que `deletedAt` conserve su único significado documentado. En cualquier caso, la pregunta de PowerSync necesita respuesta antes de cablear el sync.

### Decisiones que requieren tu visto bueno

1. **Carrusel**: el spec dice que "Cupo disponible" es el default, pero el dominio fija `cardBalancePrimary = debt` al crear, así que una tarjeta nueva abre en la página 2. Se priorizó la preferencia **persistida** (es el punto de HU-04) sobre el default visual. Cambiarlo exige tocar dominio.
2. **Punto de entrada a "Cuentas archivadas" INVENTADO**: ningún frame define cómo se llega. Se puso un icono archive en el header de la lista → ese header queda con 2 acciones, lo que tensiona la regla de centrado 44x44 de MASTER.md. Necesita decisión de diseño.
3. `AccountsListCubit` se suscribe a **dos** streams (accounts + overview) según el change map: son eventualmente consistentes, no atómicos (el total puede ir un microtask detrás de la lista). Derivar el overview del único stream de la lista sería atómico pero sacaría la regla de `WatchAccountsOverview`.
4. `DayCell` usa `day.toString()` en vez de clave l10n: un numeral desnudo no tiene idioma. Cumple `avoid_hardcoded_ui_strings` honestamente, sin suprimir la regla (efecto: los dígitos no se formatean por locale).
5. `onReorder` está deprecado en este SDK → se usa `onReorderItem` (entrega índices ya ajustados), así que el cubit **no** hace el `newIndex - 1`.

### Pendientes técnicos reales

- **`updatedAt` y resolución de segundos**: Drift guarda `DateTime` como epoch en **segundos**, así que dos escrituras dentro del mismo segundo dejan `updatedAt` igual, no mayor. AC-10 está cumplida y testeada (el test retrocede la fila en vez de dormir), pero el límite es real y solo se arregla con cambio de esquema (`storeDateTimeValuesAsText` o millis) — fuera de alcance. Relevante para el orden de resolución de conflictos de PowerSync.
- **`accountNumberEnc` es columna muerta**: siempre NULL por diseño. Falta excluirla del sync de PowerSync y evaluar eliminarla en un futuro `/drift-schema-change`. **Cualquier escritura futura a esa columna filtra el número a Supabase** en cuanto se active el sync.
- **Rendimiento**: el saldo materializa las filas de movimiento en Dart. Suficiente para Fase 0 (SQLite local, un usuario); si el perfilado lo pide, agregar por buckets en SQL manteniendo los signos en el dominio.
- **`Debts` no tiene `accountId`**: el conteo de deudas de HU-08 se deriva de los `debtId` distintos de las transacciones de la cuenta. **Confirmar que es la semántica esperada.**
- **Multi-moneda**: `AccountsOverview` no expone ningún total cruzado (solo subtotales por moneda ordenados); la conversión sigue pendiente en `12-multi-moneda.md`.
- **Acoplamiento cross-feature**: el saldo se deriva leyendo `Transactions` desde el datasource de Accounts, y Transacciones aún no existe. La fórmula vive **solo** en `domain/entities/account_balance.dart` y la query en un único datasource; cuando llegue Transacciones, debe **reusarse, no reimplementarse**.
- **Gaps de cobertura**: sin widget tests de `confirm_archive` / `confirm_delete` / `currency_picker` / `day_picker` (cubiertos a nivel cubit).
- **Affordance vacía**: revelar/copiar se muestran en cualquier cuenta con `last4` aunque no haya número guardado; el ojo entonces no hace nada (no rompe).
- **`MoneyFormatter.format` siempre pinta 2 decimales** → COP se ve "$4.500,00". Coherente con la convención de almacenamiento, no con la convención es-CO del peso.
- **Tokens de contraste** (`primary-on-soft`, `expense-text`) son fáciles de perder al implementar: `$primary` puro sobre `$primary-soft` falla en oscuro (~2.75:1) y `$expense` puro no llega a 4.5:1 en texto normal. Aplican a Account Card, Credit Card Account Row, Empty State, Archived Account Row, link 'Eliminar cuenta' y badge 'Sobrecupo'.
- **Componentes en la feature, no en core**: `EmptyState`, `SkeletonRow`, `BottomSheetBase` y `SheetButtonsRow` están en MASTER.md como globales, pero la convención dice que un componente sube a `lib/core/widgets/` solo cuando lo usan **dos** features. Se quedan aquí; promoverlos cuando Categorías/Transacciones los necesiten.
- **Interacciones no cerradas en diseño** (pendientes en `cuentas.md`): animación del pill de tipo (`AnimatedSize` asumido), mecanismo del carrusel (`PageView` asumido), si los dots son interactivos, y qué acción exacta dispara cada sheet. Asumidas en la implementación; el diseño no las valida.

Observaciones no bloqueantes del review: ninguna.

## Mensaje de commit sugerido

```
Implementar la feature completa de Cuentas (HU-01 a HU-04, HU-06 a HU-09)

Dominio, datos y presentación de Cuentas sobre el esquema Drift existente,
sin migración. HU-05 (vista combinada multi-cuenta) queda fuera: pertenece
a Transacciones.

- Dominio: regla única de saldo/cupo (signos, soft-delete, sobrecupo) en
  AccountBalance; validación HU-01/02/03 como invariante de AccountDraft;
  13 casos de uso.
- Datos: datasources Drift + número completo SOLO en SecureStorage bajo
  clave derivada del id (accountNumberEnc queda siempre NULL); borrado
  lógico para no romper el FK de Transactions.accountId.
- Presentación: 4 cubits, 4 páginas y 23 widgets contra billetudo.pen,
  claro + oscuro, sin strings literales y con paridad es/en.
- Core: parseMinor/parseRateBps con aritmética entera pura (sin double).
- Nivel 0 intacto: sin ads, cupos ni paywall, y sin límite de cuentas.

flutter analyze, dart run custom_lint y flutter test en verde (247 tests).
```

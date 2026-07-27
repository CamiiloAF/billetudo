# Convenciones de código — billetudo

Cómo se escribe código en este repo y por qué. `CLAUDE.md` define **qué** se
construye (arquitectura, reglas de negocio); este documento define **cómo** se
escribe. Lo que es automatizable vive en
[`analysis_options.yaml`](../analysis_options.yaml); el resto (3 reglas de
widgets/UI que ningún lint oficial cubre) lo revisa el subagente
`ui-convention-reviewer`; aquí está el porqué, que ni un lint ni un agente
pueden explicar por sí solos.

Regla que gobierna a todas las demás: **keep it simple**. Ninguna convención de
abajo justifica una abstracción que nadie pidió. Si una regla te obliga a algo
que empeora el código, el problema es la regla — discútela, no la sortees en
silencio.

---

## 1. Cómo se hacen cumplir

| Mecanismo | Qué cubre | Cuándo corre |
|---|---|---|
| `flutter analyze` | lints oficiales de Dart/Flutter + `strict-casts`/`strict-inference` | IDE y CI |
| `ui-convention-reviewer` | las 3 reglas propias de widgets/UI del proyecto | proactivo, tras cada cambio en `lib/` |
| `dart format` | formato, 80 columnas | pre-commit |
| `finance-code-reviewer` | lo que ningún lint puede ver (centavos, `updatedAt`, capas) | antes de cerrar |

Las tres reglas propias de widgets/UI vivían en un plugin `custom_lint`
(`tools/billetudo_lints/`), retirado el 2026-07-17: `drift_dev`/`powersync`
exigían `analyzer` ≥10.0.0 y `custom_lint_builder` (última versión publicada)
todavía fijaba `analyzer` ^8.0.0 — sin combinación válida de versiones, y sin
fecha de solución upstream. En vez de bloquear el resto del stack a una
versión de `analyzer` vieja, se retiró el plugin y las mismas 3 reglas las
hace cumplir el subagente `ui-convention-reviewer` (`.claude/agents/`),
invocado proactivamente después de que se escribe o edita código en `lib/` —
mismo criterio de detección, ahora en prosa en vez de en un `LintRule` del
analyzer.

```bash
flutter analyze          # lints oficiales
dart format .
```

> Las 3 reglas propias (funciones que devuelven `Widget`, widgets privados,
> strings de UI sin localizar) **no las corre `flutter analyze`** — nunca las
> corrió, ni siquiera con el plugin (ese solo las mostraba en el IDE y en
> `dart run custom_lint`, un comando aparte). Ahora es `ui-convention-reviewer`
> quien las revisa; no depender solo de la memoria para acordarse de invocarlo.

Un lint se silencia con `// ignore: nombre_regla` **y una línea de comentario
que explique por qué**. Un `ignore` sin justificación es un bug esperando turno.

---

## 2. Widgets

### No se construyen widgets desde funciones

```dart
// ✗ Mal
Widget buildBalanceCard(BuildContext context, int amountMinor) { ... }

// ✓ Bien
class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.amountMinor, super.key});
  final int amountMinor;
  ...
}
```

**Por qué:** una función que devuelve `Widget` es invisible para el framework.
No tiene elemento propio en el árbol, así que Flutter no puede marcarla como
dirty por separado, no puede saltarse su reconstrucción con `const`, y no
aparece en el widget inspector. Todo lo que devuelve se reconstruye con el
padre, siempre. Una clase cuesta cinco líneas más y recupera las tres cosas.

Excepciones legítimas, que la regla ya contempla: el `build` override y
cualquier closure anónima (`builder:`, `itemBuilder:`) — esos son puntos de
extensión del framework, no el anti-patrón.

Lint: `avoid_widget_functions`.

### No se crean widgets privados

```dart
// ✗ Mal — en accounts_page.dart
class _AccountTile extends StatelessWidget { ... }

// ✓ Bien — en presentation/widgets/account_tile.dart
class AccountTile extends StatelessWidget { ... }
```

**Por qué:** un widget privado no se puede widget-testear desde `test/` ni
reutilizar desde otra pantalla, y sirve de escondite para UI que crece dentro
de un archivo que ya tiene otro dueño. Público y en su propio archivo bajo
`presentation/widgets/` mantiene ambas puertas abiertas.

Las clases `State` (`_AccountsPageState`) siguen siendo privadas: es la
convención del propio framework y no son widgets. La regla no las toca.

Lint: `avoid_private_widgets`.

### Un archivo, un widget público

`presentation/pages/` para pantallas completas (una por ruta),
`presentation/widgets/` para los componentes de esa feature. Un componente que
usan dos features sube a `lib/core/widgets/`. La única razón para bajarlo desde
`core/` es que dejó de compartirse.

---

## 3. Strings y localización

La app se publica en **es** y **en**. Todo texto que el usuario lee sale de
`AppLocalizations` (`lib/core/l10n/arb/app_es.arb` + `app_en.arb`), nunca de un
literal.

```dart
// ✗ Mal
const Text('Saldo disponible')

// ✓ Bien
Text(AppLocalizations.of(context).accountsAvailableBalance)
```

**Por qué:** un literal en la UI es un texto que solo puede existir en un
idioma. No es una regla de estilo: es la diferencia entre poder publicar en
inglés y no poder.

`app_es.arb` es el template (la app se piensa en español). Toda clave nueva se
agrega **a los dos** `.arb` en el mismo commit; si falta en uno, `flutter
gen-l10n` avisa. Tras editar un `.arb`, regenera con `flutter gen-l10n`.

**Nombre de claves:** `<feature><Concepto>` en lowerCamelCase —
`accountsEmptyTitle`, `transactionsFilterAll`. Lo transversal lleva el prefijo
`common` (`commonSave`) o `error` (`errorDatabase`). El nombre describe **dónde
y para qué** se usa, no qué dice: `commonSave`, no `commonGuardar`.

Agrega `"@clave": {"description": "..."}` cuando el traductor necesite contexto
que la clave no da (una palabra ambigua, un placeholder, un plural).

**Qué NO es un string de UI**, y por tanto puede ser literal en inglés:

- Mensajes de excepción y logs (`throw StateError('account not found')`) — los
  lee el equipo, no el usuario. `Failure.message` es técnico **a propósito**: la
  UI mapea el *tipo* de failure a una clave localizada, nunca muestra `message`.
- Rutas de assets, `package:`, nombres de fuente, ids de restauración.
- Rutas de navegación (`/cuentas`) — son URLs visibles, se quedan en español.
- Claves de base de datos, nombres de columna, valores de enum persistidos.

El lint solo mira argumentos de constructores de widgets, así que estos casos
no lo activan por diseño.

Lint: `avoid_hardcoded_ui_strings`.

---

## 4. Idioma del código

**Todo el código y sus comentarios van en inglés.** Identificadores, doc
comments, mensajes de excepción, TODOs.

**Por qué:** el código en Spanglish (`final cuentasFiltradas = accounts.where`)
obliga a decidir el idioma en cada línea, y esa decisión se toma distinta cada
vez. El inglés es además el idioma del SDK contra el que se escribe.

Se quedan en español, deliberadamente:

- Los `.arb` (son el producto).
- Las rutas (`/cuentas`) — son URLs que el usuario ve.
- `docs/`, `CLAUDE.md`, `design-system/` y este archivo — los lee el equipo.
- Los mensajes de commit.

---

## 5. Comentarios

Un comentario justifica algo que el código no puede mostrar: una restricción,
un porqué, una decisión que parece un error y no lo es. Si solo narra lo que la
línea siguiente ya dice, se borra.

```dart
// ✗ Redundante
// Incrementa el índice
index++;

// ✗ Le habla al revisor, no al próximo lector — muere al mergear el PR
// Cambiado para arreglar el bug del pull anterior
final balance = _sumEntries(entries);

// ✓ Explica una restricción invisible
// Drift emite el stream antes de aplicar la migración, así que el primer
// evento puede traer el esquema viejo.
await _database.migrationCompleted;
```

Los doc comments (`///`) valen la pena en lo público de `domain/` y `core/`: la
entidad, el caso de uso, el contrato del repositorio. No hace falta documentar
cada campo obvio de un DTO.

`TODO(usuario): descripción` — con dueño, siempre (lint `flutter_style_todos`).
Un TODO anónimo no lo reclama nadie.

---

## 6. Dinero, ids y tiempo

Las tres reglas que ningún lint puede verificar y que corrompen datos en
silencio. Están en `CLAUDE.md`; se repiten aquí porque son las que más caro
cuestan.

- **Dinero: siempre `int` en centavos** (`amountMinor`). Nunca `double`. Un
  `double` no representa `0.1` exactamente; sumar mil transacciones acumula el
  error y el saldo deja de cuadrar. `MoneyFormatter` es el **único** punto que
  convierte entre centavos y texto.
- **IDs: UUID en texto**, vía `clientDefault` en Drift. Nunca autoincrement: dos
  dispositivos offline generarían el mismo id y el sync los fusionaría en uno.
- **`updatedAt` en cada escritura**, en el repositorio (no en el DAO, no en el
  cubit). PowerSync resuelve conflictos con ese timestamp; sin él, gana el
  registro equivocado.
- **Nombres de variable con unidad**: `amountMinor`, no `amount`. El tipo `int`
  no distingue 1234 centavos de 1234 pesos; el nombre sí.

---

## 7. Capas

Las dependencias apuntan hacia adentro: `presentation → domain ← data`. El
detalle de cada capa está en `CLAUDE.md`. Lo que se revisa en cada PR:

- Un tipo generado por Drift **nunca** cruza fuera de `data/`. Si un cubit
  importa `app_database.dart`, la capa se rompió.
- Un cubit orquesta **casos de uso**, jamás repositorios ni DAOs directo.
- `domain/` no importa Flutter, Drift ni Supabase. Es Dart puro y se testea sin
  `flutter_test`.
- Un caso de uso por acción de negocio, con un solo `call()`, **incluso cuando
  es un passthrough de una línea**. Es el punto donde la validación va a caer
  cuando aparezca, y ahorra el refactor de reconectar toda la feature.

**Errores:** los casos de uso y repositorios devuelven `FutureResult<T>`
(`Either<Failure, T>`). El error va en la firma, no en una excepción implícita.
`data/` traduce las excepciones de infraestructura a una subclase de `Failure`;
`presentation/` mapea el tipo de `Failure` a una clave de l10n.

El `catch (e, st)` sin `on` **es correcto en la frontera de `data/`**: ahí el
trabajo es precisamente convertir cualquier excepción de Drift o del secure
storage en un `Failure` (ver `SecureStorageService`). Por eso
`avoid_catches_without_on_clauses` está desactivada — pediría un `ignore` en
cada método de cada repositorio. Lo que sigue prohibido, y lo revisa una
persona porque ningún lint lo ve:

- Tragarse el error (`catch (_) {}`) o perder la causa: `cause` y `stackTrace`
  siempre viajan dentro del `Failure`.
- Un catch-all fuera de `data/`. En `domain/` y `presentation/` se atrapa el
  tipo concreto que se sabe manejar.

---

## 8. Nombres

| Qué | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case` | `account_tile.dart` |
| Clases, enums, extensiones | `UpperCamelCase` | `AccountTile` |
| Casos de uso | verbo en imperativo | `CreateTransaction`, `GetAccounts` |
| Interfaz de repositorio | `<Entidad>Repository` | `AccountRepository` |
| Implementación | `<Interfaz>Impl` | `AccountRepositoryImpl` |
| Cubit / Bloc | `<Feature>Cubit` + `<Feature>State` | `AccountsCubit` |
| Booleanos | `is` / `has` / `can` | `isArchived`, `hasPendingSync` |
| Montos | sufijo `Minor` | `amountMinor` |
| Claves de l10n | `<feature><Concepto>` | `accountsEmptyTitle` |

Sin abreviaturas inventadas: `transaction`, no `txn`; `category`, no `cat`. La
excepción es `TxSource`, que ya está en el esquema y en Postgres.

---

## 9. Estado (bloc/cubit)

- **Cubit por defecto.** Bloc con eventos solo cuando de verdad hay un flujo de
  eventos que rastrear o debouncear. Un `Bloc` con un evento por método es un
  cubit con ceremonia.
- **Estados inmutables** con `Equatable`. Sin `Equatable`, `BlocBuilder`
  reconstruye en cada emisión.
- **Un estado con `status`**, no cuatro clases sueltas que se pisan: la UI
  necesita poder mostrar los datos viejos mientras recarga.
- **Los streams se cancelan en `close()`** (lints `cancel_subscriptions`,
  `close_sinks`). Un stream de Drift vivo después del cubit emite hacia un
  objeto muerto.
- **`context` después de un `await`**: revisa `mounted` primero (lint
  `use_build_context_synchronously`). El usuario pudo salir de la pantalla
  mientras el `await` corría.

---

## 10. Tests

Detalle y responsabilidades en el agente `qa-automator`. Lo relevante para
quien escribe código:

- `domain/` (casos de uso, cálculos como safe-to-spend, rollover): unit tests,
  sin Flutter. Es la capa donde un test cuesta menos y atrapa más.
- Cubits: `bloc_test` con casos de uso mockeados (`mocktail`).
- Widgets: uno por componente público — de ahí que no haya widgets privados.
- Flujos completos: Patrol en `integration_test/`.
- **Los tests no se localizan**: un literal en un test es correcto, y por eso
  las reglas propias solo miran `lib/`.

---

## 11. Formato

`dart format` decide, no se discute. 80 columnas. Es la **única** autoridad
sobre el formato, comas finales incluidas.

Por eso `require_trailing_commas` está desactivada: con `dart format` de Dart
3.12 entra en un ciclo infinito — el formatter quita la coma, el lint la exige,
`dart fix` la repone y el formatter la vuelve a quitar. Dos autoridades sobre lo
mismo no pueden ganar las dos. Si algún día el proyecto sube a tall style
(language version 3.8+), el lint se auto-desactiva solo y esto deja de importar.

- Comillas simples (`prefer_single_quotes`).
- Tipos de retorno siempre explícitos (`always_declare_return_types`).
- Imports relativos dentro del paquete (`prefer_relative_imports`), ordenados
  (`directives_ordering`): `dart:` → `package:` → relativos.
- `const` donde el analyzer lo permita. No es estética: es el mecanismo por el
  que Flutter se salta reconstrucciones.
- Nada de `print` — `CrashReporter` o nada (`avoid_print`).

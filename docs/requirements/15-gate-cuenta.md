# Feature: La app sin cuentas (gate "necesitas una cuenta")

**Nivel:** 0 (regla transversal, nunca detrás de anuncio ni pago)
**Depende de:** `01-cuentas.md` (HU-01 crear, HU-08 lápida/archivado)
**Afecta a:** `03-transacciones.md`, `04-inicio.md` (HU-02 FAB), `07-metas.md`, `08-deudas.md`, `09-pagos-programados.md`, `13-onboarding.md` (HU-02 omitible)
**Tablas Drift:** ninguna — se deriva de `Accounts`
**Diseño (billetudo.pen):** **no existe todavía** (una hoja puente + sus variantes por superficie). Aplica el flujo "diseño primero" de CLAUDE.md.

## Contexto

**"Cero cuentas activas" es un estado legítimo y permanente de la app, no un accidente del primer arranque.** Se llega ahí por tres caminos:

1. El usuario **omite** la creación de cuenta en el onboarding (`13-onboarding.md` HU-02, que es omitible por decisión).
2. Archiva o borra **todas** sus cuentas (`01-cuentas.md` HU-08) — un usuario veterano puede terminar acá.
3. Inicia sesión en una cuenta de la nube que todavía no tenía cuentas creadas.

Sin este documento, ese estado produce formularios que no pueden guardar: `Transactions.accountId` y `ScheduledPayments.accountId` son **NOT NULL** en el esquema, así que la app estaría ofreciendo acciones imposibles y fallando en el submit.

**Se separó de `13-onboarding.md` a propósito:** aunque el camino más frecuente sea omitir el paso de cuenta, esta es una regla de la app, no del flujo inicial. Vive aquí para que ninguna feature futura la trate como "algo de onboarding" que solo aplica una vez.

## Historias de usuario

### HU-01 — Puente, no muro
Como usuario sin ninguna cuenta activa quiero que la app me explique qué falta y me deje resolverlo en el momento, en vez de dejarme abrir un formulario que no puede funcionar ni darme un botón muerto.

**Criterios de aceptación:**
- **La acción sigue visible y tocable.** Al activarla se muestra una hoja breve que explica lo que falta y ofrece **crear la cuenta ahí mismo**, con el formulario de `01-cuentas.md` HU-01.
- **Al terminar de crear la cuenta, continúa automáticamente a la acción original** que el usuario pidió (registrar el movimiento, crear el pago programado, abonar a la deuda…). No lo devuelve al punto de partida a que vuelva a intentarlo.
- Si **cancela**, vuelve exactamente a donde estaba, sin cambios.
- **Prohibido deshabilitar el FAB o esconder acciones sin explicación.** Un control gris que no responde no comunica nada y se lee como un bug.
- **Tono** informativo y de progreso ("Para registrar movimientos necesitas una cuenta. Crea la primera en un momento"). Nunca de error, regaño ni advertencia; sin iconografía de alerta ni familia `$expense`.

### HU-02 — Condición única y compartida
Como desarrollador quiero una sola definición de "la app tiene cuentas", para que ninguna pantalla invente su propia versión y se desincronicen entre sí.

**Criterios de aceptación:**
- **La condición es:** existe al menos una cuenta **activa** — `deletedAt IS NULL AND tombstonedAt IS NULL`. Una cuenta archivada o con lápida **no** cuenta.
- Se resuelve en **un solo caso de uso** (`HasAnyActiveAccount`, en `features/accounts/domain`), no con un conteo replicado en cada cubit.
- **Se expone como stream, no como consulta puntual:** si el usuario crea su primera cuenta en otra pantalla, o le llega una por sync, el gate desaparece sin reiniciar la app. Escuchar, no fotografiar.
- **La transferencia exige dos** cuentas activas, no una. Con una sola, la opción se explica en vez de dejar fallar el guardado.

### HU-03 — Qué se bloquea y qué no
Como usuario sin cuentas quiero poder seguir usando todo lo que no necesita una, para que la app no se vuelva inútil por un dato que todavía no registré.

**Superficies bloqueadas** (exigen cuenta por esquema o por semántica):

| Superficie | Motivo |
|---|---|
| Registrar movimiento — ingreso, gasto y transferencia (`03`), incluido el FAB del Home (`04` HU-02) y el acceso rápido | `Transactions.accountId` es NOT NULL |
| Transferencia (`03` HU-03) | Exige **dos** cuentas activas |
| Crear pago programado (`09` HU-01), **incluida la cuota de una deuda** (`08` HU-03, reusa el mismo formulario) | `ScheduledPayments.accountId` es NOT NULL |
| Deuda **con desembolso registrado** y **abono que mueve dinero** (`08` HU-02) | La rama con caja genera una `Transaction` |
| Aporte/retiro de meta con el toggle "¿Mover dinero de una cuenta?" en **Sí** (`07` HU-03/HU-04) | Genera una transferencia real |
| Enlazar un movimiento existente a una deuda o a una meta (`08` HU-02, `07` HU-03) | Sin cuentas no hay movimientos que listar |
| **Crear presupuesto** (`06` HU-01) — decisión revertida 2026-08-06, ver nota abajo | Decisión de producto: bloquea toda la creación, no solo el alcance "Personalizado" |

**No se bloquean:** crear categorías, metas (sin cuenta vinculada), deudas **sin** desembolso, aportes de meta de seguimiento puro, abonos de deuda sin caja, importar datos (`11-import-export.md` — un import puede traer justamente las cuentas), gráficas (vacías) y todo Ajustes, incluido iniciar sesión.

> **Presupuestos — decisión revertida (2026-08-06).** Hasta esta fecha, presupuestos estaba en "no se bloquean" porque un presupuesto con alcance "Todo" no referencia ninguna cuenta específica — tiene sentido de dominio crearlo sin cuentas. El usuario decidió explícitamente cambiar esto a bloqueante: **toda** la creación de presupuestos exige al menos una cuenta activa, incluido el alcance "Todo", no solo cuando se elige "Personalizado". No se revierte el razonamiento de dominio (sigue siendo cierto que "Todo" no necesita ninguna cuenta puntual) — es una decisión de producto que prioriza consistencia de flujo sobre esa posibilidad técnica.
>
> **Vincular una cuenta a una meta ya en progreso no es un bloqueo, es una ayuda opcional.** El campo "Cuenta vinculada (recomendado)" del formulario de Metas sigue sin ser obligatorio (crear la meta sin cuenta sigue funcionando, ver arriba) — pero si el usuario lo toca sin tener cuentas, en vez de quedar como un no-op silencioso, se le ofrece la misma hoja puente de forma informativa: crea una si quiere, o sigue sin vincular ninguna. No usa el mecanismo de bloqueo estándar (no impide nada si cancela).

**Criterio general:** se bloquea la **rama** que necesita cuenta, nunca la feature entera. Metas y Deudas funcionan sin cuentas por diseño y así deben seguir.

### HU-04 — El bloqueo también aplica por ruta directa
Como usuario que llega por un deep link o restaura la app en una ruta profunda quiero el mismo trato coherente, para no ver un formulario roto.

**Criterios de aceptación:**
- Entrar a `/movimientos/nuevo` (o equivalente) sin cuentas activas **no monta el formulario**: muestra el mismo puente de HU-01.
- Se resuelve en el router (`app_router.dart`), no solo en los widgets de origen de cada acción.
- Tras crear la cuenta desde el puente, la ruta original se abre normalmente.

## Reglas de negocio y edge cases

- **Precedencia sobre cualquier otra capa:** si en la misma entrada corresponde mostrar el puente y un minitutorial (`16-minitutoriales.md`), **gana el puente**; el tutorial espera a la siguiente visita. Nunca dos capas superpuestas.
- **No se muestra durante el onboarding:** mientras el flujo de bienvenida está activo, el gate no aplica — ese flujo tiene su propio manejo (`13-onboarding.md` HU-04).
- **No es un recordatorio recurrente:** el puente aparece cuando el usuario intenta la acción, nunca como banner permanente, notificación ni interrupción al abrir la app.
- **No reabre el onboarding** en ningún caso (`13-onboarding.md`, ciclo de vida del latch).
- Cero impacto en datos: no crea cuentas implícitas ni de ejemplo.

## Impacto técnico (change map preliminar)

- **Dominio:** `HasAnyActiveAccount` en `features/accounts/domain/usecases/`, expuesto como `Stream<bool>` sobre la consulta existente de cuentas activas.
- **Presentación:** un **widget puente compartido** (hoja + formulario de creación + continuación a la acción original), parametrizado por el copy de cada superficie. No una implementación por feature.
- **Cableado:** FAB y acceso rápido del Home, formularios de movimiento y transferencia, creación de pago programado, ramas con caja de Deudas y Metas, y pickers de "enlazar movimiento existente".
- **Router:** guardas por ruta en `app_router.dart` para las rutas de creación listadas en HU-03.
- **l10n:** copy por superficie en `lib/core/l10n/arb/` (es + en).
- **Tests:** unit de `HasAnyActiveAccount` (archivada y con lápida **no** cuentan; reacciona a la creación), widget del puente en cada superficie **incluida la continuación automática**, widget de la precedencia sobre el minitutorial, y e2e Patrol del camino "primer arranque omitiendo cuenta → chocar con el gate → crear → continuar".

## Fuera de alcance

- Crear una cuenta implícita "Efectivo" por el usuario (descartado en `13-onboarding.md`, decisión #2).
- Un estado "modo solo lectura" de la app: sin cuentas la app se usa igual, solo con esas ramas puenteadas.
- Sugerir cuentas por institución o por país; el formulario es el de `01-cuentas.md`, sin variantes.

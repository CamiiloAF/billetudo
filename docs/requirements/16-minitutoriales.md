# Feature: Minitutoriales (ayuda contextual por feature)

**Nivel:** 0 (nunca detrás de anuncio, pago ni login)
**Depende de:** `13-onboarding.md` (no se muestran durante el flujo de bienvenida), `15-gate-cuenta.md` (el gate tiene precedencia)
**Afecta a:** `03-transacciones.md`, `06-presupuestos.md`, `07-metas.md`, `08-deudas.md`, `09-pagos-programados.md`
**Tabla Drift:** una tabla nueva de tutoriales ya vistos (`TutorialViews`) + una preferencia en `AppSettings`
**Diseño (billetudo.pen):** **no existe todavía** (un componente de hoja reutilizable + el "?" en headers). Aplica el flujo "diseño primero" de CLAUDE.md.

## Contexto

El onboarding (`13-onboarding.md`) enseña la promesa y el arranque; **no puede enseñar cada feature sin volverse un tour de diez pantallas** que nadie lee y que además llega demasiado pronto — el usuario todavía no tiene el problema que la feature resuelve.

Los minitutoriales resuelven la otra mitad: **ayuda contextual permanente**, que aparece la primera vez que el usuario entra a una feature o abre un sub-flujo no obvio, y queda siempre reabrible. Es donde se explican los conceptos propios de esta app — modo sobres, el ledger de deudas, aportes que mueven dinero o no — que ninguna etiqueta de formulario alcanza a comunicar.

**Ciclo de vida distinto al del onboarding:** el flujo de bienvenida corre una vez y se cierra para siempre; esto vive en la app indefinidamente. Por eso son documentos separados aunque compartan tono y componente.

## Forma (decisión cerrada 2026-07-27)

**Hoja de bienvenida al primer acceso, reabrible. No coach marks.**

- **Bottom sheet** del sistema de diseño (no pantalla completa) con **título + 2-3 puntos + una acción primaria** que lleva a hacer lo que acaba de explicar ("Crear mi primer presupuesto"), más "Entendido" para cerrar.
- **Aparece una sola vez**, al primer acceso, y queda **reabrible desde un "?" en el header** de esa pantalla. Reabrirla es idéntico a verla la primera vez.
- **Un solo componente compartido**, parametrizado por contenido. No se construye una hoja distinta por feature.
- Cada tutorial tiene una **clave estable** (`tutorial-budgets`, `tutorial-debt-link-movement`, …) que es la unidad de "ya lo vi".

**Se descartaron:**
- **Coach marks** (burbujas sobre controles reales): exigen infraestructura de overlays, se rompen con cada cambio de layout, no se capturan en golden y envejecen mal.
- **Solo a demanda** (nada aparece solo, todo tras el "?"): no enseña a quien no sabe que no sabe.
- **Tarjeta inline en el estado vacío**: no cabe una explicación de concepto y muere justo cuando la feature empieza a usarse.

## Historias de usuario

### HU-01 — Tutorial de pantalla al primer acceso
Como usuario quiero que cada feature con concepto propio me explique brevemente de qué se trata la primera vez que entro, para no tener que adivinar cómo piensa la app.

**Alcance v1** — solo features cuyo concepto no es obvio:

| Feature | Qué tiene que dejar claro |
|---|---|
| Presupuestos (`06`) | Qué es un presupuesto por periodo, el alcance por cuenta/categoría y qué es el **modo sobres** (zero-based) — el concepto más ajeno de la app. |
| Metas (`07`) | Que el progreso es un **historial de aportes**, no un número que se edita, y que un aporte puede mover dinero real o ser solo seguimiento. |
| Deudas (`08`) | Que la deuda es un **ledger**: el saldo se deriva de desembolsos, abonos e intereses, y cada evento decide si toca una cuenta. |
| Pagos programados (`09`) | La diferencia entre **automático y manual** (confirmar antes de aplicar) y qué es la bandeja de vencimientos. |

**Criterios de aceptación:**
- Se muestra al **primer acceso a la pantalla principal** de la feature, no al abrir un formulario suyo.
- La acción primaria de la hoja lleva a la acción real de la feature (crear presupuesto, crear meta…), no a otra pantalla explicativa.
- Cerrar la hoja con el gesto estándar **cuenta como vista** — no se insiste.

### HU-02 — Tutorial de sub-flujo
Como usuario quiero que las decisiones raras dentro de un formulario se me expliquen justo cuando las tengo enfrente, para no elegir a ciegas algo que cambia mis saldos.

Se muestran la primera vez que se abre **ese** flujo, no al entrar a la feature:

| Sub-flujo | Qué tiene que dejar claro |
|---|---|
| **Enlazar un movimiento existente a una deuda** (`08` HU-02) | Que no crea un movimiento nuevo: **atribuye** uno que ya registraste, para no duplicar. |
| **Enlazar un movimiento existente a una meta** (`07` HU-03) | Lo mismo, con el copy de Metas — mismo patrón, misma explicación. |
| **Toggle "¿agregar a una cuenta?" del abono de deuda** (`08` HU-02) | Que "No" **sí** baja la deuda pero no toca saldos: es la salida para "lo pagué en efectivo / lo pagó otro". |
| **Toggle "¿Mover dinero de una cuenta?" del aporte a meta** (`07` HU-03) | La diferencia entre apartar (cajita, sin transacción) y mover dinero de verdad (transferencia). |
| **Crear la cuota programada de una deuda** (`08` HU-03) | Que la cuota vive en Pagos programados, que **configurarla** se hace desde la deuda y **confirmarla** desde la bandeja, y que la transacción generada baja la cuenta *y* la deuda. |
| **Transferencia presupuestable** (`countsInBudget`, `03` / `plan-cuentas-tipos-y-transferencias-presupuestables.md`) | Por qué una transferencia puede contar en un presupuesto sin ser un gasto, y qué implica marcarla. |
| **Modo sobres / zero-based** (`06`) | Solo si se activa desde el toggle y no se vio ya el tutorial de pantalla de Presupuestos. |

**Criterios de aceptación:**
- **Nunca se encadenan dos tutoriales** en una misma navegación: si corresponde el de pantalla y el de sub-flujo, se muestra uno y el otro espera.
- El tutorial de sub-flujo **no bloquea el formulario**: se cierra y el usuario sigue donde estaba, con el flujo intacto.

### HU-03 — Volver a ver la explicación
Como usuario quiero poder releer la explicación cuando la necesite, para no depender de haberla entendido la primera vez.

**Criterios de aceptación:**
- **"?" en el header** de cada pantalla del alcance de HU-01, siempre visible (no solo la primera vez), que reabre exactamente la misma hoja.
- Para los sub-flujos de HU-02, el punto de reapertura es el mismo control que los dispara (el toggle, el botón de enlazar), mediante un affordance discreto de ayuda.
- Reabrir **no altera** el registro de "ya visto" ni reordena nada.

### HU-04 — Apagar y reactivar la ayuda
Como usuario que ya conoce la app quiero poder apagar estas hojas, y como usuario que quiere repasar quiero poder reactivarlas, para tener el control.

**Criterios de aceptación:**
- Ajuste único en Ajustes: **"Mostrar ayuda al entrar a una sección"** (encendido por defecto). Apagado, ningún tutorial aparece solo; el "?" sigue funcionando.
- **Reactivarlo reinicia el registro de "ya lo vi"** de todos los tutoriales — es la única forma de que una hoja vuelva a aparecer sola. Se le advierte al usuario en una línea, sin diálogo de confirmación pesado.
- El ajuste y el registro sincronizan (ver "Persistencia").

## Reglas de negocio y edge cases

**Precedencia y no-interrupción**
- **El gate de `15-gate-cuenta.md` gana siempre.** Si en la misma entrada corresponden el puente y un tutorial, se muestra el puente; el tutorial espera a la siguiente visita.
- **No se muestran durante el onboarding** (`13-onboarding.md`): mientras el flujo de bienvenida está activo, ninguna hoja aparece.
- **Nunca bloquean.** Se cierran con el gesto estándar de la hoja, y cerrar cuenta como vista.
- **No hay tutoriales al arrancar la app** ni fuera del contexto que explican.

**Contenido**
- **Se prohíbe el tutorial obvio:** nada para crear una cuenta, registrar un gasto o crear una categoría. Si una pantalla necesita explicación para algo trivial, el problema es el diseño de la pantalla — se arregla ahí, no con una hoja encima.
- **Tono:** explicar, no vender ni corregir. Nada de "¡No cometas el error de...!" ni de presuponer desorden financiero.
- **100% local y offline:** sin llamadas de red, sin imágenes remotas, sin video. Cualquier ilustración es un asset del bundle o un ícono del sistema de diseño.
- **Nivel 0 puro:** ningún tutorial queda detrás de anuncio, pago o login, y ninguno promociona features de pago (mientras HU-05 de `13-onboarding.md` siga congelada, no se mencionan).
- **Localizados** (es + en) desde `AppLocalizations`, texto escalable y navegables con lector de pantalla.

**Persistencia**
- **"Ya lo vi" es del usuario, no del teléfono**, así que **se sincroniza**: quien ya entendió Presupuestos no debe recibir la misma hoja al estrenar dispositivo. Va en tabla propia, no en preferencias locales (a diferencia del default del toggle de abono de Deudas, que sí es una comodidad por dispositivo).
- **Una fila por tutorial visto**, con la clave estable como `id` — no una columna por tutorial en `AppSettings`: agregar un tutorial no puede costar una migración de esquema en cuatro sitios.
- **Ojo con el id determinístico:** las claves (`tutorial-budgets`) no son UUID y se repiten entre usuarios. Es exactamente el patrón que rompió producción con las categorías semilla (decisión #19 de `05-auth-sync.md`): en Postgres la PK **debe** componerse con `user_id`. No repetir ese bug.
- Un tutorial cuya clave ya no existe (feature rediseñada) simplemente se ignora; no se limpia ni se migra.

## Impacto técnico (change map preliminar)

- **Esquema:** tabla nueva `TutorialViews` (`id` = clave del tutorial, con el mixin `_SyncColumns`) + columna de preferencia "mostrar ayuda" en `AppSettings` → sube `schemaVersion` + migración.
- **Regla de las cuatro piezas** (decisiones #17/#20/#21 de `05-auth-sync.md`, tres incidentes en producción por saltársela): Drift, `powersync_schema.dart`, Postgres **dev y prod**, y —por ser **tabla nueva**— su línea en el **Sync Stream de PowerSync (dev y prod)**, que es justo el paso que ya se olvidó dos veces. En Postgres, **PK compuesta `(id, user_id)`**. Usar `drift-migration-helper`.
- **Dominio:** un caso de uso por acción — `HasSeenTutorial`, `MarkTutorialSeen`, `ResetTutorials`, `SetTutorialsEnabled`.
- **Presentación:** **un único widget de hoja** parametrizado por contenido, el "?" en el header de las 4 pantallas de HU-01, y el cableado de los 7 sub-flujos de HU-02.
- **l10n:** el contenido de los 11 tutoriales en `lib/core/l10n/arb/` (es + en).
- **Tests:** unit del registro (marcar visto, no repetir, reset al reactivar), widget de cada hoja, widget de la precedencia gate > tutorial y de "no se encadenan dos", golden de cada hoja en ambos temas, y e2e Patrol de "primer acceso a Presupuestos → hoja → cerrar → no vuelve → reabrir con el ?".

## Fuera de alcance

- **Coach marks / burbujas sobre controles reales** — descartados, no pospuestos.
- **Tutoriales de las features obvias** (Cuentas, Transacciones, Categorías, Gráficas). Gráficas e informes es la primera candidata a sumarse si se detecta que sus convenciones de conteo confunden.
- **Centro de ayuda / FAQ navegable, búsqueda de ayuda y video:** la ayuda vive pegada a la pantalla que explica, no en una sección aparte.
- **Tutoriales personalizados por comportamiento** (mostrar según lo que el usuario hace o deja de hacer): requiere telemetría, que el repo no tiene ni introduce aquí.

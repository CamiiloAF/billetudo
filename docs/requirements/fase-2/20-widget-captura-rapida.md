# Feature: Widget de captura rápida (Android + iOS)

**Nivel:** 0 (gratis, ilimitado, sin anuncios). Es un atajo a la captura, y la captura es Nivel 0 — ponerlo detrás de anuncio o pago rompería la regla (`CLAUDE.md`).
**Fase:** 2 (captura sin fricción local). **Es la última pieza de la fase**: el widget es un atajo *hacia* las otras tres (voz `17`, OCR `18`, notificaciones bancarias `19`) y hacia el registro manual (`fase-1/03-transacciones.md`). Construirlo antes dejaría botones que no llevan a ninguna parte.
**Alcance: ATAJO PURO (decisión 2026-08-17).** El widget **no muestra ningún dato financiero**: es un conjunto de botones que abren la app en el punto de captura correspondiente. Ver §Alcance para las consecuencias, que atraviesan todo el documento.
**Tabla Drift:** ninguna propia. Con el alcance decidido, el widget **no lee datos de negocio en absoluto** — ni directa ni indirectamente.
**Plataformas:** ambas a la vez (decisión 2026-08-17). Android = App Widget (Glance / RemoteViews). iOS = WidgetKit.
**Directorio previsto:** `lib/features/capture/` (hoy vacío, solo `.gitkeep`) para el lado Flutter; el widget en sí vive en `android/` e `ios/` como código nativo.
**Diseño (billetudo.pen):** **no existe todavía**. Se diseña con `pencil-designer` antes de implementar (ver §Diseño).

## Contexto

El Home (`fase-1/04-inicio.md`) es la pantalla que resume la plata del usuario y el FAB es el punto de entrada de captura. Este widget es **la extensión del FAB fuera de la app**: pone en la pantalla de inicio del teléfono el atajo a registrar un gasto, para que el costo de capturar baje de "desbloquear → buscar el ícono → abrir la app → esperar el Home → tocar el FAB → elegir tipo" a un solo toque.

El valor no es mostrar información — es **quitar pasos antes del formulario**.

**Restricción de proceso (la restricción que decidió el alcance).** Un widget de sistema **no corre dentro del proceso de la app Flutter**: en Android es un `AppWidgetProvider`/`GlanceAppWidget` que el launcher hospeda, en iOS es una *widget extension* con su propio binario y su propio sandbox. Ninguno de los dos puede abrir la base Drift de la app ni ejecutar código Dart. De ahí salen dos ambiciones con costos muy distintos:

- Un widget que solo **abre la app** (deep link) no necesita compartir nada entre procesos: es barato, funciona en ambas plataformas por igual y funciona incluso con la app nunca abierta.
- Un widget que **muestra datos** necesitaría que la app Flutter escribiera de antemano un **espejo** de esos datos en un almacén compartido — `UserDefaults(suiteName:)` bajo un **App Group** en iOS, `SharedPreferences`/DataStore o un `ContentProvider` en Android — con todo lo que eso arrastra: invalidación del espejo, datos que envejecen, y cifras financieras a la vista de cualquiera que mire el teléfono.

**Se eligió la primera.** El resto del documento asume esa decisión.

## Alcance (decisión 2026-08-17)

**El widget es un atajo puro: botones que navegan, nunca datos.** Consecuencias directas, todas verificables en el resto del doc:

- **No se requiere App Group en iOS ni espejo de datos entre procesos.** No es que se posponga: no hay ningún dato que compartir. Sería necesario únicamente si el widget se volviera informativo algún día (ver HU-04, descartada).
- **Desaparece el problema de privacidad** de exhibir cifras en la pantalla de inicio. Era especialmente grave acá porque **la app no tiene hoy bloqueo biométrico ni PIN** (hallazgo verificado, ver HU-08): no existe un estado "app bloqueada" al que un widget pudiera consultar para ocultar montos. Con atajo puro el punto se vuelve inaplicable — pero el hallazgo se conserva porque sigue siendo cierto y afecta a otras decisiones.
- **Desaparece el problema de datos desactualizados.** WidgetKit refresca por *timeline*, con un presupuesto de refrescos que administra el sistema: un widget informativo de iOS mostraría, inevitablemente, números viejos. **Un widget que no muestra datos no envejece.** Es una de las razones de peso por las que esta opción es la barata: elimina de raíz la clase entera de bugs de "el widget dice una cifra y la app dice otra".
- **Desaparece el problema de multi-moneda** en el widget: no se muestran montos, así que no hay nada que sumar ni que etiquetar por moneda.
- **Ningún cambio de esquema**, y tampoco preferencias nuevas que espejar (ver HU-10 y §Cambios de esquema).

## Historias de usuario

### HU-01 — Registrar un gasto desde la pantalla de inicio, en un toque

Como usuario quiero tocar un botón en la pantalla de inicio de mi teléfono y caer directo en el formulario de gasto, para registrar lo que acabo de pagar antes de guardarme el celular.

**Criterios de aceptación:**
- El widget expone una acción **"Gasto"** que abre la app **directamente en el formulario de nueva transacción con `type = expense` preseleccionado**, sin pasar por el Home ni por un selector de tipo intermedio.
- El destino es la misma pantalla de `fase-1/03-transacciones.md` HU-01, con el mismo comportamiento: campo Monto enfocado y teclado numérico anclado ya visible.
- La transacción resultante se guarda con `source = manual` (el widget es un atajo de navegación, no un origen de captura distinto). Ver la observación sobre medición en §Reglas de negocio.
- El atajo **no crea nada por sí mismo**: tocar el widget nunca escribe una transacción. Sin confirmación humana en el formulario, no hay registro (modelo de confirmación de Fase 2).
- Si la app estaba en segundo plano con otro formulario abierto, el deep link **no descarta datos ya escritos por el usuario sin avisar**: o continúa el formulario en curso, o pregunta antes de reemplazarlo.
- Funciona con el teléfono recién encendido y la app nunca abierta en esa sesión (arranque en frío): el costo es un arranque más lento, nunca un error.

### HU-02 — Atajos a la captura sin fricción (voz, foto, pendientes)

Como usuario quiero llegar en un toque a dictar un gasto o a fotografiar un recibo, sin abrir la app y navegar hasta ahí.

**Criterios de aceptación:**
- El widget puede exponer, además de "Gasto", los atajos: **"Voz"** (abre la captura por voz, `17-captura-voz.md`), **"Foto"** (abre la cámara de recibos, `18-captura-ocr.md`) e **"Ingreso"** (formulario con `type = income`).
- Cada atajo abre la app en el destino correspondiente **ya en marcha** (la captura por voz empieza a escuchar, la de foto abre la cámara), no en una pantalla intermedia que obligue a un segundo toque. Los permisos de micrófono/cámara se piden en ese momento si no se concedieron; negarlos degrada al formulario manual, nunca a un error sin salida.
- **Voz y OCR pre-llenan el formulario; no registran.** El usuario ve lo capturado y confirma (modelo de confirmación de Fase 2). El widget no cambia eso.
- Si una de esas features **no está disponible** en el dispositivo (sin micrófono, sin cámara, reconocimiento no soportado en el idioma), su atajo **no se muestra** en el widget en vez de mostrarse y fallar al tocarlo.
- **Bandeja de pendientes bancarios — atajo sin contador (decisión 2026-08-17).** El widget **puede** exponer un atajo **"Pendientes"** que abre la bandeja de `19-notificaciones-bancarias.md`. Es compatible con el alcance porque un botón que abre una pantalla no muestra ningún dato. **El contador ("3 por confirmar") queda fuera de esta entrega**: un número que cambia solo exigiría exactamente el espejo de datos entre procesos que la decisión de alcance eliminó, y además delataría en la pantalla de inicio que hubo movimientos bancarios.
- Ese atajo **solo existe en Android** (la lectura de notificaciones bancarias es Android-only). Es la única asimetría de plataforma aceptada en el widget, y es consecuencia de la feature fuente, no del widget.

### HU-03 — Elegir qué atajos aparecen

Como usuario quiero que el widget muestre los atajos que yo uso, no cuatro botones de los que solo toco uno.

**Criterios de aceptación:**
- El conjunto y el orden de atajos son **configurables** por el usuario.
- En **Android** la configuración se hace en la *configuration activity* del widget al añadirlo, y se puede volver a editar después.
- En **iOS** se hace con los parámetros de configuración de WidgetKit (editar el widget desde la pantalla de inicio). iOS **no permite** una pantalla de configuración arbitraria: la configuración se limita a los parámetros que la extensión declara (una selección entre opciones predefinidas), no a un formulario libre.
- Existe además una entrada en Ajustes de la app que explica el widget y cómo añadirlo, para el usuario que no sabe que existe.
- **Pendiente de decidir: ¿hay un conjunto de atajos por defecto o el widget arranca sin configurar?** Opciones: (a) default fijo "Gasto + Voz + Foto" y el usuario ajusta si quiere (menos fricción al añadir, riesgo de mostrar atajos que no usa); (b) obligar a configurar al añadir (Android puede, iOS no del todo — su configuración es opcional por diseño, así que iOS necesitaría un default de todas formas). La asimetría de plataforma hace que (a) sea lo único simétrico, pero la decisión es del dueño de producto.

### HU-04 — Widget informativo — DESCARTADA (decisión 2026-08-17)

*Se conserva escrita porque es la decisión de alcance de la feature y porque, si alguna vez se retoma, este es el inventario del costo que implica.*

La ambición alternativa era mostrar datos en el widget (gastado del mes, presupuesto restante, saldo total o últimos movimientos). **Se descartó.** Racional:

- Obligaría a un **espejo** de datos escrito por la app en un almacén compartido, con **App Group** obligatorio en iOS y su propia lógica de invalidación (al crear/editar/borrar una transacción, al cambiar de mes, tras un sync, al abrir la app).
- El dato mostrado **envejecería** inevitablemente en iOS (HU-05), y un número financiero que el usuario cree actual y no lo es hace más daño que no mostrar número.
- Pondría **cifras financieras en la pantalla de inicio**, sin que la app tenga hoy un bloqueo (HU-08) que permita ocultarlas cuando corresponde.
- Abriría el riesgo de **descuadre con el Home**: dos superficies mostrando el mismo total y una de las dos vieja.
- Y traería el problema de **multi-moneda** (no se pueden sumar monedas distintas, `fase-1/12-multi-moneda.md`) en la superficie con menos espacio de toda la app.

**Si algún día se retoma**, esta HU se reabre completa junto con: App Group + espejo (§Dependencias), política de privacidad de montos (HU-08), marca de frescura visible (HU-05), estado sin datos con tono de bienvenida y nunca `$0` (HU-07), y la elección del dato a mostrar. **Nada de eso es alcance de esta entrega.**

### HU-05 — Restricciones de plataforma: interacción y refresco

Como equipo queremos que el widget no prometa comportamientos que la plataforma no permite.

**Criterios de aceptación:**
- **iOS (WidgetKit) no ejecuta código libre ni se refresca en vivo.** La extensión entrega una *timeline* de entradas ya renderizadas y el sistema decide cuándo pedir la siguiente, con un presupuesto diario de refrescos que administra y puede recortar. **Con el alcance de atajo puro esto deja de ser un problema:** un widget cuyo contenido es un conjunto fijo de botones no tiene nada que refrescar, así que no puede quedar desactualizado. El único momento en que su contenido cambia es cuando el usuario edita su configuración (HU-03), y eso ya dispara una recarga del timeline.
- **Android** actualiza por `updatePeriodMillis` (con un piso del sistema) o por una actualización explícita que dispare la app. Por la misma razón, el widget **no necesita ninguna actualización periódica**: se declara sin refresco periódico, lo que además evita consumo de batería innecesario.
- **Interacción dentro del widget:** Android permite acciones que ejecutan trabajo sin abrir la app; **iOS solo desde iOS 17** y limitado a un `Button`/`Toggle` con una *App Intent* acotada. En ninguna de las dos plataformas se registrará una transacción desde el widget: contradice el modelo de confirmación de Fase 2 (nada se registra sin que el usuario lo vea y confirme). **Los botones del widget navegan; no escriben.**
- El widget no hace red, no consulta Supabase y no dispara sync por su cuenta.

### HU-06 — Tamaños y variantes

Como usuario quiero elegir cuánto espacio le doy al widget en mi pantalla de inicio y que lo que muestre tenga sentido en ese tamaño.

**Criterios de aceptación:**
- **Android:** el widget es redimensionable; se declara un tamaño mínimo y se soportan al menos dos formas — **compacta** (≈2×1: 1–2 atajos) y **mediana** (≈4×2: fila de atajos completa). Android permite un rango continuo, así que el layout debe **degradar por ancho disponible** (mostrar menos atajos, nunca apretarlos hasta que dejen de ser tocables), no asumir una grilla fija.
- **iOS:** se soportan las familias `systemSmall` y `systemMedium`. `systemLarge` **queda fuera de alcance** — con atajo puro no hay contenido que justifique esa superficie.
  - `systemSmall` en iOS **admite un solo toque para toda la superficie** (un único destino), no varios botones con destinos distintos, salvo que se usen App Intents de iOS 17+. Por eso la variante pequeña de iOS es, por construcción, **un solo atajo** (el que el usuario configure en HU-03) — no una fila de cuatro. Es una diferencia real de plataforma, no una omisión.
  - `systemMedium` sí admite zonas con destinos distintos vía deep links.
- Widgets de **pantalla de bloqueo** (iOS `accessoryCircular`/`accessoryRectangular`) quedan **fuera de alcance inicial**. Con atajo puro ya no hay una objeción de privacidad que lo impida (no muestran cifras), pero sí una de utilidad: un atajo de captura en la pantalla de bloqueo lleva igualmente a desbloquear el teléfono para llegar al formulario, así que ahorra poco. Reevaluable como mejora posterior.
- Cada variante debe ser cómoda de tocar: un widget compacto con cuatro botones diminutos es un fallo de accesibilidad, no una variante válida (ver §Reglas de negocio).

### HU-07 — Comportamiento sin datos (usuario nuevo, app nunca abierta)

Como usuario que acaba de instalar la app quiero que el widget me sirva desde el primer momento.

**Criterios de aceptación:**
- **Los atajos funcionan siempre**, incluso si la app nunca se ha abierto y no hay ni una cuenta ni una transacción: son deep links, no dependen de ningún dato compartido. **Este era el argumento más fuerte a favor del atajo puro y con la decisión pasa a ser el comportamiento normal, no un caso borde.**
- No existe estado "sin datos", "cargando" ni "error" en el widget: no hay dato que cargar. El widget se ve igual el primer día y el día mil.
- **Sin cuentas activas** (el gate de `fase-1/15-gate-cuenta.md`): tocar un atajo de captura abre la app, que ofrece crear la cuenta en el momento y **continúa al formulario original**. El widget **no** deshabilita ni oculta sus botones por esta razón — el gate es un puente, no un muro, y el widget de todos modos no puede saber si hay cuentas sin leer datos.
- **Sin presupuesto, sin transacciones, sin sesión iniciada:** ninguno de esos estados cambia lo que muestra el widget.

### HU-08 — Privacidad

Como usuario quiero que el widget no le muestre mi situación financiera a quien tome mi teléfono o mire por encima de mi hombro.

**Resuelto por el alcance (decisión 2026-08-17):** el widget **no muestra ninguna cifra**, así que no filtra nada. Un botón que dice "Gasto" o "Voz" no revela información financiera. No hay ajuste de "ocultar montos" que decidir, ni preferencia local que espejar, ni dependencia de un bloqueo de app.

**Hallazgo que se conserva (sigue siendo cierto y relevante fuera de esta feature):** la app **no tiene hoy bloqueo biométrico ni bloqueo por PIN** — no existe `local_auth` en `pubspec.yaml` ni ninguna pantalla de bloqueo en `lib/`; lo único cifrado es el número de cuenta, en `flutter_secure_storage`. Es decir, **no hay un estado "app bloqueada"** al que ninguna superficie pueda consultar. Consecuencias:

- Cualquier futura decisión que dependa de "ocultar esto cuando la app está bloqueada" (incluido el widget informativo de HU-04, si se retoma) **depende primero de que ese bloqueo exista**, y hoy no está en ningún requisito de Fase 1 ni Fase 2.
- Mientras no exista, **ningún widget de esta feature se instala en la pantalla de bloqueo** con contenido que no sea un botón de navegación.

**Criterios de aceptación:**
- El widget no muestra montos, saldos, nombres de comercio, números de cuenta ni entidad bancaria. Nunca.
- Las etiquetas de los atajos son genéricas ("Gasto", "Ingreso", "Voz", "Foto", "Pendientes") y no revelan estado alguno de la cuenta del usuario — en particular, **el atajo de Pendientes no lleva contador** (HU-02).

### HU-09 — Localización del widget (es/en)

Como usuario quiero que el widget esté en mi idioma, igual que la app.

**Criterios de aceptación:**
- El widget se muestra en **español o inglés** según el idioma del sistema, con la misma paridad de contenido que la app.
- **El widget vive fuera de `AppLocalizations`**: el sistema de l10n de Flutter (`lib/core/l10n/arb/app_es.arb` + `app_en.arb`) genera código Dart que **el proceso del widget no puede ejecutar**. Los textos del widget tienen que existir como recursos nativos: `res/values/strings.xml` + `res/values-es/strings.xml` en Android, y `Localizable.strings` (o String Catalog) por idioma en la extensión de iOS.
- **Regla derivada:** el widget tiene un juego de strings **duplicado** respecto a los `.arb`. Es duplicación real e inevitable — la regla `avoid_hardcoded_ui_strings` sigue aplicando a `lib/`, y el equivalente nativo es "ningún literal en el layout/SwiftUI, todo desde el recurso localizado". Ninguna de las dos plataformas admite un literal en el árbol de UI del widget.
- **El alcance de atajo puro mantiene ese juego de strings mínimo**: cinco etiquetas de atajo, el nombre del widget y su descripción en el selector del sistema. Sin datos no hay etiquetas de métrica, ni marcas de frescura, ni estados vacíos que traducir — y por tanto casi no hay superficie donde los `.arb` y los recursos nativos puedan desfasarse.
- Al no mostrar montos, **el widget no formatea moneda**, así que no hereda el problema de separadores/posición de símbolo entre es-CO, es-MX, es-AR y en-US.
- **Pendiente de decidir: ¿el widget sigue el idioma del sistema o el idioma elegido dentro de la app?** Si la app llega a ofrecer un selector de idioma propio (hoy sigue el sistema), el widget no lo heredaría automáticamente: habría que espejar esa preferencia al almacén compartido — justo el mecanismo que la decisión de alcance evitó construir. Mientras la app siga el sistema, no hay conflicto; si se añade selector propio, la opción barata es que el widget siga usando el idioma del sistema y se documente la diferencia.

### HU-10 — Tema claro y oscuro

Como usuario quiero que el widget se vea parte de mi pantalla de inicio y de mi app, en el tema que tenga puesto.

**Criterios de aceptación:**
- **El widget sigue el tema del SISTEMA (decisión 2026-08-17), no el elegido en Ajustes → Apariencia.** Racional: la preferencia de tema de la app vive en `shared_preferences` (`fase-1/14-apariencia.md`), dentro del sandbox de la app, y leerla desde el widget exigiría espejarla a un almacén compartido — es decir, montar el App Group de iOS y el puente de datos entre procesos que la decisión de alcance eliminó. Construir toda esa infraestructura únicamente para el color del widget no se justifica, y además seguir el tema del sistema es lo que esperan las guías de ambas plataformas para un widget de pantalla de inicio. **Consecuencia asumida y documentada:** un usuario que fuerza tema claro en la app con el sistema en oscuro verá el widget oscuro. Es una divergencia visible, aceptada a cambio de no cargar la feature con un espejo de datos.
- Los colores se derivan de las variables del sistema de diseño (`billetudo.pen`), replicadas como recursos nativos por tema: `res/values/colors.xml` + `res/values-night/colors.xml` en Android, *color assets* con variante Any/Dark en iOS. **Ningún hex suelto en el layout del widget** — misma regla que en la app, aplicada al lado nativo.
- Contraste verificado en ambos temas sobre **fondos de wallpaper arbitrarios**: a diferencia de la app, el widget no controla lo que hay detrás. El fondo del widget debe ser opaco (`$surface`) o el texto debe llevar su propia superficie; nada de texto directamente sobre un fondo translúcido.

## Reglas de negocio y edge cases

- **Nada se registra sin confirmación humana.** El widget nunca escribe una transacción. Sus botones navegan a un formulario que el usuario ve y confirma. Esto es el modelo de confirmación de Fase 2 y no es negociable, ni siquiera donde la plataforma lo permitiría técnicamente (App Intents de iOS 17+, acciones de Glance).
- **El widget no lee ni expone datos de negocio** (decisión de alcance 2026-08-17). Cualquier propuesta futura de mostrar una cifra reabre HU-04 completa, con su costo; no se cuela como "un detallito más".
- **`source` de la transacción resultante:** un gasto capturado tras tocar el widget termina siendo `manual`, `voice` u `ocr` según el destino al que el widget llevó, no un `source` propio del widget. El widget es navegación, no un origen de captura. **Pendiente de decidir: ¿interesa medir cuántas capturas nacen del widget?** Si sí, no se hace con `source` (rompería la semántica de "cómo se capturó el dato" que los cupos usan) sino con una marca aparte; y hoy la app no tiene analítica de producto, así que sería una decisión nueva.
- **Nivel 0 intacto:** el widget y todos sus atajos son gratis, ilimitados y sin anuncios. Un widget con publicidad sería exactamente el "anuncio ambiental" que `CLAUDE.md` prohíbe.
- **Multi-moneda: no aplica.** El widget no muestra montos, así que no hay ningún total que pudiera mezclar monedas (`fase-1/12-multi-moneda.md`). Reaparecería solo con HU-04.
- **Coherencia con el Home: no aplica**, por la misma razón. El widget no puede contradecir una cifra del Home porque no muestra ninguna.
- **Widget añadido y app desinstalada/reinstalada:** el widget queda huérfano; el sistema lo retira o lo deja inerte. Al reinstalar, el usuario lo vuelve a añadir — no se intenta restaurar el estado previo.
- **Múltiples instancias:** el usuario puede poner varios widgets con configuraciones distintas (Android lo permite por instancia). Cada instancia guarda su propia configuración de atajos; no hay estado compartido entre ellas.
- **El widget no dispara sync, ni red, ni trabajo en segundo plano.**
- **Accesibilidad:** cada zona tocable lleva su descripción de contenido / *accessibility label* localizada, y el área tocable cumple el mínimo de la plataforma.
- **Tono:** aplica igual que dentro de la app. Al no mostrar cifras, el widget **no puede** caer en la trampa de tono que sí tendría uno informativo (ver §Diseño).

## Diseño

El widget es **superficie de marca fuera de la app**: para muchos usuarios será lo único de billetudo que vean en el día. Debe leerse como billetudo, no como un botón genérico del sistema.

- **Paleta:** las variables del sistema de diseño (`design-system/billetudo/MASTER.md`, fuente de verdad `billetudo.pen`), replicadas como recursos nativos por tema (HU-10). Fondo `$surface`, marca `$primary`, texto `$text-primary`/`$text-secondary`. **Ningún hex hardcodeado.**
- **Tipografía:** Plus Jakarta Sans, la misma de la app. Los `.ttf` ya están en `assets/fonts/`, pero **el widget nativo no accede a los assets de Flutter**: la fuente debe empaquetarse también del lado nativo (`res/font/` en Android, la fuente añadida al target de la extensión en iOS). Si eso resultara inviable, el fallback es la fuente del sistema — y eso es una decisión de diseño, no un detalle: cambia cómo se ve la marca. Con atajo puro el texto del widget se reduce a unas pocas etiquetas cortas, lo que hace el empaquetado de la fuente barato y su ausencia más notoria.
- **Tono (regla crítica de `CLAUDE.md`).** El alcance elegido **elimina la trampa de tono más peligrosa del widget**: un widget informativo que muestre **"te quedan $0"** o un **rojo agresivo** al agotarse el presupuesto se ve en la pantalla de inicio **todo el día, sin que el usuario haya entrado a mirarlo** — un regaño dentro de la app dura lo que dura la pantalla, en un widget es permanente. Sin cifras, no hay regaño posible. Las reglas siguen escritas por si HU-04 se retoma: tono neutral y de progreso al superar un límite, el gasto **nunca** en `$expense` (es el rojo de alertas y deuda real), y nada de semáforo por cercanía al límite.
- **El diseño real se hace en `billetudo.pen` con `pencil-designer` antes de implementar**, siguiendo el flujo por feature de `CLAUDE.md`: variantes en tema claro → elección → `design-system/billetudo/pages/widget-captura.md` → refinamiento auditado por `ui-ux-reviewer` → tema oscuro al final. **No se implementa UI contra el `.md` solo.** El widget necesita frames propios por tamaño y plataforma (Android compacto/mediano, iOS small/medium), porque las restricciones de cada uno cambian la composición (HU-06) — en particular, el `systemSmall` de iOS es **un solo atajo**, no una fila reducida.
- Consideración de composición: el widget compite con los íconos de la pantalla de inicio, no con otras pantallas. Densidad baja, foco único, toque cómodo.

## Cambios de esquema requeridos (Drift)

**Ninguno.** `schemaVersion` no cambia por esta feature. Evaluado explícitamente:

- Con el alcance de atajo puro, el widget **no lee ni escribe datos de negocio**. No hay agregados que calcular ni entidades que añadir.
- **No hay espejo de datos compartido** que persistir (decisión de alcance). Si algún día lo hubiera, seguiría sin ser una tabla: sería un archivo de preferencias nativo, derivado y desechable — guardarlo en Drift sería un error, porque PowerSync sincronizaría un dato puramente local y recalculable.
- La configuración por instancia del widget (HU-03) vive en el mecanismo de configuración de cada plataforma, no en la base.
- No se añade ninguna preferencia en `shared_preferences`: el tema lo resuelve el sistema (HU-10) y no hay ajuste de privacidad que guardar (HU-08).

**Coordinación de versiones dentro de Fase 2 (para evitar colisión):** `19-notificaciones-bancarias.md` toma el primer número libre y `18-captura-ocr.md` el siguiente (al 2026-08-17 serían 28 → 29 y 29 → 30). Este documento **no consume ningún número**, así que puede entregarse en cualquier orden respecto a esos dos sin conflicto de migración.

## Dependencias y configuración nativa nueva

Nada de esto existe hoy en el repo; todo hay que añadirlo. La lista es **notablemente más corta** que la de un widget informativo:

| Necesidad | Estado hoy | Qué hay que hacer |
|---|---|---|
| Puente Flutter ↔ widget nativo (registrar/actualizar el widget, recibir el deep link) | **No existe** ningún paquete de widgets en `pubspec.yaml` (`home_widget` no está declarado) | Declarar `home_widget` **o** escribir un `MethodChannel` propio. **Pendiente de decidir:** el paquete ahorra el puente, pero con atajo puro el puente que hace falta es mínimo (no hay que escribir datos compartidos), lo que **inclina la balanza hacia el canal propio** — una dependencia menos de terceros en una app de finanzas. Decisión del dueño de producto/técnico. |
| **App Group (iOS)** | No configurado (`ios/Runner/Runner.entitlements` no declara ninguno) | **NO REQUERIDO en esta entrega.** Sin datos compartidos entre procesos no hace falta. Sería obligatorio solo si se retomara HU-04. |
| **Espejo de datos entre procesos** | No existe | **NO REQUERIDO en esta entrega** (decisión de alcance). |
| **Ejecución en segundo plano** | No existe (`workmanager` no está declarado) | **NO REQUERIDO.** No hay nada que refrescar (HU-05). Evita permisos y preguntas de las tiendas. |
| Target de widget extension (iOS) | **No existe**; solo está el target `Runner` | Añadir la extensión WidgetKit al proyecto Xcode y al `Podfile`. |
| Módulo de App Widget (Android) | **No existe** | `AppWidgetProvider`/`GlanceAppWidget`, `appwidget-provider` XML, entrada en el `AndroidManifest`, y la *configuration activity* de HU-03. |
| Deep links a los destinos de captura | Rutas de `go_router` ya existen para el formulario de transacción; **no hay** rutas para voz ni OCR (`lib/features/capture/` está vacío) | Definir rutas parametrizadas (tipo de transacción preseleccionado, modo de captura) y verificar el arranque en frío. Depende de `17` y `18`. |
| Strings y colores nativos por idioma y tema | **No existen** (todo el l10n vive en `.arb`) | `strings.xml`/`values-es`, `colors.xml`/`values-night` en Android; `Localizable.strings` y color assets en iOS (HU-09/HU-10). Juego mínimo. |
| Fuente Plus Jakarta Sans en el lado nativo | Los `.ttf` están en `assets/fonts/` pero no empaquetados para nativo | Añadirlos a `res/font/` y al target de la extensión, o aceptar la fuente del sistema (§Diseño). |

`ios/Runner/Info.plist` **no declara** hoy `UIBackgroundModes` ni ningún `*UsageDescription`. Los `*UsageDescription` de micrófono y cámara los introducen `17-captura-voz.md` y `18-captura-ocr.md`, no este documento; **el widget no añade ningún permiso propio, ningún modo de background y ningún entitlement.**

## Entrega

**Una sola entrega** (el alcance de atajo puro ya no justifica partirla en fases): HU-01, HU-02, HU-03, HU-05, HU-06, HU-07, HU-08, HU-09, HU-10.

**Requisito previo:** que existan los destinos a los que el widget lleva — `17-captura-voz.md` y `18-captura-ocr.md` implementados, y `19-notificaciones-bancarias.md` si se incluye el atajo a Pendientes (HU-02). El registro manual (`fase-1/03-transacciones.md`) ya existe, así que HU-01 es lo único entregable hoy sin dependencias de fase.

## Decisiones tomadas

| # | Decisión | Fecha |
|---|---|---|
| 1 | **El widget es atajo puro**: no muestra ningún dato financiero (HU-04 descartada) | 2026-08-17 |
| 2 | Ambas plataformas a la vez: Android (App Widget/Glance) + iOS (WidgetKit) | 2026-08-17 |
| 3 | **Sin App Group ni espejo de datos** entre procesos — no requeridos en esta entrega | 2026-08-17 |
| 4 | **Privacidad resuelta por construcción**: sin cifras no hay filtración. Se conserva el hallazgo de que la app **no tiene bloqueo biométrico ni PIN** | 2026-08-17 |
| 5 | **Sin problema de frescura**: un widget sin datos no envejece; sin refresco periódico en ninguna plataforma | 2026-08-17 |
| 6 | Atajo a la bandeja de pendientes bancarios permitido, **sin contador** (el contador exigiría espejo) y solo en Android | 2026-08-17 |
| 7 | **El widget sigue el tema del sistema**, no el de Ajustes → Apariencia (leerlo exigiría el espejo descartado) | 2026-08-17 |
| 8 | **Multi-moneda no aplica** al widget: no muestra montos | 2026-08-17 |
| 9 | **Sin cambios de esquema**; `schemaVersion` no cambia | 2026-08-17 |

## Pendientes de decidir (vivos)

1. **HU-03 — ¿conjunto de atajos por defecto o configuración obligatoria al añadir?** (iOS no puede obligar, así que necesitaría un default de todas formas).
2. **HU-09 — ¿el widget sigue el idioma del sistema o el de la app**, si la app llega a tener selector propio de idioma? (heredar el de la app exigiría el espejo descartado).
3. **§Reglas — ¿se mide cuántas capturas nacen del widget?** No vía `source` (rompería la semántica de cupos); hoy no hay analítica de producto.
4. **§Dependencias — ¿`home_widget` o puente nativo propio?** Con atajo puro el puente necesario es mínimo, lo que inclina hacia el propio, pero no está decidido.

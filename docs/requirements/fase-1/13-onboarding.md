# Feature: Onboarding (flujo de bienvenida)

**Nivel:** 0 (gratis, sin anuncios, sin cuenta requerida)
**Depende de:** `01-cuentas.md` (HU-01, HU-08), `02-categorias.md` (HU-06), `04-inicio.md` (HU-02 FAB, HU-08 estado vacío), `05-auth-sync.md` (HU-01/HU-02/HU-04, decisión #12)
**Se partió en tres documentos** (ver "Documentos hermanos"): `15-gate-cuenta.md` (la app sin cuentas) y `16-minitutoriales.md` (ayuda contextual por feature)
**Tabla Drift:** ninguna propia — un latch nuevo (`onboardingCompleted`) en el singleton `AppSettings`
**Diseño (billetudo.pen):** **no existe todavía**. Aplica el flujo "diseño primero" de CLAUDE.md: `pencil-designer` propone variantes → el usuario aprueba → se documenta `design-system/billetudo/pages/onboarding.md` → recién entonces `flutter-dev` implementa. **No se implementa UI contra este documento solo.**

## Contexto

Primera experiencia del usuario, antes de cualquier login. Debe llevarlo de "app recién instalada" a "puede registrar su primer movimiento" con la menor fricción posible, coherente con el principio local-first: **la app se usa sin cuenta y sin red** (salvo la excepción del catálogo de categorías, ya documentada).

**Estado real del código (2026-07-27) — punto de partida, no lienzo en blanco:**

- No existe `lib/features/onboarding/`. Hoy la app arranca directo en el Home (`initialLocation: AppRoutes.home`, `lib/core/router/app_router.dart`).
- El primer arranque ya hace dos cosas que este documento **no debe rehacer**: `bootstrap.dart` siembra el catálogo de categorías desde Supabase (idempotente vía el latch `AppSettings.categoriesSeeded`) y, si no hay red en ese primer arranque, `FirstLaunchOfflineGate` bloquea con pantalla de reintento. Ese gate corre **antes** del onboarding y es independiente de él.
- El Home ya tiene estado vacío diseñado y construido (`04-inicio.md` HU-08), que es la red de seguridad para todo lo que el usuario salte aquí.

Por eso el onboarding **no** es "todo lo que pasa la primera vez": es un flujo corto y acotado que aporta lo que hoy falta — encuadre de la promesa, la primera cuenta, el respaldo en la nube y la invitación al primer movimiento.

### Documentos hermanos

Enseñar la app son **tres trabajos con ciclos de vida distintos**, y por eso viven en tres documentos. Este cubre solo el primero:

| Documento | Qué cubre | Ciclo de vida |
|---|---|---|
| **`13-onboarding.md`** (este) | El flujo de bienvenida: promesa, primera cuenta, respaldo, primer movimiento | Corre **una vez** y se cierra para siempre |
| **`15-gate-cuenta.md`** | Qué pasa en la app cuando no hay ninguna cuenta activa | Regla **permanente**; se dispara cuando aplica |
| **`16-minitutoriales.md`** | Ayuda contextual por feature y por sub-flujo | **Permanente**, siempre reabrible |

**El gate y los minitutoriales no son opcionales para este flujo:** omitir la cuenta (decisión #2) solo es viable si el gate existe, y lo que el onboarding no puede enseñar sin volverse un tour de diez pantallas lo enseña el minitutorial en su contexto. Ver "Orden de entrega".

## Decisiones cerradas (2026-07-27)

Estas nueve decisiones fijan el alcance; reemplazan lo que el documento anterior dejaba abierto.

1. **Las categorías semilla no son un paso del onboarding.** Se siembran en silencio en el primer arranque (comportamiento actual de `bootstrap.dart`), completas. El onboarding a lo sumo lo **menciona en una línea** ("ya te dejamos categorías listas; edítalas cuando quieras"). Se descartó la pantalla de selección/deselección: obliga a mover el seeding fuera de `bootstrap`, agrega una pantalla de 60+ ítems al primer minuto de uso y pide una decisión que el usuario todavía no tiene criterio para tomar. Depurar categorías es una tarea de mantenimiento, no de arranque, y ya vive en Categorías (HU-03/HU-04 de `02-categorias.md`).
2. **Ningún paso es obligatorio: la primera cuenta se propone pre-llenada, pero se puede omitir.** No se obliga al usuario a crear nada para entrar a la app — obligarlo castiga sobre todo a quien **ya tiene sus datos en la nube** y solo quiere iniciar sesión (ver #5). La fricción se ataca por pre-llenado, no por imposición: nombre "Ahorros" (localizado), tipo `savings`, moneda según la región del dispositivo, saldo inicial 0 — un toque en "Listo" y sigue; o "Omitir" y entra igual. **Cambiado el 2026-07-29** de `cash`/"Efectivo" a `savings`/"Ahorros" como default: es el tipo de cuenta más común entre usuarios reales, más que efectivo. Se descartó crear una cuenta implícita al omitir (aparece un dato que el usuario no creó y no entiende de dónde salió).
3. **La consecuencia de omitir se maneja donde duele, no en el onboarding: un gate de "necesitas una cuenta" en toda la app**, documentado aparte en **`15-gate-cuenta.md`**. Sin cuentas activas, los formularios que no pueden existir sin una (`Transactions.accountId` y `ScheduledPayments.accountId` son NOT NULL) **no se abren**: se ofrece crear la cuenta en el momento y continuar. **No es un parche de onboarding** — cualquier usuario puede quedarse sin cuentas activas archivándolas todas (`01-cuentas.md` HU-08).
4. **Flujo lineal de pantallas completas antes del Home, que se cierra para siempre al terminarlo.** No es una capa sobre el Home ni un checklist persistente. Criterio de cierre: **el usuario llegó al final del flujo y actuó** — sin condición sobre cuántas cuentas creó. Mientras el latch esté apagado, el flujo vuelve a aparecer al abrir la app; una vez encendido no se reabre nunca (para el usuario sin cuentas está `15-gate-cuenta.md` y el estado vacío del Home).
5. **El onboarding ofrece "Ya tengo cuenta"** (HU-06), como acción secundaria hacia el login existente. Es una excepción explícita y acotada al "no se solicita login en ningún paso" de HU-01: se **ofrece**, nunca se pide ni se pone como acción principal.
6. **HU-05 (comunicar el modelo gratis/opt-in) queda congelada, no eliminada.** Hoy no existe ninguna feature monetizada, ni IA, ni gráficas avanzadas, y los SDKs de tienda/anuncios están deliberadamente sin instalar. Mencionar extras inexistentes en el primer minuto de uso es prometer lo que no se puede tocar. **Condición de activación:** cuando exista la primera feature de Nivel 1 real. Ver "Fuera de alcance de la v1".
7. **El respaldo en la nube se enseña dentro del onboarding, con acción opcional en caliente** (HU-07). Es una pantalla que explica qué es, que es gratis y qué se pierde sin él, con un CTA "Activar respaldo" que lleva al login social y un "Después" igual de alcanzable. Se descartó dejarlo solo como mención informativa (pierde al usuario que en ese momento sí quería activarlo) y también dejarlo únicamente para un recordatorio posterior en el Home. **No convierte el login en requisito:** sigue siendo saltable y el latch se enciende igual.
8. **Lo que el onboarding no alcanza a enseñar lo enseñan los minitutoriales**, en hojas de bienvenida al primer acceso de cada feature (no coach marks). Alcance, forma y persistencia en **`16-minitutoriales.md`**. Ningún minitutorial se muestra mientras el flujo de bienvenida está activo.
9. **Las tres piezas se documentan por separado y se entregan en orden** (ver "Orden de entrega"), porque tienen ciclos de vida distintos y tamaños muy distintos: el flujo es la más pequeña de las tres.

## Secuencia real del flujo

La numeración de las HU es estable e histórica; **el orden de las pantallas es este**:

1. **Bienvenida** (HU-01) — con el enlace secundario "Ya tengo cuenta" (HU-06).
2. **Tu primera cuenta** (HU-02) — pre-llenada y omitible.
3. **Respalda tus datos** (HU-07) — explica el respaldo; "Activar respaldo" o "Después".
4. **Cierre: tu primer movimiento** (HU-04) — registrar o explorar.

HU-03 (categorías) no es una pantalla: se menciona en una línea. HU-05 está congelada. El gate de cuenta (`15`) y los minitutoriales (`16`) no son parte del flujo: viven en la app para siempre.

## Historias de usuario

### HU-01 — Bienvenida sin fricción
Como usuario nuevo quiero entender en pocos segundos qué hace la app y que puedo usarla sin crear cuenta, para decidir seguir sin barreras de entrada.

**Criterios de aceptación:**
- **No se solicita login ni email en ningún paso.** Iniciar sesión nunca es requisito, ni acción principal, ni condición para avanzar. **Única excepción, deliberada:** el enlace secundario "Ya tengo cuenta" de HU-06, que *ofrece* el login a quien viene con datos en la nube. Nunca se pide email/contraseña (solo social, regla no negociable).
- El mensaje deja claro que el Nivel 0 es **completo y gratis para siempre** — no "gratis por ahora", no "prueba", no cuenta regresiva. Evitar la sensación de "cebo" identificada como riesgo en la investigación de mercado (`docs/Viabilidad_App_Finanzas_Personales.md`).
- **Máximo una pantalla de bienvenida.** Sin carrusel de 4 slides ni tour de features: la promesa se comunica en una pantalla y se avanza. Si el diseño necesita más de una, se justifica en `pages/onboarding.md`, no se asume.
- Se menciona que **los datos viven en el dispositivo** y que respaldar en la nube es opcional y posterior (coherente con `05-auth-sync.md` HU-01, sin convertirlo en un CTA aquí).
- Copy en tono positivo y de progreso; nunca lenguaje de culpa ni de control ("deja de gastar mal", "toma el control de tus deudas").
- Localizado en es + en desde `AppLocalizations` (regla `avoid_hardcoded_ui_strings`).

### HU-02 — Crear la primera cuenta
Como usuario nuevo quiero que se me guíe a crear mi primera cuenta como parte del flujo inicial, para poder registrar mi primera transacción sin fricción.

**Criterios de aceptación:**
- **Omitible.** La acción principal crea la cuenta; una acción secundaria explícita ("Omitir" / "Lo hago después") entra a la app sin crear nada. Se descartó volverlo obligatorio: la app sin cuentas es un estado legítimo y ya manejado (`15-gate-cuenta.md`), y obligar castiga a quien solo quiere iniciar sesión (HU-06).
- **Es el paso recomendado, y el diseño debe mostrarlo así**: la acción de crear es la prominente; "Omitir" es visible pero secundaria, sin lenguaje de advertencia ni culpa. Puede acompañarse de una línea neutra sobre lo que habilita ("con una cuenta ya puedes registrar movimientos").
- **Reutiliza el formulario de `01-cuentas.md` HU-01** (mismo caso de uso `CreateAccount`, mismas validaciones, mismos widgets de selección), **simplificado por defecto**: se muestran nombre, institución (`showInstitutionField`), tipo, moneda y saldo inicial. Se ocultan número de cuenta/`last4`, `interestRateBps`, ícono y color — todos opcionales y editables después desde Cuentas. **Cambiado el 2026-07-30:** institución dejó de estar oculta — se muestra igual que en el formulario completo, condicionada al tipo de cuenta (oculta solo para `cash`, que no tiene institución; mismo criterio que ya usa `showInterestRateField`). **Nada de una segunda implementación del formulario**: si el diseño exige una variante compacta, es una variante del mismo widget, no un formulario paralelo.
- **Pre-llenado con valores por defecto razonables**, todos editables:
  - nombre: "Ahorros" (localizado);
  - tipo: `savings`;
  - moneda: **siempre COP** (mercado principal de la app). **Cambiado el 2026-07-30**: la versión anterior de esta decisión la derivaba de la región del locale del dispositivo (CO → COP, MX → MXN, AR → ARS, CL → CLP, PE → PEN, ES → EUR, US → USD…, con fallback a USD y luego a COP para región desconocida). Se abandonó por completo tras confirmar en pruebas reales que la región del locale es una preferencia de idioma/formato del usuario, no su ubicación física — un dispositivo en Colombia resolvió primero a España (`ES`) y luego, tras corregir el idioma, a un "Región: US" del sistema, ninguno de los dos reflejando el país real. El picker de monedas hoy solo ofrece COP/USD de todos modos. La moneda **siempre es editable** aquí — nunca se fija en silencio.
  - saldo inicial: 0.
- Si el usuario elige `type = card`, aplican **sin excepción** las reglas de `01-cuentas.md` HU-02 (cupo máximo obligatorio, día de corte, día de pago). El onboarding no relaja validaciones del dominio; si eso hace el paso largo, el diseño puede sugerir "empieza con efectivo o banco, la tarjeta la agregas después", pero no bloquea la elección.
- **Cambiado el 2026-07-29:** el paso ya no ofrece "Agregar otra" cuenta. Se limita a una sola cuenta (la pre-llenada, editable) y avanza directo al siguiente paso — permitir crear varias alargaba el onboarding sin necesidad; agregar cuentas adicionales es una tarea normal de mantenimiento en Cuentas, no del arranque. Se descartaron las variantes de referencia que mostraban ese estado.
- La cuenta creada aquí es un dato normal: editable, archivable y con lápida como cualquier otra (`01-cuentas.md` HU-06/HU-08). No queda marcada como "cuenta de onboarding".
- **Sin conexión el paso funciona igual** — es una escritura local en Drift.

### HU-03 — Categorías listas de entrada (sin paso)
Como usuario nuevo quiero partir de un set de categorías comunes en español ya creadas, para no tener que pensar en mi estructura de categorías antes de registrar mi primer gasto.

**Criterios de aceptación:**
- **No hay pantalla de selección de categorías** (decisión cerrada #1). El catálogo semilla completo ya está sembrado cuando el usuario llega al onboarding, por `bootstrap.dart` (`SeedDefaultCategories`, latch `categoriesSeeded`).
- El onboarding puede **mencionarlo en una línea** dentro de otra pantalla (bienvenida o cierre) e invitar a editarlas después. No es un paso, no tiene CTA propio ni pantalla propia.
- El set, sus ids estables (`seed-*`), su origen en Postgres (`category_seeds`) y las reglas de idempotencia y de fusión al iniciar sesión están definidos en **`02-categorias.md` HU-06 y su apéndice** — este documento no los duplica ni los redefine.
- Las categorías semilla son datos normales y editables (`02-categorias.md` HU-03/HU-04): el usuario que no las quiera las borra desde Categorías, no desde el onboarding.
- **Caso sin red en el primer arranque:** lo resuelve `FirstLaunchOfflineGate` **antes** de que el onboarding se monte. El onboarding nunca ve un estado "categorías a medio sembrar": o el gate ya pasó, o la app todavía no llegó aquí.

### HU-04 — Registrar la primera transacción guiada
Como usuario nuevo quiero que se me invite a registrar mi primera transacción justo después de crear la cuenta, para experimentar el flujo core de la app de inmediato.

**Criterios de aceptación:**
- Pantalla de cierre con un CTA claro ("Registra tu primer movimiento") y una acción secundaria explícita para saltar ("Lo hago después" / "Explorar la app").
- **Si el usuario omitió la cuenta (HU-02), esta pantalla cambia de CTA**: en vez de abrir el formulario de movimiento — que no puede existir sin cuenta — invita a crear la cuenta, con el mismo copy y comportamiento del puente de `15-gate-cuenta.md`. No se muestra un CTA que al tocarlo choque contra un bloqueo.
- El CTA abre **el flujo real de creación de transacción** (`03-transacciones.md`), no una versión de demostración ni datos de ejemplo. **Prohibido sembrar transacciones falsas** para que el Home "se vea lleno": ensucia saldos y reportes reales.
- Este paso es **opcional**. Saltarlo lleva al Home, cuyo estado vacío (`04-inicio.md` HU-08) ya invita a registrar el primer movimiento — la guía continúa ahí, sin duplicar lógica.
- **El onboarding se da por terminado al llegar a esta pantalla y actuar en ella** (registrar o saltar), no al guardar la transacción. Si el usuario abre el formulario y lo cancela, vuelve al Home con el onboarding ya cerrado — no queda atrapado en el flujo.
- Registrar la primera transacción aquí no dispara ninguna celebración ni bloqueo; es una transacción normal.

### HU-05 — Comunicar el modelo gratis/opt-in sin presión — **congelada**
Como usuario nuevo quiero entender, sin sentirme presionado, que existen features extra opcionales, para saber que existen sin que se me empuje a pagar.

**Estado:** fuera de alcance de la v1 (decisión cerrada #4). Se activa cuando exista la primera feature de Nivel 1 real (IA de captura o gráficas avanzadas) **ya construida y usable**. Los criterios de aceptación se conservan para ese momento:

- Se menciona de forma breve y no intrusiva (una pantalla informativa **opcional** al final del onboarding), nunca un paywall.
- No se presenta paywall, cuenta regresiva de prueba gratis, ni solicitud de pago durante el onboarding.
- Coherente con "Nivel 0 completo y sin anuncios" desde el primer uso.
- La pantalla no puede convertirse en un paso obligatorio del flujo cuando se active.

Mientras tanto, el mensaje de la v1 es solo el de HU-01: Nivel 0 completo y gratis.

### HU-06 — "Ya tengo cuenta"
Como usuario que reinstala la app o estrena teléfono quiero recuperar mis datos sin tener que inventar una cuenta nueva, para no empezar de cero ni quedar con datos duplicados.

**Problema que resuelve:** el latch de onboarding es local, así que un usuario con datos en la nube que reinstala ve el flujo completo desde cero. Si el flujo lo obligara a crear una cuenta antes de poder llegar a Ajustes → Respaldar, tras la fusión (`05-auth-sync.md` HU-04) le quedarían sus cuentas reales **más** una "Efectivo" que la app lo forzó a inventar, justo en el momento de re-enganche.

**Criterios de aceptación:**
- **Acción secundaria "Ya tengo cuenta"** en el flujo (bienvenida y/o paso de cuenta), que lleva a la pantalla de respaldar/login ya existente (`05-auth-sync.md` HU-02/HU-03). Reusa esa pantalla; no se construye un login propio del onboarding.
- **Ofrecer no es solicitar.** Es visualmente secundaria, nunca la acción principal, y no bloquea nada: quien la ignore completa el flujo igual.
- Si el usuario **cancela el login** o falla, vuelve al paso del onboarding donde estaba, sin perder lo que ya hubiera creado y sin mensaje de error acusatorio.
- Si el login **tiene éxito**, corre la fusión de `05-auth-sync.md` HU-04 (con su confirmación) y el onboarding **se cierra**: el latch se enciende y la app entra al Home. No se le vuelve a pedir crear una cuenta a alguien que acaba de recuperar las suyas.
- **El caso "inicié sesión y la cuenta no tenía datos"** (usuario nuevo que igual quiso loguearse) termina en un Home vacío y en el gate de `15-gate-cuenta.md` la primera vez que intente registrar algo. Es correcto: no se reabre el onboarding.
- Este enlace **no existe fuera del onboarding**: una vez cerrado el flujo, el camino a login es Ajustes → Respaldar, como hoy.

### HU-07 — Enseñar el respaldo en la nube
Como usuario nuevo quiero entender que puedo respaldar mis datos en la nube gratis y qué pasa si no lo hago, para decidir con información en vez de descubrirlo cuando pierda el teléfono.

**Criterios de aceptación:**
- **Pantalla propia dentro del flujo**, después de la primera cuenta y antes del cierre. Explica tres cosas y nada más: (a) hoy tus datos viven **solo en este teléfono**; (b) el respaldo es **gratis y parte del Nivel 0** — no es una feature de pago ni un gancho; (c) sirve para recuperar todo si cambias de dispositivo o reinstalas.
- **Dice explícitamente qué se pierde sin respaldo**, con tono neutro y sin dramatizar: si desinstalas o pierdes el teléfono, esos datos no se recuperan. Es información honesta, no una amenaza — sin iconografía de alerta ni familia `$expense`.
- **Dos acciones, ambas alcanzables:** "Activar respaldo" (principal) lleva al login social existente (`05-auth-sync.md` HU-02/HU-03); "Después" (secundaria, visible, nunca escondida en texto diminuto) avanza al cierre. **Ningún patrón de confirmshaming** ("No, prefiero perder mis datos") — prohibido.
- **Activar respaldo aquí no termina el onboarding a la fuerza**: tras autenticar y correr la fusión (`05-auth-sync.md` HU-04), el usuario sigue al paso de cierre (HU-04) con normalidad. Es el mismo camino de HU-06, con distinta puerta de entrada.
- **Si el login falla o se cancela**, vuelve a esta pantalla y puede seguir con "Después". Nunca deja el flujo trabado ni repite el intento en bucle.
- **Menciona que se puede activar luego** y dónde (Ajustes → Respaldar), para que "Después" no se sienta una puerta que se cierra.
- **Sin conexión:** la pantalla se muestra igual (es informativa); "Activar respaldo" explica que necesita conexión y ofrece hacerlo más tarde, sin bloquear el avance.
- **No repetir el mensaje tres veces:** si el usuario ya inició sesión vía "Ya tengo cuenta" (HU-06), esta pantalla **se omite**.
- Nunca se presenta el respaldo como requisito, ni se condiciona ninguna feature de Nivel 0 a activarlo (regla de `05-auth-sync.md` HU-01).

## Reglas de negocio y edge cases

**Alcance y Nivel 0**
- El onboarding completo (bienvenida → cuenta → respaldo → invitación al primer movimiento) se completa **100% offline y sin cuenta**: la pantalla de respaldo es informativa y su CTA es opcional. La única dependencia de red del primer arranque es el catálogo de categorías, que ocurre antes y ya tiene su propia pantalla de reintento.
- Ningún paso puede condicionar acceso a features de Nivel 0 a ver un anuncio, pagar o iniciar sesión.
- Sin telemetría: el repo no tiene analítica de producto y esta feature no la introduce. Lo único observable son errores, vía `CrashReporter`.

**Persistencia y ciclo de vida del flujo**
- El estado se guarda en un latch nuevo, **`AppSettings.onboardingCompleted`** (mismo patrón y motivos que `categoriesSeeded`: singleton de id `'app'`, se enciende una vez y no se apaga nunca).
- **Condición de encendido:** el usuario llegó a la pantalla de cierre (HU-04) y actuó en ella — registrando, saltando o omitiendo. **No depende de que haya creado una cuenta** (decisión #2). También se enciende al completar con éxito el login de HU-06.
- **Se enciende sin mostrar el flujo** si al evaluarlo ya existe al menos una cuenta activa (instalación previa a la bandera, o restauración por import/export). Nadie que ya venía usando la app ve el onboarding por primera vez después de una actualización.
- **Interrupción a mitad** (el usuario mata la app en el paso 2): el latch sigue apagado, el flujo reinicia desde el principio en el siguiente arranque, y las cuentas ya creadas **se conservan** y se listan en el paso 2 — no se duplican ni se borran.
- **El onboarding no se reabre nunca** una vez encendido: ni al omitir la cuenta, ni al borrar/archivar todas después. Ese estado lo cubren `15-gate-cuenta.md` y el estado vacío del Home, que sirven igual al usuario nuevo y al veterano.
- El gate se evalúa **una sola vez por arranque**, tras el bootstrap. No reacciona a cambios del latch que lleguen por sync a mitad de sesión (`app_settings` sincroniza; un cambio remoto no debe expulsar al usuario de la pantalla en la que está).
- **Navegación:** mientras el onboarding esté activo, el flujo es la única ruta accesible (redirect en `app_router.dart`). El botón atrás del sistema en Android navega entre pasos y en el primero **no** deja salir a un Home a medias (minimiza la app). No hay deep links hacia el onboarding.

**Datos**
- Todo lo creado en el onboarding son filas normales: UUID por `clientDefault`, montos en centavos, `updatedAt` estampado por el repositorio. Sin marcas de "creado en onboarding".
- La moneda de la primera cuenta **no fija la moneda base de reportes** (`12-multi-moneda.md` HU-04). Ese ajuste vive en Ajustes y el onboarding no lo pide.
- El onboarding no toca tema/apariencia (`14-apariencia.md`): la app arranca en "seguir al sistema" y el usuario lo cambia en Ajustes. No se agrega un paso de personalización visual.

**Accesibilidad y tono**
- Texto escalable, contraste y áreas táctiles según `design-system/billetudo/MASTER.md`; el flujo debe ser completable con lector de pantalla.
- Ninguna animación es bloqueante ni indispensable para entender el paso.
- Nunca avergonzar ni presuponer desorden financiero del usuario.

## Impacto técnico (change map preliminar)

- **Esquema:** columna `onboardingCompleted` (bool, `clientDefault false`) en `AppSettings` → sube `schemaVersion` a 20 + migración. **Regla de las cuatro piezas** (decisiones #17/#20/#21 de `05-auth-sync.md`, tres incidentes en producción por saltársela): Drift, `powersync_schema.dart` (`Column.integer('onboarding_completed')`), Postgres **dev y prod** (`ALTER TABLE app_settings ADD COLUMN onboarding_completed bigint`), y el Sync Stream **no** requiere cambios (columna nueva sobre tabla ya sincronizada). Usar `drift-migration-helper`.
- **Dominio:** `SetOnboardingCompleted` y lectura del flag en `features/settings` (donde ya viven `AppSettings`, su repositorio y `GetAppSettings`), reusando la infraestructura de `categoriesSeeded`.
- **Feature nueva:** `lib/features/onboarding/` con las tres capas; la presentación reusa `CreateAccount` (Cuentas), el flujo de transacción y la pantalla de respaldar/login (HU-06) existentes — **no** duplica repositorios ni formularios.
- **Router:** rutas en español bajo `/bienvenida` + redirect condicionado al latch en `app_router.dart`. La pantalla de respaldar/login (HU-06/HU-07) debe ser alcanzable **fuera del shell de tabs** — hoy cuelga de `/ajustes/respaldar` — y al cancelar debe volver al paso del onboarding, no al Home.
- **l10n:** strings nuevos en `lib/core/l10n/arb/` (es + en).
- **Tests:** unit del latch y sus condiciones de encendido (incluido el caso "ya hay cuentas → enciende sin mostrar"), widget del flujo y de la interrupción a mitad, golden de cada pantalla en ambos temas, y e2e Patrol de tres caminos: primer arranque **creando** cuenta → registrar movimiento; primer arranque **omitiendo** → llegar al Home; y "Ya tengo cuenta" → login → onboarding cerrado. Los goldens son además el insumo de `/design-fidelity-check onboarding`.

## Orden de entrega

Las tres piezas se construyen en este orden, y el motivo no es de gusto sino de dependencia:

1. **`15-gate-cuenta.md` — primero, incluso antes que este documento.** Aporta valor **hoy**, sin onboarding: la app ya puede quedarse sin cuentas activas y hoy no lo maneja. Y es la condición que permite que el paso de cuenta sea omitible (decisión #2). Empezar por las superficies NOT NULL (movimientos y pagos programados).
2. **`13-onboarding.md` — este flujo.** Es la pieza **más pequeña** de las tres: cuatro pantallas, un latch y reuso de formularios existentes.
3. **`16-minitutoriales.md` — al final.** Es la más grande en contenido (11 tutoriales, l10n en dos idiomas) y la única que agrega una tabla sincronizada. No bloquea a las otras dos.

Dentro de la pieza 3, los **tutoriales de pantalla** (4) van antes que los **de sub-flujo** (7): comparten infraestructura y los de pantalla son los de mayor retorno.

## Fuera de alcance de la v1

- **HU-05** (pantalla informativa de niveles) — congelada hasta que exista la primera feature de Nivel 1 real.
- **Tour de features dentro del flujo**: lo cubre `16-minitutoriales.md`, en el contexto de cada feature.
- **Permiso de notificaciones**: no hay infraestructura de notificaciones locales en el repo (ver `07-metas.md` HU-06); pedir el permiso en el onboarding sería pedirlo para nada.
- **Import de datos de otra app** (`11-import-export.md`) como paso del flujo: existe la feature, pero ofrecerla en el primer minuto agrega una rama entera al onboarding. Se evalúa después de la v1.
- **Personalización de tema, moneda base y orden del acceso rápido**: todo vive en Ajustes.

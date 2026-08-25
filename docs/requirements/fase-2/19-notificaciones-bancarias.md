# Feature: Lectura de notificaciones bancarias (Android)

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Plataforma:** **Solo Android.** iOS no expone las notificaciones de otras apps a terceros — ver "Alcance por plataforma".
**Feature dir:** `lib/features/capture/` (hoy vacío)
**Tablas Drift:** `Transactions` (existente, `TxSource.notification` ya en el enum), **`PendingCaptures`** (nueva)

## Contexto

Fase 2 ataca el costo de registrar un gasto: **captura sin fricción, 100% en el dispositivo, sin backend y sin costo marginal**. Esta feature es el diferenciador Android-first del producto (`docs/Plan_Monetizacion_y_Tecnico.md` §2 y §8): cuando el banco notifica "Compra por $45.900 en EXITO CALLE 80", la app ya tiene monto, comercio y fecha sin que el usuario escriba nada.

**Es la primera pieza que se construye dentro de Fase 2** (decisión 2026-08-17), por ser la de mayor impacto en el mercado objetivo.

**Es Nivel 0** (ver "Frontera Nivel 0 / Nivel 1" en `../README.md`): el parseo usa **reglas locales**, no LLM. El parseo con LLM llega en Fase 4 como Nivel 1 — una mejora de precisión que se suma encima y que **nunca puede bloquear ni degradar lo entregado acá**. Si el usuario no tiene Premium ni Modo anuncios, la captura por notificación sigue funcionando igual de bien que el día del lanzamiento.

**Modelo de confirmación** (decisión 2026-08-17, aplica a toda Fase 2): voz y OCR pre-llenan el formulario de transacción existente porque el usuario está presente y mirando. Las **notificaciones bancarias no**: llegan cuando el usuario no está en la app, muchas veces mientras hace otra cosa. Por eso caen en una **bandeja de capturas pendientes** y **nada se registra sin confirmación humana**. Una app de finanzas que inventa movimientos sola destruye la confianza en el saldo, que es el dato del que depende todo lo demás.

## Alcance por plataforma

- **Android:** vía `NotificationListenerService` (permiso `BIND_NOTIFICATION_LISTENER_SERVICE`). Es la única vía soportada.
- **iOS:** **no existe y no va a existir.** iOS no permite a una app de terceros leer las notificaciones de otras apps. En iOS la app **no debe** mostrar esta feature, ni siquiera deshabilitada con un candado — sería prometer algo imposible. En su lugar, la superficie de captura en iOS es **voz** (`17-captura-voz.md`) y **OCR de recibo** (`18-captura-ocr.md`), que sí son multiplataforma.
- Cualquier texto de marketing o de ayuda que mencione esta feature debe decir "en Android" explícitamente.

## Historias de usuario

### HU-01 — Activar la lectura de notificaciones (permiso especial)
Como usuario de Android quiero autorizar a la app a leer las notificaciones de mis bancos, para que mis compras aparezcan solas sin tener que escribirlas.

**El permiso no es un diálogo normal.** `BIND_NOTIFICATION_LISTENER_SERVICE` no se pide con `requestPermissions()`: se concede en **Ajustes del sistema → Acceso a notificaciones**, en una pantalla que la app solo puede abrir (`ACTION_NOTIFICATION_LISTENER_SETTINGS`), no controlar. El usuario sale de la app, busca la app en una lista, activa un switch y confirma un diálogo de advertencia del sistema que dice, con esas palabras, que la app podrá leer **todas** las notificaciones.

**Criterios de aceptación:**
- **Explicación antes de salir de la app (obligatoria).** Antes de abrir Ajustes se muestra una pantalla/hoja propia que dice, en lenguaje llano: qué se lee (solo las notificaciones de las apps de banco que el usuario elija), qué se guarda (**solo lo que la app entendió**: monto, comercio y fecha — nunca el texto de la notificación), qué se sincroniza a la nube (esos mismos datos, como cualquier movimiento) y que **ningún movimiento se registra sin que el usuario lo confirme**. Sin esta pantalla, el usuario ve primero la advertencia agresiva del sistema y abandona.
- La misma pantalla anticipa el diálogo del sistema ("Android te va a advertir que la app podrá ver todas tus notificaciones; es la única forma en que el sistema concede este permiso") — que la advertencia no sorprenda.
- Un botón lleva a Ajustes; un botón secundario permite **seguir sin activarlo**, nunca un flujo de una sola salida. El resto de la app funciona íntegra sin este permiso.
- Al volver de Ajustes la app **re-verifica el estado real** del permiso (no asume que el usuario lo concedió por haber ido). Si sigue sin concederse, se muestra el estado "desactivado" sin regaño ni insistencia, con la opción de reintentar.
- Concedido el permiso, el siguiente paso del flujo es elegir de qué apps se escucha (HU-02). Activar el permiso sin seleccionar emisores **no** captura nada.
- El estado del permiso es visible y reversible desde Ajustes de la app en todo momento (ver HU-09).

**Pendiente de decidir:** ¿cuándo se ofrece activar esto por primera vez? (a) durante el onboarding, junto al resto de la configuración inicial — máxima adopción, pero pedir el permiso más invasivo de la app antes de que el usuario le tenga confianza es la peor conversión posible y arriesga desinstalaciones; (b) contextual, la primera vez que el usuario registra un gasto a mano ("¿quieres que esto aparezca solo?") — mejor conversión y consentimiento más informado, pero muchos usuarios nunca lo descubren; (c) solo bajo demanda desde Ajustes — el más conservador de cara a Google Play, el de menor adopción.

### HU-02 — Elegir de qué apps se escucha (catálogo de emisores)
Como usuario quiero decidir explícitamente cuáles de mis apps bancarias se leen, para que la app no meta las narices en mis chats ni en mis correos.

**Criterios de aceptación:**
- La app muestra una lista de **apps candidatas instaladas en el dispositivo** que coinciden con su catálogo de emisores conocidos (bancos, billeteras y fintechs del mercado objetivo). Cada una tiene un switch, **apagado por defecto**.
- **Nada se procesa de una app que no esté encendida en esta lista.** El filtro se aplica por `packageName` **antes** de leer el contenido de la notificación, no después.
- El usuario puede apagar un emisor en cualquier momento; a partir de ese instante deja de generar capturas (las pendientes ya creadas siguen en la bandeja hasta que las despache, HU-05).
- La pantalla indica cuántos emisores están activos y permite apagarlos todos de un toque, sin tener que revocar el permiso del sistema.

**Pendiente de decidir:** ¿el catálogo es cerrado o abierto? (a) **cerrado** — solo apps del catálogo curado; es la postura más defendible ante Google Play y ante el usuario ("solo miramos bancos"), pero deja fuera al banco pequeño que no alcanzamos a incluir; (b) **abierto con advertencia** — el usuario puede añadir cualquier app instalada; cubre el long tail, pero legitima escuchar WhatsApp y vuelve mucho más difícil sostener la declaración de uso ante la tienda. Un híbrido posible: catálogo cerrado en el lanzamiento, más un formulario para **pedir** que se añada un banco (la regla llega en una actualización de la app), sin que el usuario pueda habilitar apps arbitrarias.

**Pendiente de decidir:** ¿con qué bancos/emisores es-CO se lanza y cómo se actualizan sus reglas? (a) reglas **empaquetadas en la app** (asset local) — coherente con "sin backend, costo $0", pero añadir un banco exige una release y esperar a que el usuario actualice; (b) reglas **descargables** desde Supabase con caché local — permite corregir un parser roto en horas, pero introduce una dependencia de red en una feature que se vendió como 100% local (nota: descargar *reglas* no envía datos del usuario, así que no rompe la promesa de privacidad, solo la de "sin backend"). Definir también la lista concreta de emisores del lanzamiento.

### HU-03 — Interpretar una notificación bancaria con reglas locales
Como usuario quiero que la app entienda cuánto gasté, dónde y con qué tarjeta a partir del texto de la notificación, para no tener que teclear nada.

**Criterios de aceptación:**
- El parseo ocurre **en el dispositivo, con reglas/expresiones regulares por emisor**. No hay llamada de red ni LLM en esta fase.
- Campos que se intentan extraer:
  - **`amountMinor`** (obligatorio): entero en centavos. El formato es-CO usa punto como separador de miles y coma decimal (`$45.900`, `$1.234.567,50`); el parser debe manejar ambos y montos sin decimales. **Si no se puede extraer un monto, no se crea captura** (una captura sin monto no ahorra trabajo, solo genera ruido en la bandeja).
  - **`currency`**: la del emisor/cuenta cuando la notificación no la explicita.
  - **Comercio** (texto libre, ej. `EXITO CALLE 80`): se guarda tal cual se extrajo y se usa como nota sugerida y como llave de aprendizaje (HU-06).
  - **Pista de cuenta/tarjeta**: normalmente los últimos 4 dígitos (`*1234`). Se usa para sugerir la cuenta, no para identificarla con certeza.
  - **Fecha/hora**: la de la notificación (`postedAt`) si el texto no trae una explícita.
  - **Tipo de movimiento**: gasto (compra, pago, retiro) vs. ingreso (abono, transferencia recibida, nómina). Ante ambigüedad se asume **gasto** por ser el caso dominante, y el usuario lo corrige al despachar.
- **Se ignoran y no generan captura** las notificaciones que no son un movimiento de dinero: avisos de seguridad, promociones, "tu extracto está listo", recordatorios de pago, códigos OTP. Los OTP además **nunca** se persisten ni se muestran.
- **La categoría no se infiere por reglas de texto** en el lanzamiento: el comercio no dice si "RAPPI" fue mercado o restaurante. Se resuelve al despachar (HU-05) o por aprendizaje (HU-06).
- Cada captura guarda **por qué regla se creó** (id del emisor y de la regla) para poder depurar un parser que empieza a fallar sin tener que guardar el texto crudo.
- Si el emisor está activo pero **ninguna regla hace match**, no se crea captura y no se persiste el contenido. Puede contarse un contador local anónimo de "no parseadas por emisor" (sin texto) para priorizar qué reglas escribir.

**Retención cero del texto crudo (decisión 2026-08-17).** **No se persiste nunca el contenido literal de la notificación** — ni completo, ni truncado, ni de forma efímera. Solo se guardan los campos ya extraídos (monto, comercio, fecha, tipo, pista de cuenta) y el id de la regla que los produjo. El texto crudo existe en memoria durante el parseo y se descarta. Es la **política uniforme de toda la Fase 2**: aplica igual al audio/transcripción de `17-captura-voz.md` y a la imagen/OCR de `18-captura-ocr.md`.

**Consecuencias honestas de esta decisión (asumidas):**
- Cuando el parser entiende mal, el usuario **no tiene el original contra qué contrastar** — solo puede corregir los campos en el formulario al despachar (HU-05). Por eso `sourceRuleId` es obligatorio: es lo único que permite depurar un parser roto.
- En **Fase 4 el LLM solo podrá mejorar capturas nuevas**, procesando la notificación en el momento en que llega. **No podrá re-parsear el histórico**, porque el histórico no existe. Es una capacidad que se renuncia a propósito, no un descuido: recuperarla exigiría guardar el dato más sensible de la app de forma indefinida.
- A cambio, la promesa de privacidad es simple y verificable, y un backup, export o dispositivo comprometido no expone el texto de ninguna notificación.

### HU-04 — Ver la bandeja de capturas pendientes
Como usuario quiero un lugar donde se acumulen las compras que la app detectó pero yo todavía no confirmé, para revisarlas cuando tenga un momento y no perder ninguna.

**Criterios de aceptación:**
- Cada notificación interpretada crea una fila en `PendingCaptures` con `status = pending`. **Nunca crea una `Transaction`.**
- La bandeja lista las pendientes **más recientes primero**, mostrando por cada una: monto, comercio, cuenta sugerida (o "sin cuenta"), fecha/hora y el emisor de origen.
- Cada fila deja claro que **todavía no afecta el saldo** — es una propuesta, no un movimiento. Ni saldos, ni presupuestos, ni gráficas, ni "disponible para gastar" cuentan una captura pendiente.
- Hay un indicador de cuántas pendientes hay, visible sin entrar a la bandeja.
- Estado vacío con tono positivo y neutral ("Todo al día", nunca "no has registrado nada").
- Si el permiso está concedido pero no hay emisores activos, la bandeja explica por qué está vacía y enlaza a HU-02.

**Pendiente de decidir:** ¿dónde vive la bandeja? (a) detrás de la **campana del Home** (`lib/features/home/presentation/widgets/home_header.dart:99`, hoy un `ComingSoonSheet`) — reusa una superficie que ya existe y encaja con la metáfora de "cosas que requieren tu atención", pero mezcla capturas pendientes con lo que sea que la campana signifique a futuro (recordatorios de vencimiento de HU-08 de `../fase-1/09-pagos-programados.md`, avisos de presupuesto); (b) **entrada propia** en el Home o en el listado de transacciones — más descubrible y sin ambigüedad de significado, pero añade una superficie nueva a una navegación ya llena (ver la decisión de nav de Metas al slot 4); (c) **la campana como bandeja unificada** de todo lo accionable, con las capturas como una sección — la más coherente conceptualmente y la que más diseño exige. Requiere definir antes qué es la campana en general, no solo para esta feature.

**Pendiente de decidir:** ¿la llegada de una captura dispara una **notificación local**? (a) sí — el usuario se entera en el momento y la confirma en caliente, cuando todavía recuerda la compra; pero significa que la app le manda una notificación **cada vez que el banco le manda una**, duplicando el ruido que ya recibe; (b) no, solo el indicador dentro de la app — silencioso y respetuoso, pero las capturas se acumulan y se despachan en frío, cuando ya no se acuerda de qué fue; (c) resumen agrupado (una sola al día / al llegar a N pendientes). Es preferencia del usuario en cualquier caso, con default conservador.

### HU-05 — Despachar una captura pendiente (confirmar / editar / descartar)
Como usuario quiero revisar cada captura y decidir si la registro, la corrijo o la boto, para que solo entren a mis cuentas movimientos que reconozco.

**Criterios de aceptación:**
- **Confirmar nunca es a ciegas.** Despachar abre siempre el **formulario de transacción existente** (`../fase-1/03-transacciones.md`) pre-llenado con lo extraído. Es el mismo formulario, con las mismas validaciones — no una pantalla paralela con reglas propias. El usuario puede aceptar sin cambiar nada, pero **después de ver** lo que va a registrar.
- Campos pre-llenados: `amountMinor`, `currency`, `date`, `accountId` (si se pudo sugerir), `note` (comercio), `type`. **`categoryId` viene vacío** salvo aprendizaje (HU-06), y sigue siendo **obligatorio** para `income`/`expense` según HU-01 de `03-transacciones.md` — la app no registra un gasto sin categoría solo porque venga de una notificación.
- Al guardar se crea la `Transaction` con **`source = notification`** (valor que ya existe en el enum `TxSource`, `lib/core/database/app_database.dart:46`, y que hoy nunca se produce en código). El detalle de la transacción lo muestra como "Notificación bancaria" (string `transactionSourceNotification` ya existente).
- La captura pasa a `status = confirmed`, guarda el `transactionId` resultante y desaparece de la bandeja. `updatedAt` se actualiza en la escritura.
- **Descartar** marca `status = discarded`, no borra la fila de inmediato: permite deshacer con `Snackbar` ("Captura descartada · Deshacer"), coherente con el resto de la app. Descartar **no** crea ninguna transacción.
- Se puede **descartar en lote** (ej. "descartar todas las de este día"); **no existe "confirmar todas"** — sería N confirmaciones ciegas, la misma restricción no negociable que en pagos programados (HU-03 de `../fase-1/09-pagos-programados.md`). Un flujo de revisión guiada una-por-una sí es aceptable.
- Si al despachar el usuario cambia la cuenta o la categoría, ese cambio alimenta el aprendizaje de HU-06.
- El usuario **nunca puede quedar bloqueado**: si no hay cuentas activas, aplica el puente de `../fase-1/15-gate-cuenta.md` (ofrecer crear la cuenta y continuar), nunca un botón gris.

### HU-06 — Que la app aprenda mis cuentas y mis comercios
Como usuario quiero no tener que decirle a la app en cada compra que `*1234` es mi tarjeta de crédito y que `EXITO` es mercado, para que despachar sea de un toque después de las primeras veces.

**Criterios de aceptación:**
- Cuando el usuario confirma una captura eligiendo cuenta, la app recuerda la asociación **pista de tarjeta → cuenta** y la sugiere en adelante.
- Cuando el usuario confirma una captura eligiendo categoría, la app recuerda **comercio → categoría** y la pre-llena en adelante.
- Toda sugerencia aprendida es **editable y visible como sugerencia**, nunca un valor impuesto en silencio. Cambiarla re-entrena la asociación.
- El aprendizaje es **privado de cada usuario**: no se comparte con nadie ni se agrega para entrenar nada. Sincroniza con la cuenta del usuario igual que el resto de sus datos, para que un teléfono nuevo no empiece de cero.
- Debe existir una forma de **olvidar** lo aprendido (por asociación o todo), junto al borrado de datos de HU-08.

**Pendiente de decidir:** ¿cómo se modela el mapeo tarjeta → cuenta? (a) **columna nueva en `Accounts`** con los últimos 4 dígitos, editable desde el formulario de cuenta — explícito, el usuario lo configura una vez y funciona desde la primera notificación; a cambio, mete un dato de instrumento de pago en una tabla que hoy es agnóstica, y ese dato **sí sincroniza** a Supabase; (b) **tabla de aprendizaje aparte**, poblada solo al confirmar — no toca `Accounts` y mantiene el dato acotado a esta feature, pero la primera captura de cada tarjeta siempre exige elegir cuenta a mano; (c) ambas. Afecta directamente la migración (HU esquema).

### HU-07 — No registrar dos veces lo mismo (deduplicación)
Como usuario quiero que si ya anoté la compra a mano, la app no me la vuelva a meter cuando revise la bandeja, para que mi saldo no quede inflado al doble.

**Criterios de aceptación:**
- Al despachar (o al mostrar la captura en la bandeja), la app busca **transacciones ya existentes** que puedan ser el mismo movimiento: mismo `amountMinor` y misma `currency`, dentro de una **ventana de tiempo corta** alrededor de la fecha de la captura, y con cuenta compatible.
- Si hay candidata, la captura se muestra **marcada como posible duplicado**, con la transacción existente visible al lado (fecha, cuenta, categoría, nota) para que el usuario compare.
- Las acciones ante un posible duplicado son: **"Es la misma"** (descarta la captura y opcionalmente enriquece la transacción existente con el comercio detectado, marcando su origen), o **"Es otra compra"** (sigue el flujo normal de confirmación).
- **La app nunca fusiona ni descarta automáticamente.** Un falso positivo de deduplicación borra un gasto real y descuadra el saldo sin dejar rastro, que es peor que el duplicado que pretende evitar.
- También se deduplica contra **otras capturas pendientes**: algunos bancos notifican dos veces el mismo movimiento (autorización y liquidación). Dos capturas del mismo emisor, mismo monto y a pocos minutos se presentan agrupadas, no como dos filas independientes.
- Deduplicar contra una transacción `source = scheduled` ya generada (`../fase-1/09-pagos-programados.md`) sigue la misma regla: se sugiere, no se aplica solo.

**Pendiente de decidir:** ¿cuál es la ventana y el criterio de match? (a) **estricto** — mismo monto exacto y ±1 hora; casi sin falsos positivos, pero se le escapa el gasto que el usuario anotó al día siguiente (el caso más común de doble registro); (b) **amplio** — mismo monto y ±48-72 horas; atrapa casi todos los duplicados reales, a cambio de marcar como sospechosos dos cafés iguales de días distintos; (c) amplio para el aviso visual y estricto para agrupar automáticamente en la UI. También hay que decidir si el match exige que coincida la cuenta o solo la sugiere.

### HU-08 — Privacidad, transparencia y borrado
Como usuario quiero saber exactamente qué ve la app de mis notificaciones y poder borrarlo, porque le acabo de dar el permiso más invasivo de mi teléfono.

Esta es la HU más sensible de toda la app. Un `NotificationListenerService` recibe **todas** las notificaciones del dispositivo: mensajes, correos, apps de salud, apps de citas. El sistema no permite suscribirse solo a unas cuantas; el filtrado es responsabilidad de la app.

**Criterios de aceptación (todos obligatorios, ninguno negociable):**
- **Filtrado por `packageName` en el primer punto de entrada.** La notificación de una app no habilitada (HU-02) se descarta **antes** de leer título, texto o extras. No se registra, no se loguea, no se cuenta.
- **Cero persistencia de contenido no bancario.** Ninguna notificación fuera del catálogo activo puede llegar nunca a la base de datos, a un log, a un archivo temporal, a un crash report ni a analítica. El redactor de Sentry (`lib/core/crash/sentry_redaction.dart`) debe cubrir explícitamente los campos de esta feature.
- **El contenido de las notificaciones no sale del dispositivo, porque no se guarda (retención cero, HU-03).** No hay llamada de red en el camino de captura: ni al backend propio, ni a analítica, ni a un servicio de parseo. Lo único que viaja después, por el sync normal de la app, son los **campos financieros ya estructurados** (ver la decisión de sync más abajo). Ambas promesas son verificables en el código y deben testearse.
- **Pantalla de transparencia** dentro de Ajustes: qué apps se están escuchando, cuántas capturas se han creado, qué campos se guardan y cuáles no, y un enlace a la política de privacidad.
- **Borrado bajo demanda:** una acción "borrar todas las capturas y lo aprendido" que deja la feature como recién instalada, sin desactivar el permiso ni tocar las transacciones ya confirmadas (esas ya son movimientos del usuario). El borrado de cuenta (requisito Apple/Google) debe arrastrar también estos datos.
- **Impacto documental obligatorio (bloqueante para el release):**
  - `docs/legal/politica-privacidad.md` debe describir el tratamiento: qué se lee, con qué base legal (consentimiento explícito y revocable), qué se almacena, dónde (dispositivo) y por cuánto tiempo.
  - `docs/legal/declaraciones-tiendas.md:165` y `docs/legal/AUDITORIA.md:649` **hoy declaran ante las tiendas que la app no tiene captura por voz/OCR/IA**, apoyándose en que `lib/features/capture/` está vacío. **Esa declaración deja de ser cierta con esta feature y debe actualizarse antes de publicar**, junto con el Data Safety de Google Play.
  - `android/app/src/main/AndroidManifest.xml` **hoy no declara ningún `uses-permission`**. Esta feature introduce el primero de la app (el `<service>` con `BIND_NOTIFICATION_LISTENER_SERVICE`), lo que cambia la ficha de permisos visible en la tienda.

**`PendingCaptures` sincroniza vía PowerSync (decisión 2026-08-17).** La tabla usa el mixin `_SyncColumns` y sincroniza como el resto del esquema — sin excepciones al patrón. El usuario que revisa la bandeja desde otro dispositivo ve las mismas pendientes, y cambiar de teléfono no pierde capturas sin despachar. Las transacciones confirmadas sincronizan siempre, como cualquier otro movimiento.

**Consecuencia (obligatoria en la política de privacidad):** hay que **declarar que metadatos derivados de notificaciones bancarias salen del dispositivo** y se almacenan en Supabase — monto, comercio, fecha, emisor y cuenta inferida. La promesa deja de ser "nada sale del dispositivo" y pasa a ser la formulación precisa: **el contenido de las notificaciones no se envía a ningún servidor porque no se guarda en ninguna parte** (retención cero, HU-03); lo que sincroniza son los datos financieros ya estructurados, exactamente el mismo tipo de dato que una transacción registrada a mano.

Esa formulación **solo se sostiene gracias a la decisión de retención cero**: si el texto crudo se guardara, sincronizarlo significaría subir a un servidor el contenido literal de las notificaciones del teléfono, y ninguna redacción de la política haría eso aceptable. Las dos decisiones se toman juntas y no deben revisarse por separado.

### HU-09 — Revocación, degradación y estado del servicio
Como usuario quiero poder apagar esto cuando quiera, y que la app me diga si dejó de funcionar, para no creer que estoy cubierto cuando no lo estoy.

**Criterios de aceptación:**
- **Revocar desde el sistema:** el usuario puede quitar el acceso a notificaciones en Ajustes de Android sin avisarle a la app. La app debe **verificar el estado real del permiso en cada arranque** (y al volver a foreground), no confiar en una bandera guardada.
- Al detectar que el permiso se revocó: se deja de capturar, se comunica el estado sin drama ni insistencia ("La lectura de notificaciones está desactivada"), y se ofrece reactivarla. **No se borran** las capturas pendientes ya existentes: el usuario todavía puede despacharlas.
- **Revocar desde la app:** debe existir un interruptor propio que detiene la captura sin obligar a ir a Ajustes del sistema. Apagarlo pregunta si además quiere borrar lo capturado (HU-08).
- El servicio puede ser matado por el sistema (optimización de batería, fabricantes con políticas agresivas — Xiaomi, Huawei, Samsung). La app **no promete** capturar el 100%: la ayuda debe decir que si algo no llegó, se registra a mano, y la app nunca presenta la captura como cobertura garantizada.
- **Ninguna cifra de la app depende de esta feature.** Si el servicio no corrió en tres días, los saldos, presupuestos y gráficas siguen siendo exactamente igual de correctos, porque solo cuentan transacciones confirmadas.
- Desinstalar/reinstalar la app pierde el permiso; el flujo de HU-01 vuelve a aplicar.

### HU-10 — Higiene de la bandeja
Como usuario quiero que la bandeja no se vuelva un basurero de 300 capturas viejas, para que revisarla siga siendo útil.

**Criterios de aceptación:**
- Las capturas pendientes con cierta antigüedad se presentan visualmente diferenciadas (atenuadas o agrupadas bajo "Antiguas"), sin desaparecer solas.
- Existe una acción explícita de "descartar todas las anteriores a [fecha]", reversible con `Snackbar`.
- Las capturas en `status = discarded` se purgan definitivamente pasada la ventana de deshacer (borrado físico, no `deletedAt`: no hay valor en conservar el rastro de algo que el usuario dijo que no era suyo, y sí hay costo de privacidad).
- La bandeja nunca bloquea el uso del resto de la app ni interrumpe con modales por acumulación.

**Pendiente de decidir:** ¿caducan solas las capturas pendientes no despachadas? (a) **nunca** — el usuario tiene el control total y nada se pierde, pero la bandeja crece sin límite y el indicador se vuelve ruido que se aprende a ignorar; (b) **caducan a 30 días** — bandeja siempre manejable y menos dato sensible retenido, pero un usuario que se ausenta un mes pierde capturas reales sin haberlo pedido; (c) **caducan a 90 días** — punto medio. En cualquier caso, caducar significa **descartar**, jamás registrar automáticamente.

## Reglas de negocio y edge cases

- **Nada se registra sin confirmación humana.** No existe ni existirá un modo "registrar automáticamente lo que detecte". Es la regla central de la feature.
- **Una captura pendiente no es dinero.** No afecta saldos, presupuestos (`../fase-1/06-presupuestos.md`), metas, deudas, gráficas (`../fase-1/10-graficas-informes.md`) ni "disponible para gastar", en ningún estado intermedio.
- **`amountMinor` siempre entero positivo en centavos**, también en `PendingCaptures`. El signo lo determina el `type`, nunca un monto negativo (`CLAUDE.md`).
- **IDs UUID en texto** (`clientDefault`), nunca autoincrement, también en la tabla nueva. **`updatedAt` se actualiza en cada escritura**, en el repositorio.
- El origen `notification` es un **hecho histórico**: `source` no es editable desde el formulario de edición (HU-04 de `../fase-1/03-transacciones.md`), aunque la transacción se haya modificado por completo al confirmarla.
- El parseo local **no puede ser reemplazado ni condicionado** por el parseo con LLM de Fase 4. El LLM entra como un enriquecedor opcional sobre la captura ya creada; si no está disponible, no lo tiene contratado o falla, el flujo local se comporta exactamente igual.
- **Tono:** la bandeja nunca reprocha ("llevas 12 gastos sin revisar"). Comunica en positivo y en términos de progreso (`CLAUDE.md`).
- **Sin cuentas activas** aplica el puente de `../fase-1/15-gate-cuenta.md`: se puede capturar y acumular en la bandeja, pero confirmar exige una cuenta, y la app ofrece crearla en el momento.
- **Sensible al idioma y al país:** las reglas se escriben para es-CO. Un usuario en otro país con un banco no cubierto ve la feature disponible pero sin emisores en el catálogo; la pantalla debe explicarlo sin hacerlo sentir un error de la app.

## Riesgo de política de Google Play (explícito, no diferible)

`docs/Plan_Monetizacion_y_Tecnico.md` §9 y §10 lo listan como riesgo abierto: **el acceso a notificaciones está muy restringido por Google Play**; el plan exige "declarar y justificar el uso" y **"no depender solo de esa vía"**, con voz/OCR como alternativa.

**La tensión que introduce el orden de construcción.** Se decidió construir esta feature **primero** dentro de Fase 2, por ser el diferenciador. Eso significa que durante un tiempo el repositorio tendrá el permiso más riesgoso del catálogo **sin** las alternativas que el propio plan exige como respaldo (`17-captura-voz.md` y `18-captura-ocr.md` aún no existen). Si esa situación llegara a producción, un rechazo de Google dejaría a la app **sin ninguna captura sin fricción**, no con una menos. La decisión de lanzamiento de más abajo resuelve la tensión separando **orden de construcción** de **orden de publicación**: se construye primero, pero no se publica sola.

**Mitigaciones que quedan (obligatorias):**
- **La feature es aditiva y desacoplada.** Poder eliminar por completo `NotificationListenerService`, su permiso y su entrada de UI **sin romper nada más** es un requisito de arquitectura, no una recomendación. La bandeja y `PendingCaptures` deben poder sobrevivir para alimentarse de otras fuentes de captura, o desaparecer limpiamente.
- **Ninguna promesa de producto depende de esta vía.** Ni el onboarding, ni la ficha de tienda (`docs/marketing/store-listing/`), ni la propuesta de valor pueden construirse sobre "tus gastos se registran solos". Si el texto de tienda lo promete y Google lo remueve, el problema pasa de técnico a comercial.
- **Declaración de uso preparada antes de subir el build:** justificación del caso de uso (finanzas personales, procesamiento local, consentimiento explícito por app), el video de demostración que Play suele pedir y el Data Safety actualizado. Sin esto listo, no se sube.
- **Voz y OCR son bloqueantes del release público**, no "las siguientes en la fila": son el plan B que el plan técnico exige y sin ellas esta feature no sale (ver la condición de cierre abajo).

**La feature va activa desde el primer release público (decisión 2026-08-17).** Se asume el riesgo de que un rechazo por esta vía afecte la publicación completa, a cambio de validar el diferenciador con usuarios reales desde el día uno. No se lanza detrás de bandera ni en canal cerrado.

**Condición de coherencia con §9 del plan — criterio de cierre, no recomendación.** El plan exige "no dependas solo de esa vía". La decisión anterior solo es compatible con esa mitigación si se cumple:

> **Esta feature no puede publicarse sola.** El release público que la incluya debe llevar **voz (`17-captura-voz.md`) y OCR (`18-captura-ocr.md`) ya funcionando**, no planeados. Construirla primero define el **orden de desarrollo**, no el orden de publicación.

- Si Google remueve o rechaza el acceso a notificaciones con voz y OCR en producción, el usuario pierde una vía de captura y conserva dos. Ese es el escenario que el plan considera aceptable.
- **Si por cualquier motivo se publicara antes que voz y OCR, se estaría incumpliendo la mitigación del plan** y esta decisión **debe reabrirse** antes de subir el build — no se resuelve con una nota ni con un "lo hacemos en el siguiente release".
- El equipo de release verifica esta condición explícitamente en el checklist de publicación, junto con la declaración de uso y el Data Safety.

## Cambios de esquema requeridos (Drift)

Ejecutar vía `/drift-schema-change`.

**Reserva de versión (decisión 2026-08-17).** Por construirse primero dentro de Fase 2, esta feature toma **el primer número libre**, y `18-captura-ocr.md` toma el siguiente para su tabla `TransactionAttachments`. Ninguna de las dos debe tomar el número de la otra aunque cambie el orden de merge — quien llegue segundo rebasa, no reusa.

> **Verifica el número antes de escribir la migración, no lo copies de aquí.** Al 2026-08-17 el working tree está en **`schemaVersion` 28** (`lib/core/database/app_database.dart`), mientras `HEAD` está en 26: hay trabajo sin commitear que ya consumió 27 (`AppSettings.quickAccessOrder`) y 28 (`ScheduledPayments.goalId`, HU-16 de Metas). Con ese estado, **esta feature tomaría 28 → 29 y OCR 29 → 30**. Pero el esquema se mueve rápido y este documento envejece: lee el `schemaVersion` vigente en el momento de implementar y toma el siguiente libre. Dos features reclamando la misma versión producen una base local que se cree migrada sin estarlo, y ese fallo es silencioso.

- **Tabla nueva `PendingCaptures`** (con el mixin `_SyncColumns`: `id` UUID, `createdAt`, `updatedAt`, `deletedAt`, `tombstonedAt`) — **sincroniza vía PowerSync como el resto del esquema** (decisión 2026-08-17, HU-08):
  - `source` (texto, `TxSource`) — `notification` en esta feature; la tabla queda lista para reusarse desde voz/OCR si se decide unificar la bandeja.
  - `sourcePackage` (texto) — `packageName` del emisor.
  - `sourceRuleId` (texto, nullable) — regla que produjo la captura, para depuración.
  - `postedAt` (datetime) — cuándo llegó la notificación.
  - `amountMinor` (entero, obligatorio), `currency` (texto).
  - `entryType` (texto, `EntryType`) — `income`/`expense` inferido.
  - `merchantRaw` (texto, nullable) — comercio tal como se extrajo.
  - `accountHint` (texto, nullable) — últimos 4 dígitos u otra pista.
  - `suggestedAccountId` (texto, nullable, `references(Accounts, #id)`), `suggestedCategoryId` (texto, nullable, `references(Categories, #id)`).
  - `status` (texto, enum nuevo `CaptureStatus { pending, confirmed, discarded }`, guardado como texto para paridad con Postgres, igual que el resto de enums).
  - `transactionId` (texto, nullable, `references(Transactions, #id)`) — se llena al confirmar.
  - `duplicateOfTransactionId` (texto, nullable) — candidata de deduplicación detectada (HU-07).
  - **No existe ninguna columna de contenido literal de la notificación** (`rawText`, `title`, `bigText` o equivalente): retención cero, decisión 2026-08-17 (HU-03). `merchantRaw` guarda **solo el fragmento identificado como comercio**, no el mensaje. Añadir una columna de texto crudo más adelante exigiría reabrir esa decisión y la de sync juntas.
- **Aprendizaje (HU-06):** tabla nueva de asociaciones `merchant → categoryId` y `accountHint → accountId`, o columna de últimos-4 en `Accounts` — **depende del pendiente de HU-06**, resolver antes de escribir la migración.
- **`TxSource.notification` ya existe** en el enum (`app_database.dart:46`) y **no requiere cambio de esquema** para marcar el origen de la transacción confirmada. Hoy simplemente nunca se produce en código.
- **Paridad Supabase/PowerSync (regla de `CLAUDE.md`, ahora obligatoria):** subir `schemaVersion` **no** migra Postgres. Como `PendingCaptures` sincroniza, hace falta el `CREATE TABLE` explícito en **prod y dev**, las sync rules de PowerSync y el RLS por usuario; sin eso el sync queda quarantined con `PGRST204`. La tabla de aprendizaje de HU-06 sigue la misma regla.
- La migración es **aditiva**: no hay datos que migrar.

## Fases de entrega

1. **Núcleo capturable:** servicio Android + permiso (HU-01), catálogo y filtrado por emisor (HU-02), parseo local de 2-3 bancos es-CO (HU-03), tabla `PendingCaptures`, bandeja mínima (HU-04) y despacho al formulario existente (HU-05). Con esto la feature ya entrega valor.
2. **Confianza:** deduplicación (HU-07), privacidad/transparencia y borrado (HU-08), revocación y degradación (HU-09). **Bloqueantes para publicar**, no opcionales.
3. **Fricción cero:** aprendizaje de cuentas y comercios (HU-06), higiene de la bandeja (HU-10), ampliación del catálogo de emisores.
4. **Puerta de publicación:** el release público que incluya esta feature exige **voz y OCR funcionando** (ver "Riesgo de política de Google Play"). Es una condición de release, no una fase de esta feature.
5. **Fase 4 (fuera de este doc):** parseo con LLM como Nivel 1, encima de lo anterior y sin degradarlo. Solo sobre capturas **nuevas** — el histórico no es re-parseable por la retención cero de HU-03.

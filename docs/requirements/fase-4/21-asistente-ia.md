# Feature: Asistente financiero con IA (Fase A)

**Nivel:** hoy **beta cerrada y gratuita** (acceso por lista, requiere sesión). Su destino es **Nivel 2 — Premium** (`docs/Plan_Monetizacion_y_Tecnico.md` §2, Cubo C: *"Chat / asistente financiero con IA (razonamiento)"* — una sesión conversacional cuesta más de lo que paga un anuncio recompensado, así que **nunca** va a Modo anuncios). Ninguna función de Nivel 0 se mueve detrás de este asistente.
**Piezas técnicas:** Edge Function `ai-chat` en Supabase (broker sin estado) → API de Gemini de Google (`gemini-2.5-flash`); tabla local de conversación **no sincronizada** (`Table.localOnly` de PowerSync); tool-calling resuelto **contra la base local** del dispositivo; tablas de control `ai_access`, `ai_feature_flags` y `ai_usage_log` en Postgres, más `ai_reports` para el reporte in-app de HU-09 (la única tabla del servidor con contenido de conversación, y solo la que el usuario envía a mano).

> **Estado al 2026-08-25, verificado contra el árbol (se mueve rápido, re-verifícalo):** el **backend ya existe** —`supabase/functions/ai-chat/` con `_shared/ai/*` y la migración `20260825120000_ai_assistant_access_and_usage.sql`— y el **cliente todavía no**: `lib/features/ai/` está creada pero **vacía**. Nada de esto ha llegado a un binario publicado, así que las declaraciones de tienda vigentes no cambian todavía (`docs/legal/declaraciones-tiendas.md` §8, `AUDITORIA.md` §10.3).

## Contexto

billetudo es local-first: la base SQLite del teléfono es la fuente de verdad y la nube es una capa opcional. El asistente **rompe esa propiedad a propósito y solo para esta función**, porque un modelo de lenguaje útil necesita ver el contexto financiero del usuario y ese modelo no corre en el teléfono.

Eso obliga a dos cosas que gobiernan todo el diseño:

1. **Decirlo de frente.** `docs/legal/politica-de-privacidad.md` prometió (v1.4, §17) que *"la idea es procesar en tu teléfono... cuando eso no sea posible, lo diremos explícitamente y sin adornos"*. El asistente es la primera excepción y hay que escribirla, no esconderla.
2. **Minimizar el envío por diseño, no por promesa.** Lo que no se envía tiene que ser imposible de enviar por construcción del snapshot, no una regla que alguien recuerde.

El objetivo de producto es el diferenciador del proyecto (dar el cambio de hábito de YNAB sin su fricción): que el usuario pueda preguntar *"¿me alcanza para X?"*, *"¿en qué se me fue la plata este mes?"* o *"ayúdame a armar un presupuesto"* y reciba una respuesta con **sus** números, más acciones listas para aplicar con un toque.

## Alcance de la Fase A

**Entra:** chat de texto, snapshot financiero agregado por turno, detalle bajo demanda vía tool-calling, propuestas de acción confirmables (presupuesto, meta, categoría, movimiento), historial local, acceso por lista.

**No entra (fuera de alcance explícito):**

- Insights proactivos o resúmenes automáticos (el asistente **solo** responde cuando el usuario escribe).
- Voz, audio, imágenes o archivos adjuntos en el chat.
- Que el asistente ejecute algo sin confirmación humana.
- Re-parseo del histórico de capturas de Fase 2 (la retención cero del dato crudo lo impide por diseño, ver `docs/requirements/README.md`, decisiones transversales de Fase 2).
- Historial de conversación sincronizado entre dispositivos.
- Monetización: no hay anuncios ni cobro en Fase A.
- Memoria de largo plazo del asistente entre conversaciones (cada turno se arma desde cero con el snapshot).

## Decisiones de arquitectura (con su porqué)

1. **La app nunca llama al LLM ni contiene API keys.** Regla no negociable de `CLAUDE.md`. Todo pasa por la Edge Function `ai-chat`, que guarda la key del proveedor y valida el JWT del usuario, como ya hace `delete-account`.
2. **El broker es sin estado.** `ai-chat` no persiste el mensaje, ni el snapshot, ni la respuesta. Recibe, llama al proveedor, devuelve y olvida. Motivo: lo que no se guarda no se filtra, no hay que borrarlo al borrar la cuenta y no aparece en un volcado de base de datos.
3. **El historial vive solo en el teléfono, en una tabla `Table.localOnly`.** No se sincroniza. Contrapartida aceptada y que hay que decirle al usuario: **al cambiar de teléfono se pierde**. Se prefirió eso a subir conversaciones completas a Postgres, que es exactamente el dato más sensible de toda la feature.
4. **El snapshot se reconstruye en cada turno desde la base local.** No se cachea en el servidor. Así el modelo siempre ve datos frescos y no existe una copia del perfil financiero del usuario esperando en ningún lado.
5. **El snapshot es agregado, no un volcado.** Se envían saldos, totales y catálogos; no se envían filas de transacción salvo que el modelo pida detalle (HU-05) y siempre con tope.
6. **Las notas de texto libre nunca salen.** Son el campo donde el usuario escribe lo que no debería escribir en ningún lado, y la política ya se lo advierte. Excluirlas del snapshot **y** del detalle es una regla de construcción con test propio (HU-08).
7. **Proveedor: Google, API de Gemini, modelo `gemini-2.5-flash`.** Elegido por costo por turno y latencia. Es un **tercero nuevo** que hay que declarar junto a Supabase y Sentry.
8. **Key de tier de pago, obligatorio antes de abrir la feature a terceros.** Los términos de la API de Gemini distinguen *Unpaid Services* (Google usa el contenido para desarrollar y mejorar sus productos, con revisión humana posible) de *Paid Services* (no se usa para mejorar productos; solo se registra por un tiempo limitado para detectar abusos y por obligaciones legales). Con key gratuita, **la feature se queda en uso propio**: no se abre a nadie más y no se declara ante las tiendas como disponible.
9. **Los cupos se cuentan en el servidor.** `ai_usage_log` es la fuente de conteo, nunca el cliente (regla de negocio de `CLAUDE.md`).
10. **Nada se escribe sin un toque del usuario.** El modelo produce propuestas; la app las materializa como tarjetas; la escritura ocurre en el caso de uso de la feature dueña del dato (presupuestos, metas, categorías, transacciones), no en el asistente.

## Historias de usuario

### HU-01 — Entrar al asistente y entender qué es

Como usuario quiero saber, sin leer la política, que estoy hablando con una IA en beta y que esto no es asesoría financiera, para no tomar sus respuestas como una recomendación profesional.

**Criterios de aceptación:**
- La pantalla muestra un banner **permanente y no descartable** con la etiqueta **"Beta"** y el disclaimer de que no es asesoría financiera.
- El banner no se puede ocultar por scroll permanente ni por preferencia: sigue visible mientras la conversación esté abierta.
- El texto del banner enlaza a la sección del asistente de la política de privacidad.
- En ningún punto la interfaz sugiere que la respuesta viene de una persona (requisito de la *AI-Generated Content policy* de Google Play).

### HU-02 — Dar consentimiento explícito antes del primer envío

Como usuario quiero que me pidan permiso, nombrando a quién le llegan mis datos, antes de que salga el primer mensaje, para poder decir que no.

**Criterios de aceptación:**
- Antes del **primer** envío de la vida de la instalación, la app muestra una pantalla de consentimiento que dice, en este orden: qué sale (texto que escribes + resumen de tus finanzas), **a quién llega (Google, API de Gemini)**, dónde se procesa (fuera de tu país) y qué no sale (notas, últimos 4 dígitos, entidad bancaria, archivos).
- El usuario debe aceptar con una acción explícita. No hay casilla premarcada, no hay consentimiento por uso ni por scroll.
- Si no acepta, el asistente no envía nada y el resto de la app funciona igual.
- El consentimiento queda registrado localmente con su fecha y la versión del texto aceptado.
- El usuario puede **retirarlo** desde Ajustes; al hacerlo se deja de enviar y se ofrece borrar el historial local.
- Motivo, no negociable: **App Store Guideline 5.1.2(i)** exige divulgar el destino y obtener permiso explícito antes de compartir datos personales con una IA de terceros, y los revisores esperan ver el nombre del proveedor en el texto.

### HU-03 — Acceso: requiere sesión y habilitación

Como responsable del producto quiero controlar quién usa el asistente durante la beta, para no abrir un costo variable sin límite.

**Criterios de aceptación:**
- El asistente **requiere iniciar sesión**. Es la única función de la app con ese requisito, y la pantalla lo explica en vez de mostrar un error.
- El resto de la app sigue siendo 100% usable sin cuenta (HU-01 de `05-auth-sync.md` no se toca).
- La habilitación se resuelve contra la tabla `ai_access` **en el servidor**; un cliente modificado no puede concederse acceso.
- Sin acceso, la entrada al asistente explica que está en beta cerrada; no se muestra un error técnico.

### HU-04 — Preguntar y recibir una respuesta con mis números

Como usuario quiero preguntar en lenguaje natural y que la respuesta use mis datos reales, para no tener que explicarle mi situación en cada mensaje.

**Criterios de aceptación:**
- En cada turno la app arma un **snapshot financiero agregado** desde la base local y lo envía junto con el texto del usuario. Contiene:
  - saldos por cuenta (id, nombre, tipo, moneda, saldo),
  - gasto e ingreso del mes en curso, por moneda,
  - top de categorías del mes (id, nombre, monto, conteo),
  - flujo de caja de los últimos 6 meses, agregado por mes,
  - presupuestos (nombre, periodo, límite, gastado, días restantes),
  - metas (nombre, objetivo, ahorrado, fecha meta),
  - totales de deuda por moneda y por dirección (me deben / debo),
  - pagos programados que vencen en los próximos 30 días,
  - catálogo de categorías (id, nombre, tipo), para que el modelo pueda referenciarlas por id.
- Se envían además metadatos técnicos: idioma, versión de la app y un id de conversación **generado en el dispositivo** (no derivado del id de usuario).
- El snapshot se arma con las mismas reglas de conteo de `10-graficas-informes.md` (transferencias, movimientos de deuda, categoría ausente, segmentación por moneda). Si una cifra del asistente no cuadra con la de Gráficas, es un bug.
- La app no envía nada mientras el usuario no envíe un mensaje: no hay turnos automáticos ni precalentamiento.

### HU-05 — Detalle bajo demanda, con tope

Como usuario quiero que el asistente pueda mirar movimientos concretos cuando hace falta ("¿en qué gasté en comida la semana pasada?"), sin que eso signifique subir mi historial entero.

**Criterios de aceptación:**
- El modelo puede pedir detalle vía tool-calling; la consulta la resuelve **la app contra su base local**, nunca el servidor contra Postgres. El servidor no lee ninguna tabla financiera.
- Las herramientas de lectura son cinco (`supabase/functions/_shared/ai/tools.ts`): `get_transactions`, `get_category_breakdown`, `compare_periods`, `get_budget_detail` y `get_goal_detail`.
- `get_transactions` devuelve **máximo 50 movimientos** (parámetro `limit` entre 1 y 50, por defecto 25), con estos campos y ningún otro: id, fecha, monto en unidades menores, moneda, tipo, nombre de categoría y nombre de cuenta.
- Si la consulta arroja más filas que el tope, el resultado marca `truncated: true` y el modelo lo dice, en vez de afirmar un total incompleto como si fuera completo.
- El detalle **no** incluye la nota de la transacción, ni las etiquetas libres, ni la contraparte de una deuda. `get_goal_detail` devuelve los aportes de una meta: **sus notas quedan fuera**, igual que las demás.
- Como máximo **3 rondas de lectura** por turno del usuario (`AI_MAX_TOOL_ROUNDS`), contadas en el servidor sobre el historial que envía el cliente. Agotadas, el modelo puede responder pero ya no pedir más datos.
- Una herramienta que el cliente no puede resolver devuelve un error explícito en el mismo campo `result`; el modelo lo explica en vez de inventar cifras.

### HU-06 — Proponer acciones que yo confirmo

Como usuario quiero que el asistente me deje aplicar su sugerencia con un toque, pero que nunca cambie mis datos por su cuenta.

**Criterios de aceptación:**
- El asistente puede proponer: crear un presupuesto, crear una meta, crear una categoría y registrar un movimiento.
- Cada propuesta se muestra como una **tarjeta con los valores concretos** que se van a escribir (monto, categoría, cuenta, fecha), editables antes de confirmar.
- **Nada se escribe hasta que el usuario confirma con un toque.** No hay auto-aplicación, ni siquiera para "acciones seguras".
- Una propuesta ignorada no deja rastro en los datos del usuario.
- La escritura la ejecuta el caso de uso de la feature correspondiente, con sus mismas validaciones (montos en enteros de unidades menores, UUID, `updatedAt`). El asistente no escribe en la base por su cuenta.
- Tras confirmar, la app muestra el resultado y permite deshacer con el mismo mecanismo que la creación manual.

### HU-07 — Mi conversación se queda en mi teléfono

Como usuario quiero saber dónde queda lo que escribí, y poder borrarlo.

**Criterios de aceptación:**
- El historial se guarda en una tabla **local, no sincronizada** (`Table.localOnly`). No viaja a Postgres ni a PowerSync.
- **Matiz que hay que decir, no esconder:** como el servidor es sin estado, el cliente **reenvía la conversación en curso en cada turno** (tope de 40 mensajes) para que el modelo tenga contexto. El historial no se *almacena* en ningún servidor, pero sí *pasa* por el proveedor en cada mensaje. La política de privacidad tiene que decirlo con esas palabras.
- El cliente poda el historial local cuando el cuerpo supera el tope del servidor (128 KB), en vez de fallar.
- Existe una acción para **borrar el historial** del asistente sin borrar nada más.
- El historial se borra también cuando el usuario borra los datos locales o borra su cuenta eligiendo borrar lo local.
- La pantalla advierte, una vez y sin alarmismo, que la conversación **no se respalda**: al cambiar de teléfono no viaja.
- La copia completa de Import/Export **no incluye** el historial del asistente. Si algún día se incluye, hay que decirlo en la política y en la propia pantalla de exportación.

### HU-08 — Lo que nunca sale del dispositivo

Como usuario quiero una lista corta y verificable de lo que el asistente jamás envía, porque "minimizamos los datos" no significa nada.

**Criterios de aceptación (cada uno con test que falle si se rompe):**
- **No se envían las notas / descripciones libres** de transacciones, aportes a metas, movimientos de deuda ni pagos programados — ni en el snapshot ni en el detalle de HU-05.
- **No se envía `Accounts.last4`** ni **`Accounts.institution`** (el nombre del banco).
- **No se envía el número completo de cuenta**: sigue viviendo solo en Keychain/Keystore y ninguna capa del asistente puede leerlo.
- **No se envía la contraparte de una deuda** (`Debts.counterparty`): del bloque de deudas solo salen totales por moneda y dirección.
- **No se envían** archivos, fotos, audio, contactos ni el contenido de notificaciones.
- **No se envía el correo ni el nombre del usuario** al proveedor del modelo.
- El test de contrato del snapshot compara el JSON serializado contra una lista blanca de claves: cualquier campo nuevo que alguien agregue al snapshot rompe el test hasta que se declare a propósito. Motivo: la fuga que importa no es la que se diseña, es la que se agrega después sin revisar la política.
- **Esta garantía es exclusivamente del cliente, y hay que saberlo.** La Edge Function acepta el snapshot como un objeto JSON cualquiera y no valida su forma (`_shared/ai/validate.ts`: solo comprueba que sea un objeto). El servidor no puede atrapar un campo de más; solo el test del cliente puede. Por eso HU-08 es un requisito con test, no una nota de diseño.

### HU-09 — Reportar una respuesta ofensiva o equivocada

Como usuario quiero poder marcar una respuesta mala sin salir de la app.

**Estado al 2026-08-25:** el lado de datos está implementado y **aplicado en dev, no en prod** (`supabase/migrations/20260825140000_ai_reports.sql`). **Falta el cliente**: no hay UI, ni datasource, ni caso de uso que escriba en `ai_reports`.

**La tensión que resuelve este diseño.** Play exige reportar *"without needing to exit the app"*, lo que descarta abrir el cliente de correo con el texto pegado y **obliga a que el reporte llegue a un servidor nuestro**. Pero el resto de la feature promete que ningún contenido de conversación se guarda en el servidor (política §17.5), y el broker está construido sin estado justamente para que esa promesa sea estructural. La excepción se sostiene porque **la dispara la persona**: es retención pedida, no retención silenciosa. Esa distinción es la que hay que preservar si esto se toca.

**Diseño implementado — tabla `public.ai_reports`:**

| Columna | Qué guarda |
|---|---|
| `id` | UUID |
| `user_id` | Quién reporta. FK a `auth.users` con `on delete cascade` |
| `created_at` | `bigint`, unix en segundos |
| `conversation_id` | El id de conversación generado en el teléfono |
| `reason` | Lista **cerrada**: `offensive`, `wrong`, `harmful`, `privacy`, `other` |
| `reported_text` | **El mensaje del asistente que la persona eligió reportar.** Es el único contenido de conversación que existe en el servidor |
| `comment` | Comentario opcional de la persona |
| `client_version` | Versión de la app |
| `status` | `pending` / `reviewed` / `dismissed`. Lo mueve un humano; la app nunca lo escribe |

**Criterios de aceptación:**
- Cada respuesta del asistente tiene una acción para **reportarla**, alcanzable **sin salir de la app**. Requisito de tienda, no un extra de UX: la *AI-Generated Content policy* de Google Play lo exige para las apps que generan contenido con IA, y su ausencia expone a **retiro**, no solo a rechazo.
- **Nada se envía automáticamente.** Solo se escribe una fila cuando la persona toca "reportar" sobre un mensaje concreto y confirma.
- **Se guarda solo el fragmento reportado**: ni la conversación, ni los mensajes anteriores, ni el snapshot financiero. No se ofrece adjuntar la conversación (cambio respecto a la versión anterior de esta HU, que contemplaba adjuntarla con consentimiento explícito: se descartó porque el fragmento basta para moderar y adjuntar el resto multiplica el dato retenido).
- **El motivo sale de una lista cerrada**, con `check` en la base. Es cerrada a propósito, para que la UI ofrezca opciones y no un campo libre que invite a pegar datos personales. El único campo libre es `comment`, y es opcional.
- **Aviso previo obligatorio.** La UI muestra, **antes de enviar**, que el mensaje reportado se guarda en nuestros servidores para poder revisarlo. Sin ese aviso, la sección 17.5 de la política queda falsa.
- **RLS: solo `insert` y `select` de las propias filas.** No hay policy de `update` ni de `delete`, así que la persona **no puede editar ni borrar** un reporte enviado —un reporte modificable después no sirve para revisar nada— ni tocar `status`. Esa limitación del derecho de rectificación se documenta en la política §11 y se resuelve por el canal de contacto.
- **Se borra con la cuenta.** `ai_reports` entra en `delete_account_data` **en la misma migración que la crea**; `delete_account_data_coverage_gaps()` devuelve cero filas en dev.
- Los reportes alimentan los ajustes del prompt y los filtros; no se usan para nada más, no se cruzan con los datos financieros y no se comparten con terceros (no viajan a Google).
- Pendientes operativos: aplicar la migración **en prod** e implementar la UI. Hasta entonces la precondición de publicación nº 5 sigue abierta.

### HU-10 — Cupos y límites, contados en el servidor

Como responsable quiero que el costo sea acotado y que el cliente no pueda saltarse el límite.

**Criterios de aceptación:**
- `ai-chat` valida el JWT, resuelve el estado de acceso y comprueba el cupo **antes** de llamar al proveedor: una compuerta cerrada no puede costar ni un token.
- El cupo de Fase A es **diario**: `ai_access.daily_message_limit`, por defecto **30 turnos con resultado `ok` por día** (UTC). Superado, la respuesta es `429 quota_exceeded` y la app la traduce a un mensaje claro, sin jerga de error.
- El conteo se hace sobre `ai_usage_log` en el servidor, vía la función `ai_access_state`. El cliente no lleva la cuenta ni puede reiniciarla.
- La habilitación se resuelve con dos fuentes: la fila del usuario en `ai_access` **o** el interruptor global `ai_feature_flags.ai_assistant_open_to_all`, que arranca **apagado** y no se enciende hasta cumplir las precondiciones de publicación.
- Si el estado de acceso no se puede leer, se **falla cerrado**: sin acceso. Un gate ilegible no es un gate abierto.
- Un cliente modificado no puede ampliar su cupo ni saltarse la habilitación: sobre `ai_access` y `ai_usage_log` solo hay política de `select` de las propias filas; escribe únicamente la Edge Function con `service_role`.

### HU-11 — Errores, sin conexión y degradación

Como usuario quiero que el asistente falle de forma entendible y que su falla no me deje sin app.

**Criterios de aceptación:**
- Sin conexión: la pantalla lo dice y ofrece reintentar. El resto de la app sigue funcionando offline como siempre.
- Error del proveedor o timeout: mensaje en español claro, con reintento; nunca un código técnico crudo.
- Ninguna función de Nivel 0 depende del asistente ni se degrada si está caído.
- Un fallo del asistente no puede dejar datos a medio escribir: la confirmación de HU-06 es atómica o no ocurre.

### HU-12 — El borrado de cuenta también borra lo del asistente

Como usuario quiero que borrar mi cuenta borre de verdad todo, incluido lo que el asistente dejó en el servidor.

**Criterios de aceptación (✅ cumplidos en la migración del 2026-08-25):**
- `ai_access` y `ai_usage_log` se eliminan dentro de `delete_account_data`, **en la misma migración que las crea**.
- Ambas tablas llevan `user_id` con FK a `auth.users(id) ON DELETE CASCADE`, siguiendo la corrección estructural de `20260808000000_delete_account_cascade_missing_tables.sql`.
- `ai_reports` (HU-09) entra a `delete_account_data` en su propia migración, con el mismo patrón.
- `delete_account_data_coverage_gaps()` devuelve **cero filas** en **dev** con las cuatro tablas del asistente. En **prod** sigue pendiente: falta aplicar las migraciones y repetir la consulta.
- Existe una prueba del flujo de borrado con un usuario que tiene filas en ambas tablas.
- Motivo: el bug B1 de `docs/legal/AUDITORIA.md` (el borrado de cuenta incompleto) ya reincidió cuatro veces, siempre por una tabla nueva que nadie agregó a la función.

### HU-13 — Observabilidad sin contenido

Como responsable quiero poder operar la feature (costo, errores, latencia) sin poder leer conversaciones.

**Criterios de aceptación:**
- `ai_usage_log` guarda por turno: fecha, día de uso, id de conversación (el que genera el dispositivo), proveedor, modelo, resultado (`ok`, `blocked`, `rate_limited`, `timeout`, `provider_error`, `invalid`), código de error, tokens de entrada y salida, rondas de herramienta, número de propuestas, latencia y versión de la app.
- Un fallo al escribir esa fila **no** puede tumbar el turno: el usuario ya tiene su respuesta. (En Fase B, cuando la fila sea la base del cupo, ese compromiso se invierte y hay que revisarlo.)
- **No guarda** el texto del usuario, ni el snapshot, ni la respuesta, ni el contenido de las propuestas. Es deliberadamente insuficiente para reconstruir una conversación, y esa insuficiencia es la feature, no una limitación.
- Sentry no puede recibir texto del chat, snapshot ni contenido de propuestas: `lib/core/crash/sentry_redaction.dart` debe cubrir esta ruta antes de activar la feature. Un crash que filtre lo que la política promete no transmitir convierte esa promesa en falsa.

### HU-14 — Idioma y tono

Como usuario quiero que me responda en mi idioma y sin sermones.

**Criterios de aceptación:**
- Responde en el idioma de la app (es / en), que viaja en los metadatos del turno.
- El tono sigue la regla de marca: positivo y de progreso, **nunca** avergonzar al usuario por sus gastos.
- No promete rendimientos, no recomienda productos financieros concretos y no se presenta como asesor.
- Cuando no tiene datos suficientes lo dice, en vez de inventar una cifra.

## Modelo de datos

**Local (Drift), nueva y no sincronizada:** tabla de mensajes del asistente con `Table.localOnly` en `powersync_schema.dart`. Cualquier tabla nueva exige subir `schemaVersion` — **léelo de `app_database.dart` al implementar** (al 2026-08-25 está en **29**), nunca de este documento.

**Servidor (Postgres), tres tablas de control** (`supabase/migrations/20260825120000_ai_assistant_access_and_usage.sql`):

| Tabla | Para qué | Qué guarda | Qué NO guarda |
|---|---|---|---|
| `ai_access` | Habilitación por usuario (beta / plan) | `user_id`, `enabled`, `tier`, `daily_message_limit`, fechas, `notes` | — |
| `ai_feature_flags` | Interruptor global de apertura | `key`, `enabled`, `notes` | Nada de ningún usuario: no tiene `user_id` |
| `ai_usage_log` | Conteo de cupo y operación | fecha, día de uso, id de conversación, proveedor, modelo, resultado, código de error, tokens, rondas de herramienta, nº de propuestas, latencia, versión de la app | texto del usuario, snapshot, respuesta del modelo, contenido de las propuestas |

Las dos con `user_id` siguen el patrón del resto del esquema: FK a `auth.users(id) ON DELETE CASCADE`, RLS que solo permite **leer** la propia fila (escribir es exclusivo de `service_role`) y borrado explícito en `delete_account_data`. **No** entran al Sync Stream de PowerSync — y como la publicación `powersync` es `FOR ALL TABLES`, eso hay que **verificarlo a mano en el dashboard** tras aplicar la migración: es la única parte del contrato que no vive en el repo.

`ai_access.notes` es texto libre administrativo sobre una persona usuaria. No es dato financiero, pero sí es dato personal: no se escribe ahí nada que no se le pueda mostrar a ella.

## Frontera Nivel 0 / Nivel 1 / Premium

| | Qué | Por qué |
|---|---|---|
| **Nivel 0 (gratis, intocable)** | Todo lo que ya existe: registro manual, categorías, presupuestos, metas, deudas, pagos programados, gráficas esenciales, import/export, y la captura local de Fase 2 | Regla de `CLAUDE.md`: ninguna feature de Nivel 0 puede quedar detrás de anuncio o pago. El asistente **no puede** convertirse en el único camino a nada de esto |
| **Nivel 1 (Modo anuncios)** | **Nada de este documento.** El parseo de captura con LLM (Cubo B) es otra feature, con otro costo y otro documento | Una sesión de chat cuesta mucho más de lo que paga un anuncio recompensado en LatAm (`Plan_Monetizacion_y_Tecnico.md` §2) |
| **Premium (Nivel 2)** | El asistente conversacional, cuando salga de beta | Es exactamente el Cubo C del plan de monetización |
| **Fase A (hoy)** | Beta cerrada, gratuita, por lista, con cupo diario (30 turnos/día por defecto) | Sirve para medir costo real y calidad antes de ponerle precio |

Cuando el asistente pase a Premium, es una **función nueva** que se cobra: no se está moviendo detrás de un pago algo que el usuario ya tenía gratis (compromiso de `terminos-de-uso.md` §7).

## Precondiciones de publicación (bloqueantes, todas)

Ninguna es negociable y ninguna es de código solamente:

1. **Key de tier de pago de la API de Gemini.** Con la capa gratuita, Google puede usar el contenido enviado para desarrollar y mejorar sus productos, con posible revisión humana. Mientras se use esa capa, la feature **no se abre a terceros** y no se declara ante las tiendas.
2. **Política de privacidad v1.5 publicada antes de activar la feature**, no el mismo día. La v1.4 afirma en público que la app no envía datos a ningún modelo de lenguaje; activar antes de publicar convierte esa frase en una declaración falsa.
3. **Declaraciones de tienda rehechas** (`docs/legal/declaraciones-tiendas.md` §8) en el mismo envío que incluya el binario con el asistente.
4. **Consentimiento explícito implementado (HU-02)**, con el nombre del proveedor visible. Sin esto, Apple 5.1.2(i) es motivo de rechazo o de retiro.
5. **Mecanismo de reporte in-app (HU-09)**, exigido por la política de contenido generado con IA de Google Play. **Parcial:** la tabla `ai_reports` con sus policies y su borrado con la cuenta ya existe (dev); falta la UI que la use y aplicar la migración en prod. Play mira el binario, así que la precondición sigue abierta.
6. **`delete_account_data` cubre las tablas nuevas (HU-12)** — ✅ ya está en la migración; falta correr `delete_account_data_coverage_gaps()` en dev y prod y confirmar cero filas.
7. **Redacción de Sentry cubre la ruta del asistente (HU-13).**
8. **Tests de contrato del snapshot y del detalle (HU-08)** en verde.

## Riesgos conocidos

- **El modelo se equivoca con seguridad.** Mitigación: confirmación humana obligatoria (HU-06), disclaimer permanente (HU-01) y reporte in-app (HU-09). No se mitiga con un prompt mejor.
- **Deriva de datos enviados.** Alguien agrega un campo al snapshot y la política queda desactualizada sin que nadie lo note. Mitigación: lista blanca con test (HU-08) y el disparador 6 de `declaraciones-tiendas.md` §6.
- **Costo variable.** Mitigación: cupo en servidor (HU-10) y beta por lista (HU-03).
- **Dependencia de un solo proveedor.** Cambiar de proveedor obliga a actualizar la política (§7 y §8) y las declaraciones de tienda; el diseño del broker lo permite, pero el trámite legal no es automático.
- **EEE.** La app hoy no se ofrece en el Espacio Económico Europeo porque faltan DPA con Sentry y PowerSync (`declaraciones-tiendas.md` §0.1). El asistente suma un tercero más a esa lista, y la capa gratuita de Gemini no es utilizable ahí en ningún caso.

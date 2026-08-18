# Checklist legal de pre-publicación — Fase 2 (captura sin fricción)

**Versión 1.0** · **Creado: 17 de agosto de 2026** · **Estado: NO VIGENTE**

> ⛔ **Este documento no describe la app de hoy.** Al 17 de agosto de 2026
> billetudo **no** captura por voz, **no** hace OCR, **no** lee notificaciones y
> **no** tiene widget. Fase 2 está **especificada** (`docs/requirements/fase-2/`)
> y **no implementada** (evidencia archivo por archivo en `AUDITORIA.md` §10.2).
>
> Los documentos **vigentes** son `politica-de-privacidad.md` (v1.4),
> `terminos-de-uso.md` (v1.2) y `declaraciones-tiendas.md` (v1.4) §0-§6. **Son
> correctos y no se tocan hasta que exista el código.**

> **Documento interno.** No se publica: `web/build_site.py` solo convierte a HTML
> `politica-de-privacidad.md`, `terminos-de-uso.md` y `como-borrar-tu-cuenta.md`.
> Este archivo, `AUDITORIA.md` y `declaraciones-tiendas.md` se quedan en el repo.
> Por eso el checklist vive aquí y **no** dentro de la política: cualquier cosa
> escrita en la política se publica literal, y una política que contiene su
> propio borrador futuro confunde al usuario y a la tienda.

**Para qué sirve:** cuando Fase 2 llegue, este documento evita el fallo más caro
—publicar con declaraciones desactualizadas— diciendo exactamente qué cambiar,
dónde y con qué precisión. Se recorre completo antes de subir el primer build
que incluya cualquiera de las cuatro features.

**Cómo se usa:** ninguna casilla se marca "por analogía". Cada una se verifica
contra el código del binario que se va a subir, igual que hizo la auditoría
original.

---

## 0. Regla que gobierna todo el checklist

Se declara **el binario**, no el plan. Mientras `lib/features/capture/` siga
teniendo solo un `.gitkeep` y `speech_to_text` / `google_mlkit_text_recognition`
sigan comentados en `pubspec.yaml:86-87`, las respuestas vigentes son las
correctas. **Declarar de más es tan sancionable como declarar de menos**, y
además rompe la confianza: prometer captura por voz en un formulario de
privacidad cuando la app no la tiene es describir un producto que no existe.

Corolario poco intuitivo, pero el que más veces se olvida: **si Fase 2 se
implementa por partes** (el orden de construcción es 19 → 17 → 18 → 20), se
declara **solo la parte que va en el binario**. Un release con notificaciones
bancarias y sin OCR no declara cámara. Ojo: `docs/requirements/README.md` fija
que el primer release público con notificaciones **debe** incluir voz y OCR
funcionando, así que ese escenario parcial no debería llegar a producción — pero
si llegara, la declaración sigue al binario.

---

## 1. Permisos nuevos por plataforma

Hoy la app declara **cero** permisos propios: el `AndroidManifest.xml` no tiene
ni un `uses-permission` y el `Info.plist` no tiene ni una clave
`*UsageDescription`. Fase 2 rompe las dos cosas, y la ficha de permisos que ven
los usuarios en la tienda cambia.

### 1.1 Android

| Permiso | Lo trae | Nota |
|---|---|---|
| `android.permission.RECORD_AUDIO` | Voz (17) | Android 11+ puede requerir además un `<queries>` para resolver el servicio de reconocimiento |
| `android.permission.CAMERA` | OCR / foto (18) | |
| `android.permission.READ_MEDIA_IMAGES` | Galería (18) — **evitable** | Solo si el flujo no usa el **Photo Picker** del sistema. Usarlo evita el permiso *y* el formulario de permisos de fotos y video de Play Console |
| `<service ... android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE">` + intent-filter `android.service.notification.NotificationListenerService` | Notificaciones bancarias (19) | **El de mayor riesgo.** Ver §3 |
| Provider de app widget | Widget (20) | No es un permiso; sí cambia el manifiesto |

### 1.2 iOS

| Clave de `Info.plist` | La trae | Nota |
|---|---|---|
| `NSMicrophoneUsageDescription` | Voz (17) | |
| `NSSpeechRecognitionUsageDescription` | Voz (17) | **Se olvida con frecuencia.** `SFSpeechRecognizer` la exige aparte del micrófono; sin ella la app crashea al pedir reconocimiento |
| `NSCameraUsageDescription` | OCR (18) | |
| `NSPhotoLibraryUsageDescription` | Galería (18) | Solo si se lee la galería |
| — | Notificaciones bancarias | **No aplica en iOS**: la plataforma no permite leer notificaciones de otras apps. La feature es solo Android y así debe describirse |

Reglas de redacción de los `*UsageDescription`:

- **Localizados** en `InfoPlist.strings` (es + en), como el resto de la app.
- Dicen el uso **real y concreto**. Apple rechaza plantillas ("esta app necesita
  acceso a la cámara"). Ejemplos utilizables como punto de partida:
  - Micrófono: *"Para que puedas dictar un gasto en vez de escribirlo. El audio
    no se guarda."*
  - Reconocimiento de voz: *"Para convertir en texto lo que dictas y llenar el
    formulario del gasto."*
  - Cámara: *"Para fotografiar un recibo y leer el monto. La foto se guarda solo
    en este dispositivo."*
  - Fotos: *"Para que elijas una foto de un recibo que ya tomaste."*
- **Solo se escribe lo que el código cumple.** "El audio no se guarda" es
  verificable; "el audio nunca sale del dispositivo" **no lo es todavía** (§5).

### 1.3 Consecuencias que arrastra cada permiso

- Petición **en contexto**, con explicación previa, y degradación no punitiva si
  se niega. No es solo UX: es la *prominent disclosure* que Play exige para
  permisos sensibles, y la única forma de que un "No permitir" de iOS —que
  aparece una sola vez— no queme la feature.
- Ninguna función de **Nivel 0** puede quedar detrás de un permiso. El registro
  manual sigue completo con el micrófono y la cámara denegados.
- El estado del permiso se **re-verifica** en cada arranque; el usuario puede
  revocarlo desde el sistema sin avisarle a la app.

---

## 2. Qué hay que reescribir en `politica-de-privacidad.md`

Sección por sección. Los textos de abajo son **borradores de trabajo**, no
redacción final: cada uno se confirma contra el código antes de publicarse.

| Sección de la política | Qué cambia |
|---|---|
| Encabezado | Nueva versión y fecha. Se publica **antes** de que la función llegue al usuario (lo promete la propia §18) |
| "Lo esencial, en diez líneas" | Añadir la línea de captura, con la precisión de la foto (§4) |
| §4.1 (datos que creas) | Filas nuevas: **capturas pendientes** (monto, comercio, fecha, emisor, pista de cuenta) y **comprobantes** (metadatos: que la transacción tiene foto, en qué dispositivo, cuándo) |
| §5 (qué sale del dispositivo) | Precisar: la **imagen** y el **texto crudo** no salen; los **campos extraídos y los metadatos del comprobante sí**, si iniciaste sesión |
| §6 (bases legales) | El acceso a notificaciones va con **consentimiento explícito y revocable**, no con ejecución del contrato. Es un tratamiento separable que el usuario activa a propósito |
| §9 (conservación) | Retención cero del material crudo (§4). Las capturas descartadas se purgan tras la ventana de deshacer |
| §10 (borrado) | Confirmar que el borrado arrastra capturas pendientes **y** los archivos de comprobante del disco |
| §14 (permisos) | Reescribir entera: hoy dice "no pedimos ningún permiso sensible" |
| §17 ("lo que hoy no hace") | Quitar el bullet de voz/foto/notificaciones **solo** para lo que ya exista en el binario |

### 2.1 Borrador — retención cero

> **Lo que dictas, fotografías o te notifica el banco no se guarda.** Cuando
> dictas un gasto, el audio y su transcripción existen mientras tienes el
> formulario abierto y se descartan al cerrarlo. Cuando fotografías un recibo,
> el texto que la app leyó se usa para llenar los campos y no se guarda. Cuando
> la app lee una notificación de tu banco, el texto de esa notificación no se
> guarda **en ninguna parte, ni siquiera un momento**: solo se conservan los
> campos que se extrajeron (monto, comercio, fecha, tipo, pista de la cuenta).
>
> Esto tiene una consecuencia que preferimos decirte: si la app entendió mal, no
> tienes el original contra el cual comparar. Lo aceptamos a propósito. Guardar
> el texto de tus notificaciones bancarias sería el dato más sensible de toda la
> app, y no queremos tenerlo.

**Condición para poder publicar ese párrafo:** que el código no persista nada de
eso ni en la base de datos, ni en un log, ni en un reporte de Sentry, ni en un
archivo temporal. Se verifica leyendo el código, no confiando en el requisito.

### 2.2 Borrador — notificaciones bancarias (Android)

> **Solo si tú lo activas.** Android no deja que una app lea notificaciones sin
> que tú lo autorices en Ajustes del sistema, y el propio sistema te advierte
> que la app podría ver **todas** tus notificaciones. Por eso billetudo hace dos
> cosas: te explica para qué antes de mandarte a esa pantalla, y **solo escucha
> las apps de bancos que tú elijas de una lista**. Del resto no lee nada.
>
> **Qué hacemos con lo que leemos:** buscamos si la notificación es un movimiento
> de dinero. Si lo es, extraemos el monto, el comercio, la fecha y los últimos
> dígitos de la cuenta, y creamos una **captura pendiente** que tú confirmas o
> descartas. El texto de la notificación no se guarda (ver arriba). Si no es un
> movimiento —una promoción, un código de seguridad—, no se crea nada y no queda
> rastro.
>
> **Puedes apagarlo cuando quieras**, desde la app o desde Ajustes del sistema, y
> borrar de una vez todas las capturas.

### 2.3 Borrador — la voz

Pendiente de la decisión de §5. **No se escribe hasta entonces.**

---

## 3. El acceso a notificaciones: la declaración de mayor riesgo

`BIND_NOTIFICATION_LISTENER_SERVICE` da acceso al contenido de **todas** las
notificaciones del teléfono. Google Play lo restringe con dureza y es el único
permiso de Fase 2 que puede tumbar la publicación entera de la app, no solo la
feature.

Antes de subir el build tiene que existir:

- [ ] **Justificación de uso escrita**: funcionalidad central y promocionada en
      la ficha, procesamiento **local**, consentimiento **explícito y por app
      emisora**, revocable desde la app y desde el sistema, retención cero del
      texto.
- [ ] **Video de demostración** del flujo completo: activación, elección de
      emisores, bandeja, confirmación, revocación.
- [ ] **Data Safety actualizado** en el mismo envío (`declaraciones-tiendas.md`
      §7.3).
- [ ] **Ficha de tienda que describa la funcionalidad**. Un permiso sensible con
      una finalidad que no aparece en la ficha es el caso típico de rechazo.
- [ ] **Voz y OCR funcionando en el mismo release.**
      `docs/Plan_Monetizacion_y_Tecnico.md` §9 exige **no depender solo de esta
      vía**, y `docs/requirements/README.md` lo eleva a condición de publicación
      no negociable. Si Google rechaza la lectura de notificaciones, la app se
      queda con una vía de captura menos, no con ninguna.
- [ ] **No combinar** este permiso con SMS, registro de llamadas o
      accesibilidad. Play Protect trata esa combinación como señal de alto
      riesgo; billetudo no pide ninguno de los tres y conviene que siga así.

`[VERIFICAR: si Play exige un formulario de declaración específico y/o video para BIND_NOTIFICATION_LISTENER_SERVICE al momento del envío]` —
la página "Permissions and APIs that Access Sensitive Information" consultada el
2026-08-17 **no** lista el acceso a notificaciones entre los permisos con
formulario propio (sí SMS/Call Log, ubicación, sensores corporales,
accesibilidad, VPN, alarmas exactas, full-screen intent). No se afirma que no
exista el requisito: no se encontró documentado. Se revisa en la consola al
momento de enviar.

---

## 4. La precisión que más fácil se rompe: foto local vs. metadatos que sí sincronizan

**La imagen del recibo es estrictamente local. Los metadatos del comprobante
sincronizan por PowerSync.** (`18-captura-ocr.md`, decisión 2026-08-17.)

Por lo tanto:

- ❌ **Prohibido:** *"esto no sale de tu teléfono"*, *"tus comprobantes no salen
  del dispositivo"*, *"todo el proceso es local"* a secas. Son **falsos** para el
  metadato, y el usuario los desmiente solo: en su segundo dispositivo ve que la
  transacción tiene comprobante.
- ✅ **Correcto:** *"La **foto** se guarda solo en este dispositivo y no se
  sincroniza. Lo que sí viaja a tu cuenta es el **registro** de que esa
  transacción tiene un comprobante y en qué dispositivo quedó guardado — para que
  desde otro teléfono sepas que existe, aunque no puedas verlo ahí."*
- La misma precisión aplica a la pérdida: **la foto se pierde** si cambias de
  teléfono o reinstalas. Hay que decirlo antes, no cuando el usuario la busque.
- Nunca escribir "el comprobante" a secas cuando se habla de lo que no viaja:
  siempre "la foto" o "la imagen".
- Lo mismo con las capturas de notificaciones: `PendingCaptures` **sincroniza**,
  así que monto, comercio, fecha, emisor y cuenta inferida **salen del
  dispositivo** si el usuario inició sesión. La promesa correcta no es "nada sale
  del dispositivo", es: **el contenido de las notificaciones no se envía a
  ningún servidor porque no se guarda en ninguna parte; lo que sincroniza son
  los datos financieros ya estructurados, del mismo tipo que un movimiento
  escrito a mano.**

---

## 5. Bloqueante abierto: a dónde va el audio mientras se transcribe

**Sin esta decisión no se puede escribir ni la política ni la casilla de audio de
las tiendas.**

`17-captura-voz.md` HU-06 lo deja abierto y lo marca como el pendiente más
urgente del documento: ¿qué hace la app cuando el reconocimiento **on-device** no
está disponible en ese dispositivo o idioma? Tanto `SFSpeechRecognizer` (iOS)
como `SpeechRecognizer` (Android) enrutan el audio a servidores de Apple o Google
en ese caso.

**No guardar no es no transmitir.** La retención cero responde *qué guardamos*
(nada); no responde *a dónde sale el audio mientras se transcribe*. Si sale:

- Apple y Google pasan a ser **destinatarios de audio del usuario** y hay que
  nombrarlos en §7 de la política.
- Las casillas de **Audio** en Data Safety y App Privacy pueden tener que decir
  "recopilado" (y, en Play, "compartido").
- La frase "el procesamiento es local", que es el argumento con el que se pide el
  micrófono, deja de ser cierta tal como se escribiría hoy.

Las tres salidas que el requisito plantea (degradar en silencio, no ofrecer voz
en esos dispositivos, o preguntar una vez con explicación) llevan a **textos de
tienda distintos**. Es una decisión de producto: este documento la señala, no la
resuelve.

- [ ] Decisión tomada y registrada en `17-captura-voz.md`.
- [ ] Política y declaraciones escritas **después** de esa decisión, no antes.

---

## 6. Menores y categorías de datos sensibles

- **La audiencia declarada no cambia**: 16-17 y 18+ en Play, 16+ en App Store.
  Fase 2 no introduce contenido ni funciones dirigidas a menores.
- **Ninguna capacidad de Fase 2 introduce datos de categorías especiales**
  (salud, biometría, religión, orientación). Ojo con la confusión frecuente: la
  voz se usa como **canal de entrada de texto**, no como biometría —no se hace
  reconocimiento del hablante ni se guarda huella de voz—, y así hay que
  describirla. Si algún día se identificara al usuario por su voz, eso **sí**
  sería dato biométrico y cambiaría el marco legal completo (RGPD art. 9, LGPD
  art. 11, dato sensible en la Ley 1581 y en la LFPDPPP).
- **El micrófono, la cámara y el acceso a notificaciones no son "datos
  sensibles" del formulario de Data Safety**, pero sí son **permisos sensibles**
  con reglas propias (§1, §3). No mezclar las dos categorías al llenar el
  formulario.
- **Incompatibilidad a tener presente:** si alguna vez se marcara una audiencia
  infantil en Play, la lectura de notificaciones sería insostenible bajo la
  Política de Familias. No marcarla.

---

## 7. Checklist final antes de subir el build

Ninguna casilla se marca por analogía; cada una se verifica contra el binario.

**Código y plataforma**

- [ ] `pubspec.yaml`: dependencias descomentadas **solo** las que la feature usa.
- [ ] `AndroidManifest.xml`: permisos y `<service>` declarados, y **ninguno de
      más**.
- [ ] `Info.plist`: todas las `*UsageDescription` que aplican, localizadas y
      específicas (incluida `NSSpeechRecognitionUsageDescription`).
- [ ] `PrivacyInfo.xcprivacy` creado (hoy **no existe**, ver B4) y coherente con
      `declaraciones-tiendas.md`.
- [ ] `delete_account_data` cubre `PendingCaptures` y `TransactionAttachments`
      **en la misma migración que las crea** (es el bug B1; ya reincidió cuatro
      veces).
- [ ] El borrado de cuenta y el borrado local eliminan también **los archivos de
      comprobante** del directorio privado (si no, se repite el patrón de B2, el
      número de cuenta que sobrevive en el llavero).
- [ ] `lib/core/crash/sentry_redaction.dart` no deja pasar rutas ni contenido de
      comprobantes, transcripciones ni texto de notificaciones. Un crash que
      filtre lo que la política promete no transmitir vuelve falsa esa promesa.
- [ ] Decidido si los comprobantes entran en la copia completa de
      Import/Export, y dicho en la política en cualquiera de los dos casos.

**Documentos**

- [ ] `politica-de-privacidad.md` actualizada y **publicada antes** de que la
      función llegue al usuario (§2).
- [ ] `declaraciones-tiendas.md` §1 y §2 actualizadas; §7 recortada a lo que
      quede pendiente.
- [ ] `AUDITORIA.md` §10.2 reescrita: deja de ser "no implementado".
- [ ] `terminos-de-uso.md` revisado (hoy no afirma nada sobre permisos ni
      captura; confirmar que sigue siendo así).
- [ ] `como-borrar-tu-cuenta.md` revisado si el borrado cambia de alcance.
- [ ] Sitio legal regenerado: `python3 web/build_site.py`.

**Tiendas**

- [ ] Data Safety de Play rehecho y enviado con el mismo build.
- [ ] App Privacy de Apple rehecho.
- [ ] Justificación de uso + video del acceso a notificaciones listos (§3).
- [ ] Ficha de tienda describe las funciones que justifican cada permiso.
- [ ] Notas para App Review actualizadas: la app funciona sin conceder micrófono
      ni cámara.

---

## 8. Límite

Este documento **no es asesoría jurídica**. Su valor es ser exacto respecto al
software y completo respecto a los requisitos de tienda; la revisión legal
formal la hace una persona abogada. Y su contenido es un **plan**: no describe
la app de hoy y no debe citarse como si lo hiciera.

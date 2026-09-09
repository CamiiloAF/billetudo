# Declaraciones de datos para Play Store y App Store — billetudo

**Versión 1.8** · **Última actualización: 9 de septiembre de 2026**
**Versión de la app a la que corresponden las respuestas vigentes: `0.0.5+8`**
`[VERIFICAR: el working tree ya está en 0.0.5+9 (pubspec.yaml:4). Confirmar contra qué build se envía y re-verificar §1.1 y §1.3 sobre ese binario]`

**Qué cambió en la versión 1.8 (9 de septiembre de 2026): §7 deja de ser un
checklist a futuro y pasa a ser el juego de respuestas del envío de Fase 2.**

El esquema de Fase 2 **ya está aplicado** (`schemaVersion` 34, tablas
`PendingCaptures` y `MerchantCategoryLearning`, columnas `Accounts.cardLast4` y
`ScheduledPayments.reminderLeadDays`) y las dependencias de voz y de
notificaciones locales **ya están descomentadas en `pubspec.yaml`**. La feature
en sí —servicio Android, UI, permisos nativos— se está construyendo en otras
ramas.

Consecuencias, y hay que leerlas juntas:

1. **§1 y §2 siguen siendo las respuestas vigentes** mientras el binario que se
   envíe no traiga la captura. Se declara el binario, no el plan: esa regla no
   cambia.
2. **§7 ya no dice "no copiar esto".** Ahora es el juego completo de respuestas
   para el envío que incluya voz, lectura de avisos bancarios y recordatorios
   locales, con la justificación de cada casilla. **OCR y widget siguen fuera de
   alcance** y no se declaran: no existen (`google_mlkit_text_recognition` sigue
   comentado en `pubspec.yaml:94`, no hay `AppWidgetProvider` ni extensión
   WidgetKit).
3. **La afirmación de §1.3 "sin voz / OCR / lectura de notificaciones" caduca**
   con ese envío. Se acotó para que diga hasta cuándo es cierta.
4. **Aparecen los primeros permisos propios de la app.** La ficha de permisos
   visible en la tienda cambia por primera vez.

**Hallazgos nuevos de esta versión, que no estaban en el checklist original:**

- **`PendingCaptures.sourcePackage` sincroniza**, y es el `packageName` de una app
  de banco. Eso es *qué apps de banco tienes instaladas* saliendo del
  dispositivo: hay que declarar **App activity → Installed apps** en Play. Ver
  §7.3.
- **Listar las apps de banco instaladas necesita visibilidad de paquetes.** Si se
  resuelve con `QUERY_ALL_PACKAGES` aparece un formulario de declaración
  obligatorio en Play Console; con un `<queries>` explícito, no. Ver §7.1.
- **El nombre de la contraparte de una transferencia** llega en claro en las
  notificaciones de algunos bancos y **sincroniza**. Es dato personal de un
  tercero y ya está cubierto por *Personal info → Name*, pero la justificación de
  esa fila hay que ampliarla. Ver §7.3.

**Qué cambió en la versión 1.7:** se re-verificaron contra el código las
precondiciones bloqueantes de §8.6. Dos ya están resueltas y dos siguen
abiertas:

- **Resuelto — precondición 8 (interruptor de notas cableado extremo a
  extremo).** Ya no es solo esquema: existe la entidad de dominio
  (`AppSettings.aiNotesAccessEnabled`), el snapshot y las herramientas del
  prompt lo leen (`_shared/ai/prompt.ts`, `NOTES_WITHHELD_SECTION` /
  `NOTES_VISIBLE_SECTION`), y hay UI en Ajustes (`AiSettingsSection`,
  `AiNotesAccessField`, `AiNotesAccessSheet`) con confirmación explícita al
  encender y apagado inmediato al desactivar. §8.7 deja de ser un checklist a
  futuro y pasa a ser la declaración vigente.
- **Resuelto — precondición 10 (sección de IA en Ajustes).**
  `settings_page.dart` ya incluye `AiSettingsSection`, con el interruptor de
  notas y el enlace para retirar el consentimiento general
  (`AiConsentWithdrawField` → `clearAiConsent`).
- **Sigue abierta — precondición 8-bis, en parte.** `aiConsentVersion` sí se
  compara de verdad (`AppSettings.hasAcceptedAiConsent`) y ya subió a `2` para
  cubrir el interruptor de notas (`lib/features/ai/domain/entities/ai_consent.dart`).
  Lo que sigue sin resolver es la precondición **9**: el texto que
  `AiConsentPage` muestra (`l10n.aiConsentBody` = *"sin notas ni datos de
  identificación bancaria"*) nunca se actualizó para mencionar que existe un
  interruptor separado para las notas. No es una afirmación falsa en sí misma
  (con el interruptor apagado por defecto, sigue siendo cierto que no viajan
  notas), pero es una oportunidad perdida de que el consentimiento inicial sea
  más informado. `[VERIFICAR: decisión de producto — si conviene ampliar
  aiConsentBody para mencionar el interruptor, y si eso amerita subir
  currentAiConsentVersion otra vez; no es una corrección de este documento,
  la decide quien mantiene el código]`.
- **Sigue abierta — precondición 4 (mecanismo de reporte in-app).** Se
  confirmó de nuevo, línea por línea: `ReportAiMessage` y su repositorio
  existen y están registrados en el contenedor de DI
  (`lib/core/di/injection.config.dart`), pero **ningún widget de
  `lib/features/ai/presentation/` lo invoca**. El único menú contextual de un
  mensaje del asistente (`AiMessageCopyMenu`) solo ofrece "Copiar" — no hay
  botón de "Reportar". La política de privacidad §17.1/17.5 y los términos de
  uso §3 describen el reporte como si ya funcionara porque estos documentos
  están escritos para el estado en que la función **debe estar antes de
  publicarse** (ver el encabezado de §8 y la Guideline de *AI-Generated
  Content* de Play), no para el estado actual del binario. **No se puede
  activar `ai_assistant_open_to_all` ni enviar esta hoja a revisión mientras
  falte ese botón** — sigue siendo el bloqueante más importante de §8.6.

Este documento contiene las respuestas campo por campo para el formulario
**Data Safety** de Google Play y para **App Privacy** de App Store Connect, con
la justificación de cada una. La evidencia está en
[`AUDITORIA.md`](AUDITORIA.md).

> **Regla de oro antes de enviar:** estas respuestas describen el binario
> `0.0.4+8`. Si en el binario que envías cambió alguna dependencia —sobre todo
> si se descomentó `google_mobile_ads` o `purchases_flutter` en `pubspec.yaml`—
> hay que rehacer esta hoja. La causa número uno de rechazo es declarar la app
> que se planeó en vez de la que se compiló.

> **Cómo leer este documento (importante).** Las secciones **§0 a §6 son las
> respuestas VIGENTES para el binario publicado hoy**. La **§7 es el juego de
> respuestas del envío de Fase 2** (voz + lectura de avisos bancarios +
> recordatorios locales): entra en vigor **el día que se compile un binario con
> esas funciones**, sustituyendo las casillas que ahí se indican, y no antes. La
> **§8 es el checklist del asistente con IA** (Fase 4), que sigue sin estar
> abierto al público. Confundir las tres cosas y declarar de más es tan
> sancionable como declarar de menos.

**Qué cambió en la versión 1.6 (28 de agosto):** se corrigió la **§8** —el
checklist del asistente con IA— en tres puntos, después de auditar el código
real de `lib/features/ai/`:

1. **§8.1 y §8.3 decían de menos.** Afirmaban que los nombres libres del usuario
   no salían más allá del chat y que el nombre de la contraparte de una deuda
   nunca viajaba. Es falso desde `SnapshotDebt`
   (`lib/features/ai/domain/entities/financial_snapshot.dart`): hoy viajan
   **cinco campos `name` de texto libre** —cuenta, categoría, presupuesto, meta
   y deuda— en el resumen de cada turno. Declarar de menos ahí es exactamente el
   tipo de respuesta que un revisor puede contrastar con el tráfico real.
2. **Nuevo: interruptor opt-in de notas.** Se documenta cómo declararlo en Play
   (recopilación *opcional*) y en Apple (sin casilla nueva, pero con obligación
   de disclosure y consentimiento). Ver §8.7.
3. **Búsqueda local por nota** (`find_scheduled_payments`, ya implementada):
   **no** cambia ninguna declaración, y se explica por qué, para que nadie la
   confunda con el punto 2.

Con ello, la política de privacidad pasa a **v1.6** y sus §17.2, §17.3 y §17.7
son la referencia de esta sección.

**Qué cambió respecto de la versión 1.4 (17 de agosto):** se escribió la **§8**,
el juego completo de respuestas para el release que incluya el **asistente
financiero con IA** (`docs/requirements/fase-4/21-asistente-ia.md`). Eso ejecuta
el **disparador 6 de §6** —datos enviados a un modelo de IA— con tres
consecuencias: categoría de datos nueva marcada como **compartida**, **tercero
nuevo** (Google, API de Gemini) y una sección propia en la política
(`politica-de-privacidad.md` §17, v1.5). Las respuestas de §1 y §2 **no se
tocaron**: el asistente no está en el código todavía (`supabase/functions/`
sigue teniendo solo `delete-account`; no hay ninguna feature de IA en `lib/`).
Lo único que se matizó en la parte vigente es el viñetazo de §1.3 sobre "sin
IA", que ahora dice hasta cuándo es cierto.

**Qué cambió en la versión 1.4 respecto de la 1.3 (8 de agosto):** el número de versión de
la app (`0.0.4+8` → `0.0.5+8`) y nada más en las respuestas. Se re-verificó, una
por una, cada afirmación de §1.1 y §1.3 contra el árbol actual: las dependencias
comentadas siguen comentadas, el manifiesto sigue sin `uses-permission` y el
`Info.plist` sigue sin claves `*UsageDescription`. Las dos columnas nuevas del
esquema (`AppSettings.quickAccessOrder`, `ScheduledPayments.goalId`,
`schemaVersion` 28) **no** crean un tipo de dato nuevo: la primera es una
preferencia de UI ya cubierta por *Other actions* / *Product Interaction*, la
segunda es una clave foránea interna. Evidencia en `AUDITORIA.md` §1.1.

---

## 0. Antes de abrir cualquier formulario

| # | Requisito | Estado |
|---|---|---|
| 1 | URL pública de la política de privacidad | ✅ **Publicada el 2026-08-18**: https://camiiloaf.github.io/billetudo/ |
| 2 | Borrado de cuenta desde la app | ✅ Implementado (ver §4) |
| 3 | Borrado de cuenta funcional para todos los usuarios | ✅ **Corregido el 2026-08-08** (migración `20260808000000_delete_account_cascade_missing_tables.sql`, aplicada en dev y prod). Ver B1 de `AUDITORIA.md` |
| 4 | URL web de borrado de cuenta (exigida por Play) | ✅ **Publicada**: https://camiiloaf.github.io/billetudo/borrar-cuenta.html |
| 5 | `PrivacyInfo.xcprivacy` en el target iOS | ✅ **Creado el 2026-08-18** en `ios/Runner/`, dentro de Copy Bundle Resources. Su contenido tiene que seguir coincidiendo con §2.2 |
| 6 | Nombre público del desarrollador | ✅ **Hecho consumado.** Las cuentas de Play y de App Store **ya están creadas** a nombre de Juan Camilo Agudelo Franco (persona natural). En Apple el *developer name* ya quedó fijado y **es irreversible**; no hay decisión pendiente aquí (ver §5) |
| 7 | Datos de contacto que la tienda publicará por su cuenta | ⚠️ Fuera del control del desarrollador y **ya condicionado** por las cuentas existentes — §5 describe qué publica hoy cada tienda y qué cambiaría al monetizar |

---

## 0.2 El v1 va solo para iPhone

`TARGETED_DEVICE_FAMILY = 1`: la app **no se distribuye para iPad**, así que
App Store **no** pide capturas de iPad y App Review no la prueba ahí.

El motivo es que ninguna pantalla está diseñada para tablet — el sistema de
diseño no tiene una sola variante de ese ancho — y una prueba de render a
1376 pt mostró la app estirada, con el importe y su etiqueta separados por casi
toda la pantalla.

La dirección importa: publicar iPhone-only y **añadir** iPad después es una
versión nueva y ya; publicar con iPad y **quitarlo** después le retira la app a
quien ya la tuviera instalada en su tablet.

Si algún día se soporta iPad, hay que generar capturas de **2064 × 2752**
(iPad 13") además de las de iPhone.

---

## 0.1 Restricción de territorio declarada en público

La política publicada dice que **billetudo no se ofrece a residentes del
Espacio Económico Europeo** (los 27 de la UE más Islandia, Liechtenstein y
Noruega), porque los DPA de **Sentry** y **PowerSync** no están firmados. El de
Supabase sí aplica, por venir en sus términos de servicio.

**Hay que excluir esos 30 países en la disponibilidad de ambas consolas.** No es
opcional ni cosmético: está declarado en un documento público, así que
distribuir allí convertiría la política en una declaración falsa — con el
agravante de que el RGPD es precisamente el régimen que exige esos acuerdos.

Cuando se firmen ambos DPA: revertir §7 de `politica-de-privacidad.md` a la
redacción simple, regenerar con `web/build_site.py`, republicar (ver
`web/README.md`) y recién entonces habilitar el EEE.

---

## 1. Google Play — Data Safety

### 1.1 Preguntas generales

| Pregunta del formulario | Respuesta | Por qué |
|---|---|---|
| ¿Tu app recopila o comparte alguno de los tipos de datos de usuario obligatorios? | **Sí** | Con sesión iniciada, los datos financieros y la cuenta viajan a nuestros servidores. Aunque el uso sin cuenta no recopile nada, Play pregunta por la app en su conjunto |
| ¿Todos los datos de usuario recopilados se cifran en tránsito? | **Sí** | Todo el tráfico va por HTTPS. `Info.plist` no relaja ATS; Supabase, PowerSync y Sentry son endpoints TLS |
| ¿Proporcionas una forma de que los usuarios soliciten la eliminación de sus datos? | **Sí** | Más → Ajustes → Eliminar cuenta. Borrado real en servidor vía Edge Function `delete-account` |
| ¿Tu app contiene anuncios? | **No** | `google_mobile_ads` está comentado en `pubspec.yaml:80`. Verificado en el manifiesto fusionado: **no aparece `com.google.android.gms.permission.AD_ID`** |
| ¿Tu app está dirigida a niños? (Target audience) | **No.** Grupos de edad a marcar: **16-17** y **18 y más** | Los términos de uso fijan **16 años** como edad mínima, así que el rango declarado debe empezar ahí. No hay verificación de edad en la app ni contenido infantil, y ningún grupo por debajo de 16 se marca. Ver la nota de abajo sobre Families |
| ¿Usas Play Billing / compras integradas? | **No** | `purchases_flutter` comentado en `pubspec.yaml:81`. No hay permiso `BILLING` en el manifiesto fusionado |
| ¿Recopilas identificadores de publicidad (AAID)? | **No** | Ningún SDK lo lee |
| ¿La app usa APIs de accesibilidad, SMS, ubicación en segundo plano, o acceso a todos los archivos? | **No** a todas | El manifiesto fusionado solo trae `INTERNET`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `REORDER_TASKS`. **Sigue siendo No también con Fase 2**: el acceso a notificaciones no es ninguna de esas cuatro cosas, y billetudo no pide accesibilidad ni SMS — combinación que Play Protect marca como alto riesgo (§7.2) |

> **Sobre el grupo 16-17.** Marcarlo es lo coherente con una edad mínima de 16
> años, pero implica declarar menores en la audiencia. La ayuda de Play dice que
> *"cualquier app con al menos un grupo de audiencia objetivo que incluya niños
> debe cumplir los requisitos de la Política de Familias"*, sin aclarar si un
> rango 16-17 sin rangos inferiores cuenta como "niños" a ese efecto. La
> exigencia concreta de esa política que suele morder —usar solo SDK de anuncios
> autocertificados para Familias— hoy no aplica: no hay SDK publicitario en el
> binario. Pero volvería a ser relevante el día que se active `google_mobile_ads`.
> `[VERIFICAR: en Play Console, si marcar 16-17 activa los requisitos de Families Policy y qué obligaciones añade]`

> **Sobre la pregunta de anuncios:** hoy la respuesta correcta es **No**, y es
> verificable contra el binario. `docs/marketing/plan-fichas-de-tienda.md` §8.3
> ya advierte que cambiarla a "Sí" en un update posterior, tras haber vendido
> "sin anuncios", es el patrón que dispara reseñas de una estrella. La decisión
> de producto (rewarded opt-in) sigue en pie, pero **no se declara antes de que
> exista en el binario**.

### 1.2 Tipos de datos — tabla de declaración

Para cada tipo: si se **recopila** (sale del dispositivo hacia nosotros), si se
**comparte** (va a un tercero como responsable independiente), si es
**obligatorio u opcional**, y para qué.

#### Personal info

| Tipo de dato | ¿Recopilado? | ¿Compartido? | ¿Obligatorio? | Finalidad | Justificación |
|---|---|---|---|---|---|
| **Name** | **Sí** | No | **Opcional** (solo si inicias sesión) | *App functionality*, *Account management* | Google/Apple entregan el nombre; se guarda en Supabase Auth y se muestra en el saludo de Inicio y en Ajustes. Además, `Debts.counterparty` puede contener el nombre de un tercero, y viaja a la nube |
| **Email address** | **Sí** | No | **Opcional** | *App functionality*, *Account management* | Lo entrega el proveedor social y lo persiste Supabase Auth. Se muestra en la tarjeta de sesión de Ajustes (`settings_session_card.dart:78-81`) y no se envía a ningún tercero |
| **User IDs** | **Sí** | No | **Opcional** | *App functionality*, *Account management* | El UUID de Supabase se estampa en la columna `user_id` de las 20 tablas |
| Address, Phone number, Race/ethnicity, Political/religious beliefs, Sexual orientation, Other info | **No** | — | — | — | No se piden en ningún lugar de la app |

> **Sobre "Name": no se declara la foto de perfil.** La URL del avatar se recibe
> del proveedor y queda en Supabase Auth, pero **la app nunca la descarga ni la
> muestra**. Si se quiere una declaración más limpia, la recomendación de
> `AUDITORIA.md` §3 es dejar de mapearla en el cliente.

#### Financial info

| Tipo de dato | ¿Recopilado? | ¿Compartido? | ¿Obligatorio? | Finalidad | Justificación |
|---|---|---|---|---|---|
| **User payment info** | **Sí** | No | **Opcional** | *App functionality* | `Accounts.institution` (nombre del banco) y `Accounts.last4` se sincronizan. **El número de cuenta completo NO**: vive solo en Keychain/Keystore y nunca sale del dispositivo |
| **Purchase history** | **Sí** | No | **Opcional** | *App functionality* | Las transacciones que el usuario registra a mano son, literalmente, su historial de gastos |
| **Other financial info** | **Sí** | No | **Opcional** | *App functionality* | Saldos, presupuestos, metas de ahorro, deudas, tasas de interés, cupos de crédito |
| Credit score | **No** | — | — | — | No existe ese concepto en la app |

> **Este es el bloque más sensible del formulario y el que más rechazos causa
> por subdeclaración.** Aunque el usuario escriba los datos a mano y la app sea
> local-first, en cuanto inicia sesión esa información viaja a un servidor bajo
> nuestro control: es recolección, y hay que declararla.

#### App activity

| Tipo de dato | ¿Recopilado? | ¿Compartido? | ¿Obligatorio? | Finalidad | Justificación |
|---|---|---|---|---|---|
| **Other user-generated content** | **Sí** | No | **Opcional** | *App functionality* | Notas de texto libre en movimientos, deudas, metas y pagos programados; nombres de cuentas, categorías, etiquetas y metas; `ImportBatches.fileName` |
| **Other actions** | **Sí** | No | **Opcional** | *App functionality* | `TutorialViews` (qué tutoriales se vieron) y `Transactions.source` se sincronizan |
| App interactions, In-app search history, Installed apps, Web browsing history | **No** | — | — | — | No hay analítica de producto de ninguna clase (§1.3) |

#### App info and performance

| Tipo de dato | ¿Recopilado? | ¿Compartido? | ¿Obligatorio? | Finalidad | Justificación |
|---|---|---|---|---|---|
| **Crash logs** | **Sí** | **Sí** (Sentry) | **Obligatorio** (no hay opt-out) | *Analytics*, *App functionality* | `sentry_flutter` activo en release. La app aún **no** tiene `beforeSend`: el filtrado de datos sensibles ocurre del lado del servidor de Sentry, no antes de enviar. Se declara con la máxima honestidad |
| **Diagnostics** | **Sí** | **Sí** (Sentry) | **Obligatorio** | *Analytics* | `enableAutoSessionTracking = true`, `tracesSampleRate = 0.2` en producción: datos de rendimiento y salud de sesión |
| Other app performance data | **No** | — | — | — | — |

> **Por qué "Crash logs" se marca como compartido:** Sentry es un procesador
> externo y Play considera compartir cualquier transferencia a un tercero,
> aunque sea un encargado. Marcarlo es la respuesta conservadora y correcta.
>
> **Por qué "Obligatorio" y no "Opcional":** hoy no existe ningún ajuste para
> desactivar Sentry. Si se añade un opt-out, esta respuesta cambia a *Opcional*.
>
> **Filtrado y retención en Sentry (organización `camilo-agudelo`).** Están
> activos *Require Data Scrubber*, *Require Using Default Scrubbers* y *Prevent
> Storing of IP Addresses*. Y la retención es de **30 días** (plan Developer /
> gratuito; los 90 días son el tope de los planes pagos). Nada de esto cambia
> las respuestas de arriba —Play pregunta qué se **recopila y comparte**, no qué
> se descarta al recibirlo— pero sí sostiene lo que declara la política y evita
> que la ficha diga más de lo que la app hace. Dos matices que hay que mantener
> en cualquier redacción: el scrubbing es **del lado del servidor** (el dato sale
> del teléfono igual) y el bloqueo de IP aplica **solo a eventos nuevos**.

#### Device or other IDs

| Tipo de dato | ¿Recopilado? | ¿Compartido? | ¿Obligatorio? | Finalidad | Justificación |
|---|---|---|---|---|---|
| **Device or other IDs** | **Sí** | **Sí** (Sentry) | **Obligatorio** | *Analytics* | Sentry genera un identificador de instalación/sesión propio para agrupar eventos. **No es el AAID**: no leemos el identificador de publicidad |

#### Tipos NO recopilados (declarar explícitamente como "No")

Location (precisa y aproximada), Health and fitness, Messages (SMS, correo,
in-app), Photos and videos, Audio files (grabaciones de voz, música), Files and
docs, Calendar, Contacts.

Justificación común: **cero permisos sensibles**. `Info.plist` no tiene ni un
`NS*UsageDescription`; el manifiesto de Android no declara cámara, micrófono,
ubicación, contactos ni almacenamiento.

> **Ojo con "Files and docs":** la app **lee** un archivo CSV o JSON cuando el
> usuario lo elige en el selector del sistema, y **escribe** archivos que
> entrega por el share sheet. Eso **no es recolección**: el archivo se procesa en
> el dispositivo y nunca se sube a nuestros servidores. La declaración correcta
> es **No**. Play define recolección como transferencia fuera del dispositivo.

### 1.3 Ausencias que conviene tener documentadas

Si Play pregunta o si hay una revisión manual, esto es lo que se puede afirmar
con evidencia:

- **Sin analítica de producto:** no hay `firebase_analytics`, `amplitude`,
  `posthog` ni `mixpanel` en `pubspec.yaml`, ni `google-services.json`.
- **Sin publicidad:** `google_mobile_ads` comentado; sin permiso `AD_ID` en el
  manifiesto fusionado.
- **Sin push remotas — y ojo con el matiz, que cambió el 2026-09-09.** No hay
  `firebase_messaging`, no hay `google-services.json` y no existe ningún token de
  push: la app **no puede** enviar un mensaje remoto. Lo que sí está ya en
  `pubspec.yaml` es `flutter_local_notifications` (`:102`) con `timezone`
  (`:103`), para **recordatorios programados en el propio dispositivo**. Mientras
  ninguna feature los use y el manifiesto no declare `POST_NOTIFICATIONS`, la
  respuesta de Data Safety no cambia; el día que se usen, ver §7.
- **Sin compras:** `purchases_flutter` comentado; sin permiso `BILLING`.
- **Sin voz / OCR / lectura de notificaciones — afirmación con fecha de
  caducidad, re-verificada el 2026-09-09.** Sigue siendo **cierta para el
  binario**: `lib/features/capture/` y `lib/features/improvement/` están vacías
  (0 archivos), no hay ni una importación de `speech_to_text`,
  `flutter_local_notifications` o `permission_handler` en todo `lib/`, el único
  `.kt` del proyecto es `MainActivity.kt`, `AndroidManifest.xml` no declara **ni
  un** `uses-permission` ni ningún `<service>` de `NotificationListenerService`, y
  `ios/Runner/Info.plist` no tiene ninguna clave `*UsageDescription`.
  **Pero el andamiaje ya está puesto y esta viñeta se cae con el siguiente
  build de captura:** `speech_to_text` (`pubspec.yaml:90`),
  `flutter_local_notifications` (`:102`), `timezone` (`:103`) y
  `permission_handler` (`:106`) **ya están descomentados**, y el esquema de Fase 2
  ya está aplicado (`schemaVersion` 34: `PendingCaptures`,
  `MerchantCategoryLearning`, `Accounts.cardLast4`,
  `ScheduledPayments.reminderLeadDays`). **§7 tiene el juego completo de
  respuestas nuevas.** Lo que **no** cambia es OCR: `google_mlkit_text_recognition`
  sigue comentado (`pubspec.yaml:94`) y no hay nada de cámara ni de galería.
- **Sin IA — cierto solo mientras el asistente no esté en el binario.**
  Verificado el 2026-08-25: `supabase/functions/` contiene únicamente
  `delete-account`, no hay ninguna feature de IA en `lib/` y ningún endpoint de
  la app habla con un proveedor de modelos. **Esta es la afirmación con fecha de
  caducidad más corta de todo el documento**: el asistente está diseñado y
  especificado (`docs/requirements/fase-4/21-asistente-ia.md`), y el primer
  binario que lo incluya invalida esta viñeta, la casilla de "compartido con
  terceros" de los datos financieros y de contenido, y la respuesta de IA
  generativa de Play. **§8 tiene el juego completo de respuestas nuevas**; no se
  improvisa al momento del envío.

### 1.4 Otros campos de Play Console

| Campo | Respuesta |
|---|---|
| URL de la política de privacidad | https://camiiloaf.github.io/billetudo/ |
| URL de eliminación de cuenta (Data deletion) | https://camiiloaf.github.io/billetudo/borrar-cuenta.html — Play exige una **URL web**, además del flujo in-app |
| ¿La app permite crear cuenta? | **Sí** (opcional, solo social) |
| ¿La eliminación borra todos los datos o solo algunos? | **Todos** — una vez corregido B1 |
| Categoría de la app | Finanzas |
| Clasificación de contenido | Sin contenido sensible. `[VERIFICAR: completar el cuestionario IARC en la consola]` |
| Declaración de app financiera | Play tiene una sección específica para apps financieras. billetudo **no** es un servicio financiero regulado: no mueve dinero, no presta, no invierte, no se conecta a bancos. `[VERIFICAR: si Play exige documentación adicional para la categoría Finanzas en el país de publicación]` |

---

## 2. Apple — App Privacy (etiquetas de privacidad)

Apple pide, por cada tipo de dato: **si se recopila**, y si se usa para
**seguimiento**, **publicidad de terceros**, **publicidad o marketing propio**,
**analítica**, **personalización**, **funcionalidad de la app** o **otros
propósitos**. Y por cada uno, si está **vinculado a la identidad del usuario**.

### 2.1 Pregunta de partida

| Pregunta | Respuesta |
|---|---|
| ¿Recopilas datos de esta app? | **Sí** |
| ¿Usas datos para hacer seguimiento (tracking) según la definición de Apple? | **No** — no combinamos datos con los de terceros ni con corredores de datos, y no hay identificador de publicidad. Por eso la app **no muestra el prompt de ATT** y no incluye `NSUserTrackingUsageDescription` |

### 2.2 Datos recopilados

#### Contact Info

| Tipo | ¿Recopilado? | ¿Vinculado al usuario? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **Email Address** | **Sí** | **Sí** | No | App Functionality |
| **Name** | **Sí** | **Sí** | No | App Functionality |
| Phone Number, Physical Address, Other Contact Info | **No** | — | — | — |

#### Financial Info

| Tipo | ¿Recopilado? | ¿Vinculado al usuario? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **Payment Info** | **Sí** | **Sí** | No | App Functionality |
| **Other Financial Info** | **Sí** | **Sí** | No | App Functionality |
| Credit Info | **No** | — | — | — |

Justificación idéntica a Play: nombre de la entidad financiera y últimos 4
dígitos se sincronizan; saldos, montos, deudas, metas y presupuestos también.
El número de cuenta completo, no.

> Apple define *Payment Info* como "forma de pago, número de tarjeta, cuenta
> bancaria". Los últimos 4 dígitos y el nombre del banco caen dentro con
> holgura. Declararlo es lo correcto aunque no permita cobrar nada.

#### User Content

| Tipo | ¿Recopilado? | ¿Vinculado? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **Other User Content** | **Sí** | **Sí** | No | App Functionality |
| Emails or Text Messages, Photos or Videos, Audio Data, Gameplay Content, Customer Support | **No** | — | — | — |

Notas de texto libre, nombres de cuentas/categorías/metas/etiquetas y el nombre
del archivo importado.

#### Identifiers

| Tipo | ¿Recopilado? | ¿Vinculado? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **User ID** | **Sí** | **Sí** | No | App Functionality |
| **Device ID** | **Sí** | **No** | No | Analytics |
| Advertising Data / IDFA | **No** | — | — | — |

`Device ID` corresponde al identificador de instalación que genera Sentry para
agrupar eventos. **No vinculado**, porque los eventos de Sentry no llevan el
UUID del usuario (`setUser` no tiene call sites). La organización de Sentry tiene
activo *Prevent Storing of IP Addresses*, así que los eventos nuevos tampoco
guardan la dirección IP; los almacenados antes de activarlo la conservan hasta
que venza la retención de 30 días.

#### Usage Data

| Tipo | ¿Recopilado? | ¿Vinculado? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **Product Interaction** | **Sí** | **Sí** | No | App Functionality |
| Advertising Data, Other Usage Data | **No** | — | — | — |

`TutorialViews` y `Transactions.source` se sincronizan con la cuenta del
usuario. Es un uso mínimo, pero es interacción con el producto vinculada a una
identidad, así que se declara.

#### Diagnostics

| Tipo | ¿Recopilado? | ¿Vinculado? | ¿Tracking? | Propósitos |
|---|---|---|---|---|
| **Crash Data** | **Sí** | **No** | No | Analytics |
| **Performance Data** | **Sí** | **No** | No | Analytics |
| **Other Diagnostic Data** | **Sí** | **No** | No | Analytics |

#### Tipos NO recopilados

Location (precisa y aproximada), Health & Fitness, Sensitive Info, Contacts,
Browsing History, Search History, Purchases (no hay compras in-app),
Environment Scanning, Body/Hands, Head, Other Data Types.

### 2.3 Otros campos de App Store Connect

| Campo | Respuesta |
|---|---|
| URL de la política de privacidad | https://camiiloaf.github.io/billetudo/ |
| URL de los términos (EULA) | https://camiiloaf.github.io/billetudo/terminos.html — si se deja vacío, Apple aplica su EULA estándar |
| Clasificación por edad | **16+**. Sin contenido sensible: el cuestionario por sí solo daría 4+, pero Apple permite subir la clasificación manualmente y 16+ es lo consistente con la edad mínima de 16 años de los términos. Ojo: Apple rehizo los tramos en 2025 (hoy son 4+, 9+, 13+, 16+ y 18+; desaparecieron 12+ y 17+) y el cuestionario ampliado ya es obligatorio |
| ¿La app requiere inicio de sesión para funcionar? | **No** — importante: Guideline 5.1.1(iii) prohíbe forzar el registro para funciones que no lo necesitan, y billetudo es funcional sin cuenta. Es un punto **a favor** en la revisión |
| Cuenta de demostración para App Review | No necesaria (la app funciona sin login), **pero conviene aportarla** para que el revisor pueda validar el flujo de borrado de cuenta de 5.1.1(v). `[VERIFICAR: cuenta de prueba de Google o Apple para el equipo de revisión]` |
| Notas para App Review | Ver §2.4 |
| Encryption / export compliance | La app usa solo HTTPS y el cifrado del sistema operativo (Keychain). Corresponde a la exención estándar: `ITSAppUsesNonExemptEncryption = false`. `[VERIFICAR: añadir esa clave a Info.plist para no responder el cuestionario en cada envío]` |

### 2.4 Notas sugeridas para App Review

Texto listo para pegar en el campo "Notes" (adaptar tras verificar los huecos):

> billetudo es una app de finanzas personales **local-first**. Funciona por
> completo sin crear cuenta y sin conexión: los datos se guardan en una base de
> datos SQLite dentro del sandbox de la app.
>
> **No se requiere inicio de sesión** para usar ninguna función. El login social
> (Sign in with Apple y Google) es opcional y solo activa la sincronización en
> la nube.
>
> **Sign in with Apple está implementado** y ofrecido junto a Google en iOS,
> conforme a la Guideline 4.8.
>
> **Borrado de cuenta dentro de la app** (Guideline 5.1.1(v)):
> Más → Ajustes → Eliminar cuenta. Elimina los datos y el usuario del servidor
> de forma inmediata, no es una desactivación. La opción también está disponible
> sin sesión iniciada, en cuyo caso borra los datos locales y lo indica en
> pantalla.
>
> La app **no se conecta a bancos**, no procesa pagos y no es un servicio
> financiero regulado: toda la información la introduce el usuario a mano.
>
> No contiene publicidad, analítica de comportamiento ni compras integradas.

---

## 3. Correspondencia entre ambas tiendas

Para que nadie tenga que recomponer el mapeo bajo presión:

| Concepto real en billetudo | Play (Data Safety) | Apple (App Privacy) |
|---|---|---|
| Correo del login social | Personal info → Email address | Contact Info → Email Address |
| Nombre del login social + `Debts.counterparty` | Personal info → Name | Contact Info → Name |
| UUID de usuario | Personal info → User IDs | Identifiers → User ID |
| Banco y últimos 4 dígitos | Financial info → User payment info | Financial Info → Payment Info |
| Movimientos registrados | Financial info → Purchase history | Financial Info → Other Financial Info |
| Saldos, presupuestos, metas, deudas | Financial info → Other financial info | Financial Info → Other Financial Info |
| Notas y nombres libres | App activity → Other user-generated content | User Content → Other User Content |
| Tutoriales vistos, origen del movimiento | App activity → Other actions | Usage Data → Product Interaction |
| Errores de Sentry | App info and performance → Crash logs | Diagnostics → Crash Data |
| Rendimiento de Sentry | App info and performance → Diagnostics | Diagnostics → Performance Data |
| ID de instalación de Sentry | Device or other IDs | Identifiers → Device ID |
| *(solo con el envío de Fase 2, §7)* Audio del dictado | Audio → Voice or sound recordings *(efímero)* | Audio Data — ver la nota de criterio en §7.4 |
| *(§7)* `PendingCaptures.sourcePackage` | App activity → Installed apps | *(no aplica: la feature es solo Android)* |
| *(§7)* Nombre de la contraparte extraído de un aviso bancario | Personal info → Name | *(no aplica: solo Android)* |
| *(§7)* Campos financieros de una captura pendiente | Financial info → Purchase history | *(no aplica: solo Android)* |
| *(§7)* `Accounts.cardLast4` | Financial info → User payment info | Financial Info → Payment Info |
| *(§7)* Aprendizaje comercio→categoría, `reminderLeadDays` | App activity → Other actions | Usage Data → Product Interaction |

---

## 4. Evidencia del borrado de cuenta (para adjuntar si lo piden)

**Camino en la app:** Más → Ajustes → **"Eliminar cuenta"** → hoja *"Eliminar
tu cuenta"* → **"Eliminar cuenta"** → hoja *"¿Qué hacemos con tus datos en este
teléfono?"* → **"Continuar"** → pantalla *"Listo, tu cuenta fue eliminada"*.

**Qué hace en el servidor:** el cliente invoca la Edge Function
`delete-account`, que valida el JWT del usuario en el servidor (nunca confía en
un id enviado por el cliente), ejecuta una función de Postgres atómica que
elimina las filas del usuario en todas las tablas, y después elimina el usuario
de `auth.users`. No es un borrado lógico ni una desactivación.

**Disponible sin sesión:** sí. En ese caso solo borra los datos locales y la
pantalla lo dice explícitamente, para que el usuario no crea que borró algo de
la nube.

⛔ **Recordatorio:** hasta que se corrija el bloqueante **B1** de
`AUDITORIA.md`, esta afirmación no es cierta para todos los usuarios.

---

## 5. Identidad del desarrollador: qué publica cada tienda por su cuenta

El responsable de billetudo es una **persona natural**, y la decisión tomada es
**no publicar domicilio** en la política de privacidad ni en los términos. Esa
decisión es válida para *nuestros* documentos, pero **no** alcanza a lo que las
tiendas exigen y muestran: eso lo deciden Apple y Google en la consola, no
nosotros.

**Punto de partida, ya fijado:** las cuentas de desarrollador de Google Play y de
App Store Connect **ya están creadas**, ambas como persona natural a nombre de
Juan Camilo Agudelo Franco. Por lo tanto esta sección **no plantea una decisión
previa** —ese momento ya pasó—: describe qué publica hoy cada tienda con las
cuentas tal como están, y qué cambia si se activa la monetización o se distribuye
en la UE. Lo único que sigue abierto es eso último.

> Regla mental: la **política de privacidad** dice quién trata tus datos. La
> **consola** verifica quién eres para poder distribuir. Son dos cosas distintas
> y la segunda es más invasiva.

### 5.1 Google Play — verificación de identidad y datos visibles

Todas las cuentas de desarrollador, incluidas las personales, pasan por
verificación de identidad antes de poder publicar.

| Qué | Cuenta personal (persona natural) | Fuente |
|---|---|---|
| Documentos que exige la verificación | Documento de identidad oficial expedido por el gobierno. La dirección legal se toma del perfil de pagos de Google vinculado a la cuenta y hay que verificarla antes de publicar | [Verify your developer identity information](https://support.google.com/googleplay/android-developer/answer/10841920) · [Required information to create a Play Console developer account](https://support.google.com/googleplay/android-developer/answer/13628312) |
| Qué se muestra públicamente **sin** monetización | Nombre legal, **país** (derivado de la dirección legal) y correo de desarrollador | [Required information…](https://support.google.com/googleplay/android-developer/answer/13628312) |
| Qué se muestra públicamente **con** monetización | **La dirección completa.** Google es explícito: las cuentas *merchant* —las que monetizan con apps de pago o compras integradas— deben mostrar su dirección completa en Google Play | [View and manage your developer account information](https://support.google.com/googleplay/android-developer/answer/13634081) |
| Datos de contacto de la ficha | El correo, el teléfono y el sitio web que se cargan en "store listing contact details" **aparecen en la ficha de la app** | [View and manage your developer account information](https://support.google.com/googleplay/android-developer/answer/13634081) |
| Qué **no** se muestra | El "contact name", "contact email" y "contact phone" de la cuenta: Google los usa solo para comunicarse con el desarrollador | [View and manage your developer account information](https://support.google.com/googleplay/android-developer/answer/13634081) |

**Consecuencia directa para billetudo.** La cuenta de Play ya existe como cuenta
personal, así que la verificación de identidad y la dirección legal del perfil de
pagos ya están en juego. Hoy la app no monetiza:
`purchases_flutter` está comentado en `pubspec.yaml:81` y no hay permiso
`BILLING` en el manifiesto fusionado (§1.1). Mientras eso siga así, Play
mostraría nombre legal + país + correo, **no** el domicilio. Pero el plan de
producto contempla Premium con RevenueCat: **el día que se active una compra
integrada, la cuenta pasa a ser merchant y la dirección completa se vuelve
pública.** Eso hay que decidirlo antes, no después.

⚠️ Play **no acepta oficinas virtuales ni apartados postales** para cuentas
personales, así que la dirección que se haría pública al monetizar es la
residencial. La cuenta ya está creada como personal: cambiar eso implicaría
constituir una persona jurídica y **abrir una cuenta de organización distinta**
—con la migración de la app que eso supone—, no editar un campo. Es una decisión
de negocio, no de redacción legal, y hay que tomarla **antes de activar la
primera compra integrada**.
`[VERIFICAR: decisión sobre monetización vs. exposición del domicilio residencial, antes de activar compras integradas]`

### 5.2 App Store Connect — nombre de vendedor y estado de "trader" en la UE

| Qué | Cuenta de individuo | Fuente |
|---|---|---|
| Nombre que se muestra como *seller* / *developer* | **El nombre legal de la persona: Juan Camilo Agudelo Franco.** Apple solo permite un nombre distinto (marca, DBA) a las cuentas de organización. El *developer name* se fija al crear la cuenta/primera app y **no se puede editar después** — con la cuenta ya creada, esto es **definitivo**, no una opción | [Set your developer name](https://developer.apple.com/help/app-store-connect/create-an-app-record/set-your-developer-name) · [Program enrollment](https://developer.apple.com/help/account/membership/program-enrollment/) |
| Estado de *trader* (Reglamento de Servicios Digitales de la UE) | Al enviar una app nueva, App Store Connect obliga a declarar si eres *trader*. **Si lo eres, un individuo debe cargar dirección o apartado postal, teléfono y correo, y Apple los publica en la ficha de la app en la UE** | [Manage European Union Digital Services Act trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/) |
| Si se declara "no soy trader" | Apple informa a los consumidores de la UE que los derechos de la normativa de consumo no aplican al contrato entre el desarrollador y ellos | misma fuente |

**Consecuencia directa para billetudo.** Apple sí acepta **apartado postal** para
individuos en la declaración de trader, a diferencia de Play. Pero la pregunta
de fondo sigue viva: billetudo se construye como producto freemium con Premium
de pago, y una app distribuida con ánimo comercial encaja en la definición de
*trader* del RSD ("persona física… que actúa con fines relacionados con su
actividad comercial, negocio, oficio o profesión"). Declararse "no trader" para
evitar publicar el contacto **no es una opción segura** si después se cobra por
la app, y además degrada la ficha en la UE.
`[VERIFICAR: declaración de estado de trader en la UE — decisión que conviene tomar con asesoría, sobre todo si billetudo se distribuye en España]`

### 5.3 Lo que no pudimos confirmar

- **Google Play y el estado de trader del RSD.** La documentación pública de
  Play Console que revisamos (verificación de identidad, información requerida
  para crear la cuenta, gestión de la información de la cuenta) **no menciona**
  una declaración de *trader* equivalente a la de Apple. No afirmamos que no
  exista: no la encontramos documentada. Hay que revisarlo en la consola al
  momento de publicar en la UE.
  `[VERIFICAR: si Play Console exige declaración de trader del RSD para distribuir en la UE y qué datos publica en ese caso]`
- **El nombre de desarrollador en Play.** La documentación indica que puede
  diferir del nombre legal, pero también que el nombre legal se muestra
  públicamente. Es decir: el alias no oculta el nombre legal.

### 5.4 Resumen para tomar la decisión

| Escenario | Play muestra | App Store muestra |
|---|---|---|
| Hoy (cuentas creadas, sin monetización, sin declarar trader) | Nombre legal, país, correo | Nombre legal como seller (ya fijado, irreversible) |
| Con Premium / compras integradas | Nombre legal, **dirección completa**, correo | Nombre legal como seller |
| Distribuyendo en la UE como trader | `[VERIFICAR]` — ver §5.3 | Nombre legal, **dirección o apartado postal, teléfono y correo** |

La política de privacidad no lleva domicilio y eso es correcto. Lo que este
cuadro deja claro es que **la exposición del domicilio no se decide en la
política, se decide al elegir el modelo de monetización y los mercados**.

---

## 6. Cuándo hay que rehacer este documento

Cualquiera de estos cambios invalida las respuestas de arriba:

1. Descomentar `google_mobile_ads` → cambia "¿contiene anuncios?", aparece el
   permiso `AD_ID` y hay que declarar identificadores de publicidad y, muy
   probablemente, **tracking** en Apple (con prompt de ATT).
2. Descomentar `purchases_flutter` → aparece el permiso `BILLING`, hay que
   declarar compras y, en Apple, `Purchases`. **Además, la cuenta de Play pasa a
   ser merchant y la dirección completa del desarrollador se vuelve pública
   (§5.1).**
3. Añadir `speech_to_text`, el OCR, la lectura de notificaciones bancarias, los
   recordatorios locales o el widget (**Fase 2**) → permisos de micrófono,
   notificaciones, cámara y acceso a notificaciones, más `NS*UsageDescription` y
   sus tipos de dato. **Ejecutado parcialmente el 2026-09-09** para voz + avisos
   bancarios + recordatorios locales: política v1.8 §18 y **§7 de este
   documento**, que ya es el juego de respuestas del envío. OCR y widget siguen
   fuera.
4. Añadir cualquier analítica de producto → nuevos tipos en *App activity* /
   *Usage Data*.
5. Añadir notificaciones push → nuevo identificador de dispositivo y nuevos
   propósitos.
6. Enviar datos a un modelo de IA → nueva categoría, nuevo tercero y una
   sección nueva en la política. **Ejecutado el 2026-08-25 para el asistente de
   Fase A**: política v1.5 §17, tercero nuevo (Google, API de Gemini) y §8 de
   este documento. Las respuestas de §8 entran en vigor **en el envío que
   incluya el binario con el asistente**, no antes.
7. Añadir un opt-out de Sentry → *Crash logs* y *Diagnostics* pasan de
   **Obligatorio** a **Opcional**.
8. Subir de plan en Sentry (Team, Business o Enterprise) → la retención deja de
   ser de 30 días y hay que corregir §5.3 y §9 de la política.
9. Cambiar de proveedor o de región de alojamiento → hay que actualizar la
   sección de transferencias internacionales de la política.

---

## 7. Fase 2 — voz, avisos bancarios y recordatorios locales

> **Estado (2026-09-09).** Esta sección **ya es el juego de respuestas del
> envío**, no un checklist a futuro. Entra en vigor en el **primer build que
> contenga** la captura por voz, la lectura de avisos bancarios o los
> recordatorios locales — TestFlight e Internal Testing incluidos: un canal de
> pruebas cerrado también exige Data Safety y App Privacy correctos.
>
> **Hasta ese build, las respuestas vigentes siguen siendo las de §1 y §2.** Hoy
> el binario todavía no trae nada de esto (evidencia en `AUDITORIA.md` §10.2).
>
> **OCR y widget siguen fuera de alcance y NO se declaran.**
> `google_mlkit_text_recognition` sigue comentado (`pubspec.yaml:94`), no hay
> `AppWidgetProvider`, no hay extensión WidgetKit, y la app **no pide cámara ni
> galería**. Declarar cámara "porque viene en la fase" es exactamente el error
> que esta sección existe para evitar.

Referencia de política: `politica-de-privacidad.md` **v1.8** §4.6, §14 y §18.
Evidencia de esquema: `AUDITORIA.md` §13.

### 7.0 Alcance exacto de lo que se declara

| Capacidad | ¿Entra en esta declaración? | Plataforma |
|---|---|---|
| Dictar un gasto (voz → texto → formulario) | **Sí** | Android + iOS |
| Leer avisos de apps de banco elegidas por el usuario | **Sí** | **Solo Android** |
| Recordatorios de pagos programados (notificaciones locales) | **Sí** | Android + iOS |
| OCR de recibos / cámara / galería | **No** | — |
| Widget de pantalla de inicio | **No** | — |

### 7.1 Permisos y declaraciones nativas que aparecen por primera vez

Hoy la app declara **cero** `uses-permission`. Este envío rompe eso.

#### Android

| Elemento del manifiesto | Lo trae | Nota |
|---|---|---|
| `android.permission.RECORD_AUDIO` | Voz | Runtime. Se pide en el primer dictado, con explicación previa |
| `<service>` con `android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"` + intent-filter `android.service.notification.NotificationListenerService` | Avisos bancarios | **El de mayor riesgo.** Ver §7.2 |
| `android.permission.POST_NOTIFICATIONS` | Recordatorios | Runtime desde Android 13 |
| `android.permission.RECEIVE_BOOT_COMPLETED` | Recordatorios | Para reprogramar tras reiniciar. No es runtime |
| `<queries>` con los `packageName` del catálogo de emisores | Avisos bancarios | **Ver el aviso de abajo** |

> ⛔ **No usar `QUERY_ALL_PACKAGES`.** Para mostrar "qué apps de banco tienes
> instaladas" (HU-02) hay que consultar el `PackageManager`, y en Android 11+ eso
> exige visibilidad de paquetes. Resolverlo con `QUERY_ALL_PACKAGES` **activa un
> formulario de declaración obligatorio en Play Console** — es uno de los pocos
> permisos que sí lo tienen ([Permissions and APIs that Access Sensitive
> Information](https://support.google.com/googleplay/android-developer/answer/16558241),
> consultada el 2026-09-09) — y sería desproporcionado: el catálogo de emisores
> es **cerrado y conocido**. Lo correcto es un bloque `<queries>` con los cuatro
> `packageName` explícitos. Con eso no hay formulario y la declaración es
> coherente con "solo miramos bancos".
>
> `[VERIFICAR: que la implementación resuelve la lista con <queries> explícito y
> NO con QUERY_ALL_PACKAGES. Lo verifica quien implemente HU-02; hoy no hay
> código que revisar]`

> **`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`: no usarlos si se puede evitar.**
> Un recordatorio de "faltan 3 días para tu pago" **no** necesita precisión al
> segundo, y las alarmas exactas **sí** tienen formulario de declaración propio
> en Play Console. `zonedSchedule` de `flutter_local_notifications` permite
> programar sin alarma exacta (`AndroidScheduleMode.inexactAllowWhileIdle`).
> `[VERIFICAR: modo de programación elegido al implementar los recordatorios. Si
> se usa exacto, hay que llenar el formulario de alarmas exactas y justificarlo]`

#### iOS

| Clave de `Info.plist` | La trae | Nota |
|---|---|---|
| `NSMicrophoneUsageDescription` | Voz | |
| `NSSpeechRecognitionUsageDescription` | Voz | **Se olvida con frecuencia.** `SFSpeechRecognizer` la exige aparte del micrófono; sin ella la app crashea al pedir autorización |
| — (permiso de notificaciones) | Recordatorios | No lleva clave de `Info.plist`: se pide en runtime con `UNUserNotificationCenter` |
| — | Avisos bancarios | **No aplica**: iOS no permite leer notificaciones ajenas |

Reglas de redacción de los `*UsageDescription`, no negociables:

- **Localizados** en `InfoPlist.strings` (es + en), como el resto de la app.
- Dicen el uso **real y concreto**. Apple rechaza plantillas genéricas.
- **Solo se escribe lo que el código cumple.** "El audio no se guarda" es
  verificable. "El audio nunca sale del dispositivo" **es falso** y no se puede
  escribir (§7.5).

Textos propuestos, listos para `InfoPlist.strings`:

| Clave | es | en |
|---|---|---|
| `NSMicrophoneUsageDescription` | Para que puedas dictar un gasto en vez de escribirlo. El audio no se guarda. | So you can dictate an expense instead of typing it. The audio is not stored. |
| `NSSpeechRecognitionUsageDescription` | Para convertir en texto lo que dictas y llenar el formulario del gasto. Si tu iPhone no puede hacerlo por su cuenta, iOS envía ese audio a Apple para transcribirlo. | To turn what you dictate into text and fill in the expense form. If your iPhone cannot do it on its own, iOS sends that audio to Apple for transcription. |

#### Consecuencias que arrastra cada permiso

- **Prominent disclosure de Play, obligatoria.** La [política de datos del
  usuario](https://support.google.com/googleplay/android-developer/answer/10144311)
  exige una divulgación **dentro de la app**, visible en el uso normal, **antes**
  de pedir el permiso, que describa **qué dato se accede** y **cómo se usa o se
  comparte**, separada de la política de privacidad y con una acción afirmativa
  del usuario. Los textos están en
  [`textos-consentimiento-fase-2.md`](textos-consentimiento-fase-2.md).
- **Ninguna función de Nivel 0 detrás de un permiso.** El registro manual sigue
  completo con micrófono y notificaciones denegados.
- **El estado del permiso se re-verifica en cada arranque**: el usuario puede
  revocarlo desde el sistema sin avisarle a la app.

### 7.2 El acceso a notificaciones es la declaración de mayor riesgo

`BIND_NOTIFICATION_LISTENER_SERVICE` da acceso al contenido de **todas** las
notificaciones del teléfono. Es el permiso más invasivo del catálogo y el único
de este envío que puede, por sí solo, tumbar la publicación entera de la app.

Qué tiene que existir **antes** de subir el build:

1. **Justificación de uso escrita.** Está redactada en
   [`declaracion-permiso-notificaciones.md`](declaracion-permiso-notificaciones.md),
   lista para pegar en la consola o para responder un correo de política.
2. **Video de demostración** del flujo completo. Guion en ese mismo documento.
3. **Data Safety actualizado en el mismo envío** (§7.3).
4. **La ficha de tienda debe describir la funcionalidad.** Un permiso sensible
   cuya finalidad no aparece en la ficha es el caso típico de rechazo.
5. **No combinar** este permiso con SMS, registro de llamadas o accesibilidad.
   Play Protect trata esa combinación como señal de alto riesgo; billetudo no
   pide ninguno de los tres y conviene que siga así.
6. **La condición de release del propio proyecto.**
   `docs/requirements/fase-2/19-notificaciones-bancarias.md` y
   `docs/requirements/README.md` fijan que esta feature **no se publica sola**:
   el release público debe llevar **voz y OCR funcionando**. Este envío lleva voz
   pero **no** OCR. Ver §7.6 — es una decisión de producto que hay que reabrir
   explícitamente antes de un release público, no un detalle de declaración.

`[VERIFICAR: si Play exige un formulario de declaración específico y/o video para
BIND_NOTIFICATION_LISTENER_SERVICE al momento del envío]` — la página
["Permissions and APIs that Access Sensitive
Information"](https://support.google.com/googleplay/android-developer/answer/16558241)
y su [versión preview](https://support.google.com/googleplay/android-developer/answer/16909972),
consultadas el **2026-09-09**, **no** listan el acceso a notificaciones entre los
permisos con formulario propio. Sí lo tienen: SMS/Call Log, ubicación en segundo
plano, All Files Access, `QUERY_ALL_PACKAGES`, `REQUEST_INSTALL_PACKAGES`,
accesibilidad, Health Connect, alarmas exactas y full-screen intent. **No se
afirma que el requisito no exista: no se encontró documentado.** Se revisa en la
consola al momento de enviar, que es donde aparecería.

### 7.3 Google Play — Data Safety, casilla por casilla

Solo se listan las filas que **cambian** o cuya **justificación** cambia. El
resto de §1.2 se mantiene tal cual.

| Tipo de dato | Hoy | Con este envío | Por qué |
|---|---|---|---|
| **Audio → Voice or sound recordings** | No | **Sí — recopilado, opcional, marcado como *procesamiento efímero*.** Compartido: ver el bloque de abajo | Play define recopilar como **transmitir el dato fuera del dispositivo**. Cuando el teléfono no tiene reconocimiento local, el sistema operativo **sí** envía el audio a los servidores de Google (o Apple, en iOS). Nosotros no lo retenemos ni un instante, que es exactamente el supuesto de **procesamiento efímero** de Play: se usa solo en memoria y solo para servir la petición en tiempo real. Ver §7.5 |
| **App activity → Installed apps** | No | **Sí — recopilado, opcional, *App functionality*** | `PendingCaptures.sourcePackage` guarda el `packageName` de la app de banco que emitió el aviso y **sincroniza a Supabase**. Eso es *qué apps de banco tiene instaladas el usuario* saliendo del dispositivo. Es una fila nueva y fácil de pasar por alto |
| **Personal info → Name** | Sí | **Sí — justificación ampliada** | Además del nombre del login social y `Debts.counterparty`, ahora `PendingCaptures.merchantRaw` puede contener el **nombre completo de una persona**: varios bancos escriben en claro quién te transfirió (*"Te llegó dinero de DANIELA TORO VALENCIA"*). Ese campo **sincroniza**. Es dato personal de un tercero que no es usuario de la app |
| **Financial info → Purchase history** | Sí | **Sí — sin cambio de respuesta, fuente nueva** | `PendingCaptures` sincroniza monto, moneda, tipo, fecha y comercio: es historial de compras, igual que una transacción escrita a mano |
| **Financial info → User payment info** | Sí | **Sí — sin cambio de respuesta, fuente nueva** | Se suma `Accounts.cardLast4` (últimos 4 de la **tarjeta**, distinta de `Accounts.last4` que identifica la cuenta) y `PendingCaptures.accountHint`. El número completo sigue sin salir del llavero |
| **App activity → Other actions** | Sí | **Sí — sin cambio de respuesta, fuente nueva** | `MerchantCategoryLearning` sincroniza pares comercio→categoría (`merchantKey` normalizado + `categoryId` + `hitCount`) y `ScheduledPayments.reminderLeadDays` |
| **Messages** (Emails, SMS/MMS, Other in-app messages) | No | **No — y la justificación importa** | Ver el bloque dedicado abajo |
| **Photos and videos** | No | **No** | No hay OCR, no hay cámara, no hay galería en este envío |
| **Device or other IDs** | Sí (Sentry) | **Sí — sin cambio** | Los recordatorios son **locales**: no hay token de push, ni Firebase, ni identificador nuevo |
| **Location, Health, Contacts, Calendar, Files and docs** | No | **No** | Sin cambio |
| Audiencia / datos de menores | 16-17 y 18+ | **Sin cambio** | Nada de este envío introduce categorías especiales. **La voz se usa como canal de entrada de texto, no como biometría**: no hay reconocimiento del hablante ni huella de voz. Si algún día se identificara al usuario por su voz, sería dato biométrico y cambiaría el marco entero (RGPD art. 9, LGPD art. 11, dato sensible en Ley 1581 y LFPDPPP) |

#### Por qué "Messages" se responde **No** (justificación para tenerla a mano)

Esta es la respuesta que un revisor puede cuestionar, así que conviene poder
sostenerla con evidencia y no con una frase:

1. **Play define recopilar como transmitir fuera del dispositivo.** El texto de
   la notificación **no se transmite** — y no se transmite porque **no se
   guarda**: no existe ninguna columna de contenido literal en el esquema
   (`PendingCaptures` en `lib/core/database/app_database.dart:987-1056`, y su
   espejo `supabase/migrations/20260909000000_fase2_capture_schema.sql:29-50`).
   Es un argumento demostrable, no una promesa.
2. **El catálogo de emisores es cerrado** y contiene solo apps de banco y
   billeteras. El usuario **no puede** añadir una app de mensajería, y todos los
   interruptores vienen apagados. No hay camino por el que un SMS o un correo
   entre al flujo.
3. **El filtro por `packageName` se aplica antes de leer el contenido**, así que
   una notificación de una app no habilitada nunca se toca.
4. **Lo que sí sale del dispositivo son los campos derivados**, y esos se
   declaran donde corresponde: *Financial info* (monto, comercio, fecha, pista de
   cuenta), *Personal info → Name* (nombre de la contraparte) y *App activity →
   Installed apps* (`sourcePackage`). Play y Apple coinciden en que un dato
   derivado de material local que sí se transmite **se declara aparte**, y eso es
   exactamente lo que se hace.

> **Nota histórica que este bloque cierra.** El 2026-08-18, al llenar la ficha
> del Nivel 0, se dejaron las tres casillas de "Mensajes" sin marcar y se anotó
> que "cuando la feature 19 se implemente, esa sección probablemente no puede
> quedar en blanco". Revisado contra el esquema real: **la respuesta correcta
> sigue siendo No**, y ahora hay evidencia para sostenerla. Lo que sí cambia son
> las tres filas nuevas de arriba.
>
> `[VERIFICAR: en Play Console, si el formulario incorporó desde entonces una
> pregunta específica sobre acceso a notificaciones. Se revisa en la consola al
> enviar]`

#### La divulgación destacada (prominent disclosure) no es opcional

Play exige, para datos personales y sensibles recogidos de forma que el usuario
no esperaría, una divulgación **in-app**, antes del permiso, con acción
afirmativa. Aplica a las tres capacidades. Los textos están en
[`textos-consentimiento-fase-2.md`](textos-consentimiento-fase-2.md) y el flujo
exacto en [`declaracion-permiso-notificaciones.md`](declaracion-permiso-notificaciones.md).

### 7.4 Apple — App Privacy

En iOS este envío lleva **voz y recordatorios locales**. La lectura de avisos
bancarios **no existe en iOS** y no se declara.

| Tipo | Hoy | Con este envío | Por qué |
|---|---|---|---|
| **Audio Data** | No recopilado | **No recopilado** — recomendación, con la justificación de abajo | Apple define *collect* como "transmitir datos fuera del dispositivo de forma que **tú o tus socios terceros** puedan acceder a ellos más tiempo del necesario para servir la petición en tiempo real". El audio del dictado **nunca llega a nosotros ni a un socio nuestro**: lo toma el reconocedor del propio sistema. Apple no es "nuestro socio tercero" en ese trayecto, es la plataforma, y es Apple quien muestra su propio aviso al usuario |
| **Other User Content** | Recopilado | **Recopilado — sin cambio de respuesta** | Los campos que salen de un dictado terminan en una `Transaction` normal |
| **Other Financial Info** | Recopilado | **Recopilado — sin cambio** | Igual |
| **Contact Info → Name** | Recopilado | **Recopilado — sin cambio en iOS** | El caso del nombre de la contraparte extraído de un aviso **no ocurre en iOS** |
| Tracking | No | **No** | Nada de esto introduce seguimiento ni identificador de publicidad |
| **Sensitive Info** | No | **No** | La voz no es biometría aquí: no hay reconocimiento del hablante |

> ⚠️ **Esta es la casilla de criterio, no de hecho.** "Audio Data = No recopilado"
> se apoya en la definición literal de Apple y en que el audio no pasa por
> nosotros. La lectura conservadora contraria —marcarlo **recopilado, no
> vinculado, App Functionality**— también es defendible y **no cuesta nada en la
> ficha**. Si hay dudas al enviar, marcarlo es la opción segura: sobredeclarar un
> tipo que el usuario ya ve en el aviso del sistema no genera un problema, y
> subdeclararlo sí.
> `[VERIFICAR: decisión final de esta casilla al enviar. No es una cuestión de
> código: el código ya está descrito con exactitud aquí y en la política v1.8 §18.1]`

Además, en iOS:

- **`PrivacyInfo.xcprivacy` hay que revisarlo**, no solo dejarlo como está. Sus
  `NSPrivacyCollectedDataTypes` tienen que seguir coincidiendo con esta hoja, y
  hay que comprobar si `flutter_local_notifications`, `timezone`,
  `permission_handler`, `speech_to_text` o `flutter_timezone` introducen
  **required reason APIs** (típicamente `UserDefaults`, categoría `CA92.1`) o
  traen su propio manifiesto de privacidad que haya que agregar.
  `[VERIFICAR: auditar los privacy manifests de los plugins nuevos al integrar, y
  actualizar ios/Runner/PrivacyInfo.xcprivacy]`
- La **clasificación por edad** no se mueve: dictar un gasto no cambia el
  contenido.
- Las **notas para App Review** (§2.4) deben añadir el párrafo de §7.7.

### 7.5 El audio: qué se decidió y qué queda por confirmar

La versión anterior de este documento tenía esto como bloqueante abierto. Ya no
lo está en cuanto al **comportamiento**, sí en cuanto a **cómo se le cuenta al
usuario en Android**.

**Comportamiento (confirmado):** el audio→texto usa el reconocedor de la
plataforma. Si el dispositivo soporta reconocimiento **on-device**, se usa ese y
el audio no sale. Si no lo soporta, **el audio se procesa en servidores de Apple
o de Google**. Ni el audio ni la transcripción se guardan en ninguna parte.

Lo que eso obliga, y ya está hecho:

- La política **nombra a Apple y a Google como responsables independientes** de
  ese audio (`politica-de-privacidad.md` v1.8 §7 y §18.1) y lo dice sin
  enterrarlo.
- La tabla de transferencias internacionales (§8 de la política) incluye esa
  fila.
- **Está prohibido escribir "todo el procesamiento es local"** en la ficha de
  tienda, en el texto del permiso o en cualquier material. *No guardar no es no
  transmitir.*

Lo que queda abierto:

- **En iOS lo advierte el sistema**, con su propio texto ("los datos de voz de
  esta app se enviarán a Apple"). **En Android no hay equivalente**, así que la
  advertencia tiene que darla la app.
  `[VERIFICAR: decisión de producto — si en Android se muestra un aviso una sola
  vez cuando el reconocimiento cae a la nube (opción C de 17-captura-voz.md
  HU-06) o si basta con la explicación previa al permiso de micrófono. Afecta
  solo al copy, no a las casillas de tienda]`
- **Si en el futuro se decide forzar `requiresOnDeviceRecognition` y desactivar
  la voz donde no haya reconocimiento local** (opción B), la casilla de Audio de
  Play pasa a **No** y este bloque se reescribe.

### 7.6 Bloqueantes de release que arrastra este envío

- ✅ **Borrado de cuenta.** `delete_account_data` ya cubre `pending_captures` y
  `merchant_category_learning`
  (`supabase/migrations/20260909000000_fase2_capture_schema.sql:153-154`), **en la
  misma migración que crea las tablas**. Es la primera vez que no se repite el
  bug B1. `[VERIFICAR: que la migración está aplicada en dev Y en prod, no solo
  commiteada en el repo — no se pudo comprobar desde este worktree]`
- ⛔ **Sentry.** `lib/core/crash/sentry_redaction.dart` hoy solo tiene reglas para
  mensajes de error de Postgres. No hay ninguna regla que cubra transcripciones,
  texto de notificaciones ni contenido de una captura. Un crash que filtre lo que
  la política promete no transmitir vuelve **falsa** esa promesa. **Bloqueante.**
- ⛔ **Borrado local ("borrar lo capturado").** La política v1.8 §18.4 lo describe
  y HU-08 lo exige. Hoy no hay código. **Bloqueante para publicar la política.**
- ⛔ **Pantalla de transparencia** (qué apps se escuchan, cuántas capturas, qué
  se guarda y qué no). Descrita en la política §18.4 y exigida por HU-08.
  **Bloqueante.**
- ⚠️ **Dónde vive la lista de emisores activos.** `AppSettings` no tiene ninguna
  columna para eso y no hay tabla nueva. `[VERIFICAR: si la preferencia queda en
  SharedPreferences (local por dispositivo) o en el lado nativo. Si terminara
  sincronizando, es una fila más de Data Safety]`
- ⚠️ **Import/Export.** Decidir si las capturas pendientes entran en la copia
  completa, y decirlo en la política en cualquiera de los dos casos.
  `[VERIFICAR: decisión de producto]`
- ⚠️ **La condición de "no publicar sola".** Ver §7.2 punto 6: el proyecto se
  autoimpuso que el release público con avisos bancarios lleve **voz y OCR**.
  Este envío lleva voz, no OCR. **Para TestFlight / Internal Testing eso es
  aceptable** —es un canal cerrado y sirve justamente para validar—, pero
  **reabrir la decisión antes de cualquier release público** no es opcional.

### 7.7 Párrafo a añadir a las notas para App Review

> **Captura por voz (opcional).** billetudo permite dictar un gasto en vez de
> escribirlo. La app usa el reconocedor de voz del sistema (`SFSpeechRecognizer`)
> y solicita reconocimiento on-device cuando el dispositivo lo soporta. **Ni el
> audio ni la transcripción se almacenan** en ningún momento: se usan para
> pre-llenar el formulario de transacción y se descartan al cerrarlo. La app no
> envía audio a servidores propios ni de terceros distintos del reconocedor del
> propio sistema.
>
> **La app funciona por completo sin conceder micrófono ni notificaciones.** El
> registro manual de movimientos, los presupuestos, las metas, las deudas, las
> gráficas y la exportación son la ruta principal y no dependen de ningún
> permiso. Si el revisor deniega el micrófono, la app abre el formulario normal
> para escribir.
>
> **Recordatorios locales.** Los avisos de pagos programados se programan en el
> dispositivo con `UNUserNotificationCenter`. No hay notificaciones push
> remotas, ni Firebase, ni tokens.
>
> **La lectura de notificaciones bancarias es exclusiva de Android** y no está
> presente en la versión de iOS.

---

## 8. Fase 4 — Asistente con IA — CHECKLIST FUTURO, NO VIGENTE

> ⛔ **NO COPIES NADA DE ESTA SECCIÓN A UN FORMULARIO DE TIENDA HOY.**
> Al 25 de agosto de 2026 **ninguna app publicada** envía nada a un modelo de
> lenguaje: el binario en tienda no tiene la feature. Ojo con el matiz, porque
> cambió durante el día: **el backend ya está en el repo**
> (`supabase/functions/ai-chat/` y la migración
> `20260825120000_ai_assistant_access_and_usage.sql`), mientras que el
> **cliente todavía no** (al 25 de agosto `lib/features/ai/` solo tiene la capa
> `domain/`: entidades, repositorios y casos de uso; ni `data/`, ni
> `presentation/`, ni una sola llamada a `ai_reports`). Es decir: §1 y §2 siguen
> siendo exactas para el binario, y dejan de serlo **el día que se compile una
> app con el asistente dentro**. Evidencia en `AUDITORIA.md` §10.3.

**Por qué esta es la sección más peligrosa del documento.** Los cambios de Fase 2
suman permisos, que son visibles y difíciles de olvidar. El asistente no suma
**ni un permiso**: no pide micrófono, ni cámara, ni notificaciones. Un binario
con IA se ve idéntico a uno sin IA desde el manifiesto y desde el `Info.plist`.
Lo único que cambia es a dónde viajan los datos — y eso solo lo atrapa este
checklist.

### 8.1 Qué sale del dispositivo cuando la feature está activa

Resumen operativo (el detalle está en el requisito y en la política v1.5 §17):

| Sale | No sale nunca |
|---|---|
| El texto que el usuario escribe en el chat | `Accounts.institution` (banco) y `Accounts.last4` |
| Resumen agregado: saldos por cuenta (**nombre**, tipo, moneda, saldo), gasto/ingreso del mes, top de categorías (**con nombre**), flujo de 6 meses, presupuestos (**con nombre**), metas (**con nombre**), totales de deuda, **cada deuda abierta con su nombre**, pagos de los próximos 30 días, catálogo de categorías | El número completo de cuenta/tarjeta (vive en Keychain/Keystore y no sale para nada) |
| **Cinco campos `name` de texto libre del usuario**: `Accounts.name`, `Categories.name`, `Budgets.name`, `Goals.name`, `Debts.name`. Evidencia: `financial_snapshot.dart` (`SnapshotAccount.name`, `SnapshotCategoryLine.name`, `SnapshotBudget.name`, `SnapshotGoal.name`, `SnapshotDebt.name`) | Correo y nombre del usuario; archivos, fotos, audio, contactos |
| Bajo demanda del modelo: hasta **50** movimientos con id, fecha, monto, moneda, tipo, nombre de categoría y nombre de cuenta (máx. 3 rondas por turno) | El historial fuera de la conversación en curso: vive en el teléfono y no se sincroniza |
| Idioma, zona horaria, versión de la app, id de conversación generado en el dispositivo | El resto de la conversación al reportar un mensaje: no se adjunta ni se ofrece adjuntarla |
| **La conversación en curso, reenviada completa en cada turno** (tope de 40 mensajes), porque el servidor no guarda estado | |
| **Solo si el usuario reporta un mensaje:** ese mensaje del asistente, el motivo (lista cerrada), un comentario opcional, el id de conversación, la versión de la app y el `user_id`. Va a **nuestro servidor**, no a Google | |
| **Condicionado a un interruptor apagado por defecto:** el texto libre de `Transactions.note`, `GoalContributions.note`, `DebtEntries.note` y `ScheduledPayments.note` — ver §8.7 | |

> **Corrección respecto de la v1.5 de este documento.** La versión anterior
> ponía en la columna "no sale nunca" tanto las notas como `Debts.counterparty`.
> Lo primero pasó a ser condicional (§8.7); lo segundo era erróneo desde el
> principio: la tabla `Debts` no tiene columna `counterparty` —el nombre de la
> contraparte se escribe en `Debts.name` (`app_database.dart`)— y ese campo
> **viaja hoy** en `SnapshotDebt.name`. Una declaración que diga lo contrario es
> falsa y contrastable.

Destino: Edge Function propia `ai-chat` (Supabase, **sin estado**, no persiste
nada) → **Google, API de Gemini, `gemini-2.5-flash`**.

En el servidor quedan **cuatro** tablas: tres de control y una de moderación.

Las tres de control no llevan contenido de conversación: `ai_access`
(habilitación por usuario), `ai_feature_flags` (interruptor global, sin datos de
nadie) y `ai_usage_log` (metadatos por turno: fecha, día de uso, id de
conversación, proveedor, modelo, resultado, código de error, tokens, rondas de
herramienta, nº de propuestas, latencia y versión de la app). El historial de
conversación vive en una tabla local `Table.localOnly` que **no sincroniza**.

La cuarta, `ai_reports` (`supabase/migrations/20260825140000_ai_reports.sql`,
aplicada **en dev, no en prod**), **sí guarda contenido**, y es la única:
`reported_text` es el mensaje del asistente que el usuario eligió reportar.
Existe porque la *AI-Generated Content policy* de Play exige reportar *sin salir
de la app*, lo que descarta abrir el cliente de correo y obliga a que el reporte
llegue a un servidor nuestro. Propiedades que hay que sostener al declarar:

- **Nada llega automáticamente.** Solo se escribe cuando la persona toca
  "reportar" sobre un mensaje concreto y confirma.
- **Solo el fragmento reportado.** Ni la conversación, ni los mensajes previos,
  ni el snapshot financiero.
- **`reason` es una lista cerrada** (`offensive`, `wrong`, `harmful`,
  `privacy`, `other`), a propósito: un campo libre invitaría a pegar datos
  personales. El campo libre que sí existe (`comment`) es opcional.
- **RLS de solo `insert` + `select` de las propias filas.** No hay policy de
  `update` ni de `delete`: la persona no puede editar ni borrar su reporte, y
  `status` (`pending`/`reviewed`/`dismissed`) lo mueve un humano a mano.
- **Entra en `delete_account_data`** en la misma migración que la crea, con FK
  `on delete cascade` a `auth.users`.
- La UI debe mostrar el aviso **antes de enviar**. Sin ese aviso, la política
  §17.5 queda falsa.

Tres matices que hay que sostener en cualquier redacción, porque son lo que
diferencia una declaración exacta de una aspiracional:

1. **No guardar no es no transmitir.** El transcript no se almacena en ningún
   servidor, pero pasa por el proveedor en cada turno. Es el mismo principio que
   ya obligó a marcar los *crash logs* como compartidos con Sentry.
2. **"El servidor no guarda contenido" ya no se puede decir sin el matiz.**
   `ai_reports` es una excepción real, aunque la dispare el usuario. La frase
   correcta es: *no se guarda nada de la conversación salvo el mensaje que la
   propia persona envía al reportarlo.* Cualquier redacción que diga "nunca" a
   secas —incluidas las notas para App Review— es falsa desde esta migración.
3. **La exclusión de notas, banco y `last4` la garantiza solo el cliente.** La
   Edge Function acepta el snapshot como un objeto JSON cualquiera y no valida
   su forma. Si el test de lista blanca del cliente no existe o se rompe, la
   respuesta "*User payment info* no compartido" de §8.3 deja de ser
   defendible — y nadie se enteraría desde el servidor.

### 8.2 Google Play — preguntas generales que cambian

| Pregunta | Respuesta hoy | Con el asistente | Por qué |
|---|---|---|---|
| ¿Compartes datos de usuario con terceros? | No (salvo Sentry) | **Sí** | Google, como proveedor del modelo, recibe datos financieros y contenido del usuario. Play cuenta como *shared* cualquier transferencia a un tercero, incluido un encargado |
| ¿Tu app usa IA generativa? (sección *App content*) | No aplica | **Sí** | La *AI-Generated Content policy* cubre expresamente las apps de chatbot texto-a-texto. `[VERIFICAR: nombre exacto y ubicación del campo en Play Console al momento del envío — la ayuda pública no documenta un formulario específico]` |
| ¿Existe mecanismo in-app para reportar contenido ofensivo generado por IA? | No aplica | **Sí, obligatorio** — backend listo, cliente pendiente | *"Apps that generate content using AI must contain in-app user reporting or flagging features that allow users to report or flag offensive content to developers without needing to exit the app."* Es HU-09 del requisito. **Sin esto la app es retirable**, no solo rechazable. La tabla `ai_reports` y sus policies ya existen (dev); falta la UI que escriba en ella, así que **el requisito todavía no está cumplido en el binario** |
| ¿Requiere inicio de sesión? | No | **No** (la app sigue siendo usable sin cuenta; solo el asistente exige sesión) | Importante para 5.1.1(iii) de Apple: el login sigue siendo opcional para todo lo demás |
| ¿Contiene anuncios / compras? | No | **No en Fase A** | Fase A es beta gratuita. Cuando pase a Premium se dispara además el punto 2 de §6 |

### 8.3 Google Play — Data Safety, tipos de dato que cambian

Ningún tipo **nuevo** aparece en Play: lo que cambia es sobre todo la columna
"¿Compartido?", que pasa de No a **Sí (Google)** en tres bloques.

| Tipo de dato | Hoy | Con el asistente | Por qué |
|---|---|---|---|
| **Financial info → Other financial info** | Recopilado, **no** compartido | Recopilado y **COMPARTIDO (Google)** | Saldos, presupuestos, metas y totales de deuda viajan en el resumen de cada turno |
| **Financial info → Purchase history** | Recopilado, no compartido | Recopilado y **COMPARTIDO (Google)** | El detalle bajo demanda envía hasta 50 movimientos con monto, fecha, categoría y cuenta |
| **Financial info → User payment info** | Recopilado, no compartido | Recopilado, **NO compartido** | `institution` y `last4` están excluidos del envío por construcción (HU-08). Es una de las pocas respuestas que **no** cambia, y hay que sostenerla con el test de lista blanca |
| **App activity → Other user-generated content** | Recopilado, no compartido | Recopilado y **COMPARTIDO (Google)** | Tres contenidos distintos, y conviene declararlos sabiendo que son tres: (a) el texto que el usuario escribe en el chat; (b) **los cinco campos `name` de texto libre** —cuenta, categoría, presupuesto, meta y **deuda**— que van en el resumen de cada turno, sin condición ninguna; (c) **el texto de las notas, solo si el usuario enciende el interruptor de §8.7**. (a) y (b) hacen que esta fila sea *compartida* con independencia del interruptor |
| **Personal info → Name / Email / User IDs** | Recopilado, no compartido | **Sin cambio** | Google **no** recibe el nombre ni el correo *del titular de la cuenta*. El id de conversación se genera en el dispositivo y no deriva del id de usuario. Ojo con el matiz: `Debts.name` puede contener el nombre de **otra** persona y sí viaja, pero Play clasifica ese contenido como *user-generated content* del titular, no como su *Name*. `[VERIFICAR: confirmar ese mapeo en la ayuda vigente de Play al momento del envío]` |
| **App activity → Other actions** | Recopilado, no compartido | Recopilado, no compartido | `ai_usage_log` es nuestro servidor, no un tercero. Se suma como fuente, sin cambiar la respuesta |
| **Messages** | No | **No** | El chat con el asistente no es mensajería entre personas; Play clasifica ese contenido como *user-generated content*. `[VERIFICAR: confirmar el mapeo en la ayuda vigente de Play al momento del envío]` |
| Audio, Photos and videos, Files and docs, Location, Contacts | No | **No** | El asistente es solo texto. No hay adjuntos, ni permisos nuevos |

Finalidad a declarar para lo compartido: **App functionality**. No es
*Personalization* ni *Advertising*: el dato se envía para producir la respuesta
del turno y no alimenta ningún perfil.

**La búsqueda local por nota (`find_scheduled_payments`) NO cambia ninguna fila
de esta tabla, y es importante no confundirla con el interruptor de §8.7.** El
modelo manda un término de búsqueda —palabras que el usuario ya escribió en su
mensaje, es decir, contenido que ya viajaba como parte de la fila (a) de *Other
user-generated content*—, **el dispositivo** compara ese término contra las
notas locales y devuelve **solo campos estructurados**: id, monto, moneda,
fecha, frecuencia, categoría y cuenta. Ni el texto de la nota ni un fragmento
suyo vuelven al modelo. Evidencia:
`lib/features/ai/domain/usecases/resolve_ai_tool_call.dart`
(`_findScheduledPayments`, `_matchesQuery`, `_scheduledPaymentItem`) y
`_transactionItem`, que no emite `note`. En términos de Play, la nota se procesa
**on-device** y no se transmite: no hay tipo de dato nuevo ni cambio de columna
"¿Compartido?".

**El mecanismo de reporte (`ai_reports`) no agrega un tipo de dato nuevo**, y
conviene dejar escrito por qué, porque es la clase de cosa que se declara mal:

- El mensaje reportado y el comentario del usuario caen en **App activity →
  Other user-generated content**, que ya está declarado como *recopilado*.
- **No cambia la columna "¿Compartido?"** de ese tipo: el reporte se queda en
  nuestro Supabase y **no viaja a Google** ni a ningún tercero. Lo que lo vuelve
  compartido es el chat (fila de arriba), no el reporte.
- **Recopilación opcional (*optional*)**, no obligatoria: solo ocurre si la
  persona toca "reportar". Play tiene esa casilla y aquí la respuesta es sí.
- **Finalidad: App functionality.** Play no ofrece una finalidad de "moderación"
  y esto no es analítica, ni personalización, ni comunicaciones. `[VERIFICAR: si
  al momento del envío Play espera además marcar "Fraud prevention, security,
  and compliance" para datos de moderación de contenido]`
- **Personal info → User IDs** sigue *recopilado, no compartido*: `ai_reports`
  guarda `user_id`, que ya estaba declarado por el resto de la base.

### 8.4 Apple — App Privacy y, sobre todo, la Guideline 5.1.2(i)

**Lo que puede tumbar el envío no es la etiqueta, es el consentimiento.** Desde
el 13 de noviembre de 2025, la Guideline 5.1.2(i) dice literal: *"You must
clearly disclose where personal data will be shared with third parties,
including with third-party AI, and obtain explicit permission before doing
so."* Los revisores lo aplican de forma estricta y esperan **ver el nombre del
proveedor** en el texto de consentimiento.

Requisitos concretos, todos verificables en pantalla:

1. Una pantalla de consentimiento **antes del primer envío**, que nombre a
   **Google** y su API de Gemini, diga qué se envía y dónde se procesa (HU-02).
2. Acción afirmativa: sin casilla premarcada, sin consentimiento implícito por
   uso o por scroll.
3. Posibilidad de **retirarlo** desde Ajustes.
4. La app debe seguir siendo utilizable si el usuario dice que no.

| Tipo (App Privacy) | Hoy | Con el asistente |
|---|---|---|
| **Financial Info → Other Financial Info** | Recopilado, *App Functionality* | **Sin cambio de casilla**, pero pasa a estar cubierto por el consentimiento de 5.1.2(i) |
| **Financial Info → Payment Info** | Recopilado | Sin cambio: no se envía al modelo |
| **User Content → Other User Content** | Recopilado | Sin cambio de casilla, pero se suman tres contenidos: el texto del chat; los **cinco nombres de texto libre** del resumen (cuenta, categoría, presupuesto, meta, deuda); y —solo si la persona reporta un mensaje— el texto reportado y su comentario, que quedan en nuestro servidor. **Con el interruptor de §8.7 encendido se suma también el texto de las notas**, que ya está cubierto por esta misma casilla |
| **Identifiers → User ID** | Recopilado | Sin cambio: no viaja al proveedor del modelo |
| **Tracking** | No | **No** — nada de esto es seguimiento entre apps ni alimenta publicidad |

**Por qué el interruptor de notas no permite quitar ninguna casilla.** Apple
solo exime de declarar un dato bajo su *Optional Disclosure*, y exige que se
cumplan **todos** los criterios a la vez: que no sea parte de la funcionalidad
principal, que sea infrecuente, y que la persona dé una **elección afirmativa
cada vez** que se envía. Un interruptor persistente en Ajustes no cumple el
último criterio: se activa una vez y aplica a todos los turnos siguientes. Por
tanto las notas se declaran bajo *User Content → Other User Content*, sin
excepción posible. `[VERIFICAR: releer la página vigente de App Privacy Details
de Apple en el momento del envío; los criterios de Optional Disclosure han
cambiado de redacción antes]`

> Ojo con una asimetría fácil de pasar por alto: el formulario de Apple **no
> tiene una casilla de "compartido con terceros"** equivalente a la de Play, así
> que las etiquetas casi no cambian. Eso puede dar la falsa sensación de que en
> iOS no hay nada que hacer. Al contrario: en iOS el trabajo está en el
> **consentimiento in-app** y en las notas de revisión, no en las etiquetas.

`PrivacyInfo.xcprivacy` no necesita tipos nuevos por esto (los tipos ya están
declarados), pero hay que **releerlo contra §2.2** en el mismo envío.

### 8.5 Notas para App Review — párrafo a añadir

> billetudo incluye un **asistente financiero opcional** basado en un modelo de
> lenguaje. Requiere iniciar sesión; el resto de la app sigue funcionando sin
> cuenta.
>
> Antes del primer mensaje, la app muestra una pantalla de consentimiento que
> indica que el texto escrito y un **resumen agregado** de las finanzas del
> usuario se envían a **Google (API de Gemini)** para generar la respuesta, y
> que el procesamiento ocurre fuera del país del usuario. El usuario debe
> aceptar explícitamente y puede retirar ese permiso desde Ajustes
> (Guideline 5.1.2(i)).
>
> Ese resumen **incluye los nombres que el propio usuario les puso** a sus
> cuentas, categorías, presupuestos, metas y deudas: es lo que permite que la
> respuesta se refiera a ellos por su nombre. Como el nombre de una deuda puede
> ser el de una persona, lo decimos explícitamente en la política (§12 y §17.3).
>
> **No se envían** el nombre de la entidad bancaria del usuario, los últimos 4
> dígitos de sus tarjetas, el número completo de sus cuentas, ni su nombre o
> correo. No se envían archivos, fotos ni audio.
>
> **Las notas de texto libre no se envían por defecto.** Ajustes incluye un
> interruptor independiente, **apagado de fábrica**, que el usuario puede
> encender para que el asistente pueda leerlas y responder con más precisión, y
> apagar en cualquier momento. Con el interruptor apagado, el texto de las notas
> no sale del dispositivo hacia el proveedor del modelo.
>
> Existe además una búsqueda que **no** envía notas en ningún caso: cuando el
> usuario nombra un pago programado por una palabra que solo está en su nota, el
> modelo devuelve un término de búsqueda, **el propio dispositivo** lo compara
> contra sus notas locales y solo regresan campos estructurados (identificador,
> monto, fecha, frecuencia, categoría y cuenta). El texto de la nota no vuelve al
> modelo ni entero ni en fragmentos.
>
> El historial de la conversación se guarda **solo en el dispositivo** y no se
> sincroniza. Nuestro servidor no almacena el contenido de las conversaciones,
> **con una única excepción que inicia el propio usuario**: si reporta un
> mensaje del asistente, ese mensaje —y solo ese, no la conversación— se guarda
> en nuestro servidor junto con el motivo y un comentario opcional, para poder
> revisarlo. La app lo advierte en pantalla antes de enviar el reporte.
>
> Ese mecanismo de reporte es accesible **desde la propia conversación, sin
> salir de la app**, y cubre el requisito de reporte de contenido generado con
> IA. Los reportes se eliminan cuando el usuario borra su cuenta.
>
> El asistente **propone** acciones (crear un presupuesto, una meta, una
> categoría, registrar un movimiento) pero **nunca las ejecuta**: la app muestra
> una tarjeta y el usuario debe confirmar con un toque. La pantalla incluye un
> aviso permanente de "Beta" y de que no se trata de asesoría financiera.

### 8.6 Precondiciones que hay que cumplir antes de enviar

Sin las tres primeras, esta hoja no se puede usar:

1. **Key de tier de pago de la API de Gemini.** Con la capa gratuita, Google
   puede usar el contenido enviado para desarrollar y mejorar sus productos, con
   posible revisión humana. En ese caso la política v1.5 §17 (que promete lo
   contrario) sería **falsa**, y la feature no puede abrirse a terceros ni
   declararse.
2. **Política v1.5 publicada antes** de que el binario con el asistente esté
   disponible, no el mismo día.
3. **Consentimiento in-app implementado** nombrando a Google (Apple 5.1.2(i)).
4. ✅ **Resuelto (2 de septiembre de 2026).** El menú de long-press sobre un
   mensaje del asistente ofrece "Reportar", que abre la hoja de motivo (5
   razones cerradas + comentario opcional) con el aviso de privacidad fijo
   antes de poder confirmar. `20260825140000_ai_reports.sql` está aplicada
   **en dev y en prod** (verificado). Probado de punta a punta en dispositivo
   real contra la base de dev: el reporte quedó guardado en `ai_reports` con
   `reason`, `reported_text`, `comment`, `conversation_id`, `client_version` y
   `status: pending` correctos.
5. **`delete_account_data` cubre las tablas del asistente.** ✅ Ya resuelto en
   el código: la migración `20260825120000_ai_assistant_access_and_usage.sql`
   las agrega a la función en la misma migración que las crea, y
   `20260825140000_ai_reports.sql` hace lo mismo con `ai_reports`. En **dev**,
   `select * from delete_account_data_coverage_gaps();` devuelve **cero filas**.
   Falta el paso operativo en **prod**: aplicar ambas migraciones y repetir la
   consulta ahí.
6. **Redacción de Sentry** cubriendo texto del chat, resumen y propuestas: un
   crash que filtre lo que la política promete no transmitir convierte esa
   promesa en falsa.
7. **Test de lista blanca del resumen** en verde: es lo único que sostiene la
   respuesta "User payment info NO compartido" de §8.3. Con el interruptor de
   §8.7 esa lista blanca deja de ser una constante y pasa a depender de un
   ajuste, así que el test tiene que cubrir **los dos estados**: apagado (ni una
   nota en el payload) y encendido (notas sí, pero `institution` y `last4`
   siguen fuera). Sin el caso "apagado" en verde, la §17.7 de la política y la
   fila "opcional" de §8.7 dejan de ser defendibles.
8. ✅ **Resuelto (1 de septiembre de 2026). Interruptor de notas cableado de
   extremo a extremo y apagado por defecto** (esquema → dominio →
   snapshot/herramientas → UI de Ajustes). Verificado en
   `AppSettings.aiNotesAccessEnabled` (dominio), `prompt.ts` (las dos
   variantes de sección según el flag), y `AiSettingsSection`/
   `AiNotesAccessField`/`AiNotesAccessSheet` (UI). §8.7 pasa de checklist a
   declaración vigente.
8-bis. ✅ **Resuelto en la parte de comparación.** `aiConsentVersion` sí se
   compara de verdad (`AppSettings.hasAcceptedAiConsent`, que exige
   `aiConsentVersion >= currentAiConsentVersion`) y la constante ya subió a
   `2` (`lib/features/ai/domain/entities/ai_consent.dart`) precisamente para
   forzar a que quien aceptó la versión 1 vuelva a ver el consentimiento.
   ⚠️ Lo que sigue abierto es el punto 9, sobre el **contenido** del texto que
   se muestra, no sobre si la versión se compara.
9. ⚠️ **Sigue abierto.** El texto de `aiConsentBody` sigue diciendo "sin notas
   ni datos de identificación bancaria" y nunca se amplió para mencionar que
   existe un interruptor separado para las notas. No es falso (con el
   interruptor apagado por defecto, la afirmación se sostiene), pero es una
   oportunidad de consentimiento más informado que no se tomó.
   `[VERIFICAR: decisión de quien mantiene el código sobre si vale la pena
   ampliar el texto y si eso amerita subir currentAiConsentVersion otra vez]`.
10. ✅ **Resuelto (1 de septiembre de 2026). Sección de IA en Ajustes
    existente.** `lib/features/settings/presentation/pages/settings_page.dart`
    ya incluye `const AiSettingsSection()`, con el interruptor de notas y el
    enlace para retirar el consentimiento general del asistente.
11. **Clasificación por edad:** un chatbot de IA puede mover el cuestionario de
    ambas tiendas. `[VERIFICAR: si declarar IA generativa altera la clasificación 16+ de Apple o el cuestionario IARC de Play]`
12. **EEE:** el veto de §0.1 sigue vigente y ahora suma un tercero más. Además,
    la capa gratuita de la API de Gemini no es utilizable para usuarios del EEE
    en ningún caso.

### 8.7 El interruptor opt-in de notas — cómo se declara

> ✅ **Resuelto el 1 de septiembre de 2026: el interruptor está cableado de
> extremo a extremo.** `AppSettings.aiNotesAccessEnabled` y
> `AppSettings.aiConsentVersion` ya no son solo columnas de esquema: la
> entidad de dominio las expone (`lib/features/settings/domain/entities/app_settings.dart`),
> el snapshot y el prompt del backend cambian de sección según el valor
> (`supabase/functions/_shared/ai/prompt.ts`, `NOTES_WITHHELD_SECTION` /
> `NOTES_VISIBLE_SECTION`), y hay UI real en Ajustes: `AiSettingsSection`
> muestra `AiNotesAccessField` solo mientras el consentimiento general está
> activo, encenderlo pide confirmación explícita en `AiNotesAccessSheet`
> (nombrando a Google Gemini), y apagarlo aplica de inmediato sin preguntar.
> Retirar el consentimiento general (`clearAiConsent`) apaga este interruptor
> también, en la misma escritura — no queda un permiso huérfano. Esta
> subsección deja de ser un checklist a futuro y pasa a ser la declaración
> vigente para el binario que incluya el asistente.

**Qué es.** Un interruptor en Ajustes, **apagado por defecto**, que autoriza al
asistente a leer el texto libre de `Transactions.note`, `GoalContributions.note`,
`DebtEntries.note` y `ScheduledPayments.note`. Encendido, ese texto viaja a
Google como parte del resumen y de los resultados de herramienta.

#### Google Play — Data Safety

| Campo | Respuesta | Por qué |
|---|---|---|
| Tipo de dato | **App activity → Other user-generated content** | Ya está declarado como recopilado y compartido por el chat; las notas no abren un tipo nuevo |
| ¿Recopilado? | **Sí** | Se transmite fuera del dispositivo cuando el interruptor está encendido |
| ¿Compartido con terceros? | **Sí (Google)** | Play cuenta como *shared* cualquier transferencia a un tercero, incluido un encargado |
| ¿Es obligatoria esta recopilación? | **No — es opcional** (*"Users can choose whether this data is collected"*) | Es exactamente el caso que esa casilla describe: apagado por defecto, la app funciona igual sin encenderlo, y se puede apagar. Marcarla como obligatoria sería declarar de más |
| Finalidad | **App functionality** | Sirve para producir la respuesta del turno. No es *Personalization* (no alimenta ningún perfil) ni *Analytics* |
| ¿Se procesa efímeramente? | **No marcar "processed ephemerally"** para esta fila | La respuesta la genera un tercero y Google (Gemini) registra las solicitudes por un tiempo limitado por abuso y obligaciones legales. "Efímero" solo aplica cuando el dato no se retiene en absoluto |

#### Apple — App Privacy

| Campo | Respuesta |
|---|---|
| Tipo | **User Content → Other User Content** (ya declarado) |
| ¿Casilla nueva? | **No.** El formulario de Apple no tiene equivalente a la casilla "opcional" de Play |
| ¿Se puede omitir por ser opcional? | **No** — ver el análisis de *Optional Disclosure* en §8.4: falla el criterio de "elección afirmativa cada vez" |
| Linked to user / Tracking | **Linked to the user** (va con la sesión), **Tracking: No** |

#### Consentimiento (Apple 5.1.2(i) y bases legales de la política)

Estas cuatro propiedades tienen que ser ciertas en pantalla, no solo en el
documento:

1. El interruptor es **independiente** del consentimiento general del asistente.
   Aceptar el asistente **no** puede encender las notas. Un consentimiento
   agrupado ("acepto todo") no es válido bajo el RGPD para dos finalidades
   distinguibles, ni bajo el criterio de acción afirmativa de Apple.
2. **Apagado por defecto**, sin casilla premarcada.
3. **Reversible** desde el mismo lugar, sin fricción añadida.
4. El texto junto al interruptor tiene que decir **a dónde** van las notas
   (Google) y **qué son** (texto libre que puede contener datos de terceros).

#### Lo que NO se declara por esto

- La **búsqueda local por nota** no aporta nada a esta hoja: la nota se compara
  en el dispositivo y no se transmite (§8.3). Si alguien la declara como
  recopilación de contenido, está declarando de más.
- El **estado del interruptor** en sí es una preferencia de la app, ya cubierta
  por *App activity → Other actions* / *Product Interaction*.

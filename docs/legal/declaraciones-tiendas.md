# Declaraciones de datos para Play Store y App Store — billetudo

**Versión 1.7** · **Última actualización: 1 de septiembre de 2026**
**Versión de la app a la que corresponden las respuestas vigentes: `0.0.5+8`**
`[VERIFICAR: el working tree ya está en 0.0.5+9 (pubspec.yaml:4). Confirmar contra qué build se envía y re-verificar §1.1 y §1.3 sobre ese binario]`

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
> respuestas VIGENTES**: describen el binario de hoy y son las que se copian a
> un formulario. La **§7 es un checklist a futuro** para Fase 2 (captura por
> voz, OCR, notificaciones bancarias, widget) y la **§8 es el checklist a futuro
> del asistente con IA** (Fase 4): **nada de lo que dicen §7 y §8 se declara
> todavía**, porque nada de eso existe en el código. Confundir las dos cosas y
> declarar de más es tan sancionable como declarar de menos.

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
| ¿La app usa APIs de accesibilidad, SMS, ubicación en segundo plano, o acceso a todos los archivos? | **No** a todas | El manifiesto fusionado solo trae `INTERNET`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `REORDER_TASKS` |

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
- **Sin push:** sin `firebase_messaging` ni `flutter_local_notifications`.
- **Sin compras:** `purchases_flutter` comentado; sin permiso `BILLING`.
- **Sin voz / OCR / lectura de notificaciones:** `lib/features/capture/`
  contiene solo un `.gitkeep` y `lib/features/improvement/` está vacía;
  `speech_to_text` (`pubspec.yaml:86`) y `google_mlkit_text_recognition`
  (`pubspec.yaml:87`) siguen **comentados**; el `AndroidManifest.xml` no declara
  ningún `uses-permission` ni ningún `<service>` de `NotificationListenerService`.
  Re-verificado el 2026-08-17 (`AUDITORIA.md` §10.2). **Que los requerimientos de
  Fase 2 existan escritos no cambia esta respuesta:** se declara el binario, no
  el plan. Ver §7.
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
3. Añadir `speech_to_text`, el OCR, la lectura de notificaciones bancarias o el
   widget (**Fase 2**) → permisos de micrófono, cámara y acceso a notificaciones,
   más `NS*UsageDescription` y sus tipos de dato. **§7 tiene el checklist
   completo**; no se improvisa al momento del envío.
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

## 7. Fase 2 (captura sin fricción) — CHECKLIST FUTURO, NO VIGENTE

> ⛔ **NO COPIES NADA DE ESTA SECCIÓN A UN FORMULARIO DE TIENDA HOY.**
> Al 17 de agosto de 2026 la app **no** captura por voz, **no** hace OCR, **no**
> lee notificaciones y **no** tiene widget. Todo eso está **especificado** en
> `docs/requirements/fase-2/` y **no implementado** (evidencia archivo por
> archivo en `AUDITORIA.md` §10.2). Las respuestas vigentes son las de §1 y §2 y
> siguen siendo correctas. Esta sección existe para que, cuando el código
> exista, nadie publique con la hoja vieja.

El desarrollo completo —incluidos los textos de permiso y los párrafos que hay
que escribir en la política— está en
[`checklist-fase-2.md`](checklist-fase-2.md). Aquí queda el resumen campo por
campo.

### 7.1 Permisos y declaraciones nativas que aparecen por primera vez

Hoy la app tiene **cero** permisos propios. Fase 2 rompe eso, y la ficha de
permisos visible en la tienda cambia.

| Capacidad | Android | iOS |
|---|---|---|
| Voz | `RECORD_AUDIO` en `AndroidManifest.xml` (+ posible `<queries>` para resolver el servicio de reconocimiento en Android 11+) | `NSMicrophoneUsageDescription` **y** `NSSpeechRecognitionUsageDescription` |
| OCR / foto del recibo | `CAMERA` | `NSCameraUsageDescription` |
| Elegir foto de la galería | **Preferir el Photo Picker del sistema**, que no exige permiso. `READ_MEDIA_IMAGES` solo si el flujo elegido lo requiere de verdad | `NSPhotoLibraryUsageDescription` (solo si se lee la galería) |
| Notificaciones bancarias | `<service>` con `BIND_NOTIFICATION_LISTENER_SERVICE` + intent-filter `android.service.notification.NotificationListenerService` | **No aplica**: la feature es solo Android |
| Widget | Provider de app widget | Extensión WidgetKit (sin App Group: el widget es atajo puro y no lee datos) |

Reglas que no son opcionales:

- Los textos de `*UsageDescription` van **localizados** (`InfoPlist.strings`, es
  + en) y describen el uso real. Apple rechaza descripciones genéricas del tipo
  "esta app necesita la cámara".
- Cada permiso se pide **en contexto**, con explicación previa, y su negación
  degrada la feature sin bloquear nada de Nivel 0. Eso no es solo UX: es la
  *prominent disclosure* que Play exige para permisos sensibles.
- Añadir `READ_MEDIA_IMAGES` activa además el formulario de **permisos de fotos
  y video** de Play Console. Evitarlo con el Photo Picker ahorra ese trámite.

### 7.2 El acceso a notificaciones es la declaración de mayor riesgo

`BIND_NOTIFICATION_LISTENER_SERVICE` da acceso al contenido de **todas** las
notificaciones del teléfono. Es el permiso más invasivo del catálogo y el único
de Fase 2 que puede, por sí solo, tumbar la publicación entera.

Qué hay que tener listo **antes** de subir el build:

1. **Justificación de uso escrita**, en los términos de la política de datos del
   usuario de Play: el permiso es necesario para una funcionalidad **central y
   promocionada** en la ficha (registrar automáticamente los movimientos que el
   banco notifica), el procesamiento es **local**, el consentimiento es
   **explícito y por app emisora**, y es **revocable** desde la app y desde el
   sistema.
2. **Video de demostración** del flujo completo (activación, selección de
   emisores, bandeja de pendientes, confirmación, revocación). Play suele
   pedirlo para permisos sensibles.
3. **Data Safety actualizado** en el mismo envío. Ver §7.3.
4. **La ficha de tienda debe describir la funcionalidad**: un permiso sensible
   cuya finalidad no aparece en la ficha es exactamente lo que Play rechaza.
5. **Alternativas vivas en el mismo release.** `docs/Plan_Monetizacion_y_Tecnico.md`
   §9 exige **no depender solo de esta vía**, y `docs/requirements/README.md`
   lo convierte en condición de publicación no negociable: el primer release
   público con notificaciones **debe** incluir voz y OCR ya funcionando. Si
   Google rechaza la lectura de notificaciones, la app se queda con una vía de
   captura menos, no sin ninguna. **Esto se verifica en el checklist de release,
   no se recuerda de memoria.**

`[VERIFICAR: si Play exige un formulario de declaración específico y/o video para BIND_NOTIFICATION_LISTENER_SERVICE al momento del envío]` —
la página vigente de Play "Permissions and APIs that Access Sensitive
Information" consultada el 2026-08-17 **no** lista el acceso a notificaciones
entre los permisos con formulario propio (sí SMS/Call Log, ubicación,
accesibilidad, VPN, alarmas exactas, full-screen intent). No se afirma que no
exista: no se encontró documentado. Sí está documentado que Play Protect trata
el acceso a notificaciones como señal de **alto riesgo** cuando se combina con
SMS o accesibilidad — billetudo no pide ninguno de esos dos, y conviene que siga
siendo así.

### 7.3 Cómo cambia el Data Safety de Google Play

| Tipo de dato | Respuesta hoy | Respuesta con Fase 2 | Por qué |
|---|---|---|---|
| **Audio files / Voice or sound recordings** | No | **No** *(condicionado)* | Retención cero: el audio no se guarda ni se envía a servidores nuestros. Play no considera recolección lo que se procesa en el dispositivo y no sale de él. **⚠️ Esta respuesta depende del punto abierto de §7.5:** si el reconocimiento cae al servicio en la nube del sistema operativo, el audio **sí sale** del dispositivo hacia un tercero y la respuesta cambia |
| **Photos and videos** | No | **No** | La imagen del recibo se guarda solo en el directorio privado de la app y **no** se sincroniza (decisión 2026-08-17). No hay transferencia fuera del dispositivo |
| **Messages / SMS** | No | **No** | La app no pide SMS. Las notificaciones bancarias no son SMS y su **texto no se persiste ni se transmite** (retención cero). Lo que sale del dispositivo son los **campos extraídos**, que se declaran como financieros |
| **Financial info → Purchase history / Other financial info** | Sí | **Sí, sin cambio de respuesta pero con fuente nueva** | Las capturas pendientes (`PendingCaptures`) **sincronizan**: monto, comercio, fecha, emisor y pista de cuenta salen del dispositivo, igual que una transacción escrita a mano |
| **App activity → Other user-generated content** | Sí | **Sí** | Se suma la fila de metadatos del comprobante (`TransactionAttachments`): que una transacción **tiene** foto, y en qué dispositivo se guardó. El archivo no viaja; el metadato sí |
| **Device or other IDs** | Sí (Sentry) | **Sí** | Sin cambio. Ojo: si el metadato del comprobante guarda un `deviceLabel` legible ("Pixel de Cami"), eso es un identificador de dispositivo elegido por el usuario que **sí** sincroniza — revisar al implementar |
| Datos de menores / categorías sensibles | No aplica | **Sin cambio** | Fase 2 no introduce datos de categorías especiales ni cambia la audiencia declarada (16-17 y 18+). El micrófono, la cámara y el acceso a notificaciones **no** son "datos sensibles" del formulario de Data Safety, pero sí son **permisos sensibles** con reglas propias (§7.1, §7.2). Si algún día se marcara una audiencia infantil, la lectura de notificaciones sería incompatible con la Política de Familias — no marcarla |

### 7.4 Cómo cambia App Privacy de Apple

Fase 2 llega a iOS **sin** la lectura de notificaciones (imposible en la
plataforma): solo voz, OCR/foto y widget.

| Tipo | Respuesta hoy | Con Fase 2 |
|---|---|---|
| **Audio Data** | No recopilado | **No recopilado** *(condicionado al mismo punto abierto de §7.5)*. Apple tampoco considera recolección lo que se procesa en el dispositivo y no se transmite |
| **Photos or Videos** | No recopilado | **No recopilado**: la imagen no sale del dispositivo |
| **Other User Content** | Recopilado | **Recopilado** (sin cambio de respuesta): se suma el metadato del comprobante |
| **Other Financial Info** | Recopilado | **Recopilado** (sin cambio): los campos extraídos por voz/OCR terminan en una transacción normal |
| Tracking | No | **No** — nada de Fase 2 introduce seguimiento ni identificador de publicidad |

Además, en iOS:

- Actualizar `PrivacyInfo.xcprivacy` (que hoy **ni siquiera existe**, ver B4 de
  `AUDITORIA.md`) para que sus `NSPrivacyCollectedDataTypes` sigan coincidiendo
  con esta hoja.
- Revisar la **clasificación por edad** solo si cambia el contenido; captura de
  gastos por voz o foto no la mueve.
- Las notas para App Review (§2.4) deben explicar que la app funciona sin
  conceder micrófono ni cámara, porque el registro manual es Nivel 0.

### 7.5 El punto abierto que bloquea la declaración de voz

**No se puede declarar la captura por voz hasta que esto se decida.**

`docs/requirements/fase-2/17-captura-voz.md` HU-06 deja sin resolver qué hace la
app cuando el reconocimiento **on-device** no está disponible en ese dispositivo
o idioma. Tanto `SFSpeechRecognizer` (iOS) como `SpeechRecognizer` (Android)
pueden enrutar el audio a servidores de Apple o de Google en ese caso.

La consecuencia es directa y no la resuelve la retención cero: **no guardar no es
no transmitir.** Si el audio sale del teléfono hacia un tercero, aunque nosotros
no lo guardemos:

- la respuesta de "Audio" en Data Safety y en App Privacy puede tener que
  cambiar a "recopilado / compartido",
- la política de privacidad tiene que nombrar a Apple/Google como destinatarios
  del audio y explicar en qué casos ocurre,
- y la promesa de "todo local" de Fase 2 deja de ser cierta tal como está
  escrita hoy.

Este documento **no** resuelve esa decisión: es de producto. Solo la señala como
**bloqueante de declaración**. Mientras siga abierta, la sección de voz de la
política y la casilla de audio de ambas tiendas quedan sin escribir.

### 7.6 Otros bloqueantes de release que arrastra Fase 2

- **Borrado de cuenta:** `PendingCaptures` y `TransactionAttachments`
  sincronizan, así que tienen que entrar en `delete_account_data` **en la misma
  migración que las crea**. Es literalmente el bug B1 de `AUDITORIA.md`, que ya
  reincidió cuatro veces. Si quedan fuera, la promesa de borrado total vuelve a
  ser falsa.
- **Fotos huérfanas:** el borrado de cuenta o el borrado local deben eliminar
  también los archivos de comprobante del directorio privado, o se repite el
  patrón de B2 (el número de cuenta que sobrevive en el llavero).
- **Sentry:** `lib/core/crash/sentry_redaction.dart` no puede dejar pasar rutas
  ni contenidos de comprobantes, transcripciones ni texto de notificaciones en
  un reporte de error. Un crash que filtre lo que la política promete no
  transmitir convierte esa promesa en falsa.
- **Export/import:** decidir si los comprobantes entran en la copia completa. Si
  entran, la política tiene que decirlo; si no, el usuario debe saber que la
  copia no los incluye.


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

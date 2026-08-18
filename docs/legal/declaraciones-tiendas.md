# Declaraciones de datos para Play Store y App Store — billetudo

**Versión 1.4** · **Última actualización: 17 de agosto de 2026**
**Versión de la app a la que corresponde: `0.0.5+8`** (`pubspec.yaml:4`)

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
> un formulario. La **§7 es un checklist a futuro** para cuando se implemente
> Fase 2 (captura por voz, OCR, notificaciones bancarias, widget): **nada de lo
> que dice §7 se declara todavía**, porque nada de eso existe en el código.
> Confundir las dos cosas y declarar de más es tan sancionable como declarar de
> menos.

**Qué cambió respecto de la versión 1.3 (8 de agosto):** el número de versión de
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
| 1 | URL pública de la política de privacidad | ⛔ https://camiiloaf.github.io/billetudo/ — **bloqueante en ambas consolas** |
| 2 | Borrado de cuenta desde la app | ✅ Implementado (ver §4) |
| 3 | Borrado de cuenta funcional para todos los usuarios | ⛔ **Ver bloqueante B1 de `AUDITORIA.md`** — hoy falla para usuarios con presupuestos por periodo o metas con montos rápidos. **Corregir antes de enviar.** |
| 4 | URL web de borrado de cuenta (exigida por Play) | ⛔ https://camiiloaf.github.io/billetudo/borrar-cuenta.html |
| 5 | `PrivacyInfo.xcprivacy` en el target iOS | ⛔ No existe — ver B4 de `AUDITORIA.md` |
| 6 | Nombre público del desarrollador | ✅ **Hecho consumado.** Las cuentas de Play y de App Store **ya están creadas** a nombre de Juan Camilo Agudelo Franco (persona natural). En Apple el *developer name* ya quedó fijado y **es irreversible**; no hay decisión pendiente aquí (ver §5) |
| 7 | Datos de contacto que la tienda publicará por su cuenta | ⚠️ Fuera del control del desarrollador y **ya condicionado** por las cuentas existentes — §5 describe qué publica hoy cada tienda y qué cambiaría al monetizar |

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
| **Email address** | **Sí** | No | **Opcional** | *App functionality*, *Account management* | Lo entrega el proveedor social y lo persiste Supabase Auth. No se muestra en la app |
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
- **Sin IA / voz / OCR / lectura de notificaciones:** `lib/features/capture/`
  contiene solo un `.gitkeep` y `lib/features/improvement/` está vacía;
  `speech_to_text` (`pubspec.yaml:86`) y `google_mlkit_text_recognition`
  (`pubspec.yaml:87`) siguen **comentados**; el `AndroidManifest.xml` no declara
  ningún `uses-permission` ni ningún `<service>` de `NotificationListenerService`.
  Re-verificado el 2026-08-17 (`AUDITORIA.md` §10.2). **Que los requerimientos de
  Fase 2 existan escritos no cambia esta respuesta:** se declara el binario, no
  el plan. Ver §7.

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
   sección nueva en la política.
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

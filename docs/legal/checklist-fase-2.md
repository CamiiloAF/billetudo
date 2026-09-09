# Checklist legal de pre-publicación — Fase 2 (captura sin fricción)

**Versión 2.0** · **Creado: 17 de agosto de 2026** · **Recorrido completo: 9 de septiembre de 2026**
**Estado: EN CURSO — ya no es un plan a futuro**

> **Qué cambió respecto de la v1.0.** La v1.0 se escribió cuando Fase 2 era solo
> una carpeta de requisitos. Ya no: el **esquema está aplicado**
> (`schemaVersion` 34), las **dependencias de voz y notificaciones locales están
> descomentadas**, la **decisión bloqueante del audio está tomada** y la
> **política v1.8 está redactada**. Este documento se recorrió entero el
> 2026-09-09 y ahora dice, casilla por casilla, **qué queda y quién lo tiene que
> hacer**.
>
> Lo que **no** cambió: se declara el binario, no el plan. Y el alcance se
> recortó: este envío es **voz + avisos bancarios + recordatorios locales**.
> **OCR y widget quedan fuera** y no se declaran.

> **Documento interno.** No se publica: `web/build_site.py` solo convierte a HTML
> `politica-de-privacidad.md`, `terminos-de-uso.md` y `como-borrar-tu-cuenta.md`.
> Este archivo, `AUDITORIA.md`, `declaraciones-tiendas.md`,
> `textos-consentimiento-fase-2.md` y `declaracion-permiso-notificaciones.md` se
> quedan en el repo.

## Cómo se leen los estados

| Símbolo | Significa |
|---|---|
| ✅ | Hecho y verificado contra el código o contra la fuente citada |
| 📝 | Escrito y listo, pero **depende de que exista código** para poder afirmarse |
| ⛔ | **Bloqueante.** Sin esto no se sube un build, ni siquiera a TestFlight / Internal Testing |
| ⚠️ | Hay que decidirlo o revisarlo, no bloquea por sí solo |
| ➖ | Fuera de alcance de este envío |

**Quién:** `[impl]` la rama que implementa la feature · `[legal]` este rol
(documentos) · `[prod]` decisión de producto · `[envío]` quien sube el build y
llena las consolas · `[infra]` Supabase / dashboards.

---

## 0. Regla que gobierna todo el checklist

Se declara **el binario**, no el plan. **Declarar de más es tan sancionable como
declarar de menos.**

Corolario que sigue vigente y que ahora sí muerde: **si Fase 2 se implementa por
partes, se declara solo la parte que va en el binario.** Este envío no incluye
OCR, así que **no se declara cámara ni galería** por más que aparezcan en la
carpeta de requisitos.

**Corolario nuevo, específico de este momento:** el esquema aplicado y una
dependencia descomentada **no son** la feature. `speech_to_text` está en
`pubspec.yaml:90` y **ningún archivo de `lib/` lo importa**; mientras siga así,
las respuestas vigentes de tienda son las de `declaraciones-tiendas.md` §1 y §2.

---

## 1. Permisos por plataforma

Hoy la app declara **cero** permisos: `AndroidManifest.xml` no tiene ni un
`uses-permission` y `Info.plist` no tiene ni una `*UsageDescription` (verificado
2026-09-09). Este envío rompe las dos cosas y la ficha de permisos visible en la
tienda cambia por primera vez.

### 1.1 Android

| # | Permiso | Estado | Quién |
|---|---|---|---|
| 1 | `RECORD_AUDIO` | ⛔ falta declarar | `[impl]` |
| 2 | `<service>` con `BIND_NOTIFICATION_LISTENER_SERVICE` + intent-filter | ⛔ falta declarar | `[impl]` |
| 3 | `POST_NOTIFICATIONS` | ⛔ falta declarar | `[impl]` |
| 4 | `RECEIVE_BOOT_COMPLETED` | ⛔ falta declarar | `[impl]` |
| 5 | `<queries>` **explícito** con los 4 `packageName` del catálogo | ⛔ falta, y **no puede ser `QUERY_ALL_PACKAGES`** (activa formulario de declaración en Play) | `[impl]` |
| 6 | **Ningún permiso de más.** Sin `READ_SMS`, `READ_CALL_LOG`, `BIND_ACCESSIBILITY_SERVICE`, `CAMERA`, `READ_MEDIA_IMAGES` — ni en el manifiesto propio ni en el fusionado | ⛔ verificar sobre el APK/AAB fusionado, no sobre el fuente | `[envío]` |
| 7 | Modo de programación de recordatorios **sin alarma exacta** si se puede | ⚠️ decidir; la alarma exacta trae su propio formulario en Play | `[impl]` / `[prod]` |

### 1.2 iOS

| # | Clave | Estado | Quién |
|---|---|---|---|
| 8 | `NSMicrophoneUsageDescription` | ⛔ falta | `[impl]` |
| 9 | `NSSpeechRecognitionUsageDescription` — **se olvida con frecuencia**; sin ella la app crashea al pedir autorización | ⛔ falta | `[impl]` |
| 10 | Autorización de notificaciones en runtime (no lleva clave de `Info.plist`) | ⛔ falta | `[impl]` |
| 11 | Textos localizados en `InfoPlist.strings` (es + en) | 📝 redactados en [`textos-consentimiento-fase-2.md`](textos-consentimiento-fase-2.md) §1.4 | `[impl]` |
| 12 | **No** declarar cámara ni galería | ✅ nada que hacer: OCR está fuera | — |

**La lectura de avisos bancarios no aplica en iOS** y no va a aplicar: la
plataforma no permite leer notificaciones ajenas. Todo texto que mencione la
feature dice "en Android" explícitamente. ✅ cumplido en la política v1.8 §14.2 y
§18.2.

### 1.3 Consecuencias que arrastra cada permiso

| # | Qué | Estado | Quién |
|---|---|---|---|
| 13 | Petición **en contexto** con explicación previa (*prominent disclosure* de Play) | 📝 textos listos, falta implementarlos | `[impl]` |
| 14 | Degradación no punitiva si se niega; **ninguna función de Nivel 0 detrás de un permiso** | ⛔ falta código | `[impl]` |
| 15 | El estado del permiso se **re-verifica en cada arranque** y al volver a foreground | ⛔ falta código | `[impl]` |

---

## 2. Política de privacidad

| # | Qué | Estado | Quién |
|---|---|---|---|
| 16 | Nueva versión y fecha | ✅ **v1.8**, 9 de septiembre de 2026 | `[legal]` |
| 17 | Línea de captura en "Lo esencial" | ✅ | `[legal]` |
| 18 | §4.1: filas de capturas pendientes, aprendizaje, `cardLast4`, `reminderLeadDays` | ✅ | `[legal]` |
| 19 | §4.6 nueva: qué se extrae de un aviso, campo por campo, y **el nombre de terceros** | ✅ | `[legal]` |
| 20 | §5.4 y §8: Apple/Google como destino del audio | ✅ | `[legal]` |
| 21 | §6: **consentimiento explícito y revocable** como base legal de voz y avisos, no ejecución del contrato | ✅ | `[legal]` |
| 22 | §7: Apple y Google como **responsables independientes** del audio | ✅ | `[legal]` |
| 23 | §9: retención cero del material crudo y plazos de las capturas | ✅ (con un `[VERIFICAR]` abierto: si las capturas caducan solas) | `[legal]` / `[prod]` |
| 24 | §10: el borrado de cuenta arrastra capturas y aprendizaje | ✅ | `[legal]` |
| 25 | §11: cómo revocar cada consentimiento nuevo | ✅ | `[legal]` |
| 26 | §12: datos de terceros que **la app extrae sin que el usuario los teclee** | ✅ | `[legal]` |
| 27 | §14 reescrita entera (antes decía "no pedimos ningún permiso sensible") | ✅ | `[legal]` |
| 28 | §17.3: corregida la frase *"la app ni siquiera pide esos permisos"*, que dejaba de ser cierta | ✅ | `[legal]` |
| 29 | §18 nueva: voz, avisos bancarios y recordatorios, entera | ✅ | `[legal]` |
| 30 | §19: quitar solo los bullets que dejan de ser ciertos; **mantener** "no hay OCR" y "no hay widget" | ✅ | `[legal]` |
| 31 | **Publicarla** (regenerar el sitio y desplegar) | ⛔ **NO todavía** — ver §9 | `[legal]` / `[envío]` |

### 2.1 La frase que sostiene todo, y por qué se puede escribir

> El contenido de las notificaciones no se envía a ningún servidor **porque no se
> guarda en ninguna parte**; lo que sincroniza son los datos financieros ya
> estructurados, del mismo tipo que un movimiento escrito a mano.

Esa frase **solo se sostiene por la retención cero**, y la retención cero es
**demostrable**: `PendingCaptures` no tiene ninguna columna de texto crudo, ni en
Drift (`app_database.dart:987-1056`) ni en Postgres
(`20260909000000_fase2_capture_schema.sql:29-50`). Ver `AUDITORIA.md` §13.3.

**Condición para que siga siendo cierta:** que el código no persista el texto ni
en la base, ni en un log, ni en un reporte de Sentry, ni en un archivo temporal,
ni disfrazado dentro de la `note` de la transacción.
⛔ **Esa verificación falta** y la hace `[impl]` sobre el código real, no sobre el
esquema.

---

## 3. El acceso a notificaciones: la declaración de mayor riesgo

| # | Qué | Estado | Quién |
|---|---|---|---|
| 32 | Justificación de uso escrita | ✅ [`declaracion-permiso-notificaciones.md`](declaracion-permiso-notificaciones.md) §1 | `[legal]` |
| 33 | Guion del video de demostración | ✅ mismo documento §2 | `[legal]` |
| 34 | **Grabar** el video | ⛔ falta; necesita la feature funcionando en un teléfono real | `[envío]` |
| 35 | Data Safety actualizado y enviado con el mismo build | 📝 respuestas listas en `declaraciones-tiendas.md` §7.3 | `[envío]` |
| 36 | Ficha de tienda que describa la funcionalidad, **sin prometer captura total** | ⛔ falta | `[prod]` |
| 37 | No combinar con SMS, registro de llamadas ni accesibilidad | ✅ hoy no se piden; verificar sobre el manifiesto fusionado al enviar | `[envío]` |
| 38 | Voz y OCR funcionando en el mismo release **público** | ⚠️ este envío lleva voz, **no OCR** — ver §7 | `[prod]` |

`[VERIFICAR: si Play exige un formulario y/o video específico para
BIND_NOTIFICATION_LISTENER_SERVICE]` — **re-verificado el 2026-09-09**: las
páginas vigentes de Play siguen **sin** listarlo entre los permisos con
formulario propio. No se afirma que no exista; se revisa en la consola al enviar.
Detalle y fuentes en `declaracion-permiso-notificaciones.md` §0.

**La nota del 2026-08-18 sobre la sección "Mensajes" queda cerrada.** Se temía que
esa sección no pudiera quedar en blanco. Revisado contra el esquema real: la
respuesta correcta **sigue siendo No**, y ahora hay evidencia para sostenerla
(catálogo cerrado sin apps de mensajería, filtro por `packageName` antes de leer
contenido, y cero persistencia del texto). Lo que sí aparece son **tres filas
nuevas** que la nota original no anticipaba: *Installed apps*, la justificación
ampliada de *Name*, y la fuente nueva de *Purchase history*.
Ver `declaraciones-tiendas.md` §7.3.

---

## 4. La precisión que más fácil se rompe

**Lo que sincroniza y lo que no.** `PendingCaptures` **sincroniza**: monto,
comercio, fecha, emisor y cuenta sugerida **salen del dispositivo** si el usuario
inició sesión.

- ❌ **Prohibido:** *"nada sale de tu teléfono"*, *"todo el proceso es local"*.
- ✅ **Correcto:** la formulación de §2.1 de este documento.
- ❌ **Prohibido para la voz:** *"todo el procesamiento es local"* a secas. Falso
  en los teléfonos sin reconocimiento on-device. Ver §5.
- ➖ La precisión sobre foto vs. metadatos del comprobante **no aplica**: OCR está
  fuera de alcance.

✅ Verificado en la política v1.8: no aparece ninguna de las frases prohibidas.

---

## 5. El audio: bloqueante RESUELTO

**Decidido (2026-09-09):** el audio→texto usa el reconocedor de la plataforma. Con
reconocimiento **on-device** disponible se usa ese y el audio no sale del
teléfono. **Cuando no está disponible, el audio se procesa en servidores de Apple
o de Google.** Ni el audio ni la transcripción se guardan.

| # | Consecuencia | Estado | Quién |
|---|---|---|---|
| 39 | La política nombra a Apple y a Google como responsables independientes del audio | ✅ v1.8 §7 y §18.1 | `[legal]` |
| 40 | La tabla de transferencias internacionales incluye esa fila | ✅ v1.8 §8 | `[legal]` |
| 41 | Casilla de Audio en Data Safety y App Privacy resuelta con su justificación | ✅ `declaraciones-tiendas.md` §7.3 y §7.4 | `[legal]` |
| 42 | **Prohibido** escribir "todo el procesamiento es local" en ficha, permiso o material de marketing | ✅ regla escrita | `[prod]` / `[envío]` |
| 43 | Pedir `requiresOnDeviceRecognition` siempre que la plataforma lo permita, y **saber** si se consiguió | ⛔ falta código | `[impl]` |
| 44 | En Android no hay aviso del sistema equivalente al de iOS. ¿Se muestra uno propio cuando cae a la nube? | ⚠️ decisión abierta, solo afecta al copy | `[prod]` |

---

## 6. Menores y categorías de datos sensibles

| # | Qué | Estado |
|---|---|---|
| 45 | La audiencia declarada **no cambia**: 16-17 y 18+ en Play, 16+ en App Store | ✅ |
| 46 | Nada de este envío introduce categorías especiales de datos | ✅ |
| 47 | **La voz es canal de entrada de texto, no biometría.** No hay reconocimiento del hablante ni huella de voz | ✅ dicho en la política v1.8 §19 y en `declaraciones-tiendas.md` §7.3 |
| 48 | Micrófono, notificaciones y acceso a notificaciones **no** son "datos sensibles" del formulario, pero sí **permisos sensibles** con reglas propias. No mezclar las dos categorías | ✅ |
| 49 | No marcar audiencia infantil: sería incompatible con la lectura de notificaciones bajo la Política de Familias | ✅ decisión vigente |

---

## 7. La condición de "no publicar sola"

`docs/requirements/fase-2/19-notificaciones-bancarias.md` y
`docs/requirements/README.md` fijan que el release **público** con avisos
bancarios debe llevar **voz y OCR ya funcionando**, para no depender de una sola
vía de captura si Google rechaza el permiso.

**Este envío lleva voz. No lleva OCR.**

- Para **TestFlight / Internal Testing** eso es aceptable y coherente: es un canal
  cerrado, y validar el diferenciador con usuarios reales es justamente para lo
  que sirve.
- Para un **release público**, la propia decisión dice que **debe reabrirse
  explícitamente**, no resolverse con una nota ni con un "lo hacemos en el
  siguiente release".

⚠️ **`[prod]` tiene que reabrirla antes de cualquier promoción a producción.**

---

## 8. Checklist final antes de subir el build

### Código y plataforma

| # | Qué | Estado | Quién |
|---|---|---|---|
| 50 | `pubspec.yaml`: solo las dependencias que la feature usa | ✅ voz, notificaciones locales y permisos descomentados; **OCR y monetización siguen comentados** | `[impl]` |
| 51 | `AndroidManifest.xml`: permisos y `<service>` declarados, y **ninguno de más** | ⛔ | `[impl]` |
| 52 | `Info.plist`: las dos `*UsageDescription`, localizadas y específicas | ⛔ | `[impl]` |
| 53 | `PrivacyInfo.xcprivacy` revisado y coherente con `declaraciones-tiendas.md`; auditar los privacy manifests de los plugins nuevos | ⚠️ existe desde 2026-08-18, **falta revisarlo** | `[impl]` |
| 54 | `delete_account_data` cubre `pending_captures` y `merchant_category_learning` **en la misma migración que las crea** | ✅ `20260909000000_fase2_capture_schema.sql:153-154` — **primera vez que no reincide el bug B1** | — |
| 55 | Esa migración **aplicada en dev y en prod**, no solo commiteada | ⚠️ no se pudo verificar desde este worktree | `[infra]` |
| 56 | Borrado local de capturas ("dejar como recién instalada", sin tocar transacciones confirmadas) | ⛔ falta código; la política ya lo describe | `[impl]` |
| 57 | Pantalla de transparencia dentro de Ajustes | ⛔ falta código; la política ya la describe | `[impl]` |
| 58 | `sentry_redaction.dart` no deja pasar transcripciones, texto de notificaciones ni contenido de capturas | ⛔ **hoy solo cubre errores de Postgres** | `[impl]` |
| 59 | La `note` de la transacción se compone **solo de campos identificados**, nunca del texto del aviso recortado | ⛔ falta verificar sobre el código | `[impl]` |
| 60 | El filtro por `packageName` se aplica **antes** de leer título, texto o extras — y hay revisión humana del Kotlin, que ningún revisor del repo cubre | ⛔ | `[impl]` |
| 61 | Decidido si las capturas entran en la copia completa de Import/Export, y dicho en la política en cualquier caso | ⚠️ | `[prod]` / `[legal]` |
| 62 | Dónde se persiste la lista de emisores activos (si sincroniza, es una fila más de Data Safety) | ⚠️ | `[impl]` |

### Documentos

| # | Qué | Estado | Quién |
|---|---|---|---|
| 63 | `politica-de-privacidad.md` actualizada | ✅ v1.8 | `[legal]` |
| 64 | `politica-de-privacidad.md` **publicada antes** de que la función llegue al usuario | ⛔ ver §9 | `[legal]` |
| 65 | `declaraciones-tiendas.md` §1.1 y §1.3 acotadas; §7 convertida en el juego de respuestas del envío | ✅ v1.8 | `[legal]` |
| 66 | `AUDITORIA.md` §10.2 reescrita: deja de ser "no implementado" a secas | ✅ nueva §13 con la evidencia; §10.2 marcada como registro histórico | `[legal]` |
| 67 | `terminos-de-uso.md` revisado | ⚠️ **revisar**: hoy no afirma nada sobre permisos ni captura. Confirmar que sigue siendo así y que no hace falta un párrafo sobre "la captura no garantiza cobertura" | `[legal]` |
| 68 | `como-borrar-tu-cuenta.md` revisado si el borrado cambia de alcance | ⚠️ el borrado de cuenta ahora arrastra dos tablas más; revisar si el texto público lo enumera | `[legal]` |
| 69 | Textos de consentimiento y transparencia listos para `.arb` | ✅ [`textos-consentimiento-fase-2.md`](textos-consentimiento-fase-2.md) — **no se metieron en los `.arb` a propósito**, para no chocar con las ramas de implementación | `[legal]` → `[impl]` |
| 70 | Justificación y guion de video del permiso de notificaciones | ✅ [`declaracion-permiso-notificaciones.md`](declaracion-permiso-notificaciones.md) | `[legal]` |
| 71 | Sitio legal regenerado (`python3 web/build_site.py`) y desplegado | ⛔ ver §9 | `[envío]` |
| 71b | El set `NO_PUBLICAR` de `web/build_site.py:54` sigue listando solo `AUDITORIA.md` y `declaraciones-tiendas.md`. Los tres documentos internos nuevos (`checklist-fase-2.md`, `textos-consentimiento-fase-2.md`, `declaracion-permiso-notificaciones.md`) **no** se publican —la lista `PAGES` es explícita y no los incluye— pero conviene añadirlos a ese set para que la omisión siga siendo deliberada y no un olvido | ⚠️ cosmético, no bloquea | `[envío]` |

### Tiendas

| # | Qué | Estado | Quién |
|---|---|---|---|
| 72 | Data Safety de Play rehecho y enviado con el mismo build | 📝 respuestas listas | `[envío]` |
| 73 | App Privacy de Apple rehecho | 📝 respuestas listas, con una casilla de criterio (Audio Data) señalada | `[envío]` |
| 74 | Justificación + video del acceso a notificaciones | 📝 / ⛔ (falta grabar) | `[envío]` |
| 75 | Ficha de tienda describe las funciones que justifican cada permiso | ⛔ | `[prod]` |
| 76 | Notas para App Review actualizadas: la app funciona sin micrófono ni notificaciones | 📝 párrafo listo en `declaraciones-tiendas.md` §7.7 | `[envío]` |
| 77 | Verificar el **manifiesto fusionado** del AAB que se sube, no el fuente | ⛔ | `[envío]` |

---

## 9. Publicación: la política se redacta ahora, se despliega después

**La política v1.8 está escrita y NO se despliega todavía.** Es deliberado y hay
que respetarlo en las dos direcciones:

- **No se despliega antes**, porque describiría funciones que el binario no
  tiene. Una política que promete un borrado local y una pantalla de
  transparencia que no existen es tan falsa como una que omite un permiso.
- **No se despliega después**, porque la propia política (§19) promete
  actualizarse **antes** de que la función llegue al usuario, y porque las
  tiendas exigen que la URL vigente describa el binario que se envía.

**El orden correcto, y no admite atajos:**

1. `[impl]` cierra los ⛔ de §8 (permisos nativos, borrado local, pantalla de
   transparencia, redacción de Sentry).
2. `[legal]` re-verifica la v1.8 contra ese código y quita cualquier afirmación
   que no se sostenga.
3. `[envío]` regenera el sitio (`python3 web/build_site.py`) y **despliega**.
4. `[envío]` sube el build a TestFlight / Internal Testing con Data Safety y App
   Privacy rehechos **en el mismo envío**.

**TestFlight e Internal Testing cuentan.** Son canales cerrados, pero son
distribución: Data Safety y App Privacy aplican, y los usuarios de prueba son
titulares de datos con los mismos derechos que cualquier otro.

---

## 10. Resumen: qué bloquea un build de TestFlight / Internal Testing

En orden de riesgo:

1. ⛔ **Redacción de Sentry** (#58). Si un crash filtra una transcripción o el
   texto de un aviso, la promesa central de la política es falsa el día uno.
2. ⛔ **Permisos nativos declarados** (#51, #52) y **ninguno de más**, verificado
   sobre el binario fusionado (#77).
3. ⛔ **Borrado local de capturas** (#56) y **pantalla de transparencia** (#57):
   la política ya los describe y HU-08 los hace no negociables.
4. ⛔ **Política v1.8 publicada antes del envío** (#64, #71).
5. ⛔ **Data Safety y App Privacy rehechos en el mismo envío** (#72, #73),
   incluida la fila nueva de *Installed apps*.
6. ⛔ **Video del permiso de notificaciones grabado** (#34), si Play lo pide.
7. ⛔ **`<queries>` explícito, nunca `QUERY_ALL_PACKAGES`** (#5).
8. ⚠️ **Migración aplicada en prod** (#55).
9. ⚠️ **Reabrir la condición de "no publicar sola"** antes de producción (§7).

---

## 11. Límite

Este documento **no es asesoría jurídica**. Su valor es ser exacto respecto al
software y completo respecto a los requisitos de tienda; la revisión legal formal
la hace una persona abogada.

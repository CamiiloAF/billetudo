# Reglas de parseo de notificaciones bancarias

`issuer_rules.json` es la **fuente única** de las reglas de HU-03
(`docs/requirements/fase-2/19-notificaciones-bancarias.md`). Lo leen **dos**
motores:

| Motor | Dónde | Para qué |
| --- | --- | --- |
| Kotlin | `android/app/src/main/kotlin/com/billetudo/app/capture/NotificationRuleEngine.kt` | Producción. Corre dentro de `NotificationListenerService`, con la app cerrada y sin motor Flutter vivo. |
| Dart | `lib/features/capture/domain/usecases/parse_bank_notification.dart` | Espejo. Existe para poder correr la batería de ejemplos con `flutter test` y para el camino de Fase 4. |

**Se duplica el motor, nunca las reglas.** Una regla que exista en un solo lado
es un bug. Añadir o corregir un formato debe ser exactamente dos ediciones:
una regla en este JSON y un caso en
`test/features/capture/domain/parse_bank_notification_test.dart`.

## Cómo se lee una regla

- `ruleId` — id estable. Es lo único que queda guardado en la captura
  (`PendingCaptures.sourceRuleId`) para poder depurar un parser roto **sin**
  guardar el texto (retención cero). No reutilizar un id para otro formato.
- `priority` — gana la más alta. Las reglas `ignore` van por encima de las de
  captura a propósito: un OTP que trae una cifra no puede volverse un
  movimiento.
- `action` — `capture` o `ignore`.
- `target` — contra qué se corre el regex: `title`, `text` (el cuerpo real de
  `EXTRA_TEXT` / `EXTRA_BIG_TEXT`) o `combined` (`título + "\n" + cuerpo`).
  Existe porque los emisores no son consistentes: Nu parte el monto (título) de
  la contraparte (cuerpo), Nequi mete el monto **dentro** de la frase del cuerpo
  y no lo pone en el título, y Google Wallet invierte todo (el título es el
  comercio).
- `captures` — nombre de campo → grupo nombrado del regex. Campos soportados:
  `amount` (obligatorio en una regla de captura), `merchant`, `last4`,
  `currency`, `cardNetwork`.
- `validated` — si la regla se escribió contra una notificación **real**.
- `packageNameValidated` (por emisor) — afirmación **distinta**: dice que el
  `packageName` se confirmó en un dispositivo real (`adb shell pm list
  packages`). Un emisor puede tener paquete confirmado y reglas sin validar.

## Estado al 2026-09-09

Catálogo de lanzamiento: **tres emisores**, todos con reglas validadas contra
texto real. **Ninguna regla de emisor está escrita a ciegas.**

| Emisor | `packageName` | Reglas |
| --- | --- | --- |
| Nu | `com.nu.production` ✅ confirmado | ✅ validadas (ingreso con contraparte, compra con comercio, envío P2P) |
| Nequi | `com.nequi.MobileApp` ✅ confirmado | ✅ validadas (ingreso Bre-B, envío de plata) |
| Google Wallet | `com.google.android.apps.walletnfcrel` ✅ confirmado | ✅ validadas (pago NFC con monto+moneda+red+últimos 4) y el recordatorio que **no** captura |

### Bancolombia NO está en el catálogo (y no se reintroduce sin volver a decidirlo)

**Bancolombia no manda notificaciones push, solo SMS.** Un SMS llega al
`NotificationListenerService` como notificación de la **app de mensajería**
(`com.google.android.apps.messaging` u otra), no del banco. Capturarlo obligaría
a habilitar el listener sobre la app de mensajes y a **leer el título (el
remitente) de todos los mensajes del usuario** para decidir cuáles procesar —
incluidos códigos de un solo uso y conversaciones personales.

Eso rompe la regla que HU-08 marca como no negociable: filtrado por
`packageName` en el primer punto de entrada, descartando **antes** de leer
título, texto o extras. Con SMS el filtro pasaría a ser por remitente, que exige
leer primero. Es además de los puntos que más rechazos generan en la revisión de
Google Play. Hay un test que lo fija:
`test/features/capture/domain/issuer_rule_set_test.dart`.

Siguen sin validar las reglas `ignore` **globales** (OTP, seguridad, extracto,
promoción) salvo la de recordatorio, cubierta por el `Recordatorio de Wallet`
real. Son de exclusión: si no disparan, la regla de captura tampoco encuentra un
movimiento en ese texto, así que el riesgo es bajo.

## Formatos de monto que hay que soportar

Ya se vieron tres distintos, y por eso el parser decide el separador por
inspección y no por locale fijo:

- `$58.470,00` (Nu) — con símbolo y con decimales
- `128.920,00` (Nu, ingreso) — **sin símbolo**
- `$1` (Nequi) — sin decimales
- `38.000,00 COP` (Wallet) — moneda explícita **después** de la cifra

El error que esto evita es de 1000×: `128.920,00` son ciento veintiocho mil
novecientos veinte pesos.

## Lo que este archivo nunca va a tener

Ninguna columna, campo o regla que guarde el texto de la notificación, completo
o recortado. `merchantRaw` guarda **solo** el fragmento que una regla
identificó como comercio o contraparte. Es la retención cero de HU-03, y la
promesa de la política de privacidad depende de ella.

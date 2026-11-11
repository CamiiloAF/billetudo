# Fix: la captura no se mostraba en vivo y las instalaciones viejas nunca avisaban (fix-captura-ingesta-en-vivo)

## Reporte del usuario (2026-11-11)

> "Cuando hago una transacción bancaria y me llega una notificación, la app no escucha y no
> muestra la nueva entrada. Antes lo arreglaste; con el cambio de los permisos se volvió a romper."

Contexto verificado en la sesión anterior con el teléfono conectado (Xiaomi Redmi, Android 16,
MIUI/HyperOS V816, build de Play `com.billetudo.app`):

- El artefacto del pipeline **sí** contiene el listener (`BilletudoNotificationListenerService`
  en `classes.dex`, `<service>` en el manifest del AAB, `flutter_assets/assets/capture/issuer_rules.json`
  empaquetado). No es un problema de build ni de firma.
- El log del sistema muestra la causa real del "no escucha" en segundo plano:
  `AutoStartManagerService: MIUILOG- Reject service` +
  `NotificationListeners: AutStart Unable to bind notification listener service`. MIUI/HyperOS
  rechaza bindear el `NotificationListenerService` si Billetudo no tiene "Inicio automático" y no
  está exenta de optimización de batería. Eso **no se puede conceder desde la app**, solo guiar al
  usuario (HU-09).
- Con la app abierta el listener sí captura; las capturas aparecen en Avisos.

Sobre ese estado quedaban **dos bugs de código**, que son los que este run corrige:

1. **La ingesta no era en vivo.** Solo se drenaba el buffer nativo en el arranque en frío y al abrir
   Avisos (`NoticesCubit.start()`). Una notificación recibida con la app ya abierta (o en segundo
   plano con el proceso vivo) quedaba en el buffer sin crear fila: la campana no mostraba badge y
   Avisos seguía diciendo "Todo al día". Es exactamente el síntoma reportado y rompe el criterio de
   HU-04 "hay un indicador de cuántas pendientes hay, visible sin entrar a la bandeja".
2. **La migración de HU-09 dejaba sin aviso a las instalaciones ya configuradas.** `configuredAt`
   solo lo escribía la pantalla de emisores, que nació con HU-09. Un teléfono configurado con una
   build anterior conservaba `configuredAt = null`, la regla respondía "nunca configurado" y las
   superficies de degradación no aparecían nunca — el usuario veía "Todo al día" mientras la
   captura estaba muerta, que es el reporte que reabrió HU-09.

## Qué cambió

### 1. Ingesta en vivo (app abierta o en segundo plano)

| Archivo | Qué |
|---|---|
| `android/.../capture/CaptureChannelHandler.kt` | Guarda el `MethodChannel` del engine vivo en el companion, expone `notifyCaptureBuffered()` (postea al main looper, `runCatching`) y `detach()`. El evento es una campanilla sin payload. |
| `android/.../capture/BilletudoNotificationListenerService.kt` | Tras `buffer.add` + `markCaptureReceived`, llama `CaptureChannelHandler.notifyCaptureBuffered()`. Sin engine no hace nada: la captura ya quedó bufferizada. |
| `android/.../app/MainActivity.kt` | `cleanUpFlutterEngine` → `CaptureChannelHandler.detach()`, para no empujar a un messenger muerto. |
| `lib/features/capture/data/datasources/capture_method_channel_datasource.dart` | Handler de método `onCaptureBuffered` → `Stream<void>` broadcast `incomingCaptures`. Sin payload (la única lectura es el drain atómico). |
| `lib/features/capture/domain/repositories/notification_capture_repository.dart` + impl | `incomingCaptureEvents()`. |
| `lib/features/capture/domain/usecases/watch_incoming_captures.dart` | Caso de uso de la campanilla. |
| `lib/features/capture/domain/usecases/drain_and_ingest_captures.dart` | **Única** ruta "drenar + mapear + ingerir". Bootstrap y `NoticesCubit` la reusan; antes el mapeo estaba duplicado y por eso los dos caminos podían desincronizarse. |
| `lib/features/capture/presentation/capture_ingest_observer.dart` | Observador app-wide (`@lazySingleton`, arrancado una vez en `bootstrap`): drena con la campanilla y en `AppLifecycleState.resumed` (red de seguridad). Coalesce ráfagas sin perder el último evento. Errores → `CrashReporter`, nunca al usuario. |
| `lib/core/bootstrap.dart` | El arranque usa `DrainAndIngestCaptures` (antes de montar, para que el primer frame ya tenga badge) y arranca el observador. |

### 2. Backfill de `configuredAt` (migración HU-09)

| Archivo | Qué |
|---|---|
| `lib/features/capture/domain/usecases/mark_capture_configured.dart` | Si no hay marca y las precondiciones se cumplen, el ancla es `lastCaptureAt` (evidencia de que el equipo ya capturaba) y, sin capturas, `now`: un equipo ya configurado hereda la fecha real en vez de reiniciar el reloj. **Deliberadamente no** se usa `lastListenerConnectedAt`: el heartbeat puede ser días anterior a que el usuario encienda los emisores y encendería la tarjeta en falso. Un ancla en el futuro (reloj del equipo atrasado) se recorta a `now`. Sigue siendo idempotente y sin sobrescritura. |
| `lib/features/capture/presentation/cubit/capture_background_cubit.dart` | Llama al backfill en cada `_reload()` una vez verificados permiso + emisores (idempotente). Además se suscribe a la campanilla para refrescar el estado: una captura nueva es la prueba más rápida de que la captura volvió. |

### 3. Reuso y no-duplicación

- `NoticesCubit` pasó de inyectar `DrainNativeCaptures` + `IngestParsedCaptures` a inyectar
  `DrainAndIngestCaptures`; el mapeo `ParsedNotification → ParsedCapture` vive en un solo lugar.
- `bootstrap` también dejó de mapear a mano.

## Tests

- `drain_and_ingest_captures_test.dart` (nuevo): mapeo campo a campo, buffer vacío, fallo de drain
  y fallo de ingesta.
- `capture_ingest_observer_test.dart` (nuevo): arranque sin drenar (el arranque en frío es del
  bootstrap), campanilla, `resumed` como red de seguridad, coalescencia de ráfagas sin perder el
  último aviso, y fallo registrado y tragado.
- `notification_capture_repository_impl_test.dart`: la campanilla nativa llega como evento del
  stream.
- `capture_background_health_test.dart`: ancla del backfill por última captura, por heartbeat y
  fallback a "ahora" cuando el diagnóstico no se puede leer.
- `capture_background_cubit_test.dart`: backfill en `start()`, no se intenta sin emisores, y la
  campanilla refresca la salud.
- `notices_cubit_test.dart`: adaptado al nuevo caso de uso único.

Verificación (2026-11-11):

- `flutter analyze` → **No issues found**.
- `flutter test test/features/capture` → **647 passed**.
- `flutter test` completo → **6132 passed, 1 skipped** (el skip es preexistente).
- Kotlin `:app:compileDevDebugKotlin` → **BUILD SUCCESSFUL** (invocando el gradle del SDK vía
  `/bin/sh` y `GRADLE_USER_HOME=.gradle-dsh` + `GRADLE_RO_DEP_CACHE`, por el sandbox).
- Revisión independiente (`finance-code-reviewer`): **APROBADO CON OBSERVACIONES**; se aplicaron
  las 3 observaciones de fondo (ancla sin heartbeat, arranque del observer antes del drenado
  inicial para no perder el timbre en esa ventana, y guarda de secuencia en `_reload` para que un
  refresco viejo no emita después de uno nuevo).

## Lo que la app no puede arreglar (y por qué se guía)

MIUI/HyperOS rechaza el bind del listener en segundo plano hasta que el usuario active
"Inicio automático" y la exención de batería. La app no puede conceder ninguno de los dos: solo
abrir las pantallas. Por eso el valor de este fix es doble: (a) la captura que sí llegó con la app
abierta ahora aparece al instante, y (b) las instalaciones viejas por fin ven la tarjeta/hoja de
HU-09 que lleva a esos dos ajustes, en vez de un "Todo al día" que miente.

## Pendientes / riesgos

- Sin device en este sandbox: la ruta nativa de la campanilla se verificó por compilación Kotlin +
  revisión de código, no en emulador. Con el teléfono conectado conviene probar:
  banco notifica → badge de campana sube sin tocar nada; abrir Avisos → captura presente; con
  captura degradada, una notificación nueva limpia la tarjeta.
- El backfill usa `lastCaptureAt` como ancla; si un usuario reconfigura emisores después de un
  hueco largo y la marca seguía ausente, el aviso podría adelantarse. Copy de la tarjeta ya es
  condicional ("puede que…"), no acusa.
- **Riesgo asumido (preexistente, ahora más frecuente):** `DrainAndIngestCaptures` vacía el buffer
  nativo antes de persistir. Si `IngestParsedCaptures` falla (fallo de base de datos o del espejo
  local del catálogo), esas capturas ya no existen. Es el contrato explícito de
  `DrainNativeCaptures` ("anything it drops is lost") y no se cambia acá; antes ocurría una vez
  por arranque, ahora también una por notificación. Si se quiere eliminar del todo, el camino es
  validar el catálogo antes de drenar, no reintentar sobre texto que ya no existe.

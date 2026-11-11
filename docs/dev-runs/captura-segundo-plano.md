# Captura en segundo plano — diagnóstico y superficies de degradación (captura-segundo-plano)

## Objetivo y criterios de aceptación

Cerrar el agujero de HU-09 que el usuario reportó en un Xiaomi/HyperOS real: con el build de Play
la lectura de notificaciones dejaba de funcionar sin que la app lo dijera. El log del sistema
mostró la causa raíz (`AutoStartManagerService: MIUILog- Reject service ... BilletudoNotificationListenerService`
+ `AutStart Unable to bind notification listener service`): MIUI rechaza rebindear el listener si
la app no tiene "Inicio automático", y la app seguía mostrando "Todo al día". La feature agrega el
diagnóstico nativo (última captura, exención de batería, fabricante/autostart) y las superficies
que dicen la verdad y ofrecen los dos ajustes del sistema.

Spec aprobado (claro + oscuro): `design-system/billetudo/pages/captura-segundo-plano.md`.
Frames: card `VW54R`/`DSCf0`, vacío `krE9G`/`S0iyTP`, hoja `TPLPN`/`bN2YZ` (variante C descartada
y borrada del canvas).

Criterios de aceptación (15, todos cubiertos):

1. `getDiagnostics` del canal devuelve `lastCaptureAtEpochMs` (nullable), `batteryOptimizationExempt`,
   `manufacturer`, `autostartAvailable`; mapeo tolerante a payload vacío/parcial y sin tráfico de
   canal fuera de Android.
2. `CaptureSettings` persiste `last_capture_at_epoch_ms` y el listener lo escribe **solo** después de
   `IssuerFilter` + parser.
3. `degraded=false` sin permiso, con 0 emisores, con `configuredAt` ausente, con <3 días configurado
   sin capturas, o con última captura <7 días.
4. `degraded=true` con ≥3 días configurado sin capturas o última captura ≥7 días; una captura del
   mismo día lo apaga.
5. `SnoozeCaptureBackgroundAlert` persiste 14 días, sobrevive a instancia nueva del repo, no toca
   capturas ni emisores.
6. `MarkCaptureConfigured` idempotente y cableado desde `CaptureIssuersCubit`.
7. El cubit re-lee permiso/emisores/diagnóstico en `start()` y `refresh()`; permiso revocado o 0
   emisores ganan sobre un diagnóstico viejo.
8. `snooze()` deja `showsAttention=false` sin tocar capturas/emisores.
9. `confirmActivated()` solo resuelve `true` si la batería quedó realmente exenta.
10. Avisos con capturas: card arriba de la sección + pie "Última captura…"; sin degradación, idéntico.
11. Avisos vacío: el vacío contextual reemplaza "Todo al día"; nunca card y vacío degradado a la vez.
12. Hoja: batería siempre, autostart solo en OEM con destino, fila cumplida no navegable, "Ahora no"
    snoozea, scrim/arrastre no.
13. "Listo, ya lo activé" cierra solo si la exención se concedió; si no, queda abierto con filas
    actualizadas; un solo label a11y por fila y flecha decorativa.
14. l10n es+en completa, `gen-l10n` limpio, sin texto hardcodeado.
15. Goldens claro/oscuro de las 3 superficies (+ variante batería cumplida) y analyze/tests verdes.

## Qué cambió

| Archivo | Qué |
|---|---|
| `android/.../AndroidManifest.xml` | Permiso `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` con comentario de contexto (se pide desde la hoja, nunca al arrancar). |
| `android/.../capture/CaptureSettings.kt` | `lastCaptureAt()` + `markCaptureReceived()` con guard monotónico (Android re-entrega notificaciones vigentes al reconectar el listener y no debe retroceder el timestamp). |
| `android/.../capture/BilletudoNotificationListenerService.kt` | Marca la última captura solo tras `IssuerFilter.resolveEnabledIssuer` + `engine.parse`. |
| `android/.../capture/CaptureChannelHandler.kt` | `getDiagnostics`, `requestIgnoreBatteryOptimizations`, `openAutostartSettings` en el canal existente. |
| `android/.../capture/CaptureSystemSettings.kt` | PowerManager, intent de exención con fallback, intents por OEM (Xiaomi/HyperOS, Huawei/EMUI, Samsung; Oppo/Vivo/OnePlus/Realme → ficha de la app), todo con fallback y `ActivityNotFoundException`/`SecurityException` capturados. |
| `lib/features/capture/domain/entities/capture_diagnostics.dart`, `capture_background_health.dart` | Entidades puras del diagnóstico y del resultado de la regla. |
| `lib/features/capture/domain/repositories/*` | Contrato de diagnóstico/acciones + preferencias locales (`configuredAt`, `snoozeUntil`). |
| `lib/features/capture/domain/usecases/*` | `GetCaptureBackgroundHealth` (única implementación de la fórmula, con `clock`), `MarkCaptureConfigured`, `SnoozeCaptureBackgroundAlert`, `RequestBatteryOptimizationExemption`, `OpenCaptureAutostartSettings`. |
| `lib/features/capture/data/*` | Datasource de canal extendido y de preferencias, modelo tolerante, repo impl con `_guard`. |
| `lib/features/capture/presentation/cubit/capture_background_*` | Estado + cubit (`start`/`refresh`/`snooze`/`requestBatteryExemption`/`openAutostart`/`confirmActivated`). |
| `lib/features/capture/presentation/widgets/capture_degraded_card.dart`, `capture_degraded_empty_view.dart`, `capture_background_action_row.dart`, `widgets/sheets/capture_background_sheet.dart` | Card (NoticeCard con sub de 3 líneas), vacío contextual (EmptyState + CTA escudo), fila de 64 con estados accionable/cumplido, hoja con botones apilados. |
| `lib/features/capture/presentation/pages/notices_page.dart`, `widgets/captures_section.dart`, `utils/capture_presentation.dart` | Integración en Avisos (card, footer, vacío degradado, apertura de hoja), pie "Última captura" con locale del build y minúscula relativa. |
| `lib/features/improvement/presentation/widgets/notice_card.dart` | `subtitleMaxLines` opcional (default 1, sin mover goldens existentes). |
| `lib/core/router/app_router.dart` | `MultiBlocProvider` en `_noticesRoute()` para arrancar `CaptureBackgroundCubit`. |
| `lib/core/l10n/arb/*.arb` + `gen/*` | Copy exacto del spec en es/en (card, vacío, hoja, filas, pies, label a11y de fila). |
| `lib/core/di/injection.config.dart` | Regenerado con `build_runner`. |
| `test/features/capture/**` | Tests de dominio (tabla de la regla con boundaries 6/7 días), repo/datasource, cubit, card, hoja, página y preferencias; goldens nuevos; tests existentes de Avisos actualizados solo con el provider del cubit (PNG intactos). |

## Tests

- `flutter analyze` → **No issues found**.
- `flutter test` → **6072 passed, 1 skipped** (skip pre-existente ajeno a la feature).
- `flutter test test/features/capture/presentation/golden` → 41 goldens verdes (2 corridas sin `--update`).
- Goldens nuevos (8): `capture_background_card_{light,dark}`, `capture_background_empty_{light,dark}`,
  `capture_background_sheet_{light,dark}`, `capture_background_sheet_battery_done_{light,dark}`.
  Los PNG existentes de Avisos/notice_card no se movieron (verificado por `git status`).
- Regenerados con: `flutter test --update-goldens test/features/capture/presentation/golden/capture_background_golden_test.dart`.
- Kotlin: la compilación en este sandbox falla por el wrapper de Gradle fuera de writable roots;
  la etapa core la verificó con `GRADLE_USER_HOME=./.gradle-dsh` + cache RO y
  `:app:compileDevDebugKotlin` → BUILD SUCCESSFUL (ver notas del core). El guard monotónico del
  fix posterior quedó solo con revisión de diff.
- e2e: **skip** por entorno, no por comodidad: sin device (`adb devices` vacío) y los AVDs viven en
  `/Volumes/Extreme SSD/.android/avd`, fuera de los writable roots del sandbox (el emulador aborta).
  El flujo degradado **sí** es forzable de forma determinista con `_FakeCaptureChannel`
  (`getDiagnostics` con `lastCaptureAtEpochMs=null`, `manufacturer=Xiaomi`, `autostart=true`,
  emisor enabled) + `configuredAt` viejo sembrado; queda como primera tarea del próximo run con device.

## Fidelidad visual vs Pencil

APROBADA en las 3 superficies nuevas (claro + oscuro), verificada por el Lead con acceso real al
`.pen` (los subagentes de esta sesión no exponen tools MCP de Pencil; el Lead usó su cliente stdio
directo). Hallazgos del fix loop, todos corregidos y re-verificados contra los frames:

- IMPORTANTE: CTA del vacío con `arrow-right` → `shield-alert` (frame `krE9G`/`S0iyTP`).
- IMPORTANTE: botones de la hoja en fila → **apilados** full-width, primaria arriba (frame `TPLPN`/`bN2YZ`).
- MENOR: pie con "Hoy" → "hoy" (copy del frame) y formato de fecha según locale del build
  (el helper pre-existente `captureWhenLabel` mantenía `es_CO`; los pies nuevos ahora reciben locale).
- Golden de la hoja ahora se abre por la ruta modal real (scrim + handle) sin botón de scaffold.

Gaps de cobertura: no hay golden a nivel **página** del estado degradado de Avisos (la card y el
footer se cubren con widget tests + goldens de pieza); el resto de Avisos no se re-auditó. Ver
`docs/fidelidad-visual-tracking.md` (fila "Captura").

## 👤 Verifica a mano

- Xiaomi/HyperOS real: con captura configurada y sin exención, "Permitir batería" abre el diálogo de
  no optimizar y "Listo, ya lo activé" re-lee la exención real al volver.
- "Abrir inicio automático" abre la pantalla de autostart de MIUI; en un fabricante sin destino la
  fila 2 no aparece.
- Conceder/revocar acceso a notificaciones desde Ajustes de Android con Avisos en background: al
  volver, la card/vacío desaparece o respeta la precedencia permiso/emisores.
- "Ahora no" oculta la card 14 días sin borrar capturas ni emisores; reinstalar lo resetea.
- Un aviso bancario aceptado actualiza "Última captura" y "Listo" cierra la hoja solo si la batería
  quedó exenta.
- TalkBack: cada fila de la hoja se lee una sola vez (título + sub) y la flecha no se anuncia.

## Pendientes y riesgos

- `lastCaptureAt` no lo limpia la purga de capturas (HU-08): si se cablea a UI, hay que resetearlo
  para no suprimir el estado degradado con un timestamp de algo que el usuario borró.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` es un permiso restringido por Play: la justificación (listener
  central) debe declararse en la ficha y en Data Safety; suma revisión encima del riesgo ya abierto por
  el acceso a notificaciones.
- Sin harness de tests Kotlin: AC2 se garantiza por revisión de código + compilación manual.
- Deuda previa: `captureWhenLabel` sigue usando `es_CO` para las **cards** (los pies nuevos ya reciben
  el locale del build); corregirlo del todo implica pasar locale en las cards y no mueve goldens es.
- Fila de estado en Ajustes (captura) y pantalla dedicada (variante C) quedan fuera de alcance.
- `docs/requirements/fase-2/19-notificaciones-bancarias.md` dice que la app "no promete captura 100%";
  el copy nuevo lo dice explícitamente ("si algo no llega, registralo a mano").

## Mensaje de commit sugerido

```
feat(captura): diagnósticos y superficies de captura en segundo plano (HU-09)

- Diagnóstico nativo en el canal de capture: última captura, exención de
  batería, fabricante y acciones de batería/autostart por OEM con fallbacks.
- Regla de degradación en un único caso de uso (3 días sin nada / 7 días sin
  capturas), snooze de 14 días e idempotencia de la marca de configuración.
- Avisos muestra card y vacío contextual con su hoja de ajustes; el copy
  advierte que la captura no es 100% y que lo que no llegue se registra a mano.
- l10n es/en, tests de dominio/data/cubit/widget/página y goldens claro+oscuro
  aprobados contra Pencil (VW54R/DSCf0, krE9G/S0iyTP, TPLPN/bN2YZ).
- Sin cambios de esquema Drift; fila de Ajustes y pantalla dedicada fuera de
  alcance.
```

## Adición 2026-11-10 — detección inmediata (heartbeat) + fila en Ajustes

Reporte del usuario después de probar: "acabo de configurar captura, recibí una notificación
bancaria y la app no la leyó; tampoco mostró nada, solo 'Todo al día'". Dos causas: (a) el build
de Play probado era 1.0.2, sin esta feature, y (b) incluso con esta feature la heurística de 3/7
días no avisa en el caso recién configurado. Se cerraron las dos.

**Heartbeat del listener (señal directa, no heurística):**

- `CaptureSettings` persiste `last_listener_connected_at_epoch_ms`; el servicio lo escribe en
  `onListenerConnected` (commit) y mantiene `isConnected` en proceso (true al conectar; false en
  `onListenerDisconnected` y `onDestroy`).
- `getDiagnostics` expone `lastListenerConnectedAtEpochMs` (nullable) y `listenerConnectedNow`.
- Regla nueva: `base && (nunca conectó ≥5 min desde configurar || !conectadoAhora con última
  conexión ≥6 h || heurística 3/7 días existente)`. Con MIUI rechazando el bind, `lastListenerConnectedAt`
  queda `null` y el aviso aparece a los pocos minutos, no a los 3 días.
- Tests: tabla de boundaries 4/5/6 min, desconectado 7 h vs 1 h, conectado-ahora con captura
  reciente (manda la heurística), precedencia de permiso/emisores.

**Fila en Ajustes** (`CaptureBackgroundField`, frames `rN8ye`/`lv0iQ`, spec en `pages/ajustes.md`):

- Después de "Avisos de tu banco", con `SettingsField` (nuevo `sublabelColor` opcional), 5 estados:
  normal ("Activa · última captura {día}"), atención (ámbar, "Revisá dos ajustes del sistema"),
  falta activar ("Activa primero los avisos de tu banco"), silenciada ("Silenciada por 14 días") y
  revisando.
- Tap: abre la hoja; si falta permiso/emisores, va al flujo de activación. iOS no la dibuja.
- `CaptureBackgroundState` ahora expone `degraded` y `snoozedUntil` (getters `isSnoozed`/`needsSetup`);
  el cubit los limpia en fallos para no mentir con "Silenciada".
- 8 goldens nuevos de la fila (4 estados × claro/oscuro) + regeneración de los 4 goldens de la
  página Ajustes (la fila queda bajo el viewport, canvas del golden pasa a 2000 de alto).

**Verificación de esta adición:** `flutter analyze` limpio; `flutter test test/features/capture
test/features/settings` → 793 verdes; Kotlin `:app:compileDevDebugKotlin` BUILD SUCCESSFUL (etapa A).

**Pendientes actualizados:** insertar las filas reales en los frames de página de Ajustes
(`aaQBp`/`TQHmY` están desactualizados); simplificar el workaround de `sync_status_page.dart` con
`persist: false`; e2e de Patrol con device (el escenario degradado es forzable con
`_FakeCaptureChannel` + `configuredAt` viejo).

## Adición 2026-11-10 (b) — acceso desde Avisos + fix de navegación de emisores

- **Acceso permanente**: footer `CaptureBackgroundLink` en Avisos (`e7Ab6E`/`uSpAA`), visible en
  todos los estados Android. Abre la hoja si ya está configurado; si falta, rutea al permiso o al
  catálogo según `permissionGranted`. l10n `captureBackgroundLinkLabel`; tests en
  `capture_background_link_test.dart`; goldens de Avisos regenerados (el footer aparece en las 8).
- **Bug reportado**: al conceder el permiso desde el flujo de Avisos y volver, la pantalla de
  emisores reaparecía con todo apagado aunque los cambios estaban guardados. Causa: el flujo
  apilaba **dos** catálogos (Avisos → emisores · permiso → `pushReplacement` → emisores nueva); al
  volver atrás caía en el primero, cuyo cubit había cargado antes del permiso. Fix: cuando el
  permiso se abre **desde** el catálogo, `extra: true` ⇒ al conceder hace `pop()` (no apila otro) y
  `CaptureIssuersPage` re-lee el catálogo al volver (`await onOpenPermission; refresh()`). Tests:
  `capture_issuers_page_test.dart`.

## Adición 2026-11-11 — ingesta en vivo + backfill del reloj de HU-09

Nuevo reporte del usuario con el build de Play 1.1.0: "no escucha y no muestra la nueva entrada".
Diagnóstico y fix en [`fix-captura-ingesta-en-vivo.md`](fix-captura-ingesta-en-vivo.md):

- Una captura recibida con la app **ya abierta** no se ingería hasta reiniciar o abrir Avisos
  (antes solo drenaban `bootstrap` y `NoticesCubit.start()`); ahora el listener nativo manda un
  evento `onCaptureBuffered` y un observador app-wide drena y persiste al instante, con
  `AppLifecycleState.resumed` como red de seguridad.
- `configuredAt` solo lo escribía la pantalla de emisores, que nació con HU-09: las instalaciones
  configuradas con builds anteriores nunca veían la tarjeta/hoja de degradación. Ahora se
  rellena desde evidencia nativa (`lastCaptureAt` → `lastListenerConnectedAt` → ahora) en cada
  lectura de `CaptureBackgroundCubit`.
- El buffer nativo y el rechazo de bind de MIUI/HyperOS no cambian: la app sigue sin poder
  conceder "Inicio automático" ni la exención de batería, solo abrir esas pantallas.

# Fix: el widget de captura rápida en iOS abría "Page Not Found"

**Fecha:** 2026-11-07. **Ámbito:** iOS únicamente. **Capa:** puente nativo.

## El reporte

En iOS, tocar "Ingreso" (o cualquier otro atajo) en el widget de captura rápida abría la app en la pantalla de error de go_router:

```
Page Not Found
GoException: no routes for location:
com.camiloagudelo.billetudo.dev://captura/income
```

El mismo widget funcionaba en Android. No era un problema de layout ni de la
pantalla de captura: la URL del atajo nunca llegaba al puente del widget.

## Causa raíz (verificada, no supuesta)

1. La app adoptó el ciclo de vida **UIScene**: `ios/Runner/Info.plist` declara
   `UIApplicationSceneManifest` con `UISceneDelegateClassName =
   FlutterSceneDelegate` (deployment target 15.0). Con UIScene, iOS entrega los
   URL opens a `scene(_:openURLContexts:)` / `scene(_:willConnectTo:options:)`
   del scene delegate, **nunca** a `AppDelegate.application(_:open:options:)`.
2. El puente del widget estaba cableado justo en ese override de
   `AppDelegate`, así que en iOS nunca se invocó: **nació muerto**. La app ya
   había adoptado UIScene el 2026-07-15 (commit `aba0eb2c`) y el widget se
   cableó el 2026-09-09 (commit `e1a42fb1`), así que ese camino solo podía
   funcionar en Android. El handler Dart (`getInitialShortcut`/`onShortcut`) y
   todo lo que viene después (`CaptureShortcutCubit` →
   `CaptureShortcutListener` → formulario) nunca se enteraba del tap.
3. Flutter 3.38.5 (engine `1527ae0ec5`) reenvía el evento a los
   `FlutterSceneLifeCycleDelegate` registrados por los plugins y, si ninguno
   devuelve `true`, ejecuta su **deep linking por defecto**: manda la URL
   completa a Dart como route information. go_router la interpreta como
   location —`com.camiloagudelo.billetudo.dev://captura/income`, no un path— y
   no encuentra ruta: pantalla de error. El texto del reporte calza exactamente
   con ese camino (la location es la URL entera).
4. `app_links` 7.0.0 (transitiva, la usa Supabase para el callback de OAuth)
   sí registra un scene delegate, pero con `defaultUrlHandling = .never`
   devuelve `false`; no interceptaba nada ni causaba el error. Su stream sí
   recibía la URL del widget, pero Supabase la descarta por no ser un callback
   de auth. Sin efecto en el bug, pero el fix la saca del medio igual.

## El fix

- `ios/Runner/QuickCaptureWidgetBridge.swift`: la clase ahora es
  `NSObject, FlutterSceneLifeCycleDelegate` e implementa
  - `scene(_:willConnectTo:options:)` — arranque en frío, lee
    `connectionOptions.urlContexts`;
  - `scene(_:openURLContexts:)` — app ya viva o en segundo plano.
  Ambos delegan en el `handle(url:)` que ya existía: el evento cae en el mismo
  canal (`getInitialShortcut`/`onShortcut`) y en la misma cola frío/caliente
  que Android. Se devuelve `true` **solo** cuando el host es `captura`, así
  Flutter no hace su deep linking por defecto y las URLs ajenas (callback de
  Google Sign-In) siguen su camino de siempre.
- `ios/Runner/AppDelegate.swift`: registra el puente con
  `registrar.addSceneDelegate(...)` dentro de `didInitializeImplicitFlutterEngine`,
  **antes** de `GeneratedPluginRegistrant.register` (el engine llama a los
  scene delegates en orden de registro y corta en el primero que devuelve
  `true`; ir primero evita que la URL del widget llegue a `app_links`). Se
  eliminó el override muerto `application(_:open:options:)`.
- `shortcutId(from:)` quedó como helper puro, testeable sin canal ni escena.
- Comentarios desactualizados de `lib/core/di/register_module.dart` y
  `lib/features/capture/data/datasources/capture_shortcut_channel_datasource.dart`
  corregidos: ya no dicen que el lado iOS vive en `AppDelegate`.

## Verificación real (simulador, no solo lectura de código)

Build: `flutter build ios --simulator --debug --flavor dev --dart-define-from-file=.env.dev`
→ OK. Instalado en el iPhone 17 con iOS 26.5 que ya estaba usando el reporte
(`com.camiloagudelo.billetudo.dev`). El mismo camino que dispara el widget
(URL scheme → scene delegate) se puede reproducir con
`xcrun simctl openurl booted "<url>"`, así que se comparó antes/después con ese
comando.

**Antes del fix** (build instalado previo al cambio):

```
xcrun simctl openurl booted "com.camiloagudelo.billetudo.dev://captura/income"
→ Page Not Found + GoException: no routes for location: ...://captura/income
```

**Después del fix** (build recién compilado e instalado):

| Caso | Comando | Resultado observado |
|---|---|---|
| Caliente (app en Inicio) | `openurl ...://captura/income` | formulario "Nuevo ingreso" con `type = income` ✓ |
| Frío (app terminada) | `terminate` + `openurl ...://captura/expense` | arranque directo en "Nuevo gasto" ✓ |
| Id desconocido en frío | `terminate` + `openurl ...://captura/bank_inbox` | abre en Inicio, sin pantalla de error ✓ |

El caso frío confirma el orden implícito del engine:
`didInitializeImplicitFlutterEngine` (registro del scene delegate) corre antes
de que se despache `scene(_:willConnectTo:options:)`, por eso la URL de
arranque también se intercepta.

**Límite de esta verificación:** `simctl openurl` no toca la superficie del
widget real, así que no cubre el tap sobre la extensión WidgetKit. El widget
real hay que probarlo a mano en un dispositivo/simulador agregándolo a la
pantalla de inicio (en su momento el widget sí abría la app: el bug era que la
app abría en la pantalla equivocada). Tampoco se pueden automatizar los
destinos Voz (hoja de dictado, pide micrófono) ni la configuración del widget.

## Tests

- **Nuevo:** `ios/RunnerTests/RunnerTests.swift` cubre el contrato de URL del
  puente: `expense`/`income`/`voice` parsean, host o esquema ajenos se rechazan
  (para no romper Google Sign-In), un id desconocido se consume sin navegar y
  nunca se reporta como error. Ese archivo era el placeholder vacío del
  template; no se agregó ningún target.
- **Cómo correrlos:** el target `RunnerUITests` del proyecto está roto de
  fábrica (producto `.xctest` sin nombre, `PRODUCT_NAME` vacío), así que
  `xcodebuild test -scheme dev` (o `Runner`) muere antes de ejecutar un solo
  test: `Multiple commands produce .../-Runner.app/PlugIns/.xctest`. Para este
  fix se verificó con un **scheme temporal** que contiene solo `RunnerTests` +
  `Runner` (creado y borrado para la verificación; no queda en el repo):

  ```
  xcodebuild test-without-building -workspace Runner.xcworkspace \
    -scheme runner-tests-only -only-testing:RunnerTests \
    -destination 'platform=iOS Simulator,id=<iPhone 17>'
  → 4 tests, 4 passed (RunnerTests)
  ```

  Arreglar `RunnerUITests` queda fuera de alcance de este fix.
- **Dart:** `flutter test test/features/capture/` → 460 tests en verde (el
  camino Dart del atajo no se tocó). `flutter analyze lib/` → ningún issue en
  los archivos de este cambio; queda **un warning preexistente**
  (`_chipMaxWidth` sin usar en `ai_card_chips.dart`) que es trabajo en curso
  del dueño del repo, igual que los errores preexistentes que `flutter analyze`
  reporta en `test/features/transactions/...`.

## Observación preexistente (fuera de alcance)

`google_sign_in_ios` 6.3.0 registra un scene delegate e implementa
`- (void)scene:openURLContexts:`, mientras que el protocolo del engine declara
ese método como `BOOL`. El engine lee un valor de retorno indefinido. No lo
introduce ni lo empeora este fix (las URLs de Google no tienen host `captura`,
así que siguen exactamente el mismo camino que antes), pero conviene tenerlo
presente si alguna vez se investiga un fallo de login con Google en iOS.

## Pendiente / siguiente paso sugerido

- Tap real del widget en dispositivo (ver "límite de esta verificación").
- Si se quiere blindar la regla "un tap del widget nunca termina en error"
  contra futuros deep links mal formados, un `onException`/`errorBuilder` en
  `createAppRouter` que degrade a Inicio en vez de mostrar la pantalla de
  `GoException` sería el siguiente paso. No se incluyó acá para no cambiar el
  comportamiento global del router en un fix de causa raíz.

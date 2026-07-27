# Billetudo

App de finanzas personales **local-first** construida en Flutter, para el mercado hispanohablante.

> Enfoque: construida primero para uso propio, con arquitectura pensada para escalar a un producto freemium para el mercado hispanohablante. Toda la investigación de mercado y el plan de producto/monetización están en [`docs/`](docs/).

## Decisiones de arquitectura

| Área | Decisión | Nota |
|---|---|---|
| Estado | **bloc / cubit** (`flutter_bloc`) | Estado explícito y testeable |
| BD local | **Drift** (SQLite) | **Fuente de verdad, offline-first**. Dinero en enteros (centavos); IDs UUID |
| Sync / respaldo | **PowerSync** ↔ **Supabase** (Postgres) | Bidireccional, sin pérdida de datos, desde el día 1 |
| Auth | Solo social: **Android → Google**; **iOS → Google + Apple** | Local-first: login diferido (usar sin cuenta, iniciar sesión luego para respaldar) |
| Gráficas | **fl_chart** | Set esencial gratis; avanzadas tras Modo anuncios / Premium |
| Monetización | **google_mobile_ads** (rewarded) + **RevenueCat** | Nivel 0 gratis completo; extras con anuncio opt-in o suscripción |
| Captura | **speech_to_text** + **google_mlkit** (OCR) + notificaciones (Android) | IA barata detrás de backend; nunca API keys en la app |
| Config remota | Tabla `remote_config` en Supabase + Realtime | Equivalente a Firebase Remote Config |

Detalle completo (niveles de acceso, límites, precios, riesgos legales) en [`docs/Plan_Monetizacion_y_Tecnico.md`](docs/Plan_Monetizacion_y_Tecnico.md).

## Estructura

```
lib/
├── core/
│   ├── database/        # Drift: app_database.dart (esquema completo)
│   ├── sync/            # Integración PowerSync + Supabase
│   ├── config/          # Remote config (límites/cupos)
│   ├── di/              # Inyección de dependencias
│   ├── theme/           # Tema / modo oscuro
│   ├── l10n/            # i18n (es/en)
│   └── utils/
└── features/            # Feature-first (data/domain/presentation por feature)
    ├── auth/            accounts/     transactions/  categories/
    ├── budgets/         goals/        debts/         reports/
    ├── improvement/     # ritual semanal, safe-to-spend, rachas, retos
    ├── capture/         # voz, OCR, notificaciones bancarias
    └── settings/        # incl. borrado de cuenta (obligatorio Apple/Google)
```

## Estado actual

Ya incluido:
- Documentación de investigación y plan (`docs/`).
- Esquema de datos Drift completo: [`lib/core/database/app_database.dart`](lib/core/database/app_database.dart) (9 tablas, UUIDs, timestamps de sync, borrado lógico, dinero en centavos).
- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`.
- Estructura de carpetas (con `.gitkeep`).

Pendiente (configuración técnica — a tu cargo):
- `flutter create .` para generar plataformas (android/ios/…).
- `dart run build_runner build` para generar `app_database.g.dart`.
- Wiring de PowerSync sobre la BD de Drift + proyecto Supabase (schema espejo).
- Claves/entornos (Supabase, RevenueCat, AdMob, LLM) fuera del repo (`.env`).
- `claude init`.

### Flavors (dev / prod)

Cada ambiente apunta a su propio proyecto Supabase / Google OAuth client (Google Cloud no permite
dos Android OAuth clients con el mismo par package+SHA-1), así que además de `--dart-define-from-file`
la app corre en flavors nativos separados — se pueden tener ambas builds instaladas a la vez en el
mismo teléfono. `prod` mantiene el `applicationId`/bundle id actual (`com.billetudo.app`);
`dev` usa el sufijo `.dev` y se ve en el teléfono como "Billetudo Dev".

```bash
# Android
flutter run --flavor dev --dart-define-from-file=.env.dev
flutter run --flavor prod --dart-define-from-file=.env.prod
flutter build apk --flavor dev --dart-define-from-file=.env.dev
flutter build apk --flavor prod --dart-define-from-file=.env.prod

# iOS (usa los Xcode schemes `dev` / `prod`, ver ios/Runner.xcodeproj/xcshareddata/xcschemes/)
flutter run --flavor dev --dart-define-from-file=.env.dev
flutter run --flavor prod --dart-define-from-file=.env.prod
```

### Publicar a Play Store (appbundle de release)

Usa el script — hornea los dos flags que es fácil olvidar (`flutter build` **no**
hereda los `--dart-define-from-file` de `launch.json`, y hay que limpiar el
plugin registrant de dev-deps antes):

```bash
./scripts/build-release-android.sh
```

Genera `build/app/outputs/bundle/prodRelease/app-prod-release.aab`, firmado con
la upload key (`android/key.properties`). Equivale a:

```bash
flutter pub get   # regenera GeneratedPluginRegistrant.java sin patrol/integration_test
flutter build appbundle --flavor prod --release --dart-define-from-file=.env.prod
```

> **Si falta `--dart-define-from-file=.env.prod`**, `SUPABASE_URL`/`POWERSYNC_URL`
> quedan vacíos y la app abre directo el gate offline ("Conéctate para
> continuar") aunque haya internet. `flutter run` lo pasa vía `launch.json`;
> `flutter build` no — por eso el script lo fija.
>
> Antes de cada subida a Play, **sube el `versionCode`** en `pubspec.yaml`
> (`version: x.y.z+N` — el `+N` es el `versionCode`); Play rechaza un `.aab` con
> uno ya publicado. Y registra en el OAuth client Android la **SHA-1 de la app
> signing key de Google** (Play Console → Integridad de la app), o el login con
> Google falla en la build de la tienda.

### Publicar a App Store (IPA de release)

```bash
./scripts/build-release-ios.sh
```

Genera `build/ios/ipa/*.ipa` para subir con Transporter o el Organizer de Xcode.
Equivale a `flutter build ipa --flavor prod --release --dart-define-from-file=.env.prod`.

> **Trampa iOS:** `ios/Flutter/Generated.xcconfig` es autogenerado y refleja los
> `DART_DEFINES` del último comando `flutter`. Si archivas desde Xcode
> (Product → Archive) sin correr el build del CLI antes, el archive sale con env
> viejo/vacío → mismo gate offline, sin aviso. Compila siempre por el CLI; si
> necesitas archivar desde Xcode, corre primero
> `flutter build ipa --config-only --flavor prod --release --dart-define-from-file=.env.prod`.
>
> El `CFBundleVersion` sale del `version: x.y.z+N` de `pubspec.yaml` — súbelo en
> cada envío igual que el `versionCode` de Android.

## Generar el código de Drift

```bash
flutter pub get
dart run build_runner build --force-jit
```

> `--force-jit` es obligatorio, no un plan B. Sin él el build siempre falla con
> "Failed to compile build script": `build_runner` precompila su script de
> arranque con `dart compile`, que en Dart 3.10.4 no soporta *build hooks*, y
> tres dependencias los traen por sus assets nativos (`sqlite3`, `powersync`,
> `objective_c`). El fallback automático a JIT que documenta `build_runner` no
> se dispara acá, así que hay que pedirlo explícito. El modo JIT genera lo mismo
> y sigue siendo incremental.
>
> `--delete-conflicting-outputs` ya no existe: `build_runner` 2.15 lo removió y
> lo ignora con un warning.

## Verificar el código

```bash
flutter analyze        # lints oficiales
flutter test
```

Tres reglas propias de widgets/UI (funciones que devuelven `Widget`, widgets privados, strings sin localizar) ya no corren como plugin del analyzer — las revisa el subagente `ui-convention-reviewer` después de cada cambio en `lib/`. Ver [`docs/convenciones-de-codigo.md`](docs/convenciones-de-codigo.md).

## Documentación

- [`docs/convenciones-de-codigo.md`](docs/convenciones-de-codigo.md) — cómo se escribe código aquí: widgets, localización, nombres, estado, manejo de errores y las reglas de lint propias. **Léelo antes del primer PR.**
- [`docs/Viabilidad_App_Finanzas_Personales.md`](docs/Viabilidad_App_Finanzas_Personales.md) — investigación de mercado, competidores y diferenciadores.
- [`docs/Plan_Monetizacion_y_Tecnico.md`](docs/Plan_Monetizacion_y_Tecnico.md) — niveles de acceso, features por costo marginal, capa de mejora financiera, límites, precios, stack, roadmap, riesgos legales.

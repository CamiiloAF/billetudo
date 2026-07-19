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
mismo teléfono. `prod` mantiene el `applicationId`/bundle id actual (`com.camiloagudelo.billetudo`);
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

## Generar el código de Drift

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

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

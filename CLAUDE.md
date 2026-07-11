# CLAUDE.md

Guía para trabajar en este repositorio. Léela antes de proponer o escribir código.

## Qué es este proyecto

App de finanzas personales **local-first** en Flutter, para el mercado hispanohablante. Se construye primero para uso propio y luego como producto freemium. La investigación de mercado y el plan completo están en [`docs/`](docs/) — consúltalos antes de decisiones de producto o monetización.

Objetivo diferenciador: dar el cambio de hábito de YNAB **sin su fricción ni su barrera de precio**, con una capa gratuita completa y captura de gastos de baja fricción en español.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera *.g.dart de Drift
flutter analyze
flutter test
flutter run
```

Tras cambiar cualquier tabla o `@DriftDatabase`, **regenera** con build_runner.

## Arquitectura y decisiones (no cambiar sin justificación)

- **Estado:** bloc / cubit (`flutter_bloc`). Estado explícito, testeable. No mezclar otros gestores de estado.
- **BD local:** Drift (SQLite) es la **fuente de verdad, offline-first**. La app debe funcionar sin conexión.
- **Sync/nube:** PowerSync ↔ Supabase (Postgres). Bidireccional, sin pérdida de datos. Local-first: el usuario usa la app sin cuenta; el login se ofrece después y **fusiona** los datos locales.
- **Auth:** solo social. Android → solo Google. iOS → Google + Sign in with Apple (requisito Apple 4.8). Nunca email/contraseña.
- **Gráficas:** fl_chart. Set esencial gratis; avanzadas tras Modo anuncios o Premium.
- **Monetización:** Nivel 0 gratis y completo, sin anuncios. Extras (IA, gráficas avanzadas) se desbloquean con **rewarded ads opt-in** (con cupo mensual) o **Premium** (RevenueCat). **Prohibido** banners e interstitials ambientales.
- **IA:** modelos económicos detrás de un backend (Supabase Edge Functions). La app **nunca** contiene API keys ni llama al LLM directo.

## Convenciones de código (críticas)

- **Dinero: SIEMPRE enteros en unidades menores (centavos).** Nunca `double`/`float` para montos. Ej: `$12.34` → `1234` (`amountMinor`).
- **IDs: UUID en texto** (`clientDefault` en Drift). Nunca autoincrement — rompería el sync y la fusión de datos offline.
- **Timestamps:** actualizar `updatedAt` en cada escritura (en el repositorio).
- **Borrado:** `deletedAt` es solo para papelera/undo de UX; PowerSync sincroniza los DELETE reales por su cuenta.
- **Comillas simples**, comas finales, tipos de retorno explícitos (ver `analysis_options.yaml`).
- Estructura **feature-first + Clean Architecture completa**: cada feature en `lib/features/<feature>/` con tres capas estrictas y dependencias apuntando siempre hacia adentro (`presentation` → `domain` ← `data`; `data` nunca es importado por `domain`):
  - `domain/`: entidades puras (sin Drift ni Supabase), interfaces de repositorio (`abstract class XRepository`), y **un caso de uso por acción de negocio** (`class GetAccounts`, `class CreateTransaction`, clases con un método `call()`), incluso para operaciones simples. Aquí vive toda la lógica de negocio (validaciones, cálculos como safe-to-spend, rollover de presupuesto).
  - `data/`: modelos/DTOs, datasources (DAOs de Drift, llamadas a Supabase/PowerSync) e implementación concreta de los repositorios de `domain` (`class XRepositoryImpl implements XRepository`). Mapea entre modelos de Drift y entidades de dominio — nunca expongas tipos generados de Drift fuera de esta capa.
  - `presentation/`: bloc/cubit que orquestan casos de uso (nunca repositorios ni DAOs directo), páginas y widgets. El bloc depende de `domain`, jamás de `data`.
  - Inyección de dependencias (`lib/core/di/`) es quien conecta `data` → `domain` → `presentation` en cada feature.
  Código transversal (DB, sync, config, theme, l10n, utils) en `lib/core/`.

## Reglas de negocio que el código debe respetar

- Los **límites y cupos** se cuentan y validan **en el servidor** (Supabase), nunca solo en el cliente.
- Las recompensas por anuncio se verifican con **AdMob SSV** antes de conceder acceso.
- Ninguna feature del **Nivel 0** puede quedar detrás de anuncio o pago (registro manual, presupuestos, categorías, metas, deudas, gráficas esenciales, import/export, captura local).
- Tono de la app: positivo y de progreso. **Nunca** avergonzar al usuario por sus gastos.

## Requisitos legales (no omitir)

- **Borrado de cuenta dentro de la app** (obligatorio Apple + Google): debe borrar datos en Supabase, no solo cerrar sesión.
- Política de privacidad y cumplimiento de leyes de datos por país (LGPD, Ley 1581, LFPDPPP, RGPD).
- Disclaimer "no es asesoría financiera" en features de IA/coach.
- Riesgo: la lectura de notificaciones bancarias (Android) está restringida por Google Play — no depender solo de ella; mantener voz/OCR como alternativa.

## Esquema de datos (Drift)

Definido en `lib/core/database/app_database.dart`. Todas las tablas usan el mixin `_SyncColumns` (`id` UUID, `createdAt`, `updatedAt`, `deletedAt`). Tablas: `Accounts`, `Categories` (jerárquica vía `parentId`), `Transactions` (income/expense/transfer; `source` distingue captura manual vs. IA para medir cupos), `Budgets`, `Goals`, `Debts`, `Recurrings`, `Tags`, `TransactionTags` (N:N). Los enums (`AccountType`, `EntryType`, `CategoryKind`, `TxSource`, `BudgetPeriod`, `DebtDirection`, `RecurFrequency`) se guardan como texto para tener paridad con Postgres. Al añadir o modificar una tabla, sube `schemaVersion` en `AppDatabase` y regenera con build_runner.

## Subagentes, skills y workflows del repo

Definidos en `.claude/` para automatizar las convenciones de este documento:

- **Subagentes** (`.claude/agents/`): `architect` (triage y change map, solo lectura), `flutter-dev` (implementa features respetando las convenciones), `qa-automator` (dueno del testing: unit/widget/Patrol e2e; solo escribe en `test/` e `integration_test/`), `feature-scaffolder` (boilerplate Clean Architecture), `drift-migration-helper` (cambios seguros al esquema Drift), `finance-code-reviewer` (convenciones de codigo), `compliance-reviewer` (reglas de Nivel 0/legales).
- **Skills**: `/feature-dev <descripcion>` (feature completa en una corrida), `/new-feature <nombre>`, `/drift-schema-change <descripcion>`, `/tier0-check [ruta]`.
- **Workflows** (`.claude/workflows/`): `feature-dev` (el principal: triage automatico s/m/l → build → tests → review escalado → un unico resumen en `docs/dev-runs/<slug>.md`, sin commitear), `feature-scaffold` (solo boilerplate capa por capa) y `feature-review` (revision multi-dimension con verificacion adversarial; `feature-dev` lo reusa como review profundo en tamano L) — se invocan explicitamente, no por defecto.

## Estado del repo

Ya existe: esquema Drift (`lib/core/database/app_database.dart`), docs, pubspec, estructura de carpetas.
`app_database.g.dart` **aún no está generado** — corre build_runner antes de referenciar `AppDatabase` o cualquier tabla generada. Las carpetas de `lib/core/*` y `lib/features/*` solo tienen `.gitkeep`: no hay código de features, DI, sync, ni tests todavía — es lienzo en blanco, no derives estructura por analogía a otro proyecto Flutter.
Falta (config técnica): `flutter create .`, build_runner, wiring PowerSync+Supabase, entornos/claves. Ver README.

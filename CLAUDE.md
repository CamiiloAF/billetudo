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

## Diseño / UI (Pencil)

Toda decisión de UI se toma contra un sistema de diseño ya establecido. **Antes de diseñar, construir o revisar cualquier pantalla, carga los lineamientos — no los repita el usuario ni los deduzcas del código.**

- **Fuente de verdad real:** `billetudo.pen` (Pencil). Las 18 variables de color (tema claro/oscuro), tipografía y componentes reutilizables viven ahí. **Nunca hardcodear un hex** — usar siempre la variable (`get_variables`).
- **Reglas escritas:** `design-system/finance-app/MASTER.md` (reglas globales: paleta, tipografía, radios/espaciado, componentes, accesibilidad, tono de marca) + `design-system/finance-app/pages/<pantalla>.md` (overrides por pantalla).
- **Orden de lectura:** `pages/<pantalla>.md` (si existe, sus reglas sobreescriben) → `MASTER.md` → si el `.md` y el `.pen` difieren, **manda `billetudo.pen`** y se corrige el `.md`.
- **Flujo por feature (diseño primero, spec después):**
  1. `pencil-designer` propone 2-3 variantes visuales de la pantalla directamente en `billetudo.pen`, **solo en tema claro**, contra `MASTER.md` (aún no existe `pages/<feature>.md` en este punto).
  2. El usuario evalúa y elige una variante; las descartadas se borran del canvas de inmediato (no se dejan a medias).
  3. Se documenta la decisión elegida en `design-system/finance-app/pages/<feature>.md` (spec por pantalla, overrides sobre `MASTER.md`).
  4. Se refina el diseño base (tema claro) contra ese spec, auditado por `ui-ux-reviewer`, hasta que el usuario apruebe explícitamente que cumple todas las expectativas y estándares del sistema de diseño.
  5. Solo con el tema claro 100% aprobado se crean las variantes de estado (error, vacío, carga, etc.), también en tema claro primero.
  6. Al final, y solo al final, se genera el tema oscuro — componentizando antes lo repetido en vez de duplicar estructura.
  7. Con todas las variantes y ambos temas cerrados, pasa a `flutter-dev` para implementar.
- **Identidad:** color de marca violeta (`primary #6C5CE7`), fuente Plus Jakarta Sans, estética limpia/minimalista, soporte completo claro/oscuro. Tono positivo, nunca punitivo con el gasto.
- El `get_guidelines` nativo de Pencil solo ofrece guías/estilos genéricos — **no** contiene este sistema de diseño. Los lineamientos del proyecto son los `.md` de arriba + las variables del `.pen`.

## Subagentes, skills y workflows del repo

Definidos en `.claude/` para automatizar las convenciones de este documento:

- **Subagentes** (`.claude/agents/`): `architect` (triage y change map, solo lectura), `flutter-dev` (implementa features respetando las convenciones), `qa-automator` (dueno del testing: unit/widget/Patrol e2e; solo escribe en `test/` e `integration_test/`), `feature-scaffolder` (boilerplate Clean Architecture), `drift-migration-helper` (cambios seguros al esquema Drift), `finance-code-reviewer` (convenciones de codigo), `compliance-reviewer` (reglas de Nivel 0/legales), `pencil-designer` (construye/edita pantallas en `billetudo.pen` contra el sistema de diseno; carga MASTER.md + `pages/<feature>.md` antes de dibujar, usa componentes `reusable:true` y variables `$token`), `ui-ux-reviewer` (audita pantallas en `billetudo.pen`/Pencil: jerarquia, accesibilidad, consistencia con el sistema de disenio y tono de marca; anota el canvas y reporta).
- **Skills**: `/feature-dev <descripcion>` (feature completa en una corrida), `/new-feature <nombre>`, `/drift-schema-change <descripcion>`, `/tier0-check [ruta]`.
- **Workflows** (`.claude/workflows/`): `feature-dev` (el principal: triage automatico s/m/l → build → tests → review escalado → un unico resumen en `docs/dev-runs/<slug>.md`, sin commitear), `feature-scaffold` (solo boilerplate capa por capa) y `feature-review` (revision multi-dimension con verificacion adversarial; `feature-dev` lo reusa como review profundo en tamano L) — se invocan explicitamente, no por defecto.

## Estado del repo

Ya existe: esquema Drift (`lib/core/database/app_database.dart`), docs, pubspec, estructura de carpetas.
`app_database.g.dart` **aún no está generado** — corre build_runner antes de referenciar `AppDatabase` o cualquier tabla generada. Las carpetas de `lib/core/*` y `lib/features/*` solo tienen `.gitkeep`: no hay código de features, DI, sync, ni tests todavía — es lienzo en blanco, no derives estructura por analogía a otro proyecto Flutter.
Falta (config técnica): `flutter create .`, build_runner, wiring PowerSync+Supabase, entornos/claves. Ver README.

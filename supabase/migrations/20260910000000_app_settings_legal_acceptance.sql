-- schemaVersion 35 (Drift): `AppSettings.legalAcceptedAt`/`legalAcceptedVersion`
-- back the onboarding "acceptance of terms" gate — see
-- `lib/core/database/app_database.dart` and `powersync_schema.dart`. No
-- backfill on purpose: a row that predates this column has no
-- `legal_accepted_version`, which the app treats the same as "never
-- accepted" (see the Drift column doc comment).
--
-- bigint en segundos unix, NUNCA timestamptz: app_settings es una tabla
-- sincronizada y Drift la lee a traves de una vista de PowerSync donde cada
-- columna es un CAST(json_extract(...) AS <tipo>). Un timestamptz llega como
-- texto y CAST('2026-08-25...' AS INTEGER) da 2026 en silencio. Mismo patron
-- exacto que `ai_consent_accepted_at` (`20260825130000_app_settings_ai_consent
-- .sql`) y `powersync_schema.dart`, que declara ambas columnas como
-- `Column.integer(...)`.
--
-- `if not exists` follows the same pattern as the other `app_settings`
-- additive migrations in this folder (e.g. `onboarding_completed`,
-- `ai_consent_version`).
alter table public.app_settings
  add column if not exists legal_accepted_at bigint,
  add column if not exists legal_accepted_version bigint;

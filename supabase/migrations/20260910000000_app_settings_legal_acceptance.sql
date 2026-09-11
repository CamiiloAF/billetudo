-- schemaVersion 35 (Drift): `AppSettings.legalAcceptedAt`/`legalAcceptedVersion`
-- back the onboarding "acceptance of terms" gate — see
-- `lib/core/database/app_database.dart` and `powersync_schema.dart`. No
-- backfill on purpose: a row that predates this column has no
-- `legal_accepted_version`, which the app treats the same as "never
-- accepted" (see the Drift column doc comment).
--
-- `if not exists` follows the same pattern as the other `app_settings`
-- additive migrations in this folder (e.g. `onboarding_completed`,
-- `ai_consent_version`).
alter table public.app_settings
  add column if not exists legal_accepted_at timestamptz,
  add column if not exists legal_accepted_version integer;

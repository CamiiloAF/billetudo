-- `13-onboarding.md`: latch nuevo que marca si el flujo de bienvenida ya
-- corrió y se cerró para siempre (mismo patrón que `categories_seeded`).
--
-- `if not exists` porque ya se aplicó manualmente contra dev y prod vía MCP
-- durante el desarrollo de la feature — este archivo deja el cambio
-- versionado junto al snapshot de `test/core/database/fixtures/postgres_schema.json`,
-- como exige el comentario de `tool/check_schema_parity.dart`.
alter table public.app_settings
  add column if not exists onboarding_completed boolean not null default false;

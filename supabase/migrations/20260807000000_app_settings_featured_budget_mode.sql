-- `featuredBudgetMode` (schemaVersion 26, `app_database.dart`): estado
-- explícito de tercer valor para el presupuesto destacado del hero de Home
-- (`automatic` / `manual` / `none`) — antes solo existía `featured_budget_id`,
-- que no distinguía "sin destacado, sin fallback automático" de "fallback
-- automático".
--
-- `if not exists` porque ya se aplicó manualmente contra dev y prod vía MCP
-- durante el desarrollo de la feature (igual que `featured_budget_id`, que
-- tampoco tiene migración versionada) — este archivo deja el cambio
-- versionado junto al snapshot de
-- `test/core/database/fixtures/postgres_schema.json`, como exige el
-- comentario de `tool/check_schema_parity.dart`.
alter table public.app_settings
  add column if not exists featured_budget_mode text not null default 'automatic';

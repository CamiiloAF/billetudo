-- schemaVersion 32 (asistente financiero con IA, Fase A): versión del
-- consentimiento aceptado + interruptor de "dejar que el asistente lea mis
-- notas".
--
-- Estas dos columnas ya viven en el código (lib/core/database/app_database.dart
-- AppSettings.aiConsentVersion / aiNotesAccessEnabled, y
-- lib/core/database/powersync_schema.dart) y ya fueron aplicadas a mano sobre
-- las bases de dev y prod en su momento — esta migración solo deja el rastro
-- en el historial para que `supabase db reset`/un entorno nuevo reproduzcan
-- el mismo esquema. `add column if not exists` la vuelve un no-op segura
-- sobre una base que ya las tiene.
--
-- ai_consent_version: bigint, nullable. NUNCA se hace backfill — ver el
-- razonamiento de aiConsentVersion en app_database.dart y la migración
-- hermana 20260825130000_app_settings_ai_consent.sql (ai_consent_accepted_at).
--
-- ai_notes_access_enabled: boolean not null default false — este SÍ se
-- backfillea (a `false`) en la migración de Drift `from < 32`, porque no
-- enviar tus notas a la IA es una decisión segura por defecto para cualquier
-- fila preexistente, a diferencia del consentimiento general.
--
-- Paridad explícita con lib/core/database/app_database.dart y
-- lib/core/database/powersync_schema.dart: subir schemaVersion en Drift no
-- migra Postgres, y sin este ALTER TABLE el conector de PowerSync responde
-- PGRST204 y la cola de subida queda quarantined para todas las tablas del
-- usuario.
alter table public.app_settings
  add column if not exists ai_consent_version bigint,
  add column if not exists ai_notes_access_enabled boolean not null default false;

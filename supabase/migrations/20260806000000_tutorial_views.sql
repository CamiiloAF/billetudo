-- schemaVersion 24: ayuda contextual permanente (minitutoriales,
-- docs/requirements/fase-1/16-minitutoriales.md). Dos piezas:
--
-- 1. `tutorial_views` — una fila por clave de tutorial que el usuario ya
--    vio (`TutorialViews` en app_database.dart). `id` NO es un UUID
--    aleatorio: es la clave estable del tutorial (ej. 'budgets_screen',
--    'debt_link_movement'), repetida entre usuarios. Por eso la PK es
--    compuesta `(id, user_id)`, nunca `id` solo — es exactamente el patrón
--    ya usado en `categories` para el mismo problema (categorías semilla,
--    decisión #19 de `05-auth-sync.md`, que costó una cuarentena de sync
--    en producción por usar `id` como PK única con una clave no-UUID).
--    Sin trash flow propio (una fila existe o no existe, no hay estado
--    intermedio) pero se mantienen `deleted_at`/`tombstoned_at` por
--    consistencia con el resto de tablas `_SyncColumns` — sin uso real hoy.
--
-- 2. `app_settings.show_help_on_section_entry` — ajuste on/off de Ajustes
--    (encendido por defecto). Mismo patrón que `onboarding_completed`
--    (migración `20260729000000`): `boolean not null default true`.
create table if not exists public.tutorial_views (
  id            text not null,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid not null references auth.users (id) on delete cascade,
  primary key (id, user_id)
);

alter table public.tutorial_views add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.tutorial_views add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.tutorial_views add column if not exists deleted_at bigint;
alter table public.tutorial_views add column if not exists tombstoned_at bigint;

create index if not exists tutorial_views_user_id_idx on public.tutorial_views (user_id);

alter table public.tutorial_views enable row level security;
drop policy if exists "Users manage own rows" on public.tutorial_views;
create policy "Users manage own rows" on public.tutorial_views
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

alter table public.app_settings
  add column if not exists show_help_on_section_entry boolean not null default true;

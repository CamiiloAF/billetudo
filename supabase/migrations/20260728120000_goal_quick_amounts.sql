-- schemaVersion 20 (Metas): chips de "aporte rápido" definidos por el usuario
-- en una meta.
--
-- **Detectada por el guardrail, no por un usuario.** El test de paridad
-- (`test/core/database/schema_parity_test.dart`) la marcó en rojo el mismo día
-- en que la tabla se agregó a `powersync_schema.dart`, con el mensaje:
--
--   These tables are declared in lib/core/database/powersync_schema.dart
--   but do NOT exist in Postgres: goal_quick_amounts.
--
-- Existía en dev y faltaba en prod: el patrón exacto de la decisión #22 en
-- `docs/requirements/fase-1/05-auth-sync.md`, que bloqueó la cola FIFO de subida
-- durante 3 días y costó 89 registros irrecuperables. Sin el test, esta tabla
-- habría llegado a producción y el primer usuario que creara un aporte rápido
-- habría trabado su sincronización entera.
--
-- Sin trash flow propio — igual que `tags`/`transaction_tags` — así que
-- `deleted_at` y `tombstoned_at` van sin usar; el borrado es un DELETE real.
--
-- Epoch SECONDS en bigint; `updated_at` en MILLIs. Nunca `timestamptz` en una
-- tabla sincronizada (ver el comentario de tipos en `powersync_schema.dart`).
create table if not exists public.goal_quick_amounts (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id),
  goal_id       text not null references public.goals (id),
  amount_minor  bigint not null
);

alter table public.goal_quick_amounts enable row level security;

drop policy if exists "Users manage own rows" on public.goal_quick_amounts;
create policy "Users manage own rows" on public.goal_quick_amounts
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

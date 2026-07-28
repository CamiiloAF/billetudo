-- schemaVersion 19 (commit 9aabe98, 2026-07-28): rediseño de Metas
-- (tablero de aspiraciones con momentum).
--
-- Todos los timestamps son epoch SECONDS en bigint; `updated_at` es MILLIs.
-- Nunca timestamptz: ver el comentario de tipos en
-- lib/core/database/powersync_schema.dart.

alter table public.goals add column if not exists completed_at bigint;
alter table public.goals add column if not exists archived_at bigint;
alter table public.goals add column if not exists last_milestone_pct integer;

-- El monto ahorrado de una meta pasa a ser DERIVADO: se suma este ledger.
-- `goals.saved_minor` queda huérfana pero se conserva (default 0) para no
-- romper a los clientes viejos que todavía la escriben.
create table if not exists public.goal_contributions (
  id             text primary key,
  created_at     bigint not null default (extract(epoch from now()))::bigint,
  updated_at     bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at     bigint,
  tombstoned_at  bigint,
  user_id        uuid references auth.users (id) on delete cascade,
  goal_id        text not null references public.goals (id) on delete cascade,
  amount_minor   bigint not null,
  direction      text not null,
  date           bigint not null,
  -- Soft FK a la transacción que este movimiento espeja, cuando movió plata
  -- real. Sin constraint a propósito: la transacción puede borrarse y el
  -- movimiento de tracking debe sobrevivir.
  transaction_id text,
  note           text
);

alter table public.goal_contributions enable row level security;

drop policy if exists "Users manage own rows" on public.goal_contributions;
create policy "Users manage own rows" on public.goal_contributions
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create index if not exists goal_contributions_goal_id_idx on public.goal_contributions (goal_id);
create index if not exists goal_contributions_user_id_idx on public.goal_contributions (user_id);

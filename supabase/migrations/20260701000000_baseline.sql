-- Baseline del esquema de Postgres de billetudo.
--
-- Este archivo captura el estado COMPLETO de `public` tal como existía en prod
-- ANTES de las dos migraciones posteriores del repo:
--   * 20260724000000_debts_closed_at.sql        -> agrega debts.closed_at
--   * 20260728000000_goals_v19_contributions.sql -> agrega goals.completed_at,
--     goals.archived_at, goals.last_milestone_pct y la tabla goal_contributions
-- Es decir: baseline + esas dos migraciones, aplicadas en orden sobre una base
-- vacía, reproducen prod exactamente. No dupliques aquí lo que ellas hacen.
--
-- Por qué existe: el esquema se venía aplicando a mano por MCP y prod quedó
-- atrás del cliente. Un `closed_at` faltante hizo que PostgREST respondiera
-- PGRST204, el conector de PowerSync lo reintentara para siempre y, al ser la
-- cola de subida FIFO, NINGUNA escritura de ninguna tabla volviera a subir.
-- Desde ahora todo cambio de esquema entra por un archivo en
-- supabase/migrations/, nunca por MCP a mano.
--
-- ============================================================================
-- CONVENCIÓN DE TIPOS (crítica, no negociable)
-- ============================================================================
-- Las tablas sincronizadas se leen en el cliente a través de las *vistas* de
-- PowerSync, donde cada columna es `CAST(json_extract(data,'$.col') AS <tipo>)`.
-- Por eso el tipo de Postgres debe seguir al tipo del cliente, no al revés
-- (decisión #15, docs/requirements/fase-1/05-auth-sync.md):
--
--   * Fechas y timestamps -> `bigint` con epoch en SEGUNDOS.
--     Es como Drift serializa un `DateTimeColumn` a SQLite.
--   * `updated_at`        -> `bigint` con epoch en MILISEGUNDOS.
--     Es un `IntColumn` en Drift (`_SyncColumns.updatedAt`), no un
--     `DateTimeColumn`; la unidad distinta es intencional.
--   * NUNCA `timestamptz` en una tabla sincronizada. Un `timestamptz` llega al
--     dispositivo como texto y `CAST('2026-07-17...' AS INTEGER)` devuelve
--     `2026` en silencio: toda fila nacida en el servidor se lee como 1970 y
--     toda fila nacida en el dispositivo se rechaza al subir como un `22xxx`
--     fatal.
--   * Dinero -> `bigint` en unidades menores (centavos). Nunca `numeric`/float.
--   * `id`   -> `text` con un UUID generado en el cliente. Nunca autoincrement:
--     rompería el sync y la fusión de datos offline.
--   * Booleanos -> `boolean` en Postgres; el cliente los ve como 0/1.
--   * Los enums se guardan como `text` + CHECK, para tener paridad exacta con
--     los enums de Drift sin depender de tipos ENUM de Postgres.
--
-- Borrado: `deleted_at` es papelera reversible (UX) y `tombstoned_at` es lápida
-- de integridad referencial (irreversible). No son sinónimos.
--
-- Todo en este archivo es idempotente: se puede correr sobre una base vacía o
-- sobre una que ya tenga parte del esquema.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- category_seeds — catálogo global de categorías sugeridas (NO sincronizada,
-- no tiene user_id ni columnas de sync; se lee de solo lectura por REST).
-- ---------------------------------------------------------------------------
create table if not exists public.category_seeds (
  id         text primary key,
  kind       text not null check (kind in ('income', 'expense')),
  parent_id  text references public.category_seeds (id),
  name_es    text not null,
  name_en    text not null,
  icon       text,
  color      text,
  sort_order integer not null default 0
);

alter table public.category_seeds add column if not exists kind text;
alter table public.category_seeds add column if not exists parent_id text;
alter table public.category_seeds add column if not exists name_es text;
alter table public.category_seeds add column if not exists name_en text;
alter table public.category_seeds add column if not exists icon text;
alter table public.category_seeds add column if not exists color text;
alter table public.category_seeds add column if not exists sort_order integer not null default 0;

alter table public.category_seeds enable row level security;

drop policy if exists "Anyone can read the seed catalog" on public.category_seeds;
create policy "Anyone can read the seed catalog" on public.category_seeds
  for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- accounts
-- ---------------------------------------------------------------------------
create table if not exists public.accounts (
  id                    text primary key,
  created_at            bigint not null default (extract(epoch from now()))::bigint,
  updated_at            bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at            bigint,
  tombstoned_at         bigint,
  user_id               uuid references auth.users (id) on delete cascade,
  name                  text not null,
  type                  text not null check (type in ('cash', 'bank', 'card', 'savings', 'investment', 'other')),
  currency              text not null check (char_length(currency) = 3),
  initial_balance_minor bigint not null default 0,
  icon                  text,
  color                 text,
  archived              boolean not null default false,
  sort_order            integer not null default 0,
  institution           text,
  last4                 text,
  interest_rate_bps     integer,
  credit_limit_minor    bigint,
  statement_day         integer,
  payment_due_day       integer,
  card_balance_primary  text check (card_balance_primary in ('debt', 'available'))
);

alter table public.accounts add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.accounts add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.accounts add column if not exists deleted_at bigint;
alter table public.accounts add column if not exists tombstoned_at bigint;
alter table public.accounts add column if not exists user_id uuid;
alter table public.accounts add column if not exists name text;
alter table public.accounts add column if not exists type text;
alter table public.accounts add column if not exists currency text;
alter table public.accounts add column if not exists initial_balance_minor bigint not null default 0;
alter table public.accounts add column if not exists icon text;
alter table public.accounts add column if not exists color text;
alter table public.accounts add column if not exists archived boolean not null default false;
alter table public.accounts add column if not exists sort_order integer not null default 0;
alter table public.accounts add column if not exists institution text;
alter table public.accounts add column if not exists last4 text;
alter table public.accounts add column if not exists interest_rate_bps integer;
alter table public.accounts add column if not exists credit_limit_minor bigint;
alter table public.accounts add column if not exists statement_day integer;
alter table public.accounts add column if not exists payment_due_day integer;
alter table public.accounts add column if not exists card_balance_primary text;

create index if not exists accounts_user_id_idx on public.accounts (user_id);

alter table public.accounts enable row level security;
drop policy if exists "Users manage own rows" on public.accounts;
create policy "Users manage own rows" on public.accounts
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- categories — jerárquica vía parent_id. PK compuesta (id, user_id) porque las
-- semillas se copian con el mismo id para cada usuario.
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id            text not null,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid not null references auth.users (id) on delete cascade,
  name          text not null,
  kind          text not null check (kind in ('income', 'expense')),
  parent_id     text,
  icon          text,
  color         text,
  sort_order    integer not null default 0,
  primary key (id, user_id),
  foreign key (parent_id, user_id) references public.categories (id, user_id)
);

alter table public.categories add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.categories add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.categories add column if not exists deleted_at bigint;
alter table public.categories add column if not exists tombstoned_at bigint;
alter table public.categories add column if not exists name text;
alter table public.categories add column if not exists kind text;
alter table public.categories add column if not exists parent_id text;
alter table public.categories add column if not exists icon text;
alter table public.categories add column if not exists color text;
alter table public.categories add column if not exists sort_order integer not null default 0;

create index if not exists categories_user_id_idx on public.categories (user_id);

alter table public.categories enable row level security;
drop policy if exists "Users manage own rows" on public.categories;
create policy "Users manage own rows" on public.categories
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- budgets
-- ---------------------------------------------------------------------------
create table if not exists public.budgets (
  id                  text primary key,
  created_at          bigint not null default (extract(epoch from now()))::bigint,
  updated_at          bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at          bigint,
  tombstoned_at       bigint,
  user_id             uuid references auth.users (id) on delete cascade,
  name                text not null,
  icon                text,
  amount_minor        bigint not null,
  currency            text not null check (char_length(currency) = 3),
  period              text not null check (period in ('weekly', 'biweekly', 'monthly', 'yearly', 'custom')),
  start_date          bigint not null,
  recurring           boolean not null default true,
  end_date            bigint,
  archived_at         bigint,
  alert_threshold_pct integer default 80,
  rollover            boolean not null default false
);

alter table public.budgets add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.budgets add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.budgets add column if not exists deleted_at bigint;
alter table public.budgets add column if not exists tombstoned_at bigint;
alter table public.budgets add column if not exists user_id uuid;
alter table public.budgets add column if not exists name text;
alter table public.budgets add column if not exists icon text;
alter table public.budgets add column if not exists amount_minor bigint;
alter table public.budgets add column if not exists currency text;
alter table public.budgets add column if not exists period text;
alter table public.budgets add column if not exists start_date bigint;
alter table public.budgets add column if not exists recurring boolean not null default true;
alter table public.budgets add column if not exists end_date bigint;
alter table public.budgets add column if not exists archived_at bigint;
alter table public.budgets add column if not exists alert_threshold_pct integer default 80;
alter table public.budgets add column if not exists rollover boolean not null default false;

create index if not exists budgets_user_id_idx on public.budgets (user_id);

alter table public.budgets enable row level security;
drop policy if exists "Users manage own rows" on public.budgets;
create policy "Users manage own rows" on public.budgets
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- goals — `saved_minor` y `color` siguen aquí por compatibilidad con clientes
-- viejos; el cliente actual (schemaVersion 19) ya no los escribe: el monto
-- ahorrado se deriva sumando goal_contributions (creada en la migración
-- 20260728000000).
-- ---------------------------------------------------------------------------
create table if not exists public.goals (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id) on delete cascade,
  name          text not null,
  target_minor  bigint not null,
  saved_minor   bigint not null default 0,
  currency      text not null check (char_length(currency) = 3),
  account_id    text references public.accounts (id),
  target_date   bigint,
  icon          text,
  color         text
);

alter table public.goals add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.goals add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.goals add column if not exists deleted_at bigint;
alter table public.goals add column if not exists tombstoned_at bigint;
alter table public.goals add column if not exists user_id uuid;
alter table public.goals add column if not exists name text;
alter table public.goals add column if not exists target_minor bigint;
alter table public.goals add column if not exists saved_minor bigint not null default 0;
alter table public.goals add column if not exists currency text;
alter table public.goals add column if not exists account_id text;
alter table public.goals add column if not exists target_date bigint;
alter table public.goals add column if not exists icon text;
alter table public.goals add column if not exists color text;

create index if not exists goals_user_id_idx on public.goals (user_id);

alter table public.goals enable row level security;
drop policy if exists "Users manage own rows" on public.goals;
create policy "Users manage own rows" on public.goals
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- debts — `closed_at` NO va aquí: la agrega 20260724000000_debts_closed_at.sql.
-- `initial_transaction_id` es un FK blando (sin constraint) a la transacción de
-- desembolso: esa transacción puede borrarse y la deuda debe sobrevivir.
-- ---------------------------------------------------------------------------
create table if not exists public.debts (
  id                     text primary key,
  created_at             bigint not null default (extract(epoch from now()))::bigint,
  updated_at             bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at             bigint,
  tombstoned_at          bigint,
  user_id                uuid references auth.users (id) on delete cascade,
  name                   text not null,
  direction              text not null check (direction in ('iOwe', 'owedToMe')),
  principal_minor        bigint not null,
  currency               text not null check (char_length(currency) = 3),
  interest_rate_bps      integer,
  counterparty           text,
  due_date               bigint,
  accrual_mode           text not null default 'manual',
  initial_transaction_id text,
  start_date             bigint
);

alter table public.debts add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.debts add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.debts add column if not exists deleted_at bigint;
alter table public.debts add column if not exists tombstoned_at bigint;
alter table public.debts add column if not exists user_id uuid;
alter table public.debts add column if not exists name text;
alter table public.debts add column if not exists direction text;
alter table public.debts add column if not exists principal_minor bigint;
alter table public.debts add column if not exists currency text;
alter table public.debts add column if not exists interest_rate_bps integer;
alter table public.debts add column if not exists counterparty text;
alter table public.debts add column if not exists due_date bigint;
alter table public.debts add column if not exists accrual_mode text not null default 'manual';
alter table public.debts add column if not exists initial_transaction_id text;
alter table public.debts add column if not exists start_date bigint;

create index if not exists debts_user_id_idx on public.debts (user_id);

alter table public.debts enable row level security;
drop policy if exists "Users manage own rows" on public.debts;
create policy "Users manage own rows" on public.debts
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- debt_entries — libro de movimientos de una deuda. El saldo pendiente es
-- DERIVADO (suma de entradas), por eso no hay columna de balance.
-- Ojo: en prod esta tabla no tiene FK de user_id ni índice por user_id, y su
-- policy aplica al rol `public` en vez de `authenticated`. Se reproduce tal
-- cual para que el baseline sea fiel; normalizarlo sería otra migración.
-- ---------------------------------------------------------------------------
create table if not exists public.debt_entries (
  id                text primary key,
  created_at        bigint not null,
  updated_at        bigint not null,
  deleted_at        bigint,
  tombstoned_at     bigint,
  user_id           uuid,
  debt_id           text not null,
  kind              text not null,
  amount_minor      bigint not null,
  entry_date        bigint not null,
  note              text,
  rate_bps_snapshot integer
);

alter table public.debt_entries add column if not exists created_at bigint;
alter table public.debt_entries add column if not exists updated_at bigint;
alter table public.debt_entries add column if not exists deleted_at bigint;
alter table public.debt_entries add column if not exists tombstoned_at bigint;
alter table public.debt_entries add column if not exists user_id uuid;
alter table public.debt_entries add column if not exists debt_id text;
alter table public.debt_entries add column if not exists kind text;
alter table public.debt_entries add column if not exists amount_minor bigint;
alter table public.debt_entries add column if not exists entry_date bigint;
alter table public.debt_entries add column if not exists note text;
alter table public.debt_entries add column if not exists rate_bps_snapshot integer;

alter table public.debt_entries enable row level security;
drop policy if exists "Users manage own rows" on public.debt_entries;
create policy "Users manage own rows" on public.debt_entries
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- scheduled_payments
-- ---------------------------------------------------------------------------
create table if not exists public.scheduled_payments (
  id                    text primary key,
  created_at            bigint not null default (extract(epoch from now()))::bigint,
  updated_at            bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at            bigint,
  tombstoned_at         bigint,
  user_id               uuid references auth.users (id) on delete cascade,
  account_id            text not null references public.accounts (id),
  category_id           text,
  amount_minor          bigint not null,
  currency              text not null check (char_length(currency) = 3),
  type                  text not null check (type in ('income', 'expense', 'transfer')),
  note                  text,
  transfer_account_id   text references public.accounts (id),
  frequency             text not null check (frequency in ('once', 'daily', 'weekly', 'monthly', 'yearly')),
  interval              integer not null default 1,
  next_date             bigint not null,
  end_date              bigint,
  requires_confirmation boolean not null default false,
  first_payment_date    bigint not null,
  debt_id               text,
  foreign key (category_id, user_id) references public.categories (id, user_id)
);

alter table public.scheduled_payments add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.scheduled_payments add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.scheduled_payments add column if not exists deleted_at bigint;
alter table public.scheduled_payments add column if not exists tombstoned_at bigint;
alter table public.scheduled_payments add column if not exists user_id uuid;
alter table public.scheduled_payments add column if not exists account_id text;
alter table public.scheduled_payments add column if not exists category_id text;
alter table public.scheduled_payments add column if not exists amount_minor bigint;
alter table public.scheduled_payments add column if not exists currency text;
alter table public.scheduled_payments add column if not exists type text;
alter table public.scheduled_payments add column if not exists note text;
alter table public.scheduled_payments add column if not exists transfer_account_id text;
alter table public.scheduled_payments add column if not exists frequency text;
alter table public.scheduled_payments add column if not exists interval integer not null default 1;
alter table public.scheduled_payments add column if not exists next_date bigint;
alter table public.scheduled_payments add column if not exists end_date bigint;
alter table public.scheduled_payments add column if not exists requires_confirmation boolean not null default false;
alter table public.scheduled_payments add column if not exists first_payment_date bigint;
alter table public.scheduled_payments add column if not exists debt_id text;

create index if not exists scheduled_payments_user_id_idx on public.scheduled_payments (user_id);

alter table public.scheduled_payments enable row level security;
drop policy if exists "Users manage own rows" on public.scheduled_payments;
create policy "Users manage own rows" on public.scheduled_payments
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- transactions — `source` distingue captura manual vs. IA para medir cupos.
-- Los montos van en unidades menores (centavos) como bigint.
-- ---------------------------------------------------------------------------
create table if not exists public.transactions (
  id                   text primary key,
  created_at           bigint not null default (extract(epoch from now()))::bigint,
  updated_at           bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at           bigint,
  tombstoned_at        bigint,
  user_id              uuid references auth.users (id) on delete cascade,
  account_id           text not null references public.accounts (id),
  category_id          text,
  amount_minor         bigint not null,
  currency             text not null check (char_length(currency) = 3),
  type                 text not null check (type in ('income', 'expense', 'transfer')),
  date                 bigint not null,
  note                 text,
  source               text not null default 'manual' check (source in ('manual', 'voice', 'ocr', 'notification', 'imported', 'scheduled')),
  transfer_account_id  text references public.accounts (id),
  scheduled_payment_id text references public.scheduled_payments (id),
  goal_id              text references public.goals (id),
  debt_id              text references public.debts (id),
  counts_in_budget     boolean not null default false,
  foreign key (category_id, user_id) references public.categories (id, user_id)
);

alter table public.transactions add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.transactions add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.transactions add column if not exists deleted_at bigint;
alter table public.transactions add column if not exists tombstoned_at bigint;
alter table public.transactions add column if not exists user_id uuid;
alter table public.transactions add column if not exists account_id text;
alter table public.transactions add column if not exists category_id text;
alter table public.transactions add column if not exists amount_minor bigint;
alter table public.transactions add column if not exists currency text;
alter table public.transactions add column if not exists type text;
alter table public.transactions add column if not exists date bigint;
alter table public.transactions add column if not exists note text;
alter table public.transactions add column if not exists source text not null default 'manual';
alter table public.transactions add column if not exists transfer_account_id text;
alter table public.transactions add column if not exists scheduled_payment_id text;
alter table public.transactions add column if not exists goal_id text;
alter table public.transactions add column if not exists debt_id text;
alter table public.transactions add column if not exists counts_in_budget boolean not null default false;

create index if not exists transactions_user_id_idx on public.transactions (user_id);

alter table public.transactions enable row level security;
drop policy if exists "Users manage own rows" on public.transactions;
create policy "Users manage own rows" on public.transactions
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- scheduled_payment_occurrences
-- ---------------------------------------------------------------------------
create table if not exists public.scheduled_payment_occurrences (
  id                        text primary key,
  created_at                bigint not null default (extract(epoch from now()))::bigint,
  updated_at                bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at                bigint,
  tombstoned_at             bigint,
  user_id                   uuid references auth.users (id) on delete cascade,
  scheduled_payment_id      text not null references public.scheduled_payments (id),
  occurrence_date           bigint not null,
  status                    text not null default 'pending' check (status in ('pending', 'confirmed', 'skipped', 'snoozed')),
  snoozed_to_date           bigint,
  generated_transaction_id  text references public.transactions (id),
  unique (scheduled_payment_id, occurrence_date)
);

alter table public.scheduled_payment_occurrences add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.scheduled_payment_occurrences add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.scheduled_payment_occurrences add column if not exists deleted_at bigint;
alter table public.scheduled_payment_occurrences add column if not exists tombstoned_at bigint;
alter table public.scheduled_payment_occurrences add column if not exists user_id uuid;
alter table public.scheduled_payment_occurrences add column if not exists scheduled_payment_id text;
alter table public.scheduled_payment_occurrences add column if not exists occurrence_date bigint;
alter table public.scheduled_payment_occurrences add column if not exists status text not null default 'pending';
alter table public.scheduled_payment_occurrences add column if not exists snoozed_to_date bigint;
alter table public.scheduled_payment_occurrences add column if not exists generated_transaction_id text;

create index if not exists scheduled_payment_occurrences_user_id_idx on public.scheduled_payment_occurrences (user_id);
create index if not exists scheduled_payment_occurrences_scheduled_payment_id_idx on public.scheduled_payment_occurrences (scheduled_payment_id);

alter table public.scheduled_payment_occurrences enable row level security;
drop policy if exists "Users manage own rows" on public.scheduled_payment_occurrences;
create policy "Users manage own rows" on public.scheduled_payment_occurrences
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- tags
-- ---------------------------------------------------------------------------
create table if not exists public.tags (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id) on delete cascade,
  name          text not null,
  color         text
);

alter table public.tags add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.tags add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.tags add column if not exists deleted_at bigint;
alter table public.tags add column if not exists tombstoned_at bigint;
alter table public.tags add column if not exists user_id uuid;
alter table public.tags add column if not exists name text;
alter table public.tags add column if not exists color text;

create index if not exists tags_user_id_idx on public.tags (user_id);

alter table public.tags enable row level security;
drop policy if exists "Users manage own rows" on public.tags;
create policy "Users manage own rows" on public.tags
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- transaction_tags (N:N)
-- ---------------------------------------------------------------------------
create table if not exists public.transaction_tags (
  id             text primary key,
  created_at     bigint not null default (extract(epoch from now()))::bigint,
  updated_at     bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at     bigint,
  tombstoned_at  bigint,
  user_id        uuid references auth.users (id) on delete cascade,
  transaction_id text not null references public.transactions (id),
  tag_id         text not null references public.tags (id),
  unique (transaction_id, tag_id)
);

alter table public.transaction_tags add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.transaction_tags add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.transaction_tags add column if not exists deleted_at bigint;
alter table public.transaction_tags add column if not exists tombstoned_at bigint;
alter table public.transaction_tags add column if not exists user_id uuid;
alter table public.transaction_tags add column if not exists transaction_id text;
alter table public.transaction_tags add column if not exists tag_id text;

create index if not exists transaction_tags_user_id_idx on public.transaction_tags (user_id);

alter table public.transaction_tags enable row level security;
drop policy if exists "Users manage own rows" on public.transaction_tags;
create policy "Users manage own rows" on public.transaction_tags
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- scheduled_payment_tags (N:N)
-- ---------------------------------------------------------------------------
create table if not exists public.scheduled_payment_tags (
  id                   text primary key,
  created_at           bigint not null default (extract(epoch from now()))::bigint,
  updated_at           bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at           bigint,
  tombstoned_at        bigint,
  user_id              uuid references auth.users (id) on delete cascade,
  scheduled_payment_id text not null references public.scheduled_payments (id),
  tag_id               text not null references public.tags (id),
  unique (scheduled_payment_id, tag_id)
);

alter table public.scheduled_payment_tags add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.scheduled_payment_tags add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.scheduled_payment_tags add column if not exists deleted_at bigint;
alter table public.scheduled_payment_tags add column if not exists tombstoned_at bigint;
alter table public.scheduled_payment_tags add column if not exists user_id uuid;
alter table public.scheduled_payment_tags add column if not exists scheduled_payment_id text;
alter table public.scheduled_payment_tags add column if not exists tag_id text;

create index if not exists scheduled_payment_tags_user_id_idx on public.scheduled_payment_tags (user_id);
create index if not exists scheduled_payment_tags_scheduled_payment_id_idx on public.scheduled_payment_tags (scheduled_payment_id);

alter table public.scheduled_payment_tags enable row level security;
drop policy if exists "Users manage own rows" on public.scheduled_payment_tags;
create policy "Users manage own rows" on public.scheduled_payment_tags
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- budget_accounts (N:N)
-- ---------------------------------------------------------------------------
create table if not exists public.budget_accounts (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id) on delete cascade,
  budget_id     text not null references public.budgets (id),
  account_id    text not null references public.accounts (id),
  unique (budget_id, account_id)
);

alter table public.budget_accounts add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.budget_accounts add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.budget_accounts add column if not exists deleted_at bigint;
alter table public.budget_accounts add column if not exists tombstoned_at bigint;
alter table public.budget_accounts add column if not exists user_id uuid;
alter table public.budget_accounts add column if not exists budget_id text;
alter table public.budget_accounts add column if not exists account_id text;

create index if not exists budget_accounts_user_id_idx on public.budget_accounts (user_id);

alter table public.budget_accounts enable row level security;
drop policy if exists "Users manage own rows" on public.budget_accounts;
create policy "Users manage own rows" on public.budget_accounts
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- budget_categories (N:N)
-- ---------------------------------------------------------------------------
create table if not exists public.budget_categories (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id) on delete cascade,
  budget_id     text not null references public.budgets (id),
  category_id   text not null,
  unique (budget_id, category_id),
  foreign key (category_id, user_id) references public.categories (id, user_id)
);

alter table public.budget_categories add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.budget_categories add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.budget_categories add column if not exists deleted_at bigint;
alter table public.budget_categories add column if not exists tombstoned_at bigint;
alter table public.budget_categories add column if not exists user_id uuid;
alter table public.budget_categories add column if not exists budget_id text;
alter table public.budget_categories add column if not exists category_id text;

create index if not exists budget_categories_user_id_idx on public.budget_categories (user_id);

alter table public.budget_categories enable row level security;
drop policy if exists "Users manage own rows" on public.budget_categories;
create policy "Users manage own rows" on public.budget_categories
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- budget_period_overrides
-- ---------------------------------------------------------------------------
create table if not exists public.budget_period_overrides (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id) on delete cascade,
  budget_id     text not null references public.budgets (id),
  period_start  bigint not null,
  amount_minor  bigint not null,
  unique (budget_id, period_start)
);

alter table public.budget_period_overrides add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.budget_period_overrides add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.budget_period_overrides add column if not exists deleted_at bigint;
alter table public.budget_period_overrides add column if not exists tombstoned_at bigint;
alter table public.budget_period_overrides add column if not exists user_id uuid;
alter table public.budget_period_overrides add column if not exists budget_id text;
alter table public.budget_period_overrides add column if not exists period_start bigint;
alter table public.budget_period_overrides add column if not exists amount_minor bigint;

create index if not exists budget_period_overrides_user_id_idx on public.budget_period_overrides (user_id);

alter table public.budget_period_overrides enable row level security;
drop policy if exists "Users manage own rows" on public.budget_period_overrides;
create policy "Users manage own rows" on public.budget_period_overrides
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- app_settings — una fila por usuario; `id` es el literal 'app'. PK compuesta
-- (id, user_id) para que la misma fila lógica exista por usuario.
-- ---------------------------------------------------------------------------
create table if not exists public.app_settings (
  id                 text not null default 'app',
  created_at         bigint not null default (extract(epoch from now()))::bigint,
  updated_at         bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at         bigint,
  tombstoned_at      bigint,
  user_id            uuid not null references auth.users (id) on delete cascade,
  zero_based_enabled boolean not null default false,
  categories_seeded  boolean not null default false,
  primary key (id, user_id)
);

alter table public.app_settings add column if not exists created_at bigint not null default (extract(epoch from now()))::bigint;
alter table public.app_settings add column if not exists updated_at bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint;
alter table public.app_settings add column if not exists deleted_at bigint;
alter table public.app_settings add column if not exists tombstoned_at bigint;
alter table public.app_settings add column if not exists zero_based_enabled boolean not null default false;
alter table public.app_settings add column if not exists categories_seeded boolean not null default false;

create index if not exists app_settings_user_id_idx on public.app_settings (user_id);

alter table public.app_settings enable row level security;
drop policy if exists "Users manage own rows" on public.app_settings;
create policy "Users manage own rows" on public.app_settings
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Publicación de replicación lógica que consume PowerSync. En prod es
-- `for all tables`, así que cualquier tabla nueva de `public` entra sola.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'powersync') then
    create publication powersync for all tables;
  end if;
end
$$;

-- schemaVersion 34 (Fase 2): abre de una sola vez TODA la superficie de esquema
-- de la fase, para que las ramas hijas que trabajan en paralelo no colisionen
-- reclamando cada una su propia version de Drift.
--
-- Espejo exacto de lib/core/database/app_database.dart y de
-- lib/core/database/powersync_schema.dart. Sin esta migracion aplicada en dev y
-- prod, PostgREST responde PGRST204 y la cola FIFO de subida de PowerSync se
-- traba para TODAS las tablas (la caida de `debts.closed_at`, decision #22 de
-- docs/requirements/fase-1/05-auth-sync.md).
--
-- Fechas en `bigint`: epoch SEGUNDOS para cada DateTimeColumn de Drift y epoch
-- MILISEGUNDOS para `updated_at`. NUNCA `timestamptz` en una tabla sincronizada
-- (ver la nota de tipos en la cabecera de powersync_schema.dart).
--
-- La publicacion `powersync` del baseline es FOR ALL TABLES, asi que las dos
-- tablas nuevas quedan publicadas sin nada extra.

-- ---------------------------------------------------------------------------
-- 1. pending_captures — bandeja de revision de candidatos parseados de una
--    notificacion bancaria.
--
-- RETENCION CERO DEL TEXTO DE LA NOTIFICACION, decision de producto no
-- negociable: aqui NO hay `raw_text` / `title` / `big_text`, y no se pueden
-- agregar. Solo campos estructurados; `source_rule_id` existe justamente para
-- depurar el parseo por regla en vez de guardando el texto.
--
-- `amount_minor` SIEMPRE positivo (centavos); el signo lo da `entry_type`.
-- ---------------------------------------------------------------------------
create table if not exists public.pending_captures (
  id                          text primary key,
  created_at                  bigint not null default (extract(epoch from now()))::bigint,
  updated_at                  bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at                  bigint,
  tombstoned_at               bigint,
  user_id                     uuid references auth.users (id),
  source                      text not null,
  source_package              text not null,
  source_rule_id              text,
  posted_at                   bigint not null,
  amount_minor                bigint not null,
  currency                    text not null,
  entry_type                  text not null,
  merchant_raw                text,
  account_hint                text,
  suggested_account_id        text references public.accounts (id),
  suggested_category_id       text references public.categories (id),
  status                      text not null default 'pending',
  transaction_id              text references public.transactions (id),
  duplicate_of_transaction_id text references public.transactions (id)
);

alter table public.pending_captures enable row level security;

drop policy if exists "Users manage own rows" on public.pending_captures;
create policy "Users manage own rows" on public.pending_captures
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create index if not exists pending_captures_user_status_idx
  on public.pending_captures (user_id, status, posted_at desc);

-- ---------------------------------------------------------------------------
-- 2. merchant_category_learning — memoria comercio -> categoria.
--
-- `merchant_key` normalizada en MAYUSCULAS sin acentos (la normalizacion la
-- hace el cliente, en `data/`). El unique va sobre (user_id, merchant_key), NO
-- sobre `merchant_key` solo: un unique global colisionaria en cuanto dos
-- usuarios distintos aprendieran el mismo comercio (mismo bug que las
-- categorias semilla, decision #19). El cliente declara el unique solo sobre
-- `merchant_key` porque una instalacion solo guarda las filas de un usuario.
-- ---------------------------------------------------------------------------
create table if not exists public.merchant_category_learning (
  id            text primary key,
  created_at    bigint not null default (extract(epoch from now()))::bigint,
  updated_at    bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at    bigint,
  tombstoned_at bigint,
  user_id       uuid references auth.users (id),
  merchant_key  text not null,
  category_id   text not null references public.categories (id),
  hit_count     bigint not null default 1
);

alter table public.merchant_category_learning enable row level security;

drop policy if exists "Users manage own rows" on public.merchant_category_learning;
create policy "Users manage own rows" on public.merchant_category_learning
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create unique index if not exists merchant_category_learning_user_key_uidx
  on public.merchant_category_learning (user_id, merchant_key);

-- ---------------------------------------------------------------------------
-- 3. accounts.card_last4 — ultimos 4 digitos de la TARJETA asociada, contra los
--    que se compara `pending_captures.account_hint` para sugerir cuenta.
--    Distinta de `accounts.last4`, que identifica la CUENTA.
--
-- 4. scheduled_payments.reminder_lead_days — dias antes del vencimiento para el
--    recordatorio local. NULL = sin recordatorio (valor con significado, no
--    "sin configurar"), por eso no lleva DEFAULT.
--
-- Ambas nullable, asi que el cliente viejo sigue funcionando sin cambios.
-- ---------------------------------------------------------------------------
alter table public.accounts
  add column if not exists card_last4 text;

alter table public.scheduled_payments
  add column if not exists reminder_lead_days bigint;

-- ---------------------------------------------------------------------------
-- 5. Touch de filas existentes (decisiones #15/#17/#20/#21/#22/#26).
--
-- `ALTER TABLE ADD COLUMN` es metadata en Postgres: no genera WAL por fila
-- existente, asi que PowerSync jamas reenvia esas filas a un dispositivo ya
-- sincronizado. Sin este UPDATE, un cliente v34 ya sincronizado nunca ve la
-- columna nueva hasta que algo mas toque la fila. Se corre en CADA entorno con
-- filas (dev y prod).
--
-- `updated_at = updated_at` no altera ningun valor: solo produce el WAL que
-- dispara la replicacion.
-- ---------------------------------------------------------------------------
update public.accounts set updated_at = updated_at where true;
update public.scheduled_payments set updated_at = updated_at where true;

-- ---------------------------------------------------------------------------
-- 6. Borrado de cuenta (HU-07, obligatorio Apple + Google).
--
-- Septima extension de delete_account_data. Las dos tablas nuevas tienen
-- user_id, asi que delete_account_data_coverage_gaps() las reportaria de
-- inmediato si se omitieran. `pending_captures` va ANTES de transactions /
-- accounts / categories porque las referencia por FK; `merchant_category_
-- learning` va antes de categories por lo mismo.
-- ---------------------------------------------------------------------------
create or replace function public.delete_account_data(p_user_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  delete from scheduled_payment_occurrences where user_id = p_user_id;
  delete from scheduled_payment_tags where user_id = p_user_id;
  delete from transaction_tags where user_id = p_user_id;
  delete from budget_accounts where user_id = p_user_id;
  delete from budget_categories where user_id = p_user_id;

  delete from budget_period_overrides where user_id = p_user_id;
  delete from goal_quick_amounts where user_id = p_user_id;
  delete from goal_contributions where user_id = p_user_id;
  delete from debt_entries where user_id = p_user_id;

  delete from tutorial_views where user_id = p_user_id;

  delete from pending_captures where user_id = p_user_id;
  delete from merchant_category_learning where user_id = p_user_id;

  delete from transactions where user_id = p_user_id;
  delete from scheduled_payments where user_id = p_user_id;
  delete from goals where user_id = p_user_id;
  delete from budgets where user_id = p_user_id;
  delete from debts where user_id = p_user_id;
  delete from categories where user_id = p_user_id;
  delete from tags where user_id = p_user_id;
  delete from app_settings where user_id = p_user_id;
  delete from accounts where user_id = p_user_id;
  delete from import_batches where user_id = p_user_id;

  delete from ai_reports where user_id = p_user_id;
  delete from ai_usage_log where user_id = p_user_id;
  delete from ai_access where user_id = p_user_id;
end;
$function$;

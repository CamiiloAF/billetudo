-- schemaVersion 21 (Import/Export, docs/requirements/11-import-export.md):
-- one row per completed CSV import, plus a nullable `import_batch_id` on
-- every table an import can create rows in (`transactions`, `accounts`,
-- `categories`, `tags`), so a whole import can be reverted by id (HU-08)
-- without the `source = 'imported'` + time-window heuristic (breaks with two
-- same-day imports, and doesn't cover accounts/categories, which have no
-- `source`).
--
-- Never deleted: it is the undo target for HU-08 ("revertir importación"), so
-- its presence in the history must survive the revert itself — `reverted_at`
-- marks that instead of removing the row.
--
-- Epoch SECONDS in bigint; `updated_at` in MILLIs. Never `timestamptz` on a
-- synced table (see the type comment in `powersync_schema.dart`).
create table if not exists public.import_batches (
  id             text primary key,
  created_at     bigint not null default (extract(epoch from now()))::bigint,
  updated_at     bigint not null default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  deleted_at     bigint,
  tombstoned_at  bigint,
  user_id        uuid references auth.users (id),
  file_name      text not null,
  template_name  text,
  imported_at    bigint not null,
  rows_imported  bigint not null,
  rows_skipped   bigint not null,
  reverted_at    bigint
);

alter table public.import_batches enable row level security;

drop policy if exists "Users manage own rows" on public.import_batches;
create policy "Users manage own rows" on public.import_batches
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Nullable `import_batch_id` on every table an import can create rows in.
-- Null = created by hand (or predates the feature, or a `seed-*` catalog
-- category).
alter table public.transactions
  add column if not exists import_batch_id text references public.import_batches (id);

alter table public.accounts
  add column if not exists import_batch_id text references public.import_batches (id);

alter table public.categories
  add column if not exists import_batch_id text references public.import_batches (id);

alter table public.tags
  add column if not exists import_batch_id text references public.import_batches (id);

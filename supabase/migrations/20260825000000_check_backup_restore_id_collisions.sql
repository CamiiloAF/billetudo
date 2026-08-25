-- Respalda la feature de remapeo de ids al restaurar un backup bajo una
-- cuenta Supabase distinta a la que originalmente sincronizo esos datos
-- (docs/dev-runs/backup-restore-id-collision-remap.md).
--
-- Contexto: `.billetudo.json` preserva el id original de cada fila. Si el
-- usuario restaura ese backup mientras esta autenticado con una cuenta
-- distinta a la duena original de esos ids, `SupabaseOperationUploader`
-- termina haciendo un `.upsert()` que Postgres trata como UPDATE sobre una
-- fila de otra cuenta -> RLS lo rechaza con 42501 en cascada por todas las
-- tablas referenciadas, y el restore entero queda en cuarentena permanente
-- (503 operaciones en el incidente real que origino esta migracion).
--
-- La deteccion en si misma NO se puede hacer con una query normal del
-- cliente: las politicas RLS (`using (user_id = auth.uid())`, ver
-- 20260701000000_baseline.sql) ocultan por diseno cualquier fila de otra
-- cuenta. De ahi la funcion `security definer` de abajo: bypasea RLS solo
-- para responder "este id ya existe bajo otra cuenta, si o no" — nunca
-- devuelve la fila ni el user_id ajeno, para no filtrar metadatos entre
-- cuentas.
--
-- `lib/core/sync/data/datasources/backup_id_collision_datasource.dart` la
-- invoca en un solo roundtrip batch (una lista de (table_name, id) por las
-- ~18 tablas que puede traer un backup, `app_settings` excluida a proposito:
-- su `id` es un singleton fijo ('app') que toda cuenta comparte
-- legitimamente, no una colision real — ver
-- `resolve_backup_id_conflicts.dart`).
--
-- Diseno deliberado: cero SQL dinamico. El allowlist de tablas no es una
-- lista que se valide en tiempo de ejecucion — es la propia estructura del
-- UNION ALL: una tabla que no aparece aqui no tiene rama que la consulte,
-- así que no hay forma de interpolar un table_name arbitrario ni de
-- consultar una tabla fuera de esta lista.

create or replace function public.check_backup_restore_id_collisions(
  p_user_id uuid,
  p_rows jsonb
)
 returns table (table_name text, id text)
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  with requested as (
    select
      (r ->> 'table_name') as table_name,
      (r ->> 'id') as id
    from jsonb_array_elements(p_rows) as r
  )
  select 'accounts'::text, t.id
    from accounts t
    join requested r on r.table_name = 'accounts' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'categories'::text, t.id
    from categories t
    join requested r on r.table_name = 'categories' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'transactions'::text, t.id
    from transactions t
    join requested r on r.table_name = 'transactions' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'budgets'::text, t.id
    from budgets t
    join requested r on r.table_name = 'budgets' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'goals'::text, t.id
    from goals t
    join requested r on r.table_name = 'goals' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'debts'::text, t.id
    from debts t
    join requested r on r.table_name = 'debts' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'scheduled_payments'::text, t.id
    from scheduled_payments t
    join requested r on r.table_name = 'scheduled_payments' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'tags'::text, t.id
    from tags t
    join requested r on r.table_name = 'tags' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'transaction_tags'::text, t.id
    from transaction_tags t
    join requested r on r.table_name = 'transaction_tags' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'budget_accounts'::text, t.id
    from budget_accounts t
    join requested r on r.table_name = 'budget_accounts' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'budget_categories'::text, t.id
    from budget_categories t
    join requested r on r.table_name = 'budget_categories' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'budget_period_overrides'::text, t.id
    from budget_period_overrides t
    join requested r on r.table_name = 'budget_period_overrides' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'goal_contributions'::text, t.id
    from goal_contributions t
    join requested r on r.table_name = 'goal_contributions' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'goal_quick_amounts'::text, t.id
    from goal_quick_amounts t
    join requested r on r.table_name = 'goal_quick_amounts' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'debt_entries'::text, t.id
    from debt_entries t
    join requested r on r.table_name = 'debt_entries' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'scheduled_payment_occurrences'::text, t.id
    from scheduled_payment_occurrences t
    join requested r on r.table_name = 'scheduled_payment_occurrences' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'scheduled_payment_tags'::text, t.id
    from scheduled_payment_tags t
    join requested r on r.table_name = 'scheduled_payment_tags' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
  union all
  select 'import_batches'::text, t.id
    from import_batches t
    join requested r on r.table_name = 'import_batches' and r.id = t.id
    where t.user_id is not null and t.user_id <> p_user_id
$function$;

-- ---------------------------------------------------------------------------
-- Guardian: mismo patron que delete_account_data_coverage_gaps
-- (20260808000000_delete_account_cascade_missing_tables.sql). Una tabla
-- nueva con user_id que quede fuera de la lista de arriba no rompe nada
-- (esa tabla simplemente nunca se marca en colision), pero es un vacio
-- silencioso: esta funcion lo hace visible.
--
-- Uso (deberia devolver cero filas):
--   select * from check_backup_restore_id_collisions_coverage_gaps();
--
-- `app_settings` queda excluida a proposito: su id es un singleton fijo
-- ('app') compartido por toda cuenta, nunca una colision real (ver
-- resolve_backup_id_conflicts.dart). `tutorial_views` tambien: no forma
-- parte de ningun `.billetudo.json` (`backupTableNames` en
-- backup_json_datasource.dart no la incluye). `category_seeds` no tiene
-- user_id (catalogo global), asi que el filtro de abajo ya la excluye por
-- construccion.
-- ---------------------------------------------------------------------------

create or replace function public.check_backup_restore_id_collisions_coverage_gaps()
 returns table (tabla_sin_cubrir text)
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select c.relname::text
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind = 'r'
    and exists (
      select 1 from pg_attribute a
      where a.attrelid = c.oid and a.attname = 'user_id'
        and a.attnum > 0 and not a.attisdropped
    )
    and c.relname not in ('app_settings', 'tutorial_views')
    and position(
      'from ' || c.relname || ' t' || chr(10) ||
      '    join requested r on r.table_name = ''' || c.relname || ''''
      in pg_get_functiondef('public.check_backup_restore_id_collisions(uuid, jsonb)'::regprocedure)
    ) = 0
  order by 1;
$function$;

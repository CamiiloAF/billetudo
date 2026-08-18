-- Cierra el borrado de cuenta (HU-07, requisito legal Apple/Google) para las
-- cinco tablas con user_id que delete_account_data nunca cubrio.
--
-- Contexto: esta es la cuarta correccion a la misma funcion
-- (7b81c2e pagos programados, bf89069 cuenta huerfana, 2bab1eb import_batches).
-- Cada una tapo la tabla que faltaba en ese momento y volvio a romperse cuando
-- se creo la siguiente. Por eso este cambio NO se limita a extender la lista:
-- convierte la relacion en estructural con ON DELETE CASCADE, para que una
-- tabla hija desaparezca con su padre aunque alguien olvide tocar la funcion.
--
-- Las cinco tablas y por que fallaban:
--
--   budget_period_overrides  FK -> budgets  sin CASCADE. Como la funcion es
--   goal_quick_amounts       FK -> goals    sin CASCADE. atomica, el delete del
--                            padre lanzaba violacion de FK y REVERTIA EL BORRADO
--                            ENTERO. Cualquier usuario con un presupuesto por
--                            periodo o un aporte rapido no podia borrar su cuenta.
--
--   debt_entries             Sin ninguna FK. Sobrevivia al borrado completo,
--                            incluso al eliminar el usuario de auth.users.
--                            Fuga real de datos financieros (montos y notas).
--
--   goal_contributions       Ya cascadeaba desde goals; se agrega a la funcion
--   tutorial_views           por profundidad. tutorial_views solo cuelga de
--                            auth.users, que la funcion no borra, asi que ahi
--                            el delete explicito no es opcional.
--
-- Verificado antes de aplicar: cero filas huerfanas en dev y en prod.

-- ---------------------------------------------------------------------------
-- 1. budget_period_overrides -> budgets
-- ---------------------------------------------------------------------------

alter table public.budget_period_overrides
  drop constraint budget_period_overrides_budget_id_fkey;

alter table public.budget_period_overrides
  add constraint budget_period_overrides_budget_id_fkey
  foreign key (budget_id) references public.budgets (id) on delete cascade;

-- El indice unico (budget_id, period_start) ya cubre las busquedas por
-- budget_id, asi que el cascade no hace scan secuencial. No se agrega indice.

-- ---------------------------------------------------------------------------
-- 2. goal_quick_amounts -> goals, y -> auth.users
-- ---------------------------------------------------------------------------

alter table public.goal_quick_amounts
  drop constraint goal_quick_amounts_goal_id_fkey;

alter table public.goal_quick_amounts
  add constraint goal_quick_amounts_goal_id_fkey
  foreign key (goal_id) references public.goals (id) on delete cascade;

-- Esta tambien estaba en NO ACTION: bloqueaba incluso el borrado del usuario
-- en auth.users, no solo el de la meta. El resto de tablas ya usa CASCADE aca.
alter table public.goal_quick_amounts
  drop constraint goal_quick_amounts_user_id_fkey;

alter table public.goal_quick_amounts
  add constraint goal_quick_amounts_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;

create index if not exists goal_quick_amounts_goal_id_idx
  on public.goal_quick_amounts using btree (goal_id);

create index if not exists goal_quick_amounts_user_id_idx
  on public.goal_quick_amounts using btree (user_id);

-- ---------------------------------------------------------------------------
-- 3. debt_entries -> debts, y -> auth.users (no tenia ninguna FK)
-- ---------------------------------------------------------------------------

alter table public.debt_entries
  add constraint debt_entries_debt_id_fkey
  foreign key (debt_id) references public.debts (id) on delete cascade;

alter table public.debt_entries
  add constraint debt_entries_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;

create index if not exists debt_entries_debt_id_idx
  on public.debt_entries using btree (debt_id);

create index if not exists debt_entries_user_id_idx
  on public.debt_entries using btree (user_id);

-- ---------------------------------------------------------------------------
-- 4. import_batches -> auth.users
--
-- Era la ultima FK a auth.users que quedaba en NO ACTION. Verificado con una
-- prueba en dev: con una sola fila en import_batches, `delete from auth.users`
-- fallaba con foreign_key_violation. No rompia el borrado desde la app (la
-- funcion ya limpiaba la tabla antes), pero dejaba el borrado del usuario
-- dependiendo de que la funcion corriera primero — justo lo que este cambio
-- busca eliminar.
-- ---------------------------------------------------------------------------

alter table public.import_batches
  drop constraint import_batches_user_id_fkey;

alter table public.import_batches
  add constraint import_batches_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;

-- ---------------------------------------------------------------------------
-- 5. delete_account_data: las cinco tablas, hijas antes que padres
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

  -- Hijas que antes faltaban. Van antes de budgets/goals/debts: aunque ahora
  -- hay CASCADE, el borrado explicito por user_id tambien limpia filas cuyo
  -- padre ya no exista (tombstones, datos importados a medias).
  delete from budget_period_overrides where user_id = p_user_id;
  delete from goal_quick_amounts where user_id = p_user_id;
  delete from goal_contributions where user_id = p_user_id;
  delete from debt_entries where user_id = p_user_id;

  -- tutorial_views solo cuelga de auth.users, que esta funcion no borra:
  -- sin este delete explicito sobrevive siempre.
  delete from tutorial_views where user_id = p_user_id;

  delete from transactions where user_id = p_user_id;
  delete from scheduled_payments where user_id = p_user_id;
  delete from goals where user_id = p_user_id;
  delete from budgets where user_id = p_user_id;
  delete from debts where user_id = p_user_id;
  delete from categories where user_id = p_user_id;
  delete from tags where user_id = p_user_id;
  delete from app_settings where user_id = p_user_id;
  delete from accounts where user_id = p_user_id;
  -- import_batches va al final: transactions/accounts/categories/tags la
  -- referencian sin CASCADE (ver 20260730000000).
  delete from import_batches where user_id = p_user_id;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 6. Guardian contra la quinta reincidencia
--
-- El problema de fondo no fue ninguna tabla en particular: fue que la funcion
-- es una lista manual que nadie actualiza al crear una tabla nueva. Esta
-- funcion compara las tablas con columna user_id contra las que la funcion
-- realmente borra, y devuelve las que quedaron fuera.
--
-- Uso (deberia devolver cero filas):
--   select * from delete_account_data_coverage_gaps();
--
-- Corrala despues de cada migracion que agregue una tabla con user_id.
-- category_seeds queda excluida a proposito: es catalogo global, no tiene
-- user_id y no debe borrarse nunca.
-- ---------------------------------------------------------------------------

create or replace function public.delete_account_data_coverage_gaps()
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
    and position(
      'delete from ' || c.relname || ' where user_id'
      in pg_get_functiondef('public.delete_account_data(uuid)'::regprocedure)
    ) = 0
  order by 1;
$function$;

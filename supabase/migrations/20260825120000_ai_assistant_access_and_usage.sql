-- Asistente financiero con IA (Fase A): gate de acceso y log de uso.
--
-- Tres objetos, NINGUNO sincronizado. No van a lib/core/database/app_database.dart
-- ni a lib/core/database/powersync_schema.dart, y no llevan las columnas del
-- mixin _SyncColumns. Viven solo en Postgres porque son control de servidor,
-- no datos del usuario: la app los lee (su propia fila) pero nunca los escribe.
--
-- Corolario de que no se sincronizan: la regla de "nunca timestamptz ni tipos
-- temporales en una tabla sincronizada" (ver la cabecera de powersync_schema.dart)
-- NO aplica aca. usage_day es un `date` real porque es el bucket de cuota y se
-- indexa; created_at si queda en bigint segundos por consistencia con el resto
-- del esquema.
--
-- La publicacion `powersync` del baseline es FOR ALL TABLES, asi que estas tres
-- quedan dentro de ella. Es inocuo mientras ninguna sync rule del dashboard de
-- PowerSync las seleccione — eso hay que verificarlo A MANO tras aplicar esta
-- migracion, porque las sync rules son la unica parte del contrato que no vive
-- en este repo.
--
-- ---------------------------------------------------------------------------
-- PRECONDICION DURA PARA ABRIR LA BETA
--
-- El flag global ai_assistant_open_to_all arranca en false a proposito, y NO
-- debe encenderse hasta que se cumplan las tres condiciones:
--
--   1. La politica de privacidad v1.5 este PUBLICADA. La v1.4, hoy publicada en
--      https://camiiloaf.github.io/billetudo/, afirma literalmente que "no hay
--      inteligencia artificial" y que "no enviamos tus datos a ningun modelo de
--      lenguaje". Encender esto antes convierte esa frase en falsa.
--   2. Las declaraciones de tienda (Play Data Safety / Apple App Privacy) esten
--      re-declaradas con el tercero nuevo y la categoria de datos nueva.
--   3. GEMINI_API_KEY apunte a un proyecto CON FACTURACION. La capa gratuita de
--      la API de Gemini permite a Google usar el contenido enviado para mejorar
--      sus modelos; eso es aceptable para dogfooding con datos propios y no lo
--      es para datos financieros de terceros.
--
-- Mientras tanto el acceso se concede fila por fila en ai_access. Este flag
-- existe como fila en Postgres, y no como constante en el codigo de la Edge
-- Function, precisamente porque la decision de abrir es de negocio y legal, no
-- de deploy.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. ai_access: gate por usuario
--
-- En Fase A es practicamente un booleano. Las columnas tier y
-- daily_message_limit ya estan para que Fase B (cupos, Premium, rewarded ads)
-- no necesite otra migracion sobre una tabla que ya estara poblada.
-- ---------------------------------------------------------------------------

create table if not exists public.ai_access (
  user_id             uuid primary key references auth.users (id) on delete cascade,
  enabled             boolean not null default false,
  tier                text    not null default 'beta'
                        check (tier in ('beta', 'free', 'premium')),
  daily_message_limit integer not null default 30
                        check (daily_message_limit >= 0),
  granted_at          bigint  not null default (extract(epoch from now()))::bigint,
  updated_at          bigint  not null
                        default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  notes               text
);

alter table public.ai_access enable row level security;

-- Solo LECTURA de la propia fila. Escribir es exclusivo de service_role, que
-- salta RLS: sin esto un usuario podria auto-habilitarse el asistente con un
-- simple upsert desde PostgREST.
drop policy if exists "Users read own ai access" on public.ai_access;
create policy "Users read own ai access" on public.ai_access
  for select to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 2. ai_feature_flags: interruptor global
--
-- RLS habilitado y SIN NINGUNA POLITICA: eso significa que ni anon ni
-- authenticated pueden leerlo. Solo lo ven service_role y las funciones
-- SECURITY DEFINER de mas abajo. Es deliberado — el estado del flag es
-- informacion de producto, no del usuario.
-- ---------------------------------------------------------------------------

create table if not exists public.ai_feature_flags (
  key        text primary key,
  enabled    boolean not null default false,
  updated_at bigint  not null
               default ((extract(epoch from clock_timestamp()) * 1000))::bigint,
  notes      text
);

alter table public.ai_feature_flags enable row level security;

insert into public.ai_feature_flags (key, enabled, notes)
values (
  'ai_assistant_open_to_all',
  false,
  'NO ENCENDER sin politica de privacidad v1.5 publicada, declaraciones de '
  || 'tienda re-declaradas y GEMINI_API_KEY en un proyecto con facturacion. '
  || 'Ver la cabecera de 20260825120000_ai_assistant_access_and_usage.sql.'
)
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 3. ai_usage_log: metadatos de uso, nunca contenido
--
-- Esta tabla es lo que convierte el gate en cupos reales en Fase B, y es
-- DELIBERADAMENTE insuficiente para reconstruir una conversacion: no guarda el
-- texto del usuario, ni la respuesta del modelo, ni el snapshot financiero, ni
-- las propuestas. Si alguna vez alguien quiere agregar una columna con
-- contenido "solo para debuggear", esa es la linea que no se cruza: la
-- politica de privacidad promete que no se retiene nada de eso en el servidor.
-- ---------------------------------------------------------------------------

create table if not exists public.ai_usage_log (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  created_at        bigint not null default (extract(epoch from now()))::bigint,
  usage_day         date   not null default ((now() at time zone 'utc')::date),
  conversation_id   text,
  provider          text not null,
  model             text not null,
  outcome           text not null
                      check (outcome in ('ok', 'blocked', 'rate_limited',
                                         'timeout', 'provider_error', 'invalid')),
  error_code        text,
  prompt_tokens     integer,
  completion_tokens integer,
  tool_rounds       integer not null default 0,
  proposals_count   integer not null default 0,
  latency_ms        integer,
  client_version    text
);

-- usage_day no es una columna generada: `at time zone` sobre timestamptz es
-- STABLE, no IMMUTABLE, y Postgres rechaza un `generated always as` con eso.
-- El default cubre el caso real (la Edge Function nunca la manda explicita).
create index if not exists ai_usage_log_user_day_idx
  on public.ai_usage_log using btree (user_id, usage_day);

alter table public.ai_usage_log enable row level security;

-- Lectura de las propias filas (util para una pantalla de "cuanto has usado"
-- en Fase B). Sin politicas de insert/update/delete: solo escribe la Edge
-- Function con service_role, para que el conteo de cupo no sea falsificable
-- desde el cliente.
drop policy if exists "Users read own ai usage" on public.ai_usage_log;
create policy "Users read own ai usage" on public.ai_usage_log
  for select to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4. Estado efectivo del gate
--
-- Una sola definicion, consumida por dos caminos con autoridad distinta:
--   - La Edge Function ai-chat la llama con service_role en CADA turno. Esa es
--     la autoridad real.
--   - La app la llama via my_ai_access_state() solo para decidir si pinta la
--     entrada al asistente. Un cliente parcheado que mienta aqui no gana nada,
--     porque ai-chat vuelve a verificar.
-- ---------------------------------------------------------------------------

create or replace function public.ai_access_state(p_user_id uuid)
 returns table (
   enabled             boolean,
   tier                text,
   daily_message_limit integer,
   used_today          integer
 )
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  with flag as (
    select coalesce(
      (select f.enabled from ai_feature_flags f
        where f.key = 'ai_assistant_open_to_all'),
      false
    ) as open_to_all
  ),
  row_ as (
    select * from ai_access a where a.user_id = p_user_id
  )
  select
    (select open_to_all from flag)
      or coalesce((select r.enabled from row_ r), false),
    coalesce((select r.tier from row_ r), 'beta'),
    coalesce((select r.daily_message_limit from row_ r), 30),
    (select count(*)::int from ai_usage_log u
      where u.user_id = p_user_id
        and u.usage_day = (now() at time zone 'utc')::date
        and u.outcome = 'ok');
$function$;

-- CRITICO: es SECURITY DEFINER y recibe el user_id como parametro. Sin este
-- revoke, cualquier usuario autenticado podria consultar el estado de otro
-- pasando su uuid — un IDOR de manual.
revoke execute on function public.ai_access_state(uuid) from public;
revoke execute on function public.ai_access_state(uuid) from anon;
revoke execute on function public.ai_access_state(uuid) from authenticated;

-- El wrapper que si expone la app: no recibe parametros, resuelve sobre
-- auth.uid(), y por lo tanto solo puede hablar del que llama.
create or replace function public.my_ai_access_state()
 returns table (
   enabled             boolean,
   tier                text,
   daily_message_limit integer,
   used_today          integer
 )
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select * from public.ai_access_state(auth.uid());
$function$;

-- Postgres concede EXECUTE a PUBLIC por defecto en toda funcion nueva, asi que
-- el grant de abajo no basta: hay que quitar primero el permiso heredado. Con
-- auth.uid() nulo esta funcion no revela datos de nadie (devuelve enabled=false),
-- pero una vez encendido el flag global le diria a cualquier anonimo que la beta
-- esta abierta, y eso es informacion de producto.
revoke execute on function public.my_ai_access_state() from public;
revoke execute on function public.my_ai_access_state() from anon;

grant execute on function public.my_ai_access_state() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Borrado de cuenta (HU-07, requisito legal Apple/Google)
--
-- Quinta extension de la misma funcion. Las dos tablas nuevas tienen user_id,
-- asi que delete_account_data_coverage_gaps() las reportaria de inmediato si
-- se omitieran — ese guardian (20260808000000) existe justo para esto.
--
-- Ambas ya cascadean desde auth.users, asi que el delete explicito es
-- redundante por diseno: delete_account_data corre ANTES de
-- auth.admin.deleteUser, y debe dejar la cuenta sin datos aunque el borrado
-- del usuario falle despues (ver supabase/functions/delete-account/index.ts).
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

  -- Control del asistente de IA. No contienen datos financieros, pero si
  -- revelan que la persona uso la funcion y cuanto: borrarlas es parte del
  -- "borra todo" que la politica de privacidad promete.
  delete from ai_usage_log where user_id = p_user_id;
  delete from ai_access where user_id = p_user_id;
end;
$function$;

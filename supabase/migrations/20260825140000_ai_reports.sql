-- Reporte in-app de contenido generado por IA.
--
-- Lo exige literalmente la AI-Generated Content policy de Google Play: "Apps
-- that generate content using AI must contain in-app user reporting or
-- flagging features that allow users to report or flag offensive content to
-- developers WITHOUT NEEDING TO EXIT THE APP". Su ausencia es causal de
-- retiro, no solo de rechazo — por eso entra en Fase A y no despues.
--
-- Ese "sin salir de la app" es lo que descarta la alternativa obvia (abrir el
-- cliente de correo con el texto prellenado) y obliga a que el reporte llegue
-- a un servidor nuestro.
--
-- ---------------------------------------------------------------------------
-- LA TENSION, Y COMO SE RESUELVE
--
-- El resto del asistente promete que NADA del contenido de una conversacion se
-- guarda en el servidor (politica de privacidad v1.5, seccion 17.5), y la Edge
-- Function ai-chat esta construida como broker sin estado justamente para que
-- esa promesa sea estructural y no una intencion.
--
-- Esta tabla es la unica excepcion, y lo es porque la dispara la persona:
--   - Nada llega aca automaticamente. Solo se escribe cuando alguien toca
--     "reportar" sobre un mensaje concreto.
--   - Se guarda SOLO el fragmento reportado, no la conversacion.
--   - La UI debe decirlo en el momento, antes de enviar: "el mensaje que
--     reportes se guarda en nuestros servidores para poder revisarlo".
--     Sin ese aviso, la seccion 17.5 de la politica queda falsa.
--
-- Es retencion pedida, no retencion silenciosa. Esa es la diferencia que
-- justifica la excepcion, y es la que hay que preservar si esto se toca.
-- ---------------------------------------------------------------------------

create table if not exists public.ai_reports (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  created_at      bigint not null default (extract(epoch from now()))::bigint,
  conversation_id text,
  -- Que le parecio mal a la persona. Lista cerrada para que la UI ofrezca
  -- opciones y no un campo libre que invite a pegar datos personales.
  reason          text not null
                    check (reason in ('offensive', 'wrong', 'harmful',
                                      'privacy', 'other')),
  -- El mensaje del asistente que se reporta. Es el unico contenido de
  -- conversacion que existe en el servidor, y llega aca porque la persona lo
  -- mando explicitamente.
  reported_text   text not null,
  -- Comentario opcional de la persona.
  comment         text,
  client_version  text,
  -- Estado de revision. Lo mueve un humano a mano; la app nunca lo escribe.
  status          text not null default 'pending'
                    check (status in ('pending', 'reviewed', 'dismissed'))
);

create index if not exists ai_reports_status_idx
  on public.ai_reports using btree (status, created_at);

alter table public.ai_reports enable row level security;

-- La persona puede crear su propio reporte y volver a leerlo (para que la UI
-- pueda mostrar "ya reportaste este mensaje"), pero no puede modificarlo ni
-- borrarlo: un reporte que se puede editar despues de enviarlo no sirve para
-- revisar nada. Tampoco puede tocar `status`, porque no hay policy de update.
drop policy if exists "Users create own ai reports" on public.ai_reports;
create policy "Users create own ai reports" on public.ai_reports
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users read own ai reports" on public.ai_reports;
create policy "Users read own ai reports" on public.ai_reports
  for select to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Borrado de cuenta (HU-07)
--
-- Sexta extension de delete_account_data. ai_reports tiene user_id, asi que
-- delete_account_data_coverage_gaps() la reportaria de inmediato si se omitiera.
--
-- Se borra con la cuenta aunque sea un reporte de moderacion: la politica
-- promete que al borrar la cuenta se elimina todo lo que esta en el servidor,
-- sin excepciones, y no vale la pena abrir una para esto.
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

  delete from ai_reports where user_id = p_user_id;
  delete from ai_usage_log where user_id = p_user_id;
  delete from ai_access where user_id = p_user_id;
end;
$function$;

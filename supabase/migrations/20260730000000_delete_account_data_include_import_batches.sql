-- Extiende delete_account_data (HU-07, requisito legal Apple/Google) para
-- incluir import_batches — quedó fuera cuando esa tabla se creó en
-- 20260729000000_import_batches.sql. Va al final del cuerpo, no al principio:
-- transactions/accounts/categories/tags tienen import_batch_id -> import_batches(id)
-- sin ON DELETE CASCADE, así que borrar import_batches antes rompería esas FKs.
CREATE OR REPLACE FUNCTION public.delete_account_data(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  delete from scheduled_payment_occurrences where user_id = p_user_id;
  delete from scheduled_payment_tags where user_id = p_user_id;
  delete from transaction_tags where user_id = p_user_id;
  delete from budget_accounts where user_id = p_user_id;
  delete from budget_categories where user_id = p_user_id;
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
end;
$function$

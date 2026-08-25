-- Corrige el orden en que PowerSync sube las claims de "reclamar" categorias
-- huerfanas (HU-04, `LocalDataOwnershipDatasource._claimCategoriesTopologically`)
-- y el orden de reimport de backups (`BackupJsonDatasource`): un hijo
-- reclamado/insertado antes de que su padre tenga `user_id` asignado violaba
-- el FK compuesto `(parent_id, user_id) references categories (id, user_id)`
-- con un 23503, aun cuando el padre SI llegaba a existir un instante despues
-- en la misma transaccion logica.
--
-- ON UPDATE CASCADE hace que, si el `user_id` de un padre cambia (el caso
-- real: pasa de NULL a un uuid al reclamarlo), Postgres propague ese cambio
-- a cualquier hijo que ya lo referenciara, en vez de rechazar el UPDATE del
-- hijo por llegar en el orden "equivocado".
--
-- Aplicado primero en supabase-dev, verificado con
-- `pg_get_constraintdef` antes de subir a prod.

alter table public.categories
  drop constraint categories_parent_id_fkey;

alter table public.categories
  add constraint categories_parent_id_fkey
  foreign key (parent_id, user_id) references public.categories (id, user_id)
  on update cascade;

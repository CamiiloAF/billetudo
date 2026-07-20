# Smoke test de sync — pruebas pendientes (2026-07-20)

Lo que falta ejercitar de Auth + Sync (`docs/requirements/05-auth-sync.md`) con un dispositivo y datos reales. Lo ya verificado está marcado en ese documento; acá solo queda lo pendiente, **en orden de ejecución**.

## Antes de empezar

- **Corré todo contra dev, no contra prod.** Dev tiene una copia exacta de los datos (los ids son deterministas, por eso coinciden). La prueba 5 borra la cuenta entera.
- Confirmá a qué entorno apunta la app: las claves salen de `Env`. Si dice producción, parás.
- Las consultas ya vienen con el `user_id` de la cuenta de dev (`19bd6a2c-10da-492e-bb1a-d51385f90968`), listas para copiar. Si alguna vez cambia la cuenta:

```sql
select id, email from auth.users;
```

---

## 1. HU-05 — UPDATE (la más importante)

**Por qué primero:** hay una sospecha concreta. El `patch` del `PowerSyncConnector` **no** estampa `user_id`. Si una fila nunca llegó a la nube, el UPDATE afecta cero filas en Postgres y **no devuelve error** — la edición se pierde sin rastro. Es el mismo patrón del bug de los inserts, que fallaba el 100% de las veces sin síntoma visible.

**Pasos**

1. Abrí un movimiento que ya exista en la nube y cambiale el monto y la nota.
2. Esperá a que el indicador de sync vuelva a "Sincronizado" (nube con check).
3. Verificá en Supabase:

```sql
select id, note, amount_minor,
       to_timestamp(updated_at / 1000) at time zone 'America/Bogota' as actualizado
from transactions
where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
order by updated_at desc
limit 5;
```

**Qué debe pasar:** el movimiento aparece con el monto y la nota nuevos, y `actualizado` con la hora de hace un momento.

**Si falla:** si el monto sigue viejo pero la app muestra el nuevo, es exactamente la sospecha — la escritura se perdió en el camino. Anotá si la fila existía en la nube antes de editarla, porque eso distingue las dos causas posibles.

4. **Repetí con una fila recién creada:** creá un movimiento nuevo, esperá a que suba, y recién entonces editalo. Este caso debería funcionar aunque el anterior falle.

---

## 2. HU-05 — DELETE

**Antes de nada: borrar un movimiento NO borra la fila en Postgres.** La app marca `deleted_at` (papelera reversible, para el undo) y deja la fila en su lugar. Las sync rules no filtran esa columna (decisión #9), así que sigue viajando a la nube. Un `count(*)` sin filtro **da lo mismo antes y después de borrar**, y eso es correcto, no un bug.

Usá siempre esta consulta, que separa los tres estados:

```sql
select count(*) as total,
       count(*) filter (where deleted_at is not null)  as en_papelera,
       count(*) filter (where tombstoned_at is not null) as lapidas,
       count(*) filter (where deleted_at is null and tombstoned_at is null) as visibles
from transactions
where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968';
```

**Pasos**

1. Corré la consulta y anotá `en_papelera` y `visibles`.
2. Borrá un movimiento desde la app.
3. Esperá a "Sincronizado" y volvé a correrla: `en_papelera` sube en 1, `visibles` baja en 1, `total` **no cambia**.
4. Para ver cuál fue:

```sql
select id, note, amount_minor,
       to_timestamp(deleted_at) at time zone 'America/Bogota' as borrado
from transactions
where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968' and deleted_at is not null
order by deleted_at desc;
```

5. **Probá el undo:** borrá otro movimiento y restauralo. `deleted_at` debe volver a `null` — o sea `en_papelera` regresa a su valor anterior. Eso confirma que el borrado viaja en ambos sentidos.

**Las dos columnas no son sinónimos** (ver CLAUDE.md → Borrado): `deletedAt` es papelera reversible de UX; `tombstonedAt` es lápida irreversible que existe para que otra tabla conserve su referencia por FK. Hoy la única feature que usa lápidas es Cuentas. Ninguna de las dos se filtra en el sync — el cliente ya las oculta en sus queries, y excluirlas del sync rompería la FK local en un dispositivo nuevo.

**Pendiente de producto, no de esta prueba:** las filas en papelera no se purgan nunca. El cron de limpieza previsto en la decisión #2 cubre lápidas, no papelera. Si el undo tiene una ventana de tiempo, alguien tiene que borrarlas de verdad al vencer.

---

## 3. HU-05 — Offline → reconexión

**Es el caso que más se parece al uso real** (metro, ascensor, mal señal) y el único que ejercita la cola de subida en serio.

**Pasos**

1. Poné el teléfono en **modo avión**.
2. Registrá **3 o 4 movimientos** y editá uno existente. La app tiene que seguir funcionando con normalidad — es local-first.
3. Verificá que el indicador de sync muestre la **nube tachada**.
4. Cerrá la app por completo y volvé a abrirla, todavía sin conexión. Los movimientos deben seguir ahí.
5. Quitá el modo avión.
6. Mirá el indicador: debe pasar a **girar** (sincronizando) y luego a nube con check.
7. Verificá que llegaron todos. Esta consulta muestra los últimos creados, así que los que registraste sin conexión deben estar arriba con su hora real de creación:

```sql
select note, amount_minor,
       to_timestamp(created_at) at time zone 'America/Bogota' as creado,
       to_timestamp(updated_at / 1000) at time zone 'America/Bogota' as subido
from transactions
where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
  and deleted_at is null
order by created_at desc
limit 8;
```

**Mirá la diferencia entre `creado` y `subido`:** `creado` debe ser la hora en que los registraste (sin conexión) y `subido` la de la reconexión. Si `creado` coincide con la reconexión en vez de con el momento real, la marca de tiempo se está generando al subir y no al escribir — sería un bug distinto, que desordena el historial.

**Si falla:** si el indicador se queda girando para siempre, la cola se atascó. Es FIFO, así que una sola operación trabada bloquea todo lo demás. Mirá el reporte de errores — desde el commit `e284dc1` los reintentos se reportan en vez de ser mudos.

---

## 4. Indicador de sync con backend real

Se valida solo mientras hacés las pruebas 1 a 3, pero conviene mirarlo a propósito porque **ningún test puede provocar estados reales de sync**.

- **Sin sesión:** nube tachada.
- **Sincronizando:** el ícono **gira** (2s por vuelta).
- **Al día:** nube con check.
- **Sin conexión:** nube tachada.

Dos cosas concretas a mirar:

- Que durante la fusión post-login **se vea girar**. Ese fue el problema original: decía "Sincronizado" mientras trabajaba y parecía colgada.
- Que no haya **parpadeo** al arrancar. Hay un caso borde conocido y documentado: si el estado inicial es `offline` y el primer evento del stream también, se emite dos veces. En los tests está fijado a propósito; falta ver si se nota en pantalla.

---

## 5. HU-07 — Borrar cuenta con ocurrencias

**Va al final porque destruye la cuenta.** Solo en dev.

**Por qué reprobarla:** la prueba anterior pasó, pero con una cuenta sin ocurrencias de pagos programados. Con ellas, el borrado fallaba **entero** (la función es atómica) porque `scheduled_payment_occurrences` referencia `scheduled_payments` y `transactions` con `NO ACTION`. Ya está corregido; falta ejercitar justo ese caso.

**Pasos**

1. Creá un pago programado y **confirmá al menos una ocurrencia** (que genere su transacción).
2. Verificá que existan de verdad:

```sql
select count(*) as ocurrencias from scheduled_payment_occurrences where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968';
select count(*) as etiquetas   from scheduled_payment_tags        where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968';
```

Si `ocurrencias` da 0, la prueba no sirve — volvé al paso 1.

3. Borrá la cuenta desde la app.
4. Verificá que **no quedó nada** en ninguna de las 14 tablas:

```sql
select 'accounts' t, count(*) from accounts where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'transactions', count(*) from transactions where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'categories', count(*) from categories where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'budgets', count(*) from budgets where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'goals', count(*) from goals where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'debts', count(*) from debts where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'tags', count(*) from tags where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'transaction_tags', count(*) from transaction_tags where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'scheduled_payments', count(*) from scheduled_payments where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'scheduled_payment_tags', count(*) from scheduled_payment_tags where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'scheduled_payment_occurrences', count(*) from scheduled_payment_occurrences where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'budget_accounts', count(*) from budget_accounts where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'budget_categories', count(*) from budget_categories where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968'
union all select 'app_settings', count(*) from app_settings where user_id = '19bd6a2c-10da-492e-bb1a-d51385f90968';
```

**Todas deben dar 0.** Y el usuario debe haber desaparecido:

```sql
select count(*) from auth.users where id = '19bd6a2c-10da-492e-bb1a-d51385f90968';
```

5. Confirmá que la app quedó **usable sin cuenta**, no rota ni en una pantalla de error.

**Si falla:** un error de tipo "violates foreign key constraint" significa que falta otra tabla en el orden de borrado.

---

## 6. HU-02 — Login con Google

Ya se probó una vez, pero **antes** de que PowerSync estuviera cableado, y esa vez la fusión falló. Falta reprobarlo ahora.

1. Desinstalá la app (eso borra la SQLite local).
2. Sin iniciar sesión, creá una cuenta y un par de movimientos.
3. Iniciá sesión con Google.
4. Verificá que la fusión no duplique nada y que tus datos locales suban.

---

## 7. Primer arranque sin conexión

`FirstLaunchOfflineGate` nunca se ejercitó en un dispositivo.

1. Desinstalá la app.
2. Poné el teléfono en **modo avión**.
3. Abrí la app: debe aparecer la pantalla de bloqueo con "Reintentar", **no** un crash ni una app vacía.
4. Quitá el modo avión y tocá "Reintentar": debe sembrar las categorías y seguir al flujo normal.

**Por qué existe:** el catálogo de categorías se baja de Supabase en el primer arranque (decisión #12), así que ese único momento sí requiere red. Es la excepción documentada al "funciona sin conexión" de HU-01.

---

## Qué anotar si algo falla

Para cada fallo, tres cosas hacen la diferencia entre poder diagnosticarlo o no:

1. **Qué mostraba el indicador de sync** en ese momento.
2. **Si la fila existía en la nube antes** de la operación (para UPDATE y DELETE).
3. **Si el dato sobrevive a cerrar y reabrir la app** — distingue "no se guardó localmente" de "no se subió".

El síntoma más engañoso ya lo vimos: *aparece y desaparece solo*. Eso no es un bug de la pantalla, es una escritura rechazada por el servidor que PowerSync revierte al reconciliar.

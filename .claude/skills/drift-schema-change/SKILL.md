---
name: drift-schema-change
description: Guia y ejecuta un cambio seguro al esquema Drift de finance_app (nueva tabla/columna, schemaVersion, migracion, regeneracion de codigo, recordatorio de Supabase/PowerSync).
---

# drift-schema-change

Uso: `/drift-schema-change <descripcion del cambio>` (ej. `/drift-schema-change anadir columna "notes" a Goals`).

## Pasos

1. Si no hay descripcion del cambio, pregunta que tabla/columna se anade, modifica o elimina.
2. Delega el cambio al subagente `drift-migration-helper` (via Agent, subagent_type: `drift-migration-helper`), describiendole exactamente el cambio pedido.
3. Cuando el subagente termine, confirma con el usuario:
   - Que `schemaVersion` subio y la migracion quedo escrita (no solo la tabla nueva).
   - Que `dart run build_runner build --delete-conflicting-outputs` corrio sin errores.
   - Que se le recordo al usuario replicar el cambio en el esquema de Supabase/PowerSync (este flujo no toca Supabase directamente).
4. Si el cambio afecta una tabla que ya tiene features construidas encima (`lib/features/*`), advierte cuales carpetas probablemente necesiten actualizarse (modelos/DTOs en `data/`, entidades en `domain/`) en vez de asumir que siguen compilando.

No inventes el cambio de esquema si el usuario no lo especifico con suficiente detalle (nombre de tabla, nombre y tipo de columna) — pregunta antes de tocar `app_database.dart`.

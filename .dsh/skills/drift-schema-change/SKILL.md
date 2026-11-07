---
name: drift-schema-change
description: Guia y ejecuta un cambio seguro al esquema Drift de billetudo (nueva tabla/columna, schemaVersion, migracion, regeneracion de codigo, recordatorio de Supabase/PowerSync).
whenToUse: "Úsalo al añadir, modificar o eliminar tablas o columnas Drift, subir `schemaVersion` o escribir una migración en `app_database.dart`."
metadata:
  source: claude-code
  original: .claude/skills/drift-schema-change/SKILL.md
---

# drift-schema-change

Uso: `/drift-schema-change <descripcion del cambio>` (ej. `/drift-schema-change anadir columna "notes" a Goals`).

## Pasos

1. Si no hay descripcion del cambio, pregunta que tabla/columna se anade, modifica o elimina.
2. Delega el cambio al rol `drift-migration-helper`: lee `.dsh/agents/drift-migration-helper.md` y lanza la tool `subagent` con un prompt = ese rol completo + el cambio exacto que se pidio; pídele un reporte final.
3. Cuando el subagente termine, confirma con el usuario:
   - Que `schemaVersion` subio y la migracion quedo escrita (no solo la tabla nueva).
   - Que `dart run build_runner build --force-jit` corrio sin errores.
   - Que se le recordo al usuario replicar el cambio en el esquema de Supabase/PowerSync (este flujo no toca Supabase directamente).
   - **Si el cambio crea una tabla (o una columna nueva en una tabla ya sincronizada), pedir confirmacion explicita de la cuarta pieza: la query del Sync Stream de PowerSync agregada y desplegada en dev y prod.** No alcanza con mencionarlo: el flujo no termina hasta que el usuario lo confirme. Sin esa pieza, PowerSync sube las filas nuevas y despues **las borra del dispositivo** al materializar el siguiente checkpoint (las filas locales que faltan en los datos sincronizados se eliminan; ver `docs/dev-runs/capturas-desaparecen-al-sincronizar.md`, 2026-11-07). Un test del repo no puede cubrir esto porque requiere sesion + sync reales; la verificacion es manual, en dispositivo.
4. Si el cambio afecta una tabla que ya tiene features construidas encima (`lib/features/*`), advierte cuales carpetas probablemente necesiten actualizarse (modelos/DTOs en `data/`, entidades en `domain/`) en vez de asumir que siguen compilando.

No inventes el cambio de esquema si el usuario no lo especifico con suficiente detalle (nombre de tabla, nombre y tipo de columna) — pregunta antes de tocar `app_database.dart`.

## En DeepSeek Harness

- Invocación: escribe `/drift-schema-change <descripción>` en un mensaje (token delimitado por espacios) para inyectar este skill; el modelo también puede cargarlo con la tool `skill`.
- Delegación: el rol vive en `.dsh/agents/drift-migration-helper.md`; lee ese `.md` y lanza la tool `subagent` con un prompt = rol completo + tarea concreta, pidiendo un reporte final.
- Contrato del repo: `CLAUDE.md` + `AGENTS.md` en la raíz; mandan las reglas de esquema (mixin `_SyncColumns`, `deletedAt` vs `tombstonedAt`, IDs UUID).
- Nunca hagas commit: deja los cambios sin commitear en el working tree para que el usuario los revise.

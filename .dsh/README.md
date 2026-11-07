# `.dsh/` — capa de DeepSeek Harness de Billetudo

Configuración versionada para trabajar el repo con DSH. La guía de uso está en
[`AGENTS.md`](../AGENTS.md); el detalle de la migración Claude → DSH y los pasos manuales
pendientes están en [`docs/dsh-migration.md`](../docs/dsh-migration.md).

```
.dsh/
├── agents/      # playbooks de subagente (rol completo, se pasan como prompt)
├── skills/      # skills de proyecto; se invocan con /nombre (descubiertas de .dsh/skills)
├── workflows/   # scripts JS para la tool `workflow` + su meta JSON
└── profile/     # ejemplo de patch para ~/.dsh/profiles/desktop/cordis.patch.yml
```

## Por qué está así

- **DSH descubre `/.dsh/skills/<name>/SKILL.md`** en la raíz del repo (rank 100). Requiere
  frontmatter con `name` kebab-case + `description`. Las skills de `.claude/skills` **no** se
  descubren; por eso están portadas acá.
- **DSH no tiene agentes por proyecto.** El Lead lee `.dsh/agents/<rol>.md` y lo pasa como
  prompt a la tool `subagent`. Los `tools:` de Claude no son enforceables acá: el alcance se
  declara en el playbook y el sandbox de DSH es la barrera real.
- **DSH no tiene registro de workflows por nombre.** La tool `workflow` recibe `script`
  inline, así que los scripts se guardan como cuerpo (sin `export const meta`) y el meta va
  aparte en `<nombre>.meta.json`.
- **Los workflows viejos de Claude** usaban `agentType`, `effort` y `workflow()` anidado;
  el port los reemplaza por lectura de playbooks, y agrega guards porque `agent()` de DSH
  devuelve `null` cuando un hijo falla.

## MCP (Pencil / Supabase)

Se configura en el **perfil** de DSH, no en el repo: copiá el bloque de
[`profile/cordis.patch.example.yml`](profile/cordis.patch.example.yml) al final de
`~/.dsh/profiles/desktop/cordis.patch.yml` y reiniciá DSH. Pencil además necesita la app
Pencil abierta.

## Regla de mantenimiento

`.claude/` se conserva como legado (Claude Code). La fuente de verdad para agentes DSH es
`.dsh/`. Si cambiás un playbook, una skill o un workflow, cambialo **solo acá**;
duplicar el cambio en `.claude/` reintroduce la deriva que esta migración elimina.

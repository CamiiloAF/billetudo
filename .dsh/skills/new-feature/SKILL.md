---
name: new-feature
description: Crea la estructura Clean Architecture (domain/data/presentation) para una nueva feature de billetudo en lib/features/<nombre>/, con archivos base listos para editar.
whenToUse: "Úsalo para crear el boilerplate Clean Architecture de una feature nueva en `lib/features/<nombre>/`, sin lógica de negocio real."
metadata:
  source: claude-code
  original: .claude/skills/new-feature/SKILL.md
---

# new-feature

Uso: `/new-feature <nombre>` (ej. `/new-feature budgets`).

Objetivo: dejar creada la estructura minima y correcta de una feature nueva, sin que Claude tenga que redescubrir la convencion cada vez.

## Pasos

1. Lee `CLAUDE.md` en la raiz del repo (secciones de arquitectura y convenciones criticas) si no lo tienes ya en contexto.
2. Si el argumento `<nombre>` no viene, pregunta cual es antes de continuar.
3. Verifica si `lib/features/<nombre>/` ya existe con contenido mas alla de `.gitkeep`. Si es asi, no sobrescribas — reporta lo que ya hay y pregunta si continuar.
4. Lee `.dsh/workflows/feature-scaffold.meta.json` y `.dsh/workflows/feature-scaffold.js`, y ejecuta la tool `workflow` con:
   - `meta` = el JSON del `.meta.json` (parseado, sin modificar).
   - `script` = el cuerpo del `.js` **sin modificar**.
   - `args` = `{ name: '<nombre>' }`, más cualquier detalle de dominio que el usuario haya dado (ej. campos especificos, relaciones con otras tablas).
   - Si la tool `workflow` no está disponible, orquesta la misma secuencia con `subagent`: lee `.dsh/agents/feature-scaffolder.md` y lanza `subagent` con el rol completo + nombre/tareas de la feature; luego repite el ciclo por capa (domain → data → presentation) en el mismo orden y gate que el workflow.
5. Cuando termine, revisa el resultado con el rol `finance-code-reviewer` (lee `.dsh/agents/finance-code-reviewer.md` y lanza `subagent` con rol completo + el diff/archivos creados; pídele reporte final) antes de reportar exito al usuario.
6. Resume al usuario: archivos creados, y los pendientes tipicos (wiring en `lib/core/di/`, registrar el bloc/cubit en el arbol de widgets, tests, y si la feature toca dinero/anuncios/IA, sugerir tambien correr `/tier0-check`).

No implementes la logica de negocio real de la feature en este flujo — el scaffold es boilerplate estructural (entidades, interfaces, casos de uso con TODOs razonables, bloc con estados basicos). La logica especifica se construye despues, en una conversacion aparte, sobre esta base.

## En DeepSeek Harness

- Invocación: escribe `/new-feature <nombre>` en un mensaje (token delimitado por espacios) para inyectar este skill; el modelo también puede cargarlo con la tool `skill`.
- Workflow: el scaffold vive en `.dsh/workflows/feature-scaffold.js` + `feature-scaffold.meta.json`; se ejecuta con la tool `workflow` (`meta`/`script`/`args`), sin editar el script.
- Delegación: los roles viven en `.dsh/agents/` (`feature-scaffolder.md`, `finance-code-reviewer.md`); lee el `.md` del rol y lanza `subagent` con rol completo + tarea, pidiendo reporte final.
- Contrato del repo: `CLAUDE.md` + `AGENTS.md` en la raíz; la estructura feature-first con domain/data/presentation y DI en `lib/core/di/` es obligatoria.
- Nunca hagas commit: deja los archivos creados sin commitear para que el usuario los revise.

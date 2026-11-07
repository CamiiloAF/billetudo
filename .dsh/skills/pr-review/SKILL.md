---
name: pr-review
description: Revisión integral de un Pull Request de billetudo en GitHub con el subagente pr-reviewer - contexto del PR via gh, verificación mecánica en worktree aislado (analyze, format, paridad de esquema, tests), todas las reglas del repo y revisión de corrección, con veredicto claro. Publica en el PR solo con --post.
whenToUse: "Úsalo antes de mergear un PR de GitHub de billetudo, sobre todo si toca `app_database.dart`, `supabase/migrations/`, `lib/core/sync/` o `docs/legal/`."
metadata:
  source: claude-code
  original: .claude/skills/pr-review/SKILL.md
---

# pr-review

Uso: `/pr-review <número o URL de PR> [--post]`

- Sin argumento: lista los PRs abiertos con `gh pr list` y pregunta cuál revisar. Si la rama actual tiene PR abierto (`gh pr view --json number`), ofrécelo como opción por defecto.
- `--post`: autoriza al subagente a publicar el reporte como comentario de revisión en GitHub (y a aprobar si el veredicto es APROBAR). Sin este flag el reporte se queda en la conversación.

## Pasos

1. Resuelve el número de PR (acepta `36`, `#36` o la URL completa).
2. Delega la revisión completa al rol `pr-reviewer`: lee `.dsh/agents/pr-reviewer.md` y lanza la tool `subagent` con un prompt = ese rol completo + el número de PR, la rama base si la conoces, y **explícitamente** si el usuario puso `--post` o no — el subagente no publica nada sin esa autorización en su prompt. Pídele un reporte final.
3. Cuando termine, relata el reporte al usuario **tal cual lo estructuró** (veredicto, tabla de ejecución, bloqueantes, importantes, menores, lo no verificado, verificación manual). No lo resumas a una frase ni le quites los `archivo:línea`.
4. Si hubo bloqueantes y el usuario quiere corregirlos, eso es otro flujo: para fixes puntuales ya diagnosticados usa `flutter-dev` + `qa-automator` directo (no `/feature-dev`, ver CLAUDE.md "Tamaño del cambio"). Nunca corrijas el PR desde este skill sin que el usuario lo pida.
5. Nunca hagas merge ni cierres el PR. Ese es un acto del usuario.

## Cuándo usarlo

Antes de mergear cualquier PR, especialmente los que tocan `app_database.dart`, `supabase/migrations/`, `lib/core/sync/` o `docs/legal/`. Este skill es solo para PRs de GitHub: un diff local sin PR queda fuera de alcance; para eso usa directo los subagentes `flutter-dev` + `qa-automator` y los revisores de convenciones/compliance/aspecto visual, según CLAUDE.md ("Tamaño del cambio").

## En DeepSeek Harness

- Invocación: escribe `/pr-review <número|URL> [--post]` en un mensaje (token delimitado por espacios) para inyectar este skill; el modelo también puede cargarlo con la tool `skill`.
- Delegación: el rol vive en `.dsh/agents/pr-reviewer.md`; lee ese `.md` y lanza la tool `subagent` con el rol completo + la tarea concreta (número de PR, rama base, `--post` sí/no), pidiendo el reporte estructurado completo.
- Gate de publicación: `gh` se sigue usando igual (lectura con `gh pr view`/`gh pr list`/`gh pr diff`, escritura solo con `--post`). Sin `--post`, nada se publica en GitHub ni se aprueba el PR.
- Contrato del repo: `CLAUDE.md` + `AGENTS.md` en la raíz; sus reglas mandan sobre este skill.
- Nunca hagas commit ni merge desde este skill: solo lee y publica comentarios de revisión con `--post`.

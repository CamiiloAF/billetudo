---
name: feature-dev
description: Entrega una feature completa de billetudo en una sola corrida multi-agente - triage automatico del esfuerzo, implementacion Clean Architecture, tests (unit/widget/Patrol) y review escalado al riesgo. Un solo artefacto de salida en docs/dev-runs/.
whenToUse: "Úsalo para implementar una feature o mejora de billetudo de punta a punta (triage s/m/l, build, tests, review). Para solo scaffold usa `/new-feature`; para solo revisar, los subagentes puntuales."
metadata:
  source: claude-code
  original: .claude/skills/feature-dev/SKILL.md
---

# feature-dev

Uso: `/feature-dev <descripcion de la feature o ruta a una nota>`

Objetivo: una ejecución = una feature completa y verificada, sin que el usuario tenga que elegir nivel de esfuerzo ni correr fases por separado. El workflow dimensiona solo (s/m/l) y escala agentes, tests y review al riesgo real.

## Pasos

1. Si no viene descripción, pregunta qué feature construir antes de continuar.
2. Lee `.dsh/workflows/feature-dev.meta.json` y `.dsh/workflows/feature-dev.js`, y ejecuta la tool `workflow` con:
   - `meta` = el JSON del `.meta.json` (parseado, sin modificar).
   - `script` = el cuerpo del `.js` **sin modificar**.
   - `args` = `{ source: '<descripcion o ruta>' }`. Si el usuario pidió explícitamente un tamaño ("hazlo ligero", "esto es grande/riesgoso"), pásalo como `size: 's'|'m'|'l'`. En cualquier otro caso NO fuerces tamaño — el triage decide.
   - Si la tool `workflow` no está disponible, orquesta la misma secuencia de fases con la tool `subagent`, en orden (Plan → Build → Test → Review → Fidelity → Close): lee cada rol de `.dsh/agents/<rol>.md`, lanza `subagent` con un prompt = ese rol completo + la tarea de la fase, y espera su reporte final antes de la siguiente fase. No omitas ni reordenes fases ni gates.
3. Al terminar, relata al usuario el resultado del objeto retornado: qué se implementó, estado de tests/review, gaps de cobertura, el checklist de verificación manual (👤) y dónde quedó el resumen (`docs/dev-runs/<slug>.md`).
4. Recuérdale que el código quedó **sin commitear** para su revisión.
5. Si el workflow retornó `aborted: true`, la petición violaba una regla de negocio de CLAUDE.md — explica el bloqueo, no intentes implementarla por otra vía.

No dupliques el trabajo del workflow revisando o testeando tú mismo después; el resultado ya viene verificado. Solo interviene si el retorno trae `remainingBlockers` y el usuario pide resolverlos.

## En DeepSeek Harness

- Invocación: escribe `/feature-dev <descripción>` en un mensaje (token delimitado por espacios) para inyectar este skill; el modelo también puede cargarlo con la tool `skill`.
- Workflow: los scripts viven en `.dsh/workflows/feature-dev.js` + `feature-dev.meta.json`; se ejecutan con la tool `workflow` (`meta`/`script`/`args`), sin editar el script. Si la tool no está disponible, orquesta las mismas fases con `subagent` secuencial.
- Delegación: los roles viven en `.dsh/agents/` (`architect`, `flutter-dev`, `qa-automator`, revisores, `pencil-fidelity-reviewer`); lee el `.md` del rol y lanza `subagent` con rol completo + tarea, pidiendo reporte final.
- Contrato del repo: `CLAUDE.md` + `AGENTS.md` en la raíz; sus reglas de negocio mandan (dinero en enteros, UUID, `deletedAt` vs `tombstonedAt`, Nivel 0 gratis, sin API keys en la app).
- Nunca hagas commit: el workflow deja el código sin commitear; no commitees tú tampoco.

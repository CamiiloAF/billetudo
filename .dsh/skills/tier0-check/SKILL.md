---
name: tier0-check
description: Checklist de cumplimiento de negocio y legal de billetudo antes de cerrar una feature (Nivel 0 gratis intacto, cupos server-side, AdMob SSV, borrado de cuenta, disclaimers de IA, tono positivo).
whenToUse: "Úsalo antes de cerrar una feature que toque monetización, cupos, Nivel 0, legal, borrado de cuenta, anuncios o IA, para verificar cumplimiento de negocio y legal."
metadata:
  source: claude-code
  original: .claude/skills/tier0-check/SKILL.md
---

# tier0-check

Uso: `/tier0-check [ruta o nombre de feature]`. Sin argumento, revisa el diff/cambios actuales (`git status` / `git diff`).

## Pasos

1. Delega la revision al rol `compliance-reviewer`: lee `.dsh/agents/compliance-reviewer.md` y lanza la tool `subagent` con un prompt = ese rol completo + el alcance (ruta, feature, o "diff actual"); pídele un reporte final.
2. Si el subagente reporta hallazgos, preséntalos priorizados: primero cualquier feature de Nivel 0 bloqueada por pago/anuncio (bloqueante para lanzar), luego cupos validados solo en cliente, luego el resto.
3. No corrijas los hallazgos automaticamente sin que el usuario lo pida — este flujo es de verificacion, no de arreglo. Pregunta si quiere que se apliquen los fixes.
4. Si el alcance incluye la feature de borrado de cuenta o cualquier feature de IA/coach, verifica explicitamente (aunque el subagente no lo mencione) que exista el flujo de borrado real en Supabase y el disclaimer "no es asesoria financiera" respectivamente — son requisitos de aprobacion de tienda, no opcionales.
5. Cierra con un veredicto claro: "listo para Nivel 0" / "bloqueado por: ..." — no dejes la conclusion ambigua.

## En DeepSeek Harness

- Invocación: escribe `/tier0-check [ruta|feature]` en un mensaje (token delimitado por espacios) para inyectar este skill; el modelo también puede cargarlo con la tool `skill`.
- Delegación: el rol vive en `.dsh/agents/compliance-reviewer.md`; lee ese `.md` y lanza la tool `subagent` con el rol completo + el alcance concreto, pidiendo reporte final.
- Contrato del repo: `CLAUDE.md` + `AGENTS.md` en la raíz; mandan las reglas de Nivel 0, monetización, legal y tono positivo.
- Nunca hagas commit: este flujo es de verificación y no modifica archivos salvo que el usuario pida los fixes.

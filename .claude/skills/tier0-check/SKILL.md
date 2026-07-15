---
name: tier0-check
description: Checklist de cumplimiento de negocio y legal de billetudo antes de cerrar una feature (Nivel 0 gratis intacto, cupos server-side, AdMob SSV, borrado de cuenta, disclaimers de IA, tono positivo).
---

# tier0-check

Uso: `/tier0-check [ruta o nombre de feature]`. Sin argumento, revisa el diff/cambios actuales (`git status` / `git diff`).

## Pasos

1. Delega la revision al subagente `compliance-reviewer` (via Agent, subagent_type: `compliance-reviewer`), indicandole el alcance (ruta, feature, o "diff actual").
2. Si el subagente reporta hallazgos, preséntalos priorizados: primero cualquier feature de Nivel 0 bloqueada por pago/anuncio (bloqueante para lanzar), luego cupos validados solo en cliente, luego el resto.
3. No corrijas los hallazgos automaticamente sin que el usuario lo pida — este flujo es de verificacion, no de arreglo. Pregunta si quiere que se apliquen los fixes.
4. Si el alcance incluye la feature de borrado de cuenta o cualquier feature de IA/coach, verifica explicitamente (aunque el subagente no lo mencione) que exista el flujo de borrado real en Supabase y el disclaimer "no es asesoria financiera" respectivamente — son requisitos de aprobacion de tienda, no opcionales.
5. Cierra con un veredicto claro: "listo para Nivel 0" / "bloqueado por: ..." — no dejes la conclusion ambigua.

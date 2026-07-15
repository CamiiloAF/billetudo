---
name: feature-dev
description: Entrega una feature completa de billetudo en una sola corrida multi-agente - triage automatico del esfuerzo, implementacion Clean Architecture, tests (unit/widget/Patrol) y review escalado al riesgo. Un solo artefacto de salida en docs/dev-runs/.
---

# feature-dev

Uso: `/feature-dev <descripcion de la feature o ruta a una nota>`

Objetivo: una ejecución = una feature completa y verificada, sin que el usuario tenga que elegir nivel de esfuerzo ni correr fases por separado. El workflow dimensiona solo (s/m/l) y escala agentes, tests y review al riesgo real.

## Pasos

1. Si no viene descripción, pregunta qué feature construir antes de continuar.
2. Lanza el workflow con la descripción tal cual:
   `Workflow({ name: 'feature-dev', args: '<descripcion o ruta>' })`
   - Si el usuario pidió explícitamente un tamaño ("hazlo ligero", "esto es grande/riesgoso"), pásalo: `args: { source: '<descripcion>', size: 's'|'m'|'l' }`. En cualquier otro caso NO fuerces tamaño — el triage decide.
3. Al terminar, relata al usuario el resultado del objeto retornado: qué se implementó, estado de tests/review, gaps de cobertura, el checklist de verificación manual (👤) y dónde quedó el resumen (`docs/dev-runs/<slug>.md`).
4. Recuérdale que el código quedó **sin commitear** para su revisión.
5. Si el workflow retornó `aborted: true`, la petición violaba una regla de negocio de CLAUDE.md — explica el bloqueo, no intentes implementarla por otra vía.

No dupliques el trabajo del workflow revisando o testeando tú mismo después; el resultado ya viene verificado. Solo interviene si el retorno trae `remainingBlockers` y el usuario pide resolverlos.

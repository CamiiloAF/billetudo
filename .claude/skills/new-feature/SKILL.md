---
name: new-feature
description: Crea la estructura Clean Architecture (domain/data/presentation) para una nueva feature de billetudo en lib/features/<nombre>/, con archivos base listos para editar.
---

# new-feature

Uso: `/new-feature <nombre>` (ej. `/new-feature budgets`).

Objetivo: dejar creada la estructura minima y correcta de una feature nueva, sin que Claude tenga que redescubrir la convencion cada vez.

## Pasos

1. Lee `CLAUDE.md` en la raiz del repo (secciones de arquitectura y convenciones criticas) si no lo tienes ya en contexto.
2. Si el argumento `<nombre>` no viene, pregunta cual es antes de continuar.
3. Verifica si `lib/features/<nombre>/` ya existe con contenido mas alla de `.gitkeep`. Si es asi, no sobrescribas — reporta lo que ya hay y pregunta si continuar.
4. Delega la generacion completa al subagente `feature-scaffolder` (vía Agent, subagent_type: `feature-scaffolder`), pasandole el nombre de la feature y cualquier detalle de dominio que el usuario haya dado (ej. campos especificos, relaciones con otras tablas).
5. Cuando el subagente termine, revisa su resultado con el subagente `finance-code-reviewer` antes de reportar exito al usuario.
6. Resume al usuario: archivos creados, y los pendientes tipicos (wiring en `lib/core/di/`, registrar el bloc/cubit en el arbol de widgets, tests, y si la feature toca dinero/anuncios/IA, sugerir tambien correr `/tier0-check`).

No implementes la logica de negocio real de la feature en este flujo — el scaffold es boilerplate estructural (entidades, interfaces, casos de uso con TODOs razonables, bloc con estados basicos). La logica especifica se construye despues, en una conversacion aparte, sobre esta base.

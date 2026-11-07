# AGENTS.md — Billetudo en DeepSeek Harness (DSH)

Este archivo es la **capa de tooling DSH**. El contrato del proyecto sigue siendo
[`CLAUDE.md`](CLAUDE.md): arquitectura, convenciones críticas, reglas de negocio y
requisitos legales. DSH carga automáticamente **ambos** (`CLAUDE.md` y `AGENTS.md`) al
iniciar cada sesión, así que no repitas aquí las reglas de dominio: están en `CLAUDE.md`.

> **Antes de confiar en "Estado del repo" de `CLAUDE.md` o en "Estado actual" de `README.md`:
> esas secciones están desactualizadas.** Verificado el 2026-11-07: `schemaVersion` es **35**
> (no 28), hay **25 tablas** (no 20), y `capture`, `ai` e `improvement` ya tienen código.
> Estado verificado y checklist de arranque en [`docs/dsh-migration.md`](docs/dsh-migration.md).

---

## Mapa de archivos (dónde vive cada cosa)

| Necesito… | Archivo |
|---|---|
| Contrato del proyecto (arquitectura, dinero, UUID, Drift, negocio) | `CLAUDE.md` |
| Convenciones de código completas (widgets, l10n, nombres, estado) | `docs/convenciones-de-codigo.md` |
| Sistema de diseño (tokens, tipografía, componentes, tono) | `design-system/billetudo/MASTER.md` + `design-system/billetudo/pages/<pantalla>.md` |
| Diseño real (frame aprobado) | `billetudo.pen` — **solo vía MCP Pencil** |
| Requerimientos por fase | `docs/requirements/` (índice en `docs/requirements/README.md`) |
| Registro de una feature ya hecha | `docs/dev-runs/<slug>.md` |
| Estado de e2e / fidelidad visual | `docs/patrol-e2e-tracking.md`, `docs/fidelidad-visual-tracking.md` |
| Skills invocables con `/nombre` | `.dsh/skills/<nombre>/SKILL.md` |
| Playbooks de subagente | `.dsh/agents/<rol>.md` |
| Workflows JS deterministas | `.dsh/workflows/<nombre>.js` + `.meta.json` |
| Config del perfil DSH (MCP Pencil, sandbox) | `.dsh/profile/cordis.patch.example.yml` |
| Migración Claude → DSH (qué se portó y qué falta) | `docs/dsh-migration.md` |

---

## Skills (se invocan como `/nombre` o con la tool `skill`)

| Skill | Uso |
|---|---|
| `/feature-dev <descripción o ruta a nota>` | Feature completa de punta a punta (triage → build → tests → review → fidelidad → cierre). El workflow principal. |
| `/new-feature <nombre>` | Solo el boilerplate Clean Architecture de una feature nueva. |
| `/drift-schema-change <cambio>` | Cambio seguro de esquema Drift + `schemaVersion` + migración + paridad Supabase/PowerSync. |
| `/tier0-check [ruta]` | Checklist de negocio/legal antes de cerrar una feature (Nivel 0, cupos server-side, SSV, disclaimers, borrado de cuenta). |
| `/design-fidelity-check <feature>` | Fidelidad visual completa contra Pencil usando goldens (sin emulador). |
| `/pr-review <número|url> [--post]` | Revisión integral de un PR con el rol `pr-reviewer` (worktree aislado, analyze/format/paridad/tests). |
| `ui-ux-pro-max` | Base de inteligencia UI/UX (catálogo local). La cargan `ui-ux-reviewer` y el diseño. |

**Tamaño del cambio:** una feature nueva, multi-capa, cambio de esquema o regla de negocio →
`/feature-dev`. Un fix pequeño ya diagnosticado → subagente puntual (`flutter-dev` +
`qa-automator` + reviewer), sin workflow completo. Cambio mecánico (renombrar, mover doc) →
editar directo.

---

## Delegación a subagentes (protocolo DSH)

DSH **no** tiene un registro de agentes por proyecto ni `subagent_type`. Elige la tool según el caso:

- **`subagent`** — contexto **fresco**: solo ve el `prompt` que le pasás. Es la opción por defecto para trabajo independiente y paralelo (varios a la vez, scopes disjuntos).
- **`subagent_fork`** — hereda **esta conversación** (los turnos ya completados). Úsalo para fixes chicos secuenciales o continuaciones que ya dependen del contexto acumulado: evita que el hijo re-lea todo el repo y pague el costo de reconstruir el estado.
- **`spawn_teammate` + tablero compartido** — Agent Teams para varios **escritores a la vez** (`team_task_create` con `write_scopes` disjuntos, `spawn_teammate` con `context: fresh|fork`, `wait_agent` para esperar). El Lead revisa el diff final y corre la verificación.

Reglas para cualquier hijo:

1. Leé el rol: `.dsh/agents/<rol>.md`.
2. Un `subagent` recibe `prompt` = **contenido del rol + tarea concreta + formato de salida esperado**. (El rol ya incluye el "Contrato del subagente DSH": reporte final, no commits, no archivos de reporte.)
3. Si necesitás varios en paralelo, lanzalos juntos y seguí trabajando.
4. **El Lead revisa el diff final y corre los tests.** Ningún subagente commitea.

Roles disponibles en `.dsh/agents/`:

| Rol | Para qué | Escritura permitida |
|---|---|---|
| `architect` | Triage s/m/l, criterios de aceptación, change map | ninguna (solo lectura) |
| `flutter-dev` | Implementación `lib/` (+ tests pegados al código) | `lib/`, `test/`, `integration_test/`, `pubspec.yaml` si el plan lo exige |
| `qa-automator` | Dueño del testing: unit/widget/golden/Patrol | solo `test/` e `integration_test/` |
| `feature-scaffolder` | Boilerplate domain/data/presentation | `lib/features/<feature>/` |
| `drift-migration-helper` | Cambios de esquema Drift seguros | `lib/core/database/`, migraciones, Supabase |
| `finance-code-reviewer` | Dinero, UUID, `updatedAt`, capas, estilo | ninguna (solo lectura) |
| `ui-convention-reviewer` | Las 3 reglas de widgets/UI que ningún lint cubre | ninguna (solo lectura) |
| `compliance-reviewer` | Nivel 0, cupos server-side, SSV, legal, tono | ninguna (solo lectura) |
| `pencil-designer` | Dibujar/editar pantallas en `billetudo.pen` | `billetudo.pen` + `design-system/` |
| `ui-ux-reviewer` | Auditar el canvas (jerarquía, a11y, sistema, tono) | anotaciones en el `.pen` |
| `pencil-fidelity-reviewer` | Goldens vs. `nodeId` de Pencil | ninguna (solo lectura) |
| `patrol-e2e-runner` | Correr suites Patrol ya escritas (flavor `dev` únicamente) | ninguna (solo lectura) |
| `pr-reviewer` | Revisión integral de PR de GitHub | worktree desechable |
| `privacy-legal-officer` | Documentos legales a partir del comportamiento real | `docs/legal/` (invocación manual) |

Para trabajo **paralelo de equipo** (varios escritores a la vez) usá Agent Teams:
`spawn_teammate` con scopes de escritura disjuntos, `team_task_create` con
`write_scopes`, y esperá con `wait_agent`; el Lead corre la verificación final.

---

## Workflows (tool `workflow`)

Los scripts viven en `.dsh/workflows/`:

- `feature-dev.js` + `feature-dev.meta.json` — pipeline completo (Plan → Build → Test →
  Review → Fidelity → Close), con fix loops y verificación adversarial.
- `feature-scaffold.js` + `feature-scaffold.meta.json` — boilerplate Clean Architecture en un solo agente.
- `feature-review.js` + `feature-review.meta.json` — revisión multi-dimensión con
  verificación adversarial de cada hallazgo.

**Cómo ejecutarlos:** leé el `.meta.json` y el `.js`, y llamá la tool `workflow` con
`meta` = JSON parseado, `script` = **cuerpo del archivo sin modificar**, y `args` (objeto):

```js
// feature-dev:      { source: "<descripción o ruta a nota>", size?: "s" | "m" | "l" }
// feature-scaffold: { name: "<feature>" }
// feature-review:   { feature: "<feature>" }
```

No edites el script para "arreglarlo" en caliente: si falla, corregí el archivo. Si la tool
`workflow` no está disponible, orquestá las mismas fases con `subagent` en secuencia.

---

## Gate de Pencil (obligatorio para UI)

- El `.pen` está **encriptado**: solo se lee con las tools MCP `mcp__pencil__*`. En DSH se
  configuran en el perfil (`.dsh/profile/cordis.patch.example.yml`, plugin
  `@deepseek-ai/dsh-mcp-client`). Requiere la **app Pencil abierta** en desktop.
- Tools reales: `mcp__pencil__get_app_state` y `mcp__pencil__execute`; dentro de `execute`:
  `Get`, `GetVariables`, `Print`, `TakeScreenshot` (lectura) e `Insert`/`Update`/... (escritura,
  solo `pencil-designer`). También existen `mcp__pencil__get_style` y
  `mcp__pencil__read_skill` (guías genéricas de Pen.dev, no el sistema del proyecto) y
  `mcp__pencil__browser`. **No existe** `get_screenshot`/`get_guidelines`/`export_nodes`: para
  una captura real usá `TakeScreenshot([nodeId,...])` dentro de `execute`.
- Orden de lectura: `pages/<pantalla>.md` → `MASTER.md` → `billetudo.pen` (si difieren,
  manda el `.pen` y se corrige el `.md`).
- **Si Pencil no responde, la UI se detiene.** No se implementa a ciegas desde el `.md` solo:
  eso ya produjo deriva visual real en Pagos Programados.

---

## Flutter: toolchain y sandbox DSH

Comandos (del `CLAUDE.md`, ya verificados): `flutter pub get`; `dart run build_runner build
--force-jit`; `flutter gen-l10n`; `flutter analyze`; `flutter test`; `flutter run`.

- **`--force-jit` no es opcional** y `--delete-conflicting-outputs` ya no existe.
- **Código generado:** `*.g.dart` está gitignoreado. En un clon nuevo no existe y hay que
  correr `flutter pub get` + `build_runner` antes de `analyze`/`test` (en este checkout ya se
  generó el 2026-11-07; si borrás `.dart_tool/`, repetilo).
- **Sandbox:** DSH confina escrituras al workspace. Flutter escribe fuera (cache del SDK,
  `~/.pub-cache`, Gradle, CocoaPods). En este equipo el perfil ya tiene
  `additionalWritableRoots` desde el 2026-11-07 y `flutter analyze` corre verde; si una ruta
  nueva falla con `Operation not permitted`, agregala al patch del perfil o usá **Full access**
  (`/permission`). Config lista en `.dsh/profile/cordis.patch.example.yml`.
- **Flavors `dev`/`prod`:** `flutter run`/`build` necesitan `--dart-define-from-file=.env.dev`
  o `.env.prod`. Este checkout solo trae `.env.example`; sin esos archivos la app abre el
  gate offline aunque haya internet.
- Producto: `flutter build` **no** hereda los defines de `launch.json`; usá
  `scripts/build-release-{android,ios}.sh` y subí el `versionCode` antes de cada envío.

---

## Reglas duras de convivencia (las hacen cumplir los workflows)

1. **Nunca** `git add/commit/push`, `gh pr *` ni merges desde un agente. El working tree
   queda sucio a propósito; el humano commitea.
2. No tocar `.claude/**` (legacy Claude Code) ni `.dsh/**` desde un subagente, salvo que el
   rol lo pida. El contrato de código es `CLAUDE.md`.
3. Docs y `.arb` en español; código y comentarios en inglés. Toda key nueva de l10n va en
   `app_es.arb` **y** `app_en.arb` en el mismo cambio + `flutter gen-l10n`.
4. Nunca hardcodear un hex: usar las variables de `billetudo.pen` / tokens del sistema.
5. No inventar estado del repo: verificar en código (`schemaVersion`, tablas, features) antes
   de citar docs que envejecen.
6. Si un comando falla por sandbox o permisos, no lo rodees con artilugios: reportá el error
   exacto y la solución de `docs/dsh-migration.md`.

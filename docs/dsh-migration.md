# Migración Claude Code → DeepSeek Harness (2026-11-07)

Registro de la mudanza del tooling del repo a **DeepSeek Harness (DSH)** y guía para
retomar el desarrollo desde este entorno. El contrato del proyecto no cambió: sigue en
[`CLAUDE.md`](../CLAUDE.md). La capa DSH está en [`AGENTS.md`](../AGENTS.md) y `.dsh/`.

## Resumen

- DSH carga `CLAUDE.md` **y** `AGENTS.md` como instrucciones de proyecto (no hubo que
  mover nada). Los `.arb`, `docs/`, `design-system/` y commits siguen en español.
- Las **7 skills** y los **3 workflows** de `.claude/` están portados a `.dsh/skills/` y
  `.dsh/workflows/`, con los mismos nombres y la misma intención. Los **14 agentes** de
  `.claude/agents/` están portados a `.dsh/agents/` como *playbooks* (DSH no tiene
  subagentes por proyecto: el Lead lee el playbook y lo pasa como prompt).
- `.claude/` se conserva sin tocar como legado de Claude Code. La fuente de verdad nueva
  es `.dsh/`.
- Lo único que **no** se pudo portar 1:1: hooks (`notify.sh`, DSH no tiene pipeline de
  hooks), allowlists de tools por agente (se vuelven prosa + sandbox), `agentType`/`effort`
  en workflows y workflows anidados por nombre (se inlinean).
- Pencil MCP y la política de sandbox se configuran en el **perfil de DSH**
  (`~/.dsh/profiles/desktop/cordis.patch.yml`), no en el repo. El ejemplo listo para
  copiar es [`.dsh/profile/cordis.patch.example.yml`](../.dsh/profile/cordis.patch.example.yml).

## Estado verificado del repo (2026-11-07)

Auditoría de solo lectura sobre `dev` @ `8c254aa9`, working tree limpio. **Esto reemplaza
a las secciones "Estado del repo" de `CLAUDE.md` y "Estado actual" de `README.md`, que
están desactualizadas.**

| Dato | Valor verificado | Lo que decían los docs |
|---|---|---|
| `schemaVersion` | **35** (`app_database.dart:1341`) | 28 |
| Tablas Drift | **25** | 20 |
| Features | **18**, ninguna vacía | capture/improvement "vacíos" |
| Archivos Dart en `lib/` | ~1.525 | — |
| Tests | 766 `*_test.dart`, 1.043 PNG golden, 22 archivos Patrol (125 casos) | — |
| `lib/features/capture` | 157 archivos (Fase 2 shippeada) | "vacío" |
| `lib/features/ai` | 91 archivos (beta cerrada, Edge Function `ai-chat`) | ni mencionado |
| `lib/features/improvement` | 11 archivos, dominio/insights listos pero **sin ruta ni page** | "vacío" |
| Código generado | `*.g.dart` gitignoreado y **ausente** en este checkout; no hay `.dart_tool/` | — |
| Env | solo `.env.example`; **`.env.dev`/`.env.prod` no existen** | — |
| Toolchain | Flutter 3.38.5 / Dart 3.10.4 (según `bin/cache/flutter.version.json`) | — |

Trabajo en vuelo en `dev` (4 commits sobre `origin/main`): captura nativa + recordatorios
(`f1dd7e6d`) y l10n del estado vacío de avisos (`8c254aa9`). El seam más visible: la
sección de avisos/insights existe pero no está montada en `notices_page.dart:183`; la ruta
`/avisos` solo provee `NoticesCubit`. Ese cableado es el candidato natural a siguiente
commit.

### Próximos trabajos candidatos (del análisis de docs + código)

1. Montar `NoticesSection` + `InsightsCubit` en `/avisos` (cerrar el gap de `notices_page.dart`).
2. Fase 3 real: safe-to-spend, ritual semanal, rachas, retos de ahorro, alertas tempranas
   de presupuesto. Antes decidir el solape entre `docs/requirements/fase-3/22-*` y HU-08.
3. OCR (`docs/requirements/fase-2/18-captura-ocr.md`): decidido, no implementado
   (`google_mlkit_text_recognition` está comentado en `pubspec.yaml`).
4. "Editar antes de confirmar una propuesta IA" (`docs/editar-antes-de-confirmar-propuesta-ia.md`).
5. Monetización/monitoreo: AdMob SSV + RevenueCat + remote config + cupos server-side
   (todo ausente; `google_mobile_ads`/`purchases_flutter` comentados a propósito).
6. Gates legales/publicación: no existe `legal.json` (la re-aceptación remota nunca se
   dispara), falta `design-system/billetudo/pages/legal.md`, `declaraciones-tiendas.md`
   y `checklist-fase-2.md` describen un binario viejo (0.0.5+8 / schemaVersion 34).
7. Deuda chica: restaurar/borrar deudas desde UI (`RestoreDebt` sin pantalla), reglas de
   sync de `debt_entries`, specs de `core/notes` y calendario, multi-moneda (Fase 1b).

## Cómo trabaja DSH (para no confundirse)

| Canal | Dónde vive | Cómo lo usa el agente |
|---|---|---|
| Instrucciones de proyecto | `CLAUDE.md` + `AGENTS.md` (raíz) | Se cargan solas en cada sesión; no hay que copiarlas. |
| Skills | `.dsh/skills/<nombre>/SKILL.md` | El usuario escribe `/feature-dev ...`; el modelo también las carga con la tool `skill`. |
| Subagentes | `.dsh/agents/<rol>.md` | El Lead lee el rol y lo pasa como prompt a la tool `subagent` (contexto vacío inicial). |
| Workflows | `.dsh/workflows/<nombre>.js` + `.meta.json` | Se leen ambos y se pasan a la tool `workflow` (`meta` + `script` + `args` objeto). |
| MCP | perfil `~/.dsh/profiles/desktop/cordis.patch.yml` | Tools con nombre `mcp__<server>__<tool>` (ej. `mcp__pencil__execute`). |
| Sandbox | perfil (`sandbox-policy`) o `/permission` | Confina escrituras; por defecto `workspace-write`. |
| Equipos | tools `spawn_teammate` / `team_task_*` | Para trabajo paralelo con scopes de escritura disjuntos. |

## Inventario portado

### Skills (`.dsh/skills/`)

| Skill | Origen | Cambios |
|---|---|---|
| `feature-dev` | `.claude/skills/feature-dev` | invoca el workflow portado leyendo `.js`+`.meta.json`; fallback a `subagent` en secuencia |
| `new-feature` | idem | usa `feature-scaffold` portado |
| `drift-schema-change` | idem | delega al playbook `drift-migration-helper` |
| `tier0-check` | idem | delega a `compliance-reviewer` |
| `design-fidelity-check` | idem | delega a `qa-automator` + `pencil-fidelity-reviewer` |
| `pr-review` | idem | delega a `pr-reviewer`; conserva el gate `--post` |
| `ui-ux-pro-max` | idem (bundle con `data/`+`scripts/` Python) | copiada completa, sin `__pycache__` |

### Agentes (`.dsh/agents/`, 14 playbooks)

`architect`, `flutter-dev`, `qa-automator`, `feature-scaffolder`,
`drift-migration-helper`, `finance-code-reviewer`, `ui-convention-reviewer`,
`compliance-reviewer`, `pencil-designer`, `ui-ux-reviewer`,
`pencil-fidelity-reviewer`, `patrol-e2e-runner`, `pr-reviewer`,
`privacy-legal-officer`.

Cada playbook: contenido y reglas originales en español + "Contrato del subagente DSH"
(reporte final, sin commits, sin archivos de reporte, alcance declarado). Las
restricciones de `tools:` de Claude pasan a prosa porque DSH no las enforcea; la barrera
real es el sandbox + revisión del Lead.

### Workflows (`.dsh/workflows/`)

- `feature-dev.js` (pipeline Plan→Build→Test→Review→Fidelity→Close) + meta. Ajustes:
  `agentType` → lectura del playbook; `effort` eliminado; `feature-review` inlineado (DSH
  no tiene workflows anidados por nombre); **null-guards** en cada `agent()` (DSH devuelve
  `null` si un hijo falla, Claude lanzaba); args objeto `{source, size?}`; se corrigió la
  referencia inexistente a `mcp__pencil__get_screenshot`.
- `feature-scaffold.js` + meta: args `{name}`.
- `feature-review.js` + meta: args `{feature}`; pipeline + verificación adversarial igual.

### Descartado

- `.claude/hooks/notify.sh`: DSH no tiene sistema de hooks y el script nunca estuvo wired
  (no hay `settings.json` que lo registre). Si se quiere notificación, es a nivel de la app
  de escritorio, no del repo.
- `.claude/settings*.json`: no existían versionados.
- `.mcp.json` (Supabase prod/dev): se recrea (opcional) en el perfil DSH porque el cliente
  MCP de DSH usa headers estáticos y no hace el flujo OAuth del cliente de Claude.

### CI / scripts / tool — sin cambios

`.github/workflows/{ci,qa,release}.yml`, `scripts/build-release-*.sh` y
`tool/check_schema_parity.dart` son agnósticos al harness y se mantienen tal cual.

## Estado de la puesta en marcha (2026-11-07)

Hecho y verificado en esta sesión:

| Paso | Estado | Evidencia |
|---|---|---|
| Perfil DSH con MCP Pencil + writable roots de Flutter | ✅ aplicado | `~/.dsh/profiles/desktop/cordis.patch.yml` (backup: `cordis.patch.yml.bak-2026-11-07`); el contexto de sesión ya lista los 10 writable roots |
| `flutter`/`dart` sin bloqueo de sandbox | ✅ | `flutter --version` → Flutter 3.38.5 / Dart 3.10.4 |
| `flutter pub get` | ✅ | dependencias resueltas (132 con versión nueva incompatible, normal) |
| `dart run build_runner build --force-jit` | ✅ | 41 s; `lib/core/database/app_database.g.dart` (1.2 MB) regenerado |
| `flutter analyze` | ✅ | **No issues found!** (23 s) |
| `flutter gen-l10n` | ✅ | exit 0, sin cambios (el `gen/` ya estaba al día) |
| `flutter test` (suite completa) | ✅ | **5.928 tests, "All tests passed!"** (1 skip, 4:59 min, goldens incluidos) |
| MCP Pencil (proceso) | ✅ probado por stdio | tools: `get_app_state`, `execute`, `get_style`, `read_skill`, `browser` |

Pendiente para el humano:

1. **Reiniciar DSH** (o abrir una sesión nueva) para que el modelo vea las tools
   `mcp__pencil__*`: el patch se aplicó durante esta sesión y las tools de un server MCP
   nuevo se registran al cargar el plugin.
2. **Abrir la app Pencil** con `billetudo.pen` antes de cualquier trabajo de UI (el MCP habla
   con la app por un socket local).
3. **Crear `.env.dev` y `.env.prod`** desde `.env.example` (Supabase, PowerSync, OAuth,
   Sentry). Sin ellos, `flutter run --flavor dev` abre el gate offline aunque haya red.
4. (Opcional) Supabase MCP: exportar `SUPABASE_ACCESS_TOKEN` (PAT `sbp_...`) antes de abrir
   DSH y descomentar el bloque correspondiente del patch. Con OAuth puro no alcanza.
5. (Opcional) `gh auth status` para que `/pr-review` funcione.

## Riesgos y decisiones de la migración

- **Allowlists de tools:** no hay enforcement por agente en DSH. Mitigación: cada playbook
  declara su alcance y el Lead revisa el diff; los workflows de review son de solo lectura
  por instrucción, no por capability.
- **`agent()` null:** los scripts portados abortan con mensaje claro si un hijo devuelve
  `null`, en vez de reventar con `undefined`.
- **`effort`:** se pierde el matiz `medium`/`low`; se puede aproximar con `provider`/`model`
  por llamada si hiciera falta.
- **Workflows por nombre:** DSH no resuelve `Workflow({name})`; la skill lee el archivo y lo
  pasa inline. No editar el script "al vuelo": corregir el archivo.
- **Pencil:** sigue siendo un gate duro. Sin app abierta o sin MCP configurado, la UI se
  detiene (regla del repo, no del harness).
- **Docs que envejecen:** `CLAUDE.md` y `README.md` tenían secciones de estado falsas. Ya se
  corrigieron los números de `CLAUDE.md` (ver abajo) y se dejó la advertencia en
  `AGENTS.md`. Antes de citar cualquier doc, verificar en código.

## Rollback

Todo lo nuevo es aditivo y no toca `.claude/`: borrar `AGENTS.md`, `.dsh/` y
`docs/dsh-migration.md` devuelve el repo al estado anterior (más la corrección de docs de
`CLAUDE.md`). El `.pen`, el código de la app y la CI no se modificaron.

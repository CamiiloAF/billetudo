export const meta = {
  name: 'feature-dev',
  description:
    'Entrega una feature COMPLETA de billetudo en una sola corrida: triage automatico del tamano (s/m/l), implementacion Clean Architecture con el equipo de agentes, tests (unit/widget/Patrol via qa-automator), review escalado al riesgo con fix loop acotado, y UN solo artefacto de cierre (docs/dev-runs/<slug>.md). El contexto viaja en memoria entre agentes (structured output), no en archivos. Codigo queda SIN commitear. Args: "<descripcion o ruta a una nota>" o {source, size?: "auto"|"s"|"m"|"l"}.',
  whenToUse:
    'Cuando el usuario pida implementar una feature o mejora de billetudo de punta a punta. Para solo scaffold usa feature-scaffold; para solo revisar usa feature-review.',
  phases: [
    { title: 'Plan', detail: 'Architect: triage de tamano, AC y change map — en memoria, sin archivos' },
    { title: 'Build', detail: 'flutter-dev: esquema Drift si aplica → domain+data → presentation' },
    { title: 'Test', detail: 'qa-automator: analyze + suite + gaps de cobertura + Patrol si hay device' },
    { title: 'Review', detail: 'Escalado por tamano: quick (s) / conventions+compliance (m) / feature-review adversarial (l), con fix loop' },
    { title: 'Close', detail: 'Unico artefacto: docs/dev-runs/<slug>.md con resumen y pruebas manuales' },
  ],
}

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
const input = typeof args === 'object' && args !== null ? args : { source: args }
const SOURCE = typeof input.source === 'string' && input.source.trim() ? input.source.trim() : null
if (!SOURCE) {
  throw new Error(
    'feature-dev requiere args = "<descripcion de la feature o ruta a una nota>" o {source: "...", size?: "auto"|"s"|"m"|"l"}.',
  )
}
const SIZE_OVERRIDE = ['s', 'm', 'l'].includes(input.size) ? input.size : null

const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes git add/commit/push/merge/rebase/restore/reset ni gh pr *. El arbol queda SUCIO a proposito; el humano commitea.
2. Solo puedes editar: lib/**, test/**, integration_test/**, y pubspec.yaml si el plan lo exige. NUNCA toques .claude/**, CLAUDE.md, docs/** (excepto el UNICO archivo docs/dev-runs/<slug>.md que escribe el cierre), ni analysis_options.yaml.
3. NO escribas archivos .md, reportes ni notas intermedias: toda tu salida va en el objeto estructurado que devuelves.
4. CLAUDE.md en la raiz es el contrato (centavos, UUID, updatedAt, Clean Architecture, bloc/cubit). Tu playbook de rol esta en .claude/agents/.
5. Si el repo no es git todavia, no dependas de git diff: trabaja con las listas de archivos que te pasa el prompt.
`

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------
const PLAN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['slug', 'featureDir', 'size', 'goal', 'acceptanceCriteria', 'needsSchema', 'needsUi', 'touchesTier0', 'changeMap', 'risks'],
  properties: {
    slug: { type: 'string', description: 'kebab-case corto para la corrida' },
    featureDir: { type: 'string', description: 'carpeta principal bajo lib/features/ (ej "transactions")' },
    size: { type: 'string', enum: ['s', 'm', 'l'] },
    goal: { type: 'string' },
    acceptanceCriteria: { type: 'array', items: { type: 'string' } },
    needsSchema: { type: 'boolean', description: 'toca tablas Drift / schemaVersion' },
    needsUi: { type: 'boolean' },
    touchesTier0: { type: 'boolean', description: 'toca monetizacion, cupos, Nivel 0, legal, borrado de cuenta o IA' },
    changeMap: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'action', 'reason'],
        properties: {
          file: { type: 'string' },
          action: { type: 'string', enum: ['create', 'modify', 'delete'] },
          reason: { type: 'string' },
        },
      },
    },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['status', 'filesChanged', 'testResult', 'notes'],
  properties: {
    status: { type: 'string', enum: ['pass', 'fail'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    testResult: { type: 'string', description: 'comando + conteo pass/fail (o "n/a")' },
    notes: { type: 'string' },
  },
}

const QA_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['analyzeClean', 'testsGreen', 'newFailures', 'filesWritten', 'acCoverage', 'e2e', 'manualChecks'],
  properties: {
    analyzeClean: { type: 'boolean' },
    testsGreen: { type: 'boolean', description: 'true si la suite pasa (ignorando fallos preexistentes documentados en notes)' },
    newFailures: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'description'],
        properties: { file: { type: 'string' }, description: { type: 'string' } },
      },
    },
    filesWritten: { type: 'array', items: { type: 'string' } },
    acCoverage: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['ac', 'status', 'test'],
        properties: {
          ac: { type: 'string' },
          status: { type: 'string', enum: ['covered', 'gap'] },
          test: { type: 'string', description: 'archivo::test que lo cubre, o razon del gap' },
        },
      },
    },
    e2e: { type: 'string', enum: ['pass', 'fail', 'skip'] },
    manualChecks: { type: 'array', items: { type: 'string' }, description: 'lo que solo un humano puede verificar' },
    notes: { type: 'string' },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['approved', 'blockers', 'observations'],
  properties: {
    approved: { type: 'boolean' },
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'description'],
        properties: { file: { type: 'string' }, description: { type: 'string' } },
      },
    },
    observations: { type: 'array', items: { type: 'string' }, description: 'mejoras no bloqueantes, quedan en el resumen' },
  },
}

// ---------------------------------------------------------------------------
// Phase: Plan — un solo agente architect, salida en memoria
// ---------------------------------------------------------------------------
phase('Plan')

const plan = await agent(
  `Haz el triage de esta peticion de feature para billetudo y devuelve el plan estructurado (NO escribas archivos).

FUENTE: ${SOURCE}
- Si es una ruta de archivo existente, leela completa; si no, trata el texto como la peticion.
${SIZE_OVERRIDE ? `- El usuario FORZO el tamano "${SIZE_OVERRIDE}": usalo, pero valida el resto del plan normalmente.` : ''}

${HARD_RULES}

Sigue tu playbook (.claude/agents/architect.md): lee CLAUDE.md, el esquema en lib/core/database/app_database.dart y el codigo real de las features afectadas. Ten en cuenta que puede haber carpetas con solo .gitkeep (lienzo en blanco). Devuelve slug, featureDir, size (rubrica del playbook), goal, acceptanceCriteria (numerados, testeables), needsSchema, needsUi, touchesTier0, changeMap (rutas reales o nuevas segun convencion feature-first) y risks. Si la peticion viola una regla de negocio de CLAUDE.md, ponlo como primer risk con prefijo "BLOQUEANTE:".`,
  { label: 'architect', phase: 'Plan', schema: PLAN_SCHEMA, agentType: 'architect', effort: 'medium' },
)

const SIZE = SIZE_OVERRIDE || plan.size
const CFG = {
  s: { fixRounds: 1, review: 'quick', e2e: false },
  m: { fixRounds: 1, review: 'combined', e2e: true },
  l: { fixRounds: 2, review: 'deep', e2e: true },
}[SIZE]
const SLUG = plan.slug
const SUMMARY_FILE = `docs/dev-runs/${SLUG}.md`

const hardBlocker = plan.risks.find((r) => r.startsWith('BLOQUEANTE:'))
if (hardBlocker) {
  return {
    slug: SLUG,
    aborted: true,
    reason: hardBlocker,
    plan,
    note: 'El architect detecto que la peticion viola una regla de negocio de CLAUDE.md. No se implemento nada.',
  }
}

const changeMapStr = plan.changeMap.map((c) => `${c.action} ${c.file} — ${c.reason}`).join('\n')
const acStr = plan.acceptanceCriteria.map((a, i) => `${i + 1}. ${a}`).join('\n')
log(`[plan] "${SLUG}" tamano=${SIZE.toUpperCase()} — ${plan.changeMap.length} archivos, esquema=${plan.needsSchema}, ui=${plan.needsUi}, tier0=${plan.touchesTier0}`)

// ---------------------------------------------------------------------------
// Phase: Build — flutter-dev por etapas segun flags (secuencial: las capas dependen entre si)
// ---------------------------------------------------------------------------
phase('Build')

const allFilesChanged = []
const buildNotes = []

async function build(label, mission) {
  const r = await agent(
    `Eres flutter-dev implementando la corrida "${SLUG}" de billetudo. VAS A EDITAR CODIGO. Sigue tu playbook (.claude/agents/flutter-dev.md).

${HARD_RULES}

OBJETIVO: ${plan.goal}
CRITERIOS DE ACEPTACION:
${acStr}
CHANGE MAP (solo toca lo que aparezca aqui; si descubres que falta un archivo indispensable, agregalo y justificalo en notes):
${changeMapStr}
${allFilesChanged.length ? `\nYA IMPLEMENTADO por etapas anteriores (no lo rehagas, construye encima):\n${allFilesChanged.join('\n')}` : ''}

TU MISION EN ESTA ETAPA:
${mission}

Cierra con dart analyze y flutter test en verde sobre lo tocado. Devuelve {status, filesChanged, testResult, notes}.`,
    { label, phase: 'Build', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
  )
  if (r) {
    allFilesChanged.push(...r.filesChanged)
    buildNotes.push(`[${label}] ${r.notes}`)
    log(`[build:${label}] ${r.status} — ${r.filesChanged.length} archivos (${r.testResult})`)
  }
  return r
}

if (SIZE === 's') {
  await build('implementer', `Implementa TODO el cambio en una pasada (es tamano S: mecanico/bajo riesgo).${plan.needsSchema ? ' Incluye el cambio de esquema Drift: sube schemaVersion, agrega la migracion en onUpgrade y corre build_runner.' : ''}`)
} else {
  if (plan.needsSchema) {
    await build('schema', 'SOLO el cambio de esquema Drift: tablas/columnas en lib/core/database/app_database.dart, sube schemaVersion, migracion en onUpgrade, y corre dart run build_runner build --delete-conflicting-outputs. Nada de logica de feature todavia. Recuerda: UUIDs clientDefault, enums como texto, mixin _SyncColumns.')
  }
  await build('core', 'Las capas domain/ y data/ de la feature: entidades puras, interfaces de repositorio, un caso de uso por accion (con la logica de negocio y validaciones), DTOs/datasources Drift y la implementacion del repositorio (updatedAt en cada escritura). Con sus tests unit (casos de uso) y de data (Drift con NativeDatabase.memory()).')
  if (plan.needsUi) {
    await build('ui', 'La capa presentation/: cubit/bloc que orquesta SOLO casos de uso, estados con Equatable, paginas/widgets, y el wiring en lib/core/di/ si existe el contenedor. Strings de UI en espanol, tono positivo. Con bloc_test para el cubit.')
  }
}

// ---------------------------------------------------------------------------
// Phase: Test — qa-automator: gate determinista + cobertura + Patrol
// ---------------------------------------------------------------------------
phase('Test')

const qaPrompt = (note) =>
  `Eres qa-automator cerrando la corrida "${SLUG}" de billetudo. Sigue tu playbook (.claude/agents/qa-automator.md).

${HARD_RULES}

OBJETIVO: ${plan.goal}
CRITERIOS DE ACEPTACION:
${acStr}
ARCHIVOS TOCADOS POR LOS IMPLEMENTADORES:
${allFilesChanged.join('\n') || '(ninguno reportado)'}

TU TRABAJO:
1. dart analyze y flutter test completos (gate determinista). Distingue fallos NUEVOS (newFailures, con archivo) de preexistentes (notes).
2. Por cada criterio de aceptacion: ¿hay un test que fallaria sin el cambio? Si falta y es automatizable (unit > widget), ESCRIBELO y correlo. Drift se prueba con BD en memoria, cubits con bloc_test + mocktail.
3. ${CFG.e2e ? 'Si hay device booteado (adb devices / xcrun simctl list devices booted) y el flujo es multi-pantalla y determinista, escribe/extiende y corre el Patrol e2e (integration_test/). Sin device: e2e="skip".' : 'Tamano S: NO hagas e2e (e2e="skip").'}
4. manualChecks: la lista CORTA de lo que solo un humano puede verificar (visual, gestos reales, datos reales).
${note ? `\nNOTA: ${note}` : ''}
Devuelve el objeto estructurado. NO edites lib/: los bugs reales van en newFailures.`

let qa = await agent(qaPrompt(null), { label: 'qa-automator', phase: 'Test', schema: QA_SCHEMA, agentType: 'qa-automator' })
log(`[test] analyze=${qa.analyzeClean ? 'limpio' : 'ISSUES'} tests=${qa.testsGreen ? 'verde' : 'ROJO'} e2e=${qa.e2e} — ${qa.filesWritten.length} tests nuevos, ${qa.acCoverage.filter((a) => a.status === 'gap').length} gaps`)

// Fix loop determinista: fallos nuevos o analyze roto se corrigen ANTES de gastar en review.
let fixRound = 0
while ((!qa.testsGreen || !qa.analyzeClean) && qa.newFailures.length > 0 && fixRound < CFG.fixRounds + 1) {
  fixRound++
  log(`[test] rojo (ronda ${fixRound}) — flutter-dev corrige ${qa.newFailures.length} fallos`)
  await agent(
    `Eres flutter-dev en MODO FIX para "${SLUG}". Corrige SOLO estos fallos detectados por QA (no re-implementes nada mas), re-corre dart analyze y flutter test, deja verde:
${qa.newFailures.map((f) => `- ${f.file}: ${f.description}`).join('\n')}
${HARD_RULES}
Devuelve {status, filesChanged, testResult, notes}.`,
    { label: `fix#${fixRound}`, phase: 'Test', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
  ).then((r) => r && allFilesChanged.push(...r.filesChanged))
  qa = await agent(qaPrompt(`Re-verificacion tras correcciones (ronda ${fixRound}). No re-escribas tests que ya existen; solo re-corre y reevalua.`), {
    label: 'qa-automator',
    phase: 'Test',
    schema: QA_SCHEMA,
    agentType: 'qa-automator',
  })
}

// ---------------------------------------------------------------------------
// Phase: Review — escalado por tamano
// ---------------------------------------------------------------------------
phase('Review')

const filesList = [...new Set(allFilesChanged)].join('\n')

async function runReview(note) {
  if (CFG.review === 'deep') {
    // Tamano L: reusa el workflow feature-review (3 dimensiones + verificacion adversarial).
    const deep = await workflow('feature-review', plan.featureDir)
    const confirmed = (deep && deep.confirmed) || []
    return {
      approved: confirmed.length === 0,
      blockers: confirmed.map((f) => ({ file: f.file, description: `${f.summary} — ${f.detail || ''}` })),
      observations: [],
    }
  }
  const scope = CFG.review === 'quick'
    ? 'Revision RAPIDA (tamano S): solo convenciones criticas (centavos, UUID, updatedAt, fuga de capas Drift, estilo) y que el cambio cumpla los AC. Se selectivo: blockers solo para violaciones reales.'
    : 'Revision COMBINADA (tamano M): convenciones criticas + direccion de dependencias Clean Architecture + que cada AC tenga test. Blockers solo para violaciones reales; lo demas en observations.'
  const reviews = await parallel([
    () =>
      agent(
        `${scope}
Corrida "${SLUG}" de billetudo. Archivos a revisar (leelos; usa git diff solo si el repo es git):
${filesList}
CRITERIOS DE ACEPTACION:
${acStr}
${note ? `NOTA: ${note}` : ''}
Devuelve (approved, blockers[{file,description}], observations[]).`,
        { label: 'code-review', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'finance-code-reviewer' },
      ),
    () =>
      agent(
        `Revisa SOLO las 3 convenciones de widgets/UI (funciones que devuelven Widget, widgets privados, strings de UI sin localizar) en estos archivos de la corrida "${SLUG}":
${filesList}
Devuelve (approved, blockers[{file,description}], observations[]). Blockers solo para violaciones reales.`,
        { label: 'ui-convention', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'ui-convention-reviewer' },
      ),
    () =>
      plan.touchesTier0
        ? agent(
            `Revisa SOLO reglas de negocio/legales de billetudo (Nivel 0 gratis intacto, cupos server-side, AdMob SSV, sin banners/interstitials, disclaimers de IA, borrado de cuenta real, tono positivo) en estos archivos de la corrida "${SLUG}":
${filesList}
Devuelve (approved, blockers[{file,description}], observations[]). Blockers solo para violaciones reales.`,
            { label: 'compliance', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'compliance-reviewer' },
          )
        : Promise.resolve({ approved: true, blockers: [], observations: [] }),
  ])
  const [code, uiConvention, compliance] = reviews.map((r) => r || { approved: true, blockers: [], observations: [] })
  return {
    approved: code.approved && uiConvention.approved && compliance.approved,
    blockers: [...code.blockers, ...uiConvention.blockers, ...compliance.blockers],
    observations: [...code.observations, ...uiConvention.observations, ...compliance.observations],
  }
}

let review = await runReview(null)
log(`[review] ${review.approved ? 'APROBADO' : `${review.blockers.length} blockers`} (${CFG.review})`)

let reviewRound = 0
while (!review.approved && review.blockers.length > 0 && reviewRound < CFG.fixRounds) {
  reviewRound++
  log(`[review] corrigiendo blockers (ronda ${reviewRound}/${CFG.fixRounds})`)
  await agent(
    `Eres flutter-dev en MODO FIX (review) para "${SLUG}". Corrige SOLO estos blockers, re-corre dart analyze y flutter test, deja verde:
${review.blockers.map((b) => `- ${b.file}: ${b.description}`).join('\n')}
${HARD_RULES}
Devuelve {status, filesChanged, testResult, notes}.`,
    { label: `review-fix#${reviewRound}`, phase: 'Review', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
  ).then((r) => r && allFilesChanged.push(...r.filesChanged))
  review = await runReview(`Re-revision tras correcciones (ronda ${reviewRound}); enfocate en verificar que los blockers previos quedaron resueltos.`)
  log(`[review] re-revision ${reviewRound}: ${review.approved ? 'APROBADO' : `${review.blockers.length} blockers restantes`}`)
}

// ---------------------------------------------------------------------------
// Phase: Close — UN solo artefacto humano
// ---------------------------------------------------------------------------
phase('Close')

const gaps = qa.acCoverage.filter((a) => a.status === 'gap')
const close = await agent(
  `Escribe el UNICO artefacto de la corrida "${SLUG}" de billetudo: ${SUMMARY_FILE} (crea la carpeta con mkdir -p docs/dev-runs). Español colombiano, conciso — es para que el humano revise y commitee. NO toques ningun otro archivo.

Datos de la corrida:
- Objetivo: ${plan.goal}
- Tamano: ${SIZE} | Review: ${CFG.review} ${review.approved ? 'APROBADO' : 'CON BLOCKERS PENDIENTES'}
- AC:\n${acStr}
- Archivos tocados:\n${[...new Set(allFilesChanged)].join('\n')}
- Tests: analyze=${qa.analyzeClean ? 'limpio' : 'con issues'}, suite=${qa.testsGreen ? 'verde' : 'roja'}, e2e=${qa.e2e}. Tests escritos: ${qa.filesWritten.join(', ') || 'ninguno nuevo'}
- Cobertura AC: ${qa.acCoverage.map((a) => `${a.status === 'covered' ? '✅' : '⚠️ GAP'} ${a.ac} → ${a.test}`).join(' | ')}
- Blockers sin resolver: ${review.blockers.map((b) => `${b.file}: ${b.description}`).join(' | ') || 'ninguno'}
- Observaciones no bloqueantes: ${review.observations.join(' | ') || 'ninguna'}
- Riesgos del plan: ${plan.risks.join(' | ') || 'ninguno'}
- Notas de build: ${buildNotes.join(' | ')}

FORMATO del archivo (usa Bash date -u +%Y-%m-%d para la fecha):
# <titulo legible> (<slug>)
## Objetivo y criterios de aceptacion
## Que cambio (tabla archivo → que)
## Tests (resultado + comandos exactos para re-correr, incluido patrol si aplica)
## 👤 Verifica a mano (checklist corto: ${qa.manualChecks.join('; ') || 'derivalo de los AC'}${qa.e2e === 'skip' ? '; el e2e quedo en skip — bootea un emulador y corre patrol test si quieres automatizarlo' : ''})
## Pendientes y riesgos (gaps de cobertura, blockers, observaciones)
## Mensaje de commit sugerido

Devuelve {status:'pass', filesChanged:['${SUMMARY_FILE}'], testResult:'n/a', notes:'listo'}.`,
  { label: 'close', phase: 'Close', schema: IMPL_SCHEMA, effort: 'low' },
)

return {
  slug: SLUG,
  size: SIZE,
  goal: plan.goal,
  filesChanged: [...new Set(allFilesChanged)],
  tests: {
    analyzeClean: qa.analyzeClean,
    suiteGreen: qa.testsGreen,
    e2e: qa.e2e,
    newTestFiles: qa.filesWritten,
    coverageGaps: gaps.map((g) => `${g.ac} — ${g.test}`),
  },
  review: { mode: CFG.review, approved: review.approved, remainingBlockers: review.blockers },
  manualChecks: qa.manualChecks,
  summary: SUMMARY_FILE,
  note: `Feature "${SLUG}" implementada SIN commitear. Revisa ${SUMMARY_FILE} y el diff, prueba a mano el checklist 👤, y commitea tu.`,
}

export const meta = {
  name: 'feature-dev',
  description:
    'Entrega una feature COMPLETA de billetudo en una sola corrida: triage automatico del tamano (s/m/l), implementacion Clean Architecture con el equipo de agentes, suite de tests completa (unit/widget/golden/Patrol via qa-automator, sin dejar e2e en skip por comodidad), review escalado al riesgo con fix loop acotado, verificacion de fidelidad visual contra Pencil si hay UI (golden vs. nodeId, con fix loop), y UN solo artefacto de cierre (docs/dev-runs/<slug>.md) que tambien deja al dia docs/fidelidad-visual-tracking.md. El contexto viaja en memoria entre agentes (structured output), no en archivos. Codigo queda SIN commitear. Args: "<descripcion o ruta a una nota>" o {source, size?: "auto"|"s"|"m"|"l"}.',
  whenToUse:
    'Cuando el usuario pida implementar una feature o mejora de billetudo de punta a punta. Para solo scaffold usa feature-scaffold; para solo revisar usa feature-review.',
  phases: [
    { title: 'Plan', detail: 'Architect: triage de tamano, AC y change map — en memoria, sin archivos' },
    { title: 'Build', detail: 'flutter-dev: esquema Drift si aplica → domain+data → presentation' },
    { title: 'Test', detail: 'qa-automator: analyze + suite + goldens completos + Patrol (bootea emulador si falta) + gaps de cobertura' },
    { title: 'Review', detail: 'Escalado por tamano: quick (s) / conventions+compliance (m) / feature-review adversarial (l), con fix loop' },
    { title: 'Fidelity', detail: 'Si needsUi: pencil-fidelity-reviewer compara goldens vs nodeId, con fix loop acotado' },
    { title: 'Close', detail: 'Unico artefacto: docs/dev-runs/<slug>.md + actualiza docs/fidelidad-visual-tracking.md' },
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

const PENCIL_ACCESS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['accessible', 'reason'],
  properties: {
    accessible: { type: 'boolean', description: 'true SOLO si pudiste leer el .pen real (editor state + screenshot de la pantalla relevante), no solo el spec .md' },
    reason: { type: 'string' },
  },
}

const FIDELITY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['applicable', 'accessible', 'reason', 'findings', 'gapsMdWithoutGolden', 'gapsGoldenWithoutMd'],
  properties: {
    applicable: { type: 'boolean', description: 'false si la feature no tiene design-system/billetudo/pages/<feature>.md todavia (sin frame que auditar) — no es un fallo, es N/A' },
    accessible: { type: 'boolean', description: 'true solo si pudiste leer el .pen real (get_app_state) y comparar goldens reales contra nodeId; false si el MCP de Pencil no respondio' },
    reason: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'golden', 'nodeId', 'description'],
        properties: {
          severity: { type: 'string', enum: ['CRITICO', 'IMPORTANTE', 'MENOR'] },
          golden: { type: 'string', description: 'path del .png afectado' },
          nodeId: { type: 'string' },
          description: { type: 'string' },
        },
      },
    },
    gapsMdWithoutGolden: { type: 'array', items: { type: 'string' }, description: 'filas del .md sin golden generado' },
    gapsGoldenWithoutMd: { type: 'array', items: { type: 'string' }, description: 'goldens sin fila correspondiente en el .md' },
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
// Gate: acceso a Pencil — obligatorio antes de implementar UI diseñada.
// flutter-dev NUNCA tiene herramientas MCP de Pencil (el .pen esta encriptado),
// asi que solo puede trabajar contra el spec .md — eso ya produjo deriva visual
// (componentes Material genericos en vez de los frames reales) en corridas previas.
// Un agente CON acceso real (ui-ux-reviewer) debe confirmar que puede leer el .pen
// antes de que arranque cualquier implementacion de presentation/. Sin eso, se detiene.
// ---------------------------------------------------------------------------
if (plan.needsUi) {
  phase('Plan')
  const pencilCheck = await agent(
    `Antes de que flutter-dev implemente la capa presentation/ de la corrida "${SLUG}" (${plan.goal}), verifica que tienes acceso FUNCIONAL y REAL al archivo .pen de billetudo — no basta con que exista el spec .md.

Pasos: llama a mcp__pencil__get_app_state (include_schema:true, include_canvas_design:true, include_scripts_and_shaders:false, include_browser:false si no conoces el schema todavia), y luego intenta localizar y ver (mcp__pencil__get_screenshot o, dentro de mcp__pencil__execute, Get) la o las pantallas relevantes a este objetivo dentro del canvas. Revisa tambien si existe design-system/billetudo/pages/<feature>.md correspondiente.

Devuelve accessible=true SOLO si lograste ver el diseño real (frames del canvas), no solo leer el .md. Si el MCP de Pencil no responde, el archivo no carga, o no encuentras las pantallas de esta feature en el canvas, accessible=false y explica la causa exacta en reason.`,
    { label: 'pencil-access-check', phase: 'Plan', schema: PENCIL_ACCESS_SCHEMA, agentType: 'ui-ux-reviewer', effort: 'low' },
  )
  if (!pencilCheck || !pencilCheck.accessible) {
    return {
      slug: SLUG,
      aborted: true,
      reason: `BLOQUEANTE: sin acceso real a Pencil (.pen) antes de implementar UI — ${pencilCheck ? pencilCheck.reason : 'el agente de verificacion no respondio.'}`,
      plan,
      note: 'Regla del proyecto (CLAUDE.md): flutter-dev no puede implementar presentation/ de una pantalla diseñada sin que se confirme primero acceso real al .pen — evita reintroducir la deriva visual (Material generico en vez de los frames reales) vista en pagos-programados. Reintenta esta corrida cuando Pencil este accesible.',
    }
  }
  log(`[plan] acceso a Pencil confirmado — ${pencilCheck.reason}`)
}

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
    await build('schema', 'SOLO el cambio de esquema Drift: tablas/columnas en lib/core/database/app_database.dart, sube schemaVersion, migracion en onUpgrade, y corre dart run build_runner build --force-jit. Nada de logica de feature todavia. Recuerda: UUIDs clientDefault, enums como texto, mixin _SyncColumns.')
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
3. ${plan.needsUi ? 'Esta corrida SI toca UI: completa los golden tests de TODAS las paginas y sheets nuevos/tocados bajo presentation/pages/ y presentation/widgets/sheets/ (claro+oscuro, un caso por estado de negocio distinguible), siguiendo la seccion "Golden tests" de tu playbook. No lo dejes como manualCheck ni como gap de cobertura — es parte de esta etapa, no una verificacion aparte.' : 'Esta corrida no toca UI: sin goldens que generar.'}
4. ${CFG.e2e ? 'Patrol e2e: verifica device con `adb devices` / `xcrun simctl list devices booted`. Si no hay ninguno booteado, NO marques skip todavia — intenta bootear uno tu mismo (`flutter emulators` para listar, `flutter emulators --launch <id>` para arrancar un Android, esperando a que quede listo) y reintenta. Escribe/extiende el Patrol e2e (integration_test/) para el flujo multi-pantalla de esta feature y correlo contra ese device, flavor `dev` (nunca `prod`). Marca e2e="skip" solo si, tras intentar bootear, sigue sin haber device disponible, o si el flujo no es multi-pantalla/determinista — y dilo explicito en notes, no en silencio.' : 'Tamano S: NO hagas e2e (e2e="skip").'}
5. manualChecks: la lista CORTA de lo que solo un humano puede verificar (visual, gestos reales, datos reales) — la fidelidad contra Pencil NO va aqui, la cierra una fase aparte del workflow.
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
// Phase: Fidelity — goldens vs. Pencil (solo si needsUi). Cierra el loop que
// el gate de acceso (Plan) no cierra por si solo: acceso a Pencil ANTES de
// construir reduce la deriva pero no la elimina (Pencil no renderiza ellipsis,
// layout final depende de decisiones que el frame no especifica). Aqui se
// compara el render real (goldens de la fase Test) contra el nodeId real.
// ---------------------------------------------------------------------------
let fidelity = null
if (plan.needsUi) {
  phase('Fidelity')

  async function runFidelity(note) {
    return agent(
      `Revisa la fidelidad visual completa de la feature "${plan.featureDir}" (corrida "${SLUG}") comparando cada golden test ya generado contra su nodeId real en billetudo.pen. Sigue tu playbook (.claude/agents/pencil-fidelity-reviewer.md).

1. Confirma primero si existe el spec de esta feature. TODOS los archivos bajo design-system/billetudo/pages/ estan nombrados en ESPANOL (ej. transacciones.md, metas.md, presupuestos.md, cuentas.md), NO en el nombre ingles de la carpeta de lib/features/. "${plan.featureDir}" es el nombre de carpeta en ingles — nunca lo uses tal cual como nombre de archivo. Primero intenta Glob("design-system/billetudo/pages/*.md") y elige el archivo cuyo nombre/contenido corresponda semanticamente a "${plan.featureDir}" (traduccion directa o Read rapido de las primeras lineas si el nombre no es obvio). Solo si ese Glob no produce ningun candidato razonable, devuelve applicable=false y explica en reason — no es un fallo, la feature aun no tiene ese spec.
2. Si existe, confirma acceso real al .pen (get_app_state). Si el MCP no responde, devuelve applicable=true, accessible=false y explica en reason — no compares a ciegas contra el .md solo.
3. Si tienes acceso: Glob sobre test/features/${plan.featureDir}/presentation/golden/goldens/*.png y compara CADA .png contra su fila en el .md (nodeId claro/oscuro segun el sufijo _light/_dark del archivo). No te limites a una muestra.
${note ? `\nNOTA: ${note}` : ''}
Devuelve {applicable, accessible, reason, findings[{severity,golden,nodeId,description}], gapsMdWithoutGolden[], gapsGoldenWithoutMd[]}. Severidad: CRITICO (un usuario lo notaria de inmediato: componente equivocado, layout roto, color fuera de paleta), IMPORTANTE (divergencia real acotada: spacing, peso de fuente, icono equivocado), MENOR (sutil/discutible). No inventes hallazgos para tener contenido.`,
      { label: note ? 'fidelity-reverify' : 'fidelity', phase: 'Fidelity', schema: FIDELITY_SCHEMA, agentType: 'pencil-fidelity-reviewer' },
    )
  }

  fidelity = await runFidelity(null)

  if (!fidelity || !fidelity.applicable) {
    log(`[fidelity] N/A — ${fidelity ? fidelity.reason : 'el agente no respondio'}`)
  } else if (!fidelity.accessible) {
    log(`[fidelity] BLOQUEADO sin acceso a Pencil — ${fidelity.reason}`)
  } else {
    const blockerFindings = fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')
    log(`[fidelity] ${blockerFindings.length ? `${blockerFindings.length} hallazgos CRITICO/IMPORTANTE` : 'sin hallazgos bloqueantes'} (${fidelity.findings.length} totales, ${fidelity.gapsMdWithoutGolden.length + fidelity.gapsGoldenWithoutMd.length} gaps de cobertura)`)

    const blockerFindingsRemain = () =>
      fidelity && fidelity.accessible && fidelity.findings.some((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')

    let fidelityRound = 0
    while (blockerFindingsRemain() && fidelityRound < CFG.fixRounds) {
      fidelityRound++
      const toFix = fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')
      log(`[fidelity] corrigiendo ${toFix.length} hallazgos (ronda ${fidelityRound}/${CFG.fixRounds})`)
      await agent(
        `Eres flutter-dev en MODO FIX (fidelidad visual vs Pencil) para "${SLUG}". Corrige SOLO estos hallazgos de fidelidad, confirmando primero contra el nodeId real en billetudo.pen (no adivines), y regenera los goldens afectados con flutter test --update-goldens sobre el path exacto tras el fix:
${toFix.map((f) => `- ${f.golden} (nodeId ${f.nodeId}): [${f.severity}] ${f.description}`).join('\n')}
${HARD_RULES}
Devuelve {status, filesChanged, testResult, notes}.`,
        { label: `fidelity-fix#${fidelityRound}`, phase: 'Fidelity', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
      ).then((r) => r && allFilesChanged.push(...r.filesChanged))
      fidelity = await runFidelity(`Re-verificacion tras correcciones (ronda ${fidelityRound}); enfocate en confirmar que estos hallazgos quedaron resueltos: ${toFix.map((f) => f.golden).join(', ')}.`)
      log(`[fidelity] re-verificacion ${fidelityRound}: ${fidelity && fidelity.accessible ? `${fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE').length} restantes` : 'BLOQUEADO'}`)
    }
  }
}

// ---------------------------------------------------------------------------
// Phase: Close — UN solo artefacto humano
// ---------------------------------------------------------------------------
phase('Close')

const gaps = qa.acCoverage.filter((a) => a.status === 'gap')

const fidelitySummaryStr = !plan.needsUi
  ? 'N/A (feature sin UI)'
  : !fidelity || !fidelity.applicable
    ? `N/A — ${fidelity ? fidelity.reason : 'el agente no respondio'}`
    : !fidelity.accessible
      ? `BLOQUEADO sin acceso a Pencil — ${fidelity.reason}`
      : `${fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE').length ? 'PARCIAL' : 'APROBADA'} — ${fidelity.findings.length} hallazgos (${fidelity.findings.map((f) => `[${f.severity}] ${f.golden}: ${f.description}`).join(' | ') || 'ninguno'}); gaps: ${[...fidelity.gapsMdWithoutGolden, ...fidelity.gapsGoldenWithoutMd].join(' | ') || 'ninguno'}`

const close = await agent(
  `Escribe el UNICO artefacto de dev-run de la corrida "${SLUG}" de billetudo: ${SUMMARY_FILE} (crea la carpeta con mkdir -p docs/dev-runs). Español colombiano, conciso — es para que el humano revise y commitee.

Ademas, y SOLO ademas de eso, actualiza la tabla de docs/fidelidad-visual-tracking.md para la feature "${plan.featureDir}" (agrega la fila si no existe todavia; si existe, edita su Estado/Fecha/Goldens/Fuente/Notas) siguiendo el formato ya usado en ese archivo (columnas Feature | Estado | Fecha | Goldens | Fuente | Notas; Estado es uno de ✅ Aprobada / 🟡 Parcial / ⏳ Agendada / ❌ Sin auditar / ⬜️ N/A). Usa el resultado de fidelidad de esta corrida:
${fidelitySummaryStr}
- Sin hallazgos CRITICO/IMPORTANTE pendientes y sin gaps de cobertura → ✅ Aprobada.
- Con hallazgos sin corregir o gaps de cobertura → 🟡 Parcial, anota en Notas que sigue pendiente.
- Si applicable=false (sin .md todavia) o accessible=false (sin acceso a Pencil) → deja el estado que ya tuviera la fila, o ❌ Sin auditar si es nueva, y anota la razon.
- Fecha: usa Bash date -u +%Y-%m-%d. Fuente: ${SUMMARY_FILE}.
Si esta corrida resuelve un pendiente listado en "Pendientes activos" de ese mismo doc, quitalo de esa lista en vez de dejarlo duplicado.

NO toques ningun otro archivo fuera de estos dos.

Datos de la corrida:
- Objetivo: ${plan.goal}
- Tamano: ${SIZE} | Review: ${CFG.review} ${review.approved ? 'APROBADO' : 'CON BLOCKERS PENDIENTES'}
- AC:\n${acStr}
- Archivos tocados:\n${[...new Set(allFilesChanged)].join('\n')}
- Tests: analyze=${qa.analyzeClean ? 'limpio' : 'con issues'}, suite=${qa.testsGreen ? 'verde' : 'roja'}, e2e=${qa.e2e}. Tests escritos: ${qa.filesWritten.join(', ') || 'ninguno nuevo'}
- Cobertura AC: ${qa.acCoverage.map((a) => `${a.status === 'covered' ? '✅' : '⚠️ GAP'} ${a.ac} → ${a.test}`).join(' | ')}
- Fidelidad visual vs Pencil: ${fidelitySummaryStr}
- Blockers sin resolver: ${review.blockers.map((b) => `${b.file}: ${b.description}`).join(' | ') || 'ninguno'}
- Observaciones no bloqueantes: ${review.observations.join(' | ') || 'ninguna'}
- Riesgos del plan: ${plan.risks.join(' | ') || 'ninguno'}
- Notas de build: ${buildNotes.join(' | ')}

FORMATO del archivo de dev-run (usa Bash date -u +%Y-%m-%d para la fecha):
# <titulo legible> (<slug>)
## Objetivo y criterios de aceptacion
## Que cambio (tabla archivo → que)
## Tests (resultado + comandos exactos para re-correr, incluido patrol si aplica)
## Fidelidad visual vs Pencil (resultado de esta corrida, hallazgos si los hay)
## 👤 Verifica a mano (checklist corto: ${qa.manualChecks.join('; ') || 'derivalo de los AC'}${qa.e2e === 'skip' ? '; el e2e quedo en skip pese al intento de bootear emulador — revisa por que' : ''})
## Pendientes y riesgos (gaps de cobertura, blockers, observaciones, gaps de fidelidad)
## Mensaje de commit sugerido

Devuelve {status:'pass', filesChanged:['${SUMMARY_FILE}','docs/fidelidad-visual-tracking.md'], testResult:'n/a', notes:'listo'}.`,
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
  fidelity: !plan.needsUi
    ? { applicable: false }
    : {
        applicable: fidelity ? fidelity.applicable : false,
        accessible: fidelity ? fidelity.accessible : false,
        remainingFindings: fidelity && fidelity.accessible ? fidelity.findings : [],
        coverageGaps: fidelity && fidelity.accessible ? [...fidelity.gapsMdWithoutGolden, ...fidelity.gapsGoldenWithoutMd] : [],
      },
  manualChecks: qa.manualChecks,
  summary: SUMMARY_FILE,
  note: `Feature "${SLUG}" implementada SIN commitear. Revisa ${SUMMARY_FILE} y el diff, prueba a mano el checklist 👤, y commitea tu.`,
}

// DSH: leer este archivo + feature-review.meta.json y llamar la tool `workflow`
// con meta/script/args sin modificar el script.
//
// `script` es el BODY JavaScript plano que espera la tool `workflow`: sin
// bloque meta de modulo (ese vive en feature-review.meta.json), sin TypeScript, con
// top-level await y un `return` final.

// DSH: agent() resuelve null cuando un hijo falla (Claude lanzaba). Aca un null
// silencioso se tragaria una dimension o una refutacion: abortamos con error.
const requireResult = (result, label) => {
  if (result === null || result === undefined) {
    throw new Error(`[${label}] el subagente no devolvió resultado`)
  }
  return result
}

// DSH no tiene agentes nombrados por proyecto ni opcion de tipo de agente: cada
// hijo arranca con contexto vacio. El workflow original no declara rol, asi que
// ROLE queda disponible para cuando alguna dimension necesite fijar un playbook.
const ROLE = (r) => `Actúa como el subagente \`${r}\` de Billetudo. Lee \`.dsh/agents/${r}.md\` completo y síguelo al pie de la letra, junto con \`CLAUDE.md\`.\n\n`

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          summary: { type: 'string' },
          detail: { type: 'string' },
        },
        required: ['file', 'summary', 'detail'],
      },
    },
  },
  required: ['findings'],
}

// Verificacion adversarial batcheada: UN agente verifica TODOS los hallazgos
// (lee cada archivo una sola vez) en vez de un agente por hallazgo. Un hallazgo
// sin veredicto se conserva, no se descarta en silencio.
const VERIFY_BATCH_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          summary: { type: 'string' },
          refuted: { type: 'boolean' },
          reason: { type: 'string' },
        },
        required: ['file', 'summary', 'refuted', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

// ---------------------------------------------------------------------------
// Args — DSH: `args` es un objeto JSON; la feature va en args.feature.
// ---------------------------------------------------------------------------
const featureName = args && typeof args === 'object' && typeof args.feature === 'string' && args.feature.trim()
  ? args.feature.trim()
  : null
if (!featureName) {
  throw new Error(
    'feature-review requiere args = { feature: "<nombre de la feature bajo lib/features/>" }.',
  )
}

const DIMENSIONS = [
  {
    key: 'conventions',
    prompt: `Lee CLAUDE.md en la raiz del repo. Luego revisa todo el codigo bajo lib/features/${featureName}/ (y lib/core/database/app_database.dart si esta feature toca el esquema). Busca violaciones de: dinero como double/float en vez de enteros en centavos; IDs autoincrement en vez de UUID; escrituras que no actualizan updatedAt; deletedAt usado incorrectamente (ni papelera ni sync real); comillas dobles, falta de comas finales, tipos de retorno implicitos, uso de print, o un gestor de estado distinto a bloc/cubit. Devuelve findings con archivo, linea aproximada y detalle. Si no hay codigo aun (solo .gitkeep), devuelve findings: [].`,
  },
  {
    key: 'architecture',
    prompt: `Lee CLAUDE.md en la raiz del repo, seccion de arquitectura Clean/feature-first. Revisa lib/features/${featureName}/ y verifica: domain/ tiene entidades puras (sin Drift/Supabase), interfaces de repositorio, y un caso de uso por accion; data/ mapea entre Drift y entidades sin exponer tipos generados de Drift fuera de esa capa; presentation/ (bloc/cubit) solo llama casos de uso, nunca repositorios ni DAOs directo. Reporta cualquier violacion de la direccion de dependencias. Si la feature no tiene codigo aun, devuelve findings: [].`,
  },
  {
    key: 'ui-conventions',
    prompt: `Revisa todo el codigo bajo lib/features/${featureName}/ buscando exactamente 3 violaciones (antes cubiertas por un plugin custom_lint retirado, ver docs/convenciones-de-codigo.md): (1) funciones o metodos (que no sean build ni un closure builder:) con tipo de retorno Widget/subclase de Widget — deben ser una clase StatelessWidget/StatefulWidget; (2) clases de widget cuyo nombre empieza con guion bajo (_) — deben ser publicas, en su propio archivo bajo presentation/widgets/ (las clases State como _FooState no aplican); (3) literales de texto pasados como argumento a un constructor de widget cuando ese argumento es user-facing (ej. Text('Hola'), Tooltip(message: '...')) en vez de venir de AppLocalizations — excepto parametros tecnicos (name, src, package, fontFamily, restorationId, debugLabel, routeName, initialRoute) y strings fuera de un constructor de widget (excepciones, logs). Devuelve findings con archivo, linea aproximada y cual de las 3 reglas viola. Si no hay codigo aun, devuelve findings: [].`,
  },
  {
    key: 'business-legal',
    prompt: `Lee CLAUDE.md en la raiz del repo, secciones "Reglas de negocio" y "Requisitos legales" (y docs/Plan_Monetizacion_y_Tecnico.md si necesitas detalle). Revisa lib/features/${featureName}/ buscando: features de Nivel 0 bloqueadas por anuncio o pago; limites/cupos validados solo en cliente; recompensas de anuncio sin verificacion SSV; ads ambientales (banners/interstitials); tono que avergüence al usuario; features de IA/coach sin disclaimer "no es asesoria financiera"; borrado de cuenta que no borre datos reales en Supabase. Si nada de esto aplica a la feature, devuelve findings: [].`,
  },
]

const reviewResults = await pipeline(
  DIMENSIONS,
  (d) => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA }),
)

// Un resultado null por dimension aborta: filtrarlo escondería hallazgos reales.
const allFindings = reviewResults
  .map((r, i) => requireResult(r, `review:${DIMENSIONS[i].key}`))
  .flatMap((r) => r.findings || [])

if (!allFindings.length) {
  return { feature: featureName, confirmed: [], note: 'Sin hallazgos en la revision inicial.' }
}

log(`${allFindings.length} hallazgos preliminares, verificando en UNA pasada...`)

const findingsList = allFindings
  .map((f, i) => `${i + 1}. [${f.file}${f.line ? `:${f.line}` : ''}] ${f.summary} — ${f.detail || ''}`)
  .join('\n')

const batch = requireResult(
  await agent(
    `Eres un verificador de hallazgos de revision de codigo en billetudo. Verifica CADA uno de los ${allFindings.length} hallazgos de abajo leyendo el archivo REAL (no el diff, no la descripcion del hallazgo) y confirma si el problema existe de verdad o es un falso positivo. Agrupa por archivo: abre cada archivo UNA sola vez y verifica contra el todos los hallazgos que le correspondan. Si tienes dudas razonables, marca refuted=false (favorece reportar sobre ocultar). Devuelve verdicts: UN item por hallazgo (mismo file y summary que el original, mas refuted y reason), en cualquier orden.

Hallazgos a verificar:
${findingsList}`,
    { label: 'verify-batch', phase: 'Verify', schema: VERIFY_BATCH_SCHEMA },
  ),
  'verify-batch',
)

const key = (x) => `${x.file}::${x.summary}`
const byKey = new Map(batch.verdicts.map((v) => [key(v), v]))
const missing = allFindings.filter((f) => !byKey.has(key(f))).length
if (missing > 0) {
  log(`[verify] ${missing}/${allFindings.length} hallazgos sin veredicto — se conservan por precaucion`)
}

const confirmed = allFindings
  .map((f) => ({ ...f, verdict: byKey.get(key(f)) }))
  .filter((v) => !v.verdict || !v.verdict.refuted)

return { feature: featureName, totalRaised: allFindings.length, confirmed }

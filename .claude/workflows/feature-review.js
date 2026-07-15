export const meta = {
  name: 'feature-review',
  description: 'Revisa una feature de billetudo contra convenciones criticas, arquitectura y reglas de negocio/legales, con verificacion adversarial de cada hallazgo',
  phases: [
    { title: 'Review', detail: 'agentes por dimension: convenciones, arquitectura, negocio/legal' },
    { title: 'Verify', detail: 'verificacion adversarial de cada hallazgo' },
  ],
}

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

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['refuted', 'reason'],
}

const featureName = args || 'la feature indicada por el usuario en la conversacion'

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
    key: 'business-legal',
    prompt: `Lee CLAUDE.md en la raiz del repo, secciones "Reglas de negocio" y "Requisitos legales" (y docs/Plan_Monetizacion_y_Tecnico.md si necesitas detalle). Revisa lib/features/${featureName}/ buscando: features de Nivel 0 bloqueadas por anuncio o pago; limites/cupos validados solo en cliente; recompensas de anuncio sin verificacion SSV; ads ambientales (banners/interstitials); tono que avergüence al usuario; features de IA/coach sin disclaimer "no es asesoria financiera"; borrado de cuenta que no borre datos reales en Supabase. Si nada de esto aplica a la feature, devuelve findings: [].`,
  },
]

const reviewResults = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA }),
)

const allFindings = reviewResults
  .filter(Boolean)
  .flatMap(r => r.findings || [])

if (!allFindings.length) {
  return { feature: featureName, confirmed: [], note: 'Sin hallazgos en la revision inicial.' }
}

log(`${allFindings.length} hallazgos preliminares, verificando cada uno...`)

const verified = await parallel(
  allFindings.map(f => () =>
    agent(
      `Intenta refutar este hallazgo de revision de codigo en billetudo. Hallazgo: "${f.summary}" — ${f.detail} (archivo: ${f.file}, linea: ${f.line ?? 'N/A'}). Lee el archivo real y confirma si el problema existe de verdad o es un falso positivo. Si tienes dudas razonables, marca refuted=false (favorece reportar sobre ocultar).`,
      { label: `verify:${f.file}`, phase: 'Verify', schema: VERDICT_SCHEMA },
    ).then(v => ({ ...f, verdict: v })),
  ),
)

const confirmed = verified.filter(Boolean).filter(v => v.verdict && !v.verdict.refuted)

return { feature: featureName, totalRaised: allFindings.length, confirmed }

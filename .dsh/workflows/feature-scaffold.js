// DSH: leer este archivo + feature-scaffold.meta.json y llamar la tool `workflow`
// con meta/script/args sin modificar el script.
//
// `script` es el BODY JavaScript plano que espera la tool `workflow`: sin
// bloque meta de modulo (ese vive en feature-scaffold.meta.json), sin TypeScript,
// con top-level await y un `return` final.

// DSH: agent() resuelve null cuando un hijo falla. Abortamos con un error claro.
const requireResult = (result, label) => {
  if (result === null || result === undefined) {
    throw new Error(`[${label}] el subagente no devolvió resultado`)
  }
  return result
}

// Un solo agente hace todo el scaffold + self-review: las capas domain→data→
// presentation son secuenciales y comparten naming/entidades, así que partirlas
// en agentes frescos obligaba a 3 re-lecturas de CLAUDE.md y a resúmenes lossy.
const SCAFFOLD_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['status', 'filesCreated', 'summary', 'pending'],
  properties: {
    status: { type: 'string', enum: ['pass', 'fail'] },
    filesCreated: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string', description: 'entidades, casos de uso y bloc/cubit creados' },
    pending: { type: 'array', items: { type: 'string' }, description: 'p.ej. wiring en lib/core/di/, tests, registrar ruta' },
  },
}

const featureName = args && typeof args === 'object' && typeof args.name === 'string' && args.name.trim()
  ? args.name.trim()
  : null
if (!featureName) {
  throw new Error('Pasa el nombre de la feature en `args.name`, ej: { meta, script, args: { name: "budgets" } }.')
}

phase('Scaffold')
const scaffold = requireResult(
  await agent(
    `Actúa como el subagente \`feature-scaffolder\` de Billetudo. Lee \`.dsh/agents/feature-scaffolder.md\` completo y síguelo al pie de la letra, junto con \`CLAUDE.md\`.

Crea la estructura Clean Architecture completa (domain/ → data/ → presentation/) de la feature "${featureName}" en lib/features/${featureName}/, con dependencias apuntando hacia adentro. Si alguna carpeta ya tiene archivos, respetalos y completa lo que falte. Al terminar corre \`flutter analyze\` (y \`dart run build_runner build --force-jit\` solo si tocaste app_database.dart) y deja el resultado en \`status\`.

Devuelve {status, filesCreated, summary, pending}.`,
    { label: 'feature-scaffolder', phase: 'Scaffold', schema: SCAFFOLD_SCHEMA },
  ),
  'feature-scaffolder',
)

return { feature: featureName, ...scaffold }

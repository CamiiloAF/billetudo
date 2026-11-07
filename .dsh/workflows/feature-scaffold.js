// DSH: leer este archivo + feature-scaffold.meta.json y llamar la tool `workflow`
// con meta/script/args sin modificar el script.
//
// `script` es el BODY JavaScript plano que espera la tool `workflow`: sin
// bloque meta de modulo (ese vive en feature-scaffold.meta.json), sin TypeScript, con
// top-level await y un `return` final.

// DSH: agent() resuelve null cuando un hijo falla (Claude lanzaba). Abortamos
// con un error claro en vez de seguir y pasar "null" como resumen de una capa.
const requireResult = (result, label) => {
  if (result === null || result === undefined) {
    throw new Error(`[${label}] el subagente no devolvió resultado`)
  }
  return result
}

// DSH no tiene agentes nombrados por proyecto ni opcion de tipo de agente: cada
// hijo arranca con contexto vacio. El workflow original no declara rol, asi que
// ROLE queda disponible para cuando algun paso necesite fijar un playbook de rol.
const ROLE = (r) => `Actúa como el subagente \`${r}\` de Billetudo. Lee \`.dsh/agents/${r}.md\` completo y síguelo al pie de la letra, junto con \`CLAUDE.md\`.\n\n`

// ---------------------------------------------------------------------------
// Args — DSH: `args` es un objeto JSON; el nombre de la feature va en args.name.
// ---------------------------------------------------------------------------
const featureName = args && typeof args === 'object' && typeof args.name === 'string' && args.name.trim()
  ? args.name.trim()
  : null
if (!featureName) {
  throw new Error(
    'Pasa el nombre de la feature en `args.name` al llamar la tool `workflow`, ej: { meta, script, args: { name: "budgets" } }.',
  )
}

phase('Domain')
const domainSummary = requireResult(
  await agent(
    `Lee CLAUDE.md en la raiz del repo (convenciones y arquitectura Clean/feature-first) y lib/core/database/app_database.dart (tablas y enums existentes). Crea la capa domain/ de la feature "${featureName}" en lib/features/${featureName}/domain/: entidades puras en Dart (sin dependencias de Drift/Supabase, con Equatable si aplica), una interfaz abstracta de repositorio en domain/repositories/, y una clase de caso de uso por cada accion CRUD relevante en domain/usecases/ (metodo call()). Usa comillas simples, comas finales y tipos de retorno explicitos. Si ya existen archivos en esa carpeta, respetalos y solo completa lo que falte. Devuelve un resumen breve (texto plano) de los archivos creados y las entidades/casos de uso definidos.`,
    { label: 'domain', phase: 'Domain' },
  ),
  'domain',
)

phase('Data')
const dataSummary = requireResult(
  await agent(
    `Lee CLAUDE.md y la capa domain/ ya creada en lib/features/${featureName}/domain/ (resumen del agente anterior: ${domainSummary}). Crea la capa data/ en lib/features/${featureName}/data/: modelos/DTOs que mapeen a/desde las tablas de Drift relevantes en lib/core/database/app_database.dart, un datasource que use el AppDatabase (DAOs de Drift), y una implementacion concreta del repositorio de domain/ que traduzca entre modelos de Drift y entidades de dominio (nunca expongas tipos generados de Drift fuera de esta capa). Actualiza updatedAt en cada escritura. Usa comillas simples, comas finales, tipos de retorno explicitos. Devuelve un resumen breve de los archivos creados.`,
    { label: 'data', phase: 'Data' },
  ),
  'data',
)

phase('Presentation')
const presentationSummary = requireResult(
  await agent(
    `Lee CLAUDE.md, y los resumenes de las capas domain/ (${domainSummary}) y data/ (${dataSummary}) ya creadas en lib/features/${featureName}/. Crea la capa presentation/ en lib/features/${featureName}/presentation/: un cubit o bloc (segun la complejidad de eventos) que dependa SOLO de los casos de uso de domain/usecases/ (nunca de repositorios ni DAOs directo), sus estados (con Equatable), y una pagina/widget minimo que consuma el bloc via BlocBuilder/BlocProvider. Usa comillas simples, comas finales, tipos de retorno explicitos. Devuelve un resumen breve de los archivos creados.`,
    { label: 'presentation', phase: 'Presentation' },
  ),
  'presentation',
)

phase('Review')
const review = requireResult(
  await agent(
    `Revisa todo lo creado en lib/features/${featureName}/ (domain, data, presentation) contra CLAUDE.md: direccion de dependencias correcta (domain no importa de data; presentation no importa Drift directo), dinero en centavos, UUIDs, updatedAt, estilo de codigo (comillas simples, comas finales, tipos de retorno explicitos). Corre "flutter analyze" si es posible y reporta errores reales de compilacion. Si encuentras violaciones de convencion, corrigelas directamente en los archivos que acabas de recibir. Devuelve un resumen final: que quedo listo, que se corrigio, y que falta (wiring en lib/core/di/, registrar la pagina en la navegacion, tests).`,
    { label: 'review', phase: 'Review' },
  ),
  'review',
)

return { feature: featureName, domainSummary, dataSummary, presentationSummary, review }

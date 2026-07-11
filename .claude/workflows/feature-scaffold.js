export const meta = {
  name: 'feature-scaffold',
  description: 'Genera el boilerplate Clean Architecture (domain/data/presentation) para una nueva feature de finance_app, capa por capa, y verifica el resultado',
  phases: [
    { title: 'Domain' },
    { title: 'Data' },
    { title: 'Presentation' },
    { title: 'Review' },
  ],
}

const featureName = args
if (!featureName || typeof featureName !== 'string') {
  throw new Error('Pasa el nombre de la feature en args, ej: Workflow({ name: "feature-scaffold", args: "budgets" })')
}

phase('Domain')
const domainSummary = await agent(
  `Lee CLAUDE.md en la raiz del repo (convenciones y arquitectura Clean/feature-first) y lib/core/database/app_database.dart (tablas y enums existentes). Crea la capa domain/ de la feature "${featureName}" en lib/features/${featureName}/domain/: entidades puras en Dart (sin dependencias de Drift/Supabase, con Equatable si aplica), una interfaz abstracta de repositorio en domain/repositories/, y una clase de caso de uso por cada accion CRUD relevante en domain/usecases/ (metodo call()). Usa comillas simples, comas finales y tipos de retorno explicitos. Si ya existen archivos en esa carpeta, respetalos y solo completa lo que falte. Devuelve un resumen breve (texto plano) de los archivos creados y las entidades/casos de uso definidos.`,
  { label: 'domain', phase: 'Domain' },
)

phase('Data')
const dataSummary = await agent(
  `Lee CLAUDE.md y la capa domain/ ya creada en lib/features/${featureName}/domain/ (resumen del agente anterior: ${domainSummary}). Crea la capa data/ en lib/features/${featureName}/data/: modelos/DTOs que mapeen a/desde las tablas de Drift relevantes en lib/core/database/app_database.dart, un datasource que use el AppDatabase (DAOs de Drift), y una implementacion concreta del repositorio de domain/ que traduzca entre modelos de Drift y entidades de dominio (nunca expongas tipos generados de Drift fuera de esta capa). Actualiza updatedAt en cada escritura. Usa comillas simples, comas finales, tipos de retorno explicitos. Devuelve un resumen breve de los archivos creados.`,
  { label: 'data', phase: 'Data' },
)

phase('Presentation')
const presentationSummary = await agent(
  `Lee CLAUDE.md, y los resumenes de las capas domain/ (${domainSummary}) y data/ (${dataSummary}) ya creadas en lib/features/${featureName}/. Crea la capa presentation/ en lib/features/${featureName}/presentation/: un cubit o bloc (segun la complejidad de eventos) que dependa SOLO de los casos de uso de domain/usecases/ (nunca de repositorios ni DAOs directo), sus estados (con Equatable), y una pagina/widget minimo que consuma el bloc via BlocBuilder/BlocProvider. Usa comillas simples, comas finales, tipos de retorno explicitos. Devuelve un resumen breve de los archivos creados.`,
  { label: 'presentation', phase: 'Presentation' },
)

phase('Review')
const review = await agent(
  `Revisa todo lo creado en lib/features/${featureName}/ (domain, data, presentation) contra CLAUDE.md: direccion de dependencias correcta (domain no importa de data; presentation no importa Drift directo), dinero en centavos, UUIDs, updatedAt, estilo de codigo (comillas simples, comas finales, tipos de retorno explicitos). Corre "flutter analyze" si es posible y reporta errores reales de compilacion. Si encuentras violaciones de convencion, corrigelas directamente en los archivos que acabas de recibir. Devuelve un resumen final: que quedo listo, que se corrigio, y que falta (wiring en lib/core/di/, registrar la pagina en la navegacion, tests).`,
  { label: 'review', phase: 'Review' },
)

return { feature: featureName, domainSummary, dataSummary, presentationSummary, review }

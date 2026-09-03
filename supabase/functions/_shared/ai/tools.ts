// The tool catalogue, split by who executes it.
//
// READ tools are never run here. The function hands the call back to the app,
// which resolves it against its local Drift database — the app's source of
// truth — and posts the result back. Postgres is only a mirror: it can lag
// behind a sync, or sit half-merged right after a login, and a model answering
// from a stale mirror lies with total confidence. Resolving on-device also
// means this function never needs read access to a single financial table.
//
// WRITE tools are never run at all, by anyone. They are how the model phrases a
// suggestion: the function turns them into `proposals[]`, the app renders a
// card, and only a tap writes anything.
//
// Schema rules (Gemini accepts a subset of OpenAPI 3.0): no $ref, no oneOf /
// anyOf, no additionalProperties, no exotic formats. Money is always declared
// `type: "integer"` — it is the strongest signal available against the model
// answering 4500.5 for a minor-unit amount.

import { AiToolDef } from './types.ts';

export const READ_TOOLS: AiToolDef[] = [
  {
    name: 'get_transactions',
    description:
      'Devuelve los movimientos del usuario en un rango de fechas. Usala solo '
      + 'cuando el resumen no alcance para responder. Maximo 50 filas.',
    parameters: {
      type: 'object',
      properties: {
        from: {
          type: 'integer',
          description: 'Inicio del rango, timestamp unix en SEGUNDOS, inclusivo.',
        },
        to: {
          type: 'integer',
          description: 'Fin del rango, timestamp unix en SEGUNDOS, exclusivo.',
        },
        type: {
          type: 'string',
          enum: ['income', 'expense', 'transfer'],
        },
        categoryIds: {
          type: 'array',
          items: { type: 'string' },
          description: 'Ids exactos del resumen. Nunca inventes un id.',
        },
        accountIds: {
          type: 'array',
          items: { type: 'string' },
        },
        currency: {
          type: 'string',
          description:
            'ISO 4217 de 3 letras. Si lo omites vienen todas las monedas '
            + 'mezcladas y NO debes sumarlas entre si.',
        },
        minAmountMinor: {
          type: 'integer',
          description: 'Filtra por monto absoluto en unidades menores (centavos).',
        },
        maxAmountMinor: {
          type: 'integer',
          description:
            'Filtra por monto absoluto maximo en unidades menores (centavos). '
            + 'Combinala con minAmountMinor para acotar un rango (por ejemplo, '
            + 'gastos hormiga: montos chicos que se repiten) sin traer tambien '
            + 'compras grandes de la misma categoria.',
        },
        searchText: {
          type: 'string',
          description:
            'Texto a buscar DENTRO de la nota del movimiento y del nombre de '
            + 'su categoria. La busqueda ocurre en el dispositivo: tu mandas el '
            + 'termino, el telefono compara contra las notas locales y te '
            + 'devuelve solo los movimientos que coinciden. El texto de la nota '
            + 'NUNCA vuelve en la respuesta, asi que no lo pidas ni lo supongas.',
        },
        limit: {
          // 50 is also what the published privacy policy commits to (section
          // 17.2) and what `ResolveAiToolCall.maxRows` enforces on the device.
          // The three move together or not at all.
          type: 'integer',
          description: 'Entre 1 y 50. Por defecto 25.',
        },
        order: {
          type: 'string',
          enum: ['date_desc', 'date_asc', 'amount_desc'],
        },
      },
      required: ['from', 'to'],
    },
  },
  {
    // Only expense: the underlying aggregate is the app's "estructura de gasto"
    // report, and there is no income equivalent. Asking for income answers
    // `not_found` rather than silently returning expenses.
    //
    // `currency` is a GUARD, not a filter: the aggregate cannot split by
    // currency, so the app answers only when every active account already uses
    // the one asked for, and refuses otherwise. Labelling a mixed-currency
    // total with a single code would be exactly the fabrication these rules
    // exist to prevent.
    name: 'get_category_breakdown',
    description:
      'Gasto agrupado por categoria en un rango. Solo gasto: no hay version de '
      + 'ingresos. Solo responde si TODAS las cuentas del usuario usan la moneda '
      + 'que pidas; si tiene varias monedas te dira que no puede.',
    parameters: {
      type: 'object',
      properties: {
        from: { type: 'integer', description: 'Unix en SEGUNDOS, inclusivo.' },
        to: { type: 'integer', description: 'Unix en SEGUNDOS, exclusivo.' },
        type: { type: 'string', enum: ['expense'] },
        currency: { type: 'string', description: 'ISO 4217 de 3 letras.' },
        topN: { type: 'integer', description: 'Entre 1 y 15. Por defecto 10.' },
        includeSubcategories: { type: 'boolean' },
      },
      required: ['from', 'to', 'type', 'currency'],
    },
  },
  {
    // Same currency guard as above, same reason.
    name: 'compare_periods',
    description:
      'Compara los totales de dos rangos, globales o por categoria. Usala para '
      + '"gaste mas que el mes pasado". Solo responde si TODAS las cuentas del '
      + 'usuario usan la moneda que pidas.',
    parameters: {
      type: 'object',
      properties: {
        aFrom: { type: 'integer' },
        aTo: { type: 'integer' },
        bFrom: { type: 'integer' },
        bTo: { type: 'integer' },
        currency: { type: 'string', description: 'ISO 4217 de 3 letras.' },
        groupBy: { type: 'string', enum: ['total', 'category'] },
      },
      required: ['aFrom', 'aTo', 'bFrom', 'bTo', 'currency'],
    },
  },
  {
    name: 'get_budget_detail',
    description:
      'Estado de un presupuesto concreto, opcionalmente con sus periodos '
      + 'anteriores para ver la tendencia.',
    parameters: {
      type: 'object',
      properties: {
        budgetId: { type: 'string', description: 'Id exacto tomado del resumen.' },
        includePreviousPeriods: {
          type: 'integer',
          description: 'Entre 0 y 6. Por defecto 0.',
        },
      },
      required: ['budgetId'],
    },
  },
  {
    name: 'get_goal_detail',
    description: 'Detalle de una meta y sus aportes.',
    parameters: {
      type: 'object',
      properties: {
        goalId: { type: 'string', description: 'Id exacto tomado del resumen.' },
      },
      required: ['goalId'],
    },
  },
  {
    name: 'get_debt_detail',
    description:
      'Detalle de una deuda concreta (id tomado de la seccion "debts" del '
      + 'resumen, nunca de "debtTotals" que es un agregado sin id): saldo '
      + 'pendiente, si tiene cuota/abono programado, y su historial de '
      + 'movimientos (abonos, desembolsos, intereses).',
    parameters: {
      type: 'object',
      properties: {
        debtId: { type: 'string', description: 'Id exacto tomado del resumen.' },
      },
      required: ['debtId'],
    },
  },
  {
    name: 'find_scheduled_payments',
    description:
      'Busca un pago programado por como el usuario lo llama, cuando no sabes '
      + 'su id. La busqueda ocurre EN EL DISPOSITIVO contra la nota del pago, '
      + 'su categoria y su cuenta; tu solo mandas el termino y recibes los que '
      + 'coinciden, con su "id". El texto de la nota NUNCA vuelve en la '
      + 'respuesta. Usala como paso previo a get_scheduled_payment_detail, que '
      + 'necesita ese "id". Solo busca entre pagos ACTIVOS (el campo "scope" lo '
      + 'confirma): si no aparece nada, puede ser que no exista O que ya haya '
      + 'terminado, y debes decirlo asi en vez de afirmar que no existe.',
    parameters: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description:
            'El termino tal como lo dijo la persona ("abono a capital", '
            + '"hipotecario"). Insensible a mayusculas y tildes. Es coincidencia '
            + 'de TEXTO, no semantica: si la persona dice "mi credito vehicular" '
            + 'y no encuentras nada, prueba con una palabra que si pueda estar '
            + 'escrita (una marca, un modelo, el nombre del banco) antes de '
            + 'concluir que no existe.',
        },
        limit: { type: 'integer', description: 'Entre 1 y 50. Por defecto 25.' },
      },
      required: ['query'],
    },
  },
  {
    name: 'get_scheduled_payment_detail',
    description:
      'Detalle de un pago programado concreto (id tomado de la seccion '
      + '"upcoming" del resumen). Usala cuando el pago que buscas no aparece '
      + 'en "upcoming" (esa seccion solo trae los proximos 30 dias, maximo 25 '
      + 'filas) o cuando necesitas su historial de ocurrencias pasadas '
      + '(confirmadas u omitidas).',
    parameters: {
      type: 'object',
      properties: {
        scheduledPaymentId: {
          type: 'string',
          description: 'Id exacto tomado del resumen.',
        },
      },
      required: ['scheduledPaymentId'],
    },
  },
];

const RATIONALE = {
  type: 'string',
  description:
    'Una frase, en espanol, explicando de donde sale esta propuesta. La ve el '
    + 'usuario en la tarjeta.',
};

export const WRITE_TOOLS: AiToolDef[] = [
  {
    name: 'propose_create_budget',
    description:
      'Propone al usuario crear un presupuesto. NO lo crea: la app le muestra '
      + 'una tarjeta y el decide. Usala solo si tienes datos que justifiquen el monto.',
    parameters: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        amountMinor: {
          type: 'integer',
          description:
            'Limite en unidades menores (centavos). 45.000 COP se escribe 4500000.',
        },
        currency: { type: 'string', description: 'ISO 4217 de 3 letras.' },
        period: {
          type: 'string',
          enum: ['weekly', 'biweekly', 'monthly', 'yearly'],
        },
        categoryIds: {
          type: 'array',
          items: { type: 'string' },
          description: 'Ids exactos del resumen. Nunca inventes un id.',
        },
        accountIds: { type: 'array', items: { type: 'string' } },
        rationale: RATIONALE,
      },
      required: ['name', 'amountMinor', 'currency', 'period', 'rationale'],
    },
  },
  {
    name: 'propose_create_goal',
    description: 'Propone al usuario crear una meta de ahorro. NO la crea.',
    parameters: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        targetMinor: {
          type: 'integer',
          description: 'Objetivo en unidades menores (centavos).',
        },
        currency: { type: 'string', description: 'ISO 4217 de 3 letras.' },
        targetDate: {
          type: 'integer',
          description: 'Fecha objetivo, unix en SEGUNDOS. Opcional.',
        },
        accountId: { type: 'string', description: 'Id exacto del resumen.' },
        rationale: RATIONALE,
      },
      required: ['name', 'targetMinor', 'currency', 'rationale'],
    },
  },
  {
    name: 'propose_create_category',
    description:
      'Propone crear una categoria. Usala antes de proponer algo que necesite '
      + 'una categoria que todavia no existe.',
    parameters: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        kind: { type: 'string', enum: ['income', 'expense'] },
        parentId: {
          type: 'string',
          description: 'Id de la categoria padre, si es una subcategoria.',
        },
        rationale: RATIONALE,
      },
      required: ['name', 'kind', 'rationale'],
    },
  },
  {
    name: 'propose_create_transaction',
    description:
      'Propone registrar un movimiento. NO lo registra: el usuario confirma.',
    parameters: {
      type: 'object',
      properties: {
        type: { type: 'string', enum: ['income', 'expense'] },
        amountMinor: {
          type: 'integer',
          description: 'Monto en unidades menores (centavos), siempre positivo.',
        },
        currency: { type: 'string', description: 'ISO 4217 de 3 letras.' },
        date: { type: 'integer', description: 'Unix en SEGUNDOS.' },
        accountId: { type: 'string', description: 'Id exacto del resumen.' },
        categoryId: {
          type: 'string',
          description:
            'Obligatoria. Id exacto de una categoria del resumen, del kind '
            + 'que corresponda a "type". Si ninguna categoria existente '
            + 'encaja, propon crearla primero (propose_create_category) en '
            + 'vez de omitir este campo.',
        },
        debtId: {
          type: 'string',
          description:
            'Opcional. Id exacto de una deuda de "debts". Si lo mandas, el '
            + 'movimiento nace ya atribuido a esa deuda (abono o desembolso '
            + 'segun corresponda), en una sola confirmacion. Usalo cuando la '
            + 'persona diga que el movimiento ES un pago de una deuda suya.',
        },
        note: { type: 'string' },
        rationale: RATIONALE,
      },
      required: [
        'type',
        'amountMinor',
        'currency',
        'date',
        'accountId',
        'categoryId',
        'rationale',
      ],
    },
  },
  {
    name: 'propose_link_transaction_to_debt',
    description:
      'Propone atribuir un movimiento QUE YA EXISTE a una deuda, como abono o '
      + 'desembolso. NO lo hace: el usuario confirma. No crea ningun movimiento '
      + 'nuevo ni mueve dinero — el movimiento ya afecto su cuenta; esto solo '
      + 'hace que cuente en el saldo de la deuda. Para un movimiento que '
      + 'todavia no existe, usa propose_create_transaction con "debtId".',
    parameters: {
      type: 'object',
      properties: {
        transactionId: {
          type: 'string',
          description:
            'Id exacto de un movimiento que hayas obtenido con get_transactions. '
            + 'Nunca lo inventes.',
        },
        debtId: {
          type: 'string',
          description: 'Id exacto de una deuda de "debts" en el resumen.',
        },
        rationale: RATIONALE,
      },
      required: ['transactionId', 'debtId', 'rationale'],
    },
  },
];

const WRITE_TOOL_NAMES = new Set(WRITE_TOOLS.map((tool) => tool.name));
const READ_TOOL_NAMES = new Set(READ_TOOLS.map((tool) => tool.name));

export function isWriteTool(name: string): boolean {
  return WRITE_TOOL_NAMES.has(name);
}

export function isReadTool(name: string): boolean {
  return READ_TOOL_NAMES.has(name);
}

export const ALL_TOOLS: AiToolDef[] = [...READ_TOOLS, ...WRITE_TOOLS];

/// `propose_create_budget` -> `create_budget`. The app's proposal mapper keys
/// off the short form; anything it does not recognise becomes an
/// `UnsupportedProposal` rather than an error.
export function proposalKindFor(toolName: string): string {
  return toolName.replace(/^propose_/, '');
}

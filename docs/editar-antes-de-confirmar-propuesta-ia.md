# Editar antes de confirmar una propuesta del asistente — pendiente

**Estado al 2026-08-28: documentado, NO implementado.** Se decidió posponer
para no retrasar el despliegue del fix de montos + enlace a deudas, que ya
estaba verde y era urgente. Retomar en otra rama, próxima semana.

## El pedido

Hoy una tarjeta de propuesta del chat solo tiene dos acciones: Descartar o
Confirmar tal cual. El usuario pidió una tercera vía — **Editar**: lleva a la
pantalla de creación/edición correspondiente, con los datos de la propuesta
precargados, para ajustarlos antes de guardar. Motivo real: *"me pasó ahora
que quería editar algo y tenía que confirmar el registro y después ir a
cambiarlo"* — hoy el único camino para ajustar una propuesta es aceptarla tal
cual y editar el registro ya creado.

## Alcance decidido

Solo para estos tres tipos de propuesta:

- `propose_create_transaction` (el caso real que motivó el pedido)
- `propose_create_budget`
- `propose_create_goal`

**Fuera de alcance, a propósito:** `propose_create_category` (poco que editar
más allá del nombre) y `propose_link_transaction_to_debt` (no crea nada;
"editar" ahí sería elegir otra deuda desde cero, un flujo distinto).

## Re-sincronización: resuelta, sin construir nada

El usuario preguntó si el asistente debía enterarse cuando la persona edita y
confirma el registro desde el formulario. **La respuesta es que ya se entera,
gratis, sin ningún mecanismo nuevo**: `AiChatCubit._attemptTurn` llama a
`BuildFinancialSnapshot` en **cada turno**, no una vez al arrancar la
conversación (`lib/features/ai/presentation/cubit/ai_chat_cubit.dart`). Así
que en cuanto la persona sigue chateando después de editar, el asistente ya
ve los datos reales en el snapshot de ese turno — es una consecuencia directa
de cómo ya funciona el chat, no una feature aparte.

Lo único que sí hay que construir es visual: **al volver del formulario, si
el registro se creó, la tarjeta de esa propuesta en el chat cambia a su
estado "Confirmada"** con los datos reales (que pueden estar editados). No
hay que avisarle nada al modelo ni abrir una ronda nueva contra el servidor.

## Por qué es tamaño M, no un fix chico

Ningún formulario de los tres (movimiento, presupuesto, meta) acepta hoy
"crear nuevo, prellenado con valores que no vienen de la base de datos" — solo
saben crear vacío o editar por id. Hay que agregar esa capacidad a los tres.

**Hay precedente real que reduce el riesgo**, no hay que inventar el patrón:
`TransactionFormPage.onConvertToScheduledPayment` — el router recibe un
callback y es el que prellena el formulario de Pagos Programados desde
`TransactionFormState`, sin que ninguna de las dos features importe a la otra.
El mismo puente (router conoce ambos lados, cada feature se queda ciega de la
otra) es el camino a seguir para los tres casos de este pedido.

Piezas de trabajo:

1. **Prellenado**: los tres formularios ganan una forma de arrancar con
   valores iniciales que no salen de una fila existente de Drift (un "draft"
   inicial, análogo a como ya recibe `ConvertToScheduledPayment` sus valores).
2. **Botón "Editar" en la tarjeta de propuesta** — diseño en Pencil, ambos
   temas, para los tres tipos de propuesta y sus dos estados relevantes.
3. **Puente de navegación en el router**, uno por cada uno de los tres
   destinos, siguiendo el patrón ya probado.
4. **Retorno del formulario → tarjeta a "Confirmada"** si el registro se creó
   de verdad; si la persona cancela el formulario, la tarjeta se queda como
   propuesta pendiente, no se marca nada.

## Siguiente paso al retomar

Pasar primero por `pencil-designer` (botón nuevo + estados) antes de tocar
`lib/`, como manda el gate de diseño del proyecto. Después, tres cambios de
formulario + el puente de router, probablemente en tandas por feature en vez
de un solo cambio grande.

# Feature: Centro de notificaciones (insights proactivos)

**Estado: exploratorio.** Este documento registra una decisión de producto tomada el 2026-08-26 y el razonamiento que la sostiene. **No es un compromiso de construcción** ni un requerimiento cerrado: no tiene historias de usuario con criterios de aceptación todavía, ni diseño en `billetudo.pen`, ni esquema Drift. Sirve para no perder la decisión y para que quien retome la idea no re-derive el análisis desde cero.

**Nivel previsto:** 0 (gratis). Ver "Por qué es Nivel 0" abajo.
**Fase:** 3 (capa de mejora financiera, todo local). Es el primer documento de esa fase; `lib/features/improvement/` está vacío y es su destino natural.
**No confundir con:** [`fase-2/19-notificaciones-bancarias.md`](../fase-2/19-notificaciones-bancarias.md), que es lo contrario — leer las notificaciones *que el banco envía al dispositivo* para capturar gastos. Este documento es sobre las notificaciones que **billetudo genera**.

## De dónde viene esta decisión

Salió de una revisión del Home (2026-08-26) motivada por un reporte real de usuaria: se sentía abrumada y perdida ante la cantidad de información de la pantalla principal.

En esa revisión se evaluó darle protagonismo al asistente de IA y se planteó mostrar **insights proactivos** — que la app le diga algo útil a la persona *antes* de que pregunte. Al maquetar la idea apareció la distinción que originó este documento:

- **Insight terminal** — un dato cerrado que se basta solo: *"Netflix se cobra en 3 días"*, *"alcanzaste tu meta de viaje"*. No abre ninguna pregunta; ya dijo todo lo que había que decir.
- **Insight abierto** — plantea algo que la persona querría profundizar: *"este mes llevás 60% más en mercado que tu promedio"*, *"a este ritmo terminás el mes por encima del presupuesto"*. La reacción natural es preguntar "¿por qué?" o "¿qué hago?".

**La decisión:** los insights **abiertos** viven en la card del asistente en Inicio (donde el paso a la conversación es la continuación natural). Los insights **terminales** NO van al Home como card — van a un centro de notificaciones.

**El razonamiento del usuario, que es el que manda aquí:** *"¿para qué quiero preguntarle a la IA sobre mi próximo pago, si ya lo tengo ahí?"*. Un insight terminal metido en la card del asistente produce disonancia — si el dato ya está completo, la IA ahí sobra. Y sacarlo a una card propia en el Home devolvía la pantalla al problema de saturación del que se venía huyendo: un bloque más compitiendo por atención.

Un cobro próximo es, además, el ejemplo de manual de una notificación: es relevante en un momento específico y deja de serlo después. Una card en el Home es permanente; una notificación caduca sola.

## Por qué NO necesita LLM (y por qué eso importa)

La detección de estos insights es **aritmética determinista sobre datos que ya están en Drift**, no inferencia. Eso no es una limitación, es la propiedad que hace viable la feature:

- **No consume cupo de IA.** `fase-4/21-asistente-ia.md` §HU-10 fija un cupo diario (30 turnos por defecto) contado en servidor, y es explícito en que una compuerta cerrada no puede costar ni un token. Si cada apertura de la app disparara un turno para generar un insight, el cupo se agotaría solo, sin que la persona haya preguntado nada.
- **Funciona sin conexión.** La app es local-first; el asistente no lo es. Un insight calculado localmente sigue llegando en el metro o con datos agotados.
- **No depende del acceso al asistente.** El asistente es hoy beta cerrada por lista y su destino es Premium (Nivel 2). Un insight determinista lo puede ver todo el mundo.
- **Es privado.** No sale nada del dispositivo, lo que es coherente con que `ai_usage_log` deliberadamente no guarde contenido de las conversaciones.

El LLM entra **solo** si la persona decide profundizar, y ese toque es intencional.

### Por qué es Nivel 0

Se apoya únicamente en datos locales y cómputo local, sin costo marginal por usuario. Ponerlo detrás de anuncio o pago contradiría la regla de `CLAUDE.md`. Un insight local NO es el asistente conversacional (Cubo C del plan de monetización) aunque comparta con él el lenguaje visual.

## Qué es material de notificación

Ordenado por qué tan difícil es equivocarse — que es el criterio que debería regir el orden de construcción:

| Insight | Fuente | Dificultad | Nota |
|---|---|---|---|
| Cobro próximo | `ScheduledPaymentOccurrences` + `ProjectUpcomingOccurrences` | Baja | El caso de uso ya existe y es dominio puro sin I/O — se construyó explícitamente como seam para que otras features lo llamen |
| Meta alcanzada / hito | `Goals`, `GoalContributions` | Baja | Refuerzo positivo; encaja con la tesis de Metas como feature de re-enganche |
| Ocurrencia pendiente de confirmar | `ScheduledPaymentOccurrences` (`status: pending`) | Baja | Ya hay `GetPendingOccurrences` |
| Racha de registro / ausencia | `Transactions` | Baja | Valor informativo bajo, pero sirve al hábito. Alto riesgo de sentirse regaño — ver "Tono" |
| Suscripción detectada | `Transactions` (heurística) | Alta | Agrupación por comercio, monto y cadencia; falsos positivos garantizados. No empezar por acá |

Los insights **abiertos** (anomalía por categoría, proyección de presupuesto) **no** pertenecen a este documento: van a la card del asistente en Inicio.

## Qué tendría que ser esta pantalla

La campana ya existe en el header del Home (`04-inicio.md` §HU-07) en estado "próximamente", con su sheet correspondiente. Es el punto de entrada natural y no hay que inventarlo.

Principios que debería respetar, si se construye:

- **Tarjetas, no una lista de texto.** El mismo lenguaje visual que se validó en el maquetado del insight: icon-wrap con color por tipo (`$sky-soft` + `calendar-clock` para pagos, y el equivalente por familia), título en lenguaje natural, dato secundario, y **una acción directa** (confirmar el pago, ver el movimiento, posponer). Una notificación que solo informa desperdicia el momento de atención.
- **Sin orbe de IA.** Es dato de la app, no salida del modelo, y el diseño debe decirlo. Prestarle la identidad visual del asistente a algo que él no generó confundiría de qué es capaz cada cosa.
- **Caduca sola.** Es su ventaja sobre una card del Home. Lo que ya no es relevante desaparece sin que nadie lo cierre.
- **Push y bandeja son la misma feature, en dos superficies.** La notificación del sistema llega fuera de la app; la campana es la bandeja/historial. Lo primero se programa localmente (`flutter_local_notifications`), sin backend, lo que preserva el "sin costo marginal".
- **Un tope de frecuencia, con preferencias por tipo en Ajustes.** La fatiga de notificaciones es el modo de fallo clásico de esta feature: la primera notificación irrelevante entrena a la persona a ignorar todas las siguientes.

### Tono (crítico, no cosmético)

`CLAUDE.md` prohíbe avergonzar al usuario por sus gastos, y una notificación proactiva es el vector perfecto para hacerlo sin querer. La distancia entre *"Netflix se cobra en 3 días"* y *"cuidado, te van a cobrar"* es la distancia entre que abra la app y que apague las notificaciones.

Dos reglas que se derivan de eso:
- **Informar y habilitar, nunca alarmar ni regañar.** Ni siquiera con buena intención.
- **Umbrales duros de significancia.** Un insight obvio o falso — *"gastaste $0 en transporte"*, *"tu gasto subió"* con tres transacciones registradas — destruye más confianza de la que uno bueno construye. Sin mínimo de datos y mínimo de delta, no hay notificación.

## Dependencias y precondiciones

- **Recordatorios de vencimientos** ya está previsto como HU-08 dentro de [`fase-1/09-pagos-programados.md`](../fase-1/09-pagos-programados.md) y es la quinta pieza de Fase 2. **Hay solapamiento real con este documento** y debe resolverse antes de construir cualquiera de los dos: o los recordatorios de pagos son el primer caso de uso de este centro, o este centro se construye encima de lo que aquellos dejen. Dos sistemas de recordatorio en paralelo sería el peor resultado.
- Permisos de notificación en Android e iOS: primeros `uses-permission` / claves de `Info.plist` para esto, con impacto en `docs/legal/declaraciones-tiendas.md`.
- Posible tabla nueva si la bandeja necesita persistir estado de leído/descartado. **No asumir que hace falta**: buena parte del contenido es derivable de las tablas existentes en el momento de mostrarlo. Si termina haciendo falta, aplica `/drift-schema-change` y la paridad en Supabase.

## Lo que queda sin decidir

- Si la bandeja persiste estado o se deriva en vivo.
- Cómo se relaciona con los recordatorios de vencimientos de Fase 2 (ver arriba — es la decisión bloqueante).
- Si el push del sistema entra en la primera versión o solo la bandeja in-app.
- Agrupación (por día, por tipo) y qué pasa cuando hay varios insights a la vez.

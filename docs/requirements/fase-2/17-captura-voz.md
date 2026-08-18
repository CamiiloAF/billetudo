# Feature: Captura por voz

**Nivel:** 0 (gratis, ilimitada, sin anuncios)
**Fase:** 2 — captura sin fricción local
**Tabla Drift:** ninguna nueva. Escribe en `Transactions` con `source = voice` (`TxSource.voice`, `lib/core/database/app_database.dart:46`).
**Depende de:** `fase-1/03-transacciones.md` (el formulario que esta feature pre-llena), `fase-1/15-gate-cuenta.md` (gate de cuenta), `fase-1/02-categorias.md` (resolución de categoría).
**Orden dentro de Fase 2:** se construye **después** de `19-notificaciones-bancarias.md`.

## Contexto

Registrar un gasto a mano toma entre 15 y 30 segundos: abrir la app, abrir el formulario, elegir cuenta, elegir categoría, teclear el monto, guardar. Esa fricción es la razón número uno por la que la gente abandona una app de finanzas — no la falta de features. Esta feature reduce ese costo a **hablar una frase**: "gasté veinte mil en almuerzo".

Tres decisiones ya cerradas, que este documento no re-litiga:

1. **Todo corre en el dispositivo.** Audio→texto con el reconocedor nativo de la plataforma (`speech_to_text`), y el texto se interpreta con **reglas locales** (expresiones regulares + diccionarios en español y en inglés). Sin backend, sin costo marginal, sin API keys en la app.
2. **Es Nivel 0.** Gratis, ilimitada, sin anuncios, sin cupo mensual. El parseo con LLM llega en **Fase 4** como Nivel 1 (mejora de precisión) y **nunca puede bloquear ni degradar** la captura por voz entregada aquí: si el usuario no tiene Nivel 1, la captura por voz sigue funcionando exactamente igual con reglas locales.
3. **Retención cero, política de toda la Fase 2 (decisión 2026-08-17).** Del material crudo de captura no se persiste nada: ni el audio, ni la transcripción cruda. Solo se guardan los **campos ya extraídos** hacia la transacción que el usuario confirma. El mismo criterio se aplicó al texto de las notificaciones bancarias (`19-notificaciones-bancarias.md`) y al texto reconocido por OCR (`18-captura-ocr.md`) — es política de fase, no una regla particular de voz. Ver HU-06 para la consecuencia sobre Fase 4.
4. **La voz nunca registra sola.** Lo dictado **pre-llena el formulario de transacción existente** (HU-01 de `03-transacciones.md`) y el usuario confirma ahí. No hay escritura automática en la base de datos. **No** pasa por la bandeja de pendientes — esa bandeja existe solo para notificaciones bancarias, que llegan sin el usuario presente; aquí el usuario está mirando la pantalla.

**Lo que esta feature NO es:** no es un asistente conversacional, no responde preguntas ("¿cuánto llevo gastado?"), no ejecuta comandos de navegación. Es un método de entrada para un formulario.

## Historias de usuario

### HU-01 — Dictar un gasto y confirmarlo

Como usuario quiero decir en voz alta "gasté veinte mil en almuerzo" y que la app me abra el formulario de gasto ya lleno, para registrar en segundos en vez de teclear campo por campo.

**Criterios de aceptación:**
- El flujo completo es: **disparar → hablar → ver transcripción → formulario pre-llenado → confirmar**. Nunca se persiste una `Transaction` sin que el usuario toque el botón de guardar del formulario.
- La transacción resultante se guarda con `source = voice`. Es el primer flujo del producto que produce ese valor (hoy `TxSource.voice` existe en el enum pero nunca se emite).
- El resto de reglas del formulario aplican sin excepción: `amountMinor` entero positivo en centavos, `categoryId` obligatorio para gasto/ingreso, `accountId` obligatorio, `date` obligatoria, `updatedAt` en la escritura, `id` UUID.
- Si el usuario edita cualquier campo pre-llenado antes de guardar, se guarda lo editado. `source` sigue siendo `voice` — el origen de captura es un hecho histórico, no cambia porque el usuario haya corregido un campo (paridad con HU-04 de `03-transacciones.md`).
- Si el usuario descarta el formulario (back/swipe), no se escribe nada y no queda residuo en ninguna tabla.
- El detalle de transacción (HU-08 de `03-transacciones.md`) muestra el origen "Voz" de forma legible.

**Pendiente de decidir:** ¿la voz puede registrar **ingresos** y **transferencias**, o solo gastos en la primera entrega?
- *Solo gastos:* el parser es mucho más simple y el gasto es el 90% del uso real. Riesgo: el usuario dice "me pagaron dos millones" y la app registra un gasto de $2.000.000, que es peor que no entender nada.
- *Gastos + ingresos:* requiere detectar polaridad por verbo ("gasté/pagué/compré" vs. "me pagaron/recibí/me entró"), y un fallback explícito cuando la polaridad es ambigua.
- *Los tres tipos:* la transferencia exige detectar dos cuentas ("pasé cien mil de Bancolombia a Nequi") y es la que más se equivoca.
Recomendación técnica (no decisión): entregar gastos + detección de polaridad para ingresos, dejar transferencias fuera.

### HU-02 — Disparar la captura por voz

Como usuario quiero llegar a dictar en el menor número de toques posible, porque si dictar cuesta lo mismo que teclear, no lo voy a usar.

**Criterios de aceptación:**
- El punto de entrada es visible sin abrir menús ni pantallas intermedias.
- El estado inicial siempre es el mismo (no recuerda "la última vez dictaste un ingreso"): la voz interpreta lo dicho, no el historial.
- Si no hay cuentas activas aplica el **gate de cuenta** de `15-gate-cuenta.md`: el disparador **sigue visible y tocable** (prohibido deshabilitarlo en gris); al activarlo se ofrece crear la cuenta y se **continúa automáticamente** al flujo de voz. El gate no puede degradarse a un botón muerto solo porque el flujo entra por voz.
- El disparador **no reemplaza** el registro manual: el camino de HU-01 de `03-transacciones.md` sigue existiendo íntegro y con la misma prominencia que hoy.

**Pendiente de decidir:** ¿dónde vive el disparador?
- *Long-press sobre el FAB de Home:* cero superficie nueva, pero es un gesto oculto — nadie lo descubre sin tutorial, y contradice la intención de "reducir fricción" si hay que enseñarlo.
- *Botón de micrófono dentro del formulario de transacción:* descubrible y coherente ("dicta en vez de teclear"), pero ya cuesta 2 toques abrir el formulario, así que ahorra poco.
- *Segunda acción visible junto al FAB (speed dial / FAB extendido con dos zonas):* el más descubrible y el más barato en toques, pero añade peso visual permanente al Home y hay que diseñarlo contra `MASTER.md`.
- *Widget de home screen del sistema:* es literalmente la feature `20-widget-captura-rapida.md`; aquí solo hay que decidir si ese widget puede lanzar directo el modo voz.
Se puede elegir más de uno; lo que hay que decidir es cuál es el **principal**.

### HU-03 — Grabar y ver que la app me está escuchando

Como usuario quiero saber sin ambigüedad cuándo la app está escuchando, cuándo dejó de escuchar y qué entendió, para no quedarme hablándole a una pantalla muerta.

**Criterios de aceptación:**
- Mientras escucha hay **feedback visual continuo y en vivo**: un indicador que reacciona al audio (nivel/onda), no un spinner genérico. Un spinner no distingue "te estoy oyendo" de "estoy colgada".
- La **transcripción parcial se muestra en pantalla mientras el usuario habla** (el reconocedor nativo entrega resultados parciales). El usuario debe poder ver que "veinte mil" se transcribió bien antes de que termine la frase.
- Hay una forma explícita de **cancelar** durante la escucha, que descarta el audio y la transcripción y no abre ningún formulario.
- **Auto-detención por silencio:** si el reconocedor detecta fin de habla, la escucha se detiene sola. Debe existir además un **tope duro de duración** para que una escucha no quede colgada indefinidamente (consume batería y micrófono).
- Si el reconocedor no devuelve **nada** (silencio total, ruido, micrófono tapado), la app lo dice en tono neutro y ofrece **reintentar** en un toque y **escribir en su lugar** (abrir el formulario vacío). Nunca un mensaje de error técnico ni una insinuación de que el usuario habló mal.
- El indicador de escucha es accesible: anunciado por lector de pantalla ("Escuchando", "Listo"), no solo visual.

**Pendiente de decidir:** ¿**mantener pulsado** para hablar (push-to-talk) o **un toque para iniciar y otro para detener**?
- *Mantener pulsado:* el modelo mental es obvio (walkie-talkie), imposible dejar el micrófono abierto por accidente, y el usuario controla exactamente el fin. Contra: exige una mano fija sobre la pantalla, es hostil para motricidad reducida, y a una mano en la calle es incómodo.
- *Toque para iniciar / toque o silencio para detener:* manos más libres, mejor para accesibilidad. Contra: si la auto-detención por silencio se dispara tarde, se cuela ruido ambiente; y si se dispara temprano, corta al usuario a mitad de frase.
Sea cual sea el principal, la ruta accesible del otro modo debe existir (ver HU-09).

**Pendiente de decidir:** ¿cuál es el tope duro de duración de una escucha (p. ej. 15 s, 30 s, 60 s)? Corto protege batería y evita capturas basura; largo permite frases con nota larga ("gasté cuarenta mil en el mercado de la semana, pañales y leche"). Debe medirse contra frases reales, no elegirse a ojo.

### HU-04 — Qué puedo dictar (parseo con reglas locales)

Como usuario quiero decir la frase natural que ya diría en voz alta, sin aprenderme una sintaxis, y que la app extraiga los campos que pueda.

**Criterios de aceptación:**
El parser local intenta extraer, de la transcripción, estos campos. **Ninguno es obligatorio**: lo que no se extrae simplemente queda vacío en el formulario (HU-05).

**a) Monto (`amountMinor`, centavos enteros)**
- Dígitos: "20000", "20.000", "20,000", "3500".
- Palabras en español: "veinte mil", "dos millones", "quinientos", "mil quinientos", "ciento cincuenta mil".
- Coloquialismos es-CO: "20 lucas" / "veinte lucas" = 20.000; "20 barras" = 20.000; "un palo" = 1.000.000; "una luca" = 1.000.
- Elipsis de magnitud, muy frecuente hablando: "tres y medio" (en contexto de miles → 3.500) y "veinte" a secas.
- Decimales: "doce mil quinientos", "12.500", "doce con cincuenta".
- La conversión a centavos es del parser: 20.000 COP → `amountMinor = 2000000`. **Nunca** se representa un monto en `double` en ningún punto del pipeline.
- El monto extraído es siempre **positivo**; la dirección del movimiento la determina `type` (regla de `03-transacciones.md`).

**Pendiente de decidir:** cómo se resuelve la **ambigüedad de magnitud** en montos sin unidad ("gasté veinte", "gasté tres y medio"). En Colombia "veinte" casi siempre son 20.000, pero en México o España "veinte" suelen ser 20. Opciones:
- *Multiplicador por país/moneda* (heurística: si la moneda de la cuenta es COP y el número es < 1000, multiplicar por 1000). Rápido y acierta el caso común es-CO; falla y sorprende en el caso legítimo de un gasto de $20.
- *No inventar magnitud:* pre-llenar el monto literal y dejar que el usuario corrija. Nunca sorprende, pero obliga a editar el campo más importante en el caso más común.
- *Pre-llenar con la heurística pero marcar el campo como "verifica esto"* (foco automático en Monto, valor preseleccionado para sobreescribir de un toque). Más trabajo de UI, mejor de ambos.
Esta decisión afecta directamente la percepción de si la feature "funciona".

**b) Categoría (`categoryId`)**
- Se resuelve por **coincidencia de palabra clave** contra: el nombre de las categorías del usuario (incluidas subcategorías, `02-categorias.md`) y un **diccionario de sinónimos por defecto** en es y en en ("almuerzo/comida/mercado/domicilio" → Alimentación; "uber/taxi/gasolina/bus/transmilenio" → Transporte; "arriendo/servicios/luz/agua" → Hogar).
- Si el usuario **renombró** o creó categorías propias, sus nombres tienen **prioridad** sobre el diccionario por defecto — es su vocabulario, no el nuestro.
- Se prefiere la coincidencia más específica: si "gasolina" mapea a una subcategoría, se elige la subcategoría, no la raíz.
- Si hay **empate o ninguna coincidencia**, la categoría queda vacía y el formulario la pide (es obligatoria para gasto/ingreso). No se elige "la más usada" a la fuerza.
- El diccionario de sinónimos es **local, versionado con la app y traducible** (es/en). No es una llamada de red.

**Pendiente de decidir:** ¿el usuario puede **enseñarle** sinónimos a la app (ej. "cuando diga 'la vaca' es Alimentación")? Un aprendizaje local por confirmación (si el usuario dicta X y termina eligiendo la categoría Y, recordar X→Y) sube mucho la precisión con el uso, pero implica **nueva persistencia** (una tabla de alias) y por tanto cambio de esquema y sync. Alternativa: no aprender nada en Fase 2 y dejar el aprendizaje para cuando llegue el parseo con LLM.

**c) Cuenta (`accountId`)**
- Se resuelve por coincidencia con el **nombre de la cuenta** dicho en la frase: "pagué con Nequi", "en efectivo", "con la tarjeta de Bancolombia".
- La coincidencia es tolerante a acentos, mayúsculas y espacios, y admite el nombre parcial ("banco" → "Bancolombia" solo si es la única cuenta que coincide; con dos coincidencias, no se elige ninguna).
- Si no se menciona cuenta, se pre-llena con **la misma cuenta por defecto que usaría el formulario manual** — no una regla nueva e invisible propia de la voz.

**d) Fecha (`date`)**
- Default: **hoy**, igual que el formulario manual.
- Fechas relativas en es: "ayer", "anteayer", "hoy", "esta mañana", "anoche", "el lunes" / "el lunes pasado" (día de semana más reciente en el pasado), "hace tres días", "el 5" (día del mes en curso o el anterior si ya pasó).
- Equivalentes en en: "yesterday", "last Monday", "three days ago".
- **Nunca se interpreta una fecha futura** desde la voz: si lo dictado apunta al futuro ("el viernes que viene"), el flujo correcto es un pago programado, no una transacción — el puente ya existe en HU-06 de `09-pagos-programados.md`. Se pre-llena la fecha y el formulario aplica su pregunta normal de "¿es un pago programado?".

**e) Nota (`note`)**
- El texto que sobra tras extraer monto/categoría/cuenta/fecha se propone como nota, **limpio de las muletillas de comando** ("gasté", "registra", "apunta").
- **La transcripción completa nunca se pierde** (ver HU-05).

**f) Etiquetas (`tags`)**
- **Fuera de alcance en esta entrega.** Extraer etiquetas libres por voz es ambiguo (¿"viaje" es categoría, nota o etiqueta?) y el usuario puede añadirlas en el formulario antes de confirmar.

**Ejemplos que deben funcionar (es-CO), como criterio verificable:**

| Dicho | Monto | Categoría | Cuenta | Fecha |
|---|---|---|---|---|
| "gasté veinte mil en almuerzo" | 20.000 | Alimentación | default | hoy |
| "20 lucas de gasolina con Nequi" | 20.000 | Transporte/Gasolina | Nequi | hoy |
| "ayer pagué cien mil de arriendo" | 100.000 | Hogar/Arriendo | default | ayer |
| "el lunes gasté 35.500 en el mercado" | 35.500 | Alimentación/Mercado | default | lunes pasado |
| "un palo del seguro del carro" | 1.000.000 | (sin match → vacío) | default | hoy |
| "me tomé un tinto" | (vacío) | Alimentación | default | hoy |

Estos casos deben existir como **tests unitarios del parser** (dominio puro, sin micrófono): el parser es una función de texto → campos, y se prueba sin plataforma.

### HU-05 — Cuando el parseo falla o es parcial

Como usuario quiero que, aunque la app no entienda todo lo que dije, no me haga empezar de cero ni me haga sentir que hablé mal.

**Este es el caso más frecuente con reglas locales, no la excepción.** El diseño se optimiza para él.

**Criterios de aceptación:**
- **Nunca se pierde lo dictado durante el flujo.** La transcripción completa siempre está disponible en el formulario (como nota pre-llenada, o visible y copiable). Si la app entendió el monto pero nada más, el usuario todavía tiene su frase para completar a mano. Esto es compatible con la retención cero (HU-06): la transcripción vive **en memoria mientras el flujo está abierto** y se descarta al cerrarlo; solo sobrevive lo que el usuario deja confirmado en un campo del formulario.
- **Se abre el formulario con lo que sí se entendió**, aunque sea un solo campo. No existe un estado "no entendí, intenta de nuevo" que descarte el trabajo del usuario.
- **Cero-campos-entendidos también abre el formulario**, con la transcripción como nota. Es el peor caso y aun así el usuario sale con algo.
- **El foco entra en el primer campo obligatorio que quedó vacío**, para que completar sea inmediato y no haya que buscar qué falta.
- Los campos que la app **infirió** se distinguen visualmente de los que el usuario ya confirmó, para que revisar sea rápido y no haya que releer todo.
- **Tono:** los mensajes describen el estado de la app, nunca el desempeño del usuario. "Completa el monto" / "Elige la categoría", nunca "No te entendí", "Habla más claro" o "Intenta de nuevo hablando despacio". Regla de tono de `CLAUDE.md`: la app nunca avergüenza al usuario.
- Reintentar el dictado desde el formulario debe ser posible **sin perder** lo ya corregido a mano: un segundo dictado **completa campos vacíos**, no sobreescribe lo que el usuario ya tocó.

**Pendiente de decidir:** ¿cómo se marcan visualmente los campos inferidos? Opciones: un estilo de campo "sugerido" (borde/fondo distinto) que se normaliza al tocarlo; un chip "Por voz" sobre los campos inferidos; o ninguna marca (el usuario revisa todo igual). La primera es la más honesta pero es superficie de diseño nueva en un formulario ya denso.

### HU-06 — Privacidad del audio

Como usuario quiero saber exactamente qué pasa con mi voz, porque conceder el micrófono a una app de finanzas es la decisión más sensible que me va a pedir.

**Retención cero (decisión 2026-08-17).** De todo el material crudo de captura no se persiste nada: **ni el audio ni la transcripción cruda**. Solo se guardan los **campos ya extraídos** hacia la transacción que el usuario confirma. Es la **política uniforme de toda la Fase 2** — el mismo criterio se aplicó al texto de las notificaciones bancarias (`19-notificaciones-bancarias.md`) y al texto reconocido por OCR (`18-captura-ocr.md`), no es una regla particular de voz.

**Consecuencia honesta, asumida al decidir:** en **Fase 4**, cuando llegue el parseo con LLM, solo podrá mejorar **capturas nuevas**. No habrá forma de re-parsear retroactivamente lo que el usuario dictó antes, porque el texto original ya no existe. Se acepta el costo: guardar texto crudo de voz que el usuario nunca eligió conservar es exactamente lo que la promesa de privacidad de esta feature dice que no hacemos.

**Criterios de aceptación:**
- **El archivo de audio no se persiste.** El audio se usa solo para producir la transcripción y se descarta al terminar la escucha. No hay archivos de audio en el almacenamiento de la app, ni en la base de datos, ni en el backup, ni en el sync.
- **La transcripción cruda no se persiste como tal en ningún campo.** Vive únicamente en memoria durante el flujo de captura y se descarta al cerrarlo. Lo único que puede sobrevivir es lo que el usuario confirmó en el formulario: si eligió dejar parte del texto en `note`, se guarda **ese** contenido como nota que él aceptó, no la transcripción como registro aparte. Cancelar el flujo no deja rastro.
- **No se sincroniza audio.** PowerSync/Supabase nunca reciben audio; reciben la `Transaction` confirmada, igual que cualquier otra.
- **La app no envía audio a servidores propios ni de terceros.** El único procesamiento es el reconocedor nativo del sistema operativo (ver el punto de iOS abajo).
- Esta feature **obliga a actualizar los documentos de tienda**: `docs/legal/declaraciones-tiendas.md:165` y `docs/legal/AUDITORIA.md:649` hoy declaran ante Google Play y App Store que la app **no** tiene captura por voz. Deben actualizarse **antes** de publicar una build con esta feature: declaración de micrófono, propósito ("registrar transacciones dictadas por el usuario"), retención ("no se retiene audio"), y, si aplica, el enrutamiento de reconocimiento del punto siguiente. Debe pasar por `privacy-legal-officer`.
- La política de privacidad debe describir el tratamiento en lenguaje llano, incluida la salvedad de iOS.

**Punto crítico — iOS puede enrutar el reconocimiento a servidores de Apple.** `SFSpeechRecognizer` procesa on-device solo si el dispositivo y el idioma lo soportan y se pide explícitamente (`requiresOnDeviceRecognition`); en caso contrario Apple procesa el audio en sus servidores. Eso contradice de frente la promesa "todo local" de Fase 2 y **no puede quedar sin resolver**.
- **Requisito duro:** la app debe solicitar reconocimiento **on-device** en iOS siempre que la plataforma lo permita, y debe **saber** si lo consiguió o no.
- Android: `SpeechRecognizer` tiene la misma bifurcación (on-device vs. servicio de Google, según dispositivo, versión y paquetes de idioma instalados). Aplica el mismo requisito y la misma decisión.

**Pendiente de decidir — EL MÁS URGENTE DE ESTE DOCUMENTO:** ¿qué hace la app cuando el reconocimiento **on-device no está disponible** en ese dispositivo/idioma?

> **Por qué subió de prioridad con la decisión de retención cero (2026-08-17):** la retención cero cierra la pregunta de *qué guardamos* (nada), pero **no** la de *a dónde sale el audio mientras se transcribe*. Si el reconocimiento cae al servicio en la nube del sistema operativo, el audio del usuario **sale del dispositivo** aunque nosotros no guardemos absolutamente nada — y eso tensiona de frente la promesa de "todo local" de Fase 2, que es el argumento con el que pedimos el micrófono. No guardar no es lo mismo que no transmitir, y la política de fase por sí sola no responde este punto. Es la única pregunta abierta que puede volver falso un texto de tienda o de política de privacidad, así que se resuelve **antes** que cualquier otra de este documento.

- *(A) Degradar en silencio a reconocimiento en la nube del sistema operativo* — la feature funciona en todos los dispositivos, pero la promesa "todo local" deja de ser cierta y hay que declararlo en tienda y en la política de privacidad para **todos** los usuarios, aunque a la mayoría no le aplique.
- *(B) Desactivar la voz en esos dispositivos* — la promesa se mantiene intacta y limpia, pero un subconjunto de usuarios (probablemente dispositivos Android de gama baja, justo el mercado objetivo) pierde la feature completa sin entender por qué.
- *(C) Preguntar una vez, con explicación clara* ("En este teléfono el reconocimiento lo hace {Apple/Google}. ¿Activar de todos modos?"), guardando la elección y permitiendo cambiarla en Ajustes. Es la más honesta y la más costosa: un diálogo de privacidad más, y una preferencia nueva que persistir.
Esta decisión determina el texto de tienda, así que hay que tomarla **antes** de escribir las declaraciones.

**Decidido (2026-08-17) — resuelto en negativo:** se evaluó guardar la transcripción original como **campo propio** en la transacción (auditoría/depuración, y poder re-parsear con LLM en Fase 4 lo ya capturado). **No se hace.** Implicaba cambio de esquema y almacenar texto crudo de voz que el usuario no eligió conservar, justo lo contrario de la promesa de retención cero. Queda registrado el trade-off aceptado: el LLM de Fase 4 solo mejora capturas nuevas.

### HU-07 — Permisos de micrófono

Como usuario quiero entender por qué la app me pide el micrófono antes de que aparezca el diálogo del sistema, y quiero que negarlo no me rompa la app.

**Criterios de aceptación:**
- **Explicación previa antes del diálogo del sistema (obligatorio).** La primera vez que el usuario dispara la voz, la app explica en una frase para qué se usa el micrófono y que el audio no se guarda, y solo entonces solicita el permiso. Nunca se dispara el diálogo nativo "en frío": en iOS el diálogo aparece **una sola vez** y un "No permitir" ahí es prácticamente irreversible para el usuario promedio.
- El permiso se pide **en el momento de usar la feature**, nunca en el onboarding ni al abrir la app.
- **Permisos necesarios:**
  - Android: `RECORD_AUDIO` en `android/app/src/main/AndroidManifest.xml` (hoy el manifiesto **no declara ningún** `uses-permission`). Android 11+ puede requerir además una entrada `<queries>` para resolver el servicio de reconocimiento.
  - iOS: `NSMicrophoneUsageDescription` **y** `NSSpeechRecognitionUsageDescription` en `ios/Runner/Info.plist` (hoy **no hay ninguna** clave `*UsageDescription`). Ambos textos van localizados es/en y deben decir la verdad de lo decidido en HU-06.
- **Permiso denegado: la feature se degrada, nunca bloquea.** Con el micrófono denegado:
  - El registro manual sigue **100% funcional e inalterado** — es Nivel 0 y no puede depender de un permiso.
  - Disparar la voz abre el formulario manual con un aviso breve y no punitivo, más un acceso directo a los ajustes del sistema para conceder el permiso.
  - La app **no vuelve a pedir el permiso de forma insistente** en cada intento.
- **Permiso revocado a mitad de sesión** (el usuario lo quita desde Ajustes del sistema): el siguiente intento se comporta como "denegado", sin crash y sin estado inconsistente.
- Habilitar `speech_to_text` en `pubspec.yaml` (líneas 84-87, hoy comentado a propósito). El comentario existente dice que se mantiene fuera porque arrastra declaraciones de privacidad "que todavía no hay qué justificar" — **Fase 2 es exactamente cuando sí hay qué justificar**, así que el comentario se reemplaza por la referencia a este documento, no se borra sin más.

**Pendiente de decidir:** ¿la app ofrece un **interruptor propio** de "captura por voz" en Ajustes, además del permiso del sistema? A favor: permite apagar la feature sin tocar permisos del sistema, deja un lugar donde vive la preferencia de reconocimiento on-device (HU-06 opción C), y da un lugar visible a la promesa de privacidad. En contra: dos interruptores para la misma cosa confunden, y la fuente de verdad debe ser siempre el permiso del sistema.

### HU-08 — Idioma

Como usuario quiero dictar en el idioma en que uso la app, y que si mi teléfono está en otro idioma la app no se quede muda.

**Criterios de aceptación:**
- El reconocedor se inicializa con el **locale de la app** (`AppLocalizations`), no con el del sistema: si la app está en español, se dicta en español aunque el teléfono esté en inglés.
- El **parser de reglas es por idioma**: diccionario de números en palabras, coloquialismos de monto, fechas relativas y sinónimos de categoría existen en **es** y en **en**. Los coloquialismos es-CO ("lucas", "palo", "barras") viven en el diccionario **es** y no rompen nada en **en**.
- Si el locale de la app **no tiene reconocimiento disponible** en ese dispositivo (paquete de idioma no instalado, sin conexión y sin modelo local), la app lo comunica en tono neutro y ofrece el registro manual. **No** hace fallback silencioso a otro idioma: transcribir español con un modelo de inglés produce basura, y basura confiada es peor que un mensaje honesto.
- El parser **no** intenta detectar el idioma del texto: usa el mismo idioma con que se pidió el reconocimiento.
- Cambiar el idioma de la app cambia el idioma de dictado **sin reiniciar** la app.
- Ningún string de UI de esta feature está hardcodeado: todo desde `AppLocalizations` (`lib/core/l10n/arb/`), regla `avoid_hardcoded_ui_strings`.

**Pendiente de decidir:** ¿se ofrece elegir el idioma de dictado **independiente** del idioma de la app? Caso real: usuario bilingüe que tiene la app en inglés pero dice los montos en español. A favor: mucha gente en el mercado objetivo mezcla. En contra: es una preferencia más, y el 95% de los usuarios nunca la tocaría.

**Pendiente de decidir:** ¿se soportan variantes regionales del español más allá de es-CO en la primera entrega? Los coloquialismos de monto son fuertemente locales ("lucas" en CO/CL, "varos" en MX, "pavos" en ES). Opciones: entregar solo es-CO y añadir variantes por demanda; o cargar todos los coloquialismos hispanos a la vez (más cobertura, más falsos positivos: "barras" o "palos" tienen otro significado en otras variantes).

### HU-09 — Accesibilidad

Como persona con dificultad para escribir en pantalla —o simplemente con las manos ocupadas— quiero que la voz sea una vía real de uso; y como persona que no puede o no quiere hablar, quiero que nada de la app dependa de que yo hable.

**Criterios de aceptación:**
- **La voz es siempre una alternativa, nunca un requisito.** No existe ninguna acción del producto que solo se pueda hacer hablando. El registro manual completo es la ruta principal y permanece intacta (Nivel 0).
- **El disparador es operable con lector de pantalla:** etiqueta semántica descriptiva ("Registrar por voz"), no un ícono sin nombre, y área táctil mínima acorde a `MASTER.md`.
- Los estados de escucha (escuchando / procesando / listo / cancelado) se **anuncian** al lector de pantalla, no solo se animan.
- **Si el modo principal es mantener pulsado (HU-03), debe existir una ruta alternativa sin pulsación sostenida** — sostener un botón es inviable para varias condiciones motoras. La ruta alternativa no puede estar escondida detrás de un ajuste que haya que descubrir.
- El feedback de escucha no depende **solo** del color (contraste y forma también), ni **solo** de animación (debe entenderse con "reducir movimiento" activo).
- No hay límite de tiempo hostil: si existe un tope de duración (HU-03), debe ser suficiente para habla lenta o entrecortada.
- La transcripción mostrada respeta el tamaño de fuente del sistema y no se recorta a una línea fija.

### HU-10 — La voz no rompe nada de lo ya entregado

Como dueño del producto quiero garantía de que añadir voz no degrada la app existente.

**Criterios de aceptación:**
- `speech_to_text` se inicializa **de forma perezosa**, al primer uso de la feature — no en el arranque de la app. El tiempo de arranque no puede empeorar por una feature opcional.
- Si el plugin falla al inicializar, la app **no crashea**: la voz queda no disponible y todo lo demás sigue igual.
- La app **no** solicita micrófono en el arranque ni en el onboarding.
- Ningún test existente se vuelve dependiente de un micrófono: el parser es dominio puro y se prueba sin plataforma; la capa de reconocimiento se aísla tras una interfaz de dominio y se falsea en tests (`presentation` → `domain` ← `data`, con el plugin viviendo en `data`).
- La feature vive en `lib/features/capture/` (hoy vacío, solo `.gitkeep`) con las tres capas de Clean Architecture. Comparte esa carpeta con OCR y widget de captura; **Pendiente de decidir:** ¿`capture` es una feature con submódulos (`capture/voice`, `capture/ocr`) o son features hermanas (`voice_capture`, `ocr_capture`)? Afecta la organización de DI y de tests, y conviene decidirlo aquí porque OCR y notificaciones bancarias llegan a la misma carpeta.

## Reglas de negocio y edge cases

- **Sin cuentas activas:** aplica el gate de `15-gate-cuenta.md` como puente, nunca como muro (HU-02).
- **La voz nunca escribe sola.** Ninguna ruta —ni un dictado perfecto, ni un reintento, ni el widget de `20-widget-captura-rapida.md`— puede persistir una `Transaction` sin confirmación explícita en el formulario.
- **La voz no pasa por la bandeja de pendientes** de `19-notificaciones-bancarias.md`. Esa bandeja existe porque las notificaciones llegan sin el usuario presente; en la voz el usuario está mirando la pantalla y confirma en el acto.
- **Duplicados:** dictar dos veces lo mismo crea dos transacciones. La app no deduplica capturas de voz — el usuario puede legítimamente pagar dos almuerzos de $20.000 el mismo día. **Pendiente de decidir:** ¿se avisa cuando se está por confirmar una transacción idéntica (mismo monto, cuenta, categoría y fecha) a otra registrada en los últimos minutos? Un aviso no bloqueante evita el duplicado accidental por doble disparo; también puede volverse ruido en gastos legítimamente repetidos.
- **Monto ausente:** una transacción sin monto no es registrable. Si el parser no extrajo monto, el formulario se abre igualmente (HU-05) y bloquea el guardado con la misma validación que el flujo manual — no con una validación especial de voz.
- **Sin conexión:** la app es offline-first y esta feature no puede ser la excepción. Si el reconocimiento del dispositivo requiere red y no la hay, se comunica en tono neutro y se ofrece el registro manual. Con reconocimiento on-device disponible, debe funcionar sin conexión.
- **Interrupciones del sistema durante la escucha** (llamada entrante, otra app toma el micrófono, la app pasa a background): la escucha se detiene limpiamente, no queda el micrófono abierto, y lo transcrito hasta ese punto **no se pierde** — se trata como transcripción parcial (HU-05).
- **Modo silencio / auriculares / Bluetooth:** el reconocimiento usa la ruta de audio del sistema; la app no gestiona rutas de audio ni reproduce sonidos de confirmación que puedan sonar en un lugar público sin que el usuario lo pida.
- **Batería y micrófono:** la escucha se detiene siempre —por silencio, por tope de duración, por cancelación o por background. No existe un camino donde el micrófono quede abierto indefinidamente.
- **Fecha futura dictada:** no se registra como transacción; se enruta por el puente de pago programado (HU-06 de `09-pagos-programados.md`).
- **Multi-moneda:** el monto dictado se interpreta en la moneda de la cuenta seleccionada, igual que en el formulario manual (`12-multi-moneda.md`). La voz **no** interpreta monedas dichas ("cincuenta dólares") en esta entrega.

## Cambios de esquema requeridos (Drift)

**Ninguno.** `TxSource.voice` ya existe en el enum (`lib/core/database/app_database.dart:46`) y se persiste como texto, con paridad ya establecida en Supabase. La transacción resultante es una `Transaction` normal; el sync no requiere nada nuevo. **`schemaVersion` no cambia por esta feature** — confirmado tras la decisión de retención cero, que eliminó el único cambio de esquema que esta feature tenía en el aire.

**No asumas que 27 está libre.** Dentro de Fase 2 las versiones ya están repartidas:

| Doc | schemaVersion |
|---|---|
| `17-captura-voz.md` (este) | **ninguno** — no consume número |
| `19-notificaciones-bancarias.md` | 26 → **27** |
| `18-captura-ocr.md` | 27 → **28** |

- **Transcripción cruda como campo propio** (HU-06): **descartado (decisión 2026-08-17)**, retención cero. Era el único cambio de esquema que la entrega base podía llegar a necesitar.
- **Alias de categoría aprendidos** (HU-04b, sigue pendiente): si se implementa, requeriría una tabla nueva (con `_SyncColumns`), subir `schemaVersion`, migración `onUpgrade` y paridad en Supabase/PowerSync, vía `/drift-schema-change`. **Iría después de las dos de arriba** — quien lo retome debe tomar la siguiente versión libre (29 o superior según lo ya aplicado), **nunca** 27. Recordatorio de `MEMORY`: subir `schemaVersion` **no** migra Postgres — sin el `ALTER TABLE`/`CREATE TABLE` explícito en dev **y** prod, el sync queda en cuarentena con PGRST204.

Cualquier preferencia nueva de usuario (interruptor de voz en Ajustes, idioma de dictado, reconocimiento on-device) debe evaluarse contra el mecanismo de preferencias ya existente en `settings` antes de asumir que necesita una columna.

## Fases de entrega

1. **Andamiaje y permisos.** Habilitar `speech_to_text`, declarar `RECORD_AUDIO` (Android) y `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` (iOS), estructura Clean Architecture en `lib/features/capture/`, interfaz de dominio del reconocedor con implementación falsa para tests, flujo de permiso con explicación previa y degradación (HU-07).
2. **Parser local, sin micrófono.** Casos de uso puros de texto → campos: monto (dígitos, palabras, coloquialismos es-CO), fecha relativa, cuenta, categoría, nota; es y en. Es la pieza con más valor por línea y la única totalmente testeable sin plataforma — la tabla de ejemplos de HU-04 es la suite base.
3. **Flujo de captura.** Disparador (HU-02), escucha con feedback en vivo y transcripción parcial (HU-03), paso al formulario pre-llenado y manejo del parseo parcial (HU-05), accesibilidad (HU-09).
4. **Privacidad y tienda.** Resolver la decisión de reconocimiento on-device (HU-06), actualizar `docs/legal/declaraciones-tiendas.md` y `docs/legal/AUDITORIA.md` (que hoy declaran que la app no tiene captura por voz) y la política de privacidad, vía `privacy-legal-officer`. **Bloquea la publicación**, no la implementación.
5. **Refinamiento con uso real.** Ampliar diccionarios y coloquialismos con lo que la gente realmente dijo y la app no entendió, midiendo qué campo falla más. **Con retención cero esto no se puede hacer leyendo transcripciones guardadas** (no existen): hay que apoyarse en métricas anónimas de *qué campo quedó vacío* y en pruebas con usuarios, nunca en el texto dictado. Insumo para el parseo con LLM de Fase 4, que se **suma** encima sin retirar nada de lo anterior y que solo mejorará capturas nuevas.

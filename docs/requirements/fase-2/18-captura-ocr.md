# Feature: Captura por foto de recibo (OCR) + comprobante adjunto

**Nivel:** 0 (gratis, ilimitado, sin anuncios) — ver "Frontera Nivel 0 / Nivel 1" en [`../README.md`](../README.md).
**Fase:** 2 (captura sin fricción local). 100% en el dispositivo, **sin backend y sin costo marginal**.
**Tablas Drift:** `Transactions` (existente) + **`TransactionAttachments`** (nueva, ver §Cambios de esquema).
**`TxSource`:** reusa el valor `ocr`, que **ya existe** en el enum (`lib/core/database/app_database.dart:46`) y que hoy nunca se produce en código.
**Diseño:** aún no diseñado en `billetudo.pen`. Antes de implementar, seguir el flujo de diseño de `CLAUDE.md` (Pencil primero, `design-system/billetudo/pages/captura-ocr.md` después de aprobar).

## Contexto

El registro manual de un gasto en billetudo cuesta hoy varios toques (monto, cuenta, categoría, fecha, nota). El abandono de las apps de finanzas personales no ocurre por falta de features, ocurre porque registrar cada café es trabajo. Fase 2 ataca exactamente eso: bajar el costo de capturar a segundos, sin pedir nada a cambio.

Esta feature cubre **dos cosas que comparten una misma foto y por eso viven en un solo documento**, pero que son necesidades distintas:

1. **Escanear para extraer** — le tomo foto al recibo y la app **pre-llena** el formulario de gasto (monto, fecha, comercio) para que yo solo confirme. Es la mitad de "captura sin fricción".
2. **Adjuntar como comprobante** — quiero que la foto del recibo **quede guardada junto a la transacción**, la haya usado o no para extraer datos. Es la mitad de "respaldo de la compra" (garantías, reembolsos corporativos, gastos deducibles, discutir un cobro).

Se documentan juntas porque comparten el archivo, el permiso, el almacenamiento, el modelo de datos y todo el problema de sincronización. Se separan en HU porque un usuario puede querer una sin la otra.

### Decisiones ya tomadas (no se re-litigan aquí)

- **Todo local, sin backend.** El OCR corre en el dispositivo con **ML Kit Text Recognition** y el parseo del texto usa **reglas locales** (expresiones regulares y heurísticas ancladas a etiquetas), **no un LLM**. El parseo con LLM llega en **Fase 4 como Nivel 1**, es una mejora de precisión que se suma encima y **nunca puede bloquear ni degradar la captura ya entregada** — si el usuario no paga, no ve anuncios o está offline, esta feature sigue funcionando idéntica.
- **Nivel 0 sin cupos.** No hay límite de escaneos ni de comprobantes por mes. El costo marginal es cero, así que un cupo no protegería nada y rompería la promesa de la capa gratuita (`CLAUDE.md`).
- **Modelo de confirmación (decisión 2026-08-17): la foto pre-llena el formulario de transacción existente y el usuario confirma ahí.** No hay registro automático, no hay bandeja de pendientes, no hay cola de revisión. El formulario que ya existe (`../fase-1/03-transacciones.md` HU-01) es la única pantalla de confirmación. Motivo: una bandeja de pendientes es una segunda inbox que el usuario tiene que atender, y su costo de mantenimiento supera el ahorro de la captura.
- **Retención cero del texto reconocido (decisión 2026-08-17, política de fase).** El texto crudo que devuelve el OCR **no se persiste**: se usa en memoria para extraer monto, fecha y comercio, y se descarta. No hay columna `ocrTextRaw`, no hay búsqueda por contenido del recibo, y no hay re-parseo posterior sobre texto guardado. Es la **política uniforme de toda la Fase 2** — el mismo criterio se aplicó al texto de las notificaciones bancarias (`19-notificaciones-bancarias.md`) y a la transcripción de voz (`17-captura-voz.md`): el contenido literal de lo que el usuario compra, recibe o dicta es el dato más sensible del flujo, y la app lo trata como material de trabajo, no como registro. Consecuencias asumidas en §Fases.
- **La fila de metadatos del comprobante SÍ sincroniza; el archivo NO (decisión 2026-08-17).** `TransactionAttachments` es una tabla sincronizable normal, con `_SyncColumns` como el resto del esquema. El binario nunca viaja. Esto tiene dos efectos deliberados: (a) el segundo dispositivo **sabe** que la transacción tiene un comprobante y **dónde** está, aunque no pueda abrirlo — un caso de UX real y obligatorio, ver HU-08; y (b) la costura para sincronizar la foto en **Premium (Nivel 2)** queda lista y será **aditiva**, sin migrar de local a sincronizable después.
- **Almacenamiento de la foto (decisión 2026-08-17): la foto vive SOLO EN LOCAL y se le dice al usuario explícitamente.** No se sube a ningún servidor, no viaja por PowerSync, y **se pierde si el usuario cambia de dispositivo o reinstala**. Ocultar esto sería la peor variante posible: el usuario descubre que perdió sus comprobantes justo cuando los necesita. **Sincronizar la foto a la nube queda reservado como feature Premium (Nivel 2) a futuro**; hoy no se construye nada de nube, solo se deja la costura en el modelo de datos (§La costura Premium).

## Historias de usuario

### HU-01 — Escanear un recibo para pre-llenar un gasto

Como usuario quiero tomarle foto a un recibo y que la app llene sola el monto, la fecha y el comercio, para registrar la compra en un toque en vez de escribir cuatro campos.

**Criterios de aceptación:**

- El flujo arranca desde una acción de captura visible (entrada exacta pendiente, ver §Pendientes P1): abre la cámara, el usuario toma la foto, y la app procesa **sin salir del flujo** — no hay "sube tu recibo y vuelve luego".
- El OCR corre **en el dispositivo**, offline. Sin conexión el flujo funciona idéntico; nunca se muestra "necesitas internet".
- El procesamiento tiene un **techo de tiempo** (objetivo: ≤ 3 s en gama media; **límite duro configurable, por defecto 8 s**). Si se excede, se aborta el OCR y se cae al camino de HU-03 con la foto ya adjunta. Nunca un spinner indefinido.
- Al terminar se abre el **formulario de transacción existente** (`../fase-1/03-transacciones.md` HU-01) con:
  - `type = expense` y `source = ocr`,
  - `amountMinor` pre-llenado con el total detectado (**centavos enteros**, nunca `double`; la conversión decimal → centavos usa aritmética decimal exacta, misma regla que `../fase-1/11-import-export.md` §Montos),
  - `date` pre-llenada con la fecha detectada, o **hoy** si no se detectó,
  - `note` pre-llenada con el nombre del comercio detectado (destino del comercio pendiente, ver §Pendientes P4),
  - `accountId` y `categoryId` **sin adivinar** (ver siguiente criterio),
  - la foto ya **adjunta** a ese borrador (HU-04 comparte el mismo mecanismo).
- **El OCR no elige cuenta ni categoría.** El recibo no contiene esa información: la cuenta la sabe el usuario y la categoría es una decisión suya. Se pre-cargan con el mismo default que el formulario manual (cuenta favorita/última usada; categoría vacía y obligatoria). Adivinar una categoría por el nombre del comercio es sugerencia de Fase 4 con LLM, no regla local.
- **`categoryId` sigue siendo obligatorio para un gasto.** El escaneo no relaja ninguna validación del formulario: si el usuario no elige categoría, no guarda. La captura reduce escritura, no reglas.
- **Nada se persiste hasta que el usuario toca Guardar.** Salir del formulario sin guardar no crea transacción (ver §Foto huérfana en Reglas de negocio para el destino del archivo).
- Guardar produce una transacción normal en todo salvo `source = ocr`, que se muestra legible como "OCR" en el detalle (`../fase-1/03-transacciones.md` HU-08).
- **Sin límite de escaneos** — ni por día, ni por mes, ni tras anuncio.

### HU-02 — Ver qué se extrajo y corregirlo antes de guardar

Como usuario quiero distinguir de un vistazo qué campos llenó la app y cuáles llené yo, para revisar lo que la máquina adivinó sin tener que releer todo el formulario.

**Criterios de aceptación:**

- Los campos pre-llenados por OCR se **marcan visualmente** como "leído del recibo" (tratamiento exacto pendiente, ver §Pendientes P5). La marca es informativa, no un bloqueo.
- **Todos los campos pre-llenados son editables** con la misma interacción que en el formulario manual. Tocar el monto abre el teclado numérico anclado de siempre (`../fase-1/03-transacciones.md` HU-01 §Teclado numérico anclado).
- Editar un campo pre-llenado **quita su marca de "leído del recibo"** en ese campo: pasa a ser un dato del usuario. Esto no cambia `source`, que sigue siendo `ocr` — el `source` describe **cómo entró** el movimiento, no cuánto sobrevivió del OCR.
- **Cuando el total es ambiguo, se ofrecen los candidatos en vez de elegir en silencio.** Si el recibo trae más de un valor plausible (total, total con propina, total factura — muy común en restaurantes colombianos, ver §Reglas de extracción), el campo monto ofrece los candidatos detectados con su etiqueta de origen ("Total a pagar", "Subtotal + propina") y el usuario toca el correcto. Elegir uno a ciegas cuando el recibo dice dos cosas distintas registra un dato incorrecto sin que el usuario se entere — el mismo riesgo que `../fase-1/09-pagos-programados.md` HU-03 resuelve con "confirmar nunca es a ciegas".
- La **foto sigue visible o accesible desde el formulario** mientras el usuario confirma (miniatura ampliable), para poder contrastar contra el recibo real sin cerrar el flujo ni volver a la galería.
- **Tono:** la marca dice qué se leyó, nunca cuánta confianza tiene el algoritmo. No se muestran porcentajes de confianza ni advertencias tipo "revisa, puede estar mal" — eso traslada al usuario la ansiedad de un problema técnico.

### HU-03 — Cuando el OCR falla o extrae mal

Como usuario quiero que un recibo ilegible no me haga perder ni la foto ni el tiempo, para poder seguir registrando el gasto igual.

**Criterios de aceptación:**

- **La foto nunca se pierde por un fallo de OCR.** Si el reconocimiento no devuelve texto, no encuentra un total, o excede el techo de tiempo, el flujo **abre igual el formulario de gasto** con la foto ya adjunta y los campos que sí se pudieron leer. El usuario completa el resto a mano y guarda: el comprobante queda igual.
- **`source` cuando no se extrajo nada:** si el OCR no aportó **ningún** campo, la transacción se guarda como `source = manual` (fue captura manual, con foto adjunta), no como `ocr`. `source = ocr` significa "el OCR aportó al menos un campo". Esto mantiene honesta cualquier medición futura de precisión de la captura.
- **Nunca se culpa al usuario ni al recibo** (regla de tono de `CLAUDE.md`). Prohibidos los fraseos "no se pudo leer tu foto", "foto de mala calidad", "intenta con mejor luz" como reproche. El mensaje describe el estado y ofrece la salida: la foto quedó guardada y el gasto se puede completar a mano. Se puede ofrecer **"Tomar otra foto"** como acción secundaria, nunca como única salida.
- **Un dato mal extraído se corrige, no se reporta.** No hay flujo de "reportar error de lectura" ni recolección de la foto para mejorar el modelo — sería recolección de datos personales sin justificación, contra `docs/legal/`.
- **Errores de captura y de cámara** (usuario cancela la cámara, la cámara no está disponible, la foto no se pudo escribir a disco) se manejan como estados propios con mensaje accionable, sin dejar borradores fantasma ni archivos a medias.
- **Sin espacio en disco:** la foto no se guarda, se explica con una acción concreta (liberar espacio, o guardar el gasto sin comprobante), y **el gasto se puede registrar igual sin foto**. Un problema de almacenamiento nunca puede bloquear registrar un movimiento.

### HU-04 — Adjuntar una foto como comprobante a una transacción

Como usuario quiero guardar la foto del recibo junto a una transacción, aunque los datos los haya escrito yo, para tener el comprobante a la mano si después lo necesito.

**Criterios de aceptación:**

- Se puede adjuntar una foto:
  - al **crear** una transacción (cualquier `type`: gasto, ingreso o transferencia — un comprobante de consignación es tan válido como el de una compra),
  - al **editar** una transacción ya existente (`../fase-1/03-transacciones.md` HU-04).
- El origen de la foto puede ser **cámara** o **galería** (alcance de galería pendiente, ver §Pendientes P8).
- Adjuntar en el flujo de edición **no dispara OCR** ni reescribe ningún campo ya guardado: adjuntar es adjuntar. (Si se ofrece "extraer datos de esta foto" sobre una transacción existente, es una acción explícita y separada — pendiente P1.)
- Adjuntar actualiza `updatedAt` de la transacción (regla de `CLAUDE.md`), porque el adjunto es parte de su estado observable.
- **Cuántos comprobantes admite una transacción:** ver §Pendientes P2. El modelo de datos propuesto (tabla aparte) soporta N desde el día uno; el límite lo impone la UI, no el esquema.
- El adjunto es **opcional siempre**. Ninguna transacción exige comprobante y ninguna pantalla presenta la falta de comprobante como algo incompleto o pendiente.

### HU-05 — Ver el comprobante desde el detalle de la transacción

Como usuario quiero abrir la foto del recibo desde el detalle de la transacción, para verificar la compra o mostrarla a alguien.

**Criterios de aceptación:**

- El detalle (`../fase-1/03-transacciones.md` HU-08) muestra una **miniatura** del comprobante cuando existe. Sin comprobante no se muestra nada — ni un placeholder, ni un "Agregar comprobante" en estado vacío permanente (agregarlo vive en editar).
- Tocar la miniatura abre el **visor a pantalla completa** con zoom (pinch) y desplazamiento. Un recibo térmico es texto pequeño: sin zoom el visor no sirve.
- Se puede **compartir** el comprobante por el share sheet del sistema (mandarlo por WhatsApp o correo es el caso de uso real de un comprobante).
- El listado de transacciones **puede** mostrar un indicador discreto de "tiene comprobante" — decisión de diseño, no requisito.
- **Accesibilidad:** la miniatura y el visor tienen etiqueta semántica descriptiva ("Comprobante de la transacción"), y el visor es cerrable con gesto y con botón (no solo swipe).
- **Texto solo desde `AppLocalizations`** (es + en), como todo lo demás.

### HU-06 — Quitar el comprobante y qué pasa al eliminar la transacción

Como usuario quiero poder quitar una foto que adjunté por error, y que borrar una transacción no me deje archivos basura ni me borre algo que todavía puedo recuperar.

**Criterios de aceptación:**

- **Quitar el comprobante a mano** (desde editar o desde el visor) es una acción explícita con confirmación, porque **es irreversible**: la foto no está en la nube y no hay papelera de archivos. La confirmación lo dice con esas palabras.
- **Eliminar la transacción es papelera reversible** (`deletedAt`, `../fase-1/03-transacciones.md` HU-05). Por lo tanto: **el archivo NO se borra mientras la transacción esté solo en la papelera.** Restaurar desde la papelera debe devolver la transacción **con su comprobante intacto**; borrar el archivo antes convertiría un "Deshacer" en una pérdida silenciosa.
  - La fila de `TransactionAttachments` recibe el mismo `deletedAt` que su transacción (borrado lógico en cascada lógica, no físico).
  - Restaurar limpia `deletedAt` en ambas.
- **El archivo se borra del disco solo cuando el borrado es definitivo**: al vaciar la papelera, al purgar por retención, o al borrar la cuenta del usuario. Ese es el único momento en que se toca el sistema de archivos.
- **`tombstonedAt` no aplica a los adjuntos.** Ninguna otra tabla referencia un `TransactionAttachments.id`, así que no hay integridad referencial que preservar: aquí solo existe papelera reversible (`deletedAt`). La distinción es la de `CLAUDE.md` y no se puede intercambiar.
- **El borrado de cuenta (requisito legal, `../fase-1/05-auth-sync.md` HU-07) debe borrar también los archivos locales**, no solo las filas. Un flujo de "borra mis datos" que deja las fotos de mis recibos en disco no cumple lo que promete.
- **Huérfanos:** debe existir una rutina de limpieza que borre archivos sin fila que los referencie (por un crash a mitad de escritura, por ejemplo) y filas cuyo archivo ya no exista (marcándolas como "archivo no disponible", ver HU-08). La limpieza corre en background y nunca borra un archivo cuya fila esté solo en papelera.

### HU-07 — Saber que la foto vive solo en este dispositivo

Como usuario quiero que la app me diga claramente que los comprobantes no se respaldan, para decidir con información si dependo de ellos o no.

**Criterios de aceptación:**

- **El aviso es explícito, no letra chica.** Se muestra al menos:
  1. **La primera vez** que el usuario adjunta un comprobante (una sola vez, con "Entendido"; no un diálogo recurrente que se vuelve invisible).
  2. De forma **permanente y consultable** en la pantalla de **Estado de sincronización** (`../fase-1/05-auth-sync.md` HU-08) y en el detalle del comprobante, como línea informativa.
- **Fraseo obligatorio en contenido, libre en forma:** debe decir las tres cosas — (a) la **foto** se guarda **solo en este dispositivo**, (b) **no se sincroniza** con la nube ni con otros dispositivos, (c) **se pierde si cambias de teléfono o reinstalas** salvo que guardes una copia (§Interacción con Import/Export). Omitir (c) es lo que produce la pérdida sorpresa.
- **Precisión obligatoria tras la decisión de sincronizar metadatos:** lo que **no** viaja es **el archivo**. El registro de que la transacción tiene un comprobante **sí** viaja (por eso el otro dispositivo lo sabe, HU-08). El aviso debe hablar de "la foto"/"la imagen", nunca de "el comprobante" a secas, o contradice lo que el usuario ve en su segundo dispositivo. Prohibido el fraseo "esto no sale de tu teléfono" sin calificar: es falso para el metadato.
- **Respeta la nomenclatura de `../fase-1/11-import-export.md` §Nomenclatura:** "respaldo" es la nube, "copia" es el archivo local. Este aviso **no** puede decir "haz un respaldo de tus fotos".
- **Tono neutro, sin alarma.** Es una característica del producto explicada, no una advertencia de riesgo. No usa iconografía de error ni color de peligro.
- El aviso **no bloquea** adjuntar ni pide confirmación adicional cada vez.
- Si la sincronización de fotos llega algún día como Premium (§La costura Premium), este aviso **cambia de contenido, no de lugar**: sigue siendo la misma línea, diciendo la verdad nueva. Y mientras no exista, **no se puede insinuar** ("próximamente en Premium") en un aviso cuya función es informar de una limitación — eso convierte una advertencia honesta en un anzuelo de venta.

### HU-08 — Ver en otro dispositivo una transacción con comprobante

Como usuario con la app en dos dispositivos quiero entender por qué en el segundo no veo la foto, para no pensar que la app perdió mis datos.

**Contexto del problema:** la fila de la transacción **y la fila de metadatos del comprobante** sincronizan por PowerSync; el archivo **no** (decisión 2026-08-17). En el dispositivo B existe la transacción, existe el registro de que tiene comprobante, y el archivo no está. **Esto no es hipotético: es la consecuencia directa y garantizada de la decisión**, así que este estado es de construcción obligatoria en Fase 2, no un caso de borde. Si no se resuelve, el resultado es una miniatura rota o —peor— la sensación de que el respaldo en la nube perdió información, que es exactamente el miedo que `../fase-1/11-import-export.md` §Contexto intenta desactivar.

**Criterios de aceptación:**

- En el dispositivo B la transacción muestra un **estado explícito de "comprobante no disponible en este dispositivo"** en lugar de la miniatura, con la explicación de una línea (la foto se guardó en el dispositivo donde se tomó y no se sincroniza) y **el nombre del dispositivo de origen** cuando está disponible (`deviceLabel`: "Guardado en *Pixel de Cami*") — un dato concreto vale más que una disculpa genérica.
- Ese estado **no es un error**: sin icono de error, sin color de peligro, sin botón de reintento, sin barra de progreso. No hay nada que reintentar y fingir que sí lo hay es peor que no mostrar nada.
- Desde ahí se ofrece la única ruta real de recuperación que existe hoy: abrir el comprobante en el dispositivo donde está.
- **No se insinúa Premium desde este estado.** Es el lugar más tentador para poner un anzuelo ("sincroniza tus comprobantes con Premium") y por eso mismo está prohibido mientras la feature no exista: convierte una explicación honesta en publicidad de una carencia — misma regla que HU-07.
- **Quitar el comprobante en el dispositivo A limpia el estado en B.** El borrado del metadato sí sincroniza, así que B no puede quedar afirmando que existe un comprobante que ya no existe.
- **Simetría:** si el usuario abre en A una transacción cuyo comprobante se capturó en B, ve exactamente el mismo estado con el nombre de B. Ningún dispositivo es "el principal".
- **Nunca se muestra una miniatura rota, un cuadro gris sin explicación, ni un spinner infinito** intentando cargar un archivo que no existe.
- La ausencia del archivo **no afecta nada más** de la transacción: monto, categoría y saldos son idénticos en ambos dispositivos.

### HU-09 — Permisos de cámara y galería

Como usuario quiero que la app me pida la cámara solo cuando la voy a usar y que negar el permiso no me deje sin registrar el gasto.

**Criterios de aceptación:**

- **El permiso se pide en contexto, nunca al abrir la app ni en el onboarding.** Se solicita en el momento exacto en que el usuario tocó "tomar foto", que es cuando la petición se explica sola.
- **Pre-prompt antes del diálogo del sistema** cuando aporte: una pantalla propia que explique para qué se usa (leer el recibo y guardarlo como comprobante) **y** que la foto no sale del dispositivo. El diálogo del sistema solo se puede mostrar una vez de forma útil; quemarlo sin contexto es perder el permiso para siempre.
- **Permiso denegado (una vez):** la app lo acepta sin insistir, explica qué se pierde y **ofrece la salida completa**: registrar el gasto a mano, o elegir una foto de la galería si ese camino está disponible. Nunca un callejón sin salida.
- **Permiso denegado permanentemente:** la app detecta el estado y ofrece **abrir los ajustes del sistema** con una explicación de un renglón. No se vuelve a lanzar el diálogo nativo (no haría nada) ni se repite la petición en cada intento.
- **La app nunca queda inutilizable por un permiso denegado.** Todas las features de Nivel 0 (registro manual incluido) siguen funcionando igual.
- **Declaraciones nativas requeridas** (hoy **ausentes**, verificado):
  - `android/app/src/main/AndroidManifest.xml` no declara **ningún** `uses-permission`: falta `android.permission.CAMERA`.
  - `ios/Runner/Info.plist` no tiene **ninguna** clave `*UsageDescription`: faltan `NSCameraUsageDescription` y, si se habilita galería, `NSPhotoLibraryUsageDescription`. Los textos van **en español y en inglés** (localizados en `InfoPlist.strings`), y deben decir el uso real, no una plantilla — Apple rechaza descripciones genéricas.
- **Preferir los selectores del sistema que no exigen permiso.** En Android, el **Photo Picker** del sistema permite elegir una imagen **sin** declarar `READ_MEDIA_IMAGES`, lo que además evita el formulario de declaración de permisos de fotos y video de Google Play. Se declara un permiso solo si el flujo elegido realmente lo requiere; verificar el comportamiento del plugin escogido antes de agregar líneas al manifiesto.
- **Dependencias hoy ausentes en `pubspec.yaml`** y que esta feature obliga a agregar: `google_mlkit_text_recognition` (hoy **comentada a propósito** en `pubspec.yaml:84-87`, con la razón escrita: "enlazan frameworks nativos y arrastran declaraciones de privacidad (micrófono, cámara) que todavía no hay qué justificar"), más un plugin de captura/selección de imagen y, si hace falta, uno de permisos. **La razón por la que estaban comentadas deja de aplicar exactamente aquí**: esta feature es la justificación que faltaba. Descomentar es parte del trabajo, y arrastra §Declaraciones de tienda.

### HU-10 — Espacio en disco y gestión del almacenamiento

Como usuario quiero que las fotos de recibos no me llenen el teléfono y poder ver cuánto ocupan.

**Criterios de aceptación:**

- **La foto se comprime antes de guardarse.** El original de una cámara moderna pesa entre 2 y 5 MB; un recibo legible no necesita eso. Objetivo: **≤ 500 KB por comprobante** con el texto todavía legible al hacer zoom. Parámetros exactos (lado mayor, calidad JPEG, escala de grises) se calibran contra recibos reales, no se fijan a ciegas en este documento. El texto debe seguir siendo legible **para un humano** después de comprimir — el OCR ya corrió antes, pero el comprobante es para leerlo.
- **La foto original a resolución completa no se conserva** (salvo que P6 decida otra cosa).
- **Ajustes muestra cuánto ocupan los comprobantes** (total en MB y cantidad), en la sección de datos/almacenamiento, con acceso a una vista donde se pueden **revisar y borrar** comprobantes antiguos. Un número sin acción es solo ansiedad.
- **Ningún borrado automático por antigüedad sin consentimiento explícito.** La app no puede decidir sola que un comprobante de hace 2 años ya no importa (justo los de garantía y deducibles son los viejos). Si se ofrece purga automática, es **opt-in** y con periodo elegido por el usuario.
- El almacenamiento vive en el **directorio privado de la app**, que en ambas plataformas se libera al desinstalar. Las fotos tomadas por la app **no se agregan al carrete/galería del usuario** (ensuciar el carrete con recibos es un efecto secundario indeseado) — salvo que P6 decida lo contrario.
- **Presupuesto de tamaño de la app:** ML Kit Text Recognition suma peso al binario (el modelo empaquetado en iOS; en Android existe además la variante servida por Google Play Services que reduce el APK a cambio de una descarga inicial). Elegir variante es parte de la implementación; medir el delta de tamaño antes y después es obligatorio.

### HU-11 — Estados, errores y accesibilidad

Como usuario quiero que la pantalla me diga qué está pasando en cada paso, en vez de dejarme mirando un spinner.

**Criterios de aceptación:**

- **Procesando:** indicador con techo de tiempo (HU-01), cancelable. Cancelar conserva la foto y abre el formulario vacío, no descarta el trabajo.
- **Sin texto detectado / sin total detectado:** estados distintos con mensajes distintos, ambos con la foto ya adjunta (HU-03).
- **Permiso denegado, cámara no disponible, sin espacio:** cubiertos en HU-09 y HU-03, cada uno con una acción concreta.
- **Archivo faltante** (borrado por fuera de la app, restauración parcial, otro dispositivo): estado "comprobante no disponible", nunca una imagen rota (HU-08).
- **Offline:** todo el flujo funciona sin conexión, sin excepción y sin avisos. Es local por definición.
- **Accesibilidad:** el flujo completo es operable con lector de pantalla; el resultado del OCR se anuncia como texto ("Monto detectado: 45.900 pesos"), no solo visualmente. El botón de disparo cumple el objetivo táctil mínimo (48 dp).
- **Tono positivo y de progreso en todos los estados, errores incluidos** (`CLAUDE.md`). Un recibo arrugado no es una falla del usuario.

## Reglas de extracción con reglas locales (formato de recibo colombiano)

Esta sección define **qué** se intenta extraer y con qué criterio. La implementación exacta de las expresiones se calibra contra recibos reales; lo que no es negociable son las reglas de desempate.

### Qué se extrae

| Campo | Destino | Obligatorio para considerar el escaneo útil |
|---|---|---|
| **Total** | `amountMinor` (centavos) | Sí — sin total, el escaneo no aporta el dato principal |
| **Fecha** | `date` | No — si falta, se usa hoy |
| **Comercio** | `note` (destino pendiente, P4) | No |

Nada más. Ítems línea por línea, NIT, CUFE, número de factura y método de pago **quedan fuera de alcance**: no tienen dónde guardarse en el modelo actual y su extracción con reglas locales es notoriamente frágil.

### El total es el problema difícil, no la lectura del texto

ML Kit devuelve texto con buena fidelidad; lo que falla es **decidir cuál de los números es el total**. Un recibo colombiano típico de restaurante trae, en este orden:

```
SUBTOTAL              38.000
IMPOCONSUMO 8%         3.040
PROPINA VOLUNTARIA     3.800
TOTAL A PAGAR         44.840
```

y uno de supermercado o retail:

```
SUBTOTAL             105.000
IVA 19%               19.950
TOTAL                124.950
CAMBIO                  .050
EFECTIVO             125.000
```

Reglas de desempate, en este orden:

1. **Anclaje por etiqueta, no por posición ni por magnitud.** Se busca el valor asociado a una etiqueta de total, con prioridad: `TOTAL A PAGAR` > `TOTAL FACTURA` / `VALOR TOTAL` / `TOTAL VENTA` > `TOTAL` > `VALOR COMPRA` (recibos de datáfono). Se aceptan variantes con y sin tildes y en mayúsculas/minúsculas mezcladas.
2. **Nunca tomar el número más grande.** `EFECTIVO 125.000` es mayor que el total y es lo que el cliente entregó, no lo que gastó. Los valores etiquetados como `EFECTIVO`, `RECIBIDO`, `CAMBIO`, `DEVUELTA`, `SU PAGO` se **excluyen explícitamente** como candidatos.
3. **`SUBTOTAL` no es `TOTAL`.** La coincidencia de la etiqueta `TOTAL` debe rechazar `SUBTOTAL` (el sufijo coincide). Es el error de regex más común en este dominio y produce un gasto sistemáticamente subestimado.
4. **`IVA` e `IMPOCONSUMO` nunca son el total**, aunque a veces aparezcan en la última línea legible de un recibo cortado.
5. **La propina es la ambigüedad legítima.** En Colombia la propina es voluntaria y frecuentemente el recibo muestra el total con y sin ella. Cuando se detecten ambos, **no se elige**: se ofrecen los dos candidatos al usuario (HU-02). Elegir por él es decidir sobre su dinero.
6. **Fallback sin etiquetas:** si ninguna etiqueta ancla, se puede proponer el mayor valor monetario **de la mitad inferior** del recibo, **marcado como incierto** y presentado como candidato en HU-02 — nunca aplicado en silencio.

### Formato numérico colombiano

- Separador de miles **punto**, decimal **coma**: `44.840`, `1.234.567,89`. Un parser con convención inglesa lee `44.840` como cuarenta y cuatro pesos con ochenta y cuatro centavos: **error de 1000×**. Es el fallo más caro posible en esta feature.
- Frecuente **sin decimales** (el peso colombiano se maneja de hecho en unidades enteras): `44.840` = 4.484.000 centavos.
- Símbolo `$` opcional, pegado o separado, a veces con `COP`.
- Espacios espurios del OCR entre dígitos (`44. 840`) deben tolerarse.
- **La conversión a centavos usa aritmética decimal exacta, nunca `double`** (misma regla que `../fase-1/11-import-export.md` §Montos: `19.99 * 100` en punto flotante da `1998.9999…`).
- **Sanidad:** un total fuera de un rango razonable (p. ej. > 100.000.000 COP o = 0) no se aplica en silencio; se trata como no detectado y cae a HU-03.
- **Moneda:** el escaneo **no detecta moneda**. Se asume la moneda de la cuenta seleccionada, igual que el formulario manual (`../fase-1/03-transacciones.md` HU-01). Un recibo en otra moneda es un caso de `../fase-1/12-multi-moneda.md`, no de OCR.

### Fecha

- Formatos frecuentes: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD/MM/YY`, y `YYYY-MM-DD` en facturas electrónicas. A veces con hora (`15/08/2026 14:32`), que se descarta: el modelo guarda fecha local sin hora.
- **En Colombia el orden es día-mes.** Ante ambigüedad (`03/04`), se asume `DD/MM`; es la convención local y equivocarse al revés desplaza el gasto de mes y descuadra presupuestos.
- **Cordura obligatoria:** una fecha futura o de hace más de N años (p. ej. 2) se descarta y se usa hoy. Es preferible una fecha por defecto correcta a una fecha leída de un número de teléfono.
- Si no hay fecha detectable, **hoy**, sin avisar como error.

### Comercio

- Heurística: primeras líneas del recibo, descartando las que sean solo números, NIT, direcciones, teléfonos o `FACTURA ELECTRONICA DE VENTA`.
- Se normaliza a capitalización legible (`EXITO CALLE 80` → `Éxito Calle 80` es **fuera de alcance**: no se corrigen tildes ni se adivinan nombres de marca; a lo sumo se pasa de MAYÚSCULAS a Capitalización).
- **Es el campo más frágil de los tres** y el de menor costo si falla: si no convence, se deja vacío. Un comercio mal leído en la nota es ruido; un total mal leído es un dato financiero falso.

## Reglas de negocio y edge cases

- **Nivel 0 intacto.** Ni el escaneo, ni el adjunto, ni el visor, ni la cantidad de comprobantes pueden quedar detrás de anuncio, pago o cupo. Sin banners ni interstitials en ninguna de sus pantallas (`CLAUDE.md`).
- **El OCR nunca escribe en la base de datos por su cuenta.** Solo pre-llena un formulario. No existe ningún camino en el que una foto produzca una transacción sin que el usuario toque Guardar.
- **Foto huérfana (borrador abandonado):** si el usuario escanea y luego abandona el formulario sin guardar, no hay transacción a la cual colgar el archivo. El archivo temporal se descarta al abandonar; **no** se guarda "por si acaso" (guardar fotos que el usuario no asoció a nada es acumular datos personales sin propósito). La app pregunta antes de descartar solo si hubo edición manual, con el mismo patrón de descarte de borrador que ya usa el formulario.
- **Un comprobante nunca modifica montos, saldos ni reportes.** Es un archivo colgado de la transacción; no participa de ningún cálculo. `../fase-1/10-graficas-informes.md` §Reglas de conteo no cambia en absoluto por esta feature.
- **`source = ocr` no cambia ninguna regla de conteo** — se comporta idéntico a `manual` en presupuestos, gráficas y saldos. Solo sirve para mostrar el origen (`../fase-1/03-transacciones.md` HU-08) y para medir el uso de la captura.
- **Gate de cuenta:** escanear un recibo sin cuentas activas cae bajo `../fase-1/15-gate-cuenta.md` — puente, no muro: se ofrece crear la cuenta y **continuar al formulario con la foto y los datos ya extraídos**, sin perder el escaneo. Prohibido un botón de cámara en gris.
- **La foto no se envía a ningún servidor, nunca.** Ni para OCR (es local), ni para telemetría, ni para diagnóstico. Lo único que llega a la nube es la **fila de metadatos** (decisión 2026-08-17), que no contiene ni la imagen ni el texto del recibo. Cualquier reporte de crash debe excluir rutas y contenidos de comprobantes (ver `lib/core/crash/sentry_redaction.dart`).
- **El texto reconocido no se persiste** (retención cero, política de Fase 2): vive en memoria durante el parseo y se descarta al abrir el formulario. Tampoco puede acabar en un log, en un crash report ni en el estado serializado de un bloc.
- **Rutas absolutas prohibidas en la base de datos.** En iOS el contenedor de la app cambia de UUID en cada actualización y restauración: una ruta absoluta guardada hoy apunta a la nada mañana. Se guarda **solo el nombre de archivo relativo** al directorio de comprobantes, y la ruta completa se resuelve en tiempo de ejecución.
- **Escanear no es una tercera vía de "registro automático".** No hay bandeja de pendientes, no hay confirmación diferida, no hay lote. Cada foto termina en un formulario o en nada.
- **Multi-moneda / cuentas archivadas / transferencias** no introducen reglas nuevas: el adjunto es ortogonal a todas.

## Almacenamiento local de la foto

- **Ubicación:** subdirectorio dedicado dentro del **directorio privado de documentos de la app** (el que persiste entre actualizaciones y se elimina al desinstalar). Nunca en almacenamiento compartido ni en el carrete.
- **Nombre de archivo:** derivado del `id` (UUID) de la fila de `TransactionAttachments` más la extensión. Así el nombre no filtra información (ni comercio, ni monto, ni fecha) si el archivo se ve desde un explorador o un respaldo del sistema operativo.
- **Referencia desde la transacción:** una fila en `TransactionAttachments` con `transactionId`. La transacción **no** guarda la ruta (ver §Cambios de esquema para el porqué).
- **Escritura:** primero el archivo, después la fila; si la fila falla, el archivo se borra. La rutina de limpieza de HU-06 cubre el resto de casos.
- **Exclusión de respaldos del sistema:** ver §Pendientes P7 — hay una decisión real sobre si el directorio se marca como excluido de iCloud/Android Auto Backup.
- **Cifrado en reposo:** por defecto, la protección de datos del sistema operativo (el archivo vive en el sandbox de la app). Cifrar el archivo con la clave del dispositivo, como se hace con `accountNumberEnc` (`../fase-1/01-cuentas.md` HU-03), es posible pero encarece el visor y el share. Se documenta como opción, no se decide aquí (P7 lo toca de lado).

## Interacción con Import/Export

Referencia: [`../fase-1/11-import-export.md`](../fase-1/11-import-export.md).

- **Export CSV: la foto NO entra, y esto no está en discusión.** El CSV es un formato de texto plano y legible; un adjunto binario no cabe ahí. **Sí se puede** agregar una columna informativa (`comprobante`: `sí`/`no`) para que el usuario sepa qué filas tenían uno — pendiente menor de diseño del formato, no bloqueante, y afecta el orden de columnas de HU-01 de ese documento.
- **Copia completa (`.billetudo.json`): es una decisión real con trade-off, ver §Pendientes P9.** Hoy la copia completa se define como "la app sabe restaurarla **sin pérdida**" (HU-03 de ese doc). Si las fotos quedan fuera, esa promesa deja de ser literal y **hay que decirlo en la propia pantalla de copia**, igual que ya se advierte que `accountNumberEnc` no se incluye.
- **Import:** un CSV externo nunca trae adjuntos; nada que hacer. La regla ya escrita en ese documento —*"lo que esas apps exportan y este modelo no representa (adjuntos, cuentas compartidas…) simplemente no se importa"*— **queda desactualizada** el día que se implemente esta feature y debe revisarse.
- **Deshacer una importación** (HU-08 de ese doc) no interactúa con comprobantes: las transacciones importadas nunca los tienen.

## Interacción con PowerSync y la costura Premium

### Qué sincroniza y qué no

- **La transacción sincroniza normalmente.** Nada cambia en `Transactions`.
- **El archivo no sincroniza jamás.** PowerSync sincroniza filas de SQLite, no binarios; y aunque pudiera, subir fotos implicaría Supabase Storage, costo por GB y una política de retención — todo lo que Fase 2 evita por definición.
- **La fila de metadatos SÍ sincroniza (decisión 2026-08-17).** `TransactionAttachments` es una tabla sincronizable normal, con `_SyncColumns`, igual que el resto del esquema. Se aceptan de forma consciente sus dos consecuencias: (a) el estado obligatorio de HU-08 en el segundo dispositivo, y (b) que el registro de *qué transacciones tienen comprobante* viaja a la nube aunque la imagen no — es metadato, no contenido, pero hay que decirlo en la política de privacidad con esa precisión.
- **`ocrTextRaw` no existe** (decisión 2026-08-17, retención cero): nada del contenido literal del recibo llega a Postgres, ni siquiera como texto.
- **Paridad de esquema obligatoria:** la tabla sincroniza, así que debe declararse **dos veces** (Drift y el `Schema` de PowerSync) y existir en Postgres, con su regla de sync — `../fase-1/05-auth-sync.md` decisión #6, y el recordatorio de `MEMORY.md`: subir `schemaVersion` **no** migra Postgres; sin `ALTER TABLE`/`CREATE TABLE` explícito en dev **y** prod, el sync queda *quarantined* con `PGRST204`.
- **`delete_account_data` debe incluir la tabla nueva**, con los hijos antes que los padres (`../fase-1/05-auth-sync.md` decisión #11). Es un requisito legal, no una mejora.

### La costura Premium (Nivel 2, a futuro)

Hoy **no se construye nada de nube**. Lo que sí se hace es dejar el modelo listo para que sincronizar comprobantes sea **aditivo**, no un retrofit. La decisión de sincronizar los metadatos (2026-08-17) es la pieza central de esa costura: el día que exista Premium, la tabla ya está en PowerSync y en Postgres con sus filas históricas, y lo único que se agrega es **dónde está el binario** (una columna de URL remota y su estado de subida) más el transporte. No hay que convertir una tabla local en sincronizable ni reconciliar filas que solo existían en un dispositivo. Requisitos mínimos que la implementación de Fase 2 debe cumplir para que eso siga siendo cierto:

1. **Tabla propia** (`TransactionAttachments`), no una columna en `Transactions`. Una columna obligaría después a migrar datos y a mezclar el ciclo de vida del binario con el de la transacción.
2. **Separar la identidad del archivo de su ubicación.** El `id` (UUID) de la fila es estable y global; `localFileName` es una ubicación de este dispositivo. El día que exista una URL remota, se agrega una columna y la identidad no cambia.
3. **`deviceId`** (o equivalente) registrado desde el día uno: sin él, el dispositivo B no puede decir *dónde* está la foto (HU-08) y una migración futura no sabría quién debe subir cada archivo.
4. **`checksum`** del contenido: es lo que hará idempotente una subida futura y lo que permite detectar un archivo corrupto o cambiado hoy mismo.
5. **`byteSize` y `mimeType`** persistidos, para poder estimar una subida futura sin abrir cada archivo, y para la vista de almacenamiento de HU-10 hoy.
6. **Nada en la lógica de Fase 2 puede asumir que el archivo siempre está presente.** Si el código asume presencia, agregar el caso "está en la nube pero no descargado" será un refactor. El estado "comprobante no disponible" de HU-08 es la misma máquina de estados que servirá para "descargando".
7. **Ninguna columna de esta tabla puede llamarse ni comportarse como si fuera de nube hoy** (nada de `syncState` sin uso). La costura son los datos, no columnas fantasma.

## Permisos y declaraciones de tienda

Esta feature **cambia lo que la app declara ante Apple y Google**, y esos documentos hoy dicen lo contrario:

- `docs/legal/declaraciones-tiendas.md:165` y `docs/legal/AUDITORIA.md:649` **declaran hoy que la app no tiene OCR**. Ambos deben actualizarse **antes** de publicar una versión con esta feature. Declarar de menos ante las tiendas es motivo de rechazo o retiro.
- **Google Play — Data Safety:** las fotos **no salen del dispositivo**, así que no hay recolección ni compartición que declarar bajo "Photos and videos". Sí hay que revisar el formulario de **permisos de fotos y video** si el flujo termina requiriendo `READ_MEDIA_IMAGES` (evitable con el Photo Picker, HU-09).
- **Apple — App Privacy:** mismo criterio (no se recolectan datos), más las `*UsageDescription` obligatorias y localizadas de HU-09. Sin ellas la app **crashea** al abrir la cámara en iOS, no solo se rechaza.
- **Política de privacidad:** debe mencionar explícitamente que la app puede acceder a la cámara y a las fotos, con qué fin, y que las imágenes **se procesan y almacenan localmente y no se transmiten**. Es una afirmación fuerte y verificable: hay que asegurarse de que ningún reporte de crash o log la contradiga.
- Este bloque debe pasar por el subagente **`privacy-legal-officer`** antes del release, no después.

## Cambios de esquema requeridos (Drift)

Ejecutar vía **`/drift-schema-change`**: subir `schemaVersion` al **siguiente número libre** (ver el aviso de abajo), escribir la migración `onUpgrade`, regenerar con `dart run build_runner build --force-jit`, y **mantener paridad en el `Schema` de PowerSync y en Postgres** (dev **y** prod), porque la tabla **sí sincroniza**. Incluir la tabla nueva en `delete_account_data`.

> **Orden de migraciones — dependencia dura.** El primer número libre **le pertenece a `19-notificaciones-bancarias.md`** (tabla `PendingCaptures`), que se construye antes que esta feature. Esta feature toma **el siguiente** y **depende de que esa migración ya exista** en el repo. Si el orden de construcción cambiara, hay que renumerar aquí antes de escribir una sola línea de migración: dos features reclamando la misma versión producen una base local que se cree migrada y no lo está, y ese fallo es silencioso.
>
> **Verifica el número vigente antes de escribir la migración, no lo copies de aquí.** Al 2026-08-17 el working tree está en **`schemaVersion` 28** (`HEAD` en 26, con 27 y 28 ya consumidos por trabajo sin commitear: `AppSettings.quickAccessOrder` y `ScheduledPayments.goalId`). Con ese estado, notificaciones bancarias tomaría **28 → 29** y esta feature **29 → 30**. El esquema se mueve rápido y este documento envejece — lee el `schemaVersion` real en el momento de implementar.

### Tabla nueva `TransactionAttachments` (con el mixin `_SyncColumns`)

| Columna | Tipo | Notas |
|---|---|---|
| `transactionId` | `text().references(Transactions, #id)` | NOT NULL. Dueño del adjunto. |
| `localFileName` | `text()` | **Nombre relativo**, nunca ruta absoluta (ver §Almacenamiento local). |
| `mimeType` | `text()` | `image/jpeg` en la práctica; explícito para el visor y el share. |
| `byteSize` | `integer()` | Tamaño en bytes, para la vista de almacenamiento (HU-10) y la costura Premium. |
| `checksum` | `text()` | Hash del contenido: detecta corrupción hoy, hace idempotente la subida mañana. |
| `deviceId` | `text()` | Dispositivo donde vive el archivo. Sin esto, HU-08 no puede decir dónde está. |
| `deviceLabel` | `text().nullable()` | Nombre legible del dispositivo para el mensaje de HU-08 ("Guardado en *Pixel de Cami*"). |
| `capturedAt` | `dateTime()` | Momento de la captura (distinto de `createdAt` por claridad de intención, igual que `importedAt` en `ImportBatches`). |

Más las columnas del mixin `_SyncColumns` (`id` UUID, `createdAt`, `updatedAt`, `deletedAt`, `tombstonedAt`), porque la tabla sincroniza como cualquier otra.

**No hay columna de texto reconocido.** `ocrTextRaw` se evaluó y **se descartó** (decisión 2026-08-17, retención cero — ver §Decisiones ya tomadas). El texto del recibo se usa en memoria y se descarta; ninguna columna de esta tabla ni de ninguna otra guarda el contenido literal de lo que el usuario compró.

- **`deletedAt`** se usa (papelera reversible, en espejo con la transacción — HU-06).
- **`tombstonedAt`** **no** se usa: ninguna tabla referencia un adjunto, así que no hay integridad referencial que preservar. La distinción es la de `CLAUDE.md` y no son intercambiables.
- Índice por `transactionId` (la consulta real es siempre "los adjuntos de esta transacción").

### Por qué tabla aparte y no una columna en `Transactions`

Se evaluó agregar `attachmentPath` (o un par de columnas) directamente a `Transactions`. Se descarta:

1. **Ciclo de vida distinto.** Ambas filas sincronizan, pero la del adjunto carga datos que solo tienen sentido **en un dispositivo concreto** (`localFileName`, `deviceId`) y que van a cambiar cuando llegue Premium. Meterlos en `Transactions` sería contaminar la tabla más caliente y más sincronizada de la app con el ciclo de vida de un binario que no viaja.
2. **Metadatos que no caben en una columna.** `checksum`, `deviceId`, `byteSize`, `mimeType`, `capturedAt` son cinco columnas nuevas en la tabla más caliente de la app, nulas en el 99% de las filas.
3. **N adjuntos.** Una columna fija el límite en 1 para siempre; la tabla lo deja como decisión de UI (P2). Un usuario que fotografía un recibo de dos páginas es un caso normal.
4. **La costura Premium.** Agregar `remoteUrl`/`uploadedAt` a una tabla dedicada es aditivo; hacerlo sobre `Transactions` sería un retrofit sobre la tabla que más filas tiene y más sincroniza.
5. **Precedente del repo:** `../fase-1/11-import-export.md` resolvió el mismo dilema igual (tabla `ImportBatches` + FK, en vez de inferir por columnas existentes).

**Contra-argumento honesto:** una tabla más significa una entidad más en PowerSync, en `delete_account_data`, en la copia completa y en el borrado de cuenta. Es costo real, y se acepta a cambio de los cinco puntos de arriba.

## Resueltos (no re-litigar)

- **P3 — ¿La fila de `TransactionAttachments` sincroniza por PowerSync? → SÍ (decisión 2026-08-17).** Se eligió la opción A: sincronizan los **metadatos**, nunca el archivo. Se aceptó a sabiendas su costo (mostrarle al usuario en el segundo dispositivo un comprobante que no puede abrir, HU-08) a cambio de dos cosas: que el usuario **sepa** que el comprobante existe y dónde está, y que la sincronización de la foto en Premium (Nivel 2) sea **aditiva** en vez de una migración de tabla local a sincronizable. La opción B (tabla local) queda descartada.
- **P10 — ¿Se guarda el texto crudo del OCR? → NO (decisión 2026-08-17).** Retención cero, y **política uniforme de toda la Fase 2**: aplica igual a la transcripción de voz (`17-captura-voz.md`) y al texto de las notificaciones bancarias (`19-notificaciones-bancarias.md`). Se eligió la opción A asumiendo explícitamente que se pierden la búsqueda por contenido del recibo y el re-parseo barato (ver §Fases para la consecuencia sobre Fase 4). La razón: el contenido literal de las compras es el dato más sensible que toca esta feature, y no guardarlo es la única garantía que no depende de que nadie lo proteja bien después.

## Pendiente de decidir

Consolidado. Ninguno de estos puntos debe resolverse en implementación sin el dueño del producto. La numeración conserva los huecos de P3 y P10 a propósito, para que las referencias cruzadas no cambien de significado.

- **P1 — ¿Escanear y adjuntar son una acción o dos?**
  Opción A: **una sola acción "foto"** que siempre intenta extraer y siempre adjunta. Menos decisiones para el usuario; a cambio, quien solo quiere guardar el comprobante recibe campos pre-llenados que no pidió (y que sí puede ignorar).
  Opción B: **dos acciones separadas** ("Escanear recibo" desde la captura rápida; "Adjuntar comprobante" desde el formulario/edición). Más claro conceptualmente y más honesto en edición; a cambio, dos entradas que explicar y el riesgo de que el usuario elija la que no era.
  Opción C: **una acción con extracción implícita y salida a mano** — se adjunta siempre, y el pre-llenado se ofrece como una tarjeta que el usuario aplica o descarta.
  *Afecta:* HU-01, HU-04, y la entrada de la feature en el shell de navegación.

- **P2 — ¿Cuántos comprobantes por transacción?**
  Opción A: **uno**. UI trivial (miniatura única), cubre el 90% de los casos, y el esquema ya permite ampliar después sin migrar datos.
  Opción B: **varios**. Cubre recibos de dos páginas y factura + comprobante de pago; a cambio, exige carrusel, orden, y borrado individual desde el día uno.
  *Afecta:* HU-04, HU-05, diseño en Pencil.

- **P4 — ¿Dónde va el nombre del comercio?**
  Opción A: en `note` (existe hoy, cero cambios). A cambio, pisa o compite con la nota que el usuario quería escribir.
  Opción B: **columna nueva `merchant`** en `Transactions`. Dato limpio, aprovechable después en reportes ("dónde gasto más") y en el parseo con LLM de Fase 4. A cambio, otra columna en la tabla más caliente y otro cambio de esquema.
  Opción C: no se guarda el comercio en absoluto en Fase 2.
  *Afecta:* HU-01, §Reglas de extracción, y potencialmente `../fase-1/10-graficas-informes.md`.

- **P5 — ¿Cómo se marca un campo "leído del recibo"?**
  Opción A: marca visual persistente en el campo hasta que el usuario lo edite. Opción B: un resumen arriba del formulario ("Leído del recibo: monto, fecha") sin tocar los campos. Opción C: nada — se pre-llena y ya, confiando en que el usuario revise.
  *Afecta:* HU-02 y el diseño del formulario existente, que hoy no tiene ningún estado de este tipo.

- **P6 — ¿Se conserva el original y/o se guarda la foto en el carrete?**
  Opción A: solo la versión comprimida, fuera del carrete (propuesta del documento). Mínimo espacio, carrete limpio; a cambio, calidad irrecuperable si la compresión resultó agresiva.
  Opción B: comprimida en la app **y** original en el carrete del usuario. El usuario conserva el original con sus propias herramientas de respaldo (Google Fotos / iCloud), lo que **mitiga de verdad la pérdida al cambiar de dispositivo**; a cambio, ensucia el carrete y expone la foto fuera del sandbox de la app.
  Opción C: opción del usuario en Ajustes.
  *Afecta:* HU-10, HU-07 (el aviso cambia si el original está en el carrete) y la política de privacidad.

- **P7 — ¿El directorio de comprobantes se excluye de los respaldos del sistema (iCloud / Android Auto Backup)?**
  Opción A: **incluido**. Un usuario con iCloud recupera sus comprobantes al restaurar el teléfono — resuelve buena parte del dolor de HU-07 sin construir nada. A cambio: los datos financieros del usuario viajan a un respaldo de terceros que la app no controla, y hay que decirlo en la política de privacidad; además Apple penaliza respaldar datos regenerables.
  Opción B: **excluido**. Control total y coherente con "todo local"; a cambio, la pérdida al cambiar de dispositivo es real y total.
  *Nota:* `../fase-1/11-import-export.md` §Recomendar la copia documenta que **Android Auto Backup nunca había respaldado esta app** (verificado con `dumpsys backup`), así que en Android la opción A puede ser teórica.
  *Afecta:* HU-07, HU-10 y las declaraciones de privacidad.

- **P8 — ¿La galería entra en el alcance de Fase 2 o solo cámara?**
  Opción A: **solo cámara**. Menos permisos, menos declaraciones de tienda, alcance más pequeño. A cambio, no se puede adjuntar un recibo que llegó por correo o WhatsApp — un caso muy real.
  Opción B: **cámara + galería** (vía el Photo Picker del sistema, que evita `READ_MEDIA_IMAGES` en Android). Cubre el caso real a cambio de `NSPhotoLibraryUsageDescription` y una superficie más de permisos.
  *Afecta:* HU-04, HU-09 y §Declaraciones de tienda.

- **P9 — ¿Las fotos entran en la copia completa (`.billetudo.json`)? — MÁXIMA PRIORIDAD.**
  **Sube de prioridad por la decisión de P3.** Al sincronizar solo metadatos, la nube dejó de ser una vía de traslado de las fotos de forma definitiva. Por lo tanto: **si las fotos tampoco entran en la copia completa, no existe NINGUNA vía —ninguna, ni una— para que el usuario se lleve sus comprobantes a otro teléfono.** El único mitigante restante sería P6 opción B (guardar también el original en el carrete, delegando el respaldo a Google Fotos / iCloud), que es una solución de terceros y fuera del control de la app. Decidir P9 en negativo **exige** que el aviso de HU-07 lo diga con todas las letras: los comprobantes se pierden y no hay forma de moverlos.
  Opción A: **no entran** (solo las filas de metadatos). La copia sigue siendo un JSON de tamaño manejable y compartible; a cambio, **"restaurar sin pérdida" deja de ser literal**, hay que advertirlo en la pantalla de copia junto a la advertencia de `accountNumberEnc` que ya existe, y se consuma el callejón sin salida descrito arriba.
  Opción B: **la copia pasa a ser un `.zip`** (JSON + carpeta de imágenes). Cumple la promesa al pie de la letra y **es la única forma real que tendría hoy el usuario de llevarse sus comprobantes a otro teléfono** — lo que la convierte en la respuesta concreta al aviso de HU-07. A cambio: la copia crece de kilobytes a decenas o cientos de megabytes, cambia de formato (rompe compatibilidad con copias existentes y con HU-04 de ese doc), y el archivo se vuelve difícil de compartir por los canales habituales.
  Opción C: **el usuario elige** al guardar la copia ("incluir comprobantes — añade ~N MB"), con el tamaño estimado a la vista. Resuelve el trade-off delegándolo, a cambio de una decisión más en un flujo que hoy es simple.
  *Afecta:* `../fase-1/11-import-export.md` HU-03 y HU-04, y el contenido del aviso de HU-07.

## Fases

- **Fase 2 (esta feature):** HU-01 a HU-11 completas, con OCR local por reglas y comprobante local. Depende de que existan Cuentas, Categorías y Transacciones (ya implementadas) y del cambio de esquema (siguiente número libre tras el de notificaciones bancarias).
- **Dependencia dura de orden:** `19-notificaciones-bancarias.md` se construye **antes** y se queda con el primer número libre (`PendingCaptures`). Esta feature no puede escribir su migración hasta que esa exista.
- **Dependencia dura de plataforma:** descomentar `google_mlkit_text_recognition` en `pubspec.yaml` y agregar los permisos nativos (HU-09). Sin eso no hay feature.
- **Dependencia blanda:** el aviso de HU-07 gana mucho si P9 elige incluir las fotos en la copia completa, porque entonces el aviso puede ofrecer una salida concreta en vez de solo informar de una limitación sin escapatoria.
- **Fase 4 (Nivel 1):** parseo con LLM detrás de Edge Function, para mejorar la precisión del total, sugerir categoría y leer recibos que las reglas no cubren. **Se suma encima**: el flujo local sigue existiendo íntegro y funcionando offline y gratis. La imagen **no** se envía al backend salvo que se decida y se declare explícitamente (no está decidido aquí, y no es requisito de esta feature).
  - **Consecuencia asumida de la retención cero:** como no se guarda el texto reconocido, **el LLM de Fase 4 solo puede mejorar capturas nuevas**. No habrá re-proceso retroactivo del histórico: los recibos ya escaneados quedan como quedaron, y una eventual mejora de las reglas locales tampoco los reinterpreta. Reprocesar exigiría volver a correr OCR sobre la imagen —que sí sigue en el dispositivo donde se tomó— y eso solo sería posible para ese dispositivo y como acción explícita del usuario, nunca en batch silencioso. Se acepta el costo.
  - **Tampoco habrá búsqueda por el contenido del recibo** (buscar "farmacia" y que aparezcan las compras cuyo recibo lo mencionaba). La búsqueda de `../fase-1/03-transacciones.md` HU-06 sigue operando sobre `note` y categoría, como hoy.
- **Nivel 2 / Premium (sin fecha):** sincronización de comprobantes a la nube. Solo la costura queda hecha hoy.
- **Fuera de alcance, sin fecha:** extracción de ítems línea por línea, división de una cuenta entre varias categorías desde el recibo, lectura de facturas electrónicas por su CUFE/código QR, PDF como comprobante, y OCR sobre extractos bancarios (es un problema distinto, más cercano a Import).

## Cumplimiento (Nivel 0 / legal / tono)

- Feature **Nivel 0 completa, gratis, ilimitada y sin anuncios**. Sin banners ni interstitials en ninguna de sus pantallas (`CLAUDE.md`).
- **No hay IA ni llamadas de red en Fase 2**, así que no aplica el disclaimer de "no es asesoría financiera". Aplicará en Fase 4 cuando entre el LLM.
- **Privacidad:** la imagen se procesa y almacena **localmente** y no se transmite a ningún servidor. Esa afirmación entra en la política de privacidad y hay que sostenerla en el código (logs y crash reporting incluidos).
- **Precisión obligatoria en la política de privacidad:** lo que **sí** viaja a la nube es el **metadato** del comprobante (que existe, su tamaño, su checksum, en qué dispositivo está), no la imagen ni el texto del recibo. Decir "los comprobantes no salen de tu dispositivo" sería falso; hay que redactarlo con esa distinción, igual que HU-07.
- **Retención cero del texto reconocido:** el contenido literal del recibo no se persiste en ninguna tabla ni viaja a Postgres. Es la política uniforme de la Fase 2 y conviene declararla como tal en la política de privacidad, no feature por feature.
- **Borrado de cuenta:** debe borrar los archivos locales además de las filas (`../fase-1/05-auth-sync.md` HU-07). Requisito de Apple y Google, no una mejora.
- **Declaraciones de tienda desactualizadas:** `docs/legal/declaraciones-tiendas.md:165` y `docs/legal/AUDITORIA.md:649` afirman hoy que la app no tiene OCR. Actualizarlas es parte del alcance de esta feature.
- **Dinero en centavos enteros siempre**, incluido el valor recién leído del recibo; la conversión decimal → centavos con aritmética exacta, nunca `double`.
- **IDs UUID** y `updatedAt` en cada escritura, adjuntos incluidos.
- **Tono positivo también en el error:** un recibo que no se pudo leer es una limitación de la app, no un descuido del usuario. Nunca se le pide que "tome mejores fotos" como condición para que la feature funcione.

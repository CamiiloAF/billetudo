# Feature: Import/Export (portabilidad de datos)

**Nivel:** 0 (gratis, ilimitado, sin anuncios) — feature de **confianza**, deliberadamente gratis y sin cupo alguno.
**Fuente/destino de datos:** CSV → `Transactions`, `Accounts`, `Categories`, `Tags`, `TransactionTags`. Copia completa → todas las tablas sincronizables.
**Ruta:** vive en el hub **"Más"** (`04-inicio.md` HU-01), sección "Gestión". **No** tiene chip de acceso rápido en Inicio (decisión explícita de `04-inicio.md` HU-05b).
**Diseño:** aún no diseñado en `billetudo.pen`. Antes de implementar, seguir el flujo de diseño de `CLAUDE.md` (Pencil primero, `pages/import-export.md` después de aprobar).

## Contexto

Diferenciador de posicionamiento explícito: *"nunca te sentirás atrapado"* (`docs/Viabilidad_App_Finanzas_Personales.md` §3.2, `Plan_Monetizacion_y_Tecnico.md` Cubo A). Tras el cierre de Mint, millones de usuarios perdieron años de historial; Wallet dejó a otros con datos dañados y sin soporte. Esta feature es la promesa contraria y por eso jamás puede quedar tras anuncio o pago.

La promesa tiene **dos mitades distintas** que este doc separa a propósito, porque un solo formato no puede cumplir ambas:

1. **Interoperabilidad** — CSV legible por humanos y por otras herramientas (Excel, Sheets, otra app de finanzas). Es un formato de *lectura*, deliberadamente plano: pierde relaciones (presupuestos, metas, ledger de deudas, ocurrencias programadas).
2. **Copia completa** — un archivo que la propia app sabe **restaurar sin pérdida**, con todas las tablas y sus relaciones. Es un formato de *estado*, no pensado para leerse a mano.

Prometer una copia completa con solo CSV sería mentir: un usuario que exporta CSV y reinstala pierde presupuestos, metas, deudas y pagos programados. Por eso existen ambos.

### Nomenclatura (decisión 2026-07-28) — "respaldo" es de la nube, "copia" es de esta feature

La palabra **"respaldo" está reservada al respaldo en la nube** (`05-auth-sync.md`, cuyo título es literalmente "Auth + Sync (respaldo en la nube)"; el onboarding tiene una pantalla "Respalda tus datos" y el hub "Más" un CTA "Respaldar y sincronizar"). El archivo local de esta feature se llama **"copia"** — *"Guardar una copia de tus datos"*, *"Restaurar desde una copia"* — en UI, `.arb` y documentación.

No es cosmética: **son dos protecciones distintas y complementarias**, y confundirlas es el peor fallo posible de esta pantalla. La nube te protege de perder el teléfono; la copia en archivo queda en tu poder y no depende de nadie (incluidos nosotros) — es la mitad de la promesa "nunca te sentirás atrapado" que la nube no puede cumplir. Un usuario que cree tener una copia porque activó el respaldo en la nube, o al revés, quedó desprotegido justo donde pensaba que estaba cubierto.

Consecuencia visual: **el violeta de marca sigue significando "nube"** (quedó reservado para ese CTA tras la auditoría de `docs/dev-runs/bug-fixes-pixel-audit.md`), así que esta pantalla no puede usarlo como su señal principal. Esta pantalla **no menciona la nube como CTA** ni se vuelve un embudo de login: es 100% local.

### Alcance de construcción (decisión 2026-07-27)

- **Import por mapeo manual de columnas**, no por perfiles hardcodeados de Wallet/Mint. La app lee **cualquier** CSV: detecta encabezados y el usuario confirma qué columna es qué (con autodetección del formato propio, que deja el caso base en un toque). Motivo: un perfil por app promete una migración 1:1 que no se puede sostener sin archivos de muestra reales de cada versión de cada app, y envejece cada vez que Wallet o Mint cambian su export. El mapeador cubre Wallet, Mint y cualquier otra herramienta sin adivinar nada, y las **plantillas de mapeo guardadas** (HU-06) hacen que reimportar el mismo origen tampoco cueste trabajo.
- **Se construye en Fase 0:** export CSV, copia completa, restauración, import con mapeo, vista previa, detección de duplicados y reversión por lote.
- **Fuera de alcance (no se promete en la tienda ni en la UI):** OFX/QIF/MT940, export a Excel nativo (`.xlsx`) o PDF, y sincronización con archivos en la nube del usuario (Drive/iCloud). El export a PDF de informes pertenece además a Cubo B (`10-graficas-informes.md`).

## Reglas transversales del formato (fuente de verdad; aplican a todas las HU)

### Dialecto CSV

- **UTF-8 con BOM.** El BOM es lo que hace que Excel en Windows/es-CO no destroce las tildes al abrir el archivo con doble clic.
- **Separador de campos: coma.** Comillado RFC 4180 (`"`), con `""` para escapar comillas dentro del valor. Fin de línea `\r\n`.
- **Al importar** se detecta el separador (coma, punto y coma, tabulador) leyendo las primeras líneas; el usuario puede corregirlo si la detección falla. Excel en configuraciones regionales europeas y latinoamericanas exporta con punto y coma — ignorarlo rompería la mitad de los archivos reales.

### Montos

- En el CSV los montos van en **unidades normales** (`12.34`), no en centavos: el CSV es para humanos y para otras apps. **La conversión a `amountMinor` ocurre en el borde** (parser/serializador), nunca dentro del dominio.
- **Export:** punto decimal, **sin** separador de miles, siempre positivo, con los decimales de la moneda (`1234.50`, no `1.234,50` ni `$ 1.234,50`). El signo/dirección lo lleva la columna `tipo`, coherente con la regla de `03-transacciones.md` (`amountMinor` siempre positivo).
- **Import:** se aceptan ambas convenciones (`1.234,56` y `1,234.56`) — la elige el usuario en el mapeo, precargada por autodetección. También se acepta la convención de **signo** (montos negativos = gasto) cuando el archivo no trae columna de tipo.
- **La conversión decimal → centavos se hace con aritmética decimal exacta** (`Decimal`/enteros), **nunca con `double`**: `19.99 * 100` en punto flotante da `1998.9999...`. Redondeo half-up al último decimal de la moneda, y si el valor trae más decimales de los que la moneda admite, la fila se marca como redondeada en la vista previa (no se descarta).

### Fechas

- **Export:** ISO-8601 `YYYY-MM-DD` (fecha local del movimiento, sin hora ni zona). Es el único formato que no es ambiguo entre `03/04` día-mes y mes-día.
- **Import:** el formato es parte del mapeo (`DD/MM/YYYY`, `MM/DD/YYYY`, `YYYY-MM-DD`, con `-`, `/` o `.`), autodetectado cuando el archivo lo permite. **Si la muestra es ambigua** (todos los días ≤ 12), la vista previa lo advierte explícitamente y muestra cómo quedó interpretada la primera fila — importar 12 meses con el día y el mes cruzados es un daño silencioso y difícil de detectar después.
- La fecha se interpreta en la **zona horaria local del dispositivo**, coherente con `10-graficas-informes.md` §Reglas de conteo.

### Encabezados y nombres de archivo

- Los encabezados del export salen **en el idioma activo de la app** (es/en) porque el CSV es para leerse. El importador **reconoce ambos vocabularios**, así que un CSV exportado en inglés se reimporta en una app en español sin tocar nada.
- Nombres de archivo: `billetudo-transacciones-YYYY-MM-DD.csv`, `billetudo-cuentas-YYYY-MM-DD.csv`, `billetudo-categorias-YYYY-MM-DD.csv`, `billetudo-copia-YYYY-MM-DD.billetudo.json`.

### Identidad y datos que nunca salen

- Cada fila exportada incluye su **`id` (UUID)** como primera columna. Es lo que permite reimportar sin duplicar (HU-08) y lo que hace del CSV propio una copia utilizable, no solo una foto.
- **Nunca se exporta `accountNumberEnc`** (número de cuenta completo), en ningún formato — CSV ni copia completa. Regla dura de `01-cuentas.md` HU-03: vive cifrado con la clave del dispositivo, no se sincroniza y no aparece en exportaciones. Tampoco se exporta `userId` (es del sync, no del usuario).
- `last4` **sí** se exporta (es el fragmento no sensible por diseño).

### Moneda

- Cada fila lleva su propia moneda (ISO-4217), tal como está en el esquema: aquí **no hay conversión ni moneda base**. Exportar convertido falsearía el dato original; ver `12-multi-moneda.md`.
- Al importar, si la moneda de la fila no coincide con la de la cuenta destino, aplica `12-multi-moneda.md` HU-01: se conserva el monto original con su moneda. **Si no hay tasa cacheada para el par**, la fila se importa igual y queda marcada como pendiente de tasa — nunca se descarta ni se inventa una conversión.

## Historias de usuario

### HU-01 — Exportar mis transacciones a CSV
Como usuario quiero exportar todas mis transacciones (o un rango filtrado) a un archivo CSV, para tener una copia propia o llevarlas a otra herramienta.

**Criterios de aceptación:**
- Columnas, en este orden: `id`, `fecha`, `tipo`, `monto`, `moneda`, `cuenta`, `cuenta_destino`, `categoria`, `subcategoria`, `nota`, `etiquetas`, `presupuestable`, `origen`.
  - `tipo`: `ingreso` / `gasto` / `transferencia`.
  - `cuenta_destino` solo se llena en transferencias (`transferAccountId`).
  - `categoria` es la **raíz** y `subcategoria` la hoja; una transacción categorizada directamente en la raíz deja `subcategoria` vacía. Dos columnas (en vez de una ruta `Comida > Mercado`) porque es lo que Excel y las demás apps saben filtrar.
  - `etiquetas`: nombres separados por `;` (el separador de campos es la coma, así que no puede ser coma).
  - `presupuestable`: `sí`/`no`, refleja `countsInBudget` — sin esa columna, un round-trip convertiría transferencias presupuestables en transferencias normales y descuadraría los presupuestos.
  - `origen`: valor legible de `TxSource` (manual, importado, …), igual que `03-transacciones.md` HU-08.
- **Reutiliza los filtros de `03-transacciones.md` HU-06** (cuenta, categoría, tipo, rango de fechas, etiqueta, texto). El export respeta exactamente lo que el usuario está viendo, más una opción explícita **"todo el histórico"** que ignora el filtro de fecha por defecto (que nunca está apagado, ver HU-06b de ese doc).
- Se excluyen las transacciones con `deletedAt` o `tombstonedAt`, y las de cuentas con `tombstonedAt` (mismas exclusiones de `10-graficas-informes.md` §Reglas de conteo). Las de **cuentas archivadas sí se incluyen** — el archivo es historial, no vista activa.
- El archivo se entrega por el **share sheet del sistema** (compartir/guardar en archivos), sin pedir permisos de almacenamiento donde el share nativo baste.
- **Sin límite de tamaño, de rango ni de frecuencia** (Nivel 0). Con historial largo, el archivo se escribe **por streaming** (fila a fila desde una query de Drift), nunca materializando todas las transacciones en memoria.
- Progreso visible y **cancelable** en exports grandes; cancelar borra el archivo parcial en vez de dejar un CSV truncado que parezca completo.

### HU-02 — Exportar cuentas y categorías
Como usuario quiero exportar también mi estructura de cuentas y categorías, para tener una copia de mi configuración, no solo de los movimientos.

**Criterios de aceptación:**
- **Cuentas** (`billetudo-cuentas-*.csv`): `id`, `nombre`, `tipo`, `moneda`, `saldo_inicial`, `institucion`, `last4`, `archivada`, `orden`, `icono`, `color`, `tasa_interes_anual` (porcentaje legible, derivado de `interestRateBps`), `cupo`, `dia_corte`, `dia_pago`. **Sin número de cuenta completo** (regla dura de arriba).
- **Categorías** (`billetudo-categorias-*.csv`): `id`, `nombre`, `tipo` (ingreso/gasto), `categoria_padre` (nombre de la raíz, vacío si es raíz), `id_padre`, `icono`, `color`, `orden`. Se exporta el nombre **y** el `id` del padre: el nombre para que sea legible, el `id` para que la reimportación reconstruya la jerarquía sin ambigüedad si hay nombres repetidos.
- El usuario elige qué exportar en un solo flujo (selección múltiple: transacciones / cuentas / categorías). Si elige más de uno, se entrega **un `.zip`** con los CSV adentro, no varios archivos sueltos por el share sheet.
- Las cuentas y categorías con `deletedAt`/`tombstonedAt` se excluyen; las **archivadas se incluyen** con su bandera.

### HU-03 — Guardar una copia completa de mis datos
Como usuario quiero guardar un archivo con **todo** lo que tengo en la app, para poder recuperarlo tal cual si cambio de teléfono, reinstalo o algo sale mal.

**Criterios de aceptación:**
- Un único archivo `.billetudo.json` que contiene **todas las tablas sincronizables** (cuentas, categorías, transacciones y sus etiquetas, presupuestos con su alcance y overrides, metas y sus aportes, deudas con su ledger completo, pagos programados con sus ocurrencias, ajustes) con sus `id`, `createdAt`, `updatedAt`, `deletedAt` y `tombstonedAt` intactos.
- **Cabecera versionada**: versión del formato de copia, `schemaVersion` de Drift y versión de la app que la generó. Sin esto, una copia vieja restaurada en una app nueva es una ruleta.
- **Excluye** `accountNumberEnc` (inútil fuera del dispositivo: está cifrado con una clave del Keychain/Keystore que no viaja) y `userId`. La app lo dice explícitamente al guardar la copia: *"el número de cuenta guardado no se incluye; tendrás que volver a ingresarlo"*.
- Se escribe por **streaming**, tabla por tabla, y es cancelable como HU-01.
- **Advertencia de privacidad al compartir:** el archivo va **sin cifrar** y contiene el detalle financiero completo. Se avisa en el momento de compartir (una línea, sin alarmismo) para que el usuario elija dónde lo guarda. No se sube a ningún servidor de la app — el flujo es 100% local.
- Es Nivel 0, sin límite de frecuencia ni de tamaño.

### HU-04 — Restaurar desde una copia
Como usuario quiero restaurar una copia que guardé antes, para recuperar mi app tal como estaba.

**Criterios de aceptación:**
- Antes de tocar nada, se valida la cabecera: **una copia de una versión de formato más nueva que la app se rechaza** con un mensaje claro ("actualiza la app para restaurar este archivo"), nunca se restaura a medias. Una copia más vieja sí se restaura, migrando su contenido.
- Se muestra un resumen previo: fecha de la copia, versión, y cuántas filas trae por tipo.
- **Dos modos, elegidos explícitamente por el usuario:**
  - **Fusionar** (por defecto): se combina por `id`. Fila que no existe → se crea; fila que existe → gana la de `updatedAt` mayor (mismo criterio last-write-wins del sync, `05-auth-sync.md`). Idempotente: restaurar el mismo archivo dos veces no duplica nada.
  - **Reemplazar todo**: borra los datos locales y deja exactamente el contenido de la copia. Requiere confirmación explícita y escalonada (no un solo "OK"), porque es destructivo e irreversible.
- **Toda la restauración ocurre en una sola transacción de base de datos:** o queda completa, o no queda nada. Una restauración a medias deja al usuario en un estado peor que el que tenía.
- **Interacción con el sync (crítico, ver `05-auth-sync.md` decisiones #15-#18):** si hay sesión iniciada, la restauración se propaga a la nube por la cola de subida de PowerSync, y **"Reemplazar todo" borra también los datos de la cuenta en la nube**. Eso se le dice al usuario en la confirmación, con esas palabras. La restauración **no** se ejecuta mientras la fusión post-login está en curso.
- Al terminar: resumen de qué se creó, qué se actualizó y qué se omitió, y aviso de que la subida a la nube puede tardar si hay sesión.

### Recomendar la copia cuando la nube no está al día (decisión 2026-07-28)

> Origen: el incidente de pérdida de datos documentado como **decisión #22** en `05-auth-sync.md`. Un bloqueo de la cola de subida dejó 89 cambios existiendo únicamente en el teléfono del usuario durante 3 días; al reinstalar la app, se perdieron todos. **La copia de esta feature es la única protección que habría funcionado ahí** — el respaldo en la nube estaba precisamente roto, y Android Auto Backup nunca había respaldado la app (verificado con `dumpsys backup`).

Esto le da a HU-03 un segundo propósito, además de la portabilidad: **es la red de seguridad cuando el respaldo en la nube no está cumpliendo su función.**

**Criterios de aceptación:**
- La pantalla **"Estado de sincronización"** (`05-auth-sync.md` HU-08) ofrece guardar una copia como acción de primer nivel cuando hay registros sin subir. No es un enlace escondido: es la salida concreta que el usuario tiene disponible en ese momento.
- El texto respeta la distinción de la §Nomenclatura y **no la difumina**: la nube es el *respaldo*, el archivo es la *copia*. Justamente porque el respaldo falló es cuando más importa que el usuario entienda que son dos cosas distintas. Nunca decir "haz un respaldo" para referirse al archivo.
- El fraseo explica **por qué ahora**, sin culpar a nadie ni alarmar: los cambios sin subir viven solo en este dispositivo, y una copia los pone a salvo de una reinstalación o un cambio de teléfono.
- La recomendación **no** aparece cuando la sincronización está sana. Un aviso permanente se vuelve invisible y contradice el tono de progreso; la copia se sigue ofreciendo desde su lugar normal en "Más".
- **La copia debe poder guardarse aunque la cola de subida esté bloqueada.** Es un flujo 100% local que lee la base local, así que un sync trabado no puede impedirla — es exactamente el escenario para el que existe. Verificar que ninguna dependencia del flujo de copia espere a que el sync esté al día.

**Excel (`.xlsx`) queda fuera de esta recomendación.** Sigue *fuera de Fase 0 y sin fecha* (ver §Fases), y además es un formato de *lectura*, no de *estado*: no puede restaurarse sin pérdida. Recomendarlo como red de seguridad sería engañoso. El diseño de la pantalla de sincronización ya reserva su lugar marcado como **Próximamente**, pero la protección real que se ofrece hoy es la copia completa de HU-03.

### HU-05 — Importar transacciones desde un CSV cualquiera
Como usuario quiero importar transacciones desde un archivo CSV, propio o de otra app, para no perder mi historial al migrar.

**Criterios de aceptación:**
- Se acepta **cualquier CSV**: la app lee los encabezados y una muestra de filas, y presenta un paso de **mapeo de columnas** donde el usuario asigna cada campo.
  - **Campos obligatorios:** fecha, monto, cuenta. **Opcionales:** tipo, moneda, categoría, subcategoría, cuenta destino, nota, etiquetas, `id`.
  - Junto al mapeo se resuelven **formato de fecha**, **convención decimal** y **cómo se expresa gasto vs. ingreso** (columna de tipo con sus valores, o signo del monto). Cada elección muestra en vivo cómo queda interpretada la primera fila real del archivo.
  - Si no se mapea `moneda`, se asume la moneda de la cuenta destino.
- **Autodetección del formato propio:** si los encabezados coinciden con los del export de HU-01 (en es o en en), el mapeo viene precargado completo y el usuario solo confirma. Migrar de un dispositivo a otro con el CSV propio es, en la práctica, un toque.
- **Wallet (BudgetBakers) y Mint quedan cubiertos por este mismo mecanismo**, sin perfiles hardcodeados. Lo que la app promete es "importa cualquier CSV", no "migración 1:1 desde Wallet" — ver §Reglas de negocio.
- Todas las filas importadas se guardan con `source = imported` (`03-transacciones.md`) y con el `importBatchId` del lote (HU-08).
- **Nada se escribe hasta que el usuario confirma la vista previa** (HU-06).
- La importación corre **fuera del hilo de UI** y en **una sola transacción de base de datos**, con progreso visible y cancelación; cancelar no deja filas a medias.
- **Sin límite de filas ni de frecuencia** (Nivel 0).

### HU-06 — Vista previa, destinos y plantillas de mapeo
Como usuario quiero ver exactamente qué va a pasar antes de confirmar una importación, para no ensuciar mis datos.

**Criterios de aceptación:**
- La vista previa muestra: total de filas leídas, cuántas se importarán, cuántas son **posibles duplicados** (HU-07), cuántas tienen advertencias y cuántas son inválidas — con la razón de cada una y la fila del archivo, para poder corregir el CSV si se quiere.
- **Resolución de destinos:** por cada nombre de cuenta o categoría del archivo que no exista, el usuario elige entre **crear** (por defecto) o **mapear a una existente**. La coincidencia se busca ignorando mayúsculas, tildes y espacios sobrantes, para que "comida y bebida" caiga en "Comida y bebida".
  - **Ninguna fila se pierde nunca por falta de cuenta o categoría destino.**
  - Las cuentas creadas por un import nacen con `initialBalanceMinor = 0` y el tipo `other` salvo que el archivo traiga tipo — el saldo real lo reconstruyen las transacciones importadas. Esto se le explica al usuario, porque es la diferencia entre "mi saldo quedó raro" y "ya entendí por qué".
  - Las categorías creadas por un import son categorías normales con UUID nuevo (nunca ids `seed-*`, reservados al catálogo canónico — `02-categorias.md` HU-06 y `05-auth-sync.md` decisión #12) y respetan la coherencia `kind` ↔ `type` de la transacción.
- **Filas inválidas no bloquean el resto:** se importa lo válido y se reporta lo omitido. Solo se aborta entero si el archivo no es legible o si ningún campo obligatorio pudo mapearse.
- **Plantillas de mapeo:** al confirmar, se ofrece guardar el mapeo con un nombre (ej. "Mi banco", "Wallet") para reusarlo en el siguiente archivo del mismo origen. Es lo que hace que una importación mensual recurrente no cueste el mismo trabajo cada vez.
- Al finalizar se muestra un **resumen**: importadas, omitidas por duplicado, omitidas por error (con motivo), cuentas creadas, categorías creadas, etiquetas creadas.

### HU-07 — Detectar duplicados al importar
Como usuario quiero que la app me avise si estoy por importar transacciones que ya tengo, para no duplicar mi historial al reimportar un archivo por error.

**Criterios de aceptación:**
- **Duplicado exacto (`id` coincide con una fila existente):** se marca como **ya importada** y se omite por defecto. Es lo que hace idempotente reimportar el CSV propio.
- **Duplicado probable (sin `id`):** misma cuenta + mismo `amountMinor` + misma moneda + mismo `type` + misma fecha. Se marca como candidato en la vista previa; la nota se usa solo para **reforzar o debilitar** la sospecha en la presentación, nunca como criterio duro (dos cafés iguales el mismo día son dos gastos reales, no un duplicado).
- El usuario decide fila por fila, con acciones en bloque ("omitir todos los duplicados" / "importar todos"). **Por defecto los candidatos vienen desmarcados** (no se importan): equivocarse omitiendo se arregla importando de nuevo; equivocarse duplicando obliga a limpiar a mano.
- **La sospecha nunca bloquea la importación completa** — es una advertencia, la decisión final es del usuario.
- La detección corre en SQL sobre índices, no comparando en memoria contra todo el historial.

### HU-08 — Deshacer una importación completa
Como usuario quiero poder revertir una importación entera después de verla en la app, para no quedar atrapado con miles de filas mal importadas.

**Criterios de aceptación:**
- Cada importación crea un **lote** (`ImportBatches`) con fecha, nombre del archivo, plantilla usada y conteos. Cada fila creada por esa importación —transacciones, y también las cuentas, categorías y etiquetas nacidas del import— queda enlazada al lote por `importBatchId`.
- Existe una vista **"Importaciones"** con el historial de lotes y, en cada uno, la acción **"Deshacer esta importación"**. **No caduca**: el lote se puede revertir mientras exista.
- **Deshacer** aplica borrado lógico (`deletedAt`) a las transacciones del lote —coherente con `03-transacciones.md` HU-05, así que siguen recuperables desde la papelera— y a las cuentas/categorías/etiquetas creadas por el lote **que no tengan uso fuera de él**. Las que sí lo tengan (ej. una categoría creada por el import y usada después en un movimiento manual) **se conservan**, y la confirmación dice cuántas y por qué.
- La confirmación informa además **cuántas filas del lote fueron editadas manualmente después de importarlas** — deshacer también las borra, y ese es justo el caso donde el usuario se arrepiente.
- Deshacer marca el lote como revertido (`revertedAt`); **el registro del lote no se borra**, para que el historial no mienta.
- Toda la reversión ocurre en una sola transacción de base de datos.
- **Con sesión iniciada, la reversión se propaga a la nube** como cualquier otro borrado (`05-auth-sync.md`); no es una operación "solo local".

### HU-09 — Estados, errores y archivos grandes
Como usuario quiero que la pantalla me diga qué está pasando en cada momento, en vez de dejarme mirando un spinner.

**Criterios de aceptación:**
- **Vacío:** sin datos que exportar (usuario nuevo), el export se explica en vez de generar un archivo con solo encabezados.
- **Carga/progreso:** export, import y restauración muestran progreso real (filas procesadas / total) y son cancelables. Nunca un spinner indefinido: un import de miles de filas se lee como app colgada — el mismo hallazgo que dejó la fusión post-login en `05-auth-sync.md` HU-04.
- **Archivo ilegible o vacío:** error claro con la causa (no es CSV, codificación no reconocida, sin filas) y sin dejar estado a medias.
- **Sin espacio en disco / permiso denegado:** mensaje accionable, archivo parcial eliminado.
- **Offline:** todo el flujo funciona sin conexión — es local por definición. Si hay sesión, se avisa que la subida a la nube ocurrirá al reconectar. **Un fallo de sync nunca bloquea exportar, importar ni restaurar.**
- **Tono** positivo y neutral en todos los estados, incluidos los errores: nunca culpar al usuario por un archivo mal formado (`CLAUDE.md`).

## Reglas de negocio y edge cases

- **Nivel 0 intacto:** ninguna parte de esta feature —ni la copia completa, ni el mapeador, ni la reversión— puede quedar detrás de anuncio, pago, cupo o límite de filas. Es central al posicionamiento de confianza (`CLAUDE.md`, `Plan_Monetizacion_y_Tecnico.md` §Cubo A).
- **100% local:** lee y escribe archivos en el dispositivo, sin backend ni red. No es una excepción al offline-first; es su demostración.
- **Compatibilidad con otras apps: best-effort y dicho con todas las letras.** La UI promete *"importa desde cualquier CSV"*, no *"migración perfecta desde Wallet/Mint"*. Lo que esas apps exportan y este modelo no representa (adjuntos, cuentas compartidas, presupuestos con su propia semántica) simplemente no se importa, y el resumen final lo dice — mejor una expectativa cumplida que una promesa rota en la reseña de la tienda.
- **Importación masiva y cola de subida:** un import de miles de filas encola miles de operaciones en `ps_crud`, que es **FIFO** — una sola operación fallida bloquea todo lo que va detrás (`05-auth-sync.md` decisiones #16 y #17, incidente del `400` en bucle). Consecuencias obligatorias: escribir en una sola transacción, mostrar el estado de subida como pendiente (no como error) mientras la cola drena, y **no** dar la sync por rota porque tarde.
- **El import no cambia las reglas de conteo:** una transferencia importada sin `countsInBudget` sigue sin contar como gasto; un movimiento importado con categoría de deuda **no** es un movimiento de deuda (no tiene `debtId`) — el CSV no puede crear deudas ni metas. Ver `10-graficas-informes.md` §Reglas de conteo.
- **Dinero siempre en centavos** dentro de la app; el decimal solo existe en el archivo. Ninguna suma, resta ni conversión intermedia en `double`, incluida la del parser.
- **Privacidad:** el número de cuenta completo nunca sale en ningún archivo. La copia va sin cifrar y se advierte al compartirla. Ningún archivo generado se envía a un servidor de la app.
- **Textos solo desde `AppLocalizations`** (es + en), encabezados de CSV incluidos — y el importador debe reconocer ambos idiomas para que el round-trip cruzado funcione.

## Cambios de esquema requeridos (Drift)

Ejecutar vía `/drift-schema-change`: subir `schemaVersion`, escribir migración, regenerar con build_runner y **mantener paridad en el `Schema` de PowerSync y en Postgres** (el esquema se declara dos veces, `05-auth-sync.md` decisión #6). Recordar también actualizar la función `delete_account_data` de Supabase: toda tabla nueva debe entrar ahí, con los hijos antes que los padres (`05-auth-sync.md` decisión #11 y el bug encontrado en HU-07).

**Tabla nueva `ImportBatches`** (con `_SyncColumns`):

| Columna | Tipo | Notas |
|---|---|---|
| `fileName` | `text()` (max 255) | Nombre del archivo importado, para reconocer el lote en el historial. |
| `templateName` | `text().nullable()` | Plantilla de mapeo usada (HU-06). |
| `importedAt` | `dateTime()` | Momento de la importación (distinto de `createdAt` solo por claridad de intención). |
| `rowsImported` | `integer()` | Filas efectivamente creadas. |
| `rowsSkipped` | `integer()` | Omitidas (duplicado o error), para que el resumen sobreviva a la sesión. |
| `revertedAt` | `dateTime().nullable()` | Marca de reversión (HU-08). El lote nunca se borra. |

**Columna nueva `importBatchId`** — `text().nullable().references(ImportBatches, #id)` — en `Transactions`, `Accounts`, `Categories` y `Tags`. Nullable: todo lo creado a mano la deja nula. Es lo que hace posible revertir un lote sin heurística.

> Alternativa descartada: inferir el lote por `source = imported` + ventana de tiempo. Falla en cuanto hay dos importaciones el mismo día y no cubre cuentas/categorías, que no tienen `source`.

## Coherencia con otros documentos

| Documento | Punto de contacto | Estado |
|---|---|---|
| `01-cuentas.md` HU-03 | El número de cuenta completo nunca aparece en exportaciones | **Reforzado aquí** — regla dura para CSV y copia completa |
| `02-categorias.md` HU-06 | Ids `seed-*` son del catálogo canónico | **Precisado** — las categorías creadas por un import usan UUID nuevo, nunca `seed-*` |
| `03-transacciones.md` HU-06/HU-08 | Filtros reutilizados por el export; `source = imported` | Consistente |
| `05-auth-sync.md` #6, #11, #16, #17 | Doble declaración de esquema, `delete_account_data`, cola FIFO | **Incorporado** como requisitos del cambio de esquema y del import masivo |
| `05-auth-sync.md` (título) + `13-onboarding.md` HU-08 | La palabra "respaldo" ya nombra el respaldo en la nube | **Resuelto aquí** — esta feature usa "copia"; ver §Nomenclatura |
| `05-auth-sync.md` #22 + HU-08 | Cuando la cola de subida se bloquea, la copia es la única protección que queda | **Incorporado aquí** — ver §Recomendar la copia cuando la nube no está al día |
| `10-graficas-informes.md` §Reglas de conteo | Exclusiones e interpretación de lo importado | Consistente — el import no introduce reglas propias |
| `12-multi-moneda.md` | Sin conversión en el archivo; fila sin tasa se importa igual | **Precisado aquí** |
| `04-inicio.md` HU-01/HU-05b | Vive en "Más", sin chip en Inicio | Consistente |

## Fases

- **Fase 0 (esta feature):** HU-01 a HU-09 completas. Depende de que existan Cuentas, Categorías y Transacciones (ya implementadas); la copia completa (HU-03/HU-04) depende además de que las demás tablas existan en el esquema — **ya existen todas**, aunque sus features no estén construidas, así que la copia se escribe contra el esquema, no contra las features.
- **Dependencia blanda:** la columna `presupuestable` del CSV solo tiene efecto real cuando exista `countsInBudget` en la UI (Fase B1 del plan de transferencias). Hasta entonces se exporta e importa el valor del esquema, sin efecto visible. No es bloqueante.
- **Fuera de Fase 0 y sin fecha:** OFX/QIF, `.xlsx`, PDF (Cubo B), copia cifrada con contraseña, y copia automática a Drive/iCloud.

## Cumplimiento (Nivel 0 / legal / tono)

- Feature **Nivel 0 completa, gratis, ilimitada y sin anuncios**. Sin banners ni interstitials en ninguna de sus pantallas.
- **Refuerza el cumplimiento legal de portabilidad** (RGPD art. 20 y equivalentes de LGPD / Ley 1581 / LFPDPPP): el usuario puede llevarse sus datos en un formato estructurado y de uso común, sin intervención de soporte. Es complementaria al borrado de cuenta de `05-auth-sync.md` HU-07, no sustituta.
- Sin IA ni llamadas de red: no aplica el disclaimer de "no es asesoría financiera".
- Dinero en centavos dentro de la app, siempre.
- Tono positivo también en el error: un archivo mal formado es un problema del archivo, no una falla del usuario.

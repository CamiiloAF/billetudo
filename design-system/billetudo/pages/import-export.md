# Página: Importar y exportar

Overrides sobre `MASTER.md` para la feature de portabilidad de datos (`docs/requirements/11-import-export.md`, HU-01 a HU-09). **Diseño cerrado y aprobado, claro y oscuro (2026-07-29).**

## Tesis (norte del diseño)

Diferenciador de posicionamiento explícito: *"nunca te sentirás atrapado"*. La feature tiene dos mitades que el diseño mantiene deliberadamente separadas:

1. **Interoperabilidad** (CSV) — un formato de lectura, para humanos y otras apps.
2. **Copia completa** (`.billetudo.json`) — un formato de estado, que la propia app sabe restaurar sin pérdida.

El hub resuelve esa tensión con jerarquía visual, no con texto: la copia local vive en un **hero** propio; exportar CSV, importar e importaciones son filas de lista debajo. Nunca se confunden porque no compiten en el mismo nivel.

### Nomenclatura (regla dura, ver `11-import-export.md` §Nomenclatura)

**"Respaldo" es de la nube. "Copia" es de esta feature.** El violeta de marca (`$primary`) significa "nube" en todo el producto — esta feature completa no lo usa en ningún elemento propio (excepciones documentadas donde el sistema lo impone, ninguna en esta feature). Consecuencia: ninguna fila ni CTA de aquí lleva violeta; la fila "Guardar una copia" que aparece en Sincronización navega hacia acá en vez de abrir su propia hoja, precisamente para no duplicar y arriesgar que las dos superficies diverjan en esta nomenclatura.

## Frames

### Hub (`FrMZc` claro / `e5WXQf` oscuro, apilado desde "Más" → Gestión; `Page Header`, sin `Tab Bar`) — Variante B "Copia protagonista"

| Estado | Claro | Oscuro |
|---|---|---|
| Con datos | `oSWz9` | `qLqgY` |
| Sin copia previa (nunca guardó un archivo) | `qDCvi` | `VJ6Bl` |
| Vacío (usuario nuevo, sin transacciones) | `Am9cg` | `n6m7LX` |

### Flujo de import (`jfq0l` claro / `pjdLI` oscuro, HU-05/HU-06/HU-07)

| Paso | Pantalla | Claro | Oscuro |
|---|---|---|---|
| Entrada | Seleccionar archivo | `W2hiZK` (OBSOLETO — ver nota) | `rsBfI` (OBSOLETO — ver nota) |
| 1/4 (chrome interno "2/4"*) | Mapeo de columnas — Manual (con toggle) | `drEA1` | `y19Ij` |
| 1/4 | Mapeo de columnas — Automático | `UuTCz` | `a1ESaS` |
| 1/4 | Mapeo de columnas — Automático, plantilla reconocida | `HBdCo` | `lHG0E` |
| 2/4 | Resolver destinos | `kYBYa` | `u8TSNH` |
| 3/4 | Vista previa final — Var 2 · Jerarquía por severidad | `ScJz3` | `L82zyd` |
| 4/4 | Resumen final | `XRBVa` | `Aa1ek` |

\* El header interno de cada paso numera "2/4"–"4/4" porque cuenta "Seleccionar archivo" como paso 1 implícito; no renumerar sin revisar los 4 headers a la vez (en ambos temas).

**Toggle Automático/Manual (agregado 2026-08-06):** el paso de mapeo ahora tiene un `Segmented Control` (`hFu41`) de 2 opciones arriba del bloque de contenido, en los tres estados de arriba — instanciado con el 3er segmento del componente como spacer inerte (`enabled:false`, 0×0) para repartir el ancho 50/50 entre "Automático"/"Manual". En modo Automático **no se muestra el desglose columna por columna** (decisión explícita del usuario, 2026-08-06) — solo el resumen de formato + la tarjeta de vista previa en vivo; el detalle completo se verifica en el paso 3 (Vista previa final). El banner de "plantilla reconocida" (`HBdCo`/`lHG0E`) reusa `Privacy Note Strip` (`YAUFx`) vía `descendants` (`fill:$mint-soft`, ícono `badge-check` en `$mint`, texto en `$mint-text`) — no es un componente nuevo.

**Entrada — `W2hiZK`/`rsBfI` obsoletos (decisión 2026-08-06):** el CTA "Importar desde un CSV" del hub ya no abre esta hoja — abre el selector de archivos nativo del SO directamente. Los frames se conservan como referencia histórica del patrón de hoja de entrada, ya renombrados con prefijo "OBSOLETO —" en el `.pen`.

### Importaciones — historial y reversión (HU-08)

| Estado | Claro | Oscuro |
|---|---|---|
| Historial de lotes | `tJhwB` | `kW3Zs` |
| Historial vacío | `tiCoZ` | `q2QLzl` |
| Confirmación de deshacer | `l1twf` | `r59P4P` |

### Restaurar copia (HU-04)

**Arquitectura de navegación (corregida 2026-08-07):** los 3 estados de abajo, más progreso/listo/error (que reusan el patrón compartido, ver "Progreso y errores" abajo), instancian todos `Bottom Sheet Base` (`PqTUt`) — es una **hoja modal**, no una página con ruta propia. La implementación original (workflow que construyó la feature) los había hecho página completa con `Page Header`; se corrigió a `RestoreSheet`/`RestoreSheetBody` (`lib/features/import_export/presentation/widgets/sheets/restore_sheet.dart`), disparada directo desde el hub — ya no existe la ruta `restaurar` en `app_router.dart`. Tocar "Restaurar desde una copia" abre el selector de archivos nativo DIRECTO (sin paso intermedio, mismo patrón que la entrada de CSV); solo si se elige un archivo válido se abre la hoja, con su contenido rotando entre resumen/elección → confirmación de reemplazar (si aplica) → progreso → listo/error, todo dentro de la MISMA hoja. No dismisible por scrim/drag mientras `running` (mismo criterio de "progreso bloqueante" del resto de la feature).

| Estado | Claro | Oscuro |
|---|---|---|
| Resumen y elección Fusionar/Reemplazar | `uUGXf` | `weAqZ` |
| Confirmación escalonada de Reemplazar — confirmado | `MjNwC` | `j6uYYz` |
| Confirmación escalonada de Reemplazar — estado inicial (inerte) | `NY5o6` | `DbfG1` |

**Resuelto (2026-08-07):** el Resumen final de Import (`Aa1ek`/`XRBVa`) y el patrón compartido de Progreso/Error (`xdG9q`/`dSkbx`, `d9wzVg`/`VHJP8`, `TmHSC`/`HbEJc`) usado también dentro de `ImportFlowPage`/`ExportPage`/`SaveCopyPage` tenían el MISMO problema (son `PqTUt` en Pencil, eran página completa en código) — corregido para los 3 flujos:

- **`ImportFlowPage`:** los pasos de mapeo/destinos/vista previa (`jfq0l`/`pjdLI`, HU-05/06/07) siguen siendo páginas con `Page Header` — no están marcados `PqTUt`, no cambiaron. Solo el commit final y lo que sigue (progreso, error de escritura, resumen `Aa1ek`/`XRBVa`) se movieron a `ImportRunSheet`/`ImportRunSheetBody` (`lib/features/import_export/presentation/widgets/sheets/import_run_sheet.dart`), abierto por el botón "Importar" del paso de vista previa. La página del wizard queda montada debajo, cubierta por el scrim de la hoja.
- **`ExportPage`:** el formulario de alcance/filtros (`zFLrC`/`h6ZQQw`/`calDR`) sigue siendo página, sin cambios — no está marcado `PqTUt`. Solo la escritura (progreso `xdG9q`/`dSkbx`, error `TmHSC`/`HbEJc`) se movió a `ExportRunSheet`/`ExportRunSheetBody` (`.../sheets/export_run_sheet.dart`), abierto por el CTA "Exportar" de `ExportForm`.
- **`SaveCopyPage`:** eliminada por completo (no había un "paso de formulario" propio que conservar — todo el flujo era ya el patrón compartido). Reemplazada por `SaveCopySheet`/`SaveCopySheetBody` (`.../sheets/save_copy_sheet.dart`), disparada directo desde el hub (ya no existe la ruta `guardar-copia` en `app_router.dart`), mismo patrón que `RestoreSheet.show`.

Mismo bug de layout encontrado y corregido al convertir Restaurar: `ImportSummaryStep`'s raíz usaba `Column` (tamaño `max` por defecto) + `Expanded`/`ListView`, correcto dentro del `Expanded` de una página pero que estira la hoja a pantalla completa dentro de un sheet — resuelto con `mainAxisSize: MainAxisSize.min` + `Flexible`/`SingleChildScrollView` (mismo patrón ya usado en `RestoreSheetBody`'s casos `summary`/`done`). `BlockingProgressView`/`IoErrorView` (sin cambios, ya reusables) se envuelven en `IntrinsicHeight` en cada call site del sheet, igual que en Restaurar.

**Pendiente, alcance menor, fuera de esta pasada:** el error de "archivo ilegible o vacío" (`a5XdP`/`qWIvy`) que puede ocurrir en `ImportFlowPage` **antes** de que exista una página de wizard montada (falla el parseo del CSV justo tras elegir el archivo, con `step` todavía en `fileSelect`) sigue renderizándose inline sobre un `Scaffold` en blanco, no en una hoja — a diferencia del error de escritura del commit final (`TmHSC`/`HbEJc`), que sí vive en `ImportRunSheet`. Mismo hallazgo estructural, pero de alcance menor (una sola pantalla transitoria) y no cubierto por esta pasada.

### Export (HU-01/HU-02)

| Estado | Claro | Oscuro |
|---|---|---|
| Seleccionar y filtrar | `zFLrC` | `s9NCmn` |
| Filtros atenuados (toggle "Transacciones" apagado) | `h6ZQQw` | `WKcmI` |
| Vacío (usuario sin transacciones) | `calDR` | `L4eJG` |

### Progreso y errores — patrón único compartido (HU-09)

| Uso | Claro | Oscuro | Notas |
|---|---|---|---|
| Progreso — Importando | `d9wzVg` | `VHJP8` | Patrón base documentado en su `context`. |
| Progreso — Exportando | `xdG9q` | `dSkbx` | Copia fiel de `d9wzVg`/`VHJP8`; solo cambian ícono (`file-spreadsheet`/`$sky`) y título. |
| Progreso — Restaurando | *(no dibujado)* | *(no dibujado)* | Mismo patrón; cambiar ícono a `$teal` y título al instanciar en Flutter, en ambos temas. |
| Error — archivo ilegible/vacío | `a5XdP` | `qWIvy` | |
| Error — sin espacio/permiso denegado | `TmHSC` | `HbEJc` | |

## Componentes creados para esta feature

**`sOBO3` — Column Mapping Row.** Fila de mapeo de columnas (HU-05/HU-06). Overrides: Source (columna detectada), Badge (`Obligatorio`/`Opcional`, en `$segment-inactive-text` sobre `$muted` — nunca `$text-secondary`, insuficiente en ese par), Value (campo destino), Preview (solo campos con formato: fecha/monto/tipo).

**`J2L8Z` — Destination Resolve Row.** Fila de resolución de destino (HU-06). Toggle "Crear nueva"/"Mapear a existente" con padding vertical `[14,8]` (mínimo 44pt de alto — no `[10,8]`, que da 36px y falla el tap target). Overrides: Icon, Name, fill de cada segmento del toggle, Mapped Box (solo si "Mapear a existente" está activo).

**Picker de "Mapear a existente" — decisión por tipo de destino (2026-08-06):** para **categorías**, la hoja debe instanciar `Category Select Sheet` (`SfSln`) tal cual — ya resuelve título, búsqueda, jerarquía padre/subcategoría y selección única, exactamente el contrato de este flujo. **No** usar una lista genérica ad-hoc para categorías (bug real encontrado en producción: `ExistingDestinationPickerSheet` con `SheetActionRow.bare` no tiene jerarquía ni íconos, y produjo un overflow visible). Para **cuentas** y **etiquetas** (sin selector propio equivalente en el sistema), `ExistingDestinationPickerSheet` sigue siendo válido.

**`zAusB` — Import Preview Row.** Fila con checkbox de la vista previa final (HU-06/HU-07). Candidatos a duplicado: checkbox desmarcado por defecto. Filas inválidas: `Leading` reemplazado por completo (`Replace()`) con ícono `circle-x` en `$expense-text`, no interactivo — **nunca** dejar el checkbox por defecto en una fila inválida, se lee como seleccionable cuando no lo es.

**`U62qV` — Stat Chip.** Chip compacto de estadística (vista previa de import, resumen de copia). Overrides: Value, Label.

**`GhK9z` — Disclosure Row.** Bloque secundario expandible para filas inválidas/advertencia, usado cuando la jerarquía da protagonismo a los duplicados (Var 2 elegida). Header siempre visible (ícono+label+chevron). Colapsado por defecto: `Detail Slot enabled:false` + `chevron-down`; expandido: `enabled:true` + `chevron-up`. **El mockup de `ScJz3` lo muestra expandido solo para exhibir contenido — el estado real por defecto es colapsado.**

**`czuGE` — Import Batch Row** (extendido, no creado desde cero). Layout `none` con posicionamiento absoluto (no horizontal — cambio estructural deliberado): ícono 40×40, `Mid` (nombre+meta) con ancho fijo, chevron, y `Badge` opcional flotando en la esquina superior derecha (`enabled:false` por defecto). Card 92px de alto. Badge en fill `$segment-inactive-text` (nunca `$text-secondary`, insuficiente sobre `$muted`). **Contrato de texto:** el nombre de archivo no tiene tope de longitud, va siempre en 1 línea con `TextOverflow.ellipsis` (Pencil no dibuja `…`, el corte a hueso en el canvas es limitación conocida de la herramienta, no defecto de diseño).

## Reglas por pantalla

### Color y semántica

- **Paleta semántica fija de la feature:** `$mint` = importar/entrada, `$sky` = exportar CSV, `$teal` = copia local/restaurar. `$primary` (violeta) queda reservado a "nube" y no aparece en ningún elemento propio de esta feature.
- **Tokens de fill vs. `-text`:** cualquier texto o ícono que necesite el tono de una familia semántica usa su variante `-text` (`$mint-text`, `$expense-text`, `$amber-text`, `$segment-inactive-text`), nunca el token de fill plano — el fill está calibrado para superficies/íconos grandes, no para texto a 12-15px. Este error se repitió varias veces durante el diseño (badge de `Import Batch Row`, badge de `Column Mapping Row`, CTA "Importar todos" de `ScJz3`) — token nuevo creado por esta razón: **`$mint-text`** (`#047857` claro / `#34D399` oscuro, mismo patrón que `expense-text`/`income-text`/`amber-text`).
- **Estados inertes/deshabilitados:** `$muted` de fondo + `$segment-inactive-text` de contenido (checkbox vacío, CTA deshabilitado). Nunca opacidad cruda sobre texto pequeño como sustituto de contraste real — probado en `h6ZQQw` con `opacity:0.45` (contraste resultante ~1.8:1, ilegible); la opacidad aceptable sobre un bloque de controles atenuados es **~0.6**, no menos (el mismo valor 0.6 funciona igual de bien en oscuro que en claro — verificado que no degrada peor, ~2.32:1 claro vs. ~3.13:1 oscuro contra `$background`, ninguno de los dos alcanza AA de texto normal pero es aceptable por tratarse de un bloque explícitamente no-interactivo, WCAG 1.4.3).
- **Iconografía de estados vacíos:** `Empty State` (`jmQO5`) hereda violeta por defecto (`$primary-soft`/`$primary-on-soft`) — en esta feature **siempre** hay que sobrescribir a un par neutro (`$muted` + `$text-secondary`, mismo patrón que `Error State`), porque el violeta se leería como señal de "nube" en una pantalla 100% local. Aplicado en `tiCoZ`/`q2QLzl` y `calDR`/`L4eJG`.
- **Confirmaciones destructivas** (Reemplazar todo al restaurar): `$expense`/`$expense-soft`/`$expense-text`, con ícono `replace` (no `trash-2` — no se elimina nada, se reemplaza; tampoco `refresh-cw`, que se lee como "sincronizar").
- **Un mismo par de tokens no garantiza el mismo contraste en los dos temas.** Dos regresiones encontradas solo al construir el oscuro, ambas con causa distinta:
  - El link "Ver todas" del componente compartido `Section Header` (`E2pvO`, usado también fuera de esta feature: Inicio, Presupuesto, Diagnóstico) traía por defecto `$primary-on-soft` — pasable en oscuro (~6.7:1) pero **~2.47:1 en claro**, ilegible. No era un problema de esta feature en particular, pero se corrigió a nivel de componente porque solo se detectó al auditar el par oscuro. Fix: `$text-secondary` (4.81:1 claro / 6.55:1 oscuro) en vez de violeta — también resuelve la regla de "cero `$primary`" de esta feature.
  - El `Choice Toggle` ad-hoc de `uUGXf`/`weAqZ` (segmento activo `$surface` sobre contenedor `$muted`) funciona en claro pero da **~1.09:1 en oscuro** (los dos tonos casi se funden). `$border` tampoco habría servido (~1.07:1). Fix aplicado solo en la instancia oscura: `stroke:"$text-secondary"` en el segmento activo → ~5.39:1.
  - **Consecuencia práctica:** cuando el segmento activo de un toggle o el link de una sección dependen solo de la separación de luminancia entre dos superficies (no de un color con su propio contraste calculado), hay que medir el par en los dos temas por separado — no basta con que el claro se vea bien.

### Comportamiento

- **Confirmación escalonada nunca es un solo "OK".** El gate de "Reemplazar todo" (HU-04) tiene checkbox de reconocimiento que debe marcarse antes de habilitar el CTA destructivo — ambos extremos están dibujados (`MjNwC` confirmado, `NY5o6` inerte) porque es una decisión de interacción crítica que no debe quedar implícita para `flutter-dev`.
- **Progreso bloqueante, no un sheet dismisible cualquiera.** Mientras `d9wzVg`/`xdG9q` corren, el scrim y el gesto de retroceso quedan **desactivados** — la única salida es "Cancelar", que además borra el archivo parcial ya escrito (mismo criterio que HU-01/HU-03: nunca dejar un archivo a medias).
- **Duplicados vs. inválidas nunca comparten tratamiento visual.** Un duplicado es una decisión del usuario (checkbox interactivo, desmarcado por defecto); una fila inválida no es seleccionable (ícono de error, no checkbox) — confundir los dos genera la falsa impresión de que una fila ya excluida puede "incluirse".
- **El resumen final siempre expone el motivo de lo omitido**, no solo el conteo — el CTA que lleva al detalle debe decirlo explícito ("Ver 3 omitidas y por qué"), igual criterio que "Ver 3 filas con error" en la vista previa. Un botón genérico "Ver detalles" no comunica que ahí están las causas.
- **La sección de filtros de export solo tiene efecto si "Transacciones" está marcado** (`zFLrC`) — su estado atenuado (`h6ZQQw`, toggle OFF) debe quedar también no-interactivo en Flutter, no solo atenuado visualmente.
- **Estados vacíos son contenido, no error.** "Aún no has importado nada" / "Todavía no tienes movimientos para exportar" — tono neutro, sin ícono de alarma, `Empty State` con CTA oculto (no deshabilitado-visible) cuando no hay ninguna acción posible desde ahí.
- **"Sin copia previa" tampoco es un estado async ni de error** (`qDCvi`) — es contenido: guardar una copia es opcional, y no haberlo hecho todavía no es una falla del usuario.
- **CTA destructivo con label largo:** si un botón dentro de `Sheet Buttons Row` no cabe en su mitad de 169px (ej. "Deshacer importación"), apilar verticalmente en esa instancia en vez de reducir fuente o quitar el ícono — prioriza legibilidad completa sobre mantener el 50/50 por defecto.

## Notas de accesibilidad (verificadas por `ui-ux-reviewer`)

- Contraste `$mint-text` sobre `$background`: ~5:1 (vs. ~3.4:1 de `$mint` crudo, bajo AA).
- Contraste `$segment-inactive-text` sobre `$muted`: ~5.3-5.46:1, el par correcto para labels apagados — `$text-secondary` sobre `$muted` mide ~4.55:1, al filo del mínimo sin margen.
- Tap targets: toggles de resolución de destino y de plantilla ≥44pt (corregido de 36px); acciones en bloque ("Omitir todos"/"Importar todos") ≥44pt (corregido de ~15px de alto real); CTAs de `Sheet Buttons Row` ~49px.
- Ícono de estado vacío en `$text-secondary` sobre `$muted`: ~4.56:1, sobre el mínimo 3:1 de objeto gráfico.

## Notas de UX review cerradas (2026-07-29)

- **`ScJz3` (Vista previa final) es la variante elegida y aprobada**, ganadora entre 4 exploraciones (original + 3 variantes de layout: tabs, jerarquía por severidad, checklist unificado). Las 3 descartadas se borraron del canvas por completo.
- **Toggle de `Destination Resolve Row` corregido a 44pt** (era 36px), mismo criterio ya aplicado antes en `Segmented Control`.
- **CTA "Reemplazar todo" cambiado de ícono `trash-2` → `replace`**, tras evaluar también `refresh-cw` (descartado, se lee como "sincronizar").
- **`Import Batch Row` reestructurado** de layout horizontal a posicionamiento absoluto para poder ubicar el badge "Revertida" en la esquina sin empujar/cortar el texto del nombre de archivo.
- **Texto de ejemplo de `Column Mapping Row` corregido** para mostrar encabezados crudos de CSV reales (`FECHA_MOV`, `MONTO_COP`, etc.) mapeados a su campo canónico — el texto anterior (`"Columna: Fecha"` → `"Campo: Fecha"`) no demostraba el valor real del mapeador.
- **Card de vista previa en vivo reubicada** en `drEA1`: estaba `fully clipped` al fondo del scroll; HU-05 exige que sea visible mientras el usuario hace sus elecciones de mapeo.

## Pendientes

- **Progreso "Restaurando"** no se dibujó como frame propio, en ningún tema — es el mismo patrón de `d9wzVg`/`xdG9q` (y sus pares oscuros `VHJP8`/`dSkbx`), solo cambiar ícono a `$teal` y título al implementar.
- **Interacciones no diseñadas en Pencil** (quedan para `flutter-dev`, documentadas en el `context` de cada frame): apertura real de los sheets de filtro de export (cuenta/categoría/tipo/etiqueta/texto) y del selector de rango de fechas — reusan los sheets ya diseñados en Transacciones; animación de expandir/colapsar `Disclosure Row`; habilitación del CTA de confirmación de reemplazo al marcar el checkbox (transición entre `NY5o6` y `MjNwC`).
- **Selector de archivo nativo del SO** no se diseña (es del sistema operativo) — `W2hiZK` solo dibuja la hoja de entrada que lo dispara.

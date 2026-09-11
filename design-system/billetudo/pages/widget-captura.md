# Página: Widget de captura rápida

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Requisitos: `docs/requirements/fase-2/20-widget-captura-rapida.md`.

> **Documento de backfill** — el diseño se implementó antes de pasar por el flujo diseño-primero de `CLAUDE.md` (el requisito pedía `pencil-designer` -> variantes en `billetudo.pen` -> elección del usuario -> este `.md` -> refinamiento auditado -> tema oscuro). Ese orden se saltó: el widget se construyó directo en código nativo (Android + iOS). Este documento describe **el resultado tal como quedó implementado**, no una decisión de diseño tomada de antemano en Pencil. **No existen frames del widget en `billetudo.pen`** (verificado con búsqueda por nombre sobre el árbol completo del `.pen`: cero coincidencias de "widget"/"captura rápida"/"quick capture") — la fuente de verdad visual para esta pieza es, por ahora, el código nativo, no el `.pen`.

## Estado

**Backfill, no diseño aprobado.** Nadie evaluó variantes ni aprobó explícitamente esta composición como se pide en el flujo normal. Es una fotografía de lo construido, con los hallazgos reales marcados como pendientes de decisión más abajo.

## Alcance (recordatorio del requisito)

Atajo puro: fila de botones que abren la app en un destino de captura, sin datos financieros, sin refresco, sin App Group. Android = `AppWidgetProvider`/`RemoteViews` (`android/app/src/main/kotlin/com/billetudo/app/widget/`); iOS = WidgetKit (`ios/QuickCaptureWidget/`).

## Colores

Ambas plataformas replican los tokens de `billetudo.pen` como recursos nativos por tema — verificado hex a hex contra `GetVariables()`, **coinciden exactamente en las dos plataformas y en ambos temas**:

| Token del sistema | Claro | Oscuro | Android (`values/colors.xml` / `values-night/colors.xml`) | iOS (`Assets.xcassets`) |
|---|---|---|---|---|
| `$surface` | `#FFFFFF` | `#1E1E2E` | `widget_surface` OK | `WidgetSurface` OK |
| `$border` | `#ECEBF3` | `#2A2A3D` | `widget_border` OK | sin equivalente en iOS - ver nota |
| `$primary` | `#6C5CE7` | `#6D4FE0` | `widget_primary` OK | `WidgetPrimary` OK |
| `$on-primary` | `#FFFFFF` (fijo) | - | `widget_on_primary` OK | `WidgetOnPrimary` OK |
| `$text-primary` | `#1C1B29` | `#F4F3FA` | `widget_text_primary` OK | `WidgetTextPrimary` OK |
| `$text-secondary` | `#6B6980` | `#9A98B5` | `widget_text_secondary` OK | sin equivalente en iOS - no se usa, todos los labels van en `$text-primary` |

**Sobre la discrepancia reportada de `widget_primary` (`#FF6D4FE0` en `values-night/colors.xml`): no es una deriva.** Es una lectura errónea comparar ese valor contra `$primary` **claro** (`#6C5CE7`) — el archivo que lo define es explícitamente el tema **oscuro** (`values-night`), así que el comparador correcto es `$primary` **oscuro**, que en `billetudo.pen` es exactamente `#6D4FE0` (ignorando el canal alfa `FF` que Android antepone). Es una coincidencia hex perfecta con el token correcto, no un ajuste de contraste paralelo ni un valor inventado. **Conclusión: coincidencia correcta, no hay decisión pendiente aquí.** (Confirmado también en iOS: `WidgetPrimary.colorset` usa el mismo par `#6C5CE7`/`#6D4FE0`.)

**Nota real (menor):** iOS no tiene un `WidgetBorder`/`WidgetTextSecondary` — el fondo del widget en iOS no lleva stroke (se apoya en la forma que el propio sistema le da al widget) y ningún label usa texto secundario. Es una asimetría real entre plataformas, pero no rompe ningún token (simplemente no usa esos dos), así que no se marca como bloqueante — se deja anotada por si alguna vez se decide dar borde también en iOS.

Ningún hex está hardcodeado sin comentario de a qué token corresponde — ambas plataformas documentan la réplica en el propio archivo de colores/estilos.

## Tamaños y comportamiento de recorte (Android, HU-06)

- `quick_capture_widget_info.xml`: `minWidth="110dp"`, `minHeight="60dp"`, `maxResizeWidth="320dp"`, `maxResizeHeight="110dp"`, `resizeMode="horizontal"`, `updatePeriodMillis="0"` (sin refresco periódico, correcto para un atajo sin datos).
- **Un solo layout** (`widget_quick_capture.xml`, fila horizontal de hasta 4 bloques icono+label) que `QuickCaptureWidgetProvider.onAppWidgetOptionsChanged` reduce dinámicamente según `OPTION_APPWIDGET_MIN_WIDTH`:
  - `< 130dp` -> 1 atajo visible.
  - `130-199dp` -> 2 atajos.
  - `200-269dp` -> 3 atajos.
  - `>= 270dp` -> 4 atajos (fila completa).
  - Orden de prioridad de conservación: Gasto -> Ingreso -> Voz -> Pendientes (el primero es el último en desaparecer).
- Esto cumple la exigencia de HU-06 de "degradar por ancho disponible, nunca apretar por debajo del área tocable mínima" — cada bloque (`WidgetShortcut`) reserva `minWidth 64dp` / `minHeight 48dp`, por encima del mínimo de 44pt.
- **No hay dos layouts discretos "compacto 2x1" / "mediano 4x2"** como sugiere la redacción del requisito — hay un único layout continuo que oculta/muestra bloques. Es una implementación válida de la misma exigencia (degradar por ancho), documentada aquí porque el `.md` original describía dos variantes y el código entrega un comportamiento continuo en su lugar.

## Tamaños (iOS, HU-06)

- `systemSmall`: un solo atajo fijo ("Gasto"), toda la superficie es un único `Link` — coincide con la restricción real de la plataforma (un solo destino sin App Intents de iOS 17+).
- `systemMedium`: fila de los 3 atajos disponibles en iOS (Gasto, Ingreso, Voz — sin Pendientes, ver abajo), cada uno con su propio `Link`.
- `systemLarge`: fuera de alcance, no declarado en `.supportedFamilies`.

## Atajos implementados vs. los del requisito (HU-02)

| Atajo | Android | iOS | Nota |
|---|---|---|---|
| Gasto | si | si | |
| Ingreso | si | si | |
| Voz | si | si | |
| Pendientes (bandeja bancaria) | si | no | Correcto: Android-only por diseño (HU-02), la ausencia en iOS no es un bug. |
| **Foto (OCR)** | **no** | **no** | **No implementado en ninguna plataforma.** El requisito (HU-02) lo lista junto a Voz/Ingreso como atajo esperado. Consistente con el estado del repo: `18-captura-ocr.md` (Fase 2) aún no está implementado (`lib/features/capture/` solo tiene `.gitkeep`), así que no había destino al que enlazar. No es una regresión de diseño — es una entrega parcial de HU-02 pendiente de completarse cuando OCR exista. **Pendiente de decisión del usuario:** si se documenta como "entrega incremental aceptada" o si se considera que el widget no debía entregarse antes de que sus 3 destinos de captura (voz, foto, notificaciones) existieran, tal como advierte el propio requisito en §Entrega ("Requisito previo: que existan los destinos"). |

## Configurabilidad de atajos (HU-03)

**No implementada.** `quick_capture_widget_info.xml` no declara `android:configure` (sin *configuration activity*); iOS no expone parámetros seleccionables por el usuario para el widget. El orden y conjunto de atajos está **hardcodeado** (`SHORTCUT_VIEWS` en `QuickCaptureWidgetProvider.kt`, `QuickCaptureShortcut.allCases` en Swift) — el usuario no puede elegir ni reordenar. **Pendiente de decisión del usuario:** HU-03 es un criterio de aceptación explícito del requisito, no una nota "opcional"; si se acepta el hardcodeo como entrega inicial hace falta decir cuál es el default fijo (ya lo hay, de facto: Gasto/Ingreso/Voz/Pendientes en ese orden) y dejar la configurabilidad como trabajo futuro, o completarla antes de considerar la feature cerrada.

## Tipografía

- **Android:** un solo peso empaquetado, `plus_jakarta_sans_semibold.ttf` (`res/font/`), aplicado vía `android:fontFamily` en `WidgetShortcutLabel` (12sp). No se referencia por `fontWeight` (no aplica en `RemoteViews`/XML clásico) sino por el archivo de fuente directo — coherente con que el widget solo necesita un peso.
- **iOS:** la misma fuente bundleada como recurso de la extensión (`PlusJakartaSans-SemiBold.ttf`, declarada en `UIAppFonts` del `Info.plist` de `QuickCaptureWidget`), aplicada a 13pt (`QuickCaptureTypography.label`). El fallback a fuente de sistema documentado en el requisito no se necesitó: la fuente se registró.
- **Diferencia de tamaño entre plataformas (12sp Android vs. 13pt iOS):** menor, dentro de rango idiomático de cada plataforma para un caption/label de widget — no se marca como inconsistencia bloqueante, pero no está escrita en ningún lado como decisión consciente; queda anotada.
- **Nota de accesibilidad (menor):** el label de cada atajo ("Gasto", "Voz"...) es, junto al ícono, el único contenido textual del bloque — no es metadata secundaria, es la etiqueta primaria de una acción. `MASTER.md` reserva 11-12px "solo para metadatos secundarios, nunca para contenido primario". 12sp/13pt está en el límite de esa franja. No se recomienda subir el tamaño dado el espacio real de un widget de home screen (compite con otros íconos), pero se documenta la tensión en vez de callarla.

## Textos y localización (HU-09)

- **Mecanismo:** recursos nativos duplicados respecto a los `.arb`, tal como anticipa el requisito — Android `res/values/strings.xml` (español, sin calificador, es el idioma por defecto de la app) + `res/values-en/strings.xml`; iOS `es.lproj/Localizable.strings` + `en.lproj/Localizable.strings`. El widget sigue el idioma del sistema en ambas plataformas (mecanismo nativo estándar, sin lógica propia).
- **Seis etiquetas** (nombre del widget, descripción, y pares label/a11y — Android incluye el par de Pendientes que iOS no tiene):
  - `widget_quick_capture_name` = "Captura rápida" / "Quick capture"
  - `widget_quick_capture_description` = "Registra un movimiento en un toque, sin abrir la app." / "Log a movement in one tap, without opening the app."
  - Gasto/Expense, Ingreso/Income, Voz/Voice, y solo en Android: Pendientes/Pending.
  - Cada atajo lleva además su descripción de accesibilidad genérica (ej. "Registrar un gasto"), nunca datos (cumple HU-08).
- **Nada de literales sueltos** en el layout Android (`@string/...` en todo el XML) ni en las vistas SwiftUI (`LocalizedStringKey`).
- Los tres juegos de strings (Android es/en + iOS es/en) están sincronizados hoy — quedan comentados de forma cruzada ("al cambiar una etiqueta hay que cambiarla en los tres sitios") para que no se desincronicen en el futuro, pero no hay ningún mecanismo automático que lo garantice; es un acuerdo de comentario, no una prueba.

## Composición visual

- Fondo opaco `$surface` + borde 1dp `$border` + radio 24dp (Android; iOS usa el fondo del sistema sin stroke propio) — dentro del rango "radio grande" de `MASTER.md` (24-28px), coherente con leer el widget como una tarjeta de marca.
- Cada atajo: ícono en círculo sólido `$primary` (44x44 en total con el label debajo) + label 12-13px semibold `$text-primary`. Sin fondo `-soft`, sin degradado — más simple que los patrones de icon-wrap del resto del sistema (ej. `Category Row` usa `-soft` + color de categoría), pero razonable dado que aquí no hay una paleta de categorías que comunicar, solo 4 acciones fijas con significado semántico propio (no de categoría).
- Tono: ninguna etiqueta usa lenguaje de alarma ni `$expense` (rojo) — cumple la regla de tono de `CLAUDE.md`/MASTER de no punir el gasto. No hay superficie aquí donde esa trampa pudiera aparecer (el widget no muestra cifras).

## Pendiente

**De diseño (sin frame en Pencil):** todo — no existe ninguna variante de este widget en `billetudo.pen`. Si se retoma el flujo correcto, correspondería a `pencil-designer` construir ahí las variantes (Android compacto/mediano, iOS small/medium, claro y luego oscuro) contra este backfill como punto de partida, no desde cero.

**Pendiente de decisión del usuario (hallazgos reales, no de proceso):**
1. **Atajo "Foto" (OCR) ausente en ambas plataformas** — HU-02 lo pide, no está implementado en ninguna, y el destino (`18-captura-ocr.md`) tampoco existe todavía en `lib/`. Decidir si se documenta como entrega incremental o si se reabre HU-02 al completar OCR.
2. **HU-03 (configurar el conjunto/orden de atajos) no está implementada** — ni configuration activity en Android ni parámetros equivalentes en iOS. El conjunto actual (Gasto, Ingreso, Voz, Pendientes en ese orden) es un default de facto, no una elección declarada.
3. **Asimetría menor iOS sin `$border`/`$text-secondary`** — no rompe ningún token, pero es una divergencia de tratamiento visual entre plataformas no documentada como decisión previa.

**No es un hallazgo:** la discrepancia de `widget_primary` en `values-night/colors.xml` — es una coincidencia exacta con `$primary` oscuro (`#6D4FE0`), ver sección Colores arriba.

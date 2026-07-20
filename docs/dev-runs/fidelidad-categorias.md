# Fidelidad visual — Categorías

Corrida `/design-fidelity-check categorias` (2026-07-20), ítem 3 de `docs/bugfixes.md`.
2 pasadas de `pencil-fidelity-reviewer`, con fixes de `flutter-dev` entre ambas.

## Ronda 1 — auditoría inicial (156 goldens)

4 hallazgos **CRÍTICO**, 2 **IMPORTANTE**, 1 **MENOR**:

1. `Page Header` ausente en 8 pantallas (`categories_page` ×4 estados, `category_form_page`
   ×4 variantes) — usaban `AppBar` de Material genérico en vez del componente `Dtm0X`. El propio
   `categorias.md` decía que el listado era "la excepción parcial" sin `Page Header`, pero el
   `.pen` real (`bA51N`) sí lo instancia completo — el `.md` estaba desactualizado, se corrigió.
2. Campo "Tipo" del formulario reconstruido a mano (`CategoryKindOption`, dos cajas con borde)
   en vez de reusar `Segmented Control` (`hFu41`), pese a que `categorias.md` documenta
   explícitamente que ese componente se comparte entre Categorías y Transacciones.
3. Sheet "Confirmar eliminar sin dependientes" con ícono/botón rojo (`triangle-alert`,
   `$expense`) — el `.pen` (`jngMo`) especifica violeta (`trash-2`, `$primary`/`$primary-soft`)
   porque el borrado es reversible vía papelera, no destructivo.
4. Título en negrita separado + subtítulo genérico (sin nombre real de categoría) en los sheets
   "con transacciones" y "raíz con subcategorías" — Pencil solo diseña un mensaje único
   interpolado con nombre y conteo reales.
5. Link "Eliminar categoría" nunca cambiaba a "Eliminar subcategoría" pese a que la clave l10n
   ya existía y se usaba correctamente en otro sheet.
6. Subtítulo explicativo faltante en el selector de categoría padre.
7. Label de "Apariencia" no variaba entre "Elegir ícono y color" (vacío) e "Ícono y color" (con
   selección).

**Buena noticia confirmada en esta misma ronda**: el bloqueo documentado desde
`bug-fixes-pixel-audit.md` ("catálogo de íconos diverge 15/32 entre Pencil y código") ya no
aplica — comparado línea por línea, `category_appearance.dart` es idéntico al catálogo vigente
del `.pen` (64 íconos). Cerrado en `bug-fixes-pixel-audit.md` y `fidelidad-visual-tracking.md`.

## Ronda 1 — fixes

- `categories_page.dart`/`category_form_page.dart`: `AppBar` → `PageHeader` real.
- `CategoryKindToggle` (nuevo, compartido): envuelve `SegmentedControl<CategoryKind>`; tanto el
  listado como el formulario lo usan ahora, eliminando la duplicación anterior
  (`CategoryKindSegment`/`CategoryKindOption`). `SegmentedControl` ganó un parámetro `enabled`
  para el candado condicional del formulario (subcategoría / raíz con hijas activas).
- `confirm_delete_simple_sheet.dart`: ícono `trash-2` + botón en violeta, copy corregido.
- `confirm_delete_with_transactions_sheet.dart`/`confirm_delete_root_with_subcategories_sheet.dart`:
  sin título separado, mensaje único con `categoryName`+conteo interpolados (requirió agregar
  `subcategoryCount` a `CategoryDeletionImpact`, poblado en el repositorio).
- Link "Eliminar (sub)categoría" condicional a `state.isSubcategory`.
- Label de Apariencia condicional al mismo estado que ya controlaba el sublabel.
- `parent_category_picker_sheet.dart`: subtítulo agregado.
- `qa-automator`: goldens regenerados (156 tests), tests rotos por cambios de firma
  (`categoryName`/`subcategoryCount` requeridos) corregidos, más un gap real de test detectado
  (viewport insuficiente para 6 `Skeleton Row` tras crecer el header — no era bug de `lib/`).

## Ronda 2 — re-verificación

**Fiel a Pencil.** Los 7 hallazgos confirmados resueltos contra sus nodeId reales, sin
regresiones ni hallazgos nuevos de severidad CRÍTICO/IMPORTANTE. Un solo punto MENOR/observación
sin acción requerida: el color ilustrativo del ícono en el estado "bloqueado/heredado" del picker
difiere entre el mockup estático (sky) y el golden con datos reales (coral, heredado de la
categoría padre real del fixture) — comportamiento correcto, solo cambia el dato de ejemplo.

## Veredicto final

**✅ Aprobada.** Reviews finales (finance-code-reviewer, ui-convention-reviewer,
compliance-reviewer): sin hallazgos.

### Gap de cobertura conocido, no bloqueante

`sheet_parent_category_picker_loading_*`/`empty_*`: estados sin frame de referencia en Pencil
(el `.pen` solo diseña el picker con candidatos ya cargados). No bloquea el cierre — el diseño
nunca se maquetó para esos casos.

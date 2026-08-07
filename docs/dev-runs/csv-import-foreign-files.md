# Importar CSV de apps externas (csv-import-foreign-files)

## Objetivo y criterios de aceptación

Corregir el flujo "Importar desde un CSV" (HU-05/HU-06) para que soporte CSVs reales de otras apps (ej. Wallet/BudgetBakers): tolerar fechas con sufijo de hora, dejar de autodetectar un mapeo "completo" falso cuando los valores reales de la columna tipo no coinciden con el vocabulario propio (con su efecto colateral: el paso de destinos mostraba "todo coincide" aunque el 100% de filas fuera inválido), y agregar el toggle Automático/Manual con las 3 hojas de configuración (formato de fecha, convención decimal, valores de tipo/signo) que HU-05/HU-06 ya pedían pero no estaban implementadas, con vista previa en vivo en cada una.

12 AC cubiertos (detalle completo en "Tests" abajo):

1. `CsvDateParser.parse` acepta un sufijo de hora separado por espacio sin cambiar el comportamiento para celdas sin hora.
2. `AutodetectColumnMapping` valida los valores de muestra antes de fijar `typeValues` por coincidencia de encabezado.
3. Una columna tipo mal autodetectada ya no produce `invalidType` en el 100% de las filas; cae al fallback de signo del monto.
4. El paso de destinos distingue "todo coincide" de "100% inválido".
5. Toggle Automático/Manual en `import_mapping_step.dart`.
6. Hoja de formato de fecha (`DateComponentOrder` × `DateSeparatorChar`) con vista previa en vivo.
7. Hoja de convención decimal (punto/coma) con vista previa en vivo.
8. Hoja de tipo/signo (columna de tipo con literales editables vs. signo del monto) con vista previa en vivo.
9. `ImportFlowCubit` expone lo nuevo sin romper `setFieldForColumn`/`setDialect`/`setTypeValues` existentes.
10. HU-04 "Restaurar desde una copia" permanece intacto (ningún archivo `restore_*`/`save_copy_*`/`backup_*` tocado).
11. Tests unitarios nuevos para el bug de fecha con hora y el de autodetección falsa (fixture sintético, no el CSV real del usuario).
12. `flutter analyze` y la suite de import_export (unit + widget + golden) en verde, con goldens nuevos en tema claro primero.

Tamaño: m · Review: combined **APROBADO**.

## Qué cambió (archivo → qué)

| Archivo | Qué |
|---|---|
| `lib/features/import_export/data/models/csv_date_parser.dart` | Corta la celda en el primer espacio antes de parsear la fecha; tolera sufijo de hora. |
| `lib/features/import_export/domain/usecases/autodetect_column_mapping.dart` | Acepta `sampleRows`; valida (case-insensitive) que al menos una fila de muestra coincida con income/expense/transfer del vocabulario antes de fijar la columna tipo. Si ninguna coincide, la columna queda sin mapear. |
| `lib/features/import_export/presentation/cubit/import_flow_cubit.dart` | Pasa `sample.sampleRows` al usecase; agrega `setMappingMode`, `applyDateFormat`, `applyDecimalConvention`, `applyTypeColumn`, `applyAmountSignMode` (aditivo, sin tocar los métodos existentes). |
| `lib/features/import_export/presentation/cubit/import_flow_state.dart` | Nuevo campo `mappingMode` (default automático, se resetea en cada carga de archivo). |
| `lib/features/import_export/domain/entities/import_mapping_mode.dart` | Enum nuevo `ImportMappingMode` (automatic/manual). |
| `lib/features/import_export/presentation/widgets/import_mapping_mode_toggle.dart` | Toggle segmentado, reutiliza `SegmentedToggleOption` (mismo patrón que `DestinationResolveRow`). |
| `lib/features/import_export/presentation/widgets/sheets/import_date_format_sheet.dart` | Hoja nueva: combinaciones de orden/separador de fecha, resalta la activa, vista previa en vivo con `CsvDateParser`. |
| `lib/features/import_export/presentation/widgets/sheets/import_decimal_format_sheet.dart` | Hoja nueva: punto/coma, vista previa en vivo con `DecimalAmountParser`. |
| `lib/features/import_export/presentation/widgets/sheets/import_type_values_sheet.dart` | Hoja nueva: columna de tipo (literales editables) vs. signo del monto, vista previa en vivo. |
| `lib/features/import_export/presentation/pages/import_mapping_step.dart` | Gate Automático (resumen + confirmar) / Manual (lista existente + 3 campos de formato ahora tocables). De paso corrige un bug latente: leía `sample.dialect` congelado en vez de `state.dialect` en vivo. |
| `lib/features/import_export/presentation/pages/import_destinations_step.dart` | Estado vacío distingue "todo coincide y es válido" de "nada por resolver porque todo es inválido" (icono/copy/CTA "Revisar mapeo" propios). |
| `lib/features/import_export/presentation/widgets/import_flow_body.dart` | Ajustes de orquestación para el nuevo modo de mapeo. |
| `lib/features/import_export/presentation/widgets/automatic_mapping_summary.dart`, `import_format_field.dart`, `import_live_preview_card.dart`, `import_literal_field.dart`, `presentation/utils/date_order_label.dart` | Widgets/utilidades de apoyo nuevos para el resumen automático y las 3 hojas. |
| `lib/core/l10n/arb/app_es.arb`, `app_en.arb` + `lib/core/l10n/gen/*` | Strings nuevas (toggle, hojas, estado "todo inválido"), mismas claves en ambos idiomas, `gen/` regenerado. |
| `test/features/import_export/data/models/csv_date_parser_test.dart` | 5 casos nuevos de sufijo de hora (ISO/DMY/MDY/separador punto/sin sufijo). |
| `test/features/import_export/domain/usecases/autodetect_column_mapping_test.dart` | Fixture sintético con headers propios pero valores ajenos ("Gastos"/"Ingresos"); confirma `typeValues == null` y fallback a signo. |
| `test/features/import_export/presentation/cubit/import_flow_cubit_test.dart` | 5 `blocTest` nuevos para modo mapeo + las 3 hojas; los existentes intactos. |
| `test/features/import_export/presentation/golden/import_flow_page_golden_test.dart` + 3 archivos golden nuevos (`import_date_format_sheet_golden_test.dart`, `import_decimal_format_sheet_golden_test.dart`, `import_type_values_sheet_golden_test.dart`) | Goldens nuevos: toggle (automático/manual), plantilla detectada, destinos 100% inválido, y las 3 hojas (column/sign donde aplica), claro y oscuro. |

Archivos de HU-04 (restore/save_copy/backup) — **no tocados**, verificado con `git status`.

## Tests

Resultado: `flutter analyze` limpio (solo 7 `info` preexistentes ajenos a este cambio) · suite unit+widget+golden de import_export en verde · Patrol e2e pass.

Comandos para re-correr:

```bash
flutter analyze lib/features/import_export test/features/import_export
flutter test test/features/import_export
flutter test test/features/import_export --update-goldens   # solo si hay que regenerar goldens
flutter gen-l10n                                             # si se tocan los .arb
```

Patrol e2e (flavor `dev`, nunca `prod`):

```bash
patrol test --target integration_test/import_export_patrol_test.dart --flavor dev
```

Cobertura AC → test, resumen:

- AC1 → `csv_date_parser_test.dart` (5 casos sufijo de hora).
- AC2/AC3 → `autodetect_column_mapping_test.dart` (fixture sintético headers propios + valores ajenos; `typeValues` null, `hasTypeColumn` false, fallback a signo).
- AC4 → `import_destinations_step.dart` (rama `allInvalid`) + golden `import_flow_page_destinations_all_invalid_{light,dark}.png`; sin unit test puro porque la lógica vive en un `StatelessWidget` (cubierto por widget/golden, aceptable por la jerarquía unit>widget del playbook).
- AC5 → `import_mapping_mode_toggle.dart` + goldens `import_flow_page_mapping_{light,dark}.png` (automático) / `..._manual_{light,dark}.png` (manual) + `blocTest` de `setMappingMode`.
- AC6 → `import_date_format_sheet_golden_test.dart` (claro+oscuro) + `blocTest` `applyDateFormat`.
- AC7 → `import_decimal_format_sheet_golden_test.dart` (claro+oscuro) + `blocTest` `applyDecimalConvention`.
- AC8 → `import_type_values_sheet_golden_test.dart` (column y sign, claro+oscuro) + `blocTest` `applyTypeColumn`/`applyAmountSignMode`.
- AC9 → `group 'mapping mode + format sheets — HU-05/06'` (5 `blocTest` nuevos) + los `blocTest` preexistentes de `setFieldForColumn`/`setDialect`/`setTypeValues` siguen pasando sin modificación.
- AC10 → `git status` confirma cero archivos `restore_*`/`save_copy_*`/`backup_*` tocados.
- AC11 → los dos test files nuevos ya detallados en AC1/AC2.
- AC12 → `flutter analyze` limpio + goldens nuevos listados arriba, todos verdes.

## Fidelidad visual vs Pencil (resultado de esta corrida)

**N/A.** No existe `design-system/billetudo/pages/import_export.md` (Glob sin resultados). Sin ese spec no hay tabla Node ID (Claro)/Node ID (Oscuro) para mapear los goldens de la feature contra `billetudo.pen`, así que no corresponde auditar fidelidad todavía — no es un fallo de la feature ni del pipeline, es que `import_export` aún no pasó por el flujo de diseño documentado (`pencil-designer` + `ui-ux-reviewer` + `pages/<feature>.md`) antes de construirse en Flutter. No se intentó `get_editor_state` porque el bloqueo es previo (falta el mapeo de nodeId); `accessible` queda en `false` por no haberse podido verificar nada contra el `.pen`.

Nota de contexto: `billetudo.pen` sí se consultó (frame `drEA1`) antes de tocar `import_mapping_step.dart` por el gate de Pencil general, pero el toggle y las 3 hojas nuevas no tienen frame dedicado todavía — se construyeron contra componentes/tokens ya aprobados de la feature (`$mint`, `$muted`, `SegmentedToggleOption`, `BottomSheetBase`, `NeutralButton`), no contra un mock que no existe.

## 👤 Verifica a mano

- [ ] Fidelidad visual contra Pencil del toggle Automático/Manual y las 3 hojas nuevas (no diseñadas en `billetudo.pen` todavía, según el propio comentario de `import_mapping_step.dart`) — correr `/design-fidelity-check import_export` o `pencil-designer` para cerrar esa brecha de diseño antes de dar la UI por definitiva.
- [ ] Confirmar en un dispositivo real (no solo emulador) que el teclado no tapa el CTA "Aplicar" de las 3 hojas nuevas al escribir en los `TextField` de `import_type_values_sheet.dart` (patrón "CTA de hoja bajo el teclado" de la memoria del equipo) — el e2e no tecleó en esos campos.
- [ ] Importar manualmente un CSV real de Wallet/BudgetBakers (no el fixture sintético) para confirmar de punta a punta que el flujo (fecha con hora, tipo ajeno, decimal) da un resultado usable.

## Pendientes y riesgos

- **Gap de diseño formalizado:** el toggle Automático/Manual y las 3 hojas nuevas no tienen frame propio en `billetudo.pen`; `design-system/billetudo/pages/import-export.md` ya lo marca en su sección "Pendientes". Recomendado: pasada de `pencil-designer` para formalizarlos y actualizar el `.md`, y solo entonces `/design-fidelity-check import_export`.
- **Cobertura del caso "todo inválido" en `import_preview_step.dart`:** revisado, no necesitó cambio — ya renderiza los chips de estadística (0 se importarán / N errores) y el detalle de filas inválidas sin importar la proporción, así que nunca produce el falso positivo que sí tenía `import_destinations_step.dart`.
- **Desviaciones cosméticas del change map original:** los goldens nuevos viven en `test/features/import_export/presentation/golden/` (convención real ya usada por esta feature) en vez de las rutas `pages/`/`widgets/sheets/` listadas en el plan; `import_type_values_sheet.dart` tiene un widget privado pequeño (`_LiteralField`) en vez de archivo público separado, siguiendo el mismo precedente ya existente en `import_mapping_step.dart` (`_FormatField`/`_LivePreviewCard`).
- **No corrido en esta etapa:** `flutter test` de todo el repo (fuera de alcance, se cerró con analyze/test de lo tocado); `pencil-fidelity-reviewer` / `ui-convention-reviewer` no se invocaron (fuera del rol de este subagente).
- **Sin blockers sin resolver.**

## Mensaje de commit sugerido

```
fix(import-export): soportar CSVs de terceros y agregar modo manual de mapeo

- CsvDateParser tolera fechas con sufijo de hora (ISO/DMY/MDY)
- AutodetectColumnMapping valida valores de muestra antes de fijar
  la columna tipo, evitando el mapeo "completo" falso y el invalidType
  al 100% de filas cuando el vocabulario no coincide
- Paso de destinos distingue "todo coincide" de "100% inválido"
- Toggle Automático/Manual en el paso de mapeo con 3 hojas nuevas
  (formato de fecha, convención decimal, tipo/signo) con vista previa
  en vivo, sin tocar el flujo de Restaurar (HU-04)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
```

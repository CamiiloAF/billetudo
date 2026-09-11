# Aceptación de términos en onboarding (aceptacion-terminos-onboarding)

## Objetivo y criterios de aceptación

Implementar la aceptación versionada de términos de uso y política de privacidad: pie discreto
en Bienvenida, hoja de aceptación que intercepta "Comenzar" y "Ya tengo cuenta", visor nativo de
documento, y re-aceptación cuando cambia la versión vigente — exactamente según
`docs/aceptacion-terminos-onboarding-pendiente.md` y `docs/legal/entrega-de-documentos-legales.md`,
usando los frames ya aprobados en `billetudo.pen` (solo tema claro).

Tamaño: **L** · Review: **deep, APROBADO**.

16 AC cubiertos (detalle en la sección Tests):

1. Pie de Bienvenida con 2 enlaces al visor nativo, sin alterar el resto de la pantalla.
2. "Comenzar" abre la hoja de aceptación antes de navegar a `/bienvenida/cuenta`.
3. "Ya tengo cuenta" abre la misma hoja antes de navegar a `LoginPage`.
4. Aceptar escribe una sola fila/timestamp con la versión REALMENTE mostrada (bundle o cache),
   nunca la del manifiesto si la descarga falló.
5. El visor lee cache primero, bundle como fallback, sin loading/error/empty (síncrono).
6. La línea de versión/fecha del visor corresponde siempre al documento efectivamente renderizado.
7. Los enlaces de Ajustes abren el mismo visor in-app, no `url_launcher`/`LegalUrls`.
8. Re-aceptación solo si `versión_aceptada < versión_vigente` Y `versión_app >= minAppVersion`.
9. La hoja de re-aceptación lista solo los documentos cambiados (singular si es uno).
10. "No acepto" en re-aceptación abre el paso 2 (consecuencia + exportar) con retorno al paso 1;
    exportar funciona sin sesión, sin red, con la app bloqueada.
11. Descarga fallida (manifiesto o documento) con conexión no bloquea el arranque; reintenta luego.
12. Manifiesto ok pero cuerpo de documento nuevo falla → no pide aceptación, no toca la versión.
13. Migración Drift (`schemaVersion`+1) con columnas nuevas de aceptación legal + SQL equivalente
    en `supabase/migrations/`.
14. Todo el texto nuevo sale de `AppLocalizations` (es + en).
15. Tests unitarios: comparación de versión, descarga fallida no bloquea, se guarda la versión
    mostrada (no la del manifiesto), documento no descargable no dispara aceptación.
16. Tests widget/golden: pie, hoja de aceptación, visor, ambos pasos de re-aceptación (multi-doc
    y single-doc), tema claro.

## Qué cambió

| Área | Archivo(s) | Qué |
|---|---|---|
| Esquema | `lib/core/database/app_database.dart` (+`.g.dart` regenerado) | `schemaVersion` 34→35; columnas `legalAcceptedAt`/`legalAcceptedVersion` en `AppSettings` (mismo patrón que `aiConsentAcceptedAt`/`aiConsentVersion`), sin backfill (NULL = "nunca aceptado") |
| Esquema | `supabase/migrations/20260910000000_app_settings_legal_acceptance.sql` | `ALTER TABLE` equivalente (`bigint`, no `timestamptz` — ver Pendientes), aplicado contra dev y prod el 2026-09-11 |
| Sync | `lib/core/database/powersync_schema.dart` | Vista PowerSync de `app_settings` expone las 2 columnas nuevas |
| Domain | `lib/core/legal/domain/{entities,repositories,usecases}/*` | `LegalDocumentKind`, `LegalDocument`, `LegalManifest`; `LegalDocumentsRepository`; casos de uso `GetLegalManifest`, `ResolveLegalDocument`, `ShouldShowReacceptance`, `GetChangedLegalDocuments`, `AcceptLegalDocuments` |
| Data | `lib/core/legal/data/{datasources,repositories}/*` | `LegalManifestRemoteDatasource`, `LegalDocumentsCacheDatasource`, `LegalDocumentsRepositoryImpl` (fallback cache→bundle, sin bloquear arranque) |
| Assets | `lib/core/legal/assets/{politica-de-privacidad,terminos-de-uso}.md` | Bundle empaquetado, versión 1 |
| Settings | `lib/features/settings/{domain,data}/**` | `legalAcceptedAt`/`legalAcceptedVersion`/`markLegalAccepted()` en entidad, repositorio e implementación |
| Presentation | `lib/core/legal/presentation/cubit/legal_acceptance_cubit.dart` (+state) | Resuelve documentos, decide `alreadyAccepted` |
| Presentation | `lib/core/legal/presentation/cubit/legal_reacceptance_cubit.dart` (+state) | Evalúa `ShouldShowReacceptance` una vez por arranque, orquesta pasos 1/2 |
| Presentation | `lib/core/legal/presentation/widgets/{legal_footer_links,legal_text_link,legal_doc_row,legal_section}.dart` | Pie de Bienvenida, fila de documento reutilizable, parser+render de secciones markdown ligero |
| Presentation | `lib/core/legal/presentation/pages/legal_document_viewer_page.dart` | Visor único, `Navigator.push(rootNavigator:true)`, síncrono |
| Presentation | `lib/core/legal/presentation/widgets/sheets/legal_acceptance_sheet.dart` | Hoja compartida Comenzar/Ya tengo cuenta |
| Presentation | `lib/core/legal/presentation/widgets/sheets/legal_reacceptance_{sheet,step1,step2}.dart` | Re-aceptación: paso 1 (multi/single-doc), paso 2 (consecuencia + exportar) |
| Presentation | `lib/core/legal/presentation/widgets/legal_reacceptance_gate.dart` | Envuelve el shell principal, dispara `checkOnLaunch()` |
| Router | `lib/core/router/app_router.dart` | "Comenzar"/"Ya tengo cuenta" pasan por `LegalAcceptanceSheet.showIfNeeded()`; shell envuelto en `LegalReacceptanceGate` |
| Bootstrap | `lib/core/bootstrap.dart` | `refreshFromRemote()` fire-and-forget tras seed de categorías |
| Bootstrap | `lib/core/bootstrap/first_launch_offline_cubit.dart` | `retry()` exitoso también dispara `refreshFromRemote()` |
| Settings UI | `lib/features/settings/presentation/widgets/{ai_settings_section,legal_link_field}.dart` | Enlaces de Ajustes abren el visor in-app en vez de `url_launcher` |
| DI | `lib/core/di/injection.config.dart` (regenerado) | Registro de cubits/casos de uso |
| l10n | `lib/core/l10n/arb/{app_es,app_en}.arb` (+gen) | ~20 claves nuevas (pie, hoja de aceptación, visor, re-aceptación pasos 1/2 multi/singular) |
| pubspec | `pubspec.yaml` | Dependencia agregada para el flujo (paquete de info de versión de la app, ya usado en el proyecto) |

## Tests

Resultado: `dart analyze` limpio · suite dirigida verde (64/64 en `test/core/legal/` tras el fix de
fidelidad) · Patrol confirmado en device real, 2/2 corridas limpias, 3/3 escenarios cada una
(`integration_test/onboarding_patrol_test.dart`, flavor `dev`, incluye el nuevo AC 3 de este
feature) — ver `docs/patrol-e2e-tracking.md`, fila Onboarding, 2026-09-11. La suite completa
`flutter test` de todo el repo no se corrió de punta a punta en esta sesión por contención de
máquina — ver Pendientes.

Comandos para re-correr:

```bash
flutter analyze
flutter test test/core/legal/ test/features/settings/ test/core/bootstrap/ test/core/router/ test/features/onboarding/
flutter test test/core/database/schema_parity_test.dart test/core/l10n/arb_parity_test.dart
flutter test integration_test/onboarding_patrol_test.dart -d <device_id>  # Patrol, flavor dev
```

Cobertura por AC:

- ✅ 1: `test/core/legal/presentation/widgets/legal_footer_links_test.dart` + golden + `integration_test/onboarding_patrol_test.dart`
- ✅ 2: `integration_test/onboarding_patrol_test.dart` + `test/core/legal/presentation/widgets/sheets/legal_acceptance_sheet_test.dart`
- ✅ 3: `integration_test/onboarding_patrol_test.dart` (caso "Ya tengo cuenta")
- ✅ 4: `test/core/legal/domain/usecases/accept_legal_documents_test.dart`
- ✅ 5: `test/core/legal/domain/usecases/resolve_legal_document_test.dart` + `legal_documents_repository_impl_test.dart` + `legal_document_viewer_page_test.dart`
- ✅ 6: `legal_document_viewer_page_test.dart` + golden (variantes bundle/cache)
- ✅ 7: `test/features/settings/presentation/widgets/ai_settings_section_test.dart`
- ✅ 8: `test/core/legal/domain/usecases/should_show_reacceptance_test.dart` (casos de una sola condición)
- ✅ 9: `get_changed_legal_documents_test.dart` + `legal_reacceptance_sheet_test.dart` + golden (step1 both/single)
- ⚠️ 10 (GAP): la mitad UI está cubierta (paso 2 renderiza, "No acepto"/"Volver" invocan el cubit,
  golden step2); falta un test que confirme que "Exportar mis datos" navega de verdad a
  `AppRoutes.exportCsv` y esa página renderiza sin sesión/red con la app bloqueada — requiere un
  `GoRouter` real con el grafo de DI de exportación. Ver checklist manual abajo.
- ✅ 11: `legal_documents_repository_impl_test.dart` (`refreshFromRemote` con manifiesto/cuerpo nulos)
- ✅ 12: mismo archivo, caso `body == null`
- ✅ 13: `app_database.dart` (schemaVersion 35) + migración SQL + `schema_parity_test.dart`
- ✅ 14: `.arb` es/en + `arb_parity_test.dart`
- ✅ 15: `should_show_reacceptance_test.dart`, `legal_documents_repository_impl_test.dart`, `accept_legal_documents_test.dart`
- ✅ 16: goldens de pie/hoja de aceptación/visor/re-aceptación (multi y single-doc) en
  `test/core/legal/presentation/golden/`, todas generadas en `Brightness.values` (claro+oscuro,
  aunque el AC solo pedía claro)

## Fidelidad visual vs Pencil

**Auditada manualmente el 2026-09-11** (el checker automático de `/design-fidelity-check` la marcó
N/A porque busca `lib/features/<feature>/` y esta feature vive en `lib/core/legal/`; se invocó
`pencil-fidelity-reviewer` a mano apuntándolo a los goldens y nodeIds correctos). Cruce hecho sobre
el árbol de nodos (`Get`), no solo comparación visual.

**1 hallazgo IMPORTANTE, ya corregido:** el orden de las filas de documentos en la hoja de
re-aceptación paso 1 (variante "ambos documentos cambiaron", nodeId `JHwhG`/`b4zW2c`) salía
invertido (Política antes que Términos) porque `legal_reacceptance_step1.dart` iteraba
`LegalDocumentKind.values` en vez de seguir el orden fijo del componente `vEgX4`/`SjOTr` de Pencil
(Términos → Política). Fix: iterar en orden fijo `[termsOfUse, privacyPolicy]`. Goldens
`legal_reacceptance_sheet_step1_both_{light,dark}.png` regenerados; 64/64 tests de
`test/core/legal/` en verde tras el fix.

Todo lo demás (Bienvenida con pie legal, hoja de aceptación, visor de documento, re-aceptación paso
1 single-doc, re-aceptación paso 2) es fiel a su nodeId de referencia — estructura, colores,
tipografía, iconografía y estados coinciden, en claro y oscuro. Detalle completo en el reporte del
agente (no persistido como archivo aparte).

Pendiente real: no existe `design-system/billetudo/pages/legal.md`, así que no hay forma no
ambigua de auditar esta feature contra Pencil en el futuro sin repetir este cruce manual —
recomendado crearlo (tarea de `pencil-designer`/`ui-ux-reviewer`).

## 👤 Verifica a mano

- [ ] **AC 10** — en un dispositivo real: entrar a la hoja de re-aceptación, tocar "No acepto",
      confirmar que en el paso 2 "Exportar mis datos" navega a `/mas/importar-exportar/exportar` y
      genera el CSV real, sin sesión activa y con el radio apagado (modo avión). No hay test
      automatizado de este tramo (ver GAP arriba).
- [x] **Fidelidad visual contra Pencil** — auditada 2026-09-11, 1 hallazgo (orden de documentos en
      re-aceptación paso 1) corregido, resto fiel. Ver sección "Fidelidad visual vs Pencil" arriba.
- [ ] Confirmar en un dispositivo real que el visor nativo abre instantáneamente (sin flash de
      loading) la primera vez que se instala la app, con el bundle empaquetado, antes de que exista
      cualquier cache en disco.

## Pendientes y riesgos

- ~~**CRÍTICO, bloqueante para producción:** falta el `ALTER TABLE` en dev/prod reales.~~
  **Resuelto el 2026-09-11.** Antes de aplicarlo se encontró y corrigió un bug real en la
  migración: el `.sql` original declaraba `legal_accepted_at timestamptz`, pero el patrón
  documentado del proyecto para `app_settings` (tabla sincronizada, leída por Drift vía una vista
  PowerSync que hace `CAST(json_extract(...) AS <tipo>)`) es **bigint en segundos unix, nunca
  timestamptz** — un timestamptz llega como texto y ese `CAST` trunca el año en silencio (mismo
  patrón exacto que `ai_consent_accepted_at`, ver `20260825130000_app_settings_ai_consent.sql`, y
  que `powersync_schema.dart` ya declaraba correctamente como `Column.integer(...)`). Corregido a
  `bigint`/`bigint` en el `.sql` del repo y aplicado con ese tipo contra **dev y prod** vía MCP de
  Supabase — verificado con `information_schema.columns` en ambas bases.
- **PENDIENTE, bloqueante para producción:** `legal.json` todavía no existe publicado en `web/`
  (GitHub Pages, `web/build_site.py`). Hasta que se publique con el shape esperado
  (`currentVersion`/`minAppVersion`/`documents[{kind,url,changedInVersion,effectiveDate}]`) descrito
  en `docs/legal/entrega-de-documentos-legales.md`, `refreshFromRemote()` no tiene manifiesto real
  que adoptar y todo corre contra el bundle fallback empaquetado en `lib/core/legal/assets/` — la
  app funciona igual (por diseño), pero la re-aceptación por cambio de versión nunca se dispara
  hasta que exista un manifiesto remoto real. Fuera del alcance de este PR/sesión.
- Gap de cobertura AC 10 (ver Tests): falta test de navegación real a `exportCsv` con `GoRouter`
  montado.
- La suite completa `flutter test` no terminó de correr en esta sesión (máquina con Patrol/emulador
  en paralelo); solo se certifica en verde lo que tocó directamente esta corrida.
- Tema oscuro de pie/hoja/visor/re-aceptación **sí quedó auditado visualmente** en la pasada de
  fidelidad del 2026-09-11 (no solo por construcción de tokens) — consistente con la regla del
  proyecto de construir oscuro solo tras aprobar el claro, ya que ambos ya estaban aprobados en
  Pencil de antemano.
- Gap de fidelidad: sin `design-system/billetudo/pages/legal.md`, no hay forma no ambigua de
  auditar esta feature contra Pencil en el futuro sin repetir el cruce manual — pendiente crearlo
  (tarea de `pencil-designer`/`ui-ux-reviewer`).
- Mitigación de tooling de Patrol actualizada tras esta corrida: además de borrar
  `integration_test/test_bundle.dart`, hace falta borrar `build/app/outputs/apk/androidTest` antes
  de cada `patrol test` (Gradle cachea el APK de instrumentación) — ver
  `docs/dev-runs/patrol-e2e-findings-2026-08-25.md`.

## Mensaje de commit sugerido

```
feat(legal): aceptación versionada de términos y política de privacidad

- Pie discreto en Bienvenida con enlaces al visor nativo
- Hoja de aceptación intercepta "Comenzar" y "Ya tengo cuenta"
- Visor de documento: cache -> bundle, síncrono, sin loading/error/empty
- Re-aceptación al cambiar la versión vigente (gate en el shell principal)
- Enlaces de Ajustes abren el visor in-app en vez de url_launcher
- schemaVersion 34->35 (AppSettings.legalAcceptedAt/legalAcceptedVersion)
  + migración SQL equivalente en supabase/migrations/
- ~20 claves .arb nuevas (es/en)

Pendiente antes de producción: aplicar el ALTER TABLE en Supabase dev+prod
y publicar legal.json en web/ (fuera del alcance de este workflow).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018p9GZ3QZDkVzPCSkzeuTzC
```

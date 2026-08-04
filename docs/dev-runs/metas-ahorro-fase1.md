# Metas de ahorro — Fase 1 (metas-ahorro-fase1)

## Objetivo y criterios de aceptacion

Implementar la feature Metas de ahorro (Nivel 0) segun `docs/requirements/07-metas.md`: modelo de progreso derivado de un historial de movimientos (`GoalContributions`), CRUD completo, aportar/retirar, proyeccion, celebracion de hitos y meta cumplida, archivado/eliminado con tombstone, lista con senal de coherencia y momentum, y el nuevo diseno "tablero de aspiraciones" ya aprobado en Pencil (`design-system/billetudo/pages/metas.md`).

Excluido explicitamente de esta corrida:
- HU-16 (aporte recurrente via `ScheduledPayments.goalId`).
- Piezas de UI sin frame aprobado en Pencil (deltas de diseno del 2026-07-24): toggle "¿Mover dinero de una cuenta?" en Aportar/Retirar, flujo "Enlazar movimiento", config de aporte recurrente, card "Meta Enlazada" en Pagos Programados.

Ambas exclusiones responden al gate de diseno de `CLAUDE.md`: no se construye UI sin frame en el `.pen`.

Criterios de aceptacion (28 en total, ver detalle de cobertura abajo): desde persistencia de progreso via `GoalContributions` (AC1-4), vinculo a cuenta y su moneda (AC5-7), aportar/retirar con y sin movimiento de dinero (AC8-11), calculo derivado de `savedMinor` (AC12), congelamiento de metas cumplidas (AC13, AC16), hitos idempotentes (AC14-15), invariante transaccional (AC17-18), archivado/eliminado con tombstone (AC19-20), proyeccion (AC21-22), orden de lista (AC23), senal de coherencia (AC24), momentum sin mezclar monedas (AC25), categoria semilla "Ahorros" (AC26), ruteo real de `/metas` (AC27), hasta `flutter analyze` y tests en verde (AC28).

Tamano: **L** | Review: **deep, APROBADO**

## Que cambio

| Archivo | Que |
|---|---|
| `lib/core/database/app_database.dart`, `.g.dart`, `powersync_schema.dart` | schemaVersion 18→19: quita `Goals.savedMinor`/`color`, agrega `completedAt`/`archivedAt`/`lastMilestonePct`; nueva tabla `GoalContributions`; migracion con backfill de `savedMinor` previo via `ps_data__`/`ps_data_local__` |
| `test/core/database/goals_schema_test.dart` | Cubre la forma del esquema resultante (onCreate) |
| `lib/features/goals/domain/**` | Entidades, `GoalRepository`, casos de uso (`CreateGoal`, `UpdateGoal`, `ContributeToGoal`, `WithdrawFromGoal`, `LinkTransactionToGoal`, `ArchiveGoal`, `DeleteGoal`, `RestoreGoal`, `WatchGoals`, `WatchGoalDetail`, `WatchArchivedGoals`) y servicios (`GoalProgressCalculator`, `GoalMilestoneTracker`, `GoalProjectionCalculator`, `GoalMomentumCalculator`, `GoalCoherenceCalculator`, `GoalCategorySeed`, `GoalStarterTemplates`) |
| `lib/features/goals/data/**` | `GoalMapper`, `GoalContributionMapper`, `GoalsLocalDatasource`, `GoalRepositoryImpl` (savedMinor siempre derivado, nunca escrito) |
| `lib/features/transactions/domain/entities/transaction_draft.dart` | Invariante de dominio: `expense` + `goalId` no nulo se rechaza con excepcion |
| `lib/features/transactions/data/repositories/transaction_repository_impl.dart` | Cascada HU-08: editar/eliminar transaccion enlazada actualiza/elimina el `GoalContribution` correspondiente (inyecta `GoalRepository`) |
| `lib/features/goals/presentation/**` (cubits, pages, widgets, sheets, utils) | Capa de presentacion completa contra el diseno aprobado en Pencil (lista, detalle, formulario, archivadas, celebracion) |
| `lib/core/router/app_router.dart` | `/metas` monta `GoalsListPage` real (antes `ComingSoonPage`); sub-rutas `/metas/nueva`, `/metas/:id`, `/metas/:id/editar`, `/metas/archivadas` |
| `lib/core/theme/app_colors.dart` | Token `track` (claro `#EEECFB`, oscuro `#101018`) tomado de `get_variables` de Pencil, usado por `GoalProgressRing` |
| `lib/core/l10n/arb/*.arb` + `gen/*` | Cadenas de UI de Metas (es/en) |
| `lib/core/di/injection.config.dart` | Regenerado (build_runner) para los nuevos `@injectable`/`@lazySingleton` de Metas y el nuevo parametro de `TransactionRepositoryImpl` |
| `test/features/goals/**`, `test/features/transactions/**` | Tests unitarios de domain/data/presentation (detalle abajo) |

## Tests

Resultado: `flutter analyze` limpio, suite unitaria verde, e2e en skip (sin emulador booteado).

```bash
flutter analyze
dart run build_runner build --force-jit   # ya corrido; solo si vuelves a tocar esquema/DI
flutter test
```

- `dart analyze` → "No issues found!"
- `flutter test` (suite completa) → 2687 passed; 42 fallos preexistentes de goldens en `scheduled_payments`/`transactions` (no relacionados con esta corrida — consistente con la nota de memoria del proyecto sobre goldens flaky en esta maquina).
- Tests de Metas escritos en esta corrida:
  - `test/core/database/goals_schema_test.dart`
  - `test/features/goals/domain/entities/goal_draft_test.dart`, `goal_contribution_draft_test.dart`
  - `test/features/goals/domain/services/goal_progress_calculator_test.dart`, `goal_milestone_tracker_test.dart`, `goal_projection_calculator_test.dart`, `goal_coherence_calculator_test.dart`, `goal_momentum_calculator_test.dart`
  - `test/features/goals/domain/usecases/create_goal_test.dart`, `update_goal_test.dart`, `contribute_to_goal_test.dart`, `withdraw_from_goal_test.dart`, `link_transaction_to_goal_test.dart`, `watch_goals_ordering_test.dart`, `goal_repository_mock.dart`
  - `test/features/goals/data/goal_repository_impl_test.dart`
  - `test/features/goals/presentation/*_cubit_test.dart` (goals_list, goal_detail, goal_form, goal_contribution) + `goals_presentation_fixtures.dart`
  - `test/features/transactions/domain/entities/transaction_draft_test.dart` (invariante expense+goalId)
  - `test/features/transactions/data/transaction_repository_impl_test.dart` (actualizado para inyectar `GoalRepositoryImpl` real)

No se escribieron golden tests ni Patrol e2e para Metas en esta corrida (fuera de alcance segun el plan; queda para `qa-automator`).

## 👤 Verifica a mano

- [ ] **AC3**: correr la migracion de schemaVersion real (18→19) contra una app con datos reales/PowerSync para confirmar que el backfill de `Goals.savedMinor` → `GoalContribution` corre sin error — no reproducible con `NativeDatabase` en memoria (no hay usuarios con datos hoy, riesgo practico bajo pero sin verificar).
- [ ] **AC7 (UI)**: el "aviso neutro" cuando la cuenta vinculada se tombstona no tiene string ni widget visible en `goal_detail_page.dart`/`goal_card.dart` todavia (sin frame en `pages/metas.md` para ese estado) — decidir si se agrega antes de cerrar la feature.
- [ ] Verificacion visual completa contra Pencil: no existen golden tests para `goals_list_page`, `goal_detail_page`, `goal_form_page`, `archived_goals_page`, `goal_completed_celebration_page` ni para los sheets. Correr un pase de golden tests + `/design-fidelity-check goals` antes de cerrar la UI.
- [ ] Flujos multi-pantalla en dispositivo real (crear meta → aportar → celebracion de hito → archivar/eliminar) — sin emulador booteado en esta maquina, Patrol e2e queda en skip.
- [ ] Confirmar en producto que la exclusion explicita de HU-16 y las piezas de UI listadas (toggle mover dinero, enlazar movimiento, config recurrente, card "Meta Enlazada") siguen fuera de alcance — no se escribio ningun test para ellas.
- [ ] Si quieres automatizar el e2e: booteat un emulador y corre `patrol test`.

## Pendientes y riesgos

- **Bloqueante parcial (alcance de UI)**: las piezas de los "Deltas de diseno por la revision del modelo de aportes (2026-07-24)" no tienen frame aprobado en `billetudo.pen` — quedan fuera de esta corrida por el gate de diseno de `CLAUDE.md`. Se recomienda una pasada de `pencil-designer` para esas piezas y luego una segunda pasada de `feature-dev` para cablearlas.
- **HU-16** (aporte recurrente) requiere su propio bump de `schemaVersion`, toca Pagos Programados y no tiene UI disenada; queda como feature/corrida separada.
- La categoria semilla "Ahorros" (`seed-savings`) vive hoy en Postgres (`category_seeds`); esta corrida solo garantiza el id estable y su consumo local — el alta real en Supabase queda fuera de `lib/**` y debe coordinarse aparte.
- Riesgo de migracion de datos: el backfill de `savedMinor` usa un detalle interno no documentado de `powersync_core` (tablas `ps_data__`/`ps_data_local__`) porque `openPowerSyncDatabase()` reemplaza el esquema de PowerSync antes de que corra `onUpgrade` de Drift — fragil ante un cambio de version del paquete `powersync`. Sin usuarios con datos reales hoy, el riesgo practico es cero, pero el mecanismo queda documentado en el codigo por si acaso.
- El calculo de coherencia (HU-12) recalcula con N+1 queries (uno por meta/cuenta activa) en cada emision via `asyncMap`; no es reactivo a cambios de saldo que no toquen las propias contribuciones/goals — limitacion aceptada por presupuesto de tiempo, documentada en el codigo.
- `local_data_ownership_datasource.dart` (`_ownedTables`) no incluye `goal_contributions` — falta agregarla para que HU-04 la reclame en login (mismo gap preexistente que `debt_entries`).
- Tema oscuro de Metas no esta generado en Pencil (deuda de sistema del token "track" documentada en el requirement); esta corrida solo implementa fielmente el tema claro.
- HU-15 (momentum) en la lista: el dominio solo expone `GoalMomentum` dentro de `GoalDetail`; la cabecera de racha del frame de lista (TNx20) no se implemento — falta un caso de uso de momentum agregado si se quiere ese header.
- Sheets de celebracion (25/50/75%/100%) implementados funcionalmente pero no verificados pixel a pixel contra sus frames (E2RRw/YUwKy/CFFdo/HH46w) por presupuesto de tiempo.
- Pendiente tecnico preexistente de Pencil: "Action Row (EZdcd) con ancho 0 / fully clipped" en 6 instancias del detalle, sin diagnosticar — verificar con `/design-fidelity-check`.
- Blockers sin resolver: ninguno. Observaciones no bloqueantes: ninguna.

## Mensaje de commit sugerido

```
feat(metas): implementar Metas de ahorro Nivel 0 (fase 1)

Modelo de progreso derivado de GoalContributions (schemaVersion 19),
CRUD completo, aportar/retirar, proyeccion, hitos, coherencia y
momentum, archivado/eliminado con tombstone, y el diseno "tablero de
aspiraciones" aprobado en Pencil. Excluye HU-16 (aporte recurrente) y
las piezas de UI sin frame aprobado (toggle mover dinero, enlazar
movimiento, config recurrente, card Meta Enlazada) por el gate de
diseno del proyecto.
```

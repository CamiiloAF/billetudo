# Dev run — Inicio (Home + shell de navegación)

Feature **04** (`docs/requirements/04-inicio.md`, spec de diseño `design-system/billetudo/pages/inicio.md`). Nivel 0. Primera pantalla de la app + marco de navegación que reemplaza `BootstrapHomePage`.

## Qué se construyó

- **Shell de navegación (HU-01):** `StatefulShellRoute.indexedStack` con tab bar de 5 destinos (Inicio, Movimientos, Presupuestos, Metas, Más). Los formularios/detalles cuelgan del `rootNavigatorKey` para cubrir la tab bar. `BootstrapHomePage` eliminado. Hub "Más" (`more_page.dart`) con Cuentas/Categorías vivas y el resto de features como "Próximamente".
- **Home (`lib/features/home/`):**
  - Dominio: `MonthSpending`/`CurrencySpending` (gasto del mes en centavos, **excluye `transfer`, `debtId` y cuentas con lápida**, por moneda), `HomeSnapshot` (combina gasto + feed reciente de todas las cuentas activas, tope 5), `WatchMonthTransactions`.
  - Presentación: `HomeCubit` (combina `WatchAccounts` + `WatchMonthTransactions` sin rxdart, refold puro vía `HomeSnapshot.from`; navegación de mes con guard de futuro), `home_page`, hero (solo estado "sin presupuesto"), header (saludo + campana + indicador de sync pasivo), `RecentActivityRow` (fila plana; gasto en `text-primary`, ingreso en `income-text`), banner de IA, month picker, skeletons.
  - Estados: con datos, vacío (sin banner de IA), carga.
  - FAB que abre el form de transacción y se oculta al hacer scroll hacia abajo.
- **Reutilizables (`lib/core/widgets/`):** `ComingSoonPage` y `ComingSoonSheet` (tabs vacías, destinos futuros de "Más", campana, banner de IA con/sin disclaimer).
- **Theme:** token `skeleton` (`#ECEBF3` claro / `#45455F` oscuro). **l10n:** claves nuevas es+en.

## Decisiones de alcance (del dueño)

- **Hero solo en estado "sin presupuesto"** (invitación a presupuestar). La barra de progreso de presupuesto depende de la feature **Budgets, que no existe** — queda estructurada pero sin cablear.
- **Pestañas vacías** (Presupuestos, Metas) y destinos futuros de "Más" → placeholder `ComingSoonPage`, sin scaffolds de esas features.

## Verificación

- `flutter analyze` y `dart run custom_lint`: sin issues.
- `flutter test`: suite completa en verde (tests de Home unit + widget: dominio del gasto, `HomeCubit`, hero, tab bar, more, month picker, actividad reciente, estados).
- **Revisión Nivel 0/legal (`compliance-reviewer`):** cumple — nada gateado, IA "próximamente" no ejecuta nada, disclaimer solo en el sheet de IA, tono positivo.
- **Revisión de convenciones (`finance-code-reviewer`):** limpia — dinero en centavos, Clean Architecture estricta, streams cancelados, tokens sin hex.

## Pendiente / fuera de alcance

- **Barra de progreso de presupuesto** en el hero: espera a la feature Budgets (06).
- **Saludo con nombre real e indicador de sync real:** esperan auth + PowerSync (05). Hoy saludo genérico y `HomeSyncStatus.synced` fijo (forward-compatible).
- **QA profundo (`qa-automator`):** se interrumpió a mitad; alcanzó a dejar cobertura de widgets adicional (todo verde tras corregir un artefacto de layout del harness del month picker). Queda espacio para e2e Patrol del flujo Home → FAB → nueva transacción.
- **i18n de fechas:** `DateFormat` usa locale fija `'es_CO'` (patrón de todo el repo, incl. Transacciones y `MoneyFormatter`); si se decide soportar `en` en formato de fecha, corregir con un helper compartido en todo el repo, no solo en Home.
- **Limpieza cosmética:** comentarios en `integration_test/transactions_patrol_test.dart` mencionan el `BootstrapHomePage` ya borrado.

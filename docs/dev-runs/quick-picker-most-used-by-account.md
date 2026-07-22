# Quick picker: más usadas también por cuenta (quick-picker-most-used-by-account)

## Objetivo y criterios de aceptación

Filtrar el conteo de "categorías más usadas" del Category Quick Picker también por cuenta (`accountId`), no solo por `kind`, propagando el filtro opcional desde el datasource de Drift hasta el cubit y ambos formularios que lo usan (transacciones y pagos programados), sin cambiar el esquema ni el fallback de desempate para cuentas sin historial.

1. `CategoriesLocalDatasource.mostUsedCategories` acepta un parámetro opcional `String? accountId`; cuando es no-null, el join/count de transacciones se filtra además por `Transactions.accountId = accountId` (junto al filtro de `kind` y los guards `deletedAt IS NULL` / `tombstonedAt IS NULL` ya existentes).
2. Cuando `accountId` es null, o cuando la cuenta filtrada no tiene transacciones vivas, el resultado y el orden de desempate (root antes que subcategoría → `sortOrder` → `createdAt`) son idénticos al comportamiento actual (regresión cero para el caso sin filtro).
3. Dos cuentas con historiales de categorías distintos producen top-3 de "más usadas" distintos cuando se pasa su `accountId` respectivo, verificado con un test de integración sobre Drift en memoria.
4. `CategoryRepository.getMostUsedCategories` y el caso de uso `GetMostUsedCategories` aceptan y propagan el mismo `accountId` opcional (default null) hasta el datasource, sin romper las llamadas existentes que no lo pasan.
5. `CategoryQuickPickerCubit` expone un método `setAccount(String? accountId)` que recarga el set de más-usados cuando el `accountId` efectivamente cambió (comparando contra el valor interno guardado), y es un no-op cuando es el mismo valor — igual patrón que `setKind`.
6. Al llamar `setAccount` con un `accountId` distinto, la categoría ya seleccionada (`state.selected`) nunca se limpia ni resetea solo por el cambio de cuenta: se conserva vía el mismo mecanismo que `syncSelection` ya usa cuando la selección no está en el nuevo top-3 (aparece como chip extra, no desaparece).
7. `CategoryQuickPicker` widget (compartido por Transacciones y Pagos Programados) recibe un nuevo parámetro `String? accountId`; en `initState` lo pasa a `_cubit.start(...)` y en `didUpdateWidget`, cuando `widget.accountId != oldWidget.accountId`, llama a `_cubit.setAccount(widget.accountId)` (independiente del cambio de `kind`).
8. `transaction_form_page.dart` pasa `accountId: state.accountId` al `CategoryQuickPicker` que ya construye (bloque gasto/ingreso), de modo que cambiar de cuenta en el formulario recalcula el top-3 sin perder la categoría elegida.
9. `scheduled_payment_form_page.dart` pasa `accountId: state.accountId` al `CategoryQuickPicker` que ya construye, con el mismo comportamiento que en (8).
10. Los 5 archivos de test listados en el change map (datasource, caso de uso, cubit, y ambos formularios) cubren explícitamente: filtrado por `accountId` con resultados distintos entre cuentas, no-regresión sin `accountId`, no-op de `setAccount` con el mismo valor, y que la selección sobrevive a un cambio de cuenta.

Tamaño: **s** · Review: quick, **APROBADO**.

## Qué cambió

| Archivo | Qué |
|---|---|
| `lib/features/categories/data/datasources/categories_local_datasource.dart` | `mostUsedCategories` acepta `accountId` opcional; filtra el join por `Transactions.accountId` cuando no es null (con `Constant(true)` si es null, para regresión cero). |
| `lib/features/categories/domain/repositories/category_repository.dart` | `getMostUsedCategories` propaga `accountId` opcional (default null). |
| `lib/features/categories/domain/usecases/get_most_used_categories.dart` | `GetMostUsedCategories.call` propaga `accountId` opcional al repositorio. |
| `lib/features/categories/data/repositories/category_repository_impl.dart` | Pasa `accountId` al datasource. |
| `lib/features/transactions/presentation/cubit/category_quick_picker_cubit.dart` | Nuevo método `setAccount(String? accountId)`: no-op si no cambió, recarga solo el set de más-usados sin tocar `state.selected` si cambió. |
| `lib/features/transactions/presentation/widgets/category_picker/category_quick_picker.dart` | Nuevo parámetro `accountId`; se pasa en `start()` (initState) y dispara `setAccount` en `didUpdateWidget` de forma independiente al chequeo de `kind`. |
| `lib/features/transactions/presentation/pages/transaction_form_page.dart` | Pasa `accountId: state.accountId` al `CategoryQuickPicker`. |
| `lib/features/scheduled_payments/presentation/pages/scheduled_payment_form_page.dart` | Pasa `accountId: state.accountId` al `CategoryQuickPicker`. |
| `test/features/categories/data/datasources/categories_local_datasource_test.dart` | Filtrado por cuenta con resultados distintos, no-regresión sin `accountId`, fallback sin historial. |
| `test/features/categories/domain/usecases/get_most_used_categories_test.dart` | Propagación de `accountId` explícito y default null. |
| `test/features/transactions/presentation/cubit/category_quick_picker_cubit_test.dart` | `setAccount` recarga si cambió, no-op si es igual, selección sobrevive al cambio de cuenta. |
| `test/features/transactions/presentation/pages/transaction_form_page_test.dart` | Propagación de `accountId` del estado al picker, al arrancar y al cambiar de cuenta. |
| `test/features/scheduled_payments/presentation/pages/scheduled_payment_form_page_test.dart` | Mismo comportamiento en el formulario de pagos programados. |
| `test/features/transactions/presentation/golden/transaction_form_page_golden_test.dart` | *(fuera del change map, ver Pendientes)* stub de `accountId`/`setAccount` para no romper el mock del cubit. |
| `test/features/scheduled_payments/presentation/golden/scheduled_payment_form_page_golden_test.dart` | *(fuera del change map, ver Pendientes)* mismo stub. |

## Tests

Resultado: `flutter analyze` limpio · suite `flutter test` verde · e2e Patrol: skip (no bloqueante, tests no nuevos).

Para re-correr:

```bash
flutter analyze
flutter test
```

Cobertura de AC (resumen — el detalle completo, con archivo::test exacto, quedó registrado en la corrida original):

- AC1-2 (filtro por `accountId`, regresión cero sin filtro y con cuenta sin historial): `categories_local_datasource_test.dart`.
- AC3 (dos cuentas, top-3 distintos, Drift en memoria): `categories_local_datasource_test.dart`.
- AC4 (propagación repositorio/caso de uso): `get_most_used_categories_test.dart`.
- AC5-6 (`setAccount` no-op / recarga, selección sobrevive): `category_quick_picker_cubit_test.dart`.
- AC7-8 (widget propaga `accountId`, `transaction_form_page` lo pasa): `transaction_form_page_test.dart`.
- AC9 (`scheduled_payment_form_page` lo pasa): `scheduled_payment_form_page_test.dart`.
- AC10 (los 5 archivos cubren los 4 casos): confirmado por lectura directa de cada archivo.

## 👤 Verifica a mano

- [ ] Verificar visualmente en dispositivo real que cambiar de cuenta en el formulario de Transacciones o Pagos Programados recalcula el top-3 del quick picker sin parpadeos ni jank perceptible.
- [ ] Confirmar en uso real (no en test) que la categoría ya elegida sigue apareciendo como chip extra tras el cambio de cuenta, incluso alternando varias veces entre cuentas seguidas.
- [ ] El e2e quedó en skip — bootea un emulador y corre `patrol test` si quieres automatizarlo.

## Pendientes y riesgos

- **Sin blockers.** Alcance acordado cerrado completo.
- Desviación justificada del change map: se tocaron además `transaction_form_page_golden_test.dart` y `scheduled_payment_form_page_golden_test.dart` (no listados originalmente) porque ambos mockeaban `CategoryQuickPickerCubit.start` sin el nuevo parámetro `accountId`, y la firma no calzaba durante el build — el golden fallaba al 59% de diff, no era el flaky de ~0.4% conocido en esta máquina. Se agregó el stub `accountId: any(named: 'accountId')` / `setAccount(any())` sin tocar las expectativas de píxeles.
- No se tocó el esquema de Drift ni `schemaVersion` (no aplicaba, `Transactions.accountId` ya existía).
- Riesgo de diseño anotado para revisión futura: `didUpdateWidget` del picker dispara `setKind` y `setAccount` de forma independiente; si ambos cambian en la misma pasada (ej. abrir el formulario en modo edición), el orden importa porque `setKind` reconstruye todo el estado vía `start`. Quedó implementado con `setAccount` disparándose de forma independiente al chequeo de `kind`, como pide el AC7 — vale la pena un ojo extra si en el futuro se edita simultáneamente cuenta y tipo de movimiento.
- Fuera de alcance: el filtro por `accountId` no aplica a la rama de Transferencias (no usa `CategoryQuickPicker`); si se reusa el picker ahí, falta decidir si filtra por cuenta origen o destino.
- Sin violaciones de negocio/legal ni de convenciones de código (dinero, IDs, `updatedAt`, borrado, capas, estilo, l10n, widgets) — repasado contra los 8 archivos de `lib/`.

## Mensaje de commit sugerido

```
feat(categories): filtrar categorías más usadas del quick picker también por cuenta

Propaga un accountId opcional desde CategoriesLocalDatasource.mostUsedCategories
hasta CategoryQuickPickerCubit y ambos formularios (Transacciones y Pagos
Programados), sin alterar el fallback de desempate ni el comportamiento sin
filtro. La categoría seleccionada sobrevive a un cambio de cuenta igual que ya
sobrevivía a un cambio de kind.
```

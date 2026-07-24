> **Estado: ✅ CERRADO (verificado en código el 2026-07-24).** Los 4 puntos ya están implementados en `lib/features/debts/` (y `lib/features/scheduled_payments/` para el punto 4). Se deja el detalle abajo como registro histórico.

1. Crear deuda form — ✅ resuelto
    - Al poner el cursor en saldo de apertura aparecen 2 signos de peso, el del hint y el "leading" del input,  genera ruido (mismo error en los otros campos de saldo de la deuda) — ✅ `debt_amount_hero_field.dart` (`prefixText: '$'` + hint solo `'0'`)
    - Ese campo debe permitir decimales. (mismo error en los otros campos de saldo de la deuda) — ✅ `MoneyInputFormatter(decimals: ...)` en el mismo widget
    - El input "Nombre" es mejor que diga "Nombre de la deuda" en el label, me confundí mientrtas probaba. — ✅ `app_es.arb: debtFormNameLabel = "Nombre de la deuda"`
    - En lugar de "Contra parte" es mejor que diga "Le debo a" o "Me debe" o algo así, contra parte es algo un poco confuso para los usuarios del común. — ✅ label condicional según `direction` en `debt_form_page.dart`
    - Vencimiento no tiene una opción para limpiar la fecha — ✅ `onClear` en `debt_form_page.dart`

2. — ✅ resuelto
    - El usuario debe tener la posibilidad de elegir si cuando se crea la deuda también se va a crear un registro que afecte su saldo en alguna de la cuenta que el seleccione. — ✅ `DebtInitialRegistroSheet` + `create_debt_with_opening_movement.dart`
    - Si el usuario seleccionó crear el registro y luego vay modifica el saldo de apertura, se le debe informar que el registro que tiene enlazado también va a cambiar y lo debes cambiar. — ✅ `DebtConfirmUpdateRegistroPrompt` + `DebtUpdateRegistroSheet`

3. — ✅ resuelto
    - Acabo de registrar un abono, enlacé un un gasto de -85.000 y la deuda sumó ese dinero al saldo pendiente en lugar de al dinero abonado. Realmente no es un error porque la deuda es de tipo "Me deben" entonces si selecciono un registro negativo va a sumar a la deuda, la idea es que filtremos obligatoriamente por tipo de transacción, si me deben y voy a enlazar un abono entonces solo debo ver los ingresos y si si yo debo y voy a abonar, solo debo ver gastos. — ✅ `DebtEventRules.cashEventType` + `transactions_link_mode.dart: accepts()`
    - Filtra también por fecha, no se pueden seleccionar registros anteriores a la fecha de creación de la deuda y tampoco crear un abono con fecha anterior a le deuda. — ✅ mismo `accepts()`, `notBefore = debt.effectiveStartDate`
    - Como usurio debo tener la posibilidad de ver el detalle de los movimientos que aparecen en la parte inferior del detalle de la deuda y si estos movimientos cambian entonces también cambia el estado de la deuda. — ✅ `debt_ledger_row.dart` navega al detalle del movimiento; ledger derivado del stream (`watch_debt_detail.dart`)

4. — ✅ resuelto
    - La pantalla de configurar cuota debe teener las mismas validaciones de fechas y el valor de la cuota no puede superar el valor de la deuda. — ✅ `scheduled_payment_form_cubit.dart` valida `amountMinor > state.debtOutstandingMinor`
    - Estoy configurando una cuota y al seleccionar el botón de guradar no hace nada, no muestra error ni nada. Si vuelvo atrás si veo la cuota programada, debería recibir feedback de la operación o simplemente volver a la pantalla del detalle de la deuda. (Solo ocurrió 1 vez) — ✅ todo camino del cubit emite `saved`/`failure` con navegación o error visible

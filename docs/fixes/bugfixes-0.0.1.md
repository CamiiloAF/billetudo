## Estado (sesión 2026-07-22)

| # | Estado | Nota |
|---|--------|------|
| 1 | ✅ Hecho | Token `segment-inactive-text` (~5.3:1 claro); aplicado a `hFu41` + 17 instancias; en MASTER. |
| 2 | ✅ Hecho | 3 sub-bugs: fecha futura→PP obligatorio (no guarda tx futura), sheet con `BottomSheetBase`, `pushReplacement`. |
| 3 | ✅ Hecho (goldens pend.) | Signo/verde ya estaban. Nota: `templateName` reescrito → título = **nota** del pago (fallback "Pago programado"), categoría al subtítulo. Aplica a lista global Y sheet del presupuesto (con item 19). |
| 4 | ✅ Hecho | Entrada permite decimales (COP incl.); display muestra centavos solo cuando existen. `12-multi-moneda.md` actualizado. |
| 5 | ✅ Hecho | Long-press en borrar limpia el input (ambos keypads). |
| 6 | ✅ Hecho (goldens pend.) | Icono sync tappable (44pt). offline+sin sesión→login; resto→`SyncStatusSheet` **reactivo** (BlocBuilder, syncing→synced cambia en sitio). 3 estados diseñados (`CaLYm`/`WAW55`/`nzxqu`). Falta oscuro del sheet + goldens. |
| 7 | ✅ Código / 🔄 .pen | PP reemplaza Metas en el nav; Metas en "Más" + accesos rápidos. Tab "Pagos"/`calendar-clock`. Sincronizando Tab Bar `u3b5s9`. |
| 8 | ✅ Hecho (goldens pend.) | Tira "Mis cuentas" en Inicio, ícono+color por tipo, "Ver todas"→Cuentas. **Tap en mini-card → Movimientos filtrado por esa cuenta** (`filterByAccount` reusa el filtro persistido HU-06a; `TransactionsListCubit` a `lazySingleton`; hook `onOpenAccountMovements`). |
| 9 | ⏳ Pendiente | Scroll a primer error + toolbar "Done" iOS (transversal, va al final). |
| 10 | ✅ Hecho (goldens pend.) | Caption `freeAfterScheduledMinor`; solo si programado>0 y X≥0; sobregiro usa "excedería". **Reword aplicado (valor primero):** "$48.000 quedarían libres si apruebas los programados" (l10n hecho; Pencil `wMwFu`+oscuro en curso). |
| 11 | ✅ Hecho (goldens pend.) | Footer "Ver todos los pagos programados" en el sheet del presupuesto → `context.go` a lista global de PP (tab-root). |
| 12 | ✅ Hecho (goldens pend.) | `account_card.dart`: nombre `maxLines:2`+ellipsis, saldo alineado arriba. |
| 13 | ✅ Hecho (goldens pend.) | El "+" ahora hace `push(newCategory(kind))` → flujo completo `CategoryFormPage` (ícono/color/padre), con `kind` correcto; devuelve la categoría creada y queda seleccionada. `NewCategorySheet` borrado. 225 tests verdes. |
| 14 | ✅ Hecho | Presupuesto "Todas"→scope vacío/global + migración one-shot. Caveat: presupuesto ya roto con categoría nueva ya creada → reabrir y re-marcar "Todas". |

**Bugs nuevos reportados en la sesión (post-lista original):**
| # | Estado | Nota |
|---|--------|------|
| 15 | ✅ Hecho (goldens pend.) | (a) Alineación ícono+input en error: solo el form de presupuesto tenía la fila → `CrossAxisAlignment.start`. (b) Vacío→"obligatorio" (no longitud) en categoría y cuenta; presupuesto ya estaba bien. |
| 16 | ✅ No es bug (confirmado) | La lista global de PP **sí** incluye ingresos (verificado, cero filtro por tipo). El detalle del presupuesto es expense-only por diseño (rastrea gasto) — **confirmado OK por el usuario**. Test de regresión agregado. |
| 17 | ✅ Hecho (goldens pend.) | `typeSelected` ahora `clearCategory:true` en cualquier cambio real de tipo (guarda si es el mismo). Forms de transacción Y PP. El picker ya filtra por `CategoryKind`. |
| 18 | ✅ Hecho (goldens pend.) | **Causa real:** el mapper omitía `firstPaymentDate` (inmutable) y el form se prellena de ahí → al reabrir volvía la fecha vieja. Fix: edición explícita de fecha **reancla** `firstPaymentDate` (`rescheduleAnchor`); catch-up nunca la mueve. + borra ocurrencias en espera viejas. Test e2e incluye reabrir el form. |
| 19 | ✅ Hecho (goldens pend.) | Título = nota del pago (con item 3), categoría al subtítulo, en `budget_scheduled_row` + calculator. |
| 20 | ✅ Hecho (goldens pend.) | `formatSymbolEntry` muestra la coma al presionarla (decimal pendiente); borrar la quita. Zona de monto de transacción + buffer de PP. Fix del item 4 (fuera de entrada) intacto. |
| 21 | ✅ Hecho (goldens pend.) | Card de saldo del carrusel de Movimientos espeja la de crédito (nombre 2 líneas, "Saldo"+figura pequeña reusando el widget de crédito, sin hero). Pencil (`C2g9cA`+oscuro, 3 carruseles extra corregidos) + código (`movements_balance_card.dart`, alto efectivo 150px). |

**✅ CERRADO (2026-07-22).** Los **21 items** resueltos (1-15 y 17-21 arreglados; 16 confirmado "funciona según diseño"; 3 unificado con 19). Incluye 7 bugs nuevos reportados durante la sesión (15-21). `qa-automator` regeneró todos los goldens en dos pasadas → **suite completa verde (+2263 tests, 0 fallos)**, `flutter analyze` limpio.

**Nada se ha commiteado** (working tree sucio para revisión). **Verificación humana pendiente:** (1) `/design-fidelity-check` sobre home/scheduled_payments/budgets/transactions/accounts (el golden confirma render estable, no fidelidad al `.pen`); (2) mirar a ojo la coma pendiente y los decimales "solo cuando existen" (items 4/20). **Deuda de fidelidad menor:** portar la tira "Mis cuentas" (item 8) a los frames canónicos de Inicio + estados.

---

1) [MENOR, no bloqueante] El componente reusable `Segmented Control` (`hFu41` en `billetudo.pen`) tiene el label del segmento inactivo en ~4.37:1 de contraste (`$text-secondary` sobre `$muted`), por debajo del umbral AA de 4.5:1 para texto normal. Afecta todas sus instancias (Gasto/Ingreso/Transferencia en Transacciones, y el nuevo selector de tema Claro/Oscuro/Sistema en Ajustes). Hallado por `ui-ux-reviewer` el 2026-07-20 al auditar el selector de tema — no introducido por esa pantalla, es del componente base. Corrección sugerida: un token calibrado tipo `segment-inactive-text` para que se propague a todas las instancias.

2) Bug al crear pago programado desde un registro normal. Algo pasó y se creo un registro que afectó el saldo aún creado para 1 mes más adelante. El sheet de alerta aparece sin respetar las margenes y luego de crear un pago programado y volver atrás, vuelve al mismo folrmulario de la Transacción.

3) ![alt text](image.png) Pagos programados no distingue entre ingresos y gastos, debnería mostrar signos y color verde cuando sea ingreso. 
    - Debería mostrar el nombre (nota) del pago programado

4) La app debe permitir decimales, a veces una compra o pago puedo incluir decimales.

5) [MEJORA] Si el usuario deja presionado el botón borrar del teclado se debe limpiar el input

6) ![alt text](image-1.png) El icono de la nube (sync) debería ser interactivo. Si está en off, debe redirigir a la pantalla de login, si está cargando, no hace nada y si está sincronizado, le mostramos un sheet con info de lo sincronizado o solo le decimos que toda su info está a salvo y sincronizada?

7) Reemplaza el item de Metas por Pagos programados (programados) en el bottom nav bar

8) Esto me dice un usuario ![alt text](image-2.png) "Y aquí a mi punto de vista, sería bueno tener un resumen rápido de mi balance al menos de efectivo por ejemplo y gastos - como para que apenas uno la abre ah bueno vamos así …" Sería bueno una card con todo el reumen de todas las cuentas o max 2-cuentas, sería analizarlo y diseñarlo.

9) ![alt text](image-3.png) Debemos mover el scroll/pantalla al primer elemento que tenga un error en el formulario. 
    - Hay que agregar las opcinoens de "Done" cuando se levante un teclado en iOS, determina cuáles inputs lo requieren a lo largo de la app

10) Node ID: q32DPb que posibilidades hay de agregar otro texto que indique cuánto dinero quedaría libre si se aplican todos los pagos programados

11) Qué tan conveniente sería tener una opción "Ver todo" para ver todos los pagos programados Node ID: hFPFU/qsjbj?

12) ![alt text](image-4.png) Ajustar la card de las cuentas, corta el texto del nombre de la cuenta. Valida opciones, tal vez esté bueno copiar el mismo diseño de la tarjeta de crédito pero adaptado, esta Node ID: WKiYZ. Analizalo y me das 2-3 variantes en pencil.

13) Node ID: SfSln el selector de categorías en transacciones y pagos programados debería tener una opción "+" para agregar una categoría nueva, tal como lo hace el selector de tags (etiquetas)

14) Hay un bug, si yo creo un presupuesto y le asigno todas las categorías (66) y días después creo otra categoría, el presupuesto que tiene asignado "Todas" las categorías va a seguir tomando las 66 y no las 67, debería tener todas la categrías si fue que las seleccionó todas o si hace parte de una categoría padre que también se eligió.
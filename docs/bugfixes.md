1) ~~Un pago programado en modo automático también debe permitir crear el registro manual~~ — ✅ hecho 2026-07-20. Tenía 2 partes con estados distintos, corregidas en sesiones separadas:
    - Node IDs `ie6BF`/`eswQN` (mostrar la opción si la fecha es HOY o anterior) y el bug del campo "Primer pago" cambiando solo → cerrados en una sesión previa (commit `4659072`, mecanismo `_ensureDuePendingOccurrence`/`dateIsDueOn`).
    - Node ID `OY2Kj` (confirmar desde el detalle **en cualquier momento**, no solo vencido) → quedó sin implementar pese a que el ítem no tenía tachado; detectado y corregido en esta sesión. Botón "Confirmar ahora" nuevo en el Hero del detalle (visible solo si automático + no vencido), diseñado en Pencil (2 variantes → elegida "CTA junto al Hero" → ícono `zap` decidido por `ui-ux-reviewer` tras descartar colisiones semánticas con otros íconos de la misma feature), claro + oscuro. Mecanismo: `_ensureDuePendingOccurrence` ganó un parámetro `force` que salta solo el chequeo de fecha vencida, conservando todas las demás guardas (tombstoned, `endDate`, ya resuelta); nuevo usecase `AdvanceScheduledOccurrence`, reusa el `ConfirmationSheet`/`ConfirmScheduledOccurrence` existente sin cambios. Verificado contra Pencil (1 hallazgo MENOR de gap 12px vs 10px, corregido), tests/goldens verdes y reviews finales sin hallazgos.

2) ~~Ejecutar pasada de fidelidad en Transacciones~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-transacciones.md`

3) ~~Ejecutar pasada de fidelidad en Categorías~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-categorias.md`

4) El bottom sheet de cerrar sesión debería sobreponerse al bottom nav bar, ahora mismo lo deja visible, De hecho, TODOS lo botom sheets deben tener este comportamiento

5) ~~Si el usuario está en el home y navega hacía atrás con gestos, debería mostrarle una alerta de confirmación para salir de la app, si lo hace en otra se las opciones del bottom nav bar, lo debe llevar al home~~ — ✅ hecho 2026-07-20

6) ~~Analiza la opción de editar un presupuesto para 1 sola vez, es decir, tal vez yo hice un trabajo extra y me gané 2 millones más y por consiguiente mi presupuesto para el proximo mes será mayor pero el resto de meses seguirá siendo igual.~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/presupuestos-ajuste-un-periodo.md`. Enfoque fork-of-3-partes sin cambio de esquema Drift, verificado contra Pencil (`pencil-fidelity-reviewer` aprobó las 4 piezas nuevas), tests/goldens verdes y reviews finales sin hallazgos.

7) ~~Node ID: oAM6Y no se muestra el snackbar cuando se elimina una transacción desde el home pero si se muestra si se elimina desde la pestaña de movimientos~~ — ✅ hecho 2026-07-20, mismo bug corregido también en Detalle de Presupuesto y Detalle de Pago Programado

8) ~~Ejecutar pasada de fidelidad en Home/Dashboard~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-home.md`. Pendiente diferido a propósito: estado "con presupuesto" del hero (barra de progreso).

9) ~~Ejecutar pasada de fidelidad en Presupuestos~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-presupuestos.md`. La sospecha de deriva amplia no se confirmó: solo 1 hallazgo (subtítulo truncado, compartido con Cuentas/Categorías).

10) ~~Implementar las pantallas **Ajustes** y **Más**~~ — ✅ hecho 2026-07-20. Ambas ya tenían código (contra lo que decía este punto); se corrió `/design-fidelity-check auth` como pedía el punto, ver `docs/dev-runs/fidelidad-ajustes.md`. 2 hallazgos corregidos (fila "Modo sobres" compuesta en el `.pen` en sección nueva "Presupuesto", sublabel de Apariencia) + 1 menor (iniciales de avatar). "Más" ya se había auditado por separado en el punto 8.

11) [MENOR, no bloqueante] El componente reusable `Segmented Control` (`hFu41` en `billetudo.pen`) tiene el label del segmento inactivo en ~4.37:1 de contraste (`$text-secondary` sobre `$muted`), por debajo del umbral AA de 4.5:1 para texto normal. Afecta todas sus instancias (Gasto/Ingreso/Transferencia en Transacciones, y el nuevo selector de tema Claro/Oscuro/Sistema en Ajustes). Hallado por `ui-ux-reviewer` el 2026-07-20 al auditar el selector de tema — no introducido por esa pantalla, es del componente base. Corrección sugerida: un token calibrado tipo `segment-inactive-text` para que se propague a todas las instancias.
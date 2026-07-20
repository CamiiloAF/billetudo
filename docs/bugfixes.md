1)  - Un pago programado en modo automático también debe permitir crear el registro manual 
    - Node ID: OY2Kj un usuario debería tener la opción de confirmar el pago programado desde el detalle en cualquier momento
    - Node IDs: ie6BF, eswQN esto debería mostrarse si la fecha de pago es HOY o anterior
    - Hay un bug, el campo "Primer pago" está cambiando solo. Tenía un pago programado para el 19 de julio y al llegar a esa fecha voy al formulario de edición y veo que el cmapo primer pago ahora dice "19 de Agosto"

2) ~~Ejecutar pasada de fidelidad en Transacciones~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-transacciones.md`

3) ~~Ejecutar pasada de fidelidad en Categorías~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-categorias.md`

4) El bottom sheet de cerrar sesión debería sobreponerse al bottom nav bar, ahora mismo lo deja visible, De hecho, TODOS lo botom sheets deben tener este comportamiento

5) ~~Si el usuario está en el home y navega hacía atrás con gestos, debería mostrarle una alerta de confirmación para salir de la app, si lo hace en otra se las opciones del bottom nav bar, lo debe llevar al home~~ — ✅ hecho 2026-07-20

6) Analiza la opción de editar un presupuesto para 1 sola vez, es decir, tal vez yo hice un trabajo extra y me gané 2 millones más y por consiguiente mi presupuesto para el proximo mes será mayor pero el resto de meses seguirá siendo igual. — 📋 analizado 2026-07-20, plan listo en `docs/dev-runs/presupuestos-ajuste-un-periodo.md`, pendiente de implementar

7) ~~Node ID: oAM6Y no se muestra el snackbar cuando se elimina una transacción desde el home pero si se muestra si se elimina desde la pestaña de movimientos~~ — ✅ hecho 2026-07-20, mismo bug corregido también en Detalle de Presupuesto y Detalle de Pago Programado

8) ~~Ejecutar pasada de fidelidad en Home/Dashboard~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-home.md`. Pendiente diferido a propósito: estado "con presupuesto" del hero (barra de progreso).

9) ~~Ejecutar pasada de fidelidad en Presupuestos~~ — ✅ hecho 2026-07-20, ver `docs/dev-runs/fidelidad-presupuestos.md`. La sospecha de deriva amplia no se confirmó: solo 1 hallazgo (subtítulo truncado, compartido con Cuentas/Categorías).

10) Implementar las pantallas **Ajustes** y **Más**, que están diseñadas en `billetudo.pen` pero sin código todavía. Nodos: Ajustes sin sesión `jDaUb` / con sesión `aaQBp` (oscuros `j4JYF` / `TQHmY`), Más `gXcHt` (oscuro `X9x7x`). Spec en `design-system/billetudo/pages/auth.md`. Son el punto de entrada a Cerrar sesión (HU-06, ya implementada) y a Borrar cuenta (HU-07). Al construirlas, correr `/design-fidelity-check auth` de nuevo para cubrir estos frames — hoy quedan fuera del alcance porque no hay código que auditar (ver `docs/fidelidad-visual-tracking.md`, fila Auth).
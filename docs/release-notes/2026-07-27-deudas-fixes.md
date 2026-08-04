# 2026-07-27 — Correcciones de Deudas

Resumen de los bugs y mejoras resueltos en esta sesión sobre la feature de Deudas (`lib/features/debts/`), a partir de los puntos 5-9 reportados en `docs/fixes/improvements_debts.md` más 3 ajustes de seguimiento pedidos tras probar en dispositivo.

## Deuda saldada (100%)

- El CTA "Registrar abono" del detalle cambia a "Completar deuda" cuando el saldo llega a $0 y la deuda aún no está cerrada.
- El menú de 3 puntos muestra "Completar deuda" en ese mismo estado, y deja de ofrecer la opción de cerrar/re-cerrar una deuda ya cerrada (evita el error "No pudimos completar la acción" al intentar cerrarla dos veces).
- Se quitó el chevron indebido de esa fila del menú (no abre nada más, solo ejecuta la acción).
- Se agregó un snackbar de confirmación ("Deuda completada") que aparece sin importar por cuál de los 3 caminos se completó la deuda: el CTA del detalle, el menú de 3 puntos, o el sheet de felicitación automático al llegar a $0.
- El card "Configurar cuota" ya no aparece en una deuda saldada.
- El badge de dirección del detalle ahora también cambia a su forma en pasado ("Me debían"/"Le debía") cuando la deuda está cerrada, igual que ya hacía el de la lista.

## Pagos programados duplicados

- Se corrigió que un pago programado (único o recurrente) ya vencido apareciera dos veces en la hoja "Pagos programados del período" de Presupuestos.

## Categoría en abonos de deuda

- Al registrar un abono o el registro de apertura de una deuda, la categoría se preselecciona automáticamente según la dirección ("Pago de préstamos" / "Cobro de préstamos") y ahora es obligatoria.
- El campo "Categoría" del sheet de abono muestra el ícono y color reales de la categoría elegida, igual que en el resto de la app, en vez de un ícono genérico fijo.

## Navegación

- El tap en el card de una deuda dentro de la lista navega correctamente a su detalle.
- El badge "Enlazada a deuda: <nombre>" en el detalle de una transacción ahora navega al detalle de esa deuda al tocarlo.

## Formulario de edición de deuda

- Cambiar la dirección de la deuda ("Me deben" ↔ "Yo debo") y guardar ya no requiere una segunda pulsación para que el cambio se aplique.
- Cambiar la dirección ya no dispara por error el sheet de "Ya pagaste tu deuda". Si la deuda ya tiene movimientos además de la apertura, cambiar la dirección queda bloqueado con un mensaje de validación (cambiarla reinterpretaría el signo de ese historial).

## Pendiente (decisión consciente, no implementado)

- Desenlazar un pago programado de una deuda: evaluado como técnicamente viable, pero requiere una pantalla nueva y por convención del proyecto debe pasar primero por el diseño en Pencil — queda fuera de esta sesión.

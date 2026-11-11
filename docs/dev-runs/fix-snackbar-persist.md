# Snackbar de "Deshacer" del descarte no se auto-ocultaba (fix-snackbar-persist)

## Síntoma

Reportado por el usuario: al descartar una captura en Avisos, el snackbar "Captura descartada ·
Deshacer" nunca se quitaba solo; quedaba en pantalla indefinidamente.

## Causa raíz

`SnackBar` cambió el default en Flutter 3.38: `persist = persist ?? action != null`. Un snackbar
**con acción** pasa a ser persistente salvo que se pase `persist: false` explícito. El resto del
repo ya lo hacía (Home, Transacciones, Presupuestos, Metas, Pagos programados, Login); el de Avisos
quedó sin esa bandera y por eso no se auto-ocultaba. El timer interno de
`ScaffoldMessengerState` sí corre: el snackbar se descarta cuando `persist` es false.

Nota: `sync_status_page.dart` tiene un workaround previo (Timer manual de 4s) con un comentario que
atribuye el problema al timer del SDK; en realidad es el default nuevo de `persist`. Se deja ese
workaround como está (funciona) — candidato a simplificar en un pase de deuda técnica.

## Fix

| Archivo | Cambio |
|---|---|
| `lib/features/capture/presentation/pages/notices_page.dart` | `SnackBar` del descarte con `persist: false` explícito (y comentario del porqué), manteniendo `duration: 5s`. |
| `test/features/capture/presentation/pages/notices_page_discard_test.dart` | Test de regresión: emite `discardedId`, verifica que el snackbar aparece, avanza 6s y verifica que desaparece sin tocar "Deshacer". Verificado que **falla sin el fix**. |

## Verificación

- `flutter analyze` → sin issues.
- `flutter test test/features/capture` → verde.
- `flutter test test/features/capture/presentation/pages/notices_page_discard_test.dart` → 3/3.
- Test anti-regresión: con `persist: false` removido el test falla (snackbar sigue visible), con el
  fix pasa.

## Pendientes

- Simplificar el workaround de `sync_status_page.dart` con `persist: false` y borrar el `Timer`
  manual, en la próxima pasada sobre Sync.
- Al revisar otros snackbars nuevos, recordar: si lleva `SnackBarAction`, **siempre** `persist: false`
  (salvo que se quiera un snackbar bloqueante a propósito).

## Mensaje de commit sugerido

```
fix(capturas): el snackbar de deshacer se auto-oculta (Flutter 3.38 persist)

SnackBar con acción pasa a persistente por defecto desde Flutter 3.38
(persist = persist ?? action != null). El de Avisos no pasaba persist:false,
así que nunca se cerraba solo. Se agrega y se cubre con test de regresión.
```

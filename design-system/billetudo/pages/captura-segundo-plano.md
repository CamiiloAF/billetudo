# Captura en segundo plano (Android)

**Estado:** claro y oscuro **aprobados** (2026-11-10, A + B) — el usuario aprobó el oscuro explícitamente antes de implementar.
**Fuente de verdad:** `billetudo.pen`, zona de Avisos (`x≈91500` / `x≈92200`).
**Requerimientos:** `docs/requirements/fase-2/19-notificaciones-bancarias.md`, HU-09 (revocación, degradación y estado del servicio).

## Por qué existe

En Android, el `NotificationListenerService` puede dejar de recibir avisos cuando el sistema mata el proceso y **no lo vuelve a bindear** (optimización de batería, y sobre todo fabricantes agresivos). Caso reportado con evidencia en log (Xiaomi/HyperOS, Android 16):

```
I/AutoStartManagerService: MIUILOG- Reject service :Intent { ... BilletudoNotificationListenerService ... }
W/NotificationListeners: AutStart Unable to bind notification listener service: ... BilletudoNotificationListenerService
```

Eso produce el peor estado posible de la feature: el usuario cree que está cubierto y no lo está. HU-09 exige decir la verdad y ofrecer reactivar, sin drama ni insistencia.

La app **no promete capturar el 100%**: el copy de la hoja lo dice explícitamente ("si algo no llega, registralo a mano").

## Superficies aprobadas (A + B)

| Superficie | Cuándo | Frame claro | Frame oscuro |
|---|---|---|---|
| **A · Card de estado en Avisos** | Hay capturas por confirmar y la captura está degradada | `VW54R` — "Captura degradada · card en Avisos (Claro)" | `DSCf0` (Oscuro) |
| **B · Vacío contextual en Avisos** | La sección de capturas está vacía y la captura está degradada | `krE9G` — "Captura degradada · vacío en Avisos (Claro)" | `S0iyTP` (Oscuro) |
| **Hoja de acciones** (compartida por A y B) | Al tocar "Revisar" / "Revisar captura", o la fila de Ajustes | `TPLPN` — "Captura en segundo plano · hoja (Claro)" | `bN2YZ` (Oscuro) |
| **Fila en Ajustes** | Siempre (Android), en Preferencias después de "Avisos de tu banco" | `rN8ye` — "Ajustes · Captura en segundo plano — fila (Claro)" | `lv0iQ` (Oscuro) |

La variante C (pantalla dedicada "Captura en segundo plano") se descartó el 2026-11-10 y se borró del canvas.

## Regla de aparición (degradado)

Solo se evalúa cuando **permiso concedido** y **emisores activos > 0**; los estados existentes (`Permiso · No concedido`, `Emisores`) tienen precedencia y no cambian.

```
degradado =
  (nuncaSeConectó  && minutosDesdeConfiguración >= 5)        // el sistema nunca dejó escuchar
  || (!escuchandoAhora && horasDesdeÚltimaConexión >= 6)     // estaba escuchando y se desconectó
  || (lastCaptureAt == null  && díasDesdeConfiguración >= 3) // configuró y nunca llegó nada
  || (lastCaptureAt != null && díasDesde(lastCaptureAt) >= 7) // dejó de llegar
```

Las **dos primeras señales son directas** y por eso muestran el problema en minutos, no en días:
`lastListenerConnectedAt` lo escribe el propio `NotificationListenerService` en `onListenerConnected`
(cuando MIUI/HyperOS rechaza el bind, queda `null` para siempre) y `listenerConnectedNow` es el
estado en proceso del servicio. Las dos últimas siguen siendo el respaldo heurístico para el caso
"conectado, pero los bancos no mandaron nada". Las cuatro están bajo el mismo prefijo de
precondiciones (permiso + ≥1 emisor + `configuredAt` marcado).

- `lastCaptureAt`: timestamp escrito por el listener nativo en `SharedPreferences` (`billetudo_capture`) en cada aviso aceptado.
- `configuración`: cuando el usuario completa permiso + al menos un emisor (se marca en Flutter, una sola vez).
- **"Ahora no"** oculta la card y el vacío degradado durante **14 días** (preferencia de Flutter). No apaga la captura ni borra nada.
- Si el usuario reinstala, se resetea todo (preferencias del sistema borradas).
- La card **no reemplaza** los estados de permiso/emisores: no se dibuja si alguno falta.
- Si la captura se recupera (llega un aviso nuevo), el estado deja de estar degradado y la card desaparece.

## Fila en Ajustes

Reutiliza el campo de Ajustes (`Appearance Field`, `R8PlN`), después de la fila "Avisos de tu banco"
en Preferencias. Es la vía **permanente** para revisar el estado sin esperar a que Avisos lo detecte.

| Estado | Icono | Wrap / glifo | Título | Sublabel | Tap |
|---|---|---|---|---|---|
| Todo en orden | `shield-check` | `$muted` / `$text-secondary` | "Captura en segundo plano" | "Activa · última captura {relativo}" | Abre la hoja |
| Puede estar detenida | `shield-alert` | `$amber-soft` / `$amber-text` | "Captura en segundo plano" | "Revisá dos ajustes del sistema" (`$amber-text`) | Abre la hoja |
| Falta activar la captura | `bell-off` | `$muted` / `$text-secondary` | "Captura en segundo plano" | "Activa primero los avisos de tu banco" | Permiso / catálogo de emisores |
| Silenciada ("Ahora no") | `clock` | `$muted` / `$text-secondary` | "Captura en segundo plano" | "Silenciada por 14 días" | Abre la hoja igual |

- Chevron siempre visible; la fila mide 64 de alto, igual que el resto de Ajustes.
- La fila no reemplaza a "Avisos de tu banco": esa activa permiso/emisores; esta explica y arregla
  el segundo plano.
- A11y: la fila es un solo nodo (título + sublabel); el chevron es decorativo.

## Copy (es)

**Card (A)**
- Título: "La captura puede detenerse"
- Sub: "Tu teléfono puede cerrar Billetudo cuando no lo usás. Si pasa, no llegan avisos hasta que lo abras."
- Acción primaria: "Revisar" · Acción secundaria: "Ahora no"
- Pie de sección: "Última captura: hoy, 9:19 a. m." / "Todavía no recibimos ningún aviso." (11/500 `$text-secondary`)

**Vacío (B)** — reemplaza "Todo al día" solo en estado degradado
- Mensaje: "Puede que los avisos no estén llegando"
- Subtítulo: "Tu teléfono puede cerrar Billetudo cuando no lo usás. Activá dos ajustes del sistema y seguimos leyendo aunque esté cerrada."
- CTA: "Revisar captura"

**Hoja**
- Título: "Captura en segundo plano"
- Body: "Para que Billetudo lea los avisos aunque esté cerrado, el teléfono no tiene que estar cerrándolo. Se arregla con dos ajustes."
- Fila 1: "Permitir batería" · "Evita que el sistema lo duerma" (icono `battery-charging`)
- Fila 2 (**solo en fabricantes con autostart gestionado por el sistema**, ver abajo): "Abrir inicio automático" · "En {marca}, para que vuelva a escuchar" (icono `rotate-cw`)
- Pie: "Última captura: hoy, 9:19 a. m. Si algo no llega, registralo a mano."
- CTA primaria: "Listo, ya lo activé" · CTA secundaria: "Ahora no"
- Si la batería ya está exenta, la fila 1 pasa a estado cumplido: check `$mint`, sub "Permitido", no navegable.
- Si el fabricante no expone autostart accionable, la fila 2 **no se dibuja** (no se inventa un destino).

## Acciones del sistema

0. **Diagnóstico (`getDiagnostics`)**: `lastCaptureAtEpochMs` (nullable), `batteryOptimizationExempt`,
   `manufacturer`, `autostartAvailable`, `lastListenerConnectedAtEpochMs` (nullable) y
   `listenerConnectedNow`.
1. **Permitir batería** → `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` con `package:` (requiere `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` en el manifest). Si el sistema no ofrece el diálogo, fallback a `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
2. **Abrir inicio automático** → intent explícito por fabricante con fallback a la ficha de la app (`ACTION_APPLICATION_DETAILS_SETTINGS`):
   - Xiaomi/HyperOS: `com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity` (intent `miui.intent.action.OP_AUTO_START`).
   - Huawei/EMUI: `com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity` (fallback `.optimize.process.ProtectActivity`).
   - Samsung: `com.samsung.android.lool/com.samsung.android.sm.ui.battery.BatteryActivity` (fallback `ACTION_APPLICATION_DETAILS_SETTINGS`).
   - Oppo/Vivo/OnePlus/Realme: ficha de la app (sus pantallas de autostart no son deep-linkeables de forma confiable).
   - Otros: fila oculta.
3. **"Listo, ya lo activé"** → re-lee el estado real (exención de batería) y cierra solo si la exención quedó concedida; si sigue sin exención, mantiene la hoja abierta con las filas actualizadas. Nunca asume que el usuario lo activó. La captura se recupera sola cuando llegue el próximo aviso: la hoja no puede exigir una captura nueva para cerrarse.

## Diseño

- Reutiliza: `Notice Card · Con acción` (`cYVQm`) con overrides de icono/copy/acciones, `Empty State` (`jmQO5`), `Page Header` (`Dtm0X`), `Bottom Sheet Base` (`PqTUt`), `Button/Primary` (`j7Zvt`), `Button/Secondary` (`pNjOz`).
- Tokens: `$amber-soft` + `$amber-text` para el estado de atención (icono y acento, nunca texto de cuerpo), `$mint`/`$mint-soft` para filas cumplidas, `$primary-soft` + `$primary-on-soft` para la fila de autostart, `$text-primary`/`$text-secondary` para copy, `$border` para bordes, `$scrim` para la hoja.
- Contraste: icono `$amber-text` sobre `$amber-soft` ≥3:1 en ambos temas (claro ~4.9:1, oscuro ~9.9:1); CTA primaria blanca sobre `$primary` 4.83:1 (ya verificado); secundaria sobre `$muted` con `$text-primary`.
- Tipografía: título card 15/600, body 12/500, labels de acción 13/700, título de hoja 19/700, filas 15/600 + 12/500, pie 11/500.
- A11y: acciones de la card 44 de alto; filas de la hoja 64; la flecha de cada fila es decorativa — el nombre accesible lo da el título + sub; "Ahora no" y "Revisar" tienen label propio; nada depende solo del color (siempre hay icono + texto).

## Pendientes / fuera de alcance

- La pantalla dedicada (variante C) queda descartada.
- Fila de estado en Ajustes: **aprobada e implementada** (2026-11-10, frames `rN8ye`/`lv0iQ`,
  ver `pages/ajustes.md`).
- Tema oscuro de estas superficies: **aprobado** el 2026-11-10 (frames `DSCf0`/`S0iyTP`/`bN2YZ` +
  `lv0iQ`), implementado.
- Ajustes ya aprobó la fila; queda como follow-up del pase de diseño de Ajustes **insertar las
  filas reales** (Notificaciones, Acceso rápido, Widget, "Avisos de tu banco" y esta) en los
  frames de página `aaQBp`/`TQHmY`, que hoy están desactualizados respecto al código.

# Ajustes — overrides sobre MASTER.md

Primera vez que esta pantalla gana su propio `.md` — hasta 2026-07-20 Ajustes vivía sin
documentación de página en `design-system/billetudo/pages/`, aunque el frame ya existía en
`billetudo.pen` y estaba auditado dentro de `docs/dev-runs/fidelidad-ajustes.md`. Este archivo
documenta la primera decisión de diseño con historial propio: el selector de tema.

## Selector de tema (Claro / Oscuro / Sistema)

Reemplaza la fila "Apariencia" anterior (chevron + sublabel derivado de
`Theme.of(context).brightness` + sheet "Próximamente", sin selector real) por una card con
control inline. Decisión de producto: la preferencia persiste **localmente por dispositivo**
(no sincroniza entre dispositivos de la misma cuenta) — primera vez que el proyecto introduce un
mecanismo de persistencia local (`SharedPreferences` o equivalente) en vez de Drift/PowerSync,
porque el tema es una preferencia del aparato, no de la cuenta.

**Variante elegida (de 3 propuestas): Segmented inline.** Las 2 descartadas (sheet con check tipo
selector de moneda, y tiles con círculo) se borraron del canvas de inmediato tras la elección.

### Estructura

Card dentro de la sección "Preferencias", mismo tratamiento visual que las otras cards de esa
sección (`cornerRadius:14`, `padding:[14,16]`, `stroke:$border` 1px, `gap:12`, `Icon Wrap` 44px
`$muted`/ícono `$text-secondary` 20px — el mismo patrón que "Modo sobres" y el campo "Moneda").
La diferencia con "Modo sobres" es de layout, no de token: "Apariencia" apila el control debajo
del label (vertical) porque necesita espacio para las 3 opciones; "Modo sobres" es una fila simple
con switch (horizontal). No es deriva, es la forma correcta para cada contenido.

Dentro de la card: header (icon-wrap + label "Apariencia") y debajo una instancia del componente
reusable `Segmented Control` (`hFu41`, el mismo usado en Gasto/Ingreso/Transferencia del
formulario de Transacciones) con 3 opciones: Claro / Oscuro / Sistema. Sin color semántico (a
diferencia de otros usos del componente) porque Apariencia no tiene uno propio — activo = fondo
`$surface` + `$text-primary`, inactivo = transparente + `$text-secondary`.

Sin sheet, sin pasos extra — un toque sobre la opción la aplica de inmediato.

### Node IDs (tema claro, 2026-07-20)

| Estado de sesión | Frame | Card "Apariencia" |
|---|---|---|
| Con sesión | `aaQBp` | `h4jCV` |
| Sin sesión | `jDaUb` | `B0uqd` |
| Referencia de la variante aprobada | `DVns1` | `f2bJJG` (instancia `S1Yvxc`, `ref: hFu41`) |

### Node IDs (tema oscuro, 2026-07-20)

| Estado de sesión | Frame | Card "Apariencia" |
|---|---|---|
| Con sesión | `TQHmY` | `onPZR` |
| Sin sesión | `j4JYF` | `eabgk` |

Copiadas desde las cards claras ya aprobadas, mismos overrides de contenido (Claro/Oscuro/
Sistema, "Sistema" seleccionado por defecto), recoloreadas automáticamente por vivir dentro de
frames `theme:{mode:"dark"}` — sin hex a mano. El gap de contraste del punto anterior aplica solo
al modo claro; en oscuro los tokens correspondientes dan contraste sustancialmente mayor (texto
claro sobre fondo oscuro), no verificado con número exacto porque la corrección sigue siendo tarea
del componente base, no de esta pantalla.

### Default

"Sistema" queda seleccionado por defecto en el mock — coherente con el comportamiento esperado en
apps sin preferencia guardada aún (mismo patrón que iOS/Android nativos, y consistente con que la
app hoy sigue el tema del sistema sin ninguna preferencia explícita).

### Gap conocido, no bloqueante

El componente compartido `Segmented Control` (`hFu41`) tiene un contraste de ~4.37:1 en el label
del segmento inactivo (`$text-secondary` sobre `$muted`), por debajo del umbral AA de 4.5:1.
Hallado por `ui-ux-reviewer` al auditar esta pantalla — no es un problema introducido por el
selector de tema, es del componente base y afecta también a Transacciones. Ver punto 11 de
`docs/bugfixes.md`. No bloquea esta feature; se corrige a nivel de componente por separado.

Diseño (claro + oscuro, con/sin sesión) cerrado. Listo para `flutter-dev`.

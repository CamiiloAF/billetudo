# Página: Estado de sincronización

Overrides sobre `MASTER.md` para la familia de pantallas y hojas del estado de sincronización (HU-08 en `docs/requirements/fase-1/05-auth-sync.md`). **Diseño cerrado y aprobado el 2026-07-28 (claro y oscuro) e implementado en Flutter** — cerrado también contra `/design-fidelity-check` el mismo día (ver `docs/fidelidad-visual-tracking.md`).

## Tesis (norte del diseño)

Esta feature nace de un incidente real, documentado como **decisión #22** en `docs/requirements/fase-1/05-auth-sync.md`: a Postgres prod le faltaba una columna, la cola FIFO de subida se bloqueó, y durante **3 días la app mostró el ícono de nube girando exactamente igual que una sincronización sana**. El usuario acumuló 89 cambios que solo existían en su teléfono, reinstaló la app y los perdió todos.

De ahí el criterio de éxito, que es literal y manda sobre cualquier consideración estética:

> **"Sincronizando" y "sincronizando desde hace tres días" no pueden verse igual.**

Y la tensión que toda la pantalla resuelve: el usuario debe entender que **sus datos corren peligro**, sin que la app se sienta rota ni lo culpe. El hecho es **geográfico, no moral** — nadie falló; unos datos están en un lugar y no en el otro.

## Frames

### Pantalla (apilada desde Ajustes; `Page Header`, sin `Tab Bar`)

| Estado | Claro | Oscuro |
|---|---|---|
| Atención (registros trabados) | `hE3Ds` | `sTebL` |
| **Sin contacto con la nube** (`stale`) | `Pe8V9` | `f2roK0` |
| Todo bien | `AGwSd` | `BwHgf` |
| Carga / skeleton | `KgGHB` | `nTlwj` |
| Nunca sincronizó | `Ux4Eo` | `reRjw` |
| Sin conexión | `tUQR4` | `R72Lm` |
| Sin sesión | `b0O9jr` | `YHUON` |
| Atención · 89 pendientes | `MG3eK` | `psOSC` |
| Lista completa de pendientes | `rxUil` | `xA9X1` |
| **Lista completa · vacía** | `wcrqA` | `Z1ws4n` |
| Sincronizando en curso | `p26K0` | `R5mjuG` |
| Resultado · todo al día | `J0B0e` | `zqXq8` |
| Resultado · no se pudo subir | `SZgd4` | `aqybA` |

### Hojas (indicador de la nube del Home)

| Hoja | Claro | Oscuro |
|---|---|---|
| Sincronizado | `DUSmQ` | `IKuAn` |
| Sincronizando | `uYVmf` | `zPkt8` |
| Sin conexión | `n1qFs` | `IrLj4` |
| Registros trabados | `MEcVH` | `ISnfN` |
| Sincronizando hace demasiado | `W4oGp` | `G6yA34` |
| **Silencio prolongado (`stale`)** | `kvytN` | `iWlff` |
| Registro técnico | `T7Iw0C` | `ShmG5` |
| Detalle de la operación | `r1qQYc` | `YzMN5` |

### Referencias de contrato (📐 andamiaje permanente, no se implementan)

`C5zm5m` indicador · 4 estados · `t1391g` fila "Última sincronización" · 4 casos · `LDgAm` Sync Pending Row · variantes y contenido largo · `z6MVC`/`INpYD` CTA sincronizando.

### Punto de entrada

Fila "Estado de sincronización" con sublabel "Última sincronización: hace 5 minutos", en Ajustes → sección "Cuenta y respaldo", bajo la `Session Card` (`STxah` en `aaQBp`). **No existe en Ajustes sin sesión** (`jDaUb`): ahí la invitación correcta es "Respaldar en la nube", y agregar una entrada al diagnóstico convertiría una invitación clara en un rodeo.

## Componentes creados para esta feature

**`VtiBc` — Sync Pending Row.** Slots: `W7CR6` icono de la entidad, `sP3fj` Title, `t80B5` Meta, `z8DWW` Chevron (on por defecto), `ni93C` Footer (off). Fijo: `$amber`/`$amber-soft`, radio 16, padding `[14,16]`, alto ≥72px. **La fila entera es tocable** y abre la hoja de detalle; el chevron no es el target. Title y Meta: una línea con ellipsis cada uno (`Expanded` + `maxLines:1`).

**`saRZW` — Sync Indicator.** Área fija 44×44, `layout:none`. Nodos: `hwMFm` glifo 18px, `T4cfKB` Dot Ring, `jZHhi` Dot. Override por path anidado: `Update('<instancia>/Qm9Zq/hwMFm', …)`.

| Estado | Glifo | Color | Dot |
|---|---|---|---|
| Sincronizado | `cloud-check` | `$text-secondary` | off |
| Sincronizando | `refresh-cw` | `$text-secondary` | off |
| Sin conexión | `cloud-off` | `$text-secondary` | off |
| **Atención** | `cloud-alert` | `$amber` | **on** |

**`UtO4B` — Sync Skeleton Row.** Único override: `SZfll` y `v9s2LT` (anchos de línea, para variar entre filas). Replica la geometría real de `VtiBc`. Rellenos siempre `$skeleton`, nunca `$border`.

**`XxHV3` — Sync Hero.** Slots: `rZGDr`/`Nr8UU` Icon Wrap + Icon, `C45uQZ` Title 19/700, `ETLeL` Kicker 13/600, `j1QIm` Body 13/500, `fwn43` Time Row (instancia de `AGZry`), `L5io11` **CTA Slot — se reemplaza entero**, `RBT2p` CTA Caption (off). Root: `$surface`+`$border` en los neutros, **`$amber-soft` sin borde** en los de atención. Fijo: radio 24, padding 20, gap 12, wrap 48px.

## Reglas por pantalla

### Color y semántica (overrides duros sobre MASTER)

- **Nunca `$expense`.** El rojo se reserva a lo destructivo, y esta pantalla no tiene ninguna acción destructiva. La atención se codifica con `$amber` — atención sin castigo.
- **`$primary` significa "la nube".** Por eso la fila "Guardar una copia" usa **`$teal`** (archivo local) y **ningún CTA de sync lleva violeta**: el CTA de atención es `Button/Neutral` sólido y el de estado sano es `Button/Secondary` enteramente neutro. Se evaluó un glifo violeta en el CTA sano y **se descartó — no reintroducir**.
- **Única excepción:** el `Button/Primary` violeta de "Iniciar sesión" en el estado sin sesión. Ahí no rompe la regla, la usa: iniciar sesión *es* activar la nube.
- La jerarquía entre los dos CTA se codifica **solo por peso** (sólido = reparar, hueco = forzar), señal que sobrevive a la escala de grises.
- **El CTA hueco sobre `$amber-soft` está medido y aceptado (2026-07-28).** El estado `stale` es el primer caso de la familia donde un `Button/Secondary` (relleno `$surface`) se apoya sobre el hero ámbar, así que se verificó explícitamente: **label 15.7:1 en claro y 14.1:1 en oscuro**. La *forma* del botón queda en 1.10:1 / 1.23:1, bajo el 3:1 de objeto gráfico — pero es el límite sistémico ya decidido en `MASTER.md` §Contraste del chrome, no un defecto de este frame, y de hecho es **mejor** que el CTA inerte que esta misma spec ya aceptaba (1.06:1 / 1.13:1). **No parchear**: teñir el botón o darle borde de color reintroduciría la jerarquía cromática que la familia decidió no tener, y solo en una pantalla.

### Comportamiento (no se lee del frame)

- **Umbral ámbar: 24 h.** Hasta ahí la fila de tiempo va en `$text-primary`; a partir de ahí label e ícono pasan a `$amber-text`. Fraseo siempre relativo ("hace 3 días"), nunca fecha absoluta.
  - **Sin excepción por estado.** La auditoría del 2026-07-28 encontró que el estado de atención pintaba la fila en ámbar *siempre*, sin mirar la antigüedad: con la última sincronización hace 5 minutos se veía igual que con 3 días. Eso reintroduce, dentro del propio estado de atención, el problema que la HU-08 existe para resolver, y de paso desgasta el ámbar encendiéndolo cuando nada es aún preocupante. El color **se deriva de `SyncFreshness.isStale`**, nunca se fija en la rama de un estado — una sola fuente de verdad para el umbral.
  - **El umbral tiene además su propia cara de pantalla**, no solo efecto sobre la fila: el estado `stale` (sin pendientes, más de 24 h sin sincronizar). Existe para que la pantalla no contradiga al indicador del Home, que se pone ámbar con ese mismo dato.
- **La fila de tiempo se muestra en los cuatro estados**, también cuando todo va bien. Si solo apareciera al fallar, el usuario no tendría con qué comparar — es la lección literal del incidente.
- **Nunca sincronizó** es informativo, no error: `$text-secondary`, **cero ámbar**, hero con `cloud-upload` sobre `$primary-soft`.
- **Prioridad de estados:** si hay cambios sin subir **y** no hay conexión, manda el estado de atención. El riesgo pesa más que la causa.
- **De 3 a 89 pendientes la lista NO crece.** Se queda en 3 filas (las más antiguas: muestra, no resumen) más el enlace "Ver los 89" hacia `rxUil`. Motivo medido: hero + "Guardar una copia" terminan a 530px de un viewport de 972; con 89 filas, **la única protección real quedaría fuera de pantalla justo cuando más importa**. El contador vive en dos sitios a propósito (título del hero y enlace de sección).
- `rxUil` es **la única pantalla de la familia donde el scroll es esperado**.
- **El CTA en curso** cambia glifo (`refresh-cw` → `loader-circle`) **y** rótulo ("Sincronizando…"). Dos señales, ninguna cromática. Va **inerte, no oculto**: quitarlo desplazaría el layout entre estados.
- **El hero no se reescribe optimistamente mientras sincroniza**, y la lista no se vacía de golpe: las filas desaparecen una a una al confirmar cada operación. El resultado se comunica con snackbar, nunca cambiando el hero en silencio. *Repintar optimistamente es el modo de falla exacto del incidente #22.*
- **Rótulo del CTA en reposo:** "Reintentar ahora" si hubo intentos fallidos, "Sincronizar ahora" si todo está sano. Llamarlos igual borraría la historia de intentos.
- **No existe "Descartar"** en ninguna superficie. Nada de esta pantalla destruye datos que solo viven en el dispositivo. Consecuencia asumida: un registro que nunca pueda subir permanece en la lista. *Decisión abierta:* si hace falta un "archivar" que lo conserve y lo saque de la lista activa.
- **La pantalla no consulta la red para pintarse** — lee la cola local. Por eso no tiene estado de error propio. El skeleton existe solo porque leer `ps_crud` + cuarentena es I/O de SQLite; si la lectura es inmediata, no se ve.
- **Jerga técnica solo en `T7Iw0C`.** Códigos (`PGRST204`), nombres de tabla y timestamps ISO están prohibidos en las filas y en la hoja de detalle. El registro técnico debe poder exportarse o copiarse.
- **"Guardar una copia" navega a Importar y exportar (`oSWz9`)**, no abre hoja propia. Respeta la nomenclatura de `11-import-export.md`: **la nube es el *respaldo*, el archivo es la *copia*** — nunca decir "haz un respaldo" para el archivo, y menos en la pantalla que existe porque el respaldo falló.
- **Sin sesión** no es alcanzable desde el flujo normal; `b0O9jr` es el fallback honesto de cerrar sesión con la pantalla en la pila.

## Notas de accesibilidad (verificadas por `ui-ux-reviewer`)

- **El cuarto estado del indicador se lee sin color.** A 18px `cloud-alert` y `cloud-check` tienen silueta parecida, así que **la señal no cromática fiable es el punto** — no quitarlo. El `Dot Ring` va en `$background` y funciona por **recorte**: abre ~2px de aire entre el punto y el glifo. **Solo funciona mientras el indicador esté sobre `$background`**; si se coloca sobre `$surface` o sobre el hero, hay que reapuntar el `fill` del anillo al fondo real.
- Contrastes claro: `$amber-text`/`$surface` 5.12:1 · `$amber-text`/`$amber-soft` 4.65:1 · `$segment-inactive-text`/`$muted` 5.46:1 · CTA neutro 15.7:1.
- Contrastes oscuro: título del hero 12.08:1 · cuerpo 4.77:1 · `$amber-text` 9.87:1 · `$segment-inactive-text` 5.39:1 · CTA neutro 16.58:1 · `$primary-on-soft`/`$surface` 6.03:1.
- **Nunca `$primary` crudo como texto o glifo en oscuro:** mide 3.005:1 sobre `$surface` y rompe AA. Usar `$primary-on-soft` (`#A78BFA`).
- **Límite heredado, aceptado a conciencia:** el relleno `$muted` del CTA inerte da 1.06:1 sobre `$amber-soft` (1.13:1 en oscuro) y el borde no lo resuelve. El botón se identifica por su **label**, que sí cumple. Es el mismo límite que `Button/Secondary` arrastra en todo el sistema — ver §Contraste del chrome en `MASTER.md`.
- Tap target del indicador: 44×44 (antes era un ícono suelto de 18px sin área de toque).

## Notas de UX review cerradas (2026-07-29)

- **Link "Ver los 89" (`MG3eK`/`psOSC`) sube a peso 700.** Iba en `$text-primary` peso 600, igual que el resto del texto — perdía la señal de afordancia de "Ver todos" que en el resto del producto se resuelve con `$primary-on-soft`, color que esta pantalla no puede usar (`$primary` = la nube). Se corrige solo con peso, sin tocar color.
- **Skeleton `KgGHB`/`nTlwj` se acepta tal cual.** Dibuja hero + 3 filas — la silueta del estado de atención — aunque el caso común (cola local vacía) termine en "todo sincronizado". Geometría correcta (I/O de SQLite es lo único que justifica el skeleton) y el estado dura poco; se documenta el matiz de tono como decisión consciente en vez de rediseñar a un skeleton solo-hero.
- **Margen ajustado en `MG3eK`/`psOSC` (89 pendientes), aceptado sin fix.** Contenido a 854px contra 834px disponibles (los 27px extra vienen del padding de tap target del link "Ver los 89"). No se recorta nada hoy; queda anotado por si una fuente de sistema ampliada o un dispositivo más corto lo hace entrar en scroll — en ese caso, la salida sería colapsar "Diagnóstico".
- **`t1391g` ganó un 5º caso** (`k1HsDg`, "Sin sesión · informativo"): el contrato de referencia solo documentaba los 4 casos de la fila de tiempo (Normal ×2, Atención, Nunca sincronizó) y le faltaba el de `b0O9jr` — icono `cloud-off` + "Sin sincronización activa" en `$text-secondary`, neutral porque no es un estado de atención.

## Pendientes

- **8 íconos de sync sueltos** en headers aún reconstruidos a mano fuera de Inicio (Notificaciones, Balance V2 y sus oscuros): ninguno mostraría el cuarto estado.
- **No diseñado:** la animación de giro del `loader-circle`, el gesto de scroll de `rxUil`, y la hoja de "archivar" (decisión de producto abierta).
- Las 7 hojas no dibujan el dispositivo tras el scrim — convención heredada del mockup, igual en ambos temas.

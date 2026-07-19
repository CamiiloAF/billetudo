# Página: Primer arranque — sin conexión

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** **Aprobada (2026-07-17, `ui-ux-reviewer`) — 1 hallazgo importante y 3 menores, todos resueltos.** Ambos temas listos.

## Contexto de producto

Excepción puntual a que la app funcione sin conexión (HU-01 de `docs/requirements/05-auth-sync.md`): en el **primerísimo arranque**, antes de que exista ninguna categoría local, la app necesita bajar el catálogo semilla desde Supabase (`category_seeds`, ver `05-auth-sync.md` decisión #12 y `02-categorias.md` HU-06). Sin conexión en ese momento puntual, se bloquea con esta pantalla en vez de sembrar con una copia local desactualizada.

**Copy deliberadamente agnóstico**: no menciona categorías, sincronización, servidor ni ningún detalle técnico — se enmarca como "terminar de configurar tu cuenta", suficiente para transmitir que es importante sin exponer implementación. Decisión de producto, no ausencia de información.

## Frames

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) | Estado |
|---|---|---|---|
| Primer arranque — Sin conexión | `KSkpO` | `zeAfp` | Decisión final, ambos temas. Instancia de `Empty State` (`jmQO5`) con overrides — icono `wifi-off`, título "Conéctate para continuar" (16/700), subtítulo "Necesitamos conexión a internet para terminar de configurar tu cuenta. Cuando tengas señal, vuelve a intentarlo." (14/500) — más botón `Reintentar` (`qiTl2`) full-width como hermano (el CTA interno de `Empty State` queda deshabilitado en esta instancia). |
| Botón — estado "Reintentando" (referencia) | `wbrdu` | `pimwT` | Solo referencia visual standalone, no interacción real de Pencil. Mismo patrón que "Auth — Login Android: Cargando" (`QD8kh`), ícono `loader-2` + label "Reintentando...". `flutter-dev` implementa el toggle normal/cargando en código. |

## Decisión de componente: `Empty State` ganó soporte de subtítulo opcional

La primera versión de esta pantalla mezclaba a mano el tratamiento de ícono de `Empty State` con la estructura de texto de `Error State`, creando un tercer patrón no documentado (hallazgo `[IMPORTANTE]` de `ui-ux-reviewer`, 2026-07-17). Se resolvió **extendiendo el componente reusable** `Empty State` (`jmQO5`) con un nodo `Subtitle` opcional (id `fKrxF`, 14/500, `$text-secondary`, `enabled:false` por defecto) en vez de inventar un patrón nuevo. Las 3 instancias previas de `Empty State` (Cuentas vacío, Archivadas vacío, Movimientos vacío) no overridean `fKrxF` y siguen renderizando igual que antes — verificado sin regresión.

Si aparece otra pantalla con el mismo patrón (icono + título + subtítulo, sin card envolvente), reusar esta misma instancia extendida en vez de duplicar estructura.

## Tema oscuro

Sin ajustes manuales de color: ambos frames oscuros (`zeAfp`, `pimwT`) son `Copy()` del frame claro con `theme:{mode:"dark"}` — mismo patrón que el resto de pantallas oscuras del sistema (`Empty State`/`Error State` resuelven sus variables por tema automáticamente, sin overrides en los descendientes).

## Pendiente (fuera de Pencil)

- Interacción real del botón "Reintentar": qué dispara, cómo se muestra el estado "Reintentando..." (¿inline en el mismo botón, o algo más?) — a resolver en `flutter-dev` al implementar, contra `SeedDefaultCategories`/`NetworkFailure` ya listos en código (ver `05-auth-sync.md` decisión #12).
- Detalle menor no bloqueante: el ícono `loader-2` se renderiza como "?" en el screenshot estático de Pencil tanto en la referencia clara como oscura — quirk del renderer de Pencil para ese ícono específico, no afecta la implementación real en Flutter (el ícono mapea y anima correctamente en la app).

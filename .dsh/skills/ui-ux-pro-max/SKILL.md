---
name: ui-ux-pro-max
description: "Base local de inteligencia UI/UX consultable por CLI (50+ estilos, 161 paletas, 57 pares tipograficos, 161 tipos de producto, 99 guias UX, 25 tipos de chart y reglas por stack, incluida Flutter). Referencia para disenar, construir y revisar UI: accesibilidad, touch, tipografia, color, layout, animacion, charts y navegacion. No es la autoridad del proyecto: mandan design-system/billetudo/ y billetudo.pen."
whenToUse: "Usalo al disenar o revisar UI (jerarquia, a11y, color, tipografia, layout, animacion, charts, navegacion) o cuando ui-ux-reviewer audite el canvas. No para backend, datos, infra ni performance no visual."
metadata:
  source: claude-code
  original: .claude/skills/ui-ux-pro-max/SKILL.md
---

# UI/UX Pro Max — base local de inteligencia de diseño

Catálogo local consultable por CLI. **No es la autoridad del proyecto**: mandan
`design-system/billetudo/MASTER.md` + `pages/<pantalla>.md` + las variables de
`billetudo.pen`. Esta base sirve para contrastar decisiones, evitar anti-patrones y no
inventar criterio de UX/a11y.

## Cuándo usarla

- Revisar jerarquía, accesibilidad, touch targets, tipografía/color o layout de una pantalla.
- Elegir estilo/paleta/fuente o patrones de un tipo de producto.
- Reglas Flutter (widgets, estado, navegación) vía `--stack flutter`.
- **No** usar para backend, datos, infra o performance no visual.

## Cómo consultarla (CLI, Python 3 stdlib)

```bash
# diseño completo: pattern + style + color + typography + anti-patterns
python3 .dsh/skills/ui-ux-pro-max/scripts/search.py "<producto> <industria> <keywords>" --design-system [-p "Nombre"]

# guardar el resultado como MASTER + overrides por página
python3 .dsh/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Nombre" [--page "dashboard"]

# diales opcionales 1-10: variance / motion / density
python3 .dsh/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --variance 8 --motion 7 --density 8

# búsqueda por dominio
python3 .dsh/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --domain <domain> [-n <max>]

# reglas por stack (este repo: flutter)
python3 .dsh/skills/ui-ux-pro-max/scripts/search.py "<keywords>" --stack flutter
```

`python3` (o `python` en Windows). Si falta Python, **no lo instales**: pedile al usuario que
lo instale y, mientras tanto, usá el checklist de abajo (no requiere CLI).

### Dominios

| Dominio | Para |
|---|---|
| `ux` | accesibilidad, touch, z-index, loading, anti-patterns |
| `style` | estilos y efectos (glassmorphism, minimalism, dark mode…) |
| `color` | paletas por tipo de producto |
| `typography` | pares de fuentes / Google Fonts |
| `product` | patrones por tipo de producto |
| `landing` | estructura de página y CTA |
| `chart` | tipos de chart y librerías |
| `web` | guías iOS/Android/React Native (touch, safe areas, a11y) |
| `google-fonts` | fuente individual |
| `react` | performance React/Next (no aplica a este repo) |
| `prompt` | keywords de estilo para prompt/CSS |

### Stacks disponibles

`ls .dsh/skills/ui-ux-pro-max/data/stacks/`. Para este repo: **`flutter`**. Otros:
`react`, `nextjs`, `vue`, `nuxtjs`, `nuxt-ui`, `svelte`, `astro`, `shadcn`, `html-tailwind`,
`angular`, `laravel`, `swiftui`, `jetpack-compose`, `react-native`, `threejs`.

## Checklist de revisión (prioridad alto → bajo)

1. **Accesibilidad** — contraste ≥4.5:1 (≥3:1 texto grande/iconos), foco visible, alt/aria, jerarquía h1→h6.
2. **Touch** — targets ≥44×44pt (iOS) / 48×48dp (Android), ≥8px de separación, feedback de tap 80–150ms, sin depender de hover.
3. **Performance visual** — lazy load, espacio reservado (CLS), sin thrashing de layout, imágenes optimizadas.
4. **Estilo** — coherencia con el sistema, iconos vectoriales (no emoji), un estilo de icono por nivel, sin mezclar flat/skeuomorphic.
5. **Layout** — mobile-first, sin scroll horizontal, sin anchos fijos en px, safe areas y system bars respetadas.
6. **Tipografía/color** — base 16px, line-height 1.5, tokens semánticos, sin hex crudo.
7. **Animación** — 150–300ms con easing nativo, con significado, respeta reduced-motion.
8. **Forms** — labels visibles, error junto al campo, helper text, feedback progresivo.
9. **Navegación** — back predecible, bottom nav ≤5, deep links.
10. **Charts** — leyenda/tooltips, color accesible, no depender solo del color.

## Checklist de cierre por pantalla

- [ ] Estados vacío/carga/error definidos (no solo el happy path).
- [ ] Texto largo/desbordado no rompe el layout; medido en 375px y landscape.
- [ ] Contraste verificado en claro **y** oscuro por separado (no se infiere de un tema).
- [ ] Modales/scrims con opacidad suficiente (≈40–60% negro) para aislar el foreground.
- [ ] Iconos: vectoriales, una familia, tamaño por token, alineados al texto.
- [ ] Pressed/focused/disabled visualmente claros y sin saltar el layout.
- [ ] Scroll no queda oculto detrás de headers/tab bars/CTA fijos.
- [ ] a11y: labels en iconos significativos, roles/estados anunciados, reduced-motion y Dynamic Type sin romper.

## En DeepSeek Harness

- Invocación: `/ui-ux-pro-max` o tool `skill`.
- Recursos: scripts en `.dsh/skills/ui-ux-pro-max/scripts/`, datos en `.../data/`. Resolvé
  rutas relativas contra la raíz del repo (`.dsh/skills/...`).
- Delegación: `ui-ux-reviewer` y `pencil-designer` (`.dsh/agents/`) la cargan como referencia.
- Contrato: `CLAUDE.md` + `AGENTS.md`; el sistema de diseño real y las variables del `.pen`
  mandan sobre esta base.
- Nunca commitees: deja los cambios sin commitear.

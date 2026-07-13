# Pagina: Inicio

Sobreescribe/complementa `design-system/finance-app/MASTER.md` con detalle especifico de esta pantalla. Fuente real: `billetudo.pen`.

## Frames en Pencil

| Frame | Node ID | Tema | Estado |
|-------|---------|------|--------|
| Inicio - Final (Claro) | `zVI9r` | claro | con datos |
| Inicio - Final (Oscuro) | `wyYlm` | oscuro | con datos |
| Inicio - Vacio (Claro) | `ubNzu` | claro | vacio |
| Inicio - Vacio (Oscuro) | `L3wAFz` | oscuro | vacio |
| Inicio - Error (Claro) | `yMJtY` | claro | error |
| Inicio - Error (Oscuro) | `i7M4r` | oscuro | error |
| Inicio - Carga (Claro) | `Irsdk` | claro | carga |
| Inicio - Carga (Oscuro) | `ACNlG` | oscuro | carga |

Las versiones oscuras son `Copy()` de su equivalente claro + `theme:{mode:"dark"}` — no tienen contenido propio, cualquier cambio de contenido/estructura debe hacerse en el frame claro y luego re-copiarse (o aplicarse igual a ambos si ya divergieron, como en estos 4 pares).

## Estructura (estado con datos)

De arriba a abajo, dentro del wrapper `Content` (padding `[6,20]`, gap `18`):

1. **Status Bar** — hora + iconos de sistema (`$text-primary`).
2. **Header** — Avatar (gradiente `$primary`→`$primary-deep`, inicial del usuario) + saludo ("Buenos dias" / nombre) + boton de notificaciones (`$surface`, icono `bell`).
3. **Hero Card** — gradiente `$primary-deep`→`$primary`, radio 28. Contiene: label "Gastado en [mes]" + selector de mes, monto grande (42px/800), barra de progreso de presupuesto mensual, texto "X% de tu presupuesto" / "de $Y".
4. **AI Assistant** (`$muted`, borde `$border`) — orb con icono `sparkles` (gradiente `$primary`→`$primary-deep`→`$primary`), titulo "Preguntale a Billetudo", 2 `AI Question Chip` instanciados.
5. **Card "Por categoria"** (`$surface`, radio 24, width fijo 350 — ver nota de robustez abajo) — titulo + link "Ver todo", lista de 4 `Category Row`: Vivienda (`$primary`/`$primary-soft`), Comida (`$mint`/`$mint-soft`), Transporte (`$sky`/`$sky-soft`), Ocio (`$peach`/`$peach-soft`).
6. **Tab Bar** — instancia con "Inicio" activo.

Datos de ejemplo usados: balance `$1,297,900`, presupuesto `$3,000,000` (43%), categorias suman exactamente el balance (620k+340k+185k+152.9k). Mantener esta invariante (categorias = total gastado) en cualquier dato de ejemplo futuro — fue la base para detectar y corregir el bug de barras de progreso que no coincidian con el %.

## Decisiones especificas de esta pagina

- **Paleta violeta ganadora sobre indigo/azul/verde/coral**: se probaron 5 variantes de color (`v12b` verde, `v12c` coral, `v12d` indigo, `v12e` azul) sobre la misma estructura y se descartaron. Razon: colision semantica con verde=ingreso/rojo=gasto, mayor cohesion del violeta con el fondo lavanda, mas distintivo que el azul generico de fintech, mas cercano a patrones de fintech ya familiares en Colombia (Nequi).
- **Sin selector de paleta para el usuario final** — decisión de producto, no solo de diseño: se evaluo dejar que el usuario elija color de marca y se descarto para el lanzamiento (mas superficie de QA visual, diluye reconocimiento de marca). Si se retoma, encaja como extra cosmetico detras de Premium, nunca como gate de una funcion de Nivel 0.
- **width:350 fijo en la Card de categorias** (en vez de `fill_container`) — anotado como hallazgo menor pendiente, funciona hoy porque coincide numericamente con el padding del Content (390 - 20*2 = 350), pero es fragil ante cambios de layout futuros.

## Estados vacio/error/carga — copy usado

- **Vacio:** Hero en "$0" / "Aun no tienes gastos este mes". Card de categorias reemplazada por icono `wallet` + "Aun no registras gastos" + subtexto + boton "Agregar gasto". Chips de IA cambiados a preguntas de onboarding ("¿Como registro mi primer gasto?", "¿Que es un presupuesto?").
- **Error:** Hero y AI Assistant ocultos. Tarjeta centrada: icono `cloud-alert` sobre `$expense` al 10% de opacidad, "No pudimos cargar tu informacion", subtexto que aclara que los datos siguen guardados localmente, boton "Reintentar" (`$primary`).
- **Carga:** Hero y AI Assistant mantienen su forma/fill pero con bloques `$border` en vez de contenido real; 4 filas skeleton (circulo + 2 lineas + barra corta) en la Card de categorias.

## Pendientes conocidos (no bloqueantes, ver checklist de MASTER.md)

- Ancho fijo de la Card de categorias (ver arriba).
- Tap target de ancho <44pt en 3 items del Tab Bar (Inicio/Metas/Mas) — corregir en la implementacion Flutter asegurando que el gesto cubra el slot completo, no solo el contenido visual.

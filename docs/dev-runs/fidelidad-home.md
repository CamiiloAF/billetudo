# Fidelidad visual — Home / Dashboard

Corrida `/design-fidelity-check home` (2026-07-20), ítem 8 de `docs/bugfixes.md`.
3 pasadas de `pencil-fidelity-reviewer`, con fixes de `flutter-dev`/`pencil-designer` entre cada una.

## Bug de crash encontrado durante la generación de goldens (no era hallazgo de fidelidad)

`HomeHeroCard` se construía con `state.spending!` condicionado a `state.isLoading` (`status ==
loading`), pero un `HomeStatus.failure` en la primera carga (sin snapshot todavía) también deja
`spending == null` — `isLoading` es `false` ahí, así que el null-check truena. Corregido:
condicionar a `state.spending == null` en vez de `state.isLoading`, cubre ambos casos sin
necesidad de rama especial para `failure`.

## Ronda 1 — auditoría inicial

4 hallazgos **CRÍTICO**, 5 **IMPORTANTE**:

1. Formato de dinero: hero y filas de "Movimientos recientes" con `.format()` ("COP") en vez de
   `.formatSymbol()` ("$").
2. Gastos recientes sin signo "-" (comentario en código decía "sin signo, según Pencil" —
   desactualizado, el `.pen` vigente sí muestra signo).
3. "Movimientos recientes" aparecía en carga y vacío, donde Pencil no lo muestra.
4. Estado "con presupuesto" del hero (barra de progreso) no implementado — **diferido a
   petición del usuario**, no se corrige en esta corrida.
5. `MoreRow` sin línea de descripción (estructura de fila incompleta, no solo estilo).
6. Fila extra "Gráficas e informes" + badges "Próximamente" (Deudas, Importar y exportar) en el
   código sin respaldo en el `.pen` — ya señalado como deuda de diseño en un comentario del
   propio código.
7. Ícono equivocado en la pestaña "Más" (`layoutGrid` en vez de `ellipsis`).
8. Borde extra no diseñado en la tab bar.
9. Etiquetas truncadas ("Movimient…", "Presupues…") por tamaño de fuente incorrecto.

## Ronda 1 — fixes

- `pencil-designer`: agregó la fila "Gráficas e informes" (`chart-line`, "Visualiza tus finanzas
  con gráficas") a `gXcHt`/`X9x7x`, y un componente nuevo reusable `Badge/Próximamente` (`yfvHv`)
  aplicado a Deudas/Gráficas e informes/Importar y exportar. Incidente menor: reestructurar
  `Appearance Field` (`R8PlN`, ~20 instancias) borró momentáneamente los overrides de título de
  todas ellas — detectado y corregido en la misma corrida, documentado como advertencia de
  mantenimiento en `design-system/billetudo/pages/auth.md`.
- `flutter-dev`: `formatSymbol()` en hero/filas, signo en gastos, `RecentActivityHeader`
  condicional a `ready && !isEmpty`, `MoreRow` con parámetro `description`, ícono `ellipsis`,
  `boxShadow` en vez de `Border.all` en la tab bar, `fontSize: 9` en las etiquetas.
- `qa-automator`: 22 goldens generados/regenerados, 125 tests en verde.

## Ronda 2 — re-verificación

Los 8 hallazgos corregibles: confirmados resueltos (incluida la fila nueva "Gráficas e informes"
con su badge, en la posición correcta). El ítem diferido (hero "con presupuesto") se reabre como
hallazgo conocido, no regresión.

3 hallazgos nuevos **IMPORTANTE** + 1 **MENOR**:
- Ícono equivocado en pestaña "Movimientos" (`receipt` en vez de `arrow-left-right`).
- Ícono equivocado en pestaña "Metas" (`flag` en vez de `target`).
- Texto truncado en las 3 filas "Próximamente" de "Más" — el badge compartía ancho con la
  descripción, no solo con el título.
- Copy del selector de mes: "Elegir mes" vs. "Selecciona el mes" en Pencil.

## Ronda 2 — fixes

- `flutter-dev`: íconos de tab bar corregidos, `MoreRow` reestructurado (badge en fila propia
  junto al título, descripción a ancho completo debajo), copy del selector de mes corregido.
- `qa-automator`: goldens regenerados, 2 tests de aserción de texto ajustados, + cobertura nueva
  (transacción `income` en `home_page_with_data` para fotografiar el signo "+").

## Ronda 3 — persistía el truncado en 2 de las 3 filas con badge

Verificación puntual: "Deudas" ya no truncaba, pero "Gráficas e informes" e "Importar y exportar"
(títulos más largos) seguían cortándose. Causa raíz real (no la misma del hallazgo anterior):
tres desviaciones acumuladas frente a Pencil restaban ~16-18px al bloque de título — chevron sin
tamaño explícito (24px por defecto vs. 20px en Pencil), un `SizedBox(width: 8)` fijo antes del
chevron que no existe en el diseño (la fila real es `space_between` dinámico), y `ComingSoonBadge`
con padding/radius de pill en vez de los valores reales del componente `Badge/Próximamente`
(`yfvHv`: padding 8, `cornerRadius` 8, no 999). De paso se corrigió el icon-wrap (44×44/radius 22,
antes 40×40/radius 16) — no causaba el truncado pero era una desviación real.

Re-verificado tras el fix: título completo en las 3 filas, sin hallazgos pendientes.

## Veredicto final

**🟡 Parcial** (bloqueado únicamente por el ítem diferido a propósito). Todos los hallazgos
corregibles quedaron cerrados y re-verificados en 3 rondas. Único punto abierto: el estado "con
presupuesto" del hero (barra de progreso, `aOhoY`/`ls7Ed`) sigue sin implementar — decisión
explícita del usuario de dejarlo para otra sesión, no un hallazgo sin resolver por descuido.

### Gaps de cobertura conocidos, no bloqueantes

- `home_page_error_*`: sin frame de referencia en Pencil (HU-10 solo documenta un indicador
  discreto, no esta vista de pantalla completa).
- Sheets "Próximamente" de IA (`ZMNrt`/`Tr8ZF`) y notificaciones (`HZTCs`/`Z7WpGJ`): documentados
  en `inicio.md` pero sin golden en `test/features/home/`.
- Íconos por categoría en "Movimientos recientes": el mapeo real es correcto, el fixture de test
  no varía ícono/color entre categorías — limitación de cobertura, no de fidelidad.

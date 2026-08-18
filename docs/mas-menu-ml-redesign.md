# Rediseño de "Más" estilo Mercado Libre — PARQUEADO

**Estado:** exploración de diseño hecha en `billetudo.pen` (tema claro), **parqueada**. Se retoma como iniciativa aparte con otro agente. **No es parte del lote de Metas.**
**Fecha:** 2026-07-24.

## Motivación

Salió del reanálisis de navegación (ver `docs/requirements/fase-1/04-inicio.md` § Nota de navegación 2026-07-24 y `docs/fixes/bugfixes-0.0.1.md` item 7): al devolver **Metas al slot 4** del bottom nav, Pagos programados vuelve a "Más". Un usuario que navega seguido a Pagos reportó fricción por tenerlo un nivel adentro. En vez de darle a Pagos un tab propio (se descartó el drawer lateral: menos alcanzable que "Más"), se decidió **enriquecer "Más"** como un menú navegable estilo Mercado Libre, para que Pagos y el resto de destinos de gestión se alcancen mejor sin inflar el bottom nav.

## Referencia

Menú de la app de Mercado Libre: **header de marca** (bloque de color con avatar + nombre + "Mi perfil ›") + **cards de CTA prominentes** (meli+ / Mercado Pago) + **secciones de lista agrupadas** con rótulo ("Mi actividad", "Descubre") de filas ícono+label+chevron, con badges opcionales ("NUEVO", contador). NO es una grilla de íconos; es lista agrupada con header rico.

## Lo construido en `billetudo.pen` (tema claro)

- **Componente `Menu Row` `hIbs3`** — fila de menú agrupada (icon-wrap neutro `$muted` + `$text-secondary`, label + badge opcional "Nuevo" `enabled:false` + chevron). Icon-wrap neutro por la regla de filas de "Más"; `$primary` solo para el CTA de respaldo.
- **Var 1 · ML clásico `Flxf1`** — header con gradiente `$primary-deep→$primary` (avatar + "Bienvenido a billetudo" + "Mi perfil ›") + **un** CTA full-width "Respaldar y sincronizar" (`$primary-soft`, `cloud-upload`) + 3 secciones agrupadas: **Tus finanzas** (Cuentas, Deudas, Pagos programados, Gráficas e informes), **Gestión** (Categorías, Import/Export), **Cuenta** (Ajustes).
- **Var 2 · dúo CTA `OkAV4`** — mismo header con **chip "Sin respaldar"** (`cloud-off`) + **dúo de cards** "Respaldar" y "Premium" (teaser con `Badge/Próximamente` `yfvHv`). Mismas 3 secciones.

## Recomendación al retomar

- **Base Var 1** (`Flxf1`): un solo CTA honesto de respaldo, sin dar espacio prime a Premium que **aún no existe** (misma lógica de no shipear superficies de tienda sin su feature).
- **Tomarle a Var 2 el chip de estado de sync** ("Sin respaldar") — informativo y on-brand para local-first.
- **Header con estado no-logueado:** el "Mi perfil ›" asume sesión; sin cuenta debe mostrar el estado no-logueado, como el header de Inicio (local-first, no empujar al login de forma intrusiva).

## Pendiente al retomar (fuera de Metas)

1. Elegir variante final y refinar (tema claro) con `ui-ux-reviewer`.
2. Documentar spec en `design-system/billetudo/pages/` (¿`mas.md`?).
3. Tema oscuro.
4. **Código:** reescribir `lib/features/home/presentation/pages/more_page.dart` (hoy lista plana) al menú agrupado; wiring de los destinos; l10n de rótulos de sección.

## Relacionado (swap de nav, distinto de este rediseño)

El swap **Metas → slot 4** del Tab Bar ya está hecho en `.pen` (`u3b5s9` slot 4 = Metas, ícono `target`) y en docs. **Código + tests PENDIENTES:** `home_tab_bar.dart`, shell, `more_page.dart`, y `quick_access_row.dart` (sacar Metas del acceso rápido, ya que vuelve a ser tab). Esto sí desbloquea a Metas y puede hacerse antes/independiente del rediseño de "Más".

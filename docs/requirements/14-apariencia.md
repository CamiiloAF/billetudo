# Feature: Apariencia (dentro de Ajustes)

**Nivel:** 0 (gratis, sin anuncios, sin cuenta requerida)
**Depende de:** `04-inicio.md` (HU-11, tema claro/oscuro ya soportado a nivel de `MaterialApp`)

## Contexto

La pantalla de Ajustes (`lib/features/settings/presentation/pages/settings_page.dart`) ya existe con una fila **"Apariencia"** en la sección "Preferencias", pero hoy es un placeholder que abre un sheet genérico de "próximamente" (`onOpenComingSoon`) — no cambia nada.

Los temas claro y oscuro ya están definidos e implementados (`lib/core/theme/app_theme.dart`, `AppTheme.light()`/`AppTheme.dark()`) y pasados a `MaterialApp.router` en `lib/app.dart`. Lo que falta es que el **usuario pueda elegir** entre claro, oscuro o seguir el sistema, y que esa elección se recuerde. Hoy la app sigue el tema del sistema operativo de forma fija, sin `themeMode` explícito, porque no hay ningún mecanismo de preferencia que lo alimente.

Este documento cubre exclusivamente el selector de apariencia. El resto de filas de Ajustes (Moneda, Modo sobres, Cuenta y respaldo, Eliminar cuenta) ya están cubiertas en otros documentos (`06-presupuestos.md` para Modo sobres, `05-auth-sync.md` para cuenta/borrado) o siguen siendo placeholders fuera de alcance aquí.

## Historias de usuario

### HU-01 — Elegir el tema de la app
Como usuario quiero poder elegir entre tema claro, oscuro o "seguir el sistema" desde Ajustes → Apariencia, para usar la app con la apariencia que prefiero, independientemente de la configuración del dispositivo.

**Criterios de aceptación:**
- Tres opciones mutuamente excluyentes: **Claro**, **Oscuro**, **Automático (sistema)**.
- La opción activa se refleja visualmente en el selector (estado seleccionado claro, sin ambigüedad).
- Al elegir una opción, el cambio de tema se aplica de inmediato en toda la app, sin necesidad de reiniciar ni navegar a otra pantalla.
- El valor por defecto para un usuario nuevo (primera instalación, sin preferencia guardada) es **Automático (sistema)** — coherente con el comportamiento actual y con HU-11 de `04-inicio.md`.

### HU-02 — La preferencia persiste entre sesiones
Como usuario quiero que la app recuerde mi elección de tema la próxima vez que la abra, para no tener que configurarla cada vez.

**Criterios de aceptación:**
- Cerrar y reabrir la app conserva el tema elegido.
- Reiniciar el dispositivo conserva el tema elegido.
- La preferencia sigue funcionando sin conexión (no depende de sync ni de sesión iniciada) — es una preferencia de dispositivo, no de cuenta.

### HU-03 — La preferencia es local al dispositivo, no sincronizada
Como usuario quiero que mi elección de tema sea propia de cada dispositivo, para poder tener, por ejemplo, oscuro en el teléfono y claro en la tablet sin que un dispositivo le sobreescriba la preferencia al otro.

**Criterios de aceptación:**
- La preferencia de tema **no viaja a través de PowerSync/Supabase** ni se fusiona al iniciar sesión — es coherente con el comentario ya existente en el esquema Drift (`AppSettings`, `lib/core/database/app_database.dart:437-439`): *"Device-local prefs like the light/dark theme do NOT belong here — they go in a separate local store."*
- Iniciar sesión, cerrar sesión, fusionar datos locales con una cuenta, o borrar la cuenta (`05-auth-sync.md` HU-07) **no altera** el tema elegido en ese dispositivo.
- Instalar la app en un segundo dispositivo y luego iniciar sesión con la misma cuenta **no** trae el tema elegido en el primer dispositivo — cada dispositivo parte de "Automático" y el usuario elige de nuevo si quiere algo distinto.

## Reglas de negocio y edge cases

- Ninguna de las tres opciones (Claro/Oscuro/Automático) puede quedar detrás de anuncio o Premium — es Nivel 0 (regla general de `CLAUDE.md`).
- El cambio de tema debe respetar los 18 tokens de color ya definidos en Pencil (`billetudo.pen` / `MASTER.md`) para ambos temas — este documento no introduce colores nuevos, solo el mecanismo para elegir entre los dos ya existentes.
- Si en el futuro se agrega alguna otra preferencia verdaderamente local al dispositivo (no sincronizable), debe usar el mismo mecanismo de almacenamiento que resulte elegido para el tema, en vez de crear un segundo mecanismo paralelo.

## Fuera de alcance de este documento

- El **cómo** técnico de persistencia local (qué paquete/mecanismo de almacenamiento se usa) es una decisión de arquitectura, no de producto — queda para la fase de diseño/implementación, no fijada aquí.
- El diseño visual del selector (¿fila con sub-pantalla?, ¿bottom sheet?, ¿segmented control inline?) se define en `pencil-designer` contra `MASTER.md`, y su spec final vive en `design-system/billetudo/pages/ajustes.md` (no existe todavía).
- Las demás filas de la pantalla de Ajustes (Moneda, Cuenta y respaldo) permanecen como placeholders o remiten a sus propios documentos — no se tocan aquí.

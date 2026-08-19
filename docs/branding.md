# Marca — qué se incorporó y qué falta

Origen: proyecto de diseño de identidad (`Billetudo Identidad.dc.html`), dirección elegida
**4d — B mayúscula sobre billete plegado** (ver `assets/branding/MARCA.md` para la
identidad completa: símbolo, tipografía, color, reglas de uso).

## Actualización (2026-08-18) — cambio de dirección: minúscula+moneda → B mayúscula+billete

La app se muestra siempre como "Billetudo" (B mayúscula), así que se descartó el
wordmark en minúscula con el punto-moneda. Nueva dirección: la **B** capital impresa sobre
un billete con un pliegue, dentro del tile de degradado violeta.

- Todos los archivos de `assets/branding/` (íconos master, capas adaptive, mipmaps
  Android, wordmark, favicon) se **reemplazaron** con el nuevo diseño, mismos nombres de
  archivo — no hizo falta tocar `pubspec.yaml` ni `flutter_launcher_icons.yaml`.
- `coin_glyph.png` / `.svg` se **eliminó**; lo reemplaza `billete_glyph.png` / `.svg` (el
  billete solo, mismo uso: sello / badge).
- Ícono de app regenerado con `dart run flutter_launcher_icons` (Android + iOS).
- Íconos de ficha de tienda regenerados desde el nuevo master:
  `docs/marketing/store-listing/icons/play-icon-512.png` y `appstore-icon-1024.png`.
- **Pencil (`billetudo.pen`)**: el componente `Logo Wordmark` (`y5JJtf`) quedó en un solo
  nodo de texto "Billetudo"; el `App Icon Tile` (`ZiNl0`) dejó de ser una reconstrucción
  dibujada y ahora usa el ícono real como `fill` de imagen
  (`assets/branding/ic_launcher_master.png`), así que no puede volver a derivar del arte
  entregado; el componente `Coin Glyph` (`U60Oq`) se eliminó al quedarse sin usos.
- **Wordmark en la app** (`lib/core/widgets/brand_wordmark.dart`): pasó de la minúscula
  con `CoinGlyph` como punto de la "ı" a "Billetudo" en texto plano. `CoinGlyph` se
  eliminó junto con las claves l10n `brandWordmarkPrefix` / `brandWordmarkDotlessI` /
  `brandWordmarkSuffix`, reemplazadas por una sola clave `brandWordmark`.

## Incorporado en la pasada de 2026-07-20

- **Assets copiados** a `assets/branding/` dentro del repo y declarados en
  `pubspec.yaml` (`flutter: assets:`).
- **Ícono de app** (Android + iOS) generado con `flutter_launcher_icons` desde
  `assets/branding/ic_launcher_master.png` (+ capas adaptive
  `ic_launcher_bg.png` / `ic_launcher_fg.png`). Reemplaza el ícono placeholder
  de `flutter create`. Config en `pubspec.yaml` (`flutter_launcher_icons:`).
- Un solo master para ambos flavors (`dev`/`prod`) — no hay ícono distintivo
  para "Billetudo Dev" todavía (ver pendientes abajo).

## Deliberadamente NO incorporado (sin feature que lo use)

- **Splash / launch screen nativo:** existe la `SplashPage` de Flutter con el wordmark,
  pero `android/app/src/main/res/drawable/launch_background.xml` y
  `ios/Runner/Assets.xcassets/LaunchImage.imageset/` siguen siendo el placeholder de
  `flutter create`.
- **Ícono de notificación push:** no hay ningún plugin de push (`firebase_messaging`,
  `flutter_local_notifications`, etc.) en `pubspec.yaml`, ni carpetas `drawable*` de
  notificación en Android. `billete_glyph.svg`/`.png` está pensado para ese uso (ver
  `MARCA.md`) pero se cablea cuando exista la feature de notificaciones.
- **Glifo de marca como `Image.asset` en UI:** el único uso de marca en `lib/` es el
  wordmark del splash, y está dibujado con texto real, no con un PNG.
- **Favicon (`favicon.png`):** solo aplica a un contexto web; la app no tiene target web
  activo.
- **Ícono de flavor `dev` distinto:** `flutter_launcher_icons` soporta generarlo con las
  claves `flutter_launcher_icons-dev:` / `flutter_launcher_icons-prod:` + `--flavor`, pero
  requiere primero una variante del master con badge/cinta "DEV" que no vino en el
  entregable. Hoy ambos flavors usan el mismo ícono.

## Al agregar cualquiera de las piezas de arriba

Repetir el gate de diseño de `CLAUDE.md`: pasar primero por Pencil
(`pencil-designer` + `ui-ux-reviewer`) contra `MASTER.md`, no implementar a
ciegas contra este documento ni contra el `.pen` sin mirarlo.

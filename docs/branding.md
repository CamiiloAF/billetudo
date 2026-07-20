# Marca — qué se incorporó y qué falta

Origen: `/Users/cami/Downloads/assets/branding` (ver `assets/branding/MARCA.md` para la
identidad completa: símbolo, tipografía, color, reglas de uso).

## Incorporado en esta pasada (2026-07-20)

- **Assets copiados** a `assets/branding/` dentro del repo y declarados en
  `pubspec.yaml` (`flutter: assets:`).
- **Ícono de app** (Android + iOS) generado con `flutter_launcher_icons` desde
  `assets/branding/ic_launcher_master.png` (+ capas adaptive
  `ic_launcher_bg.png` / `ic_launcher_fg.png`). Reemplaza el ícono placeholder
  de `flutter create`. Config en `pubspec.yaml` (`flutter_launcher_icons:`).
  Para regenerar tras un cambio de ícono: `dart run flutter_launcher_icons`.
- Un solo master para ambos flavors (`dev`/`prod`) — no hay ícono distintivo
  para "Billetudo Dev" todavía (ver pendientes abajo).

## Deliberadamente NO incorporado (sin feature que lo use)

- **Splash / launch screen:** no existe launch screen de marca en el repo —
  `android/app/src/main/res/drawable/launch_background.xml` y
  `ios/Runner/Assets.xcassets/LaunchImage.imageset/` siguen siendo el
  placeholder de `flutter create`. No se cableó `wordmark_light.png` /
  `wordmark_dark.png` / `coin_glyph` a un splash porque no hay una feature de
  splash/onboarding construida aún — hacerlo ahora sería adivinar un layout no
  diseñado en Pencil.
- **Ícono de notificación push:** no hay ningún plugin de push (`firebase_messaging`,
  `flutter_local_notifications`, etc.) en `pubspec.yaml`, ni carpetas
  `drawable*` de notificación en Android. `coin_glyph.svg`/`.png` está pensado
  para ese uso (ver `MARCA.md`) pero se cablea cuando exista la feature de
  notificaciones.
- **Wordmark / coin_glyph en UI (`lib/`):** ningún widget de la app usa
  todavía `Image.asset` de marca (ni logo en about/settings, ni avatar de
  asistente IA). Se incorporan cuando esas pantallas se diseñen en Pencil.
- **Favicon (`favicon.png`):** solo aplica a un contexto web; la app no tiene
  target web activo.
- **Ícono de flavor `dev` distinto:** `flutter_launcher_icons` soporta
  generarlo con las claves `flutter_launcher_icons-dev:` /
  `flutter_launcher_icons-prod:` + `--flavor`, pero requiere primero una
  variante del master con badge/cinta "DEV" que no vino en el entregable de
  assets. Hoy ambos flavors usan el mismo ícono de producción.

## Al agregar cualquiera de las piezas de arriba

Repetir el gate de diseño de `CLAUDE.md`: pasar primero por Pencil
(`pencil-designer` + `ui-ux-reviewer`) contra `MASTER.md`, no implementar a
ciegas contra este documento ni contra el `.pen` sin mirarlo.

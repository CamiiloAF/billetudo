# Marca — qué se incorporó y qué falta

Origen: proyecto de diseño de identidad (`Billetudo Identidad.dc.html`), dirección elegida
**4d — B mayúscula sobre billete plegado** (ver `assets/branding/MARCA.md` para la
identidad completa: símbolo, tipografía, color, reglas de uso).

## Actualización (2026-08-19c) — la fuente corrigió la moneda pero no el `ic_launcher_fg.png`

Respuesta a los dos pendientes de la entrada anterior (billete angosto + moneda pegada al
borde). La entrega nueva sí corrigió ambos **en `ic_launcher_master.png`** (~81%/64%,
moneda con más aire) — pero **`ic_launcher_fg.png` llegó sin cambios de escala**, en el
mismo ~59%/45% chico de antes (solo con la moneda reposicionada). Como
`flutter_launcher_icons` arma el ícono adaptativo de Android desde
`adaptive_icon_background`/`adaptive_icon_foreground` (no desde el master), generar
directo con esa entrega habría reproducido el bug original 2026-08-19b en Android —
verificado generando y viendo el mipmap antes de dar por buena la entrega.

- Fix: se tomó `ic_launcher_fg.png` (que sí trae la moneda bien reposicionada) como fuente
  de verdad, se reescaló 1.337× para igualar la proporción del master corregido (bbox
  resultante ~79%/60%), y se reconstruyó `ic_launcher_master.png` +
  `ic_launcher_rounded_512.png` a partir de ese fg escalado — mismo mecanismo que
  2026-08-19b, pero ahora arrancando de un fg con la moneda ya bien puesta.
- Ícono de app y de tienda regenerados; goldens de `test/features/splash/` actualizados
  (cambiaron porque incluyen el ícono).
- **Para la próxima entrega de este ícono:** verificar el bbox de `ic_launcher_fg.png`
  específicamente (no solo el master a ojo) — es el archivo real detrás del ícono que ve
  el usuario en Android, y es fácil que quede desincronizado del master si el ajuste se
  hizo solo sobre uno de los dos.

## Actualización (2026-08-19b) — el billete se veía muy chico en el ícono de app

Reporte del usuario comparando el ícono de billetudo contra otras apps en su launcher
Android: se veía notoriamente más chico que Nu, Instagram, Facebook, etc. Causa:
`ic_launcher_fg.png` traía el billete ocupando solo ~55% de ancho / ~42% de alto del
canvas de 1024px — por debajo de la "zona segura" que recomienda Android para íconos
adaptativos (~66% de diámetro) y muy por debajo de cómo se ven los íconos vecinos.

- Fix mecánico (sin pasar por Pencil — no cambia el diseño, solo corrige una escala de
  exportación): se reescaló el contenido de `ic_launcher_fg.png` 1.42× centrado en el
  canvas (nuevo bbox ~79% ancho / ~60% alto), y se reconstruyó `ic_launcher_master.png`
  como `alpha_composite(ic_launcher_bg.png, fg escalado)` — mismo diseño (billete +
  moneda), solo más grande dentro del tile.
- `ic_launcher_master_dark.png` (solo referencia, no entra en la generación) ya traía
  una proporción razonable (~74%/60%) y se dejó intacto.
- Ícono de app regenerado con `dart run flutter_launcher_icons`; íconos de ficha de
  tienda (`play-icon-512.png`, `appstore-icon-1024.png`) regenerados desde el master
  corregido.
- Verificado contra el recorte circular (la máscara de launcher más agresiva): el
  billete y la moneda quedan completos, sin cortes.
- **Si se vuelve a regenerar el master desde una entrega externa** (como la del
  2026-08-19a), revisar el bbox del contenido en `ic_launcher_fg.png` antes de dar por
  buena la entrega — este problema puede repetirse si el próximo export trae el mismo
  padding excesivo.

**Resuelto en 2026-08-19c** (ver entrada arriba): el margen de la moneda y el ancho del
billete quedaron bien. Sigue pendiente, de forma menor, que `ic_launcher_fg.png` nazca ya
a la escala correcta en la fuente en vez de depender del parche mecánico de reescalado —
no bloquea nada, es solo para no repetir el mismo ajuste manual en la próxima entrega de
este ícono.

## Actualización (2026-08-19a) — se añade moneda al billete

Misma dirección 4d (B mayúscula sobre billete plegado), refinada: se agrega una
**moneda** en la esquina superior derecha del billete como segundo punto de
reconocimiento (se sigue leyendo cuando el billete se simplifica en tamaños chicos).
Estructura y tipografía del wordmark sin cambios.

- Todos los archivos de `assets/branding/` (íconos master + dark, capas adaptive,
  mipmaps Android, favicon, wordmark) se **reemplazaron** con el nuevo diseño, mismos
  nombres de archivo — `pubspec.yaml` y `flutter_launcher_icons.yaml` sin cambios.
- `billete_glyph.svg` se **eliminó** (la entrega ya no lo incluye); queda solo
  `billete_glyph.png`. Nada en `lib/` ni `assets/branding/MARCA.md` referenciaba el
  `.svg` directamente, así que no rompe nada.
- Ícono de app regenerado con `dart run flutter_launcher_icons` (Android + iOS).
- Íconos de ficha de tienda regenerados desde el nuevo master (mismo proceso que la
  pasada anterior: full-bleed 1024 sin alfa para App Store, resize a 512 para Play):
  `docs/marketing/store-listing/icons/play-icon-512.png` y `appstore-icon-1024.png`.
- **Pendiente, no incorporado en esta pasada:** el `App Icon Tile` (`ZiNl0`) en
  `billetudo.pen` embebe una copia estática del ícono como `fill` de imagen (ver
  entrada 2026-08-18 abajo) — no se refresca solo porque el PNG en disco cambió. Para
  que el canvas de Pencil refleje la moneda nueva hace falta que `pencil-designer`
  reinserte `assets/branding/ic_launcher_master.png` como `fill` del componente.

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

# Marca billetudo

Identidad visual de **Billetudo** — app de finanzas personales local-first para el mercado hispanohablante. *Billetudo* es coloquialmente “con billete”, con la billetera llena.

Dirección elegida: **B mayúscula sobre billete plegado, con moneda** (opción 4d de exploración + moneda, ver `Billetudo Identidad.dc.html` en el proyecto de diseño). Reemplaza la dirección anterior en minúscula con moneda flotando junto al wordmark.

---

## El logo

- **Símbolo:** la **B** de Billetudo, impresa sobre un billete con un solo pliegue (como la inicial de un banco emisor), con una **moneda** en la esquina superior derecha del billete.
- **El billete:** una tarjeta blanca rotada -8°, con una segunda capa detrás (tono `#EEECFB`) que sugiere el pliegue. Es el elemento gráfico reutilizable de la marca — sellos, badges de racha/logro, accents.
- **La moneda:** círculo con aro, en la esquina superior derecha del billete, **contenida por completo dentro de la tarjeta** (nunca cortada por el borde redondeado — al cortarse contra el fondo genera un falso aro oscuro). Da un segundo punto de reconocimiento que sigue leyéndose cuando el billete se simplifica en tamaños chicos (favicon, notif).
- **Claro vs. oscuro:** estructura, tamaño y posición **idénticos**; solo cambian los colores. En ambos casos la moneda es un tono de la letra B y el aro es casi el color de la tarjeta.
- **Tipografía:** Plus Jakarta Sans **ExtraBold (800)**, tracking `-0.045em`. Wordmark plano, sin elementos flotantes.
- **Ícono de app:** el billete centrado en un tile de degradado violeta, con la B en violeta profundo sobre la tarjeta blanca y la moneda en su esquina.

---

## Color

| Token | Hex | Uso |
|-------|-----|-----|
| `primary` | `#6C5CE7` | Color de marca, monocromo sólido |
| `primary-deep` | `#5648C8` | Letra B sobre el billete; extremo oscuro del degradado |
| `primary-light` | `#A78BFA` | Moneda (claro); billete en tema oscuro |
| `primary-soft` | `#EEECFB` | Capa trasera del billete (pliegue); aro de la moneda (claro) |
| `coin-dark` | `#33304E` | Moneda en tema oscuro (familia de la B `#1E1E2E`) |
| `coin-ring-dark` | `#BCAEF6` | Aro de la moneda en tema oscuro |
| `text-primary` | `#1C1B29` / `#F4F3FA` | Wordmark (claro / oscuro) |
| `surface (dark)` | `#1E1E2E` | Tile del ícono en tema oscuro |

Degradado del ícono: lineal ~150°, `#7B6BF0 → #5648C8`.

---

## Archivos

### Íconos de app (raster)
| Archivo | Tamaño | Para |
|---------|--------|------|
| `ic_launcher_master.png` | 1024² full-bleed | **Fuente iOS** + base de generación |
| `ic_launcher_master_dark.png` | 1024² | Referencia tema oscuro |
| `ic_launcher_bg.png` | 1024² | Capa **fondo** adaptive Android |
| `ic_launcher_fg.png` | 1024² transparente | Capa **frente** adaptive Android (billete en zona segura) |
| `ic_launcher_rounded_512.png` | 512² | Preview con esquinas redondeadas |
| `android/mipmap-*/…` | 48→192 (+ adaptive 108→432) | Drop-in a `android/app/src/main/res/` |

### Glifo / wordmark
| Archivo | Notas |
|---------|-------|
| `billete_glyph.png` | El billete con su moneda (sello, badge de racha/logro). Reemplaza a `coin_glyph` de la dirección anterior. |
| `favicon.png` | 64², billete + moneda sobre tile violeta |
| `wordmark_light.png` / `wordmark_dark.png` | **Wordmark canónico** (alta resolución, 3×), texto plano "Billetudo". |
| `wordmark.svg` / `wordmark_dark.svg` | Vector con la fuente embebida (base64). |

---

## Importar los íconos en Flutter

Sin cambios respecto a la config existente — mismos nombres de archivo, solo el contenido cambió:

```
flutter pub add dev:flutter_launcher_icons
dart run flutter_launcher_icons
```

Config en `flutter_launcher_icons.yaml` (sin tocar).

---

## Reglas de uso

- **Proporción en el tile:** el billete ocupa **~79% del ancho** del lienzo (~64% de alto contando el pliegue trasero; ~59% la tarjeta frontal), para que no se vea chico junto a otros íconos en el launcher.
- **Área de resguardo:** el margen libre superior/inferior equivale a ~⅓ de la altura del billete (regla mínima: ¼).
- **Capa adaptive de Android:** `ic_launcher_fg.png` va al 62% de escala (≈54% × 40% del lienzo) porque Android recorta al círculo seguro de 66dp sobre 108dp — es requisito de plataforma, no un billete más chico.
- **Tamaño mínimo:** ~20px de alto para el ícono; por debajo el pliegue trasero se simplifica y solo queda la tarjeta frontal con la B.
- **Posición de la moneda:** separada del borde de la tarjeta (inset = 1.25 × su radio desde la esquina), nunca tocando el borde redondeado.
- **Nunca** poner la B blanca sobre `primary-light` (contraste insuficiente); el degradado va entre `primary` y `primary-deep`.
- Monocromo disponible (sólido / negro / invertido) para stamps, facturas y watermark — un solo billete sin capa trasera.

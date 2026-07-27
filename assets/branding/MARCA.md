# Marca billetudo

Identidad visual de **billetudo** — app de finanzas personales local-first para el mercado hispanohablante. *Billetudo* es coloquialmente “con billete”, con la billetera llena.

Todo parte del sistema de diseño existente (violeta de marca `#6C5CE7`, tipografía **Plus Jakarta Sans**). Ver mockups y direcciones exploradas en `Billetudo Identidad.dc.html` (dirección elegida: **2d**).

---

## El logo

- **Símbolo:** la **b** minúscula del wordmark.
- **La moneda:** el punto de la **i** es una moneda (círculo violeta con aro). Es el elemento gráfico reutilizable de toda la marca — favicon, avatar del asistente, punto de notificación.
- **Tipografía:** Plus Jakarta Sans **ExtraBold (800)**, tracking `-0.04em`. La *i* del wordmark es **sin punto** (`ı`, U+0131) porque la moneda hace de punto.
- **Ícono de app:** la **b** blanca sobre tile de degradado violeta, con la moneda arriba a la derecha.

---

## Color

| Token | Hex | Uso |
|-------|-----|-----|
| `primary` | `#6C5CE7` | Color de marca, moneda, wordmark en contextos de color |
| `primary-deep` | `#5648C8` | Extremo oscuro del degradado del ícono |
| `primary-light` | `#A78BFA` | Relleno de la moneda sobre el ícono; “b” en tema oscuro |
| `primary-soft` | `#EEECFB` | Aro de la moneda como glifo suelto |
| `text-primary` | `#1C1B29` / `#F4F3FA` | Wordmark (claro / oscuro) |
| `surface (dark)` | `#1E1E2E` | Tile del ícono en tema oscuro |

Degradado del ícono: lineal ~150°, `#7B6BF0 → #5648C8`.

---

## Archivos

### Íconos de app (raster — los launchers siempre usan PNG)
| Archivo | Tamaño | Para |
|---------|--------|------|
| `ic_launcher_master.png` | 1024² full-bleed, sin alfa | **Fuente iOS** + base de generación |
| `ic_launcher_master_dark.png` | 1024² | Referencia tema oscuro |
| `ic_launcher_bg.png` | 1024² | Capa **fondo** adaptive Android |
| `ic_launcher_fg.png` | 1024² transparente | Capa **frente** adaptive Android (b+moneda en zona segura) |
| `ic_launcher_rounded_512.png` | 512² | Preview con esquinas redondeadas |
| `android/mipmap-*/…` | 48→192 (+ adaptive 108→432) | Drop-in directo a `android/app/src/main/res/` |

### Glifo / wordmark
| Archivo | Notas |
|---------|-------|
| `coin_glyph.svg` / `.png` | La moneda sola (favicon, avatar del asistente). SVG = geometría pura, escala perfecto. |
| `favicon.png` | 64² |
| `wordmark_light.png` / `wordmark_dark.png` | **Wordmark canónico** (alta resolución, 3×). |
| `wordmark.svg` / `wordmark_dark.svg` | Vector con la fuente **embebida** (base64). Renderiza en navegadores reales; algunos rasterizadores (p. ej. html-to-image) ignoran `@font-face` embebido. Para producción sin dependencia, usar el PNG o exportar contornos desde Figma/Illustrator. |

---

## Importar los íconos en Flutter (recomendado)

1. Copia `assets/branding/` dentro del repo Flutter.
2. `flutter pub add dev:flutter_launcher_icons`
3. Pega el bloque de `flutter_launcher_icons.yaml` en `pubspec.yaml`.
4. `dart run flutter_launcher_icons`

Esto genera automáticamente todos los mipmaps de Android (legacy + adaptive) y el `AppIcon.appiconset` de iOS desde el master 1024.

**Alternativa manual (Android):** los PNG ya listos están en `assets/branding/android/mipmap-*/`. Cópialos a `android/app/src/main/res/mipmap-*/` y define el adaptive en `res/mipmap-anydpi-v26/ic_launcher.xml`:

```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

---

## Reglas de uso

- **Área de resguardo:** dejar libre alrededor del wordmark al menos la altura de la moneda.
- **Tamaño mínimo del wordmark:** ~18px de alto; por debajo la moneda se simplifica a punto sólido (sin aro).
- **Nunca** rellenar la *i* con su punto natural **y** la moneda a la vez (usar siempre la *i* sin punto `ı`).
- **Nunca** poner la “b” blanca sobre `primary-light` (contraste insuficiente); el degradado va entre `primary` y `primary-deep`.
- Monocromo disponible (sólido / negro / invertido) para stamps, facturas y watermark.

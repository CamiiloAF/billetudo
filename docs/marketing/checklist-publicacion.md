# Checklist de publicación — Play Store y App Store

Última actualización: **2026-08-18**.

Este documento es la **lista de ejecución**: qué falta, en qué orden, y qué
pegar en cada campo. No repite el contenido de los otros dos —
[`../legal/declaraciones-tiendas.md`](../legal/declaraciones-tiendas.md) tiene
las respuestas de Data Safety y App Privacy campo por campo, y
[`store-listing/copy.md`](store-listing/copy.md) tiene los textos listos para
copiar. Cuando este checklist dice "ver §1.2", es a ese documento.

> **Sitio legal publicado.** Política, términos y borrado de cuenta están en
> línea desde el 2026-08-18. Cómo regenerarlos y republicarlos:
> [`../../web/README.md`](../../web/README.md).

> **Verificá antes de citar.** Los estados de abajo se comprobaron el
> 2026-08-18 contra el código, contra Postgres de producción y contra los
> archivos en disco. Si vas a apoyarte en un ✅ para enviar la app, volvé a
> comprobarlo.

---

## 0. Bloqueantes vigentes

Ninguna de las dos consolas deja enviar sin esto.

| # | Bloqueante | Estado | Quién lo destraba |
|---|---|---|---|
| 1 | **Política de privacidad publicada en una URL pública** | ✅ **Publicada el 2026-08-18** en https://camiiloaf.github.io/billetudo/ (HTTP 200, sin marcadores pendientes) | — |
| 2 | **URL web de borrado de cuenta** | ✅ **Publicada** en https://camiiloaf.github.io/billetudo/borrar-cuenta.html (HTTP 200) | — |
| 3 | **Excluir el Espacio Económico Europeo** | ✅ **Excluido en ambas consolas** (2026-08-18), coherente con la política publicada, que declara que billetudo **no se ofrece en el EEE** mientras no estén firmados los DPA de Sentry y PowerSync | — |
| 4 | **Decisión iPad** | ✅ **Resuelto: el v1 va iPhone-only.** `TARGETED_DEVICE_FAMILY = 1` (verificado con `xcodebuild -showBuildSettings`) y se quitaron las orientaciones de iPad del Info.plist. No hacen falta capturas de iPad. Añadir soporte más adelante es una versión nueva; quitarlo después de publicar habría perjudicado a quien ya la tuviera instalada | — |
| 5 | **`PrivacyInfo.xcprivacy` en el target de iOS** | ✅ **Creado** en `ios/Runner/PrivacyInfo.xcprivacy` y añadido a Copy Bundle Resources. Declara las 11 categorías de §2.2, `NSPrivacyTracking = false` y dos Required Reason APIs (CA92.1, C617.1) | — |

**Ya no son bloqueantes** (se cerraron el 2026-08-08 y conviene no arrastrar el
estado viejo):

- **Borrado de cuenta funcional para todos los usuarios** — fallaba para quienes
  tuvieran presupuestos por periodo o metas con montos rápidos. Corregido con
  `supabase/migrations/20260808000000_delete_account_cascade_missing_tables.sql`,
  aplicada en dev **y en producción**, verificada con 0 huérfanos y 0 pérdida de
  datos. Ver B1 de `AUDITORIA.md`.
- **Cuentas de desarrollador** — ya creadas en ambas tiendas a nombre de Juan
  Camilo Agudelo Franco (persona natural). En Apple el *developer name* ya quedó
  fijado y es irreversible.

---

## 1. Activos gráficos

| Activo | Requisito de la tienda | Estado | Ruta |
|---|---|---|---|
| Capturas (fuente) | 1170 × 2532, la app real | ✅ **Dos juegos de 9**: barra de estado Android y iOS. Cada tienda usa el suyo — una captura con el chrome de la otra plataforma se nota | `store-listing/raw/android/` y `raw/ios/` |
| Capturas Play | 1080 × 1920, **máx. 8** | ✅ Las 8, exportadas y verificadas (1080×1920 exactos, RGB sin alfa) | `store-listing/play/` |
| Capturas App Store | 1290 × 2796, **máx. 10** | ✅ Las 9, exportadas y verificadas. La novena (Importar/Exportar) es exclusiva de iOS porque Play topa en 8 | `store-listing/appstore/` |
| Ícono Play | 512 × 512, PNG 32 bits, < 1 MB | ✅ 512×512 RGBA, 113 KB | `store-listing/icons/play-icon-512.png` |
| Ícono App Store | 1024 × 1024, **sin canal alfa**, sin esquinas redondeadas | ✅ 1024×1024 RGB, 161 KB. Verificado píxel a píxel contra el master: diferencia 0 | `store-listing/icons/appstore-icon-1024.png` |
| Gráfico destacado (Play) | 1024 × 500 | ✅ Exportado, 1024×500 | `store-listing/play/00-grafico-destacado.png` |

**Regenerar las capturas:**

```bash
flutter test test/marketing/store_screenshots.dart
```

Genera los 18 archivos (9 por plataforma). El gráfico destacado es un activo
solo de Play, así que usa la captura de `android/`.

Es el archivo, no el directorio: `test/marketing/` no lleva sufijo `_test.dart`
justamente para que un `flutter test` normal **no** reescriba los activos de
marketing como efecto secundario.

> ⚠️ **Las capturas no son reproducibles entre fechas.** El dataset de showcase
> usa fechas relativas al día de ejecución, así que hoy dice "18 ago" y "faltan
> 14 días", y el mes que viene diría otra cosa. Si importa que el juego de 9
> sea consistente, hay que fijar el reloj del showcase antes de la corrida
> final.

---

## 2. Google Play Console

Orden sugerido; los campos de texto salen de `copy.md`.

1. **Ficha principal** — título (26/30), descripción corta (72/80) y descripción
   larga. Idioma: **es-419**, único del v1.
2. **Activos** — ícono 512, gráfico destacado 1024×500, hasta 8 capturas.
3. **Categoría** — Finanzas.
4. **Clasificación de contenido** — completar el cuestionario IARC en la
   consola. Sin contenido sensible.
5. **Grupo de edad** — 16-17 y 18+, coherente con la edad mínima de 16 de los
   términos. Ojo con la Families Policy: ver la advertencia en
   `declaraciones-tiendas.md`.
6. **Data Safety** — respuestas campo por campo en §1.2 de
   `declaraciones-tiendas.md`. No improvisar acá.
7. **URLs** — política de privacidad y eliminación de cuenta (bloqueantes 1 y 2).
8. **Declaración de anuncios** — ver §4 de este documento.

---

## 3. App Store Connect

1. **Ficha** — nombre (9/30), subtítulo (28/30), palabras clave (79/100), texto
   promocional (139/170) y descripción.
   **La descripción es la de Play sin las viñetas `•`** — Apple las renderiza de
   forma inconsistente; sustituirlas por guiones o saltos de línea.
2. **Activos** — ícono 1024 sin alfa, hasta 10 capturas de 1290 × 2796.
3. **Clasificación por edad** — **16+ fijada manualmente**. Por contenido el
   cuestionario daría 4+, pero eso contradiría la edad mínima de 16 de los
   términos. Apple rehízo los tramos en 2025: hoy son 4+, 9+, 13+, 16+ y 18+.
4. **App Privacy** — respuestas en §2.2 de `declaraciones-tiendas.md`.
5. **`PrivacyInfo.xcprivacy`** — bloqueante 3.
6. **Notas para App Review** — hay un borrador en §2.4 de
   `declaraciones-tiendas.md`. Incluye cómo probar sin cuenta y dónde está el
   borrado de cuenta, que es lo que App Review suele buscar primero.

---

## 4. Declaración de anuncios — leer antes de responder

Hoy la respuesta correcta en **ambas** tiendas es **"No contiene anuncios"**, y
es verificable contra el binario: `google_mobile_ads` no está cableado y el
manifiesto fusionado no declara `AD_ID`.

**Cambia a "Sí" en cuanto se active el primer rewarded.** Declarar anuncios que
no existen es tan incorrecto como omitir los que sí — y en Play, cambiar esta
respuesta después de publicar dispara una revisión.

Relacionado, y con la misma trampa: **la frase "sin anuncios" está vetada** en
todos los campos de texto. El modelo incluye anuncios con recompensa opcionales;
prometer lo contrario obliga a reescribir la ficha entera y quema la confianza
cuando la promesa cambie. La formulación correcta es siempre condicional al
opt-in: *nunca verás un anuncio que no hayas pedido tú*. Ver §6 del plan.

---

## 5. Orden recomendado

1. ~~Publicar el sitio~~ → ✅ hecho el 2026-08-18; cerró los bloqueantes 1 y 2.
2. ~~Decidir iPad~~ → ✅ iPhone-only.
3. ~~Crear el `PrivacyInfo.xcprivacy`~~ → ✅ hecho.
4. ~~Excluir el EEE~~ → ✅ hecho el 2026-08-18 en ambas consolas.
5. ~~Cargar Play y App Store~~ → ✅ **fichas completas en ambas consolas
   (2026-08-18)**: ficha principal, Data Safety / App Privacy, clasificación de
   edad y contenido, declaración de anuncios ("No contiene anuncios"), notas
   para App Review. Listas para enviar a revisión.

Los pasos 1-4 eran independientes entre sí. Con las fichas cerradas, lo único
que queda fuera de este documento es **subir el build** (`.aab` firmado para
Play, `.ipa` para App Store vía Xcode/Transporter) y darle enviar — eso no es
parte de la ficha, es el paso de publicación en sí.

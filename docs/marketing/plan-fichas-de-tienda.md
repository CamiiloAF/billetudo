# Plan — Material de marketing para Play Store y App Store

Estado: **aprobado, listo para ejecutar**.
Fecha original: 2026-07-29 · **Revisado: 2026-08-07** contra `0.0.4+8`.

> **Qué cambió en la revisión del 2026-08-07.** Gráficas e Import/Export pasaron
> de "no existe" a implementadas y con goldens. Eso **elimina los dos riesgos
> principales del plan**: ya no hay ninguna captura que salga de Pencil en vez
> de la app, y desaparecen las fases F1b y F8 (producir y luego regenerar la
> captura de Gráficas). Todo el set se produce ahora desde la app real, de una
> sola pasada.

---

## 1. Punto de partida — qué puede mostrar la app hoy

Lo primero es un filtro duro: **ambas tiendas rechazan capturas que muestren
funcionalidad que la app no tiene**. Así que el set se arma solo con features
implementadas y con goldens ya generados (prueba de que la pantalla existe y
está estable).

| Feature | Archivos en `lib/` | Goldens | ¿Sirve para la tienda? |
|---|---|---|---|
| Inicio (home + shell) | 29 | 32 | **Sí — hero** |
| Transacciones | 97 | 104 | **Sí** |
| **Gráficas / informes** | **82** | **43** | **Sí — ya implementada** ✅ |
| Presupuestos | 96 | 102 | **Sí** |
| Metas | 104 | 126 | **Sí** |
| Deudas | 89 | 54 | **Sí** |
| Pagos programados | 99 | 102 | **Sí** |
| **Import / Export** | **134** | **84** | **Sí — nueva candidata** (ver §4) ✅ |
| Cuentas | 81 | 72 | Sí (secundaria) |
| Categorías | 50 | 36 | Sí (secundaria) |
| Onboarding | 18 | 12 | Sí (secundaria) |
| Tutoriales | 16 | — | No (no es argumento de venta) |
| Ajustes / apariencia | 19 | 14 | Sí (solo como prueba de claro/oscuro) |
| Auth + sync | 56 | (en home) | Sí (como "local-first", no como login) |
| **Captura IA / voz / OCR** | **0** | 0 | **No — sigue sin existir** |
| **Mejora / coach** | **0** | 0 | **No — sigue sin existir** |

> Consecuencia para el copy, sin cambios: **no se puede prometer IA, captura por
> voz ni lectura de notificaciones bancarias** — `capture/` e `improvement/`
> siguen vacíos. El mensaje se sostiene sobre registro rápido, presupuestos,
> metas, deudas, pagos programados, gráficas esenciales, portabilidad de datos y
> offline-first.

---

## 2. Decisiones que necesito que revises

Están resueltas con una recomendación; si no objetas, se ejecutan así.

| # | Decisión | Recomendación | Por qué |
|---|---|---|---|
| D1 | Idiomas de la ficha | **Solo es-419** ✅ *decidido* | Cubre toda LatAm. El inglés se agrega después clonando los lienzos y cambiando solo el caption — no hay que rediseñar nada. |
| D2 | Tablet | **No en el v1** | No hay diseño de tablet en Pencil ni layouts responsive verificados. Play penaliza levemente la visibilidad, pero mentir con capturas escaladas es peor. |
| D3 | Estilo de captura | **Mockup con marco de dispositivo + caption arriba, fondo de marca** | Convierte mejor que la captura cruda; es el estándar de la categoría (YNAB, Fintonic, Mobills). |
| D4 | Fuente de píxeles de la app | **Capturas reales de la app a 3x, las 8** ✅ *simplificado 2026-08-07* | Los goldens actuales son 390×844 @1x → se ven borrosos al escalarlos. Ver §5. Ya no hay excepción de Pencil: Gráficas está implementada. |
| D5 | Video / App Preview | **No en el v1** | Multiplica el esfuerzo y no es obligatorio en ninguna tienda. Se agenda para el primer update. |
| D6 | Cantidad de capturas | **8 en Play, 8 en App Store** (mismo guion) | Play muestra ~3 sin scroll, Apple ~2-3. Las 8 dan cobertura completa a quien sí desliza. |

---

## 3. Especificaciones técnicas exactas

### 3.1 Google Play Console

| Asset | Especificación | ¿Obligatorio? |
|---|---|---|
| Ícono de app | **512 × 512** PNG 32-bit, ≤ 1 MB, sin transparencia | Sí |
| Gráfico destacado (*feature graphic*) | **1024 × 500** PNG o JPG, sin transparencia | Sí |
| Capturas de teléfono | **1080 × 1920** PNG/JPG 24-bit. Mín. 2, máx. 8. Lado corto ≥ 320 px, lado largo ≤ 3840 px, y el lado largo **no puede superar el doble** del corto | Sí (mín. 2) |
| Título | ≤ **30** caracteres | Sí |
| Descripción corta | ≤ **80** caracteres | Sí |
| Descripción larga | ≤ **4000** caracteres | Sí |
| Video promocional | URL de YouTube | No (D5: se omite) |

> Ojo con el ratio: **1080 × 2400 no es válido** (2.22× el lado corto). Se usa
> **1080 × 1920** (1.78×), que además es lo más común de la categoría.

### 3.2 App Store Connect

| Asset | Especificación | ¿Obligatorio? |
|---|---|---|
| Ícono de app | **1024 × 1024** PNG, sin transparencia ni esquinas redondeadas | Sí |
| Capturas iPhone 6.9" | **1290 × 2796** (o 1320 × 2868). Mín. 1, máx. 10 | Sí |
| Otros tamaños de iPhone | Apple escala el set de 6.9" automáticamente | No |
| Capturas iPad 13" | 2064 × 2752 | Solo si la app soporta iPad → **no** (D2) |
| Nombre | ≤ **30** caracteres | Sí |
| Subtítulo | ≤ **30** caracteres | Sí |
| Palabras clave | ≤ **100** caracteres en total, separadas por coma sin espacios | Sí |
| Descripción | ≤ **4000** caracteres | Sí |
| Texto promocional | ≤ **170** caracteres (editable sin nueva review) | No, pero conviene |
| App Preview | 15–30 s, hasta 3 | No (D5) |

**Total de piezas gráficas a producir:** 8 (Play, 1080×1920) + 9 (App Store,
1290×2796 — la novena es Import/Export, §4.1) = **17 lienzos**, más el gráfico
destacado (1024×500) y los dos íconos (512 y 1024). Un solo idioma (D1).

---

## 4. Guion de las 8 capturas (mismo orden en ambas tiendas)

El orden importa: la #1 es la que más pesa en la decisión de instalar, y las
#1–#3 son las únicas visibles sin deslizar.

| # | Fuente | Caption (≤ 40 car./línea, máx. 2 líneas) | Por qué está aquí |
|---|---|---|---|
| 1 | App @3x — `home_page_with_data_light` | **Todo tu dinero,** / **en una sola pantalla** | Muestra el producto completo de un vistazo. Es el hero. |
| 2 | App @3x — `transaction_form_page_keypad_open_light` | **Anota un gasto** / **en 3 segundos** | El diferenciador central: captura de baja fricción. El teclado numérico visible comunica "esto es rápido". |
| 3 | App @3x — `reports_page_categories_with_data_light` | **En qué se te va la plata,** / **sin adivinar** | La dona es la pieza más vendedora del set y la que mejor funciona como miniatura. |
| 4 | App @3x — `budgets_page_envelope_with_data_light` | **Presupuestos** / **que sí se entienden** | El anti-YNAB: el beneficio de sobres sin la curva de aprendizaje. |
| 5 | App @3x — `goals_list_page_momentum_active_light` | **Ahorra para lo que** / **de verdad quieres** | Emocional, y la feature con más trabajo de diseño detrás. |
| 6 | App @3x — `debts_list_page_with_data_light` | **Sabe quién te debe** / **y a quién le debes** | Muy pedido en el mercado hispano, mal cubierto por la competencia. |
| 7 | App @3x — `scheduled_payments_page_with_data_with_pending_light` | **Ningún pago** / **se te vuelve a pasar** | Beneficio concreto y fácil de entender. |
| 8 | App @3x — `home_page_with_data_dark` | **Todo lo esencial, gratis.** / **Sin interrupciones, sin internet.** | Cierre de posicionamiento: gratis + local-first + privacidad, y de paso vende el tema oscuro. Ver ⚠️ en §6 — la frase "sin anuncios" está vetada. |

Todas las capturas van en **tema claro salvo la #8**, que es la que
deliberadamente muestra el oscuro.

### 4.1 Import/Export — la novena candidata

Import/Export se implementó después de escribir este plan (134 archivos, 84
goldens) y es un argumento de venta real: **captura al usuario que ya está en
otra app** y refuerza el mensaje de "tus datos son tuyos" con una prueba
concreta, no con una promesa. El problema es que Play topa en 8 capturas y las
8 actuales ya están peleadas.

**Recomendación:**

- **Play (máx. 8):** no le doy slot propio. Import/Export es una preocupación de
  fase de decisión ("¿puedo traerme lo que ya tengo?"), y eso el **texto** lo
  responde mejor que una imagen — una pantalla de mapeo de columnas CSV es poco
  atractiva como miniatura. Se cubre en la descripción larga (§6.1).
- **App Store (máx. 10):** entra como **#9**, con
  `import_export_hub_page_with_data_light` y el caption
  **"Trae tus datos de otra app" / "y llévatelos cuando quieras"**. El slot es
  gratis ahí, así que no cuesta nada aprovecharlo.

Esto rompe levemente el "mismo guion en ambas tiendas", y es a propósito: los
límites de las tiendas son distintos y desperdiciar dos slots en iOS por
simetría no tiene sentido.

**Datos de vitrina:** las capturas necesitan datos coherentes entre sí (los
mismos nombres de cuenta, categorías y montos en las 8), realistas para el
mercado objetivo (COP como moneda base, montos plausibles) y sin ningún dato
personal real. Es un dataset nuevo hecho a propósito para marketing, **no** el
que usan los goldens.

---

## 5. Cómo se produce cada pieza (pipeline)

Dos fuentes, cada una para lo suyo:

**a) Los píxeles de la app → capturas reales a 3x** (las 8, más la #9 de iOS).
Los goldens existentes son 390 × 844 @1x; metidos en un mockup de ~900 px de
ancho quedan borrosos. La solución es un *harness* de captura dedicado en
`test/marketing/` (no toca `test/features/`, no altera ningún golden existente)
que renderiza las 9 pantallas seleccionadas con el dataset de vitrina y
`devicePixelRatio: 3` → PNG de **1170 × 2532**, nítidos y fieles a la app real.
Salida a `docs/marketing/store-listing/raw/`.

**b) El lienzo alrededor → Pencil.**
Fondo, marco de dispositivo, caption y gráfico destacado se construyen en
`billetudo.pen`, en una página nueva **"Marketing / Store"**, usando las
variables de color y la tipografía del sistema (nada de hex hardcodeado, regla
de `CLAUDE.md`). Los PNG de (a) se colocan dentro de los marcos. Se exportan
desde Pencil a los tamaños finales.

**Dos sets de artboards, no un escalado.** 1080 × 1920 (ratio 1.78) y
1290 × 2796 (ratio 2.17) son proporciones muy distintas: el mismo diseño
escalado deja bandas o recorta el caption. Se diseñan los dos, compartiendo un
componente `reusable:true` de caption y otro de fondo.

---

## 6. Borradores de copy

> ⚠️ **Regla que gobierna todo el copy sobre anuncios.** El modelo de
> monetización (`CLAUDE.md`) es: Nivel 0 gratis **y sin anuncios**, con los
> extras (IA, gráficas avanzadas) desbloqueables por **anuncio con recompensa
> opt-in** o Premium. Están prohibidos los banners e interstitials ambientales.
> Por lo tanto **está vetada la frase "sin anuncios" a secas**: sería falsa en
> cuanto exista el primer rewarded, y obligaría a cambiar la declaración
> "Contiene anuncios" de Play después de haber prometido lo contrario.
> La formulación correcta es siempre **condicional al opt-in**: *nunca verás un
> anuncio que no hayas pedido tú*. Es igual de fuerte como posicionamiento y
> resiste el lanzamiento de la monetización sin tener que reescribir la ficha.

### 6.1 Play Store

- **Título** (30): `Billetudo: gastos y ahorro` *(26)*
- **Descripción corta** (80): `Gastos, presupuestos y metas. Gratis, sin interrupciones y sin internet.` *(72)*
- **Descripción larga** (borrador, ~1300 car. de 4000):

```
Billetudo es una app de finanzas personales pensada para que de verdad la uses
todos los días: anotar un gasto toma segundos, y todo funciona sin conexión.

QUÉ PUEDES HACER
• Registrar ingresos, gastos y transferencias en segundos
• Organizar tu plata en cuentas: efectivo, bancos y tarjetas de crédito
• Armar presupuestos por categoría y ver cuánto te queda de verdad
• Ahorrar para tus metas y seguir tu avance
• Llevar tus deudas y préstamos: a quién le debes y quién te debe
• Programar tus pagos recurrentes para que no se te pase ninguno
• Ver en qué se te va la plata con gráficas claras: flujo del mes, patrimonio
  y desglose por categoría
• Categorías y etiquetas propias, con íconos y colores

GRATIS DE VERDAD, Y SIN LETRA PEQUEÑA
Todo lo esencial es gratis para siempre: registrar, presupuestar, tus metas,
tus deudas, tus gráficas. Ninguna de esas funciones está detrás de un pago.

Y nunca vas a ver un anuncio que no hayas pedido tú. No hay banners ni
pantallas que te interrumpan mientras usas la app. Si algún día quieres probar
una función extra sin pagar, tú decides ver un anuncio corto a cambio — y si no
quieres, no pasa nada: la app completa sigue funcionando igual.

TUS DATOS SON TUYOS
Billetudo guarda todo en tu teléfono. Funciona completo sin internet y sin
crear cuenta. Si quieres, luego inicias sesión y tus datos se respaldan y
sincronizan sin perder nada de lo que ya registraste.

¿Ya llevas tus cuentas en otra app o en una hoja de cálculo? Puedes importar
tus movimientos desde un archivo CSV y seguir donde ibas. Y cuando quieras,
exportas todo o guardas una copia completa: nada se queda encerrado aquí.

MODO CLARO Y OSCURO
Diseñada con cuidado, en español, y con un tono que no te regaña por gastar.

Billetudo no es asesoría financiera.
```

### 6.2 App Store

- **Nombre** (30): `Billetudo` *(9)*
- **Subtítulo** (30): `Gastos, presupuesto y ahorro` *(28)*
- **Palabras clave** (100): `gastos,presupuesto,ahorro,finanzas,dinero,deudas,cuentas,budget,control,personal`
- **Texto promocional** (170): `Anota un gasto en segundos, arma tu presupuesto y cumple tus metas. Todo lo esencial gratis, sin interrupciones y funcionando sin internet.` *(139)*
- **Descripción**: la misma de §6.1 (Apple no permite listas con viñetas tan
  agresivas, se ajusta el formato).

> El inglés queda fuera del alcance (D1). Cuando se agregue, lo único que se
> rediseña son los captions; los campos donde el ASO realmente cambia por idioma
> son título, descripción corta y palabras clave — no se traducen literal, se
> reescriben.

---

## 7. Fases de ejecución y a quién se delega

| Fase | Qué | Quién | Salida |
|---|---|---|---|
| **F0** | Aprobar este plan (§2) | Tú | — |
| **F1** | Dataset de vitrina + harness de captura a 3x (**9 pantallas**) | `qa-automator` | `test/marketing/`, PNG en `docs/marketing/store-listing/raw/` |
| **F2** | Página "Marketing / Store" en Pencil: fondos, marcos, captions, los **17 lienzos** (8 Play + 9 App Store) + gráfico destacado | `pencil-designer` | Frames en `billetudo.pen` |
| **F3** | Auditoría de los lienzos (jerarquía, contraste del caption sobre el fondo, consistencia con el sistema) | `ui-ux-reviewer` | Anotaciones + reporte |
| **F4** | Correcciones y export final a PNG en los tamaños de §3 | `pencil-designer` | `docs/marketing/store-listing/play/` y `/appstore/` |
| **F5** | Íconos 512 y 1024 desde `assets/branding/ic_launcher_master.png` (verificar que no lleven transparencia ni esquinas redondeadas) | Directo | `store-listing/icons/` |
| **F6** | Copy final en un archivo listo para copiar/pegar en cada consola | Directo | `docs/marketing/store-listing/copy.md` |
| **F7** | Checklist de subida (clasificación de contenido, URL de política de privacidad, formulario de seguridad de datos de Play, App Privacy de Apple, **declaración de anuncios** — ver §8.6) | Directo | `docs/marketing/checklist-publicacion.md` |

~~F8 — regenerar la captura de Gráficas desde la app~~ **eliminada el
2026-08-07**: Gráficas ya está implementada, así que la #3 nace de la app real
en F1 y no hay nada que regenerar después.

F1 y F2 se pueden arrancar en paralelo: `pencil-designer` construye los lienzos
con placeholders y sustituye los PNG reales cuando F1 termine.

---

## 8. Riesgos y cosas que no cubre este plan

> ✅ **Cerrados el 2026-08-07:** los riesgos #1 y #2 de la versión anterior
> (la captura de Gráficas salía de Pencil y dependía de que la feature se
> implementara) desaparecieron: `lib/features/reports/` tiene 82 archivos y 43
> goldens. Todo el set nace ahora de la app real.

1. **El copy no puede prometer IA, voz, OCR ni lectura de notificaciones
   bancarias.** Son el diferenciador del plan de producto pero no existen en
   código y no hay fecha. Se quedan fuera del texto por completo.
2. **La política de privacidad publicada en una URL sigue siendo el único
   bloqueante duro.** Es campo obligatorio en ambas consolas: sin ella no se
   puede enviar la ficha, por bueno que quede el material. **Es lo único de
   este plan que no puedo producir yo** y no depende de ninguna fase de abajo,
   así que conviene arrancarlo en paralelo desde ya. El resto del frente legal
   está resuelto: borrado de cuenta in-app implementado
   (`lib/features/auth/domain/usecases/delete_account.dart`), plataformas
   nativas (`android/`, `ios/`) y PowerSync cableado.
3. **La declaración de anuncios hay que decidirla en el envío, no después.**
   Play pregunta "¿la app contiene anuncios?" y pone la etiqueta *Contiene
   anuncios* en la ficha; Apple lo pregunta en App Privacy (recolección de datos
   para publicidad) y en la clasificación. Hoy `google_mobile_ads` está
   comentado en `pubspec.yaml` y no hay ni un anuncio en el binario, así que la
   respuesta técnicamente correcta en el v1 es **no**. Pero cambiarla a **sí**
   en el update que traiga los rewarded, después de haber vendido "sin
   anuncios", es el patrón que dispara reseñas de una estrella. Por eso el copy
   ya está escrito para sobrevivir ese cambio (§6, ⚠️) y hay que confirmar la
   respuesta contra el binario real al momento de enviar, no antes.
   Relacionado: si los rewarded llegan, la verificación con **AdMob SSV** es
   obligatoria antes de conceder el acceso (`CLAUDE.md`).
4. **Los datos de vitrina son una superficie de error propia.** Montos, nombres
   y fechas tienen que ser coherentes entre las 8 capturas (misma cuenta, mismas
   categorías, mismo mes) o se nota al deslizar. Es responsabilidad explícita de
   F1, no un detalle.

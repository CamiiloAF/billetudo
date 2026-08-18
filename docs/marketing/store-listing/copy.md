# Copy de las fichas de tienda — listo para copiar y pegar

Idioma: **es-419** (español LatAm). Único idioma del v1 (decisión D1 del plan).
Última actualización: 2026-08-08.

> **Antes de pegar nada, lee esto.** La frase **"sin anuncios"** está vetada en
> todos los campos. El modelo de monetización incluye anuncios con recompensa
> opcionales, y prometer lo contrario obliga a reescribir la ficha entera —
> además de quemar la confianza del usuario y de disparar reseñas de una
> estrella cuando la promesa cambie. La formulación correcta es siempre
> condicional al opt-in: *nunca verás un anuncio que no hayas pedido tú*.
> Ver §6 de [`../plan-fichas-de-tienda.md`](../plan-fichas-de-tienda.md).

---

## 1. Google Play Console

### Título — máx. 30 caracteres

```
Billetudo: gastos y ahorro
```

*(26 de 30)*

### Descripción corta — máx. 80 caracteres

```
Gastos, presupuestos y metas. Gratis, sin interrupciones y sin internet.
```

*(72 de 80)*

### Descripción larga — máx. 4000 caracteres

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

### URLs de la ficha

| Campo | Valor |
|---|---|
| Política de privacidad | `https://camiiloaf.github.io/billetudo/` |
| Correo del desarrollador | `camiiloagudelo92@gmail.com` |
| Borrado de cuenta (URL) | `https://camiiloaf.github.io/billetudo/borrar-cuenta.html` |

### Otros campos de consola

| Campo | Respuesta | Nota |
|---|---|---|
| ¿Contiene anuncios? | **No** | Verificable contra el binario: `google_mobile_ads` no está cableado y el manifiesto fusionado no declara `AD_ID`. **Cambia a Sí en cuanto se active el primer rewarded.** |
| Categoría | Finanzas | |
| Grupo de edad | 16-17 y 18+ | Coherente con la edad mínima de 16 de los términos. Ver la advertencia de Families Policy en `docs/legal/declaraciones-tiendas.md`. |

---

## 2. App Store Connect

### Nombre — máx. 30 caracteres

```
Billetudo
```

*(9 de 30)*

### Subtítulo — máx. 30 caracteres

```
Gastos, presupuesto y ahorro
```

*(28 de 30)*

### Palabras clave — máx. 100 caracteres, separadas por coma sin espacios

```
gastos,presupuesto,ahorro,finanzas,dinero,deudas,cuentas,budget,control,personal
```

*(79 de 100)*

### Texto promocional — máx. 170 caracteres

Editable sin pasar por revisión, así que sirve para anuncios puntuales.

```
Anota un gasto en segundos, arma tu presupuesto y cumple tus metas. Todo lo esencial gratis, sin interrupciones y funcionando sin internet.
```

*(139 de 170)*

### Descripción — máx. 4000 caracteres

La misma de Play, sin las viñetas `•` (Apple las renderiza de forma
inconsistente): sustituirlas por guiones o por saltos de línea.

### Clasificación por edad

**16+**, fijada manualmente. Por contenido el cuestionario daría 4+, pero eso
contradiría la edad mínima de 16 de los términos de uso. Apple rehízo los
tramos en 2025: hoy son 4+, 9+, 13+, 16+ y 18+.

---

## 3. Capturas

Guion completo, con el caption de cada una, en §4 y §4.1 de
[`../plan-fichas-de-tienda.md`](../plan-fichas-de-tienda.md).

- **Play:** 8 capturas a 1080 × 1920 + gráfico destacado 1024 × 500
- **App Store:** 9 capturas a 1290 × 2796 (la novena, Importar/Exportar, es
  exclusiva de iOS porque Play topa en 8)

Los PNG finales salen de `billetudo.pen`, zona `MARKETING / STORE`.

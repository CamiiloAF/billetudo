# Cómo se entregan los documentos legales a la app

Decisión de arquitectura del 2026-08-28. Aplica a la política de privacidad y a
los términos de uso: cómo llegan al dispositivo, cuándo se le vuelve a pedir
aceptación a la persona, y qué se muestra cuando algo falla.

Este documento es la fuente de verdad escrita. La misma decisión está anotada en
el `context` del nodo `naAqn` de `billetudo.pen` (bloque de documentos de la
hoja de re-aceptación), porque es ahí donde la lee quien implementa la pantalla
— pero el `.pen` está encriptado y solo se abre por MCP, así que no puede ser el
único lugar donde exista.

## El problema que resuelve

Si los documentos viajaran compilados en el binario, corregir la política por un
problema legal exigiría una release y esperar la revisión de App Store. Eso no
es aceptable para un arreglo urgente.

## Cómo funciona

**Publicación.** El manifiesto (`legal.json`) y los documentos se publican en
GitHub Pages, junto a la política y los términos que ya viven ahí — ver
[`web/README.md`](../../web/README.md). El manifiesto declara:

- la **versión legal vigente**,
- **qué documento cambió** en cada versión (la política, los términos, o ambos),
- un **`minAppVersion`** por cada versión legal.

**Descarga.** La app descarga y cachea manifiesto y documentos en segundo plano
al arrancar. La descarga inicial se cuelga de `FirstLaunchOfflineGate`
(`lib/core/bootstrap/first_launch_offline_screen.dart`), que ya bloquea el
primer arranque sin conexión para traer el catálogo semilla de categorías
(decisión #12 de `docs/requirements/fase-1/05-auth-sync.md`). No hace falta un
paso nuevo en el arranque: el momento ya existe y ya tiene conexión garantizada.

**Lectura.** El visor lee del caché en disco y, si no hay, del documento
empaquetado en la app. Nunca espera a la red, así que no necesita estados de
carga, error ni vacío.

## El fallback empaquetado

**No es para "no hay internet".** Ese caso ya lo cubre el gate de primer
arranque. Redactarlo mal lleva a la conclusión equivocada de que el fallback
sobra.

Es para **la descarga que falla teniendo conexión**: un 404 por un archivo mal
publicado, un timeout, GitHub Pages caído.

Reglas que se derivan:

- **Una descarga legal fallida no bloquea el arranque**, a diferencia del
  catálogo semilla. La diferencia es que para el catálogo no hay copia local
  posible y para los documentos sí; bloquear a alguien teniendo un documento
  válido en la mano sería gratuito. Se muestra el fallback y se reintenta luego.
- **El documento empaquetado debe ser el texto legal real y vigente al momento
  de publicar la app**, nunca un placeholder ni una versión vieja. Es lo que ve
  quien tuvo mala suerte con la descarga, así que tiene que sostenerse solo.
- **La línea de versión y fecha del visor refleja el documento que se está
  mostrando**, no la versión vigente del manifiesto. Si se está viendo el
  bundle, dice la versión del bundle. Mentir ahí es peor que mostrar una fecha
  vieja.
- Ver el fallback **no es un error** y no se presenta como tal.

## Qué versión se guarda al aceptar

**Siempre la del documento que se mostró de verdad**, nunca la que declara el
manifiesto. Si la descarga falló y la persona leyó y aceptó el documento
empaquetado, se guarda la versión del bundle.

De ahí sale el comportamiento correcto sin lógica adicional: cuando más adelante
la descarga sí funcione y el manifiesto declare una versión mayor, `aceptada <
vigente` y se le vuelve a pedir aceptación como si fuera una actualización. Que
es lo que corresponde — aceptó un texto anterior, no el vigente.

Guardar la versión del manifiesto en vez de la mostrada convertiría el fallback
en una aceptación falsa permanente: quedaría registrado que aceptó algo que
nunca vio.

Es el mismo principio que rige la línea de fecha del visor, aplicado a lo que se
persiste: **nunca afirmar una versión que no se puso delante de la persona.**

## Nunca pidas aceptar un documento que no puedes mostrar

Caso aparte del anterior: el manifiesto descarga bien pero el cuerpo de un
documento no. Entonces la app **sabe** que existe una versión nueva pero **no
puede mostrarla**.

En ese estado no se pide aceptación. Se sigue con el documento disponible
(caché o bundle), no se toca la versión aceptada, y se reintenta la descarga
después. Pedir que alguien acepte un texto que no podemos ponerle delante es
peor que esperar.

## Caché del CDN

GitHub Pages sirve detrás de CDN. Si `legal.json` se cachea por horas, el
arreglo legal urgente —que es la razón entera por la que estos documentos
viajan por red— deja de ser urgente.

Hay que publicarlo con cabeceras de caché cortas o con *cache busting*, y
verificarlo de verdad tras el primer despliegue, no asumirlo.

## `minAppVersion`: no lo quites

La re-aceptación se dispara solo si se cumplen **las dos** condiciones:

```
versión_aceptada < versión_vigente   Y   versión_de_la_app >= minAppVersion
```

Este guard sustituye la protección que antes daba compilar la versión en el
binario. Sin él, alguien que no ha actualizado la app recibiría una
re-aceptación de términos que describen funcionalidad que todavía no tiene
instalada — por ejemplo, que se le pida aceptar las cláusulas del asistente de
IA cuando su versión no lo incluye.

Es la pieza que alguien va a querer simplificar sin entender para qué está.

## Lo que no cambia

- **La aceptación es conjunta**: un solo botón "Acepto", una sola versión
  guardada. No se versiona por documento.
- **La hoja de re-aceptación lista solo los documentos que cambiaron** respecto
  de la versión aceptada, comparando contra el manifiesto. Si solo cambió la
  política, se muestra una fila, y el copy va en singular (ver el frame de
  referencia `X2781z` en `billetudo.pen`).

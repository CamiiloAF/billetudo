# Declaración de uso del acceso a notificaciones — Google Play

**Versión 1.0** · **9 de septiembre de 2026** · **Estado: listo para usar cuando el build exista**

> **Documento interno**, no se publica en el sitio legal. Es lo que se pega en
> Play Console —o se responde por correo si el equipo de política escribe— para
> justificar `BIND_NOTIFICATION_LISTENER_SERVICE`, más el guion del video de
> demostración.

## 0. Antes de nada: el estado del requisito

`[VERIFICAR: si Play exige un formulario de declaración específico y/o video para
BIND_NOTIFICATION_LISTENER_SERVICE al momento del envío]`

Las páginas vigentes de Play
["Permissions and APIs that Access Sensitive Information"](https://support.google.com/googleplay/android-developer/answer/16558241)
y su [versión preview](https://support.google.com/googleplay/android-developer/answer/16909972),
consultadas el **2026-09-09**, **no** listan el acceso a notificaciones entre los
permisos con formulario propio. Los que sí lo tienen: SMS y Call Log, ubicación
en segundo plano, All Files Access, `QUERY_ALL_PACKAGES`,
`REQUEST_INSTALL_PACKAGES`, API de accesibilidad, Health Connect, alarmas exactas
y full-screen intent.

**No se afirma que el requisito no exista: no se encontró documentado.** Lo que
sí está documentado es que el acceso a notificaciones se considera de **alto
riesgo** y que Play Protect lo trata así, sobre todo combinado con SMS o
accesibilidad — combinación que billetudo **no** tiene y no debe tener nunca.

Por eso este documento existe igual: la justificación se tiene lista **antes** de
enviar, no se improvisa cuando llega el correo.

---

## 1. Justificación de uso (texto listo para pegar)

### Versión corta (campo de formulario, ~1.000 caracteres)

> billetudo es una app de finanzas personales. La funcionalidad central que
> requiere acceso a notificaciones es la captura de movimientos: cuando el banco
> del usuario le envía un aviso de compra, la app extrae el monto, el comercio y
> la fecha, y crea una propuesta que el usuario confirma o descarta manualmente.
> Nunca registra un movimiento por su cuenta.
>
> El usuario elige explícitamente, de una lista cerrada de apps de banco, cuáles
> se leen; todos los interruptores vienen apagados. Las notificaciones de
> cualquier otra app se descartan por `packageName` antes de acceder a su
> contenido.
>
> El contenido literal de las notificaciones **no se almacena en ningún momento**
> ni se transmite: la base de datos de la app no tiene ninguna columna para él.
> Solo se persisten los campos financieros extraídos. El parseo ocurre en el
> dispositivo, con reglas locales empaquetadas en la app; no hay llamada de red
> en el flujo de captura.
>
> El permiso es revocable desde la app y desde los ajustes del sistema, y la app
> ofrece borrar todo lo capturado. La funcionalidad es opcional: todas las demás
> funciones operan sin ella.

### Versión larga (respuesta a una consulta de política)

**1. Qué hace la app con el permiso.**
billetudo usa `NotificationListenerService` para detectar avisos de movimientos
de dinero enviados por las apps bancarias del propio usuario, y proponerle
registrar ese movimiento en su presupuesto personal. Es la funcionalidad
diferenciadora del producto y está descrita en la ficha de la tienda.

**2. Por qué es funcionalidad central y no un extra.**
El costo de registrar cada gasto a mano es la causa principal de abandono de las
apps de finanzas personales. Esta función reduce ese costo a un toque de
confirmación. Está anunciada en la ficha de la app, es gratuita y no está detrás
de ningún pago ni anuncio.

**3. Por qué no hay alternativa técnica.**
Android no ofrece a apps de terceros ninguna otra vía para conocer el contenido
de un aviso bancario. No usamos —ni pediremos— SMS, registro de llamadas ni la
API de accesibilidad, precisamente para no acumular permisos de alto riesgo.

**4. Alcance real de la lectura.**
El sistema entrega todas las notificaciones al servicio, pero la app aplica un
filtro por `packageName` **en el primer punto de entrada**, antes de acceder a
título, texto o extras. El catálogo es **cerrado**: solo apps de banco y
billeteras conocidas del mercado objetivo. El usuario elige cuáles, con
interruptores **apagados por defecto**. Conceder el permiso sin encender ningún
emisor no captura absolutamente nada.

**5. Retención de datos.**
El contenido literal de la notificación **no se persiste nunca**: ni completo, ni
truncado, ni de forma efímera en disco. Se procesa en memoria, se extraen los
campos y se descarta. Es verificable en el esquema: la tabla de capturas no tiene
ninguna columna de texto crudo, y la migración de Postgres tampoco. Se guarda
únicamente: monto, moneda, tipo de movimiento, fecha, fragmento identificado como
comercio, últimos 4 dígitos mencionados, `packageName` del emisor e identificador
de la regla que interpretó el aviso.

**6. Transmisión.**
No hay llamada de red en el flujo de captura: ni a un backend propio, ni a
analítica, ni a un servicio de parseo externo. Los campos financieros extraídos
sincronizan a la cuenta del usuario **solo si el usuario inició sesión**, por el
mismo mecanismo que cualquier movimiento que escriba a mano, y bajo *row level
security* por usuario.

**7. Consentimiento y control.**
Antes de abrir los ajustes del sistema, la app muestra una pantalla propia que
explica qué se lee, qué se guarda, qué sincroniza y que nada se registra sin
confirmación. La pantalla anticipa además la advertencia del propio sistema. El
usuario puede: apagar un emisor concreto, apagarlos todos, apagar la función
desde la app sin tocar los ajustes del sistema, revocar el permiso desde el
sistema, y borrar de una vez todas las capturas y lo aprendido.

**8. Transparencia permanente.**
Ajustes incluye una pantalla que muestra en todo momento qué apps se están
escuchando, cuántas capturas se han creado, qué campos se guardan y cuáles no,
con enlace a la política de privacidad.

**9. Lo que la app no hace.**
No lee notificaciones de mensajería, correo ni de ninguna app fuera del catálogo.
No almacena ni transmite códigos de un solo uso. No comparte contenido de
notificaciones con terceros. No usa este acceso para publicidad, analítica,
perfilado ni ninguna finalidad distinta de la descrita. No pide SMS, registro de
llamadas ni accesibilidad.

**10. Política de privacidad.**
Descrito en lenguaje llano en https://camiiloaf.github.io/billetudo/ , secciones
4.6, 14 y 18.

---

## 2. Video de demostración — guion

Play suele pedir un video del flujo completo para permisos sensibles. Debe
mostrar el permiso **siendo usado**, no una pantalla de marketing.

**Formato:** grabación de pantalla de un dispositivo Android real, sin cortes
dentro de cada bloque, 90-150 s, sin música, con el idioma de la app en español y
subtítulos en inglés si se sube a un canal en inglés.
`[VERIFICAR: formato, duración y forma de entrega que pida la consola en el
momento del envío — enlace no listado de YouTube es lo habitual]`

| # | Qué se ve | Por qué importa para el revisor |
|---|---|---|
| 1 | La app abierta en Inicio. El usuario registra un gasto **a mano**, completo | Demuestra que la función es aditiva y que la app es plenamente usable sin el permiso |
| 2 | Aparece el ofrecimiento contextual. El usuario toca "Ver cómo funciona" | Muestra que el permiso se pide **en contexto**, no en el arranque |
| 3 | **La pantalla explicadora, leída con calma y sin cortes**: qué se lee, qué se guarda, qué sincroniza, y el anticipo de la advertencia de Android | Es la *prominent disclosure*. Es el fotograma que más pesa en la evaluación: debe leerse completo en el video |
| 4 | Se ve el botón secundario "Ahora no" antes de continuar | Prueba que no es un flujo de una sola salida |
| 5 | Toca "Ir a ajustes de Android" → pantalla del sistema → activa el switch → **el diálogo de advertencia del sistema** → acepta | Prueba que el permiso lo concede el usuario en el sistema, viendo la advertencia real |
| 6 | Vuelve a la app. Lista de emisores: **todos apagados**. El usuario enciende **uno** | Prueba consentimiento granular y por defecto apagado |
| 7 | Llega una notificación real de un banco (o de una app de prueba del catálogo) | Muestra el disparador real |
| 8 | Aparece la captura pendiente en la bandeja. **Se hace evidente que el saldo NO cambió** (mostrar el saldo antes y después) | Prueba que no se registra nada sin confirmación |
| 9 | El usuario abre la captura, ve el formulario pre-llenado, **corrige un campo** y guarda | Prueba la confirmación humana explícita |
| 10 | Llega una notificación de **otra app no habilitada** (ej. mensajería) y **no pasa nada**: la bandeja no cambia | Es la prueba más convincente del filtrado. Vale la pena que dure unos segundos |
| 11 | Ajustes → pantalla de transparencia: qué apps se escuchan, cuántas capturas, qué se guarda y qué no | Prueba la transparencia permanente |
| 12 | "Borrar todas las capturas y lo aprendido" → confirma → la bandeja queda vacía y los movimientos ya confirmados siguen ahí | Prueba el control del usuario sobre los datos |
| 13 | Apaga la función desde la app, y luego revoca el permiso desde Ajustes del sistema | Prueba la revocabilidad por las dos vías |

**Errores que arruinan el video:**

- Cortar o acelerar la pantalla explicadora. Es justo lo que se quiere ver.
- Grabar en un emulador sin notificaciones reales.
- Empezar con el permiso ya concedido.
- No mostrar nunca una notificación de una app **no** habilitada. Sin ese plano,
  la afirmación de filtrado es solo una frase.
- Mostrar datos financieros reales del desarrollador. Usar una cuenta de prueba.

---

## 3. Checklist de envío (acceso a notificaciones)

- [ ] `AndroidManifest.xml`: `<service>` con `BIND_NOTIFICATION_LISTENER_SERVICE`
      y su intent-filter, y **ningún permiso de más**.
- [ ] `<queries>` explícito con los `packageName` del catálogo. **NO**
      `QUERY_ALL_PACKAGES` (ver `declaraciones-tiendas.md` §7.1).
- [ ] Sin `READ_SMS`, `READ_CALL_LOG` ni `BIND_ACCESSIBILITY_SERVICE`, en el
      manifiesto propio **y** en el fusionado.
- [ ] Pantalla explicadora implementada y verificada en dispositivo real.
- [ ] Pantalla de transparencia implementada.
- [ ] Acción de borrado de capturas implementada.
- [ ] Data Safety enviado en el mismo envío, con las filas de
      `declaraciones-tiendas.md` §7.3 (incluida **Installed apps**).
- [ ] Ficha de tienda describe la funcionalidad, sin prometer captura total.
- [ ] Política de privacidad **v1.8 publicada antes** del envío.
- [ ] Video grabado según §2.
- [ ] Justificación de §1 pegada donde la consola la pida.

---

## 4. Límite

No es asesoría jurídica. Es una justificación construida sobre lo que el código
hace; la revisión legal formal la hace una persona abogada, y la evaluación final
la hace Google.

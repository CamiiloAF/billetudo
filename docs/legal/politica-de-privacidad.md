# Política de privacidad de billetudo

**Versión 1.8** · **Última actualización: 12 de septiembre de 2026** · **En vigor desde: 12 de septiembre de 2026**

Esta política explica qué datos maneja billetudo, dónde viven, quién más los
toca y qué puedes hacer al respecto. Está escrita para que se entienda leyéndola
una vez. Si algo no queda claro, escríbenos a
camiiloagudelo92@gmail.com.

### Qué cambió en la versión 1.8

Llegan las dos primeras funciones de billetudo que necesitan un **permiso del
sistema**. Hasta ahora la app no pedía ninguno; esta versión existe justamente
para contarlo antes de que ocurra.

- **Puedes dictar un gasto** en vez de teclearlo. Está explicado entero en la
  [sección 18.1](#181-dictar-un-gasto), incluida la parte incómoda: si tu
  teléfono no puede convertir voz en texto por su cuenta, ese trabajo lo hace un
  servidor de Apple o de Google.
- **En Android, y solo si tú lo activas, la app puede leer los avisos de compra
  de las apps de banco que elijas de una lista.** Es el permiso más invasivo que
  existe en un teléfono y le dedicamos la
  [sección 18.2](#182-leer-los-avisos-de-tu-banco-solo-android) completa: qué se
  lee, qué se guarda, qué **no** se guarda nunca y cómo apagarlo.
- **Aparece un dato de otras personas que antes no existía.** Cuando alguien te
  transfiere dinero, algunos bancos escriben su nombre completo en el aviso. Ese
  nombre se guarda como el "comercio" del movimiento y **sincroniza con tu
  cuenta**. Lo decimos con todas las letras en las secciones 4.6 y 12.
- **Recordatorios de pagos programados**, que **tu propio teléfono** programa. No
  hay servidor, no hay Firebase y no hay tokens de notificación push
  (sección 18.3).
- **Sección 14 reescrita entera.** Antes decía que la app no pide ningún permiso
  sensible. Eso deja de ser cierto y ahora hay una lista completa, permiso por
  permiso, con qué pasa si lo niegas.
- **Nueva base legal:** tu **consentimiento explícito y revocable** para dictar y
  para leer avisos bancarios (sección 6). No van bajo "ejecución del contrato":
  son tratamientos separables que tú enciendes a propósito.
- **Sigue sin haber OCR de recibos.** No leemos fotos, no pedimos cámara y no
  pedimos galería (sección 19).

Si tu versión de la app todavía no muestra estas funciones, nada de la sección
18 está ocurriendo en tu teléfono.

### Qué cambió en la versión 1.7

Esta versión no cambia lo que el asistente envía ni a quién: **confirma en el
código que dos promesas de la versión 1.6 ya son reales**, en vez de una
condición futura.

- **El interruptor de notas (sección 17.7) ya está cableado de punta a punta.**
  Existe en Ajustes (`AiSettingsSection`), pide una confirmación explícita antes
  de encenderse, se apaga sin fricción y retirar el consentimiento general del
  asistente lo apaga también. La versión 1.6 documentaba el comportamiento final
  marcado como pendiente de confirmar, porque en ese momento el ajuste existía
  solo en la base de datos y nada lo leía; esa marca se retira aquí porque ya
  se verificó en el código, no solo en el diseño.
- **Un defecto real, ya corregido, que afectaba justo a este interruptor:** por
  un tiempo, guardar *cualquier otra* preferencia de Ajustes podía resetear en
  silencio el interruptor de notas a apagado (un problema de cómo se escribía la
  fila de configuración, no del interruptor en sí). Quedó corregido antes de la
  publicación de esta versión. Lo mencionamos porque, si activaste el
  interruptor en una versión anterior de la app y lo viste "desactivarse solo",
  esa era la causa — ya no debería volver a pasar.
- **Seguimos sin haber activado el asistente para el público general** (sigue
  en beta cerrada mientras se completa lo que falta, ver `declaraciones-tiendas.md`
  §8.6). El resto de la sección 17 no cambia.

### Qué cambió en la versión 1.6

Esta versión **corrige** y **amplía** lo que la 1.5 decía del asistente. Las dos
cosas importan y las separamos, porque son distintas:

- **Corrección (aplica a todo el mundo, actives o no algo).** La versión 1.5
  decía que del bloque de deudas "solo salen totales" y que los nombres que tú
  escribes no viajaban. Eso no era exacto: **los nombres que tú les pones a tus
  cuentas, categorías, presupuestos, metas y deudas sí viajan** en el resumen
  que se manda al asistente, y siempre viajaron. Son la forma en que el
  asistente puede decir "tu presupuesto de Mercado" en vez de "tu presupuesto
  número 3". Lo decimos ahora con todas las letras en las secciones 17.2 y 17.3.
- **Novedad (solo si tú la activas).** Aparece un **interruptor en Ajustes para
  que el asistente pueda leer tus notas**. Viene **apagado**, y mientras siga
  apagado tus notas no salen del teléfono. Está explicado entero en la
  [sección 17.7](#177-el-interruptor-de-notas-apagado-hasta-que-tú-decidas).
- **Búsqueda de pagos programados sin enviar notas.** Cuando le preguntas por un
  pago concreto ("el abono de la moto"), **tu propio teléfono** busca esas
  palabras dentro de tus notas y solo devuelve datos estructurados. Ese camino
  no envía el texto de ninguna nota, ni con el interruptor apagado ni con él
  encendido (sección 17.2).
- **Se actualizaron** la tabla de terceros (sección 7) y la sección 12 (datos de
  otras personas que tú registras), para que digan lo mismo que lo anterior.

### Qué cambió en la versión 1.5

Llega el **asistente financiero con inteligencia artificial**, y con él la
primera función de billetudo que envía información tuya a un modelo de lenguaje
de un tercero. La versión 1.4 decía, correctamente para ese momento, que no
había ninguna IA en la app. Eso deja de ser cierto cuando esta función se active.

- **Sección 17, nueva:** qué hace el asistente, exactamente qué sale de tu
  teléfono, qué no sale nunca, a quién llega y qué se guarda —incluida la única
  cosa del chat que llega a nuestro servidor: el mensaje que **tú** decidas
  reportar (sección 17.5).
- **Nuevo tercero:** Google, a través de su API de Gemini (secciones 7 y 8).
- **Base legal nueva:** tu consentimiento explícito, que te pedimos dentro de la
  app antes del primer mensaje (sección 6).
- **Se corrigió** la sección 4.3: tu correo **sí** se muestra hoy en la app, en
  la tarjeta de sesión de Ajustes. La versión 1.4 decía que no.
- El resto de la política no cambió.

Si tu versión de la app todavía no muestra el asistente, nada de la sección 17
está ocurriendo en tu teléfono.

---

## Lo esencial, en diez líneas

- **billetudo funciona sin cuenta y sin conexión.** Tus movimientos, cuentas,
  presupuestos, metas y deudas se guardan en una base de datos **dentro de tu
  teléfono**. Esa es la copia principal, no una caché.
- **Mientras no inicies sesión, ningún dato financiero tuyo sale del
  dispositivo.** Ni montos, ni notas, ni nombres.
- **El respaldo en la nube es opcional** y se activa solo cuando inicias sesión.
  Al hacerlo, tu historial local —también el de antes de iniciar sesión— se sube
  a tu cuenta.
- **No vendemos tus datos. No hay publicidad. No hay analítica de
  comportamiento.** Nada de eso está en la app.
- **El número completo de tus cuentas bancarias nunca sale del teléfono**, ni
  siquiera a la nube ni en las exportaciones.
- **Puedes borrar tu cuenta desde la app**, y borra de verdad: elimina tus datos
  del servidor, no solo cierra la sesión.
- Sí hay dos cosas que salen del dispositivo aunque no tengas cuenta: la app
  **descarga el catálogo de categorías** la primera vez que se abre, y envía
  **reportes de error técnicos**. Los dos están explicados abajo, sin adornos.
- **El asistente con inteligencia artificial es la excepción a todo lo
  anterior.** Es opcional, requiere iniciar sesión y te pedimos permiso antes
  del primer mensaje. Si lo usas, un **resumen de tus finanzas** y lo que
  escribas en el chat salen del teléfono hacia Google. Ese resumen incluye **los
  nombres que tú les pusiste** a tus cuentas, categorías, presupuestos, metas y
  deudas. Está explicado entero en la
  [sección 17](#17-el-asistente-con-inteligencia-artificial), sin adornos y sin
  enterrarlo.
- **Tus notas no van al asistente, salvo que tú enciendas un interruptor.**
  Viene apagado de fábrica, está en Ajustes y lo puedes apagar cuando quieras
  (sección 17.7).
- **Puedes dictar un gasto y, en Android, dejar que la app lea los avisos de tu
  banco.** Las dos funciones son opcionales, las activas tú, y **nada se
  registra sin que lo confirmes**. Del audio y del texto del aviso **no
  guardamos nada**: solo los datos que la app entendió (monto, comercio, fecha).
  Sección 18.

---

## Índice

1. [Quién es responsable de tus datos](#1-quién-es-responsable-de-tus-datos)
2. [A quién y a qué aplica esta política](#2-a-quién-y-a-qué-aplica-esta-política)
3. [Cómo funciona billetudo: local primero](#3-cómo-funciona-billetudo-local-primero)
4. [Qué datos existen y dónde viven](#4-qué-datos-existen-y-dónde-viven)
5. [Qué sale de tu dispositivo, cuándo y hacia dónde](#5-qué-sale-de-tu-dispositivo-cuándo-y-hacia-dónde)
6. [Para qué usamos cada dato y con qué base legal](#6-para-qué-usamos-cada-dato-y-con-qué-base-legal)
7. [Con quién compartimos datos](#7-con-quién-compartimos-datos)
8. [Transferencias internacionales](#8-transferencias-internacionales)
9. [Cuánto tiempo conservamos tus datos](#9-cuánto-tiempo-conservamos-tus-datos)
10. [Cómo borrar tu cuenta y tus datos](#10-cómo-borrar-tu-cuenta-y-tus-datos)
11. [Tus derechos y cómo ejercerlos](#11-tus-derechos-y-cómo-ejercerlos)
12. [Datos de otras personas que tú registras](#12-datos-de-otras-personas-que-tú-registras)
13. [Exportar e importar archivos](#13-exportar-e-importar-archivos)
14. [Permisos que la app pide](#14-permisos-que-la-app-pide)
15. [Seguridad](#15-seguridad)
16. [Menores de edad](#16-menores-de-edad)
17. [El asistente con inteligencia artificial](#17-el-asistente-con-inteligencia-artificial)
18. [Cómo billetudo captura tus gastos](#18-cómo-billetudo-captura-tus-gastos)
19. [Lo que billetudo hoy no hace](#19-lo-que-billetudo-hoy-no-hace)
20. [Cambios a esta política](#20-cambios-a-esta-política)
21. [Contacto](#21-contacto)

---

## 1. Quién es responsable de tus datos

El responsable del tratamiento de los datos personales descritos aquí es:

billetudo lo desarrolla y opera una **persona natural**, no una empresa. No hay
compañía detrás: es un proyecto independiente. Te lo decimos de frente porque
cambia a quién le escribes cuando quieres ejercer tus derechos.

- **Responsable:** Juan Camilo Agudelo Franco, persona natural
- **Correo de contacto para asuntos de privacidad:** camiiloagudelo92@gmail.com
- **Ley aplicable al responsable:** la de la **República de Colombia**, sin
  perjuicio de la normativa de tu propio país (ver los
  [Términos de uso](https://camiiloaf.github.io/billetudo/terminos.html), sección 13)

Ese correo es el **único canal oficial** para asuntos de datos personales. El
responsable atiende personalmente las solicitudes; no hay un delegado de
protección de datos (DPO) designado, porque el tratamiento que hace billetudo no
obliga a designarlo (ver sección 11).

Cuando esta política dice "nosotros", se refiere a esa persona.

---

## 2. A quién y a qué aplica esta política

Aplica a la aplicación móvil **billetudo** para Android e iOS, y a los servicios
en la nube que la app usa cuando decides iniciar sesión.

No aplica a los servicios de terceros que uses por tu cuenta, incluso si es para
entrar a billetudo: cuando inicias sesión con Google o con Apple, esas empresas
tratan tus datos bajo **sus** políticas, no bajo esta.

---

## 3. Cómo funciona billetudo: local primero

Esto no es un detalle técnico, es la decisión que explica casi todo lo demás.

billetudo guarda tu información en una base de datos **dentro del
almacenamiento privado de la app**, en tu teléfono. Esa base de datos es la
copia de referencia: la app lee y escribe ahí, y funciona completa sin conexión
y sin cuenta. Puedes usar billetudo por tiempo indefinido sin registrarte.

La nube es una **capa opcional encima**. Sirve para dos cosas: que no pierdas tus
datos si pierdes el teléfono, y que puedas usar la app en más de un dispositivo.
Nada más. Si nunca inicias sesión, esa capa no existe para ti.

---

## 4. Qué datos existen y dónde viven

### 4.1 Los datos que tú creas (siempre en tu dispositivo)

Todo esto lo escribes tú y vive en tu teléfono. Solo llega a la nube si inicias
sesión.

| Qué | Ejemplos concretos |
|---|---|
| **Cuentas** | Nombre que tú le pones, tipo (efectivo, ahorros, tarjeta…), moneda, saldo inicial, **nombre de la entidad financiera**, **últimos 4 dígitos** de la tarjeta, tasa de interés, cupo, día de corte y de pago |
| **Movimientos** | Monto, moneda, tipo (ingreso, gasto, transferencia), fecha, cuenta, categoría, **nota de texto libre** y etiquetas |
| **Categorías y etiquetas** | Los nombres, iconos y colores que tú definas |
| **Presupuestos** | Nombre, monto, periodo, umbral de alerta, cuentas y categorías asociadas |
| **Metas de ahorro** | Nombre, monto objetivo, fecha, aportes y sus **notas** |
| **Deudas** | Nombre, si te deben o debes, monto, tasa, **nombre de la contraparte** (la persona o entidad), fecha de vencimiento, movimientos del historial y sus **notas** |
| **Pagos programados** | Cuenta, categoría, monto, frecuencia, fechas y **notas** |
| **Importaciones** | El **nombre del archivo** que importaste y cuántas filas entraron |
| **Últimos 4 dígitos de tu tarjeta** | Si los registras en una cuenta, se usan para adivinar a qué cuenta pertenece un aviso del banco (sección 18.2) |
| **Recordatorios** | Cuántos días antes de un pago programado quieres que el teléfono te avise |
| **Capturas pendientes** | Lo que la app entendió de un aviso de tu banco y todavía no has confirmado. Detalle completo en la [sección 4.6](#46-lo-que-la-app-extrae-de-los-avisos-de-tu-banco-solo-android) |
| **Lo que la app aprende de ti** | Que a un comercio ("EXITO") tú le asignas siempre una categoría ("Mercado"), para pre-llenarla la próxima vez. Es una lista de pares comercio → categoría, y nada más |
| **Preferencias** | Tema claro/oscuro, moneda, modo de presupuesto, el orden en que ordenaste los accesos rápidos de Inicio, qué tutoriales ya viste |

Ten presente que las **notas** son campos de texto libre: ahí cabe lo que tú
escribas, incluida información que quizá prefieras no escribir. Lo mismo aplica
a los **nombres** que les pones a tus cuentas, categorías, presupuestos, metas y
deudas. Si usas el asistente de IA, esos nombres viajan a Google y tus notas
solo si tú lo activas: está explicado en la
[sección 17](#17-el-asistente-con-inteligencia-artificial).

### 4.2 El número completo de tus cuentas bancarias

Si lo registras, el **número completo** de una cuenta o tarjeta se guarda en el
almacén seguro del sistema operativo (**Keychain** en iOS, **Keystore** en
Android), cifrado por el propio sistema.

Ese número:

- **nunca** se guarda en la base de datos de la app,
- **nunca** se sube a la nube ni se sincroniza,
- **nunca** aparece en una exportación, ni en CSV ni en la copia completa,
- en iOS, está marcado para **no incluirse en las copias de seguridad de
  iCloud**.

Lo único que sí puede salir del teléfono son los **últimos 4 dígitos**, si los
guardaste, porque son el fragmento que la app usa para que reconozcas la cuenta.

**Advertencia honesta:** hoy, si borras tu cuenta o borras los datos locales, ese
número guardado en el llavero del sistema **puede quedarse ahí**, porque el
borrado masivo no lo alcanza. Sí se elimina cuando borras la cuenta bancaria
concreta desde la app. Estamos corrigiéndolo; mientras tanto, si quieres estar
seguro de eliminarlo, borra primero cada cuenta bancaria dentro de la app o
desinstala la aplicación.

### 4.3 Los datos de tu cuenta de billetudo (solo si inicias sesión)

billetudo **solo permite iniciar sesión con Google o con Apple**. Nunca pedimos
ni almacenamos contraseñas, ni tu número de teléfono.

Al iniciar sesión, el proveedor nos entrega:

| Proveedor | Qué nos entrega |
|---|---|
| **Google** (Android e iOS) | Un identificador de usuario, tu **nombre**, tu **correo electrónico** y la URL de tu **foto de perfil** |
| **Apple** (solo iOS) | Un identificador de usuario, y —**solo la primera vez** que autorizas— tu **nombre** y tu **correo**. Si usas "Ocultar mi correo", recibimos la dirección de reenvío de Apple, no tu correo real. Apple no entrega foto |

Qué hacemos con eso:

- El **identificador de usuario** se usa para marcar cuáles filas de la base de
  datos son tuyas. Es lo único que queda guardado también en tu dispositivo.
- El **nombre** se muestra en la app: en el saludo de la pantalla de Inicio y en
  la tarjeta de sesión de Ajustes. El avatar circular que ves son tus
  **iniciales, dibujadas en el teléfono**.
- El **correo** se guarda en el servicio de autenticación y se muestra en la
  **tarjeta de sesión de Ajustes**, para que sepas con qué cuenta estás dentro.
  No aparece en ninguna otra pantalla y no se envía a nadie más.
- La **foto de perfil**: recibimos la URL, pero **la app nunca la descarga ni la
  muestra**.

Nada de esto (nombre, correo, foto) se guarda en la base de datos local de tu
teléfono.

### 4.4 Datos técnicos de errores

Ver la [sección 5.3](#53-reportes-de-error).

### 4.5 Tus conversaciones con el asistente

Si usas el asistente con inteligencia artificial, lo que escribes y lo que te
responde se guardan **solo en tu teléfono**, en una tabla que **no se
sincroniza** ni siquiera con la sesión iniciada. No guardamos una copia de tu
conversación en ningún servidor nuestro.

Hay **una sola excepción, y la disparas tú**: si reportas un mensaje del
asistente porque te pareció ofensivo o equivocado, ese mensaje —solo ese— se
guarda en nuestro servidor para que podamos revisarlo. La app te lo advierte
antes de enviarlo. Los detalles están en la
[sección 17.5](#175-qué-se-guarda-y-dónde).

### 4.6 Lo que la app extrae de los avisos de tu banco (solo Android)

Esto aplica **únicamente** si activaste la lectura de avisos bancarios
(sección 18.2). Si no la activaste, nada de esta sección existe en tu teléfono.

Cuando la app reconoce que un aviso es un movimiento de dinero, guarda una
**captura pendiente**. Una captura pendiente contiene esto, y **nada más que
esto**:

| Qué se guarda | Ejemplo |
|---|---|
| Monto y moneda | `45.900` · `COP` |
| Si parece gasto o ingreso | gasto |
| Fecha y hora del movimiento | 3 de septiembre, 14:12 |
| **Comercio o contraparte**, tal como venía escrito en el aviso | `EXITO CALLE 80` |
| Los **últimos 4 dígitos** que mencionó el aviso | `1234` |
| Qué app envió el aviso | `com.nu.production` |
| Qué regla de lectura lo interpretó | `nu-compra-tarjeta` |
| Si ya la confirmaste o descartaste, y a qué movimiento dio lugar | — |

**El texto del aviso no está en esa lista, y no es un olvido.** En la base de
datos de billetudo **no existe ninguna casilla donde quepa** el mensaje que te
mandó tu banco: ni completa, ni recortada, ni por un rato. La app lee el aviso,
saca esos campos y descarta el texto en el acto. Puedes comprobarlo tú: es una
decisión de cómo está construida la base de datos, no una promesa nuestra.

Esa decisión tiene una consecuencia que preferimos decirte: **si la app entendió
mal, no tienes el mensaje original contra el cual comparar.** Lo aceptamos a
propósito. El texto de tus avisos bancarios sería el dato más sensible de toda
la app —ahí caben códigos de seguridad, nombres y saldos— y preferimos no
tenerlo.

#### El nombre de otras personas

Cuando alguien te transfiere dinero, **algunos bancos escriben su nombre
completo** en el aviso: *"Te llegó dinero de DANIELA TORO VALENCIA"*. Ese nombre
es justo lo que la app extrae como "comercio", así que **se guarda como parte de
la captura y, si iniciaste sesión, se sincroniza a tu cuenta en la nube**,
exactamente igual que si tú lo hubieras escrito a mano.

- Otros bancos lo enmascaran, y entonces no hay ningún nombre que guardar.
- No podemos evitarlo desde la app: el nombre viene dentro del aviso.
- **Puedes editarlo o descartar la captura** antes de confirmarla, y puedes
  borrar todas las capturas de una vez (sección 18.4).

Es información de una persona que probablemente no usa billetudo, así que
preferimos que lo sepas antes y no después. Ver también la
[sección 12](#12-datos-de-otras-personas-que-tú-registras).

---

## 5. Qué sale de tu dispositivo, cuándo y hacia dónde

Esta es la sección más importante de la política, y la escribimos con detalle
porque "local-first" no significa "cero red".

### 5.1 Antes de iniciar sesión

**Ningún dato financiero tuyo sale del dispositivo.** Ni montos, ni notas, ni
nombres de cuentas, ni deudas, ni nada que tú hayas escrito.

Pero sí hay tráfico de red, y conviene que lo sepas:

1. **Catálogo de categorías.** La **primera vez** que abres billetudo, la app
   descarga desde nuestro servidor el catálogo de categorías por defecto
   (Comida, Transporte, Salud…). Es una **descarga**, no un envío: no lleva
   ningún dato tuyo. Pero, como toda conexión, nuestro proveedor recibe la
   **dirección IP** y los metadatos de red habituales de tu dispositivo.
   Consecuencia práctica que te debemos: **el primer arranque de la app requiere
   conexión**. Si no la hay, la app te muestra una pantalla de reintento hasta
   que la consigas. A partir de ahí, funciona sin conexión.
2. **Reportes de error**, si ocurre alguno. Ver 5.3.

### 5.2 Cuando inicias sesión

Al iniciar sesión, la app empieza a sincronizar. Concretamente:

- **Se sube todo tu historial existente**, incluido el que creaste **antes** de
  iniciar sesión. Ese es el propósito: no perder nada. Pero significa que el
  momento de iniciar sesión es el momento en que tus datos financieros salen del
  teléfono por primera vez.
- A partir de ahí, la sincronización es **continua y bidireccional**: cada
  cambio que hagas se sube, y cada cambio hecho en otro dispositivo tuyo baja.
- Lo que se sincroniza son todas las categorías de datos de la
  [sección 4.1](#41-los-datos-que-tú-creas-siempre-en-tu-dispositivo), incluidos
  el nombre de la entidad financiera, los últimos 4 dígitos, el nombre de la
  contraparte de una deuda y las notas de texto libre.
- **Lo que borras también se sincroniza como borrado**, y por ahora la fila
  correspondiente **sigue existiendo en el servidor** marcada como eliminada, en
  vez de desaparecer de inmediato. Se elimina de verdad cuando borras tu cuenta.
- **No hay un interruptor de sincronización separado.** Está atada a la sesión:
  se activa al iniciar sesión y se detiene al cerrarla. Si la app tiene una
  sesión guardada, se reconecta sola al abrirse.

### 5.3 Reportes de error

billetudo usa **Sentry** para saber cuándo la app falla. Está **activo por
defecto** y hoy **no hay una forma de desactivarlo desde la app**. Te lo decimos
de frente porque preferimos eso a esconderlo en un párrafo.

- **Qué se envía:** el tipo de error, el punto del código donde ocurrió, la
  versión de la app y datos del dispositivo (modelo, versión del sistema
  operativo, memoria disponible y similares), más un pequeño rastro de las
  acciones previas al fallo.
- **Qué no se envía deliberadamente:** no enviamos capturas de pantalla, no
  enviamos el árbol de la interfaz, y no asociamos los reportes a tu
  identificador de usuario.
- **Lo que no podemos garantizar al 100%:** cuando el error viene del servidor
  de base de datos, el mensaje técnico de ese error puede, en casos puntuales,
  incluir fragmentos del dato que causó el fallo. No es intencional ni es lo
  habitual, pero sería deshonesto prometerte que es imposible. Estamos añadiendo
  un filtro para descartar esos fragmentos antes de enviarlos.
- **Qué se filtra antes de guardarse:** en Sentry tenemos activados los filtros
  automáticos que eliminan contraseñas, números de tarjeta y patrones
  equivalentes, y la opción que **impide almacenar direcciones IP**. Dos
  precisiones que te debemos:
  - Ese filtrado ocurre **en los servidores de Sentry, al recibir el reporte**.
    O sea: el dato igual sale de tu teléfono y llega a Sentry, y ahí se limpia
    antes de almacenarse. No es lo mismo que no enviarlo, y no vamos a decírtelo
    como si lo fuera. Estamos trabajando para que ese filtrado también ocurra en
    la app, antes de que el reporte salga del dispositivo.
  - El bloqueo de direcciones IP aplica a los **eventos nuevos**. Los reportes
    almacenados antes de activarlo conservan la IP hasta que venza su plazo de
    conservación.
- **Dónde se procesa:** en los servidores de Sentry en **Estados Unidos**.
- **Cuánto dura:** **30 días**. Es el plazo de conservación del plan de Sentry
  que usamos; cumplido ese plazo, los reportes se eliminan solos.

### 5.4 Resumen: destinos de tus datos

| Destino | Qué recibe | Cuándo |
|---|---|---|
| **Supabase** (base de datos y autenticación) | Todos tus datos financieros, tu correo y nombre, y los mensajes del asistente que decidas reportar | Solo con sesión iniciada (excepto el catálogo de categorías, que es una descarga anónima) |
| **PowerSync** | Los mismos datos, en tránsito, para sincronizarlos | Solo con sesión iniciada |
| **Sentry** | Diagnósticos técnicos de fallos | Siempre que ocurra un error |
| **Google / Apple** | Los datos de tu inicio de sesión, según sus propias políticas | Solo si inicias sesión |
| **Apple o Google (reconocimiento de voz del sistema)** | Solo si dictas un gasto **y** tu teléfono no puede convertir voz en texto por su cuenta: en ese caso el audio se procesa en sus servidores. Ni el audio ni la transcripción se guardan en ninguna parte (sección 18.1) | Solo al dictar, en los teléfonos donde no hay reconocimiento local |
| **Google (API de Gemini)** | El texto que escribes en el chat y un resumen de tus finanzas, con los nombres que tú les pusiste a tus cuentas, categorías, presupuestos, metas y deudas. **Tus notas solo si enciendes el interruptor de la sección 17.7**, que viene apagado | Solo si usas el asistente, después de aceptarlo (sección 17) |

---

## 6. Para qué usamos cada dato y con qué base legal

| Finalidad | Datos | Base legal (RGPD, art. 6) |
|---|---|---|
| Que la app funcione: registrar y mostrar tus finanzas | Los de la sección 4.1 | **Ejecución del contrato** (art. 6.1.b) |
| Identificarte y proteger tu cuenta | Identificador, correo, nombre | **Ejecución del contrato** (art. 6.1.b) |
| Respaldar y sincronizar entre tus dispositivos | Los de la sección 4.1 | **Ejecución del contrato**, a petición tuya al iniciar sesión (art. 6.1.b) |
| Responder tus preguntas con el asistente de IA | El texto que escribes y el resumen financiero de la sección 17, con los nombres que tú les diste a tus cuentas, categorías, presupuestos, metas y deudas | **Consentimiento** explícito, que puedes retirar (art. 6.1.a) |
| Responder con más precisión leyendo tus notas | El texto libre de tus notas (sección 17.7) | **Consentimiento** explícito y **separado** del anterior: es un interruptor aparte, apagado por defecto, que puedes apagar cuando quieras (art. 6.1.a) |
| Revisar un mensaje del asistente que tú reportaste y corregir la función | El mensaje reportado, el motivo y tu comentario (sección 17.5) | **Interés legítimo** en moderar el contenido que genera la app, a partir de un envío tuyo; además es un requisito de Google Play para las apps con IA generativa (art. 6.1.f) |
| Convertir en texto lo que dictas para llenar el formulario | El audio de ese dictado y su transcripción, mientras el formulario está abierto (sección 18.1) | **Consentimiento** explícito, que das al conceder el micrófono y puedes retirar desde Ajustes del sistema (art. 6.1.a) |
| Leer los avisos de las apps de banco que elijas y proponerte el movimiento | Monto, comercio o contraparte, fecha, últimos 4 dígitos y app emisora (sección 4.6) | **Consentimiento** explícito, **separable y revocable**: lo activas tú en Ajustes del sistema, eliges app por app y lo apagas cuando quieras (art. 6.1.a). No va bajo "ejecución del contrato": la app funciona entera sin esto |
| Recordarte un pago programado | La fecha del pago y cuántos días antes pediste el aviso | **Ejecución del contrato**, a petición tuya al activar el recordatorio (art. 6.1.b) |
| Detectar y corregir fallos de la app | Diagnósticos técnicos (sección 5.3) | **Interés legítimo** en mantener la app estable y segura (art. 6.1.f) |
| Cumplir obligaciones legales y responder a autoridades | Los estrictamente exigidos | **Obligación legal** (art. 6.1.c) |

En Colombia, México y Brasil el tratamiento se realiza con tu **autorización**,
otorgada al aceptar esta política y al usar la aplicación, y en desarrollo de la
relación contractual que se crea al usarla.

**Para lo que NO usamos tus datos:** no los vendemos, no los alquilamos, no los
cedemos a terceros con fines comerciales, no hacemos perfilado publicitario, no
te enviamos correos de marketing y no tomamos decisiones automatizadas que
produzcan efectos jurídicos sobre ti.

---

## 7. Con quién compartimos datos

Los siguientes proveedores tratan datos **por cuenta nuestra** (son encargados
del tratamiento), bajo contrato y solo para las finalidades de arriba:

| Proveedor | Para qué | Qué recibe |
|---|---|---|
| **Supabase, Inc.** | Base de datos en la nube y autenticación | Tus datos financieros sincronizados, tu correo, nombre y foto de perfil (URL), y los mensajes del asistente que reportes |
| **JourneyApps / PowerSync** | Motor de sincronización entre el teléfono y la base de datos | Los mismos datos, en tránsito |
| **Functional Software, Inc. (Sentry)** | Reporte de errores | Diagnósticos técnicos, sin identificador de usuario y sin dirección IP almacenada (filtrado aplicado en su servidor, ver 5.3) |
| **Google LLC (API de Gemini)** | Generar las respuestas del asistente de IA | El texto que escribes en el chat y el resumen financiero de la sección 17, incluidos los **nombres** que tú les pusiste a tus cuentas, categorías, presupuestos, metas y deudas. **Tus notas solo si enciendes el interruptor de la sección 17.7**; viene apagado. **No** recibe tu correo, tu nombre, el nombre de tu banco ni los últimos 4 dígitos de tus tarjetas |

Además, **Google LLC** y **Apple Inc.** actúan como **responsables
independientes** en dos momentos, y en ninguno de los dos actúan por cuenta
nuestra:

- **Cuando inicias sesión con ellos:** no les enviamos tus datos financieros,
  pero ellos saben que iniciaste sesión en billetudo y aplican sus propias
  políticas.
- **Cuando dictas un gasto en un teléfono sin reconocimiento de voz local:** el
  audio lo procesa el servicio de reconocimiento del propio sistema operativo,
  que es de Apple o de Google según tu teléfono. Nosotros no elegimos ese
  destino ni recibimos el audio: la app le pide al sistema que transcriba y
  recibe el texto de vuelta. Lo que hagan con ese audio se rige por **sus**
  políticas de privacidad, no por esta. En iPhone el propio sistema te lo
  advierte con un aviso que dice que los datos de voz se enviarán a Apple. Está
  explicado en la [sección 18.1](#181-dictar-un-gasto).

También podríamos revelar información si una autoridad competente nos lo exige
legalmente, o si es necesario para defender derechos ante un fraude o un abuso.
En ese caso, te lo notificaríamos salvo que la ley lo prohíba.

Con cada uno de esos proveedores debe existir un **acuerdo de encargo del
tratamiento** (el contrato que los obliga a tratar tus datos solo siguiendo
nuestras instrucciones, a protegerlos y a devolverlos o borrarlos al terminar).
Con Supabase ese acuerdo forma parte de sus propios términos de servicio, así
que aplica automáticamente desde que usamos el servicio. Con Google, para el
asistente, usamos el servicio de pago de la API de Gemini, cuyos términos
incluyen el acuerdo de tratamiento de datos y establecen que **el contenido que
enviamos no se usa para entrenar ni mejorar los modelos de Google**. Con Sentry
y con PowerSync estamos formalizándolo; mientras eso no esté cerrado, billetudo
**no se ofrece a residentes del Espacio Económico Europeo** (los países de la
Unión Europea, más Islandia, Liechtenstein y Noruega).

---

## 8. Transferencias internacionales

**Tus datos salen de tu país.** Lo decimos primero y sin rodeos.

Si usas billetudo sin iniciar sesión, esto casi no te afecta: solo la descarga
del catálogo y los reportes de error cruzan la frontera. Si inicias sesión, tus
datos financieros se almacenan y se procesan en **Estados Unidos**. Y si usas el
asistente, el resumen de tus finanzas se procesa en la infraestructura de
Google, también fuera de tu país.

| Proveedor | Dónde se procesa |
|---|---|
| Sentry | **Estados Unidos** |
| Supabase | **Estados Unidos** |
| PowerSync | **Estados Unidos** |
| Google (API de Gemini, solo si usas el asistente) | **Estados Unidos** y, según la disponibilidad del servicio, otros países donde Google opera |
| Apple o Google (reconocimiento de voz, solo al dictar y solo en teléfonos sin reconocimiento local) | En la infraestructura de cada uno, **fuera de tu país**. Ni Apple ni Google publican el país exacto donde procesan el reconocimiento de voz de apps de terceros, así que no podemos nombrarte uno: lo que sí podemos asegurarte es que ocurre en la nube de quien fabrica tu teléfono, no en nuestros servidores ni en los de Supabase |

**Por qué es así:** son los proveedores que hacen posible la sincronización sin
pérdida de datos y sin que tengamos que operar servidores propios. No hay hoy un
equivalente con alojamiento local que sostenga el mismo modelo.

**Con qué garantías.** Para las transferencias desde el Espacio Económico
Europeo nos apoyamos en las **Cláusulas Contractuales Tipo** aprobadas por la
Comisión Europea, incluidas en los contratos con nuestros proveedores. Para
Colombia, México y Brasil, la transferencia se realiza con tu autorización
expresa y bajo compromisos contractuales de confidencialidad y seguridad
equivalentes a los de esta política.

Si prefieres que tus datos no salgan del país, **no inicies sesión**: la app es
completamente funcional sin cuenta, y esa es una decisión de diseño, no un
consuelo.

---

## 9. Cuánto tiempo conservamos tus datos

| Dato | Cuánto dura |
|---|---|
| Datos en tu dispositivo | Hasta que los borres tú, borres los datos de la app o la desinstales. No caducan solos |
| Datos en la nube | Mientras tu cuenta exista. Se eliminan al borrar la cuenta |
| Elementos que enviaste a la papelera | Siguen guardados, marcados como eliminados, hasta que borres tu cuenta. **Hoy no se purgan automáticamente** |
| Cuenta de usuario (correo, nombre) | Mientras la cuenta exista |
| Reportes de error | **30 días** en Sentry, según el plazo de conservación del plan que usamos. Vencido ese plazo se eliminan solos |
| Copias de seguridad del proveedor de base de datos | **No hay.** El plan que usamos en Supabase no incluye copias de seguridad automáticas |
| El audio que dictas y su transcripción | **No se conservan.** Existen en la memoria del teléfono mientras el formulario está abierto y se descartan al cerrarlo. Lo único que sobrevive es lo que tú dejaste guardado en un campo del formulario |
| El texto de un aviso de tu banco | **No se conserva, en ninguna parte y en ningún momento.** No hay dónde guardarlo (sección 4.6) |
| Capturas pendientes que no has confirmado | En tu teléfono —y en tu cuenta, si iniciaste sesión— hasta que las confirmes, las descartes o las borres. **Hoy no caducan solas**: pueden quedarse ahí indefinidamente si no actúas sobre ellas |
| Capturas que descartaste | Se eliminan definitivamente pasada la ventana para deshacer la acción. No quedan marcadas como borradas: se van |
| Lo que la app aprendió (comercio → categoría) | Mientras exista tu cuenta o hasta que uses "borrar lo capturado" (sección 18.4) |
| Tus conversaciones con el asistente | Solo en tu teléfono, hasta que las borres tú, borres los datos de la app o la desinstales. **No se respaldan**: si cambias de teléfono, no viajan |
| Registro técnico de uso del asistente (sin contenido) | Mientras tu cuenta exista. Se elimina al borrar la cuenta |
| Mensajes del asistente que **tú** reportaste | En nuestro servidor mientras tu cuenta exista. **No se purgan solos** cuando terminamos de revisarlos: quedan como registro de la revisión. Se eliminan al borrar la cuenta |
| Lo que envías al asistente, en los servidores de Google | Google registra las solicitudes **por un tiempo limitado**, solo para detectar abusos y por obligaciones legales, y no las usa para entrenar sus modelos en el servicio de pago que usamos |

Tras borrar tu cuenta, los datos desaparecen de la base de datos activa de forma
inmediata. Y como no existen copias de seguridad automáticas, no queda una copia
tuya esperando a que la rotación la elimine: el borrado es efectivo de una vez.

Te lo decimos porque juega a tu favor en privacidad, pero tiene su otra cara y
preferimos que la sepas: **si algo le pasara a nuestra base de datos, no habría
copia desde la cual restaurarla.** Por eso la copia principal de tus datos vive
en tu teléfono y no en la nube, y por eso te recomendamos usar de vez en cuando
**Más → Importar y exportar → Guardar una copia**.

---

## 10. Cómo borrar tu cuenta y tus datos

Puedes hacerlo tú, desde la app, sin escribirnos ni llamar a nadie.

### El camino, paso a paso

1. Abre billetudo y toca **"Más"** en la barra inferior.
2. Toca **"Ajustes"**.
3. Baja hasta el final de la pantalla y toca **"Eliminar cuenta"** (el bloque
   rojo con el icono de papelera).
4. Lee el aviso —**"Esta acción es irreversible"**— y confirma con **"Eliminar
   cuenta"**.
5. La app te pregunta **"¿Qué hacemos con tus datos en este teléfono?"**. Elige
   entre **conservar** tus datos locales para seguir usando la app sin cuenta, o
   **borrarlos también**. Toca **"Continuar"**.
6. Verás la confirmación: **"Listo, tu cuenta fue eliminada"**.

### Qué pasa exactamente

- **Se eliminan tus datos del servidor**, de forma inmediata: cuentas,
  movimientos, categorías, presupuestos, metas, deudas, pagos programados,
  etiquetas y preferencias, **más las capturas pendientes de avisos bancarios y
  lo que la app aprendió sobre tus comercios**.
- **Se elimina tu usuario** del sistema de autenticación, con tu correo y tu
  nombre.
- **Se elimina tu habilitación, el registro técnico de uso del asistente y los
  mensajes que hayas reportado**, con su motivo y tu comentario. Los reportes no
  sobreviven al borrado de la cuenta: no abrimos una excepción para ellos.
  El resto de la conversación nunca estuvo en el servidor: vive en tu teléfono y
  se va con los datos locales.
- No es un borrado lógico ni una desactivación: las filas se eliminan.
- Si eliges borrar también lo local, se vacía la base de datos del teléfono.
  Ten presente lo que advertimos en la [sección 4.2](#42-el-número-completo-de-tus-cuentas-bancarias)
  sobre los números de cuenta guardados en el llavero del sistema.

### Si nunca iniciaste sesión

La opción existe igual y borra los datos guardados en tu dispositivo. La app te
lo dice explícitamente en pantalla para que no creas que borraste algo que
estaba en la nube.

### Antes de borrar

El borrado es irreversible. Si quieres conservar tu historial, usa
**Más → Importar y exportar → Guardar una copia** antes de continuar.

### Borrar sin la app

Si desinstalaste la app y no puedes recuperarla, escríbenos a
camiiloagudelo92@gmail.com desde el correo
asociado a tu cuenta y la eliminaremos.

---

## 11. Tus derechos y cómo ejercerlos

Tienes derecho a **conocer, acceder, actualizar, rectificar, suprimir y
oponerte** al tratamiento de tus datos, así como a **revocar la autorización** y
a solicitar la **portabilidad** de tu información.

Buena parte de eso lo puedes hacer sin pedirnos permiso, dentro de la app:

| Derecho | Cómo ejercerlo tú mismo |
|---|---|
| **Acceso** | Todos tus datos están visibles en la app |
| **Rectificación** | Edita cualquier registro directamente. Única excepción: un reporte del asistente ya enviado (ver la nota de abajo) |
| **Supresión** | Borra registros uno a uno, o borra tu cuenta completa (sección 10) |
| **Portabilidad** | **Más → Importar y exportar**: obtienes tus datos en CSV estándar o en una copia completa. Sin límites, sin costo y sin necesidad de cuenta |
| **Revocar la autorización de la nube** | Cierra sesión: la sincronización se detiene de inmediato |
| **Revocar el permiso del asistente de IA** | Ajustes: retira el permiso y borra tu historial de conversación. Deja de enviarse cualquier cosa a Google |
| **Revocar el consentimiento de dictado** | Quita el permiso de micrófono en Ajustes del sistema |
| **Revocar el consentimiento de lectura de avisos bancarios** | Un interruptor en la app, o Ajustes del sistema de Android. Además puedes borrar de una vez todas las capturas y lo aprendido (sección 18.4) |

### Lo único que no puedes deshacer desde la app: un reporte ya enviado

Cuando reportas un mensaje del asistente, ese reporte **no se puede editar ni
borrar** desde la app. Es a propósito: un reporte modificable después de
enviarlo no sirve para revisar nada. La app te lo advierte antes de enviarlo,
para que decidas con eso claro.

Eso no anula tu derecho de rectificación y supresión: escríbenos al correo de
abajo y corregimos o eliminamos el reporte. Y si borras tu cuenta, se va con
ella, como todo lo demás.

Ojo con un detalle: **retirar el permiso del asistente no borra los reportes que
ya enviaste**. Retirar el permiso detiene los envíos a Google y te deja borrar tu
conversación local; los reportes se eliminan al borrar la cuenta o pidiéndonoslo.

Para lo que no puedas resolver por tu cuenta, escríbenos a
camiiloagudelo92@gmail.com. Responderemos en
un plazo máximo de **15 días hábiles** (Colombia), **20 días hábiles** (México)
o **30 días** (Brasil y Unión Europea), contados desde que recibimos la
solicitud. Podríamos pedirte que acredites tu identidad antes de actuar, para no
entregarle tus datos a otra persona.

### Según dónde estés

- **Colombia — Ley 1581 de 2012 y Decreto 1377 de 2013.** Tienes derecho de
  *habeas data*. Si consideras que no atendimos tu solicitud, puedes presentar
  un reclamo ante la **Superintendencia de Industria y Comercio (SIC)**, después
  de haber agotado el trámite de consulta o reclamo con nosotros.
  El responsable **no está inscrito** en el Registro Nacional de Bases de Datos
  (RNBD) de la SIC, y no tiene que estarlo: desde el Decreto 090 de 2018, esa
  obligación aplica solo a personas jurídicas —sociedades y entidades sin ánimo
  de lucro con activos superiores a 100.000 UVT, y personas jurídicas
  públicas—. Una persona natural queda fuera. Esto no reduce ninguno de tus
  derechos ni nuestras obligaciones bajo la Ley 1581.
- **México — LFPDPPP.** Tienes derechos **ARCO** (Acceso, Rectificación,
  Cancelación y Oposición) y puedes acudir al **INAI**.
- **Brasil — LGPD.** Tienes los derechos del art. 18, incluida la confirmación
  del tratamiento, la anonimización y la portabilidad, y puedes acudir a la
  **ANPD**.
- **Unión Europea y España — RGPD.** Tienes los derechos de los arts. 15 a 22,
  incluida la limitación del tratamiento y la oposición, y puedes reclamar ante
  tu autoridad de control (en España, la **AEPD**).
- **Argentina, Chile, Perú y otros países.** Reconocemos los derechos
  equivalentes de tu legislación local; usa el mismo correo de contacto.

### ¿Por qué no hay un "delegado de protección de datos"?

Porque ninguna de las leyes que nos aplican lo exige en este caso, y no queremos
inventar un cargo que no existe:

- **RGPD (art. 37).** El delegado es obligatorio para autoridades públicas, para
  quien haga observación sistemática a gran escala, o para quien trate
  categorías especiales de datos a gran escala. billetudo no encaja en ninguno:
  no somos autoridad, no perfilamos, y los datos financieros que registras **no**
  son categoría especial del art. 9.
- **LGPD (Brasil).** El art. 41 pide un *encarregado*, pero la Resolución
  CD/ANPD n.º 2 de 2022 dispensa de designarlo a los agentes de tratamiento de
  pequeño porte, siempre que exista un canal de contacto con el titular. Ese
  canal es el correo de arriba.
- **Colombia y México.** La ley pide que exista un responsable identificable y
  un canal para atender consultas y reclamos, no un cargo formal. Ese
  responsable es la persona natural identificada en la sección 1.

En la práctica: le escribes al responsable, y el responsable te responde.

---

## 12. Datos de otras personas que tú registras

Al registrar una deuda, billetudo te deja anotar el **nombre de la
contraparte**: quién te debe o a quién le debes. También puedes escribir nombres
de terceros en las **notas** de cualquier movimiento.

Esos datos son de otras personas, aunque los escribas tú. Para nosotros son
simplemente contenido de tu cuenta: no los usamos para nada, no los cruzamos con
nada y no los mostramos a nadie más. Pero **tú eres quien decide incluirlos**, y
por eso te pedimos dos cosas:

- Registra solo lo mínimo que necesites para llevar tus cuentas.
- Si vas a anotar datos de otra persona, asegúrate de que sea razonable hacerlo
  en tu contexto.

### Un caso nuevo: el nombre que viene dentro de un aviso del banco

Con la lectura de avisos bancarios activada (sección 18.2) aparece un dato de
otra persona que **tú no escribiste**: cuando alguien te transfiere dinero,
algunos bancos ponen su nombre completo en el aviso, y ese nombre se guarda como
el comercio del movimiento y **se sincroniza con tu cuenta**.

Es la única información de terceros que entra a billetudo sin que tú la teclees.
Tres cosas al respecto:

- **La ves siempre antes de confirmar.** Una captura no es un movimiento hasta
  que tú la apruebas, y en ese momento puedes editar o borrar ese nombre.
- **No la usamos para nada más.** No la cruzamos, no la agregamos, no
  identificamos a nadie con ella.
- **Puedes borrar todas las capturas de una vez** desde la app (sección 18.4).

### Tres casos en los que esos datos sí salen del teléfono

Preferimos que lo sepas antes y no después:

- **Si iniciaste sesión**, el nombre de la contraparte de una transferencia que
  la app extrajo de un aviso bancario sube a tu cuenta, como cualquier otro
  campo de un movimiento.
- **Si usas el asistente**, el nombre que le pusiste a una deuda viaja a Google
  como parte del resumen. Si ese nombre es el de una persona ("Préstamo a
  Camila"), ese nombre viaja. Pasa desde la primera versión del asistente y no
  depende de ningún interruptor (sección 17.2).
- **Si además enciendes el interruptor de notas** (sección 17.7), el texto de
  tus notas también viaja, y ahí es donde suelen estar los nombres, teléfonos o
  detalles de otras personas. Es tu decisión y por eso el interruptor viene
  apagado.

Si esos datos son de un tercero, quien decide compartirlos eres tú. Vale la
pena tenerlo presente al escribir una nota, sobre todo si el interruptor está
encendido.

Si una tercera persona quiere saber si aparece en los datos de alguien, no
podemos responder: no tenemos forma de buscar dentro de la información de
nuestros usuarios sin vulnerar la privacidad de estos.

---

## 13. Exportar e importar archivos

billetudo puede exportar tus datos y leer archivos que tú le des. Cómo funciona
exactamente:

- **Al exportar**, la app crea el archivo (CSV, ZIP o una copia completa en
  formato JSON) en su propia carpeta temporal y te lo entrega mediante el
  **menú de compartir del sistema**. Tú eliges qué hacer con él: guardarlo,
  enviarlo o descartarlo. La app **no escribe en tu galería ni en tu carpeta de
  Descargas**, y por eso **no necesita permiso de almacenamiento**.
- **Al importar**, se abre el **selector de archivos del sistema** y la app solo
  recibe el archivo que tú señalas. No puede explorar tu dispositivo.
- **Qué contiene un archivo exportado:** tus datos financieros en claro,
  incluidas las notas de texto libre, el nombre de la entidad financiera y los
  últimos 4 dígitos. **Nunca** el número de cuenta completo.
- **Los archivos exportados no van cifrados** y quedan bajo tu control. La app te
  lo advierte en pantalla. Trátalos como tratarías un extracto bancario.
- **Nota técnica honesta:** los archivos temporales que la app genera al
  compartir se quedan por ahora en su carpeta temporal privada hasta que el
  sistema operativo los limpie. Están dentro del área privada de la app —otras
  aplicaciones no pueden leerlos— y desaparecen al desinstalarla.

---

## 14. Permisos que la app pide

Hasta la versión 1.7 de esta política, billetudo **no pedía ni un solo permiso**.
Eso cambia con las funciones de la sección 18, y cambia también la ficha de
permisos que ves en la tienda antes de instalar. Esta es la lista completa.

Tres reglas valen para todos:

- **Se piden en el momento de usar la función**, nunca al abrir la app ni en el
  onboarding, y siempre con una explicación previa de para qué sirven.
- **Negarlos no te deja sin app.** Registrar movimientos a mano, presupuestos,
  metas, deudas, gráficas e importar/exportar funcionan igual sin conceder
  ninguno.
- **Los puedes revocar cuando quieras** desde Ajustes del sistema, sin avisarnos.

### 14.1 Android

| Permiso | Para qué | Cuándo se pide | Si lo niegas o lo quitas |
|---|---|---|---|
| **Micrófono** (`RECORD_AUDIO`) | Dictar un gasto en vez de teclearlo | La primera vez que tocas el botón de dictar | Se abre el formulario para escribir, con un aviso breve. Nada más cambia |
| **Acceso a las notificaciones** (`BIND_NOTIFICATION_LISTENER_SERVICE`) | Leer los avisos de compra de las apps de banco que **tú** elijas (sección 18.2) | **Nunca automáticamente.** Se concede en Ajustes del sistema, en una pantalla que la app solo puede abrir, y Android te advierte ahí que la app podría ver todas tus notificaciones | La app deja de capturar. Las capturas que ya tenías siguen ahí para que las revises |
| **Mostrar notificaciones** (`POST_NOTIFICATIONS`) | Recordarte un pago programado | Cuando activas un recordatorio | No recibes recordatorios. Los pagos programados siguen funcionando igual |
| **Volver a arrancar tras reiniciar** (`RECEIVE_BOOT_COMPLETED`) | Reprogramar tus recordatorios después de que apagues y prendas el teléfono | No se pide: Android lo concede al instalar | — |

### 14.2 iOS

| Clave del sistema | Para qué |
|---|---|
| **Micrófono** (`NSMicrophoneUsageDescription`) | Grabar lo que dictas, mientras dictas |
| **Reconocimiento de voz** (`NSSpeechRecognitionUsageDescription`) | Convertir ese audio en texto. iOS te muestra su propio aviso, que dice que los datos de voz pueden enviarse a Apple. No es un texto nuestro y no podemos cambiarlo — ver la [sección 18.1](#181-dictar-un-gasto) |
| **Notificaciones** | Recordatorios de pagos programados |

**La lectura de avisos bancarios no existe en iPhone y no va a existir.** iOS no
permite que una app lea las notificaciones de otra, y no hay forma de sortearlo.
Si usas billetudo en iPhone, la sección 18.2 no te aplica.

### 14.3 Lo que seguimos sin pedir

Cámara, fotos y galería, ubicación, contactos, calendario, SMS, registro de
llamadas, sensores corporales, almacenamiento compartido y servicios de
accesibilidad. **Ninguno de esos.**

Tampoco mostramos el aviso de seguimiento de iOS, porque **no hacemos
seguimiento entre aplicaciones**.

---

## 15. Seguridad

Lo que hacemos:

- Todo el tráfico entre la app y nuestros servidores viaja **cifrado con HTTPS**.
- Los datos en la nube están protegidos por **seguridad a nivel de fila**: cada
  consulta está restringida al usuario dueño de los datos. Un usuario no puede
  leer los de otro, ni siquiera por error.
- El **número completo de cuenta** se guarda en el almacén seguro del sistema
  operativo, cifrado por hardware cuando el dispositivo lo soporta.
- **No manejamos contraseñas**: la autenticación la hacen Google y Apple, así que
  no hay ninguna credencial tuya que podamos perder.
- El borrado de cuenta valida tu sesión en el servidor: nadie puede pedir el
  borrado de la cuenta de otra persona.

Lo que debes saber:

- Los datos guardados en tu dispositivo están protegidos por el **aislamiento de
  aplicaciones** del sistema operativo y por el bloqueo de pantalla que tú
  configures. Si otra persona desbloquea tu teléfono, verá tus finanzas.
- Ningún sistema es infalible. Si ocurre un incidente de seguridad que afecte
  tus datos, te lo notificaremos y avisaremos a la autoridad correspondiente en
  los plazos que exija la ley.

---

## 16. Menores de edad

billetudo no está dirigida a menores de **16 años**, y no recopilamos
conscientemente sus datos.

La app **no pide tu edad** ni la verifica. Si eres madre, padre o tutor y crees
que un menor a tu cargo está usando billetudo con una cuenta, escríbenos a
camiiloagudelo92@gmail.com y eliminaremos la
cuenta y sus datos.

---

## 17. El asistente con inteligencia artificial

Esta es la única función de billetudo que envía información tuya a un modelo de
lenguaje. Le dedicamos una sección entera porque contradice el principio con el
que está construido el resto de la app, y prometimos decirlo de frente cuando
pasara.

**Si tu app no muestra el asistente, nada de esta sección está ocurriendo.**

### 17.1 Qué es y cómo se activa

Es un chat donde le preguntas por tus finanzas ("¿en qué se me fue la plata este
mes?", "¿me alcanza para esto?") y te responde usando **tus** datos.

- **Es opcional.** Si no lo abres, no pasa nada de lo que sigue.
- **Requiere iniciar sesión.** Es la única función de la app con ese requisito.
- **Te pedimos permiso antes del primer mensaje**, con una pantalla que te dice
  qué sale, a quién llega y qué no sale. Si no aceptas, no se envía nada y el
  resto de la app funciona igual.
- **Puedes retirar ese permiso** cuando quieras desde Ajustes, y borrar tu
  historial de conversación.
- **Tus notas quedan fuera por defecto.** En Ajustes hay un interruptor
  independiente para dejar que el asistente las lea. Viene **apagado** y no se
  enciende solo (sección 17.7).
- **Puedes reportar cualquier respuesta** desde la propia conversación, sin
  salir de la app. Eso sí: el mensaje que reportes se guarda en nuestro
  servidor, y es la única cosa del chat que llega ahí (sección 17.5).
- Está marcado como **Beta** dentro de la app, con un aviso permanente de que
  **no es asesoría financiera**. Un modelo de lenguaje puede equivocarse con
  total seguridad; las decisiones sobre tu dinero siguen siendo tuyas.

### 17.2 Qué sale de tu teléfono

Cada vez que envías un mensaje salen tres cosas:

1. **El texto que escribiste**, y también **los mensajes anteriores de esa misma
   conversación**. Esto es importante y preferimos decirlo con todas las letras:
   el asistente no tiene memoria en nuestro servidor, así que tu teléfono
   reenvía la conversación en curso cada vez, para que la respuesta tenga
   sentido. Tu historial **no se guarda** en ningún servidor —salvo un mensaje
   suelto, si tú decides reportarlo (sección 17.5)—, pero **sí pasa** por el
   proveedor en cada mensaje. Cuando empiezas una conversación nueva, empieza de
   cero.
2. **Un resumen de tus finanzas**, que la app arma en ese momento desde la base
   de datos de tu teléfono. Contiene:
   - tus cuentas: nombre que tú les pusiste, tipo, moneda y saldo;
   - cuánto gastaste e ingresaste este mes, por moneda;
   - tus categorías con más gasto del mes, con nombre y montos;
   - el flujo de caja de los últimos 6 meses, mes a mes;
   - tus presupuestos: nombre, periodo, límite, gastado, lo que ya tienes
     programado y días restantes;
   - tus metas: nombre, objetivo, ahorrado y fecha;
   - tus deudas: **totales** por moneda, y además **cada deuda abierta con el
     nombre que tú le pusiste**, si te deben o debes, el saldo pendiente y su
     cuota si la configuraste;
   - los pagos programados que vencen en los próximos 30 días, identificados por
     **su categoría y su cuenta** (no por su nota);
   - la lista de tus categorías, para que el asistente pueda nombrarlas.
3. Además viajan cuatro datos técnicos: el **idioma** de la app, tu **zona
   horaria** (para que entienda "este mes" o "la semana pasada"), la **versión**
   de la app y un **identificador de conversación** que se genera en tu
   teléfono.

**Los nombres que tú escribes sí viajan, y conviene saberlo.** El nombre de una
cuenta, una categoría, un presupuesto, una meta o una deuda es texto que tú
escribiste, y va en el resumen. Es lo que permite que el asistente responda
"vas bien en Mercado" en vez de "vas bien en el presupuesto 3". Si prefieres que
algo no viaje, la forma directa de conseguirlo es no ponerlo en el nombre.

**Detalle bajo demanda.** Si para responderte hace falta mirar movimientos
concretos, el asistente los pide y **tu propio teléfono** resuelve la búsqueda en
su base local: nuestro servidor nunca consulta tus datos. Se envían **como
máximo 50 movimientos**, y de cada uno solo: su identificador interno, fecha,
monto, moneda, tipo, nombre de la categoría y nombre de la cuenta. El asistente
puede pedir ese detalle **hasta tres veces** por cada mensaje tuyo; pasado ese
tope responde con lo que tiene.

**Buscar dentro de tus notas sin enviarlas.** Cuando le preguntas por algo que
solo está escrito en una nota ("el abono de la moto", "el pago del gimnasio"),
pasa esto:

1. El asistente manda **las palabras que tú ya escribiste** en tu mensaje. Ese
   texto ya había salido del teléfono al enviar la pregunta, así que no se envía
   nada nuevo.
2. **Tu teléfono** compara esas palabras con tus notas locales.
3. De vuelta solo salen **datos estructurados**: identificador, monto, moneda,
   fecha, frecuencia, categoría y cuenta. **El texto de la nota no se devuelve**,
   ni entero ni en fragmentos.

La nota se usa como llave de búsqueda dentro de tu teléfono y se descarta ahí
mismo. Este camino funciona igual con el interruptor de la sección 17.7 apagado.

### 17.3 Qué no sale, y qué sí sale aunque no lo esperes

Empecemos por lo que **nunca** sale, en ninguna circunstancia y con cualquier
configuración. No es una intención, es cómo está construido el resumen:

- **El nombre de tu banco** y los **últimos 4 dígitos** de tu tarjeta.
- **El número completo de tus cuentas**, que además nunca sale del teléfono para
  nada (sección 4.2).
- **Tu nombre y tu correo.** Google no recibe quién eres desde acá.
- **Archivos, fotos, audio y contactos**, y el **texto de las notificaciones de
  tu banco**. Del audio y del texto de un aviso no hay nada que enviar, porque no
  se guardan en ninguna parte (sección 18). Los movimientos que salieron de una
  captura llegan al asistente igual que cualquier otro: como monto, fecha,
  categoría y cuenta.

Y ahora lo que **sí sale** y quizá no dabas por hecho, porque prometer de menos
también sería mentirte:

- **Los nombres que tú escribes**: los de tus cuentas, categorías, presupuestos,
  metas y deudas. Van en el resumen de cada mensaje.
- **El nombre que le pusiste a una deuda**, que a veces es el de una persona.
  Sale con el resto del bloque de deudas.
- **Tus notas**, pero **solo si enciendes el interruptor** de la sección 17.7.
  Mientras esté apagado —y viene apagado— el texto de tus notas de movimientos,
  aportes a metas, deudas y pagos programados no sale del teléfono.

> La versión 1.5 de esta política decía que del bloque de deudas "solo salen
> totales" y que ninguna palabra tuya viajaba. No era exacto y lo corregimos
> aquí. Nos parece mejor decirlo que dejarlo pasar.

### 17.4 A quién llega y dónde se procesa

Tu mensaje viaja primero a un servicio nuestro en **Supabase**, que solo hace de
intermediario: comprueba que tengas sesión y cupo, reenvía la consulta y te
devuelve la respuesta. **No guarda nada** de lo que pasa por ahí. Reportar un
mensaje es otro camino distinto, y ahí sí se guarda: lo explicamos en 17.5.

De ahí llega a **Google**, a su API de Gemini (modelo `gemini-2.5-flash`), que
es quien genera la respuesta.

- Usamos el **servicio de pago** de esa API. Bajo esos términos, **Google no usa
  tu contenido para entrenar ni mejorar sus modelos**. Sí registra las
  solicitudes por un tiempo limitado para detectar abusos y por obligaciones
  legales.
- Google aplica sus propios **filtros de seguridad** sobre lo que se envía y lo
  que responde. Si un filtro se activa, el asistente te dirá que no puede
  responder eso.
- **El procesamiento ocurre fuera de tu país**, en la infraestructura de Google
  (ver sección 8). Como con Supabase y Sentry, es una transferencia
  internacional y te la decimos de frente.
- La app **nunca** habla directamente con Google ni lleva claves de acceso
  dentro: por eso existe el intermediario.

### 17.5 Qué se guarda, y dónde

| Qué | Dónde queda |
|---|---|
| Tu conversación (lo que escribes y lo que responde) | **Solo en tu teléfono**, en una tabla que no se sincroniza. Ni siquiera con sesión iniciada. *Guardada* solo ahí; *enviada* a Google en cada turno, como explica 17.2 |
| Un mensaje del asistente que **tú** reportes | **En nuestro servidor**, junto con el motivo, tu comentario, la fecha, la versión de la app y el identificador de esa conversación. Es la única excepción a la fila de arriba, y la explicamos entera debajo de la tabla |
| El resumen de tus finanzas que se envió | **En ningún lado.** Se arma para ese mensaje y se descarta |
| Si tienes el asistente habilitado | En nuestro servidor, como un permiso de acceso |
| Un registro técnico por mensaje | En nuestro servidor: fecha, proveedor, modelo, si salió bien o mal (y el código de error si falló), tamaño de la consulta, tiempo de respuesta, versión de la app, cuántas propuestas se generaron y el identificador de la conversación |
| Si el asistente está abierto a todo el mundo o solo a la beta | En nuestro servidor, como un interruptor general. No lleva datos de nadie |

Ese registro técnico **no incluye tu mensaje, ni el resumen, ni la respuesta**.
Es deliberadamente insuficiente para reconstruir una conversación: sirve para
saber cuánto cuesta la función y si está fallando, y nada más.

#### La excepción: el mensaje que reportas

Google Play exige que las apps que generan contenido con IA permitan reportar
una respuesta **sin salir de la app**. Eso descarta abrir tu correo con el texto
pegado, y obliga a que el reporte llegue a un servidor nuestro. Preferimos
decirte cómo quedó resuelto en vez de dejarlo entre líneas:

- **Nada se envía solo.** El reporte se escribe únicamente cuando tocas
  "reportar" sobre un mensaje concreto y confirmas. No hay envío automático, ni
  en segundo plano, ni por muestreo.
- **Se guarda solo el mensaje que reportaste.** No la conversación, no los
  mensajes anteriores, no lo que tú escribiste y no el resumen de tus finanzas.
- **Qué lo acompaña:** el motivo que elijas, el comentario que quieras escribir
  (opcional), la fecha, la versión de la app, el identificador de esa
  conversación y tu identificador de usuario.
- **El motivo sale de una lista cerrada:** ofensivo, equivocado, peligroso,
  problema de privacidad, u otro. No es un campo libre a propósito, para que la
  pregunta no te invite a escribir ahí datos personales.
- **Te lo advertimos antes de enviar**, en la misma pantalla: el mensaje
  reportado se guarda en nuestros servidores para poder revisarlo.
- **Quién lo lee:** la persona responsable de la sección 1, para ajustar el
  asistente y sus filtros. No se usa para nada más, no se cruza con tus finanzas
  y no se comparte con nadie.
- **Un reporte enviado no se puede editar ni borrar** desde la app. La app
  puede mostrarte que ya reportaste ese mensaje, y nada más: un reporte que se
  cambia después de enviado no sirve para revisar nada. Si necesitas corregir o
  retirar uno, escríbenos (sección 11).
- **Se borra con tu cuenta**, igual que todo lo demás.

La diferencia que sostiene esta excepción es simple: es **retención que tú
pides**, no retención silenciosa. Si nunca reportas un mensaje, no hay ni una
línea de tu conversación en nuestro servidor.

Todo lo que está en nuestro servidor **se elimina al borrar tu cuenta**
(sección 10), incluidos los reportes que hayas enviado. El resto de la
conversación se va con los datos de tu teléfono.

### 17.6 El asistente no toca tus datos por su cuenta

Puede **proponerte** acciones: crear un presupuesto, una meta, una categoría o
registrar un movimiento. Cuando lo hace, la app te muestra una tarjeta con los
valores exactos y **no se escribe nada hasta que tú lo confirmes con un toque**.
Si ignoras la propuesta, no queda rastro en tus datos.

### 17.7 El interruptor de notas: apagado hasta que tú decidas

En Ajustes hay un interruptor llamado **"Dejar que el asistente lea mis notas"**.
Viene **apagado**.

**Con el interruptor apagado (así viene):** el texto de tus notas —las de
movimientos, aportes a metas, movimientos de deuda y pagos programados— **no
sale de tu teléfono** hacia el asistente. Eso incluye el detalle bajo demanda:
los movimientos que el asistente pide llegan sin nota.

**Con el interruptor encendido:** el texto de esas notas **empieza a viajar a
Google**, junto con el resto del resumen y de los resultados de búsqueda, cuando
sea relevante para responderte.

**Por qué existe.** Buscar palabra por palabra funciona solo si escribes la misma
palabra. Si tu nota dice "Crédito KTM 1390" y preguntas por "mi crédito
vehicular", la búsqueda del punto anterior no encuentra nada, porque no sabe que
una KTM es una moto. Con las notas a la vista, el asistente sí puede conectarlo.
Es una función de precisión, y por eso la decides tú.

**Antes de encenderlo, dos cosas que vale la pena pensar:**

- Una nota es **texto completamente libre**. Ahí caben nombres de personas,
  motivos de un gasto, detalles de salud, direcciones o cualquier cosa que hayas
  escrito sin pensar que algún día saldría del teléfono.
- Parte de eso puede ser **información de otras personas** (sección 12). Al
  encender el interruptor, esa información también empieza a viajar, y la
  decisión es tuya.

Nada de esto es motivo de alarma: es exactamente la información que ya usas todos
los días, y lo único que cambia es quién más puede leerla para ayudarte. Solo
queremos que lo sepas antes y no después.

**Cómo funciona en la práctica:**

- **Se apaga igual de fácil.** Vuelves a Ajustes y lo apagas. Desde el siguiente
  mensaje, tus notas dejan de salir.
- **No es retroactivo hacia atrás ni hacia adelante.** Apagarlo no borra lo que
  ya se envió en conversaciones anteriores; encenderlo no reenvía nada de lo que
  ya pasó.
- **Sigue sin guardarse en ningún servidor.** Tus notas viajan para producir la
  respuesta de ese mensaje y se descartan, igual que el resto del resumen
  (sección 17.5). La única cosa del chat que se guarda en nuestro servidor sigue
  siendo el mensaje que tú decidas reportar.
- **Es independiente del permiso general del asistente.** Puedes usar el
  asistente con el interruptor apagado toda la vida.
- **El estado del interruptor se guarda con tus ajustes**, en tu teléfono, y se
  sincroniza con tu cuenta como cualquier otra preferencia.
- **Si en el futuro ampliamos lo que el asistente puede leer, te lo volvemos a
  preguntar.** La app recuerda qué versión del aviso aceptaste, así que un
  permiso que diste para una cosa no se convierte solo en permiso para otra.

---

## 18. Cómo billetudo captura tus gastos

Registrar un gasto a mano toma entre quince y treinta segundos, y esa fricción
es la razón número uno por la que la gente abandona una app de finanzas. Estas
funciones existen para bajarla.

Tres cosas valen para todas y no tienen excepción:

1. **Son opcionales y las activas tú.** Sin activarlas, la app se comporta
   exactamente como antes.
2. **Nada se registra sin que tú lo confirmes.** No existe, y no va a existir, un
   modo "apunta solo lo que detectes". Un saldo con movimientos que tú no
   aprobaste no sirve para nada.
3. **No guardamos el material en bruto.** Ni el audio, ni la transcripción, ni el
   texto del aviso del banco. Solo los campos que la app entendió.

### 18.1 Dictar un gasto

Tocas el micrófono, dices *"gasté veinte mil en almuerzo"* y la app abre el
formulario de gasto ya lleno. Tú revisas y guardas.

**Qué pasa con tu voz, paso a paso:**

1. El micrófono se enciende mientras hablas y se apaga cuando terminas, cuando
   cancelas o cuando pasa el tope de duración. No hay ningún camino en el que
   quede abierto.
2. El audio se convierte en texto con el **reconocedor de voz de tu teléfono**
   (el mismo que usa el dictado del teclado). billetudo no tiene un motor propio
   ni manda el audio a un servidor nuestro.
3. La app lee ese texto con reglas locales para sacar el monto, la fecha, la
   categoría y la cuenta, y llena el formulario.
4. **Al cerrar el formulario, el audio y la transcripción desaparecen.** Lo único
   que queda es el movimiento que tú guardaste, igual que si lo hubieras
   tecleado. Si cancelas, no queda nada.

**La parte incómoda, que decimos de frente:** *convertir voz en texto* no siempre
ocurre dentro de tu teléfono. Cuando tu dispositivo y tu idioma lo soportan, se
hace ahí mismo y el audio no sale. **Cuando no lo soportan, el sistema operativo
envía el audio a los servidores de Apple o de Google para transcribirlo**, según
la marca de tu teléfono.

- Nosotros no elegimos eso ni recibimos ese audio: la app le pide al sistema que
  transcriba y recibe el texto de vuelta.
- Apple y Google, en ese caso, son responsables independientes de ese audio, y
  aplica **su** política de privacidad, no esta (sección 7).
- En iPhone, el propio sistema te lo advierte la primera vez con un aviso suyo:
  dice que los datos de voz de esta app se enviarán a Apple. Ese texto lo escribe
  Apple y no podemos cambiarlo.
- **No guardar no es lo mismo que no transmitir**, y nos parecía deshonesto
  escribir "todo pasa en tu teléfono" a secas. Si prefieres que tu voz no salga
  nunca, no uses el dictado: escribir a mano funciona igual de bien y es la ruta
  principal de la app.

**Lo que no hacemos con tu voz:** no la usamos para identificarte. No guardamos
una huella de voz, no reconocemos quién habla y no hay ningún dato biométrico en
esto. El micrófono es una forma de escribir, nada más.

### 18.2 Leer los avisos de tu banco (solo Android)

Cuando tu banco te avisa *"Compra por $45.900 en EXITO CALLE 80"*, la app puede
tomar ese dato y dejarte el movimiento listo para confirmar. Es la función más
sensible de billetudo y por eso está explicada con este detalle.

**Solo en Android.** iPhone no permite que una app lea las notificaciones de
otra.

#### Cómo se activa

Android **no** deja que una app lea notificaciones con un permiso normal: tienes
que ir a **Ajustes del sistema → Acceso a notificaciones** y activarlo ahí. La
app solo puede abrirte esa pantalla.

- Antes de mandarte allá, billetudo te explica en su propia pantalla qué va a
  leer, qué va a guardar y qué va a sincronizar.
- También te anticipa que **Android te va a advertir que la app podría ver todas
  tus notificaciones**. Esa advertencia es real y es la única forma en que el
  sistema concede este permiso: no hay una versión "solo mi banco".
- Puedes decir que no y seguir usando la app completa.

#### Qué lee de verdad

El sistema le entrega a la app todas las notificaciones. **billetudo descarta las
que no vienen de un banco que tú encendiste, antes de mirar su título, su texto o
su contenido.** El filtro es por la app que la envió, no por lo que dice.

- Hay un **catálogo cerrado** de apps de banco y billeteras. No puedes añadir
  cualquier app: si no está en la lista, no se lee.
- **Todos los interruptores vienen apagados.** Activar el permiso sin encender
  ningún banco no captura absolutamente nada.
- Los mensajes de WhatsApp, los correos, los códigos de un solo uso y las
  notificaciones de cualquier otra app **no se leen, no se guardan, no se cuentan
  y no se envían a ningún lado**.

#### Qué se guarda y qué no

Se guarda lo que está en la [sección 4.6](#46-lo-que-la-app-extrae-de-los-avisos-de-tu-banco-solo-android):
monto, moneda, si es gasto o ingreso, fecha, comercio o contraparte, los últimos
4 dígitos, qué app lo envió y qué regla lo interpretó.

**No se guarda el texto del aviso.** No hay dónde: la base de datos de la app no
tiene una casilla para eso, ni completa ni recortada. Si un aviso no es un
movimiento de dinero —una promoción, un código de seguridad, "tu extracto está
listo"— **no se crea nada y no queda rastro**.

#### Qué sale de tu teléfono

Aquí conviene una precisión, porque es fácil prometer de más:

> **El contenido de los avisos de tu banco no se envía a ningún servidor, porque
> no se guarda en ninguna parte.** Lo que sí sincroniza a tu cuenta, si iniciaste
> sesión, son los **datos financieros ya estructurados** —monto, comercio, fecha,
> app emisora y cuenta sugerida—, exactamente el mismo tipo de dato que un
> movimiento que escribes a mano.

Las dos mitades de esa frase van juntas: la primera solo se sostiene porque el
texto no se guarda. Si algún día se guardara, sincronizarlo sería subir a un
servidor el contenido literal de las notificaciones de tu teléfono, y ninguna
redacción haría eso aceptable.

Si nunca inicias sesión, las capturas se quedan en tu teléfono, como todo lo
demás.

#### Lo que esta función no promete

- **No captura todo, y no puede.** No hay aviso para un pago en efectivo, hay
  bancos fuera del catálogo, y Android puede apagar el servicio para ahorrar
  batería. Si algo no apareció, lo registras a mano.
- **Ninguna cifra de la app depende de esto.** Tus saldos, presupuestos y
  gráficas cuentan solo los movimientos que tú confirmaste. Una captura pendiente
  no suma a nada.

### 18.3 Recordatorios de pagos

Puedes pedirle a la app que te avise unos días antes de un pago programado.

- **Los programa tu propio teléfono.** No hay un servidor mandándote mensajes.
- **No hay notificaciones push.** No usamos Firebase ni ningún servicio de
  mensajería, no existe un token de notificación tuyo y **no tenemos forma de
  enviarte un mensaje remoto** aunque quisiéramos.
- El contenido del recordatorio se arma en el teléfono con tus propios datos y no
  sale de ahí.
- Los apagas desde Ajustes de la app o revocando el permiso de notificaciones del
  sistema.

### 18.4 Cómo apagar todo esto y borrar lo capturado

- **Apagar el dictado:** quita el permiso de micrófono en Ajustes del sistema. El
  botón sigue ahí y te abre el formulario para escribir.
- **Apagar la lectura de avisos:** desde la propia app, con un interruptor, o
  desde Ajustes del sistema de Android. Cualquiera de los dos la detiene de
  inmediato. También puedes apagar un banco concreto y dejar los demás.
- **Ver qué está pasando:** dentro de Ajustes hay una pantalla que te muestra qué
  apps se están escuchando, cuántas capturas se han creado y qué campos se
  guardan y cuáles no.
- **Borrar lo capturado:** hay una acción que borra **todas** las capturas
  pendientes y todo lo que la app aprendió, y deja la función como recién
  instalada. **No toca los movimientos que ya confirmaste**: esos ya son tuyos y
  se borran como cualquier otro movimiento.
- **Borrar tu cuenta** (sección 10) se lleva las capturas y el aprendizaje del
  servidor, junto con todo lo demás.

---

## 19. Lo que billetudo hoy no hace

Esta sección existe para que no tengas que deducirlo. Todo lo de abajo es
verificable en la versión publicada de la app:

- **No hay publicidad.** Ningún SDK publicitario está incluido en la aplicación.
  No recopilamos identificadores de publicidad y no construimos perfiles.
- **No hay analítica de comportamiento.** No usamos Google Analytics, Firebase,
  Amplitude, Mixpanel ni equivalentes. No sabemos qué pantallas visitas ni
  cuánto tiempo pasas en cada una.
- **No hay compras dentro de la app** ni suscripciones.
- **No hay notificaciones push.** Los recordatorios que ves los programa tu
  propio teléfono (sección 18.3). No hay Firebase, no hay tokens de notificación
  y no existe forma de que te enviemos un mensaje remoto.
- **La inteligencia artificial se limita al asistente** de la sección 17: es
  opcional, requiere sesión y requiere tu permiso. Fuera de él, ningún dato tuyo
  se envía a un modelo de lenguaje. No categorizamos tus gastos con IA, no
  analizamos tus finanzas en segundo plano y no generamos informes automáticos.
- **No leemos recibos con la cámara.** No hay reconocimiento de texto en
  imágenes, y la app **no pide permiso de cámara ni de galería**.
- **No identificamos a nadie por su voz.** El micrófono es una forma de escribir
  (sección 18.1); no guardamos huellas de voz ni hacemos reconocimiento del
  hablante, así que no hay ningún dato biométrico en la app.
- **No leemos las notificaciones de tus otras apps.** Solo las de las apps de
  banco que tú enciendes de una lista cerrada, y solo en Android (sección 18.2).
- **No hay un widget** de pantalla de inicio.
- **No vendemos ni cedemos datos personales a terceros.**

### Sobre el futuro

Seguimos diseñando funciones para que registrar un gasto cueste segundos:
**fotografiar el recibo** para que la app lea el monto y un **widget** de acceso
rápido. Más adelante, gráficas avanzadas y una versión de pago que podría
apoyarse en anuncios **con recompensa y de participación voluntaria** o en una
suscripción. El asistente de la sección 17, hoy en beta y gratuito, será parte
de esa versión de pago.

**Nada de eso está activo hoy** — la lista de arriba, la de lo que billetudo no
hace, sigue siendo cierta mientras leas esta versión de la política. Cuando alguna de esas funciones
llegue, pasarán tres cosas, en este orden:

1. **Actualizamos esta política antes**, con su número de versión y su fecha,
   explicando qué se procesa, dónde y por cuánto tiempo.
2. **Te lo decimos dentro de la app** y, donde la ley lo exija, te pedimos una
   nueva autorización.
3. **Te pedimos el permiso del sistema en el momento de usar la función**, no
   antes. Puedes negarlo y seguir usando billetudo igual.

Y hay dos compromisos que ya podemos adelantar sobre esas funciones, porque son
la razón de diseñarlas así:

- **Serán opcionales.** Lo que hoy es gratis sigue gratis, sin anuncios y sin
  condiciones nuevas.
- **La idea es procesar en tu teléfono**, no en un servidor. La sección 17 es la
  primera excepción a eso, y por eso está escrita entera y sin adornos en vez de
  esconderse bajo un "podríamos compartir datos con proveedores". Cuando vuelva a
  pasar en otra función, lo diremos igual de explícito y antes de activarla.

---

## 20. Cambios a esta política

Si cambia lo que hacemos con tus datos, cambiamos esta política. Publicaremos la
versión nueva en esta misma dirección, con su número de versión y su fecha.

Cuando el cambio sea **relevante** —un tratamiento nuevo, un proveedor nuevo, una
finalidad nueva— te avisaremos dentro de la app con antelación razonable y,
donde la ley lo exija, te pediremos una nueva autorización. Los cambios menores
(redacción, correcciones) entran en vigor al publicarse.

El historial de versiones se conserva para que puedas comparar.

---

## 21. Contacto

Para cualquier asunto relacionado con tus datos personales, incluido el
ejercicio de tus derechos:

- **Correo:** camiiloagudelo92@gmail.com
- **Responsable:** Juan Camilo Agudelo Franco, persona natural

No publicamos una dirección física porque el responsable es una persona natural
y no tiene domicilio comercial. El correo es el canal de contacto y lo
atendemos.

Escribe en español o en inglés, indicando qué quieres y desde qué correo usas la
app. Si en 30 días no tuviste respuesta, insiste: algo falló.

---

*billetudo — Política de privacidad, versión 1.8, 9 de septiembre de 2026.*

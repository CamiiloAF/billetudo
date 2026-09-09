# Textos de consentimiento y transparencia — Fase 2 (captura)

**Versión 1.0** · **9 de septiembre de 2026** · **Estado: borrador listo para pasar a `.arb`**

> **Estos textos NO se han metido en `lib/core/l10n/arb/`.** Se dejan aquí a
> propósito para que la rama que implemente cada feature los copie y evite un
> conflicto entre ramas. Quien los copie: revisar contra el diseño de la pantalla
> en `billetudo.pen` antes de pegarlos — el largo de una línea puede no caber.
>
> **Documento interno.** No se publica en el sitio legal (`web/build_site.py`
> solo convierte `politica-de-privacidad.md`, `terminos-de-uso.md` y
> `como-borrar-tu-cuenta.md`).

## Para qué existe este documento

Google Play exige, para datos personales y sensibles que el usuario no esperaría
que se recojan, una **divulgación destacada dentro de la app** (*prominent
disclosure*) que cumpla cuatro cosas a la vez
([User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311)):

1. Aparece **dentro de la app**, no solo en la ficha ni en la política.
2. Se ve **en el uso normal**, sin tener que entrar a un menú a buscarla.
3. Describe **qué dato se accede** y **cómo se usa o se comparte**.
4. Va **antes** de pedir el permiso, y el usuario tiene que hacer algo
   afirmativo (tocar un botón). Salirse de la pantalla no es consentir.

Apple, por su parte, rechaza los `*UsageDescription` genéricos: tienen que decir
el uso real y concreto.

Todo lo de abajo está escrito para cumplir eso **y** el tono de marca: claro,
directo, español neutro de LatAm, sin jerga y sin alarmismo.

### Regla de redacción que atraviesa todo

**Está prohibido escribir "todo pasa en tu teléfono" a secas** para la voz. Es
falso cuando el reconocimiento cae al servicio en la nube del sistema operativo.
La frase correcta separa las dos cosas: *no se guarda* (siempre cierto) y *puede
salir para transcribirse* (cierto en algunos teléfonos). Ver
`declaraciones-tiendas.md` §7.5.

También está prohibido prometer cobertura total de la captura por notificación
(*"tus gastos se registran solos"*). La app no captura efectivo, no cubre todos
los bancos y el sistema puede matar el servicio.

---

## 1. Captura por voz

### 1.1 Explicación previa al permiso de micrófono

Se muestra la **primera vez** que el usuario toca el botón de dictar, antes del
diálogo del sistema.

**Título**

> Dicta tu gasto

**Cuerpo**

> Di algo como *"gasté veinte mil en almuerzo"* y te lleno el formulario. Tú
> revisas y guardas: nunca registro nada solo.
>
> **El audio no se guarda.** Se usa para entender lo que dijiste y se descarta al
> cerrar el formulario.

**Aviso secundario (obligatorio, no se puede omitir)**

> Para convertir tu voz en texto uso el reconocedor de tu teléfono. Si tu
> teléfono no puede hacerlo por su cuenta, ese audio lo transcribe {Apple/Google}
> en sus servidores. No pasa por billetudo en ningún caso.

**Botones**

> `Permitir micrófono` · `Ahora no`

**Nota para quien implemente:** `{Apple/Google}` se resuelve por plataforma. Si
se decide mostrar este aviso solo cuando el reconocimiento cae a la nube (opción
C de `17-captura-voz.md` HU-06), el texto es el mismo pero en presente: *"En este
teléfono el reconocimiento lo hace {Apple/Google}"*.

### 1.2 Micrófono denegado

**Texto**

> Sin micrófono no puedo escuchar, pero puedes escribirlo igual de rápido.

**Acción secundaria**

> `Abrir ajustes`

**Prohibido:** insistir en cada intento, poner el botón en gris, o culpar al
usuario.

### 1.3 Estados de la escucha (accesibilidad)

Anunciados por lector de pantalla, no solo animados:

| Estado | Texto |
|---|---|
| Escuchando | Escuchando |
| Procesando | Un momento |
| Listo | Listo |
| Cancelado | Cancelado |
| Sin resultado | No alcancé a oír nada. Prueba otra vez o escríbelo |

**Prohibido:** "No te entendí", "Habla más claro", "Intenta hablando despacio".

### 1.4 `Info.plist` (iOS)

Van localizados en `InfoPlist.strings` (es + en).

| Clave | es | en |
|---|---|---|
| `NSMicrophoneUsageDescription` | Para que puedas dictar un gasto en vez de escribirlo. El audio no se guarda. | So you can dictate an expense instead of typing it. The audio is not stored. |
| `NSSpeechRecognitionUsageDescription` | Para convertir en texto lo que dictas y llenar el formulario del gasto. Si tu iPhone no puede hacerlo por su cuenta, iOS envía ese audio a Apple para transcribirlo. | To turn what you dictate into text and fill in the expense form. If your iPhone cannot do it on its own, iOS sends that audio to Apple for transcription. |

---

## 2. Lectura de avisos bancarios (solo Android)

### 2.1 La pantalla explicadora — la divulgación destacada

Es **la** pantalla que Play evalúa. Se muestra **antes** de abrir Ajustes del
sistema, nunca después.

**Título**

> Leer los avisos de tu banco

**Entradilla**

> Cuando tu banco te avise de una compra, te la dejo lista para confirmar.

**Bloque "Qué leo"**

> Solo los avisos de las apps de banco que **tú** enciendas en una lista. De
> WhatsApp, tus correos, tus códigos de seguridad y cualquier otra app **no leo
> nada**: los descarto antes de mirar qué dicen.

**Bloque "Qué guardo"**

> Solo lo que entendí: el monto, el comercio, la fecha y los últimos 4 dígitos.
> **El texto del aviso no lo guardo en ninguna parte** — ni completo, ni
> recortado, ni un momento.

**Bloque "Qué sube a tu cuenta"**

> Si iniciaste sesión, esos datos suben a tu cuenta como cualquier otro
> movimiento tuyo. El texto del aviso no sube, porque no existe en ningún lado.

**Bloque "Qué no hago"**

> Nunca registro un movimiento solo. Todo lo que detecte queda esperando a que tú
> lo confirmes, y hasta entonces no afecta ningún saldo.

**Anticipo de la advertencia del sistema (obligatorio)**

> Android te va a advertir que billetudo podría ver **todas** tus notificaciones.
> Es cierto que el sistema no ofrece otra forma de dar este permiso — no existe
> una versión "solo mi banco". Por eso el filtro lo pongo yo, y solo miro las
> apps que enciendas.

**Botones**

> `Ir a ajustes de Android` · `Ahora no`

**Pie**

> Lo puedes apagar cuando quieras. [Cómo trato tus datos](enlace a la política)

**Reglas de implementación**

- El botón secundario **siempre existe**. Nunca un flujo de una sola salida.
- Al volver de Ajustes se **re-verifica el estado real** del permiso; no se
  asume concedido por haber ido.
- Si sigue sin concederse: estado "desactivado", sin regaño y sin insistir.

### 2.2 Ofrecimiento contextual (después del primer gasto a mano)

**Título**

> ¿Te ahorro este paso la próxima vez?

**Cuerpo**

> Cuando tu banco te avise de una compra, te la dejo lista para confirmar. Tú
> decides si la registras.

**Botones**

> `Ver cómo funciona` · `No, gracias`

**Prohibido:** *"¿Quieres que tus gastos se registren solos?"* y cualquier
variante que prometa cobertura total.

### 2.3 Elegir de qué apps se escucha

**Título**

> ¿De qué apps leo los avisos?

**Cuerpo**

> Enciende solo las que uses. De las demás no leo nada.

**Estado vacío (ninguna app del catálogo instalada)**

> Todavía no reconozco ninguna app de banco en este teléfono. Cuando instales
> una de las que sé leer, aparece aquí.

**Pie de la lista**

> {n} apps encendidas · `Apagar todas`

### 2.4 Pantalla de transparencia (dentro de Ajustes)

Exigida por HU-08 y descrita en la política v1.8 §18.4. Es la pantalla que
demuestra, no que promete.

**Título**

> Qué leo de tus notificaciones

**Bloque 1 — Estado**

> Permiso de Android: {Activo / Desactivado}
> Apps que estoy escuchando: {lista, o "ninguna"}
> Capturas creadas hasta hoy: {n}

**Bloque 2 — Qué guardo**

> Monto y moneda
> Si es gasto o ingreso
> Fecha y hora
> Comercio o quién te transfirió
> Últimos 4 dígitos que mencionó el aviso
> Qué app envió el aviso

**Bloque 3 — Qué NO guardo**

> El texto del aviso. Ni completo, ni recortado, ni por un momento. No hay
> ningún lugar en billetudo donde quepa.
>
> Nada de las apps que no encendiste. Sus avisos los descarto antes de mirarlos.

**Bloque 4 — Un aviso honesto**

> Cuando alguien te transfiere, algunos bancos escriben su nombre completo en el
> aviso. Ese nombre queda guardado como el comercio del movimiento y, si
> iniciaste sesión, sube a tu cuenta. Puedes editarlo o descartar la captura
> antes de confirmarla.

**Acciones**

> `Cambiar qué apps leo`
> `Borrar todas las capturas y lo aprendido`
> `Leer la política de privacidad`

### 2.5 Borrar lo capturado — confirmación

**Título**

> ¿Borrar todo lo capturado?

**Cuerpo**

> Se van las capturas que no has confirmado y lo que aprendí sobre tus comercios.
> Queda como recién instalado.
>
> **Los movimientos que ya confirmaste no se tocan**: esos ya son tuyos.

**Botones**

> `Borrar` · `Cancelar`

### 2.6 Apagar la lectura

**Título**

> Dejar de leer los avisos

**Cuerpo**

> Dejo de capturar desde ya. Lo que tengas pendiente sigue ahí para que lo
> revises.

**Casilla**

> `Borrar también lo capturado`

### 2.7 Permiso revocado desde el sistema

> La lectura de notificaciones está desactivada.
>
> `Activar`

**Prohibido:** signos de exclamación, iconos de alerta roja, "¡Atención!" o
cualquier cosa que sugiera que el usuario hizo algo mal.

### 2.8 Estado vacío de la bandeja

| Caso | Texto |
|---|---|
| Sin nada pendiente | Todo al día |
| Permiso activo, sin apps encendidas | Todavía no estoy escuchando ninguna app. `Elegir apps` |
| Permiso desactivado | La lectura de avisos está desactivada. `Activar` |

**Prohibido:** "No has registrado nada", "Llevas 12 gastos sin revisar" y
cualquier conteo presentado como reproche.

### 2.9 Lo que la app no promete (texto de ayuda)

Va en la pantalla de ayuda o al final del explicador, no escondido:

> No capturo todo, y no puedo: no hay aviso cuando pagas en efectivo, hay bancos
> que todavía no sé leer, y Android a veces apaga el servicio para ahorrar
> batería. Si algo no apareció, lo registras a mano en segundos.
>
> Tus saldos y presupuestos nunca dependen de esto: solo cuentan los movimientos
> que confirmaste.

---

## 3. Recordatorios de pagos (notificaciones locales)

### 3.1 Antes de pedir `POST_NOTIFICATIONS` / autorización de iOS

**Título**

> ¿Te aviso antes de que se venza?

**Cuerpo**

> Te mando un recordatorio unos días antes de cada pago programado. El aviso lo
> prepara **tu propio teléfono**: no hay ningún servidor mandándote mensajes.

**Botones**

> `Activar recordatorios` · `Ahora no`

### 3.2 Permiso denegado

> Sin permiso de notificaciones no puedo avisarte, pero tus pagos programados
> siguen funcionando igual dentro de la app.

---

## 4. Cambios que hay que hacer en textos que YA existen

Estos no son textos nuevos: son afirmaciones vigentes en la app que **dejan de
ser ciertas** con este envío. Quien implemente tiene que buscarlas.

| Dónde | Qué dice hoy | Qué hay que hacer |
|---|---|---|
| `AiConsentPage` (`l10n.aiConsentBody`) | *"sin notas ni datos de identificación bancaria"* | Verificar que sigue siendo exacto ahora que existen capturas. Los movimientos que vienen de una captura llegan al asistente como cualquier otro movimiento, así que **no** cambia el alcance — pero conviene releerlo. `[VERIFICAR]` |
| Cualquier texto de ayuda / onboarding que diga que la app no pide permisos | — | Buscar y corregir antes de enviar |
| Ficha de tienda (`docs/marketing/store-listing/`) | — | Tiene que **describir** la lectura de avisos bancarios: un permiso sensible cuya finalidad no aparece en la ficha es causa típica de rechazo (`declaraciones-tiendas.md` §7.2). Y **no** puede construir la propuesta de valor sobre "tus gastos se registran solos" |

---

## 5. Límite

Este documento **no es asesoría jurídica**. Es copy verificado contra el esquema
y contra los requisitos de las tiendas; la revisión legal formal la hace una
persona abogada.

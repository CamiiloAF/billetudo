# Casos de prueba — QA build 0.0.7 (asistente de IA)

Gracias por ayudar a probar Billetudo. Esta guía te lleva por la app completa,
con más detalle en el asistente de IA porque es lo nuevo de este build —
acabamos de arreglar varios errores reales que encontramos usándolo.

**No hace falta seguir el orden exacto**, pero si algo falla, anota:
- qué estabas haciendo (los pasos, tal cual los diste),
- qué esperabas que pasara,
- qué pasó en realidad (una captura de pantalla ayuda muchísimo),
- si lo pudiste repetir o fue una sola vez.

No hay una forma de "romper mal" la app — si algo se ve raro, avísanos aunque
no estés seguro de si es un bug. Preferimos que reportes de más a que te
guardes una duda.

---

## 0. Instalación

- [ ] Instala el build desde Play Store (track interno) o TestFlight, según tu
  dispositivo.
- [ ] Ábrela por primera vez. Si tenías una versión anterior instalada, tus
  datos deben seguir ahí — nada se borra al actualizar.

## 1. Primer arranque / onboarding (solo si es instalación nueva)

- [ ] Bienvenida → crea tu primera cuenta → respalda tus datos (o sáltalo) →
  registra un movimiento inicial (o sáltalo). Cada paso debe poder omitirse
  sin trabarte.
- [ ] Si te saltaste la cuenta en su paso, el botón final debe decir algo
  distinto a "Guardar" (invita a crear la cuenta primero).

## 2. Cuentas

- [ ] Crea una cuenta de cada tipo que uses (efectivo, banco, ahorros,
  tarjeta de crédito, inversión). En tarjeta de crédito, revisa que te pida
  cupo y día de corte/pago, y que muestre "deuda actual" si aplica.
- [ ] Edita una cuenta (nombre, saldo). El saldo mostrado en Inicio debe
  reflejar el cambio de inmediato.
- [ ] Archiva una cuenta con movimientos. Debe desaparecer de los selectores
  de cuenta al registrar algo nuevo, pero sus movimientos pasados siguen
  visibles en su historial.

## 3. Movimientos

- [ ] Registra un gasto, un ingreso y una transferencia entre dos cuentas
  tuyas. Verifica que los saldos de origen y destino cambien correctamente.
- [ ] Edita un movimiento ya registrado (monto, cuenta, categoría, fecha).
- [ ] Elimina un movimiento y confirma que el saldo de su cuenta se ajusta.
- [ ] Filtra movimientos por cuenta, por categoría y por rango de fechas.
- [ ] Si tienes deudas: enlaza un movimiento existente a una deuda (como
  abono o desembolso) y confirma que el saldo de la deuda se actualiza.

## 4. Presupuestos

- [ ] Crea un presupuesto (mensual o del periodo que prefieras) para una
  categoría o cuenta.
- [ ] Registra un gasto que caiga dentro de ese presupuesto y verifica que
  el progreso avance.
- [ ] Pasa el gasto del presupuesto por encima del 100% y confirma que el
  estado visual cambia a "excedido", sin ningún mensaje que te haga sentir
  mal por el gasto — el tono de la app es de progreso, nunca de regaño.

## 5. Categorías

- [ ] Crea una categoría y una subcategoría dentro de ella.
- [ ] Usa esa categoría al registrar un movimiento.
- [ ] Intenta eliminar una categoría que ya tiene movimientos — debe avisarte
  del impacto, no borrar en silencio.

## 6. Metas

- [ ] Crea una meta de ahorro con un monto objetivo.
- [ ] Regístrale un aporte y confirma que el progreso avanza.
- [ ] Si la meta tiene montos rápidos configurados, pruébalos.

## 7. Deudas

- [ ] Crea una deuda (te deben o debes) con su cuota si aplica.
- [ ] Regístrale un abono y un desembolso (si aplica) y confirma que el saldo
  pendiente se recalcula bien.
- [ ] Si tienes **más de una deuda parecida** (mismo tipo, montos similares),
  pruébalo especialmente con el asistente de IA — ver sección 12.

## 8. Pagos programados

- [ ] Crea un pago programado recurrente (ej. arriendo mensual) y uno único a
  futuro.
- [ ] Confirma una ocurrencia cuando llegue su fecha, u omítela.
- [ ] Verifica que aparezca en el resumen de Inicio como próximo a pagar.

## 9. Reportes

- [ ] Abre las gráficas de gasto por categoría del mes actual.
- [ ] Cambia de mes y confirma que los datos cambian con él.
- [ ] Si tienes subcategorías, prueba el drill-down (entrar a ver el detalle
  de una categoría con hijos).

## 10. Importar/Exportar

- [ ] Exporta tus datos y confirma que el archivo se genera (revisa que
  contenga tus cuentas y movimientos reales).
- [ ] Si tienes un archivo de otro banco/app a mano, prueba importarlo.

## 11. Ajustes y sincronización

- [ ] Entra a Ajustes y revisa que tu sesión y modo de tema (claro/oscuro/
  sistema) funcionen.
- [ ] Si tienes cuenta con respaldo activo, revisa el estado de
  sincronización desde el ícono/avatar de Inicio — debe abrir una hoja con
  el estado real, y esa hoja debe **cerrarse sola** al tocar cualquiera de
  sus opciones (Ajustes, estado de sync, cerrar sesión). Si se queda abierta
  detrás de la pantalla a la que te llevó, repórtalo.
- [ ] Toca el botón de "Tu dinero" (arriba a la derecha en Inicio) y toca una
  cuenta — debe llevarte a sus movimientos filtrados y la hoja debe cerrarse
  igual que la anterior.
- [ ] **Nuevo — sección "Asistente de IA" en Ajustes**: revisa que existan
  los enlaces a Política de privacidad y Términos de uso, y el interruptor
  "Dejar que el asistente lea mis notas" (ver sección 12.6).

## 12. Asistente de IA — lo nuevo de este build

Entra al chat desde la tarjeta de IA en Inicio o desde el ícono en la barra
superior. La primera vez te va a pedir aceptar un consentimiento — acéptalo
para poder chatear.

### 12.1 Precisión de montos (bug arreglado)

Antes, el asistente a veces mostraba un monto **cien veces más grande** del
real (leía los centavos como si fueran pesos).

- [ ] Pregúntale "¿cuánto tengo en [nombre de una cuenta tuya]?" y compara
  la cifra que te da contra el saldo real que ves en Inicio. Deben coincidir
  exactamente, con separadores de miles correctos.
- [ ] Pregúntale por el total de un presupuesto, una meta o una deuda y
  compara igual contra la pantalla real de esa sección.
- [ ] Si en algún momento un monto se ve absurdamente grande o pequeño
  (varios órdenes de magnitud de diferencia con lo real), repórtalo con
  captura — es exactamente el bug que arreglamos y queremos confirmar que
  no reaparece en ningún caso.

### 12.2 Deudas parecidas (bug arreglado)

Si tienes **dos o más deudas del mismo tipo** (dos créditos, dos tarjetas):

- [ ] Pregúntale por "mi crédito" o "la deuda de [categoría genérica]" sin
  decir el nombre exacto. El asistente debe **preguntarte cuál** de las dos
  en vez de adivinar o mezclarlas en una sola respuesta.
- [ ] Nómbrala por su nombre exacto (como la registraste) y confirma que
  responde sobre esa y solo esa — nunca combinando datos de dos deudas
  distintas en una sola cifra.

### 12.3 El asistente reconoce sus límites (bug arreglado)

- [ ] Pídele algo que hoy no puede hacer (ej. "bórrame este movimiento" o
  "cámbiame el nombre de esta categoría"). Debe decirte con claridad que
  todavía no puede hacer eso — no debe inventarse una explicación que suene
  creíble pero sea falsa.

### 12.4 Registrar movimientos y enlazar a deudas (nuevo)

- [ ] Pídele que registre un gasto o ingreso ("anota que gasté $50.000 en
  comida hoy"). Debe proponerte una tarjeta con los datos — nunca lo
  registra solo, siempre confirmas tú con un toque.
- [ ] Si tienes una deuda, pídele "registra un abono de $X a mi deuda de
  [nombre]" — la propuesta debe mostrar a qué deuda quedará atribuido el
  movimiento.
- [ ] Pídele que enlace un movimiento **que ya registraste** a una deuda
  existente. La tarjeta debe dejar claro que no está creando un movimiento
  nuevo ni moviendo plata — solo lo está asociando a la deuda.

### 12.5 Insight de presupuesto excedido, en Inicio (bug arreglado)

Si tienes un presupuesto en riesgo de excederse (por pagos programados
pendientes de este periodo):

- [ ] En la tarjeta de IA de Inicio debería aparecer ese aviso.
- [ ] Tócalo y elige "Ahora no". Registra un movimiento nuevo cualquiera y
  vuelve a Inicio — el mismo aviso **no debe reaparecer** en lo que queda
  del mes.
- [ ] Aunque no lo descartes, no debería insistir contigo más de una vez al
  día por el mismo motivo.

### 12.6 Consentimiento de notas (nuevo)

- [ ] En Ajustes → Asistente de IA, activa "Dejar que el asistente lea mis
  notas". Debe mostrarte una hoja de confirmación que menciona a Google
  Gemini antes de activarlo de verdad.
- [ ] Con el interruptor **apagado**, pídele al asistente que encuentre algo
  por como tú lo llamas en una nota (ej. "búscame el pago de [una palabra
  que uses en tus notas]"). Debe poder encontrarlo igual, sin que tú actives
  el interruptor — busca localmente en tu dispositivo.
- [ ] Desactívalo de nuevo y confirma que no pide confirmación para apagarlo
  (solo para encenderlo).

### 12.7 El chat se abre donde debe (bug arreglado)

- [ ] Ten una conversación con varios mensajes. Sal del chat (botón atrás) y
  vuelve a entrar a la misma conversación desde el historial. Debe abrir con
  el scroll en el **último mensaje**, no arriba del todo.

### 12.8 General

- [ ] Prueba el tema oscuro en el chat (cambia el tema de la app en Ajustes)
  y confirma que se ve bien.
- [ ] Cierra la app a la mitad de una conversación y vuelve a abrirla — la
  conversación debe seguir ahí.

---

Cuando termines, cuéntanos en general cómo se sintió usar la app — lento,
confuso en algún punto, algo que no encontrabas. Eso también nos sirve,
aunque no sea técnicamente un "bug".

¡Gracias por el tiempo!

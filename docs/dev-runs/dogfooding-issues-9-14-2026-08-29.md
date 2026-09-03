# Dogfooding — issues #9 a #14 (2026-08-29)

**Estado: trabajo completo, verde, sin commitear.** El usuario pidió revisar
esto con calma antes de commitear — nada de lo de esta sesión se subió a
`main` ni se desplegó. Rama `feat/ai-assistant`.

## Verificación final

- `flutter analyze`: limpio, salvo 4 `info` preexistentes en
  `test/features/import_export/` (no relacionados con este trabajo).
- `flutter test` (suite completa): **5127 tests, 1 skipped (preexistente),
  0 fallos.**
- Pipeline de QA (`qa.yml`, tag `qa-*`) verificado funcionando de punta a
  punta contra el fix de permiso `bd263c2f` — build subido con éxito a Play
  Store (track interno) y TestFlight.

## Estado por issue

### #9 — "IA: Registro futuro" — **cerrado**
El asistente propuso una fecha en el futuro para un movimiento que la
persona ya había pagado, aparentemente tomando prestada la fecha de
vencimiento de un pago programado relacionado en vez de usar "hoy". Regla
nueva en `supabase/functions/_shared/ai/prompt.ts`: la fecha por defecto de
`propose_create_transaction` es siempre hoy salvo pedido explícito; un pago
programado y "registrar algo que ya pasó" son cosas distintas y la fecha del
primero nunca es el default del segundo.

### #10 — "IA: Scroll del chat" — **cerrado**, dos bugs distintos
1. Al reabrir una conversación con la misma cantidad de mensajes que la
   actual, el scroll no llegaba al fondo (`listenWhen` solo comparaba
   `messages.length`, no detectaba el cambio de conversación). Se agregó una
   llamada explícita a `_scrollToBottom()` en `_openHistory()`.
2. Tocar la tarjeta de IA varias veces rápido abría el chat varias veces
   (async gap sin guardia de reentrada). Guardia compartida `_openingAi` en
   los cuatro métodos de navegación de `HomePage` que abren el chat.

### #11 — "Hero del home" — **cerrado**
La barra de progreso del hero pintaba el segmento de "pagos programados" en
ámbar (`onPrimaryWarn`) con solo tener algo programado, sin importar si
había riesgo real de exceder el presupuesto. Verificado en Pencil (`xRSdl`):
el diseño real no tiene una variante "morado más opaco" para ese caso — la
respuesta es simplemente no dibujar el segundo segmento. Corregido para que
solo se pinte cuando `BudgetProgress.isScheduledOverspendRisk` es real.

### #12 — "IA: Permitir leer notas al asistente" — **sin reproducir, documentado**
El interruptor de notas en Ajustes no persistía al cerrar/reabrir la app,
con sesión iniciada. Investigación exhaustiva:
- Descartada la capa local completa (repro real: escribir, cerrar Drift,
  abrir instancia nueva contra el mismo archivo, leer — persiste bien).
- Descartada la hipótesis de carrera de sincronización, **refutada por el
  propio paquete `powersync` 2.3.3** (no por lectura del código del
  proyecto): `ps_crud` bloquea la aplicación de cualquier checkpoint
  entrante mientras haya algo pendiente de subir, y esa protección sobrevive
  un reinicio de proceso. Hay un test del paquete que ejercita exactamente
  este escenario.
- Queda una pista sin confirmar: `LocalDataOwnershipDatasource.claimUnownedRows`
  toca `app_settings.user_id` en el primer login, pero no calza del todo con
  "cerrar y reabrir con la sesión de siempre" tal como se reportó.

**No se escribió ningún fix especulativo.** Detalle completo en
`docs/dev-runs/issue-12-notas-no-persisten.md`.

### #13 — "IA: Retirar consentimiento" — **cerrado**, dos partes
1. **La promesa vs. la realidad**: el texto decía que las conversaciones "se
   quedan en tu dispositivo", pero no había forma de navegar a verlas sin
   volver a aceptar el consentimiento. Decisión del usuario: dejar el
   historial accesible, con un botón en `AiConsentPage` ("Ver mis
   conversaciones anteriores", visible solo si hay conversaciones guardadas)
   que lleva a una pantalla de solo lectura nueva (`AiConversationReadPage`
   + `AiConversationReadCubit`, sin método `send` — imposible enviar un
   mensaje nuevo sin consentimiento, por construcción, no por chequeo de UI).
2. **Permiso huérfano**: el interruptor de notas quedaba visible y
   reactivable con el consentimiento amplio ya retirado. Ahora solo existe
   con consentimiento vigente (mismo patrón que ya usaba el botón de
   retirar).

### #14 — "IA: Card del home" — **cerrado**, tras dos vueltas de diseño
Los chips de preguntas sugeridas casi no se distinguían de la tarjeta que
los contiene, sobre todo en oscuro (1.09:1 medido, WCAG pide ≥3:1).

- **Primer intento** (borde `stroke:$primary-on-soft`): rechazado por el
  usuario al verlo — "la aplicación no brilla por tener bordes".
- **Segundo intento**: resuelto por color, no por forma — nuevo token
  `$muted-strong` (claro idéntico a `$muted`, oscuro `#6E68AB`, 3.30:1).
  `ui-ux-reviewer` encontró 2 bloqueantes reales en su primera auditoría
  (el fix no se había propagado a 107/115 instancias por overrides viejos;
  el ícono quedó ilegible contra el nuevo fondo, 1.82:1) — cerrados y
  verificados independientemente en una segunda pasada: 0/115 instancias con
  overrides rotos, ícono en oscuro a `$text-primary` (4.50:1).
- El usuario además pidió reabrir una decisión de esta misma sesión: el alto
  uniforme forzado entre los 4 chips (`_chipHeight = 64`, fix de un bug
  anterior) se sentía artificial para chips de texto corto. Se quitó — cada
  chip mide su propio contenido, sin alto forzado. El texto sigue pudiendo
  ocupar 2 líneas (el usuario prefirió eso a forzar una sola línea).
- Padding bajado de `[14,16]` a `14` uniforme, verificado que sigue en el
  piso de 44pt de tap target.

Implementado en `lib/core/theme/app_colors.dart` (token `mutedStrong`
nuevo) y `lib/features/home/presentation/widgets/ai_question_chip.dart` /
`ai_card_chips.dart`. 338/338 tests de Home en verde, goldens regenerados.

## Archivos nuevos de esta sesión (no trackeados)

- `lib/features/ai/presentation/cubit/ai_conversation_read_cubit.dart` (+state)
- `lib/features/ai/presentation/pages/ai_conversation_read_page.dart`
- `lib/features/ai/presentation/widgets/ai_read_only_banner.dart`
- Tests correspondientes en `test/features/ai/presentation/`
- `test/features/home/presentation/widgets/ai_card_chips_test.dart`
- `docs/dev-runs/issue-12-notas-no-persisten.md`
- `docs/qa/casos-de-prueba-qa-0.0.7.md`

## Pendiente

- **Commitear y cerrar los issues de GitHub** — a la espera de que el
  usuario revise. `screenshot2.png` en la raíz es un archivo de debugging
  de esta sesión, no debería commitearse (igual que la vez pasada).
  `.claude/hooks/` es local del usuario, tampoco se commitea.
- `#12` sigue abierto — la pista de `claimUnownedRows` no se investigó más
  a fondo; hace falta reproducirlo en un dispositivo real con sesión
  iniciada para avanzar.

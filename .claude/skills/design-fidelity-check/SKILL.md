---
name: design-fidelity-check
description: Valida que TODAS las pantallas de una feature (paginas + sheets) coincidan con su diseno en billetudo.pen, usando golden tests como referencia deterministica en vez de un emulador en vivo. Genera/completa los goldens faltantes y compara cada uno contra su nodeId de Pencil.
---

# design-fidelity-check

Uso: `/design-fidelity-check <feature>` (ej. `/design-fidelity-check cuentas`, `/design-fidelity-check transacciones`).

Reemplaza la revision manual en emulador (screenshots via `adb`, comparacion a ojo contra Pencil) por un flujo deterministico: golden tests de Flutter (renderizado real, sin emulador, sin ADB) comparados contra capturas de `billetudo.pen`. Nace de un incidente real: en una sesion previa, `adb input tap` dejo de responder de forma persistente pese a multiples reinicios del emulador (documentado en `docs/dev-runs/bug-fixes-pixel-audit.md`), bloqueando la verificacion visual durante gran parte de la corrida. Un golden no depende de ningun dispositivo, corre en segundos, y es repetible en CI.

## Pasos

1. **Completar goldens** — delega a `qa-automator` (via Agent, subagent_type: `qa-automator`): generar/actualizar los golden tests de la feature indicada, cubriendo **cada** archivo bajo `presentation/pages/` y `presentation/widgets/sheets/`, con todos sus estados de negocio distinguibles, en claro y oscuro. Sigue la seccion "Golden tests" de `.claude/agents/qa-automator.md` (helper compartido `test/support/golden_helpers.dart`, nunca uno duplicado por feature). Corre `flutter test --update-goldens` sobre esa carpeta y confirma que todo pasa antes de continuar.
2. **Comparar contra Pencil** — delega a `pencil-fidelity-reviewer` (via Agent, subagent_type: `pencil-fidelity-reviewer`): revisar cada `.png` generado en el paso 1 contra su nodeId en `design-system/billetudo/pages/<feature>.md`, y entregar el reporte por severidad (`CRITICO/IMPORTANTE/MENOR`) que ya sabe producir. Si el `.pen` no es accesible, el skill se detiene aqui y lo reporta — no se aprueba a ciegas contra el `.md` solo (misma regla del gate de Pencil de `feature-dev`).
3. **Presentar el resultado**: un resumen unico, agrupado por pantalla, con los hallazgos del paso 2 mas los dos gaps explicitos que entrega `pencil-fidelity-reviewer` (goldens sin fila en el `.md`, pantallas en el `.md` sin golden). No corrijas nada automaticamente — este flujo es de verificacion, igual que `/tier0-check`. Pregunta al usuario si quiere que se apliquen los fixes encontrados (y si los pide, es trabajo de `flutter-dev`, no de este skill).
4. Cierra con un veredicto claro por feature: "fiel a Pencil" / "N hallazgos, M gaps de cobertura" — no dejes la conclusion ambigua.
5. **Actualizar `docs/fidelidad-visual-tracking.md`** (obligatorio, es el unico lugar que consolida el estado de fidelidad entre features — ver su cabecera): edita la fila de la feature revisada con el veredicto del paso 4.
   - Sin hallazgos `CRITICO`/`IMPORTANTE` pendientes y sin gaps de cobertura → Estado `✅ Aprobada`, fecha de hoy, Fuente apuntando al dev-run/reporte de esta corrida.
   - Con hallazgos aun sin corregir, o con gaps de cobertura (`.md` sin golden / golden sin fila) → Estado `🟡 Parcial`, y anota en Notas que sigue pendiente.
   - Si el usuario pidio los fixes y `flutter-dev` los aplico dentro de la misma corrida, refleja el resultado *final* (post-fix), no el hallazgo original.
   - Si esta corrida resuelve un pendiente listado en "Pendientes activos" de ese mismo doc o en `docs/bugfixes.md`, tachalo/quitalo de esa lista en vez de dejarlo duplicado.
   - Si no existe todavia una fila para la feature en la tabla, agregala en vez de omitir el paso.

## Notas

- No se engancha automaticamente al workflow `feature-dev` — se invoca a demanda, por feature, cuando se quiera esa garantia extra. El gate de Pencil que ya existe en `feature-dev.js` (fase Plan) sigue siendo el unico chequeo automatico de acceso a Pencil antes de construir; este skill es el chequeo de *fidelidad* despues de construir.
- Si la feature no tiene aun `design-system/billetudo/pages/<feature>.md` (ej. `settings` hoy), dilo como bloqueo antes de invocar a `pencil-fidelity-reviewer` — sin esa tabla no hay como resolver nodeIds de forma confiable.
- El paso 5 (actualizar `docs/fidelidad-visual-tracking.md`) lo hace este skill, no `pencil-fidelity-reviewer` — ese agente es de solo lectura a proposito (nunca escribe `.pen`, `lib/` ni `test/`, ver su definicion). Si en algun momento se corre la auditoria por fuera de este skill (a mano, agente suelto), quien la cierre es responsable de dejar la tabla al dia igual.

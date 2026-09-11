# `mcp__pencil__get_screenshot` no existe — usar `TakeScreenshot` dentro de `execute`

**Fecha:** 2026-09-10. **Contexto:** bloqueo real al intentar `/design-fidelity-check` sobre `scheduled_payments` (PR #29, `feat/local-notifications`).

## El problema

`CLAUDE.md` y varios subagentes (`pencil-fidelity-reviewer`, `pencil-designer`, `ui-ux-reviewer`, `flutter-dev`) dan por hecho que el servidor MCP de Pencil expone tools independientes `mcp__pencil__get_screenshot`, `mcp__pencil__get_guidelines` y `mcp__pencil__export_nodes`. En el servidor Pencil realmente conectado a este repo (binario local en `~/.pencil/mcp/visual_studio_code/out/mcp-server-darwin-arm64`, tanto con `--app desktop` como con `--app visual_studio_code`), esas tres tools **no existen**. Confirmado dos veces:

- `ToolSearch({query:"select:mcp__pencil__get_screenshot"})` → "No matching deferred tools found".
- Listar todo con `ToolSearch({query:"pencil"})` solo devuelve `browser`, `execute`, `get_app_state`, `get_style`, `read_skill`.

Esto ya se había descubierto el 2026-08-18 (ver memoria `pencil-agentes-sin-write-ni-screenshot`) y sigue igual hoy — no es un problema de carga diferida ni de configuración, la tool simplemente no está en este build del servidor.

## La solución real (no un workaround a medias)

El tool consolidado `mcp__pencil__execute` expone, dentro de su API de JavaScript, una función `TakeScreenshot(nodeIds: string[])` que **sí renderiza y adjunta capturas reales** de cualquier nodo del `.pen` — es la misma capacidad que prometía la tool separada, solo que vive dentro de `execute` en vez de ser su propia tool MCP.

Uso:

```js
TakeScreenshot(['nodeId1', 'nodeId2']);
```

Esto adjunta una imagen por nodo a la respuesta de `execute`, en el mismo orden que la lista de ids. Verificado en vivo contra los goldens de `scheduled_payments` (recordatorio de vencimiento, PR #29): coincidencia exacta de texto, ícono, color y layout.

**Cualquier agente de solo lectura de Pencil que necesite comparar un render real (no solo estructura) debe:**
1. Tener `mcp__pencil__execute` en su lista de `tools:` (no `mcp__pencil__get_screenshot`, que no existe).
2. Usar únicamente las funciones de lectura de `execute` para esto: `Get`, `GetVariables`, `Print`, `TakeScreenshot`. Nunca `Insert`/`Copy`/`Update`/`Replace`/`Move`/`Delete`/`SetVariables`/`Generate` — la restricción de solo-lectura la impone la instrucción del agente, no el tooling (esto ya era así para `flutter-dev`, ver `CLAUDE.md`).
3. `export_nodes`/`Export(...)` (dentro de `execute`) sigue existiendo para producir archivos en disco si hace falta, pero para *verificar* fidelidad visual `TakeScreenshot` alcanza y no ensucia el filesystem.
4. `get_guidelines` tampoco existe como tool separada; los lineamientos genéricos que ofrecía no eran el sistema de diseño del proyecto de todas formas (ver `CLAUDE.md`), así que su ausencia no pierde nada real.

## Qué se corrigió con este hallazgo

- `CLAUDE.md`, sección "Diseño / UI (Pencil)": ya no cita `get_screenshot`/`get_guidelines`/`export_nodes` como tools independientes.
- `.claude/agents/pencil-fidelity-reviewer.md`, `.claude/agents/pencil-designer.md`, `.claude/agents/ui-ux-reviewer.md`, `.claude/agents/flutter-dev.md`: `tools:` actualizado a `mcp__pencil__execute` en vez de las tools inexistentes, con la instrucción explícita de qué funciones de `execute` usar (y cuáles no, para los agentes de solo lectura).
- `design-system/billetudo/pages/pagos-programados.md`: sección "Recordatorio de vencimiento" añadida con los nodeId reales, verificados con este mecanismo.

## Qué NO cambia

Esto no reemplaza la comparación estructural (`Get` con `visit`, sin captura) que ya usaban los agentes como respaldo — sigue siendo válida y más barata para verificar tokens/estructura/copy. `TakeScreenshot` se reserva para cuando de verdad hace falta ver el render (layout, alineación, tipografía real), tal como ya decía la guía de `execute`: "reach for a screenshot only when visual fidelity ... is what you need to verify".

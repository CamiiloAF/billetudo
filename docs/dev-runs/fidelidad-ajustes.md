# Fidelidad visual — Ajustes

Corrida `/design-fidelity-check auth` (2026-07-20), ítem 10 de `docs/bugfixes.md`.

El ítem original pedía "implementar las pantallas Ajustes y Más, que están diseñadas en
`billetudo.pen` pero sin código todavía". Al investigar, ambas ya existían en código
(`lib/features/settings/presentation/pages/settings_page.dart` y
`lib/features/home/presentation/pages/more_page.dart`, esta última ya auditada en el ítem 8
de este mismo backlog) y conectadas al router — el ítem, tal como está escrito, indica
explícitamente correr `/design-fidelity-check auth` de nuevo una vez construidas. Eso es lo
que hizo esta corrida, acotada a Ajustes (Más ya cerrado por separado).

## Auditoría — resultado

**2 hallazgos IMPORTANTE + 1 MENOR** (con decisión del usuario en 2 de los 3):

1. **Fila "Modo sobres"** nunca se había compuesto dentro de los 4 frames reales de Ajustes en
   Pencil (`jDaUb`/`j4JYF`/`aaQBp`/`TQHmY`) — solo existía como referencia aislada
   (`r5aVv`/`GZUqi`), documentada en `presupuestos.md`, no en `auth.md`. El copy del código
   además divergía de esa referencia.
2. **Sublabel "Claro" ausente** en la fila "Apariencia" — Pencil especifica label+sublabel de
   2 líneas, el código solo mostraba una.
3. **[MENOR, decisión de usuario]** Avatar de sesión con 2 iniciales ("CA") en vez de 1 ("C")
   como especifica Pencil.

## Fixes

- `pencil-designer`: compuso la fila "Modo sobres" dentro de los 4 frames reales de Ajustes,
  en una sección nueva "Presupuesto" (entre "Cuenta y respaldo" y "Preferencias") — decisión de
  UX: es un ajuste de comportamiento central del presupuesto (`zeroBasedEnabled`, global), no
  una preferencia de visualización como Apariencia/Moneda. `auth.md` actualizado con la
  estructura completa y los nodeId reales de las 4 instancias.
- `flutter-dev`: sublabel "Claro"/"Oscuro" condicional en Apariencia, copy de "Modo sobres"
  corregido a "Reparte todo tu ingreso en sobres", avatar a una sola inicial. Segunda tanda:
  `EnvelopeModeField` movido de la sección "Preferencias" a la nueva sección "Presupuesto"
  (gap detectado por `qa-automator` al regenerar goldens — el switch ya existía en código, solo
  faltaba la sección propia).
- **Incidente de sesión**: una condición de carrera entre dos agentes editando
  `settings_page.dart` en secuencia hizo que el archivo volviera a su estado pre-fix
  silenciosamente (sin error, sin conflicto reportado) — detectado porque `compliance-reviewer`
  señaló que `git status` no mostraba cambios ahí, contradiciendo el trabajo ya confirmado por
  goldens. Reaplicado directamente, sin pasar por otro agente, para evitar repetir la carrera.
- `qa-automator`: 4 goldens nuevos de `settings_page` (con/sin sesión, claro/oscuro) — no
  existía ningún golden de esta página antes de esta corrida, solo del sheet informativo.

## Veredicto final

**✅ Aprobada.** Los 3 hallazgos resueltos y re-verificados contra los nodeId reales. Reviews
finales (finance-code-reviewer, ui-convention-reviewer, compliance-reviewer): sin hallazgos —
compliance confirmó explícitamente que "Eliminar cuenta" (HU-07) sigue accesible y funcional,
sin ningún cambio de esta pasada detrás de gate de pago/anuncio, y que "Modo sobres" (Nivel 0)
sigue gratis y sin restricciones.

### Gaps de diseño, no bloqueantes (documentados en `auth.md`)

- El destino del link "¿Qué es?" (explicación del modo sobres) y el comportamiento del `Switch`
  al activarse/desactivarse (¿confirmación, cambio inmediato?) no están diseñados como flujo —
  quedan igual que en la referencia original.
- La fila "Apariencia" no tiene selector diseñado todavía (bottom sheet o pantalla para elegir
  claro/oscuro/sistema) — sigue abriendo el placeholder "Próximamente".

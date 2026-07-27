# Fidelidad visual — Cuentas

Cierre formal del ciclo de fidelidad para Cuentas (2026-07-20). Primer cierre real vía
`/design-fidelity-check` — la auditoría del 2026-07-19 (`docs/dev-runs/bug-fixes-pixel-audit.md`)
fue pixel-a-pixel manual, nunca se verificó goldens contra Pencil con este flujo.

## Ronda 1 — auditoría inicial (52 goldens)

3 hallazgos **CRÍTICO** + 6 **IMPORTANTE** + 1 **MENOR** (del lado del `.pen`, no corregido a
propósito):

1. Formato de dinero: código en vez de símbolo en toda la feature.
2. Botón "Guardar cuenta" ausente en el cuerpo del formulario (solo estaba en el header).
3. Botón "Guardar" ausente en el sheet Selector de día (confirmaba directo al tocar).
4. Skeleton del Total Card ausente en carga.
5. Label "Deuda" vs "Deuda actual" en `Credit Card Account Row`.
6. Ícono en el botón "Archivar" que Pencil desactiva.
7. Sheets de confirmar-eliminar y cambio-tipo/moneda con título+cuerpo reescritos en vez de
   mensaje único.
8. Campo de dinero de nivel superior visible para tarjeta, sin equivalente en el diseño.
9. Labels/placeholders del formulario distintos a Pencil.

## Ronda 1 — fixes

`flutter-dev` corrigió los 9 (formatSymbol, botones nuevos, skeleton, labels, sheets con mensaje
único, campo condicional por tipo). `qa-automator` regeneró 52 goldens + agregó cobertura nueva
(day picker con interacción real, botón Guardar habilitado/deshabilitado).

## Ronda 2 — re-verificación + 2 hallazgos nuevos

Los 9 de la ronda 1 confirmados resueltos. Aparecieron:

- **[CRÍTICO]** Campo "Tasa de interés" ausente para cuentas no-tarjeta — `showInterestRateField`
  estaba restringido a `isCard`, contradiciendo el diseño aprobado (`xdLeB`, cuenta Banco, sí lo
  muestra). Corregido a `type != AccountType.cash` (efectivo es la única exclusión real, por
  razón de negocio — el diseño no lo distingue explícitamente pero no genera interés).
- **[IMPORTANTE]** Botón "Archivadas" en el header presente en los 4 estados en código, pero
  Pencil solo lo documentaba en el estado "con datos". Decisión: el código tiene razón (el
  usuario debe poder navegar a archivadas incluso si la carga falló/está vacía) — se propagó el
  botón a los 6 frames restantes en Pencil en vez de quitarlo del código.

## Ronda 3 — re-verificación final

Ambos hallazgos confirmados resueltos. Reviews finales (finance-code-reviewer,
ui-convention-reviewer, compliance-reviewer): sin hallazgos — compliance confirmó explícitamente
que el borrado de cuenta sigue usando `tombstonedAt` correctamente (integridad referencial con
`Transactions.accountId`) y que el tono del nuevo copy de los sheets es neutral/no punitivo.

## Veredicto final

**✅ Aprobada.** 326+ tests en la feature, 52 goldens.

### Gaps de cobertura conocidos, no bloqueantes

- Estados de referencia/interacción sin golden (tipo de cuenta expandido, reordenar por
  arrastre) — transitorios, difíciles de fijar en un golden estático.
- El chip "Banco" preseleccionado en `CwiKu` (lado Pencil) — posible artefacto de edición, no
  corregido a propósito, queda para que se confirme la intención por separado.

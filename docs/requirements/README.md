# Requerimientos — Fase 0 / Nivel 0

Requerimientos funcionales de la capa gratuita y completa de la app (Nivel 0 según `docs/Plan_Monetizacion_y_Tecnico.md`), separados por feature. Cada archivo tiene historias de usuario con criterios de aceptación observables, alineados al esquema Drift (`lib/core/database/app_database.dart`) y a las reglas de `CLAUDE.md`.

1. [Cuentas](01-cuentas.md)
2. [Categorías](02-categorias.md)
3. [Transacciones](03-transacciones.md)
4. [Inicio (Home + shell de navegación)](04-inicio.md)
5. [Auth + Sync](05-auth-sync.md)
6. [Presupuestos](06-presupuestos.md)
7. [Metas de ahorro](07-metas.md)
8. [Deudas y préstamos](08-deudas.md)
9. [Pagos programados](09-pagos-programados.md)
10. [Gráficas e informes esenciales](10-graficas-informes.md)
11. [Import/Export (portabilidad de datos)](11-import-export.md)
12. [Multi-moneda](12-multi-moneda.md) — **diferida a Fase 1** (ver el propio documento; Fase 0 segmenta por moneda y no convierte)
13. [Onboarding — flujo de bienvenida](13-onboarding.md)
14. [Apariencia (dentro de Ajustes)](14-apariencia.md)
15. [La app sin cuentas (gate "necesitas una cuenta")](15-gate-cuenta.md)
16. [Minitutoriales (ayuda contextual por feature)](16-minitutoriales.md)

Los documentos **13, 15 y 16** son las tres piezas de "enseñar la app" y se entregan en el orden **15 → 13 → 16** (ver "Orden de entrega" en `13-onboarding.md`).

Ninguna de estas features puede quedar bloqueada tras anuncio o pago (regla de Nivel 0, `CLAUDE.md`). La única excepción documentada es dentro de **Gráficas e informes**: el set esencial es Nivel 0, pero las vistas avanzadas son Nivel 1/2 — ver el detalle en `10-graficas-informes.md`.

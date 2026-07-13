# Requerimientos — Fase 0 / Nivel 0

Requerimientos funcionales de la capa gratuita y completa de la app (Nivel 0 según `docs/Plan_Monetizacion_y_Tecnico.md`), separados por feature. Cada archivo tiene historias de usuario con criterios de aceptación observables, alineados al esquema Drift (`lib/core/database/app_database.dart`) y a las reglas de `CLAUDE.md`.

1. [Cuentas](01-cuentas.md)
2. [Categorías](02-categorias.md)
3. [Transacciones](03-transacciones.md)
4. [Presupuestos](04-presupuestos.md)
5. [Metas de ahorro](05-metas.md)
6. [Deudas y préstamos](06-deudas.md)
7. [Recurrentes](07-recurrentes.md)
8. [Gráficas e informes esenciales](08-graficas-informes.md)
9. [Import/Export CSV](09-import-export.md)
10. [Multi-moneda](10-multi-moneda.md)
11. [Auth + Sync](11-auth-sync.md)
12. [Onboarding](12-onboarding.md)

Ninguna de estas features puede quedar bloqueada tras anuncio o pago (regla de Nivel 0, `CLAUDE.md`). La única excepción documentada es dentro de **Gráficas e informes**: el set esencial es Nivel 0, pero las vistas avanzadas son Nivel 1/2 — ver el detalle en `08-graficas-informes.md`.

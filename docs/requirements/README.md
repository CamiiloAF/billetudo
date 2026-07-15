# Requerimientos — Fase 0 / Nivel 0

Requerimientos funcionales de la capa gratuita y completa de la app (Nivel 0 según `docs/Plan_Monetizacion_y_Tecnico.md`), separados por feature. Cada archivo tiene historias de usuario con criterios de aceptación observables, alineados al esquema Drift (`lib/core/database/app_database.dart`) y a las reglas de `CLAUDE.md`.

1. [Cuentas](01-cuentas.md)
2. [Categorías](02-categorias.md)
3. [Transacciones](03-transacciones.md)
4. [Auth + Sync](04-auth-sync.md)
5. [Presupuestos](05-presupuestos.md)
6. [Metas de ahorro](06-metas.md)
7. [Deudas y préstamos](07-deudas.md)
8. [Recurrentes](08-recurrentes.md)
9. [Gráficas e informes esenciales](09-graficas-informes.md)
10. [Import/Export CSV](10-import-export.md)
11. [Multi-moneda](11-multi-moneda.md)
12. [Onboarding](12-onboarding.md)

Ninguna de estas features puede quedar bloqueada tras anuncio o pago (regla de Nivel 0, `CLAUDE.md`). La única excepción documentada es dentro de **Gráficas e informes**: el set esencial es Nivel 0, pero las vistas avanzadas son Nivel 1/2 — ver el detalle en `09-graficas-informes.md`.

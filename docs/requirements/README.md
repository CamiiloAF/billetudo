# Requerimientos por fase

Requerimientos funcionales separados por feature. Cada archivo tiene historias de usuario con criterios de aceptación observables, alineados al esquema Drift (`lib/core/database/app_database.dart`) y a las reglas de `CLAUDE.md`.

La numeración es **global y única** (no reinicia por fase): muchos docs, tests y comentarios de código referencian estos archivos por su número, así que un número identifica siempre la misma feature aunque cambie de carpeta.

## [Fase 1](fase-1/) — Núcleo + respaldo en nube (Nivel 0)

La capa gratuita y completa de la app (Nivel 0 según `docs/Plan_Monetizacion_y_Tecnico.md`).

1. [Cuentas](fase-1/01-cuentas.md)
2. [Categorías](fase-1/02-categorias.md)
3. [Transacciones](fase-1/03-transacciones.md)
4. [Inicio (Home + shell de navegación)](fase-1/04-inicio.md)
5. [Auth + Sync](fase-1/05-auth-sync.md)
6. [Presupuestos](fase-1/06-presupuestos.md)
7. [Metas de ahorro](fase-1/07-metas.md)
8. [Deudas y préstamos](fase-1/08-deudas.md)
9. [Pagos programados](fase-1/09-pagos-programados.md)
10. [Gráficas e informes esenciales](fase-1/10-graficas-informes.md)
11. [Import/Export (portabilidad de datos)](fase-1/11-import-export.md)
12. [Multi-moneda](fase-1/12-multi-moneda.md) — **diferida a Fase 1b** (ver el propio documento; Fase 1 segmenta por moneda y no convierte)
13. [Onboarding — flujo de bienvenida](fase-1/13-onboarding.md)
14. [Apariencia (dentro de Ajustes)](fase-1/14-apariencia.md)
15. [La app sin cuentas (gate "necesitas una cuenta")](fase-1/15-gate-cuenta.md)
16. [Minitutoriales (ayuda contextual por feature)](fase-1/16-minitutoriales.md)

Los documentos **13, 15 y 16** son las tres piezas de "enseñar la app" y se entregan en el orden **15 → 13 → 16** (ver "Orden de entrega" en `13-onboarding.md`).

Ninguna de estas features puede quedar bloqueada tras anuncio o pago (regla de Nivel 0, `CLAUDE.md`). La única excepción documentada es dentro de **Gráficas e informes**: el set esencial es Nivel 0, pero las vistas avanzadas son Nivel 1/2 — ver el detalle en `10-graficas-informes.md`.

## [Fase 2](fase-2/) — Captura sin fricción local (Nivel 0)

Reducir a segundos el costo de registrar un gasto, **sin backend y sin costo marginal**: todo corre en el dispositivo.

17. [Captura por voz](fase-2/17-captura-voz.md)
18. [Captura por foto de recibo (OCR)](fase-2/18-captura-ocr.md)
19. [Lectura de notificaciones bancarias (Android)](fase-2/19-notificaciones-bancarias.md)
20. [Widget de captura rápida](fase-2/20-widget-captura-rapida.md)

**Recordatorios de vencimientos** es la quinta pieza de Fase 2 pero no tiene doc propio: vive como HU-08 dentro de [`09-pagos-programados.md`](fase-1/09-pagos-programados.md), porque configura una plantilla que ya existe en Fase 1.

**Frontera Nivel 0 / Nivel 1 (decisión 2026-08-17).** Toda la captura de Fase 2 es **Nivel 0: gratis, ilimitada y sin anuncios**, porque ocurre 100% en el dispositivo (audio→texto con `speech_to_text`, OCR con `mlkit`, lectura de notificaciones en Android) y el parseo usa **reglas locales**. Lo que el Cubo B de `Plan_Monetizacion_y_Tecnico.md` §2 clasifica como Nivel 1 es el **parseo con LLM** que llega en Fase 4 — una mejora de precisión que se suma encima, y que **nunca puede bloquear ni degradar la captura local ya entregada**. Esto resuelve la contradicción aparente entre §8 ("Fase 2 sin costo, parse con reglas locales") y §2 ("captura por voz/OCR = Cubo B").

### Decisiones transversales de Fase 2 (2026-08-17)

Aplican a los cuatro documentos; cada uno las desarrolla en su propio contexto.

- **Modelo de confirmación — híbrido.** Nada se registra sin confirmación humana. Voz y OCR **pre-llenan el formulario de transacción** existente (el usuario está presente). Las notificaciones bancarias caen en una **bandeja de capturas pendientes**, porque llegan sin el usuario delante.
- **Retención cero del dato crudo.** No se persiste el audio, ni la transcripción de voz, ni el texto de la notificación, ni el texto devuelto por el OCR — solo los campos ya extraídos. Consecuencia asumida: en Fase 4 el LLM podrá mejorar capturas **nuevas**, nunca re-parsear el histórico, y no habrá búsqueda por contenido del recibo.
- **Las tablas nuevas sincronizan.** `PendingCaptures` y `TransactionAttachments` usan el mixin `_SyncColumns` como el resto del esquema. Se sincronizan los **metadatos**, nunca los archivos: la foto del recibo es estrictamente local (ver punto siguiente). Sostener esto ante la política de privacidad es más fácil justamente porque el dato crudo no se guarda.
- **Foto del recibo: solo local, con aviso explícito al usuario.** No se sincroniza y se pierde al cambiar de dispositivo; hay que decírselo al usuario, no dejarlo implícito. La sincronización de la foto queda reservada como feature **Premium (Nivel 2)** a futuro — la costura se deja lista para que sea aditiva, sin construir nada de nube ahora.
- **El widget es atajo puro.** Botones que abren la app en el punto de captura; no muestra ningún dato financiero. Evita App Groups en iOS, el espejo de datos entre procesos y el problema de exponer cifras en la pantalla de inicio — especialmente relevante porque **la app no tiene bloqueo biométrico ni PIN** (la biometría figura en el Cubo A del plan pero nunca se implementó).

**Orden de construcción.** 19 (notificaciones bancarias) → 17 (voz) → 18 (OCR) → 20 (widget). Las notificaciones bancarias van primero por ser el diferenciador Android-first.

**Condición de publicación (no negociable).** La lectura de notificaciones bancarias va **activa desde el primer release público**, pero ese release **debe incluir voz y OCR ya funcionando**. `Plan_Monetizacion_y_Tecnico.md` §9 exige no depender solo de esa vía por el riesgo de rechazo de Google Play; publicar la feature sin las alternativas vivas incumpliría esa mitigación y obliga a reabrir la decisión.

**Migraciones de esquema.** Dos, en este orden para que no colisionen: `PendingCaptures` toma el **primer número libre** y `TransactionAttachments` el **siguiente**. Voz y widget no consumen ninguno (`TxSource` ya incluye `voice`, `ocr` y `notification`). Cada migración exige paridad en Supabase/PowerSync — ver `/drift-schema-change`.

> **Lee el `schemaVersion` vigente al implementar; no copies un número de estos documentos.** Al 2026-08-17 el working tree está en **28** mientras `HEAD` está en **26** — hay trabajo sin commitear que ya consumió 27 y 28. Con ese estado las dos migraciones de Fase 2 serían 28 → 29 y 29 → 30, pero el esquema se mueve rápido. Este mismo repo ya tiene el precedente: `fase-1/09-pagos-programados.md` documentó "hoy 10 → 11" y quedó obsoleto. Dos features reclamando la misma versión producen una base local que se cree migrada sin estarlo, y el fallo es silencioso.

**Bloqueante de publicación.** `docs/legal/declaraciones-tiendas.md` y `docs/legal/AUDITORIA.md` declaran hoy ante las tiendas que la app **no** tiene captura por voz, OCR ni IA, apoyándose en que `lib/features/capture/` está vacío. Fase 2 invalida esa declaración: hay que actualizarla, junto con los primeros `uses-permission` del `AndroidManifest.xml` y las claves `*UsageDescription` del `Info.plist`, antes de publicar.

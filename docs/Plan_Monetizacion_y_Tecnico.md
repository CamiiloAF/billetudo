# Plan de monetización y técnico — App de finanzas personales (Flutter)

**Principio rector:** hay **una capa 100% gratuita, completa y sin anuncios** que basta para llevar tus finanzas para siempre. El resto de features (IA, gráficas/informes más allá de un mínimo, etc.) están bloqueadas por defecto y se desbloquean de **dos formas a elección del usuario**: activando el *Modo con anuncios* o suscribiéndose a Premium. Nada de banners intrusivos ni interstitials sorpresa — los anuncios existen **solo** dentro del modo opt-in que el usuario enciende a propósito.

---

## 1. Los tres niveles de acceso

### Nivel 0 — Capa gratuita, completa, sin anuncios (siempre)

El error de AI Money y MonAi es mutilar el plan gratis (WhatsApp a 2/día, ~20 transacciones/mes), lo que genera reseñas negativas y sensación de rehén. Tu ventaja es la contraria: **el nivel gratis es una app de finanzas completa** — registro manual ilimitado, presupuestos, categorías, metas, deudas, un set esencial de gráficas e informes, import/export. Todo eso te cuesta **cero** porque se calcula en el dispositivo, así que jamás se limita ni se acompaña de anuncios.

### Nivel 1 — Features extra vía *Modo con anuncios* (opt-in, reversible, con límite mensual)

Las features que te cuestan dinero (IA) o que reservas como "extra" (gráficas/informes avanzados más allá de X) están **bloqueadas por defecto**. El usuario puede **activar el Modo con anuncios**: al aceptarlo, se le habilitan esas features **hasta un límite mensual**, y a cambio ve anuncios recompensados como "precio" de ese acceso.

Puntos clave de este nivel:
- Es **opt-in**: el usuario lo enciende conscientemente; nunca se le imponen anuncios.
- Es **reversible**: puede apagarlo cuando quiera desde ajustes. Al apagarlo, **pierde el acceso a esas features** (vuelve al Nivel 0). Sin castigo, sin pérdida de datos — solo dejan de estar disponibles las funciones extra.
- Tiene **límite mensual** aunque vea anuncios: el modo con anuncios no es ilimitado. Al agotar el cupo mensual, para más solo queda Premium (o esperar al mes siguiente).

### Nivel 2 — Premium (suscripción)

Las mismas features extra **sin anuncios** y con **límite mayor o ilimitado**, más las funciones demasiado costosas para sostenerse con anuncios (chat IA, insights proactivos, nube).

Los límites del Nivel 1 se calibran para que **un usuario normal casi nunca los alcance** — solo el usuario intenso, que ya recibió mucho valor, llega al tope y siente que es justo ver más anuncios o pagar. Esto convierte anuncios y suscripción en algo que el usuario *elige desde la gratitud*, no desde la frustración.

---

## 2. Clasificación de features por costo marginal

Tres cubos que corresponden a los tres niveles. La regla es simple: **si te cuesta $0 por uso, es gratis ilimitado (Nivel 0). Si te cuesta poco, es feature extra desbloqueable con Modo anuncios o Premium (Nivel 1). Si te cuesta bastante por uso, es solo Premium (Nivel 2).**

### Cubo A — Nivel 0: siempre gratis e ilimitado (costo marginal $0, todo local)

Estas son el corazón de la app y jamás se limitan ni llevan anuncios. Se calculan en el dispositivo, así que no te cuestan nada por usuario.

| Feature | Por qué es gratis |
|---|---|
| Registro **manual** de transacciones (ilimitado) | Es el núcleo; limitarlo rompería la promesa de "100% funcional" |
| Cuentas ilimitadas (efectivo, banco, tarjetas, ahorros) | Solo son filas en la base de datos local |
| Categorías y subcategorías **personalizables** ilimitadas | Queja directa contra Wallet — aquí es gratis y libre |
| Presupuestos ilimitados (mensual, por categoría, base-cero) | Cálculo local |
| Metas de ahorro (vinculables a cuentas) | Cálculo local |
| Deudas y préstamos | Cálculo local |
| **Set esencial de gráficas e informes** (flujo, balance, estructura de gasto) | Se renderizan en el dispositivo con `fl_chart`. Las visualizaciones *avanzadas más allá de X* van al Cubo B |
| Transacciones recurrentes / pagos planeados | Lógica local |
| **Import/Export CSV** impecable (incluye formato Wallet/Mint) | Feature de *confianza*: "nunca te sentirás atrapado". Gratis a propósito |
| Multi-moneda (con tasas cacheadas diariamente) | Una llamada de tasas al día para todos, no por usuario |
| **Lectura de notificaciones bancarias del móvil** (Android) | Se procesa localmente; captura automática sin costo de API ni Plaid |
| Backup local, modo oscuro, biometría | Locales |

> Nota: la lectura de notificaciones bancarias es potentísima y **gratis para ti** porque ocurre 100% en el dispositivo. Solo funciona en **Android** (iOS no permite leer notificaciones de otras apps). Es un gran diferenciador para tu mercado, que es Android-first.

### Cubo B — Nivel 1: features extra vía Modo anuncios (opt-in) o Premium

Bloqueadas por defecto. El usuario las habilita **activando el Modo con anuncios** (hasta un límite mensual) o con **Premium** (sin anuncios, ilimitado). Son de dos tipos:

**(i) Captura por IA** — te cuestan dinero, pero **muy poco** si las optimizas. Un anuncio recompensado en LatAm paga ~$0.002-0.004, así que deben costarte *menos que eso* por uso — se logra con modelos económicos + *prompt caching* + OCR/voz en el dispositivo.

| Feature | Costo marginal aprox. | Cómo mantenerlo bajísimo |
|---|---|---|
| Captura por **voz** (hablar el gasto) | ~$0.0002 | `speech_to_text` local para el audio→texto (gratis); solo el parse va a un LLM barato |
| Captura por **texto en lenguaje natural** | ~$0.0002 | LLM económico (Haiku/GPT-nano), prompt corto, cacheado |
| **Escáner de recibo (OCR)** | ~$0.0003 | OCR con `google_mlkit` en el dispositivo (gratis) + LLM barato solo para estructurar |
| **Auto-categorización con IA** | ~$0.0001 | Procesamiento en *batch* (−50%) + caching (−90%); primero intenta reglas locales gratis |

**(ii) Visualizaciones avanzadas** — no te cuestan nada (se calculan local), pero las reservas como "extra" a petición tuya: gráficas e informes **más allá del set esencial gratuito** (p. ej. comparativas entre periodos, tendencias, desglose por etiquetas, proyecciones, informes exportables a PDF). Aquí el anuncio no compensa un costo — es ingreso puro y riesgo cero.

**Mecánica (no bloqueante):**
- El Nivel 0 sigue disponible gratis siempre → la app nunca se bloquea; el registro manual y las gráficas esenciales no dependen de esto.
- Si el Modo anuncios está **apagado**: la feature aparece bloqueada con la invitación *"Actívala viendo anuncios o con Premium."*
- Si está **encendido**: la feature funciona hasta el cupo mensual; un anuncio recompensado desbloquea un lote (p. ej. 5-10 capturas o una sesión de informes avanzados). 1 anuncio = un lote, no una sola acción, para que el valor del anuncio (~$0.003) cubra con margen el costo.
- Al **agotar el cupo mensual** del Modo anuncios: *"Llegaste a tu límite mensual. Pásate a Premium para uso ilimitado, o vuelve el próximo mes."*
- Si el usuario **apaga el Modo anuncios**: estas features se bloquean de nuevo al instante (vuelve al Nivel 0), sin tocar sus datos.

### Cubo C — Nivel 2: solo Premium (costo marginal alto o infraestructura continua)

Aquí un anuncio de LatAm no alcanza a cubrir el costo, así que **no** se ofrece la opción de Modo anuncios: es Premium directo. Son también el "valor sostenido" que justifica pagar mes a mes.

| Feature | Por qué solo suscripción |
|---|---|
| **Chat / asistente financiero con IA** (razonamiento) | Una sesión conversacional cuesta $0.01-0.10; un anuncio no lo cubre |
| **Insights proactivos** generados por IA (resúmenes semanales/mensuales automáticos) | Costo recurrente por usuario, no puntual |
| **Sincronización multi-dispositivo en la nube** | Infraestructura continua (servidor + almacenamiento) |
| **Respaldo automático en la nube** | Almacenamiento continuo |
| Quitar la (opcional) invitación a anuncios | Comodidad para quien ya paga |

---

## 3. Cómo la app incentiva a mejorar las finanzas

Este es el diferenciador central que detectamos en la investigación: registrar gastos no basta — el valor real (y lo que retiene usuarios) es que la app **ayude activamente a mejorar**. YNAB logra esto pero con una curva de aprendizaje brutal; casi todas las demás solo registran. Aquí está tu oportunidad de dar el cambio de hábito de YNAB **sin su fricción**.

Ventaja clave: la mayoría de estas funciones se calculan **en el dispositivo, costo $0**, así que van **gratis en el Nivel 0**. No son un lujo de pago: son el corazón de la propuesta y el motor de retención. Solo la versión con IA (insights personalizados, coach) es Premium.

### Nivel 0 — gratis (local, $0)

- **Ritual de revisión semanal (15 min):** una pantalla guiada que resume la semana (gastos, presupuesto, avance de metas) y pide confirmar/recategorizar. Es el *sweet spot* que vimos: crea conciencia financiera sin el tedio del registro diario ni la complejidad de YNAB.
- **"Disponible para gastar" (safe-to-spend):** calcula cuánto puedes gastar hoy/este mes tras descontar presupuestos y compromisos. Es lo que hace atractivo a Chanchito y Simplifi — convierte datos en una respuesta accionable.
- **Rachas y hábito de registro:** streaks por registrar seguido e hitos, para volver el registro un hábito. Refuerzo positivo, nunca culpa.
- **Metas con progreso visible e hitos celebrados:** barras de avance, proyección de fecha de logro, celebración al alcanzar cada tramo.
- **Retos de ahorro basados en reglas:** ej. reto de 52 semanas, redondeo de compras a ahorro, "no gastar en X esta semana".
- **Alertas de presupuesto anticipadas y positivas:** avisar *antes* de pasarse ("te queda 20% del presupuesto de comida y faltan 10 días") y felicitar al cumplir.
- **Presupuesto base-cero opcional ("dale un trabajo a cada peso"):** la metodología que hace poderoso a YNAB, pero opcional y simplificada, no obligatoria.

### Nivel 2 — Premium (con IA)

- **Insights proactivos personalizados:** "Gastaste 30% más en delivery este mes; a este ritmo superarás tu presupuesto el día 22." Detecta patrones y sugiere ajustes.
- **Coach financiero por chat:** el usuario pregunta y recibe un plan (fondo de emergencia, priorizar deudas, ajustar metas).

**Principio de bienestar (importante):** el tono siempre es positivo y de progreso — celebrar avances, plantear los excesos como oportunidades, nunca avergonzar ni usar lenguaje negativo sobre el dinero. Las finanzas son un tema sensible; una app que motiva sin culpar genera lealtad, una que regaña se desinstala.

---

## 4. Diseño de límites

Tres columnas: lo que da el Nivel 0 gratis, el cupo mensual del Modo anuncios, y Premium. Los números exactos los afinarás con datos reales, pero la lógica de calibración es fijar el cupo del Modo anuncios **por encima del uso del percentil ~80** — de modo que el usuario intenso lo alcance y se sienta invitado a Premium, sin molestar al normal.

| Feature | Nivel 0 (gratis) | Modo anuncios (cupo mensual) | Premium |
|---|---|---|---|
| Registro manual, presupuestos, metas, deudas | Ilimitado | — | Ilimitado |
| **Gráficas / informes** | Set esencial (p. ej. 3-4 vistas core) | Hasta ~X vistas avanzadas/mes con anuncios | Todas, ilimitadas + export PDF |
| Captura por voz + texto natural | Bloqueada | ~40-60 / mes | Ilimitada |
| Escáner de recibos (OCR) | Bloqueada | ~10-15 / mes | Ilimitada |
| Auto-categorización IA | Reglas locales gratis; IA no | IA fallback ~50/mes | IA ilimitada |
| Chat IA e insights proactivos | — | — (no cubre el anuncio) | Sí |
| Nube / multi-dispositivo | — | — | Sí |

Sobre las **gráficas**: es buena idea limitar las *avanzadas* (el usuario ve un set esencial gratis siempre, y las vistas extra se cuentan). Detalle importante para no molestar: cuenta **vistas nuevas generadas**, no re-aperturas — una gráfica que el usuario ya desbloqueó este mes debe seguir viéndose sin gastar cupo ni anuncio nuevo. Así el límite incentiva sin frustrar.

Clave de implementación: **los límites y el conteo se validan en tu servidor, no en el cliente**, o serán triviales de saltar. Y la recompensa por anuncio debe verificarse con **AdMob Server-Side Verification (SSV)**, para que nadie falsee "vi el anuncio" y consiga features gratis.

---

## 5. Modelo de precios sugerido

- **Gratis (Nivel 0):** todo el Cubo A ilimitado, sin anuncios. Las features del Cubo B están bloqueadas hasta que el usuario active el Modo anuncios.
- **Modo anuncios (Nivel 1):** opt-in, gratis en dinero; desbloquea el Cubo B hasta los cupos mensuales a cambio de anuncios recompensados. Reversible.
- **Premium mensual:** regionalizado a LatAm, ~US$3-5 equivalente en moneda local (usa el *price localization* de Google Play / RevenueCat).
- **Premium anual:** ~US$25-40 equivalente (empújalo fuerte: retiene hasta ~36% al año vs ~7% del mensual).
- **Lifetime (pago único):** ~US$50-70. Es lo que más valoran los usuarios de Wallet y te distingue de la fatiga de suscripciones. Opcional pero recomendable.

Premium desbloquea: Cubo B ilimitado + todo el Cubo C.

### Formato de anuncios: rewarded ("anuncio grande") a demanda — no ambientales

**Decisión: solo anuncios recompensados (rewarded video) a demanda. Nada de banners ni interstitials en ninguna parte de la app.** Comparación:

| Formato | eCPM LatAm aprox. | Experiencia | Veredicto |
|---|---|---|---|
| **Rewarded video** ("anuncio grande") | ~$2-4 | Opt-in, el usuario lo elige por un beneficio claro | **Elegido** |
| Interstitial (pantalla completa entre vistas) | ~$1-2 | Intrusivo; Google penaliza colocaciones disruptivas | Descartado |
| Banner (fijo en pantalla) | ~$0.15 | Ensucia cada pantalla; pésimo en una app de finanzas | Descartado |

Dos razones: (1) **dinero** — el rewarded paga 15-25× más que un banner, así que los ambientales generan centavos mientras arruinan la UI; (2) **experiencia** — el rewarded es opt-in por diseño (Google *exige* que lo inicie el usuario), con intercambio de valor claro ("veo un video → 10 capturas"), y mantiene la app limpia para quien no quiere anuncios. Los anuncios "a lo largo de la app" recrearían justo la fricción que hace perder usuarios a AI Money y MonAi.

**Mecánica:** al tocar una feature bloqueada o agotar el cupo → *"Ver anuncio (desbloquea X) o Premium"*. Un video = un lote (p. ej. 10 capturas de IA, o los informes/gráficas avanzadas de esa sesión). Con *frequency capping* para no ofrecer videos sin parar. Nunca un anuncio forzado.

---

## 6. Stack técnico (Flutter)

| Capa | Elección recomendada | Por qué |
|---|---|---|
| Base de datos local | **Drift** (SQLite tipado) | **Fuente de verdad offline-first**: la app funciona sin conexión, con lecturas instantáneas y datos en el dispositivo (privacidad). La nube (Supabase) **respalda y sincroniza desde la etapa 0 para no perder datos**, pero local sigue mandando. Datos financieros son relacionales → SQL real, migraciones sólidas, export a CSV trivial |
| Sync y respaldo en nube | **PowerSync** (decidido) | Mantiene la SQLite local en sync bidireccional con Supabase Postgres, offline-capable, sin pérdida de datos. Integra con Drift. (Brick y sync custom quedan descartados) |
| Estado | **bloc / cubit** | Estado explícito y predecible (evento→estado), muy testeable, encaja bien con flujos financieros |
| Gráficas | **fl_chart** | Nativo Flutter, flexible, gratis |
| Anuncios | **google_mobile_ads** (AdMob) | Rewarded ads + UMP (consentimiento) integrado |
| Suscripciones/IAP | **RevenueCat** (`purchases_flutter`) | Multiplataforma, valida recibos, gestiona *entitlements*, precios regionales y analítica sin backend propio de billing |
| OCR en dispositivo | **google_mlkit_text_recognition** | Gratis, offline, alimenta la captura de recibos |
| Voz | **speech_to_text** | Audio→texto local y gratis; solo el parse va al LLM |
| Notificaciones bancarias (Android) | listener de notificaciones (p. ej. `flutter_notification_listener`) | Captura automática local, sin Plaid |
| Backend (BaaS, no artesanal) | **Supabase** (recomendado) o **Firebase** | No necesitas montar un servidor propio: las *funciones serverless* de cualquiera cubren el proxy al LLM (**nunca embebas la API key en la app**), el *caching*, el **enforcement de límites** y el endpoint de AdMob SSV |
| IA | Modelo económico (Claude Haiku / GPT-nano) con *prompt caching* + *batch* | Costo marginal en fracciones de centavo |

**Regla de oro de arquitectura:** nada que cueste dinero (llamadas al LLM) sale directo desde la app. Todo pasa por tu backend (Supabase Edge Functions o Firebase Cloud Functions), que (a) guarda la API key, (b) cachea, (c) cuenta el uso por usuario y aplica el límite, y (d) verifica los anuncios vía SSV antes de conceder features extra.

### ¿Backend propio, Supabase o Firebase?

No hace falta backend artesanal. Necesitas lado-servidor solo para cuatro cosas: ocultar la API key del LLM, contar/aplicar límites, recibir el SSV de AdMob, y la sync/respaldo de Premium. Ambos BaaS lo resuelven:

- **Supabase (recomendado para este caso):** es **Postgres relacional**, igual que tu SQLite local — el mismo modelo de datos a ambos lados hace la **sincronización mucho más simple**. Trae Auth, Row Level Security y Edge Functions (Deno) para el proxy/SSV/límites. Open-source y portable.
- **Firebase:** ecosistema muy integrado (Cloud Functions + Firestore + Auth). Ventaja concreta: **Remote Config** para ajustar límites y cupos **sin publicar nueva versión** de la app. Desventaja: Firestore es NoSQL y modelar datos financieros relacionales ahí es más incómodo (sync más artesanal).

Regla práctica: **Supabase** si priorizas que el modelo relacional calce con la BD local (lo más limpio para sync); **Firebase** si valoras el ecosistema y el ajuste de límites en caliente. Cualquiera integra con RevenueCat para validar suscripciones. **Decisión tomada: Supabase**, por el encaje relacional con Drift para el sync sin pérdida de datos.

### Sincronización y respaldo (desde la etapa 0)

Local (Drift) es la fuente de verdad; la nube respalda y sincroniza desde el inicio para **no perder datos**. El costo es bajo: son filas de texto diminutas (nada que ver con la agregación bancaria).

**Decisión: PowerSync.** SQLite local ↔ Supabase Postgres, bidireccional, offline-capable, reconcilia al reconectar, sin pérdida de datos por diseño. Tiene SDK Flutter oficial e integración con Drift (corres tus queries de Drift sobre la BD de PowerSync). Evita tener que escribir y mantener un motor de sync propio. (Brick y el sync custom quedan descartados.)

### Config remoto en Supabase (equivalente a Firebase Remote Config)

Supabase no tiene un producto de Remote Config, pero se replica fácil: una **tabla `remote_config` / `feature_flags` en Postgres** que la app lee al arrancar y cachea localmente. Cambias un límite o cupo con un UPDATE (sin republicar la app), y con **Supabase Realtime** los cambios se propagan **en vivo** a las apps abiertas. Para targeting avanzado (rollouts graduales, A/B, flags por segmento) se enchufa un servicio externo compatible con cualquier backend: **PostHog**, **Flagsmith** o **GrowthBook** (open-source), o **ConfigCat**. Para tunear límites/cupos, la tabla + Realtime es suficiente y gratis.

---

## 7. Modelo de datos (esbozo)

Tablas núcleo en Drift/SQLite:

- **accounts** (id, nombre, tipo, moneda, saldo_inicial, archivada)
- **categories** (id, nombre, icono, color, parent_id → subcategorías, tipo ingreso/gasto)
- **transactions** (id, account_id, category_id, monto, moneda, fecha, nota, tipo, origen [manual/voz/ocr/notificacion], recurring_id)
- **budgets** (id, category_id, periodo, monto, tipo)
- **goals** (id, nombre, monto_objetivo, monto_actual, account_id, fecha_meta)
- **debts** (id, nombre, tipo [debo/me deben], monto, tasa, pagos)
- **recurring** (id, plantilla de transacción, frecuencia, próxima_fecha)
- **tags** y tabla puente transaction_tags (opcional pero útil)

Diseña `transactions.source` desde el día 1: te permite medir cuánto se usa la captura por IA (para calibrar límites) y separar lo que te cuesta de lo que no.

> El esquema completo e implementado (con IDs UUID, `createdAt`/`updatedAt`, borrado lógico y enums) está en el archivo **`app_database.dart`** — listo para `build_runner` y para PowerSync.

---

## 8. Roadmap sugerido

**Fase 1 — Núcleo para ti + respaldo en nube.** Registro manual, cuentas, **transferencias entre cuentas**, categorías (con **categorías semilla + onboarding**), presupuestos, metas, deudas, set esencial de gráficas e informes, import/export CSV, **búsqueda y filtros**, recurrentes, multi-moneda (con **fuente de tasas FX**). **Cifrado local en reposo** (SQLCipher). **Respaldo/sync en la nube (Supabase + PowerSync) disponible desde el inicio para no perder datos**, pero **local-first**: el usuario puede usar la app sin cuenta y **el login se ofrece después** ("inicia sesión para respaldar y sincronizar"). Al iniciar sesión, se **fusionan sus datos locales** con la cuenta (PowerSync lo soporta). **Login solo social: en Android solo Google; en iOS Google + Sign in with Apple** (Apple exige ofrecer Apple por su guía 4.8 cuando das login de terceros; en Android no aplica). Como hay Auth, incluye el **borrado de cuenta dentro de la app** (obligatorio para Apple y Google; borra los datos en Supabase, no solo cierra sesión). **i18n (es/en) desde ya.** Sin IA ni anuncios todavía. Al terminar tienes una app que te sirve mejor que Wallet, con tus datos a salvo, y validas el modelo de datos.

**Fase 2 — Captura sin fricción local (gratis).** Voz (`speech_to_text`), OCR de recibos (`mlkit`), lectura de notificaciones bancarias en Android, **widget de captura rápida** y **recordatorios de vencimientos** (notificaciones locales). Aún sin costo para ti: el parse puede empezar con reglas locales antes de meter LLM.

**Fase 3 — Capa de mejora financiera (gratis, motor de retención).** Ritual de revisión semanal, "disponible para gastar" (safe-to-spend), rachas de registro, metas con hitos celebrados, retos de ahorro, alertas de presupuesto anticipadas y base-cero opcional. Todo local ($0) → fortalece el producto gratis antes de monetizar (mejores reseñas → mejor conversión luego).

**Fase 4 — Backend + IA + monetización.** Backend serverless con proxy al LLM, conteo de límites y SSV. Integra AdMob (rewarded) y RevenueCat (Premium mensual/anual/lifetime). Activa Cubos B y C, incluyendo **insights proactivos con IA** y **coach por chat** (Premium). Añade **analítica** (PostHog) para medir, y las **pantallas legales** de publicación (política de privacidad, disclaimer "no es asesoría financiera"; el borrado de cuenta ya viene de la Fase 1). Lanza el freemium.

**Fase 5 — Validar y ajustar.** Mide con `transactions.source` el uso real de IA, ajusta límites al percentil ~80, mide conversión (meta 2-5%) y retención. Solo entonces considera features mayores.

---

## 9. Riesgos y cómo mitigarlos

- **Que el anuncio no cubra el costo de la feature** → mantén el Cubo B en modelos baratos + caching + OCR/voz local; nunca pongas features caras en el Cubo B.
- **Usuarios que falsean "vi el anuncio"** → AdMob SSV obligatorio; conteo en servidor.
- **API key filtrada** → nunca en la app; siempre tras tu backend.
- **Plan gratis percibido como cebo** → mantén el Cubo A genuinamente completo e ilimitado; que el usuario sienta que podría no pagar nunca y aun así estar contento. Esa es la fuente de las buenas reseñas.
- **iOS sin lectura de notificaciones** → comunícalo claro; en iOS apóyate en voz, OCR y (si algún día) Apple Pay shortcuts.
- **Rechazo de Google Play por lectura de notificaciones bancarias** → el acceso a notificaciones/SMS está muy restringido por política de Google; declara y justifica el uso, y **no dependas solo de esa vía**: ten la captura por voz/OCR como alternativa por si no la aprueban.

---

## 10. Consideraciones que faltaban (producto, legal, técnico)

Revisión de completitud. Lo más urgente es lo legal, porque una app de finanzas se juega la publicación y la confianza ahí.

**Producto (completar el CRUD y la usabilidad):**
- Transferencias entre cuentas, búsqueda y filtros de transacciones, adjuntar foto del recibo, recordatorios de vencimientos (notificaciones locales), widget de captura rápida, onboarding con categorías semilla, y una fuente de tasas de cambio (FX) para el multi-moneda.

**Legal / cumplimiento (crítico para publicar y coherente con tu posicionamiento de privacidad):**
- **Política de privacidad** y cumplimiento de leyes de datos según país: LGPD (Brasil), Ley 1581 (Colombia), LFPDPPP (México), RGPD (España). Es requisito de las tiendas.
- **Riesgo de política de Google Play con la lectura de notificaciones bancarias** (ver Riesgos): declararlo, justificarlo y tener alternativa.
- **Borrado de cuenta (y exportación de datos) dentro de la app** — **obligatorio**: Apple lo exige desde 2022 y Google también, para toda app que permita crear cuenta. Debe borrar los datos del usuario en Supabase, no solo cerrar sesión. Constrúyelo junto con el Auth (Fase 1), no al final.
- **Disclaimer "esto no es asesoría financiera"** en la IA/coach, para no incurrir en responsabilidad.

**Técnico:**
- **Cifrado local en reposo** (SQLCipher / Drift cifrado) — coherente con "tus datos son tuyos" y esperable en datos financieros.
- **i18n** (español + inglés) desde el inicio, para no reescribir la UI después.
- **Analítica de producto** (PostHog o Firebase Analytics) — sin ella no puedes ejecutar la fase de validación (conversión, retención, embudos).
- **Estrategia de tests** (bloc facilita unit/bloc tests; añade tests de integración del sync con PowerSync).

---

*Los umbrales y precios son puntos de partida; ajústalos con tus costos reales de LLM y con las tasas de eCPM que observes en tu base. La arquitectura (límites server-side, IA barata tras backend, captura local gratis) es lo que hace que este modelo sea sostenible incluso con eCPM bajo de LatAm.*

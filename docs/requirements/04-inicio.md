# Feature: Inicio (Home / Dashboard + shell de navegación)

**Nivel:** 0 (gratis). El bloque de IA se muestra en estado "próximamente" y **no ejecuta IA** en esta fase, así que no rompe Nivel 0 (ver HU-06).
**Tabla Drift:** ninguna propia. El Home solo **lee y agrega** datos de `Accounts`, `Transactions`, `Budgets` (y `Categories`/`Goals` de forma indirecta).
**Ruta:** `/` (pantalla por defecto al abrir la app). Reemplaza el placeholder temporal `BootstrapHomePage` (`lib/core/router/bootstrap_home_page.dart`).
**Diseño (billetudo.pen):** composición aprobada = **variante A ("Lean / actividad primero")**. Pantalla base con presupuesto: frame `aOhoY`; estado **sin presupuesto** aprobado (invitación a crear presupuesto): frame `A9v7s`. El spec de pantalla está en `design-system/billetudo/pages/inicio.md`; este documento describe la intención funcional, el `.pen` es la fuente de verdad visual.

## Contexto

Es la **primera pantalla** que ve el usuario al abrir la app y el marco de navegación de toda la experiencia. Cumple dos roles:

1. **Dashboard accionable de un vistazo:** el gasto del mes (con o sin presupuesto) y la **actividad reciente** (movimientos de todas las cuentas), sin obligar a entrar a cada feature. El desglose por categoría **no** vive en el Home (decisión de composición): es una tarea de análisis más reflexiva que se accede desde Gráficas e informes (`10`).
2. **Shell de navegación:** el tab bar que reemplaza los botones temporales de `BootstrapHomePage` y da acceso al resto de la app.

Es **local-first**: funciona completo sin cuenta ni sincronización, leyendo directo de Drift. El login y el sync se ofrecen después y no son requisito para que el Home muestre datos (ver `05-auth-sync.md`).

## Historias de usuario

### HU-01 — Shell de navegación (tab bar)
Como usuario quiero una barra inferior siempre visible para moverme entre las secciones principales de la app.

**Criterios de aceptación:**
- Cinco destinos, en este orden: **Inicio**, **Movimientos** (Transacciones), **Presupuestos**, **Metas**, **Más**.
- **Inicio** es la pestaña por defecto al abrir la app.
- La pestaña activa se resalta (ícono + label en color de marca); las inactivas usan `text-secondary`.
- **Más** es un hub que agrupa el resto de destinos de Nivel 0: **Cuentas**, **Categorías**, **Deudas** (`08`), **Pagos programados** (`09`), **Gráficas e informes** (`10`), **Import/Export** (`11`) y **Ajustes/Cuenta** (moneda, borrado de cuenta, etc.).
- Reemplaza por completo a `BootstrapHomePage`; las rutas actuales (`/cuentas`, `/categorias`, …) se cuelgan del shell.
- Ninguna feature de Nivel 0 puede quedar inaccesible desde el shell (regla de Nivel 0).

### HU-02 — FAB para agregar transacción
Como usuario quiero un acceso rápido y siempre a mano para registrar un movimiento nuevo.

**Criterios de aceptación:**
- FAB flotante (abajo-derecha) sobre el Home que abre el formulario de nueva transacción (`03-transacciones.md`).
- **Se oculta al hacer scroll hacia abajo y reaparece al subir**, para no tapar contenido durante la lectura.
- Es el punto de entrada principal de captura manual; la captura de baja fricción (voz/OCR) se enruta desde el mismo flujo cuando exista.
- Registrar un movimiento es Nivel 0 (nunca detrás de anuncio ni pago).

### HU-03 — Resumen del mes (hero card)
Como usuario quiero ver de inmediato cuánto he gastado en el mes, funcione o no con presupuesto.

**Criterios de aceptación:**
- **Métrica principal (siempre presente):** "Gastado en `<mes>`" + monto total del **gasto** del mes en curso. Se calcula solo con transacciones, así que **no depende de que exista ningún presupuesto**.
- Monto en **centavos** (`amountMinor`), formateado en la moneda del usuario.
- El total **excluye** transferencias (`transfer`) y los movimientos ligados a deuda (`debtId`) que no son gasto real — coherente con `10-graficas-informes.md`.
- **Con presupuesto (estado `aOhoY`):** si existe un presupuesto **global** (`categoryId = null`) mensual vigente para el mes visto, se añade una barra de progreso "X% de tu presupuesto" + "faltan Y días".
- **Sin presupuesto (estado aprobado `A9v7s`):** en lugar de la barra, el hero **no inventa un tope**. Muestra una invitación a crear presupuesto: "Define un presupuesto para ver cuánto te queda este mes →". Racional: sin presupuesto la app no conoce un límite de gasto, así que no se finge uno; en su lugar se empuja suavemente el hábito de presupuestar (diferenciador de billetudo). El destino del enlace (formulario o bottom-sheet de Presupuestos) se define con `06-presupuestos.md`.
- Presupuestos globales no mensuales (semanal/anual/custom) y presupuestos por categoría **no** se representan en el hero; su progreso vive en la sección Presupuestos (`06`). Esto evita prorrateos engañosos en la tarjeta.
- Superar el presupuesto se comunica con tono neutral/de progreso, **nunca** avergonzando al usuario.

### HU-04 — Navegación por mes
Como usuario quiero cambiar el mes que estoy viendo, para revisar meses pasados.

**Criterios de aceptación:**
- Chip de mes (ej. "Julio ▾") en la hero card permite navegar entre meses (mes en curso y anteriores).
- Cambiar el mes actualiza de forma consistente el **hero (HU-03)** y los **movimientos recientes (HU-05)**.
- El mes por defecto es el mes en curso.
- El Home se ancla al **mes calendario** como unidad de navegación; los periodos flexibles de presupuesto (`BudgetPeriod` weekly/yearly/custom) se gestionan en la sección Presupuestos, no aquí.

### HU-05 — Movimientos recientes
Como usuario quiero ver mi actividad reciente apenas abro la app, para confirmar que lo que registré quedó bien y saber qué ha pasado con mi plata sin un click extra.

**Criterios de aceptación:**
- Lista los movimientos más recientes **de todas las cuentas activas**, en un solo feed agregado (no filtrado por una cuenta).
- **Excluye** cuentas archivadas / con lápida (`tombstonedAt`) y transacciones eliminadas (`deletedAt`) o con lápida.
- Muestra ~**5 filas** (`Transaction Row`), cada una con: ícono/color de la categoría, descripción, "cuenta · fecha" y monto. Gasto en tono neutro (`text-primary`), ingreso en verde (`income`), **nunca** gasto en rojo.
- Es un **feed de actividad**, no un cálculo de gasto: puede incluir income, expense y transfer tal como ocurrieron. (A diferencia del total del hero en HU-03, que sí excluye transfers y deuda.)
- Ordenado por fecha descendente (más reciente arriba).
- Header de sección "Movimientos recientes" + enlace "Ver todos →" que lleva a la pestaña **Movimientos** (lista completa).
- El detalle por categoría **no** está aquí; vive en Gráficas e informes (`10`).

### HU-06 — Asistente de IA ("Próximamente")
Como usuario quiero saber que podré preguntarle a Billetudo sobre mi plata en lenguaje natural.

**Criterios de aceptación:**
- Se muestra un **banner de una línea "Pronto: pregúntale a Billetudo →"** (componente `bziZm`) **directamente debajo de los movimientos recientes** (no anclado al fondo: allá abajo se pierde y compite con el FAB), en estado **"próximamente"**. (La tarjeta completa `yTLHY` se conserva en el archivo para cuando la IA se habilite, pero no se usa en el Home de esta fase.)
- **Al presionar el banner** se muestra una alerta / bottom-sheet: **"Próximamente estará disponible"**. En esta fase **no ejecuta IA** ni llama a ningún backend.
- Al no ejecutar IA, no consume cupos ni requiere desbloqueo, por lo que **no viola Nivel 0**.
- Cuando la IA se habilite, aplicará el modelo de `CLAUDE.md`: modelos detrás de backend (Supabase Edge Functions), la app nunca llama al LLM directo, acceso vía rewarded ads opt-in (cupo mensual, validado en servidor) o Premium, recompensas verificadas con AdMob SSV, y disclaimer **"no es asesoría financiera"** en toda salida.

### HU-07 — Encabezado con saludo
Como usuario quiero un saludo personal al abrir la app, para sentirla mía.

**Criterios de aceptación:**
- Avatar (inicial o foto) + "Hola de nuevo, `<nombre>`".
- **Sin cuenta / sin sync**: el nombre sale de un valor local o es un saludo genérico; nunca bloquea el Home ni empuja al login de forma intrusiva.
- Ícono de campana (notificaciones) a la derecha: **se mantiene visible** y al presionarlo muestra un aviso "Próximamente" (aún no existe centro de notificaciones).
- Tono positivo, nunca punitivo (regla de marca).

### HU-08 — Estado vacío
Como usuario nuevo (sin transacciones en el mes) quiero un Home que me oriente en vez de mostrar puros ceros muertos.

**Criterios de aceptación:**
- Hero en `$0` (o "Aún no hay gastos este mes") sin barra de presupuesto ni dato engañoso.
- Bloque "Movimientos recientes" en estado vacío ("Aún no registras movimientos") con un CTA/apoyo al FAB (HU-02) para registrar el primero.
- Tono de bienvenida, positivo.

### HU-09 — Estado de carga
Como usuario quiero feedback mientras se hidratan los datos.

**Criterios de aceptación:**
- Skeletons en hero y en la lista de movimientos recientes (variante de carga).
- Al ser local-first, la carga desde Drift es breve; el skeleton cubre el primer frame y/o la hidratación tras un sync.

### HU-10 — Robustez offline / error de sync
Como usuario quiero que el Home funcione aunque no haya internet o falle el sync.

**Criterios de aceptación:**
- Los datos del Home vienen de Drift (fuente de verdad local): **sin conexión el Home sigue mostrando todo**.
- Un error de sincronización **no rompe ni vacía** el Home. Se comunica con un **indicador discreto de estado de sync**; no hay banner intrusivo ni pantalla de error dedicada.

### HU-11 — Tema claro y oscuro
Como usuario quiero que el Home respete el tema del sistema/app.

**Criterios de aceptación:**
- Soporta claro y oscuro (el tema oscuro se genera al final del flujo de diseño).
- Todos los colores desde variables del `.pen`; ningún hex hardcodeado.

## Reglas de negocio y edge cases

- **Solo lectura/agregación:** el Home no crea ni edita datos de negocio directamente; la única acción de escritura que dispara es abrir el formulario de nueva transacción vía el FAB (HU-02).
- **Movimientos recientes = todas las cuentas activas:** el feed agrega transacciones de todas las cuentas no archivadas / sin lápida (HU-05). No se filtra por cuenta en el Home.
- **El desglose por categoría NO vive en el Home:** decisión de composición (variante A). Se accede desde Gráficas e informes (`10`).
- **Dinero siempre en centavos** (`amountMinor`), nunca `double`.
- **Coherencia de totales con `10-graficas-informes.md`:** el **total de gasto del hero** excluye `transfer` y movimientos con `debtId`; el Home y las gráficas deben dar el mismo número para el mismo mes. (El feed de movimientos recientes, en cambio, es actividad literal e incluye transfers.)
- **Nivel 0 intacto:** todos los bloques funcionan sin anuncio ni pago. El bloque de IA está en "próximamente" y no ejecuta nada. Nada de banners ni interstitials ambientales.
- **Tono:** positivo y de progreso; jamás avergonzar por el gasto, incluso al superar el presupuesto.
- **Textos solo desde `AppLocalizations`** (es + en); prohibido hardcodear strings de UI (`avoid_hardcoded_ui_strings`).
- **Local-first:** el Home no exige cuenta; saludo, totales y movimientos se calculan sobre datos locales.

## Dependencias con otras features

El Home es principalmente una **vista de composición** que agrega datos de otras features. Cada bloque depende de que la feature fuente exista:

| Bloque del Home | Fuente / doc |
|---|---|
| Shell / tab bar (HU-01) | Reemplaza `BootstrapHomePage`; enruta a todas las features |
| FAB agregar movimiento (HU-02) | `03-transacciones.md` |
| Gasto del mes (HU-03) | `03-transacciones.md`, `01-cuentas.md` |
| Barra / invitación de presupuesto (HU-03) | `06-presupuestos.md` |
| Movimientos recientes + "Ver todos" (HU-05) | `03-transacciones.md`, `01-cuentas.md`, `02-categorias.md` |
| Asistente de IA (HU-06) | Backend de IA + monetización (`CLAUDE.md`) — hoy solo "próximamente" |
| Menú "Más" (HU-01) | `01`, `02`, `08`, `09`, `10`, `11`, Ajustes/Cuenta |

## Estado del diseño

Diseño **completo y aprobado** en `billetudo.pen` (claro + oscuro), spec en `design-system/billetudo/pages/inicio.md`:
- Composición (variante A), estados (con/sin presupuesto, vacío, carga) — 8 frames.
- Interacciones: selector de mes (HU-04), sheets "Próximamente" IA + notificaciones (HU-06/HU-07), indicador discreto de sync en el header (HU-10) — en ambos temas.
- Comportamiento de scroll del FAB (HU-02) documentado (sin frame propio).
- Token temático `skeleton` añadido para el contraste de los skeletons en tema oscuro.

## Estado de implementación

**Implementado en Flutter** (`lib/features/home/`, rama `feature/inicio-home`): shell de 5 tabs, hero (estado sin presupuesto), movimientos recientes, selector de mes, banner de IA y campana "próximamente", header con saludo y avatar, estados vacío/carga, FAB con auto-hide. Cobertura unit + widget + e2e Patrol del shell en verde. Detalle en `docs/dev-runs/inicio-home.md`.

## Pendiente (bloqueado por dependencias externas — NO perder)

Estos dos bloques quedan **estructurados pero sin cablear** en el Home porque dependen de features que aún no existen. El código los deja listos para conectar sin rediseño:

1. **Barra de progreso de presupuesto en el hero (HU-03, estado "con presupuesto", frame `aOhoY`).** Hoy el hero solo muestra el estado **sin presupuesto** (invitación a presupuestar). La barra "X% de $Y · faltan Z días" requiere la feature **Presupuestos (`06-presupuestos.md`)**: leer el presupuesto global mensual vigente (`categoryId = null`) del mes visto y calcular el progreso contra el gasto del mes. Cuando exista Budgets: añadir un segundo estado al `HomeHeroCard` (la estructura ya lo contempla) y alimentarlo desde un caso de uso de Presupuestos. **No inventar un tope mientras tanto.**
2. **Indicador de sync con estados reales (HU-10).** El header ya renderiza el indicador pasivo, pero hoy está **fijo en `HomeSyncStatus.synced`**. Los 3 estados reales (Sincronizado / Sincronizando / Sin conexión) requieren **PowerSync cableado** (ver `05-auth-sync.md`): exponer el estado de sync como stream y mapearlo a `HomeSyncStatus` en el `HomeCubit`/header. Es local-first: offline nunca alarma ni vacía el Home.

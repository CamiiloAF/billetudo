# Página: Auth (Login / invitación a respaldar en la nube)

Sobreescribe/complementa `design-system/billetudo/MASTER.md`. Fuente real: `billetudo.pen`.

**Estado:** **Auditoría de cierre completa (2026-07-16, `ui-ux-reviewer`) — aprobada con hallazgos menores documentados, ninguno bloqueante.** Las 7 historias de usuario (HU-01 a HU-07) están cubiertas sin gaps: Login Android/iOS, confirmación de fusión, cerrar sesión y borrado de cuenta en 3 pasos tienen ambos temas; Ajustes (punto de entrada) tiene tema claro, pendiente el oscuro junto con el resto de la app. `Illustration/Device Preview` ya está componentizado (`a0FOYN`, reusable) — el hallazgo que lo pedía se resolvió y su nota se retiró del canvas. El contraste del Skip Link (`Continuar sin cuenta`) ya usa `$primary-on-soft-strong` en las 6 instancias — hallazgo resuelto, notas retiradas. Cubre el flujo completo de Auth + Sync descrito en `docs/requirements/05-auth-sync.md`.

## Contexto de producto

Local-first estricto: la app es 100% usable sin cuenta (HU-01). La pantalla de Login **nunca** es un gate de entrada — es una invitación opcional a respaldar/sincronizar que el usuario puede cerrar o posponer en cualquier momento ("Continuar sin cuenta"). Al iniciar sesión, los datos locales existentes se fusionan con la cuenta (HU-04), sin pérdida. Auth es solo social: Android → solo Google; iOS → Google + Sign in with Apple.

## Frames

| Pantalla / pieza | Node ID (Claro) | Node ID (Oscuro) | Estado |
|---|---|---|---|
| Auth — Respaldo D: Centrado (Android, **ganadora**) | `fTetG` | `eCMut` | Decisión final, ambos temas |
| Auth — Respaldo D: Centrado (iOS, **ganadora**) | `RSzD1` | `DFlXI` | Decisión final, ambos temas — misma estructura que `fTetG`, solo difiere Status Bar/iOS y Apple visible |
| Auth — Fusión de datos (HU-04, **ganadora**) | `vexqA` | `V5NA1` | Decisión final, ambos temas — mismo lenguaje centrado que Login |
| Auth — Cerrar sesión (HU-06, **ganadora**) | `j4hgYN` | `MDDdY` | Decisión final, ambos temas — Bottom Sheet, sigue el patrón obligatorio de MASTER |
| Auth — Borrar cuenta, paso 1: confirmación irreversible (HU-07) | `j8ZdEx` | `QOJ74` | Decisión final, ambos temas — Bottom Sheet, tono destructivo |
| Auth — Borrar cuenta, paso 2: datos locales (HU-07) | `K8SAG` | `jxqEb` | Decisión final, ambos temas — Bottom Sheet, elección sin dark pattern |
| Auth — Borrar cuenta, paso 3: confirmación final (HU-07) | `sqm4I` | `q43mHJ` | Decisión final, ambos temas — pantalla completa, cierre neutral |
| Ajustes — sin sesión | `jDaUb` | `j4JYF` | Decisión final, ambos temas. Punto de entrada a Login. |
| Ajustes — con sesión | `aaQBp` | `TQHmY` | Decisión final, ambos temas. Sin "Cerrar sesión" (se movió a "Más", ver abajo) — termina en la fila "Eliminar cuenta" rediseñada. |
| Más (nueva, destino de la pestaña "Más" del Tab Bar) | `gXcHt` | `X9x7x` | Decisión final, ambos temas. Lista Cuentas/Categorías/Deudas/Recurrentes/Import-Export/Ajustes + "Cerrar sesión" al final. |
| Borrar cuenta, paso 1 — estado de error | `T1YkkA` | — | Solo claro, referencia de patrón |
| Login Android — estado de carga | `QD8kh` | — | Solo claro, referencia de patrón |
| Login Android — estado de error | `JA0KD` | — | Solo claro, referencia de patrón. Snackbar anclado a 16px del `Sign-in Buttons Group` (mismo margen que el patrón de "Snackbar Undo" en Movimientos), no flotando a mitad de pantalla. |

**Las 7 pantallas del flujo de Auth ya tienen ambos temas.** Ajustes (nueva, ver abajo) solo tiene claro por ahora — se generará su oscuro en la misma pasada que el resto de pantallas de la app que todavía no lo tienen.

**Tratamiento de marca en oscuro:**
- **Botón de Google**: no necesitó ajuste manual — `Button/Google` (`FJ4Yl`) usa 100% variables (`$surface`/`$border`/`$text-primary`), así que el tema oscuro lo recolorea automáticamente a un estilo oscuro sólido con buen contraste, razonablemente cercano al estilo `dark` oficial de Google. El logo "G" de 4 colores es fijo por diseño (marca) y no cambia con el tema.
- **Botón de Apple**: su fill fijo `#000000` sobre `$background` oscuro (`#14141F`) da ~1.1:1 de contraste — casi indistinguible. Se corrigió agregando `stroke:"$border"` **solo en la instancia dentro de `DFlXI`** (única pantalla con Apple visible en oscuro; en Android sigue oculto). El componente base `Button/Apple` (`ZhTnN`) no se tocó — si se agrega otra pantalla con Apple visible en oscuro, aplicar el mismo override de borde ahí.
- **`Illustration/Device Preview`**: se ve bien en oscuro sin ajustes, todos sus fills son variables.

Los dos frames de Login son la misma composición (ilustración Device Preview centrada, texto centrado, mismo copy) — la única diferencia es la plataforma: Status Bar y el modo del `Auth/Sign-in Buttons Group` (Android = solo Google, iOS = Apple + Google).

**Historial de variantes exploradas** (regla de MASTER: no dejar variantes a medias en el canvas — todas ya fueron eliminadas del `.pen`, ninguna sobrevive salvo las 3 ganadoras de arriba):
- **Variante A — Hero simple** (`z33Vg`, Android / `I4f2J`, iOS, ambas eliminadas): centrada, ícono en círculo 96px, 2 filas de beneficio en texto. Fue la ganadora original, luego reemplazada por D (asimétrico) tras una segunda ronda de exploración.
- **Variante B — Bottom Sheet rápido** (`haWfH`, eliminada): overlay tipo `Bottom Sheet Base`.
- **Variante C — Tarjeta editorial** (`RdrCi`, eliminada): Hero Card con gradiente + Benefits Card separada.
- **Variante E — Preview de dispositivos** (`SRfig`, eliminada): mockup de 2 teléfonos + badge de sync, layout centrado. Su ilustración (`Device Preview`) fue reutilizada/adaptada dentro de D.
- **Variante "D asimétrica"** (`OfAgW`/`z0by7`/`ZBLtO`, todas eliminadas): fue la decisión ganadora durante varias rondas — ilustración y texto alineados a la izquierda, compartiendo un borde común. Se probó centrar solo el texto (`z0by7`) y solo la ilustración (`ZBLtO`) por separado; ambas se descartaron porque centrar una sola pieza mientras la otra seguía asimétrica generaba "dos anclas visuales compitiendo". **Finalmente se revirtió la decisión completa** — ver "Decisión de diseño" abajo, la versión centrada final (`fTetG`) centra ilustración Y texto JUNTOS sobre el mismo eje, lo que sí resuelve el problema que mató a los intentos parciales.
- **Confirmación de fusión, versión asimétrica** (`V0YiG`, eliminada): fue la decisión ganadora de HU-04 durante una ronda, alineada a la izquierda para ser consistente con el Login asimétrico de ese momento. Reemplazada por `vexqA` al revertirse la decisión de alineación.

## Estructura (`fTetG` Android / `RSzD1` iOS, misma composición)

De arriba a abajo, dentro de `Content` (`height:fill_container`, sin `Page Header` ni `Tab Bar` — ver Navegación):

1. **Status Bar** (`vYZJT` Android / `YX2tK` iOS).
2. **Top Bar**: botón de cerrar (`x`, 44x44, `fill:$muted`) alineado a la derecha — permite posponer la invitación sin fricción, coherente con "nunca bloquea el acceso" (HU-01).
3. **Middle** (`justifyContent:center`, `alignItems:center`, `height:fill_container`):
   - **Ilustración** (`Device Preview`, ~248x160 de contenido dentro de un bloque de 350px): mockup simplificado de 2 "teléfonos" superpuestos (uno atrás con fragmento simulado de cuenta/transacción, uno adelante con monto destacado en `$primary`) conectados por un badge circular `$primary`/`$on-primary` con ícono `refresh-cw` — comunica sincronización multi-dispositivo visualmente en vez de con texto. **Centrada**: los 3 hijos absolutos (Phone Back, Phone Front, Sync Badge) están desplazados +35px en X respecto a la posición original asimétrica, de forma que el centro visual de la composición cae exactamente en el centro del bloque de 350px.
   - **Text Group** (`alignItems:center`, `textAlign:center`): titular **"Nunca pierdas tu progreso"** (28px/**700** — no 800; MASTER reserva 800 para montos tipo Hero, no para titulares) + subtítulo "Un respaldo automático de tus cuentas y movimientos, listo para cuando lo necesites." (`$text-secondary`).
   - **Trust Row**: fila horizontal (`alignItems:center`, `gap:8`) centrada como grupo dentro de su contenedor (`alignItems:center` en el padre) — ícono `shield-check` (lucide, 24px, `$primary`) a la izquierda + texto **"Usa la app desde cualquier celular sin perder tu historial"** (`$text-secondary`, 13px/600, `textAlign:center`) a la derecha. **Corrección 2026-07-16 (auditoría `ui-ux-reviewer`):** esta sección documentaba antes una variante vertical (ícono `phone` arriba, texto debajo) que ya no coincide con `billetudo.pen` — el archivo real usa la fila horizontal descrita arriba, centrada como bloque completo por el padre (`Trust Row` wrapper, `layout:vertical`, `alignItems:center`), lo cual evita el problema original (texto centrado solo en el espacio restante) sin necesitar el layout vertical. Documento corregido para reflejar el `.pen`, que manda (ver regla de MASTER.md).
4. **Bottom**: instancia de `Auth/Sign-in Buttons Group` (ver "Componentes" abajo), configurada en modo solo-Google (Apple oculto) + Skip Link "Continuar sin cuenta".

**Estados de loading/error** (referencia solo sobre Android claro, `fTetG` — no se hizo para iOS ni oscuro):
- **Loading** (`QD8kh`): tras tocar "Continuar con Google", el botón cambia su contenido a `loader-2` + "Conectando con Google…", mismo tamaño/radio/borde que el botón normal. En Flutter: mismo contenedor con `CircularProgressIndicator` reemplazando el contenido cuando `isLoading==true`; el ícono debe animarse (en Pencil es estático).
- **Error** (`JA0KD`): botón de Google vuelve a su estado normal + `Snackbar` (`zSTlU`) flotando sobre el contenido con "No pudimos iniciar sesión con Google" y acción "Reintentar". En Flutter usa `ScaffoldMessenger`/`SnackBar` nativo — no repliques la posición exacta del mockup.

## Estructura (`vexqA`, confirmación de fusión — HU-04)

Aparece justo después de un login exitoso donde había datos locales que fusionar. Comparte el **mismo lenguaje centrado que Login** — consistencia de layout entre las pantallas del flujo de Auth, no cada pantalla con su propia alineación.

1. **Status Bar** (Android; sin botón de cerrar — esta pantalla no es descartable como Login, es una confirmación automática post-login).
2. **Middle** (`justifyContent:center`, `alignItems:center`):
   - **Ilustración** (copia del mismo `Device Preview` de Login, centrada igual, con el ícono del badge cambiado de `refresh-cw` a `check`): reutiliza el mockup de 2 teléfonos para dar continuidad narrativa "antes (sincronizando) → después (sincronizado)" con Login.
   - **Text Group** (`alignItems:center`, `textAlign:center`): titular "Tus datos están a salvo" + subtítulo "Combinamos todo lo que ya tenías guardado con tu cuenta. Nada se perdió en el camino."
   - **Stats Card** (`$surface`, borde, 3 columnas con separadores `$border`, centrada internamente): evidencia concreta de la fusión — conteos de Cuentas / Movimientos / Categorías, valores en `$primary-on-soft` (no `$primary` crudo — ver nota de contraste abajo) 22px/**700** (no 800, reservado para montos). Con el resto del bloque ya centrado, la Stats Card comparte el mismo eje visual en vez de chocar con un titular alineado a la izquierda (problema real que tenía la versión asimétrica anterior, detectado por `ui-ux-reviewer`).
3. **Caption** ("Tus dispositivos se mantendrán sincronizados automáticamente", `$text-secondary`, `textAlign:center`) entre la Stats Card y el CTA.
4. **CTA**: `Button/Primary` "Ir a mis finanzas" + ícono `arrow-right`, `width:fill_container`.

**Nota de contraste:** los valores de la Stats Card usan `$primary-on-soft` (no `$primary` puro) — en tema claro son visualmente idénticos, pero `$primary` puro sobre `$surface` cae a ~3.00:1 en tema oscuro (falla texto normal), mientras `$primary-on-soft` está calibrado para pasar en ambos temas. Aplica este mismo criterio a cualquier valor numérico destacado que se agregue después en esta pantalla o en Login.

## Estructura (`j4hgYN`, cerrar sesión — HU-06)

Se dispara desde un botón "Cerrar sesión" en Ajustes/Configuración (pantalla que todavía no existe — punto de entrada futuro). Es un **Bottom Sheet**, no una pantalla completa ni un diálogo modal centrado: `MASTER.md` establece Bottom Sheet como patrón **obligatorio** para confirmaciones en mobile, y todo el precedente existente (Confirmar Eliminar, Confirmar Archivar, Confirmar Cambio, No se Puede Eliminar, todos en Cuentas) lo sigue sin excepción. Se probó una variante de diálogo centrado (`jpOWk`) solo para comparar y se descartó de inmediato por romper esa convención sin justificación.

Instancia de `Bottom Sheet Base` (`PqTUt`) con el `Content Slot` reemplazado:
- **Icon Circle** (56px, `$primary-soft`) + ícono `log-out` (26px, `$primary-on-soft`) — mismo tratamiento no alarmante que "Confirmar Archivar", NO el rojo/`$expense` de "Confirmar Eliminar" (cerrar sesión no es una acción destructiva).
- **Título**: "Cerrar sesión".
- **Mensaje**: "Tus cuentas y movimientos seguirán guardados en este dispositivo, no se borran. Pero los cambios que hagas aquí después no se sincronizarán hasta que vuelvas a iniciar sesión." — cubre las dos garantías de HU-06 (datos locales intactos + advertencia de no-sync) en tono neutral.
- **`Sheet Buttons Row`** (`Ot4yI`): "Cancelar" (`Button/Secondary`, ícono `x` oculto) / "Cerrar sesión" (`Button/Primary`, ícono `log-out`).

## Estructura (borrar cuenta — HU-07, flujo de 3 pasos)

La pantalla más sensible del flujo: requisito legal obligatorio de Apple/Google (borrado de cuenta dentro de la app). Se dispara desde Ajustes/Cuenta (pantalla que todavía no existe, mismo pendiente de punto de entrada que el resto de Auth). A diferencia de "Cerrar sesión" (tono neutral, `$primary-soft`/`log-out`), este flujo usa el tono **destructivo** ya establecido en "Confirmar Eliminar" de Cuentas (`$expense`/`$expense-soft`) — es una acción irreversible, no una acción de rutina.

**Paso 1 — Confirmación irreversible** (`j8ZdEx`, Bottom Sheet): Icon Circle `$expense-soft` + ícono `triangle-alert` (`$expense`). Título "Eliminar tu cuenta". Mensaje explícito de irreversibilidad y alcance: "cuentas, movimientos, categorías y todo lo demás asociado a tu cuenta" se borran de la nube. `Sheet Buttons Row`: "Cancelar" (`Button/Secondary`) / "Eliminar cuenta" (`$expense` + ícono `trash-2`).

**Paso 2 — Datos locales** (`K8SAG`, Bottom Sheet): título "¿Qué hacemos con tus datos en este teléfono?", subtítulo aclara que la cuenta en la nube ya se eliminó — esto es solo sobre el dispositivo actual. Dos filas de opción con **igual peso visual, ninguna preseleccionada** (radio vacío en ambas, mismo `$border`/`$surface`) — cumple explícitamente la regla de no-dark-pattern de HU-07 (el usuario debe elegir conscientemente, nunca una opción disfrazada de default):
- "Conservar mis datos en este dispositivo" — sigue usando billetudo sin cuenta.
- "Borrar también los datos de este dispositivo" — se elimina todo el historial local.
CTA único "Continuar" (`Button/Primary`) — deshabilitado (`opacity:0.4`, mismo patrón ya usado en Cuentas) hasta que el usuario seleccione una opción; el mockup muestra el estado disabled como referencia aparte (`GamyH` claro / `Fqpgc` oscuro), no como frame completo. El radio seleccionado usa anillo + punto interior en `$primary` (mockup de referencia con "Conservar mis datos" preseleccionado como ejemplo — en producción ninguna va preseleccionada).

**Paso 3 — Confirmación final** (`sqm4I`, pantalla completa, mismo lenguaje centrado que Login/Fusión): Icon Circle `$primary-soft` + `check`. Titular "Listo, tu cuenta fue eliminada" + subtítulo que **solo habla de la nube** ("Ya no tenemos ningún dato tuyo en la nube. Puedes seguir usando billetudo cuando quieras, con o sin cuenta.") — deliberadamente no menciona qué pasó con los datos locales, para que el copy no se sienta falso sin importar cuál opción se eligió en el paso 2. CTA "Ir al inicio". Se decidió construir una pantalla completa en vez de un snackbar/toast: es el cierre de una acción legal irreversible, merece confirmación explícita que no se pueda perder por accidente.

**Paso 1 — estado de error** (`T1YkkA`, Bottom Sheet, solo claro): para cuando falla la llamada al Edge Function que borra los datos en Supabase. Tono **neutral** (`$muted`/`$text-secondary`, ícono `wifi-off`), NO el rojo/`$expense` del paso 1 normal — esto ya no es la advertencia de irreversibilidad, es un fallo técnico. Título "No pudimos eliminar tu cuenta", mensaje aclara que los datos siguen a salvo localmente. Botones "Cancelar" / "Reintentar" (`refresh-cw`).

**Pendientes específicos de este flujo:**
- No hay estado de loading intermedio ("Eliminando...") entre confirmar el paso 1 y ver éxito o error — evaluar si hace falta antes de implementar, dado que el borrado en Supabase es síncrono (HU-07).

## Estructura (`jDaUb` sin sesión / `aaQBp` con sesión, pantalla de Ajustes)

Se llega desde la fila "Ajustes" de la pantalla "Más" (ver siguiente sección) — resuelve el pendiente de navegación. Pantalla completa con `Page Header` (`Dtm0X`: back + título "Ajustes"), 2 estados según sesión:

1. **Sección "Cuenta y respaldo"**:
   - **Sin sesión** (`jDaUb`): fila `Appearance Field` (`R8PlN`) reusada como invitación — ícono `cloud-upload`, "Respaldar en la nube", "Guarda tus datos de forma segura" → navega a Login (`fTetG`).
   - **Con sesión** (`aaQBp`): `Session Card` (`$surface` + borde) con avatar iniciales sobre degradado `$primary`→`$primary-deep`, nombre + "Sesión iniciada con Google" (placeholder — viene de los datos reales de la sesión al implementar). Ya **no** incluye "Cerrar sesión" — se movió a la pantalla "Más" (decisión del usuario: acción de nivel superior, más fácil de encontrar que anidada en Ajustes).
2. **Sección "Preferencias"**: 2 filas `Appearance Field` reusadas — "Apariencia" (estático por ahora, no hay selector diseñado) y "Moneda" (navega al `Selector de Moneda` ya existente en Cuentas, `rCY7Q`).
3. **Spacer** (`fill_container`) empuja la zona destructiva al fondo real de la pantalla.
4. **Eliminar cuenta** (`hRVfo` "Eliminar Cuenta Row", reemplaza al `Delete Link` original tras feedback de que el link de texto plano no se veía bien): fila completa con tap target de 44px+padding, fondo `$expense-soft`, icon-wrap circular `$surface` con ícono `trash-2` en `$expense`, label "Eliminar cuenta" en `$expense-text` 15px/600, chevron `$expense-text` → navega al flujo de borrado (`j8ZdEx`). Se siente como una acción real con jerarquía apropiada, no un link perdido, sin dejar de estar claramente separada de las opciones normales.

Componentes reusados: `Page Header` (`Dtm0X`), `Appearance Field` (`R8PlN`, 3 instancias). `hRVfo` no es `reusable:true` (única instancia); el `Delete Link` original (`u0THG`) sigue existiendo y en uso en Detalle de Transacción — no se tocó, solo se dejó de usar aquí.

**Pendientes específicos de Ajustes:**
- Solo existe tema claro — se genera el oscuro en la misma pasada que el resto de pantallas de la app que aún no lo tienen.
- Nombre/avatar del usuario son de ejemplo ("Camila Agudelo") — vienen de la sesión real de Google/Apple al implementar.
- La fila "Apariencia" no tiene un selector diseñado todavía (bottom sheet o pantalla para elegir claro/oscuro/sistema) — pendiente si se decide exponer esa opción.

## Estructura (`gXcHt`, pantalla "Más")

Destino de la pestaña "Más" del Tab Bar (`u3b5s9`) — no existía, se construyó para resolver el pendiente de navegación de toda la feature. Agrupa los destinos que no caben en el tab bar (regla de `CLAUDE.md`). Header de texto simple "Más" (24px/700, sin back — es una pestaña raíz, no una pantalla apilada; no usa `Page Header`, mismo patrón que el resto de pestañas raíz del Tab Bar), Tab Bar al fondo con "Más" activo.

1. **6 filas de navegación**, instancias de `Appearance Field` (`R8PlN`), cada una ícono + label + sublabel descriptivo + chevron: Cuentas, Categorías, Deudas, Recurrentes, Importar y exportar, **Ajustes** (→ `jDaUb`/`aaQBp` según sesión).
2. **Spacer** (`fill_container`).
3. **Cerrar sesión** (reconstruida a mano replicando la fila que antes vivía en Ajustes: icon-wrap `$primary-soft`/`log-out`, tono neutral) → navega al Bottom Sheet `j4hgYN`. Vive aquí, no en Ajustes, por ser una acción de nivel superior que el usuario debe poder encontrar sin entrar a Ajustes primero.

**Pendientes específicos de "Más":**
- Solo tema claro.
- Si "Cerrar sesión" llega a repetirse en un tercer lugar del `.pen`, componentizarla (`reusable:true`) — hoy es una única instancia manual.
- Navegación de Inicio → "Más" ya está resuelta (pestaña del Tab Bar), pero no se verificó si además debería existir un acceso directo desde Inicio (ej. ícono de perfil) — no estaba en alcance.

## Botones de login — reglas de marca (no negociables)

Google y Apple publican guías oficiales de branding para sus botones de "Sign in" y **no se pueden improvisar** (ni recolorear libremente ni sustituir el logo por texto/placeholder) — son requisito de sus programas de developer y de revisión de tienda:

- **"Sign in with Google"**: seguir las [Google Identity branding guidelines](https://developers.google.com/identity/branding-guidelines). Usar el asset oficial del logo "G" multicolor (no un placeholder de texto con un solo color), en uno de los estilos aprobados (`light`/`neutral`/`dark`, variante `full`/`icon`). Para el tema claro de billetudo, estilo `neutral` (fondo blanco/`$surface`, borde gris, texto `#1F1F1F` o equivalente) es el que más se acerca al resto del sistema. Alto mínimo 40dp/44pt, radios y tipografía siguen la guía oficial, no `$primary` ni la tipografía Plus Jakarta Sans del resto de la app — el botón de Google es una excepción documentada a la identidad visual de billetudo, exigida por Google.
- **"Sign in with Apple"** (solo iOS): seguir las [Apple Human Interface Guidelines para Sign in with Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple). Usar el botón oficial (`ASAuthorizationAppleIDButton` en iOS nativo; en Flutter, el paquete de Apple sign-in trae el widget/asset correspondiente) con el logo oficial y uno de los estilos aprobados (`black`/`white`/`white-outline`). Debe tener **visibilidad igual** a Google (mismo tamaño, mismo orden de prioridad visual, no un link secundario más pequeño) — regla explícita de HU-03 y de la guía 4.8 de App Store. **Nunca** recrear el glifo con una icon font de terceros en el código de producción, aunque el mockup en Pencil use `phosphor:apple-logo-fill` como aproximación visual.
- Ambos botones **nunca** llevan el color `$primary` de la marca ni la tipografía Plus Jakarta Sans — ambas guías de terceros tienen precedencia sobre `MASTER.md` en este punto específico (excepción documentada).
- **Desbalance visual Apple/Google en iOS — decisión aceptada, no defecto.** Con ambos botones al mismo tamaño exacto (350x50px, mismo padding/ícono/tipografía), el relleno negro sólido de Apple pesa visualmente más que el blanco+borde de Google. Se evaluó cambiar Google a su estilo `dark` para emparejar el peso, pero se decidió mantener `neutral` (igual que en Android) y aceptar la asimetría de peso: el requisito literal de HU-03 / guideline 4.8 de Apple es paridad de **tamaño y prioridad de orden**, no de peso visual idéntico entre marcas con identidades de color opuestas por diseño. No marcar esto como hallazgo en futuras auditorías de `ui-ux-reviewer`.
- **ADVERTENCIA — riesgo de rechazo en App Store Review:** ningún ícono de una icon font de terceros (Phosphor, Lucide, Material Symbols, etc.) es el asset oficial de Apple. La implementación real en Flutter **DEBE** usar el paquete oficial `sign_in_with_apple` (o el widget nativo `ASAuthorizationAppleIDButton` vía su integración Flutter), que trae el glifo exacto certificado por Apple con las proporciones de bite/hoja correctas. Usar un ícono "parecido" de una icon font en el código de producción — no solo en el mockup — es causal directa de rechazo bajo la guideline 4.8 de App Store Review y viola las Apple HIG de Sign in with Apple. El glifo en Pencil (`phosphor:apple-logo-fill`) es únicamente para que el mockup se vea aceptable durante el diseño; no debe copiarse a mano en `lib/`.
- El badge "G" y el botón de Apple en Pencil son reproducciones vectoriales fieles (4 paths de color oficial para Google; silueta sólida para Apple) — no son los assets SVG certificados. Sustituir por los widgets/paquetes oficiales (`google_sign_in`, `sign_in_with_apple`) al implementar en Flutter.

Nota de implementación (tipografía): el botón de Google usa `Roboto` (no `$font-body`/Plus Jakarta Sans). El botón de Apple usa `Inter` como aproximación al system font de iOS en Pencil (SF Pro no está disponible ahí); en Flutter, el widget oficial de Apple ya trae su propia tipografía del sistema, así que este detalle no aplica al código final.

## Decisión de diseño (variante ganadora)

Se exploraron, en orden: A (Hero simple), B (Bottom Sheet), C (Tarjeta editorial) → el usuario eligió A inicialmente. Tras verla en contexto con los botones oficiales de marca aplicados, pidió una segunda ronda: D (Asimétrico, ilustración con gradiente) y E (Preview de dispositivos, mockup de teléfonos) → el usuario eligió **D**, y su ilustración terminó incorporando el mockup de teléfonos explorado en E.

**Primera decisión de alineación (revertida): izquierda.** Sobre D se probó centrar solo el texto (descartado: dejaba el trust row descoordinado) y solo la ilustración (descartado: generaba dos anclas visuales compitiendo). Con esa evidencia parcial, se concluyó "izquierda" como ganadora y se aplicó también a la confirmación de fusión por consistencia.

**Reconsideración y decisión final: centrado.** El usuario notó la inconsistencia entre Login (asimétrico) y la primera versión de Fusión (centrada, heredada de la variante A original) y pidió unificar — inicialmente se unificó hacia asimétrico. Al revisar el resultado, el usuario reconsideró si centrado se vería mejor en general. Se construyeron versiones de prueba centrando **ilustración Y texto juntos** (no una sola pieza, a diferencia de los intentos parciales anteriores) y se pasaron a `ui-ux-reviewer` para veredicto comparativo. Hallazgos clave que inclinaron la decisión:
- Verificado en coordenadas: la versión centrada logra que ilustración, titular, subtítulo y trust row compartan un **único eje de simetría real** (no aproximado) — el mismo criterio de "un solo eje de lectura coherente" que justificó "asimétrico" en su momento, cumplido igual de bien por la alternativa centrada.
- En Fusión, la versión asimétrica tenía un defecto real no detectado antes: el titular alineado a la izquierda chocaba con la Stats Card, que siempre estuvo centrada internamente (3 columnas) — dos paradigmas de alineación apilados en la misma pantalla. Centrado lo resuelve.
- **`Empty State`** (componente reusable ya usado en Cuentas/Archivadas: Icon Circle + Message + CTA) es el patrón dominante en el resto de `billetudo.pen` para este tipo de composición, y va **todo centrado**. El asimétrico de Auth era el outlier frente al resto del sistema, no al revés — dato no considerado en las rondas de decisión anteriores.

El Trust Row de Login se reestructuró de horizontal a vertical (ícono arriba, texto centrado debajo) como parte de este cambio, para que también comparta el eje central en vez de quedar "centrado a medias" (el mismo error que mató los intentos parciales previos).

**Copy revisado y corregido por `ui-ux-reviewer`** en una pasada anterior (se mantiene): trust row cambiado por ser redundante con el titular; peso del titular corregido de 800 a 700 por uso incorrecto de un token reservado para montos.

## Navegación

Login se llega desde la fila "Respaldar en la nube" de Ajustes (`jDaUb`) — usa un botón de cerrar simple en vez de `Page Header` (no hay jerarquía de "atrás" que mostrar, es una invitación que se cierra, no un paso de un flujo con historial) y **sin** `Tab Bar` (regla de exclusión de MASTER). Cerrar sesión y Borrar cuenta se llegan desde Ajustes en estado "con sesión" (`aaQBp`). El único tramo de navegación que sigue sin resolver es de dónde se llega a Ajustes mismo (ver Pendientes de esa sección arriba).

## Componentes / variables usados

- **`Button/Google`** (`FJ4Yl`, reusable): botón oficial de Google, instanciado en `fTetG` y `RSzD1`.
- **`Button/Apple`** (`ZhTnN`, reusable): botón oficial de Apple, instanciado dentro de `Auth/Sign-in Buttons Group`.
- **`Auth/Sign-in Buttons Group`** (`rSSog`, reusable): contenedor vertical (`gap:12`) con Apple Button + Google Button + Skip Wrap ("Continuar sin cuenta", `$primary-on-soft-strong`). Pencil no soporta variantes de componente nombradas — el modo Android-solo-Google vs. iOS-Apple+Google se controla ocultando el hijo Apple Button vía override `enabled:false` en la instancia (`descendants:{"<id del Apple Button>":{enabled:false}}`), no con un selector de variante explícito. Documentarlo así para quien edite este componente después.
  - Instancias: `fTetG` (Apple oculto → solo Google), `RSzD1` (Apple visible, default → Apple + Google).
- **`Illustration/Device Preview`** (`a0FOYN`, reusable): mockup de 2 teléfonos + badge de sync, 350x190px. Ícono del badge parametrizable vía override `descendants` sobre el descendant `J4VJC` ("Sync Icon") — default `refresh-cw`.
  - Instancias: `fTetG` (`oW7jx`, ícono default `refresh-cw`), `RSzD1` (`uTVzv`, ícono default `refresh-cw`), `vexqA` (`j0QDos`, override `descendants:{"J4VJC":{icon:"check"}}`).

Nota: `$primary-on-soft` normal NO pasa WCAG AA (~4.4:1) para texto ≤14px sobre `$background`/`$surface` — usar siempre `$primary-on-soft-strong` (4.5:1+) en el Skip Link y cualquier texto pequeño similar de esta pantalla.

Variables usadas: `$background`, `$text-primary`, `$text-secondary`, `$muted`, `$primary`, `$primary-soft`, `$primary-deep`, `$on-primary`, `$primary-on-soft-strong`, `$surface`, `$border`. Sin hex hardcodeado del sistema de billetudo; los botones de Google/Apple usan sus propios colores de marca fijos por diseño (ver excepción documentada arriba), no tokens `$`.

## Pendientes conocidos

- **Asset oficial de Google/Apple**: los glifos en Pencil (4 paths de color para Google, silueta `phosphor:apple-logo-fill` para Apple) son reproducciones de referencia, no los assets certificados — sustituir por `google_sign_in`/`sign_in_with_apple` al implementar en Flutter (ver advertencia de riesgo de rechazo arriba).
- **Copy de la Stats Card asume datos previos**: "Combinamos todo lo que ya tenías guardado..." asume que el usuario ya tenía cuentas/movimientos locales. Si un usuario nuevo inicia sesión sin haber registrado nada, la pantalla mostraría `0/0/0` y el mensaje se sentiría falso — falta decidir si esta pantalla se omite cuando no hay datos que fusionar, o si el copy debe ser más neutral para cubrir ese caso.
- **Resuelto: punto de entrada a Ajustes.** Se llega desde la pantalla "Más" (`gXcHt`), destino de la pestaña "Más" del Tab Bar. La navegación de salida de la confirmación de fusión (qué pasa tras "Ir a mis finanzas") sigue sin definirse más allá de volver a la app.
- **Toda la feature Auth (13 pantallas de flujo) ya tiene ambos temas** — Ajustes y "Más" fueron las últimas en cerrarse. Los 3 estados solo-claro de referencia (`QD8kh`/`JA0KD` loading/error de login, `T1YkkA` error del paso 1 de borrado) siguen sin oscuro, por diseño (son piezas de referencia de patrón, no pantallas del flujo principal).
- **Canvas organizado**: todas las pantallas claras viven en `Zona — Auth (Claro)` (`dXjjz`) y las oscuras en `Zona — Auth (Oscuro)` (`S5vV0`), cada oscura alineada en la misma columna X que su par claro.
- **Loading/error de login** solo cubren Android en claro (`QD8kh`/`JA0KD`) — falta la versión iOS y oscura si se necesita como referencia (probablemente no haga falta, es el mismo patrón).
- **Selector de "Apariencia"** en Ajustes no está diseñado — la fila es estática por ahora.
- **Riesgo de dark pattern en Borrar Cuenta Paso 2** (`K8SAG`/`jxqEb`): el frame "decisión final" muestra una opción preseleccionada (con CTA habilitado) como ejemplo visual del estado post-selección, no el estado inicial real (que vive aparte en `GamyH`/`Fqpgc`, CTA deshabilitado, ninguna opción marcada). Anotado en el canvas (auditoría `ui-ux-reviewer` 2026-07-16) para que el handoff a `flutter-dev` no implemente por accidente una opción preseleccionada — violaría la regla explícita de no-dark-pattern de HU-07.

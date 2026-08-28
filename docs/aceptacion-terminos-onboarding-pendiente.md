# Aceptación de términos en el onboarding — pendiente de implementar

**Estado al 2026-08-28: diseño cerrado, implementación NO iniciada.**

Se trabaja en otra rama. La rama `feat/ai-assistant` deja el diseño aprobado y
esta documentación; no contiene una sola línea de código de esta feature.

## Por qué existe

Investigando el consentimiento de notas del asistente de IA se descubrió que
**la app no pide en ningún momento que la persona acepte los términos de uso ni
la política de privacidad**. No es un hueco que haya creado el asistente: es
preexistente, y bloquea publicación en las tiendas (Apple Guideline 5.1.2,
Google Play Data Safety).

El consentimiento de IA es cosa aparte y **ya está implementado** en
`feat/ai-assistant` (pantalla versionada con `currentAiConsentVersion`,
interruptor de notas, retiro de consentimiento, enlaces legales en Ajustes).
Esta feature no lo bloquea ni depende de él.

## Decisión de producto

De tres variantes evaluadas en Pencil, el usuario eligió la **C**: la pantalla
de Bienvenida no cambia de tono —solo suma un pie discreto con los dos
enlaces— y la aceptación sube como hoja al tocar el CTA. Se descartaron un
checkbox dentro de la Bienvenida (metía ~123px de peso legal en la primera
pantalla y dejaba un botón muerto como primera impresión) y una hoja bloqueante
al abrir (ponía un trámite antes de cualquier bienvenida).

Restricción explícita del usuario: **no crear una pantalla adicional de
onboarding.**

## Frames en `billetudo.pen`

Diseño aprobado por el usuario el 2026-08-28, ambos temas, sin marcas de
revisión pendientes.

| Pantalla | Claro | Oscuro |
|---|---|---|
| Bienvenida con pie legal | `fRrDQ` | `mmFVh` |
| Hoja de aceptación (2 entradas) | `TxoKJ` | `GVvmO` |
| Visor de documento legal | `wwNqS` | `K1O3r` |
| Re-aceptación Paso 1 | `JHwhG` | `b4zW2c` |
| Re-aceptación Paso 1 · un solo documento | `X2781z` | `w0rpiN` |
| Re-aceptación Paso 2 · "No acepto" | `f8KnrT` | `ZrgY7` |

Componentes reutilizables nuevos: `Legal Doc Row` (`SjOTr`), `Legal Text Link`
(`c1dEc`), `Legal Section` (`i5tj1`) y `Sheet Body · Re-aceptación` (`vEgX4`),
este último compartido por las cuatro hojas de re-aceptación — la variante de
un solo documento se resuelve con cinco overrides, sin estructura duplicada.

La nota de arquitectura de implementación vive en el `context` de `T2SsXQ`
(el bloque "Docs" dentro de `Sheet Body · Re-aceptación`), heredada por las
cuatro hojas. Apunta a este documento y al de entrega.

**El texto legal del visor y su línea de versión son placeholders**, no
contenido final: el real sale de `docs/legal/`.

## Reglas que no se pueden romper

La arquitectura de entrega de los documentos está en
[`docs/legal/entrega-de-documentos-legales.md`](legal/entrega-de-documentos-legales.md).
**Léelo antes de implementar.** Resumen de lo que más fácil se rompe:

- La versión que se guarda al aceptar es la del **documento que se mostró**,
  nunca la del manifiesto.
- El disparador de re-aceptación exige **dos** condiciones: versión aceptada
  menor que la vigente **Y** versión de app mayor o igual al `minAppVersion` de
  esa versión legal.
- Una descarga fallida **no bloquea** el arranque; se muestra el bundle.
- Nunca pedir aceptar un documento que no se puede mostrar.
- La hoja de re-aceptación lista **solo los documentos que cambiaron**.

## Trabajo por hacer

**Datos**
- Columna en `AppSettings` para la versión legal aceptada, con su migración,
  el bump de `schemaVersion` (léelo de `app_database.dart`, no de un doc) y el
  `ALTER TABLE` en Supabase **dev y prod** — sin eso el sync queda quarantined
  con `PGRST204`.

**Entrega de documentos**
- Cliente de descarga del manifiesto y los documentos, con caché en disco.
  Se cuelga de `FirstLaunchOfflineGate`
  (`lib/core/bootstrap/first_launch_offline_screen.dart`), que ya bloquea el
  primer arranque sin conexión por el catálogo semilla.
- Los `.md` de `docs/legal/` empaquetados como assets de fallback. Deben ser el
  texto vigente al publicar, nunca un placeholder.
- `legal.json` en el pipeline de `web/` (ver `web/README.md`), con cabeceras de
  caché cortas o cache busting.

**UI** (los frames están en `billetudo.pen`, ambos temas)
- Pie de enlaces en la Bienvenida.
- Hoja de aceptación, que sirve a **dos entradas**: "Comenzar" → onboarding, y
  "Ya tengo cuenta" → login. Un solo componente y un solo copy; el
  consentimiento se registra una vez.
- Pantalla nativa del visor de documento, parametrizada para ambos documentos.
  Destino también desde los enlaces de Ajustes.
- Re-aceptación en dos pasos: paso 1 con los documentos que cambiaron; "No
  acepto" abre el paso 2, que explica la consecuencia y ofrece exportar los
  datos, con retorno visible al paso 1.

**Ruteo**
- La hoja debe interceptar **ambas** entradas. Que "Ya tengo cuenta" se saltara
  el consentimiento era el agujero más grave de los detectados.
- El export desde el paso 2 va a `/mas/importar-exportar/exportar`. Verificado:
  usa `parentNavigatorKey: _rootNavigatorKey` (se dibuja sobre el shell) y
  `ExportCubit` no depende de auth, red ni sesión, así que funciona con la app
  bloqueada y sin conexión.

**l10n** en es y en, y tests.

## Otro trabajo diferido a otra rama

Independiente de esta feature: los ítems 1-6 y 10-11 del issue #7 (filtros de
transacciones) y las incidencias Sentry C y D. Se apartaron cuando el usuario
acotó el alcance de la sesión a lo relacionado con IA.

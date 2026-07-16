# Feature: Onboarding

**Nivel:** 0 (gratis, sin anuncios, sin cuenta requerida)
**Depende de:** `01-cuentas.md`, `02-categorias.md`

## Contexto

Primera experiencia del usuario, antes de cualquier login. Debe llevarlo de "app recién instalada" a "primera cuenta y primeras categorías creadas" con la menor fricción posible, coherente con el principio local-first (sin pedir cuenta).

## Historias de usuario

### HU-01 — Bienvenida sin fricción
Como usuario nuevo quiero entender en pocos segundos qué hace la app y que puedo usarla sin crear cuenta, para decidir seguir sin barreras de entrada.

**Criterios de aceptación:**
- No se solicita login ni email en ningún paso del onboarding.
- El mensaje deja claro que el Nivel 0 es completo y gratis para siempre (evitar sensación de "cebo" identificada como riesgo en la investigación de mercado).

### HU-02 — Crear la primera cuenta
Como usuario nuevo quiero que se me guíe a crear mi primera cuenta (efectivo, banco, tarjeta...) como parte del flujo inicial, para poder registrar mi primera transacción sin fricción.

**Criterios de aceptación:**
- Reutiliza el formulario de `01-cuentas.md` HU-01, simplificado para el contexto de onboarding (valores por defecto razonables: moneda sugerida según el idioma/región del dispositivo).
- El usuario puede crear más de una cuenta en este paso o posponerlo y crear solo una para empezar rápido.

### HU-03 — Elegir categorías semilla
Como usuario nuevo quiero partir de un set de categorías comunes en español ya creadas (ej. Comida, Transporte, Vivienda, Salario), para no tener que pensar en mi estructura de categorías antes de registrar mi primer gasto.

**Criterios de aceptación:**
- Se ofrece un set semilla razonable de categorías de ingreso y gasto, con íconos y colores predefinidos, en español (es-CO/es-ES/es-MX neutro donde aplique).
- El usuario puede deseleccionar las que no quiere antes de confirmar, o aceptar el set completo con un solo toque.
- Las categorías semilla creadas son datos normales y editables después (ver `02-categorias.md` HU-06) — no quedan bloqueadas ni marcadas como especiales.
- El usuario puede saltar este paso por completo y empezar sin categorías (se le recuerda que puede crearlas luego).

### HU-04 — Registrar la primera transacción guiada
Como usuario nuevo quiero que se me invite a registrar mi primera transacción justo después de crear cuenta y categorías, para experimentar el flujo core de la app de inmediato.

**Criterios de aceptación:**
- CTA claro al finalizar los pasos anteriores ("Registra tu primer gasto/ingreso").
- Este paso es opcional/saltable; el usuario puede llegar directo a la pantalla principal si prefiere explorar por su cuenta.

### HU-05 — Comunicar el modelo gratis/opt-in sin presión
Como usuario nuevo quiero entender, sin sentirme presionado, que existen features extra opcionales (IA, gráficas avanzadas) desbloqueables con anuncios o Premium, para saber que existen sin que se me empuje a pagar antes de haber usado la app.

**Criterios de aceptación:**
- Se menciona de forma breve y no intrusiva (ej. una pantalla informativa opcional al final del onboarding, no un paywall).
- No se presenta ningún paywall, cuenta regresiva de prueba gratis, ni solicitud de pago durante el onboarding — coherente con "Nivel 0 completo y sin anuncios" desde el primer uso.

## Reglas de negocio y edge cases

- El onboarding completo (bienvenida → cuenta → categorías → primera transacción) debe poder completarse 100% offline y sin cuenta.
- Ningún paso del onboarding puede condicionar el acceso a features de Nivel 0 a ver un anuncio o iniciar sesión.
- El onboarding es saltable en cada paso opcional (categorías, primera transacción, pantalla informativa de niveles) — solo crear la primera cuenta es un mínimo razonable, dado que ninguna transacción puede existir sin al menos una cuenta.

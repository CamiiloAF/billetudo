# Feature: Categorías

**Nivel:** 0 (gratis, ilimitado, sin anuncios)
**Tabla Drift:** `Categories` (`lib/core/database/app_database.dart`)

## Contexto

Queja #1 repetida contra Wallet en la investigación de mercado: **categorías maestras fijas, no editables**. Este es terreno diferenciador explícito: categorías y subcategorías 100% libres, jerárquicas (`parentId`), para ingreso y gasto (`CategoryKind`).

## Historias de usuario

### HU-01 — Crear categoría raíz
Como usuario quiero crear una categoría de ingreso o de gasto con nombre, ícono y color, para clasificar mis transacciones a mi manera.

**Criterios de aceptación:**
- Elijo `kind`: income o expense.
- El nombre es obligatorio (1-100 caracteres).
- Ícono y color son opcionales pero recomendados en el formulario (mejoran reconocimiento visual en listas y gráficas).
- No hay límite de categorías (Nivel 0).

### HU-02 — Crear subcategoría
Como usuario quiero anidar una categoría dentro de otra (ej. "Comida" → "Restaurantes", "Mercado"), para tener un desglose más fino sin perder la vista agregada.

**Criterios de aceptación:**
- `parentId` apunta a otra categoría existente del mismo `kind` (no se mezcla ingreso con gasto en una misma rama).
- La jerarquía soporta al menos 2 niveles (raíz → subcategoría); no se exige límite técnico de profundidad, pero el diseño de UI debe evitar anidar indefinidamente.
- Las gráficas y presupuestos pueden agregarse por categoría raíz sumando sus subcategorías, o desglosarse por subcategoría.

### HU-03 — Editar categoría
Como usuario quiero renombrar o cambiar ícono/color de una categoría, para ajustarla a mi vocabulario sin perder el historial de transacciones ya categorizadas.

**Criterios de aceptación:**
- Editar nombre/ícono/color no afecta transacciones históricas (siguen enlazadas por `categoryId`, no por nombre).
- Mover una subcategoría a otro padre es soportado y reclasifica automáticamente su aporte en reportes agregados.

### HU-04 — Eliminar categoría
Como usuario quiero eliminar una categoría que ya no uso, para mantener mi lista limpia.

**Criterios de aceptación:**
- Borrado lógico (`deletedAt`), recuperable desde papelera.
- Si tiene subcategorías o transacciones asociadas, se advierte antes de confirmar y se ofrece: reasignar transacciones a otra categoría, o dejarlas sin categoría (`categoryId = null`, ya soportado por el esquema).
- Eliminar una categoría raíz con subcategorías activas requiere resolver primero las subcategorías (reasignar o eliminar en cascada con confirmación explícita).

### HU-05 — Reordenar categorías
Como usuario quiero definir el orden en que aparecen mis categorías, para tener arriba las que más uso.

**Criterios de aceptación:**
- `sortOrder` persiste y se respeta en selectores de transacciones, presupuestos y gráficas.

### HU-06 — Categorías semilla (onboarding)
Como usuario nuevo quiero empezar con un set de categorías comunes en español ya creadas, para no tener que armar mi estructura desde cero.

**Criterios de aceptación:**
- Ver `12-onboarding.md` para el detalle completo del flujo.
- Las categorías semilla son datos normales (mismas tablas, mismos IDs UUID) — el usuario puede editarlas o eliminarlas como cualquier categoría propia, sin restricción especial de "categoría del sistema".

## Reglas de negocio y edge cases

- No existen categorías "maestras" bloqueadas ni no editables — diferenciador explícito frente a Wallet.
- Una transacción de tipo `transfer` no debería requerir categoría (las transferencias mueven dinero entre cuentas propias, no son gasto ni ingreso real) — validar en el formulario de transacciones.
- El `kind` de la categoría debe ser coherente con el `type` de la transacción que la usa (una transacción `income` no debería poder elegir una categoría `expense` y viceversa).

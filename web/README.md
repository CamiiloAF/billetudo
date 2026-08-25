# Sitio legal público

Las páginas que Play Store y App Store exigen como **URL pública**, generadas
desde los documentos de [`../docs/legal/`](../docs/legal/).

| Página | URL | Fuente |
|---|---|---|
| Política de privacidad | https://camiiloaf.github.io/billetudo/ | `docs/legal/politica-de-privacidad.md` |
| Términos de uso | https://camiiloaf.github.io/billetudo/terminos.html | `docs/legal/terminos-de-uso.md` |
| Cómo borrar tu cuenta | https://camiiloaf.github.io/billetudo/borrar-cuenta.html | `docs/legal/como-borrar-tu-cuenta.md` |

Publicado el **2026-08-18**. Las dos primeras URLs son las que van en las
consolas; Play exige la de borrado de cuenta como **página web**, aparte del
flujo dentro de la app.

## Cómo actualizar

**Nunca edites el HTML de `dist/`**: se regenera y perderías el cambio. Editá el
markdown en `docs/legal/` y volvé a generar.

```bash
python3 -m venv web/venv && web/venv/bin/pip install markdown   # solo la 1.ª vez
web/venv/bin/python web/build_site.py
```

Antes de publicar, comprobá que no quede ningún marcador pendiente ni enlace
interno roto:

```bash
grep -c "VERIFICAR" web/dist/*.html          # tiene que dar 0 en las tres
```

## Cómo se publica

GitHub Pages sirve la rama **`gh-pages`**, que es **huérfana**: no comparte
historia con `dev` ni con `main` y contiene *solo* los archivos de `web/dist/`
en su raíz.

Eso no es un capricho. El repo es **público**, y `docs/` contiene la auditoría
de privacidad, el plan de marketing y las declaraciones de tiendas — material
interno que no debe quedar accesible desde el dominio de Pages. Con la rama
huérfana, `https://camiiloaf.github.io/billetudo/docs/legal/AUDITORIA.md`
devuelve 404 (verificado al publicar).

La rama se construye **sin cambiar de rama ni tocar el working tree**, con un
índice temporal. Esto importa cuando hay trabajo sin commitear en `dev`:

```bash
IDX=$(mktemp)
cd web/dist
GIT_INDEX_FILE="$IDX" git --git-dir=/ruta/al/repo/.git --work-tree=. add -A -f .
TREE=$(GIT_INDEX_FILE="$IDX" git --git-dir=/ruta/al/repo/.git write-tree)
cd /ruta/al/repo
COMMIT=$(git commit-tree "$TREE" -m "docs(legal): actualizar sitio")   # sin -p: huérfano
git update-ref refs/heads/gh-pages "$COMMIT"
git push -f origin gh-pages
```

En republicaciones el `push` va con `-f`, porque cada commit es huérfano y no
desciende del anterior. Si preferís conservar historia, encadená con
`-p refs/heads/gh-pages`.

El archivo `.nojekyll` es necesario: sin él, Jekyll ignora cualquier archivo o
carpeta que empiece con guion bajo.

`web/venv/` está en `.gitignore`.

## Pendiente que afecta al contenido

La política declara hoy que **billetudo no se ofrece a residentes del Espacio
Económico Europeo**, porque los DPA (acuerdos de encargo del tratamiento) de
**Sentry** y **PowerSync** no están firmados. El de Supabase sí aplica, por
formar parte de sus términos de servicio.

Dos consecuencias:

1. **Hay que excluir los 30 países del EEE** en la disponibilidad de ambas
   consolas. Está declarado en público: no cumplirlo convierte la política en
   una declaración falsa.
2. Cuando se firmen los dos DPA, hay que **volver a la redacción simple** en
   §7 de la política, regenerar, republicar y recién entonces habilitar el EEE.

#!/usr/bin/env python3
"""Genera el sitio legal estatico de billetudo a partir de docs/legal/*.md.

Por que un generador y no HTML escrito a mano: la politica de privacidad tiene
que seguir siendo editable como Markdown (es el formato en el que la revisa el
agente legal y en el que se versiona), y el HTML no puede divergir de ella. Se
regenera; no se edita a mano.

Uso:
    python3 web/build_site.py

Requiere el paquete `markdown`:
    python3 -m venv .venv && .venv/bin/pip install markdown

Salida: web/dist/ — eso es exactamente lo que se publica en GitHub Pages.
"""

from __future__ import annotations

import html
import pathlib
import re
import shutil
import sys
import unicodedata

try:
    import markdown
except ModuleNotFoundError:
    sys.exit(
        'Falta el paquete `markdown`.\n'
        '  python3 -m venv .venv && .venv/bin/pip install markdown\n'
        '  .venv/bin/python web/build_site.py'
    )

ROOT = pathlib.Path(__file__).resolve().parent.parent
LEGAL = ROOT / 'docs' / 'legal'
WEB = ROOT / 'web'
DIST = WEB / 'dist'

SITE_NAME = 'billetudo'

# (archivo markdown de origen, archivo html de salida, etiqueta en la nav)
# El orden define la barra de navegacion.
PAGES = [
    ('politica-de-privacidad.md', 'index.html', 'Privacidad'),
    ('terminos-de-uso.md', 'terminos.html', 'Términos'),
    ('como-borrar-tu-cuenta.md', 'borrar-cuenta.html', 'Borrar tu cuenta'),
]

# AUDITORIA.md y declaraciones-tiendas.md son documentos internos: no se
# publican. Se listan aca explicitamente para que quede claro que la omision es
# deliberada y no un olvido.
NO_PUBLICAR = {'AUDITORIA.md', 'declaraciones-tiendas.md'}


def slugify_unicode(value: str, separator: str) -> str:
    """Genera anclas conservando los acentos, como hace GitHub.

    El slugify por defecto de python-markdown pasa por ASCII y convierte
    "1. Quien es responsable" -> "1-quien-es-responsable", pero los indices de
    los documentos fueron escritos con las anclas acentuadas
    ("#1-quién-es-responsable-de-tus-datos"). Con el slug por defecto, los 19
    enlaces del indice de la politica apuntan a nada.
    """
    value = unicodedata.normalize('NFKC', value)
    value = re.sub(r'[^\w\s-]', '', value, flags=re.UNICODE).strip().lower()
    return re.sub(r'[{}\s]+'.format(re.escape(separator)), separator, value)


def build_nav(current: str) -> str:
    items = []
    for _, out, label in PAGES:
        attr = ' aria-current="page"' if out == current else ''
        items.append(f'<a href="{out}"{attr}>{html.escape(label)}</a>')
    return '\n      '.join(items)


def render_markdown(text: str) -> tuple[str, str]:
    """Devuelve (titulo, html). El titulo sale del primer `# ` del documento."""
    match = re.search(r'^#\s+(.+)$', text, flags=re.MULTILINE)
    title = match.group(1).strip() if match else SITE_NAME

    body = markdown.markdown(
        text,
        extensions=['extra', 'toc', 'sane_lists'],
        extension_configs={'toc': {'slugify': slugify_unicode}},
        output_format='html5',
    )

    # Las tablas anchas tienen que poder desplazarse solas: el body nunca debe
    # tener scroll horizontal en movil.
    body = body.replace('<table>', '<div class="table-scroll"><table>')
    body = body.replace('</table>', '</table></div>')

    # Resalta los [VERIFICAR] que sigan sin resolver, para que sea imposible
    # publicar sin verlos.
    body = re.sub(
        r'\[VERIFICAR:([^\]]*)\]',
        lambda m: f'<span class="pendiente">FALTA:{html.escape(m.group(1))}</span>',
        body,
    )

    return title, body


TEMPLATE = """<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{title} · {site}</title>
    <meta name="description" content="{description}" />
    <link rel="stylesheet" href="style.css" />
  </head>
  <body>
    <header class="site-header">
      <div class="site-header__inner">
        <span class="site-header__mark" aria-hidden="true">b</span>
        <span class="site-header__name">{site}</span>
        <nav class="site-nav">
      {nav}
        </nav>
      </div>
    </header>
    <main>
{body}
    </main>
    <footer class="site-footer">
      <div class="site-footer__inner">
        <p>{site} — aplicación de finanzas personales.
        Escríbenos a <a href="mailto:{email}">{email}</a>.</p>
      </div>
    </footer>
  </body>
</html>
"""

EMAIL = 'camiiloagudelo92@gmail.com'


def main() -> int:
    if DIST.exists():
        shutil.rmtree(DIST)
    DIST.mkdir(parents=True)

    pendientes_total = 0

    for source, out, label in PAGES:
        path = LEGAL / source
        if not path.exists():
            print(f'  FALTA el origen: {path}', file=sys.stderr)
            return 1

        text = path.read_text(encoding='utf-8')
        title, body = render_markdown(text)

        pendientes = len(re.findall(r'\[VERIFICAR:', text))
        pendientes_total += pendientes

        description = (
            f'{title} de {SITE_NAME}, aplicación de finanzas personales.'
        )

        page = TEMPLATE.format(
            title=html.escape(title),
            site=SITE_NAME,
            description=html.escape(description),
            nav=build_nav(out),
            body=body,
            email=EMAIL,
        )
        (DIST / out).write_text(page, encoding='utf-8')
        flag = f'  ({pendientes} pendientes)' if pendientes else ''
        print(f'  {source}  ->  dist/{out}{flag}')

    shutil.copy(WEB / 'style.css', DIST / 'style.css')
    print('  style.css  ->  dist/style.css')

    # GitHub Pages corre Jekyll por defecto y se come los archivos que empiezan
    # por guion bajo. No los tenemos hoy, pero desactivarlo evita una sorpresa.
    (DIST / '.nojekyll').write_text('', encoding='utf-8')

    print(f'\nListo: {DIST}')
    if pendientes_total:
        print(
            f'\n  ATENCION: quedan {pendientes_total} marcas [VERIFICAR] sin '
            'resolver.\n  Salen resaltadas en rojo en el sitio. No publicar '
            'asi.'
        )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

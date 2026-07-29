"""Servidor estático mínimo para publicar cartografia_del_ingenium_1.html en Railway.

No usa dependencias externas (solo librería estándar de Python) a propósito:
este componente es deliberadamente pequeño, separado del backend/frontend de
FASE 0-1 (hoy inactivos) y del pipeline de ingesta automática.

Lo único que hace: lee el HTML una vez al arrancar, sustituye los tokens
%%%SUPABASE_URL%%% / %%%SUPABASE_ANON_KEY%%% por las variables de entorno
reales (SUPABASE_URL / SUPABASE_ANON_KEY), y sirve el resultado en cualquier
ruta.

Los tokens usan %%% en vez de los nombres de variable JS (__SUPABASE_URL__)
a propósito: esos nombres ya aparecen muchas veces en el propio HTML como
identificadores de código (window.__SUPABASE_URL__), y un reemplazo de texto
ingenuo sobre esa cadena rompería esas referencias.

Si las variables no están configuradas, sirve el HTML tal cual: el atlas
sigue funcionando igual, solo sin memoria compartida (ver
supabaseConfigured() dentro del propio HTML).
"""
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
HTML_PATH = os.path.join(HERE, "..", "cartografia_del_ingenium_1.html")


def render_html():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()
    supabase_url = os.environ.get("SUPABASE_URL", "")
    supabase_anon_key = os.environ.get("SUPABASE_ANON_KEY", "")
    html = html.replace("%%%SUPABASE_URL%%%", supabase_url)
    html = html.replace("%%%SUPABASE_ANON_KEY%%%", supabase_anon_key)
    if not supabase_url or not supabase_anon_key:
        print("[atlas-server] Aviso: SUPABASE_URL / SUPABASE_ANON_KEY no configuradas — "
              "el atlas se sirve sin memoria compartida.")
    return html.encode("utf-8")


RENDERED_HTML = render_html()


class AtlasHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(RENDERED_HTML)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(RENDERED_HTML)

    def log_message(self, fmt, *args):
        print("[atlas-server]", fmt % args)


def main():
    port = int(os.environ.get("PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), AtlasHandler)
    print(f"[atlas-server] Sirviendo cartografia_del_ingenium_1.html en el puerto {port}")
    server.serve_forever()


if __name__ == "__main__":
    main()

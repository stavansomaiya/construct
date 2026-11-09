"""Serve only the Flutter web build, never repository files or SDK caches."""

from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

BUILD = Path(__file__).resolve().parent.parent / "Satark_2" / "build" / "web"


class PreviewHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".mjs": "text/javascript",
    }

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    if not (BUILD / "index.html").is_file():
        raise SystemExit("Flutter web build missing. Run bash scripts/run.sh.")
    server = ThreadingHTTPServer(
        ("0.0.0.0", 5000), partial(PreviewHandler, directory=str(BUILD))
    )
    print("Satark preview serving on port 5000", flush=True)
    server.serve_forever()

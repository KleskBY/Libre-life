"""Serve only the generated web distribution on loopback."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm'}

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parents[1] / 'dist' / 'web'
    if not (directory / 'build.json').is_file():
        parser.error('Run python tools/web_build.py first')
    server = ThreadingHTTPServer(('127.0.0.1', args.port), partial(Handler, directory=str(directory)))
    print(f'Libre-life: http://127.0.0.1:{args.port}/ (Ctrl+C to stop)', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()

import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlsplit


APP_NAME = os.getenv("BACKEND_APP_NAME", "landing-zone-demo-backend")
APP_ENV = os.getenv("APP_ENV", "dev")
HOST = os.getenv("APP_HOST", "0.0.0.0")
PORT = int(os.getenv("APP_PORT", "8080"))

# Demo application/data logic belongs to the P4D-hosted backend, not the AKS
# frontend. This in-memory data is deliberately portable and has no Azure SDK
# or infrastructure dependency.
DEMO_ITEMS = [
    {"id": "foundation", "status": "implemented"},
    {"id": "networking", "status": "implemented"},
    {"id": "security", "status": "implemented"},
]


class BackendRequestHandler(BaseHTTPRequestHandler):
    def _send_json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/health":
            self._send_json({"status": "ok", "application": APP_NAME, "environment": APP_ENV})
        elif path == "/api/info":
            self._send_json({"application": APP_NAME, "environment": APP_ENV, "runtime": "python-stdlib-httpserver"})
        elif path == "/api/items":
            self._send_json({"items": DEMO_ITEMS})
        else:
            self._send_json({"error": "Not found"}, status=404)

    def log_message(self, format, *args):
        return


def main():
    HTTPServer((HOST, PORT), BackendRequestHandler).serve_forever()


if __name__ == "__main__":
    main()

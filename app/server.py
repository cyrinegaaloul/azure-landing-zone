import json
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


START_TIME = time.time()
APP_NAME = os.getenv("APP_NAME", "landing-zone-demo-app")
APP_ENV = os.getenv("APP_ENV", "dev")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
HOST = os.getenv("APP_HOST", "0.0.0.0")
PORT = int(os.getenv("APP_PORT", "8080"))


class DemoRequestHandler(BaseHTTPRequestHandler):
    def _send_json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, body, status=200, content_type="text/plain; version=0.0.4"):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        if self.path == "/":
            self._send_json(
                {
                    "name": APP_NAME,
                    "environment": APP_ENV,
                    "version": APP_VERSION,
                    "message": "Azure landing zone demo application is running."
                }
            )
            return

        if self.path == "/health":
            self._send_json({"status": "ok", "uptime_seconds": round(time.time() - START_TIME, 2)})
            return

        if self.path == "/metrics":
            metrics_body = "\n".join(
                [
                    "# HELP demo_app_info Static information about the demo app.",
                    "# TYPE demo_app_info gauge",
                    'demo_app_info{name="%s",environment="%s",version="%s"} 1' % (APP_NAME, APP_ENV, APP_VERSION),
                    "# HELP demo_app_uptime_seconds Uptime of the demo app in seconds.",
                    "# TYPE demo_app_uptime_seconds counter",
                    f"demo_app_uptime_seconds {round(time.time() - START_TIME, 2)}",
                    ""
                ]
            )
            self._send_text(metrics_body)
            return

        self._send_json({"error": "Not found"}, status=404)

    def log_message(self, format, *args):
        return


def main():
    httpd = HTTPServer((HOST, PORT), DemoRequestHandler)
    print(f"{APP_NAME} listening on http://{HOST}:{PORT}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()

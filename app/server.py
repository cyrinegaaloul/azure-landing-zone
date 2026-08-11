import json
import os
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit


START_TIME = time.time()
APP_NAME = os.getenv("APP_NAME", "landing-zone-demo-app")
APP_ENV = os.getenv("APP_ENV", "dev")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
APP_MOUNTED_FILE_PATH = Path(os.getenv("APP_MOUNTED_FILE_PATH", "/mnt/secrets-store/demo-secret"))
HOST = os.getenv("APP_HOST", "0.0.0.0")
PORT = int(os.getenv("APP_PORT", "8080"))

REQUEST_TOTAL = defaultdict(int)
REQUEST_ERRORS = defaultdict(int)
REQUEST_LATENCY_SUM = defaultdict(float)

SAMPLE_SERVICES = [
    {"name": "foundation", "status": "implemented", "description": "Resource groups, naming, and tags"},
    {"name": "networking", "status": "implemented", "description": "VNet, subnets, and enforced NSG paths"},
    {"name": "security-baseline", "status": "implemented", "description": "RBAC, private Key Vault, and optional locks"},
    {"name": "aks", "status": "implemented", "description": "Entra-integrated application platform"},
]

KNOWN_PATHS = {"/", "/api/info", "/api/status", "/health", "/metrics", "/secret-status"}


def normalized_path(raw_path):
    path = urlsplit(raw_path).path
    return path if path in KNOWN_PATHS else "/not-found"


def secret_is_mounted(secret_path=APP_MOUNTED_FILE_PATH):
    try:
        with secret_path.open("rb") as secret_file:
            return bool(secret_file.read(1))
    except (FileNotFoundError, IsADirectoryError, PermissionError, OSError):
        return False


def record_request(path, status, duration_seconds):
    labels = (path, str(status))
    REQUEST_TOTAL[labels] += 1
    REQUEST_LATENCY_SUM[labels] += duration_seconds
    if status >= 400:
        REQUEST_ERRORS[labels] += 1


class DemoRequestHandler(BaseHTTPRequestHandler):
    def _finish(self, body, status, content_type):
        encoded = body.encode("utf-8")
        record_request(self.metric_path, status, time.perf_counter() - self.request_started)
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def _send_json(self, payload, status=200):
        self._finish(json.dumps(payload), status, "application/json")

    def _send_text(self, body, status=200, content_type="text/plain; version=0.0.4"):
        self._finish(body, status, content_type)

    def do_GET(self):
        self.request_started = time.perf_counter()
        self.metric_path = normalized_path(self.path)

        if self.metric_path == "/":
            self._send_json({"name": APP_NAME, "environment": APP_ENV, "version": APP_VERSION, "message": "Azure landing zone demo application is running."})
            return

        if self.metric_path == "/api/info":
            self._send_json(
                {
                    "application": {"name": APP_NAME, "environment": APP_ENV, "version": APP_VERSION},
                    "platform": {"runtime": "python-stdlib-httpserver", "container_ready": True, "kubernetes_ready": True},
                    "project": {"title": "Secure Azure Landing Zone", "focus": "Layered, cost-aware final demo"},
                }
            )
            return

        if self.metric_path == "/api/status":
            self._send_json({"status": "ok", "uptime_seconds": round(time.time() - START_TIME, 2), "services": SAMPLE_SERVICES})
            return

        if self.metric_path == "/health":
            self._send_json({"status": "ok", "application": APP_NAME, "environment": APP_ENV, "uptime_seconds": round(time.time() - START_TIME, 2)})
            return

        if self.metric_path == "/secret-status":
            self._send_json({"secretMounted": secret_is_mounted()})
            return

        if self.metric_path == "/metrics":
            lines = [
                "# HELP demo_app_info Static information about the demo app.",
                "# TYPE demo_app_info gauge",
                f'demo_app_info{{name="{APP_NAME}",environment="{APP_ENV}",version="{APP_VERSION}"}} 1',
                "# HELP demo_app_uptime_seconds Uptime of the demo app in seconds.",
                "# TYPE demo_app_uptime_seconds gauge",
                f"demo_app_uptime_seconds {time.time() - START_TIME:.6f}",
                "# HELP demo_app_services_total Number of platform services represented by the demo.",
                "# TYPE demo_app_services_total gauge",
                f"demo_app_services_total {len(SAMPLE_SERVICES)}",
                "# HELP demo_app_http_requests_total HTTP requests by path and status.",
                "# TYPE demo_app_http_requests_total counter",
            ]
            for (path, status), count in sorted(REQUEST_TOTAL.items()):
                lines.append(f'demo_app_http_requests_total{{path="{path}",status="{status}"}} {count}')
            lines.extend(["# HELP demo_app_http_request_errors_total HTTP error responses.", "# TYPE demo_app_http_request_errors_total counter"])
            for (path, status), count in sorted(REQUEST_ERRORS.items()):
                lines.append(f'demo_app_http_request_errors_total{{path="{path}",status="{status}"}} {count}')
            lines.extend(["# HELP demo_app_http_request_duration_seconds_sum Cumulative HTTP request duration.", "# TYPE demo_app_http_request_duration_seconds_sum counter"])
            for (path, status), duration in sorted(REQUEST_LATENCY_SUM.items()):
                lines.append(f'demo_app_http_request_duration_seconds_sum{{path="{path}",status="{status}"}} {duration:.6f}')
            lines.append("")
            self._send_text("\n".join(lines))
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

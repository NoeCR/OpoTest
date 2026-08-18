"""Mitmproxy addon: log Testea API requests to JSONL."""
import json
import os
import time
from mitmproxy import ctx

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "capture", "requests.jsonl")


class Logger:
    def response(self, flow):
        url = flow.request.pretty_url
        if "glados-cakeserver" not in url and "testea" not in url:
            return
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "method": flow.request.method,
            "url": url,
            "status": flow.response.status_code if flow.response else None,
        }
        if flow.response and flow.response.content:
            try:
                body = flow.response.content.decode("utf-8", errors="replace")
                if len(body) < 4000:
                    entry["body"] = body
                else:
                    entry["body_preview"] = body[:2000]
            except Exception:
                pass
        with open(OUT, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")


addons = [Logger()]

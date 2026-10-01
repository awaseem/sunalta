"""Offline Three.js asset workspace. Run: python3 AssetFactory/serve.py."""

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent
SLUG = re.compile(r"[a-z0-9][a-z0-9-]{0,63}\Z")
EXPORT = re.compile(r"([a-z0-9][a-z0-9-]{0,63})\.(glb|png)\Z")


def catalog():
    assets, errors = [], []
    for path in sorted((ROOT / "assets").glob("*/asset.json")):
        asset_id = path.parent.name
        try:
            if not SLUG.fullmatch(asset_id) or not path.resolve().is_relative_to(ROOT):
                raise ValueError("Invalid asset directory")
            manifest = json.loads(path.read_text())
            if not isinstance(manifest, dict):
                raise ValueError("Manifest must be a JSON object")
            module = manifest.get("module", "asset.mjs")
            if not isinstance(module, str) or not re.fullmatch(r"[a-zA-Z0-9_-]+\.mjs", module):
                raise ValueError("Module must be a local .mjs filename")
            module_path = path.parent / module
            if not module_path.is_file() or not module_path.resolve().is_relative_to(ROOT):
                raise ValueError(f"Missing module: {module}")
            label = manifest.get("label", asset_id)
            description = manifest.get("description", "")
            if not isinstance(label, str) or not isinstance(description, str):
                raise ValueError("Label and description must be text")
            assets.append({"id": asset_id, "label": label, "description": description,
                           "module": f"/assets/{asset_id}/{module}"})
        except (ValueError, OSError, TypeError) as error:
            errors.append({"id": asset_id, "message": str(error)})
    return {"assets": assets, "errors": errors}


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        path = unquote(urlsplit(self.path).path)
        if path == "/api/assets":
            data = json.dumps(catalog()).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif not Path(self.translate_path(self.path)).resolve().is_relative_to(ROOT):
            self.send_error(403)
        else:
            super().do_GET()

    def do_POST(self):
        # All exports stay inside a registered asset's output folders.
        parts = unquote(urlsplit(self.path).path).strip("/").split("/")
        if len(parts) != 3 or parts[0] != "export":
            self.send_error(400, "Expected /export/<asset>/<filename>")
            return
        _, asset_id, name = parts
        if asset_id not in {asset["id"] for asset in catalog()["assets"]}:
            self.send_error(404, "Unknown asset")
            return
        match = EXPORT.fullmatch(name)
        if name != "manifest.json" and not match:
            self.send_error(400, "Expected a model slug and .glb or .png extension")
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error(400)
            return
        if not 0 < size <= 64_000_000:
            self.send_error(413)
            return
        folder = ROOT / "assets" / asset_id
        if name != "manifest.json":
            folder /= "models" if match.group(2) == "glb" else "png"
        destination = folder / name
        if not destination.resolve().is_relative_to(ROOT / "assets" / asset_id):
            self.send_error(403)
            return
        data = self.rfile.read(size)
        if len(data) != size:
            self.send_error(400, "Incomplete export")
            return
        folder.mkdir(exist_ok=True)
        temporary = destination.with_suffix(destination.suffix + ".tmp")
        temporary.write_bytes(data)
        temporary.replace(destination)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8770)
    arguments = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", arguments.port), Handler)
    print(f"AssetFactory: http://127.0.0.1:{arguments.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

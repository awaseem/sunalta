"""Scaffold a procedural asset: python3 AssetFactory/new_asset.py <asset-id>."""

import argparse
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("asset_id", help="Lowercase letters, digits, and hyphens")
    parser.add_argument("--label", help="Name shown in the viewer")
    arguments = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,63}", arguments.asset_id):
        parser.error("Asset ID must be a lowercase slug, at most 64 characters")
    destination = ROOT / "assets" / arguments.asset_id
    if destination.exists():
        parser.error(f"Asset already exists: {arguments.asset_id}")
    destination.mkdir()
    shutil.copy2(ROOT / "templates" / "asset.mjs", destination / "asset.mjs")
    manifest = {"label": arguments.label or arguments.asset_id.replace("-", " ").title(),
                "description": "Procedural Three.js model. Edit asset.mjs to shape it.",
                "module": "asset.mjs"}
    (destination / "asset.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Created {destination.relative_to(ROOT.parent)}. Edit asset.mjs, then click Reload assets in the viewer.")


if __name__ == "__main__":
    main()

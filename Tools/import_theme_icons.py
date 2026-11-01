"""Import the native Debug renderer's completed icon exports into the asset catalog.

Launch a stopped Debug app with --export-theme-icons, then locate its data container:
xcrun simctl get_app_container SIMULATOR_UDID dev.ambitionsoftware.sunalta data
Run this script with that container's Documents/ThemeIcons folder after complete.txt appears.
The App Store image is Sunalta/Assets.xcassets/AppIcon.appiconset/Any.png.
"""
import argparse
import json
from pathlib import Path
import shutil
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path, help="Simulator app's Documents/ThemeIcons folder")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
if not (args.source / "complete.txt").is_file():
    parser.error("The renderer has not finished exporting all icons.")

icons = [("white", "AppIcon"), ("midnight", "AppIconMidnight"), ("grass", "AppIconGrass")]
variants = [("", "Any"), ("-dark", "Dark"), ("-tinted", "Tinted")]

# Validate the whole set before replacing any checked-in artwork.
for theme, _ in icons:
    for suffix, _ in variants:
        path = args.source / f"{theme}{suffix}.png"
        data = path.read_bytes()
        width, height, depth, color_type = struct.unpack(">IIBB", data[16:26])
        if data[:8] != b"\x89PNG\r\n\x1a\n" or (width, height, depth) != (1024, 1024, 8):
            parser.error(f"Expected a 1024px, 8-bit PNG: {path}")
        if color_type not in (0, 2) or b"tRNS" in data:
            parser.error(f"App icon must be opaque RGB or grayscale: {path}")
        if suffix == "-tinted" and color_type != 0:
            parser.error(f"Tinted app icon must be grayscale: {path}")

for theme, catalog in icons:
    target = root / "Sunalta" / "Assets.xcassets" / f"{catalog}.appiconset"
    target.mkdir(exist_ok=True)
    images = []
    for suffix, variant in variants:
        filename = f"{variant}.png"
        shutil.copyfile(args.source / f"{theme}{suffix}.png", target / filename)
        image = {"filename": filename, "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        if suffix:
            image["appearances"] = [{"appearance": "luminosity", "value": variant.lower()}]
        images.append(image)
    (target / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print(f"Imported {catalog}: Any, Dark, Tinted")

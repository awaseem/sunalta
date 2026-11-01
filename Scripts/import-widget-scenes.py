#!/usr/bin/env python3
"""Import calendar-layout layers without resampling or recoloring the images."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct


def inspect_theme(source, theme):
    folder = source / theme
    if not (folder / "complete.txt").is_file():
        raise ValueError(f"Wait for --export-widget-scenes to finish {theme}.")
    if (folder / "complete.txt").read_text() != "Calendar row; weekday light above hours":
        raise ValueError(f"Re-export {theme} with the current calendar layout and lighting.")
    names = [f"{theme}-{slot}-{digit}" for slot in range(4) for digit in range(10)]
    dimensions = set()
    images = {}
    for name in names:
        filename = f"{name}.png"
        data = (folder / filename).read_bytes()
        if len(data) < 26 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[25] != 6:
            raise ValueError(f"Expected a transparent PNG: {name}")
        dimensions.add(struct.unpack(">II", data[16:24]))
        images[filename] = hashlib.sha256(data).hexdigest()
    if len(dimensions) != 1:
        raise ValueError(f"Every {theme} layer must use the same scene crop.")
    width, height = next(iter(dimensions))
    if abs(width - height) > 1 or min(width, height) < 512 or max(width, height) > 1024:
        raise ValueError(f"Expected a square scene crop between 512 and 1024 pixels: {theme}")
    return {"dimensions": [width, height], "images": images}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="The app's Documents/WidgetScenes directory")
    source = parser.parse_args().source
    root = Path(__file__).resolve().parent.parent
    # Validate every theme before replacing any bundled artwork.
    themes = {theme: inspect_theme(source, theme) for theme in ("white", "midnight", "grass")}
    catalog = root / "SunaltaWidgets/Clock/Assets.xcassets"
    catalog.mkdir(parents=True, exist_ok=True)
    info = {"author": "xcode", "version": 1}
    (catalog / "Contents.json").write_text(json.dumps({"info": info}, indent=2) + "\n")
    for theme, artwork in themes.items():
        for filename in artwork["images"]:
            destination = catalog / f"ClockFace-{Path(filename).stem}.imageset"
            destination.mkdir(exist_ok=True)
            shutil.copyfile(source / theme / filename, destination / filename)
            (destination / "Contents.json").write_text(json.dumps({
                "images": [{"filename": filename, "idiom": "universal"}], "info": info,
            }, indent=2) + "\n")
        print(f"Imported {len(artwork['images'])} {theme} calendar layers ({artwork['dimensions']}).")
    manifest = root / "Design/WidgetScenes/export-manifest.json"
    manifest.parent.mkdir(parents=True, exist_ok=True)
    manifest.write_text(json.dumps({
        "source": "Sunalta/Resources/SharpNumerals.clockmesh",
        "sourceSHA256": hashlib.sha256((root / "Sunalta/Resources/SharpNumerals.clockmesh").read_bytes()).hexdigest(),
        "renderer": "ClockWidgetSceneExporter --export-widget-scenes; ClockRenderView",
        "appearance": "Original AppTheme materials and key lighting; weekday accent shines down from header onto hours",
        "framing": "Calendar layout from ClockWidgetComposition; row captured in place; four uniformly scaled layers",
        "themes": themes,
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()

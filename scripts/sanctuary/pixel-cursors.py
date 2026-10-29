#!/usr/bin/env python3
"""Lantern / Harvest mouse cursors, built from mikaeladev/pixel-cursors.

    pixel-cursors.py            fetch (once) + build both themes into ~/.local/share/icons
    pixel-cursors.py --src DIR  build from a checkout you already have

The art is Pixel Cursors by mikaeladev (GPL-3.0), 12px hand-drawn cursors in
three colours, some taken from shmorgus' Micro Icon Pack. We only recolour
it and pack it: primary / secondary / border swapped for Lantern's (or
Harvest's), each cursor at 1x-4x (12, 24, 36, 48px; the desk asks for 24).
Animated cursors keep their first frame: the pixel style has no motion.

The built themes live outside the dotfiles (the art isn't ours to publish):
  ~/.local/share/icons/Lantern-Pixel   ~/.local/share/icons/Harvest-Pixel
shell.sh points the cursor at them while Lantern / Harvest is on.

Written instead of the upstream build.sh so it needs no xcursorgen / magick /
pixel-to-svg: an Xcursor file is a short header, a table, and ARGB images.
"""
import argparse
import pathlib
import shutil
import struct
import subprocess
import sys
import tomllib

from PIL import Image

REPO = "https://github.com/mikaeladev/pixel-cursors.git"
SRC = pathlib.Path.home() / ".local/src/pixel-cursors"
OUT = pathlib.Path.home() / ".local/share/icons"
SCALES = (1, 2, 3, 4)
FALLBACK = "Bibata-Modern-Classic"      # names the set doesn't draw come from here

# The two printings, as in Theme.qml: cream body, the "you" colour, wood outline.
THEMES = {
    "Lantern-Pixel": {"primary": "#fff0cc", "secondary": "#ff5c9d", "border": "#1e1216"},
    "Harvest-Pixel": {"primary": "#fff0cc", "secondary": "#b8286c", "border": "#3a2018"},
}


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def recolour(img, default, theme):
    swap = {rgb(default[k]): rgb(theme[k]) for k in ("primary", "secondary", "border")}
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in swap:
                px[x, y] = swap[(r, g, b)] + (a,)
    return img


def xcursor(images):
    """images: [(size, hot_x, hot_y, RGBA Image)] → bytes of one Xcursor file."""
    ntoc = len(images)
    head = struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc)
    chunks, toc, pos = [], [], 16 + 12 * ntoc
    for size, hx, hy, img in images:
        w, h = img.size
        raw, pixels = img.tobytes(), bytearray()
        for i in range(0, len(raw), 4):
            r, g, b, a = raw[i:i + 4]
            # premultiplied ARGB, little-endian
            pixels += struct.pack("<I", (a << 24) | (r * a // 255 << 16) | (g * a // 255 << 8) | (b * a // 255))
        chunk = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1, w, h, hx, hy, 0) + bytes(pixels)
        toc.append(struct.pack("<III", 0xFFFD0002, size, pos))
        chunks.append(chunk)
        pos += len(chunk)
    return head + b"".join(toc) + b"".join(chunks)


def asset_for(name, spec, assets, frame_h):
    """The 12×12 image a cursor entry draws (transformed, first frame)."""
    a = spec.get("asset", name)
    if isinstance(a, str):
        a = {"name": a}
    img = assets[a["name"]]
    if img.height > frame_h:                     # stacked frames: keep the first
        img = img.crop((0, 0, img.width, frame_h))
    if a.get("flip"):
        img = img.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    if a.get("flop"):
        img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if a.get("rotate"):
        img = img.rotate(-int(a["rotate"]), expand=True)   # magick -rotate is clockwise
    return img


def build(src, out):
    cfg = tomllib.loads((src / "config.toml").read_text())
    default = cfg["themes"]["default"]
    size = 12
    for theme, colours in THEMES.items():
        assets = {p.stem: recolour(Image.open(p), default, colours) for p in (src / "assets").glob("*.png")}
        root = out / theme
        if root.exists():
            shutil.rmtree(root)
        (root / "cursors").mkdir(parents=True)
        (root / "index.theme").write_text(
            f"[Icon Theme]\nName={theme}\nComment=Pixel Cursors (mikaeladev, GPL-3.0) in Sanctuary's "
            f"{theme.split('-')[0]} colours\nInherits={FALLBACK}\n")
        shutil.copy(src / "LICENSE", root / "LICENSE")
        for name, spec in cfg["cursors"].items():
            base = asset_for(name, spec, assets, size)
            images = [(size * s, spec["hot_x"] * s, spec["hot_y"] * s,
                       base.resize((base.width * s, base.height * s), Image.Resampling.NEAREST)) for s in SCALES]
            (root / "cursors" / name).write_bytes(xcursor(images))
            for alias in spec.get("aliases", []):
                link = root / "cursors" / alias
                if not link.exists():
                    link.symlink_to(name)
        print(f"{theme}: {len(cfg['cursors'])} cursors → {root}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", type=pathlib.Path, default=SRC)
    ap.add_argument("--out", type=pathlib.Path, default=OUT)
    args = ap.parse_args()
    if not (args.src / "config.toml").exists():
        args.src.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "clone", "--depth", "1", REPO, str(args.src)], check=True)
    build(args.src, args.out)


if __name__ == "__main__":
    sys.exit(main())

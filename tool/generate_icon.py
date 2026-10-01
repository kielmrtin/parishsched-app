#!/usr/bin/env python3
"""Rasterizes the same church-silhouette shapes used in
lib/widgets/church_logo.dart (Flutter CustomPainter) directly to PNGs,
using only the standard library. Written because `flutter test` couldn't
produce an image in this sandbox (toImage() never resolved, even with
tester.runAsync). Geometry here must stay in sync with church_logo.dart by
hand if that file changes.

Writes two files:
- assets/icon/app_icon.png: opaque maroon bg + cream church, for the
  legacy/flat launcher icon (flutter_launcher_icons `image_path`).
- assets/icon/app_icon_foreground.png: transparent bg, cream church only,
  scaled down further so it clears Android's adaptive-icon safe zone (a
  ~61%-radius circle inscribed in the 108dp canvas) even at this shape's
  rectangular corners, which reach further from center than a round or
  organic glyph would at the same fill percentage.

Usage: python3 tool/generate_icon.py
"""
import os
import struct
import zlib

SIZE = 1024
MAROON = (0x6E, 0x1B, 0x29)
CREAM = (0xF5, 0xEA, 0xD9)

# Actual drawn content in church_logo.dart spans roughly x:[12,90] y:[1,76]
# within its nominal 100x100 box (there's dead space bottom/right of that),
# so center on this bbox rather than the nominal box, or the icon looks
# shifted toward the top-left.
CONTENT_L, CONTENT_T, CONTENT_R, CONTENT_B = 12, 1, 90, 76
CONTENT_CX = (CONTENT_L + CONTENT_R) / 2
CONTENT_CY = (CONTENT_T + CONTENT_B) / 2


def in_rect(x, y, box):
    l, t, r, b = box
    return l <= x < r and t <= y < b


def in_triangle(x, y, p1, p2, p3):
    def sign(a, b, c):
        return (a[0] - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (a[1] - c[1])

    p = (x, y)
    d1 = sign(p, p1, p2)
    d2 = sign(p, p2, p3)
    d3 = sign(p, p3, p1)
    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (has_neg and has_pos)


def in_arch(x, y, box):
    """Rect with a domed (semicircular) top — mirrors _archRect's
    arcToPoint with radius == half the chord, i.e. a true semicircle cap."""
    l, t, r, b = box
    arch_height = (r - l) * 0.55
    mid_y = t + arch_height
    radius = (r - l) / 2
    cx = (l + r) / 2
    if y >= mid_y:
        return l <= x <= r and y <= b
    dx = x - cx
    dy = y - mid_y
    return dx * dx + dy * dy <= radius * radius


def render(fill_px, transparent_bg):
    scale = fill_px / (CONTENT_R - CONTENT_L)

    def to_px(x, y):
        return (
            SIZE / 2 + (x - CONTENT_CX) * scale,
            SIZE / 2 + (y - CONTENT_CY) * scale,
        )

    def rect_px(l, t, r, b):
        (l, t) = to_px(l, t)
        (r, b) = to_px(r, b)
        return l, t, r, b

    tower_rect = rect_px(14, 34, 34, 76)
    spire_tri = (to_px(12, 34), to_px(24, 10), to_px(36, 34))
    cross_v = rect_px(23, 1, 25, 10)
    cross_h = rect_px(20, 4, 28, 6)
    nave_rect = rect_px(38, 50, 90, 76)
    roof_tri = (to_px(38, 46), to_px(64, 36), to_px(90, 46))
    roof_rect = rect_px(38, 46, 90, 50)

    nave_arch1 = rect_px(47, 58, 60, 76)
    nave_arch2 = rect_px(68, 58, 81, 76)
    tower_arch = rect_px(20.5, 42, 27.5, 56)

    tl = to_px(CONTENT_L, CONTENT_T)
    br = to_px(CONTENT_R, CONTENT_B)
    x0 = int(tl[0]) - 4
    x1 = int(br[0]) + 4
    y0 = int(tl[1]) - 4
    y1 = int(br[1]) + 4

    channels = 4 if transparent_bg else 3
    pixels = bytearray(SIZE * SIZE * channels)
    if not transparent_bg:
        for i in range(SIZE * SIZE):
            pixels[i * 3 : i * 3 + 3] = MAROON

    for py in range(max(y0, 0), min(y1, SIZE)):
        row_base = py * SIZE * channels
        for px in range(max(x0, 0), min(x1, SIZE)):
            x, y = px + 0.5, py + 0.5
            cream = (
                in_rect(x, y, tower_rect)
                or in_triangle(x, y, *spire_tri)
                or in_rect(x, y, cross_v)
                or in_rect(x, y, cross_h)
                or in_rect(x, y, nave_rect)
                or in_triangle(x, y, *roof_tri)
                or in_rect(x, y, roof_rect)
            )
            if not cream:
                continue
            cut = (
                in_arch(x, y, nave_arch1)
                or in_arch(x, y, nave_arch2)
                or in_arch(x, y, tower_arch)
            )
            off = row_base + px * channels
            if cut:
                if transparent_bg:
                    pixels[off : off + 4] = bytes((0, 0, 0, 0))
                else:
                    pixels[off : off + 3] = bytes(MAROON)
            else:
                if transparent_bg:
                    pixels[off : off + 4] = bytes(CREAM + (255,))
                else:
                    pixels[off : off + 3] = bytes(CREAM)

    return pixels, channels


def write_png(path, width, height, pixel_bytes, channels):
    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    color_type = 6 if channels == 4 else 2
    raw = bytearray()
    stride = width * channels
    for row in range(height):
        raw.append(0)  # filter type: None
        raw.extend(pixel_bytes[row * stride : (row + 1) * stride])

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 9)

    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


os.makedirs("assets/icon", exist_ok=True)

flat_pixels, flat_channels = render(fill_px=680, transparent_bg=False)
write_png("assets/icon/app_icon.png", SIZE, SIZE, flat_pixels, flat_channels)
print("wrote assets/icon/app_icon.png")

fg_pixels, fg_channels = render(fill_px=560, transparent_bg=True)
write_png(
    "assets/icon/app_icon_foreground.png", SIZE, SIZE, fg_pixels, fg_channels
)
print("wrote assets/icon/app_icon_foreground.png")

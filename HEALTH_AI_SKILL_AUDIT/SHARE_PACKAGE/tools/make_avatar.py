"""Generate the bundled profile avatar (flat illustration, no real person).

Output: 512x512 PNG with a circular crop, matching the warm design
palette. Run from the repo root:
    python tools/make_avatar.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 2  # supersample for smoother curves
W = SIZE * SS
OUT = Path("app/assets/brand/avatar.png")

BG = (241, 232, 218, 255)  # warm mist
SKIN = (225, 171, 128, 255)
SKIN_SHADE = (203, 146, 104, 255)
HAIR = (43, 32, 26, 255)
HAIR_LIGHT = (68, 50, 40, 255)
SHIRT = (224, 168, 59, 255)  # mustard, as in the reference
SHIRT_DARK = (198, 143, 40, 255)
COLLAR = (249, 246, 238, 255)
INK = (45, 32, 26, 255)
BLUSH = (219, 141, 112, 70)


def ellipse(draw, box, fill):
    draw.ellipse([v * SS for v in box], fill=fill)


def polygon(draw, points, fill):
    draw.polygon([(x * SS, y * SS) for x, y in points], fill=fill)


def rounded(draw, box, radius, fill):
    draw.rounded_rectangle(
        [v * SS for v in box], radius=radius * SS, fill=fill
    )


def arc(draw, box, start, end, fill, width):
    draw.arc(
        [v * SS for v in box],
        start=start,
        end=end,
        fill=fill,
        width=width * SS,
    )


def main() -> None:
    image = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    # Background + shoulders + shirt.
    ellipse(draw, (0, 0, SIZE, SIZE), BG)
    ellipse(draw, (180, 690, 844, 1180), SHIRT_DARK)
    rounded(draw, (300, 640, 724, 1120), 190, SHIRT)
    # Collar.
    polygon(draw, [(430, 650), (512, 760), (594, 650)], COLLAR)
    polygon(draw, [(430, 650), (512, 760), (512, 650)], (236, 231, 220, 255))

    # Neck.
    rounded(draw, (440, 520, 584, 700), 70, SKIN_SHADE)

    # Ears.
    ellipse(draw, (238, 352, 312, 466), SKIN)
    ellipse(draw, (712, 352, 786, 466), SKIN)
    ellipse(draw, (258, 382, 296, 444), SKIN_SHADE)
    ellipse(draw, (728, 382, 766, 444), SKIN_SHADE)

    # Head.
    ellipse(draw, (268, 150, 756, 676), SKIN)

    # Hair: back mass, then a fringe over the forehead.
    ellipse(draw, (244, 96, 780, 480), HAIR)
    ellipse(draw, (272, 196, 752, 672), SKIN)
    # Fringe swept to the side.
    polygon(
        draw,
        [
            (272, 300),
            (296, 206),
            (390, 152),
            (556, 142),
            (690, 184),
            (742, 262),
            (744, 330),
            (656, 296),
            (556, 286),
            (470, 312),
            (386, 352),
            (312, 334),
        ],
        HAIR,
    )
    ellipse(draw, (330, 128, 620, 250), HAIR_LIGHT)
    # Sideburns.
    rounded(draw, (274, 300, 322, 420), 22, HAIR)
    rounded(draw, (702, 300, 750, 420), 22, HAIR)

    # Brows.
    arc(draw, (356, 306, 468, 372), 200, 340, HAIR, 13)
    arc(draw, (556, 306, 668, 372), 200, 340, HAIR, 13)

    # Eyes.
    ellipse(draw, (382, 378, 440, 424), (250, 246, 238, 255))
    ellipse(draw, (584, 378, 642, 424), (250, 246, 238, 255))
    ellipse(draw, (400, 388, 428, 420), INK)
    ellipse(draw, (602, 388, 630, 420), INK)
    ellipse(draw, (406, 392, 416, 404), (255, 255, 255, 255))
    ellipse(draw, (608, 392, 618, 404), (255, 255, 255, 255))

    # Nose.
    arc(draw, (478, 404, 546, 492), 60, 120, SKIN_SHADE, 9)

    # Smile.
    arc(draw, (444, 486, 580, 566), 30, 150, INK, 11)

    # Cheeks.
    ellipse(draw, (330, 448, 412, 512), BLUSH)
    ellipse(draw, (612, 448, 694, 512), BLUSH)

    # Crop to a circle.
    mask = Image.new("L", (W, W), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse((0, 0, W, W), fill=255)
    image.putalpha(mask)

    image = image.resize((512, 512), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()

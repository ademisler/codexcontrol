from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


def build_icon(size: int) -> Image.Image:
    palette = {
        "dark_icon": "#0c1218",
        "accent": "#4fd1c5",
        "ring": "#e8eff2",
    }
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    outer_padding = max(2, int(size * 0.08))
    corner_radius = max(8, int(size * 0.24))
    draw.rounded_rectangle(
        (outer_padding, outer_padding, size - outer_padding, size - outer_padding),
        radius=corner_radius,
        fill=palette["dark_icon"],
    )

    ring_padding = int(size * 0.26)
    ring_width = max(2, int(size * 0.08))
    ring_bounds = (ring_padding, ring_padding, size - ring_padding, size - ring_padding)
    draw.arc(ring_bounds, start=140, end=400, fill=palette["ring"], width=ring_width)
    draw.arc(ring_bounds, start=140, end=320, fill=palette["accent"], width=ring_width)

    center = size // 2
    pointer_end = (int(size * 0.66), int(size * 0.36))
    draw.line((center, center, pointer_end[0], pointer_end[1]), fill="#ffffff", width=max(2, int(size * 0.05)))
    hub = max(2, int(size * 0.05))
    draw.ellipse((center - hub, center - hub, center + hub, center + hub), fill="#ffffff")

    dot_size = max(4, int(size * 0.15))
    dot_left = size - outer_padding - dot_size - max(2, int(size * 0.05))
    dot_top = size - outer_padding - dot_size - max(2, int(size * 0.05))
    draw.ellipse(
        (dot_left, dot_top, dot_left + dot_size, dot_top + dot_size),
        fill=palette["accent"],
        outline="#ffffff",
        width=max(1, int(size * 0.03)),
    )
    return image


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    assets_dir = root / "build-assets"
    assets_dir.mkdir(parents=True, exist_ok=True)
    output_path = assets_dir / "CodexControl.ico"

    base = build_icon(256)
    sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (24, 24), (16, 16)]
    base.save(output_path, format="ICO", sizes=sizes)
    print(output_path)


if __name__ == "__main__":
    main()

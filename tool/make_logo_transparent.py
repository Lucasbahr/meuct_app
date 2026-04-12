"""Remove outer dark background from assets/images/logo.png via edge flood-fill."""
from __future__ import annotations

import shutil
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "logo.png"
BACKUP = ROOT / "assets" / "images" / "logo_backup_opaque.png"


def main() -> None:
    if not LOGO.is_file():
        raise SystemExit(f"Missing {LOGO}")

    if not BACKUP.is_file():
        shutil.copy2(LOGO, BACKUP)
        print("Backup:", BACKUP)

    im = Image.open(LOGO).convert("RGBA")
    arr = np.array(im)
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.int16)

    corners = np.array(
        [rgb[0, 0], rgb[0, w - 1], rgb[h - 1, 0], rgb[h - 1, w - 1]],
        dtype=np.float64,
    )
    ref = corners.mean(axis=0)
    tol = 12

    def near_ref(p: np.ndarray) -> bool:
        return bool(np.max(np.abs(p.astype(np.float64) - ref)) <= tol)

    mask_bg = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    for j in range(w):
        for i in (0, h - 1):
            if near_ref(rgb[i, j]) and not mask_bg[i, j]:
                mask_bg[i, j] = True
                q.append((i, j))
    for i in range(h):
        for j in (0, w - 1):
            if near_ref(rgb[i, j]) and not mask_bg[i, j]:
                mask_bg[i, j] = True
                q.append((i, j))

    while q:
        i, j = q.popleft()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ni, nj = i + di, j + dj
            if ni < 0 or ni >= h or nj < 0 or nj >= w:
                continue
            if mask_bg[ni, nj]:
                continue
            if near_ref(rgb[ni, nj]):
                mask_bg[ni, nj] = True
                q.append((ni, nj))

    arr[:, :, 3] = np.where(mask_bg, 0, arr[:, :, 3])
    Image.fromarray(arr, "RGBA").save(LOGO, optimize=True)
    print("Wrote", LOGO)
    print("Transparent pixels:", int(mask_bg.sum()), "/", h * w)


if __name__ == "__main__":
    main()

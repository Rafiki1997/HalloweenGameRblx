"""Render a top-down shaded preview of src/server/Landscape.luau with the town footprint drawn over it.
Runs the real Luau module through the local runner, so the picture is the shape the server will build."""
from pathlib import Path
import math
import subprocess
import sys
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
LUAU = ROOT / '.tools/luau/luau.exe'
OUT = ROOT / 'assets/previews/landscape-plan.png'
STEP = 2
MATERIALS = {'LeafyGrass': (36, 58, 52), 'Grass': (30, 50, 44), 'Ground': (58, 48, 62), 'Mud': (48, 40, 54),
             'Rock': (76, 74, 96), 'Basalt': (52, 50, 72)}

def sample():
    script = f"""
local L = require('../src/server/Landscape')
local B, step = L.Bounds, {STEP}
local out = {{}}
for z = -B, B - step, step do
    local row = {{}}
    for x = -B, B - step, step do
        local h = L.height(x + step / 2, z + step / 2)
        row[#row + 1] = string.format('%.2f:%s', h, L.material(x + step / 2, z + step / 2))
    end
    out[#out + 1] = table.concat(row, ' ')
end
print(table.concat(out, string.char(10)))
"""
    # The runner only resolves ./ and ../ requires, so the probe script lives beside the build output.
    path = ROOT / 'build' / '_landscape_probe.luau'
    path.write_text(script, encoding='utf-8')
    run = subprocess.run([str(LUAU), 'build/_landscape_probe.luau'], capture_output=True, text=True, cwd=ROOT)
    path.unlink()
    if run.returncode:
        sys.exit(run.stderr or run.stdout)
    rows = [line.split(' ') for line in run.stdout.strip().split('\n')]
    heights = np.array([[float(c.split(':')[0]) for c in row] for row in rows])
    mats = [[c.split(':')[1] for c in row] for row in rows]
    return heights, mats

def render():
    heights, mats = sample()
    n = heights.shape[0]
    water = -1.5
    rgb = np.zeros((n, n, 3), dtype=float)
    for j in range(n):
        for i in range(n):
            rgb[j, i] = MATERIALS.get(mats[j][i], (255, 0, 255))
    # Hillshade from the north-west so slopes read as relief.
    gz, gx = np.gradient(heights, STEP)
    light = np.array([-0.5, -0.6, 0.62]); light /= np.linalg.norm(light)
    normal = np.dstack((-gx, -gz, np.ones_like(heights)))
    normal /= np.linalg.norm(normal, axis=2, keepdims=True)
    shade = np.clip(normal @ light, 0, 1)
    rgb = rgb * (0.45 + 0.9 * shade[..., None])
    # Height tint: cool moonlight on the crests.
    tint = np.clip((heights - 5) / 70, 0, 1)[..., None]
    rgb = rgb * (1 - 0.35 * tint) + np.array([120, 126, 176]) * 0.35 * tint
    under = heights < water
    rgb[under] = np.array([40, 62, 118]) * (0.7 + 0.3 * np.clip((heights[under] + 8) / 6.5, 0, 1))[:, None]
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).resize((n * 2, n * 2), Image.NEAREST)
    draw = ImageDraw.Draw(img)
    scale = 2 / STEP
    def px(x, z): return ((x + heights.shape[0] * STEP / 2) * scale, (z + heights.shape[0] * STEP / 2) * scale)
    def rect(x0, z0, x1, z1, color): draw.rectangle([px(x0, z0), px(x1, z1)], outline=color, width=2)
    def circle(x, z, r, color): draw.ellipse([px(x - r, z - r), px(x + r, z + r)], outline=color, width=2)
    circle(0, 0, 33, (200, 190, 240))                                  # plaza
    circle(0, 0, 150, (120, 110, 150))                                 # protected disc
    rect(-68, -206, 68, -20, (200, 150, 250))                          # mansion avenue and hill
    rect(-45, -200, 45, -130, (230, 180, 255))
    rect(116, 64, 182, 148, (150, 230, 170))                           # graveyard lot
    rect(-62, 40, -42, 104, (255, 200, 130))                           # shop row
    for i in (1, 2, 3, 4, 6, 7, 8):
        a = math.radians(20 + (i - 1) * 40)
        cx, cz = math.sin(a) * 116, math.cos(a) * 116
        ox, oz = cx / 116, cz / 116; rx, rz = oz, -ox
        pts = [px(cx + rx * sx + ox * sz, cz + rz * sx + oz * sz) for sx, sz in ((-23, -20), (23, -20), (23, 20), (-23, 20))]
        draw.polygon(pts, outline=(255, 170, 230))
        draw.line([px(cx * 0.26, cz * 0.26), px(cx, cz)], fill=(150, 130, 150), width=2)
    draw.line([px(0, -30), px(0, -129)], fill=(150, 130, 150), width=3)
    circle(60, 215, 30, (140, 200, 255))                               # pond
    circle(0, 21, 4, (255, 255, 255))                                  # spawn
    for r in (165, 195): circle(0, 0, r, (90, 120, 90))                # tree ring
    for label, x, z in (('MANSION', 0, -165), ('GRAVEYARD', 150, 105), ('SHOPS', -52, 71), ('POND', 60, 215), ('RIDGE', 0, -270), ('SPAWN', 8, 21)):
        draw.text(px(x - 14, z - 4), label, fill=(255, 255, 255))
    OUT.parent.mkdir(exist_ok=True)
    img.save(OUT)
    print(f'{OUT.relative_to(ROOT)}: {img.size[0]}x{img.size[1]}; height range {heights.min():.1f} to {heights.max():.1f}; '
          f'{(under.sum() * STEP * STEP):.0f} sq studs under water')

if __name__ == '__main__':
    render()

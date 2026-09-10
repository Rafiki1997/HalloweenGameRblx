# Ghostlight Hollow assets

First batch prepared; uploads and imported-mesh runtime calibration are pending. All IDs are zero.
The remaining zones in the town brief are not yet modelled. These are intentionally economical
low-poly props, not a claim that the entire concept's detail level has been achieved.

| Asset | Zone | Budget | Actual tris | Footprint (X,Y,Z studs) | Roles | ID | Preview |
| --- | --- | ---: | ---: | --- | --- | ---: | --- |
| StreetLamp | Props | 300 | 188 | 1.44, 8.7, 1.44 | Collision, Glow, Metal | 0 | [Front](../assets/previews/StreetLamp_front.png) |
| Gravestone | Props | 150 | 80 | 3, 3.2, 1.6 | Collision, Stone | 0 | [Front](../assets/previews/Gravestone_front.png) |
| PineTree | Props | 400 | 132 | 8.86327, 17, 8.72862 | Collision, Foliage, Wood | 0 | [Front](../assets/previews/PineTree_front.png) |
| DeadTree | Props | 600 | 392 | 6.34299, 10.54509, 4.04853 | Collision, Wood | 0 | [Front](../assets/previews/DeadTree_front.png) |
| Pumpkin | Props | 300 | 300 | 2.916, 2.46633, 2.608 | Accent, Collision, Glow, Wood | 0 | [Front](../assets/previews/Pumpkin_front.png) |

Each asset also has a `_top.png` preview. All ten images have been inspected. The first batch uses
one arched gravestone; cross and obelisk silhouette variants belong to the later graveyard zone.

## Rebuild commands (PowerShell, project directory)

Save and close Blender before rebuilding town.blend. Never rebuild it between upload and ID harvest.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --disable-autoexec --python-exit-code 1 --python tools/blender/build_assets.py -- --out assets
& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --disable-autoexec --python-exit-code 1 --python tools/blender/render_previews.py -- --out assets
```

## Upload these collections

Open `assets/town.blend`. The collections share their export origin, so overlapping models in the
viewport are expected. Each collection uploads separately. Select collection rows (folder icons)
in the Outliner, not the individual mesh objects:

- StreetLamp
- Gravestone
- PineTree
- DeadTree
- Pumpkin

In the 3D viewport press N, select Roblox, log in if needed, choose your personal account in
Upload to, and click Upload. Wait for a green checkmark on every collection, then Ctrl+S and close
Blender. Tell Codex the upload is finished before proceeding. No script uses the saved login token.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --disable-autoexec --python-exit-code 1 --python tools/blender/harvest_ids.py
python tools/gen_asset_ids.py
python tools/build_place.py
python tools/verify.py
python tools/build_place.py --test
```

The runtime replacement is activated per positive asset ID. Once all five load, the initial layout
uses 26 lamps, 15 gravestones, one pine, one dead tree and one pumpkin: 117 MeshParts including
collision meshes and 6,912 placed triangles. Remaining trees stay primitive pending the full-town
budget decision. A configured asset that fails loading produces a labelled placeholder and warning.

The first batch does not add lights beyond the existing lamp count. World.build prints total
primitive parts, MeshParts and lights including the mansion interiors; that total is not the final
outdoor-only light budget. Existing dynamic ghost and upgrade lights also need a final budget audit.

## Verification status

- Closed edges, nondegenerate triangles, outward aggregate volume and per-asset budgets pass.
- FBX files and town.blend are below 5 MB and can remain tracked.
- Eleven production Luau scripts compile; ten rule groups pass; nested loader source is packaged.
- Two Python metadata/packaging tests pass; two independent builds produce identical normalized
  geometry signatures for all five assets.
- The acceptance place was opened in Studio, but automatic Play was unavailable: Weppy requires
  Pro for that action, and Windows refused to focus the window for the F5 fallback. No new Studio
  acceptance success is claimed. The existing connected published-place tab was not modified.
- Real upload, Roblox role-name preservation, extents calibration, and mesh screenshots remain
  pending. A primitive-only acceptance run cannot prove these properties.

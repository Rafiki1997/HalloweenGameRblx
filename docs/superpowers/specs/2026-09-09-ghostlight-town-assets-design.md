# Ghostlight Hollow town asset pipeline design

## Purpose

Replace the primitive outdoor town with original, deterministic Blender assets that match
`HalloweenGameModels.png`, upload them through Roblox's official Blender add-on, and load them at
server startup without publishing the experience. The existing gameplay, mansion interiors, map
frame, and server-facing `World` contract remain intact.

`docs/CODEX-TOWN-ASSETS-PROMPT.md` is the detailed visual, placement, budget, and acceptance source
for this work. This document records the architecture and sequencing decisions used to implement it.

## Delivery strategy

Build one vertical slice before producing large assets. The first slice contains StreetLamp,
Gravestone, PineTree, DeadTree, and Pumpkin and proves generation, FBX export, preview rendering,
upload, ID harvesting, manifest generation, runtime loading, role styling, collision behavior, and
Studio acceptance. Subsequent checkpoints add Plaza, Haunts, Mansion, Town, and Graveyard in that
order. The runtime world remains usable after each zone.

This is preferred over modelling everything before integration because it exposes scale, naming,
upload, and loader problems while assets are still cheap to revise. It is also preferred over a
placeholder-first runtime rewrite because the first real props provide the same architectural proof
without creating a disposable parallel asset set.

## Blender pipeline

`tools/blender/build_assets.py` owns deterministic mesh generation. It rebuilds named collections
from primitives and modifiers, applies modifiers, triangulates output, validates mesh and asset
budgets, restores existing Roblox package IDs from the manifest, exports one FBX per collection, and
saves `assets/town.blend`. Each asset is a collection named exactly after the asset. Mesh names end
in a controlled material role so Roblox can style imported MeshParts without relying on Blender
materials or textures.

Geometry uses metres with one metre corresponding to one Roblox stud. Origins sit at each asset's
base centre. Collision meshes are simple, invisible shapes with the `Collision` role. Visible mesh
objects are non-collidable at runtime. Export settings match the installed Roblox add-on so manual
uploads and reproducible exports have the same axes and scale.

`tools/blender/render_previews.py` renders two Workbench images per asset using a consistent moonlit
blue background, fixed cameras, and fixed lighting. The front three-quarter view tests silhouette and
role readability; the top view tests footprint and placement. Previews are compared against the
corresponding concept panel before a zone advances.

`tools/blender/harvest_ids.py` reads only the `Roblox Package ID` collection property from
`town.blend`. It writes the asset ID, upload time, and exported FBX SHA-256 to the manifest. It reports
missing IDs and never reads or prints OAuth credentials. If `ROBLOX_API_KEY` is present, the optional
headless uploader uses that key only in memory and writes results through the same manifest and
collection-property path.

## Manifest and generated source

`assets/manifest.json` is the editable data boundary between Blender, upload, and Roblox runtime. One
entry per asset records its name, zone, footprint, roles, triangle budget, actual triangle count,
asset ID, upload timestamp, and FBX hash. Existing asset IDs survive regeneration and cause later
uploads to create new versions instead of duplicate assets.

`tools/gen_asset_ids.py` validates the manifest and generates `src/shared/AssetIds.luau`. Generated
Luau maps each asset name to its numeric ID, footprint, and roles. It is never edited manually. Asset
documentation is generated or checked against the same manifest so reported counts cannot drift from
the build.

## Roblox runtime

`src/shared/Assets/Loader.luau` is the only module that calls `InsertService:LoadAsset`. It preloads
each unique asset once, in parallel, with a twelve-second overall wait and a cache for successful
models. Failures produce one warning per asset ID and leave a cache entry that prevents repeated
network requests.

Placement clones the cached model, scales it to the manifest footprint within two percent, pivots it
from its base centre, anchors all parts, and applies a palette based on the final role suffix in each
MeshPart name. Visible parts are non-collidable and non-queryable. `Collision` parts are transparent,
collidable, and queryable. `Glow` and `Accent` use Neon, and each Haunt instance supplies its own accent
color. Glass and Water receive their specified transparency.

If loading fails or moderation has not completed, placement creates a dark footprint-sized Part and
warning label. This keeps the world, gameplay contracts, and acceptance fixture alive while making
the missing asset visible to developers.

`src/server/World.luau` becomes a layout and gameplay-adapter module. It keeps ground, paving, mist,
labels, lights, prompts, and other large flat or dynamic elements as Roblox instances. It preloads and
places mesh assets, then builds the exact fields consumed by the server: `Plots`, `Areas`,
`MansionDoor`, `Upgrades`, `Leaderboard`, `RebirthAltar`, `RebirthAltarPrompt`, `ChamberPortal`,
`ChamberPortalPrompt`, `Root`, and `prompt`. Each plot preserves `Model`, `CF`, twenty ordered `Slots`,
`Label`, `IncomeLabel`, `Deposit`, `ChamberDoor`, `Owner`, and `Displays`.

The six mansion hunting interiors remain primitive and isolated at their current coordinates. The
outdoor layout preserves spawn, mansion-interior offsets, seven Haunts, the clear northern avenue,
and out-of-bounds limits. Legacy overlapping signs are removed, welcome signs move away from the
portal base, and server copy and player count are corrected to seven.

## Packaging

`tools/build_place.py` recursively packages Luau files beneath `src/shared`, allowing the new
`Assets/Loader.luau` module to appear as a nested ModuleScript. Production and acceptance places use
the same production source set; acceptance-only scripts remain exclusive to the test build.

Generated binary Blender and FBX files remain untracked when they exceed the repository size policy.
The manifest, generated Luau, scripts, documentation, and preview PNGs remain tracked. Runtime assets
are always referenced by creator-owned Roblox asset IDs rather than embedded in the place XML.

## Failure handling and safety

Blender refuses to regenerate `town.blend` while an interactive Blender process has it open. Asset
generation stops on invalid topology, a mesh over 20,000 triangles, an asset over its stated budget,
an export over 20 MB, a missing role, or a missing required collection. Upload failures are reported
verbatim and receive at most two deliberate attempts.

Runtime load failures use placeholders. No workflow reads, prints, copies, or moves the add-on's
saved login token. The experience is never published by this work. Existing worktree changes are
preserved through additive checkpoint commits without reset, stash, or history rewriting.

## Verification

Each zone must pass, in order:

1. Blender validation, FBX existence and hashes, triangle limits, and two preview renders per asset.
2. `python tools/verify.py`.
3. Production and acceptance builds through `tools/build_place.py`.
4. Studio Play acceptance ending with exactly 26 passing checks and no asset-load warnings.
5. Runtime inspection of imported MeshPart names and StreetLamp scale calibration.
6. Screenshots of the required town views compared with the concept and Blender previews.
7. Printed budgets below 400,000 triangles, 120 MeshParts, 1,500 primitives, 60 lights, three shadowed
   lights, and a two-second `World.build()` CPU budget excluding asset network time.

Every completed zone receives a checkpoint commit. Final reporting lists modelled, uploaded, and
loading assets; geometry and runtime budgets; acceptance results; previews; and Studio screenshots.

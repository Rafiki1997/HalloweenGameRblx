# Ghostlight Hollow Town Assets Implementation Plan

> Execute inline using the executing-plans workflow. Preserve the user's required workspace and branch.

**Goal:** Generate, preview, upload, and integrate the reference town one verified zone at a time.

**Architecture:** Python produces role-separated Blender collections and a manifest. A generated
Luau module provides asset metadata to a cached server loader; World remains the gameplay adapter.

**Tech Stack:** Blender 5.1.2 Python, FBX, Python standard library, Luau, Roblox InsertService, Weppy.

**Spec:** `docs/superpowers/specs/2026-09-09-ghostlight-town-assets-design.md` and
`docs/CODEX-TOWN-ASSETS-PROMPT.md`.

## Global constraints

- Work only in this workspace on `ghostlight-feedback-pass`; preserve baseline commit `a7d1f53`.
- Never publish the experience or expose credentials. Only the authorized login-presence boolean is read.
- Human uploads through Blender; no API key is available in the current process.
- Preserve collection `Roblox Package ID` strings across regeneration.
- Apply modifiers and triangulation; closed surfaces, outward normals, under 20,000 triangles per mesh,
  under each asset's stated budget, and under 20 MB per upload.
- Keep every server-facing World field and six existing hunting interiors functional.
- Keep the avenue and spawn unobstructed; preserve seven Haunts and existing map coordinates.
- Do not overwrite a Blender file open in the user's interactive process.
- Whole-town MeshPart budget requires a user decision before implementation: see preflight report.
- Static outdoor triangle and light budgets are 400,000 and 60; shadowed lights at most three.
  Runtime counters must distinguish outdoor scenery from interior lights, equipment, and displayed ghosts.

## 0. Preflight

- [x] Verify branch and preserve the complete pre-asset project in a checkpoint.
- [x] Create `tools/blender/preflight.py`; run with Blender `--background --disable-autoexec
  --python-exit-code 1 --python tools/blender/preflight.py`.
- [x] Export one-metre cube to `assets/exports/preflight_cube.fbx` using the requested settings.
- [x] Report enabled add-on, saved-login presence, and API-key presence without credential contents.
- [x] List workspace children through Weppy and retain the exact routing identity for subsequent calls.
- [x] Run baseline `python tools/verify.py`.
- [ ] Resolve MeshPart count conflict and receive confirmation Blender is closed.

## 1. Props: generation, preview, and upload preparation

Files: `tools/blender/build_assets.py`, `tools/blender/render_previews.py`,
`tools/blender/harvest_ids.py`, `assets/manifest.json`, `docs/ASSETS.md`.

- [ ] Implement first-zone collections: StreetLamp, Gravestone (slab/cross/obelisk variants),
  PineTree, DeadTree, Pumpkin. Store deterministic footprints for props unspecified in the brief.
- [ ] Build reusable closed box, tapered cylinder, roof wedge, branch, and low-resolution sphere
  helpers. Join geometry by role, apply transforms/modifiers, triangulate and recalculate normals.
- [ ] Validate with Blender: reject loose edges, boundary/nonmanifold edges, nontriangular faces,
  nonpositive signed volume, budget overflow, or a mesh with no vertices. Report per-role counts.
- [ ] Serialize manifest as `{schemaVersion: 1, assets: {name: {zone, footprint, roles,
  triangleBudget, triangles, assetId, uploadedAt, sha256}}}`. Preserve upload metadata when rebuilding;
  changed geometry must be distinguishable from the last uploaded hash.
- [ ] Keep collections positioned at the origin for export, with mesh origins at base centre.
  Arrange assets for inspection only through a separate preview scene or temporary render transforms.
- [ ] Match the brief's explicit FBX parameters. Confirm current add-on defaults do not produce a
  different coordinate transform; use StreetLamp import to calibrate actual Roblox units.
- [ ] Generate Workbench front-three-quarter and top renders; hide collision geometry for previews.
- [ ] Inspect every image; fix silhouettes until recognizably consistent with the concept.
- [ ] Rerun generation and compare normalized mesh coordinates/triangles for determinism. FBX files
  may contain timestamps, so raw hash equality alone is not a geometry determinism test.
- [ ] Ask the user to open `assets/town.blend`, select the listed collections, choose personal creator
  `1445842194`, upload, verify green checkmarks, save, and close Blender.

## 2. Props: harvest and runtime integration

Files: `tools/gen_asset_ids.py`, `src/shared/AssetIds.luau`, `src/shared/Assets/Loader.luau`,
`tools/build_place.py`, `src/server/World.luau`, `tests/test_asset_pipeline.py`.

- [ ] Harvest IDs from each collection; reject absent, nonnumeric, or nonpositive IDs. Update
  timestamps only for a confirmed upload. Preserve previously completed assets and their IDs.
- [ ] Generate deterministic `AssetIds.luau`: `AssetName -> {Id, Footprint, Roles}`. Tests use a
  temporary manifest and assert exact IDs and vectors survive generation; invalid IDs fail clearly.
- [ ] Add recursive folder packaging to `sources()`. A fixture containing `Assets/Loader.luau`
  must produce a Folder named Assets and a ModuleScript named Loader with byte-equivalent source.
- [ ] Loader exposes `preload(names)` and `place(name, parent, cf, options)`. Cache one request per
  unique name; finish waiting after 12 seconds; discard or safely handle late responses without
  mutating already placed fallbacks. Log one warning per failed name and ID.
- [ ] On load, strip executable scripts from imported containers; locate all MeshParts recursively.
  Parse only allowed role suffixes and report unexpected names. Do not execute uploaded code.
- [ ] Derive base-centre from model bounds. Uniformly calibrate scale, reject nonuniform footprint
  mismatches greater than two percent rather than concealing malformed exports by stretching.
- [ ] Apply palette, anchoring, visibility, query/collision flags and per-instance accent.
  Collision role islands require actual simple blockers: a single convex hull must not seal a
  fence gate or fill the courtyard. Verify decomposition in Studio before adopting it for Haunts.
- [ ] Place the uploaded props into existing World layout, retaining primitive remainder of town.
- [ ] Confirm StreetLamp extents and uploaded role names through Studio. Calibrate export scale if
  needed; preserve matching settings in the human upload lane.
- [ ] Build production place before source-equality verification when sources changed; then run the
  requested verify/build/build-test sequence against current artifacts.
- [ ] Run Studio acceptance, inspect output for 26 passes and zero asset warnings, capture relevant
  views, print scene counts, document results, and checkpoint the completed Props zone.

## 3. Plaza

- [ ] Add GhostFountain, ChamberPortal, RebirthAltar, NoticeBoard, WelcomeSign generators.
- [ ] Render and validate all five assets; upload and harvest using the proven props process.
- [ ] Replace plaza geometry, retain primitive paving, move welcome signs to ±12/50, and remove
  legacy Rebirth sign. Maintain portal prompt/animation, altar prompt, and Leaderboard.Label.TextLabel.
- [ ] Verify seven plots and all six interiors still function; run local checks, acceptance and
  screenshots; update `docs/ASSETS.md` and commit the Plaza checkpoint.

## 4. Haunts

- [ ] Generate HauntShowcase with house at rear, front gate, fenced yard and twenty pedestals.
- [ ] Keep twenty slot anchors aligned with pedestal tops, ordered front row first; preserve the
  home landing at local `(0,4,-22)` and a clear walking route from gate to deposit.
- [ ] Upload, harvest, and replace all seven plots with distinct accent colors and identical World
  contracts. Move upgrade decorations clear of the house; account for their runtime light growth.
- [ ] Verify plot ownership, display placement, teleport landing and collisions in Studio; run full
  zone checks, update asset documentation, and commit the Haunts checkpoint.

## 5. Mansion

- [ ] Generate MansionHill, MansionFacade and Boulder. Facade roles naturally split its 18,000
  triangle budget across at least three mesh objects; build proper spires and arched windows.
- [ ] Add an invisible stair wedge and terrace collision, preserve 24-wide approach, and align
  MansionDoor and prompt with the visible entrance.
- [ ] Upload, harvest, integrate, inspect the entrance from the avenue, run zone checks and commit.

## 6. Town

- [ ] Generate ShopHouse, Caretaker, MarketStall, Barrel and Crate; reuse Pumpkin and StreetLamp.
- [ ] Place three shops on the west, facing the plaza; attach Workshop/Inn/Curiosities labels.
  Preserve W.Upgrades prompt and Mira/Orin text with visible interaction anchors.
- [ ] Upload, harvest, integrate, review shop-row screenshot, run zone checks and commit.

## 7. Graveyard and final verification

- [ ] Generate GraveyardFence and Crypt; use three gravestone variants for 18 placements and
  four DeadTrees. Preserve the quiet-garden sign, mist primitives, and open gate toward the plaza.
- [ ] Upload, harvest, integrate, run zone checks and commit.
- [ ] Correct seven-player config, both stale startup/kick strings, and README server-size copy.
- [ ] Update README creator-owned asset instructions, IMPLEMENTATION.md, PLAYTEST.md and ASSETS.md.
- [ ] Ignore `build/screens/`; ignore exports or town.blend according to the brief's 5 MB threshold.
- [ ] Rebuild both places, pass local verification and Studio's 26 acceptance checks without load
  warnings. Capture spawn north, Haunt gate, mansion steps, shops, graveyard gate and overhead views.
- [ ] Report actual modelled/uploaded/loading counts, placed triangles, MeshParts, primitives,
  static and dynamic lights, shadowed lights and World.build time excluding network wait.

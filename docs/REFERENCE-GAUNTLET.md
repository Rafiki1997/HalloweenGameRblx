# Spawn-town reference gauntlet

Reference: `assets/reference/spawn-town.png`. Method: independent builders, real Roblox Studio renders, fresh critics, and revisions responding to concrete failures, following [Matt Shumer's Gauntlet Loop](https://somethingbig.ai/gauntlet-loop).

## Review status

**Exact reference fidelity is not achieved.** Independent rounds 1, 5, 7, and 10 failed visual acceptance. Mechanical test results must not be represented as passing the visual comparison. The full Studio screenshots and written reviews remain in `build/gauntlet/`. The latest full overview is `round-10.png`; the final independent verdict is `critic-10.md`.

Round 10 passed all eight engine groups: 2,154 path center/quarter-point samples, 21 plot-gate samples, 140 clear display centers, landmark collision ownership, portal alignment, spawn clearance, ready-state checks and zero script errors. Raw output is preserved as `build/gauntlet/engine-round-10.json`. The one-client diagnostic measured about 60 FPS on this machine; it is not a multiplayer or mobile benchmark. All 22 production scripts compile and pass scope lint, packaged sources match, all local Luau suites pass, and seven Python tests pass. Local output is in `build/gauntlet/local-verification.txt`.

The map now has a western lake with docks, boats, lilies and waterfalls; a central blue spirit fountain; seven player estates with six prominent reference colors; a raised northern mansion; southwest shops; southeast graves and a chapel; winding cobbled routes, retaining rockwork, forest planting, iron fences, lanterns and valley mist. The existing seven-player capacity, twenty slots per estate, and six hunting interiors remain supported. The reference drawing's text mentions eight showcases while depicting six; the implementation retains seven functional plots rather than changing the game's capacity.

The major remaining visual differences are the illustrated reference's much denser, more irregular Gothic buildings, its tightly packed tiered composition, the tall flowing central spirit silhouette, and its painterly treatment of trees, rocks and light. Current meshes and procedural decoration still read as a simpler 3D environment.

## Reproduce

1. `python tools/build_place.py` builds the playable place.
2. `python tools/build_place.py --preview` builds the separate fixed-camera review place.
3. Open the preview in Roblox Studio and press Play. Allow asset loading and terrain collision to settle.
4. Read `REFERENCE PASS/FAIL` output. The preview checks path visibility, plot approaches, landmark collision ownership, ghost display clearance, portal alignment, spawn usability and engine errors.
5. Compare a real Studio capture against the source image. Record a visual failure separately from engine failures.

`python tools/verify.py` compiles and lints production Luau, verifies packaged-source equality, and runs rule, encounter and terrain checks. Six `ReferenceMap.spec.luau` groups validate the active island height function; the older nine `Landscape.spec.luau` groups concern the retained legacy module. `python -m unittest discover -s tests -p 'test_*.py'` runs the Python checks.

The preview's camera and diagnostic remote are excluded from the playable build. Capture helpers under `tools/` target only the explicitly named local preview Studio window; they are optional Windows utilities. `capture_window.py` uses the locally installed `windows-capture` and OpenCV packages under `.tools/capture`.

The original on-disk place was preserved as `build/GhostlightHollow-before-reference.rbxlx` before rebuilding. Nothing has been published.

## Placement correction pass

The two marked misplaced estates now occupy separate plots beside the southern entrance. The red and cyan eastern estates face the plaza, with the cyan courtyard moved north to clear the cemetery. The old rear-mansion plot and lake/village plot locations are restored to landscape. Plot pads and orientations share `MapPlan.luau` with the route builder, eliminating duplicate coordinate lists.

Routes now meet at intentional junctions and enter the actual front gates. The village entrance serves a clear street in front of the workshop row; the cemetery route enters its west gate. Lake access uses defined bank paths and raised wooden approaches to the docks. Junctions omit curbs and lamps that could obstruct their openings. Village fence sections near the relocated plots are omitted.

`MapRoutes.spec.luau` checks dry routes, full shop footprints, plot entry corridors, duplicate paving, unintended crossings and facing directions. `ReferenceMap.spec.luau` also checks the rotated corners of all seven terrain pads. The preview adds pedestrian-volume checks against plot, shop and cemetery walls. Latest visual evidence: `build/gauntlet/layout-corrected.png`.

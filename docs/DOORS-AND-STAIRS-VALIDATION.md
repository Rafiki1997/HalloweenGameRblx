# Doors and plot approaches — 2026-09-14

The main mansion now presents a solid paneled double door on the outside of its Gothic facade. The mansion selection prompt belongs to this visible door; the obsolete anchor behind the wall is removed. The avenue terminates at a level porch in front of the doorway.

All seven plot houses have framed, closed decorative doors, positioned ahead of the imported timber wall and porch posts. They have no entry prompt. The public ghost display slots remain clear.

Plot approaches use graded stone stair flights with level landings at bends and gates. Terrain is cut and filled beneath the flights instead of letting pavement follow the abrupt edge of each terrace. Bridge junction heights and scaled courtyard heights are accounted for explicitly.

## Verification

The preview's `ReferenceAcceptance` runner reports **12 passed, 0 failed**:

- 3,552 path surface samples remain visible above terrain.
- 3,552 pedestrian volumes clear plot, shop, and cemetery walls.
- 21 gate approach samples connect to paving.
- 140 ghost display centers remain clear of opaque architecture.
- A ray from the front porch reaches the visible mansion door, within prompt range.
- 2,047 live stair collision samples have no riser above 0.6 studs; gate landings meet their courtyards.
- A disposable avatar walks the main mansion approach and all seven plot approaches with jumping disabled.
- Zero script errors during build and acceptance checks.

`python tools/verify.py` passes: all 23 production scripts compile, scope checks pass, packaged sources match, and terrain, route, economy, and hunting checks pass. The seven Python tests also pass.

Visual evidence:

- [Mansion front door](../build/gauntlet/mansion-door-fixed.png)
- [Plot front door](../build/gauntlet/plot-door-fixed.png)
- [Graded plot staircase and landing](../build/gauntlet/plot-stairs-landings.png)

## Open the updated game

Close the old `GhostlightHollow.rbxlx` Studio tab without saving its stale contents. Open `build/GhostlightHollow.rbxlx` from disk, then press Play. The separate `GhostlightHollow-ReferencePreview.rbxlx` contains camera and acceptance helpers that are excluded from the production place.

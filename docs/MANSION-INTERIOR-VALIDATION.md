# Mansion interior redesign — 2026-09-14

The six hunting wings now have connected rooms with furnishings appropriate to their purpose. `MansionInterior.luau` replaces the repeated divider-and-table grid previously embedded in `World.luau`.

| Wing | Design |
| --- | --- |
| Abandoned Foyer | Paired stairs to a rear gallery, a moonlit gallery window, drawing room with fireplace and piano, dining room with table settings and sideboard. |
| Whispering Bedrooms | Four suites off a portrait hall, with canopy beds, wardrobes, bedside candles, dressing tables, mirrors, and leaded windows. |
| Cursed Library | Bookcases, reading alcoves, desks with open books, an archive room, fireplace, and grandfather clock. |
| Forgotten Basement | Wine barrels in cradles, storage crates, workshop benches and tool boards, boiler, ceiling pipes, and high windows. |
| The Moonless Crypt | Chapel aisle and pews, memorial glass, altar, sarcophagi, and recessed burial tablets. |
| The Catacombs | Vaulted burial galleries, masonry pillars, tombs, stone paths, and a lit reliquary. |

The upper floors have plaster walls, wood paneling, rugs, portraits, and curtains. Underground areas use masonry and stone paving, with lower chandelier light. Windows occupy actual wall openings. Doorway spandrels fill the wall above the arch. Candle flicker affects a candle fixture and restores its original brightness.

Every area has a solid return door at its perimeter. Existing floor unlocks, encounter rules, capture rewards, and progression are unchanged. Ghosts spawn and roam within clear room pockets; fleeing targets are clamped to those pockets so furniture and room walls do not trap them.

## Verification

- **12 interior Studio checks passed:** 17 actual window openings, six return prompts, 1,050 ghost clearance volumes, and navigable routes from the entrance to all 42 hunting pockets and all six exits.
- **12 existing map Studio checks passed**, including the exterior door, path, stair, and avatar walking checks.
- **28 hunting harness checks passed**, including new spawn-pocket and roaming-boundary coverage.
- All **24 production scripts compile**, scope lint passes, packaged sources match, and existing terrain, routes, economy, and seven Python tests pass.
- No engine script errors observed during the preview run.

Screenshots: [foyer](../build/gauntlet/interior-foyer.png), [bedroom suite](../build/gauntlet/interior-bedroom-suite.png), [library](../build/gauntlet/interior-library.png), [cellar](../build/gauntlet/interior-cellar.png), [crypt](../build/gauntlet/interior-crypt.png), [catacombs](../build/gauntlet/interior-catacombs.png).

## Playtest

Close the old Studio tab without saving its stale contents, reopen `build/GhostlightHollow.rbxlx`, and press Play. Enter the mansion from its front door and select the Abandoned Foyer. Explore the parlor, dining room, and stairs; return using the door at the entrance. The remaining wings retain their existing unlock requirements. The separate reference preview contains the inspection camera and automated checks, which are excluded from the production file.

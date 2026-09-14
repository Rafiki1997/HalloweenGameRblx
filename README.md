# Ghostlight Hollow

A new Roblox ghost-hunting simulator built from the supplied brief and three reference images.

## Open and play

Open **build/GhostlightHollow.rbxlx** in Roblox Studio and press **Play (F5)**. The town and mansion are generated when the server starts; the edit viewport initially has no map. Wait for the HUD to load. Your vacuum equips automatically.

The spawn map now follows `assets/reference/spawn-town.png`: a central spirit fountain, western fishing lake, southwest village, southeast cemetery, six prominent colored haunt estates, a seventh rear estate for the existing seven-player game, and a northern mansion above stone terraces. `ReferenceTerrain`, `ReferenceLayout`, `ReferenceArchitecture`, and `ReferenceDetails` build these districts. Exact visual parity with the illustration has **not** passed the independent visual gauntlet; screenshots and critiques are preserved in `build/gauntlet/`.

For the repeatable visual review, run `python tools/build_place.py --preview`, open `build/GhostlightHollow-ReferencePreview.rbxlx`, and press Play. This separate preview hides the HUD, fixes the overview camera, and runs eight engine acceptance groups. Its camera also supports `workspace:SetAttribute('ReferenceShot','plaza')`, `'town'`, `'lake'`, `'graveyard'`, or `'overview'` from the Studio command bar during Play. The normal game build keeps the playable camera and HUD. The place that existed before this rebuild is preserved as `build/GhostlightHollow-before-reference.rbxlx`.

1. Select **MANSION → ENTER** beside Abandoned Foyer.
2. Run into a ghost (within 5.5 studs) or click one to start the 2.8-second retro intro, followed by a private **1v1 capture screen** with your avatar facing the ghost. Click anywhere in the battle to fill the bottom capture bar. Hover inside a target when its outer ring closes for **+12 percentage points** on top of your clicks. Keep clicking: bonuses require a click within the last 2.5 seconds. On touch, tap to capture and hold a finger inside the closing target. Movement and ghost attacks pause until the encounter ends. Capture returns you to the mansion; **FLEE / Q** releases the ghost. Encounters have a 3-second cooldown after release or capture.
3. Press **F** or **LIGHT** to toggle your flashlight. **Q** releases a target.
4. Select **HAUNT → GO HOME**, then **DEPOSIT**, or use your glowing deposit pad. Depositing automatically fills empty display slots with the strongest available ghosts.
5. Use **HAUNT** to remove or place individual ghosts. Income arrives every second.
6. Buy **UPGRADES** and unlock the next **MANSION** area. The **REBIRTH** panel explains the cost and asks for confirmation before resetting progression.
7. At home, enter **HAUNT CHAMBER** with at least one placed ghost. Use +/− to zoom and EXIT to return. Hunters find an owned ghost and a small dollar reward every 35 seconds. Regular Haunt income continues.

PC mouse, touch action buttons, and gamepad controls are included. In the 1v1 screen, **A / R2** captures, the **right stick** aims a visible cursor, and **B** flees. A circle takes 1.2 seconds to close; misses cost no extra progress. Your battle avatar always uses a fixed vacuum-ready pose facing the ghost, with your own appearance. Fifteen seconds without activity, or a two-minute encounter limit, releases the ghost.

## Saving and publishing

Studio defaults to an explicitly labeled **practice session with no persistence**. This permits testing an unpublished place without a DataStore failure blocking entry.

Published Roblox servers use server-side DataStores automatically. Publish to your own new experience and set the server size to **7 players**. For persistent Studio testing, use a separate test experience, enable Studio API access, and set `StudioPersistence = true` in `src/shared/Config.luau`, then rebuild. Production load failures never fall back to an empty writable profile.

Profiles use UpdateAsync leases, token validation, retries, autosaves, and leave/shutdown saves. Verify these against a published test experience before release. DataStore implementation reference: [Roblox Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

## Development

- `src/shared/Config.luau`: ghost roster, rarity colors, economy, capture configuration.
- `src/shared/Rules.luau`: pure, executable rules for rewards, placement and progression.
- `src/shared/Visuals.luau`: original part-built ghost and equipment models.
- `src/server`: reference island generation, authoritative hunting, profiles, chamber, and orchestration. Seven player estates surround the clear mansion approach.
- `src/client`: HUD, collection previews, inputs, suction effects, encounter transition, 1v1 battle and chamber camera. Tune contact distance, intro duration and cooldown in `C.Encounter`; circle timing, radius, bonus and battle timeouts are in `C.Battle` in the shared config.
- `default.project.json`: Rojo mapping for continued editing.
- `docs/BUILD-BRIEF.md`: the supplied specification.
- `docs/PLAYTEST.md`: runtime acceptance checklist and known limits.

Build with `python tools/build_place.py`. Run `python tools/verify.py` after installing the official [Luau Windows binaries](https://github.com/luau-lang/luau/releases) in `.tools/luau`. The local verifier lints every script for file-level locals used before their declaration and for unknown globals (both are nil at runtime in Roblox), compiles scripts, runs the rule tests, and checks that the place contains the exact source files.

For repeatable single-player engine tests, run `python tools/build_place.py --test`, open `build/GhostlightHollow.Acceptance.rbxlx`, and press Play. The test runner prints its results to Studio Output. This separate place contains test-only setup and remote controls; do not publish it. The 1v1 battle build passed **41 Studio acceptance checks**, **26 local encounter checks**, 11 rule groups and 9 landscape groups. Multiplayer, hardware touch/gamepad testing and published persistence remain release checks.

The town mesh pipeline uses the creator's own meshes listed in `assets/manifest.json`, uploaded with the Roblox Blender add-on. To publish under another account or group, clear the IDs from the manifest, re-upload under that creator, and regenerate `AssetIds.luau`. The first five props are modelled; upload is pending and the game retains its original props until their IDs are recorded. See `docs/ASSETS.md` for commands and status. Sounds use bundled Roblox effects where available; footsteps use Roblox's standard character audio.

# Ghostlight Hollow

A new Roblox ghost-hunting simulator built from the supplied brief and three reference images.

## Open and play

Open **build/GhostlightHollow.rbxlx** in Roblox Studio and press **Play (F5)**. The town and mansion are generated when the server starts; the edit viewport initially has no map. Wait for the HUD to load. Your vacuum equips automatically.

1. Select **MANSION → ENTER** beside Abandoned Foyer.
2. Aim at a nearby ghost and click repeatedly. Follow it when it pulls away. On touch devices, repeatedly press **TAP TO VACUUM** while looking toward the ghost.
3. Press **F** or **LIGHT** to toggle your flashlight. **Q** releases a target.
4. Select **HAUNT → GO HOME**, then **DEPOSIT**, or use your glowing deposit pad. Depositing automatically fills empty display slots with the strongest available ghosts.
5. Use **HAUNT** to remove or place individual ghosts. Income arrives every second.
6. Buy **UPGRADES** and unlock the next **MANSION** area. The **REBIRTH** panel explains the cost and asks for confirmation before resetting progression.
7. At home, enter **HAUNT CHAMBER** with at least one placed ghost. Use +/− to zoom and EXIT to return. Hunters find an owned ghost and a small dollar reward every 35 seconds. Regular Haunt income continues.

The bottom navigation scrolls horizontally on narrow screens. PC mouse, touch action buttons, and basic gamepad hunting inputs (R2 capture, X light) are included.

## Saving and publishing

Studio defaults to an explicitly labeled **practice session with no persistence**. This permits testing an unpublished place without a DataStore failure blocking entry.

Published Roblox servers use server-side DataStores automatically. Publish to your own new experience and set the server size to **8 players**. For persistent Studio testing, use a separate test experience, enable Studio API access, and set `StudioPersistence = true` in `src/shared/Config.luau`, then rebuild. Production load failures never fall back to an empty writable profile.

Profiles use UpdateAsync leases, token validation, retries, autosaves, and leave/shutdown saves. Verify these against a published test experience before release. DataStore implementation reference: [Roblox Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

## Development

- `src/shared/Config.luau`: ghost roster, rarity colors, economy, capture configuration.
- `src/shared/Rules.luau`: pure, executable rules for rewards, placement and progression.
- `src/shared/Visuals.luau`: original part-built ghost and equipment models.
- `src/server`: world, authoritative hunting, profiles, chamber, and orchestration. The main mansion approach intentionally has seven available plots so the path remains clear.
- `src/client`: HUD, collection previews, inputs, suction effects and chamber camera.
- `default.project.json`: Rojo mapping for continued editing.
- `docs/BUILD-BRIEF.md`: the supplied specification.
- `docs/PLAYTEST.md`: runtime acceptance checklist and known limits.

Build with `python tools/build_place.py`. Run `python tools/verify.py` after installing the official [Luau Windows binaries](https://github.com/luau-lang/luau/releases) in `.tools/luau`. The local verifier compiles scripts, runs the rule tests, and checks that the place contains the exact source files.

For repeatable single-player engine tests, run `python tools/build_place.py --test`, open `build/GhostlightHollow.Acceptance.rbxlx`, and press Play. The test runner prints its results to Studio Output. This separate place contains test-only setup and remote controls; do not publish it. The pre-feedback baseline passed 26 checks, alongside ten local rule-test groups; rerun it after future behavior changes. Multiplayer and published persistence remain release checks.

No purchased models or uploaded custom asset IDs are required. Sounds use bundled Roblox effects where available; footsteps use Roblox's standard character audio. Original custom models, bespoke sound design and runtime balance tuning remain polish work.

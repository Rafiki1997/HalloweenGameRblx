# Runtime acceptance checks

## Mesh town checks

Done 2026-09-09: the first ten assets loaded with zero warnings, StreetLamp extents matched Blender to
four decimals (no scale compensation needed), role names survived import, 275 MeshParts.

- [ ] After the remaining 13 uploads: Play once, Output shows `World.build` with no `Asset load failed`
      lines and under 500 MeshParts; the acceptance place still reports 26 passes.
- [ ] Spawn: fountain spirit is blue-white and lit, portal arch behind spawn, altar right, notice board and
      two signposts behind, mesh lamps along every path, nothing floating or sunk.
- [ ] Haunt: walk through the front gate (not around it), stand on the yard, place a ghost and see it on a
      pedestal, GO HOME lands you in front of the gate, spires appear along the roof ridge after upgrades.
- [ ] Mansion: walk up the avenue, one small step onto the lower terrace, up the stair without jumping,
      door prompt at the porch, no gap between hill and facade, towers not overhanging the terrace.
- [ ] Town: three shops face the plaza, the Workshop door opens Upgrades, signs readable, Mira in front
      of the Workshop and Orin by the altar, stalls and barrels not blocking the path to the eighth Haunt.
- [ ] Graveyard: enter through the west gate, headstones in three shapes, two crypts, mist and green light,
      sign by the gate, nothing intersecting the tree ring.
- [ ] Phone portrait and landscape: HUD still fits (independent of meshes) and frame rate holds.

Local verification is not a substitute for Roblox playtesting. A pre-feedback single-client Studio baseline passed 26 automated checks (see STUDIO-ACCEPTANCE.txt). The next run should repeat that fixture against this feedback pass. It used starter capture power, server-driven chase/click calls into the real hunting service, and client RemoteEvent requests for travel, deposit, upgrades, flashlight, chamber and rebirth. The fixture grants money/unlocks to reach late systems and accelerates one chamber reward; this is functional testing, not a balance or manual-input playthrough. Test controls are absent from the shipped place.

Ten local rule-test groups also pass. All nine production scripts compile and the packaged sources match. Desktop startup was inspected. The checklist below deliberately remains open for complete manual release acceptance, including feel, visual quality, multiplayer and real DataStores.

## Fresh player
- [ ] Town, roofs, paths, lamps and signs render; seven available plots leave the mansion approach clear; character spawns safely.
- [ ] One Haunt is assigned and the vacuum is held correctly.
- [ ] Mansion entry opens the free foyer; locked floors reject entry.
- [ ] Ghosts wander and are targetable; walls block initial locks.
- [ ] Repeated clicks progress capture, resistance pushes ghosts away, and inactivity/range/unequipping breaks the beam.
- [ ] Common and higher-rarity captures complete at 100% with compression into the nozzle and a result toast.
- [ ] Flashlight and room switches work and dark areas remain navigable.
- [ ] Full vacuum blocks further captures. Returning and depositing frees capacity without creating copies.
- [ ] Displayed ghosts generate income; removing a ghost reduces income.
- [ ] Upgrades change movement, flashlight, capacity and capture power as described.
- [ ] Sequential floor unlocks charge once and open the appropriate pool.
- [ ] Rebirth requires all areas and the stated cost, confirms, resets temporary upgrades, and preserves owned ghosts.
- [ ] Chamber camera enters/exits and restores after death; placed hunters move, converge on targets and award discoveries.

## Multiplayer and persistence
- [ ] Start a Studio server with at least two clients. Haunts are distinct and each player's displays are visible to the other.
- [ ] Two players cannot lock the same ghost or alter each other's slots.
- [ ] Server rejects unknown action arguments, out-of-range captures, unavailable copies and rapid reward requests.
- [ ] Disconnect during a capture, during profile load, and while in the chamber; plots and sessions clean up.
- [ ] Published test place: leave/rejoin preserves money, bag, collection, placements and upgrades.
- [ ] Overlapping sessions respect the profile lock. Failed loading does not overwrite a profile.
- [ ] Autosave failures warn; loss of a lease prevents further profile mutation.

## Visual and device review
- [ ] Desktop 1920×1080, phone portrait 390×844, phone landscape 844×390, tablet: read HUD, scroll navigation and panels, capture while moving.
- [ ] Verify bundled sound playback, beam visibility, finale animation and model orientation.
- [ ] Check spawn-to-mansion and mansion-to-home transitions, roofs, collisions and camera clipping.
- [ ] Profile frame rate with eight clients. Current budget: 42 wild ghosts at 10 Hz plus chamber hunters at 5 Hz.

## Current implementation limits

- Functional part-built art; custom mesh production and reference-level visual polish remain.
- Mansion progression uses six isolated themed wings reached through the area selector, rather than vertically connected floors.
- The chamber's hunters use simple procedural movement and converge on prey; room-navigation/pathfinding polish remains.
- The leaderboard ranks the current server, not all Roblox servers.
- Audio uses bundled effects; licensed/uploaded ambient, resistance and rare-capture sound assets remain.
- No offline income or attempt to bypass Roblox's idle disconnect behavior.
- Published DataStore round trips, extended balance and all-device visual checks are pending.

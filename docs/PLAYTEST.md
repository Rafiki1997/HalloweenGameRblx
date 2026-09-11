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

## Ghost restyle and label checks (2026-09-10)

- [x] Little Boo loads from asset 130914286159636 and spawns on floor 1. User validated it in a Studio play
      test on 2026-09-10; the server printed "fifteen ghosts" with no "Little Boo model unavailable" warning.
- [ ] COLLECTION previews frame every one of the 15 species fully (wings, antlers, flames, Little Boo's hem).
- [ ] Placed ghosts on plot pedestals and chamber hunters use the restyled models, faces toward the walkway.
- [ ] Labels: only nearby signs show, none overlap on screen, a ghost's name appears only while aimed at it,
      and the shortened plot sign plus separate "$N / sec" hologram read correctly.
- [ ] MeshPart count stays under 500 after the floor-1 spawn settles with several Little Boos alive.
- [ ] Phone landscape: the relocated objective line and shorter nav buttons fit without touching the stats box.

## Landscape checks (2026-09-10)

- [x] Play: the `World.build` line reports the landscape chunk count and its build time. Verified in the
      Halooweenie place 2026-09-10 20:09 after a Rojo sync: 28,224 columns in 64 chunks in 0.45 s, 1,003 primitive
      parts, 441 MeshParts, 12 hillside pines, 130 silhouettes, no errors.
- [x] Probes verified in Halooweenie 2026-09-10 20:51: surface -0.50 at plaza edge, Haunt approach, mansion avenue and
      graveyard; hill 28.65; walkway probe met `Path at 0.50` over Haunt 1 and the avenue.
- [ ] Spawn: level ground across the plaza, walkways, plots, shops, graveyard and mansion avenue; nothing floating or
      sunk. The `Landscape surface probe` line should read -0.50 at the four town spots and the `Walkway probe`
      should meet `Path at 0.50`. Grass blades appear only beyond the tree ring, never through paths or plinths.
- [ ] Walk from the plaza past a Haunt into the hills: the ground rises gently, mesh pines and dark silhouette
      pines stand on the slopes, the two knolls (behind the shops, beyond the graveyard) can be climbed.
- [ ] The rim and the ridge behind the mansion cannot be climbed (character slides back); no route reaches a view
      of the mansion floor boxes to the north.
- [ ] Pond south-east of the plaza: water surface visible with reflections, no water anywhere else, no trees
      standing in the water.
- [ ] Mansion terrace: the ridge reads as a hillside behind the house; boulders sit on the ground.
- [ ] Frame rate holds with the terrain and roughly 260 extra silhouette parts.

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

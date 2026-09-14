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

The 1v1 capture build passed 41 single-client Studio acceptance checks: contact, intro-to-battle transition, timed bonus validation, capture reward, movement/camera/UI restoration, travel, deposit, upgrades, chamber and rebirth. The fixture uses starter capture power, server-driven clicks and weak-spot claims into the actual hunting service, and client RemoteEvent requests for travel and progression. It grants money/unlocks and accelerates one chamber reward. Temporary test runners were removed from the open production place after the run.

All 18 production scripts compile and match their packaged sources; 26 deterministic encounter checks, 11 rule groups and 9 landscape groups pass locally. The desktop battle layout was inspected in Studio, and the client input review recorded a real cursor-triggered +0.12 bonus. The avatar follow-up uses 1.2-second closing rings and a fixed vacuum-ready pose. In Studio, all 16 R15 body parts matched after changing the source rig's animation transforms and facing; the vacuum grip matched the right hand and its nozzle faced forward. The resulting battle pose was visually checked. The checks below remain for broader visual, hardware, multiplayer and persistence acceptance.

## Fresh player
- [x] Run into a mansion ghost: flash, black sweeps and ghost reveal transition to a private 1v1 screen with the hunter, ghost and bottom capture bar.
- [x] Closing circles award +12 percentage points alongside clicks. Early and duplicate claims are rejected; capture rewards once and restores movement, camera and HUD.
- [x] The battle avatar keeps the player's appearance, adopts a fixed stance facing screen-right toward the ghost, and holds a fresh vacuum in its right hand. Rings close in 1.2 seconds.
- [ ] During the intro, capture progress pauses. Mansion movement and attacks stay paused throughout the battle. Q/FLEE releases; death, respawn, travel and disconnect restore movement and remove overlays. Contact cannot immediately retrigger after release (3-second cooldown).
- [ ] On touch, repeatedly tap to capture while holding a finger inside a closing circle. On gamepad, aim with the right stick, click with A/R2 and flee with B. Verify misses, changing targets and moving outside at closure.
- [ ] Full bags, walls, other floors and another hunter's reserved ghost block the encounter. On two clients, only the initiating hunter sees the transition.
- [ ] Review the intro on phone portrait/landscape and desktop: full-screen wipe has no uncovered bands, ghost fits its viewport, dialogue stays readable, HUD returns and camera stays unchanged.
- [ ] Town, roofs, paths, lamps and signs render; seven available plots leave the mansion approach clear; character spawns safely.
- [ ] One Haunt is assigned and the vacuum is held correctly.
- [ ] Mansion entry opens the free foyer; locked floors reject entry.
- [ ] Ghosts wander and are targetable; walls block initial locks.
- [ ] Repeated clicks progress capture while resistance gradually drains progress. Missed circles add no penalty. Fifteen seconds of inactivity, the two-minute limit, travel or unequipping releases the battle.
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

- Desktop encounter and 1v1 behavior were checked in Studio. Hardware touch/gamepad use, small-screen visual review and multiplayer playtests remain pending. Weak-spot ownership, token, timing, finite pointer coordinates and radius are validated on the server; physical cursor position is necessarily reported by the client.

- Functional part-built art; custom mesh production and reference-level visual polish remain.
- Mansion progression uses six isolated themed wings reached through the area selector, rather than vertically connected floors.
- The chamber's hunters use simple procedural movement and converge on prey; room-navigation/pathfinding polish remains.
- The leaderboard ranks the current server, not all Roblox servers.
- Audio uses bundled effects; licensed/uploaded ambient, resistance and rare-capture sound assets remain.
- No offline income or attempt to bypass Roblox's idle disconnect behavior.
- Published DataStore round trips, extended balance and all-device visual checks are pending.

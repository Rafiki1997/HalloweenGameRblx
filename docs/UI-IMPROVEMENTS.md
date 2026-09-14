# Pumpkin Parade UI

Implements the user-selected first concept on `feature/HLWN-3-UI-improvements`.

The game now has an orange-and-purple HUD with eight original illustrated icons, cream Fredoka headings, a contextual quest card, live cash and income, a bonus indicator, rebirth count, vacuum capacity with an explicit FULL state, and illustrated Light/Vacuum controls. Haunt, Mansion, Upgrades and Rebirth occupy the left rail; Collection is emphasized at the bottom. Small landscape layouts use a two-column navigation cluster; portrait layouts use shorter controls and a vertically stacked collection/capacity group.

All five menus share the palette and framing. Collection uses a responsive grid with live 3D ghost portraits and undiscovered cards. Menu rows expand for wrapped text. Locked/MAX buttons are visibly disabled. The existing rebirth confirmation remains. Menus suppress gameplay controls and restore them on close, travel, encounters and respawn. Desktop F/click and controller X/RT remain; controller Y opens Collection and B closes a menu. Touch controls show TAP hints.

The HUD uses the [Roblox core UI safe area](https://create.roblox.com/docs/ui/on-screen-containers) to reserve the platform top bar and device insets. Camera, world design and progression rules are unchanged. The separate encounter/battle presentation keeps its existing treatment.

## Validation

- 27 production Luau scripts compile and match the rebuilt place exactly.
- Eight pure layout profiles: 1920x1020, 1366x710, 1050x560, 1024x710, 844x330, 667x310, 390x744, 320x520; all major HUD regions fit without mutual overlaps, action targets exceed 44px.
- 89 Studio UI assertions pass: actual server state, uploaded atlas loaded, engine-computed rectangles for all eight profiles, all five menu open/close flows, phone text fit, two-column phone collection, loaded 3D portrait, FULL warning and server restoration.
- Existing economy (11 groups), hunting (28 checks), landscape/route checks and seven Python tests pass.
- Screenshots in `build/ui-review/`: desktop HUD, Collection, landscape layout and portrait Mansion layout. Phone screenshots exercise a constrained safe-area Frame in Studio; they are not physical-device screenshots. Hardware touch and controller input still warrant device playtesting.

## Reproduce

Run `python tools/build_place.py` for the production place, then reopen `build/GhostlightHollow.rbxlx` and Play. Close stale open tabs with Don't Save before reopening the generated file.

Run `python tools/build_place.py --ui-preview` for an isolated `GhostlightHollow-UIPreview.rbxlx`. Its QA-only script validates layouts and menus, temporarily frames the plaza for screenshots, then restores the camera and normal HUD. No preview controls ship in the production build.

Generated art, prompt and uploaded asset ID are recorded in `assets/ui/pumpkin-parade/README.md`. Concept drafts remain in `docs/ui-concepts/`.

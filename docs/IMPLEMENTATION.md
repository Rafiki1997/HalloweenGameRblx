# Ghostlight Hollow implementation

Town mesh pipeline update: five deterministic Blender props, FBX exports, previews, ID harvesting,
generated AssetIds and a server loader are implemented. Packaging now recurses through shared
subfolders. Uploaded IDs are still pending; World preserves primitive props until IDs are supplied.
See ASSETS.md for upload instructions and the limited 117-MeshPart first-batch layout.

The user-approved build brief is BUILD-BRIEF.md. Visual references are the three HalloweenGameImage PNGs supplied by the user. This is a new project; use original part-built assets with blue/purple moonlight and warm lanterns.

Architecture: shared configuration and pure rules; server services for profiles, world, hunts, plots, chamber and requests; client HUD and effects. Clients send intentions only. A Python packager produces an openable rbxlx containing the same sources as the Rojo project. World geometry is generated deterministically on server startup.

Decisions: eight social plots, six separately gated mansion wings, two original ghosts per rarity, one dollar currency. Captures immediately record discovery and ownership but remain in the vacuum until deposited. Rebirth preserves owned ghosts and discovery, clears equipment and slots, and increases income by 0.5x. Chamber runs only while connected and in chamber mode, with placed ghosts as hunters. No offline reward or artificial anti-idle behavior.

Implementation sequence:
- [x] Pure rules and tests: capture, inventory/deposit/slots, upgrade costs, unlocks, rebirth, reward eligibility.
- [x] Core hunting: tool, wandering/resisting ghosts, authoritative click capture, escape, client suction finale.
- [x] World: circular town, eight plots, six mansion wings, light switches, flashlight and decor.
- [x] Economy: placement, income, equipment and haunt upgrades, floor access, rebirth.
- [x] Chamber: miniature rooms, autonomous hunters, periodic server rewards, top-down camera.
- [x] Profiles implemented: lease-based UpdateAsync, retries, autosave, leave/shutdown protection, safe Studio memory mode. Published network validation remains pending.
- [x] Client: responsive HUD, collection previews, actions, capture feedback, chamber controls.
- [x] Package and local verification: nine scripts compile, ten rule groups pass, sources match packaged place.
- [x] Single-client Studio baseline: 26 automated checks passed before this feedback pass; repeat against the current build before release.
- [ ] Multi-client, published persistence, all-device visual QA and extended balance testing.

Verification distinguishes local compilation/logic checks from Roblox runtime tests. Studio was subsequently launched and the single-client acceptance runner completed. Desktop startup was visually inspected; full manual and mobile playtesting remain in PLAYTEST.md.

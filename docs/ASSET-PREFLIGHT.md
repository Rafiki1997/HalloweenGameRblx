# Town asset preflight — 2026-09-09

## Verified

- Branch: `ghostlight-feedback-pass`; pre-asset checkpoint: `a7d1f53`.
- Blender 5.1.2 headless FBX export passes. Output:
  `assets/exports/preflight_cube.fbx`, 12,124 bytes. This is a disposable calibration cube,
  not an asset for upload.
- Add-on enabled: True. Saved login present: False. API key present: False.
  No credential values were printed, copied, or persisted by this check.
- Human upload lane selected. Intended creator: personal account `1445842194`, subject to
  confirmation in Blender's Upload to dropdown. The actual selected creator is not yet verified.
- Weppy workspace query passes: Terrain and Camera. The queried session is `studio-2`,
  place ID `81235367075585`, reported name `Place2`; ServerScriptService contains GhostlightServer.
  This establishes connectivity, not equality with the newly rebuilt local place.
- Local verification: nine production scripts compile, ten rule-test groups pass, packaged
  production sources match. Both production and acceptance places build successfully.
- No new Studio acceptance run has been performed in this stage.

## Decisions needed before modelling

Blender process 39556 is open with an unsaved scene. The user must save any desired work and close
it before town.blend generation. The current session may retain the successful login in memory;
the headless check only establishes that the saved preference is empty.

The 120 MeshPart cap conflicts with separately instanced, role-separated scenery. A conservative
lower bound, even giving each tree only one visible mesh, is:

| Scenery | Instances | Minimum visible meshes each | Total |
| --- | ---: | ---: | ---: |
| Tree ring | 58 | 1 | 58 |
| Haunts: Wood, Roof, Accent, Foliage, Metal, Glow | 7 | 6 | 42 |
| Grave markers | 18 | 1 | 18 |
| Avenue street lamps: Metal, Glow | 12 | 2 | 24 |
| **Subtotal** | | | **142** |

This excludes collision meshes, pine foliage as an additional role, fountain, portal, altar,
mansion, shops, caretakers, fence, crypts, props, and extra hillside trees. Even if the seeded ring
skips up to ten trees to clear the northern approach, this subtotal remains 132.

Options presented to the user: raise the cap to 500 MeshParts while retaining all other budgets,
or retain 120 and revise scenery counts/batching. The new limit is not approved yet. Counting
unique meshes instead of placed MeshPart instances would not satisfy the original limit.

## Next stage

Update: Blender subsequently closed. The first five props are built and saved in town.blend,
with previews and runtime integration prepared. Full-tree replacement remains deferred, keeping
the first uploaded batch at 117 MeshParts. See ASSETS.md for current state; the original full-town
budget decision remains outstanding.

After the two decisions, execute `docs/superpowers/plans/2026-09-09-town-assets.md`, starting with
the small props. Build and inspect actual previews before requesting any upload. Do not replace
the existing town with incomplete assets.

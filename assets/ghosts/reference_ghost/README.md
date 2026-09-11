# Reference ghost

New standalone ghost based on the user's September 10 image: a periwinkle sheet body, blended arms, waving hem, glossy eyes, rose cheeks, and smiling mouth.

- `ReferenceGhost.blend`: editable source model; six material groups, UV mapped.
- `ReferenceGhost.fbx`: export using the installed Roblox Blender add-on's axis and scale settings.
- `front.png`, `three-quarter.png`, `back.png`: rendered inspection views.
- `model-info.json`: geometry count and intended size (approximately 4 studs tall).

The body is a continuous closed mesh. Face details are separate material meshes. This model is static and unrigged.

Integrated as **Little Boo** (`little_boo`), the fifteenth species. It is Common, earns $3/sec when placed, and joins the first-floor spawn pool with weight 30. Existing species retain their IDs and progression values.

Roblox Model asset: **130914286159636**, uploaded under user 1445842194 through the installed Blender add-on. `upload-status.json` is the upload receipt. `LittleBoo.uploaded.blend` preserves the uploaded collection and asset ID. The game loads this asset once on the server into `ReplicatedStorage.Ghostlight.GhostModelTemplates` and uses the same template for hunts, placed ghosts, chamber ghosts, and collection previews. If Roblox cannot deliver the model, the existing roster still starts and Little Boo temporarily drops out of the spawn pool.

Rebuild with Blender in background mode using `tools/blender/build_reference_ghost.py`. This uses a separate file and leaves the town scene alone. Validate size in Roblox's import preview; the FBX uses the add-on's 0.01 export scale and will look smaller if reimported into Blender without compensating for that scale.

Validation: exported FBX reimported successfully with 6 meshes, 12,704 triangles, UV maps on every mesh, and a closed manifold body.

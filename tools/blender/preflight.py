"""Run with Blender --background --python-exit-code 1 --python tools/blender/preflight.py.

Writes only the disposable smoke-test export beneath the repository. Credential
inspection is limited to the boolean explicitly requested by the asset brief.
"""
from pathlib import Path
import os
import bpy

ROOT = Path(__file__).resolve().parents[2]
addon = bpy.context.preferences.addons.get('roblox-blender-plugin')
print('addon_enabled=' + str(addon is not None))
print('logged_in=' + str(bool(addon and addon.preferences.refresh_token)))
print('api_key_present=' + str(bool(os.environ.get('ROBLOX_API_KEY'))))
assert addon is not None, 'Upload to Roblox is not enabled'

# This runs in a separate disposable process and never saves preferences or a blend.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
collection = bpy.data.collections.new('PreflightCube')
bpy.context.scene.collection.children.link(collection)
bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[collection.name]
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
bpy.context.object.name = 'PreflightCube_Stone'
output = ROOT / 'assets/exports/preflight_cube.fbx'
output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.fbx(
    filepath=str(output), global_scale=0.01, axis_forward='-Z', axis_up='Y',
    apply_unit_scale=True, bake_space_transform=True, use_mesh_modifiers=True,
    mesh_smooth_type='FACE', object_types={'MESH'}, use_active_collection=True,
    use_custom_props=True, bake_anim=False,
)
assert output.is_file() and output.stat().st_size > 0
print(f'fbx_smoke=PASS bytes={output.stat().st_size} path={output.relative_to(ROOT)}')

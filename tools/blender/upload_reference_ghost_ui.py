"""Run inside the existing Blender UI. Uses the add-on's normal upload operation.
Keeps the unsaved town scene intact; never reads or copies authentication data.
"""
import bpy
import importlib
import json
import time
from pathlib import Path
ROOT=Path('C:/Users/rahul/orca/projects/Halloween Roblox game')
OUT=ROOT/'assets/ghosts/reference_ghost'
status_path=OUT/'upload-status.json'
def status(**data): status_path.write_text(json.dumps(data,indent=2))
started=time.monotonic()
constants=importlib.import_module('roblox-blender-plugin.lib.constants')
upload=importlib.import_module('roblox-blender-plugin.lib.upload_operator')
wm=bpy.context.window_manager
# Initialize the add-on's normal UI session, as its Roblox sidebar does on first draw.
importlib.import_module('roblox-blender-plugin.lib.creator_details').load_creator_details(wm,bpy.context.preferences)
status(state='awaiting_login',name='LittleBoo')
bpy.ops.rbx.oauth2login()
def begin_upload():
    global started,window,area,scene,collection,previous_scene
    if not wm.rbx.is_logged_in: return 1.0
    window=wm.windows[0]
    area=next(a for a in window.screen.areas if a.type=='VIEW_3D')
    previous_scene=window.scene
    scene=bpy.data.scenes.new('ReferenceGhostUpload')
    with bpy.data.libraries.load(str(OUT/'ReferenceGhost.blend'),link=False) as (source,target):
        target.collections=['ReferenceGhost']
    collection=target.collections[0]; collection.name='LittleBoo'
    scene.collection.children.link(collection)
    window.scene=scene
    scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
    creator=next((c for c in wm.rbx.creators if c.id=='1445842194'),None)
    if creator is None:
        status(state='failed',reason='Expected creator account is not authorized')
        return None
    wm.rbx.creator=creator.id
    wm.rbx.num_objects_uploading=1
    started=time.monotonic()
    status(state='uploading',name=collection.name)
    upload.RBX_OT_upload.upload(wm,area,scene,scene.view_layers[0],bpy.context.preferences,collection)
    bpy.app.timers.register(finish,first_interval=1)
    return None
def finish():
    if wm.rbx.num_objects_uploading and time.monotonic()-started<180: return 1.0
    asset_id=str(collection.get(constants.RBX_PACKAGE_ID_PROPERTY_NAME,'') or '')
    status(state='complete' if asset_id.isdigit() else 'failed',assetId=asset_id)
    # Save only the new model scene; the original town's unsaved state is preserved.
    if asset_id.isdigit():
        bpy.data.libraries.write(str(OUT/'LittleBoo.uploaded.blend'),{scene},fake_user=True)
    window.scene=previous_scene
    area.type='VIEW_3D'
    return None
bpy.app.timers.register(begin_upload,first_interval=1)

"""Render first-zone props without opening or saving the user's town.blend."""
import argparse
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from build_assets import ROOT, build

parser=argparse.ArgumentParser()
parser.add_argument('--out',default='assets')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
out=ROOT/args.out
manifest=build(out,save=False)
scene=bpy.context.scene
scene.render.engine='BLENDER_WORKBENCH'
scene.render.resolution_x=640
scene.render.resolution_y=640
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.display.shading.light='STUDIO'
scene.display.shading.color_type='MATERIAL'
scene.display.shading.show_shadows=True
scene.display.shading.show_cavity=True
scene.display.shading.cavity_type='BOTH'
scene.display.shading.background_type='WORLD'
scene.world.color=(.014,.025,.065)
scene.view_settings.view_transform='Standard'
camera_data=bpy.data.cameras.new('PreviewCamera')
camera=bpy.data.objects.new('PreviewCamera',camera_data)
scene.collection.objects.link(camera)
scene.camera=camera
camera_data.type='ORTHO'
(out/'previews').mkdir(exist_ok=True)
for name,metadata in manifest['assets'].items():
    if name not in bpy.data.collections: continue
    for layer in bpy.context.view_layer.layer_collection.children:
        layer.exclude=layer.name!=name
    for obj in bpy.data.collections[name].objects:
        obj.hide_render=obj['Role']=='Collision'
    width,height,depth=metadata['footprint']
    centre=Vector((0,0,height/2))
    radius=max(width,height,depth)
    for view, direction in [('front',(1.4,-2,1.1)),('top',(0,-.001,1))]:
        camera.location=centre+Vector(direction).normalized()*radius*3
        camera.rotation_euler=(centre-camera.location).to_track_quat('-Z','Y').to_euler()
        bpy.context.view_layer.update()
        inverse=camera.matrix_world.inverted()
        projected=[inverse@(obj.matrix_world@v.co)
                   for obj in bpy.data.collections[name].objects if not obj.hide_render
                   for v in obj.data.vertices]
        camera_data.ortho_scale=max(max(abs(v.x),abs(v.y)) for v in projected)*2.25
        scene.render.filepath=str(out/'previews'/f'{name}_{view}.png')
        bpy.ops.render.render(write_still=True)
        print('PREVIEW '+name+' '+view)

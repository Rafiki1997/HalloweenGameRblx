"""Build an independent smooth ghost from the user's September 10 image reference.
Run in a separate background Blender process; never changes town.blend.
"""
from pathlib import Path
import math
import json
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/ghosts/reference_ghost'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='METRIC'
scene.unit_settings.scale_length=1
collection=bpy.data.collections.new('ReferenceGhost')
scene.collection.children.link(collection)

def material(name,color,roughness=.4,metallic=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=roughness
    p.inputs['Metallic'].default_value=metallic
    return m

body_mat=material('Pearlescent periwinkle',(0.57,.66,.94),.32)
body_mat.node_tree.nodes.get('Principled BSDF').inputs['Subsurface Weight'].default_value=.07
eyes_mat=material('Glossy midnight eyes',(.008,.013,.028),.12)
mouth_mat=material('Smile velvet',(.039,.014,.058),.36)
pink_mat=material('Rose blush',(.83,.37,.63),.6)
tongue_mat=material('Berry tongue',(.53,.16,.46),.36)
white_mat=material('Eye glints',(.94,.97,1),.16)

def relocate(obj,mat):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    collection.objects.link(obj)
    obj.data.materials.append(mat)
    for p in obj.data.polygons: p.use_smooth=True
    return obj

def ellipsoid(name,pos,size,mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=16,location=pos)
    o=bpy.context.object; o.name=name; o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return relocate(o,mat)

# A hollow sheet with a softly waving hem; the closed underside is recessed above its lip.
profile=[(.10,1.64,1.01),(.18,1.69,1.04),(.42,1.63,1.02),(.85,1.52,.99),
         (1.3,1.43,.97),(1.8,1.39,.97),(2.35,1.35,.95),(2.8,1.29,.92),
         (3.15,1.19,.86),(3.48,1.01,.74),(3.76,.76,.57),(3.97,.42,.32),(4.05,.08,.07)]
verts=[]; faces=[]; n=64
for z,rx,ry in profile:
    for i in range(n):
        a=i*2*math.pi/n
        hem=math.exp(-z*2.0)
        fold=1+.028*math.cos(7*a+.35)*max(0,1-z/2.8)
        verts.append((rx*math.cos(a)*fold,ry*math.sin(a)*fold,z+.085*math.cos(5*a+.3)*hem))
for j in range(len(profile)-1):
    for i in range(n):
        a=j*n+i; b=j*n+(i+1)%n
        faces.append((a,b,b+n,a+n))
faces.append(tuple(reversed(range(n))))
faces.append(tuple((len(profile)-1)*n+i for i in range(n)))
mesh=bpy.data.meshes.new('Flowing sheet'); mesh.from_pydata(verts,[],faces); mesh.update()
body=bpy.data.objects.new('ReferenceGhost_Body',mesh); collection.objects.link(body)
body.data.materials.append(body_mat)
bpy.context.view_layer.objects.active=body; body.select_set(True)
sub=body.modifiers.new('Silhouette smoothing','SUBSURF'); sub.levels=2
bpy.ops.object.modifier_apply(modifier=sub.name)
arms=[]
for s in (-1,1):
    arm=ellipsoid('Arm blend',(s*1.48,0,1.56),(.65,.47,.43),body_mat)
    arm.rotation_euler[1]=s*.43
    arms.append(arm)
    arms.append(ellipsoid('Rounded mitten',(s*1.94,-.07,1.32),(.31,.44,.44),body_mat))
bpy.ops.object.select_all(action='DESELECT')
for o in [body]+arms: o.select_set(True)
bpy.context.view_layer.objects.active=body; bpy.ops.object.join()
remesh=body.modifiers.new('Seamless arm transitions','REMESH'); remesh.mode='VOXEL'; remesh.voxel_size=.045
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=body.modifiers.new('Soft cloth surface','SMOOTH'); smooth.factor=.7; smooth.iterations=5
bpy.ops.object.modifier_apply(modifier=smooth.name)
decimate=body.modifiers.new('Game mesh','DECIMATE')
decimate.ratio=min(1,5200/(len(body.data.polygons)*2))
bpy.ops.object.modifier_apply(modifier=decimate.name)
for p in body.data.polygons: p.use_smooth=True

for s in (-1,1):
    eye=ellipsoid('ReferenceGhost_Eye', (s*.56,-.862,2.66),(.245,.17,.37),eyes_mat)
    eye.rotation_euler[1]=s*.12
    ellipsoid('ReferenceGhost_Glint',(s*.56-.065,-1.02,2.83),(.061,.027,.085),white_mat)
    ellipsoid('ReferenceGhost_GlintSmall',(s*.56+.075,-1.02,2.52),(.024,.016,.029),white_mat)
    ellipsoid('ReferenceGhost_Cheek',(s*.85,-.775,2.17),(.20,.038,.088),pink_mat)

# Concave upper lip and rounded lower lip form a happy open smile, not an oval hole.
outline=[(-.23,2.22),(-.14,2.20),(-.07,2.215),(0,2.19),(.08,2.22),(.17,2.225),
         (.23,2.23),(.235,2.15),(.19,2.05),(.105,1.98),(0,1.96),(-.105,1.985),(-.19,2.065),(-.225,2.15)]
curved=[]
for i in range(len(outline)):
    a=Vector(outline[(i-1)%len(outline)]); b=Vector(outline[i])
    c=Vector(outline[(i+1)%len(outline)]); d=Vector(outline[(i+2)%len(outline)])
    for step in range(4):
        t=step/4
        p=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
        curved.append(tuple(p))
outline=curved
vs=[(x,-1.012,z) for x,z in outline]+[(0,-1.012,2.10)]
fs=[(len(outline),i,(i+1)%len(outline)) for i in range(len(outline))]
me=bpy.data.meshes.new('Smiling mouth'); me.from_pydata(vs,[],fs); me.update()
mouth=bpy.data.objects.new('ReferenceGhost_Smile',me); collection.objects.link(mouth); mouth.data.materials.append(mouth_mat)
for face in me.polygons: face.use_smooth=True
solid=mouth.modifiers.new('Lip thickness','SOLIDIFY'); solid.thickness=.025
bevel=mouth.modifiers.new('Rounded lip','BEVEL'); bevel.width=.022; bevel.segments=3
ellipsoid('ReferenceGhost_Tongue',(0,-1.043,2.04),(.102,.022,.053),tongue_mat)

# Consolidate by material: a small, predictable number of Roblox MeshParts.
for mat in [body_mat,eyes_mat,mouth_mat,pink_mat,tongue_mat,white_mat]:
    objs=[o for o in collection.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==mat]
    if not objs: continue
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    for o in objs:
        bpy.context.view_layer.objects.active=o
        for modifier in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join()
    o=bpy.context.object; o.name='ReferenceGhost_'+mat.name.replace(' ','')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.02); bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
for o in collection.objects: o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'ReferenceGhost.fbx'),use_selection=True,
    global_scale=.01,axis_forward='-Z',axis_up='Y',apply_unit_scale=True,
    bake_space_transform=True,object_types={'MESH'},mesh_smooth_type='FACE',bake_anim=False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ReferenceGhost.blend'))
triangles=0
for o in collection.objects:
    o.data.calc_loop_triangles(); triangles+=len(o.data.loop_triangles)
metadata={'name':'ReferenceGhost','triangles':triangles,'meshParts':len(collection.objects),
          'front':'Blender -Y','heightStuds':4.05,'source':'User image reference, September 10 2026'}
(OUT/'model-info.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('MODEL',json.dumps(metadata),flush=True)

# Studio-style turntable render, kept out of the exported model collection.
scene.render.engine='CYCLES'; scene.cycles.samples=48
scene.render.resolution_x=900; scene.render.resolution_y=900; scene.render.resolution_percentage=100
scene.world.color=(.10,.10,.12)
scene.view_settings.view_transform='AgX'
def aim(o,at): o.rotation_euler=(Vector(at)-o.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Soft key',(-4,-6,7),700,5),('Blue rim',(4,2,5),900,4),('Face fill',(3,-4,3),180,3)]:
    data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.shape='DISK'; data.size=size
    o=bpy.data.objects.new(name,data); scene.collection.objects.link(o); o.location=loc; aim(o,(0,0,2))
bpy.ops.object.camera_add(location=(.7,-10,4.1)); camera=bpy.context.object
camera.data.type='ORTHO'; camera.data.ortho_scale=5.5; aim(camera,(0,0,2)); scene.camera=camera
scene.render.image_settings.file_format='PNG'
for name,loc in [('front',(.4,-10,3.5)),('three-quarter',(6,-9,4.3)),('back',(4,9,4))]:
    camera.location=loc; aim(camera,(0,0,2)); scene.render.filepath=str(OUT/(name+'.png'))
    bpy.ops.render.render(write_still=True)
print('DONE reference ghost',flush=True)

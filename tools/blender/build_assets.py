"""Deterministic first-zone town props. Blender --background --python ... -- --out assets.

--no-save exports meshes/metadata without touching town.blend while the user has Blender open.
Blender coordinates are X right, Y depth, Z height; manifest footprints are Roblox X,Y,Z.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
PALETTE = {'Stone': (51,49,65), 'Wood': (62,43,58), 'Metal': (43,40,57),
           'Glow': (255,188,104), 'Foliage': (25,43,43), 'Accent': (255,140,60),
           'Collision': (220,50,80)}
BUDGETS = {'StreetLamp':300, 'Gravestone':150, 'PineTree':400, 'DeadTree':600, 'Pumpkin':300}
ACTIVE = None
ASSET = None


def role(obj, name):
    obj['Role'] = name
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = (*[v / 255 for v in PALETTE[name]], 1)
    obj.data.materials.clear()
    obj.data.materials.append(material)
    obj.color = material.diffuse_color
    obj.name = f'{ASSET}_{name}'
    return obj


def box(name, center, size):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.scale = size
    return role(obj, name)


def taper(name, center, depth, r1, r2, sides=6):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=r1, radius2=r2,
                                  depth=depth, end_fill_type='NGON', location=center)
    return role(bpy.context.object, name)


def branch(a, b, radius, tip):
    start, end = Vector(a), Vector(b)
    obj = taper('Wood', (start+end)/2, (end-start).length, radius, tip, 6)
    obj.rotation_euler = (end-start).to_track_quat('Z', 'Y').to_euler()


def street_lamp():
    taper('Metal',(0,0,.2),.4,.6,.48)
    taper('Metal',(0,0,.7),.6,.34,.23)
    taper('Metal',(0,0,3.5),5,.21,.13)
    taper('Metal',(0,0,6.05),.18,.48,.48,4)
    taper('Glow',(0,0,6.8),1.3,.28,.44,4)
    for x in (-.31,.31):
        for y in (-.31,.31):
            box('Metal',(x,y,6.8),(.085,.085,1.5))
    taper('Metal',(0,0,7.55),.2,.68,.68,4)
    taper('Metal',(0,0,7.98),.65,.72,.08,4)
    taper('Metal',(0,0,8.5),.4,.12,.01)
    box('Collision',(0,0,3),(.5,.5,6))


def gravestone():
    box('Stone',(0,0,.18),(3,1.6,.36))
    outline=[(-1.15,.36),(1.15,.36),(1.15,2.2)]
    outline += [(1.15*math.cos(i*math.pi/6),2.2+.9*math.sin(i*math.pi/6)) for i in range(1,7)]
    vertices=[(x,y,z) for y in (-.325,.325) for x,z in outline]
    count=len(outline)
    faces=[tuple(reversed(range(count))),tuple(range(count,count*2))]
    faces += [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
    mesh=bpy.data.meshes.new('ArchedStone')
    mesh.from_pydata(vertices,[],faces)
    obj=bpy.data.objects.new('ArchedStone',mesh)
    bpy.context.collection.objects.link(obj)
    role(obj,'Stone')
    box('Stone',(0,-.35,1.6),(.21,.12,1.05))
    box('Stone',(0,-.35,1.8),(.9,.12,.18))
    box('Collision',(0,0,1.6),(2.3,.65,3.2))


def pine():
    taper('Wood',(0,0,4),8,.65,.3,7)
    for height, radius, depth in ((7,4.5,6),(10.5,3.5,6),(14,2.5,6)):
        taper('Foliage',(0,0,height),depth,radius,.05,9)
    box('Collision',(0,0,3),(.9,.9,6))


def dead_tree():
    branch((0,0,0),(.25,0,4),.65,.42)
    branch((.25,0,4),(-.6,.2,7.5),.42,.23)
    branch((-.6,.2,7.5),(.1,.2,10.5),.23,.02)
    for a,b,c in [((.15,0,3),(-2,.2,5),(-3.2,.5,7)),
                  ((-.2,0,5),(2,.5,6.3),(3.1,.5,8.5)),
                  ((-.5,.2,7),(-2,-.2,8.5),(-2.4,-.4,10)),
                  ((0,0,4),(.3,-2,6),(.5,-2.8,8))]:
        branch(a,b,.27,.15)
        branch(b,c,.15,.025)
        mid=Vector(b).lerp(Vector(c),.35)
        branch(mid,mid+Vector((.7,.3,1.1)),.09,.015)
    for i in range(4):
        angle=i*math.pi/2
        branch((0,0,.65),(math.cos(angle)*1.2,math.sin(angle)*1.2,.07),.25,.06)
    box('Collision',(0,0,3),(.85,.85,6))


def pumpkin():
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=6, radius=1)
    obj=bpy.context.object
    for v in obj.data.vertices:
        theta=math.atan2(v.co.y,v.co.x)
        lobes=1+.08*math.cos(6*theta)
        v.co.x*=1.35*lobes
        v.co.y*=1.35*lobes
        v.co.z=v.co.z*.95+.95
    role(obj,'Accent')
    taper('Glow',(0,0,1.89),.12,.27,.27,8)
    stem=taper('Wood',(0,0,2.18),.55,.17,.095,6)
    stem.rotation_euler.y=.22
    box('Collision',(0,0,.85),(1.6,1.6,1.7))


BUILDERS = {'StreetLamp':street_lamp,'Gravestone':gravestone,'PineTree':pine,
            'DeadTree':dead_tree,'Pumpkin':pumpkin}


def finalize(collection):
    for material_role in sorted({o['Role'] for o in collection.objects}):
        bpy.ops.object.select_all(action='DESELECT')
        objects=[o for o in collection.objects if o['Role']==material_role]
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.convert(target='MESH')
        if len(objects)>1:
            bpy.ops.object.join()
        obj=bpy.context.object
        obj.name=f'{collection.name}_{material_role}'
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        bpy.context.scene.cursor.location=(0,0,0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.triangulate(bm,faces=list(bm.faces),quad_method='FIXED',ngon_method='EAR_CLIP')
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        assert all(e.is_manifold for e in bm.edges), f'{obj.name}: open or nonmanifold edges'
        assert all(f.calc_area()>1e-9 for f in bm.faces), f'{obj.name}: degenerate triangle'
        assert bm.calc_volume(signed=True)>0, f'{obj.name}: invalid volume'
        assert len(bm.faces)<=20000, f'{obj.name}: exceeds 20,000 triangles'
        bm.to_mesh(obj.data)
        bm.free()
        obj.data.update()
        obj.hide_render=material_role=='Collision'
        obj.display_type='WIRE' if material_role=='Collision' else 'TEXTURED'
    vertices=[o.matrix_world@v.co for o in collection.objects for v in o.data.vertices]
    low=Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
    high=Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
    base=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    for obj in collection.objects:
        for vertex in obj.data.vertices: vertex.co-=base
    size=high-low
    triangles=sum(len(o.data.polygons) for o in collection.objects)
    assert triangles<=BUDGETS[collection.name], f'{collection.name}: {triangles} > {BUDGETS[collection.name]}'
    # Hash geometry independently of Blender's internal face/vertex allocation order.
    geometry=[]
    for obj in sorted(collection.objects,key=lambda o:o.name):
        triangles_coordinates=[]
        for face in obj.data.polygons:
            coords=[tuple(round(c,6) for c in obj.data.vertices[i].co) for i in face.vertices]
            rotations=[coords[i:]+coords[:i] for i in range(3)]
            triangles_coordinates.append(min(rotations))
        geometry.append((obj.name,sorted(triangles_coordinates)))
    return {'zone':'Props','footprint':[round(size.x,5),round(size.z,5),round(size.y,5)],
            'roles':sorted({o['Role'] for o in collection.objects}),
            'triangleBudget':BUDGETS[collection.name],'triangles':triangles,
            'meshCount':len(collection.objects),
            'geometrySha256':hashlib.sha256(json.dumps(geometry,sort_keys=True).encode()).hexdigest()}


def build(out, save=True):
    global ASSET
    out=out.resolve()
    assert out.is_relative_to(ROOT), 'Output must stay inside workspace'
    manifest_path=out/'manifest.json'
    manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'schemaVersion':1,'assets':{}}
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections): bpy.data.collections.remove(collection)
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene.unit_settings.scale_length=1
    exports=out/'exports'
    exports.mkdir(parents=True,exist_ok=True)
    for name, builder in BUILDERS.items():
        ASSET=name
        collection=bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
        bpy.context.view_layer.active_layer_collection=bpy.context.view_layer.layer_collection.children[name]
        builder()
        metadata=finalize(collection)
        previous=manifest['assets'].get(name,{})
        if previous.get('assetId'): collection['Roblox Package ID']=str(previous['assetId'])
        target=exports/f'{name}.fbx'
        bpy.ops.export_scene.fbx(filepath=str(target),global_scale=.01,axis_forward='-Z',axis_up='Y',
            apply_unit_scale=True,bake_space_transform=True,use_mesh_modifiers=True,
            mesh_smooth_type='FACE',object_types={'MESH'},use_active_collection=True,
            use_custom_props=True,bake_anim=False)
        assert target.stat().st_size<20*1024*1024
        metadata.update(assetId=previous.get('assetId',0),uploadedAt=previous.get('uploadedAt'),
                        sha256=previous.get('sha256'),
                        exportSha256=hashlib.sha256(target.read_bytes()).hexdigest())
        manifest['assets'][name]=metadata
        print(f"ASSET {name}: {metadata['triangles']} triangles / {BUDGETS[name]}, {metadata['meshCount']} meshes")
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    # Keep every collection enabled so the add-on can export any selected collection.
    # Assets share a base-centred origin; isolate a collection to inspect it in the UI.
    for layer in bpy.context.view_layer.layer_collection.children:
        layer.exclude=False
    bpy.ops.object.select_all(action='DESELECT')
    if save:
        bpy.ops.wm.save_as_mainfile(filepath=str(out/'town.blend'))
    return manifest


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--out',default='assets')
    parser.add_argument('--no-save',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    build(ROOT/args.out,save=not args.no_save)

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


def mesh_object(name, vertices, faces, smooth=False):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(obj)
    role(obj,name)
    if smooth:
        for face in mesh.polygons: face.use_smooth=len(face.vertices)==4
    return obj


def loft(name, rings, smooth=False):
    """Join equal-sized polygon rings into a closed surface, retaining cap normals."""
    count=len(rings[0])
    vertices=[tuple(v) for ring in rings for v in ring]
    faces=[tuple(reversed(range(count)))]
    for level in range(len(rings)-1):
        for i in range(count):
            a=level*count+i; b=level*count+(i+1)%count
            faces.append((a,b,b+count,a+count))
    faces.append(tuple(range((len(rings)-1)*count,len(rings)*count)))
    return mesh_object(name,vertices,faces,smooth)


def sweep(points, radii, sides=6):
    """A continuous tapered branch: no disconnected cylinder joints."""
    points=[Vector(p) for p in points]
    rings=[]
    previous_tangent=None
    radial=Vector((1,0,0))
    for i,(p,radius) in enumerate(zip(points,radii)):
        tangent=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
        if previous_tangent is None:
            if abs(radial.dot(tangent))>.95: radial=Vector((0,1,0))
            radial=(radial-tangent*radial.dot(tangent)).normalized()
        else:
            radial=previous_tangent.rotation_difference(tangent)@radial
        perpendicular=tangent.cross(radial).normalized()
        rings.append([p+radius*(radial*math.cos(j*2*math.pi/sides)+
                               perpendicular*math.sin(j*2*math.pi/sides)) for j in range(sides)])
        previous_tangent=tangent
    return loft('Wood',rings,smooth=True)


def turned(name, levels, sides=8, phase=0, smooth=False):
    return loft(name,[[(r*math.cos(phase+i*2*math.pi/sides),
                        r*math.sin(phase+i*2*math.pi/sides),z) for i in range(sides)]
                      for z,r in levels],smooth)


def street_lamp():
    # Chamfered foot, cast plinth and a single continuous fluted shaft.
    turned('Metal',[(0,.52),(.1,.62),(.25,.62),(.34,.47),(.85,.29),
                    (1.05,.23),(5.65,.15),(5.82,.27),(6,.36)],sides=6)
    turned('Metal',[(5.94,.48),(6.09,.56),(6.19,.47)],sides=4,phase=math.pi/4)
    turned('Glow',[(6.13,.38),(7.35,.55)],sides=4,phase=math.pi/4)
    # Rails follow the lantern's taper and meet its corners.
    for x,y in [(-1,-1),(-1,1),(1,-1),(1,1)]:
        start=Vector((x*.28,y*.28,6.08)); end=Vector((x*.40,y*.40,7.42))
        rail=box('Metal',(start+end)/2,(.1,.1,(end-start).length))
        rail.rotation_euler=(end-start).to_track_quat('Z','Y').to_euler()
    turned('Metal',[(7.37,.64),(7.50,.69),(7.59,.62),(7.79,.38),(8.10,.13)],sides=4,phase=math.pi/4)
    turned('Metal',[(8.03,.14),(8.22,.19),(8.60,.015)],sides=4,phase=math.pi/4)
    box('Collision',(0,0,2.95),(.55,.55,5.9))


def gravestone():
    # Chamfered eight-corner footing avoids a raw cube silhouette.
    corners=[(-1.3,-.65),(1.3,-.65),(1.45,-.5),(1.45,.5),
             (1.3,.65),(-1.3,.65),(-1.45,.5),(-1.45,-.5)]
    loft('Stone',[[(x*s,y*s,z) for x,y in corners] for z,s in [(0,.94),(.14,1),(.30,.93)]])
    outline=[(-1.15,.36),(1.15,.36),(1.15,2.2)]
    outline += [(1.15*math.cos(i*math.pi/6),2.2+.9*math.sin(i*math.pi/6)) for i in range(1,7)]
    loft('Stone',[[(x*s,y,(z-1.6)*s+1.6) for x,z in outline]
                  for y,s in [(-.29,.94),(-.21,1),(.21,1),(.29,.94)]])
    # Low-relief cross sits within the bevel, rather than projecting as bulky bars.
    box('Stone',(0,-.305,1.70),(.17,.075,1.10))
    box('Stone',(0,-.305,1.91),(.77,.075,.17))
    box('Collision',(0,0,1.5),(2.18,.50,3))


def pine():
    sweep([(0,0,0),(.12,0,1),(-.08,.1,5),(.3,0,11)],[.60,.46,.27,.07],6)
    # Four asymmetric, scalloped bough skirts. Alternating droop makes branch tips
    # readable while the profile shoulders break the perfect traffic-cone shape.
    for tier,(base,radius,depth) in enumerate([(2.6,4.4,6.2),(5.5,3.7,5.8),(8.5,2.75,5.5),(11.6,1.8,5.4)]):
        rings=[]
        for level,(height,scale) in enumerate([(0,1),(.16,.78),(.56,.38),(1,.015)]):
            ring=[]
            for i in range(10):
                angle=2*math.pi*i/10+tier*.29
                irregular=1+.075*math.sin(i*2.3+tier)
                r=radius*scale*irregular
                z=base+depth*height
                if level==0:
                    z+=.38 if i%2 else -.12
                    if i%2: r*=.85
                lean=.32*height*math.sin(tier+1)
                ring.append((math.cos(angle)*r+lean,math.sin(angle)*r+.14*tier,z))
            rings.append(ring)
        loft('Foliage',rings)
    box('Collision',(0,0,3),(.9,.9,6))


def dead_tree():
    sweep([(0,0,0),(.3,.04,1.2),(.1,0,3.4),(-.45,.1,5.5),
           (-.72,.3,7.3),(-.30,.22,8.8),(-.8,.35,10.8)],
          [.85,.61,.46,.34,.24,.15,.012],8)
    paths=[[(.10,0,3.2),(-1.1,-.12,4.5),(-2.8,.05,4.9),(-3.8,.15,6.9)],
           [(-.34,.1,5.1),(1.1,.3,5.7),(2.5,.4,6.4),(3.2,.3,8.7)],
           [(-.64,.25,7),(-1.75,.15,8.0),(-2.0,-.05,9.2),(-3.0,-.1,10)],
           [(.05,0,3.4),(.4,-1.2,4.5),(1.2,-2.4,5.5),(.8,-3.1,7.0)]]
    for points in paths: sweep(points,[.30,.22,.12,.015],6)
    twigs=[([(-2.3,.03,4.82),(-2.5,-.25,6.1),(-2.25,-.3,7.0)],[.13,.075,.008]),
           ([(2.2,.38,6.24),(3.45,.8,6.6),(4,.9,7.5)],[.14,.075,.008]),
           ([(-1.85,.1,8.2),(-3,.2,8.4),(-3.8,.3,9.0)],[.12,.06,.008]),
           ([(.9,-2,5.2),(2,-2.6,5.8),(2.4,-2.7,6.5)],[.12,.06,.008]),
           ([(-.34,.22,8.7),(.45,.6,9.5),(.7,.65,10.2)],[.14,.07,.008])]
    for points,radii in twigs: sweep(points,radii,5)
    for i in range(4):
        angle=i*math.pi/2+.3
        sweep([(0,0,.8),(math.cos(angle)*.85,math.sin(angle)*.85,.30),
               (math.cos(angle)*1.65,math.sin(angle)*1.65,.08)],[.32,.21,.035],5)
    box('Collision',(0,0,3),(.85,.85,6))


def pumpkin():
    # Recessed crown, swollen shoulders and a tucked underside. Smooth normals
    # follow the lobes; the silhouette is not merely a scaled UV sphere.
    rings=[]
    for z,r in [(0,.30),(.25,1.08),(.85,1.42),(1.40,1.18),(1.68,.68),(1.56,.17)]:
        rings.append([(r*(1+.065*math.cos(5*a))*math.cos(a),
                       r*(1+.065*math.cos(5*a))*math.sin(a),
                       z+(.025*math.cos(5*a) if .1<z<1.6 else 0))
                      for a in [i*2*math.pi/20 for i in range(20)]])
    loft('Accent',rings,smooth=True)
    turned('Glow',[(1.57,.22),(1.64,.22)],sides=4,phase=math.pi/4)
    sweep([(0,0,1.56),(.04,0,1.95),(.24,.02,2.25)],[.18,.13,.075],4)
    box('Collision',(0,0,.7),(1.6,1.6,1.4))


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

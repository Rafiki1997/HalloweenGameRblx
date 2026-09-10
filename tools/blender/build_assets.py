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
PALETTE = {'Stone': (51,49,65), 'Wood': (62,43,58), 'Metal': (43,40,57), 'Roof': (39,30,57),
           'Glow': (255,188,104), 'Foliage': (25,43,43), 'Accent': (255,140,60),
           'Glass': (120,160,220), 'Water': (80,205,255), 'Ground': (29,43,42),
           'Collision': (220,50,80)}
BUDGETS = {'StreetLamp':300, 'Gravestone':150, 'PineTree':400, 'DeadTree':600, 'Pumpkin':300,
           'GhostFountain':4000, 'ChamberPortal':2500, 'RebirthAltar':2000, 'NoticeBoard':600, 'WelcomeSign':300,
           'HauntShowcase':6000, 'MansionHill':3000, 'MansionFacade':18000, 'Boulder':200,
           'ShopHouse':5000, 'Caretaker':1200, 'MarketStall':800, 'Barrel':200, 'Crate':100,
           'GraveyardFence':2200, 'Crypt':1800, 'GravestoneCross':150, 'GravestoneObelisk':150}
ZONES = {'GhostFountain':'Plaza', 'ChamberPortal':'Plaza', 'RebirthAltar':'Plaza', 'NoticeBoard':'Plaza', 'WelcomeSign':'Plaza',
         'HauntShowcase':'Haunts', 'MansionHill':'Mansion', 'MansionFacade':'Mansion', 'Boulder':'Mansion',
         'ShopHouse':'Town', 'Caretaker':'Town', 'MarketStall':'Town', 'Barrel':'Town', 'Crate':'Town',
         'GraveyardFence':'Graveyard', 'Crypt':'Graveyard', 'GravestoneCross':'Graveyard', 'GravestoneObelisk':'Graveyard'}
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


def sweep(points, radii, sides=6, role_name='Wood'):
    """A continuous tapered tube along a polyline: no disconnected cylinder joints."""
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
    return loft(role_name,rings,smooth=True)


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


def tube(role_name, a, b, r1, r2, sides=6):
    """Straight tapered tube between two points."""
    start, end = Vector(a), Vector(b)
    obj = taper(role_name, (start+end)/2, (end-start).length, r1, r2, sides)
    obj.rotation_euler = (end-start).to_track_quat('Z', 'Y').to_euler()
    return obj


def pyramid(role_name, center, half_width, height):
    """Square pyramid with axis-aligned edges; center is the base centre."""
    obj = taper(role_name, (center[0], center[1], center[2]+height/2), height, half_width*math.sqrt(2), .02, 4)
    obj.rotation_euler = (0, 0, math.pi/4)
    return obj


def arch(role_name, x, y, z_base, radius, thickness, depth, segments):
    """Semicircular arch in the XZ plane from stone segments; overlaps hide the joints."""
    for i in range(segments):
        t0 = math.pi*i/segments; t1 = math.pi*(i+1)/segments; t = (t0+t1)/2
        obj = box(role_name, (x+radius*math.cos(t), y, z_base+radius*math.sin(t)),
                  (thickness, depth, radius*(t1-t0)*1.12))
        obj.rotation_euler = (0, -t, 0)


def ring_of(count, radius, start=0):
    return [(radius*math.cos(start+2*math.pi*i/count), radius*math.sin(start+2*math.pi*i/count)) for i in range(count)]


def ghost_fountain():
    # Lower basin: up the outside, over the lip, down the inside to a floor disc.
    turned('Stone',[(0,11.6),(.5,12.1),(1.3,12.1),(1.7,12.5),(1.7,11.2),(.9,11.0),(.9,.6)],sides=16)
    turned('Water',[(1.0,11.0),(1.2,11.0)],sides=16)
    # Pedestal column and upper bowl.
    turned('Stone',[(.9,2.6),(1.3,2.0),(3.0,1.7),(3.4,2.2)],sides=12)
    turned('Stone',[(3.3,1.0),(3.7,4.3),(4.4,4.7),(4.7,4.9),(4.7,4.1),(4.1,4.0),(4.1,.8)],sides=16)
    turned('Water',[(4.15,3.9),(4.3,3.9)],sides=16)
    # Four steep streams from the upper lip into the lower water.
    for i in range(4):
        a = math.pi/4 + i*math.pi/2
        tube('Water',(4.6*math.cos(a),4.6*math.sin(a),4.7),(6.9*math.cos(a),6.9*math.sin(a),1.25),.22,.30,6)
    # Ghost spirit, 12 studs tall: scalloped floating hem, tapered body, rounded hood, raised arms, dark eyes.
    # Accent role so the game colours it blue-white while lanterns stay amber.
    sides = 12
    rings = []
    for z, r in [(4.6,2.15),(5.5,2.05),(7.0,1.95),(9.0,1.75),(11.0,1.6),(12.6,1.5),(13.6,1.55),(14.8,1.4),(15.7,.95),(16.3,.35)]:
        ring = []
        for i in range(sides):
            a = 2*math.pi*i/sides
            hem = (.42 if i%2 else -.05) if z < 5 else 0
            ring.append((r*math.cos(a), r*math.sin(a), z+hem))
        rings.append(ring)
    loft('Accent', rings, smooth=True)
    sweep([(1.35,-.1,11.6),(2.6,-.5,12.8),(3.5,-.9,14.2)],[.5,.36,.16],6,'Accent')
    sweep([(-1.35,-.1,11.6),(-2.6,-.5,12.9),(-3.3,-.8,14.4)],[.5,.36,.16],6,'Accent')
    for x in (-.55,.55):
        box('Metal',(x,-1.45,13.9),(.46,.22,.62))
    # Eight bollard lights on the plaza ring.
    for x,y in ring_of(8,13.4,math.pi/8):
        box('Stone',(x,y,.5),(.7,.7,1.0))
        box('Glow',(x,y,1.25),(.5,.5,.5))
    taper('Collision',(0,0,.85),1.7,12.6,12.6,16)
    taper('Collision',(0,0,3.2),3.0,4.95,4.95,12)


def chamber_portal():
    turned('Stone',[(0,8.0),(.7,8.0)],sides=16)                      # round base
    turned('Stone',[(.7,7.2),(1.0,7.2)],sides=16)                    # low step
    for x in (-5.6,5.6):
        box('Stone',(x,0,5.5),(2.2,2.6,9.0))                         # pier
        pyramid('Stone',(x,0,10.0),1.4,1.4)                          # pier cap
        box('Glow',(x,0,11.5),(.5,.5,.5))                            # finial
    arch('Stone',0,0,10.0,5.6,1.3,2.2,11)
    box('Stone',(0,0,15.75),(1.6,2.4,1.1))                           # keystone
    # Swirl plane inside the arch: a rounded-top slab in two layers.
    box('Glow',(0,.15,2.75),(8.6,.25,5.5))
    disc = turned('Glow',[(-.125,4.3),(.125,4.3)],sides=16); disc.rotation_euler=(math.pi/2,0,0); disc.location=(0,.15,5.5)
    box('Accent',(0,-.15,2.6),(7.4,.2,5.2))
    disc2 = turned('Accent',[(-.1,3.7),(.1,3.7)],sides=16); disc2.rotation_euler=(math.pi/2,0,0); disc2.location=(0,-.15,5.3)
    taper('Collision',(0,0,.5),1.0,8.1,8.1,16)
    for x in (-5.6,5.6): box('Collision',(x,0,5.5),(2.3,2.7,9.0))


def rebirth_altar():
    turned('Stone',[(0,6.0),(1.0,5.7)],sides=16)                     # marble round base
    turned('Stone',[(1.0,4.3),(1.8,4.0)],sides=16)                   # second step
    for x,y in ring_of(4,3.9,math.pi/4):
        turned('Stone',[(1.8,.55),(4.0,.5),(4.3,.65)],sides=8).location=(x,y,0)
        box('Stone',(x,y,4.45),(1.3,1.3,.3))
    turned('Stone',[(1.8,1.5),(3.1,1.2),(3.3,1.6)],sides=12)         # pedestal
    box('Accent',(0,0,3.55),(3.6,2.0,.5))                            # altar slab
    turned('Glow',[(5.4,.25),(5.7,.8),(6.2,1.1),(6.7,.8),(7.0,.25)],sides=12,smooth=True)  # floating orb
    for sx,sy in ((-2.2,-2.6),(2.4,2.2)):
        for k,(dx,dy,h) in enumerate(((0,0,1.1),(.5,.3,.8),(-.4,.4,.6))):
            turned('Stone',[(1.8,.16),(1.8+h,.16)],sides=6).location=(sx+dx,sy+dy,0)
            box('Glow',(sx+dx,sy+dy,1.8+h+.15),(.2,.2,.3))
    taper('Collision',(0,0,.9),1.8,6.1,6.1,16)
    box('Collision',(0,0,2.8),(3.6,2.2,2.0))
    for x,y in ring_of(4,3.9,math.pi/4): box('Collision',(x,y,3.2),(1.3,1.3,2.8))


def notice_board():
    for x in (-3.6,3.6): box('Wood',(x,0,2.75),(.5,.5,5.5))
    box('Wood',(0,0,3.3),(7.6,.35,3.4))                              # board
    for z in (1.4,5.2): box('Stone',(0,0,z),(8.0,.55,.35))           # frame rails
    for x in (-3.85,3.85): box('Stone',(x,0,3.3),(.35,.55,4.1))      # frame stiles
    for sgn in (-1,1):
        cap = box('Roof',(sgn*2.1,0,6.05),(4.6,1.6,.3)); cap.rotation_euler=(0,sgn*.42,0)
    box('Collision',(0,0,3.0),(8.0,.9,6.0))


def welcome_sign():
    box('Wood',(0,0,2.5),(.4,.4,5.0))
    box('Wood',(0,0,4.5),(2.8,.25,1.4))
    for z in (3.75,5.25): box('Metal',(0,0,z),(2.9,.32,.12))
    box('Glow',(0,0,5.55),(.45,.45,.45))
    box('Collision',(0,0,2.5),(.6,.6,5.0))


def prism_x(role_name, x0, x1, profile):
    """Closed prism: a polygon in the YZ plane extruded from x0 to x1 (gable roofs, wedges)."""
    n = len(profile)
    vertices = [(x0, y, z) for y, z in profile] + [(x1, y, z) for y, z in profile]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    for i in range(n):
        j = (i+1) % n
        faces.append((i, j, n+j, n+i))
    return mesh_object(role_name, vertices, faces)


def fence_run(a, b, post_every=4.6, picket_every=1.55):
    """Low iron fence between two ground points: posts, two rails, pickets. Metal role."""
    start, end = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    length = (end-start).length
    direction = (end-start)/length
    yaw = math.atan2(direction.y, direction.x)
    def along(t, z, size):
        pos = start+direction*t
        obj = box('Metal', (pos.x, pos.y, z), size)
        obj.rotation_euler = (0, 0, yaw)
        return obj
    posts = max(2, round(length/post_every)+1)
    for i in range(posts):
        along(length*i/(posts-1), 2.45, (.36, .36, 2.9))
    for z in (2.05, 3.3):
        along(length/2, z, (length, .14, .14))
    pickets = int(length/picket_every)
    for i in range(1, pickets):
        along(length*i/pickets, 2.25, (.11, .11, 2.5))


def haunt_showcase():
    # Blender +Y is the plaza-facing front (Roblox -Z after export); the house sits at the back (-Y).
    box('Stone', (0, 0, .5), (46, 40, 1.0))                       # yard plinth, top at z 1
    # House: two storeys, jettied upper floor, gable roof, chimney, door, steps and glowing windows.
    box('Wood', (0, -15.5, 4.0), (30, 9, 6))
    box('Wood', (0, -15.6, 9.5), (31.4, 9.8, 5))
    box('Roof', (0, -10.6, 7.1), (32.4, 1.4, .36))                 # jetty ledge
    prism_x('Roof', -16.8, 16.8, [(-21.4, 11.85), (-9.6, 11.85), (-15.5, 18.7)])
    box('Stone', (9.2, -13.6, 17.3), (1.8, 1.8, 5.4))
    box('Roof', (0, -10.92, 3.1), (2.7, .28, 4.2))                 # door
    box('Stone', (0, -10.2, 1.25), (4.6, 1.7, .5))                 # doorstep
    for x in (-10.5, -5.5, 5.5, 10.5): box('Accent', (x, -10.86, 4.3), (1.8, .24, 2.4))
    for x in (-11, -6, 0, 6, 11): box('Accent', (x, -10.56, 9.6), (1.6, .24, 2.2))
    for sx in (-1, 1):
        for y in (-18.2, -13.2): box('Accent', (sx*15.82, y, 9.6), (.24, 1.5, 2.0))
    # Twenty display pedestals on the server's 5 by 4 slot grid (Roblox z = -Blender y).
    for j in range(20):
        x = ((j % 5)-2)*6; y = 5-(j//5)*5
        box('Stone', (x, y, 1.6), (3.2, 3.2, 1.2))
        box('Stone', (x, y, 2.27), (3.6, 3.6, .14))
    # Gate posts with glowing caps, iron fence on three sides, hedges inside the fence.
    for x in (-3.6, 3.6):
        box('Stone', (x, 20, 3.1), (1.4, 1.4, 4.2))
        box('Accent', (x, 20, 5.5), (.7, .7, .6))
    fence_run((-23, 20), (-4.4, 20)); fence_run((4.4, 20), (23, 20))
    fence_run((-23, 20), (-23, -20)); fence_run((23, 20), (23, -20))
    for sx in (-1, 1):
        box('Foliage', (sx*21.5, 6, 2.1), (1.9, 26, 2.2))
        box('Foliage', (sx*13.2, 18.5, 2.0), (17.4, 1.8, 2.0))


def arched_window(role_name, x, y, z, width, height, depth=.24, facing='-Y'):
    """Rectangular pane with a half-disc top, proud of a wall. facing='-Y' means the pane's normal points to -Y."""
    r = width/2
    body_h = height-r
    if facing in ('-Y', '+Y'):
        box(role_name, (x, y, z+body_h/2), (width, depth, body_h))
        disc = turned(role_name, [(-depth/2, r), (depth/2, r)], sides=10)
        disc.rotation_euler = (math.pi/2, 0, 0); disc.location = (x, y, z+body_h)
    else:
        box(role_name, (x, y, z+body_h/2), (depth, width, body_h))
        disc = turned(role_name, [(-depth/2, r), (depth/2, r)], sides=10)
        disc.rotation_euler = (0, math.pi/2, 0); disc.location = (x, y, z+body_h)


def mansion_hill():
    # Front (plaza side) is -Y. Lower terrace, stair between the flanks, upper terrace the facade stands on.
    prism_x('Ground', -45, 45, [(-35, 0), (-35, 1.6), (-21, 1.6), (-8, 12), (35, 12), (35, 0)])
    box('Stone', (0, -28, 1.7), (88, 14, .3))                       # lower terrace paving, one step above the avenue
    box('Stone', (0, 13.5, 12.15), (88, 43, .3))                     # upper terrace paving
    # Grand stair, 24 wide: ten risers from z 3.5 to 12 between y -21 and -8.
    profile = [(-21, 1.3)]
    for k in range(10):
        y0 = -21+1.3*k; z0 = 1.6+1.04*k
        profile += [(y0, z0+1.04), (y0+1.3, z0+1.04)]
    profile += [(-8, 12.3), (-6, 12.3), (-6, 1.3)]
    prism_x('Stone', -12, 12, profile)
    # Balustrades: sloped along the stair, level along the upper terrace edge, with square posts.
    for sx in (-1, 1):
        rail = box('Stone', (sx*12.9, -14.5, 8.2), (.9, 16.8, .8)); rail.rotation_euler = (math.atan2(10.4, 13), 0, 0)
        for k in range(4):
            y = -21+13*k/3; z = 1.6+10.4*k/3
            box('Stone', (sx*12.9, y, z+1.2), (1.1, 1.1, 2.4))
        box('Stone', (sx*29, -7.6, 13.2), (32, .9, 1.9))             # terrace-edge parapet
        for x in (16, 24, 32, 40, 44):
            box('Stone', (sx*x, -7.6, 14.6), (1.2, 1.2, 1.4))
    for sx in (-1, 1):                                                # side retaining walls of the upper terrace
        box('Stone', (sx*45.2, 13.5, 6), (.6, 43, 12))
    box('Stone', (0, -35.2, .8), (90, .6, 1.6))                       # front retaining wall of the lower terrace


def mansion_facade():
    # Front is -Y. Central block, two towers with spires, taller central spire, porch, balcony, windows, ivy.
    box('Stone', (0, 0, 20), (80, 26, 40))                            # central block
    prism_x('Roof', -41, 41, [(-14, 40), (14, 40), (0, 52)])         # central gable
    pyramid('Roof', (0, 0, 51.5), 7, 14)                              # central spire
    box('Glow', (0, 0, 66), (.9, .9, .9))                              # spire lamp
    for sx in (-1, 1):
        box('Stone', (sx*51, 0, 25), (22, 26, 50))                    # tower
        box('Stone', (sx*51, 0, 50.6), (23.6, 27.6, 1.2))            # tower cornice
        pyramid('Roof', (sx*51, 0, 51), 11.8, 12)
        box('Glow', (sx*51, 0, 63.5), (.8, .8, .8))
        for cx, cy in ((-1, -1), (1, -1), (-1, 1), (1, 1)):          # gargoyle blocks on tower corners
            box('Stone', (sx*51+cx*11, cy*13, 47.5), (2.2, 2.2, 2.6))
        for z in (8, 20, 32):                                         # tower windows, front face
            arched_window('Glow', sx*51, -13.15, z, 3.2, 6.5)
    box('Roof', (0, -13.4, 40.2), (82, 1.2, 1.0))                     # front cornice
    # Porch: four columns, roof slab, balcony with railing.
    for x in (-11, -5, 5, 11):
        turned('Stone', [(0, 1.0), (.4, 1.15), (12.2, .8), (12.6, 1.05)], sides=10).location = (x, -18.5, 0)
    box('Stone', (0, -16.2, 13.2), (30, 8.4, 1.4))                    # porch roof
    box('Stone', (0, -16.2, 14.3), (22, 6.4, .8))                     # balcony floor lip
    for x in (-10.5, -6, -2, 2, 6, 10.5):
        box('Metal', (x, -19.2, 15.9), (.25, .25, 2.4))
    box('Metal', (0, -19.2, 17.2), (21.6, .25, .25))
    box('Wood', (0, -13.35, 7), (10, .6, 14))                          # entrance door
    box('Stone', (0, -13.5, 14.5), (13, .9, 1.0))                     # door lintel
    arched_window('Glow', 0, -13.15, 17, 5, 8)                        # balcony door glow
    for x in (-30, -20, 20, 30):                                       # ground-floor windows
        arched_window('Glow', x, -13.15, 4, 3.6, 7)
    for x in (-30, -20, -10, 10, 20, 30):                              # upper storeys
        arched_window('Glow', x, -13.15, 17, 3.2, 6)
        arched_window('Glow', x, -13.15, 29, 3.2, 6)
    for sx in (-1, 1):                                                 # ivy strips
        for x, h in ((36, 30), (39, 22), (14, 18)):
            box('Foliage', (sx*x, -13.2, h/2+1), (1.6, .35, h))
        box('Foliage', (sx*61.5, -6, 20), (.35, 8, 36))


def boulder():
    rng = [0.92, 1.08, 0.97, 1.12, 0.9, 1.05, 1.0, 0.94]
    rings = []
    for z, r in [(0, 1.2), (.5, 1.9), (1.3, 2.2), (2.1, 1.7), (2.6, .7)]:
        rings.append([(r*rng[i]*math.cos(2*math.pi*i/8), r*rng[(i+3) % 8]*math.sin(2*math.pi*i/8)*.85, z) for i in range(8)])
    loft('Stone', rings)


def prism_y(role_name, y0, y1, profile):
    """Closed prism: a polygon in the XZ plane extruded from y0 to y1 (roofs whose ridge runs along Y)."""
    n = len(profile)
    vertices = [(x, y0, z) for x, z in profile] + [(x, y1, z) for x, z in profile]
    faces = [tuple(range(n)), tuple(reversed(range(n, 2*n)))]
    for i in range(n):
        j = (i+1) % n
        faces.append((i, j, n+j, n+i))
    return mesh_object(role_name, vertices, faces)


def shop_house():
    # Front is -Y. Stone ground floor, jettied timber upper floor, pitched roof with a front dormer.
    box('Stone', (0, 0, .3), (22, 18, .6))                            # plinth
    box('Stone', (0, 0, 3.8), (20, 16, 6))                            # ground floor z .6..6.6
    box('Wood', (0, -.4, 9.7), (22, 17.6, 6.2))                       # jettied upper floor
    box('Roof', (0, -9.3, 6.7), (22.6, 1.0, .4))                      # jetty ledge
    for x in (-9.4, -3.2, 3.2, 9.4): box('Roof', (x, -9.25, 9.7), (.5, .3, 6.2))     # timber studs
    box('Roof', (0, -9.25, 12.6), (22, .3, .5))                        # timber head beam
    prism_x('Roof', -11.8, 11.8, [(-9.6, 12.8), (9.6, 12.8), (0, 18.6)])
    box('Wood', (0, -7.4, 14.6), (3.6, 3.2, 3.0))                      # dormer body
    prism_y('Roof', -9.3, -5.7, [(-2.2, 16.0), (2.2, 16.0), (0, 17.8)])
    arched_window('Glow', 0, -9.1, 14.2, 1.6, 2.4)                    # dormer window
    box('Stone', (5.6, 3.0, 17.6), (1.5, 1.5, 4.4))                     # chimney
    box('Wood', (-4.2, -8.2, 3.3), (3.2, .3, 5.0))                      # door
    box('Stone', (-4.2, -8.9, .85), (4.0, 1.4, .5))                     # step
    box('Glow', (3.6, -8.2, 4.1), (6.4, .3, 3.6))                       # shop window
    for x in (-8.4, 3.6):                                              # timber frame around the shop window / door
        box('Roof', (x, -8.3, 4.1), (.35, .35, 4.2))
    for x in (-5.5, 5.5): box('Glow', (x, -9.4, 10.1), (2.0, .3, 2.6))  # upper windows
    box('Metal', (7.4, -9.9, 8.9), (.2, 1.4, .2))                       # lantern bracket
    box('Glow', (7.4, -10.5, 8.2), (.7, .7, .9))                        # hanging lantern
    box('Metal', (-4.2, -9.9, 8.9), (.2, 1.4, .2))                      # sign rod
    box('Wood', (-4.2, -10.4, 7.9), (4.4, .3, 1.7))                     # hanging sign board


def caretaker():
    # Cloaked figure carrying a lantern. Body Wood, face Glow, lantern Metal and Glow.
    turned('Wood', [(0, 1.0), (.5, 1.05), (2.8, .8), (3.5, .62), (4.0, .55)], sides=8)
    turned('Wood', [(3.7, .6), (4.4, .68), (5.0, .35)], sides=8)     # hood
    turned('Glow', [(3.95, .3), (4.25, .36), (4.55, .26)], sides=8).location = (0, -.22, 0)
    sweep([(.55, -.2, 3.1), (1.0, -.7, 2.6), (1.15, -.95, 2.2)], [.26, .2, .14], 6)
    sweep([(-.55, -.1, 3.1), (-.9, -.4, 2.4), (-1.0, -.5, 1.9)], [.26, .2, .14], 6)
    box('Metal', (1.15, -.95, 1.75), (.12, .12, .8))                   # lantern handle
    box('Metal', (1.15, -.95, 1.25), (.5, .5, .1)); box('Metal', (1.15, -.95, .55), (.5, .5, .1))
    box('Glow', (1.15, -.95, .9), (.4, .4, .6))


def market_stall():
    for x, y in ((-3.5, -2.2), (3.5, -2.2), (-3.5, 2.2), (3.5, 2.2)):
        box('Wood', (x, y, 2.5), (.4, .4, 5.0))
    box('Wood', (0, 0, 2.4), (7.6, 4.0, .35))                          # table
    box('Wood', (0, 0, 1.4), (7.0, 3.6, .25))                          # shelf
    prism_x('Roof', -4.4, 4.4, [(-3.0, 5.0), (3.0, 5.0), (0, 6.6)])    # canopy
    for x, y in ((-2.4, .3), (-.6, -.5), (1.4, .4), (2.8, -.6)):
        turned('Accent', [(2.58, .15), (2.75, .55), (3.2, .6), (3.55, .35), (3.65, .12)], sides=8).location = (x, y, 0)
    box('Glow', (3.2, -2.2, 4.6), (.5, .5, .7))                        # lantern


def barrel():
    turned('Wood', [(0, .78), (.4, .95), (1.3, 1.0), (2.2, .95), (2.6, .78)], sides=10, smooth=True)
    for z in (.55, 2.05):
        turned('Metal', [(z-.08, 1.03), (z+.08, 1.03)], sides=10)   # hoops sit just outside the staves


def crate():
    box('Wood', (0, 0, .9), (1.8, 1.8, 1.8))
    for z in (.12, 1.68):
        box('Metal', (0, 0, z), (1.9, 1.9, .12))
    for x, y in ((-.9, -.9), (.9, -.9), (-.9, .9), (.9, .9)):
        box('Metal', (x, y, .9), (.14, .14, 1.9))


def graveyard_fence():
    # Lot 70 x 50, front (gate) on -Y toward the plaza. Posts every 7, two rails, pickets every 2.5.
    def run(a, b):
        fence_run(a, b, post_every=7.0, picket_every=2.5)
    run((-35, -25), (-4.5, -25)); run((4.5, -25), (35, -25))
    run((-35, -25), (-35, 25)); run((35, -25), (35, 25)); run((-35, 25), (35, 25))
    for x in (-4.5, 4.5):
        box('Stone', (x, -25, 2.6), (1.6, 1.6, 5.2))
        box('Accent', (x, -25, 5.6), (.8, .8, .7))
    # Two gate leaves swung inward.
    for sx in (-1, 1):
        leaf = box('Metal', (sx*3.0, -23.6, 1.9), (3.4, .12, 3.0)); leaf.rotation_euler = (0, 0, sx*.9)
        for k in range(4):
            pk = box('Metal', (sx*3.0+sx*(k-1.5)*.8*math.cos(.9), -23.6-(k-1.5)*.8*math.sin(.9)*sx*sx, 1.9), (.1, .1, 3.2))
            pk.rotation_euler = (0, 0, sx*.9)


def crypt():
    box('Stone', (0, 0, .4), (10, 12, .8))                             # plinth
    box('Stone', (0, .5, 3.2), (8, 10, 4.8))                           # body z .8..5.6
    prism_x('Roof', -4.6, 4.6, [(-5.6, 5.5), (5.6, 5.5), (0, 8.4)])
    box('Roof', (0, -4.6, 2.9), (2.4, .3, 4.2))                        # door
    box('Stone', (0, -5.2, 1.0), (3.4, 1.2, .4))                       # step
    box('Stone', (0, -4.7, 5.3), (3.6, .5, .6))                        # lintel
    box('Foliage', (-3.2, -4.55, 3.2), (1.2, .3, 4.6))                 # ivy
    box('Glow', (0, -4.7, 6.4), (.5, .3, .5))                          # lamp over the door


def gravestone_cross():
    loft('Stone', [[(x*s, y*s, z) for x, y in [(-1.0, -.5), (1.0, -.5), (1.0, .5), (-1.0, .5)]] for z, s in [(0, .95), (.3, 1)]])
    box('Stone', (0, 0, 1.9), (.55, .4, 3.2))
    box('Stone', (0, 0, 2.6), (1.8, .4, .5))


def gravestone_obelisk():
    turned('Stone', [(0, 1.05), (.35, 1.05), (.35, .8), (2.9, .5), (3.3, .12)], sides=4, phase=math.pi/4)


BUILDERS = {'StreetLamp':street_lamp,'Gravestone':gravestone,'PineTree':pine,
            'DeadTree':dead_tree,'Pumpkin':pumpkin,
            'GhostFountain':ghost_fountain,'ChamberPortal':chamber_portal,'RebirthAltar':rebirth_altar,
            'NoticeBoard':notice_board,'WelcomeSign':welcome_sign,
            'HauntShowcase':haunt_showcase,
            'MansionHill':mansion_hill,'MansionFacade':mansion_facade,'Boulder':boulder,
            'ShopHouse':shop_house,'Caretaker':caretaker,'MarketStall':market_stall,'Barrel':barrel,'Crate':crate,
            'GraveyardFence':graveyard_fence,'Crypt':crypt,'GravestoneCross':gravestone_cross,'GravestoneObelisk':gravestone_obelisk}


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
    return {'zone':ZONES.get(collection.name,'Props'),'footprint':[round(size.x,5),round(size.z,5),round(size.y,5)],
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

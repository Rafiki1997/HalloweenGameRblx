-- The reference is an island, with a broad western lake and a raised northern mansion.
-- Height/material are pure functions so all builders can share one surface contract.
local ReferenceTerrain = {}
local Plan=if script then require(script.Parent.MapPlan) else require('./MapPlan')
ReferenceTerrain.Ground = -0.5
ReferenceTerrain.WaterLevel = -3
ReferenceTerrain.Bounds = 300
-- Studio surface probes put WriteVoxels' rendered cells two studs beyond
-- their addressed boundaries. Account for that only in the voxel writer.
ReferenceTerrain.CellShift = 2
ReferenceTerrain.Pond = {x = -122, z = 15, radius = 62, radiusX = 65, radiusZ = 62}

local function smooth(a, b, value)
    local t = math.clamp((value - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)
end

local function boundary(angle)
    return 1 + 0.023 * math.sin(angle * 11 + 0.6) + 0.017 * math.cos(angle * 7 - 0.8)
end

local function islandDistance(x, z)
    local angle = math.atan2(z / 260, x / 245)
    return ((math.abs(x / 245) ^ 2.8 + math.abs(z / 260) ^ 2.8) ^ (1 / 2.8)) / boundary(angle)
end

local function lakeDistance(x, z)
    local p = ReferenceTerrain.Pond
    local nx, nz = (x - p.x) / p.radiusX, (z - p.z) / p.radiusZ
    local angle = math.atan2(nz, nx)
    return math.sqrt(nx * nx + nz * nz) / (1 + 0.035 * math.sin(angle * 5) + 0.025 * math.cos(angle * 9))
end

local function rectangleDistance(x, z, cx, cz, rx, rz)
    return math.sqrt(math.max(math.abs(x - cx) - rx, 0) ^ 2 + math.max(math.abs(z - cz) - rz, 0) ^ 2)
end

local PADS = {}
for _,plot in Plan.Plots do table.insert(PADS,{plot[1],plot[3],plot[2],34,30,plot[4]}) end
ReferenceTerrain.HauntPads = PADS

local function naturalHeight(x, z)
    local d = islandDistance(x, z)
    if d >= 1.055 then return -100 end
    local h = -0.5 + 30.5 * smooth(65, 163, -z)
    -- Uneven wooded shoulders surround the flat build areas.
    h += 4.5 * (math.sin(x * 0.042 + 0.9) * math.cos(z * 0.033) + 1) * smooth(75, 170, math.abs(x))
    -- Plaza, town, cemetery, mansion court, and main approach remain buildable.
    local plaza = 1 - smooth(43, 59, math.sqrt(x * x + z * z))
    h += (-0.5 - h) * plaza
    for _, lot in {{-105, 139, 65, 48}, {132, 143, 46, 49}} do
        local blend = 1 - smooth(0, 14, rectangleDistance(x, z, lot[1], lot[2], lot[3], lot[4]))
        h += (-0.5 - h) * blend
    end
    local gardenCliff=smooth(115,130,-z)*(1-smooth(145,155,-z))*smooth(24,32,math.abs(x))*(1-smooth(70,82,math.abs(x)))
    h-=12*gardenCliff
    for _, pad in PADS do
        local angle=math.rad(pad[6]); local dx,dz=x-pad[1],z-pad[2]
        local lx,lz=math.cos(angle)*dx-math.sin(angle)*dz,math.sin(angle)*dx+math.cos(angle)*dz
        local blend = 1 - smooth(0, 8, rectangleDistance(lx, lz, 0, 0, pad[4], pad[5]))
        h += (pad[3] - h) * blend
    end
    local mansion = 1 - smooth(0, 5, rectangleDistance(x, z, 0, -186, 67, 38))
    h += (30 - h) * mansion
    local avenue = (1 - smooth(15, 25, math.abs(x))) * (1 - smooth(217, 237, z))
    local avenueHeight = -0.5 + 30.5 * smooth(65, 163, -z)
    h += (avenueHeight - h) * avenue
    -- The water exists only in this basin. Outside the island is empty air.
    local lake = lakeDistance(x, z)
    h += (-12 - h) * (1 - smooth(0.81, 1.11, lake))
    -- A narrow steep skirt exposes sixty studs of rock around the entire island.
    h += (-66 - h) * smooth(0.973, 1.038, d)
    return h
end

-- Grade the whole gate approach, spreading each terrace rise over its available
-- run. The final landing meets the scaled courtyard top without a drop.
ReferenceTerrain.Approaches={}
for _,route in Plan.Routes do
    if not route.plot then continue end
    local segments,total={},0
    for i=1,#route.points-1 do
        local a,b=route.points[i],route.points[i+1]
        local length=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2)
        table.insert(segments,{a=a,b=b,length=length,start=total})
        total+=length
    end
    local first=route.points[1]
    local startHeight=naturalHeight(first[1],first[2])
    for _,other in Plan.Routes do
        if not other.bridge then continue end
        for _,point in {other.points[1],other.points[#other.points]} do
            if (point[1]-first[1])^2+(point[2]-first[2])^2<.01 then startHeight=math.max(startHeight,.2) end
        end
    end
    local flats={}
    for i=2,#segments do
        local previous,current=segments[i-1],segments[i]
        local dot=((previous.b[1]-previous.a[1])*(current.b[1]-current.a[1])+(previous.b[2]-previous.a[2])*(current.b[2]-current.a[2]))/(previous.length*current.length)
        if dot<.995 then
            local radius=route.width*.5+1
            table.insert(flats,{math.max(0,current.start-radius),math.min(total,current.start+radius)})
        end
    end
    table.insert(flats,{total-1.5,total})
    local merged={}
    for _,flat in flats do
        local last=merged[#merged]
        if last and flat[1]<=last[2] then last[2]=math.max(last[2],flat[2]) else table.insert(merged,flat) end
    end
    local climbRun=total
    for _,flat in merged do climbRun-=flat[2]-flat[1] end
    ReferenceTerrain.Approaches[route.id]={segments=segments,length=total,width=route.width,flats=merged,climbRun=climbRun,
        low=startHeight+1,high=Plan.Plots[route.plot][2]+Plan.Scale*.5-.5}
end
function ReferenceTerrain.approachHeight(id,distance)
    local a=ReferenceTerrain.Approaches[id]
    local climb=distance
    for _,flat in a.flats do climb-=math.clamp(distance-flat[1],0,flat[2]-flat[1]) end
    return a.low+(a.high-a.low)*math.clamp(climb/a.climbRun,0,1)
end
function ReferenceTerrain.height(x,z)
    local h=naturalHeight(x,z)
    for id,approach in ReferenceTerrain.Approaches do
        local nearest,along=math.huge,0
        for _,segment in approach.segments do
            local a,b=segment.a,segment.b
            local t=math.clamp(((x-a[1])*(b[1]-a[1])+(z-a[2])*(b[2]-a[2]))/segment.length^2,0,1)
            local distance=math.sqrt((x-a[1]-(b[1]-a[1])*t)^2+(z-a[2]-(b[2]-a[2])*t)^2)
            if distance<nearest then nearest=distance; along=segment.start+segment.length*t end
        end
        local blend=1-smooth(approach.width*.5+3,approach.width*.5+7,nearest)
        if blend>0 then
            -- Extra substrate clearance absorbs four-stud voxel interpolation.
            -- Fade the cut at the junction so adjacent paving still meets flush.
            local cut=math.min(1.5,math.abs(approach.high-approach.low)*.15)*smooth(0,5,along)*(1-smooth(approach.length-5,approach.length,along))
            local target=ReferenceTerrain.approachHeight(id,along)-1-cut
            h+=(target-h)*blend
        end
    end
    return h
end

function ReferenceTerrain.material(x, z)
    local h = ReferenceTerrain.height(x, z)
    if islandDistance(x, z) > 0.963 then return 'Rock' end
    if lakeDistance(x, z) < 1.11 and h < -1 then return 'Mud' end
    local dx = (ReferenceTerrain.height(x + 2, z) - ReferenceTerrain.height(x - 2, z)) / 4
    local dz = (ReferenceTerrain.height(x, z + 2) - ReferenceTerrain.height(x, z - 2)) / 4
    if dx * dx + dz * dz > 1 then return 'Rock' end
    return 'LeafyGrass'
end

local function rock(root, name, size, cf, color)
    local p = Instance.new('Part')
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cf
    p.Material = Enum.Material.Slate
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = root
    return p
end

local function addCliffFaces(root)
    local folder = Instance.new('Folder')
    folder.Name = 'FacetedIslandCliffs'
    folder.Parent = root
    local rng = Random.new(57109)
    for i = 0, 125 do
        local angle = i * math.pi * 2 / 126
        local ca, sa = math.cos(angle), math.sin(angle)
        local reach = boundary(angle) / ((math.abs(ca) ^ 2.8 + math.abs(sa) ^ 2.8) ^ (1 / 2.8))
        local x, z = ca * 245 * reach * 0.977, sa * 260 * reach * 0.977
        local top = ReferenceTerrain.height(x * 0.97, z * 0.97) - rng:NextNumber(0, 4)
        local bottom = rng:NextNumber(-74, -60)
        local tall = top - bottom
        local shade = rng:NextInteger(-9, 10)
        rock(folder, 'BasaltCliff', Vector3.new(rng:NextNumber(11, 19), tall, rng:NextNumber(15, 26)),
            CFrame.new(x, bottom + tall / 2, z) * CFrame.Angles(0, -angle, rng:NextNumber(-0.065, 0.065)),
            Color3.fromRGB(49 + shade, 44 + shade, 69 + shade))
        if i % 3 == 0 then
            rock(folder, 'CliffCrown', Vector3.new(rng:NextNumber(10, 16), rng:NextNumber(4, 8), rng:NextNumber(10, 17)),
                CFrame.new(x * 0.989, top - 0.6, z * 0.989) * CFrame.Angles(0.12, angle + 0.4, 0.15),
                Color3.fromRGB(62 + shade, 55 + shade, 79 + shade))
        end
    end
    -- Exposed stone escarpment under the mansion's raised garden.
    for i = -6, 6 do
        local x, z = i * 12, -143 + math.abs(i) * 0.6
        if math.abs(x) > 15 then
            local top = ReferenceTerrain.height(x, z - 5)
            rock(folder, 'MansionTerraceFace', Vector3.new(11.8, 21, 10),
                CFrame.new(x, top - 11, z) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0),
                Color3.fromRGB(64, 56, 82))
        end
    end
end

function ReferenceTerrain.build(root)
    local started = os.clock()
    local terrain = workspace.Terrain
    terrain:Clear()
    terrain:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(35, 52, 43))
    terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(30, 47, 40))
    terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(58, 49, 76))
    terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(35, 35, 48))
    terrain.WaterColor = Color3.fromRGB(8, 36, 57)
    terrain.WaterTransparency = 0.48
    terrain.WaterReflectance = 0.12
    terrain.WaterWaveSize = 0.1
    terrain.WaterWaveSpeed = 5
    local step, chunk, floor = 4, 60, -80
    local n, columns, chunks = chunk / step, 0, 0
    for cx = -300, 240, chunk do
        for cz = -300, 240, chunk do
            local heights, surface, wet, highest = {}, {}, {}, 0
            for i = 1, n do
                heights[i], surface[i], wet[i] = {}, {}, {}
                for k = 1, n do
                    local x, z = cx + (i - 0.5) * step + ReferenceTerrain.CellShift, cz + (k - 0.5) * step + ReferenceTerrain.CellShift
                    local h = ReferenceTerrain.height(x, z)
                    heights[i][k] = h
                    surface[i][k] = Enum.Material[ReferenceTerrain.material(x, z)]
                    wet[i][k] = lakeDistance(x, z) < 1.12
                    highest = math.max(highest, h)
                end
            end
            local ny = math.ceil((highest - floor - ReferenceTerrain.CellShift) / step) + 1
            local materials, occupancy = {}, {}
            for i = 1, n do
                materials[i], occupancy[i] = {}, {}
                for j = 1, ny do
                    local bottom = floor + (j - 1) * step + ReferenceTerrain.CellShift
                    local mr, oc = {}, {}
                    for k = 1, n do
                        local ground = math.clamp((heights[i][k] - bottom) / step, 0, 1)
                        local water = wet[i][k] and math.clamp((ReferenceTerrain.WaterLevel - bottom) / step, 0, 1) or 0
                        if ground >= 0.5 or ground >= water and ground > 0 then
                            mr[k], oc[k] = surface[i][k], ground
                        elseif water > 0 then
                            mr[k], oc[k] = Enum.Material.Water, water
                        else
                            mr[k], oc[k] = Enum.Material.Air, 0
                        end
                    end
                    materials[i][j], occupancy[i][j] = mr, oc
                end
            end
            terrain:WriteVoxels(Region3.new(Vector3.new(cx, floor, cz), Vector3.new(cx + chunk, floor + ny * step, cz + chunk)), step, materials, occupancy)
            columns += n * n
            chunks += 1
        end
    end
    addCliffFaces(root)
    return {columns = columns, chunks = chunks, seconds = os.clock() - started}
end

return ReferenceTerrain

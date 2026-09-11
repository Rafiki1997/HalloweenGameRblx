-- Deterministic landscape around the level town: pure shape functions first, Roblox Terrain writing in build().
-- Everything World.luau places assumes the ground top is y -0.5; that footprint stays exactly level and the
-- hills, ridge, rim and pond are sculpted around it.
local Landscape = {}
local GROUND = -0.5
Landscape.Ground = GROUND
Landscape.Bounds = 336 -- terrain covers x and z in [-336, 336): 168 voxels of 4 studs per axis
Landscape.WaterLevel = -1.5 -- the only ground below this is the pond floor, so water appears nowhere else
Landscape.Pond = {x = 60, z = 215, radius = 30}

local function smoothstep(a, b, v)
    local t = math.clamp((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)
end
-- Integer hash and value noise: deterministic on every server without math.noise.
local function hash(ix, iz)
    local h = (ix * 73856093 + iz * 19349663 + 1013904223) % 4294967296
    h = bit32.bxor(h, bit32.rshift(h, 13))
    h = (h * 1664525) % 4294967296
    h = bit32.bxor(h, bit32.rshift(h, 16))
    return h / 4294967296
end
local function noise(x, z)
    local x0, z0 = math.floor(x), math.floor(z)
    local fx, fz = x - x0, z - z0
    local ux, uz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
    local a, b, c, d = hash(x0, z0), hash(x0 + 1, z0), hash(x0, z0 + 1), hash(x0 + 1, z0 + 1)
    return (a + (b - a) * ux) * (1 - uz) + (c + (d - c) * ux) * uz
end
local function fbm(x, z, scale) -- 0..1, three octaves; the fine octave stays light so hills roll rather than crumple
    return 0.70 * noise(x / scale, z / scale)
        + 0.24 * noise(x / (scale * 0.47) + 31.7, z / (scale * 0.47) + 11.3)
        + 0.06 * noise(x / (scale * 0.21) + 7.1, z / (scale * 0.21) + 53.9)
end

-- Protected footprint: the plaza and Haunt ring, the mansion avenue and hill, the graveyard lot.
local function discOutside(x, z, cx, cz, r)
    return math.max(0, math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2) - r)
end
local function rectOutside(x, z, x0, z0, x1, z1)
    local dx = math.max(x0 - x, 0, x - x1)
    local dz = math.max(z0 - z, 0, z - z1)
    return math.sqrt(dx * dx + dz * dz)
end
local function outside(x, z) -- distance beyond the footprint; 0 inside it
    return math.min(discOutside(x, z, 0, 0, 150), rectOutside(x, z, -68, -206, 68, -20), rectOutside(x, z, 116, 64, 182, 148))
end
Landscape.outside = outside

local function knoll(x, z, cx, cz, radius, tall)
    return tall * (1 - smoothstep(0, radius, math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2)))
end
-- Rolling ground that grows with distance from town, two lookout knolls (behind the shops and beyond the graveyard),
-- all fading under the rim so crests stay within the height ceiling.
local function hills(x, z, d)
    local reach = smoothstep(0, 120, d)
    local rolling = (7 + 14 * fbm(x, z, 90)) * (0.5 + 0.5 * reach)
    local lookouts = knoll(x, z, -238, 60, 95, 18) + knoll(x, z, 250, -30, 95, 17) -- broad, and clear of the footprint blends
    local r = math.sqrt(x * x + z * z)
    return (rolling + lookouts) * (1 - 0.6 * smoothstep(240, 300, r))
end
-- A steep ridge stands directly behind the mansion hill so the house reads as carved into a hillside;
-- its face exceeds 60 degrees, which the character slope limit treats as a wall.
local function ridge(x, z)
    local front = smoothstep(214, 236, -z)
    local span = 1 - smoothstep(150, 230, math.abs(x))
    return 44 * front * span * (0.85 + 0.3 * fbm(x + 400, z, 70))
end
-- The rim closes the hollow: it hides the mansion floor boxes to the north and stops anyone reaching the edge.
local function rim(x, z)
    local r = math.sqrt(x * x + z * z)
    local wander = 24 * fbm(x - 300, z + 300, 180) -- the foot of the rim drifts up to 24 studs so the hollow is not a circle
    return 66 * smoothstep(258 + wander, 292 + wander, r) * (0.85 + 0.3 * fbm(x + 300, z - 300, 120))
end
-- One dell in the tree ring south-east of the plaza fills with water: the ground eases down to a flat bed at y -8,
-- and the water's edge falls close to the nominal radius whatever the surrounding hills do.
local function pondBlend(x, z)
    local p = Landscape.Pond
    local dist = math.sqrt((x - p.x) ^ 2 + (z - p.z) ^ 2)
    return 1 - smoothstep(p.radius - 6, p.radius + 16, dist)
end
function Landscape.height(x, z)
    local d = outside(x, z)
    if d <= 0 then return GROUND end
    local blend = smoothstep(0, 45, d)
    local h = hills(x, z, d) + math.max(ridge(x, z), rim(x, z))
    h += (-8 - h) * pondBlend(x, z)
    return GROUND + (h - GROUND) * blend
end
local function slopeAt(x, z)
    local e = 1.5
    local dx = (Landscape.height(x + e, z) - Landscape.height(x - e, z)) / (2 * e)
    local dz = (Landscape.height(x, z + e) - Landscape.height(x, z - e)) / (2 * e)
    return math.sqrt(dx * dx + dz * dz)
end
-- Terrain material names (Enum.Material keys). LeafyGrass carries no animated blades, so the town floor uses it
-- and paths, plinths and props stay clean; Grass with decoration only appears well beyond the footprint.
function Landscape.material(x, z)
    local h = Landscape.height(x, z)
    if h < Landscape.WaterLevel + 0.6 then return 'Mud' end
    local s = slopeAt(x, z)
    if s > 1.2 then return 'Rock' end
    if outside(x, z) <= 30 then return 'LeafyGrass' end
    if h > 50 then return 'Basalt' end
    if s > 0.7 then return 'Ground' end
    if fbm(x + 900, z - 900, 55) > 0.62 then return 'LeafyGrass' end
    return 'Grass'
end
-- One 4-stud voxel of the column whose ground top is h. Ground fills from below; water takes any cell the ground
-- leaves more than half empty beneath the water level; everything else is air.
function Landscape.voxel(h, material, y0)
    local ground = math.clamp((h - y0) / 4, 0, 1)
    if ground >= 0.5 then return material, ground end
    local water = math.clamp((Landscape.WaterLevel - y0) / 4, 0, 1)
    if water > ground then return 'Water', water end
    if ground > 0 then return material, ground end
    return 'Air', 0
end

-- Roblox-only from here down. Moonlit material palette, then the whole square written in 84-stud chunks.
local COLORS = {
    Grass = {29, 43, 42}, LeafyGrass = {33, 49, 46}, Ground = {46, 39, 52}, Mud = {40, 33, 46},
    Rock = {58, 56, 74}, Basalt = {40, 38, 56},
}
local CHUNK = 84
local STEP = 4
local FLOOR = -12
function Landscape.build(root)
    local started = os.clock()
    local terrain = workspace.Terrain
    terrain:Clear()
    for name, rgb in COLORS do terrain:SetMaterialColor(Enum.Material[name], Color3.fromRGB(rgb[1], rgb[2], rgb[3])) end
    terrain.WaterColor = Color3.fromRGB(38, 58, 112); terrain.WaterTransparency = 0.55; terrain.WaterReflectance = 0.35
    terrain.WaterWaveSize = 0.08; terrain.WaterWaveSpeed = 6
    -- Terrain.Decoration (grass blades) is not scriptable; tools/build_place.py sets it in the place file.
    local enums = {}
    local function enum(name)
        local e = enums[name]
        if not e then e = Enum.Material[name]; enums[name] = e end
        return e
    end
    local B, n = Landscape.Bounds, CHUNK / STEP
    local columns, chunks = 0, 0
    for cx = -B, B - CHUNK, CHUNK do
        for cz = -B, B - CHUNK, CHUNK do
            local heights, mats, top = {}, {}, Landscape.WaterLevel
            for i = 1, n do
                heights[i], mats[i] = {}, {}
                for k = 1, n do
                    local x, z = cx + (i - 0.5) * STEP, cz + (k - 0.5) * STEP
                    local h = Landscape.height(x, z)
                    heights[i][k], mats[i][k] = h, Landscape.material(x, z)
                    if h > top then top = h end
                end
            end
            local yTop = math.ceil((top + STEP) / STEP) * STEP
            local ny = (yTop - FLOOR) / STEP
            local materials, occupancy = {}, {}
            for i = 1, n do
                materials[i], occupancy[i] = {}, {}
                for j = 1, ny do
                    local y0 = FLOOR + (j - 1) * STEP
                    local mRow, oRow = {}, {}
                    for k = 1, n do
                        local name, o = Landscape.voxel(heights[i][k], mats[i][k], y0)
                        mRow[k], oRow[k] = enum(name), o
                    end
                    materials[i][j], occupancy[i][j] = mRow, oRow
                end
            end
            terrain:WriteVoxels(Region3.new(Vector3.new(cx, FLOOR, cz), Vector3.new(cx + CHUNK, yTop, cz + CHUNK)), STEP, materials, occupancy)
            columns += n * n; chunks += 1
        end
    end
    -- Invisible walls along the edge of the square; the rim already makes the edge hard to reach.
    for _, side in {-1, 1} do
        for _, axis in {'x', 'z'} do
            local wall = Instance.new('Part'); wall.Name = 'WorldEdge'; wall.Anchored = true; wall.Transparency = 1
            wall.CanQuery = false; wall.CastShadow = false
            if axis == 'x' then
                wall.Size = Vector3.new(2, 200, 2 * B + 4); wall.CFrame = CFrame.new(side * (B + 1), 80, 0)
            else
                wall.Size = Vector3.new(2 * B + 4, 200, 2); wall.CFrame = CFrame.new(0, 80, side * (B + 1))
            end
            wall.Parent = root
        end
    end
    return {columns = columns, chunks = chunks, seconds = os.clock() - started}
end
return Landscape

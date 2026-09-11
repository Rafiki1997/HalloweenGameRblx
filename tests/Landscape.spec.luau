-- Pure landscape checks; runs under the local Luau runner with no Roblox API.
local Landscape = require('../src/server/Landscape')
local count = 0
local function check(name, test)
    test()
    count += 1
    print('PASS ' .. name)
end
local GROUND = -0.5
local function flatAt(x, z, label)
    local h = Landscape.height(x, z)
    assert(math.abs(h - GROUND) < 1e-6, string.format('%s at (%.1f, %.1f) should sit on level ground, got %.3f', label, x, z, h))
end
-- Coordinates mirror src/server/World.luau. Every one of these assumes the ground top is y -0.5.
local landmarks = {
    {0, 0, 'plaza'}, {0, 21, 'spawn'}, {0, 40, 'chamber portal'}, {-12, 50, 'welcome sign'}, {12, 50, 'welcome sign'},
    {0, 62, 'notice board'}, {-40, 50, 'Mira'}, {38, 46.5, 'Orin'}, {33.5, 40, 'rebirth altar'}, {28.5, 46, 'pumpkin'},
    {-52, 48, 'Workshop'}, {-52, 71, 'Inn'}, {-52, 94, 'Curiosities'}, {-38, 62, 'stall'}, {-38, 84, 'stall'},
    {-41.5, 100, 'cask'}, {-35.5, 58, 'pumpkin'},
    {0, -30, 'mansion path start'}, {0, -129, 'mansion path end'}, {-13, -45, 'avenue lamp'}, {13, -120, 'avenue lamp'},
    {0, -165, 'mansion hill'}, {-45, -200, 'hill corner'}, {45, -200, 'hill corner'}, {-62, -198.8, 'facade corner'},
    {-50, -140, 'boulder'}, {52, -134, 'boulder'}, {-53, -176, 'boulder'}, {55, -192, 'boulder'}, {-60, -120, 'boulder'},
    {125, 70, 'graveyard gate corner'}, {175, 140, 'graveyard far corner'}, {122, 113, 'graveyard sign'},
    {140, 78, 'graveyard dead tree'}, {158, 136, 'graveyard dead tree'}, {168, 80, 'crypt'}, {168, 130, 'crypt'},
}
for _, i in {1, 2, 3, 4, 6, 7, 8} do
    local angle = math.rad(20 + (i - 1) * 40)
    local cx, cz = math.sin(angle) * 116, math.cos(angle) * 116
    local ox, oz = cx / 116, cz / 116          -- outward unit vector; the house back wall lies this way
    local rx, rz = oz, -ox                     -- perpendicular
    table.insert(landmarks, {cx, cz, 'Haunt ' .. i .. ' centre'})
    for _, side in {-23, 23} do
        for _, depth in {-20, 20} do
            table.insert(landmarks, {cx + rx * side + ox * depth, cz + rz * side + oz * depth, 'Haunt ' .. i .. ' corner'})
        end
    end
    table.insert(landmarks, {cx * 0.26, cz * 0.26, 'Haunt ' .. i .. ' path start'})
end
check('every built landmark keeps level ground at y -0.5', function()
    for _, l in landmarks do flatAt(l[1], l[2], l[3]) end
end)
local function slope(x, z)
    local e = 1
    local dx = (Landscape.height(x + e, z) - Landscape.height(x - e, z)) / (2 * e)
    local dz = (Landscape.height(x, z + e) - Landscape.height(x, z - e)) / (2 * e)
    return math.sqrt(dx * dx + dz * dz)
end
local WALKABLE = math.tan(math.rad(35))
local WALL = math.tan(math.rad(60))
check('ground rises into rolling, walkable hills beyond the town footprint', function()
    for _, pt in {{215, 0}, {-215, 0}, {180, 200}, {-152, 152}, {100, 190}, {-150, -150}, {150, -150}} do
        local h = Landscape.height(pt[1], pt[2])
        assert(h >= 3 and h <= 30, string.format('hill at (%d, %d) should be 3 to 30 studs, got %.2f', pt[1], pt[2], h))
    end
    -- The blend from level ground and the near hills themselves must never exceed a comfortable walking grade.
    for r = 150, 250, 10 do
        for deg = 0, 359, 15 do
            local x, z = math.sin(math.rad(deg)) * r, math.cos(math.rad(deg)) * r
            local nearPond = (x - 60) ^ 2 + (z - 215) ^ 2 < 50 ^ 2
            local nearRidge = z < -200 or (math.abs(x) <= 70 and z < -20) -- the ridge test covers the mansion strip
            if not nearRidge and not nearPond then
                assert(slope(x, z) <= WALKABLE, string.format('slope at (%.0f, %.0f) is %.2f, steeper than 35 degrees', x, z, slope(x, z)))
            end
        end
    end
    -- Relief has to be visible from town: the near hills vary by 10 studs or more around the ring, and two knolls give lookouts.
    local lo, hi = math.huge, -math.huge
    for deg = 0, 359, 5 do
        local x, z = math.sin(math.rad(deg)) * 235, math.cos(math.rad(deg)) * 235
        if z > -180 and (x - 60) ^ 2 + (z - 215) ^ 2 > 60 ^ 2 then
            local h = Landscape.height(x, z)
            lo, hi = math.min(lo, h), math.max(hi, h)
        end
    end
    assert(hi - lo >= 10, string.format('near hills should vary by at least 10 studs around the ring, got %.1f', hi - lo))
    for _, k in {{-215, 60}, {240, -30}} do
        local h = Landscape.height(k[1], k[2])
        assert(h >= 16, string.format('knoll at (%d, %d) should be a lookout at least 16 studs high, got %.1f', k[1], k[2], h))
    end
end)
check('a ridge rises behind the mansion, tall and too steep to climb', function()
    local crest = Landscape.height(0, -270)
    assert(crest >= 35 and crest <= 70, 'ridge crest should be 35 to 70 studs, got ' .. crest)
    assert(crest - Landscape.height(0, -212) >= 30, 'ridge must stand well above the ground behind the mansion')
    for _, x in {-150, 150} do
        assert(Landscape.height(x, -270) >= 25, 'ridge should span the width of the mansion approach at x ' .. x)
    end
    local steep = false
    for z = -212, -250, -2 do
        if slope(0, z) >= WALL then steep = true end
    end
    assert(steep, 'the ridge face must exceed 60 degrees somewhere so it acts as a wall')
end)
check('an outer rim encloses the hollow, tall, too steep to climb, and bounded in height', function()
    assert(Landscape.Bounds == 336, 'terrain square is 672 studs across so its edge lies on the 4-stud voxel grid')
    for deg = 0, 359, 30 do
        local sx, sz = math.sin(math.rad(deg)), math.cos(math.rad(deg))
        local h = Landscape.height(sx * 312, sz * 312)
        assert(h >= 50, string.format('rim at bearing %d should be at least 50 studs, got %.1f', deg, h))
        local steep = false
        for r = 262, 306, 2 do
            if slope(sx * r, sz * r) >= WALL then steep = true end
        end
        assert(steep, 'the inner face of the rim must exceed 60 degrees at bearing ' .. deg)
    end
    for x = -Landscape.Bounds, Landscape.Bounds, 12 do
        for z = -Landscape.Bounds, Landscape.Bounds, 12 do
            local h = Landscape.height(x, z)
            assert(h <= 95, string.format('height %.1f at (%d, %d) exceeds the 95 stud ceiling', h, x, z))
        end
    end
    -- The foot of the rim wanders so the hollow is not a perfect circle: where the ground first passes 25 studs
    -- must differ by at least 12 studs of radius between bearings.
    local nearest, farthest = math.huge, -math.huge
    for deg = 0, 359, 10 do
        local sx, sz = math.sin(math.rad(deg)), math.cos(math.rad(deg))
        for r = 240, 330, 1 do
            if Landscape.height(sx * r, sz * r) >= 25 then
                nearest, farthest = math.min(nearest, r), math.max(farthest, r)
                break
            end
        end
    end
    assert(farthest - nearest >= 12, string.format('rim foot should wander at least 12 studs, got %d to %d', nearest, farthest))
end)
check('a pond fills a dell south-east of town and nowhere else', function()
    local pond = Landscape.Pond
    assert(pond.x == 60 and pond.z == 215 and pond.radius == 30, 'pond matches the dell excluded from the walkability sweep')
    assert(Landscape.WaterLevel == -2, 'water surface sits on a voxel boundary 1.5 studs under the town ground')
    local floor = Landscape.height(pond.x, pond.z)
    assert(math.abs(floor - -6) < 1e-6, 'pond bed sits on the voxel boundary at y -6, got ' .. floor)
    for deg = 0, 359, 45 do
        local x = pond.x + math.sin(math.rad(deg)) * pond.radius
        local z = pond.z + math.cos(math.rad(deg)) * pond.radius
        local h = Landscape.height(x, z)
        assert(h <= Landscape.WaterLevel - 0.5, string.format('the pond should still be water at its nominal radius, bearing %d got %.2f', deg, h))
    end
    for deg = 0, 359, 45 do
        local x = pond.x + math.sin(math.rad(deg)) * (pond.radius + 35)
        local z = pond.z + math.cos(math.rad(deg)) * (pond.radius + 35)
        local h = Landscape.height(x, z)
        assert(h >= Landscape.WaterLevel + 1, string.format('ground at (%.0f, %.0f) beyond the pond must be dry, got %.2f', x, z, h))
    end
end)
check('surface material follows the ground: leafy turf in town, grass blades on hills, rock on walls, mud under water', function()
    assert(Landscape.material(0, -40) == 'LeafyGrass', 'level town ground uses LeafyGrass so no animated blades poke through paths')
    assert(Landscape.material(40, 109) == 'LeafyGrass', 'Haunt yards keep the same turf')
    assert(Landscape.material(0, -226) == 'Rock', 'the ridge face is bare rock, got ' .. Landscape.material(0, -226))
    assert(Landscape.material(60, 215) == 'Mud', 'the pond bed is mud, got ' .. Landscape.material(60, 215))
    local crest = Landscape.material(0, 320)
    assert(crest == 'Basalt' or crest == 'Rock', 'rim crests are dark stone, got ' .. crest)
    local allowed = {Grass = true, LeafyGrass = true, Ground = true, Rock = true}
    local blades = false
    for _, pt in {{215, 0}, {-215, 0}, {180, 200}, {-152, 152}, {100, 190}, {-150, -150}, {150, -150}, {230, -60}, {-230, 60}} do
        local m = Landscape.material(pt[1], pt[2])
        assert(allowed[m], string.format('unexpected hill material %s at (%d, %d)', tostring(m), pt[1], pt[2]))
        if m == 'Grass' then blades = true end
    end
    assert(blades, 'the near hills should carry Grass so decoration blades appear somewhere')
end)
check('WriteVoxels layers sit half a cell above the region coordinate that addresses them', function()
    -- Measured in Studio 2026-09-10: a region starting at y -12 rendered its third layer as the cell spanning -2 to 2,
    -- so the layer addressed at y0 occupies [y0 + 2, y0 + 6).
    assert(Landscape.CellShift == 2)
    assert(Landscape.layerBottom(-12, 1) == -10)
    assert(Landscape.layerBottom(-12, 3) == -2)
    assert(Landscape.layerBottom(-12, 4) == 2)
end)
check('voxel cells carry ground occupancy, water where the ground dips under the water level, and air above', function()
    local function cell(h, material, bottom)
        local name, occupancy = Landscape.voxel(h, material, bottom)
        return name .. ':' .. string.format('%.3f', occupancy)
    end
    -- level town column: solid below, 1.5 of the cell spanning -2..2 filled so the surface lands on y -0.5, air above
    assert(cell(-0.5, 'LeafyGrass', -6) == 'LeafyGrass:1.000')
    assert(cell(-0.5, 'LeafyGrass', -2) == 'LeafyGrass:0.375')
    assert(cell(-0.5, 'LeafyGrass', 2) == 'Air:0.000')
    -- pond centre: mud bed at -6, water filling exactly the cell -6..-2, air from -2 up
    assert(cell(-6, 'Mud', -10) == 'Mud:1.000')
    assert(cell(-6, 'Mud', -6) == 'Water:1.000')
    assert(cell(-6, 'Mud', -2) == 'Air:0.000')
    -- pond bank: a cell more than half ground stays ground, a thinner sliver of ground under water becomes water
    assert(cell(-3, 'Mud', -6) == 'Mud:0.750')
    assert(cell(-4.5, 'Mud', -6) == 'Water:1.000')
    assert(cell(-1, 'Mud', -2) == 'Mud:0.250')
    -- hillside: partial top cell, nothing above
    assert(cell(9, 'Grass', 6) == 'Grass:0.750')
    assert(cell(9, 'Grass', 10) == 'Air:0.000')
end)
check('the rebirth shrine stands clear of every Haunt walkway', function()
    -- Walkways run from 0.295 x centre to the Haunt centre and are 12 wide plus a 0.4 curb (World.luau).
    local walkways = {}
    for _, i in {1, 2, 3, 4, 6, 7, 8} do
        local angle = math.rad(20 + (i - 1) * 40)
        local cx, cz = math.sin(angle) * 116, math.cos(angle) * 116
        table.insert(walkways, {ax = cx * 0.295, az = cz * 0.295, bx = cx, bz = cz})
    end
    table.insert(walkways, {ax = 0, az = -34, bx = 0, bz = -129, half = 9.4}) -- mansion avenue, 18 wide
    local function clearance(x, z)
        local best = math.huge
        for _, w in walkways do
            local dx, dz = w.bx - w.ax, w.bz - w.az
            local t = math.clamp(((x - w.ax) * dx + (z - w.az) * dz) / (dx * dx + dz * dz), 0, 1)
            local px, pz = w.ax + dx * t, w.az + dz * t
            best = math.min(best, math.sqrt((x - px) ^ 2 + (z - pz) ^ 2) - (w.half or 6.4))
        end
        return best
    end
    -- Coordinates mirror World.luau: altar mesh 12.2 wide, caretaker 2.2, pumpkin 3.1.
    for _, item in {{33.5, 40, 6.1, 'rebirth altar'}, {38, 46.5, 1.1, 'Orin'}, {28.5, 46, 1.6, 'pumpkin'}} do
        local gap = clearance(item[1], item[2]) - item[3]
        assert(gap >= 1, string.format('%s at (%.1f, %.1f) overlaps a walkway by %.1f studs', item[4], item[1], item[2], -gap))
        flatAt(item[1], item[2], item[4])
    end
end)
print(count .. ' landscape groups passed')

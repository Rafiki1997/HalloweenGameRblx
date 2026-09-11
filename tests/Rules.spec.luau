local Rules = require('../src/shared/Rules')
local Config = require('../src/shared/Config')
local count = 0
local function check(name, test)
    test()
    count += 1
    print('PASS ' .. name)
end
check('Little Boo joins the existing roster and survives capture, deposit and save reconciliation', function()
    local species=0
    for _ in Config.Ghosts do species+=1 end
    assert(species==15)
    assert(Config.Ghosts.mothlight and Config.Ghosts.door_to_nowhere)
    local g=Config.Ghosts.little_boo
    assert(g and g.Shape=='ReferenceGhost' and g.Rarity==1 and g.Weight>0)
    assert(table.find(g.Areas,1))
    local p=Rules.newProfile()
    assert(Rules.captureReward(p,'little_boo'))
    Rules.deposit(p)
    assert(Rules.place(p,'little_boo'))
    p=Rules.reconcile(p)
    assert(p.Owned.little_boo==1 and p.Discovered.little_boo and p.Placed[1]=='little_boo')
    assert(Rules.income(p)==g.Income)
end)
check('clicks matter and capture never progresses on a timer', function()
    assert(Rules.capture(0.5, 0, 1, 1, 1) < 0.5)
    assert(Rules.capture(0, 1, 1, 1, 0) > 0)
    assert(Rules.capture(0, 1, 1, 7, 0) < Rules.capture(0, 1, 1, 1, 0))
end)
check('capture capacity, deposit and slot ownership are enforced', function()
    local p = Rules.newProfile()
    assert(not Rules.place(p, 'mothlight'))
    for _ = 1, 3 do assert(Rules.captureReward(p, 'mothlight')) end
    assert(not Rules.captureReward(p, 'mothlight'))
    assert(not Rules.place(p, 'mothlight'))
    Rules.deposit(p)
    assert(Rules.place(p, 'mothlight'))
    assert(Rules.place(p, 'mothlight'))
    assert(Rules.place(p, 'mothlight'))
    assert(not Rules.place(p, 'mothlight'))
    assert(Rules.income(p) == Config.Ghosts.mothlight.Income * 3)
end)
check('purchases reject invalid or unaffordable requests', function()
    local p = Rules.newProfile()
    assert(not Rules.upgrade(p, 'Capture'))
    assert(not Rules.upgrade(p, 'Money'))
    assert(not Rules.unlock(p, 6))
    assert(not Rules.unlock(p, 0/0))
    p.Money = 1e9
    assert(Rules.upgrade(p, 'Capture'))
    assert(p.Upgrades.Capture == 2)
    assert(Rules.unlock(p, 2))
    assert(not Rules.unlock(p, 2))
end)
check('rebirth preserves collection but resets temporary progression', function()
    local p = Rules.newProfile()
    assert(not Rules.rebirth(p))
    p.Money = Rules.rebirthCost(p)
    p.Floor = 6
    p.Owned.mothlight = 2
    p.Discovered.mothlight = true
    p.Placed = {'mothlight'}
    assert(Rules.rebirth(p))
    assert(p.Rebirths == 1 and p.Floor == 1 and p.Money == 0)
    assert(p.Owned.mothlight == 2 and p.Discovered.mothlight and #p.Placed == 0)
    assert(Rules.place(p, 'mothlight'))
    assert(Rules.income(p) == Config.Ghosts.mothlight.Income * 1.5)
end)
check('loaded profiles reconcile invalid data and prevent phantom copies', function()
    local p = Rules.reconcile({Money = 0/0, Floor = 99, Owned = {mothlight = 1, bad = 99}, Placed = {'mothlight', 'mothlight'}, Bag = {'bad'}})
    assert(p.Money == 0 and p.Floor == 6)
    assert(p.Owned.bad == nil and #p.Placed == 1 and #p.Bag == 0)
end)
check('all rarities have multiple ghosts and every floor has a spawn pool', function()
    local rarities = {}
    for _, g in Config.Ghosts do rarities[g.Rarity] = (rarities[g.Rarity] or 0) + 1 end
    for i = 1, 7 do assert(rarities[i] >= 2) end
    for i = 1, 6 do assert(#Rules.pool(i) > 0) end
end)
check('upgraded equipment can capture every rarity with sustained clicks', function()
    for _,g in Config.Ghosts do
        local progress=0
        for _=1,1800 do
            progress=Rules.capture(progress,1,6,g.Difficulty,0)
            if progress>=1 then break end
            progress=Rules.capture(progress,0,6,g.Difficulty,0.15)
        end
        assert(progress>=1, 'Uncatchable ghost: '..g.Name)
    end
end)
check('chamber rewards require placed hunters and permitted area', function()
    local p=Rules.newProfile()
    assert(not Rules.chamberReward(p,'mothlight'))
    Rules.captureReward(p,'mothlight'); Rules.deposit(p); Rules.place(p,'mothlight')
    assert(not Rules.chamberReward(p,'door_to_nowhere'))
    assert(Rules.chamberReward(p,'mothlight'))
    assert(p.Owned.mothlight==2 and #p.Bag==0 and p.ChamberDiscoveries==1)
end)
check('slot removals reject malformed requests and release the exact copy', function()
    local p=Rules.newProfile()
    Rules.captureReward(p,'mothlight'); Rules.deposit(p); Rules.place(p,'mothlight')
    for _,bad in {'1',{},-1,0,1.5,2,0/0,math.huge} do assert(not Rules.remove(p,bad)) end
    assert(Rules.remove(p,1)); assert(Rules.available(p,'mothlight')==1)
end)
check('a full simulated progression reaches rebirth without extra currencies', function()
    local p=Rules.newProfile()
    Rules.captureReward(p,'mothlight'); Rules.deposit(p); Rules.place(p,'mothlight')
    local seconds=0
    for floor=2,6 do
        local needed=Config.Floors[floor].Cost-p.Money
        local elapsed=math.ceil(math.max(0,needed)/Rules.income(p))
        p.Money+=elapsed*Rules.income(p); seconds+=elapsed
        assert(Rules.unlock(p,floor))
        local best=Rules.pool(floor)[1]
        for _,id in Rules.pool(floor) do if Config.Ghosts[id].Income>Config.Ghosts[best].Income then best=id end end
        assert(Rules.captureReward(p,best)); Rules.deposit(p)
        if #p.Placed==Config.Slots[p.HauntLevel] then Rules.remove(p,1) end
        assert(Rules.place(p,best))
    end
    p.Money=Rules.rebirthCost(p)
    assert(Rules.rebirth(p))
    assert(p.Rebirths==1)
    print('Optimistic progression income-wait seconds (excludes hunting): '..seconds)
end)
print(string.format('%d rule groups passed', count))

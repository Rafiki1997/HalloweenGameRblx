local Config = if script then require(script.Parent.Config) else require('./Config')
local R = {}
local function integer(v, lo, hi, fallback)
    if type(v) ~= 'number' or v ~= v or math.abs(v) == math.huge then return fallback end
    return math.clamp(math.floor(v), lo, hi)
end
function R.newProfile()
    return {Version=1,Money=0,Owned={},Discovered={},Bag={},Placed={},HauntLevel=1,Floor=1,Rebirths=0,
        Upgrades={Suction=1,Capture=1,Capacity=1,Movement=1,Flashlight=1},Captures=0,ChamberDiscoveries=0}
end
function R.reconcile(raw)
    local p = R.newProfile()
    if type(raw) ~= 'table' then return p end
    p.Money = integer(raw.Money,0,1e15,0)
    p.HauntLevel = integer(raw.HauntLevel,1,5,1)
    p.Floor = integer(raw.Floor,1,6,1)
    p.Rebirths = integer(raw.Rebirths,0,10000,0)
    p.Captures = integer(raw.Captures,0,1e12,0)
    p.ChamberDiscoveries = integer(raw.ChamberDiscoveries,0,1e12,0)
    for name in p.Upgrades do
        p.Upgrades[name] = integer(type(raw.Upgrades)=='table' and raw.Upgrades[name],1,6,1)
    end
    for id in Config.Ghosts do
        local qty = integer(type(raw.Owned)=='table' and raw.Owned[id],0,1e9,0)
        if qty > 0 then p.Owned[id] = qty end
        if qty > 0 or (type(raw.Discovered)=='table' and raw.Discovered[id] == true) then p.Discovered[id] = true end
    end
    local used = {}
    for _, field in {'Bag','Placed'} do
        if type(raw[field]) == 'table' then
            local limit = if field=='Bag' then R.capacity(p) else Config.Slots[p.HauntLevel]
            for _, id in raw[field] do
                if type(id)=='string' and Config.Ghosts[id] and #p[field]<limit and (used[id] or 0)<(p.Owned[id] or 0) then
                    table.insert(p[field],id)
                    used[id]=(used[id] or 0)+1
                end
            end
        end
    end
    return p
end
function R.capacity(p) return Config.Capacity[p.Upgrades.Capacity] end
function R.multiplier(p) return 1+p.Rebirths*0.5 end
function R.income(p)
    local sum=0
    for _, id in p.Placed do sum += Config.Ghosts[id].Income end
    return sum * R.multiplier(p)
end
function R.capture(progress, clicks, power, difficulty, dt)
    return math.clamp(progress + clicks*(0.085+0.025*(power-1))/difficulty - dt*0.028*difficulty,0,1)
end
function R.captureReward(p,id)
    if not Config.Ghosts[id] or #p.Bag>=R.capacity(p) then return false end
    p.Owned[id]=(p.Owned[id] or 0)+1
    p.Discovered[id]=true
    p.Captures+=1
    table.insert(p.Bag,id)
    return true
end
function R.chamberReward(p,id)
    if #p.Placed==0 or not Config.Ghosts[id] or not table.find(Config.Ghosts[id].Areas,p.Floor) then return false end
    p.Owned[id]=(p.Owned[id] or 0)+1
    p.Discovered[id]=true
    p.ChamberDiscoveries+=1
    return true
end
function R.deposit(p) table.clear(p.Bag) end
function R.available(p,id)
    local n=p.Owned[id] or 0
    for _, v in p.Placed do if v==id then n-=1 end end
    for _, v in p.Bag do if v==id then n-=1 end end
    return n
end
function R.place(p,id)
    if not Config.Ghosts[id] or #p.Placed>=Config.Slots[p.HauntLevel] or R.available(p,id)<=0 then return false end
    table.insert(p.Placed,id)
    return true
end
function R.remove(p,index)
    if type(index)~='number' or index~=math.floor(index) or index<1 or index>#p.Placed then return false end
    table.remove(p.Placed,index)
    return true
end
function R.upgradeCost(p,name)
    if name=='Haunt' then return Config.HauntCosts[p.HauntLevel+1] end
    if not Config.UpgradeBase[name] or p.Upgrades[name]>=Config.MaxUpgrade then return nil end
    return math.floor(Config.UpgradeBase[name]*4^(p.Upgrades[name]-1))
end
function R.upgrade(p,name)
    local cost=R.upgradeCost(p,name)
    if not cost or p.Money<cost then return false end
    p.Money-=cost
    if name=='Haunt' then p.HauntLevel+=1 else p.Upgrades[name]+=1 end
    return true
end
function R.unlock(p,floor)
    if type(floor)~='number' or floor~=p.Floor+1 or not Config.Floors[floor] then return false end
    local cost=Config.Floors[floor].Cost
    if p.Money<cost then return false end
    p.Money-=cost
    p.Floor=floor
    return true
end
function R.rebirthCost(p) return 5000000000*(1+p.Rebirths) end
function R.rebirth(p)
    if p.Floor<6 or p.Money<R.rebirthCost(p) then return false end
    p.Money=0
    p.Floor=1
    p.HauntLevel=1
    p.Rebirths+=1
    table.clear(p.Bag)
    table.clear(p.Placed)
    for name in p.Upgrades do p.Upgrades[name]=1 end
    return true
end
function R.pool(floor)
    local result={}
    for id,g in Config.Ghosts do if table.find(g.Areas,floor) then table.insert(result,id) end end
    table.sort(result)
    return result
end
function R.roll(floor,unit)
    local pool=R.pool(floor)
    local total=0
    for _,id in pool do total+=Config.Ghosts[id].Weight end
    local pick=unit*total
    for _,id in pool do pick-=Config.Ghosts[id].Weight; if pick<=0 then return id end end
    return pool[#pool]
end
return R

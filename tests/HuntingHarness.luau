-- tools/verify.py inserts the real Hunting module at the marker below. The small
-- engine doubles let us exercise server encounter transitions with a deterministic clock.
local Config=require('../src/shared/Config')
local RealRules=require('../src/shared/Rules')
local now=10
local os={clock=function() return now end}
local Vector3={}
local vectorMeta={}
function Vector3.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectorMeta) end
vectorMeta.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vectorMeta.__index=function(v,k)
    local length=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
    if k=='Magnitude' then return length end
    if k=='Unit' then return Vector3.new(v.X/length,v.Y/length,v.Z/length) end
    return nil
end
local CFrame={new=function(pos) return {Position=pos} end,lookAt=function(pos) return {Position=pos} end}
local function object()
    return {Parent=true,Attributes={},SetAttribute=function(self,k,v) self.Attributes[k]=v end,
        PivotTo=function(self,cf) self.Position=cf.Position end,Destroy=function(self) self.Parent=nil end}
end
local Instance={new=object}
local Random={new=function() return {NextNumber=function(_,a,b) return if a then (a+b)/2 else 0.5 end} end}
local RaycastParams={new=function() return {} end}
local Enum={RaycastFilterType={Exclude=1}}
local blocked=false
local workspace={Raycast=function() return if blocked then {} else nil end,GetServerTimeNow=function() return now end}
local roster={}
local removed
local Players={GetPlayers=function() return roster end,PlayerRemoving={Connect=function(_,fn) removed=fn end}}
local guid=0
local modules={Config=Config,Rules=RealRules,Visuals={ghost=function() return object() end}}
local services={Players=Players,HttpService={GenerateGUID=function() guid+=1; return tostring(guid) end},
    ReplicatedStorage={WaitForChild=function() return modules end}}
local game={GetService=function(_,name) return services[name] end}
local loops={}
local task={spawn=function(fn) table.insert(loops,coroutine.create(fn)) end,wait=function() coroutine.yield(); return true end,delay=function() end}
local function loadHunting()
    local require=function(value) return value end
    -- HUNTING_SOURCE
end
local H=loadHunting()
local world={Areas={},Root=object()}
for i=1,6 do world.Areas[i]={Center=Vector3.new(0,0,i*200),GhostZones={{Center=Vector3.new(12,4,i*200-15),X=5,Z=6}}} end
local events={}
local remote={FireClient=function(_,player,event,data) table.insert(events,{Player=player,Event=event,Data=data}) end,
    FireAllClients=function(_,event,data) table.insert(events,{Event=event,Data=data}) end}
local profiles={get=function(player) return player.Data end}
H.start(world,profiles,remote,function() end)
local function step(dt)
    now+=dt or 0.1
    for _,co in loops do local ok,err=coroutine.resume(co); assert(ok,err) end
end
step(0) -- Prime the heartbeat coroutine at its first wait.
local function playerAt(pos,id)
    local root={Position=pos,Anchored=false,Parent=true}
    local hum={Health=100,TakeDamage=function(self,n) self.Health-=n end}
    local char={FindFirstChild=function(_,name) return if name=='HumanoidRootPart' then root else {} end,
        FindFirstChildOfClass=function() return hum end}
    local p={UserId=id,Character=char,Data=RealRules.newProfile(),Attributes={Floor=1}}
    function p:GetAttribute(k) return self.Attributes[k] end
    return p,root,hum
end
local ghost
for _,g in H.Ghosts do if g.Floor==1 then ghost=g; break end end
assert(ghost)
-- Isolate contact from the other spawned ghosts.
H.Ghosts={[ghost.Id]=ghost}
local p,root,hum=playerAt(ghost.Pos,1)
local other=playerAt(ghost.Pos,2)
roster={p,other}
local function count(event)
    local n=0
    for _,e in events do if e.Event==event then n+=1 end end
    return n
end
local passed=0
local function check(condition,name)
    assert(condition,name); passed+=1; print('PASS encounter: '..name)
end
check(ghost.RoamZone and (ghost.Pos-ghost.RoamZone.Center).Magnitude<.01,'ghost spawns in its assigned clear room pocket')
step()
check(H.Active[p]==ghost and ghost.Owner==p and root.Anchored,'contact reserves one ghost and freezes the hunter')
check(count('EncounterStart')==1 and count('BeamOn')==0 and H.Active[other]==nil,'one client gets the intro; another cannot steal the ghost')
H.click(p,ghost.Id); H.click(other,ghost.Id)
step(Config.Encounter.Duration-0.2)
check(ghost.Progress==0 and hum.Health==100 and root.Anchored and count('BeamOn')==0,'clicks, attacks and capture stay paused through the intro')
step(0.3)
check(root.Anchored and not ghost.IntroUntil and ghost.Battle and count('BattleStart')==1 and count('BeamOn')==1,'intro enters 1v1 once and keeps mansion actors frozen')
H.click(p,ghost.Id)
check(ghost.Progress>0,'clicking after the intro advances capture')
local originalPos=ghost.Pos
step(Config.Battle.SpotDelay)
local spot=ghost.Spot
check(spot~=nil and count('WeakSpot')==1,'server schedules a closing circle for the battle owner')
local claim={Id=ghost.Id,Token=spot.Token,X=spot.X,Y=spot.Y}
local before=ghost.Progress
H.weakSpot(p,claim)
check(ghost.Progress==before and ghost.Spot==spot,'early circle claims do not grant progress')
now=spot.EndsAt
H.click(p,ghost.Id)
before=ghost.Progress
H.weakSpot(other,claim)
H.weakSpot(p,{Id=ghost.Id,Token='forged',X=spot.X,Y=spot.Y})
H.weakSpot(p,{Id='wrong ghost',Token=spot.Token,X=spot.X,Y=spot.Y})
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=0/0,Y=spot.Y})
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=math.huge,Y=spot.Y})
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X='bad',Y=spot.Y})
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=0,Y=0})
check(ghost.Progress==before,'foreign, forged, mismatched, malformed and outside-circle claims are rejected')
H.weakSpot(p,claim)
check(math.abs(ghost.Progress-before-Config.Battle.SpotBonus)<1e-6 and ghost.Spot==nil,'valid closing-circle hover adds 12 percentage points to clicks')
before=ghost.Progress; H.weakSpot(p,claim)
check(ghost.Progress==before,'replaying a circle cannot award twice')
step(Config.Battle.SpotGap+Config.Battle.LateTolerance+0.1)
spot=ghost.Spot
check(spot~=nil and spot.Token~=claim.Token,'next circle gets a new token')
now=spot.EndsAt+Config.Battle.LateTolerance+0.01
H.click(p,ghost.Id); before=ghost.Progress
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=spot.X,Y=spot.Y})
check(ghost.Progress==before,'late claims do not grant progress')
step()
check(ghost.Pos==originalPos and hum.Health==100 and root.Anchored,'battle cannot move the ghost away or damage the frozen player')
step(Config.Battle.SpotGap+0.1)
spot=ghost.Spot; assert(spot)
now=spot.EndsAt; ghost.LastClick=now-Config.Capture.IdleTimeout-0.1; before=ghost.Progress
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=spot.X,Y=spot.Y})
check(ghost.Progress==before,'hover alone without recent clicks cannot farm captures')
H.cancel(p,'')
step()
check(not H.Active[p] and not root.Anchored,'release cleans up and contact cooldown prevents immediate retrigger')
roster={p}
H.cancel(other,'')
now+=Config.Encounter.Cooldown+1
root.Position=ghost.Pos
blocked=true
H.click(p,ghost.Id)
check(not H.Active[p],'walls block encounter initiation')
blocked=false
p.Data.Bag={'little_boo','little_boo','little_boo'}
step()
check(not H.Active[p],'full bag blocks automatic encounters')
p.Data.Bag={}
p.Attributes.Floor=0
step()
check(not H.Active[p],'town players cannot trigger mansion ghosts')
p.Attributes.Floor=1
now+=1; H.click(p,ghost.Id)
check(root.Anchored and ghost.IntroUntil~=nil,'a later encounter starts normally')
p.Attributes.Floor=0
step()
check(not root.Anchored and not ghost.Owner,'travel during the intro releases the reservation and root')
p.Attributes.Floor=1; now+=Config.Encounter.Cooldown+1
root.Anchored=true
H.click(p,ghost.Id); H.cancel(p,'')
check(root.Anchored,'cleanup preserves a root that was already anchored')
root.Anchored=false; now+=Config.Encounter.Cooldown+1
H.click(p,ghost.Id); hum.Health=0; step()
check(not root.Anchored and not H.Active[p],'death during the intro restores movement and releases the ghost')
hum.Health=100; now+=Config.Encounter.Cooldown+1
H.click(p,ghost.Id); step(Config.Encounter.Duration+0.1)
step(Config.Battle.IdleTimeout+0.1)
check(not root.Anchored and not H.Active[p],'inactive 1v1 times out and restores exploration')
now+=Config.Encounter.Cooldown+1
H.click(p,ghost.Id); step(Config.Encounter.Duration+0.1)
step(Config.Battle.SpotDelay)
spot=ghost.Spot; now=spot.EndsAt
H.click(p,ghost.Id); ghost.Progress=0.98
local bagBefore=#p.Data.Bag
H.weakSpot(p,{Id=ghost.Id,Token=spot.Token,X=spot.X,Y=spot.Y})
check(ghost.Progress==1,'bonus clamps capture progress at 100 percent')
step(); step()
check(#p.Data.Bag==bagBefore+1 and not H.Active[p] and not root.Anchored,'bonus completion grants one ghost and releases the battle')
-- Reinsert the fixture ghost to cover disconnect cleanup in a subsequent session.
ghost.Finishing=nil; ghost.Owner=nil; H.Ghosts[ghost.Id]=ghost
hum.Health=100; now+=Config.Encounter.Cooldown+1
H.click(p,ghost.Id); removed(p)
check(not root.Anchored and not H.Active[p] and not H.NextEncounter[p] and not H.LastClick[p],'disconnect cleans up reservation, root and cooldown tables')
roster={}
ghost.NextMove=now+100
ghost.Target=ghost.RoamZone.Center+Vector3.new(100,0,100)
for _=1,200 do step() end
local offset=ghost.Pos-ghost.RoamZone.Center
check(math.abs(offset.X)<=ghost.RoamZone.X and math.abs(offset.Z)<=ghost.RoamZone.Z,'roaming stays in its room even when a target lies beyond the walls')
print(passed..' encounter checks passed')

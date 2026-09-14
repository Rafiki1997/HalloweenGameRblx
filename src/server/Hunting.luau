local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local C=require(Shared.Config)
local Rules=require(Shared.Rules)
local V=require(Shared.Visuals)
local H={Ghosts={},Active={},LastClick={},NextEncounter={}}
local rng=Random.new()
local world,profiles,remote,onChanged
local function character(player)
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local humanoid=char and char:FindFirstChildOfClass('Humanoid')
    return if root and humanoid and humanoid.Health>0 then root else nil
end
local function equipped(player)
    return player.Character and player.Character:FindFirstChild('Spectral Vacuum')
end
local function releaseEncounter(g)
    if g.FrozenRoot and g.FrozenRoot.Parent then g.FrozenRoot.Anchored=g.WasAnchored end
    g.FrozenRoot=nil; g.IntroUntil=nil; g.Battle=nil; g.Spot=nil; g.NextSpot=nil
end
function H.cancel(player,message)
    local g=H.Active[player]
    if g then
        releaseEncounter(g)
        H.NextEncounter[player]=os.clock()+C.Encounter.Cooldown
        g.Owner=nil; g.Progress=0; g.Model:SetAttribute('Hunter',nil)
        H.Active[player]=nil
        remote:FireAllClients('BeamOff',{UserId=player.UserId})
        remote:FireClient(player,'CaptureEnd',message or 'Ghost escaped! Keep clicking during the encounter.')
    end
end
local function spawnGhost(floor)
    local area=world.Areas[floor]
    local species=Rules.roll(floor,rng:NextNumber())
    local pos=area.Center+Vector3.new(rng:NextNumber(-46,46),4,rng:NextNumber(-32,24))
    local zone
    if area.GhostZones then
        zone=area.GhostZones[math.min(#area.GhostZones,math.floor(rng:NextNumber(0,#area.GhostZones))+1)]
        pos=zone.Center+Vector3.new(rng:NextNumber(-zone.X,zone.X),0,rng:NextNumber(-zone.Z,zone.Z))
    end
    local id=Http:GenerateGUID(false)
    local model=V.ghost(species,world.GhostFolder,CFrame.new(pos),1,true)
    model.Name='Ghost_'..id; model:SetAttribute('GhostId',id); model:SetAttribute('Floor',floor)
    local g={Id=id,Species=species,Floor=floor,Model=model,Pos=pos,Target=pos,RoamZone=zone,Progress=0,NextMove=0,Seed=rng:NextNumber(0,20)}
    H.Ghosts[id]=g
    return g
end
function H.click(player,id)
    if type(id)~='string' or #id>60 then return end
    local now=os.clock()
    if now-(H.LastClick[player] or 0)<C.Capture.ClickInterval then return end
    H.LastClick[player]=now
    local p=profiles.get(player)
    local root=character(player)
    if not p or not root or not equipped(player) or player:GetAttribute('Chamber') then return end
    local g=H.Ghosts[id]
    if not g or g.Finishing or (g.Owner and g.Owner~=player) or g.Floor>p.Floor or player:GetAttribute('Floor')~=g.Floor then return end
    if #p.Bag>=Rules.capacity(p) then remote:FireClient(player,'Notice','VACUUM FULL • Return to your Haunt to deposit.'); return end
    if H.Active[player] and H.Active[player]~=g then return end
    if g.IntroUntil then return end
    local range=if g.Owner then C.Capture.BreakRange else C.Capture.Range+p.Upgrades.Suction
    if (root.Position-g.Pos).Magnitude>range then return end
    if not g.Owner then
        if now<(H.NextEncounter[player] or 0) then return end
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character,world.GhostFolder}
        local hit=workspace:Raycast(root.Position,g.Pos-root.Position,params)
        if hit then return end
        g.Owner=player; g.Progress=0; g.Start=now; H.Active[player]=g
        g.Model:SetAttribute('Hunter',player.UserId)
        -- Reserve immediately, but do not attack, decay progress, or start suction under the wipe.
        g.IntroUntil=now+C.Encounter.Duration
        g.FrozenRoot=root; g.WasAnchored=root.Anchored; root.Anchored=true
        remote:FireClient(player,'EncounterStart',{Id=g.Id,Species=g.Species,EndsAt=workspace:GetServerTimeNow()+C.Encounter.Duration})
        return
    end
    g.LastClick=now
    g.LastActivity=now
    g.Progress=Rules.capture(g.Progress,1,p.Upgrades.Capture,C.Ghosts[g.Species].Difficulty,0)
end
local function sendProgress(player,g)
    remote:FireClient(player,'CaptureProgress',{Id=g.Id,Progress=g.Progress,Species=g.Species,Battle=true})
end
local function spawnSpot(player,g,now)
    local spot={Token=Http:GenerateGUID(false),X=rng:NextNumber(0.24,0.76),Y=rng:NextNumber(0.24,0.76),
        EndsAt=workspace:GetServerTimeNow()+C.Battle.SpotDuration}
    g.Spot=spot
    g.NextSpot=now+C.Battle.SpotDuration+C.Battle.LateTolerance+C.Battle.SpotGap
    remote:FireClient(player,'WeakSpot',{Id=g.Id,Token=spot.Token,X=spot.X,Y=spot.Y,EndsAt=spot.EndsAt})
end
function H.weakSpot(player,claim)
    if type(claim)~='table' or type(claim.Token)~='string' or #claim.Token>60 then return end
    -- The client reports a pointer position, never a reward amount or trusted timestamp.
    for _,key in {'X','Y'} do
        local n=claim[key]
        if type(n)~='number' or n~=n or n<0 or n>1 then return end
    end
    local g=H.Active[player]
    local p=profiles.get(player)
    local root=character(player)
    if not g or not g.Battle or g.Finishing or not g.Spot or not p or not root or root~=g.FrozenRoot then return end
    if not equipped(player) or player:GetAttribute('Chamber') or player:GetAttribute('Floor')~=g.Floor or #p.Bag>=Rules.capacity(p) then return end
    local spot=g.Spot
    if claim.Id~=g.Id or claim.Token~=spot.Token then return end
    local offset=workspace:GetServerTimeNow()-spot.EndsAt
    if offset< -C.Battle.EarlyTolerance or offset>C.Battle.LateTolerance then return end
    if (claim.X-spot.X)^2+(claim.Y-spot.Y)^2>C.Battle.SpotRadius^2 then return end
    -- Aim bonuses supplement active clicking. Parking the cursor alone cannot farm captures.
    if os.clock()-g.LastClick>C.Capture.IdleTimeout then return end
    g.Spot=nil -- Consume before changing progress: replayed claims cannot award twice.
    local before=g.Progress
    g.Progress=math.min(1,g.Progress+C.Battle.SpotBonus)
    g.LastActivity=os.clock()
    remote:FireClient(player,'WeakSpotResult',{Id=g.Id,Token=spot.Token,Hit=true,Bonus=g.Progress-before,Progress=g.Progress})
    sendProgress(player,g)
end
local function finish(player,g,p)
    g.Finishing=true
    if not Rules.captureReward(p,g.Species) then g.Finishing=false; H.cancel(player,'Vacuum full.'); return end
    -- Award once on the server. The visual finale cannot grant or repeat a reward.
    releaseEncounter(g)
    H.Active[player]=nil; H.Ghosts[g.Id]=nil
    H.NextEncounter[player]=os.clock()+C.Encounter.Cooldown
    remote:FireAllClients('Captured',{UserId=player.UserId,Id=g.Id,Species=g.Species})
    onChanged(player)
    task.delay(0.8,function() g.Model:Destroy() end)
    task.delay(4,function() spawnGhost(g.Floor) end)
end
function H.start(w,p,r,changed)
    world=w; profiles=p; remote=r; onChanged=changed
    world.GhostFolder=Instance.new('Folder'); world.GhostFolder.Name='WildGhosts'; world.GhostFolder.Parent=world.Root
    for floor=1,6 do for _=1,7 do spawnGhost(floor) end end
    task.spawn(function()
        while task.wait(C.Capture.Tick) do
            local now=os.clock()
            for _,g in H.Ghosts do
                local area=world.Areas[g.Floor]
                local old=g.Pos
                if g.Owner then
                    local player=g.Owner
                    local data=profiles.get(player)
                    local root=character(player)
                    if g.IntroUntil then
                        if not root or root~=g.FrozenRoot or not data or not equipped(player) or player:GetAttribute('Chamber') or player:GetAttribute('Floor')~=g.Floor then
                            H.cancel(player,'')
                        elseif now>=g.IntroUntil then
                            g.IntroUntil=nil; g.Battle=true
                            g.Start=now; g.LastClick=now; g.LastActivity=now; g.NextSpot=now+C.Battle.SpotDelay
                            remote:FireClient(player,'BattleStart',{Id=g.Id,Species=g.Species,Progress=0})
                            remote:FireAllClients('BeamOn',{UserId=player.UserId,Id=g.Id})
                        end
                        continue
                    end
                    if not root or root~=g.FrozenRoot or not data or not equipped(player) or player:GetAttribute('Chamber') or player:GetAttribute('Floor')~=g.Floor or (root.Position-g.Pos).Magnitude>C.Capture.BreakRange or now-g.LastActivity>C.Battle.IdleTimeout or now-g.Start>C.Battle.MaxDuration then
                        H.cancel(player)
                    else
                        if g.Progress>=1 then finish(player,g,data); continue end
                        g.Progress=Rules.capture(g.Progress,0,data.Upgrades.Capture,C.Ghosts[g.Species].Difficulty,C.Capture.Tick)
                        -- The mansion actors stay reserved and stationary for the whole 1v1.
                        -- Resistance still drains progress, but no off-screen chase or damage occurs.
                        if g.Spot and workspace:GetServerTimeNow()>g.Spot.EndsAt+C.Battle.LateTolerance then
                            remote:FireClient(player,'WeakSpotResult',{Id=g.Id,Token=g.Spot.Token,Hit=false,Progress=g.Progress})
                            g.Spot=nil
                        end
                        if now>=g.NextSpot then spawnSpot(player,g,now) end
                        sendProgress(player,g)
                    end
                else
                    -- Anchored, non-colliding ghosts do not reliably fire Touched. Check contact
                    -- on the server, then use the same capacity/floor/line-of-sight validation as clicks.
                    for _,player in Players:GetPlayers() do
                        local root=character(player)
                        if root and not H.Active[player] and now>=(H.NextEncounter[player] or 0) and player:GetAttribute('Floor')==g.Floor and (root.Position-g.Pos).Magnitude<=C.Encounter.TouchRange then
                            local data=profiles.get(player)
                            if data and #data.Bag<Rules.capacity(data) then H.click(player,g.Id) end
                            if g.Owner then break end
                        end
                    end
                    if g.Owner then continue end
                    if now>g.NextMove then
                        g.NextMove=now+rng:NextNumber(2,5)
                        g.Target=area.Center+Vector3.new(rng:NextNumber(-48,48),4,rng:NextNumber(-37,28))
                        if g.RoamZone then
                            local zone=g.RoamZone
                            g.Target=zone.Center+Vector3.new(rng:NextNumber(-zone.X,zone.X),0,rng:NextNumber(-zone.Z,zone.Z))
                        end
                        for _,player in Players:GetPlayers() do
                            local root=character(player)
                            if root and player:GetAttribute('Floor')==g.Floor and (root.Position-g.Pos).Magnitude<12 then
                                local delta=g.Pos-root.Position
                                if delta.Magnitude>0.1 then g.Target=g.Pos+delta.Unit*15 end
                                break
                            end
                        end
                    end
                    if g.RoamZone then
                        local zone=g.RoamZone
                        local offset=g.Target-zone.Center
                        g.Target=zone.Center+Vector3.new(math.clamp(offset.X,-zone.X,zone.X),0,math.clamp(offset.Z,-zone.Z,zone.Z))
                    end
                    local delta=g.Target-g.Pos
                    if delta.Magnitude>0.4 then g.Pos+=delta.Unit*math.min(delta.Magnitude,0.38) end
                    local rel=g.Pos-area.Center
                    g.Pos=area.Center+Vector3.new(math.clamp(rel.X,-51,51),4+math.sin(now*2+g.Seed)*0.5,math.clamp(rel.Z,-40,37))
                end
                if g.Model.Parent then
                    local direction=if g.Owner and character(g.Owner) then character(g.Owner).Position else g.Pos+(g.Pos-old)
                    direction=Vector3.new(direction.X,g.Pos.Y,direction.Z)
                    g.Model:PivotTo(if (direction-g.Pos).Magnitude>0.05 then CFrame.lookAt(g.Pos,direction) else CFrame.new(g.Pos))
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(player) H.cancel(player); H.LastClick[player]=nil; H.NextEncounter[player]=nil end)
end
return H

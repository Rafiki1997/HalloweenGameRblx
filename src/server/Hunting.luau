local Players=game:GetService('Players')
local Http=game:GetService('HttpService')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local C=require(Shared.Config)
local Rules=require(Shared.Rules)
local V=require(Shared.Visuals)
local H={Ghosts={},Active={},LastClick={}}
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
function H.cancel(player,message)
    local g=H.Active[player]
    if g then
        g.Owner=nil; g.Progress=0; g.Model:SetAttribute('Hunter',nil)
        H.Active[player]=nil
        remote:FireAllClients('BeamOff',{UserId=player.UserId})
        remote:FireClient(player,'CaptureEnd',message or 'Ghost escaped! Stay close and keep clicking.')
    end
end
local function spawnGhost(floor)
    local area=world.Areas[floor]
    local species=Rules.roll(floor,rng:NextNumber())
    local pos=area.Center+Vector3.new(rng:NextNumber(-46,46),4,rng:NextNumber(-32,24))
    local id=Http:GenerateGUID(false)
    local model=V.ghost(species,world.GhostFolder,CFrame.new(pos),1,true)
    model.Name='Ghost_'..id; model:SetAttribute('GhostId',id); model:SetAttribute('Floor',floor)
    local g={Id=id,Species=species,Floor=floor,Model=model,Pos=pos,Target=pos,Progress=0,NextMove=0,Seed=rng:NextNumber(0,20)}
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
    local range=if g.Owner then C.Capture.BreakRange else C.Capture.Range+p.Upgrades.Suction
    if (root.Position-g.Pos).Magnitude>range then return end
    if not g.Owner then
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character,world.GhostFolder}
        local hit=workspace:Raycast(root.Position,g.Pos-root.Position,params)
        if hit then return end
        g.Owner=player; g.Progress=0; g.Start=now; H.Active[player]=g
        g.Model:SetAttribute('Hunter',player.UserId)
        remote:FireAllClients('BeamOn',{UserId=player.UserId,Id=g.Id})
    end
                        g.LastClick=now
    g.Progress=Rules.capture(g.Progress,1,p.Upgrades.Capture,C.Ghosts[g.Species].Difficulty,0)
end
local function finish(player,g,p)
    g.Finishing=true
    if not Rules.captureReward(p,g.Species) then g.Finishing=false; H.cancel(player,'Vacuum full.'); return end
    -- Award once on the server. The visual finale cannot grant or repeat a reward.
    H.Active[player]=nil; H.Ghosts[g.Id]=nil
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
                    if not root or not data or not equipped(player) or player:GetAttribute('Floor')~=g.Floor or (root.Position-g.Pos).Magnitude>C.Capture.BreakRange or now-g.LastClick>C.Capture.IdleTimeout then
                        H.cancel(player)
                    else
                        if g.Progress>=1 then finish(player,g,data); continue end
                        g.Progress=Rules.capture(g.Progress,0,data.Upgrades.Capture,C.Ghosts[g.Species].Difficulty,C.Capture.Tick)
                        if now-(g.LastAttack or 0)>=C.Capture.AttackInterval and (root.Position-g.Pos).Magnitude<=C.Capture.AttackRange then
                            g.LastAttack=now
                            local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
                            if humanoid and not player:GetAttribute('TestInvulnerable') then humanoid:TakeDamage(C.Capture.AttackDamage*10) end
                            g.Progress=math.max(0,g.Progress-C.Capture.AttackDamage*0.08)
                            remote:FireClient(player,'GhostAttack',{Species=g.Species})
                        end
                        local away=g.Pos-root.Position
                        away=Vector3.new(away.X,0,away.Z)
                        if away.Magnitude<0.1 then away=Vector3.new(0,0,-1) end
                        away=away.Unit
                        local surge=math.sin((now-g.Start)*2.7+g.Seed)>0.55
                        local speed=if surge then 9+C.Ghosts[g.Species].Rarity else -2-data.Upgrades.Suction*0.65-g.Progress*5
                        local side=Vector3.new(-away.Z,0,away.X)*math.sin(now*5+g.Seed)*4
                        g.Pos+= (away*speed+side)*C.Capture.Tick
                        local relative=g.Pos-area.Center
                        g.Pos=area.Center+Vector3.new(math.clamp(relative.X,-51,51),4+math.sin(now*7)*0.35,math.clamp(relative.Z,-40,36))
                        remote:FireClient(player,'CaptureProgress',{Progress=g.Progress,Species=g.Species,Surge=surge})
                    end
                else
                    if now>g.NextMove then
                        g.NextMove=now+rng:NextNumber(2,5)
                        g.Target=area.Center+Vector3.new(rng:NextNumber(-48,48),4,rng:NextNumber(-37,28))
                        for _,player in Players:GetPlayers() do
                            local root=character(player)
                            if root and player:GetAttribute('Floor')==g.Floor and (root.Position-g.Pos).Magnitude<12 then
                                local delta=g.Pos-root.Position
                                if delta.Magnitude>0.1 then g.Target=g.Pos+delta.Unit*15 end
                                break
                            end
                        end
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
    Players.PlayerRemoving:Connect(function(player) H.cancel(player); H.LastClick[player]=nil end)
end
return H

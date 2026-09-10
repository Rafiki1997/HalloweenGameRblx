local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local V=require(Shared.Visuals)
local Rules=require(Shared.Rules)
local C=require(Shared.Config)
local Chamber={Sessions={}}
local rng=Random.new()
local world,profiles,remote,changed
function Chamber.leave(player)
    local s=Chamber.Sessions[player]
    if s then s.Model:Destroy(); Chamber.Sessions[player]=nil end
    player:SetAttribute('Chamber',false)
    local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    if hum then hum.AutoRotate=true end
    remote:FireClient(player,'ChamberExit')
end
function Chamber.enter(player,plotIndex)
    local p=profiles.get(player)
    if not p or #p.Placed==0 then remote:FireClient(player,'Notice','Place at least one ghost in your Haunt first.'); return false end
    if Chamber.Sessions[player] then return false end
    local center=Vector3.new((plotIndex-1)*130,0,-720)
    local m=Instance.new('Model'); m.Name='Chamber_'..player.UserId; m.Parent=world.Root
    local function part(name,size,pos,color)
        return V.part(m,name,size,CFrame.new(center+pos),color or Color3.fromRGB(62,44,72),Enum.Material.Slate)
    end
    part('MiniatureFloor',Vector3.new(68,1,54),Vector3.new(0,0,0))
    for _,s in {-1,1} do
        part('Wall',Vector3.new(68,4,1),Vector3.new(0,2,s*27))
        part('Wall',Vector3.new(1,4,54),Vector3.new(s*34,2,0))
        for _,z in {-19,19} do part('RoomWall',Vector3.new(1,4,16),Vector3.new(s*12,2,z)) end
        for _,x in {-26,26} do part('RoomWall',Vector3.new(16,4,1),Vector3.new(x,2,0)) end
    end
    for _,x in {-25,0,25} do for _,z in {-18,18} do
        part('Rug',Vector3.new(10,0.15,9),Vector3.new(x,0.65,z),Color3.fromRGB(87,42,95))
        local candle=part('Lantern',Vector3.new(0.5,2,0.5),Vector3.new(x+5,1.7,z),Color3.fromRGB(255,184,87))
        candle.Material=Enum.Material.Neon
        local light=Instance.new('PointLight'); light.Color=candle.Color; light.Range=16; light.Parent=candle
    end end
    local hunters={}
    for i,id in p.Placed do
        local pos=center+Vector3.new((i%5-2)*5,3,((math.floor(i/5))%4-2)*5)
        local ghost=V.ghost(id,m,CFrame.new(pos),0.65,false)
        table.insert(hunters,{Model=ghost,Pos=pos,Phase=i*1.7})
    end
    local preyId=Rules.roll(p.Floor,rng:NextNumber())
    local prey=V.ghost(preyId,m,CFrame.new(center+Vector3.new(22,3,-17)),0.55,true)
    Chamber.Sessions[player]={Model=m,Center=center,Hunters=hunters,Prey=prey,PreyId=preyId,Start=os.clock(),NextReward=os.clock()+C.ChamberInterval,LastStep=os.clock()}
    player:SetAttribute('Chamber',true)
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if root then player.Character:PivotTo(CFrame.new(center+Vector3.new(0,4,23))) end
    local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    if hum then hum.WalkSpeed=0; hum.AutoRotate=false end
    remote:FireClient(player,'ChamberEnter',{Center=center,Hunters=#hunters})
    return true
end
function Chamber.start(w,p,r,callback)
    world=w; profiles=p; remote=r; changed=callback
    task.spawn(function()
        while task.wait(0.2) do
            local now=os.clock()
            for player,s in Chamber.Sessions do
                local data=profiles.get(player)
                if not data then continue end
                local phase=(now-s.Start)%C.ChamberInterval
                local hunting=phase>C.ChamberInterval-8
                local target=s.Prey:GetPivot().Position
                for _,h in s.Hunters do
                    local goal=if hunting then target else s.Center+Vector3.new(math.sin(now*0.22+h.Phase)*26,3,math.cos(now*0.18+h.Phase)*19)
                    local delta=goal-h.Pos
                    if delta.Magnitude>0.25 then h.Pos+=delta.Unit*math.min(delta.Magnitude,1.3) end
                    h.Model:PivotTo(CFrame.new(h.Pos))
                end
                if now>=s.NextReward then
                    s.NextReward=now+C.ChamberInterval
                    if Rules.chamberReward(data,s.PreyId) then
                        data.Money=math.min(1e15,data.Money+Rules.income(data)*5)
                        remote:FireClient(player,'ChamberFound',{Species=s.PreyId})
                        changed(player)
                    end
                    s.Prey:Destroy()
                    s.PreyId=Rules.roll(data.Floor,rng:NextNumber())
                    s.Prey=V.ghost(s.PreyId,s.Model,CFrame.new(s.Center+Vector3.new(rng:NextNumber(-27,27),3,rng:NextNumber(-19,19))),0.55,true)
                end
            end
        end
    end)
end
return Chamber

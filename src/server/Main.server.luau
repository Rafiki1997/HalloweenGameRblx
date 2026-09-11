local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Shared=ReplicatedStorage:WaitForChild('Ghostlight')
local C=require(Shared.Config)
local Rules=require(Shared.Rules)
local V=require(Shared.Visuals)
local Profiles=require(script.Parent.Profiles)
local World=require(script.Parent.World)
local Hunt=require(script.Parent.Hunting)
local Chamber=require(script.Parent.Chamber)
local remote=Instance.new('RemoteEvent'); remote.Name='Action'; remote.Parent=Shared
local plots={}
local lastRequest={}
local closing=false
require(Shared.GhostModels).prepare()
World.build()
local function notice(player,text) remote:FireClient(player,'Notice',text) end
local function push(player)
    local p=Profiles.get(player)
    if not p then return end
    remote:FireClient(player,'State',{Profile=p,Income=Rules.income(p),Plot=plots[player],Practice=Profiles.Memory})
end
local function refreshPlot(player)
    local p=Profiles.get(player)
    local plot=plots[player] and World.Plots[plots[player]]
    if not p or not plot then return end
    for _,m in plot.Displays do m:Destroy() end
    table.clear(plot.Displays)
    plot.Label.Text=player.DisplayName.."'s Haunt\nLevel "..p.HauntLevel
    plot.IncomeLabel.Text='$'..Rules.income(p)..' / sec'
    for i,pad in plot.Slots do
        pad.Transparency=if i<=C.Slots[p.HauntLevel] then 0 else 0.8
        pad.Color=if i<=C.Slots[p.HauntLevel] then Color3.fromRGB(105,66,146) else Color3.fromRGB(35,30,46)
        if p.Placed[i] then
            local m=V.ghost(p.Placed[i],plot.Model,pad.CFrame*CFrame.new(0,2.3,0),0.65,true)
            table.insert(plot.Displays,m)
        end
    end
    local existing=plot.Model:FindFirstChild('UpgradeDecor')
    if existing then existing:Destroy() end
    local decor=Instance.new('Folder'); decor.Name='UpgradeDecor'; decor.Parent=plot.Model
    for i=2,p.HauntLevel do
        for _,s in {-1,1} do
            local offset=if plot.SpireOffset then plot.SpireOffset(s,i) else CFrame.new(s*(20+i),4+i,-10+i*5)
            local pillar=V.part(decor,'EstateSpire',Vector3.new(1.2,3+i,1.2),plot.CF*offset,V.color(i),Enum.Material.Neon)
            local l=Instance.new('PointLight'); l.Color=pillar.Color; l.Range=8; l.Brightness=0.3; l.Parent=pillar
        end
    end
end
local function stats(player)
    local p=Profiles.get(player)
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if not p or not hum then return end
    hum.WalkSpeed=if player:GetAttribute('Chamber') then 0 else 22+(p.Upgrades.Movement-1)*2
    for _,container in {char,player:FindFirstChildOfClass('Backpack')} do
        if container then
            local tool=container:FindFirstChild('Spectral Vacuum')
            if tool then
                local light=tool:FindFirstChild('Lamp',true)
                if light then light.Range=35+p.Upgrades.Flashlight*10; light.Brightness=2+p.Upgrades.Flashlight*0.5 end
            end
        end
    end
end
local function rootOf(player)
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    return if hum and hum.Health>0 then char:FindFirstChild('HumanoidRootPart') else nil
end
local function near(player,part)
    local root=rootOf(player)
    return root and (root.Position-part.Position).Magnitude<=15
end
local function home(player)
    local plot=plots[player] and World.Plots[plots[player]]
    if not plot or not rootOf(player) then return end
    Hunt.cancel(player,'')
    if player:GetAttribute('Chamber') then Chamber.leave(player) end
    player:SetAttribute('Floor',0)
    player.Character:PivotTo(plot.CF*CFrame.new(0,4,-22))
    stats(player); push(player)
end
local function atHome(player)
    local plot=plots[player] and World.Plots[plots[player]]
    local root=rootOf(player)
    return plot and root and not player:GetAttribute('Chamber') and (root.Position-plot.CF.Position).Magnitude<45
end
local function deposit(player)
    local p=Profiles.get(player)
    if not p or not atHome(player) then return end
    local n=#p.Bag; Rules.deposit(p)
    -- Fill free slots for a smooth first loop; players can replace any slot in the Haunt panel.
    local ids={}
    for id in p.Owned do table.insert(ids,id) end
    table.sort(ids,function(a,b) return C.Ghosts[a].Income>C.Ghosts[b].Income end)
    for _,id in ids do while Rules.place(p,id) do end end
    refreshPlot(player); push(player)
    notice(player,if n>0 then n..' ghosts deposited! Free slots filled. Your Haunt is earning dollars.' else 'Inventory ready. Manage your ghost slots in HAUNT.')
end
local function enterFloor(player,floor)
    local p=Profiles.get(player)
    if not p or type(floor)~='number' or floor~=math.floor(floor) or not World.Areas[floor] or floor>p.Floor or not rootOf(player) then return end
    Hunt.cancel(player,'')
    if player:GetAttribute('Chamber') then Chamber.leave(player) end
    player:SetAttribute('Floor',floor)
    player.Character:PivotTo(CFrame.new(World.Areas[floor].Entry))
    stats(player); push(player)
    notice(player,'Aim at a ghost and click repeatedly. Chase it when it pulls away!')
end
Hunt.start(World,Profiles,remote,push)
Chamber.start(World,Profiles,remote,push)
Profiles.start()
for i,plot in World.Plots do
    World.prompt(plot.Deposit,'Deposit ghosts','Your Haunt',function(player)
        if plot.Owner==player and near(player,plot.Deposit) then deposit(player) end
    end)
end
World.ChamberPortalPrompt.Triggered:Connect(function(player)
    if near(player,World.ChamberPortal) and (player:GetAttribute('Floor') or 0)==0 and not player:GetAttribute('Chamber') then Hunt.cancel(player,''); Chamber.enter(player,plots[player]); push(player) end
end)
for _,area in World.Areas do World.prompt(area.Exit,'Return home','Deposit captured ghosts',function(player) if near(player,area.Exit) then home(player) end end) end
World.prompt(World.MansionDoor,'Choose mansion area','Haunted Mansion',function(player) if near(player,World.MansionDoor) then remote:FireClient(player,'Open','Mansion') end end)
World.prompt(World.Upgrades,'Browse upgrades','Workshop',function(player) if near(player,World.Upgrades) then remote:FireClient(player,'Open','Upgrades') end end)
World.RebirthAltarPrompt.Triggered:Connect(function(player) if near(player,World.RebirthAltar) then remote:FireClient(player,'Open','Rebirth') end end)
remote.OnServerEvent:Connect(function(player,action,arg)
    if type(action)~='string' or #action>24 then return end
    if action=='Click' then Hunt.click(player,arg); return end
    local now=os.clock()
    if now-(lastRequest[player] or 0)<0.15 then return end
    lastRequest[player]=now
    local p=Profiles.get(player)
    if not p then return end
    if action=='Sync' then push(player)
    elseif action=='Home' then home(player)
    elseif action=='EnterFloor' then enterFloor(player,arg)
    elseif action=='Deposit' then deposit(player)
    elseif action=='Place' then
        if type(arg)=='string' and #arg<50 and atHome(player) and Rules.place(p,arg) then refreshPlot(player); push(player) else notice(player,'Return home, deposit your ghosts, and check for a free slot.') end
    elseif action=='Remove' then
        if atHome(player) and Rules.remove(p,arg) then refreshPlot(player); push(player) end
    elseif action=='Upgrade' then
        if type(arg)=='string' and #arg<30 and Rules.upgrade(p,arg) then stats(player); refreshPlot(player); push(player); notice(player,arg..' upgraded!') else notice(player,'Upgrade unavailable or not enough dollars.') end
    elseif action=='Unlock' then
        if Rules.unlock(p,arg) then push(player); notice(player,'New mansion area unlocked!') else notice(player,'Unlock areas in order and earn enough dollars.') end
    elseif action=='Rebirth' then
        if Rules.rebirth(p) then home(player); refreshPlot(player); stats(player); push(player); notice(player,'REBORN! Permanent income multiplier: '..Rules.multiplier(p)..'x') else notice(player,'Unlock all six areas and meet the dollar requirement first.') end
    elseif action=='Chamber' then
        if atHome(player) then Hunt.cancel(player,''); Chamber.enter(player,plots[player]); push(player) else notice(player,'Return to your Haunt to enter the chamber.') end
    elseif action=='ExitChamber' then home(player)
    elseif action=='Cancel' then Hunt.cancel(player,'Capture released.')
    elseif action=='Flashlight' then
        local tool=player.Character and player.Character:FindFirstChild('Spectral Vacuum')
        local light=tool and tool:FindFirstChild('Lamp',true)
        if light then light.Enabled=not light.Enabled end
    end
end)
local function characterAdded(player,char)
    char:WaitForChild('HumanoidRootPart',10)
    local humanoid=char:WaitForChild('Humanoid',10)
    if not humanoid or not Profiles.get(player) then return end
    if player:GetAttribute('Chamber') then Chamber.leave(player) end
    player:SetAttribute('Floor',0)
    local backpack=player:WaitForChild('Backpack')
    if not backpack:FindFirstChild('Spectral Vacuum') and not char:FindFirstChild('Spectral Vacuum') then
        local tool=V.vacuum(); tool.Parent=backpack; humanoid:EquipTool(tool)
        tool.Unequipped:Connect(function()
            task.defer(function()
                if tool.Parent==backpack and humanoid.Health>0 and player.Character==char then humanoid:EquipTool(tool) end
            end)
        end)
    end
    stats(player); push(player)
    humanoid.Died:Connect(function()
        Hunt.cancel(player,'')
        if player:GetAttribute('Chamber') then Chamber.leave(player) end
        player:SetAttribute('Floor',0)
    end)
end
local function joined(player)
    if closing then player:Kick('Server restarting. Please rejoin.'); return end
    local index
    for i,plot in World.Plots do if not plot.Owner then index=i; plot.Owner=player; plots[player]=i; break end end
    if not index then player:Kick('All seven Haunts are occupied. Please join another server.'); return end
    local data=Profiles.load(player)
    if not data or not player.Parent then
        if World.Plots[index].Owner==player then World.Plots[index].Owner=nil end
        local session=Profiles.Sessions[player]
        if session then session.Closing=true; Profiles.save(player,true); Profiles.Sessions[player]=nil end
        plots[player]=nil
        return
    end
    local leaderstats=Instance.new('Folder'); leaderstats.Name='leaderstats'; leaderstats.Parent=player
    for _,name in {'Dollars','Rebirths','Income'} do local v=Instance.new('NumberValue'); v.Name=name; v.Parent=leaderstats end
    refreshPlot(player)
    player.CharacterAdded:Connect(function(char) characterAdded(player,char) end)
    if player.Character then task.spawn(characterAdded,player,player.Character) end
    push(player)
end
Players.PlayerAdded:Connect(joined)
for _,player in Players:GetPlayers() do task.spawn(joined,player) end
Players.PlayerRemoving:Connect(function(player)
    Hunt.cancel(player,'')
    if Chamber.Sessions[player] then Chamber.leave(player) end
    local s=Profiles.Sessions[player]
    if s then s.Closing=true; Profiles.save(player,true); Profiles.Sessions[player]=nil end
    local plot=plots[player] and World.Plots[plots[player]]
    if plot then
        plot.Owner=nil; plot.Label.Text='UNCLAIMED HAUNT'
        for _,m in plot.Displays do m:Destroy() end
        table.clear(plot.Displays)
    end
    plots[player]=nil; lastRequest[player]=nil
end)
task.spawn(function()
    while task.wait(1) do
        local ranking={}
        for _,player in Players:GetPlayers() do
            local p=Profiles.get(player)
            if not p then continue end
            p.Money=math.min(1e15,p.Money+Rules.income(p))
            local ls=player:FindFirstChild('leaderstats')
            if ls then ls.Dollars.Value=math.floor(p.Money); ls.Income.Value=Rules.income(p); ls.Rebirths.Value=p.Rebirths end
            local ownedPlot=plots[player] and World.Plots[plots[player]]
            if ownedPlot then ownedPlot.IncomeLabel.Text='$'..Rules.income(p)..' / sec' end
            local root=rootOf(player)
            local floor=player:GetAttribute('Floor') or 0
            if root and not player:GetAttribute('Chamber') then
                if floor>0 and World.Areas[floor] then
                    local rel=root.Position-World.Areas[floor].Center
                    if math.abs(rel.X)>58 or math.abs(rel.Z)>48 or rel.Y< -10 then enterFloor(player,floor) end
                elseif root.Position.Y< -15 or root.Position.Z< -245 or math.abs(root.Position.X)>215 then home(player) end
            end
            push(player)
            table.insert(ranking,{Name=player.DisplayName,Income=Rules.income(p)})
        end
        table.sort(ranking,function(a,b) return a.Income>b.Income end)
        local lines={'HOLLOW HUNTERS • THIS SERVER'}
        for i=1,math.min(8,#ranking) do table.insert(lines,i..'. '..ranking[i].Name..' • $'..ranking[i].Income..'/sec') end
        World.Leaderboard.Label.TextLabel.Text=table.concat(lines,'\n')
    end
end)
game:BindToClose(function()
    closing=true
    local remaining=0
    for player,s in Profiles.Sessions do
        s.Closing=true; remaining+=1
        task.spawn(function() Profiles.save(player,true); remaining-=1 end)
    end
    local deadline=os.clock()+25
    while remaining>0 and os.clock()<deadline do task.wait(0.1) end
end)
print('Ghostlight Hollow server ready: seven Haunts, six mansion areas, fifteen ghosts.')

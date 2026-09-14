local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local UserInputService=game:GetService('UserInputService')
local SoundService=game:GetService('SoundService')
local StarterGui=game:GetService('StarterGui')
local TweenService=game:GetService('TweenService')
local GuiService=game:GetService('GuiService')
local Theme=require(script.Parent.UITheme)
local HUD=require(script.Parent.HUD)
local Shared=ReplicatedStorage:WaitForChild('Ghostlight')
local C=require(Shared.Config)
local Rules=require(Shared.Rules)
local V=require(Shared.Visuals)
local Encounter=require(script.Parent.Encounter)
local Battle=require(script.Parent.Battle)
local remote=Shared:WaitForChild('Action')
local player=Players.LocalPlayer
local mouse=player:GetMouse()
local gui=Instance.new('ScreenGui'); gui.Name='GhostlightHUD'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild('PlayerGui')
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
local ink=Theme.Colors.Ink
local purple=Theme.Colors.Purple
local mint=Theme.Colors.Mint
local amber=Theme.Colors.Orange
local state,currentPanel,lastSignature
local targetId=nil
local beams={}
local chamberCenter=nil
local zoom=70
local toastId=0
local make,frame,label,button=Theme.make,Theme.frame,Theme.label,Theme.button
local function money(n)
    if n>=1e9 then return string.format('$%.2fB',n/1e9) end
    if n>=1e6 then return string.format('$%.2fM',n/1e6) end
    if n>=1e3 then return string.format('$%.1fK',n/1e3) end
    return '$'..math.floor(n)
end
local function send(action,arg) remote:FireServer(action,arg) end
local function sound(asset,volume,pitch,looped)
    local s=Instance.new('Sound'); s.SoundId=asset; s.Volume=volume or 0.25; s.PlaybackSpeed=pitch or 1; s.Looped=looped or false; s.Parent=SoundService
    s:Play()
    if not looped then game:GetService('Debris'):AddItem(s,4) end
    return s
end
local suction=sound('rbxasset://sounds/action_swim.mp3',0.08,0.65,true); suction:Stop()
local render,click,ui
local function closePanel()
    currentPanel=nil; ui:setPanel(nil); ui.Actions.Visible=chamberCenter==nil
end
ui=HUD.new(gui,{Navigate=function(name) if currentPanel==name then closePanel() else render(name) end end,
    Close=closePanel,Light=function() if not currentPanel and not chamberCenter then send('Flashlight') end end,
    Vacuum=function() if click then click() end end})
local cash,income,rebirths=ui.Cash,ui.Income,ui.Rebirths
local toast,toastText=ui.Toast,ui.ToastText
local function notify(text,color)
    toastId+=1; local id=toastId
    toast.Visible=true; toastText.Text=text; toastText.TextColor3=color or amber
    task.delay(3.8,function() if id==toastId then toast.Visible=false end end)
end
local list,actions=ui.List,ui.Actions
local captureBox,captureText,bar=ui.Capture,ui.CaptureText,ui.CaptureBar
local function clearList(grid)
    for _,child in list:GetChildren() do if not child:IsA('UIPadding') then child:Destroy() end end
    if grid then
        make('UIGridLayout',list,{CellPadding=UDim2.fromOffset(12,12),CellSize=UDim2.new(1/3,-14,0,202),SortOrder=Enum.SortOrder.LayoutOrder})
        ui:resize()
    else make('UIListLayout',list,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder}) end
end
local function row(text,caption,callback,color,height,ghostId)
    local f=frame(list,UDim2.new(1,-8,0,height or 100),UDim2.new(),Color3.fromRGB(57,31,80))
    f.LayoutOrder=#list:GetChildren(); f.Name='Row'
    Theme.stroke(f,purple,1).Transparency=0.6
    local offset=12
    if ghostId then
        local vp=make('ViewportFrame',f,{Size=UDim2.fromOffset(62,70),Position=UDim2.fromOffset(3,7),BackgroundTransparency=1,Ambient=Color3.fromRGB(200,200,220),LightColor=Color3.new(1,1,1)})
        local wm=Instance.new('WorldModel'); wm.Parent=vp
        local preview=V.ghost(ghostId,wm,CFrame.new(),0.9,false)
        local bounds,size=preview:GetBoundingBox()
        local distance=math.max(size.Y,size.X/(62/70))*.56/math.tan(math.rad(24))+size.Z*.5
        local cam=Instance.new('Camera'); cam.CFrame=CFrame.lookAt(bounds.Position+Vector3.new(0,0,-distance),bounds.Position)
        cam.FieldOfView=48; cam.Parent=vp; vp.CurrentCamera=cam
        vp.Ambient=Color3.fromRGB(110,115,140); vp.LightDirection=Vector3.new(-1,-1,2)
        offset=70
    end
    f.AutomaticSize=Enum.AutomaticSize.Y
    local copy=label(f,text,UDim2.new(1,-offset-(caption and 116 or 12),0,0),UDim2.fromOffset(offset,14),18,color or ink)
    copy.Name='Copy'; copy.AutomaticSize=Enum.AutomaticSize.Y
    make('UIPadding',f,{PaddingBottom=UDim.new(0,14)})
    if caption then
        local b=button(f,caption,UDim2.fromOffset(102,52),UDim2.new(1,-112,0.5,-26),callback,amber)
        b.TextSize=16
        if caption=='LOCKED' or caption=='MAX' then b.Interactable=false; b.BackgroundColor3=Color3.fromRGB(83,64,99); b.TextColor3=Theme.Colors.Muted end
    end
    return f
end
local function sortedGhosts()
    local ids={}
    for id in C.Ghosts do table.insert(ids,id) end
    table.sort(ids,function(a,b) return C.Ghosts[a].Income<C.Ghosts[b].Income end)
    return ids
end
local benefits={Suction='Stronger pull during capture',Capture='More progress per click',Capacity='Carry more ghosts per trip',Movement='Run faster while exploring',Flashlight='Brighter, longer light beam',Haunt='More display slots and estate decorations'}
local subtitles={Haunt='A happy home for your haunted collection',Collection='Meet every ghost in Ghostlight Hollow',
    Mansion='Choose your next spooky adventure',Upgrades='A little more power. A lot more ghost hunting.',Rebirth='Start again with a bigger income bonus'}
local function ghostCard(id,p)
    local g=C.Ghosts[id]
    local found=p.Discovered[id]
    local color=if found then V.color(g.Rarity) else Theme.Colors.Muted
    local card=frame(list,UDim2.new(),UDim2.new(),Color3.fromRGB(55,29,77))
    card.Name='GhostCard_'..id; card.LayoutOrder=#list:GetChildren()
    Theme.stroke(card,color,2).Transparency=if found then 0.2 else 0.7
    local rarity=label(card,C.Rarities[g.Rarity],UDim2.new(1,-16,0,23),UDim2.fromOffset(8,7),15,color)
    rarity.TextXAlignment=Enum.TextXAlignment.Center
    local titleLabel=label(card,if found then g.Name else 'Undiscovered',UDim2.new(1,-16,0,38),UDim2.fromOffset(8,123),18,if found then ink else color)
    titleLabel.TextXAlignment=Enum.TextXAlignment.Center
    local desc=Theme.body(card,if found then money(g.Income)..' / sec  •  Owned '..(p.Owned[id] or 0) else 'Explore deeper areas',UDim2.new(1,-16,0,31),UDim2.fromOffset(8,162),13,color)
    desc.TextXAlignment=Enum.TextXAlignment.Center
    if found then
        local vp=make('ViewportFrame',card,{Name='GhostPortrait',Size=UDim2.new(1,-28,0,90),Position=UDim2.fromOffset(14,31),BackgroundTransparency=1,
            Ambient=Color3.fromRGB(160,153,183),LightColor=Color3.fromRGB(255,248,223),LightDirection=Vector3.new(-1,-1,2)})
        -- Asset loading must not block subsequent state updates or redraws.
        task.spawn(function()
            local wm=Instance.new('WorldModel'); wm.Parent=vp
            local ghost=V.ghost(id,wm,CFrame.new(),0.9,false)
            if not card.Parent then wm:Destroy(); return end
            local bounds,size=ghost:GetBoundingBox()
            local camera=Instance.new('Camera'); camera.FieldOfView=42
            local distance=math.max(size.Y,size.X)*0.65/math.tan(math.rad(21))+size.Z*.5
            camera.CFrame=CFrame.lookAt(bounds.Position+Vector3.new(0,0,-distance),bounds.Position)
            camera.Parent=vp; vp.CurrentCamera=camera
        end)
    else
        local mystery=label(card,'?',UDim2.new(1,-20,0,84),UDim2.fromOffset(10,35),64,purple)
        mystery.TextXAlignment=Enum.TextXAlignment.Center
    end
end
render=function(name)
    if not state or Battle.isActive() or Encounter.isPlaying() then return end
    local previous=currentPanel
    local scroll=if previous==name then list.CanvasPosition else Vector2.zero
    currentPanel=name; ui:setPanel(name,subtitles[name]); actions.Visible=false; captureBox.Visible=false; clearList(name=='Collection')
    local p=state.Profile
    if name=='Haunt' then
        row('YOUR HAUNT • '..#p.Placed..'/'..C.Slots[p.HauntLevel]..' slots\n'..money(state.Income)..'/sec','GO HOME',function() send('Home') end,mint)
        row('Vacuum contains '..#p.Bag..' ghosts. Deposit at home to fill free slots.','DEPOSIT',function() send('Deposit') end)
        row('Watch your placed ghosts hunt and find new discoveries.','CHAMBER',function() closePanel(); send('Chamber') end,purple)
        for i,id in p.Placed do
            row('Slot '..i..' • '..C.Ghosts[id].Name..'\n'..money(C.Ghosts[id].Income*Rules.multiplier(p))..'/sec','REMOVE',function() send('Remove',i) end,V.color(C.Ghosts[id].Rarity),86,id)
        end
        for _,id in sortedGhosts() do
            if Rules.available(p,id)>0 then row(C.Ghosts[id].Name..'\nAvailable: '..Rules.available(p,id),'PLACE',function() send('Place',id) end,V.color(C.Ghosts[id].Rarity),86,id) end
        end
    elseif name=='Collection' then
        for _,id in sortedGhosts() do
            ghostCard(id,p)
        end
    elseif name=='Mansion' then
        for i,f in C.Floors do
            local open=i<=p.Floor
            row(i..' • '..f.Name..'\n'..(if open then 'Unlocked • '..C.Rarities[f.Min]..' to '..C.Rarities[f.Max] else 'Unlock: '..money(f.Cost)),if open then 'ENTER' elseif i==p.Floor+1 then 'UNLOCK' else 'LOCKED',function()
                if open then closePanel(); send('EnterFloor',i)
                elseif i==p.Floor+1 then send('Unlock',i)
                else notify('Unlock the previous area first.') end
            end,if open then mint else ink)
        end
    elseif name=='Upgrades' then
        local names=table.clone(C.UpgradeNames); table.insert(names,'Haunt')
        for _,key in names do
            local level=if key=='Haunt' then p.HauntLevel else p.Upgrades[key]
            local cost=Rules.upgradeCost(p,key)
            row(key..' • Level '..level..'\n'..benefits[key],if cost then money(cost) else 'MAX',function() if cost then send('Upgrade',key) end end,ink,94)
        end
    elseif name=='Rebirth' then
        row('REBIRTH '..(p.Rebirths+1)..'\nIncome bonus: '..Rules.multiplier(p)..'x → '..(Rules.multiplier(p)+0.5)..'x',nil,nil,purple,90)
        row('Requires all 6 mansion areas and '..money(Rules.rebirthCost(p))..'.\nMoney, upgrades, area access and placed slots reset.',nil,nil,ink,105)
        row('You keep every owned ghost and discovery. Place your best ghosts again after rebirth.',nil,nil,mint,95)
        row('Ready to reset your progression?','REBIRTH',function()
            clearList()
            row('Confirm rebirth? Your money and temporary upgrades will reset. Your collection stays.','CONFIRM',function() send('Rebirth') end,amber,120)
            row('Keep playing without rebirthing.','BACK',function() render('Rebirth') end)
        end)
    end
    list.CanvasPosition=scroll
end
local function wildGhost(id)
    local world=workspace:FindFirstChild('GhostlightWorld')
    local folder=world and world:FindFirstChild('WildGhosts')
    return folder and folder:FindFirstChild('Ghost_'..id)
end
local function aimedGhost()
    local part=mouse.Target
    local model=part and part:FindFirstAncestorOfClass('Model')
    if model and model:GetAttribute('GhostId') then return model:GetAttribute('GhostId') end
    -- Touch/gamepad button targets the closest ghost to the screen center in range.
    local world=workspace:FindFirstChild('GhostlightWorld')
    local folder=world and world:FindFirstChild('WildGhosts')
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if not folder or not root then return nil end
    local camera=workspace.CurrentCamera
    local best,bestScore=nil,180
    for _,g in folder:GetChildren() do
        if (g:GetPivot().Position-root.Position).Magnitude<28 then
            local point,onScreen=camera:WorldToViewportPoint(g:GetPivot().Position)
            local score=(Vector2.new(point.X,point.Y)-camera.ViewportSize/2).Magnitude
            if onScreen and score<bestScore then best=g:GetAttribute('GhostId'); bestScore=score end
        end
    end
    return best
end
require(Shared.LabelVisibility).start(player,function()
    if currentPanel or Battle.isActive() or Encounter.isPlaying() then return nil end
    local id=targetId or aimedGhost()
    return id and wildGhost(id) or nil
end)
local vacuumButton=ui.Vacuum
click=function()
    if currentPanel or chamberCenter or Encounter.isPlaying() or Battle.isActive() then return end
    local id=targetId or aimedGhost()
    if id then
        send('Click',id)
        local scale=vacuumButton:FindFirstChildOfClass('UIScale')
        scale.Scale=0.95
        TweenService:Create(scale,TweenInfo.new(0.11,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    end
end
local chamberBar=Theme.plate(ui.Root,'Chamber',UDim2.new(1,-24,0,65),UDim2.new(0,12,1,-140)); chamberBar.Visible=false
local chamberText=label(chamberBar,'HAUNTING IN PROGRESS',UDim2.new(1,-240,1,0),UDim2.fromOffset(10,0),15,mint)
button(chamberBar,'−',UDim2.fromOffset(42,43),UDim2.new(1,-227,0,11),function() zoom=math.min(110,zoom+10) end)
button(chamberBar,'+',UDim2.fromOffset(42,43),UDim2.new(1,-178,0,11),function() zoom=math.max(40,zoom-10) end)
button(chamberBar,'EXIT',UDim2.fromOffset(116,43),UDim2.new(1,-126,0,11),function() send('ExitChamber') end,amber)
local function beamOff(userId)
    local data=beams[userId]
    if data then for _,obj in data.Objects do obj:Destroy() end; beams[userId]=nil end
    if userId==player.UserId then suction:Stop() end
end
local function beamOn(data)
    beamOff(data.UserId)
    local hunter=Players:GetPlayerByUserId(data.UserId)
    local tool=hunter and hunter.Character and hunter.Character:FindFirstChild('Spectral Vacuum')
    local nozzle=tool and tool:FindFirstChild('Nozzle')
    local g=wildGhost(data.Id)
    if not nozzle or not g or not g.PrimaryPart then return end
    local a=Instance.new('Attachment'); a.Parent=g.PrimaryPart
    local beam=Instance.new('Beam'); beam.Attachment0=nozzle.Suction; beam.Attachment1=a; beam.Color=ColorSequence.new(mint); beam.Width0=0.3; beam.Width1=2; beam.FaceCamera=true; beam.LightEmission=1; beam.Transparency=NumberSequence.new(0.25); beam.Parent=nozzle
    local particles=Instance.new('ParticleEmitter'); particles.Color=ColorSequence.new(mint); particles.Rate=35; particles.Lifetime=NumberRange.new(0.25,0.6); particles.Speed=NumberRange.new(4,9); particles.Size=NumberSequence.new(0.12); particles.LightEmission=1; particles.SpreadAngle=Vector2.new(20,20); particles.Parent=nozzle.Suction
    beams[data.UserId]={Objects={beam,a,particles},Ghost=g,Nozzle=nozzle}
    if data.UserId==player.UserId then targetId=data.Id; suction:Play() end
end
local function captureEnd()
    Encounter.cancel()
    Battle.close()
    targetId=nil; captureBox.Visible=false; suction:Stop()
end
local function finale(data)
    local g=wildGhost(data.Id)
    local hunter=Players:GetPlayerByUserId(data.UserId)
    local tool=hunter and hunter.Character and hunter.Character:FindFirstChild('Spectral Vacuum')
    local nozzle=tool and tool:FindFirstChild('Nozzle')
    beamOff(data.UserId)
    if g and nozzle then
        local clone=g:Clone(); clone.Name='CaptureVisual'; clone.Parent=workspace
        for _,v in g:GetDescendants() do if v:IsA('BasePart') then v.LocalTransparencyModifier=1 elseif v:IsA('BillboardGui') then v.Enabled=false end end
        for _,v in clone:GetDescendants() do if v:IsA('BillboardGui') then v:Destroy() end end
        local start=clone:GetPivot()
        task.spawn(function()
            local began=os.clock()
            while os.clock()-began<0.65 and nozzle.Parent do
                local t=(os.clock()-began)/0.65
                clone:ScaleTo(math.max(0.04,1-t*0.96))
                clone:PivotTo(start:Lerp(nozzle.CFrame,t*t)*CFrame.Angles(0,0,math.sin(t*30)*(1-t)*0.3))
                RunService.RenderStepped:Wait()
            end
            clone:Destroy()
        end)
    end
    if data.UserId==player.UserId then
        if Battle.isActive() then
            Battle.finish(data); targetId=nil; captureBox.Visible=false; suction:Stop()
        else captureEnd() end
        local gdata=C.Ghosts[data.Species]
        sound('rbxasset://sounds/volume_slider.ogg',0.35,if gdata.Rarity>=5 then 0.75 else 1.1)
        notify(string.upper(C.Rarities[gdata.Rarity])..' GHOST CAPTURED!\n'..gdata.Name,V.color(gdata.Rarity))
    end
end
local function restoreCamera()
    local camera=workspace.CurrentCamera
    local character=player.Character
    local hum=character and character:FindFirstChildOfClass('Humanoid')
    local root=character and character:FindFirstChild('HumanoidRootPart')
    player.CameraMinZoomDistance=0.5; player.CameraMaxZoomDistance=22
    camera.CameraType=Enum.CameraType.Custom
    if hum then camera.CameraSubject=hum end
    if root then camera.CFrame=CFrame.lookAt((root.CFrame*CFrame.new(0,6,13)).Position,root.Position+Vector3.new(0,2,0)) end
end
local function updateQuest()
    if not state then return end
    local p=state.Profile
    local floor=player:GetAttribute('Floor') or 0
    if chamberCenter then ui:setQuest('Your Haunt at work','Your ghosts are searching for discoveries.',1,#p.Placed..' hunters')
    elseif #p.Bag>=Rules.capacity(p) then ui:setQuest('Vacuum full!','Return to your Haunt to deposit your ghosts.',1,'Time to head home')
    elseif #p.Placed==0 and #p.Bag>0 then ui:setQuest('Make yourself at home','Deposit your ghost at your Haunt to earn cash.',0,'0 / 1 deposited')
    elseif floor>0 then ui:setQuest('Happy haunting!','Touch a ghost or click one to start an encounter.',#p.Bag/Rules.capacity(p),#p.Bag..' / '..Rules.capacity(p)..' in vacuum')
    elseif state.Income==0 then ui:setQuest('First Haunt','Enter the mansion and catch your first ghost.',0,'0 / 1')
    elseif p.Floor<6 then
        local nextArea=C.Floors[p.Floor+1]
        ui:setQuest('A new door awaits',nextArea.Name..' • '..money(nextArea.Cost),p.Money/nextArea.Cost,if p.Money>=nextArea.Cost then 'Ready to unlock!' else 'Saving for the next area')
    else ui:setQuest('Keep the magic growing','Explore the Catacombs or prepare for rebirth.',p.Money/Rules.rebirthCost(p),'All 6 areas unlocked') end
end
player:GetAttributeChangedSignal('Floor'):Connect(updateQuest)
remote.OnClientEvent:Connect(function(event,data)
    if event=='State' then
        state=data
        local p=state.Profile
        cash.Text=money(p.Money); income.Text='+'..money(state.Income)..' / sec'
        ui.Bonus.Text=Rules.multiplier(p)..'x BONUS'
        ui:setCapacity(#p.Bag,Rules.capacity(p)); rebirths.Text='REBIRTHS '..p.Rebirths
        ui.Practice.Text=if data.Practice then 'Practice mode' else ''
        updateQuest()
        if chamberCenter then chamberText.Text=#p.Placed..' HUNTERS\nDiscoveries: '..p.ChamberDiscoveries end
        local signature=p.HauntLevel..':'..p.Floor..':'..p.Rebirths..':'..#p.Bag..':'..table.concat(p.Placed,',')
        for _,name in C.UpgradeNames do signature..=':'..p.Upgrades[name] end
        for _,id in sortedGhosts() do signature..=':'..(p.Owned[id] or 0)..':'..tostring(p.Discovered[id]) end
        if currentPanel and signature~=lastSignature then render(currentPanel) end
        lastSignature=signature
    elseif event=='Notice' then notify(data)
    elseif event=='Open' then render(data)
    elseif event=='BeamOn' then beamOn(data)
    elseif event=='BeamOff' then beamOff(data.UserId)
    elseif event=='CaptureProgress' then
        if Battle.isActive() then Battle.progress(data); return end
        captureBox.Visible=not currentPanel; bar.Size=UDim2.fromScale(data.Progress,1)
        local g=wildGhost(targetId)
        if g and g.PrimaryPart then
            g:ScaleTo(math.max(0.35,1-data.Progress*0.35))
            local glow=g.PrimaryPart:FindFirstChildOfClass('PointLight')
            if glow then glow.Brightness=0.65+data.Progress*1.8 end
        end
        captureText.Text=C.Ghosts[data.Species].Name..' • '..math.floor(data.Progress*100)..'%\n'..(if data.Surge then 'PULLING AWAY! CHASE IT!' else 'KEEP CLICKING!')
        bar.BackgroundColor3=if data.Surge then amber else mint
    elseif event=='EncounterStart' then
        captureEnd(); closePanel(); toast.Visible=false
        targetId=data.Id
        Encounter.play(player,gui,data)
    elseif event=='BattleStart' then
        Encounter.cancel()
        targetId=data.Id; captureBox.Visible=false
        Battle.open(player,gui,data,remote)
    elseif event=='WeakSpot' then Battle.weakSpot(data)
    elseif event=='WeakSpotResult' then Battle.weakSpotResult(data)
    elseif event=='CaptureEnd' then captureEnd(); if data and data~='' then notify(data) end
    elseif event=='GhostAttack' then
        notify('THE '..string.upper(C.Ghosts[data.Species].Name)..' STRIKES!\nKeep moving while you vacuum.',Color3.fromRGB(255,117,135))
        captureText.Text='DANGER! MOVE TO AVOID THE ATTACK'
        if vacuumButton then
            vacuumButton.BackgroundColor3=Color3.fromRGB(255,117,135)
            task.delay(0.3,function() if vacuumButton then vacuumButton.BackgroundColor3=mint end end)
        end
    elseif event=='Captured' then finale(data)
    elseif event=='ChamberEnter' then
        chamberCenter=data.Center; chamberBar.Visible=true; closePanel(); captureEnd(); updateQuest()
        workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
    elseif event=='ChamberExit' then
        chamberCenter=nil; chamberBar.Visible=false; actions.Visible=true
        updateQuest()
        restoreCamera()
    elseif event=='ChamberFound' then
        local g=C.Ghosts[data.Species]
        notify('YOUR GHOSTS FOUND '..string.upper(C.Rarities[g.Rarity])..'!\n'..g.Name,V.color(g.Rarity))
        sound('rbxasset://sounds/volume_slider.ogg',0.25,0.9)
    end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if Battle.isActive() or Encounter.isPlaying() then return end
    if input.KeyCode==Enum.KeyCode.ButtonB and currentPanel then closePanel(); return end
    if processed then return end
    if input.KeyCode==Enum.KeyCode.ButtonY then
        if currentPanel then closePanel() else render('Collection') end
        return
    end
    if currentPanel or chamberCenter then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then click()
    elseif input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonX then send('Flashlight')
    elseif input.KeyCode==Enum.KeyCode.Q then send('Cancel') end
end)
GuiService.MenuOpened:Connect(function() if currentPanel then closePanel() end end)
RunService.RenderStepped:Connect(function()
    if chamberCenter then workspace.CurrentCamera.CFrame=CFrame.lookAt(chamberCenter+Vector3.new(0,zoom,zoom*0.6),chamberCenter) end
    for userId,b in beams do if not b.Ghost.Parent or not b.Nozzle.Parent then beamOff(userId) end end
end)
player.CharacterAdded:Connect(function(character)
    captureEnd(); closePanel()
    character:WaitForChild('HumanoidRootPart',10)
    if chamberCenter then send('ExitChamber') else restoreCamera() end
end)
if player.Character then
    task.spawn(function() player.Character:WaitForChild('HumanoidRootPart',10); if not chamberCenter then restoreCamera() end end)
end
task.spawn(function()
    while not state do send('Sync'); task.wait(2) end
end)

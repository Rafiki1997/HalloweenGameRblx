local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local UserInputService=game:GetService('UserInputService')
local SoundService=game:GetService('SoundService')
local StarterGui=game:GetService('StarterGui')
local TweenService=game:GetService('TweenService')
local Shared=ReplicatedStorage:WaitForChild('Ghostlight')
local C=require(Shared.Config)
local Rules=require(Shared.Rules)
local V=require(Shared.Visuals)
local remote=Shared:WaitForChild('Action')
local player=Players.LocalPlayer
local mouse=player:GetMouse()
local gui=Instance.new('ScreenGui'); gui.Name='GhostlightHUD'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild('PlayerGui')
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
local bg=Color3.fromRGB(23,17,36)
local ink=Color3.fromRGB(241,232,255)
local purple=Color3.fromRGB(174,119,255)
local mint=Color3.fromRGB(131,255,225)
local amber=Color3.fromRGB(255,197,111)
local state,currentPanel,lastSignature
local targetId=nil
local beams={}
local chamberCenter=nil
local zoom=70
local toastId=0
local function make(class,parent,props)
    local obj=Instance.new(class)
    for k,v in props do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function corner(obj,radius) make('UICorner',obj,{CornerRadius=UDim.new(0,radius or 9)}) end
local function frame(parent,size,pos,color)
    local obj=make('Frame',parent,{Size=size,Position=pos,BackgroundColor3=color or bg,BorderSizePixel=0})
    corner(obj)
    return obj
end
local function label(parent,text,size,pos,fontSize,color)
    return make('TextLabel',parent,{Size=size,Position=pos,BackgroundTransparency=1,Text=text,TextColor3=color or ink,Font=Enum.Font.GothamMedium,TextSize=fontSize or 17,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true})
end
local function button(parent,text,size,pos,callback,color)
    local b=make('TextButton',parent,{Size=size,Position=pos,Text=text,TextColor3=bg,BackgroundColor3=color or purple,Font=Enum.Font.GothamBold,TextSize=16,TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true})
    corner(b)
    b.Activated:Connect(callback)
    return b
end
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
local top=frame(gui,UDim2.fromOffset(176,145),UDim2.fromOffset(12,116))
local cash=label(top,'GHOSTLIGHT HOLLOW',UDim2.new(1,-16,0,35),UDim2.fromOffset(10,8),18,amber)
local income=label(top,'Loading your Haunt…',UDim2.new(1,-16,0,36),UDim2.fromOffset(10,47),16,mint)
local capacity=label(top,'VACUUM 0/3',UDim2.new(1,-16,0,25),UDim2.fromOffset(10,88),14,ink)
local rebirths=label(top,'REBIRTHS 0',UDim2.new(1,-16,0,25),UDim2.fromOffset(10,115),14,purple)
local objective=label(gui,'Loading…',UDim2.new(1,-32,0,42),UDim2.fromOffset(16,89),15,ink)
objective.TextStrokeTransparency=0.45
local toast=frame(gui,UDim2.new(1,-32,0,72),UDim2.new(0,16,0.5,-36)); toast.Visible=false; toast.ZIndex=8
local toastText=label(toast,'',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),19,amber); toastText.TextXAlignment=Enum.TextXAlignment.Center; toastText.ZIndex=9
local function notify(text,color)
    toastId+=1; local id=toastId
    toast.Visible=true; toastText.Text=text; toastText.TextColor3=color or amber
    task.delay(3.8,function() if id==toastId then toast.Visible=false end end)
end
local nav=make('ScrollingFrame',gui,{Size=UDim2.fromOffset(176,310),Position=UDim2.fromOffset(12,270),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=2})
make('UIListLayout',nav,{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
local panel=frame(gui,UDim2.fromOffset(650,460),UDim2.fromScale(0.5,0.52)); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Visible=false
panel.ZIndex=5
make('UIStroke',panel,{Color=purple,Thickness=1,Transparency=0.45})
local title=label(panel,'',UDim2.new(1,-76,0,46),UDim2.fromOffset(16,2),21,purple)
button(panel,'×',UDim2.fromOffset(42,38),UDim2.new(1,-50,0,7),function() panel.Visible=false; currentPanel=nil; actions.Visible=true end)
local list=make('ScrollingFrame',panel,{Size=UDim2.new(1,-20,1,-64),Position=UDim2.fromOffset(10,54),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=purple})
local function clearList()
    for _,child in list:GetChildren() do child:Destroy() end
    make('UIListLayout',list,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
end
local function row(text,caption,callback,color,height,ghostId)
    local f=frame(list,UDim2.new(1,-8,0,height or 86),UDim2.new(),Color3.fromRGB(40,29,57))
    local offset=12
    if ghostId then
        local vp=make('ViewportFrame',f,{Size=UDim2.fromOffset(62,70),Position=UDim2.fromOffset(3,7),BackgroundTransparency=1,Ambient=Color3.fromRGB(200,200,220),LightColor=Color3.new(1,1,1)})
        local wm=Instance.new('WorldModel'); wm.Parent=vp
        V.ghost(ghostId,wm,CFrame.new(),0.9,false)
        local cam=Instance.new('Camera'); cam.CFrame=CFrame.lookAt(Vector3.new(0,1,-9),Vector3.new(0,0,0)); cam.FieldOfView=48; cam.Parent=vp; vp.CurrentCamera=cam
        offset=70
    end
    label(f,text,UDim2.new(1,-offset-(caption and 105 or 12),1,-12),UDim2.fromOffset(offset,6),15,color or ink)
    if caption then button(f,caption,UDim2.fromOffset(96,54),UDim2.new(1,-103,0.5,-27),callback,amber) end
    return f
end
local function sortedGhosts()
    local ids={}
    for id in C.Ghosts do table.insert(ids,id) end
    table.sort(ids,function(a,b) return C.Ghosts[a].Income<C.Ghosts[b].Income end)
    return ids
end
local benefits={Suction='Stronger pull during capture',Capture='More progress per click',Capacity='Carry more ghosts per trip',Movement='Run faster while exploring',Flashlight='Brighter, longer light beam',Haunt='More display slots and estate decorations'}
local function render(name)
    if not state then return end
    currentPanel=name; panel.Visible=true; actions.Visible=false; captureBox.Visible=false; title.Text=string.upper(name); clearList()
    local p=state.Profile
    if name=='Haunt' then
        row('YOUR HAUNT • '..#p.Placed..'/'..C.Slots[p.HauntLevel]..' slots\n'..money(state.Income)..'/sec','GO HOME',function() send('Home') end,mint)
        row('Vacuum contains '..#p.Bag..' ghosts. Deposit at home to fill free slots.','DEPOSIT',function() send('Deposit') end)
        row('Watch your placed ghosts hunt and find new discoveries.','CHAMBER',function() panel.Visible=false; currentPanel=nil; send('Chamber') end,purple)
        for i,id in p.Placed do
            row('Slot '..i..' • '..C.Ghosts[id].Name..'\n'..money(C.Ghosts[id].Income*Rules.multiplier(p))..'/sec','REMOVE',function() send('Remove',i) end,V.color(C.Ghosts[id].Rarity),86,id)
        end
        for _,id in sortedGhosts() do
            if Rules.available(p,id)>0 then row(C.Ghosts[id].Name..'\nAvailable: '..Rules.available(p,id),'PLACE',function() send('Place',id) end,V.color(C.Ghosts[id].Rarity),86,id) end
        end
    elseif name=='Collection' then
        for _,id in sortedGhosts() do
            local g=C.Ghosts[id]
            local found=p.Discovered[id]
            row(if found then g.Name..' • '..C.Rarities[g.Rarity]..'\n'..money(g.Income)..'/sec • Owned '..(p.Owned[id] or 0) else 'UNDISCOVERED\n'..C.Rarities[g.Rarity]..' • Explore deeper areas',nil,nil,if found then V.color(g.Rarity) else Color3.fromRGB(144,133,163),86,if found then id else nil)
        end
    elseif name=='Mansion' then
        for i,f in C.Floors do
            local open=i<=p.Floor
            row(i..' • '..f.Name..'\n'..(if open then 'Unlocked • '..C.Rarities[f.Min]..' to '..C.Rarities[f.Max] else 'Unlock: '..money(f.Cost)),if open then 'ENTER' elseif i==p.Floor+1 then 'UNLOCK' else 'LOCKED',function()
                if open then panel.Visible=false; currentPanel=nil; send('EnterFloor',i)
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
end
for _,name in {'Haunt','Collection','Mansion','Upgrades','Rebirth'} do button(nav,string.upper(name),UDim2.new(1,-8,0,46),UDim2.new(),function() render(name) end) end
local captureBox=frame(gui,UDim2.new(0.65,0,0,76),UDim2.new(0.5,0,1,-151)); captureBox.AnchorPoint=Vector2.new(0.5,0); captureBox.Visible=false
local captureText=label(captureBox,'',UDim2.new(1,-16,0,37),UDim2.fromOffset(8,2),15,mint); captureText.TextXAlignment=Enum.TextXAlignment.Center
local track=frame(captureBox,UDim2.new(1,-20,0,18),UDim2.fromOffset(10,45),Color3.fromRGB(66,49,83))
local bar=frame(track,UDim2.fromScale(0,1),UDim2.new(),mint)
local actions=frame(gui,UDim2.fromOffset(104,122),UDim2.new(1,-116,1,-200)); actions.BackgroundTransparency=1
button(actions,'LIGHT [F]',UDim2.fromOffset(104,42),UDim2.new(),function() send('Flashlight') end,amber)
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
local vacuumButton
local function click()
    if currentPanel or chamberCenter then return end
    local id=targetId or aimedGhost()
    if id then
        send('Click',id)
        if vacuumButton then
            vacuumButton.Size=UDim2.fromOffset(96,64)
            TweenService:Create(vacuumButton,TweenInfo.new(0.11,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(104,70)}):Play()
        end
    end
end
vacuumButton=button(actions,'TAP TO\nVACUUM',UDim2.fromOffset(104,70),UDim2.fromOffset(0,49),click,mint)
local chamberBar=frame(gui,UDim2.new(1,-24,0,65),UDim2.new(0,12,1,-140)); chamberBar.Visible=false
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
        captureEnd()
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
remote.OnClientEvent:Connect(function(event,data)
    if event=='State' then
        state=data
        local p=state.Profile
        cash.Text=money(p.Money); income.Text=money(state.Income)..'/SEC • '..Rules.multiplier(p)..'x BONUS'
        capacity.Text='VACUUM '..#p.Bag..'/'..Rules.capacity(p); rebirths.Text='REBIRTHS '..p.Rebirths
        local floor=player:GetAttribute('Floor') or 0
        if chamberCenter then objective.Text='HAUNT CHAMBER • Your ghosts are hunting.'
        elseif #p.Bag>=Rules.capacity(p) then objective.Text='VACUUM FULL → HAUNT → GO HOME → DEPOSIT'
        elseif #p.Placed==0 and #p.Bag>0 then objective.Text='Return to your Haunt and DEPOSIT to start earning.'
        elseif floor>0 then objective.Text='Click repeatedly • Chase resisting ghosts • F: flashlight • Q: release'
        elseif state.Income==0 then objective.Text='Your Haunt: Plot '..(state.Plot or '?')..' • MANSION → ENTER to hunt your first ghost.'
        elseif p.Floor<6 then objective.Text='Next area: '..C.Floors[p.Floor+1].Name..' • '..money(C.Floors[p.Floor+1].Cost)
        else objective.Text='Explore the Catacombs or work toward your next rebirth.' end
        if data.Practice then objective.Text..='  [Studio practice — no saves]' end
        if chamberCenter then chamberText.Text=#p.Placed..' HUNTERS\nDiscoveries: '..p.ChamberDiscoveries end
        local signature=p.HauntLevel..':'..p.Floor..':'..p.Rebirths..':'..#p.Bag..':'..table.concat(p.Placed,',')
        for _,name in C.UpgradeNames do signature..=':'..p.Upgrades[name] end
        for _,id in sortedGhosts() do signature..=':'..(p.Owned[id] or 0) end
        if currentPanel and signature~=lastSignature then render(currentPanel) end
        lastSignature=signature
    elseif event=='Notice' then notify(data)
    elseif event=='Open' then render(data)
    elseif event=='BeamOn' then beamOn(data)
    elseif event=='BeamOff' then beamOff(data.UserId)
    elseif event=='CaptureProgress' then
        captureBox.Visible=not currentPanel; bar.Size=UDim2.fromScale(data.Progress,1)
        local g=wildGhost(targetId)
        if g and g.PrimaryPart then
            g:ScaleTo(math.max(0.35,1-data.Progress*0.35))
            local glow=g.PrimaryPart:FindFirstChildOfClass('PointLight')
            if glow then glow.Brightness=0.65+data.Progress*1.8 end
        end
        captureText.Text=C.Ghosts[data.Species].Name..' • '..math.floor(data.Progress*100)..'%\n'..(if data.Surge then 'PULLING AWAY! CHASE IT!' else 'KEEP CLICKING!')
        bar.BackgroundColor3=if data.Surge then amber else mint
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
        chamberCenter=data.Center; chamberBar.Visible=true; actions.Visible=false; panel.Visible=false; currentPanel=nil; captureEnd()
        workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
    elseif event=='ChamberExit' then
        chamberCenter=nil; chamberBar.Visible=false; actions.Visible=true
        restoreCamera()
    elseif event=='ChamberFound' then
        local g=C.Ghosts[data.Species]
        notify('YOUR GHOSTS FOUND '..string.upper(C.Rarities[g.Rarity])..'!\n'..g.Name,V.color(g.Rarity))
        sound('rbxasset://sounds/volume_slider.ogg',0.25,0.9)
    end
end)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.KeyCode==Enum.KeyCode.ButtonR2 then click()
    elseif input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonX then send('Flashlight')
    elseif input.KeyCode==Enum.KeyCode.Q then send('Cancel') end
end)
local function resize()
    local viewport=workspace.CurrentCamera.ViewportSize
    panel.Size=UDim2.fromOffset(math.min(690,viewport.X-24),math.max(180,math.min(540,viewport.Y-170)))
    captureBox.Size=UDim2.fromOffset(math.min(420,viewport.X-145),76)
    captureBox.Position=UDim2.new(0.5,-45,1,-151)
end
resize()
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize)
RunService.RenderStepped:Connect(function()
    if chamberCenter then workspace.CurrentCamera.CFrame=CFrame.lookAt(chamberCenter+Vector3.new(0,zoom,zoom*0.6),chamberCenter) end
    for userId,b in beams do if not b.Ghost.Parent or not b.Nozzle.Parent then beamOff(userId) end end
end)
player.CharacterAdded:Connect(function(character)
    captureEnd()
    character:WaitForChild('HumanoidRootPart',10)
    if chamberCenter then send('ExitChamber') else restoreCamera() end
end)
if player.Character then
    task.spawn(function() player.Character:WaitForChild('HumanoidRootPart',10); if not chamberCenter then restoreCamera() end end)
end
task.spawn(function()
    while not state do send('Sync'); task.wait(2) end
end)

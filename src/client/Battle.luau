-- Private 1v1 capture screen. All progress and weak-spot rewards come from the server.
local RunService=game:GetService('RunService')
local UserInputService=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local ContextActionService=game:GetService('ContextActionService')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local C=require(Shared.Config)
local V=require(Shared.Visuals)
local BattleAvatar=require(script.Parent.BattleAvatar)
local Battle={}
local active=nil
local movementAction='GhostlightBattleMovement'
local ink=Color3.fromRGB(242,237,220)
local mint=Color3.fromRGB(133,255,220)
local gold=Color3.fromRGB(255,204,118)
local dark=Color3.fromRGB(19,14,31)
local function make(class,parent,props)
    local obj=Instance.new(class)
    for k,v in props do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function box(parent,name,size,pos,color,z)
    return make('Frame',parent,{Name=name,Size=size,Position=pos,BackgroundColor3=color,BorderSizePixel=0,ZIndex=z or 1})
end
local function label(parent,name,value,size,pos,color,maxSize,z)
    local obj=make('TextLabel',parent,{Name=name,Text=value,Size=size,Position=pos,BackgroundTransparency=1,
        Font=Enum.Font.Arcade,TextColor3=color or ink,TextScaled=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z or 2})
    make('UITextSizeConstraint',obj,{MinTextSize=9,MaxTextSize=maxSize or 26})
    return obj
end
local function outline(obj,color,thickness)
    return make('UIStroke',obj,{Color=color,Thickness=thickness or 2})
end
local function round(obj) make('UICorner',obj,{CornerRadius=UDim.new(1,0)}) end
local function contains(obj,pos)
    local p,s=obj.AbsolutePosition,obj.AbsoluteSize
    return pos.X>=p.X and pos.Y>=p.Y and pos.X<=p.X+s.X and pos.Y<=p.Y+s.Y
end
local function listen(session,signal,fn)
    table.insert(session.Connections,signal:Connect(fn))
end
local function portrait(parent,name,model,size,pos,back)
    local vp=make('ViewportFrame',parent,{Name=name,Size=size,Position=pos,BackgroundTransparency=1,Active=false,
        Ambient=Color3.fromRGB(165,161,189),LightColor=Color3.fromRGB(255,245,228),LightDirection=Vector3.new(-1,-1,2),ZIndex=4})
    local wm=make('WorldModel',vp,{Name='PortraitWorld'})
    model.Parent=wm
    for _,obj in model:GetDescendants() do
        if obj:IsA('Script') or obj:IsA('LocalScript') or obj:IsA('BillboardGui') or obj:IsA('Sound') then obj:Destroy()
        elseif obj:IsA('BasePart') then obj.Anchored=true; obj.CanCollide=false; obj.LocalTransparencyModifier=0 end
    end
    model:PivotTo(CFrame.new())
    local bounds,extent=model:GetBoundingBox()
    local camera=make('Camera',vp,{FieldOfView=38})
    vp.CurrentCamera=camera
    return {Viewport=vp,Model=model,Camera=camera,Bounds=bounds,Extent=extent,Back=back,Pivot=model:GetPivot(),Scale=model:GetScale()}
end
local function fitPortrait(p,t,shrink)
    local vp=p.Viewport
    local aspect=math.max(0.1,vp.AbsoluteSize.X/math.max(1,vp.AbsoluteSize.Y))
    local distance=math.max(p.Extent.Y,p.Extent.X/aspect)*0.58/math.tan(math.rad(19))+p.Extent.Z*0.65
    -- Back-right view projects the hunter's forward (-Z) direction toward the ghost on screen-right.
    local direction=if p.Back then Vector3.new(1.25,0.12,1).Unit else Vector3.new(0,0,-1)
    p.Camera.CFrame=CFrame.lookAt(p.Bounds.Position+direction*distance,p.Bounds.Position)
    p.Model:ScaleTo(p.Scale*shrink)
    p.Model:PivotTo(p.Pivot*CFrame.new(0,if p.Back then 0 else math.sin(t*2.4)*0.15,0))
end
function Battle.isActive() return active~=nil end
function Battle.close()
    local s=active
    if not s then return end
    active=nil
    for _,connection in s.Connections do connection:Disconnect() end
    ContextActionService:UnbindAction(movementAction)
    if s.Gui then s.Gui:Destroy() end
    if s.Hud.Parent then s.Hud.Enabled=s.HudEnabled end
    if s.Camera and s.Camera==workspace.CurrentCamera then s.Camera.CameraType=s.CameraType end
    UserInputService.MouseBehavior=s.MouseBehavior
    UserInputService.MouseIconEnabled=s.MouseIconEnabled
end
local function click(s)
    if active~=s or s.Finished then return end
    local now=os.clock()
    if now-s.LastClick<C.Capture.ClickInterval then return end
    s.LastClick=now
    s.Remote:FireServer('Click',s.Id)
    s.PulseUntil=now+0.13
end
function Battle.progress(data)
    local s=active
    if not s or s.Id~=data.Id or s.Finished then return end
    s.Progress=data.Progress
end
function Battle.weakSpot(data)
    local s=active
    if not s or s.Id~=data.Id or s.Finished then return end
    s.Spot=data; s.SpotClaimed=false; s.Target.Visible=true; s.Ring.Visible=true
    s.Target.Position=UDim2.fromScale(data.X,data.Y)
    s.Ring.Position=s.Target.Position
    s.Feedback.Text='AIM INSIDE WHEN THE RING CLOSES'
    s.Feedback.TextColor3=dark
end
function Battle.weakSpotResult(data)
    local s=active
    if not s or s.Id~=data.Id or not s.Spot or s.Spot.Token~=data.Token or s.Finished then return end
    s.Progress=data.Progress
    s.Spot=nil; s.Target.Visible=false; s.Ring.Visible=false
    s.Feedback.Text=if data.Hit then string.format('WEAK SPOT! +%d%% CAPTURE',math.floor(data.Bonus*100+0.5)) else 'MISSED! KEEP CLICKING'
    s.Feedback.TextColor3=if data.Hit then Color3.fromRGB(18,112,90) else Color3.fromRGB(136,80,15)
    if data.Hit then s.Cue:Play(); s.PulseUntil=os.clock()+0.3 end
end
function Battle.finish(data)
    local s=active
    if not s or s.Id~=data.Id then return end
    s.Finished=os.clock(); s.Progress=1; s.Spot=nil
    s.Target.Visible=false; s.Ring.Visible=false; s.Exit.Visible=false
    s.Feedback.Text=string.upper(C.Ghosts[data.Species].Name)..' CAPTURED!'
    s.Feedback.TextColor3=Color3.fromRGB(18,112,90)
    s.Help.Text='Added to your vacuum. Returning to the mansion...'
    task.delay(1.35,function() if active==s then Battle.close() end end)
end
function Battle.open(player,hud,data,remote)
    Battle.close()
    local s={Id=data.Id,Hud=hud,HudEnabled=hud.Enabled,Connections={},Remote=remote,Progress=data.Progress or 0,
        ShownProgress=0,LastClick=0,PulseUntil=0,Touches={},Stick=Vector2.new(),PadCursor=Vector2.new(0.5,0.5),
        MouseBehavior=UserInputService.MouseBehavior,MouseIconEnabled=UserInputService.MouseIconEnabled}
    active=s
    local ok,err=xpcall(function()
        local species=C.Ghosts[data.Species]
        local accent=V.color(species.Rarity)
        local playerGui=player:WaitForChild('PlayerGui')
        if active~=s then return end
        local gui=make('ScreenGui',playerGui,{Name='GhostlightBattle',IgnoreGuiInset=true,
            ResetOnSpawn=false,DisplayOrder=900,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
        s.Gui=gui
        local backdrop=box(gui,'Backdrop',UDim2.fromScale(1,1),UDim2.new(),dark)
        make('UIGradient',backdrop,{Color=ColorSequence.new(Color3.fromRGB(16,13,28),Color3.fromRGB(53,36,66)),Rotation=90})
        local content=box(backdrop,'Content',UDim2.new(1,-48,1,-76),UDim2.fromOffset(24,60),dark)
        content.BackgroundTransparency=1
        label(content,'Heading','GHOST ENCOUNTER',UDim2.fromScale(0.67,0.09),UDim2.new(),gold,30)
        s.Exit=make('TextButton',content,{Name='Flee',Text='FLEE [Q]',Size=UDim2.fromScale(0.22,0.09),Position=UDim2.fromScale(0.78,0),
            BackgroundColor3=Color3.fromRGB(62,42,70),TextColor3=ink,TextScaled=true,Font=Enum.Font.Arcade,BorderSizePixel=0,ZIndex=3})
        make('UITextSizeConstraint',s.Exit,{MinTextSize=10,MaxTextSize=20})
        listen(s,s.Exit.Activated,function() if not s.Finished then remote:FireServer('Cancel') end end)
        local arena=box(content,'Arena',UDim2.fromScale(1,0.59),UDim2.fromScale(0,0.12),Color3.fromRGB(50,39,70))
        arena.ClipsDescendants=true; outline(arena,accent)
        make('UIGradient',arena,{Color=ColorSequence.new(Color3.fromRGB(34,29,52),Color3.fromRGB(90,67,97)),Rotation=90})
        -- Tall windows and floor lines suggest the mansion, with diagonal Pokemon-style platforms.
        for i=1,5 do
            local window=box(arena,'Window'..i,UDim2.fromScale(0.09,0.49),UDim2.fromScale(i*0.19-0.12,-0.09),Color3.fromRGB(139,117,165),2)
            window.BackgroundTransparency=0.85
            box(window,'Mullion',UDim2.fromScale(0.08,1),UDim2.fromScale(0.46,0),Color3.fromRGB(43,32,57),2)
        end
        for i=1,5 do
            local line=box(arena,'FloorLine'..i,UDim2.new(1,0,0,1),UDim2.fromScale(0,0.46+i*0.10),accent,2)
            line.BackgroundTransparency=0.88
        end
        local near=box(arena,'PlayerPlatform',UDim2.fromScale(0.46,0.16),UDim2.fromScale(0.015,0.80),Color3.fromRGB(90,86,111),3); round(near); outline(near,Color3.fromRGB(142,131,159))
        local far=box(arena,'GhostPlatform',UDim2.fromScale(0.39,0.12),UDim2.fromScale(0.56,0.56),Color3.fromRGB(107,91,123),3); round(far); outline(far,accent)
        local nameplate=box(arena,'GhostNameplate',UDim2.fromScale(0.43,0.20),UDim2.fromScale(0.035,0.05),dark,5)
        outline(nameplate,accent)
        label(nameplate,'GhostName',species.Name,UDim2.fromScale(0.90,0.50),UDim2.fromScale(0.05,0.07),ink,26,6)
        label(nameplate,'Rarity','WILD / '..string.upper(C.Rarities[species.Rarity]),UDim2.fromScale(0.90,0.25),UDim2.fromScale(0.05,0.65),accent,16,6)
        label(arena,'HunterName',player.DisplayName..' / HUNTER',UDim2.fromScale(0.44,0.07),UDim2.fromScale(0.03,0.91),ink,16,5)
        local wild=workspace:FindFirstChild('GhostlightWorld')
        wild=wild and wild:FindFirstChild('WildGhosts')
        local original=wild and wild:FindFirstChild('Ghost_'..data.Id)
        local ghost=if original then original:Clone() else V.ghost(data.Species,nil,CFrame.new(),1,false)
        if active~=s then ghost:Destroy(); return end
        ghost:ScaleTo(1)
        s.Ghost=portrait(arena,'Opponent',ghost,UDim2.fromScale(0.40,0.61),UDim2.fromScale(0.55,0.025),false)
        local char=player.Character
        if char then
            local avatar=BattleAvatar.create(char)
            s.Hunter=portrait(arena,'Hunter',avatar,UDim2.fromScale(0.48,0.69),UDim2.fromScale(0.01,0.23),true)
        end
        local field=box(arena,'WeakSpotField',UDim2.fromOffset(200,200),UDim2.fromScale(0.73,0.43),dark,8)
        field.AnchorPoint=Vector2.new(0.5,0.5); field.BackgroundTransparency=1; s.Field=field
        s.Target=box(field,'Target',UDim2.fromScale(C.Battle.SpotRadius*2,C.Battle.SpotRadius*2),UDim2.fromScale(0.5,0.5),dark,9)
        s.Target.AnchorPoint=Vector2.new(0.5,0.5); s.Target.BackgroundTransparency=0.20; round(s.Target)
        s.TargetStroke=outline(s.Target,ink,3)
        local cross=label(s.Target,'Crosshair','+',UDim2.fromScale(0.75,0.75),UDim2.fromScale(0.125,0.10),ink,30,10)
        cross.TextXAlignment=Enum.TextXAlignment.Center
        s.Ring=box(field,'ClosingRing',UDim2.fromScale(0.44,0.44),UDim2.fromScale(0.5,0.5),mint,10)
        s.Ring.AnchorPoint=Vector2.new(0.5,0.5); s.Ring.BackgroundTransparency=1; round(s.Ring); s.RingStroke=outline(s.Ring,gold,3)
        s.Target.Visible=false; s.Ring.Visible=false
        s.PadMarker=box(field,'GamepadCursor',UDim2.fromOffset(9,9),UDim2.fromScale(0.5,0.5),mint,12)
        s.PadMarker.AnchorPoint=Vector2.new(0.5,0.5); round(s.PadMarker); outline(s.PadMarker,dark,2); s.PadMarker.Visible=false
        local footer=box(content,'CapturePanel',UDim2.fromScale(1,0.25),UDim2.fromScale(0,0.75),Color3.fromRGB(239,232,212))
        outline(footer,accent,3)
        s.Feedback=label(footer,'Feedback','CLICK ANYWHERE TO VACUUM',UDim2.fromScale(0.90,0.23),UDim2.fromScale(0.04,0.065),dark,24)
        local track=box(footer,'CaptureTrack',UDim2.fromScale(0.92,0.21),UDim2.fromScale(0.04,0.37),Color3.fromRGB(58,48,72),2)
        s.Bar=box(track,'CaptureFill',UDim2.fromScale(0,1),UDim2.new(),mint,3)
        s.Percent=label(track,'CapturePercent','CAPTURE 0%',UDim2.fromScale(0.98,0.88),UDim2.fromScale(0.01,0.05),ink,20,4)
        s.Percent.TextXAlignment=Enum.TextXAlignment.Center; s.Percent.TextStrokeTransparency=0.25; s.Percent.TextStrokeColor3=dark
        s.Help=label(footer,'Instructions','Click to capture. Hover inside a circle as its ring closes: +12%.',UDim2.fromScale(0.92,0.28),UDim2.fromScale(0.04,0.66),Color3.fromRGB(70,56,86),18)
        s.Cue=make('Sound',gui,{SoundId='rbxasset://sounds/volume_slider.ogg',Volume=0.28,PlaybackSpeed=1.35})
        hud.Enabled=false
        s.Camera=workspace.CurrentCamera; s.CameraType=s.Camera.CameraType; s.Camera.CameraType=Enum.CameraType.Scriptable
        UserInputService.MouseBehavior=Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled=true
        ContextActionService:BindActionAtPriority(movementAction,function() return Enum.ContextActionResult.Sink end,false,3000,
            Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,
            Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
        listen(s,UserInputService.InputBegan,function(input,processed)
            if s.Finished or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return end
            local kind=input.UserInputType
            if kind==Enum.UserInputType.MouseButton1 or kind==Enum.UserInputType.Touch then
                local pos=if kind==Enum.UserInputType.Touch then Vector2.new(input.Position.X,input.Position.Y) else UserInputService:GetMouseLocation()
                if not contains(content,pos) or contains(s.Exit,pos) then return end
                s.Mode=if kind==Enum.UserInputType.Touch then 'Touch' else 'Mouse'
                if kind==Enum.UserInputType.Touch then s.Touches[input]=pos end
                click(s)
            elseif not processed and (input.KeyCode==Enum.KeyCode.ButtonR2 or input.KeyCode==Enum.KeyCode.ButtonA) then
                s.Mode='Gamepad'; click(s)
            elseif not processed and (input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.ButtonB) then remote:FireServer('Cancel') end
        end)
        listen(s,UserInputService.InputChanged,function(input)
            if input.UserInputType==Enum.UserInputType.Touch and s.Touches[input] then s.Touches[input]=Vector2.new(input.Position.X,input.Position.Y)
            elseif input.KeyCode==Enum.KeyCode.Thumbstick2 then s.Stick=Vector2.new(input.Position.X,-input.Position.Y); s.Mode='Gamepad'
            elseif input.UserInputType==Enum.UserInputType.MouseMovement then s.Mode='Mouse' end
        end)
        listen(s,UserInputService.InputEnded,function(input) s.Touches[input]=nil end)
        listen(s,UserInputService.WindowFocusReleased,function() s.Focused=false; table.clear(s.Touches); s.Stick=Vector2.new() end)
        listen(s,UserInputService.WindowFocused,function() s.Focused=true end)
        listen(s,RunService.RenderStepped,function(dt)
            if active~=s then return end
            local now=os.clock()
            local side=math.min(arena.AbsoluteSize.X*0.52,arena.AbsoluteSize.Y*0.83)
            field.Size=UDim2.fromOffset(side,side)
            local finishTime=if s.Finished then math.clamp((now-s.Finished)/0.8,0,1) else 0
            fitPortrait(s.Ghost,now,math.max(0.03,(1-s.Progress*0.12)*(1-finishTime)))
            if s.Hunter then fitPortrait(s.Hunter,now,1) end
            s.ShownProgress+=(s.Progress-s.ShownProgress)*math.min(1,dt*16)
            s.Bar.Size=UDim2.fromScale(s.ShownProgress,1)
            s.Bar.BackgroundColor3=if now<s.PulseUntil then gold else mint
            s.Percent.Text='CAPTURE '..math.floor(s.Progress*100+0.5)..'%'
            s.PadMarker.Visible=s.Mode=='Gamepad' and not s.Finished
            if s.Mode=='Gamepad' then
                s.PadCursor=Vector2.new(math.clamp(s.PadCursor.X+s.Stick.X*dt*0.7,0,1),math.clamp(s.PadCursor.Y+s.Stick.Y*dt*0.7,0,1))
                s.PadMarker.Position=UDim2.fromScale(s.PadCursor.X,s.PadCursor.Y)
            end
            if not s.Finished then
                s.Help.Text=if s.Mode=='Touch' then 'Tap to capture. Hold a circle as its ring closes: +12%.'
                    elseif s.Mode=='Gamepad' then 'A / R2: capture. Right stick: aim. B: flee. Circles: +12%.'
                    else 'Click to capture. Hover inside a circle as its ring closes: +12%.'
            end
            local spot=s.Spot
            if not spot then return end
            local remaining=spot.EndsAt-workspace:GetServerTimeNow()
            local t=math.clamp(1-remaining/C.Battle.SpotDuration,0,1)
            local radius=C.Battle.SpotRadius+(0.23-C.Battle.SpotRadius)*(1-t)
            s.Ring.Size=UDim2.fromScale(radius*2,radius*2)
            local pointer
            local function testPoint(pos)
                local uv=(pos-field.AbsolutePosition)/math.max(1,side)
                if (uv-Vector2.new(spot.X,spot.Y)).Magnitude<=C.Battle.SpotRadius then pointer=uv end
            end
            if s.Mode=='Touch' then for _,pos in s.Touches do testPoint(pos) end
            elseif s.Mode=='Gamepad' then testPoint(field.AbsolutePosition+s.PadCursor*side)
            else testPoint(UserInputService:GetMouseLocation()) end
            local over=pointer~=nil and s.Focused~=false and not GuiService.MenuIsOpen and not UserInputService:GetFocusedTextBox()
            s.TargetStroke.Color=if over then mint else ink
            s.RingStroke.Color=if over then mint else gold
            if remaining<=0 and remaining>= -C.Battle.LateTolerance and not s.SpotClaimed then
                s.SpotClaimed=true -- Judge the pointer at closure, not after a missed circle.
                if over then remote:FireServer('WeakSpot',{Id=s.Id,Token=spot.Token,X=pointer.X,Y=pointer.Y}) end
            end
            if remaining< -C.Battle.LateTolerance then s.Target.Visible=false; s.Ring.Visible=false end
        end)
    end,debug.traceback)
    if not ok then
        if active==s then Battle.close(); remote:FireServer('Cancel') end
        warn('Ghost battle screen: '..tostring(err))
    end
end
return Battle

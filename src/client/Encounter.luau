-- Original handheld-RPG encounter treatment, built entirely from UI and our ghost models.
-- One render loop owns the sequence; cancellation destroys every temporary instance.
local RunService=game:GetService('RunService')
local ContextActionService=game:GetService('ContextActionService')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local C=require(Shared.Config)
local V=require(Shared.Visuals)
local Encounter={}
local active=nil
local inputAction='GhostlightEncounterInput'
local function make(class,parent,props)
    local obj=Instance.new(class)
    for key,value in props do obj[key]=value end
    obj.Parent=parent
    return obj
end
local function box(parent,name,size,pos,color,z)
    return make('Frame',parent,{Name=name,Size=size,Position=pos,BackgroundColor3=color,BorderSizePixel=0,ZIndex=z or 1})
end
local function text(parent,name,value,size,pos,color,z)
    local label=make('TextLabel',parent,{Name=name,Text=value,Size=size,Position=pos,BackgroundTransparency=1,
        Font=Enum.Font.Arcade,TextColor3=color,TextScaled=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=z or 2})
    make('UITextSizeConstraint',label,{MinTextSize=10,MaxTextSize=32})
    return label
end
local function ease(t)
    t=math.clamp(t,0,1)
    return 1-(1-t)^3
end
function Encounter.isPlaying()
    return active~=nil
end
function Encounter.cancel()
    local session=active
    if not session then return end
    active=nil
    ContextActionService:UnbindAction(inputAction)
    if session.Gui then session.Gui:Destroy() end
    if session.Hud.Parent then session.Hud.Enabled=session.HudEnabled end
end
function Encounter.play(player,hud,data)
    Encounter.cancel()
    local species=C.Ghosts[data.Species]
    if not species then return end
    local session={Hud=hud,HudEnabled=hud.Enabled}
    active=session
    task.spawn(function()
        local ok,err=xpcall(function()
            local playerGui=player:WaitForChild('PlayerGui')
            if active~=session then return end
            local black=Color3.fromRGB(10,8,18)
            local paper=Color3.fromRGB(244,237,215)
            local accent=V.color(species.Rarity)
            local gui=make('ScreenGui',playerGui,{Name='GhostlightEncounter',
                IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=1000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
            session.Gui=gui
            local canvas=make('CanvasGroup',gui,{Name='Transition',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Active=true})
            local scene=box(canvas,'BattleReveal',UDim2.fromScale(1,1),UDim2.new(),black,1)
            scene.Visible=false
            local stage=box(scene,'GhostStage',UDim2.fromScale(1,0.48),UDim2.fromScale(0,0.15),Color3.fromRGB(51,38,75),2)
            stage.ClipsDescendants=true
            make('UIGradient',stage,{Color=ColorSequence.new(Color3.fromRGB(23,18,41),Color3.fromRGB(92,67,114)),Rotation=90})
            box(scene,'TopRule',UDim2.new(1,0,0,4),UDim2.fromScale(0,0.15),accent,3)
            box(scene,'BottomRule',UDim2.new(1,0,0,4),UDim2.fromScale(0,0.63),accent,3)
            text(scene,'EncounterHeading','GHOST ENCOUNTER',UDim2.fromScale(0.86,0.06),UDim2.fromScale(0.07,0.055),accent,3)
            local streaks={}
            for i=1,14 do
                local stripe=box(stage,'SpeedLine'..i,UDim2.fromScale(0.15+(i%4)*0.06,0.006),UDim2.fromScale((i*0.29)%1,i/16),accent,3)
                stripe.BackgroundTransparency=0.7
                table.insert(streaks,stripe)
            end
            local ground=box(stage,'GhostShadow',UDim2.fromScale(0.32,0.10),UDim2.fromScale(0.53,0.83),black,3)
            make('UICorner',ground,{CornerRadius=UDim.new(1,0)})
            ground.BackgroundTransparency=0.2
            local viewport=make('ViewportFrame',stage,{Name='GhostPortrait',Size=UDim2.fromScale(0.52,0.92),Position=UDim2.fromScale(0.43,0.01),
                BackgroundTransparency=1,Ambient=Color3.fromRGB(155,155,180),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,2),ZIndex=4})
            local wm=make('WorldModel',viewport,{Name='PortraitWorld'})
            local world=workspace:FindFirstChild('GhostlightWorld')
            local wild=world and world:FindFirstChild('WildGhosts')
            local original=wild and wild:FindFirstChild('Ghost_'..data.Id)
            local ghost
            if original then
                ghost=original:Clone(); ghost.Parent=wm; ghost:ScaleTo(1); ghost:PivotTo(CFrame.new())
            else
                ghost=V.ghost(data.Species,wm,CFrame.new(),1,false)
            end
            -- Model loading can yield. A canceled/expired intro must never hide the HUD later.
            if active~=session or workspace:GetServerTimeNow()>=data.EndsAt then return end
            for _,obj in ghost:GetDescendants() do
                if obj:IsA('BillboardGui') or obj:IsA('Script') or obj:IsA('LocalScript') then obj:Destroy() end
            end
            local bounds,size=ghost:GetBoundingBox()
            local camera=make('Camera',viewport,{FieldOfView=40})
            viewport.CurrentCamera=camera
            local rarity=text(stage,'Rarity',string.upper(C.Rarities[species.Rarity]),UDim2.fromScale(0.34,0.12),UDim2.fromScale(0.07,0.24),accent,4)
            text(stage,'WildLabel','WILD GHOST',UDim2.fromScale(0.32,0.09),UDim2.fromScale(0.07,0.41),paper,4)
            local dialogue=box(scene,'DialogueBorder',UDim2.fromScale(0.90,0.23),UDim2.fromScale(0.05,0.70),accent,3)
            local inner=box(dialogue,'Paper',UDim2.new(1,-8,1,-8),UDim2.fromOffset(4,4),paper,4)
            local message='A wild '..species.Name..' appeared!'
            local caption=text(inner,'EncounterText',message,UDim2.fromScale(0.90,0.49),UDim2.fromScale(0.05,0.08),black,5)
            text(inner,'Hint','Get your vacuum ready!',UDim2.fromScale(0.90,0.22),UDim2.fromScale(0.05,0.68),Color3.fromRGB(78,65,96),5)
            local flash=box(canvas,'Flash',UDim2.fromScale(1,1),UDim2.new(),paper,8)
            flash.BackgroundTransparency=1
            local bands={}
            for i=1,12 do
                local band=box(canvas,'Sweep'..i,UDim2.new(1,2,1/12,2),UDim2.new(if i%2==0 then -1.01 else 1.01,0,(i-1)/12,0),black,10)
                table.insert(bands,band)
            end
            hud.Enabled=false
            ContextActionService:BindActionAtPriority(inputAction,function() return Enum.ContextActionResult.Sink end,false,3000,
                Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,
                Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
            -- Bundled effect: no uploaded audio or Pokemon assets required.
            local cue=make('Sound',gui,{SoundId='rbxasset://sounds/volume_slider.ogg',Volume=0.22,PlaybackSpeed=0.65})
            cue:Play()
            local endsAt=data.EndsAt
            while active==session do
                local t=math.clamp(1-(endsAt-workspace:GetServerTimeNow())/C.Encounter.Duration,0,1)
                if t>=1 then session.Completed=true; break end
                -- A single warm flash, followed by staggered alternating horizontal shutters.
                flash.BackgroundTransparency=if t<0.16 then 1-math.sin(t/0.16*math.pi)*0.72 else 1
                scene.Visible=t>=0.40
                for i,band in bands do
                    local direction=if i%2==0 then -1 else 1
                    local delay=(i-1)*0.006
                    local covered=ease((t-0.16-delay)/0.16)
                    local opened=ease((t-0.44-delay)/0.15)
                    band.Position=UDim2.new(direction*((1-covered)-opened)*1.01,0,(i-1)/12,0)
                end
                local arrival=ease((t-0.44)/0.23)
                viewport.Position=UDim2.fromScale(0.43+(1-arrival)*0.65,0.01)
                viewport.ImageColor3=Color3.new(1,1,1):Lerp(Color3.fromRGB(15,10,25),1-ease((t-0.56)/0.12))
                rarity.TextTransparency=1-arrival
                caption.MaxVisibleGraphemes=math.floor(#message*math.clamp((t-0.59)/0.17,0,1))
                for i,stripe in streaks do stripe.Position=UDim2.fromScale(((i*0.29-t*(1+i%3))%1.4)-0.25,i/16) end
                local aspect=math.max(0.1,viewport.AbsoluteSize.X/math.max(1,viewport.AbsoluteSize.Y))
                local distance=math.max(size.Y,size.X/aspect)*0.60/math.tan(math.rad(20))+size.Z*0.5
                camera.CFrame=CFrame.lookAt(bounds.Position+Vector3.new(0,0,-distance),bounds.Position)
                -- Hold the reveal until BattleStart swaps in the 1v1 screen without a world flash.
                canvas.GroupTransparency=0
                RunService.RenderStepped:Wait()
            end
        end,debug.traceback)
        if active==session and (not ok or not session.Completed) then Encounter.cancel() end
        if not ok then warn('Ghost encounter transition: '..tostring(err)) end
    end)
end
return Encounter

local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local V=require(Shared.Visuals)
local C=require(Shared.Config)
local Assets=require(Shared.Assets.Loader)
local W={Plots={},Areas={},Switches={}}
local stone=Color3.fromRGB(51,49,65)
local wood=Color3.fromRGB(62,43,58)
local purple=Color3.fromRGB(166,103,246)
local warm=Color3.fromRGB(255,188,104)
local function part(parent,name,size,pos,color,mat)
    return V.part(parent,name,size,CFrame.new(pos),color or stone,mat or Enum.Material.Slate)
end
local function prompt(p,text,object,callback)
    local pr=Instance.new('ProximityPrompt'); pr.ActionText=text; pr.ObjectText=object or ''; pr.MaxActivationDistance=12; pr.RequiresLineOfSight=false; pr.Parent=p
    if callback then pr.Triggered:Connect(callback) end
    return pr
end
W.prompt=prompt
local function lamp(parent,pos)
    if Assets.configured('StreetLamp') then
        local model=Assets.place('StreetLamp',parent,CFrame.new(pos))
        local glow=model:FindFirstChild('StreetLamp_Glow',true)
        if glow then
            local light=Instance.new('PointLight'); light.Color=warm; light.Brightness=1.4; light.Range=19; light.Parent=glow
        end
        return
    end
    part(parent,'LampPost',Vector3.new(0.4,7,0.4),pos+Vector3.new(0,3.5,0))
    local glow=part(parent,'Lantern',Vector3.new(1,1.6,1),pos+Vector3.new(0,7.5,0),warm,Enum.Material.Neon)
    local light=Instance.new('PointLight'); light.Color=warm; light.Brightness=1.4; light.Range=19; light.Parent=glow
    part(parent,'LanternCap',Vector3.new(1.6,0.3,1.6),pos+Vector3.new(0,8.5,0))
end
local function sign(parent,pos,text,color)
    local p=part(parent,'Sign',Vector3.new(9,3,0.6),pos,Color3.fromRGB(27,22,43),Enum.Material.Wood)
    V.label(p,text,color or purple,240,65)
    return p
end
local function path(parent,a,b,width)
    local mid=(a+b)/2
    local p=part(parent,'Path',Vector3.new(width or 12,0.3,(a-b).Magnitude),mid,Color3.fromRGB(86,76,94),Enum.Material.Cobblestone)
    p.CFrame=CFrame.lookAt(mid,b)
end
function W.build()
    local loadNames={}
    for _,name in {'StreetLamp','Gravestone','PineTree','DeadTree','Pumpkin','GhostFountain','ChamberPortal','RebirthAltar','NoticeBoard','WelcomeSign'} do
        if Assets.configured(name) then table.insert(loadNames,name) end
    end
    Assets.preload(loadNames)
    local buildStarted=os.clock()
    local root=Instance.new('Folder'); root.Name='GhostlightWorld'; root.Parent=workspace; W.Root=root
    local lighting=game:GetService('Lighting')
    lighting.ClockTime=0.5; lighting.Brightness=1.6; lighting.Ambient=Color3.fromRGB(40,32,67); lighting.OutdoorAmbient=Color3.fromRGB(61,65,103)
    lighting.GlobalShadows=true; lighting.FogColor=Color3.fromRGB(30,28,56); lighting.FogStart=130; lighting.FogEnd=560
    local atm=Instance.new('Atmosphere'); atm.Density=0.24; atm.Color=Color3.fromRGB(112,116,165); atm.Decay=Color3.fromRGB(65,48,94); atm.Parent=lighting
    local bloom=Instance.new('BloomEffect'); bloom.Intensity=0.14; bloom.Size=18; bloom.Threshold=2.2; bloom.Parent=lighting
    part(root,'TownGround',Vector3.new(420,3,420),Vector3.new(0,-2,0),Color3.fromRGB(29,43,42),Enum.Material.Grass)
    local plaza=part(root,'CircularPlaza',Vector3.new(1,66,66),Vector3.new(0,0,0),stone,Enum.Material.Cobblestone)
    plaza.Shape=Enum.PartType.Cylinder; plaza.CFrame=CFrame.new(0,0,0)*CFrame.Angles(0,0,math.pi/2)
    local spiritBlue=Color3.fromRGB(160,225,255)
    if Assets.configured('GhostFountain') then
        -- The plaza disc top is y 0.5; the fountain base sits on it. Its spirit is the Accent mesh, coloured blue-white.
        local fountain=Assets.place('GhostFountain',root,CFrame.new(0,0.5,0),{Accent=spiritBlue})
        local spirit=fountain:FindFirstChild('GhostFountain_Accent',true)
        if spirit then
            local l=Instance.new('PointLight'); l.Color=spiritBlue; l.Brightness=2.2; l.Range=28; l.Shadows=true; l.Parent=spirit
        end
    else
        local pedestal=part(root,'Fountain',Vector3.new(1.5,13,13),Vector3.new(0,1,0),stone)
        pedestal.Shape=Enum.PartType.Cylinder; pedestal.CFrame=CFrame.new(0,1,0)*CFrame.Angles(0,0,math.pi/2)
        V.ghost('mothlight',root,CFrame.new(0,7,0),2,false)
    end
    local spawn=Instance.new('SpawnLocation'); spawn.Name='TownSpawn'; spawn.Size=Vector3.new(8,1,8); spawn.Position=Vector3.new(0,0.6,21); spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0; spawn.Transparency=1; spawn.CanCollide=false; spawn.Parent=root
    -- Welcome signs flank the south path; nothing stands on the portal base any more.
    if Assets.configured('WelcomeSign') then
        for _,x in {-12,12} do
            local post=Assets.place('WelcomeSign',root,CFrame.new(x,-0.5,50))
            local board=post:FindFirstChild('WelcomeSign_Wood',true) or post:FindFirstChildWhichIsA('BasePart',true)
            V.label(board,'GHOSTLIGHT HOLLOW\nHunt • Haunt • Discover',purple,240,65).Parent.StudsOffset=Vector3.new(0,1.2,0)
        end
    else
        sign(root,Vector3.new(0,5,54),'GHOSTLIGHT HOLLOW\nHunt • Haunt • Discover')
    end
    local plotNumber=0
    for i=1,8 do
        if i==5 then continue end
        plotNumber+=1
        local angle=math.rad(20+(i-1)*40)
        local center=Vector3.new(math.sin(angle)*116,0,math.cos(angle)*116)
        local model=Instance.new('Model'); model.Name='Haunt'..i; model.Parent=root
        local cf=CFrame.lookAt(center,Vector3.new(0,0,0))
        local function p(name,size,offset,color,mat) return V.part(model,name,size,cf*CFrame.new(offset),color or wood,mat) end
        p('Foundation',Vector3.new(46,1,40),Vector3.new(0,0.5,0),stone,Enum.Material.Cobblestone)
        p('BackWall',Vector3.new(46,13,1),Vector3.new(0,7,19))
        for _,s in {-1,1} do
            p('SideWall',Vector3.new(1,13,40),Vector3.new(s*23,7,0))
            p('FrontPillar',Vector3.new(2,13,2),Vector3.new(s*21,7,-19))
            p('Roof',Vector3.new(24,1.5,42),Vector3.new(s*10,15.2,0),Color3.fromRGB(39,30,57)).CFrame=cf*CFrame.new(s*10,15.2,0)*CFrame.Angles(0,0,s*math.rad(-18))
        end
        local board=p('OwnerBoard',Vector3.new(18,3,1),Vector3.new(0,12,-16),Color3.fromRGB(24,19,37))
        local label=V.label(board,'UNCLAIMED HAUNT',purple,290,100)
        local hologram=p('IncomeHologram',Vector3.new(0.5,0.5,0.5),Vector3.new(0,10,2),Color3.fromRGB(131,255,225),Enum.Material.Neon)
        hologram.Transparency=1
        local incomeLabel=V.label(hologram,'$/SEC • $0',Color3.fromRGB(131,255,225),210,48)
        local deposit=p('Deposit',Vector3.new(5,0.4,5),Vector3.new(-11,1.2,-10),Color3.fromRGB(82,219,190),Enum.Material.Neon)
        V.label(deposit,'DEPOSIT\nCaptured ghosts',Color3.fromRGB(153,255,223),140,45)
        local chamber=p('ChamberDoor',Vector3.new(5,7,0.5),Vector3.new(11,4.5,14),purple,Enum.Material.Neon)
        V.label(chamber,'HAUNT CHAMBER',purple,170,45)
        chamber.Transparency=1; chamber.CanCollide=false
        local chamberGui=chamber:FindFirstChild('Label'); if chamberGui then chamberGui.Enabled=false end
        local slots={}
        for j=1,20 do
            local x=((j-1)%5-2)*6
            local z=math.floor((j-1)/5)*5-5
            local pad=p('Slot'..j,Vector3.new(4,0.4,4),Vector3.new(x,1.2,z),Color3.fromRGB(70,53,98))
            table.insert(slots,pad)
        end
        W.Plots[plotNumber]={Model=model,CF=cf,Slots=slots,Label=label,IncomeLabel=incomeLabel,Deposit=deposit,ChamberDoor=chamber,Owner=nil,Displays={}}
        path(root,Vector3.new(center.X,0.1,center.Z)*0.26,center,12)
        lamp(root,(cf*CFrame.new(-20,1,-17)).Position)
        lamp(root,(cf*CFrame.new(20,1,-17)).Position)
    end
    path(root,Vector3.new(0,0.2,-30),Vector3.new(0,0.2,-180),18)
    for z=-45,-170,-25 do lamp(root,Vector3.new(-13,-0.5,z)); lamp(root,Vector3.new(13,-0.5,z)) end
    -- Landmark exterior. Hunting wings are separated so access remains personal and server-validated.
    local facade=Instance.new('Model'); facade.Name='MansionExterior'; facade.Parent=root
    part(facade,'EntranceSteps',Vector3.new(70,2,40),Vector3.new(0,0,-181))
    part(facade,'MansionFacade',Vector3.new(72,36,12),Vector3.new(0,18,-202),wood,Enum.Material.Brick)
    for _,x in {-31,31} do
        part(facade,'Tower',Vector3.new(15,52,19),Vector3.new(x,26,-204),stone,Enum.Material.Brick)
        local roof=part(facade,'TowerRoof',Vector3.new(20,12,23),Vector3.new(x,57,-204),Color3.fromRGB(37,27,53))
        roof.Shape=Enum.PartType.Ball
    end
    for x=-24,24,12 do for y=12,30,12 do part(facade,'GlowingWindow',Vector3.new(4,7,0.3),Vector3.new(x,y,-195.8),warm,Enum.Material.Neon) end end
    W.MansionDoor=part(facade,'MansionEntrance',Vector3.new(10,14,1),Vector3.new(0,8,-195),purple,Enum.Material.Neon)
    sign(root,Vector3.new(0,17,-179),'THE HAUNTED MANSION\nEnter • Hunt • Return')
    W.Upgrades=sign(root,Vector3.new(-42,4,30),'THE WORKSHOP\nVacuum & Haunt Upgrades',warm)
    -- The legacy REBIRTH ALTAR sign is gone; it overlapped the altar built further down.
    if Assets.configured('NoticeBoard') then
        local board=Assets.place('NoticeBoard',root,CFrame.new(0,-0.5,62))
        W.Leaderboard=board:FindFirstChild('NoticeBoard_Collision',true) or board:FindFirstChildWhichIsA('BasePart',true)
        V.label(W.Leaderboard,'HOLLOW HUNTERS',warm,240,65).Parent.StudsOffset=Vector3.new(0,0.8,0)
    else
        W.Leaderboard=sign(root,Vector3.new(0,5,62),'HOLLOW HUNTERS',warm)
    end
    W.Leaderboard.Label.Size=UDim2.fromOffset(330,170)
    for _,x in {-47,47} do
        local npc=part(root,'Caretaker',Vector3.new(2,3,1),Vector3.new(x,2,36),Color3.fromRGB(63,45,84))
        local head=part(root,'CaretakerHead',Vector3.new(1.5,1.5,1.5),Vector3.new(x,4.3,36),warm); head.Shape=Enum.PartType.Ball
        V.label(npc,if x<0 then 'MIRA • EQUIPMENT' else 'ORIN • REBIRTH',warm,180,45)
    end
    local rng=Random.new(1047)
    for i=1,58 do
        local a=rng:NextNumber(0,math.pi*2); local r=rng:NextNumber(165,195)
        local pos=Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
        if math.abs(pos.X)>24 or pos.Z>0 then
            -- Whole-town MeshPart cap is 500, so every ring tree is a mesh once uploaded: two pines per dead tree.
            local meshName=if i%3==0 then 'DeadTree' else 'PineTree'
            if Assets.configured(meshName) then
                Assets.place(meshName,root,CFrame.new(pos.X,-0.5,pos.Z))
                continue
            end
            part(root,'TreeTrunk',Vector3.new(2,11,2),pos+Vector3.new(0,5,0),wood,Enum.Material.Wood)
            for j=1,3 do local crown=part(root,'Pine',Vector3.new(14-j*2,8,14-j*2),pos+Vector3.new(0,8+j*4,0),Color3.fromRGB(25,43,43),Enum.Material.Grass); crown.Shape=Enum.PartType.Ball end
        end
    end
    for i=1,15 do
        local pos=Vector3.new(130+(i%5)*7,1.4,100+math.floor(i/5)*9)
        if Assets.configured('Gravestone') then
            Assets.place('Gravestone',root,CFrame.new(pos.X,-.5,pos.Z))
        else
            part(root,'Gravestone',Vector3.new(3,4,1),pos,Color3.fromRGB(86,86,102))
        end
    end
    if Assets.configured('Pumpkin') then Assets.place('Pumpkin',root,CFrame.new(47,-0.5,26)) end
    sign(root,Vector3.new(146,3,93),'THE QUIET GARDEN',Color3.fromRGB(170,187,206))
    for floor,info in C.Floors do
        local center=Vector3.new((floor-1)*150,0,-450)
        local area=Instance.new('Model'); area.Name='Floor'..floor; area.Parent=root
        part(area,'Floor',Vector3.new(132,2,112),center-Vector3.new(0,1,0),wood,Enum.Material.WoodPlanks)
        part(area,'Ceiling',Vector3.new(134,1,114),center+Vector3.new(0,19,0),Color3.fromRGB(27,23,38))
        for _,s in {-1,1} do
            part(area,'Wall',Vector3.new(2,20,114),center+Vector3.new(s*66,9,0),stone,Enum.Material.Brick)
            part(area,'Wall',Vector3.new(132,20,2),center+Vector3.new(0,9,s*56),stone,Enum.Material.Brick)
            for _,z in {-36,36} do part(area,'RoomDivider',Vector3.new(2,17,34),center+Vector3.new(s*22,8,z),wood) end
        end
        local entry=center+Vector3.new(0,3,35)
        local exit=part(area,'ReturnDoor',Vector3.new(8,9,0.5),center+Vector3.new(0,4.5,44),purple,Enum.Material.Neon)
        V.label(exit,'RETURN TO HAUNT',purple)
        sign(area,center+Vector3.new(0,12,40),floor..' • '..info.Name)
        local roomNames={'Foyer','Bedrooms','Library','Basement Workshop','Crypt Chapel','Catacomb Reliquary'}
        for room=1,3 do
            local roomSign=part(area,'RoomSign',Vector3.new(7,2,0.4),center+Vector3.new((room-2)*38,8,-50),Color3.fromRGB(34,27,48),Enum.Material.Wood)
            V.label(roomSign,roomNames[math.min(#roomNames,room+(floor-1))],warm,150,35)
        end
        local lights={}
        for _,x in {-36,0,36} do
            for _,z in {-25,25} do
                local pos=center+Vector3.new(x,0,z)
                local tablePart=part(area,'OldTable',Vector3.new(8,0.8,4),pos+Vector3.new(0,3,0),wood,Enum.Material.Wood)
                for _,dx in {-3,3} do part(area,'TableLeg',Vector3.new(0.5,3,0.5),pos+Vector3.new(dx,1.5,0),wood) end
                local candle=part(area,'Candle',Vector3.new(0.3,1.4,0.3),pos+Vector3.new(0,4,0),warm,Enum.Material.Neon)
                local l=Instance.new('PointLight'); l.Color=warm; l.Range=if floor>=4 then 12 else 22; l.Brightness=0.9; l.Parent=candle; table.insert(lights,l)
                if floor==3 then
                    for k=1,5 do part(area,'Book',Vector3.new(0.7,1.2,1),tablePart.Position+Vector3.new(k-3,1,0),Color3.fromRGB(60+k*20,40,76)) end
                elseif floor==2 then
                    part(area,'Bed',Vector3.new(6,2,10),pos+Vector3.new(4,1,-10),Color3.fromRGB(63,39,72))
                elseif floor>=5 then
                    part(area,'Sarcophagus',Vector3.new(5,3,9),pos+Vector3.new(3,1.5,-10),stone)
                end
            end
        end
        -- Lights remain atmospheric and non-toggleable during exploration.
        W.Areas[floor]={Model=area,Center=center,Entry=entry,Exit=exit,Lights=lights}
    end
    local portalGlow,portalLight,portalHome
    local portalCyan=Color3.fromRGB(103,245,224)
    if Assets.configured('ChamberPortal') then
        -- Ground top is y -0.5 outside the plaza disc; the portal base is one stud tall so it meets the plaza top.
        local portalModel=Assets.place('ChamberPortal',root,CFrame.new(0,-0.5,40),{Accent=purple})
        W.ChamberPortal=portalModel:FindFirstChild('ChamberPortal_Collision',true) or portalModel:FindFirstChildWhichIsA('BasePart',true)
        portalGlow=portalModel:FindFirstChild('ChamberPortal_Glow',true)
        if portalGlow then
            portalGlow.Color=portalCyan; portalHome=portalGlow.CFrame
            portalLight=Instance.new('PointLight'); portalLight.Color=portalCyan; portalLight.Range=22; portalLight.Brightness=3; portalLight.Shadows=true; portalLight.Parent=portalGlow
        end
        V.label(W.ChamberPortal,'HAUNT CHAMBER\nAFK PORTAL',Color3.fromRGB(131,255,225),210,60).Parent.StudsOffset=Vector3.new(0,9,0)
    else
        local portalBase=part(root,'ChamberPortalBase',Vector3.new(16,1,16),Vector3.new(0,0.7,40),Color3.fromRGB(54,38,83),Enum.Material.Cobblestone)
        portalBase.Shape=Enum.PartType.Cylinder; portalBase.CFrame=CFrame.new(0,0.7,40)*CFrame.Angles(0,0,math.pi/2)
        portalGlow=part(root,'ChamberPortal',Vector3.new(8,12,1),Vector3.new(0,7,40),portalCyan,Enum.Material.Neon)
        portalGlow.Transparency=0.25; portalHome=portalGlow.CFrame
        portalLight=Instance.new('PointLight'); portalLight.Color=portalCyan; portalLight.Range=22; portalLight.Brightness=3; portalLight.Parent=portalGlow
        V.label(portalGlow,'HAUNT CHAMBER\nAFK PORTAL',Color3.fromRGB(131,255,225),210,60)
        W.ChamberPortal=portalGlow
    end
    local orbAmber=Color3.fromRGB(255,197,111)
    if Assets.configured('RebirthAltar') then
        local altar=Assets.place('RebirthAltar',root,CFrame.new(42,-0.5,30),{Accent=Color3.fromRGB(169,93,246)})
        W.RebirthAltar=altar:FindFirstChild('RebirthAltar_Collision',true) or altar:FindFirstChildWhichIsA('BasePart',true)
        local orb=altar:FindFirstChild('RebirthAltar_Glow',true)
        if orb then
            orb.Color=orbAmber
            local altarLight=Instance.new('PointLight'); altarLight.Color=orbAmber; altarLight.Range=18; altarLight.Brightness=2; altarLight.Parent=orb
        end
        V.label(W.RebirthAltar,'REBIRTH ALTAR\nPermanent bonus',orbAmber,190,55).Parent.StudsOffset=Vector3.new(0,6,0)
        W.RebirthAltarPrompt=prompt(W.RebirthAltar,'View rebirth','Altar')
    else
        local altarBase=part(root,'RebirthAltarBase',Vector3.new(12,2,12),Vector3.new(42,1,30),Color3.fromRGB(62,45,81),Enum.Material.Marble)
        altarBase.Shape=Enum.PartType.Cylinder; altarBase.CFrame=CFrame.new(42,1,30)*CFrame.Angles(0,0,math.pi/2)
        W.RebirthAltar=part(root,'RebirthAltar',Vector3.new(4,5,4),Vector3.new(42,4,30),Color3.fromRGB(169,93,246),Enum.Material.Neon)
        W.RebirthAltar.Shape=Enum.PartType.Cylinder; W.RebirthAltar.CFrame=CFrame.new(42,4,30)*CFrame.Angles(0,0,math.pi/2)
        local altarOrb=part(root,'RebirthOrb',Vector3.new(2.2,2.2,2.2),Vector3.new(42,8,30),orbAmber,Enum.Material.Neon); altarOrb.Shape=Enum.PartType.Ball
        local altarLight=Instance.new('PointLight'); altarLight.Color=orbAmber; altarLight.Range=18; altarLight.Brightness=2; altarLight.Parent=altarOrb
        V.label(W.RebirthAltar,'REBIRTH ALTAR\nPermanent bonus',orbAmber,190,55)
        W.RebirthAltarPrompt=prompt(altarOrb,'View rebirth','Altar')
    end
    W.ChamberPortalPrompt=prompt(W.ChamberPortal,'Enter chamber','AFK hunting')
    task.spawn(function()
        while root.Parent do
            local t=os.clock()
            if portalGlow and portalHome then
                portalGlow.CFrame=portalHome*CFrame.new(0,math.sin(t*2)*0.25,0)*CFrame.Angles(0,math.sin(t)*0.05,0)
            end
            if portalLight then portalLight.Brightness=2.4+math.sin(t*3)*0.6 end
            task.wait(0.05)
        end
    end)
    task.spawn(function()
        while root.Parent do
            task.wait(4)
            local area=W.Areas[rng:NextInteger(1,6)]
            local l=area.Lights[1]
            if l.Enabled then l.Brightness=0.15; task.wait(0.12); l.Brightness=0.9 end
        end
    end)
    local parts,meshes,lights=0,0,0
    for _,item in root:GetDescendants() do
        if item:IsA('MeshPart') then meshes+=1 elseif item:IsA('BasePart') then parts+=1 end
        if item:IsA('Light') then lights+=1 end
    end
    print(string.format('World.build %.3fs excluding preload: %d primitive parts, %d MeshParts, %d lights including interiors',os.clock()-buildStarted,parts,meshes,lights))
    return W
end
return W

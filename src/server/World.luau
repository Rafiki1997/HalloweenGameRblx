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
            local light=Instance.new('PointLight'); light.Color=warm; light.Brightness=2.8; light.Range=30; light.Parent=glow
        end
        return
    end
    part(parent,'LampPost',Vector3.new(0.4,7,0.4),pos+Vector3.new(0,3.5,0))
    local glow=part(parent,'Lantern',Vector3.new(1,1.6,1),pos+Vector3.new(0,7.5,0),warm,Enum.Material.Neon)
    local light=Instance.new('PointLight'); light.Color=warm; light.Brightness=2.8; light.Range=30; light.Parent=glow
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
    for _,name in {'StreetLamp','Gravestone','PineTree','DeadTree','Pumpkin','GhostFountain','ChamberPortal','RebirthAltar','NoticeBoard','WelcomeSign','HauntShowcase','MansionHill','MansionFacade','Boulder',
        'ShopHouse','Caretaker','MarketStall','OakCask','Crate','GraveyardFence','Crypt','GravestoneCross','GravestoneObelisk'} do
        if Assets.configured(name) then table.insert(loadNames,name) end
    end
    Assets.preload(loadNames)
    local buildStarted=os.clock()
    local root=Instance.new('Folder'); root.Name='GhostlightWorld'; root.Parent=workspace; W.Root=root
    local lighting=game:GetService('Lighting')
    -- Future lighting is much darker than Voxel at the same numbers: moonlit ambient, exposure and environment lighting are raised.
    lighting.ClockTime=0.5; lighting.Brightness=2.8; lighting.Ambient=Color3.fromRGB(96,90,146); lighting.OutdoorAmbient=Color3.fromRGB(140,146,200)
    lighting.GlobalShadows=true; lighting.FogColor=Color3.fromRGB(52,50,90); lighting.FogStart=200; lighting.FogEnd=700
    lighting.EnvironmentDiffuseScale=0.9; lighting.EnvironmentSpecularScale=0.7; lighting.ShadowSoftness=0.25; lighting.ExposureCompensation=1.0
    local atm=Instance.new('Atmosphere'); atm.Density=0.2; atm.Offset=0.25; atm.Haze=1.0; atm.Glare=0.2
    atm.Color=Color3.fromRGB(112,116,165); atm.Decay=Color3.fromRGB(65,48,94); atm.Parent=lighting
    local bloom=Instance.new('BloomEffect'); bloom.Intensity=0.26; bloom.Size=26; bloom.Threshold=1.6; bloom.Parent=lighting
    local grade=Instance.new('ColorCorrectionEffect'); grade.Brightness=0.06; grade.Contrast=0.08; grade.Saturation=0.06; grade.TintColor=Color3.fromRGB(230,228,255); grade.Parent=lighting
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
    local hauntHues={Color3.fromRGB(166,103,246),Color3.fromRGB(70,130,255),Color3.fromRGB(80,220,140),Color3.fromRGB(255,85,85),
        Color3.fromRGB(80,205,255),Color3.fromRGB(240,90,220),Color3.fromRGB(255,140,60)}
    local meshHaunts=Assets.configured('HauntShowcase')
    for i=1,8 do
        if i==5 then continue end
        plotNumber+=1
        local angle=math.rad(20+(i-1)*40)
        local center=Vector3.new(math.sin(angle)*116,0,math.cos(angle)*116)
        local model=Instance.new('Model'); model.Name='Haunt'..i; model.Parent=root
        local cf=CFrame.lookAt(center,Vector3.new(0,0,0))
        local function p(name,size,offset,color,mat) return V.part(model,name,size,cf*CFrame.new(offset),color or wood,mat) end
        local label,incomeLabel,deposit,chamber,spireOffset
        local slots={}
        if meshHaunts then
            -- Visuals come from the HauntShowcase mesh. Collision, slot pads and label anchors stay primitives so the
            -- gate opening, pedestal tops and the server's plot contract never depend on Roblox's collision approximation.
            -- The mesh base sits on the ground top (y -0.5); its yard plinth top is therefore y 0.5.
            Assets.place('HauntShowcase',model,cf*CFrame.new(0,-0.5,0),{Accent=hauntHues[plotNumber]})
            local function blocker(name,size,offset)
                local b=p(name,size,offset,stone); b.Transparency=1; b.CanQuery=false; return b
            end
            blocker('PlinthCollision',Vector3.new(46,1,40),Vector3.new(0,0,0))
            blocker('HouseCollision',Vector3.new(31.4,17.5,9.8),Vector3.new(0,9.25,15.6))
            for _,s in {-1,1} do
                blocker('SideFence',Vector3.new(0.6,3.4,40),Vector3.new(s*23,2.2,0))
                blocker('FrontFence',Vector3.new(18.6,3.4,0.6),Vector3.new(s*13.7,2.2,-20))
                blocker('GatePost',Vector3.new(1.4,4.2,1.4),Vector3.new(s*3.6,2.6,-20))
                blocker('SideHedge',Vector3.new(1.9,2.2,26),Vector3.new(s*21.5,1.6,-6))
                blocker('FrontHedge',Vector3.new(17.4,2.0,1.8),Vector3.new(s*13.2,1.5,-18.5))
            end
            local anchor=p('OwnerBoard',Vector3.new(0.5,0.5,0.5),Vector3.new(0,12.5,10.4))
            anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false
            label=V.label(anchor,'UNCLAIMED HAUNT',purple,290,100)
            local hologram=p('IncomeHologram',Vector3.new(0.5,0.5,0.5),Vector3.new(0,9,2),Color3.fromRGB(131,255,225),Enum.Material.Neon)
            hologram.Transparency=1; hologram.CanCollide=false; hologram.CanQuery=false
            incomeLabel=V.label(hologram,'$/SEC • $0',Color3.fromRGB(131,255,225),210,48)
            deposit=p('Deposit',Vector3.new(5,0.4,5),Vector3.new(-11,0.7,-12),Color3.fromRGB(82,219,190),Enum.Material.Neon)
            V.label(deposit,'DEPOSIT\nCaptured ghosts',Color3.fromRGB(153,255,223),140,45)
            chamber=p('ChamberDoor',Vector3.new(5,7,0.5),Vector3.new(11,4.5,14),purple,Enum.Material.Neon)
            chamber.Transparency=1; chamber.CanCollide=false; chamber.CanQuery=false
            for j=1,20 do
                local x=((j-1)%5-2)*6
                local z=math.floor((j-1)/5)*5-5
                blocker('Pedestal'..j,Vector3.new(3.2,1.2,3.2),Vector3.new(x,1.1,z))
                -- The pad is the server's slot part: it recolours and dims it, and hangs the display ghost 2.3 studs above it.
                local pad=p('Slot'..j,Vector3.new(3.6,0.3,3.6),Vector3.new(x,1.99,z),Color3.fromRGB(70,53,98))
                table.insert(slots,pad)
            end
            -- Estate spires stand on the roof ridge instead of the yard edge, which the fence now occupies.
            spireOffset=function(s,k) return CFrame.new(s*(5+2.2*k),19+0.5*k,15.5) end
        else
            p('Foundation',Vector3.new(46,1,40),Vector3.new(0,0.5,0),stone,Enum.Material.Cobblestone)
            p('BackWall',Vector3.new(46,13,1),Vector3.new(0,7,19))
            for _,s in {-1,1} do
                p('SideWall',Vector3.new(1,13,40),Vector3.new(s*23,7,0))
                p('FrontPillar',Vector3.new(2,13,2),Vector3.new(s*21,7,-19))
                p('Roof',Vector3.new(24,1.5,42),Vector3.new(s*10,15.2,0),Color3.fromRGB(39,30,57)).CFrame=cf*CFrame.new(s*10,15.2,0)*CFrame.Angles(0,0,s*math.rad(-18))
            end
            local board=p('OwnerBoard',Vector3.new(18,3,1),Vector3.new(0,12,-16),Color3.fromRGB(24,19,37))
            label=V.label(board,'UNCLAIMED HAUNT',purple,290,100)
            local hologram=p('IncomeHologram',Vector3.new(0.5,0.5,0.5),Vector3.new(0,10,2),Color3.fromRGB(131,255,225),Enum.Material.Neon)
            hologram.Transparency=1
            incomeLabel=V.label(hologram,'$/SEC • $0',Color3.fromRGB(131,255,225),210,48)
            deposit=p('Deposit',Vector3.new(5,0.4,5),Vector3.new(-11,1.2,-10),Color3.fromRGB(82,219,190),Enum.Material.Neon)
            V.label(deposit,'DEPOSIT\nCaptured ghosts',Color3.fromRGB(153,255,223),140,45)
            chamber=p('ChamberDoor',Vector3.new(5,7,0.5),Vector3.new(11,4.5,14),purple,Enum.Material.Neon)
            V.label(chamber,'HAUNT CHAMBER',purple,170,45)
            chamber.Transparency=1; chamber.CanCollide=false
            local chamberGui=chamber:FindFirstChild('Label'); if chamberGui then chamberGui.Enabled=false end
            for j=1,20 do
                local x=((j-1)%5-2)*6
                local z=math.floor((j-1)/5)*5-5
                local pad=p('Slot'..j,Vector3.new(4,0.4,4),Vector3.new(x,1.2,z),Color3.fromRGB(70,53,98))
                table.insert(slots,pad)
            end
        end
        W.Plots[plotNumber]={Model=model,CF=cf,Slots=slots,Label=label,IncomeLabel=incomeLabel,Deposit=deposit,ChamberDoor=chamber,SpireOffset=spireOffset,Owner=nil,Displays={}}
        path(root,Vector3.new(center.X,0.1,center.Z)*0.26,center,12)
        local plinthTop=if meshHaunts then 0.5 else 1
        lamp(root,(cf*CFrame.new(-19,plinthTop,-15)).Position)
        lamp(root,(cf*CFrame.new(19,plinthTop,-15)).Position)
    end
    -- Landmark exterior. Hunting wings are separated so access remains personal and server-validated.
    if Assets.configured('MansionHill') and Assets.configured('MansionFacade') then
        -- Hill mesh: front edge at z -130, lower terrace top y 1.4, stair and flank slopes from z -144 to -157, upper terrace
        -- top y 11.8 to z -200. Walkable collision is primitive so the climb never depends on mesh collision fidelity.
        path(root,Vector3.new(0,0.2,-30),Vector3.new(0,0.2,-129),18)
        for z=-45,-120,-25 do lamp(root,Vector3.new(-13,-0.5,z)); lamp(root,Vector3.new(13,-0.5,z)) end
        Assets.place('MansionHill',root,CFrame.new(0,-0.5,-165))
        local function blocker(name,size,cf)
            local b=V.part(root,name,size,cf,stone); b.Transparency=1; b.CanQuery=false; return b
        end
        local function slope(name,width,x)
            local wedge=Instance.new('WedgePart'); wedge.Name=name; wedge.Size=Vector3.new(width,10.4,13)
            -- A WedgePart is tall at its back (+Z); the hill rises toward -Z, so turn it around.
            wedge.CFrame=CFrame.new(x,6.6,-150.5)*CFrame.Angles(0,math.pi,0)
            wedge.Anchored=true; wedge.Transparency=1; wedge.CanQuery=false; wedge.Parent=root
        end
        blocker('LowerTerrace',Vector3.new(90,1.9,14),CFrame.new(0,0.45,-137))
        blocker('UpperTerrace',Vector3.new(90,12.3,43),CFrame.new(0,5.65,-178.5))
        slope('HillSlopeLeft',33,-28.5); slope('HillSlopeRight',33,28.5); slope('StairSlope',24,0)
        for _,x in {-16,16} do lamp(root,Vector3.new(x,1.4,-136)); lamp(root,Vector3.new(x,11.8,-160)) end
        -- Facade mesh: its bounding box (porch railing to tower cornice) is centred 2.8 studs in front of the block centre,
        -- so z -183 puts the block at -172.8..-198.8 on the terrace and the porch columns at -167.3.
        Assets.place('MansionFacade',root,CFrame.new(0,11.8,-183),{Accent=purple})
        blocker('FacadeCollision',Vector3.new(124,50,26),CFrame.new(0,36.8,-185.8))
        for _,x in {-11,-5,5,11} do blocker('PorchColumn',Vector3.new(2.2,12.6,2.2),CFrame.new(x,18.1,-167.3)) end
        W.MansionDoor=V.part(root,'MansionEntrance',Vector3.new(10,14,1),CFrame.new(0,18.8,-172.5),purple,Enum.Material.Neon)
        W.MansionDoor.Transparency=1; W.MansionDoor.CanQuery=false
        V.label(W.MansionDoor,'THE HAUNTED MANSION\nEnter • Hunt • Return',purple,240,65).Parent.StudsOffset=Vector3.new(0,10,0)
        if Assets.configured('Boulder') then
            for _,b in {{-50,-0.5,-140},{52,-0.5,-134},{-53,-0.5,-176},{55,-0.5,-192},{-60,-0.5,-120}} do
                Assets.place('Boulder',root,CFrame.new(b[1],b[2],b[3]))
            end
        end
    else
        path(root,Vector3.new(0,0.2,-30),Vector3.new(0,0.2,-180),18)
        for z=-45,-170,-25 do lamp(root,Vector3.new(-13,-0.5,z)); lamp(root,Vector3.new(13,-0.5,z)) end
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
    end
    -- Asset meshes face Roblox +Z (their Blender -Y front). Yaw +90 degrees turns that front toward +X.
    local faceEast=CFrame.Angles(0,math.pi/2,0)
    local faceWest=CFrame.Angles(0,-math.pi/2,0)
    local function anchor(name,cf)
        local a=V.part(root,name,Vector3.new(0.5,0.5,0.5),cf,stone); a.Transparency=1; a.CanCollide=false; a.CanQuery=false; return a
    end
    local function blocker(name,size,cf)
        local b=V.part(root,name,size,cf,stone); b.Transparency=1; b.CanQuery=false; return b
    end
    if Assets.configured('ShopHouse') then
        -- Shop row on the west side, fronts toward the plaza, north of the path to the eighth Haunt.
        -- The mesh bounding box is centred 1.1 studs in front of the building block (hanging sign and lantern).
        local shops={{z=48,name='THE WORKSHOP\nVacuum & Haunt Upgrades'},{z=71,name='THE HOLLOW INN\nRooms for the restless'},{z=94,name='CURIOSITIES\nOddments & charms'}}
        for k,shop in shops do
            Assets.place('ShopHouse',root,CFrame.new(-52,-0.5,shop.z)*faceEast,{Accent=warm})
            blocker('ShopCollision'..k,Vector3.new(17.6,19,22),CFrame.new(-52.7,9,shop.z))
            local board=anchor('ShopSign'..k,CFrame.new(-42.7,7.4,shop.z+4.2))
            V.label(board,shop.name,warm,220,60).Parent.StudsOffset=Vector3.new(0,1.6,0)
            if k==1 then
                W.Upgrades=V.part(root,'WorkshopDoor',Vector3.new(0.6,5,3.2),CFrame.new(-44.6,2.8,shop.z+4.2),warm,Enum.Material.Neon)
                W.Upgrades.Transparency=1; W.Upgrades.CanQuery=false
            end
        end
        for _,z in {62,84} do
            if Assets.configured('MarketStall') then Assets.place('MarketStall',root,CFrame.new(-38,-0.5,z)*faceEast,{Accent=Color3.fromRGB(255,140,60)}) end
            blocker('StallCollision',Vector3.new(4.4,2.6,8),CFrame.new(-38,0.8,z))
        end
        if Assets.configured('OakCask') then for _,z in {56,68.5,100} do Assets.place('OakCask',root,CFrame.new(-41.5,-0.5,z)) end end
        if Assets.configured('Crate') then for _,c in {{-41.5,-0.5,90},{-39.6,-0.5,91.9},{-41.5,1.3,90}} do Assets.place('Crate',root,CFrame.new(c[1],c[2],c[3])) end end
        if Assets.configured('Pumpkin') then for _,c in {{-35.5,-0.5,58},{-35.2,-0.5,66.5},{-35.6,-0.5,80}} do Assets.place('Pumpkin',root,CFrame.new(c[1],c[2],c[3])) end end
    else
        W.Upgrades=sign(root,Vector3.new(-42,4,30),'THE WORKSHOP\nVacuum & Haunt Upgrades',warm)
    end
    -- The legacy REBIRTH ALTAR sign is gone; it overlapped the altar built further down.
    if Assets.configured('NoticeBoard') then
        local board=Assets.place('NoticeBoard',root,CFrame.new(0,-0.5,62))
        W.Leaderboard=board:FindFirstChild('NoticeBoard_Collision',true) or board:FindFirstChildWhichIsA('BasePart',true)
        V.label(W.Leaderboard,'HOLLOW HUNTERS',warm,240,65).Parent.StudsOffset=Vector3.new(0,0.8,0)
    else
        W.Leaderboard=sign(root,Vector3.new(0,5,62),'HOLLOW HUNTERS',warm)
    end
    W.Leaderboard.Label.Size=UDim2.fromOffset(330,170)
    if Assets.configured('Caretaker') then
        for _,npc in {{x=-40,z=50,cf=faceEast,text='MIRA • EQUIPMENT'},{x=47,z=36,cf=faceWest,text='ORIN • REBIRTH'}} do
            Assets.place('Caretaker',root,CFrame.new(npc.x,-0.5,npc.z)*npc.cf,{Accent=warm})
            blocker('CaretakerCollision',Vector3.new(2.2,5,2.2),CFrame.new(npc.x,2,npc.z))
            V.label(anchor('CaretakerName',CFrame.new(npc.x,5.2,npc.z)),npc.text,warm,180,45)
        end
    else
        for _,x in {-47,47} do
            local npc=part(root,'Caretaker',Vector3.new(2,3,1),Vector3.new(x,2,36),Color3.fromRGB(63,45,84))
            local head=part(root,'CaretakerHead',Vector3.new(1.5,1.5,1.5),Vector3.new(x,4.3,36),warm); head.Shape=Enum.PartType.Ball
            V.label(npc,if x<0 then 'MIRA • EQUIPMENT' else 'ORIN • REBIRTH',warm,180,45)
        end
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
    if Assets.configured('GraveyardFence') then
        -- Fenced lot 50 (x) by 70 (z) centred at (150,105); the gate faces west toward the plaza.
        Assets.place('GraveyardFence',root,CFrame.new(150,-0.5,105)*faceWest,{Accent=Color3.fromRGB(80,220,140)})
        blocker('GraveFenceW1',Vector3.new(0.6,3.4,30.5),CFrame.new(125,1.2,85.25))
        blocker('GraveFenceW2',Vector3.new(0.6,3.4,30.5),CFrame.new(125,1.2,124.75))
        blocker('GraveFenceE',Vector3.new(0.6,3.4,70),CFrame.new(175,1.2,105))
        blocker('GraveFenceN',Vector3.new(50,3.4,0.6),CFrame.new(150,1.2,70))
        blocker('GraveFenceS',Vector3.new(50,3.4,0.6),CFrame.new(150,1.2,140))
        for _,z in {100.5,109.5} do blocker('GraveGatePost',Vector3.new(1.6,5.2,1.6),CFrame.new(125,2.1,z)) end
        local shapes={'Gravestone','GravestoneCross','GravestoneObelisk'}
        local k=0
        for _,z in {88,106,124} do
            for x=137,167,6 do
                k+=1
                local shape=shapes[(k%3)+1]
                if Assets.configured(shape) then Assets.place(shape,root,CFrame.new(x,-0.5,z)*faceWest) end
            end
        end
        if Assets.configured('Crypt') then
            for _,z in {80,130} do
                Assets.place('Crypt',root,CFrame.new(168,-0.5,z)*faceWest)
                blocker('CryptCollision',Vector3.new(10.5,6,8.5),CFrame.new(168,2.5,z))
            end
        end
        if Assets.configured('DeadTree') then
            for _,c in {{140,78},{161,76},{140,134},{158,136}} do Assets.place('DeadTree',root,CFrame.new(c[1],-0.5,c[2])) end
        end
        for _,m in {{146,0.2,90,44,26},{156,0.3,120,36,28},{136,0.25,108,20,18}} do
            local mist=part(root,'GraveMist',Vector3.new(m[4],0.25,m[5]),Vector3.new(m[1],m[2],m[3]),Color3.fromRGB(150,160,180),Enum.Material.SmoothPlastic)
            mist.Transparency=0.85; mist.CanCollide=false; mist.CanQuery=false; mist.CastShadow=false
        end
        for _,x in {128,133} do
            local l=Instance.new('PointLight'); l.Color=Color3.fromRGB(120,220,160); l.Range=14; l.Brightness=0.6
            l.Parent=anchor('GraveLight',CFrame.new(x,4,x==128 and 100 or 110))
        end
        sign(root,Vector3.new(122,4,113),'THE QUIET GARDEN',Color3.fromRGB(170,187,206))
    else
        for i=1,15 do
            local pos=Vector3.new(130+(i%5)*7,1.4,100+math.floor(i/5)*9)
            if Assets.configured('Gravestone') then
                Assets.place('Gravestone',root,CFrame.new(pos.X,-.5,pos.Z))
            else
                part(root,'Gravestone',Vector3.new(3,4,1),pos,Color3.fromRGB(86,86,102))
            end
        end
        sign(root,Vector3.new(146,3,93),'THE QUIET GARDEN',Color3.fromRGB(170,187,206))
    end
    if Assets.configured('Pumpkin') then Assets.place('Pumpkin',root,CFrame.new(47,-0.5,26)) end
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

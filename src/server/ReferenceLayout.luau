-- Explicit landmark composition measured from assets/reference/spawn-town.png.
local Layout={}
Layout.Plots={
    {-160,15,-105,165},{-70,10,-85,180},{80,17,-100,190},
    {160,12,-50,205},{140,4,60,205},{-48,0,90,170},{-115,30,-185,150},
}
local amber=Color3.fromRGB(255,170,67)
local slate=Color3.fromRGB(62,53,75)
local cobble=Color3.fromRGB(105,87,88)

function Layout.build(root,W,Assets,V,Landscape)
    -- Legacy straight spokes are replaced by the reference's continuous winding paths.
    for _,p in root:GetDescendants() do
        if p.Name=='Path' or p.Name=='PathEdging' then p:Destroy() end
    end
    local garden=Instance.new('Folder'); garden.Name='ReferencePathsAndGardens'; garden.Parent=root
    local terrainQuery=RaycastParams.new(); terrainQuery.FilterType=Enum.RaycastFilterType.Include
    terrainQuery.FilterDescendantsInstances={workspace.Terrain}; terrainQuery.IgnoreWater=true
    local function p(name,size,cf,color,material)
        return V.part(garden,name,size,cf,color or slate,material or Enum.Material.Slate)
    end
    local function lamp(pos)
        local model=Assets.place('StreetLamp',garden,CFrame.new(pos))
        local glow=model:FindFirstChild('StreetLamp_Glow',true)
        if glow then
            glow.Color=amber
            local light=Instance.new('PointLight'); light.Color=amber; light.Range=19; light.Brightness=1.5; light.Parent=glow
        end
        -- A faint baked pool keeps the lantern's warm grounding visible beyond dynamic-light culling distance.
        local pool=p('LanternLightPool',Vector3.new(23,.04,23),CFrame.new(pos+Vector3.new(0,1.32,0)),amber)
        pool.Transparency=1; pool.CanCollide=false; pool.CanQuery=false; pool.CastShadow=false
        local surface=Instance.new('SurfaceGui'); surface.Face=Enum.NormalId.Top; surface.CanvasSize=Vector2.new(64,64); surface.LightInfluence=0; surface.Parent=pool
        local halo=Instance.new('ImageLabel'); halo.BackgroundTransparency=1; halo.Size=UDim2.fromScale(1,1)
        halo.Image='rbxasset://textures/particles/smoke_main.dds'; halo.ImageColor3=Color3.fromRGB(255,153,54); halo.ImageTransparency=.64; halo.Parent=surface
    end
    local function route(nodes,width,lit)
        local distance=0
        for j=1,#nodes-1 do
            local a,b=nodes[j],nodes[j+1]
            local count=math.max(1,math.ceil((b-a).Magnitude/3))
            for k=1,count do
                local u,v=a:Lerp(b,(k-1)/count),a:Lerp(b,k/count)
                local function surfaceHeight(x,z)
                    local hit=workspace:Raycast(Vector3.new(x,100,z),Vector3.new(0,-220,0),terrainQuery)
                    return math.max(Landscape.height(x,z),hit and hit.Position.Y or -100)+1
                end
                local au=Vector3.new(u.X,surfaceHeight(u.X,u.Z),u.Z)
                local bv=Vector3.new(v.X,surfaceHeight(v.X,v.Z),v.Z)
                local length=(bv-au).Magnitude
                local cf=CFrame.lookAt((au+bv)/2,bv)
                local clearance=0
                for _,fraction in {-.5,-.25,0,.25,.5} do
                    local sample=(cf*CFrame.new(0,0,(length+.2)*fraction)).Position
                    local hit=workspace:Raycast(Vector3.new(sample.X,100,sample.Z),Vector3.new(0,-220,0),terrainQuery)
                    if hit then clearance=math.max(clearance,hit.Position.Y+.7-sample.Y) end
                end
                cf+=Vector3.new(0,clearance,0)
                local tile=p('ReferenceWalkway',Vector3.new(width,1,length+0.2),cf,cobble,Enum.Material.Cobblestone)
                tile.Color=cobble:Lerp(Color3.fromRGB(144,112,93),lit and .1+.1*math.cos(distance*.22) or .05)
                tile:SetAttribute('ReferencePath',true)
                for _,side in {-1,1} do
                    local curb=p('StoneCurb',Vector3.new(.7,.6,length+.2),cf*CFrame.new(side*(width/2+.25),.4,0))
                    curb.CanCollide=false
                end
                distance+=length
                if lit and distance>23 then
                    distance=0
                    for _,side in {-1,1} do
                        local at=(cf*CFrame.new(side*(width/2+2.4),0,0)).Position
                        lamp(Vector3.new(at.X,Landscape.height(at.X,at.Z),at.Z))
                    end
                end
            end
        end
    end
    local function nodes(coords)
        local out={}
        for _,v in coords do table.insert(out,Vector3.new(v[1],0,v[2])) end
        return out
    end
    local function toGate(coords,index)
        local out=nodes(coords)
        local cf=W.Plots[index].CF
        local scale=W.Plots[index].Scale or 1
        table.insert(out,(cf*CFrame.new(0,0,-30*scale)).Position)
        table.insert(out,(cf*CFrame.new(0,0,-19.5*scale)).Position)
        route(out,8,true)
    end
    local ring={}
    for i=0,64 do local a=i*math.pi*2/64; table.insert(ring,Vector3.new(math.sin(a)*45,0,math.cos(a)*45)) end
    route(ring,12,false)
    route(nodes({{0,48},{0,90},{5,130},{0,165},{0,239}}),16,true)
    route(nodes({{0,-47},{0,-75},{0,-105},{0,-140},{0,-166}}),18,true)
    for z=-90,-164,-2 do
        local h=Landscape.height(0,z)
        p('MansionAvenueStair',Vector3.new(18,1.1,2.2),CFrame.new(0,h+.95,z),Color3.fromRGB(114,97,109),Enum.Material.Cobblestone)
        for _,side in {-1,1} do
            local wall=p('AvenueBalustrade',Vector3.new(1,3.2,2.3),CFrame.new(side*12,h+1.4,z),slate)
            if z%6==0 then p('AvenueStonePier',Vector3.new(2,4.4,2),wall.CFrame*CFrame.new(0,.6,0),Color3.fromRGB(91,78,103)) end
        end
    end
    toGate({{-34,-29},{-51,-44},{-70,-54}},2)
    toGate({{-70,-54},{-105,-53},{-137,-63}},1)
    toGate({{32,-31},{52,-43},{72,-62}},3)
    toGate({{52,-43},{93,-18},{132,-5}},4)
    toGate({{43,12},{65,28},{87,54},{115,95}},5)
    toGate({{-26,39},{-20,68},{-25,120}},6)
    route(nodes({{-14,75},{-23,111},{-58,130},{-91,143},{-129,142},{-161,126}}),12,true)
    route(nodes({{10,125},{45,113},{75,112},{105,135}}),10,true)
    route(nodes({{-43,14},{-55,29},{-61,58},{-78,77},{-103,87},{-126,102}}),9,true)
    toGate({{-137,-63},{-205,-75},{-216,-130},{-205,-155}},7)
    -- Garden islands break up the circular plaza; four openings align with its approaches.
    for i=0,47 do
        local a=i*math.pi*2/48
        if i%12<2 or i%12>9 then continue end
        local cf=CFrame.new(math.sin(a)*32,.9,math.cos(a)*32)*CFrame.Angles(0,a,0)
        p('GardenBorder',Vector3.new(4.3,1.5,6.5),cf,slate)
        p('GardenBed',Vector3.new(4.1,1.4,5.6),cf*CFrame.new(0,.5,0),Color3.fromRGB(30,51,36),Enum.Material.Grass)
        if i%3==0 then
            local shrub=p('ClippedHedge',Vector3.new(4,3.1,4),cf*CFrame.new(0,1.6,0),Color3.fromRGB(23,64,43),Enum.Material.Grass)
            shrub.Shape=Enum.PartType.Ball
        end
    end
    for i=0,7 do
        local a=(i+.5)*math.pi/4
        lamp(Vector3.new(math.sin(a)*53,-.5,math.cos(a)*53))
        if i%2==0 then
            local cf=CFrame.new(math.sin(a)*36,0,math.cos(a)*36)*CFrame.Angles(0,a,0)
            for _,x in {-3,3} do p('BenchLeg',Vector3.new(.6,2,.6),cf*CFrame.new(x,1,0)) end
            p('BenchSeat',Vector3.new(8,.5,2),cf*CFrame.new(0,2,0),Color3.fromRGB(76,45,38),Enum.Material.WoodPlanks)
            p('BenchBack',Vector3.new(8,2,.45),cf*CFrame.new(0,3,1),Color3.fromRGB(76,45,38),Enum.Material.WoodPlanks)
        end
    end
    -- Keep interactable object references while moving the old shop row into the southwest village.
    local town=root:FindFirstChild('SpookyTown')
    for _,part in town:GetDescendants() do if part:IsA('BasePart') then part.CFrame+=Vector3.new(-65,0,58) end end
    for i,spot in {{-73,163,0},{-104,179,15},{-142,173,-20},{-162,139,80},{-77,117,190},{-143,105,150}} do
        local cf=CFrame.new(spot[1],-.5,spot[2])*CFrame.Angles(0,math.rad(spot[3]),0)
        local model=Assets.place('ShopHouse',town,cf,{Accent=amber})
        local block=V.part(town,'VillageHouseCollision',Vector3.new(20,17,15),cf*CFrame.new(0,8.5,-1),slate)
        block.Transparency=1
        local glow=model:FindFirstChild('ShopHouse_Glow',true)
        if glow then local light=Instance.new('PointLight'); light.Color=amber; light.Brightness=1.9; light.Range=24; light.Parent=glow end
        lamp(Vector3.new(spot[1]+11,-.5,spot[2]+6))
    end
    local square=p('VillageSquare',Vector3.new(52,1,43),CFrame.new(-100,0,145),cobble,Enum.Material.Cobblestone)
    square.Parent=town
    for _,pos in {{-83,138},{-121,152},{-114,123},{-81,156}} do
        Assets.place('MarketStall',town,CFrame.new(pos[1],.5,pos[2])*CFrame.Angles(0,math.rad(90),0),{Accent=amber})
    end
    -- The decorative chamber portal belongs beside the plaza, leaving the main south avenue clear.
    local portal=root:FindFirstChild('ChamberPortal')
    if portal and portal:IsA('Model') then
        for _,part in portal:GetDescendants() do if part:IsA('BasePart') then part.CFrame+=Vector3.new(58,0,15) end end
    end
    local board=root:FindFirstChild('NoticeBoard')
    if board then for _,part in board:GetDescendants() do if part:IsA('BasePart') then part.CFrame+=Vector3.new(-83,0,64) end end end
    for _,part in root:GetChildren() do
        if part.Name=='Caretaker' or part.Name=='CaretakerCollision' or part.Name=='CaretakerName' then
            local parts=if part:IsA('Model') then part:GetDescendants() else {part}
            for _,q in parts do if q:IsA('BasePart') and q.Position.X<0 then q.CFrame+=Vector3.new(-65,0,58) end end
        end
    end
    -- Star-shaped fountain beams give the central spirit the same blue focal glow as the reference.
    local fountain=root:FindFirstChild('GhostFountain')
    if fountain then
        local glow=fountain:FindFirstChild('GhostFountain_Accent',true)
        if glow then glow.Transparency=1 end
        for _,step in {{32,.8,1},{29,1.3,1.7},{25,1.1,2.7}} do
            local rim=p('FountainStoneStep',Vector3.new(step[2],step[1],step[1]),CFrame.new(0,step[3],0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(70,88,122),Enum.Material.Marble)
            rim.Shape=Enum.PartType.Cylinder
        end
        local water=p('SpiritFountainWater',Vector3.new(.16,23,23),CFrame.new(0,3.35,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(29,137,217),Enum.Material.Neon)
        water.Shape=Enum.PartType.Cylinder; water.CanCollide=false; water.Transparency=.22
        for i=0,23 do
            local a=i*math.pi/12
            p('FountainCarvedRim',Vector3.new(3.4,1.7,1.4),CFrame.new(math.sin(a)*12.6,3.6,math.cos(a)*12.6)*CFrame.Angles(0,a,0),Color3.fromRGB(104,116,147),Enum.Material.Marble)
        end
        local spirit=V.ghost('little_boo',fountain,CFrame.new(0,26,0)*CFrame.Angles(0,math.pi,0),6,false)
        spirit.Name='PlazaGuardianSpirit'
        for _,mesh in spirit:GetDescendants() do
            if mesh:IsA('BasePart') and mesh.Name:match('Pearlescent') then
                mesh.Color=Color3.fromRGB(24,100,195); mesh.Material=Enum.Material.Neon
            end
        end
        local spiritLight=Instance.new('PointLight'); spiritLight.Color=Color3.fromRGB(68,178,255); spiritLight.Range=46; spiritLight.Brightness=3; spiritLight.Parent=spirit.PrimaryPart
        for i=0,5 do
            local a=i*math.pi/3
            local from=Vector3.new(math.sin(a)*7,3,math.cos(a)*7)
            local to=Vector3.new(math.sin(a)*2,23,math.cos(a)*2)
            local beam=p('SpiritJet',Vector3.new(.16,.16,(to-from).Magnitude),CFrame.lookAt((from+to)/2,to),Color3.fromRGB(74,185,255),Enum.Material.Neon)
            beam.CanCollide=false
        end
    end
    -- Sky and distant peaks sit behind the mansion, away from all play spaces.
    local oldSky=game:GetService('Lighting'):FindFirstChildOfClass('Sky')
    if oldSky then oldSky:Destroy() end
    local moon=p('BlueHarvestMoon',Vector3.one,CFrame.new(190,95,-300),Color3.fromRGB(125,188,255))
    moon.Transparency=1; moon.CanCollide=false; moon.CanQuery=false
    local disk=Instance.new('BillboardGui'); disk.Name='MoonDisc'; disk.Size=UDim2.fromScale(52,52); disk.LightInfluence=0; disk.Parent=moon
    local lunarImage=Instance.new('ImageLabel'); lunarImage.Size=UDim2.fromScale(1,1); lunarImage.BackgroundTransparency=1
    lunarImage.Image='rbxasset://sky/moon.jpg'; lunarImage.ImageColor3=Color3.fromRGB(126,188,255); lunarImage.Parent=disk
    local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(.5,0); round.Parent=lunarImage
    local function triangle(a,b,c,color)
        local ab,ac,bc=b-a,c-a,c-b
        if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
        elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
        ab,ac,bc=b-a,c-a,c-b
        local right=ac:Cross(ab).Unit; local up=bc:Cross(right).Unit; local back=bc.Unit
        for _,v in {{(a+b)/2,right,back,math.abs(ab:Dot(back))},{(a+c)/2,-right,-back,math.abs(ac:Dot(back))}} do
            if v[4]<.01 then continue end
            local face=Instance.new('WedgePart'); face.Name='MountainRockFace'; face.Anchored=true; face.CanCollide=false; face.CanQuery=false
            face.Size=Vector3.new(.2,math.abs(ab:Dot(up)),v[4]); face.CFrame=CFrame.fromMatrix(v[1],v[2],up,v[3])
            face.Material=Enum.Material.Slate; face.Color=color; face.Parent=garden
        end
    end
    for i=-6,6 do
        local x,z=i*54,-330-math.abs(i)*3
        local summit=Vector3.new(x+math.sin(i)*12,-63+math.abs(i%4)*7,z)
        local vertices={Vector3.new(x-28,-95,z-25),Vector3.new(x+28,-95,z-25),Vector3.new(x+32,-95,z+27),Vector3.new(x-27,-95,z+31)}
        for k=1,4 do triangle(vertices[k],vertices[k%4+1],summit,Color3.fromRGB(11+k*2,18+k*2,31+k*3)) end
    end
    for i=0,35 do
        local a=i*math.pi*2/36
        local reach=(math.abs(math.cos(a))^2.8+math.abs(math.sin(a))^2.8)^(1/2.8)
        local at=Vector3.new(math.cos(a)*270/reach,-12+math.sin(a*3)*12,math.sin(a)*281/reach)
        local anchor=p('CliffMistAnchor',Vector3.one,CFrame.new(at),slate)
        anchor.Transparency=1; anchor.CanCollide=false; anchor.CanQuery=false
        local cloud=Instance.new('BillboardGui'); cloud.Name='ValleyCloud'; cloud.Size=UDim2.fromScale(90,55); cloud.LightInfluence=0; cloud.Parent=anchor
        local vapor=Instance.new('ImageLabel'); vapor.Size=UDim2.fromScale(1,1); vapor.BackgroundTransparency=1
        vapor.Image='rbxasset://textures/particles/smoke_main.dds'; vapor.ImageColor3=Color3.fromRGB(28,47,84); vapor.ImageTransparency=.32; vapor.Rotation=i*41%360; vapor.Parent=cloud
        local mist=Instance.new('ParticleEmitter'); mist.Name='BlueValleyMist'; mist.Texture='rbxasset://textures/particles/smoke_main.dds'
        mist.Color=ColorSequence.new(Color3.fromRGB(33,54,88),Color3.fromRGB(20,34,60)); mist.LightInfluence=0; mist.LightEmission=.2
        mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,26),NumberSequenceKeypoint.new(1,64)})
        mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.55),NumberSequenceKeypoint.new(.75,.72),NumberSequenceKeypoint.new(1,1)})
        mist.Lifetime=NumberRange.new(18,25); mist.Rate=.3; mist.Speed=NumberRange.new(.4,1.2); mist.SpreadAngle=Vector2.new(180,180)
        mist.Rotation=NumberRange.new(0,360); mist.RotSpeed=NumberRange.new(-4,4); mist.Parent=anchor; mist:Emit(5)
    end
end
return Layout

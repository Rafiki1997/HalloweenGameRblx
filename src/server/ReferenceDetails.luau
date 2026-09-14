-- Reference-image environmental set dressing. Positions use the finished town layout.
local Details = {}

function Details.build(root, W, Assets, V, Landscape)
    local folder = Instance.new('Folder')
    folder.Name = 'ReferenceEnvironment'
    folder.Parent = root
    local random = Random.new(3102026)
    local slate = Color3.fromRGB(53, 54, 78)
    local edge = Color3.fromRGB(78, 76, 100)
    local wood = Color3.fromRGB(89, 56, 41)
    local iron = Color3.fromRGB(33, 29, 45)
    local gold = Color3.fromRGB(255, 170, 66)
    local blue = Color3.fromRGB(79, 168, 245)
    local function part(name, size, cf, color, material, parent)
        local p = V.part(parent or folder, name, size, cf, color or slate, material or Enum.Material.Slate)
        p.CanTouch = false
        return p
    end
    local function model(name)
        local m = Instance.new('Model')
        m.Name = name
        m.Parent = folder
        return m
    end
    local function beam(name, a, b, width, color, material, parent)
        return part(name, Vector3.new(width, width, (b-a).Magnitude), CFrame.lookAt((a+b)/2, b), color, material, parent)
    end
    local function ground(x,z)
        return Landscape.height(x,z)
    end
    local function lantern(cf, parent)
        if Assets.configured('StreetLamp') then
            local m = Assets.place('StreetLamp', parent or folder, cf)
            local glow = m:FindFirstChild('StreetLamp_Glow',true)
            if glow then
                local light = Instance.new('PointLight')
                light.Color = gold; light.Brightness = 1.9; light.Range = 21; light.Shadows = true; light.Parent = glow
            end
            return
        end
        part('LanternPost',Vector3.new(.35,6,.35),cf*CFrame.new(0,3,0),iron,Enum.Material.Metal,parent)
        part('LanternFoot',Vector3.new(1.2,.5,1.2),cf*CFrame.new(0,.25,0),slate,nil,parent)
        local glow=part('LanternGlass',Vector3.new(.8,1.3,.8),cf*CFrame.new(0,6.5,0),gold,Enum.Material.Neon,parent)
        part('LanternCap',Vector3.new(1.4,.3,1.4),cf*CFrame.new(0,7.3,0),iron,Enum.Material.Metal,parent)
        local light=Instance.new('PointLight'); light.Color=gold; light.Brightness=1.9; light.Range=21; light.Parent=glow
    end
    -- Docks have separate planks, underwater piles, rope rails and corner lanterns.
    local function dock(name, cf, length, width)
        local m = model(name)
        local count = math.floor(length/1.55)
        for i=0,count-1 do
            part('WeatheredDockPlank',Vector3.new(width,.55,1.42),cf*CFrame.new(0,0,-i*1.55),wood:Lerp(Color3.fromRGB(137,90,54),random:NextNumber(0,.32)),Enum.Material.WoodPlanks,m)
        end
        for _,x in {-width/2+.65,width/2-.65} do
            part('DockStringer',Vector3.new(.65,1,length),cf*CFrame.new(x,-.8,-length/2+1),wood,Enum.Material.Wood,m)
        end
        local stations = {0, -length*.45, -length+2}
        for _,z in stations do
            for _,side in {-1,1} do
                local x=side*(width/2+.3)
                part('DockPile',Vector3.new(.8,10,.8),cf*CFrame.new(x,-1.8,z),wood,Enum.Material.Wood,m)
                part('PileCap',Vector3.new(1.15,.28,1.15),cf*CFrame.new(x,3.3,z),wood,Enum.Material.Wood,m)
                if z~=stations[#stations] then
                    local nextZ=if z==0 then stations[2] else stations[3]
                    beam('SaggingRope',cf:PointToWorldSpace(Vector3.new(x,2.8,z)),cf:PointToWorldSpace(Vector3.new(x,2.3,(z+nextZ)/2)),.12,Color3.fromRGB(152,120,77),Enum.Material.Fabric,m)
                    beam('SaggingRope',cf:PointToWorldSpace(Vector3.new(x,2.3,(z+nextZ)/2)),cf:PointToWorldSpace(Vector3.new(x,2.8,nextZ)),.12,Color3.fromRGB(152,120,77),Enum.Material.Fabric,m)
                end
            end
        end
        lantern(cf*CFrame.new(width/2+1,0,1),m)
        lantern(cf*CFrame.new(-width/2-1,0,-length+2),m)
        if Assets.configured('OakCask') then
            local cask=Assets.place('OakCask',m,cf*CFrame.new(-width*.25,.3,-2))
            cask:ScaleTo(cask:GetScale()*.55)
        end
        return m
    end
    dock('SouthFishingDock',CFrame.new(-148,.2,65),28,8)
    dock('WestFishingDock',CFrame.new(-183,.3,10)*CFrame.Angles(0,-math.pi/2,0),28,7)
    dock('EastFishingDock',CFrame.new(-66,.2,19)*CFrame.Angles(0,math.pi/2,0),24,8)
    -- Open rowboats: pointed bow, rising gunwales, seats, interior ribs and oars.
    local function boat(cf, name)
        local m=model(name)
        local outline={Vector3.new(0,0,-6),Vector3.new(-2.5,0,-3.4),Vector3.new(-2.8,0,2.8),Vector3.new(-1.8,0,5),Vector3.new(1.8,0,5),Vector3.new(2.8,0,2.8),Vector3.new(2.5,0,-3.4)}
        part('BoatFloor',Vector3.new(3.6,.4,8),cf*CFrame.new(0,-.45,.6),wood,Enum.Material.WoodPlanks,m)
        for i,a in outline do
            local b=outline[i%#outline+1]
            local mid=(a+b)/2
            local wall=part('HullPlanking',Vector3.new(.42,1.8,(b-a).Magnitude),CFrame.lookAt(cf:PointToWorldSpace(mid),cf:PointToWorldSpace(b)),wood,Enum.Material.WoodPlanks,m)
            wall.CanCollide=false
            beam('Gunwale',cf:PointToWorldSpace(a+Vector3.new(0,.95,0)),cf:PointToWorldSpace(b+Vector3.new(0,.95,0)),.32,Color3.fromRGB(139,95,58),Enum.Material.Wood,m)
        end
        for _,z in {-2,2.5} do
            part('RowingSeat',Vector3.new(4.9,.35,1),cf*CFrame.new(0,.2,z),wood,Enum.Material.Wood,m)
        end
        beam('Oar',cf:PointToWorldSpace(Vector3.new(-4,.9,-3)),cf:PointToWorldSpace(Vector3.new(4,.9,2)),.19,Color3.fromRGB(156,115,67),Enum.Material.Wood,m)
        part('OarBlade',Vector3.new(.65,.17,2),cf*CFrame.new(-4.2,.9,-3.2)*CFrame.Angles(0,1,0),wood,Enum.Material.Wood,m)
    end
    boat(CFrame.new(-114,-2.6,48)*CFrame.Angles(0,-.7,0),'LakeRowboatAmber')
    boat(CFrame.new(-102,-2.6,5)*CFrame.Angles(0,.55,0),'LakeRowboatMoss')
    boat(CFrame.new(-158,-2.6,-5)*CFrame.Angles(0,1.9,0),'MooredRowboat')
    -- Pads are distributed across the shallows, leaving the middle readable as water.
    for i=1,45 do
        local a=random:NextNumber(0,math.pi*2)
        local r=random:NextNumber(.65,.9)
        local x,z=-122+math.cos(a)*62*r,15+math.sin(a)*59*r
        local pad=part('LilyPad',Vector3.new(.09,random:NextNumber(.6,1.5),random:NextNumber(.6,1.5)),CFrame.new(x,-2.85,z)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(49,91,54),Enum.Material.Grass)
        pad.Shape=Enum.PartType.Cylinder; pad.CanCollide=false
        if i%7==0 then
            local flower=part('WaterLily',Vector3.new(.35,.3,.35),CFrame.new(x,-2.62,z),Color3.fromRGB(160,134,204),Enum.Material.SmoothPlastic)
            flower.Shape=Enum.PartType.Ball; flower.CanCollide=false
        end
    end
    local function waterfall(name, x,z,top,bottom,width,yaw)
        local m=model(name)
        for i=1,9 do
            local dx=(i-5)*width/9
            local h=top-bottom+random:NextNumber(-1,1)
            local stream=part('FallingWater',Vector3.new(width/9+.12,h,.65),CFrame.new(x+dx,bottom+h/2,z+random:NextNumber(-.45,.45)),blue:Lerp(Color3.fromRGB(184,220,255),random:NextNumber(0,.6)),Enum.Material.Glass,m)
            stream.Transparency=random:NextNumber(.28,.48); stream.CanCollide=false; stream.CastShadow=false
            if i%2==0 then
                local foam=part('FoamRibbon',Vector3.new(.12,h,.1),stream.CFrame*CFrame.new(0,0,-.4),Color3.fromRGB(137,203,255),Enum.Material.Neon,m)
                foam.Transparency=.65; foam.CanCollide=false; foam.CastShadow=false
            end
        end
        for i=1,7 do
            local spray=part('WaterfallSpray',Vector3.new(3,1.1,2.6),CFrame.new(x+random:NextNumber(-width*.55,width*.55),bottom+.2,z+random:NextNumber(-2,2)),Color3.fromRGB(143,211,255),Enum.Material.Glass,m)
            spray.Shape=Enum.PartType.Ball; spray.Transparency=.5; spray.CanCollide=false; spray.CastShadow=false
        end
        local glow=part('FallLight',Vector3.one,CFrame.new(x,bottom+2,z-1),blue,Enum.Material.Neon,m)
        glow.Transparency=1; glow.CanCollide=false
        local light=Instance.new('PointLight'); light.Color=blue; light.Range=23; light.Brightness=1.4; light.Parent=glow
        for _,side in {-1,1} do
            part('WaterfallRockShoulder',Vector3.new(7,top-bottom+6,7),CFrame.new(x+side*(width/2+3),bottom+(top-bottom)/2-1,z+2)*CFrame.Angles(0,side*.23,side*.035),slate,Enum.Material.Slate,m)
        end
        if yaw then m:PivotTo(CFrame.new(x,0,z)*CFrame.Angles(0,yaw,0)*CFrame.new(-x,0,-z)*m:GetPivot()) end
    end
    waterfall('NorthLakeCascade',-126,-43,13,-3,12)
    waterfall('EasternIslandCascade',243,65,2,-62,13,math.pi/2)
    -- A gothic gateway frames the entrance without covering the walking route.
    local gateway=model('SouthEntranceGateway')
    local baseY=ground(0,215)
    for _,side in {-1,1} do
        local x=side*21
        for tier=0,3 do
            part('GateStonePier',Vector3.new(6.5-tier*.25,5,6.5-tier*.25),CFrame.new(x,baseY+2.5+tier*5,215),slate:Lerp(edge,tier*.13),Enum.Material.Slate,gateway)
        end
        part('PierCap',Vector3.new(8,1.3,8),CFrame.new(x,baseY+20.5,215),edge,Enum.Material.Slate,gateway)
        local spike=part('PierFinial',Vector3.new(2.6,4,2.6),CFrame.new(x,baseY+23,215),iron,Enum.Material.Metal,gateway)
        spike.Shape=Enum.PartType.Ball
        lantern(CFrame.new(x-side*2,baseY+10,211),gateway)
        for j=1,8 do
            local fx=x+side*(4+j*1.7)
            part('EntranceIronPicket',Vector3.new(.25,8+j%3,.25),CFrame.new(fx,baseY+4.5,215),iron,Enum.Material.Metal,gateway)
        end
        for _,height in {2,6} do
            part('EntranceIronRail',Vector3.new(19,.3,.35),CFrame.new(x+side*11,baseY+height,215),iron,Enum.Material.Metal,gateway)
        end
        local banner=part('PurpleEntranceBanner',Vector3.new(4.2,9,.22),CFrame.new(x+side*7,baseY+13,214.4),Color3.fromRGB(95,38,134),Enum.Material.Fabric,gateway)
        banner.CanCollide=false
        local medallion=part('BannerSpiritEmblem',Vector3.new(1.6,2.1,.25),banner.CFrame*CFrame.new(0,1,-.2),Color3.fromRGB(191,130,232),Enum.Material.Neon,gateway)
        medallion.Shape=Enum.PartType.Ball; medallion.CanCollide=false
    end
    for i=0,15 do
        local a,b=i/16*math.pi,(i+1)/16*math.pi
        local p=Vector3.new(21*math.cos(a),baseY+20+8*math.sin(a),215)
        local q=Vector3.new(21*math.cos(b),baseY+20+8*math.sin(b),215)
        beam('GothicGateArch',p,q,.65,iron,Enum.Material.Metal,gateway)
        local post=part('ArchCrownSpike',Vector3.new(.22,2.5,.22),CFrame.new(p+Vector3.new(0,1,0)),iron,Enum.Material.Metal,gateway)
        post.CanCollide=false
    end
    -- Path geometry, rather than estimated spokes, defines the planting clearances.
    local walkways={}
    for _,p in root:GetDescendants() do
        if p:IsA('BasePart') and p.Name=='ReferenceWalkway' then table.insert(walkways,p) end
    end
    local function onPath(x,z,padding)
        for _,p in walkways do
            if math.abs(x-p.Position.X)>p.Size.Magnitude/2+padding or math.abs(z-p.Position.Z)>p.Size.Magnitude/2+padding then continue end
            local q=p.CFrame:PointToObjectSpace(Vector3.new(x,p.Position.Y,z))
            if math.abs(q.X)<p.Size.X/2+padding and math.abs(q.Z)<p.Size.Z/2+padding then return true end
        end
        return false
    end
    local function clear(x,z)
        if x*x+z*z<54^2 then return false end
        if math.abs(x)<74 and z>-225 and z<-160 then return false end
        if x>-176 and x<-57 and z>104 and z<195 then return false end
        if ((x-130)/39)^2+((z-135)/50)^2<1 then return false end
        if ((x+122)/69)^2+((z-15)/66)^2<1 then return false end
        if math.abs(x-220)<17 and math.abs(z-65)<23 then return false end
        if math.abs(x)<35 and z>202 and z<225 then return false end
        for _,plot in W.Plots do
            local q=plot.CF:PointToObjectSpace(Vector3.new(x,plot.CF.Position.Y,z))
            if math.abs(q.X)<28*(plot.Scale or 1) and math.abs(q.Z)<26*(plot.Scale or 1) then return false end
        end
        return not onPath(x,z,5.5)
    end
    local function shrub(cf,scale,parent,tint)
        for n=1,3 do
            local bush=part('WoodlandUndergrowth',Vector3.new(3.2,2.5,3.1)*scale,cf*CFrame.new((n-2)*1.25*scale,scale,random:NextNumber(-.7,.7)),tint or Color3.fromRGB(39,70+random:NextInteger(0,18),45),Enum.Material.Grass,parent)
            bush.Shape=Enum.PartType.Ball; bush.CanCollide=false
        end
    end
    local woods=model('LayeredPineWoodland')
    local placed={}
    local attempts=0
    while #placed<390 and attempts<12000 do
        attempts+=1
        local x,z=random:NextNumber(-235,235),random:NextNumber(-239,233)
        if (x/245)^2+(z/247)^2>1 or not clear(x,z) then continue end
        local crowded=false
        for _,p in placed do if (x-p.X)^2+(z-p.Y)^2<53 then crowded=true; break end end
        if crowded then continue end
        table.insert(placed,Vector2.new(x,z))
        local y=ground(x,z)
        local scale=random:NextNumber(.72,1.88)
        local cf=CFrame.new(x,y,z)*CFrame.Angles(0,random:NextNumber(0,math.pi*2),0)
        if Assets.configured('PineTree') then
            local tree=Assets.place('PineTree',woods,cf)
            tree:ScaleTo(tree:GetScale()*scale)
            -- Scaling around the model pivot can shift its base; restore the base to the terrain.
            local bounds,size=tree:GetBoundingBox()
            tree:PivotTo(tree:GetPivot()+Vector3.new(0,y-(bounds.Position.Y-size.Y/2),0))
            for _,p in tree:GetDescendants() do
                if p:IsA('BasePart') and p.Name:match('_Foliage$') then
                    p.Color=Color3.fromRGB(20+random:NextInteger(0,13),49+random:NextInteger(0,25),39+random:NextInteger(0,18))
                end
            end
        else
            part('PineTrunk',Vector3.new(1.1,17,1.1)*scale,cf*CFrame.new(0,8.5*scale,0),wood,Enum.Material.Wood,woods)
            for tier=0,4 do
                for wing=0,3 do
                    local foliage=Instance.new('WedgePart')
                    foliage.Name='PineTier'; foliage.Size=Vector3.new((13-tier*2)*.65,7,(13-tier*2)*.5)*scale
                    foliage.CFrame=cf*CFrame.Angles(0,wing*math.pi/2,0)*CFrame.new(0,(8+tier*3.5)*scale,-(13-tier*2)*.25*scale)
                    foliage.Color=Color3.fromRGB(22,51-tier*3,40); foliage.Material=Enum.Material.Grass
                    foliage.Anchored=true; foliage.CanCollide=false; foliage.CanTouch=false; foliage.Parent=woods
                end
            end
        end
        shrub(cf*CFrame.new(3,0,1),random:NextNumber(.55,1.1),woods)
        if #placed%3==0 then shrub(cf*CFrame.new(-3,0,-2),random:NextNumber(.4,.9),woods) end
        if #placed%8==0 and Assets.configured('Boulder') then
            local rock=Assets.place('Boulder',woods,CFrame.new(x+3,y,z+2)*CFrame.Angles(0,random:NextNumber(0,6),0))
            rock:ScaleTo(rock:GetScale()*random:NextNumber(.4,.85))
        end
    end
    -- Low masonry and planting stitch the paths into the landscape.
    local beds=model('PathsideRetainingGardens')
    for i,p in walkways do
        if i%13~=0 or p.Position.Magnitude<55 then continue end
        for _,side in {-1,1} do
            local at=(p.CFrame*CFrame.new(side*(p.Size.X/2+7),0,0)).Position
            if not clear(at.X,at.Z) then continue end
            local y=ground(at.X,at.Z)
            local cf=CFrame.new(at.X,y,at.Z)*p.CFrame.Rotation
            part('RetainingWallBlock',Vector3.new(1.5,2.3,7),cf*CFrame.new(-side*2.7,1.05,0),edge,Enum.Material.Cobblestone,beds)
            part('RetainingWallCoping',Vector3.new(1.9,.45,7.4),cf*CFrame.new(-side*2.7,2.4,0),slate,nil,beds)
            shrub(cf,1.15,beds)
            if i%26==0 and Assets.configured('Pumpkin') then
                Assets.place('Pumpkin',beds,cf*CFrame.new(0,0,3),{Accent=gold})
            end
        end
    end
    -- The cemetery's oval retaining wall and tall memorials read clearly from above.
    local necropolis=model('VioletNecropolis')
    local purple=Color3.fromRGB(173,87,255)
    local grave=root:FindFirstChild('GraveyardLandmark')
    if grave then
        for _,p in grave:GetDescendants() do
            if p:IsA('BasePart') then
                if p.Name=='GraveMist' then p:Destroy(); continue end
                p.CFrame+=Vector3.new(0,1.5,0)
                if p.Name:match('_Accent$') or p.Name:match('_Glow$') then p.Color=purple end
            elseif p:IsA('PointLight') then p.Color=purple; p.Brightness=2; p.Range=24 end
        end
    end
    local precinct=part('OvalBurialPrecinct',Vector3.new(2,71,93),CFrame.new(130,.2,135)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(49,40,62),Enum.Material.Cobblestone,necropolis)
    precinct.Shape=Enum.PartType.Cylinder
    for i=0,43 do
        local a=i/44*math.pi*2
        local x,z=130+math.cos(a)*35,135+math.sin(a)*46
        if x<108 and math.abs(z-135)<12 then continue end
        local cf=CFrame.new(x,1.5,z)*CFrame.Angles(0,-a,0)
        part('NecropolisRetainingWall',Vector3.new(2,3.4,6.5),cf,slate,Enum.Material.Cobblestone,necropolis)
        part('NecropolisWallCoping',Vector3.new(2.6,.5,7),cf*CFrame.new(0,1.9,0),edge,nil,necropolis)
        if i%3==0 then
            part('CemeteryStonePost',Vector3.new(3,5,3),cf*CFrame.new(0,1,0),edge,nil,necropolis)
            local orb=part('PurpleCemeteryFire',Vector3.new(.8,1.5,.8),cf*CFrame.new(0,4,0),purple,Enum.Material.Neon,necropolis)
            orb.Shape=Enum.PartType.Ball; orb.CanCollide=false
            local light=Instance.new('PointLight'); light.Color=purple; light.Brightness=2.8; light.Range=23; light.Parent=orb
        end
        if i%4==0 then shrub(CFrame.new(x*1.01,ground(x,z),z+2),.9,necropolis,Color3.fromRGB(57,44,77)) end
    end
    for step=0,3 do
        part('CemeteryEntranceStep',Vector3.new(3,.5+step*.4,10),CFrame.new(96+step*3,-.25+step*.2,135),edge,Enum.Material.Cobblestone,necropolis)
    end
    for _,v in {{114,108,1.2},{145,114,.85},{136,164,1.05},{113,158,.8}} do
        local x,z,s=v[1],v[2],v[3]
        local cf=CFrame.new(x,1.3,z)
        part('MemorialFoundation',Vector3.new(7,1.2,7)*s,cf*CFrame.new(0,.6*s,0),edge,nil,necropolis)
        part('MemorialPlinth',Vector3.new(4.8,2.5,4.8)*s,cf*CFrame.new(0,2.3*s,0),slate,nil,necropolis)
        part('MemorialPillar',Vector3.new(2.5,10,2.5)*s,cf*CFrame.new(0,8*s,0),edge,nil,necropolis)
        part('MemorialCornice',Vector3.new(4,1,4)*s,cf*CFrame.new(0,13*s,0),edge,nil,necropolis)
        part('MemorialCrossStem',Vector3.new(.7,4,.7)*s,cf*CFrame.new(0,15*s,0),slate,nil,necropolis)
        part('MemorialCrossArms',Vector3.new(3,.7,.7)*s,cf*CFrame.new(0,15.6*s,0),slate,nil,necropolis)
        local jewel=part('MemorialVioletGem',Vector3.new(.8,1.3,.4)*s,cf*CFrame.new(0,9*s,-1.35*s),purple,Enum.Material.Neon,necropolis)
        jewel.Shape=Enum.PartType.Ball; jewel.CanCollide=false
    end
    for row,z in {117,135,153} do
        for col,x in {117,123,129,135,141,147} do
            local cf=CFrame.new(x,1.3,z)*CFrame.Angles(0,math.pi/2+((row+col)%3-1)*.04,0)
            part('RaisedBurialSlab',Vector3.new(3,.45,4.8),cf*CFrame.new(0,.2,2.8),Color3.fromRGB(68,59,80),Enum.Material.Slate,necropolis)
            part('GraveSlabInset',Vector3.new(2.5,.08,4.2),cf*CFrame.new(0,.48,2.8),Color3.fromRGB(46,40,55),Enum.Material.Slate,necropolis)
        end
    end
    for _,spot in {{105,111},{155,146},{120,174},{145,96}} do
        if Assets.configured('DeadTree') then
            local tree=Assets.place('DeadTree',necropolis,CFrame.new(spot[1],1,spot[2])*CFrame.Angles(0,random:NextNumber(0,6),0))
            tree:ScaleTo(tree:GetScale()*1.5)
        end
    end
    for _,spot in {{120,127},{141,147},{151,129}} do
        local spirit=V.ghost('little_boo',necropolis,CFrame.new(spot[1],5,spot[2]),.65,false)
        for _,p in spirit:GetDescendants() do
            if p:IsA('BasePart') then
                p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
                if p.Transparency<1 and p.Color.R+p.Color.G+p.Color.B>.7 then p.Color=purple; p.Material=Enum.Material.Neon end
            end
        end
    end
    -- A broken oval village fence gives the southwest shops a common boundary.
    local village=model('VillageEnclosureAndGardens')
    for i=0,47 do
        local a=i/48*math.pi*2
        local x,z=-113+math.cos(a)*72,148+math.sin(a)*50
        if onPath(x,z,7) or z<105 then continue end
        local cf=CFrame.new(x,ground(x,z),z)*CFrame.Angles(0,-a,0)
        part('VillageFenceStoneBase',Vector3.new(1.8,1.6,8),cf*CFrame.new(0,.7,0),slate,Enum.Material.Cobblestone,village)
        part('VillageFencePost',Vector3.new(1.4,5,1.4),cf*CFrame.new(0,2.5,0),wood,Enum.Material.Wood,village)
        for _,h in {2.1,3.8} do part('VillageFenceRail',Vector3.new(.35,.4,8),cf*CFrame.new(0,h,0),wood,Enum.Material.Wood,village) end
        if i%3==0 then lantern(cf,village) end
        if i%2==0 then shrub(cf*CFrame.new(-3,0,0),.85,village) end
    end
    -- Layered rock faces distinguish each raised estate from the forest floor.
    local terraces=model('EstateRockTerraces')
    local estateColors={Color3.fromRGB(198,68,255),Color3.fromRGB(47,147,255),Color3.fromRGB(47,255,133),Color3.fromRGB(255,72,33),Color3.fromRGB(47,223,255),Color3.fromRGB(240,46,235),gold}
    local function decorative(p)
        p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
        return p
    end
    local function flame(cf,color,parent,name)
        decorative(part(name..'Pedestal',Vector3.new(2,3,2),cf*CFrame.new(0,1.5,0),slate,Enum.Material.Slate,parent))
        decorative(part(name..'Brazier',Vector3.new(2.8,.7,2.8),cf*CFrame.new(0,3.3,0),iron,Enum.Material.Metal,parent))
        for i=0,2 do
            local fire=decorative(part(name..'Flame',Vector3.new(1.45-i*.38,2.1-i*.35,1.45-i*.38),cf*CFrame.new(i==1 and .22 or 0,4.1+i*.75,0),color:Lerp(Color3.new(1,1,1),i*.16),Enum.Material.Neon,parent))
            fire.Shape=Enum.PartType.Ball
            if i==0 then
                local light=Instance.new('PointLight'); light.Color=color; light.Brightness=2.3; light.Range=24; light.Parent=fire
            end
        end
    end
    for index,plot in W.Plots do
        local cf,s=plot.CF,plot.Scale or 1
        local hue=estateColors[index] or purple
        for side=-1,1,2 do
            for k=0,8 do
                local lx,lz=side*(24*s+2.4),(-19+k*5)*s
                local at=(cf*CFrame.new(lx,0,lz)).Position
                if onPath(at.X,at.Z,2.5) then continue end
                local drop=math.clamp(at.Y-ground(at.X+side*4,at.Z)+7,6,18)
                local height=drop+random:NextNumber(0,2)
                local offset=cf*CFrame.new(lx,-height/2-.4,lz)*CFrame.Angles(0,random:NextNumber(-.1,.1),side*.035)
                decorative(part('EstateUpperRockFace',Vector3.new(7,height,7.4),offset,edge:Lerp(slate,random:NextNumber(.15,.65)),Enum.Material.Slate,terraces))
                decorative(part('EstateLowerRockLedge',Vector3.new(10,3.5,8.4),cf*CFrame.new(lx+side*2,-height+1,lz+1)*CFrame.Angles(0,.12,0),slate,Enum.Material.Slate,terraces))
                decorative(part('EstateStoneCoping',Vector3.new(6.7,.8,7.1),cf*CFrame.new(lx,-.3,lz),Color3.fromRGB(93,88,113),Enum.Material.Slate,terraces))
                if k%2==0 then shrub(cf*CFrame.new(lx+side*1.2,.2,lz),.75,terraces,Color3.fromRGB(32,67,43)) end
            end
            -- Front corners are planted, while the full central gateway stays open.
            for _,lx in {side*20*s,side*13*s} do
                local at=(cf*CFrame.new(lx,0,-22*s)).Position
                if not onPath(at.X,at.Z,2.8) then
                    decorative(part('EstateFrontTerrace',Vector3.new(9,7,6),cf*CFrame.new(lx,-3.8,-22*s),edge:Lerp(slate,.3),Enum.Material.Slate,terraces))
                    decorative(part('EstateFrontCoping',Vector3.new(9.2,.6,6.2),cf*CFrame.new(lx,-.2,-22*s),edge,nil,terraces))
                end
            end
            local flameCf=cf*CFrame.new(side*26*s,0,-14*s)
            if not onPath(flameCf.Position.X,flameCf.Position.Z,3) then flame(flameCf,hue,terraces,'EstateSpirit') end
            local spiritCf=cf*CFrame.new(side*26*s,6,8*s)
            if not onPath(spiritCf.Position.X,spiritCf.Position.Z,3) then
                local spirit=V.ghost('little_boo',terraces,spiritCf,.9,false)
                for _,p in spirit:GetDescendants() do
                    if p:IsA('BasePart') then
                        decorative(p)
                        if p.Transparency<1 and p.Color.R+p.Color.G+p.Color.B>.7 then p.Color=hue; p.Material=Enum.Material.Neon end
                    end
                end
            end
        end
        -- A narrow back ledge remains below the architectural and gameplay surfaces.
        for k=-3,3 do
            local at=(cf*CFrame.new(k*9,0,23*s)).Position
            if not onPath(at.X,at.Z,3) then
                decorative(part('EstateRearRockTerrace',Vector3.new(10,11,7),cf*CFrame.new(k*9,-6,23*s),slate:Lerp(edge,random:NextNumber(.1,.5)),Enum.Material.Slate,terraces))
            end
        end
    end
    -- Small bank rocks interrupt the smooth lake outline; shallow streaks catch moonlight.
    local shore=model('FishingLakeShoreline')
    for i=0,61 do
        local a=i/62*math.pi*2
        local x,z=-122+math.cos(a)*65,15+math.sin(a)*62
        if onPath(x,z,4) or (math.abs(x+126)<12 and z<-31) then continue end
        if (math.abs(z-10)<10 and x<-169) or (math.abs(z-19)<10 and x>-79) or (math.abs(x+148)<10 and z>52) then continue end
        local cf=CFrame.new(x,math.max(-4,ground(x,z))-.6,z)*CFrame.Angles(0,-a+random:NextNumber(-.18,.18),random:NextNumber(-.15,.15))
        decorative(part('LakeBankStone',Vector3.new(random:NextNumber(4,8),random:NextNumber(2.2,4.8),random:NextNumber(3,6)),cf,slate:Lerp(edge,random:NextNumber(.1,.6)),Enum.Material.Slate,shore))
        if i%3==0 then shrub(cf*CFrame.new(0,1,0),.8,shore,Color3.fromRGB(35,78,54)) end
        if i%7==0 then lantern(CFrame.new(x,math.max(-.5,ground(x,z)),z),shore) end
    end
    for i=1,90 do
        local x,z=random:NextNumber(-177,-66),random:NextNumber(-34,68)
        if ((x+122)/59)^2+((z-15)/55)^2>1 then continue end
        local wave=decorative(part('MoonlitWaterRipple',Vector3.new(random:NextNumber(.5,2.6),.035,.13),CFrame.new(x,-2.9,z)*CFrame.Angles(0,random:NextNumber(-.2,.2),0),Color3.fromRGB(63,136,192),Enum.Material.Neon,shore))
        wave.Transparency=random:NextNumber(.62,.85); wave.CastShadow=false
    end
    for _,v in {{-166,39},{-93,-26},{-80,43}} do
        local p=decorative(part('LakeMoonlight',Vector3.one,CFrame.new(v[1],1,v[2]),blue,Enum.Material.Neon,shore))
        p.Transparency=1
        local light=Instance.new('PointLight'); light.Color=Color3.fromRGB(46,120,208); light.Brightness=1.4; light.Range=38; light.Parent=p
    end
    -- Warm light and market clutter give the village a shared busy square.
    local town=root:FindFirstChild('SpookyTown')
    if town then
        for _,p in town:GetDescendants() do
            if p:IsA('BasePart') and p.Name:match('_Glow$') then p.Color=Color3.fromRGB(255,152,48) end
            if p:IsA('PointLight') then p.Color=Color3.fromRGB(255,140,40); p.Brightness=2.8; p.Range=28 end
        end
    end
    local squareCenter=CFrame.new(-105,.7,155)
    for i=0,17 do
        local a=i/18*math.pi*2
        decorative(part('VillageWellStone',Vector3.new(1.5,2,2.2),squareCenter*CFrame.new(math.cos(a)*4.4,1,math.sin(a)*4.4)*CFrame.Angles(0,-a,0),edge,Enum.Material.Cobblestone,village))
    end
    local well=decorative(part('VillageWellWater',Vector3.new(.15,7.1,7.1),squareCenter*CFrame.new(0,.7,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(53,131,174),Enum.Material.Glass,village))
    well.Shape=Enum.PartType.Cylinder; well.Transparency=.28
    for _,side in {-1,1} do decorative(part('WellTimberPost',Vector3.new(.65,7,.65),squareCenter*CFrame.new(side*4,3.5,0),wood,Enum.Material.Wood,village)) end
    decorative(part('WellCrossBeam',Vector3.new(10,.8,.8),squareCenter*CFrame.new(0,7,0),wood,Enum.Material.Wood,village))
    decorative(part('WellRope',Vector3.new(.14,5,.14),squareCenter*CFrame.new(0,4,0),Color3.fromRGB(160,128,76),Enum.Material.Fabric,village))
    for _,v in {{-123,136},{-88,150},{-105,161},{-134,153},{-73,153},{-135,117}} do
        local cf=CFrame.new(v[1],ground(v[1],v[2]),v[2])
        if onPath(v[1],v[2],2) then continue end
        flame(cf,Color3.fromRGB(255,146,37),village,'VillageBonfire')
        if Assets.configured('OakCask') then Assets.place('OakCask',village,cf*CFrame.new(2.2,0,1)) end
        if Assets.configured('Crate') then
            Assets.place('Crate',village,cf*CFrame.new(-2.2,0,0))
            Assets.place('Crate',village,cf*CFrame.new(-2.2,1.8,0)*CFrame.Angles(0,.2,0))
        end
        if Assets.configured('Pumpkin') then Assets.place('Pumpkin',village,cf*CFrame.new(2,0,-2),{Accent=gold}) end
    end
    for _,s in {{-121,130,-83,132},{-137,157,-87,169}} do
        local a,b=Vector3.new(s[1],11,s[2]),Vector3.new(s[3],11,s[4])
        for i=0,10 do
            local t=i/10
            local at=a:Lerp(b,t)-Vector3.new(0,math.sin(t*math.pi)*2.5,0)
            local nextT=math.min(1,(i+1)/10)
            local to=a:Lerp(b,nextT)-Vector3.new(0,math.sin(nextT*math.pi)*2.5,0)
            if i<10 then decorative(beam('VillageFestivalWire',at,to,.09,iron,Enum.Material.Metal,village)) end
            local bulb=decorative(part('VillageStringLantern',Vector3.new(.75,1,.75),CFrame.new(at-Vector3.new(0,.5,0)),gold,Enum.Material.Neon,village))
            if i%3==0 then local light=Instance.new('PointLight'); light.Color=gold; light.Brightness=1.6; light.Range=16; light.Parent=bulb end
        end
    end
    -- A larger chapel and violets make the cemetery more than a field of tiny stones.
    if Assets.configured('Crypt') then
        local chapel=Assets.place('Crypt',necropolis,CFrame.new(130,1.2,102),{Accent=purple})
        chapel.Name='VioletMemorialChapel'; chapel:ScaleTo(chapel:GetScale()*1.65)
        local bounds,size=chapel:GetBoundingBox()
        chapel:PivotTo(chapel:GetPivot()+Vector3.new(0,1.2-(bounds.Position.Y-size.Y/2),0))
        for _,p in chapel:GetDescendants() do
            if p:IsA('BasePart') then
                decorative(p)
                if p.Name:match('_Glow$') then
                    p.Color=purple
                    local light=Instance.new('PointLight'); light.Color=purple; light.Brightness=2.5; light.Range=30; light.Parent=p
                end
            end
        end
    end
    for _,v in {{111,120},{119,144},{143,126},{145,164}} do flame(CFrame.new(v[1],1.3,v[2]),purple,necropolis,'NecropolisVigil') end
    for i=1,35 do
        local x,z=random:NextNumber(108,155),random:NextNumber(106,169)
        if math.abs(z-135)<5 then continue end
        local patch=decorative(part('GraveViolets',Vector3.new(random:NextNumber(1.5,3),.55,random:NextNumber(1.5,3)),CFrame.new(x,1.8,z),Color3.fromRGB(90,49,131),Enum.Material.Grass,necropolis))
        patch.Shape=Enum.PartType.Ball
        if i%5==0 then
            local petal=decorative(part('GraveSpiritBloom',Vector3.new(.35,.4,.35),CFrame.new(x,2.3,z),purple,Enum.Material.Neon,necropolis))
            petal.Shape=Enum.PartType.Ball
        end
    end
    folder:SetAttribute('ReferenceTreeCount',#placed)
    return folder
end

return Details

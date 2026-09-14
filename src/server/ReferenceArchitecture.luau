-- Dimensional Gothic silhouette and small illuminated openings, composed in local space.
-- Haunt fronts face -Z. The mansion wrapper rotates that convention toward +Z.
local A={}
local slate=Color3.fromRGB(28,35,55)
local edge=Color3.fromRGB(93,87,111)
local iron=Color3.fromRGB(30,25,41)
local brick=Color3.fromRGB(62,53,72)
local amber=Color3.fromRGB(255,117,27)

local function builder(parent,cf,V)
    local b={}
    function b.part(name,size,offset,color,material)
        local p=V.part(parent,name,size,cf*offset,color or brick,material or Enum.Material.Slate)
        p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
        return p
    end
    function b.beam(name,a,c,width,color)
        local mid=(a+c)*.5
        return b.part(name,Vector3.new(width,width,(a-c).Magnitude),CFrame.lookAt(mid,c),color or edge,Enum.Material.Metal)
    end
    function b.triangle(name,a,c,d,color,material)
        local ab,ac,bc=c-a,d-a,d-c
        if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then
            d,a=a,d
        elseif ac:Dot(ac)>bc:Dot(bc) then
            a,c=c,a
        end
        ab,ac,bc=c-a,d-a,d-c
        local right=ac:Cross(ab).Unit
        local up=bc:Cross(right).Unit
        local back=bc.Unit
        local height=math.abs(ab:Dot(up))
        for i,data in {{(a+c)*.5,right,back,math.abs(ab:Dot(back))},{(a+d)*.5,-right,-back,math.abs(ac:Dot(back))}} do
            if data[4]<.015 then continue end
            local p=Instance.new('WedgePart')
            p.Name=name..i; p.Size=Vector3.new(.16,height,data[4])
            p.CFrame=cf*CFrame.fromMatrix(data[1],data[2],up,data[3])
            p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
            p.Material=material or Enum.Material.Slate; p.Color=color or slate; p.Parent=parent
        end
    end
    function b.finial(x,y,z,scale)
        b.part('IronFinial',Vector3.new(.14,2.8,.14)*scale,CFrame.new(x,y+1.4*scale,z),iron,Enum.Material.Metal)
        b.part('FinialCross',Vector3.new(.95,.12,.12)*scale,CFrame.new(x,y+2*scale,z),edge,Enum.Material.Metal)
        local bead=b.part('FinialBead',Vector3.new(.36,.36,.36)*scale,CFrame.new(x,y+.6*scale,z),edge,Enum.Material.Metal)
        bead.Shape=Enum.PartType.Ball
    end
    function b.window(x,y,z,w,h,hue)
        -- Recess, pointed glass head, stone arch and thin iron mullions are all geometry.
        b.part('WindowRecess',Vector3.new(w+.52,h+.4,.32),CFrame.new(x,y+h*.5,z+.07),iron)
        local pane=b.part('LuminousLancet',Vector3.new(w,h*.72,.13),CFrame.new(x,y+h*.36,z-.12),hue,Enum.Material.Neon)
        b.triangle('PointedGlass',Vector3.new(x-w*.5,y+h*.72,z-.2),Vector3.new(x+w*.5,y+h*.72,z-.2),Vector3.new(x,y+h,z-.2),hue,Enum.Material.Neon)
        -- Triangle glass retains a mild emissive material without luminous facade bands.
        for _,s in {-1,1} do
            b.beam('ArchJamb',Vector3.new(x+s*(w*.5+.15),y,z-.26),Vector3.new(x+s*(w*.5+.15),y+h*.72,z-.26),.22,edge)
            b.beam('PointedArch',Vector3.new(x+s*(w*.5+.15),y+h*.72,z-.26),Vector3.new(x,y+h+.24,z-.26),.24,edge)
        end
        b.part('WindowSill',Vector3.new(w+.8,.25,.65),CFrame.new(x,y-.1,z-.2),edge)
        b.part('WindowMullion',Vector3.new(.12,h,.19),CFrame.new(x,y+h*.5,z-.3),iron,Enum.Material.Metal)
        b.part('WindowTransom',Vector3.new(w,.12,.19),CFrame.new(x,y+h*.4,z-.3),iron,Enum.Material.Metal)
        return pane
    end
    function b.gable(x,y,z,w,h,depth,hue)
        local a=Vector3.new(x-w*.5,y,z)
        local c=Vector3.new(x+w*.5,y,z)
        local top=Vector3.new(x,y+h,z)
        b.triangle('GableFace',a,c,top,brick)
        for _,s in {-1,1} do
            local low=Vector3.new(x+s*w*.5,y,z)
            local rear=low+Vector3.new(0,0,depth)
            local peakRear=top+Vector3.new(0,0,depth)
            b.triangle('SteepSlateRoof',low,top,rear,slate)
            b.triangle('SteepSlateRoof',rear,top,peakRear,slate)
            b.beam('GableBargeboard',low,top,.32,edge)
            b.beam('RoofEave',low,rear,.32,iron)
        end
        b.beam('RidgeCap',top,top+Vector3.new(0,0,depth),.3,edge)
        if hue then b.window(x,y+.65,z-.2,w*.24,h*.48,hue) end
        b.finial(x,y+h,z,.8)
    end
    function b.tower(x,z,base,height,radius,roofHeight,hue)
        local shaft=b.part('OctagonalTurret',Vector3.new(height,radius*1.7,radius*1.7),CFrame.new(x,base+height*.5,z)*CFrame.Angles(0,0,math.pi*.5),brick)
        shaft.Shape=Enum.PartType.Cylinder
        for _,y in {base+.35,base+height*.52,base+height-.25} do
            local ring=b.part('TurretCornice',Vector3.new(.45,radius*1.95,radius*1.95),CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi*.5),edge)
            ring.Shape=Enum.PartType.Cylinder
        end
        local roofY=base+height
        for i=0,7 do
            local angle=i*math.pi*.25
            local nextAngle=(i+1)*math.pi*.25
            local a=Vector3.new(x+math.cos(angle)*radius*1.15,roofY,z+math.sin(angle)*radius*1.15)
            local c=Vector3.new(x+math.cos(nextAngle)*radius*1.15,roofY,z+math.sin(nextAngle)*radius*1.15)
            local top=Vector3.new(x,roofY+roofHeight,z)
            b.triangle('NeedleSpire',a,c,top,slate)
            if i%2==0 then b.beam('SpireSeam',a,top,.13,edge) end
        end
        b.finial(x,roofY+roofHeight,z,1)
        if hue then b.window(x,base+height*.55,z-radius*.88-.05,radius*.62,height*.25,hue) end
    end
    function b.lantern(x,y,z,hue)
        b.part('LanternBracket',Vector3.new(.16,.16,1),CFrame.new(x,y+.75,z+.3),iron,Enum.Material.Metal)
        local p=b.part('ArchitecturalLantern',Vector3.new(.5,.8,.5),CFrame.new(x,y,z),hue,Enum.Material.Neon)
        for _,dy in {-.5,.5} do b.part('LanternCap',Vector3.new(.8,.17,.8),CFrame.new(x,y+dy,z),iron,Enum.Material.Metal) end
        local l=Instance.new('PointLight'); l.Color=hue; l.Brightness=1.4; l.Range=13; l.Parent=p
    end
    return b
end

function A.decorateHaunt(model,cf,hue,V)
    -- This imported role combines the original long roof, timber trim and door.
    -- Its broad eave otherwise occludes the new elevated Gothic frontage.
    for _,p in model:GetDescendants() do
        if p:IsA('BasePart') and p.Name=='HauntShowcase_Roof' then
            p.Transparency=1; p.CastShadow=false
        end
    end
    local detail=Instance.new('Model'); detail.Name='GothicArchitecture'; detail.Parent=model
    -- Row four of the interactive ghost display occupies x=-12,0,12 at z=10.
    -- New upper-storey walls begin behind z12 and above the original wall's y12 eave.
    local b=builder(detail,cf,V)
    for _,x in {-11,-6,0,6,11} do b.window(x,8,10.3,1.5,2.5,hue) end
    local facade=brick:Lerp(hue,.18)
    -- Stable architectural differences belong to a plot, rather than changing every run.
    local seed=math.abs(math.round(cf.Position.X*137+cf.Position.Z*313))
    local rng=Random.new(seed)
    local dominantSide=if seed%2==0 then -1 else 1
    local centreEave=rng:NextNumber(21.8,25)
    local centreWidth=rng:NextNumber(7.1,8.6)
    local centreRoof=rng:NextNumber(8,10.8)
    local centreFront=rng:NextNumber(12.8,14)
    -- A low roof running sideways through the estate creates real intersecting roof
    -- volumes between the stepped front wings. It stays behind all display slots.
    local crossRoof=builder(detail,cf*CFrame.new(-15.4,0,17.2)*CFrame.Angles(0,math.pi*.5,0),V)
    crossRoof.gable(0,12.35,0,9.1,6.2,30.8,nil)
    for _,s in {-1,1} do
        local eave=rng:NextNumber(17.8,23)+(if s==dominantSide then 1 else 0)
        local front=rng:NextNumber(14.3,17.1)
        local width=rng:NextNumber(6.4,8.2)
        local x=s*rng:NextNumber(9.2,10.8)
        local depth=23.4-front
        b.part('ProjectingFrontBay',Vector3.new(width,eave-12.2,depth),CFrame.new(x,(eave+12.2)*.5,front+depth*.5),facade,Enum.Material.Brick)
        b.gable(x,eave,front-.12,width+1.1,rng:NextNumber(7.4,10.4),depth+.5,hue)
        for _,dx in {-width*.24,width*.24} do b.window(x+dx,13.3,front-.28,width*.22,math.min(6.3,eave-13.8),hue) end
        -- A narrow stone balcony projects out from each staggered bay. Short dark
        -- columns and angled brackets accent the depth without filling the yard.
        b.part('BayBalcony',Vector3.new(width+.7,.35,1.55),CFrame.new(x,12.8,front-.65),edge)
        b.part('BayBalconyRail',Vector3.new(width+.25,.12,.12),CFrame.new(x,14.35,front-1.35),iron,Enum.Material.Metal)
        for j=-3,3 do b.part('BayBaluster',Vector3.new(.1,1.4,.1),CFrame.new(x+j*width/6,13.55,front-1.35),iron,Enum.Material.Metal) end
        for _,side in {-1,1} do
            b.part('VerticalButtress',Vector3.new(.45,eave-12,1),CFrame.new(x+side*(width*.5-.12),(eave+12)*.5,front-.1),edge)
            b.beam('BalconyBracket',Vector3.new(x+side*width*.35,11.6,front),Vector3.new(x+side*width*.35,12.65,front-1.2),.2,iron)
        end
        -- Broad lower side wings and unequal tower heights replace paired needles.
        local wingX=s*17.3
        local wingTop=rng:NextNumber(14.5,17.3)
        b.part('LowerSideWing',Vector3.new(5.8,wingTop-11.8,7.3),CFrame.new(wingX,(wingTop+11.8)*.5,17),facade,Enum.Material.Brick)
        b.gable(wingX,wingTop,13.2,6.8,6.2,8.2,hue)
        b.window(wingX,12.6,13.05,2.3,3.2,hue)
        local towerHeight=if s==dominantSide then rng:NextNumber(24,27) else rng:NextNumber(17.5,21)
        b.tower(s*17.6,20.1,.6,towerHeight,3.1,if s==dominantSide then 10.5 else 7.4,hue)
        local sideWindows=builder(detail,cf*CFrame.new(s*20.28,0,18.5)*CFrame.Angles(0,-s*math.pi*.5,0),V)
        sideWindows.window(0,13,0,2.1,4,hue)
        b.lantern(s*4.7,8.5,12.8,amber)
        local dormerX=s*rng:NextNumber(4.8,6.4)
        local dormerEave=rng:NextNumber(20,23)
        b.part('DormerCheek',Vector3.new(3.4,5,4.3),CFrame.new(dormerX,dormerEave-2.5,21),facade,Enum.Material.Brick)
        b.gable(dormerX,dormerEave,18.7,4.4,5.8,4.8,hue)
        -- Two concealed spotlights wash the stone in each plot's identity colour.
        -- They sit over the yard, face toward the house, and do not add visible neon strips.
        local source=b.part('FacadeFlood',Vector3.new(.2,.2,.2),CFrame.lookAt(Vector3.new(s*11,5.8,5),Vector3.new(s*8,18,15)),hue)
        source.Transparency=1
        local light=Instance.new('SpotLight'); light.Name='ColouredFacadeWash'
        light.Face=Enum.NormalId.Front; light.Color=hue; light.Range=38; light.Angle=88
        light.Brightness=3.2; light.Shadows=false; light.Parent=source
    end
    b.part('EntryBay',Vector3.new(centreWidth,centreEave-12.2,23.8-centreFront),CFrame.new(0,(centreEave+12.2)*.5,(23.8+centreFront)*.5),facade,Enum.Material.Brick)
    b.gable(0,centreEave,centreFront-.12,centreWidth+1.6,centreRoof,24-centreFront,hue)
    for _,x in {-centreWidth*.24,centreWidth*.24} do b.window(x,14.4,centreFront-.3,centreWidth*.23,centreEave-15.2,hue) end
    b.part('DoorRecess',Vector3.new(4.4,7,.4),CFrame.new(0,4.1,12.8),iron,Enum.Material.Wood)
    b.gable(0,9.8,12.3,7.4,4.3,3,nil)
    for _,s in {-1,1} do
        b.part('PorchColumn',Vector3.new(.48,9,.48),CFrame.new(s*2.9,5.3,12.5),edge)
        b.part('BalconyPost',Vector3.new(.2,2.1,.2),CFrame.new(s*3.1,14.8,13),iron,Enum.Material.Metal)
    end
    b.part('BalconyStone',Vector3.new(7,.4,2.7),CFrame.new(0,13.8,13.6),edge)
    b.part('BalconyRailing',Vector3.new(6.4,.17,.17),CFrame.new(0,15.8,12.3),iron,Enum.Material.Metal)
    for x=-3,3,.75 do b.part('BalconyIronwork',Vector3.new(.11,1.9,.11),CFrame.new(x,14.8,12.3),iron,Enum.Material.Metal) end
    -- The third roof feature alternates between a chimney cluster and a rear steeple.
    if seed%3==0 then
        b.tower(-dominantSide*4.2,22,20.5,8.5,1.65,8.6,hue)
    else
        for _,x in {dominantSide*4.8,dominantSide*6.5} do
            b.part('VictorianChimney',Vector3.new(1.2,8.2,1.6),CFrame.new(x,25,22),brick,Enum.Material.Brick)
            b.part('ChimneyCrown',Vector3.new(1.6,.45,2),CFrame.new(x,29.15,22),edge)
            b.part('ChimneyPot',Vector3.new(.65,1.4,.65),CFrame.new(x,30,22),iron,Enum.Material.Brick)
        end
    end
    -- Segment cornices follow each wing rather than drawing a flat line across the house.
    b.part('EntryCornice',Vector3.new(centreWidth+.3,.35,.7),CFrame.new(0,centreEave-.25,centreFront-.1),edge)
    return detail
end

function A.decorateMansion(root,baseCf,V)
    for _,p in root:GetDescendants() do
        if p:IsA('BasePart') and p.Name=='MansionFacade_Glow' then p.Color=amber end
        if p:IsA('BasePart') and p.Name=='MansionFacade_Roof' then p.Color=slate end
    end
    local detail=Instance.new('Model'); detail.Name='MansionGothicArchitecture'; detail.Parent=root
    local b=builder(detail,baseCf*CFrame.Angles(0,math.pi,0),V)
    -- The base mansion spans 127 studs. Its frontage is south; towers progress up to
    -- the central steeple so the high view reads as a many-spired Victorian mansion.
    for _,s in {-1,1} do
        for i=1,3 do
            local x=s*(15+i*12)
            local eave=if i==1 then 34 elseif i==2 then 28 else 23
            b.part('MansionProjectingBay',Vector3.new(10.3,eave,4.5),CFrame.new(x,eave*.5,-17),brick,Enum.Material.Brick)
            b.gable(x,eave,-19.4,12.7,14-i,23,amber)
            for _,y in {5,15,25} do
                if y+6<eave+3 then b.window(x,y,-19.75,3.1,6.7,amber) end
            end
            for _,side in {-1,1} do b.part('MansionButtress',Vector3.new(.8,eave,1.5),CFrame.new(x+side*5,eave*.5,-19.5),edge) end
        end
        b.tower(s*59,-7,0,30,4.3,19,amber)
        b.tower(s*42,6,4,36,3.3,20,amber)
        b.tower(s*26,11,8,42,3.6,23,amber)
        b.tower(s*12,-14,0,44,3.2,24,amber)
        b.tower(s*6,12,25,26,2.4,20,amber)
        b.lantern(s*8,9,-23,amber)
        -- Lower forward wings give the mansion a layered estate footprint and
        -- overlap the tall rear facade with real roof planes and recessed windows.
        local wingX=s*39
        local wingEave=if s==-1 then 14.5 else 17
        b.part('MansionLowerWing',Vector3.new(19,wingEave,8),CFrame.new(wingX,wingEave*.5,-19.5),brick,Enum.Material.Brick)
        b.gable(wingX,wingEave,-23.65,21,10,9,amber)
        for _,dx in {-5,0,5} do b.window(wingX+dx,3.3,-23.88,2.3,7,amber) end
        b.part('WingBalcony',Vector3.new(20,.45,1.4),CFrame.new(wingX,2.8,-23.4),edge)
        for _,dx in {-9,9} do
            b.part('WingPier',Vector3.new(.75,wingEave,.9),CFrame.new(wingX+dx,wingEave*.5,-23.8),edge)
        end
        -- Visible dormer cheeks and short transverse ridges articulate the old
        -- broad main roof, rather than adding another row of flush window decals.
        for i=1,2 do
            local x=s*(15+i*9)
            local y=if i==1 then 48 else 45.5
            b.part('MansionDormerCheek',Vector3.new(5.2,5.5,6),CFrame.new(x,y-2.75,-5),brick,Enum.Material.Brick)
            b.gable(x,y,-8.2,6.6,8,7,amber)
        end
        for _,dx in {0,2.1} do
            b.part('MansionChimney',Vector3.new(1.6,11,2.4),CFrame.new(s*34+dx,52.5,7),brick,Enum.Material.Brick)
            b.part('MansionChimneyCap',Vector3.new(2.1,.55,2.8),CFrame.new(s*34+dx,58.1,7),edge)
            b.part('MansionChimneyPot',Vector3.new(.8,1.5,.8),CFrame.new(s*34+dx,59.1,7),iron,Enum.Material.Brick)
        end
        local bannerX=s*20
        b.part('MansionBannerPole',Vector3.new(.19,19,.19),CFrame.new(bannerX,9.5,-23),edge,Enum.Material.Metal)
        b.part('MansionBanner',Vector3.new(3.1,6.3,.16),CFrame.new(bannerX-s*1.65,14.1,-23),Color3.fromRGB(85,31,119),Enum.Material.Fabric)
        b.finial(bannerX,19,-23,.75)
    end
    b.part('CentralFrontage',Vector3.new(18,43,6),CFrame.new(0,21.5,-18),brick,Enum.Material.Brick)
    b.gable(0,43,-21,21,19,24,amber)
    b.tower(0,6,34,25,4,25,amber)
    for _,y in {16,28,42} do b.window(0,y,-21.3,5,8,amber) end
    b.part('MansionPortalRecess',Vector3.new(11,14,.6),CFrame.new(0,7,-21.4),iron,Enum.Material.Wood)
    b.gable(0,13.5,-24,15,10,5,nil)
    for _,s in {-1,1} do
        b.part('PortalColumn',Vector3.new(1.1,13,1.1),CFrame.new(s*6.5,6.5,-23.5),edge)
        b.window(s*3,4,-21.8,1.9,6,amber)
    end
    for _,y in {1,13,25} do
        b.part('MansionStringCourse',Vector3.new(116,.55,1),CFrame.new(0,y,-18.9),edge)
    end
    return detail
end

return A

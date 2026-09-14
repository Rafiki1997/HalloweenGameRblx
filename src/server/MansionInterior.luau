-- Room-scale architecture and furnishings for the six mansion hunting wings.
local Interior={}
local wood=Color3.fromRGB(55,32,29)
local trim=Color3.fromRGB(109,77,48)
local stone=Color3.fromRGB(74,72,88)
local gold=Color3.fromRGB(167,128,64)
local iron=Color3.fromRGB(26,28,38)
local warm=Color3.fromRGB(255,193,110)
local moon=Color3.fromRGB(115,161,217)
local themes={
    {wall=Color3.fromRGB(77,57,65),rug=Color3.fromRGB(105,29,45),names={'Drawing Room','Entrance Hall','Dining Room'}},
    {wall=Color3.fromRGB(60,68,78),rug=Color3.fromRGB(48,66,90),names={'Guest Suites','Portrait Gallery','Family Suites'}},
    {wall=Color3.fromRGB(48,67,60),rug=Color3.fromRGB(44,77,64),names={'Reading Room','Grand Library','Archives'}},
    {wall=Color3.fromRGB(67,67,64),rug=Color3.fromRGB(62,61,55),names={'Wine Cellar','Service Hall','Workshop'}},
    {wall=Color3.fromRGB(64,60,77),rug=Color3.fromRGB(76,35,84),names={'Family Tombs','Memorial Chapel','Candle Gallery'}},
    {wall=Color3.fromRGB(53,61,64),rug=Color3.fromRGB(42,59,57),names={'Burial Vaults','Reliquary','Ossuary'}},
}

function Interior.build(root,floor,info,center,V)
    local theme=themes[floor]
    local underground=floor>=4
    local area=Instance.new('Model'); area.Name='Floor'..floor; area.Parent=root
    area:SetAttribute('InteriorDesign','Victorian mansion rooms')
    area:SetAttribute('AreaName',info.Name)
    local lights={}
    local flickerLight
    local base=CFrame.new(center)
    local function part(name,size,cf,color,material,solid)
        local p=V.part(area,name,size,base*cf,color or wood,material or Enum.Material.Wood)
        p.CanCollide=solid==true; p.CanQuery=solid==true; p.CanTouch=false
        if solid then p:SetAttribute('InteriorObstacle',true) end
        return p
    end
    local function box(name,x,y,z,w,h,d,color,material,solid)
        return part(name,Vector3.new(w,h,d),CFrame.new(x,y,z),color,material,solid)
    end
    local function beam(name,a,b,width,color)
        return part(name,Vector3.new(width,width,(a-b).Magnitude),CFrame.lookAt((a+b)/2,b),color or trim)
    end
    local function triangle(cf,a,b,c)
        local ab,ac,bc=b-a,c-a,c-b
        if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
        elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
        ab,ac,bc=b-a,c-a,c-b
        local right=ac:Cross(ab).Unit; local up=bc:Cross(right).Unit; local back=bc.Unit
        local height=math.abs(ab:Dot(up))
        for _,v in {{(a+b)*.5,right,back,math.abs(ab:Dot(back))},{(a+c)*.5,-right,-back,math.abs(ac:Dot(back))}} do
            if v[4]<.01 then continue end
            local wedge=Instance.new('WedgePart'); wedge.Name='ArchSpandrel'; wedge.Size=Vector3.new(1.3,height,v[4])
            wedge.CFrame=base*cf*CFrame.fromMatrix(v[1],v[2],up,v[3]); wedge.Color=theme.wall; wedge.Material=if underground then Enum.Material.Brick else Enum.Material.Plaster
            wedge.Anchored=true; wedge.CanCollide=false; wedge.CanQuery=false; wedge.CanTouch=false; wedge.Parent=area
        end
    end
    local function light(p,color,range,brightness)
        local l=Instance.new('PointLight'); l.Color=color; l.Range=range; l.Brightness=brightness; l.Shadows=true; l.Parent=p
        table.insert(lights,l); return l
    end
    local function candle(x,y,z)
        box('CandleHolder',x,y+.1,z,.65,.2,.65,gold,Enum.Material.Metal)
        box('IvoryCandle',x,y+.6,z,.3,.9,.3,Color3.fromRGB(207,192,155))
        local flame=box('CandleFlame',x,y+1.15,z,.2,.35,.2,warm,Enum.Material.Neon)
        local l=light(flame,warm,19,1.1)
        flickerLight=flickerLight or l
    end
    local function rug(x,z,w,d)
        if floor==4 or floor==6 then
            box('StoneWalkBorder',x,.035,z,w,.06,d,Color3.fromRGB(48,51,60),Enum.Material.Slate)
            box('StoneWalkInlay',x,.075,z,w-.55,.04,d-.55,Color3.fromRGB(72,76,80),Enum.Material.Cobblestone)
            return
        end
        box('RugBorder',x,.035,z,w,.06,d,gold,Enum.Material.Fabric)
        box('WornVelvetRug',x,.075,z,w-.55,.04,d-.55,theme.rug,Enum.Material.Fabric)
        for _,s in {-1,1} do box('RugWovenStripe',x+s*(w*.5-.8),.1,z,.12,.015,d-1.4,trim,Enum.Material.Fabric) end
    end
    local function plaque(text,cf,w)
        local p=part('RoomPlaque',Vector3.new(w or 13,1.8,.22),cf,wood)
        local gui=Instance.new('SurfaceGui'); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(480,70); gui.LightInfluence=.5; gui.Parent=p
        local label=Instance.new('TextLabel'); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=text
        label.Font=Enum.Font.Garamond; label.TextSize=36; label.TextColor3=Color3.fromRGB(224,193,130); label.Parent=gui
    end
    local function panelWall(cf,length,height)
        part('InteriorWall',Vector3.new(length,height,1.3),cf*CFrame.new(0,height*.5,0),theme.wall,if underground then Enum.Material.Brick else Enum.Material.Plaster,true)
        for _,y in {.3,5.3,height-.7} do
            part('WallMolding',Vector3.new(length,.3,1.65),cf*CFrame.new(0,y,0),if underground then stone else trim)
        end
        if not underground then
            part('Wainscot',Vector3.new(length,4.7,1.45),cf*CFrame.new(0,2.65,0),wood)
            for x=-length*.5+1,length*.5-1,4 do
                part('PanelStile',Vector3.new(.16,4.1,1.6),cf*CFrame.new(x,2.65,0),trim)
            end
        end
    end
    local function arch(cf,width,height)
        for _,s in {-1,1} do
            part('ArchPier',Vector3.new(.8,height-3,1.9),cf*CFrame.new(s*(width*.5+.4),(height-3)*.5,0),if underground then stone else trim)
            beam('ArchShoulder',(cf*CFrame.new(s*width*.5,height-3,0)).Position,(cf*CFrame.new(s*width*.26,height-.6,0)).Position,.5,if underground then stone else trim)
            beam('ArchCrown',(cf*CFrame.new(s*width*.26,height-.6,0)).Position,(cf*CFrame.new(0,height,0)).Position,.5,if underground then stone else trim)
            -- Fill the wall above the pointed opening rather than drawing an
            -- arch beneath an unrelated rectangular hole.
            local edgeTop=Vector3.new(s*width*.5,height,0)
            local shoulder=Vector3.new(s*width*.26,height-.6,0)
            triangle(cf,Vector3.new(s*width*.5,height-3,0),edgeTop,shoulder)
            triangle(cf,edgeTop,Vector3.new(0,height,0),shoulder)
        end
    end
    -- Wall segments leave actual window openings, with a night garden beyond the glass.
    local function window(cf,clerestory)
        local bottom=if clerestory then 13 else 6
        local h=if clerestory then 6 else 14
        part('WindowGlass',Vector3.new(10,h,.12),cf*CFrame.new(0,bottom+h*.5,0),moon,Enum.Material.Glass,true).Transparency=.5
        for _,x in {-5.2,5.2} do part('WindowJamb',Vector3.new(.55,h+.8,2),cf*CFrame.new(x,bottom+h*.5,0),stone) end
        for _,y in {bottom,bottom+h} do part('WindowLintel',Vector3.new(11,.5,2),cf*CFrame.new(0,y,0),stone) end
        for _,x in {-2.5,0,2.5} do part('LeadedMullion',Vector3.new(.14,h,.22),cf*CFrame.new(x,bottom+h*.5,-.18),iron,Enum.Material.Metal) end
        for y=bottom+3,bottom+h-1,3.5 do part('LeadedTransom',Vector3.new(10,.14,.22),cf*CFrame.new(0,y,-.18),iron,Enum.Material.Metal) end
        local glow=part('MoonlitWindow',Vector3.new(9,h-1,.12),cf*CFrame.new(0,bottom+h*.5,2),moon,Enum.Material.Neon)
        glow.Transparency=.75; light(glow,moon,34,1.6)
        part('NightBeyondWindow',Vector3.new(13,h+4,.2),cf*CFrame.new(0,bottom+h*.5,5),Color3.fromRGB(9,17,37))
        for _,x in {-3.5,3.2} do
            part('DistantTreeTrunk',Vector3.new(.3,h+2,.2),cf*CFrame.new(x,bottom+h*.5,4.5),iron)
            for _,s in {-1,1} do
                beam('BareBranch',(cf*CFrame.new(x,bottom+4,4.3)).Position,(cf*CFrame.new(x+s*2,bottom+h-1,4.3)).Position,.2,iron)
            end
        end
        if not underground then
            for _,s in {-1,1} do
                for fold=0,2 do part('VelvetCurtain',Vector3.new(.6,h+.7,.65),cf*CFrame.new(s*(5.8+fold*.45),bottom+h*.5,-1),theme.rug,Enum.Material.Fabric) end
            end
            part('CurtainRail',Vector3.new(14,.2,.2),cf*CFrame.new(0,bottom+h+1,-1),gold,Enum.Material.Metal)
        end
    end
    local function portrait(cf,index)
        part('PortraitFrame',Vector3.new(6,8,.4),cf,gold,Enum.Material.Metal)
        part('PortraitCanvas',Vector3.new(5.3,7.3,.12),cf*CFrame.new(0,0,-.25),Color3.fromRGB(27+index*4,31,44),Enum.Material.Fabric)
        local head=part('PortraitSilhouette',Vector3.new(1.8,2.3,.13),cf*CFrame.new(0,1,-.34),Color3.fromRGB(80,71,79)); head.Shape=Enum.PartType.Ball
        part('PortraitShoulders',Vector3.new(3.5,2.8,.13),cf*CFrame.new(0,-1.4,-.34),Color3.fromRGB(42,39,48))
        for _,s in {-1,1} do part('PortraitEyes',Vector3.new(.13,.1,.1),cf*CFrame.new(s*.4,1.1,-.44),gold) end
    end
    local function tableAt(x,z,w,d)
        box('CarvedTableTop',x,3.3,z,w,.45,d,wood,Enum.Material.Wood,true)
        for _,sx in {-1,1} do for _,sz in {-1,1} do
            box('TurnedTableLeg',x+sx*(w*.5-.6),1.55,z+sz*(d*.5-.6),.45,3.1,.45,trim)
        end end
    end
    local function chair(cf)
        part('UpholsteredSeat',Vector3.new(3,1,3),cf*CFrame.new(0,1.9,0),theme.rug,Enum.Material.Fabric,true)
        part('ChairBack',Vector3.new(3,4,.5),cf*CFrame.new(0,3.4,1.3),wood,Enum.Material.Wood,true)
        part('ChairBackCushion',Vector3.new(2.5,2.6,.2),cf*CFrame.new(0,3.7,.98),theme.rug,Enum.Material.Fabric)
        for _,x in {-1,1} do for _,z in {-1,1} do part('ChairLeg',Vector3.new(.3,1.5,.3),cf*CFrame.new(x,.75,z),trim) end end
    end
    local function shelf(cf,width)
        part('BookcaseBack',Vector3.new(width,12,1),cf*CFrame.new(0,6,1),wood,Enum.Material.Wood,true)
        for _,x in {-width*.5,width*.5} do part('BookcaseUpright',Vector3.new(.5,12,2.6),cf*CFrame.new(x,6,0),trim) end
        for y=1,12,2.5 do
            part('BookcaseShelf',Vector3.new(width,.25,2.8),cf*CFrame.new(0,y,0),trim)
            if y>10 then continue end
            for i=1,math.floor(width/1.1)-1 do
                local x=-width*.5+i*1.1
                local color=({Color3.fromRGB(93,37,38),Color3.fromRGB(46,72,64),Color3.fromRGB(57,55,85),Color3.fromRGB(126,88,43)})[(i+math.floor(y))%4+1]
                part('LeatherBoundBook',Vector3.new(.7,1.5+(i%3)*.2,1.6),cf*CFrame.new(x,y+1,-.2)*CFrame.Angles(0,0,if i%5==0 then .1 else 0),color)
                part('BookSpineGilt',Vector3.new(.5,.07,.1),cf*CFrame.new(x,y+1.5,-1.05),gold)
            end
        end
    end
    local function fireplace(cf)
        part('FireplaceBack',Vector3.new(12,12,2),cf*CFrame.new(0,6,1),stone,Enum.Material.Brick,true)
        part('SootyHearth',Vector3.new(8,7,.2),cf*CFrame.new(0,3.6,-.2),iron)
        part('HearthSlab',Vector3.new(13,.4,5),cf*CFrame.new(0,.2,-1),stone)
        for _,s in {-1,1} do part('FireplaceColumn',Vector3.new(1.5,8,2),cf*CFrame.new(s*5,4,-.5),stone) end
        part('CarvedMantel',Vector3.new(14,.7,3),cf*CFrame.new(0,8.1,-.6),trim)
        for _,x in {-2,0,2} do
            local ember=part('HearthEmbers',Vector3.new(1.5,.3,1.7),cf*CFrame.new(x,.55,-1),Color3.fromRGB(237,94,27),Enum.Material.Neon)
            if x==0 then
                light(ember,Color3.fromRGB(255,133,65),25,1.8)
                local fire=Instance.new('Fire'); fire.Size=3; fire.Heat=1; fire.Color=Color3.fromRGB(255,168,68); fire.SecondaryColor=Color3.fromRGB(160,47,18); fire.Parent=ember
            end
        end
        local log=part('HearthLog',Vector3.new(6,.7,.7),cf*CFrame.new(0,.85,-1.5),Color3.fromRGB(36,25,23)); log.Shape=Enum.PartType.Cylinder
        portrait(cf*CFrame.new(0,13,-.25),floor)
    end

    box('Floor',0,-1,0,132,2,112,if underground then stone else Color3.fromRGB(82,57,42),if underground then Enum.Material.Cobblestone else Enum.Material.WoodPlanks,true)
    box('Ceiling',0,28.5,0,134,1,114,Color3.fromRGB(34,34,44),Enum.Material.Plaster,true)
    -- Side walls: solid piers between the window bays at z -28 and +28.
    for _,s in {-1,1} do
        local wallCf=CFrame.new(s*66,0,0)*CFrame.Angles(0,s*math.pi*.5,0)
        if floor<=4 then
            for _,segment in {{-44.5,23},{0,46},{44.5,23}} do panelWall(wallCf*CFrame.new(segment[1],0,0),segment[2],28) end
            for _,z in {-28,28} do
                local cf=wallCf*CFrame.new(z,0,0)
                local bottom=if floor==4 then 13 else 6
                panelWall(cf,10,bottom)
                part('WindowOverwall',Vector3.new(10,28-(if floor==4 then 19 else 20),1.3),cf*CFrame.new(0,(28+(if floor==4 then 19 else 20))*.5,0),theme.wall,Enum.Material.Plaster,true)
                window(cf,floor==4)
            end
        else
            panelWall(wallCf,112,28)
            for _,z in {-42,-14,14,42} do
                local cf=wallCf*CFrame.new(z,0,-.85)
                part('BurialNicheRecess',Vector3.new(8,9,.2),cf*CFrame.new(0,7,0),iron)
                arch(cf*CFrame.new(0,2,-.2),8,10)
                for y=4,10,3 do part('SealedBurialTablet',Vector3.new(6.7,2,.3),cf*CFrame.new(0,y,-.2),stone,Enum.Material.Slate) end
            end
        end
        if floor==1 and s==-1 then
            for _,x in {-35.5,35.5} do panelWall(CFrame.new(x,0,-56),61,28) end
            panelWall(CFrame.new(0,0,-56),10,6)
            box('GalleryWindowOverwall',0,24,-56,10,8,1.3,theme.wall,Enum.Material.Plaster,true)
            window(CFrame.new(0,0,-56)*CFrame.Angles(0,math.pi,0),false)
        else panelWall(CFrame.new(0,0,s*56),132,28) end
        -- Two connected side wings; bedrooms have four private rooms off the hall.
        local divider=CFrame.new(s*22,0,0)*CFrame.Angles(0,math.pi*.5,0)
        if floor==2 or floor==6 then
            for _,seg in {{-45,22},{0,40},{45,22}} do panelWall(divider*CFrame.new(seg[1],0,0),seg[2],28) end
            for _,z in {-27,27} do
                part('DoorwayHeader',Vector3.new(14,14,1.3),divider*CFrame.new(z,21,0),theme.wall,Enum.Material.Plaster,true)
                arch(divider*CFrame.new(z,0,0),14,14)
            end
            panelWall(CFrame.new(s*44,0,0),42,28)
        else
            for _,z in {-35,35} do panelWall(divider*CFrame.new(z,0,0),42,28) end
            part('GalleryArchHeader',Vector3.new(28,8,1.3),divider*CFrame.new(0,24,0),theme.wall,Enum.Material.Plaster,true)
            arch(divider,28,20)
        end
    end
    -- Ceiling ribs, coffer borders, and hanging lamps give the hall human scale.
    for _,z in {-42,-14,14,42} do
        box('CeilingCrossBeam',0,27.5,z,132,.8,1.1,if underground then stone else trim)
        if underground then arch(CFrame.new(0,0,z),40,27) end
    end
    for _,x in {-22,22} do box('CeilingLongBeam',x,27.5,0,1.1,.8,112,trim) end
    if floor==1 or floor==3 then
        for _,s in {-1,1} do for _,z in {-37,37} do
            portrait(CFrame.new(s*21.15,13,z)*CFrame.Angles(0,s*math.pi*.5,0),floor)
        end end
    end
    for _,z in {-16,23} do
        box('ChandelierChain',0,24,z,.12,7,.12,iron,Enum.Material.Metal)
        for i=0,15 do
            local a,b=i*math.pi/8,(i+1)*math.pi/8
            beam('ChandelierRing',Vector3.new(math.cos(a)*4,20.4,z+math.sin(a)*4),Vector3.new(math.cos(b)*4,20.4,z+math.sin(b)*4),.22,gold)
        end
        local source=box('ChandelierLight',0,19.5,z,.2,.2,.2,warm)
        source.Transparency=1; light(source,warm,46,if underground then 1.2 else 2)
        for i=0,5 do
            local a=i*math.pi/3
            local x,zz=math.cos(a)*4,z+math.sin(a)*4
            box('ChandelierStem',x,21,zz,.15,1.3,.15,gold,Enum.Material.Metal)
            box('ChandelierWax',x,21.6,zz,.32,.8,.32,Color3.fromRGB(216,202,160))
            box('ChandelierCandle',x,22.1,zz,.2,.3,.2,warm,Enum.Material.Neon)
            beam('ChandelierArm',Vector3.new(0,23,z),Vector3.new(x,20.4,zz),.16,gold)
        end
    end
    for _,x in {-64.8,64.8} do for _,z in {-10,10} do
        candle(x,7,z); box('SconceShelf',x,7,z,2,.25,2,trim)
        box('SconceWallPlate',if x<0 then -65.1 else 65.1,6.6,z,.35,2,1.2,gold,Enum.Material.Metal)
    end end
    rug(0,12,14,62)
    if not underground then for _,x in {-43,43} do rug(x,0,26,82) end end
    -- A recognizable door at the perimeter replaces the floating neon exit slab.
    local exit=box('ReturnDoor',0,6,54.9,10,12,.6,wood,Enum.Material.WoodPlanks,true)
    for _,x in {-5.4,5.4} do box('ExitJamb',x,6,54.2,.5,12.8,1,gold) end
    box('ExitLintel',0,12.3,54.2,11.4,.6,1,gold)
    for _,x in {-2.5,2.5} do
        box('ReturnDoorPanel',x,6,54.4,4.2,10,.3,Color3.fromRGB(83,49,37))
        box('ReturnDoorHandle',x*.3,5.7,54,.15,1,.2,gold,Enum.Material.Metal)
    end
    plaque('RETURN TO THE GROUNDS',CFrame.new(0,14.5,54),23)
    for i,name in theme.names do plaque(name,CFrame.new((i-2)*43,24,-54.9)*CFrame.Angles(0,math.pi,0),20) end
    for _,x in {-11,11} do candle(x,5,51); box('EntryConsole',x,2.5,52,4,5,3,wood,Enum.Material.Wood,true) end

    if floor==1 then
        -- Paired stair flights reach a real rear gallery; parlor and dining flank it.
        for _,s in {-1,1} do
            for i=1,12 do box('GrandStairTread',s*13,i*.3,-25-i*2,8,i*.6,2.1,wood,Enum.Material.Wood,true) end
            for _,x in {s*8,s*18} do
                beam('StairHandrail',Vector3.new(x,3,-25),Vector3.new(x,10.2,-49),.35,gold)
                for i=0,6 do box('StairBaluster',x,1.5+i*1.2,-25-i*4,.2,3,.2,trim) end
            end
        end
        box('RearGalleryLanding',0,7,-51,40,.5,8,wood,Enum.Material.Wood,true)
        for x=-7,7,2 do box('GalleryBaluster',x,8.6,-47,.2,3,.2,trim) end
        box('GalleryRail',0,10.1,-47,16,.3,.3,gold)
        for _,x in {-29,29} do portrait(CFrame.new(x,12,-54.8)*CFrame.Angles(0,math.pi,0),1) end
        fireplace(CFrame.new(-62,0,0)*CFrame.Angles(0,-math.pi*.5,0))
        for _,z in {-9,9} do chair(CFrame.new(-45,0,z)*CFrame.Angles(0,if z<0 then math.pi else 0,0)) end
        tableAt(-45,0,6,5); candle(-45,3.55,0)
        box('ParlorPiano',-43,3,-50,14,6,4,iron,Enum.Material.Wood,true)
        box('PianoKeyboard',-43,3,-47.4,13,.4,1.8,Color3.fromRGB(202,192,160))
        for i=-12,12 do
            box('PianoKeySeam',-43+i*.5,3.23,-47,.035,.02,1.1,iron)
            if i%3~=0 then box('PianoBlackKey',-43+i*.5,3.4,-47.8,.24,.3,.8,iron) end
        end
        box('PianoBench',-43,1.4,-43,7,2.8,3,wood,Enum.Material.Wood,true)
        portrait(CFrame.new(-43,13,-54.8)*CFrame.Angles(0,math.pi,0),1)
        tableAt(44,0,11,20)
        for _,s in {-1,1} do for _,z in {-6,0,6} do chair(CFrame.new(44+s*8,0,z)*CFrame.Angles(0,-s*math.pi*.5,0)) end end
        for _,z in {-6,6} do candle(44,3.55,z) end
        for _,x in {41,47} do for _,z in {-6,0,6} do
            local plate=part('PorcelainPlate',Vector3.new(.08,1.5,1.5),CFrame.new(x,3.58,z)*CFrame.Angles(0,0,math.pi*.5),Color3.fromRGB(196,190,170)); plate.Shape=Enum.PartType.Cylinder
        end end
        box('DiningSideboard',44,3,-50,22,6,4,wood,Enum.Material.Wood,true)
        for _,x in {37,44,51} do
            box('SideboardPanel',x,3,-47.9,6,4.8,.15,trim)
            box('SideboardHandle',x,3,-47.6,.2,.5,.2,gold,Enum.Material.Metal)
        end
        portrait(CFrame.new(44,14,-54.8)*CFrame.Angles(0,math.pi,0),1)
    elseif floor==2 then
        for _,s in {-1,1} do for _,z in {-40,40} do
            local x=s*53
            box('FourPosterBed',x,1.4,z,9,2,13,wood,Enum.Material.Wood,true)
            box('BedMattress',x,2.6,z,8.4,.6,12.4,Color3.fromRGB(177,164,144),Enum.Material.Fabric)
            box('VelvetCoverlet',x,3,z,8.5,.35,8,theme.rug,Enum.Material.Fabric)
            for _,dx in {-4.4,4.4} do for _,dz in {-6.2,6.2} do box('BedPost',x+dx,5,z+dz,.4,10,.4,trim) end end
            box('BedCanopy',x,10,z,10,.5,14,theme.rug,Enum.Material.Fabric)
            box('BedHeadboard',x,4,z+(if z<0 then -6 else 6),9,6,.7,wood)
            box('BedsideCabinet',x-s*8,2,z,4,4,4,wood,Enum.Material.Wood,true); candle(x-s*8,4,z)
            box('Wardrobe',s*29,5,z+(if z<0 then -9 else 9),8,10,4,wood,Enum.Material.Wood,true)
            box('WardrobeMirror',s*29,6,z+(if z<0 then -6.9 else 6.9),4,6,.15,Color3.fromRGB(104,120,140),Enum.Material.Glass)
        end end
        for _,s in {-1,1} do for _,z in {-3,3} do
            tableAt(s*43,z,12,4)
            local cf=CFrame.new(s*43,8,if z<0 then -1 else 1)*CFrame.Angles(0,if z<0 then 0 else math.pi,0)
            part('DressingMirrorFrame',Vector3.new(7,8,.35),cf,gold,Enum.Material.Metal)
            part('DressingMirror',Vector3.new(6.2,7.2,.1),cf*CFrame.new(0,0,-.25),Color3.fromRGB(98,114,133),Enum.Material.Glass)
            chair(CFrame.new(s*43,0,z*3)*CFrame.Angles(0,if z<0 then math.pi else 0,0))
            candle(s*43+4,3.55,z)
        end end
        for _,s in {-1,1} do for _,z in {-12,12,37} do portrait(CFrame.new(s*21.15,11,z)*CFrame.Angles(0,s*math.pi*.5,0),2) end end
        box('LinenChest',0,2.4,-49,12,4.8,6,wood,Enum.Material.Wood,true)
    elseif floor==3 then
        for _,s in {-1,1} do
            for _,z in {-43,0,43} do shelf(CFrame.new(s*62,0,z)*CFrame.Angles(0,s*math.pi*.5,0),18) end
            for _,z in {-52,52} do shelf(CFrame.new(s*43,0,z)*CFrame.Angles(0,if z<0 then math.pi else 0,0),27) end
            tableAt(s*43,0,13,7); candle(s*43,3.55,0)
            for _,z in {-6,6} do chair(CFrame.new(s*43,0,z)*CFrame.Angles(0,if z<0 then math.pi else 0,0)) end
            for _,z in {-20,16} do
                tableAt(s*16,z,6,9); candle(s*16,3.55,z)
                box('OpenBook',s*16,3.7,z+2,2,.2,1.4,Color3.fromRGB(188,174,141))
            end
        end
        fireplace(CFrame.new(0,0,-53)*CFrame.Angles(0,math.pi,0))
        box('LibraryClockCase',-15,8,-49,4,16,3,wood,Enum.Material.Wood,true)
        local dial=part('ClockFace',Vector3.new(.2,3,3),CFrame.new(-15,12,-47.3)*CFrame.Angles(0,math.pi*.5,0),Color3.fromRGB(210,191,148)); dial.Shape=Enum.PartType.Cylinder
        box('ClockMinuteHand',-15,12.45,-47.1,.1,.9,.08,iron)
        box('ClockHourHand',-14.6,12,-47.1,.8,.1,.08,iron)
        box('ClockPendulumRod',-15,7,-47.2,.12,6,.15,gold,Enum.Material.Metal)
        local pendulum=box('ClockPendulum',-15,4,-47.2,1.3,1.3,.3,gold,Enum.Material.Metal); pendulum.Shape=Enum.PartType.Ball
    elseif floor==4 then
        for _,z in {-39,-13,13,39} do
            box('BarrelCradle',-57,.35,z,12.5,.7,5.2,wood,Enum.Material.Wood,true)
            for _,x in {-60,-54} do
                local barrel=part('WineBarrel',Vector3.new(6,4.6,4.6),CFrame.new(x,3,z),Color3.fromRGB(91,60,36),Enum.Material.WoodPlanks,true); barrel.Shape=Enum.PartType.Cylinder
                for _,dx in {-2,2} do local band=part('BarrelHoop',Vector3.new(.25,4.8,4.8),CFrame.new(x+dx,3,z),iron,Enum.Material.Metal); band.Shape=Enum.PartType.Cylinder end
            end
        end
        for _,z in {-42,42} do
            tableAt(44,z,28,6)
            box('WorkshopPegboard',44,7,z+(if z<0 then -4 else 4),26,6,.5,wood)
            for i=1,8 do box('HangingTool',31+i*3,7,z+(if z<0 then -3.6 else 3.6),.25,2+(i%2),.3,iron,Enum.Material.Metal) end
            candle(44,3.55,z)
        end
        box('OldBoiler',0,5,-46,10,10,8,iron,Enum.Material.Metal,true)
        for _,x in {-13,13} do
            box('CeilingPipe',x,24,0,1,1,108,Color3.fromRGB(107,69,43),Enum.Material.Metal)
            box('PipeDownturn',x,15,-48,1,18,1,Color3.fromRGB(107,69,43),Enum.Material.Metal)
        end
        for _,s in {-1,1} do box('SupplyCrate',s*43,2.5,0,9,5,8,wood,Enum.Material.WoodPlanks,true) end
    else
        for _,s in {-1,1} do for _,z in {-34,0,34} do
            box('CarvedSarcophagus',s*56,2,z,7,4,12,stone,Enum.Material.Marble,true)
            box('TombLid',s*56,4.2,z,7.5,.5,12.5,Color3.fromRGB(105,101,117),Enum.Material.Slate)
            box('MemorialCross',s*56,4.5,z,.45,.12,5,gold)
            box('MemorialCrossArm',s*56,4.5,z-1,2,.12,.35,gold)
        end end
        box('AltarDais',0,.25,-43,30,.5,17,stone,Enum.Material.Marble,true)
        box('MemorialAltar',0,3,-44,15,5,5,stone,Enum.Material.Marble,true)
        for _,x in {-5,5} do candle(x,5.5,-44) end
        if floor==5 then
            for _,s in {-1,1} do for _,z in {-29,-14,1,16} do
                box('ChapelPew',s*14,1.7,z,10,.6,3.6,wood,Enum.Material.Wood,true)
                box('PewBack',s*14,3,z+1.5,10,3,.4,wood,Enum.Material.Wood,true)
                for _,dx in {-4,4} do box('PewFoot',s*14+dx,.8,z,.5,1.6,3,wood) end
            end end
            -- A memorial glass panel is lit from its recessed chapel niche.
            for i=-3,3 do box('MemorialStainedGlass',i*2,16,-54.6,1.8,13,.2,if i%2==0 then Color3.fromRGB(62,111,155) else Color3.fromRGB(109,57,123),Enum.Material.Neon) end
            arch(CFrame.new(0,8,-54.2),15,15)
        else
            for _,x in {-12,12} do for _,z in {-37,0,37} do
                box('VaultPillar',x,10,z,2,20,2,stone,Enum.Material.Brick,true)
                box('PillarCapital',x,20,z,3,.8,3,stone)
            end end
            box('ReliquaryCabinet',0,8,-52,9,12,3,gold,Enum.Material.Metal,true)
            local relic=box('SpectralRelic',0,10,-49.8,2,3,2,Color3.fromRGB(106,217,193),Enum.Material.Neon); relic.Shape=Enum.PartType.Ball
            light(relic,Color3.fromRGB(106,217,193),27,1.6)
        end
    end
    -- Open floor pockets are deliberately clear of furniture on every theme.
    local zones={}
    for _,p in {{0,12,5,8},{0,-15,5,6},{-43,-23,5,6},{-43,23,5,6},{43,-23,5,6},{43,23,5,6},{0,33,5,3}} do
        table.insert(zones,{Center=center+Vector3.new(p[1],4,p[2]),X=p[3],Z=p[4]})
    end
    return {Model=area,Center=center,Entry=center+Vector3.new(0,3,43),Exit=exit,Lights=lights,FlickerLight=flickerLight,GhostZones=zones}
end
return Interior

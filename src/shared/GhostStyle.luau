-- Reference direction: HalloweenSprites1/2/3. Local front is -Z.
-- Shared procedural models render in both Workspace and inventory WorldModels.
local Style={}
local cream=Color3.fromRGB(238,231,255)
local ink=Color3.fromRGB(22,16,43)
local gold=Color3.fromRGB(224,174,78)
local pink=Color3.fromRGB(245,148,192)
local white=Color3.fromRGB(255,252,255)
local dark=Color3.fromRGB(55,38,82)
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end

function Style.build(m,g,accent)
    local shape=g.Shape
    local bodyColor=cream:Lerp(accent,0.16)
    if shape=='Eclipse' or shape=='Door' then bodyColor=rgb(48,31,76)
    elseif shape=='Stag' then bodyColor=rgb(82,63,112)
    elseif shape=='Candle' then bodyColor=rgb(255,231,187) end
    local function part(name,size,pos,color,form,rotation,glow)
        local p=Instance.new('Part')
        p.Name=name; p.Size=size; p.CFrame=CFrame.new(pos)*(rotation or CFrame.new())
        p.Color=color or bodyColor; p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
        p.Shape=form or Enum.PartType.Ball
        p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CastShadow=false
        p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
        p.Parent=m
        return p
    end
    local function ball(name,x,y,z,sx,sy,sz,color,glow)
        return part(name,Vector3.new(sx,sy,sz),Vector3.new(x,y,z),color,nil,nil,glow)
    end
    local function block(name,x,y,z,sx,sy,sz,color,rotation)
        return part(name,Vector3.new(sx,sy,sz),Vector3.new(x,y,z),color,Enum.PartType.Block,rotation)
    end
    -- Thin accessory segments have rounded tips and stay aligned between their endpoints.
    local function line(name,a,b,width,color,glow)
        local p=part(name,Vector3.new(width,width,(b-a).Magnitude),(a+b)/2,color,Enum.PartType.Block,CFrame.lookAt(a,b).Rotation,glow)
        ball(name..'Tip',b.X,b.Y,b.Z,width,width,width,color,glow)
        return p
    end
    local function ring(name,center,rx,ry,width,color,segments)
        local count=segments or 16
        for i=1,count do
            local a=(i-1)*2*math.pi/count; local b=i*2*math.pi/count
            line(name,center+Vector3.new(math.cos(a)*rx,math.sin(a)*ry,0),center+Vector3.new(math.cos(b)*rx,math.sin(b)*ry,0),width,color)
        end
    end
    local function bow(x,y,z,color)
        for _,s in {-1,1} do
            part('BowLoop',Vector3.new(.65,.43,.25),Vector3.new(x+s*.32,y,z),color,nil,CFrame.Angles(0,0,s*.3))
        end
        ball('BowKnot',x,y,z,.28,.3,.3,color)
    end
    local function flame(x,y,z,size,color)
        part('SpiritFlame',Vector3.new(.45,1,.4)*size,Vector3.new(x,y,z),color,nil,CFrame.Angles(0,0,-.22),true)
        ball('FlameHeart',x,y-.17*size,z-.08*size,.23*size,.45*size,.24*size,white,true)
    end
    local function book(x,y,z,angle)
        local turn=CFrame.Angles(0,angle or 0,-.15)
        block('BookCover',x,y,z,.85,1.05,.25,dark,turn)
        block('BookPages',x,y,z-.15,.69,.86,.12,rgb(240,215,176),turn)
        block('BookSpine',x-.36,y,z-.02,.12,1.08,.3,gold,turn)
        ball('CoverGem',x,y,z-.24,.16,.25,.08,accent,true)
    end
    local function lantern(x,y,z)
        ball('LanternLight',x,y,z,.4,.7,.4,rgb(255,192,94),true)
        for _,s in {-1,1} do for _,t in {-1,1} do
            block('LanternFrame',x+s*.28,y,z+t*.22,.07,.88,.07,gold)
        end end
        block('LanternBase',x,y-.46,z,.68,.13,.58,dark)
        ball('LanternCap',x,y+.48,z,.76,.3,.66,dark)
        ring('LanternHandle',Vector3.new(x,y+.76,z),.16,.22,.055,gold,8)
    end
    local root=ball('Core',0,0,0,2.35,3.1,1.85,bodyColor)
    m.PrimaryPart=root
    for i=-2,2 do
        local x=i*.39
        ball('ScallopedHem',x,-1.24+math.abs(i)*.1,.03,.56,1.12,1.02,bodyColor)
    end
    for _,s in {-1,1} do
        part('Hand',Vector3.new(.56,1,.64),Vector3.new(s*1.18,-.42,-.05),bodyColor,nil,CFrame.Angles(0,0,-s*.48))
        ball('Eye',s*.47,.37,-.85,.45,.59,.23,ink)
        ball('EyeIris',s*.47,.28,-.964,.28,.26,.06,accent)
        ball('EyeCatchlight',s*.47-.07,.51,-.97,.13,.17,.065,white)
        ball('EyeSparkle',s*.47+.09,.26,-.983,.06,.065,.04,white)
        ball('Blush',s*.77,-.03,-.77,.29,.14,.085,pink)
    end
    ball('Smile',0,-.14,-.932,.3,.24,.075,ink)
    ball('Tongue',0,-.205,-.972,.16,.08,.035,pink)

    if shape=='Moth' then
        for _,s in {-1,1} do
            part('UpperWing',Vector3.new(1.6,2,.25),Vector3.new(s*1.5,.3,.45),rgb(179,207,246),nil,CFrame.Angles(0,0,-s*.45))
            part('WingInset',Vector3.new(1.13,1.48,.13),Vector3.new(s*1.58,.34,.28),cream,nil,CFrame.Angles(0,0,-s*.45))
            ball('WingEye',s*1.8,.45,.19,.32,.47,.1,accent)
            ball('LowerWing',s*1.32,-.7,.42,1.14,1.16,.28,rgb(160,156,218))
            line('Antenna',Vector3.new(s*.4,1.25,0),Vector3.new(s*.7,2,-.06),.085,dark)
            ball('AntennaLight',s*.7,2,-.06,.22,.25,.2,accent,true)
        end
    elseif shape=='Cup' then
        ball('PorcelainCup',0,-.83,-.05,2.5,1.34,2.05,rgb(252,235,222))
        ball('TeaSurface',0,-.23,-.05,2.05,.1,1.58,rgb(121,74,69))
        ball('Saucer',0,-1.46,0,3.15,.19,2.5,cream)
        ring('CupHandle',Vector3.new(1.35,-.77,0),.46,.47,.13,gold,12)
        bow(0,-.87,-1.05,pink)
    elseif shape=='Lantern' then
        bow(0,-.54,-.87,dark); lantern(1.75,-.35,-.1)
        part('Cap',Vector3.new(1.55,.3,1.5),Vector3.new(0,1.47,0),dark)
        bow(-.65,1.52,-.18,accent)
    elseif shape=='Doll' then
        ball('ButtonEye',-.47,.37,-1.01,.48,.58,.1,dark)
        for _,s in {-1,1} do line('ButtonStitch',Vector3.new(-.61,.37+s*.14,-1.08),Vector3.new(-.33,.37-s*.14,-1.08),.055,pink) end
        bow(.77,1.23,-.16,accent)
        for i=-2,2 do ball('YarnHair',i*.32,1.25,-.12,.42,.72,1.3,rgb(169,125,201)) end
        for i=-1,1 do ball('DressButton',0,-.65+i*.22,-.9,.11,.11,.09,gold) end
    elseif shape=='Clock' then
        ring('ClockBezel',Vector3.new(0,-.84,-.91),.62,.62,.09,gold,12)
        ball('ClockFace',0,-.84,-.9,1.15,1.15,.12,cream)
        line('MinuteHand',Vector3.new(0,-.84,-1.01),Vector3.new(0,-.41,-1.01),.065,dark)
        line('HourHand',Vector3.new(0,-.84,-1.02),Vector3.new(.29,-.96,-1.02),.065,dark)
        for _,s in {-1,1} do ball('ClockBell',s*.7,1.45,0,.7,.48,.65,gold) end
        line('Pendulum',Vector3.new(0,-1.5,0),Vector3.new(0,-2.03,0),.08,gold)
        ball('PendulumWeight',0,-2.05,0,.45,.45,.23,gold)
    elseif shape=='Vine' or shape=='Stag' then
        for _,s in {-1,1} do
            local a=Vector3.new(s*.65,1.15,.05); local b=Vector3.new(s*1.12,2.25,.1)
            line('Antler',a,b,.14,if shape=='Stag' then gold else rgb(102,72,63))
            for i=1,2 do
                local start=a:Lerp(b,i*.3)
                line('AntlerBranch',start,start+Vector3.new(s*.47,.32,0),.1,if shape=='Stag' then gold else rgb(102,72,63))
                if shape=='Vine' then part('IvyLeaf',Vector3.new(.55,.24,.42),start+Vector3.new(s*.4,.35,-.04),rgb(111,182,115),nil,CFrame.Angles(0,0,s*.5)) end
            end
            if shape=='Stag' then
                part('DeerEar',Vector3.new(.78,.32,.48),Vector3.new(s*1.1,.9,0),bodyColor,nil,CFrame.Angles(0,0,s*.3))
            else
                for i=1,3 do part('IvyLeaf',Vector3.new(.5,.24,.35),Vector3.new(s*(.7+i*.12),-.9+i*.4,-.7),rgb(93,162,110),nil,CFrame.Angles(0,0,s*i*.4)) end
            end
        end
        if shape=='Stag' then
            ball('Muzzle',0,-.15,-.86,.8,.48,.62,rgb(157,125,177))
            ball('Nose',0,-.08,-1.16,.28,.19,.16,ink)
        end
    elseif shape=='Veil' then
        for i=-3,3 do
            local x=i*.37
            part('SilkenHair',Vector3.new(.52,3.05,1.12),Vector3.new(x,-.05,.55),rgb(176,151,225),nil,CFrame.Angles(0,0,-i*.065))
        end
        for _,s in {-1,1} do
            part('FaceFramingLock',Vector3.new(.43,2.4,.6),Vector3.new(s*1.05,.32,-.3),rgb(208,192,248),nil,CFrame.Angles(0,0,-s*.17))
        end
        bow(0,-.75,-.89,dark)
        ball('TiaraGem',0,1.48,-.16,.38,.47,.22,accent,true)
    elseif shape=='Book' then
        book(-1.35,-.8,-.54,-.2); book(1.5,.6,.1,.25)
        for _,s in {-1,1} do ring('Spectacles',Vector3.new(s*.47,.37,-1),.33,.39,.055,gold,10) end
        line('SpectacleBridge',Vector3.new(-.14,.44,-1),Vector3.new(.14,.44,-1),.055,gold)
        part('Quill',Vector3.new(.32,1.6,.18),Vector3.new(1.3,-.9,-.3),cream,nil,CFrame.Angles(0,0,-.5))
    elseif shape=='Crown' or shape=='Knight' then
        ball('RoyalCollar',0,-.68,.04,2.65,.48,1.92,dark)
        bow(0,-.64,-1,gold)
        for _,s in {-1,1} do ball('Pauldrons',s*1.17,-.28,.12,.85,.65,.9,if shape=='Knight' then rgb(99,113,151) else gold) end
        ball('CrownBand',0,1.34,0,1.92,.3,1.48,gold)
        for i=-2,2 do
            local x=i*.34
            line('CrownPoint',Vector3.new(x,1.35,-.49),Vector3.new(x,1.9-math.abs(i)*.1,-.49),.17,gold)
            ball('CrownJewel',x,1.79-math.abs(i)*.1,-.6,.14,.19,.1,accent,true)
        end
        if shape=='Knight' then
            line('BellStaff',Vector3.new(1.7,-1.5,0),Vector3.new(1.7,1.7,0),.13,gold)
            ball('Bell',1.7,1.2,0,.68,.78,.58,gold)
            ball('BellRim',1.7,.88,0,.85,.14,.72,dark)
            ball('BellClapper',1.7,.74,0,.2,.2,.2,accent,true)
        end
    elseif shape=='Eclipse' then
        ring('EclipseHalo',Vector3.new(0,.25,.85),1.85,1.85,.09,gold,20)
        for i=1,6 do local a=i*math.pi/3; ball('OrbitStar',math.cos(a)*2,math.sin(a)*2+.25,.85,.18,.28,.15,accent,true) end
        bow(0,-.64,-.91,rgb(133,86,168))
    elseif shape=='Candle' then
        ball('WaxCrown',0,1.38,0,1.85,.25,1.42,cream)
        for i=-2,2 do ball('WaxDrip',i*.34,1.13-math.abs(i%2)*.13,-.6,.26,.62,.28,cream) end
        block('Wick',0,1.61,0,.08,.34,.08,ink)
        flame(0,2.12,0,.85,rgb(255,177,66))
        for _,s in {-1,1} do
            ball('FloatingCandle',s*1.65,-.35,0,.42,1.14,.42,cream)
            flame(s*1.65,.52,0,.47,rgb(255,177,66))
        end
    elseif shape=='Door' then
        for _,s in {-1,1} do
            block('PortalPillar',s*1.38,-.15,.58,.3,3.7,.45,dark)
            line('PortalRune',Vector3.new(s*1.39,-1.8,.3),Vector3.new(s*1.39,1.6,.3),.055,accent,true)
        end
        for i=1,8 do
            local a=(i-1)*math.pi/8; local b=i*math.pi/8
            line('PortalArch',Vector3.new(math.cos(a)*1.38,1.65+math.sin(a)*.55,.58),Vector3.new(math.cos(b)*1.38,1.65+math.sin(b)*.55,.58),.28,dark)
        end
        ball('Keyhole',0,-.75,-.96,.3,.3,.08,gold)
        block('KeyholeStem',0,-.96,-.96,.16,.25,.08,gold)
    end
    -- Small, non-emissive details stay legible without washing out the silhouette.
    if shape=='Moth' then
        for _,s in {-1,1} do
            for i=1,3 do
                line('WingVein',Vector3.new(s*1.1,0,.15),Vector3.new(s*(1.5+i*.15),.3+i*.22,.15),.035,rgb(137,152,208))
            end
        end
    elseif shape=='Cup' then
        for _,s in {-1,1} do ball('PorcelainRose',s*.7,-.81,-.89,.22,.22,.08,pink) end
        ball('GildedFoot',0,-1.39,0,1.5,.1,1.25,gold)
    elseif shape=='Doll' then
        for i=1,4 do block('DressStitch',.44,-.54-i*.15,-.84,.15,.035,.035,cream,CFrame.Angles(0,0,.25)) end
    elseif shape=='Clock' then
        for i=1,12 do
            local a=i*math.pi/6
            block('ClockTick',math.sin(a)*.48,-.84+math.cos(a)*.48,-1,.04,.09,.03,dark,CFrame.Angles(0,0,-a))
        end
    elseif shape=='Book' then
        for _,x in {-1.35,1.5} do
            local y=if x<0 then -.8 else .6
            local z=if x<0 then -.54 else .1
            for i=1,3 do block('InkLine',x,y-.14-i*.09,z-.23,.42,.025,.025,rgb(145,105,96)) end
        end
    elseif shape=='Knight' then
        for _,s in {-1,1} do
            ball('HelmetCheek',s*.96,.27,-.4,.34,1.3,.65,rgb(103,117,149))
            ball('ArmorRivet',s*1.21,-.21,-.32,.12,.12,.1,gold)
        end
        ball('Breastplate',0,-.95,-.63,1.18,.79,.65,rgb(83,97,132))
        ball('ArmorSigil',0,-.92,-.98,.21,.32,.08,gold)
    elseif shape=='Crown' then
        for _,s in {-1,1} do
            part('RoyalMantle',Vector3.new(.7,1.6,.45),Vector3.new(s*.82,-.77,.58),rgb(106,49,104),nil,CFrame.Angles(0,0,s*.2))
            ball('CloakClasp',s*.35,-.54,-.89,.17,.17,.08,gold)
        end
    elseif shape=='Veil' then
        for _,s in {-1,1} do
            ball('PearlEarring',s*1.04,-.37,-.65,.13,.23,.12,white)
            part('VeilRibbon',Vector3.new(.17,1.15,.11),Vector3.new(s*.3,-1.16,-.78),dark,nil,CFrame.Angles(0,0,s*.18))
        end
    elseif shape=='Vine' or shape=='Stag' then
        for i=-1,1 do ball('ForestGem',i*.22,1.02-math.abs(i)*.12,-.68,.11,.17,.075,accent) end
    elseif shape=='Lantern' then
        for i=1,3 do ball('WaistcoatButton',0,-.8-i*.18,-.84,.09,.09,.06,gold) end
    elseif shape=='Door' then
        for _,s in {-1,1} do for i=1,3 do
            block('CarvedRune',s*1.39,-1.25+i*.67,.27,.15,.15,.05,gold,CFrame.Angles(0,0,math.pi/4))
        end end
    elseif shape=='Candle' then
        ball('WaxSeal',0,-.8,-.85,.4,.45,.12,rgb(151,63,86))
        block('SealMark',0,-.8,-.93,.05,.23,.03,gold)
    elseif shape=='Eclipse' then
        ball('MoonBrooch',0,-.88,-.86,.4,.4,.13,gold)
        ball('MoonCutout',.12,-.81,-.94,.33,.33,.08,bodyColor)
    end
    if g.Rarity>=4 then
        for _,s in {-1,1} do flame(s*1.4,-1.37,.55,.4,accent) end
    end
    local light=Instance.new('PointLight'); light.Color=accent; light.Range=7; light.Brightness=.22; light.Parent=root
    m:SetAttribute('VisualStyle','ReferenceChibiV1')
    return root
end
return Style

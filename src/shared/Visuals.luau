local Config=require(script.Parent.Config)
local V={}
function V.color(rarity) return Color3.fromRGB(table.unpack(Config.Colors[rarity])) end
function V.part(parent,name,size,cf,color,material)
    local p=Instance.new('Part')
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
function V.label(part,text,color,width,height)
    local gui=Instance.new('BillboardGui')
    gui.Name='Label'; gui.Size=UDim2.fromOffset(width or 230,height or 60)
    gui.StudsOffset=Vector3.new(0,3,0); gui.MaxDistance=90; gui.AlwaysOnTop=false; gui.Parent=part
    local label=Instance.new('TextLabel')
    label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=text
    label.TextColor3=color or Color3.new(1,1,1); label.TextStrokeTransparency=0.4
    label.Font=Enum.Font.GothamBold; label.TextSize=16; label.TextWrapped=true; label.Parent=gui
    return label
end
function V.ghost(id,parent,cf,scale,withLabel)
    local g=Config.Ghosts[id]
    local m=Instance.new('Model'); m.Name=g.Name; m:SetAttribute('Species',id)
    local c=V.color(g.Rarity)
    local root=V.part(m,'Core',Vector3.new(2.5,2.8,2),CFrame.new(),c,Enum.Material.Neon)
    root.Shape=Enum.PartType.Ball; root.Transparency=0.32; root.CanCollide=false
    m.PrimaryPart=root
    local function piece(name,size,pos,color,ball,rotation)
        local p=V.part(m,name,size,CFrame.new(pos)*(rotation or CFrame.new()),color or c,Enum.Material.Neon)
        p.CanCollide=false
        if ball then p.Shape=Enum.PartType.Ball end
        return p
    end
    for _,x in {-0.48,0.48} do piece('Eye',Vector3.new(0.34,0.48,0.2),Vector3.new(x,0.3,-0.91),Color3.fromRGB(18,13,37),true) end
    piece('Tail',Vector3.new(1.25,1.8,1),Vector3.new(0,-1.4,0),c,true)
    local shape=g.Shape
    if shape=='Moth' then
        for _,s in {-1,1} do piece('Wing',Vector3.new(2.6,1.7,0.25),Vector3.new(s*1.6,0.3,0.2),c,true,CFrame.Angles(0,0,s*0.4)) end
    elseif shape=='Cup' then
        root.Shape=Enum.PartType.Cylinder; root.CFrame=CFrame.Angles(0,0,math.pi/2)
        piece('Handle',Vector3.new(1,1.3,0.4),Vector3.new(1.5,0,0),Color3.fromRGB(240,222,201),true)
        piece('Saucer',Vector3.new(3.5,0.2,2.8),Vector3.new(0,-1.35,0),Color3.fromRGB(240,222,201),true)
    elseif shape=='Lantern' then
        for _,x in {-1,1} do piece('Iron',Vector3.new(0.2,3.4,0.2),Vector3.new(x,0,-0.8),Color3.fromRGB(43,40,57)) end
        piece('Cap',Vector3.new(2.8,0.4,2.5),Vector3.new(0,1.6,0))
    elseif shape=='Doll' then
        root.Size=Vector3.new(1.8,1.8,1.8)
        piece('Dress',Vector3.new(2,2.1,1.2),Vector3.new(0,-1.8,0))
        for _,s in {-1,1} do piece('Arm',Vector3.new(0.5,1.8,0.5),Vector3.new(s*1.35,-1.4,0),c,true) end
    elseif shape=='Clock' then
        root.Size=Vector3.new(3,3,1)
        piece('ClockHand',Vector3.new(0.15,1,0.15),Vector3.new(0,0.5,-0.65),Color3.new(1,1,1))
        piece('Pendulum',Vector3.new(0.2,2,0.2),Vector3.new(0,-2,0))
        piece('Weight',Vector3.new(0.8,0.8,0.5),Vector3.new(0,-3,0),c,true)
    elseif shape=='Vine' or shape=='Stag' then
        for _,s in {-1,1} do
            piece('Antler',Vector3.new(0.25,2.4,0.25),Vector3.new(s*1.1,2,0),c,false,CFrame.Angles(0,0,-s*0.4))
            piece('Branch',Vector3.new(1,0.2,0.2),Vector3.new(s*1.6,2.1,0))
        end
        if shape=='Stag' then piece('Muzzle',Vector3.new(1.4,0.8,1.7),Vector3.new(0,-0.3,-1.1),c,true) end
    elseif shape=='Veil' then
        for i=1,5 do piece('Veil',Vector3.new(0.6,3.8,0.3),Vector3.new((i-3)*0.7,-0.6,0.7),c,true) end
    elseif shape=='Book' then
        root.Shape=Enum.PartType.Block; root.Size=Vector3.new(3,2,0.9)
        piece('Pages',Vector3.new(2.6,1.7,0.2),Vector3.new(0,0,-0.65),Color3.fromRGB(230,217,190))
        piece('Quill',Vector3.new(0.4,3,0.3),Vector3.new(2,0.7,0),c,true,CFrame.Angles(0,0,-0.4))
    elseif shape=='Crown' or shape=='Knight' then
        piece('Shoulders',Vector3.new(4,0.7,1.6),Vector3.new(0,-1,0),Color3.fromRGB(100,93,130))
        for i=-1,1 do piece('Crown',Vector3.new(0.5,1.2,0.5),Vector3.new(i*0.9,1.8,0),c) end
        if shape=='Knight' then piece('Lance',Vector3.new(0.3,5,0.3),Vector3.new(2.5,0,0)) end
    elseif shape=='Eclipse' then
        root.Color=Color3.fromRGB(30,16,43)
        for i=1,12 do local a=i*math.pi/6; piece('Halo',Vector3.new(0.6,0.6,0.3),Vector3.new(math.cos(a)*2.2,math.sin(a)*2.2,0.5),c,true) end
    elseif shape=='Candle' then
        root.Shape=Enum.PartType.Block; root.Size=Vector3.new(1.6,3.8,1.6); root.Color=Color3.fromRGB(243,226,189)
        piece('Flame',Vector3.new(0.8,1.6,0.8),Vector3.new(0,2.8,0),c,true)
    elseif shape=='Door' then
        root.Shape=Enum.PartType.Block; root.Size=Vector3.new(2.5,4.8,0.7); root.Color=Color3.fromRGB(14,10,30)
        for _,s in {-1,1} do piece('Frame',Vector3.new(0.25,5.4,0.9),Vector3.new(s*1.5,0,0)) end
        piece('Lintel',Vector3.new(3.2,0.25,0.9),Vector3.new(0,2.6,0))
    end
    local light=Instance.new('PointLight'); light.Color=c; light.Range=9; light.Brightness=0.38; light.Parent=root
    m.Parent=parent; m:PivotTo(cf); m:ScaleTo(scale or 1)
    if withLabel then V.label(root,g.Name..'\n'..Config.Rarities[g.Rarity],c,180,48) end
    return m
end
function V.vacuum()
    local t=Instance.new('Tool'); t.Name='Spectral Vacuum'; t.RequiresHandle=true; t.CanBeDropped=false
    t.Grip=CFrame.new(0,-0.3,0.5)*CFrame.Angles(0,0,0)
    local handle=V.part(t,'Handle',Vector3.new(0.65,1,0.65),CFrame.new(),Color3.fromRGB(43,39,57))
    local function attach(name,size,position,color,material)
        local p=V.part(t,name,size,CFrame.new(position),color,material)
        local w=Instance.new('WeldConstraint'); w.Part0=handle; w.Part1=p; w.Parent=p
        return p
    end
    attach('Body',Vector3.new(1.4,1.4,2.3),Vector3.new(0,0.6,-0.4),Color3.fromRGB(78,63,105),Enum.Material.Metal)
    local tank=attach('CaptureContainer',Vector3.new(1,1.6,1),Vector3.new(0,1.4,0.2),Color3.fromRGB(108,245,225),Enum.Material.Neon)
    tank.Transparency=0.35
    attach('Hose',Vector3.new(0.55,0.55,2),Vector3.new(0,0.6,-2),Color3.fromRGB(30,28,40))
    local nozzle=attach('Nozzle',Vector3.new(1,0.85,0.6),Vector3.new(0,0.6,-3),Color3.fromRGB(174,154,220),Enum.Material.Metal)
    local a=Instance.new('Attachment'); a.Name='Suction'; a.Position=Vector3.new(0,0,-0.35); a.Parent=nozzle
    local lens=attach('Flashlight',Vector3.new(0.45,0.45,0.3),Vector3.new(0.7,0.8,-1.5),Color3.fromRGB(255,236,178),Enum.Material.Neon)
    local light=Instance.new('SpotLight'); light.Name='Lamp'; light.Face=Enum.NormalId.Front; light.Angle=65; light.Range=40; light.Brightness=3; light.Shadows=true; light.Parent=lens
    for _,p in t:GetDescendants() do if p:IsA('BasePart') then p.Anchored=false; p.CanCollide=false; p.Massless=true end end
    return t
end
return V

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
    gui.Name='Label'; gui.Size=UDim2.fromOffset(math.min(width or 210,230),math.min(height or 48,64))
    gui.StudsOffset=Vector3.new(0,3,0); gui.MaxDistance=180; gui.AlwaysOnTop=false
    gui:SetAttribute('ContextLabel',true); gui:SetAttribute('ReadDistance',42)
    gui.Enabled=false; gui.Parent=part
    local label=Instance.new('TextLabel')
    label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=text
    label.TextColor3=color or Color3.new(1,1,1); label.TextStrokeTransparency=0.75
    label.Font=Enum.Font.GothamMedium; label.TextSize=14; label.TextWrapped=true; label.Parent=gui
    return label
end
function V.ghost(id,parent,cf,scale,withLabel)
    local g=Config.Ghosts[id]
    local m=Instance.new('Model'); m.Name=g.Name; m:SetAttribute('Species',id)
    local c=V.color(g.Rarity)
    local root=if g.Shape=='ReferenceGhost' then require(script.Parent.GhostModels).build(m)
        else require(script.Parent.GhostStyle).build(m,g,c)
    m.Parent=parent; m:ScaleTo(scale or 1); m:PivotTo(cf)
    if withLabel then
        local label=V.label(root,g.Name..'\n'..Config.Rarities[g.Rarity],c,180,42)
        label.Parent:SetAttribute('GhostLabel',true)
        label.Parent.StudsOffset=Vector3.new(0,m:GetExtentsSize().Y*.5+.8,0)
    end
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

-- Server-only, one request per asset. Collection mesh names carry material roles.
local InsertService=game:GetService('InsertService')
local Ids=require(script.Parent.Parent.AssetIds)
local Loader={}
local cache={}
local pending={}
local warned={}
local palette={
    Stone={51,49,65},Wood={62,43,58},Roof={39,30,57},Metal={43,40,57},
    Glass={120,160,220},Glow={255,188,104},Accent={255,140,60},
    Foliage={25,43,43},Ground={29,43,42},Water={80,205,255},Collision={51,49,65},
}
-- Built-in Roblox materials give the meshes surface detail without any texture assets. Meshes carry a
-- box-projected UV map from Blender so these tile evenly.
local materials={
    Stone=Enum.Material.Slate,Wood=Enum.Material.WoodPlanks,Roof=Enum.Material.Slate,Metal=Enum.Material.Metal,
    Glass=Enum.Material.Glass,Glow=Enum.Material.Neon,Accent=Enum.Material.Neon,
    Foliage=Enum.Material.Grass,Ground=Enum.Material.Grass,Water=Enum.Material.Glass,Collision=Enum.Material.SmoothPlastic,
}
local function warning(name,reason)
    if warned[name] then return end
    warned[name]=true
    warn(string.format('Asset load failed: %s ID=%s: %s',name,tostring(Ids[name] and Ids[name].Id),tostring(reason)))
end
function Loader.configured(name)
    return Ids[name]~=nil and Ids[name].Id>0
end
function Loader.preload(names)
    local deadline=os.clock()+12
    for _,name in names do
        if cache[name]~=nil or pending[name] then continue end
        if not Loader.configured(name) then cache[name]=false; warning(name,'not uploaded'); continue end
        pending[name]=true
        task.spawn(function()
            local ok,model=pcall(function() return InsertService:LoadAsset(Ids[name].Id) end)
            if ok and model and model:IsA('Model') and model:FindFirstChildWhichIsA('BasePart',true) then
                for _,item in model:GetDescendants() do
                    if item:IsA('LuaSourceContainer') then item:Destroy() end
                end
                if pending[name] then cache[name]=model else model:Destroy() end
            else
                if typeof(model)=='Instance' then model:Destroy() end
                cache[name]=false
                warning(name,ok and 'empty asset' or model)
            end
            pending[name]=nil
        end)
    end
    while os.clock()<deadline do
        local waiting=false
        for _,name in names do if pending[name] then waiting=true; break end end
        if not waiting then break end
        task.wait()
    end
    for _,name in names do
        if pending[name] then
            pending[name]=nil; cache[name]=false; warning(name,'12-second preload timeout')
        end
    end
end
local function fallback(name,parent,cf)
    local model=Instance.new('Model'); model.Name=name..'_Unavailable'
    local p=Instance.new('Part'); p.Name='Placeholder'; p.Size=Ids[name].Footprint
    p.CFrame=cf*CFrame.new(0,p.Size.Y/2,0); p.Color=Color3.fromRGB(32,29,43)
    p.Anchored=true; p.Parent=model
    local gui=Instance.new('BillboardGui'); gui.Size=UDim2.fromOffset(180,40); gui.StudsOffset=Vector3.new(0,3,0); gui.Parent=p
    local label=Instance.new('TextLabel'); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
    label.Text='Asset unavailable: '..name; label.TextColor3=Color3.fromRGB(255,188,104); label.TextScaled=true; label.Parent=gui
    model.Parent=parent
    return model
end
function Loader.place(name,parent,cf,options)
    assert(Ids[name],'Unknown asset '..name)
    if not cache[name] then warning(name,'no cached model'); return fallback(name,parent,cf) end
    local model=cache[name]:Clone(); model.Name=name
    local target=Ids[name].Footprint
    local extent=model:GetExtentsSize()
    if name=='StreetLamp' and not Loader.LampCalibrated then
        Loader.LampCalibrated=true
        print('StreetLamp imported extents:',extent,'expected:',target)
    end
    local factor=target.Y/extent.Y
    if math.abs(extent.X*factor/target.X-1)>.02 or math.abs(extent.Z*factor/target.Z-1)>.02 then
        model:Destroy(); warning(name,'nonuniform footprint mismatch'); return fallback(name,parent,cf)
    end
    model:ScaleTo(model:GetScale()*factor)
    local bounds,size=model:GetBoundingBox()
    local base=bounds*CFrame.new(0,-size.Y/2,0)
    model:PivotTo(cf*base:Inverse()*model:GetPivot())
    for _,p in model:GetDescendants() do
        if not p:IsA('BasePart') then continue end
        local role=p.Name:match('_([%a]+)$')
        if not palette[role] then
            model:Destroy(); warning(name,'unexpected role suffix: '..p.Name); return fallback(name,parent,cf)
        end
        p.Anchored=true
        p.CanCollide=role=='Collision'; p.CanQuery=role=='Collision'; p.CanTouch=false
        p.Transparency=if role=='Collision' then 1 elseif role=='Glass' then .4 elseif role=='Water' then .5 else 0
        p.Material=materials[role] or Enum.Material.SmoothPlastic
        p.Reflectance=if role=='Water' then 0.35 elseif role=='Glass' then 0.2 elseif role=='Metal' then 0.08 else 0
        p.CastShadow=role~='Glow' and role~='Water' and role~='Collision'
        p.Color=if role=='Accent' and options and options.Accent then options.Accent else Color3.fromRGB(table.unpack(palette[role]))
    end
    model.Parent=parent
    return model
end
return Loader

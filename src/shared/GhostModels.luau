-- Imported ghost templates are loaded once by the server and shared with inventory previews.
local Models={}
local RunService=game:GetService('RunService')
local TEMPLATE_FOLDER='GhostModelTemplates'
local ASSET_ID=130914286159636
local colors={
    Pearlescentperiwinkle=Color3.fromRGB(199,212,248),
    Glossymidnighteyes=Color3.fromRGB(15,20,35),
    Eyeglints=Color3.fromRGB(248,251,255),
    Roseblush=Color3.fromRGB(235,158,207),
    Smilevelvet=Color3.fromRGB(53,24,69),
    Berrytongue=Color3.fromRGB(193,110,180),
}
local function prepareAsset()
    assert(RunService:IsServer(),'Ghost templates must be prepared by the server')
    if script.Parent:FindFirstChild(TEMPLATE_FOLDER) then return end
    assert(ASSET_ID>0,'Little Boo asset has not been configured')
    local imported=game:GetService('InsertService'):LoadAsset(ASSET_ID)
    local template=Instance.new('Model'); template.Name='ReferenceGhost'
    local meshes={}
    for _,item in imported:GetDescendants() do
        if item:IsA('MeshPart') then table.insert(meshes,item) end
    end
    assert(#meshes==6,'Little Boo must contain its six material meshes')
    for _,p in meshes do
        local role=p.Name:match('ReferenceGhost_(.+)')
        assert(colors[role],'Unknown Little Boo material: '..p.Name)
        p.Color=colors[role]; p.Material=Enum.Material.SmoothPlastic
        p.Reflectance=if role=='Glossymidnighteyes' then .16 else 0
        p.Transparency=0; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=true
        p.Parent=template
    end
    imported:Destroy()
    local extent=template:GetExtentsSize()
    template:ScaleTo(template:GetScale()*4.05/extent.Y)
    local bounds=template:GetBoundingBox()
    -- The imported Blender -Y face points toward Roblox -Z, matching the other pets.
    template:PivotTo(bounds:Inverse()*template:GetPivot())
    local core=Instance.new('Part'); core.Name='Core'; core.Size=Vector3.new(2.6,3.6,1.8)
    core.Transparency=1; core.Anchored=true; core.CanCollide=false; core.CanTouch=false
    core.CFrame=CFrame.new(); core.Parent=template; template.PrimaryPart=core
    local folder=Instance.new('Folder'); folder.Name=TEMPLATE_FOLDER
    template.Parent=folder; folder.Parent=script.Parent
end
function Models.prepare()
    local ok,reason=pcall(prepareAsset)
    if not ok then
        warn('Little Boo model unavailable: '..tostring(reason))
        -- Keep the existing roster playable if Roblox cannot deliver the new asset.
        local config=require(script.Parent.Config)
        config.Ghosts.little_boo.Weight=0
        config.Ghosts.little_boo.Areas={}
        local folder=Instance.new('Folder'); folder.Name=TEMPLATE_FOLDER
        folder:SetAttribute('LoadFailed',true); folder.Parent=script.Parent
    end
end
function Models.build(model)
    local folder=script.Parent:WaitForChild(TEMPLATE_FOLDER,20)
    local template=folder and folder:FindFirstChild('ReferenceGhost')
    if not template then
        local core=Instance.new('Part'); core.Name='Core'; core.Size=Vector3.new(2.6,3.6,1.8)
        core.Anchored=true; core.CanCollide=false; core.CanTouch=false; core.Transparency=1
        core.Parent=model; model.PrimaryPart=core
        local gui=Instance.new('BillboardGui'); gui.Name='Label'; gui.Size=UDim2.fromOffset(140,40); gui.MaxDistance=24; gui.Parent=core
        local text=Instance.new('TextLabel'); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1
        text.Text='Little Boo\nModel unavailable'; text.TextColor3=Color3.fromRGB(199,212,248); text.Parent=gui
        model:SetAttribute('VisualStyle','Unavailable')
        return core
    end
    for _,part in template:GetChildren() do part:Clone().Parent=model end
    local core=model:FindFirstChild('Core'); model.PrimaryPart=core
    local light=Instance.new('PointLight'); light.Color=colors.Pearlescentperiwinkle
    light.Range=7; light.Brightness=.18; light.Parent=core
    model:SetAttribute('VisualStyle','ReferenceMeshV1')
    return core
end
return Models

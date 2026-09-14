-- Include only in reference preview/test builds. Read-only map and engine checks.
local Log=game:GetService('LogService')
local errors={}
local errorConnection=Log.MessageOut:Connect(function(message,kind)
    if kind==Enum.MessageType.MessageError then table.insert(errors,message) end
end)
local diagnostics=Instance.new('RemoteEvent')
diagnostics.Name='ReferenceDiagnostics'; diagnostics.Parent=game:GetService('ReplicatedStorage')
local received={}
diagnostics.OnServerEvent:Connect(function(player,data)
    if type(data)~='table' or (received[player.UserId] and os.clock()-received[player.UserId]<1) then return end
    received[player.UserId]=os.clock()
    local values={}
    for key,value in data do
        if #values>=16 then break end
        if type(key)=='string' and #key<=40 and (type(value)=='number' or type(value)=='boolean' or type(value)=='string' and #value<=160) then
            table.insert(values,key..'='..tostring(value))
        end
    end
    table.sort(values)
    print('REFERENCE CLIENT '..table.concat(values,'; '))
end)
local W=require(script.Parent:WaitForChild('World'))
local passed,failed=0,0
local function group(name,fn)
    local ok,result=pcall(fn)
    if ok then passed+=1 else failed+=1 end
    print(string.format('REFERENCE %s %s: %s',if ok then 'PASS' else 'FAIL',name,tostring(result or 'ok')))
end
local deadline=os.clock()+45
repeat
    local environment=W.Root and W.Root:FindFirstChild('ReferenceEnvironment')
    if environment and environment:GetAttribute('ReferenceTreeCount') and #W.Areas==6 then break end
    task.wait(.1)
until os.clock()>deadline
task.wait(4) -- Terrain collision settles after WriteVoxels.
local root=W.Root
local paths={}
if root then
    for _,p in root:GetDescendants() do
        if p:IsA('BasePart') and p:GetAttribute('ReferencePath') then table.insert(paths,p) end
    end
end
local function params(items)
    local q=RaycastParams.new(); q.FilterType=Enum.RaycastFilterType.Include
    q.FilterDescendantsInstances=items; q.RespectCanCollide=true; q.IgnoreWater=false
    return q
end
local function down(pos,q)
    return workspace:Raycast(pos+Vector3.new(0,15,0),Vector3.new(0,-40,0),q)
end
group('world ready',function()
    local environment=root and root:FindFirstChild('ReferenceEnvironment')
    assert(environment and environment:GetAttribute('ReferenceTreeCount'),'reference environment missing or timed out')
    assert(#W.Plots==7 and #W.Areas==6,'expected seven plots and six hunting interiors')
    assert(#paths>100,'reference walking routes missing')
    return #paths..' path tiles; 7 plots; 6 interiors'
end)
group('walkway visibility',function()
    local buried,missing,samples=0,0,0
    local examples={}
    for _,p in paths do
        local q=params({workspace.Terrain,p})
        for _,fraction in {-.25,0,.25} do
            local pos=(p.CFrame*CFrame.new(0,0,p.Size.Z*fraction)).Position
            local hit=down(pos,q); samples+=1
            if not hit then missing+=1
            elseif hit.Instance==workspace.Terrain then
                buried+=1
                if #examples<4 then table.insert(examples,string.format('(%.1f,%.1f)',pos.X,pos.Z)) end
            end
        end
    end
    assert(samples>0 and buried==0 and missing==0,string.format('%d/%d buried, %d missing; %s',buried,samples,missing,table.concat(examples,', ')))
    return samples..' centers/quarter-points visible above terrain'
end)
group('gate approaches',function()
    local included={workspace.Terrain}
    for _,p in paths do table.insert(included,p) end
    local q=params(included)
    local checked=0
    for i,plot in W.Plots do
        local posts={}
        for _,p in plot.Model:GetDescendants() do
            if p:IsA('BasePart') and p.Name=='GatePost' then table.insert(posts,p) end
        end
        assert(#posts==2,'Haunt '..i..' needs two live gate posts')
        local center=(posts[1].Position+posts[2].Position)/2
        local direction=center-plot.CF.Position
        direction=Vector3.new(direction.X,0,direction.Z).Unit
        local scale=(posts[1].Position-posts[2].Position).Magnitude/7.2
        for _,distance in {0,3,7} do
            local hit=down(center+direction*distance*scale,q)
            assert(hit and hit.Instance:GetAttribute('ReferencePath'),'Haunt '..i..' gate approach lacks visible path at '..distance..' scaled studs')
            checked+=1
        end
    end
    return checked..' gate center/outside samples connect to paths'
end)
group('landmark collision parents',function()
    local town=root:FindFirstChild('SpookyTown'); local graves=root:FindFirstChild('GraveyardLandmark')
    local shops,fences=0,0
    for _,p in root:GetDescendants() do
        if p.Name:match('^ShopCollision') or p.Name=='StallCollision' or p.Name:match('^ShopSign') then
            assert(town and p:IsDescendantOf(town),p.Name..' left outside translated town'); shops+=1
        elseif p.Name:match('^GraveFence') or p.Name=='GraveGatePost' or p.Name=='CryptCollision' or p.Name=='GraveLight' then
            assert(graves and p:IsDescendantOf(graves),p.Name..' left outside translated cemetery'); fences+=1
        end
    end
    assert(shops>=8 and fences>=9,'shop/cemetery collision coverage missing')
    return shops..' town and '..fences..' cemetery parts stay with landmark'
end)
group('ghost slot visibility',function()
    local checked=0
    for i,plot in W.Plots do
        local architecture=plot.Model:FindFirstChild('GothicArchitecture')
        assert(architecture,'Haunt '..i..' architecture missing')
        for index,pad in plot.Slots do
            -- Mirrors the public display placement contract, not building geometry.
            local display=(pad.CFrame*CFrame.new(0,2.3,0)).Position
            for _,p in architecture:GetDescendants() do
                if p:IsA('BasePart') and p.Transparency<.5 then
                    local localPoint=p.CFrame:PointToObjectSpace(display)
                    local half=p.Size*.5
                    assert(not (math.abs(localPoint.X)<half.X and math.abs(localPoint.Y)<half.Y and math.abs(localPoint.Z)<half.Z),
                        string.format('Haunt %d slot %d display inside %s',i,index,p.Name))
                end
            end
            checked+=1
        end
    end
    return checked..' ghost display centers clear of opaque architecture'
end)
group('portal animation position',function()
    local portal=root:FindFirstChild('ChamberPortal')
    assert(portal and portal:IsA('Model'),'portal Model missing')
    local glow=portal:FindFirstChild('ChamberPortal_Glow',true)
    local stone=portal:FindFirstChild('ChamberPortal_Stone',true)
    assert(glow and stone and W.ChamberPortal:IsDescendantOf(portal),'portal glow/frame/prompt missing')
    local maxGap=0
    for _=1,8 do
        local delta=glow.Position-stone.Position
        maxGap=math.max(maxGap,Vector3.new(delta.X,0,delta.Z).Magnitude)
        task.wait(.12)
    end
    assert(maxGap<4,string.format('animated glow separated %.2f studs from frame',maxGap))
    return string.format('glow/frame horizontal separation <= %.2f studs across animation',maxGap)
end)
group('spawn usable',function()
    local spawn=root:FindFirstChild('TownSpawn')
    assert(spawn and spawn:IsA('SpawnLocation'),'spawn missing')
    local q=RaycastParams.new(); q.RespectCanCollide=true; q.IgnoreWater=false
    local excluded={spawn}
    for _,player in game:GetService('Players'):GetPlayers() do
        if player.Character then table.insert(excluded,player.Character) end
    end
    q.FilterType=Enum.RaycastFilterType.Exclude; q.FilterDescendantsInstances=excluded
    local hit=down(spawn.Position,q)
    assert(hit and hit.Material~=Enum.Material.Water,'spawn has no dry floor')
    assert(math.abs(hit.Position.Y-spawn.Position.Y)<3,'spawn is buried or suspended above floor')
    local ceiling=workspace:Raycast(hit.Position+Vector3.new(0,.2,0),Vector3.new(0,7,0),q)
    assert(not ceiling,'spawn lacks avatar headroom')
    return string.format('dry %s floor at %.2f; 7 studs headroom',hit.Instance.Name,hit.Position.Y)
end)
group('engine errors',function()
    assert(#errors==0,table.concat(errors,' | '))
    return '0 script errors observed during build/QA'
end)
errorConnection:Disconnect()
print(string.format('REFERENCE COMPLETE %d passed; %d failed',passed,failed))

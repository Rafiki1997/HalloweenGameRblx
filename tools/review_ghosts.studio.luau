-- Run on the Client in a Studio play test. Stop the test to remove this review overlay.
local player=game.Players.LocalPlayer
assert(player,'Run this review on the Client')
local shared=game.ReplicatedStorage.Ghostlight
local V=require(shared.Visuals)
local C=require(shared.Config)
local old=player.PlayerGui:FindFirstChild('GhostStyleReview')
if old then old:Destroy() end
local gui=Instance.new('ScreenGui'); gui.Name='GhostStyleReview'
gui.IgnoreGuiInset=true; gui.DisplayOrder=1000; gui.Parent=player.PlayerGui
local bg=Instance.new('Frame'); bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(11,14,28); bg.Parent=gui
local ids={}
for id in C.Ghosts do table.insert(ids,id) end
table.sort(ids,function(a,b)
    return C.Ghosts[a].Rarity<C.Ghosts[b].Rarity or (C.Ghosts[a].Rarity==C.Ghosts[b].Rarity and a<b)
end)
local count=0
for i,id in ids do
    local vp=Instance.new('ViewportFrame'); vp.Size=UDim2.fromScale(1/5,.29)
    vp.Position=UDim2.fromScale(((i-1)%5)/5,.025+math.floor((i-1)/5)*.325)
    vp.BackgroundTransparency=1; vp.Ambient=Color3.fromRGB(95,102,127)
    vp.LightColor=Color3.fromRGB(255,237,221); vp.LightDirection=Vector3.new(-1,-1,2); vp.Parent=bg
    local wm=Instance.new('WorldModel'); wm.Parent=vp
    local model=V.ghost(id,wm,CFrame.new(),1,false)
    assert(model.PrimaryPart and model.PrimaryPart.Name=='Core')
    assert(model:GetAttribute('Species')==id)
    local parts=0
    for _,p in model:GetDescendants() do
        if p:IsA('BasePart') then
            assert(p.Anchored and not p.CanCollide and p.CanQuery,id..': invalid capture geometry')
            parts+=1
        end
    end
    assert(parts<100,id..': visual part budget exceeded')
    local copy=model:Clone(); copy:ScaleTo(.2); copy:PivotTo(CFrame.new(1,2,3))
    assert((copy:GetPivot().Position-Vector3.new(1,2,3)).Magnitude<.001)
    copy:Destroy()
    local cam=Instance.new('Camera')
    cam.CFrame=CFrame.lookAt(Vector3.new(0,.5,-10),Vector3.new(0,.1,0))
    cam.FieldOfView=38; cam.Parent=vp; vp.CurrentCamera=cam
    local label=Instance.new('TextLabel'); label.Size=UDim2.fromScale(.94,.12)
    label.Position=UDim2.fromScale(.03,.88); label.BackgroundTransparency=1
    label.Text=C.Ghosts[id].Name; label.TextColor3=Color3.new(1,1,1)
    label.TextScaled=true; label.Font=Enum.Font.GothamBold; label.Parent=vp
    count+=1
end
assert(count==15,'Expected fifteen species including Little Boo')
return 'PASS: 15 species rendered; capture geometry, part budgets, cloning and scaling verified'

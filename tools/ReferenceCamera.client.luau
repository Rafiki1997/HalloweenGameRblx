-- Visual QA only; tools/build_place.py includes this solely with --preview.
local RunService=game:GetService('RunService')
local player=game:GetService('Players').LocalPlayer
pcall(function() game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
RunService:BindToRenderStep('ReferenceCapture',Enum.RenderPriority.Camera.Value+20,function()
    local camera=workspace.CurrentCamera
    camera.CameraType=Enum.CameraType.Scriptable
    local shot=workspace:GetAttribute('ReferenceShot') or 'overview'
    camera.FieldOfView=if shot=='overview' then 50 else 55
    if shot:match('^interior') then
        local floor=tonumber(shot:match('%d+')) or 1
        local center=Vector3.new(5000+(floor-1)*150,0,-450)
        camera.FieldOfView=75
        if shot=='interior2side' then camera.CFrame=CFrame.lookAt(center+Vector3.new(-29,8,12),center+Vector3.new(-52,6,39))
        elseif shot:match('side') then camera.CFrame=CFrame.lookAt(center+Vector3.new(-30,9,43),center+Vector3.new(-48,9,-19))
        else camera.CFrame=CFrame.lookAt(center+Vector3.new(8,8,45),center+Vector3.new(-2,10,-22)) end
    elseif shot=='plaza' then camera.CFrame=CFrame.lookAt(Vector3.new(0,12,52),Vector3.new(0,17,-15))
    elseif shot=='town' then camera.CFrame=CFrame.lookAt(Vector3.new(-49,22,190),Vector3.new(-108,8,137))
    elseif shot=='graveyard' then camera.CFrame=CFrame.lookAt(Vector3.new(83,21,181),Vector3.new(134,7,133))
    elseif shot=='lake' then camera.CFrame=CFrame.lookAt(Vector3.new(-61,17,96),Vector3.new(-130,0,10))
    elseif shot=='mansion-door' then camera.CFrame=CFrame.lookAt(Vector3.new(0,37,-145),Vector3.new(0,37,-161))
    elseif shot=='plot-door' then camera.CFrame=CFrame.lookAt(Vector3.new(120,22,-47),Vector3.new(169,22,-53))
    elseif shot=='plot-stairs' then camera.CFrame=CFrame.lookAt(Vector3.new(63,7,-33),Vector3.new(83,18,-69))
    else camera.CFrame=CFrame.lookAt(Vector3.new(8,315,405),Vector3.new(0,4,25)) end
    camera.Focus=camera.CFrame*CFrame.new(0,0,if shot=='overview' then -490 else -60)
    for _,g in player.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end
end)
task.spawn(function()
    local event=game:GetService('ReplicatedStorage'):WaitForChild('ReferenceDiagnostics',60)
    if not event then return end
    task.wait(12)
    local started=os.clock()
    for _=1,90 do RunService.RenderStepped:Wait() end
    local camera=workspace.CurrentCamera
    event:FireServer({Camera=tostring(camera.CFrame),FPS=90/(os.clock()-started),Descendants=#workspace:GetDescendants()})
end)

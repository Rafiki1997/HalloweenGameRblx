-- Test-build-only remote driver. Not included in production.
local player=game:GetService('Players').LocalPlayer
local remote=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight'):WaitForChild('Action')
player:WaitForChild('PlayerGui'):WaitForChild('GhostlightHUD')
player:GetAttributeChangedSignal('TestAction'):Connect(function()
    local action=player:GetAttribute('TestAction')
    if action then remote:FireServer(action,player:GetAttribute('TestArg')) end
end)
local testRemote=game:GetService('ReplicatedStorage'):WaitForChild('RuntimeTestStatus')
testRemote:FireServer('Ready')
workspace.CurrentCamera:GetPropertyChangedSignal('CameraType'):Connect(function()
    testRemote:FireServer(if workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then 'Scriptable' else 'Custom')
end)

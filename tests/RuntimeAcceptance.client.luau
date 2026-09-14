-- Test-build-only remote driver. Not included in production.
local player=game:GetService('Players').LocalPlayer
local remote=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight'):WaitForChild('Action')
player:WaitForChild('PlayerGui'):WaitForChild('GhostlightHUD')
player:GetAttributeChangedSignal('TestAction'):Connect(function()
    local action=player:GetAttribute('TestAction')
    if action then remote:FireServer(action,player:GetAttribute('TestArg')) end
end)
local testRemote=game:GetService('ReplicatedStorage'):WaitForChild('RuntimeTestStatus')
local playerGui=player:WaitForChild('PlayerGui')
playerGui.ChildAdded:Connect(function(child)
    if child.Name=='GhostlightEncounter' then testRemote:FireServer('EncounterShown') end
    if child.Name=='GhostlightBattle' then testRemote:FireServer('BattleShown') end
end)
playerGui.ChildRemoved:Connect(function(child)
    if child.Name=='GhostlightEncounter' then testRemote:FireServer('EncounterHidden') end
    if child.Name=='GhostlightBattle' then testRemote:FireServer('BattleHidden') end
end)
testRemote:FireServer('Ready')
workspace.CurrentCamera:GetPropertyChangedSignal('CameraType'):Connect(function()
    testRemote:FireServer(if workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable then 'Scriptable' else 'Custom')
end)

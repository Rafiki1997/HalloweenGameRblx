-- Embedded only by build_place.py --test. Never shipped in the normal place.
local Players=game:GetService('Players')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local Rules=require(Shared.Rules)
local Profiles=require(script.Parent.Profiles)
local H=require(script.Parent.Hunting)
local W=require(script.Parent.World)
local Chamber=require(script.Parent.Chamber)
local passed=0
local testRemote=Instance.new('RemoteEvent'); testRemote.Name='RuntimeTestStatus'; testRemote.Parent=game:GetService('ReplicatedStorage')
testRemote.OnServerEvent:Connect(function(player,status)
    if status=='Ready' then player:SetAttribute('TestClientReady',true)
    elseif status=='Scriptable' then player:SetAttribute('TestCameraScriptable',true)
    elseif status=='Custom' then player:SetAttribute('TestCameraScriptable',false) end
end)
local function check(value,message)
    assert(value,'ACCEPTANCE FAIL: '..message)
    passed+=1
    print('ACCEPTANCE PASS: '..message)
end
local function untilTrue(fn,seconds)
    local deadline=os.clock()+seconds
    repeat if fn() then return true end; task.wait(0.1) until os.clock()>deadline
    return false
end
local ok,err=pcall(function()
    check(untilTrue(function() return #Players:GetPlayers()>0 end,25),'player joined')
    local player=Players:GetPlayers()[1]
    check(untilTrue(function() return Profiles.get(player) and player.Character and player.Character:FindFirstChild('Spectral Vacuum') end,25),'profile loaded and vacuum equipped')
    local testHumanoid=player.Character:FindFirstChildOfClass('Humanoid')
    testHumanoid.MaxHealth=1000; testHumanoid.Health=1000
    player:SetAttribute('TestInvulnerable',true)
    local p=Profiles.get(player)
    local function client(action,arg)
        player:SetAttribute('TestAction',nil)
        player:SetAttribute('TestArg',arg)
        task.wait(0.2)
        player:SetAttribute('TestAction',action)
        task.wait(0.5)
    end
    check(#W.Plots==7 and #W.Areas==6,'seven plots and six mansion areas created with mansion path clear')
    local ghostCount=0
    for _ in H.Ghosts do ghostCount+=1 end
    check(ghostCount==42,'42 wild ghosts spawned')
    check(player.Character.HumanoidRootPart.Position.Y> -5,'spawn above town ground')
    check(untilTrue(function() return player:GetAttribute('TestClientReady') end,10),'client HUD loaded')
    client('EnterFloor',6)
    check((player:GetAttribute('Floor') or 0)==0,'locked area request rejected')
    client('EnterFloor',1)
    check(player:GetAttribute('Floor')==1,'client entered foyer')
    local function catch()
        local ghost
        for _,g in H.Ghosts do if g.Floor==1 then ghost=g; break end end
        assert(ghost,'No matching test ghost')
        local before=#p.Bag
        local deadline=os.clock()+25
        repeat
            player.Character:PivotTo(CFrame.new(ghost.Pos+Vector3.new(0,0,7)))
            H.click(player,ghost.Id)
            task.wait(0.12)
        until #p.Bag>before or os.clock()>deadline
        check(#p.Bag==before+1,'server capture reaches completion: '..ghost.Species)
        return ghost.Species
    end
    local first=catch()
    check(p.Owned[first]==1 and p.Discovered[first],'capture ownership and discovery recorded once')
    client('Home')
    check(player:GetAttribute('Floor')==0,'client returned home')
    client('Deposit')
    check(#p.Bag==0 and #p.Placed==1,'deposit frees bag and displays ghost')
    local light=player.Character:FindFirstChild('Lamp',true)
    local wasEnabled=light.Enabled
    client('Flashlight')
    check(light.Enabled~=wasEnabled,'flashlight toggles through validated client request')
    local cash=p.Money
    task.wait(1.3)
    check(p.Money>cash and Rules.income(p)>0,'placed ghost earns real server income')
    local before=p.Owned[first]
    client('Place',first)
    check(#p.Placed==1 and p.Owned[first]==before,'duplicate placement rejected')
    p.Money=1e9
    client('Upgrade','Movement')
    local movementHumanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    check(p.Upgrades.Movement==2 and movementHumanoid and movementHumanoid.WalkSpeed==24,'upgrade changes live movement speed')
    client('Upgrade','Haunt')
    check(p.HauntLevel==2,'haunt upgrade expands slots')
    client('Unlock',2)
    check(p.Floor==2,'floor unlock charges and persists in profile')
    client('Chamber')
    check(player:GetAttribute('Chamber') and Chamber.Sessions[player]~=nil,'chamber server session entered')
    check(untilTrue(function() return player:GetAttribute('TestCameraScriptable') end,4),'client camera enters top-down mode')
    local session=Chamber.Sessions[player]
    session.NextReward=os.clock()+0.2
    task.wait(0.8)
    check(p.ChamberDiscoveries==1,'autonomous chamber discovery grants once')
    client('ExitChamber')
    check(not player:GetAttribute('Chamber') and Chamber.Sessions[player]==nil,'chamber exits and cleans its models')
    check(untilTrue(function() return player:GetAttribute('TestCameraScriptable')==false end,4),'client camera restores after chamber exit')
    p.Floor=6; p.Money=Rules.rebirthCost(p)
    client('Rebirth')
    check(p.Rebirths==1 and p.Floor==1 and p.HauntLevel==1 and #p.Placed==0,'rebirth resets temporary progression')
    check(p.Owned[first]>=1 and p.Discovered[first] and Rules.multiplier(p)==1.5,'rebirth keeps collection and increases multiplier')
    check(Profiles.save(player,false),'Studio practice save path completes')
    print('ACCEPTANCE COMPLETE: '..passed..' checks passed. DataStore network and multiplayer checks remain separate.')
end)
if not ok then warn(err) end

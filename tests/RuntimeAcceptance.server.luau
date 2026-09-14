-- Embedded only by build_place.py --test. Never shipped in the normal place.
local Players=game:GetService('Players')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
local Rules=require(Shared.Rules)
local C=require(Shared.Config)
local Profiles=require(script.Parent.Profiles)
local H=require(script.Parent.Hunting)
local W=require(script.Parent.World)
local Chamber=require(script.Parent.Chamber)
local passed=0
local testRemote=Instance.new('RemoteEvent'); testRemote.Name='RuntimeTestStatus'; testRemote.Parent=game:GetService('ReplicatedStorage')
testRemote.OnServerEvent:Connect(function(player,status)
    if status=='Ready' then player:SetAttribute('TestClientReady',true)
    elseif status=='Scriptable' then player:SetAttribute('TestCameraScriptable',true)
    elseif status=='Custom' then player:SetAttribute('TestCameraScriptable',false)
    elseif status=='EncounterShown' then player:SetAttribute('TestEncounterVisible',true)
    elseif status=='EncounterHidden' then player:SetAttribute('TestEncounterVisible',false)
    elseif status=='BattleShown' then player:SetAttribute('TestBattleVisible',true)
    elseif status=='BattleHidden' then player:SetAttribute('TestBattleVisible',false) end
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
    local function client(action,arg,expected)
        player:SetAttribute('TestAction',nil)
        player:SetAttribute('TestArg',arg)
        task.wait(0.2)
        player:SetAttribute('TestAction',action)
        -- Attribute replication, the client's FireServer and the server handler are one round trip. Poll for the
        -- expected state instead of a fixed wait; a fixed 0.5 s failed the chamber check on cold Studio runs.
        if expected then untilTrue(expected,6) else task.wait(0.5) end
    end
    check(#W.Plots==7 and #W.Areas==6,'seven plots and six mansion areas created with mansion path clear')
    local ghostCount=0
    for _ in H.Ghosts do ghostCount+=1 end
    check(ghostCount==42,'42 wild ghosts spawned')
    check(player.Character.HumanoidRootPart.Position.Y> -5,'spawn above town ground')
    check(untilTrue(function() return player:GetAttribute('TestClientReady') end,10),'client HUD loaded')
    client('EnterFloor',6)
    check((player:GetAttribute('Floor') or 0)==0,'locked area request rejected')
    client('EnterFloor',1,function() return player:GetAttribute('Floor')==1 end)
    check(player:GetAttribute('Floor')==1,'client entered foyer')
    local contactGhost
    for _,g in H.Ghosts do if g.Floor==1 then contactGhost=g; break end end
    player.Character:PivotTo(CFrame.new(contactGhost.Pos))
    check(untilTrue(function() return H.Active[player]~=nil end,2),'physical contact begins an encounter')
    local encounterGhost=H.Active[player]
    check(encounterGhost.IntroUntil and player.Character.HumanoidRootPart.Anchored,'intro reserves ghost and freezes movement')
    check(untilTrue(function() return player:GetAttribute('TestEncounterVisible') end,2),'client creates encounter overlay')
    H.click(player,encounterGhost.Id)
    check(encounterGhost.Progress==0,'intro blocks capture progress')
    check(untilTrue(function() return not encounterGhost.IntroUntil end,C.Encounter.Duration+2),'intro completes on server')
    check(player.Character.HumanoidRootPart.Anchored and encounterGhost.Battle,'intro enters 1v1 with mansion movement paused')
    check(untilTrue(function() return player:GetAttribute('TestEncounterVisible')==false end,2),'client removes completed overlay')
    check(untilTrue(function() return player:GetAttribute('TestBattleVisible')==true end,2),'client opens 1v1 screen')
    check(untilTrue(function() return encounterGhost.Spot~=nil end,3),'server issues a timed weak spot')
    local spot=encounterGhost.Spot
    local claim={Id=encounterGhost.Id,Token=spot.Token,X=spot.X,Y=spot.Y}
    local progress=encounterGhost.Progress
    H.weakSpot(player,claim)
    check(encounterGhost.Progress==progress,'early weak-spot claim is rejected in engine')
    untilTrue(function() return workspace:GetServerTimeNow()>=spot.EndsAt end,3)
    H.click(player,encounterGhost.Id); progress=encounterGhost.Progress
    H.weakSpot(player,claim)
    check(math.abs(encounterGhost.Progress-progress-C.Battle.SpotBonus)<0.001,'closing-circle bonus adds 12 percentage points in engine')
    progress=encounterGhost.Progress; H.weakSpot(player,claim)
    check(encounterGhost.Progress==progress,'duplicate bonus cannot be replayed in engine')
    local function catch()
        local ghost=H.Active[player]
        if not ghost then for _,g in H.Ghosts do if g.Floor==1 then ghost=g; break end end end
        assert(ghost,'No matching test ghost')
        local before=#p.Bag
        local deadline=os.clock()+25
        repeat
            ghost=H.Active[player] or ghost
            player.Character:PivotTo(CFrame.new(ghost.Pos+Vector3.new(0,0,7)))
            H.click(player,ghost.Id)
            task.wait(0.12)
        until #p.Bag>before or os.clock()>deadline
        check(#p.Bag==before+1,'server capture reaches completion: '..ghost.Species)
        return ghost.Species
    end
    local first=catch()
    check(p.Owned[first]==1 and p.Discovered[first],'capture ownership and discovery recorded once')
    check(not player.Character.HumanoidRootPart.Anchored,'capture restores mansion movement')
    check(untilTrue(function() return player:GetAttribute('TestBattleVisible')==false end,3),'capture result closes 1v1 screen')
    check(untilTrue(function() return player:GetAttribute('TestCameraScriptable')==false end,2),'capture restores exploration camera')
    client('Home',nil,function() return player:GetAttribute('Floor')==0 end)
    check(player:GetAttribute('Floor')==0,'client returned home')
    client('Deposit',nil,function() return #p.Bag==0 and #p.Placed==1 end)
    check(#p.Bag==0 and #p.Placed==1,'deposit frees bag and displays ghost')
    local light=player.Character:FindFirstChild('Lamp',true)
    local wasEnabled=light.Enabled
    client('Flashlight',nil,function() return light.Enabled~=wasEnabled end)
    check(light.Enabled~=wasEnabled,'flashlight toggles through validated client request')
    local cash=p.Money
    task.wait(1.3)
    check(p.Money>cash and Rules.income(p)>0,'placed ghost earns real server income')
    local before=p.Owned[first]
    client('Place',first)
    check(#p.Placed==1 and p.Owned[first]==before,'duplicate placement rejected')
    p.Money=1e9
    client('Upgrade','Movement',function() return p.Upgrades.Movement==2 end)
    local movementHumanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
    check(p.Upgrades.Movement==2 and movementHumanoid and movementHumanoid.WalkSpeed==24,'upgrade changes live movement speed')
    client('Upgrade','Haunt',function() return p.HauntLevel==2 end)
    check(p.HauntLevel==2,'haunt upgrade expands slots')
    client('Unlock',2,function() return p.Floor==2 end)
    check(p.Floor==2,'floor unlock charges and persists in profile')
    client('Chamber',nil,function() return player:GetAttribute('Chamber') and Chamber.Sessions[player]~=nil end)
    check(player:GetAttribute('Chamber') and Chamber.Sessions[player]~=nil,'chamber server session entered')
    check(untilTrue(function() return player:GetAttribute('TestCameraScriptable') end,4),'client camera enters top-down mode')
    local session=Chamber.Sessions[player]
    session.NextReward=os.clock()+0.2
    task.wait(0.8)
    check(p.ChamberDiscoveries==1,'autonomous chamber discovery grants once')
    client('ExitChamber',nil,function() return not player:GetAttribute('Chamber') and Chamber.Sessions[player]==nil end)
    check(not player:GetAttribute('Chamber') and Chamber.Sessions[player]==nil,'chamber exits and cleans its models')
    check(untilTrue(function() return player:GetAttribute('TestCameraScriptable')==false end,4),'client camera restores after chamber exit')
    p.Floor=6; p.Money=Rules.rebirthCost(p)
    client('Rebirth',nil,function() return p.Rebirths==1 end)
    check(p.Rebirths==1 and p.Floor==1 and p.HauntLevel==1 and #p.Placed==0,'rebirth resets temporary progression')
    check(p.Owned[first]>=1 and p.Discovered[first] and Rules.multiplier(p)==1.5,'rebirth keeps collection and increases multiplier')
    check(Profiles.save(player,false),'Studio practice save path completes')
    print('ACCEPTANCE COMPLETE: '..passed..' checks passed. DataStore network and multiplayer checks remain separate.')
end)
if not ok then warn(err) end

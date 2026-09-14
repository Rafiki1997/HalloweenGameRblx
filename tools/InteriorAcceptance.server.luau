-- Preview-only spatial checks for furnished rooms, window openings and hunting pockets.
local W=require(script.Parent.World)
local deadline=os.clock()+45
repeat task.wait(.2) until #W.Areas==6 or os.clock()>deadline
task.wait(3)
local passed,failed=0,0
local function check(name,fn)
    local ok,result=pcall(fn)
    if ok then passed+=1 else failed+=1 end
    print('INTERIOR '..(if ok then 'PASS ' else 'FAIL ')..name..': '..tostring(result or 'ok'))
end
for floor,area in W.Areas do
    check('floor '..floor..' windows and exit',function()
        local windows=0
        for _,p in area.Model:GetDescendants() do
            if p.Name=='WindowGlass' then
                windows+=1
                local q=RaycastParams.new(); q.FilterType=Enum.RaycastFilterType.Include; q.FilterDescendantsInstances={area.Model}; q.RespectCanCollide=true
                local origin=p.Position+p.CFrame.LookVector*4
                local hit=workspace:Raycast(origin,-p.CFrame.LookVector*5,q)
                assert(hit and hit.Instance==p,'solid wall covers a window opening')
            end
        end
        assert(floor>4 or windows==(if floor==1 then 5 else 4),'real window openings missing')
        assert(area.Exit:FindFirstChildOfClass('ProximityPrompt'),'return prompt missing')
        local delta=area.Exit.Position-area.Entry
        assert(Vector3.new(delta.X,0,delta.Z).Magnitude<13,'entry must be close to the return door')
        return windows..' window openings; return prompt present'
    end)
    check('floor '..floor..' ghost clearance and connected rooms',function()
        local obstacles={}
        for _,p in area.Model:GetDescendants() do
            if p:IsA('BasePart') and p.CanCollide and p.Name~='Floor' and p.Name~='Ceiling' then table.insert(obstacles,p) end
        end
        local q=OverlapParams.new(); q.FilterType=Enum.RaycastFilterType.Include; q.FilterDescendantsInstances=obstacles
        local samples=0
        for _,zone in area.GhostZones do
            for x=-zone.X,zone.X,zone.X/2 do for z=-zone.Z,zone.Z,zone.Z/2 do
                local pos=zone.Center+Vector3.new(x,0,z)
                local hits=workspace:GetPartBoundsInBox(CFrame.new(pos),Vector3.new(5,5,5),q)
                assert(#hits==0,'ghost pocket overlaps '..(hits[1] and hits[1].Name or '?')..' at '..tostring(pos-area.Center))
                samples+=1
            end end
        end
        local function key(x,z) return x..':'..z end
        local free={}
        for x=-60,60,2 do for z=-50,52,2 do
            free[key(x,z)]=#workspace:GetPartBoundsInBox(CFrame.new(area.Center+Vector3.new(x,3,z)),Vector3.new(3.6,5,3.6),q)==0
        end end
        local queue={{0,42}}; local seen={[key(0,42)]=true}; local head=1
        assert(free[key(0,42)],'arrival position obstructed')
        while head<=#queue do
            local point=queue[head]; head+=1
            for _,step in {{2,0},{-2,0},{0,2},{0,-2}} do
                local x,z=point[1]+step[1],point[2]+step[2]; local k=key(x,z)
                if free[k] and not seen[k] then seen[k]=true; table.insert(queue,{x,z}) end
            end
        end
        for _,zone in area.GhostZones do
            local offset=zone.Center-area.Center
            assert(seen[key(math.round(offset.X/2)*2,math.round(offset.Z/2)*2)],'hunting room disconnected from entry')
        end
        assert(seen[key(0,50)],'return door blocked')
        return samples..' ghost volume samples clear; all seven hunting pockets and exit connected'
    end)
end
print(string.format('INTERIOR COMPLETE %d passed; %d failed',passed,failed))

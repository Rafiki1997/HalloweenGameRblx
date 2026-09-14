-- Active reference terrain contract; runs with the standalone Luau interpreter.
local T=require('../src/server/ReferenceTerrain')
local groups,failures=0,0
local function check(name,fn)
    local ok,err=pcall(fn)
    groups+=1
    if ok then print('REFERENCE PASS '..name)
    else failures+=1; print('REFERENCE FAIL '..name..': '..tostring(err)) end
end
local function close(actual,expected,label)
    assert(math.abs(actual-expected)<.6,string.format('%s expected %.1f, got %.2f',label,expected,actual))
end
check('spawn, town, cemetery and entrance remain dry and level',function()
    for _,p in {{0,21},{0,215},{0,239},{-105,139},{132,143},{-117,106},{-117,152}} do
        close(T.height(p[1],p[2]),-.5,string.format('ground (%d,%d)',p[1],p[2]))
        assert(T.height(p[1],p[2])>T.WaterLevel+1,'public landmark underwater')
    end
end)
check('seven haunt cores support their elevated plots',function()
    assert(#T.HauntPads==7,'seven plot build pads required')
    for i,p in T.HauntPads do
        for _,offset in {{0,0},{-10,-10},{10,-10},{-10,10},{10,10}} do
            close(T.height(p[1]+offset[1],p[2]+offset[2]),p[3],'Haunt '..i..' core')
        end
    end
end)
check('western lake has depth, dry banks and a mud bed',function()
    for _,p in {{-122,15},{-110,30},{-145,0},{-122,-20}} do
        assert(T.height(p[1],p[2])<T.WaterLevel-5,'lake must have swimming depth')
        assert(T.material(p[1],p[2])=='Mud','lake bed should be mud')
    end
    for _,p in {{-45,15},{-205,15},{-122,94},{-122,-65}} do
        assert(T.height(p[1],p[2])>T.WaterLevel+1,'lake escaped its bank')
    end
end)
check('main entrance connects to a walkable raised mansion approach',function()
    local previous=T.height(0,239)
    for z=238,-186,-1 do
        local h=T.height(0,z)
        assert(h>T.WaterLevel+1,'avenue enters water or void at z '..z)
        assert(math.abs(h-previous)<math.tan(math.rad(50)),'avenue exceeds 50 degrees at z '..z)
        previous=h
    end
    close(T.height(0,-186),30,'mansion court')
    assert(T.height(0,-186)-T.height(0,0)>25,'mansion must stand above plaza')
end)
check('all seven pads connect to spawn over dry walkable terrain',function()
    -- Discover connectivity independently of the hand-authored path nodes.
    local step=4
    local heights={}
    local function key(x,z) return tostring(x)..':'..tostring(z) end
    for x=-228,204,step do for z=-220,240,step do heights[key(x,z)]=T.height(x,z) end end
    local queue={{0,0}}
    local visited={[key(0,0)]=true}
    local head=1
    while head<=#queue do
        local p=queue[head]; head+=1
        local h=heights[key(p[1],p[2])]
        for _,d in {{step,0},{-step,0},{0,step},{0,-step}} do
            local x,z=p[1]+d[1],p[2]+d[2]
            local k=key(x,z); local nextHeight=heights[k]
            if nextHeight and not visited[k] and nextHeight>T.WaterLevel+.5 and math.abs(nextHeight-h)<=step*math.tan(math.rad(60)) then
                visited[k]=true; table.insert(queue,{x,z})
            end
        end
    end
    for i,p in T.HauntPads do
        local x,z=math.round(p[1]/step)*step,math.round(p[2]/step)*step
        assert(visited[key(x,z)],'Haunt '..i..' isolated by water, void or unwalkable terrain')
    end
    print('REFERENCE INFO reachable dry grid cells '..#queue)
end)
check('island ends in cliffs and open void instead of an enclosing ground slab',function()
    for _,p in {{300,0},{-300,0},{0,300},{0,-300},{280,280},{-280,-280}} do
        assert(T.height(p[1],p[2])< -80,'outside island should be empty at '..p[1]..','..p[2])
    end
    local cliff=false
    for x=230,270,2 do
        if T.height(x,0)<-20 and T.material(x,0)=='Rock' then cliff=true end
    end
    assert(cliff,'eastern island edge lacks exposed cliff')
end)
print(string.format('REFERENCE COMPLETE %d pure groups passed; %d failed',groups-failures,failures))
assert(failures==0,'reference terrain contract failed')

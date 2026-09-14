local P=require('../src/server/MapPlan')
local T=require('../src/server/ReferenceTerrain')
local function localPoint(x,z,p)
    local a=math.rad(p[4]); local dx,dz=x-p[1],z-p[3]
    return math.cos(a)*dx-math.sin(a)*dz,math.sin(a)*dx+math.cos(a)*dz
end
local count=0
for id,a in T.Approaches do
    local grade=math.abs(a.high-a.low)/a.climbRun
    assert(grade<math.tan(math.rad(38)),id..' stair flight is too steep')
    assert(grade*.65<=.5,id..' stair riser requires jumping')
    local previous=T.approachHeight(id,0)
    for distance=.25,a.length,.25 do
        local height=T.approachHeight(id,distance)
        assert(math.abs(height-previous)<=.25*math.tan(math.rad(38)),id..' has an abrupt height change')
        previous=height
    end
    assert(math.abs(T.approachHeight(id,a.length)-a.high)<.001,id..' landing misses the courtyard')
end
for _,r in P.Routes do
    for j=1,#r.points-1 do
        local a,b=r.points[j],r.points[j+1]
        local length=math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2)
        assert(length>.05,r.id..' contains a duplicate segment')
        for k=0,math.ceil(length*2) do
            local t=k/math.ceil(length*2); local x,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t
            assert(r.bridge or T.height(x,z)>-2,string.format('%s enters lake/void at %.1f,%.1f (%.1f)',r.id,x,z,T.height(x,z)))
            for i,plot in P.Plots do
                local lx,lz=localPoint(x,z,plot)
                local margin=r.width*.5+.5
                if math.abs(lx)<23*P.Scale+margin and math.abs(lz)<20*P.Scale+margin then
                    assert(r.plot==i and math.abs(lx)<.1 and lz<=-19.5*P.Scale+.1,
                        string.format('%s runs into plot %d at %.1f,%.1f (local %.1f,%.1f)',r.id,i,x,z,lx,lz))
                end
            end
            local shops={}
            for _,s in P.Shops do table.insert(shops,{s[1],0,s[2],s[3]}) end
            for _,s in shops do
                local lx,lz=localPoint(x,z,s)
                assert(math.abs(lx)>=12.35+r.width*.5 or math.abs(lz)>=10.38+r.width*.5,
                    string.format('%s intersects village house %.0f,%.0f at %.1f,%.1f',r.id,s[1],s[3],x,z))
            end
            for si,sz in {106,129,152} do
                assert((r.id=='shop-door-'..si and x>=-108.91) or math.abs(x+117.7)>=8.8+r.width*.5 or math.abs(z-sz)>=11+r.width*.5,
                    r.id..' intersects an original shop')
            end
            count+=1
        end
    end
end
local segments={}
for _,r in P.Routes do for j=1,#r.points-1 do table.insert(segments,{r.points[j],r.points[j+1],r.id}) end end
local function cross(ax,az,bx,bz) return ax*bz-az*bx end
for i,a in segments do for j=i+1,#segments do
    local b=segments[j]
    local ax,az=a[2][1]-a[1][1],a[2][2]-a[1][2]
    local bx,bz=b[2][1]-b[1][1],b[2][2]-b[1][2]
    local dx,dz=b[1][1]-a[1][1],b[1][2]-a[1][2]
    local det=cross(ax,az,bx,bz)
    if math.abs(det)>.0001 then
        local u,v=cross(dx,dz,bx,bz)/det,cross(dx,dz,ax,az)/det
        assert(not(u>.001 and u<.999 and v>.001 and v<.999),a[3]..' crosses '..b[3]..' away from a junction')
    elseif math.abs(cross(dx,dz,ax,az))<.001 then
        local length2=ax*ax+az*az
        local u=(dx*ax+dz*az)/length2
        local v=((b[2][1]-a[1][1])*ax+(b[2][2]-a[1][2])*az)/length2
        local overlap=math.min(1,math.max(u,v))-math.max(0,math.min(u,v))
        assert(overlap*math.sqrt(length2)<.1,a[3]..' duplicates paving along '..b[3])
    end
end end
for _,i in {4,5,6,7} do
    local p=P.Plots[i]; local a=math.rad(p[4]); local dot=(math.sin(a)*p[1]+math.cos(a)*p[3])/math.sqrt(p[1]^2+p[3]^2)
    assert(dot>.999,'plot '..i..' faces away from the plaza')
end
print('ROUTES PASS '..count..' dry route/footprint samples; no duplicate paving or unintended crossings; marked plots face plaza')

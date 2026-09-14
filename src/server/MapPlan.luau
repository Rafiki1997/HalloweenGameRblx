-- Shared plan for buildings, terrain pads and the pedestrian network. X/Z coordinates in studs.
local Plan={}
Plan.Plots={
    {-160,15,-105,165},{-70,10,-85,180},{80,17,-100,190},
    {160,12,-50,math.deg(math.atan2(160,-50))},
    {145,4,45,math.deg(math.atan2(145,45))},
    {-55,0,215,math.deg(math.atan2(-55,215))},
    {62,0,208,math.deg(math.atan2(62,208))},
}
Plan.Scale=1.4
Plan.Shops={{-60,153,-90},{-107,184,160},{-142,173,120},{-162,139,90},{-76,110,180},{-149,111,55}}
Plan.Routes={}
local function route(id,width,points,bridge)
    table.insert(Plan.Routes,{id=id,width=width,points=points,bridge=bridge or false})
end
local function front(index,distance)
    local p=Plan.Plots[index]; local a=math.rad(p[4])
    return {p[1]-math.sin(a)*distance*Plan.Scale,p[3]-math.cos(a)*distance*Plan.Scale}
end
Plan.front=front
local function gate(id,index,points)
    local approach=front(index,30)
    local last=points[#points]
    if (last[1]-approach[1])^2+(last[2]-approach[2])^2>.01 then table.insert(points,approach) end
    table.insert(points,front(index,19.5))
    route(id,7,points)
    Plan.Routes[#Plan.Routes].plot=index
end
local diagonal=45/math.sqrt(2)
route('entrance',16,{{0,45},{0,90},{0,135},{0,170},{0,239}})
route('mansion',18,{{0,-45},{0,-90},{0,-140},{0,-157}})
route('northwest-lane',9,{{-diagonal,-diagonal},{-50,-43},{-70,-43}})
gate('blue-gate',2,{{-70,-43}})
route('north-bank-bridge',7,{{-70,-43},{-88,-43},{-111,-53}},true)
gate('violet-gate',1,{{-111,-53},{-148,-60}})
route('northeast-lane',9,{{diagonal,-diagonal},{56,-40}})
gate('green-gate',3,{{56,-40}})
gate('red-gate',4,{{56,-40},{90,-25}})
route('east-lane',9,{{45,0},{70,15}})
gate('cyan-gate',5,{{70,15}})
route('cemetery-lane',9,{{70,15},{76,80},{76,135}})
route('cemetery-entrance',7,{{0,135},{76,135},{105,135}})
gate('rose-gate',6,{{0,170},{-28,171}})
gate('amber-gate',7,{{0,170},{29,168}})
route('village-entrance',10,{{0,135},{-51,135},{-77,135},{-96,135}})
route('village-street',8,{{-96,110},{-96,133.2},{-96,135},{-96,156.2},{-96,160}})
for i,z in {110.2,133.2,156.2} do
    route('shop-door-'..i,5,{{-96,z},{-108.9,z}})
end
route('lake-east-bank',8,{{-45,0},{-49,28},{-59,60},{-77,88}})
route('village-north',8,{{-77,88},{-96,93},{-96,110}})
route('lake-south-bank',8,{{-77,88},{-122,88},{-150,82}})
route('south-dock',7,{{-150,82},{-148,65}},true)
route('lake-west-bank',6,{{-150,82},{-193,78},{-203,36},{-197,10}})
route('west-dock',6,{{-197,10},{-183,10}},true)
route('east-dock',6,{{-49,28},{-57,19},{-66,19}},true)
return Plan

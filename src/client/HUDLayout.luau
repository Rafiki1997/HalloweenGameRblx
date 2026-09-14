-- Pure layout math: sizes are in the ScreenGui's safe area, not the raw viewport.
local function region(x,y,w,h,s) return {X=x,Y=y,W=w,H=h,Scale=s} end
return function(w,h,touch)
    local wide=w>=1050 and h>=560
    local portrait=w<h and w<650
    local s=math.clamp(math.min(w/1500,h/820),0.72,1.05)
    local result={Portrait=portrait,Wide=wide,NavStep=118,NavHeight=110,ActionStep=118,ActionHeight=110}
    if wide then
        result.Nav=region(18,math.max(112*s,(h-464*s)/2),110,464,s)
        result.Quest=region((w-430*s)/2,12,430,112,s)
        result.Wallet=region(w-236*s-18,112*s,236,164,s)
        result.Dock=region((w-288*s)/2,h-110*s-20,288,110,s)
        result.Actions=region(w-224*s-20,h-110*s-(if touch then 150 else 20),224,110,s)
        result.Columns=1
    elseif portrait then
        s=math.clamp(w/470,0.66,0.9)
        local qs=(w-28)/430
        local top=112*qs+26
        result.Quest=region(14,8,430,112,qs)
        result.NavStep=96; result.NavHeight=88; result.ActionStep=106; result.ActionHeight=98
        result.Nav=region(12,top,110,376,s)
        result.Wallet=region(w-236*s-12,top,236,164,s)
        result.Dock=region((w-132*s)/2,h-188*s-16,132,188,s)
        result.Actions=region(w-106*s-12,top+164*s+16,106,204,s)
        result.Columns=1
    else
        s=math.clamp(math.min(w/1180,h/500),0.60,0.88)
        result.Nav=region(12,12,228,228,s)
        result.Quest=region((w-390*s)/2,8,390,112,s)
        result.Wallet=region(w-236*s-12,12,236,164,s)
        result.Dock=region((w-288*s)/2,h-110*s-12,288,110,s)
        result.Actions=region(w-224*s-12,164*s+26,224,110,s)
        result.Columns=2
    end
    result.Panel=region((w-math.min(760,w-28))/2,(h-math.min(590,h-24))/2,math.min(760,w-28),math.min(590,h-24),1)
    result.Capture=region((w-math.min(410,w-40))/2,math.max(135,h-240),math.min(410,w-40),82,1)
    return result
end

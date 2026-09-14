local layout=require('../src/client/HUDLayout')
local cases={{1920,1020},{1366,710},{1050,560},{1024,710},{844,330},{667,310},{390,744},{320,520}}
local function bounds(r) return r.X,r.Y,r.X+r.W*r.Scale,r.Y+r.H*r.Scale end
for _,size in cases do
    local l=layout(size[1],size[2],size[1]<1050)
    local names={'Nav','Wallet','Quest','Dock','Actions'}
    for i,name in names do
        local x,y,right,bottom=bounds(l[name])
        assert(x>=0 and y>=0 and right<=size[1] and bottom<=size[2],name..' outside '..size[1]..'x'..size[2])
        for j=i+1,#names do
            local nx,ny,nright,nbottom=bounds(l[names[j]])
            assert(right<=nx or nright<=x or bottom<=ny or nbottom<=y,name..' overlaps '..names[j]..' at '..size[1]..'x'..size[2])
        end
    end
    assert(106*l.Actions.Scale>=44,'Action touch target smaller than 44px')
    assert(110*l.Nav.Scale>=44,'Menu touch target smaller than 44px')
    print('HUD PASS visible controls, no overlaps, accessible targets: '..size[1]..'x'..size[2])
end

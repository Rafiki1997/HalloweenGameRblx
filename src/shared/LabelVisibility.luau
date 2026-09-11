-- Client-only proximity and screen-overlap filtering. Text remains server-owned.
local Labels={}
function Labels.start(player,focus)
    local labels={}
    local function register(item)
        if item:IsA('BillboardGui') and item:GetAttribute('ContextLabel') then labels[item]=true end
    end
    for _,item in workspace:GetDescendants() do register(item) end
    workspace.DescendantAdded:Connect(register)
    workspace.DescendantRemoving:Connect(function(item) labels[item]=nil end)
    local elapsed=0
    game:GetService('RunService').Heartbeat:Connect(function(dt)
        elapsed+=dt
        if elapsed<.12 then return end
        elapsed=0
        local camera=workspace.CurrentCamera
        local character=player.Character
        local root=character and character:FindFirstChild('HumanoidRootPart')
        if not camera or not root then return end
        local target=focus()
        local candidates={}
        for gui in labels do
            gui.Enabled=false
            local anchor=gui.Adornee or gui.Parent
            if not anchor:IsA('BasePart') then continue end
            local distance=(root.Position-anchor.Position).Magnitude
            if distance>(gui:GetAttribute('ReadDistance') or 42) then continue end
            local isGhost=gui:GetAttribute('GhostLabel')
            if isGhost and (not target or not gui:IsDescendantOf(target)) then continue end
            local point,visible=camera:WorldToViewportPoint(anchor.Position+gui.StudsOffset+gui.StudsOffsetWorldSpace)
            if not visible then continue end
            local w,h=gui.Size.X.Offset,gui.Size.Y.Offset
            local rect={x=point.X-w/2-8,y=point.Y-h/2-6,w=w+16,h=h+12}
            table.insert(candidates,{gui=gui,rect=rect,score=distance-(isGhost and 1000 or 0)})
        end
        table.sort(candidates,function(a,b) return a.score<b.score end)
        local shown={}
        for _,candidate in candidates do
            local r=candidate.rect
            local clear=true
            for _,other in shown do
                if r.x<other.x+other.w and r.x+r.w>other.x and r.y<other.y+other.h and r.y+r.h>other.y then clear=false; break end
            end
            if clear then
                candidate.gui.Enabled=true; table.insert(shown,r)
                if #shown>=4 then break end
            end
        end
    end)
end
return Labels

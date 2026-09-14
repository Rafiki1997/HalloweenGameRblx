-- Appended to Main only in --ui-preview builds; never part of production.
return function(ui,open,close,ghostCard)
    local Players=game:GetService('Players')
    local ContentProvider=game:GetService('ContentProvider')
    local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight')
    local remote=Shared:WaitForChild('Action')
    local function waitFor(fn)
        local endAt=os.clock()+15
        repeat if fn() then return true end; task.wait(.1) until os.clock()>endAt
        return false
    end
    local passed=0
    local function check(value,message)
        assert(value,'UI ACCEPTANCE FAIL '..message)
        passed+=1; print('UI ACCEPTANCE PASS '..message)
    end
    local ok,err=xpcall(function()
        check(waitFor(function() return ui.Objective.Text~='Loading your Haunt...' end),'actual server state reaches the HUD')
        ContentProvider:PreloadAsync({require(script.Parent.UITheme).Atlas})
        check(ui.Buttons.Haunt.HauntIcon.Art.IsLoaded,'published transparent icon atlas loads in Studio')
        local originalSize=ui.Root.Size
        for _,size in {{1920,1020},{1366,710},{1050,560},{1024,710},{844,330},{667,310},{390,744},{320,520}} do
            ui.Root.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.15); ui:resize(); task.wait(.15)
            local controls={ui.Nav,ui.Wallet,ui.Quest,ui.Dock,ui.Actions}
            local origin=ui.Root.AbsolutePosition
            for i,a in controls do
                local p,s=a.AbsolutePosition-origin,a.AbsoluteSize
                check(p.X>=-1 and p.Y>=-1 and p.X+s.X<=size[1]+1 and p.Y+s.Y<=size[2]+1,a.Name..' on screen '..size[1]..'x'..size[2])
                for j=i+1,#controls do
                    local b=controls[j]; local q,t=b.AbsolutePosition-origin,b.AbsoluteSize
                    assert(p.X+s.X<=q.X+1 or q.X+t.X<=p.X+1 or p.Y+s.Y<=q.Y+1 or q.Y+t.Y<=p.Y+1,'UI ACCEPTANCE FAIL overlapping engine rectangles')
                end
            end
            check(ui.Vacuum.AbsoluteSize.X>=44 and ui.Vacuum.AbsoluteSize.Y>=44,'vacuum target at least 44px '..size[1]..'x'..size[2])
        end
        ui.Root.Size=originalSize; task.wait(.2); ui:resize()
        for _,name in {'Haunt','Collection','Mansion','Upgrades','Rebirth'} do
            open(name); task.wait(.3)
            check(ui.Modal.Visible and not ui.Actions.Visible and not ui.Nav.Visible,name..' opens and hides gameplay controls')
            check(#ui.List:GetChildren()>2,name..' contains actual game content')
            ui.Root.Size=UDim2.fromOffset(390,744); task.wait(.2); ui:resize(); task.wait(.2)
            for _,row in ui.List:GetChildren() do
                local copy=row:FindFirstChild('Copy')
                if copy then check(copy.TextFits,name..' phone text fits its row') end
            end
            ui.Root.Size=originalSize; task.wait(.2); ui:resize()
            if name=='Collection' then
                check(ui.List:FindFirstChildOfClass('UIGridLayout')~=nil,'collection uses a responsive ghost grid')
                ui.Root.Size=UDim2.fromOffset(390,744); task.wait(.2); ui:resize()
                check(ui.List:FindFirstChildOfClass('UIGridLayout').CellSize.X.Scale==.5,'phone collection uses two columns')
                ui.Root.Size=originalSize; task.wait(.2); ui:resize()
                ghostCard('little_boo',{Discovered={little_boo=true},Owned={little_boo=1}})
                local portrait=ui.List:GetChildren()[#ui.List:GetChildren()]:FindFirstChild('GhostPortrait')
                check(portrait and waitFor(function() return portrait.CurrentCamera~=nil end),'discovered ghost loads its 3D collection portrait')
            end
            close(); task.wait(.1)
            check(not ui.Modal.Visible and ui.Actions.Visible and ui.Nav.Visible,name..' closes and restores exploration')
        end
        ui:setCapacity(3,3)
        check(ui.CapacityHint.Text=='FULL','full vacuum has an explicit text warning')
        remote:FireServer('Sync'); task.wait(.5)
        check(ui.CapacityHint.Text=='VACUUM','server state replaces the temporary capacity test')
        print('UI ACCEPTANCE COMPLETE '..passed..' checks passed')
        -- QA-only review control, reached through a PlayerGui attribute or native input.
        ui.Gui:GetAttributeChangedSignal('ReviewPanel'):Connect(function()
            local name=ui.Gui:GetAttribute('ReviewPanel')
            if name=='' then close() else open(name) end
        end)
        local camera=workspace.CurrentCamera
        local oldType=camera.CameraType
        game:GetService('RunService'):BindToRenderStep('HUDReview',220,function()
            camera.CameraType=Enum.CameraType.Scriptable
            camera.CFrame=CFrame.lookAt(Vector3.new(35,20,94),Vector3.new(0,20,-40))
        end)
        close(); print('UI REVIEW HUD'); task.wait(18)
        open('Collection'); print('UI REVIEW Collection'); task.wait(18)
        close(); ui.Root.Size=UDim2.fromOffset(844,330); print('UI REVIEW Phone HUD'); task.wait(18)
        ui.Root.Size=UDim2.fromOffset(390,744); open('Mansion'); print('UI REVIEW Phone Mansion'); task.wait(18)
        ui.Root.Size=originalSize; close(); ui:resize()
        game:GetService('RunService'):UnbindFromRenderStep('HUDReview'); camera.CameraType=oldType
        print('UI REVIEW COMPLETE')
    end,debug.traceback)
    if not ok then warn(err); ui.Root.Size=UDim2.fromScale(1,1); close() end
end

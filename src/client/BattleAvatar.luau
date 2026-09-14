-- A deterministic display rig using the player's appearance, not their current animation pose.
local V=require(game:GetService('ReplicatedStorage'):WaitForChild('Ghostlight').Visuals)
local Avatar={}
local poses={
    RightShoulder={65,0,8}, ['Right Shoulder']={75,0,8},
    LeftShoulder={30,0,-10}, ['Left Shoulder']={30,0,-10},
    RightElbow={20,0,0}, LeftElbow={15,0,0}, RightWrist={-10,0,0},
}
function Avatar.create(character)
    local archivable=character.Archivable
    character.Archivable=true
    local ok,model=pcall(function() return character:Clone() end)
    character.Archivable=archivable
    assert(ok and model,'Could not clone the battle avatar')
    local built,err=xpcall(function()
        model.Name='BattleAvatar'
        for _,obj in model:GetDescendants() do
            if obj:IsA('Tool') or obj:IsA('Script') or obj:IsA('LocalScript') or obj:IsA('Animator')
                or obj:IsA('AnimationController') or obj:IsA('Sound') or obj:IsA('Beam') or obj:IsA('Trail') then
                obj:Destroy()
            elseif obj:IsA('BasePart') then
                obj.Anchored=true; obj.CanCollide=false; obj.LocalTransparencyModifier=0
            end
        end
        local root=model:FindFirstChild('HumanoidRootPart')
        assert(root,'Battle avatar has no root')
        model.PrimaryPart=root
        model:PivotTo(root.CFrame:Inverse()*model:GetPivot())
        local joints={}
        for _,joint in model:GetDescendants() do
            if (joint:IsA('JointInstance') or joint:IsA('WeldConstraint')) and joint.Part0 and joint.Part1
                and joint.Part0:IsDescendantOf(model) and joint.Part1:IsDescendantOf(model) then
                local offset
                if joint:IsA('WeldConstraint') then
                    offset=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)
                else
                    if joint:IsA('Motor6D') then
                        joint.Transform=CFrame.new()
                        local pose=poses[joint.Name]
                        if pose then
                            -- Rotate in the parent's axes so both R6 and R15 shoulder bases work.
                            joint.C0=CFrame.new(joint.C0.Position)*CFrame.Angles(math.rad(pose[1]),math.rad(pose[2]),math.rad(pose[3]))*joint.C0.Rotation
                        end
                    end
                    offset=joint.C0*joint.C1:Inverse()
                end
                table.insert(joints,{Parent=joint.Part0,Child=joint.Part1,Offset=offset})
            end
        end
        -- Anchored viewport rigs do not solve joints automatically. Rebuild the body and
        -- accessory CFrames from the neutral skeleton, removing any captured run/jump pose.
        local solved={[root]=true}
        for _=1,#joints do
            local changed=false
            for _,joint in joints do
                if solved[joint.Parent] and not solved[joint.Child] then
                    joint.Child.CFrame=joint.Parent.CFrame*joint.Offset
                    solved[joint.Child]=true; changed=true
                end
            end
            if not changed then break end
        end
        local hand=model:FindFirstChild('RightHand') or model:FindFirstChild('Right Arm')
        assert(hand,'Battle avatar has no right hand')
        local gripAttachment=hand:FindFirstChild('RightGripAttachment')
        local gripPosition=if gripAttachment then gripAttachment.Position else Vector3.new(0,-hand.Size.Y*0.5,0)
        -- Always create a fresh vacuum: a cloned live Tool can retain a stale RightGrip,
        -- suction effects or a position from the middle of an equipment animation.
        local vacuum=V.vacuum(); vacuum.Parent=model
        local handle=vacuum.Handle
        local gripCF=CFrame.new(hand.CFrame:PointToWorldSpace(gripPosition))*root.CFrame.Rotation
        local delta=gripCF*handle.CFrame:Inverse()
        for _,part in vacuum:GetDescendants() do
            if part:IsA('BasePart') then part.CFrame=delta*part.CFrame; part.Anchored=true end
        end
        local weld=Instance.new('Weld'); weld.Name='BattleGrip'; weld.Part0=hand; weld.Part1=handle
        weld.C0=hand.CFrame:ToObjectSpace(gripCF); weld.C1=CFrame.new(); weld.Parent=hand
        model:SetAttribute('BattlePose','VacuumReadyV1')
    end,debug.traceback)
    if not built then model:Destroy(); error(err) end
    return model
end
return Avatar

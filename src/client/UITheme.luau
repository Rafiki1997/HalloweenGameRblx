-- Pumpkin Parade: shared presentation primitives. Gameplay remains in Main.
local TweenService=game:GetService('TweenService')
local T={}
T.Colors={Background=Color3.fromRGB(31,15,51),Panel=Color3.fromRGB(59,27,87),
    Ink=Color3.fromRGB(255,244,214),Purple=Color3.fromRGB(196,133,255),
    Mint=Color3.fromRGB(117,255,214),Orange=Color3.fromRGB(255,167,64),
    Outline=Color3.fromRGB(17,10,29),Muted=Color3.fromRGB(198,178,216)}
T.Atlas='rbxassetid://119439463451097'
local cells={Haunt={0,0},Mansion={1,0},Upgrades={2,0},Rebirth={3,0},Collection={0,1},Vacuum={1,1},Light={2,1},Coin={3,1}}
function T.make(class,parent,props)
    local obj=Instance.new(class)
    for k,v in props do obj[k]=v end
    obj.Parent=parent
    return obj
end
function T.corner(obj,radius)
    return T.make('UICorner',obj,{CornerRadius=UDim.new(0,radius or 16)})
end
function T.stroke(obj,color,width)
    return T.make('UIStroke',obj,{Color=color or T.Colors.Purple,Thickness=width or 2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
function T.gradient(obj,top,bottom)
    return T.make('UIGradient',obj,{Color=ColorSequence.new(top,bottom),Rotation=90})
end
function T.frame(parent,size,pos,color)
    local obj=T.make('Frame',parent,{Size=size,Position=pos,BackgroundColor3=color or T.Colors.Background,BorderSizePixel=0})
    T.corner(obj)
    return obj
end
function T.label(parent,text,size,pos,fontSize,color)
    local obj=T.make('TextLabel',parent,{Size=size,Position=pos,BackgroundTransparency=1,Text=text,
        TextColor3=color or T.Colors.Ink,Font=Enum.Font.FredokaOne,TextSize=fontSize or 20,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,TextStrokeColor3=T.Colors.Outline,TextStrokeTransparency=0.45})
    return obj
end
function T.body(parent,text,size,pos,fontSize,color)
    local obj=T.label(parent,text,size,pos,fontSize or 17,color or T.Colors.Muted)
    obj.Font=Enum.Font.GothamMedium; obj.TextStrokeTransparency=1
    return obj
end
function T.plate(parent,name,size,pos,accent)
    local f=T.frame(parent,size,pos,Color3.new(1,1,1)); f.Name=name
    T.gradient(f,Color3.fromRGB(73,33,108),T.Colors.Background)
    T.stroke(f,accent or T.Colors.Orange,3)
    local rim=T.frame(f,UDim2.new(1,-10,1,-10),UDim2.fromOffset(5,5)); rim.Name='InnerRim'; rim.BackgroundTransparency=1
    T.stroke(rim,T.Colors.Purple,1).Transparency=0.3
    return f
end
function T.icon(parent,name,size,pos)
    -- Scale the entire sheet inside a clipped cell. This remains correct even if
    -- Roblox resizes the uploaded texture; no hard-coded source pixel dimensions.
    local c=cells[name] or cells.Collection
    local clip=T.make('Frame',parent,{Name=name..'Icon',Size=size,Position=pos,BackgroundTransparency=1,ClipsDescendants=true})
    T.make('ImageLabel',clip,{Name='Art',Size=UDim2.fromScale(4,2),Position=UDim2.fromScale(-c[1],-c[2]),
        BackgroundTransparency=1,Image=T.Atlas,ScaleType=Enum.ScaleType.Stretch})
    return clip
end
function T.feedback(b)
    local scale=T.make('UIScale',b,{Scale=1})
    local tween
    local function to(value)
        if tween then tween:Cancel() end
        tween=TweenService:Create(scale,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{Scale=value}); tween:Play()
    end
    b.MouseEnter:Connect(function() to(1.035) end)
    b.MouseLeave:Connect(function() to(1) end)
    b.SelectionGained:Connect(function() to(1.035) end)
    b.SelectionLost:Connect(function() to(1) end)
    b.MouseButton1Down:Connect(function() to(0.96) end)
    b.MouseButton1Up:Connect(function() to(1) end)
    b.Activated:Connect(function() to(1) end)
end
function T.button(parent,text,size,pos,callback,color)
    local b=T.make('TextButton',parent,{Name=text,Size=size,Position=pos,Text=text,TextColor3=if color then T.Colors.Outline else T.Colors.Ink,
        BackgroundColor3=color or T.Colors.Panel,Font=Enum.Font.FredokaOne,TextSize=18,TextWrapped=true,BorderSizePixel=0,AutoButtonColor=true})
    T.corner(b,12); T.stroke(b,if color then Color3.fromRGB(255,208,119) else T.Colors.Purple,2)
    b.Activated:Connect(callback); T.feedback(b)
    return b
end
function T.iconButton(parent,name,caption,size,pos,callback,accent)
    local b=T.button(parent,'',size,pos,callback)
    b.Name=name; b.BackgroundColor3=Color3.new(1,1,1)
    b:FindFirstChildOfClass('UIStroke').Color=accent or T.Colors.Orange
    b:FindFirstChildOfClass('UIStroke').Thickness=3
    T.gradient(b,Color3.fromRGB(100,48,150),T.Colors.Background)
    local rim=T.frame(b,UDim2.new(1,-9,1,-9),UDim2.fromOffset(4.5,4.5)); rim.BackgroundTransparency=1
    T.stroke(rim,T.Colors.Purple,1)
    local art=T.icon(b,name,UDim2.new(1,-16,1,-34),UDim2.fromOffset(8,2))
    T.make('UIAspectRatioConstraint',art,{AspectRatio=1,DominantAxis=Enum.DominantAxis.Height})
    art.AnchorPoint=Vector2.new(0.5,0); art.Position=UDim2.new(0.5,0,0,2)
    local label=T.label(b,caption,UDim2.new(1,-6,0,28),UDim2.new(0,3,1,-30),22)
    label.Name='Caption'; label.TextXAlignment=Enum.TextXAlignment.Center
    return b
end
return T

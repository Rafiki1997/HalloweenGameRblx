local UserInputService=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local T=require(script.Parent.UITheme)
local layout=require(script.Parent.HUDLayout)
local C=T.Colors
local HUD={}
function HUD.new(gui,callbacks)
    gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
    gui.DisplayOrder=10
    local self=setmetatable({}, {__index=HUD})
    self.Gui=gui
    self.Root=T.make('Frame',gui,{Name='SafeArea',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    local root=self.Root
    self.Nav=T.make('Frame',root,{Name='Navigation',BackgroundTransparency=1})
    self.Buttons={}
    for _,name in {'Haunt','Mansion','Upgrades','Rebirth'} do
        self.Buttons[name]=T.iconButton(self.Nav,name,name,UDim2.fromOffset(110,110),UDim2.new(),function() callbacks.Navigate(name) end)
    end
    self.Wallet=T.plate(root,'Wallet',UDim2.fromOffset(236,164),UDim2.new())
    T.icon(self.Wallet,'Coin',UDim2.fromOffset(54,54),UDim2.fromOffset(10,10))
    self.Cash=T.label(self.Wallet,'$0',UDim2.fromOffset(160,51),UDim2.fromOffset(64,10),37)
    self.Cash.Name='Cash'; self.Cash.TextScaled=true
    T.make('UITextSizeConstraint',self.Cash,{MinTextSize=20,MaxTextSize=37})
    self.Income=T.label(self.Wallet,'+$0 / sec',UDim2.fromOffset(214,30),UDim2.fromOffset(11,64),25,C.Mint)
    self.Income.Name='Income'; self.Income.TextXAlignment=Enum.TextXAlignment.Center
    self.Bonus=T.label(self.Wallet,'1x BONUS',UDim2.fromOffset(214,26),UDim2.fromOffset(11,100),18)
    self.Bonus.Name='Bonus'; self.Bonus.TextXAlignment=Enum.TextXAlignment.Center
    self.Rebirths=T.label(self.Wallet,'REBIRTHS 0',UDim2.fromOffset(214,24),UDim2.fromOffset(11,131),17,C.Purple)
    self.Rebirths.Name='Rebirths'; self.Rebirths.TextXAlignment=Enum.TextXAlignment.Center
    self.Quest=T.plate(root,'Quest',UDim2.fromOffset(430,112),UDim2.new())
    T.icon(self.Quest,'Collection',UDim2.fromOffset(84,84),UDim2.fromOffset(6,12))
    self.QuestTitle=T.label(self.Quest,'First Haunt',UDim2.new(1,-110,0,32),UDim2.fromOffset(96,9),28)
    self.QuestTitle.Name='Heading'
    self.Objective=T.body(self.Quest,'Loading your Haunt...',UDim2.new(1,-108,0,39),UDim2.fromOffset(96,39),15,C.Ink)
    self.Objective.Name='Objective'
    local track=T.frame(self.Quest,UDim2.new(1,-112,0,19),UDim2.fromOffset(96,84),C.Outline)
    T.stroke(track,C.Purple,1)
    self.QuestBar=T.frame(track,UDim2.fromScale(0,1),UDim2.new(),C.Mint); self.QuestBar.Name='Progress'
    self.QuestProgress=T.label(track,'0 / 1',UDim2.fromScale(1,1),UDim2.new(),15)
    self.QuestProgress.Name='ProgressText'; self.QuestProgress.TextXAlignment=Enum.TextXAlignment.Center
    self.Practice=T.body(root,'',UDim2.fromOffset(110,20),UDim2.new(),12)
    self.Practice.Name='Practice'; self.Practice.TextXAlignment=Enum.TextXAlignment.Right
    self.Dock=T.make('Frame',root,{Name='CollectionDock',BackgroundTransparency=1})
    self.Buttons.Collection=T.iconButton(self.Dock,'Collection','Collection',UDim2.fromOffset(150,110),UDim2.new(),function() callbacks.Navigate('Collection') end)
    self.Bag=T.plate(self.Dock,'VacuumCapacity',UDim2.fromOffset(126,64),UDim2.fromOffset(162,46),C.Purple)
    T.icon(self.Bag,'Vacuum',UDim2.fromOffset(43,43),UDim2.fromOffset(5,10))
    self.Capacity=T.label(self.Bag,'0 / 3',UDim2.fromOffset(70,27),UDim2.fromOffset(49,10),23)
    self.Capacity.Name='Capacity'
    self.CapacityHint=T.label(self.Bag,'VACUUM',UDim2.fromOffset(70,17),UDim2.fromOffset(49,37),11,C.Muted)
    self.Actions=T.make('Frame',root,{Name='Actions',BackgroundTransparency=1})
    self.Light=T.iconButton(self.Actions,'Light','Light',UDim2.fromOffset(106,110),UDim2.new(),callbacks.Light,C.Purple)
    self.Vacuum=T.iconButton(self.Actions,'Vacuum','Vacuum',UDim2.fromOffset(106,110),UDim2.fromOffset(118,0),callbacks.Vacuum,C.Purple)
    self.LightHint=T.label(self.Light,'F',UDim2.fromOffset(28,23),UDim2.fromOffset(5,4),14)
    self.VacuumHint=T.label(self.Vacuum,'CLICK',UDim2.fromOffset(50,23),UDim2.fromOffset(5,4),12)
    self.Modal=T.make('Frame',root,{Name='Modal',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false,ZIndex=20})
    local shade=T.make('TextButton',self.Modal,{Name='Scrim',Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=C.Outline,
        BackgroundTransparency=0.28,AutoButtonColor=false,BorderSizePixel=0,Selectable=false})
    shade.Activated:Connect(callbacks.Close)
    self.Panel=T.plate(self.Modal,'Panel',UDim2.fromOffset(760,590),UDim2.new()); self.Panel.ZIndex=2; self.Panel.Active=true
    self.PanelIcon=T.icon(self.Panel,'Collection',UDim2.fromOffset(62,62),UDim2.fromOffset(14,7))
    self.Title=T.label(self.Panel,'Collection',UDim2.new(1,-146,0,39),UDim2.fromOffset(80,11),30)
    self.Subtitle=T.body(self.Panel,'',UDim2.new(1,-110,0,23),UDim2.fromOffset(82,46),14)
    self.Close=T.button(self.Panel,'X',UDim2.fromOffset(44,44),UDim2.new(1,-58,0,14),callbacks.Close,C.Orange)
    self.Close.Name='Close'
    self.List=T.make('ScrollingFrame',self.Panel,{Name='Content',Size=UDim2.new(1,-30,1,-90),Position=UDim2.fromOffset(15,78),
        BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=5,ScrollBarImageColor3=C.Purple})
    T.make('UIPadding',self.List,{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,12),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,10)})
    self.Toast=T.plate(root,'Toast',UDim2.fromOffset(500,78),UDim2.new(),C.Mint)
    self.Toast.ZIndex=40; self.Toast.Visible=false
    self.ToastText=T.label(self.Toast,'',UDim2.new(1,-28,1,-18),UDim2.fromOffset(14,9),20)
    self.ToastText.TextXAlignment=Enum.TextXAlignment.Center
    self.Capture=T.plate(root,'Capture',UDim2.fromOffset(410,82),UDim2.new(),C.Mint); self.Capture.Visible=false
    self.CaptureText=T.label(self.Capture,'',UDim2.new(1,-20,0,42),UDim2.fromOffset(10,6),17,C.Mint)
    self.CaptureText.TextXAlignment=Enum.TextXAlignment.Center
    local captureTrack=T.frame(self.Capture,UDim2.new(1,-24,0,18),UDim2.fromOffset(12,53),C.Outline)
    self.CaptureBar=T.frame(captureTrack,UDim2.fromScale(0,1),UDim2.new(),C.Mint)
    self.Scales={}
    for _,name in {'Nav','Wallet','Quest','Dock','Actions'} do self.Scales[name]=T.make('UIScale',self[name],{Scale=1}) end
    self.Root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function() self:resize() end)
    UserInputService.LastInputTypeChanged:Connect(function() self:inputHints() end)
    self:inputHints(); self:resize()
    return self
end
function HUD:inputHints()
    local input=UserInputService:GetLastInputType()
    local pad=tostring(input):find('Gamepad')~=nil
    local touch=input==Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
    self.LightHint.Text=if touch then 'TAP' elseif pad then 'X' else 'F'
    self.VacuumHint.Text=if touch then 'TAP' elseif pad then 'RT' else 'CLICK'
end
function HUD:resize()
    local size=self.Root.AbsoluteSize
    if size.X<1 or size.Y<1 then return end
    local spec=layout(size.X,size.Y,UserInputService.TouchEnabled)
    self.Layout=spec
    for _,name in {'Nav','Wallet','Quest','Dock','Actions','Panel','Capture'} do
        local r=spec[name]; local obj=self[name]
        obj.Position=UDim2.fromOffset(r.X,r.Y); obj.Size=UDim2.fromOffset(r.W,r.H)
        if self.Scales[name] then self.Scales[name].Scale=r.Scale end
    end
    for i,name in {'Haunt','Mansion','Upgrades','Rebirth'} do
        self.Buttons[name].Position=UDim2.fromOffset(((i-1)%spec.Columns)*118,math.floor((i-1)/spec.Columns)*spec.NavStep)
        self.Buttons[name].Size=UDim2.fromOffset(110,spec.NavHeight)
    end
    self.Buttons.Collection.Size=UDim2.fromOffset(if spec.Portrait then 132 else 150,110)
    self.Bag.Position=if spec.Portrait then UDim2.fromOffset(3,124) else UDim2.fromOffset(162,46)
    self.Vacuum.Position=if spec.Portrait then UDim2.fromOffset(0,spec.ActionStep) else UDim2.fromOffset(118,0)
    self.Light.Size=UDim2.fromOffset(106,spec.ActionHeight); self.Vacuum.Size=self.Light.Size
    self.Practice.Position=UDim2.fromOffset(size.X-126,spec.Wallet.Y+spec.Wallet.H*spec.Wallet.Scale+6)
    self.Practice.Visible=spec.Wide
    self.Toast.Size=UDim2.fromOffset(math.min(500,size.X-32),78)
    self.Toast.Position=UDim2.fromOffset((size.X-self.Toast.Size.X.Offset)/2,math.min(size.Y-100,spec.Quest.Y+spec.Quest.H*spec.Quest.Scale+14))
    local grid=self.List:FindFirstChildOfClass('UIGridLayout')
    if grid then
        local columns=if self.Panel.Size.X.Offset<500 then 2 else 3
        grid.CellSize=UDim2.new(1/columns,-14,0,202)
    end
end
function HUD:setPanel(name,subtitle)
    self.Modal.Visible=name~=nil
    self.Nav.Visible=name==nil; self.Dock.Visible=name==nil; self.Quest.Visible=name==nil; self.Wallet.Visible=name==nil
    for key,b in self.Buttons do b:FindFirstChildOfClass('UIStroke').Color=if key==name then C.Mint else C.Orange end
    if name then
        self.Title.Text=if name=='Haunt' then 'Your Haunt' else name
        self.Subtitle.Text=subtitle or ''
        self.PanelIcon:Destroy(); self.PanelIcon=T.icon(self.Panel,name,UDim2.fromOffset(62,62),UDim2.fromOffset(14,7))
        if UserInputService.GamepadEnabled then GuiService.SelectedObject=self.Close end
    elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.Modal) then
        GuiService.SelectedObject=self.Buttons.Collection
    end
end
function HUD:setQuest(title,text,progress,caption)
    self.QuestTitle.Text=title; self.Objective.Text=text
    self.QuestBar.Size=UDim2.fromScale(math.clamp(progress,0,1),1)
    self.QuestProgress.Text=caption
end
function HUD:setCapacity(count,max)
    self.Capacity.Text=count..' / '..max
    self.Capacity.TextColor3=if count>=max then C.Orange else C.Ink
    self.CapacityHint.Text=if count>=max then 'FULL' else 'VACUUM'
end
return HUD

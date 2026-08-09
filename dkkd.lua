--[[
    Merged UI Library (White Google Material + River Floating Button)
    Controls: RightCtrl to toggle UI visibility
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local MergedUI = {}
MergedUI.__index = MergedUI
MergedUI.Flags = {}

-- Google UI Light Theme Palette
local Theme = {
    Background = Color3.fromRGB(248, 250, 252),
    Topbar = Color3.fromRGB(255, 255, 255),
    Sidebar = Color3.fromRGB(255, 255, 255),
    Card = Color3.fromRGB(255, 255, 255),
    CardAlt = Color3.fromRGB(245, 247, 251),
    Border = Color3.fromRGB(226, 232, 240),
    Text = Color3.fromRGB(31, 41, 55),
    Muted = Color3.fromRGB(100, 116, 139),
    Primary = Color3.fromRGB(26, 115, 232),
    PrimaryHover = Color3.fromRGB(24, 102, 204),
    PrimarySoft = Color3.fromRGB(232, 240, 254),
    Success = Color3.fromRGB(52, 168, 83),
    Warning = Color3.fromRGB(251, 188, 4),
    Danger = Color3.fromRGB(234, 67, 53),
    Hover = Color3.fromRGB(241, 245, 249)
}

local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function corner(parent, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or 6), Parent = parent})
end

local function stroke(parent, color, thickness, transparency)
    create("UIStroke", {Color = color or Theme.Border, Thickness = thickness or 1, Transparency = transparency or 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent})
end

local function pad(parent, top, bottom, left, right)
    create("UIPadding", {PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or 0), PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or 0), Parent = parent})
end

local function tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- Notifications (Google Style Cards)
local NotificationContainer
local function initNotifications()
    if NotificationContainer then return end
    NotificationContainer = create("Frame", {
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundTransparency = 1,
        Parent = CoreGui
    })
    create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotificationContainer})
end

function MergedUI:Notify(title, text, duration)
    initNotifications()
    duration = duration or 5
    local notif = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Card,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = NotificationContainer
    })
    corner(notif, 8)
    stroke(notif, Theme.Border, 1, 0.5)

    local accentBar = create("Frame", {Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Theme.Primary, BorderSizePixel = 0, Parent = notif})
    corner(accentBar, 2)

    local titleLbl = create("TextLabel", {Text = title, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(16, 10), TextXAlignment = Enum.TextXAlignment.Left, Parent = notif})
    local bodyLbl = create("TextLabel", {Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Muted, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 0), Position = UDim2.fromOffset(16, 30), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Parent = notif})

    task.spawn(function()
        task.wait(0.1)
        local h = titleLbl.TextBounds.Y + bodyLbl.TextBounds.Y + 20
        notif.Size = UDim2.new(1, 0, 0, h)
        notif.Position = UDim2.new(1, 0, 0, 0)
        tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.5)
        
        task.wait(duration)
        tween(notif, {Position = UDim2.new(1, 0, 0, 0)}, 0.5)
        task.wait(0.5)
        notif:Destroy()
    end)
end

function MergedUI:CreateWindow(config)
    config = config or {}
    local gui = create("ScreenGui", {Name = "MergedWhiteUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = gethui and gethui() or CoreGui})

    local main = create("Frame", {Size = config.Size or UDim2.fromOffset(600, 400), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = gui})
    corner(main, 10)
    stroke(main, Theme.Border, 1, 0.5)

    local topbar = create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, Parent = main})
    corner(topbar, 10)
    create("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0, Parent = topbar})
    create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = topbar})

    local title = create("TextLabel", {Text = config.Title or "White UI", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, BackgroundTransparency = 1, Position = UDim2.fromOffset(15, 0), Size = UDim2.new(1, -100, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = topbar})

    -- Google Style 3 Dots (Red, Yellow, Green)
    local dotsContainer = create("Frame", {Size = UDim2.fromOffset(60, 20), Position = UDim2.new(1, -70, 0.5, -10), BackgroundTransparency = 1, Parent = topbar})
    create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = dotsContainer})

    local redDot = create("TextButton", {Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Danger, Text = "", AutoButtonColor = false, Parent = dotsContainer})
    local yellowDot = create("TextButton", {Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Warning, Text = "", AutoButtonColor = false, Parent = dotsContainer})
    local greenDot = create("TextButton", {Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Success, Text = "", AutoButtonColor = false, Parent = dotsContainer})
    corner(redDot, 6); corner(yellowDot, 6); corner(greenDot, 6)

    -- River UI Open Button
    local openBtn = create("TextButton", {Text = "Open UI", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Text, Size = UDim2.fromOffset(80, 30), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Theme.Card, Visible = false, Parent = gui})
    corner(openBtn, 8)
    stroke(openBtn, Theme.Primary, 1.5, 0.2)

    -- Dot Logic
    yellowDot.MouseButton1Click:Connect(function()
        -- Minimize to Topbar
        tween(main, {Size = UDim2.fromOffset(300, 40)}, 0.3)
    end)
    greenDot.MouseButton1Click:Connect(function()
        -- Restore Size
        tween(main, {Size = config.Size or UDim2.fromOffset(600, 400)}, 0.3)
    end)
    redDot.MouseButton1Click:Connect(function()
        -- Hide UI
        main.Visible = false
        openBtn.Visible = true
    end)
    openBtn.MouseButton1Click:Connect(function()
        main.Visible = true
        openBtn.Visible = false
        tween(main, {Size = config.Size or UDim2.fromOffset(600, 400)}, 0.3)
    end)

    -- Toggle on RightControl
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            main.Visible = not main.Visible
            openBtn.Visible = not main.Visible
        end
    end)

    -- Dragging Logic
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Google UI Sidebar & Tabs
    local sidebar = create("Frame", {Size = UDim2.new(0, 140, 1, -40), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = main})
    create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = sidebar})
    
    local tabList = create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = sidebar})
    pad(tabList, 10, 10, 10, 10)
    local tabLayout = create("UIListLayout", {Padding = UDim.new(0, 8), Parent = tabList})
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabList.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
    end)

    local content = create("Frame", {Size = UDim2.new(1, -140, 1, -40), Position = UDim2.fromOffset(140, 40), BackgroundTransparency = 1, Parent = main})

    local windowObj = setmetatable({Gui = gui, Tabs = {}, ActiveTab = nil}, MergedUI)
    
    function windowObj:CreateTab(name)
        local btn = create("TextButton", {Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Card, BackgroundTransparency = 1, AutoButtonColor = false, Parent = tabList})
        corner(btn, 8)
        local accentBar = create("Frame", {Size = UDim2.new(0, 3, 0, 16), Position = UDim2.fromOffset(0, 9), BackgroundColor3 = Theme.Primary, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = btn})
        corner(accentBar, 3)
        local lbl = create("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Muted, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})

        local page = create("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = content})
        pad(page, 15, 15, 15, 15)
        local pageLayout = create("UIListLayout", {Padding = UDim.new(0, 12), Parent = page})
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 30)
        end)

        local tabObj = {Button = btn, Page = page}
        table.insert(self.Tabs, tabObj)

        btn.MouseButton1Click:Connect(function()
            if self.ActiveTab then
                self.ActiveTab.Page.Visible = false
                tween(self.ActiveTab.Button, {BackgroundTransparency = 1})
                self.ActiveTab.Button.TextLabel.TextColor3 = Theme.Muted
                self.ActiveTab.Button.Frame.BackgroundTransparency = 1
            end
            self.ActiveTab = tabObj
            page.Visible = true
            tween(btn, {BackgroundTransparency = 0})
            lbl.TextColor3 = Theme.Primary
            accentBar.BackgroundTransparency = 0
        end)

        if not self.ActiveTab then 
            self.ActiveTab = tabObj; page.Visible = true
            tween(btn, {BackgroundTransparency = 0}); lbl.TextColor3 = Theme.Primary; accentBar.BackgroundTransparency = 0
        end

        function tabObj:CreateSection(title)
            local sec = create("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Card, AutomaticSize = Enum.AutomaticSize.Y, Parent = page})
            corner(sec, 8)
            stroke(sec, Theme.Border, 1, 0.5)
            local secLayout = create("UIListLayout", {Padding = UDim.new(0, 10), Parent = sec})
            pad(sec, 12, 12, 12, 12)
            create("TextLabel", {Text = title or "Section", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = sec})
            
            local sectionObj = {Instance = sec}

            function sectionObj:CreateButton(cfg)
                local btnCtrl = create("TextButton", {Text = cfg.Title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = cfg.Style == "Danger" and Theme.Danger or Theme.Text, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.CardAlt, BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = #sec:GetChildren(), Parent = sec})
                corner(btnCtrl, 6)
                stroke(btnCtrl, cfg.Style == "Danger" and Theme.Danger or Theme.Border, 1, 0.5)
                btnCtrl.MouseEnter:Connect(function() tween(btnCtrl, {BackgroundColor3 = Theme.Hover}) end)
                btnCtrl.MouseLeave:Connect(function() tween(btnCtrl, {BackgroundColor3 = Theme.CardAlt}) end)
                btnCtrl.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback() end end)
                return btnCtrl
            end

            function sectionObj:CreateToggle(cfg)
                local state = cfg.Default or false
                local togCtrl = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = #sec:GetChildren(), Parent = sec})
                create("TextLabel", {Text = cfg.Title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = togCtrl})
                local sw = create("TextButton", {Size = UDim2.fromOffset(44, 24), Position = UDim2.new(1, -44, 0.5, -12), BackgroundColor3 = state and Theme.Primary or Theme.Border, BorderSizePixel = 0, AutoButtonColor = false, Parent = togCtrl})
                corner(sw, 12)
                local knob = create("Frame", {Size = UDim2.fromOffset(20, 20), Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.fromOffset(2, 2), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Parent = sw})
                corner(knob, 10)
                stroke(knob, Theme.Border, 1, 0.5)

                if cfg.Flag then MergedUI.Flags[cfg.Flag] = state end
                sw.MouseButton1Click:Connect(function()
                    state = not state
                    if cfg.Flag then MergedUI.Flags[cfg.Flag] = state end
                    tween(sw, {BackgroundColor3 = state and Theme.Primary or Theme.Border})
                    tween(knob, {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.fromOffset(2, 2)})
                    if cfg.Callback then cfg.Callback(state) end
                end)
                return togCtrl
            end

            function sectionObj:CreateSlider(cfg)
                local val = cfg.Default or cfg.Min or 0
                local sldCtrl = create("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = #sec:GetChildren(), Parent = sec})
                create("TextLabel", {Text = cfg.Title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Parent = sldCtrl})
                local valLbl = create("TextLabel", {Text = tostring(val), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Primary, BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0, 0), Parent = sldCtrl})
                
                local track = create("TextButton", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 28), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, AutoButtonColor = false, Parent = sldCtrl})
                corner(track, 3)
                local fill = create("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Primary, BorderSizePixel = 0, Parent = track})
                corner(fill, 3)
                local knob = create("Frame", {Size = UDim2.fromOffset(16, 16), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Parent = track})
                corner(knob, 8)
                stroke(knob, Theme.Primary, 1, 0)

                local dragging = false
                local function update(input)
                    local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    val = math.floor(cfg.Min + (cfg.Max - cfg.Min) * pct)
                    valLbl.Text = tostring(val)
                    if cfg.Flag then MergedUI.Flags[cfg.Flag] = val end
                    fill.Size = UDim2.fromScale(pct, 1)
                    knob.Position = UDim2.fromScale(pct, 0.5)
                    if cfg.Callback then cfg.Callback(val) end
                end
                track.MouseButton1Down:Connect(function(input) dragging = true; update(input) end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end end)
                return sldCtrl
            end

            function sectionObj:CreateDropdown(cfg)
                local ddCtrl = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = #sec:GetChildren(), Parent = sec})
                local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.CardAlt, BorderSizePixel = 0, AutoButtonColor = false, Parent = ddCtrl})
                corner(btn, 6)
                stroke(btn, Theme.Border, 1, 0.5)
                create("TextLabel", {Text = cfg.Title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Muted, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
                local valLbl = create("TextLabel", {Text = cfg.Default or "Select", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Primary, BackgroundTransparency = 1, Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -110, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = btn})
                
                local list = create("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 40), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Visible = false, ZIndex = 10, Parent = ddCtrl})
                corner(list, 8)
                stroke(list, Theme.Border, 1, 0.5)
                local listLayout = create("UIListLayout", {Padding = UDim.new(0, 4), Parent = list})
                pad(list, 4, 4, 4, 4)

                local open = false
                btn.MouseButton1Click:Connect(function()
                    open = not open
                    list.Visible = open
                    local h = open and listLayout.AbsoluteContentSize.Y + 8 or 0
                    tween(ddCtrl, {Size = UDim2.new(1, 0, 0, 34 + h)})
                    tween(list, {Size = UDim2.new(1, 0, 0, h)})
                end)

                for _, opt in ipairs(cfg.Options) do
                    local optBtn = create("TextButton", {Text = opt, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.Text, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, AutoButtonColor = false, Parent = list})
                    corner(optBtn, 6)
                    optBtn.MouseEnter:Connect(function() tween(optBtn, {BackgroundColor3 = Theme.Hover}) end)
                    optBtn.MouseLeave:Connect(function() tween(optBtn, {BackgroundColor3 = Theme.Card}) end)
                    optBtn.MouseButton1Click:Connect(function()
                        valLbl.Text = opt
                        if cfg.Flag then MergedUI.Flags[cfg.Flag] = opt end
                        if cfg.Callback then cfg.Callback(opt) end
                        open = false
                        list.Visible = false
                        tween(ddCtrl, {Size = UDim2.new(1, 0, 0, 34)})
                    end)
                end
                return ddCtrl
            end

            function sectionObj:CreateTextbox(cfg)
                local tbCtrl = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = #sec:GetChildren(), Parent = sec})
                local box = create("TextBox", {Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "Enter text...", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.CardAlt, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, Parent = tbCtrl})
                corner(box, 6)
                stroke(box, Theme.Border, 1, 0.5)
                pad(box, 0, 0, 12, 12)
                
                box.FocusLost:Connect(function()
                    if cfg.Flag then MergedUI.Flags[cfg.Flag] = box.Text end
                    if cfg.Callback then cfg.Callback(box.Text) end
                end)
                return tbCtrl
            end

            function sectionObj:CreateKeybind(cfg)
                local kbCtrl = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = #sec:GetChildren(), Parent = sec})
                create("TextLabel", {Text = cfg.Title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = kbCtrl})
                local btn = create("TextButton", {Text = cfg.Default and cfg.Default.Name or "None", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Primary, Size = UDim2.fromOffset(70, 28), Position = UDim2.new(1, -70, 0.5, -14), BackgroundColor3 = Theme.CardAlt, BorderSizePixel = 0, AutoButtonColor = false, Parent = kbCtrl})
                corner(btn, 6)
                stroke(btn, Theme.Border, 1, 0.5)
                
                local listening = false
                local currentKey = cfg.Default
                btn.MouseButton1Click:Connect(function() listening = true; btn.Text = "..." end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        currentKey = input.KeyCode
                        btn.Text = currentKey.Name
                        if cfg.Flag then MergedUI.Flags[cfg.Flag] = currentKey.Name end
                    elseif currentKey and input.KeyCode == currentKey then
                        if cfg.Callback then cfg.Callback() end
                    end
                end)
                return kbCtrl
            end

            return sectionObj
        end

        return tabObj
    end

    return windowObj
end

-- Config System (JSON based)
function MergedUI:SaveConfig(name)
    if not isfolder("MergedUI") then makefolder("MergedUI") end
    writefile("MergedUI/" .. name .. ".json", HttpService:JSONEncode(self.Flags))
    self:Notify("Config Saved", name .. ".json has been saved successfully.")
end

function MergedUI:LoadConfig(name)
    if isfile("MergedUI/" .. name .. ".json") then
        local data = HttpService:JSONDecode(readfile("MergedUI/" .. name .. ".json"))
        for k, v in pairs(data) do self.Flags[k] = v end
        self:Notify("Config Loaded", name .. ".json has been loaded.")
    end
end

return MergedUI

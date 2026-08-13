--[[
    StreamUI Library
    Re-engineered for maximum operational control.
    - Squared geometry (CornerRadius 4)
    - Solid workarea (less transparent)
    - Buttery smooth drag interpolation
    - Dynamic keybind rebinding
    - Live theme switching, scaling, and transparency manipulation
    - Tab asset integration
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StreamUI = {}

local Themes = {
    Midnight = {
        Background = Color3.fromRGB(20, 20, 23),
        Sidebar = Color3.fromRGB(25, 25, 28),
        Workarea = Color3.fromRGB(30, 30, 34),
        Text = Color3.fromRGB(240, 240, 242),
        SubText = Color3.fromRGB(160, 160, 168),
        Accent = Color3.fromRGB(0, 116, 224),
        Element = Color3.fromRGB(35, 35, 40),
        Border = Color3.fromRGB(45, 45, 50)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 242),
        Sidebar = Color3.fromRGB(230, 230, 232),
        Workarea = Color3.fromRGB(245, 245, 248),
        Text = Color3.fromRGB(20, 20, 23),
        SubText = Color3.fromRGB(100, 100, 108),
        Accent = Color3.fromRGB(0, 116, 224),
        Element = Color3.fromRGB(220, 220, 225),
        Border = Color3.fromRGB(200, 200, 205)
    },
    Ocean = {
        Background = Color3.fromRGB(15, 25, 35),
        Sidebar = Color3.fromRGB(20, 30, 45),
        Workarea = Color3.fromRGB(25, 40, 55),
        Text = Color3.fromRGB(200, 230, 255),
        SubText = Color3.fromRGB(100, 150, 180),
        Accent = Color3.fromRGB(0, 150, 200),
        Element = Color3.fromRGB(30, 50, 70),
        Border = Color3.fromRGB(40, 60, 80)
    }
}

local CurrentTheme = Themes.Midnight
local Registry = {}
local Connections = {}

local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function applyTheme(inst, prop, role)
    Registry[#Registry + 1] = {inst = inst, prop = prop, role = role}
    inst[prop] = CurrentTheme[role]
end

local function RefreshTheme()
    for _, entry in ipairs(Registry) do
        if entry.inst and entry.inst.Parent then
            entry.inst[entry.prop] = CurrentTheme[entry.role]
        end
    end
end

local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    Connections[#Connections + 1] = conn
    return conn
end

function StreamUI:CreateWindow(title)
    local existing = PlayerGui:FindFirstChild("StreamUI")
    if existing then existing:Destroy() end

    local scrgui = new("ScreenGui", {
        Name = "StreamUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui,
    })

    local scale = new("UIScale", {
        Scale = 1,
        Parent = scrgui,
    })

    local main = new("Frame", {
        Name = "main",
        Size = UDim2.new(0, 680, 0, 480),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = scrgui,
    })
    applyTheme(main, "BackgroundColor3", "Background")
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = main
    local stroke = new("UIStroke", { Thickness = 1, Parent = main })
    applyTheme(stroke, "Color", "Border")

    -- Smooth Drag Logic
    local dragging = false
    local dragInput, dragStart, startPos
    local targetPos = main.Position

    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    Connect(RunService.RenderStepped, function()
        main.Position = main.Position:Lerp(targetPos, 0.2)
    end)

    -- Top Bar
    local topBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CurrentTheme.Sidebar,
        BorderSizePixel = 0,
        Parent = main,
    })
    applyTheme(topBar, "BackgroundColor3", "Sidebar")
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = topBar
    local topBarBlend = new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = CurrentTheme.Sidebar,
        BorderSizePixel = 0,
        Parent = topBar,
    })
    applyTheme(topBarBlend, "BackgroundColor3", "Sidebar")

    local titleLbl = new("TextLabel", {
        Size = UDim2.new(0, 400, 1, 0),
        Position = UDim2.new(0, 120, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "StreamUI",
        Font = Enum.Font.GothamBold,
        TextColor3 = CurrentTheme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })
    applyTheme(titleLbl, "TextColor3", "Text")

    -- Mac Buttons
    local btnContainer = new("Frame", {
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Parent = topBar,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = btnContainer,
    })

    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        Text = "",
        AutoButtonColor = false,
        Parent = btnContainer,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = closeBtn

    -- Sidebar
    local sidebar = new("ScrollingFrame", {
        Size = UDim2.new(0, 200, 1, -50),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = main,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar,
    })

    local searchBox = new("TextBox", {
        Size = UDim2.new(1, -10, 0, 32),
        BackgroundColor3 = CurrentTheme.Element,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = CurrentTheme.SubText,
        Font = Enum.Font.GothamMedium,
        TextColor3 = CurrentTheme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = sidebar,
    })
    applyTheme(searchBox, "BackgroundColor3", "Element")
    applyTheme(searchBox, "TextColor3", "Text")
    applyTheme(searchBox, "PlaceholderColor3", "SubText")
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = searchBox
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = searchBox })

    -- Workarea (Right side, less transparent)
    local workarea = new("Frame", {
        Size = UDim2.new(1, -230, 1, -60),
        Position = UDim2.new(0, 220, 0, 50),
        BackgroundColor3 = CurrentTheme.Workarea,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Parent = main,
    })
    applyTheme(workarea, "BackgroundColor3", "Workarea")
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = workarea

    local sections = {}
    local pages = {}

    local function selectSection(idx)
        for i, btn in ipairs(sections) do
            btn.BackgroundTransparency = 1
            btn.TextColor3 = CurrentTheme.SubText
            if btn.Icon then btn.Icon.ImageColor3 = CurrentTheme.SubText end
        end
        for i, pg in ipairs(pages) do
            pg.Visible = (i == idx)
        end
        if sections[idx] then
            sections[idx].BackgroundTransparency = 0
            sections[idx].TextColor3 = CurrentTheme.Text
            if sections[idx].Icon then sections[idx].Icon.ImageColor3 = CurrentTheme.Text end
        end
    end

    Connect(RunService.RenderStepped, function()
        if not searchBox:IsFocused() then
            for _, btn in ipairs(sections) do
                if btn:IsA("TextButton") then btn.Visible = true end
            end
        end
        local txt = string.upper(searchBox.Text)
        for _, btn in ipairs(sections) do
            if btn:IsA("TextButton") then
                if txt == "" or string.find(string.upper(btn.Name), txt) then
                    btn.Visible = true
                else
                    btn.Visible = false
                end
            end
        end
    end)

    local Window = {}

    function Window:CreateTab(name, iconId)
        local sidebarBtn = new("TextButton", {
            Name = name,
            Size = UDim2.new(1, -10, 0, 36),
            BackgroundColor3 = CurrentTheme.Element,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = sidebar,
        })
        applyTheme(sidebarBtn, "BackgroundColor3", "Element")
        new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = sidebarBtn

        local btnLayout = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = sidebarBtn,
        })
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = btnLayout,
        })
        new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = btnLayout })

        local icon
        if iconId then
            icon = new("ImageLabel", {
                Size = UDim2.fromOffset(18, 18),
                BackgroundTransparency = 1,
                Image = "rbxassetid://" .. iconId,
                ImageColor3 = CurrentTheme.SubText,
                Parent = btnLayout,
            })
            applyTheme(icon, "ImageColor3", "SubText")
        end

        local label = new("TextLabel", {
            Size = UDim2.new(1, -30, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextColor3 = CurrentTheme.SubText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btnLayout,
        })
        applyTheme(label, "TextColor3", "SubText")
        
        sidebarBtn.Name = name
        sidebarBtn.Text = name 
        sidebarBtn.Icon = icon
        sidebarBtn.Label = label

        local page = new("ScrollingFrame", {
            Name = name .. "_page",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = workarea,
        })
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })

        local idx = #sections + 1
        sidebarBtn.MouseButton1Click:Connect(function()
            selectSection(idx)
        end)
        
        table.insert(sections, sidebarBtn)
        table.insert(pages, page)

        if idx == 1 then selectSection(1) end

        local Tab = {}

        local function baseRow(height)
            local row = new("Frame", {
                Size = UDim2.new(1, -10, 0, height),
                BackgroundColor3 = CurrentTheme.Element,
                BackgroundTransparency = 0.5,
                Parent = page,
            })
            applyTheme(row, "BackgroundColor3", "Element")
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = row
            return row
        end

        function Tab:Button(name, callback)
            local row = baseRow(38)
            local btn = new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamBold,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                Parent = row,
            })
            applyTheme(btn, "TextColor3", "Text")
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        function Tab:Toggle(name, default, callback)
            local state = default
            local row = baseRow(38)
            
            local label = new("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            applyTheme(label, "TextColor3", "Text")
            new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = label })

            local switchBg = new("TextButton", {
                Size = UDim2.fromOffset(44, 22),
                Position = UDim2.new(1, -56, 0.5, -11),
                BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Border,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })
            applyTheme(switchBg, "BackgroundColor3", state and "Accent" or "Border")
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = switchBg

            local knob = new("Frame", {
                Size = UDim2.fromOffset(16, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = switchBg,
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = knob

            switchBg.MouseButton1Click:Connect(function()
                state = not state
                if state then
                    TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(1, -19, 0.5, -8)}):Play()
                else
                    TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 3, 0.5, -8)}):Play()
                end
                TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Border}):Play()
                if callback then callback(state) end
            end)
        end

        function Tab:Slider(name, min, max, default, callback)
            local value = default
            local row = baseRow(44)
            
            local label = new("TextLabel", {
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.new(0, 12, 0, 6),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            applyTheme(label, "TextColor3", "Text")

            local valLbl = new("TextLabel", {
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -60, 0, 6),
                BackgroundTransparency = 1,
                Text = tostring(value),
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.SubText,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })
            applyTheme(valLbl, "TextColor3", "SubText")

            local track = new("Frame", {
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 0, 30),
                BackgroundColor3 = CurrentTheme.Border,
                Parent = row,
            })
            applyTheme(track, "BackgroundColor3", "Border")
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = track

            local fill = new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = CurrentTheme.Accent,
                Parent = track,
            })
            applyTheme(fill, "BackgroundColor3", "Accent")
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = fill

            local dragging = false
            local function setVal(x)
                local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel)
                fill.Size = UDim2.new(rel, 0, 1, 0)
                valLbl.Text = tostring(value)
                if callback then callback(value) end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setVal(input.Position.X)
                end
            end)
            Connect(UserInputService.InputChanged, function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setVal(input.Position.X)
                end
            end)
            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
        end

        function Tab:Dropdown(name, options, default, callback)
            local selected = default
            local row = baseRow(38)
            
            local label = new("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            applyTheme(label, "TextColor3", "Text")
            new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = label })

            local btn = new("TextButton", {
                Size = UDim2.new(0.5, -12, 0, 24),
                Position = UDim2.new(0.5, 0, 0.5, -12),
                BackgroundColor3 = CurrentTheme.Border,
                Text = selected or "Select...",
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.SubText,
                TextSize = 13,
                Parent = row,
            })
            applyTheme(btn, "BackgroundColor3", "Border")
            applyTheme(btn, "TextColor3", "SubText")
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = btn

            local list = new("Frame", {
                Size = UDim2.new(0.5, -12, 0, #options * 28),
                Position = UDim2.new(0.5, 0, 1, 4),
                BackgroundColor3 = CurrentTheme.Background,
                Visible = false,
                ZIndex = 10,
                Parent = row,
            })
            applyTheme(list, "BackgroundColor3", "Background")
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = list
            new("UIListLayout", { Padding = UDim.new(0, 4), Parent = list })

            for _, opt in ipairs(options) do
                local optBtn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = CurrentTheme.Text,
                    TextSize = 13,
                    Parent = list,
                })
                applyTheme(optBtn, "TextColor3", "Text")
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    btn.Text = opt
                    list.Visible = false
                    if callback then callback(opt) end
                end)
            end

            btn.MouseButton1Click:Connect(function()
                list.Visible = not list.Visible
            end)
        end

        function Tab:Keybind(name, defaultKey, callback)
            local currentKey = defaultKey
            local listening = false
            local row = baseRow(38)

            local label = new("TextLabel", {
                Size = UDim2.new(1, -80, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            applyTheme(label, "TextColor3", "Text")
            new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = label })

            local keyBtn = new("TextButton", {
                Size = UDim2.fromOffset(60, 24),
                Position = UDim2.new(1, -72, 0.5, -12),
                BackgroundColor3 = CurrentTheme.Border,
                Text = currentKey.Name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.SubText,
                TextSize = 13,
                Parent = row,
            })
            applyTheme(keyBtn, "BackgroundColor3", "Border")
            applyTheme(keyBtn, "TextColor3", "SubText")
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = keyBtn

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
            end)

            Connect(UserInputService.InputBegan, function(input, gpe)
                if gpe then return end
                if listening then
                    if input.KeyCode ~= Enum.KeyCode.Unknown then
                        currentKey = input.KeyCode
                        keyBtn.Text = currentKey.Name
                        listening = false
                    end
                else
                    if input.KeyCode == currentKey then
                        if callback then callback() end
                    end
                end
            end)
        end

        function Tab:Label(text)
            local row = baseRow(28)
            local lbl = new("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.GothamMedium,
                TextColor3 = CurrentTheme.SubText,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
            applyTheme(lbl, "TextColor3", "SubText")
            new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = lbl })
        end

        return Tab
    end

    -- Built-in Settings Tab
    local SettingsTab = Window:CreateTab("Settings", "122669828593160")
    
    SettingsTab:Label("Appearance")
    
    SettingsTab:Dropdown("Theme", {"Midnight", "Light", "Ocean"}, "Midnight", function(val)
        CurrentTheme = Themes[val]
        RefreshTheme()
    end)
    
    SettingsTab:Slider("UI Scale", 50, 150, 100, function(val)
        scale.Scale = val / 100
    end)
    
    SettingsTab:Slider("Background Transparency", 0, 100, 10, function(val)
        main.BackgroundTransparency = val / 100
    end)
    
    SettingsTab:Slider("Workarea Transparency", 0, 100, 5, function(val)
        workarea.BackgroundTransparency = val / 100
    end)

    SettingsTab:Label("Keybinds")
    SettingsTab:Keybind("Toggle UI", Enum.KeyCode.RightControl, function()
        toggleVisible()
    end)

    SettingsTab:Label("System")
    SettingsTab:Button("Unload UI", function()
        for _, conn in ipairs(Connections) do
            conn:Disconnect()
        end
        scrgui:Destroy()
    end)

    -- Visibility Toggle
    local visible = true
    local animating = false
    function toggleVisible()
        if animating then return end
        visible = not visible
        animating = true
        if visible then
            targetPos = UDim2.new(0.5, 0, 0.5, 0)
        else
            targetPos = UDim2.new(0.5, 0, 1.5, 0)
        end
        task.delay(0.5, function()
            animating = false
        end)
    end

    Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            toggleVisible()
        end
    end)

    return Window
end

return StreamUI

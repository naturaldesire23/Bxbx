--[[
    StreamUI Library
    Tuned for sharp geometry, transparency, and Right-Control toggling.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local StreamUI = {}

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

local function tp(ins, pos, time)
    TweenService:Create(ins, TweenInfo.new(time or 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos}):Play()
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

    local main = new("Frame", {
        Name = "main",
        Size = UDim2.new(0, 721, 0, 584),
        Position = UDim2.new(0.5, 0, 1.5, 0), 
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 24, 27),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = scrgui,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = main
    new("UIStroke", { Color = Color3.fromRGB(45, 45, 45), Thickness = 1, Transparency = 0.5 }).Parent = main
    
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local buttonsFrame = new("Frame", {
        Name = "buttons",
        Size = UDim2.new(0, 80, 0, 40),
        Position = UDim2.new(0, 15, 0, 10),
        BackgroundTransparency = 1,
        Parent = main,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = buttonsFrame

    local closeBtn = new("TextButton", {
        Name = "close",
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        Text = "",
        AutoButtonColor = false,
        Parent = buttonsFrame,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = closeBtn

    local minimizeBtn = new("TextButton", {
        Name = "minimize",
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        Text = "",
        AutoButtonColor = false,
        Parent = buttonsFrame,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = minimizeBtn

    local resizeBtn = new("TextButton", {
        Name = "resize",
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(39, 200, 63),
        Text = "",
        AutoButtonColor = false,
        Parent = buttonsFrame,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = resizeBtn

    closeBtn.MouseButton1Click:Connect(function()
        tp(main, main.Position + UDim2.new(0, 0, 2, 0), 0.6)
        task.delay(0.6, function() scrgui:Destroy() end)
    end)

    local visible = true
    local isAnimating = false
    local function toggleVisible()
        if isAnimating then return end
        visible = not visible
        isAnimating = true
        if visible then
            tp(main, UDim2.new(0.5, 0, 0.5, 0), 0.6)
        else
            tp(main, main.Position + UDim2.new(0, 0, 2, 0), 0.6)
        end
        task.delay(0.6, function() isAnimating = false end)
    end
    
    minimizeBtn.MouseButton1Click:Connect(toggleVisible)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            toggleVisible()
        end
    end)

    new("TextLabel", {
        Name = "title",
        Size = UDim2.new(0, 400, 0, 30),
        Position = UDim2.new(0, 120, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = title or "StreamUI",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = main,
    })

    local sidebar = new("ScrollingFrame", {
        Name = "sidebar",
        Size = UDim2.new(0, 230, 1, -80),
        Position = UDim2.new(0, 15, 0, 70),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = main,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = sidebar

    local searchBar = new("Frame", {
        Name = "search",
        Size = UDim2.new(1, -10, 0, 36),
        BackgroundColor3 = Color3.fromRGB(34, 34, 38),
        BackgroundTransparency = 0.2,
        Parent = sidebar,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = searchBar

    new("ImageLabel", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(0, 10, 0.5, -9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://2804603863",
        ImageColor3 = Color3.fromRGB(120, 120, 120),
        Parent = searchBar,
    })

    local searchBox = new("TextBox", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 35, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        Font = Enum.Font.GothamMedium,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchBar,
    })

    local workarea = new("Frame", {
        Name = "workarea",
        Size = UDim2.new(1, -260, 1, -80),
        Position = UDim2.new(0, 245, 0, 70),
        BackgroundColor3 = Color3.fromRGB(28, 28, 31),
        BackgroundTransparency = 0.5,
        Parent = main,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = workarea

    local sections = {}
    local pages = {}

    local function selectSection(idx)
        for i, btn in ipairs(sections) do
            btn.BackgroundTransparency = 1
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        for i, pg in ipairs(pages) do
            pg.Visible = (i == idx)
        end
        if sections[idx] then
            sections[idx].BackgroundTransparency = 0
            sections[idx].TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    RunService.RenderStepped:Connect(function()
        if not searchBox:IsFocused() then
            for _, btn in ipairs(sections) do
                if btn:IsA("TextButton") then btn.Visible = true end
            end
        end
        local txt = string.upper(searchBox.Text)
        for _, btn in ipairs(sections) do
            if btn:IsA("TextButton") then
                if txt == "" or string.find(string.upper(btn.Text), txt) then
                    btn.Visible = true
                else
                    btn.Visible = false
                end
            end
        end
    end)

    local windowObj = {}

    function windowObj:CreateSection(name)
        local sidebarBtn = new("TextButton", {
            Name = name,
            Size = UDim2.new(1, -10, 0, 36),
            BackgroundColor3 = Color3.fromRGB(40, 40, 44),
            BackgroundTransparency = 1,
            Text = name,
            Font = Enum.Font.GothamMedium,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Parent = sidebar,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = sidebarBtn
        new("UIPadding", { PaddingLeft = UDim.new(0, 12) }).Parent = sidebarBtn

        local page = new("ScrollingFrame", {
            Name = name .. "_page",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = workarea,
        })
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }).Parent = page

        local idx = #sections + 1
        sidebarBtn.MouseButton1Click:Connect(function()
            selectSection(idx)
        end)
        
        table.insert(sections, sidebarBtn)
        table.insert(pages, page)

        if idx == 1 then selectSection(1) end

        local sectionObj = {}

        function sectionObj:Divider(text)
            new("TextLabel", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                LayoutOrder = #page:GetChildren(),
                Parent = page,
            })
        end

        function sectionObj:Button(name, callback)
            local btn = new("TextButton", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Color3.fromRGB(34, 34, 38),
                BackgroundTransparency = 0.5,
                Text = name,
                Font = Enum.Font.GothamBold,
                TextColor3 = Color3.fromRGB(10, 132, 255),
                TextSize = 14,
                AutoButtonColor = false,
                LayoutOrder = #page:GetChildren(),
                Parent = page,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = btn
            new("UIStroke", { Color = Color3.fromRGB(10, 132, 255), Thickness = 1, Transparency = 0.5 }).Parent = btn

            btn.MouseButton1Click:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.2 }):Play()
                task.delay(0.1, function()
                    TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.5 }):Play()
                end)
                if callback then callback() end
            end)
        end

        function sectionObj:Label(name)
            new("TextLabel", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(180, 180, 180),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = #page:GetChildren(),
                Parent = page,
            })
        end

        function sectionObj:Switch(name, default, callback)
            local state = default
            local toggleFrame = new("Frame", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundTransparency = 1,
                LayoutOrder = #page:GetChildren(),
                Parent = page,
            })
            
            new("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggleFrame,
            })

            local switchBg = new("TextButton", {
                Size = UDim2.fromOffset(50, 26),
                Position = UDim2.new(1, -50, 0.5, -13),
                BackgroundColor3 = state and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 60),
                BackgroundTransparency = 0.2,
                Text = "",
                AutoButtonColor = false,
                Parent = toggleFrame,
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = switchBg

            local knob = new("Frame", {
                Size = UDim2.fromOffset(20, 20),
                Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = switchBg,
            })
            new("UICorner", { CornerRadius = UDim.new(1, 0) }).Parent = knob

            switchBg.MouseButton1Click:Connect(function()
                state = not state
                if state then
                    TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(1, -23, 0.5, -10) }):Play()
                else
                    TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 3, 0.5, -10) }):Play()
                end
                TweenService:Create(switchBg, TweenInfo.new(0.3), { BackgroundColor3 = state and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 60) }):Play()
                if callback then callback(state) end
            end)
        end

        function sectionObj:TextField(name, placeholder, callback)
            local fieldFrame = new("Frame", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundTransparency = 1,
                LayoutOrder = #page:GetChildren(),
                Parent = page,
            })

            new("TextLabel", {
                Size = UDim2.new(0.4, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = name,
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = fieldFrame,
            })

            local inputBg = new("Frame", {
                Size = UDim2.new(0.6, -10, 0, 30),
                Position = UDim2.new(0.4, 0, 0.5, -15),
                BackgroundColor3 = Color3.fromRGB(34, 34, 38),
                BackgroundTransparency = 0.2,
                Parent = fieldFrame,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }).Parent = inputBg

            local box = new("TextBox", {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = placeholder or "Enter...",
                PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
                Font = Enum.Font.GothamMedium,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = inputBg,
            })

            box.FocusLost:Connect(function()
                if callback then callback(box.Text) end
            end)
        end

        return sectionObj
    end

    tp(main, UDim2.new(0.5, 0, 0.5, 0), 0.6)

    return windowObj
end

return StreamUI

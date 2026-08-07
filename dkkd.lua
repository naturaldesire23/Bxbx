--[[
    AetherUI - Merged UI Library
    Combines the best of RectUI, Samet UI, and Ather UI
    Features: Glass theme, Tabs, Sections, Toggles, Sliders, Dropdowns,
              Keybinds, Color Pickers, Notifications, Keybind List,
              Watermark, Config System, Server Hop, and more.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Helper Functions
local function New(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    return inst
end

local function Tween(inst, props, time, style, dir)
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function MakeDraggable(handle, target)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--// Main UI Class
local UI = {}
UI.__index = UI

--// Default Theme (Glass + Dark)
local DefaultTheme = {
    Background = Color3.fromRGB(20, 20, 25),
    Header = Color3.fromRGB(30, 30, 35),
    TabBar = Color3.fromRGB(25, 25, 30),
    TabInactive = Color3.fromRGB(170, 170, 170),
    TabActive = Color3.fromRGB(255, 255, 255),
    Section = Color3.fromRGB(28, 28, 33),
    Element = Color3.fromRGB(40, 40, 45),
    Border = Color3.fromRGB(50, 50, 55),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(0, 150, 255),
    AccentGradient = Color3.fromRGB(100, 180, 255),
}

--// UI Creation
function UI:CreateWindow(config)
    config = config or {}
    local Theme = DefaultTheme
    if config.Theme then
        for k, v in pairs(config.Theme) do Theme[k] = v end
    end

    local Window = {}
    Window.Theme = Theme
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.Flags = {}
    Window.AccentRefreshers = {}
    Window.IsOpen = false
    Window.Transparency = config.Transparency or 0.15

    local function registerAccentRefresher(fn)
        table.insert(Window.AccentRefreshers, fn)
    end

    function Window:SetAccent(color)
        Theme.Accent = color
        for _, refresh in ipairs(Window.AccentRefreshers) do refresh() end
    end

    function Window:SetTransparency(value)
        Window.Transparency = value
        MainFrame.BackgroundTransparency = value
        -- Apply to all relevant frames
        for _, child in MainFrame:GetDescendants() do
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                if child ~= MainFrame then
                    child.BackgroundTransparency = value + 0.1
                end
            end
        end
    end

    function Window:Destroy()
        if ScreenGui then ScreenGui:Destroy() end
        if blurPart then blurPart:Destroy() end
        if dof then dof:Destroy() end
    end

    function Window:SaveConfig(name)
        local data = {}
        for flag, handle in pairs(Window.Flags) do
            data[flag] = handle.Get()
        end
        local encoded = HttpService:JSONEncode(data)
        if writefile then
            if not isfolder or not isfolder("AetherUI") then
                if makefolder then makefolder("AetherUI") end
            end
            writefile("AetherUI/" .. name .. ".json", encoded)
        end
    end

    function Window:LoadConfig(name)
        if readfile and isfile and isfile("AetherUI/" .. name .. ".json") then
            local decoded = HttpService:JSONDecode(readfile("AetherUI/" .. name .. ".json"))
            for flag, value in pairs(decoded) do
                if Window.Flags[flag] then
                    Window.Flags[flag].Set(nil, value)
                end
            end
        end
    end

    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local text = config.Text or ""
        local duration = config.Duration or 3

        local NotifHolder = Window.NotifHolder
        if not NotifHolder then
            NotifHolder = New("Frame", {
                Name = "Notifications",
                Size = UDim2.new(0, 280, 1, -20),
                Position = UDim2.new(1, -290, 0, 10),
                BackgroundTransparency = 1,
                Parent = ScreenGui,
            })
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 6),
                Parent = NotifHolder,
            })
            Window.NotifHolder = NotifHolder
        end

        local Card = New("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Section,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = NotifHolder,
        })
        New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 1, Parent = Card })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            Parent = Card,
        })
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = Card })

        local NTitle = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = Theme.Text,
            TextTransparency = 1,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Card,
        })
        local NText = New("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextDim,
            TextTransparency = 1,
            TextSize = 13,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Card,
        })

        Tween(Card, { BackgroundTransparency = Window.Transparency }, 0.15)
        Tween(NTitle, { TextTransparency = 0 }, 0.15)
        Tween(NText, { TextTransparency = 0 }, 0.15)

        task.delay(duration, function()
            Tween(Card, { BackgroundTransparency = 1 }, 0.2)
            Tween(NTitle, { TextTransparency = 1 }, 0.2)
            Tween(NText, { TextTransparency = 1 }, 0.2)
            task.delay(0.2, function() Card:Destroy() end)
        end)
    end

    --// Create ScreenGui and Main Frame
    local ScreenGui = New("ScreenGui", {
        Name = "AetherUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    local size = config.Size or UDim2.new(0, 520, 0, 420)

    local MainFrame = New("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Window.Transparency,
        BorderSizePixel = 0,
        Parent = ScreenGui,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = MainFrame })

    --// Glass Blur Effect (Ather UI Style)
    local blurPart
    local dof
    if config.Blur ~= false then
        dof = New("DepthOfFieldEffect", {
            Parent = Lighting,
            Enabled = true,
            FarIntensity = 0,
            FocusDistance = 0,
            InFocusRadius = 1000,
            NearIntensity = 1,
        })
        blurPart = New("Part", {
            Material = Enum.Material.Glass,
            Transparency = 0.95,
            Reflectance = 0.5,
            CastShadow = false,
            Anchored = true,
            CanCollide = false,
            Size = Vector3.new(1, 1, 1) * 0.01,
            Parent = workspace,
        })
        local blockMesh = New("BlockMesh", { Parent = blurPart })
        RunService.RenderStepped:Connect(function()
            if Window.IsOpen and MainFrame.Visible then
                local pos = MainFrame.AbsolutePosition
                local size = MainFrame.AbsoluteSize
                local c0 = pos
                local c1 = pos + size
                local ray0 = Camera:ScreenPointToRay(c0.X, c0.Y, 1)
                local ray1 = Camera:ScreenPointToRay(c1.X, c1.Y, 1)
                local origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ)
                local normal = Camera.CFrame.LookVector
                local function getPoint(ray)
                    local t = -normal:Dot(origin - ray.Origin) / normal:Dot(ray.Direction)
                    return origin + (ray.Direction * t)
                end
                local p0 = Camera.CFrame:PointToObjectSpace(getPoint(ray0))
                local p1 = Camera.CFrame:PointToObjectSpace(getPoint(ray1))
                local center = (p0 + p1) / 2
                local scale = (p1 - p0) / 0.0101
                blockMesh.Offset = center
                blockMesh.Scale = scale
                blurPart.CFrame = Camera.CFrame
            end
        end)
    end

    MakeDraggable(MainFrame, MainFrame)

    --// Header
    local Header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })

    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Title or "AetherUI",
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    --// Header Buttons
    local function HeaderButton(name, text, xOffset)
        local btn = New("TextButton", {
            Name = name,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, xOffset, 0.5, -14),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = Theme.TextDim,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = Header,
        })
        btn.MouseEnter:Connect(function() Tween(btn, { TextColor3 = Theme.Text }, 0.1) end)
        btn.MouseLeave:Connect(function() Tween(btn, { TextColor3 = Theme.TextDim }, 0.1) end)
        return btn
    end

    local CloseBtn = HeaderButton("Close", "✕", -36)
    local MinBtn = HeaderButton("Minimize", "—", -64)
    local GearBtn = HeaderButton("Settings", "⚙", -92)

    local minimized = false
    local expandedSize = size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 36) }, 0.2)
        else
            Tween(MainFrame, { Size = expandedSize }, 0.2)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, 0.15)
        task.delay(0.15, function() Window:Destroy() end)
    end)

    GearBtn.MouseButton1Click:Connect(function()
        if Window.SettingsCallback then Window.SettingsCallback() end
    end)

    function Window:OnSettings(cb)
        Window.SettingsCallback = cb
    end

    --// Tab Bar
    local TabBar = New("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = Theme.TabBar,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    New("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.5,
        Parent = TabBar,
    })

    local TabLayout = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = TabBar,
    })

    --// Content Area
    local ContentArea = New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -70),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Window.Transparency + 0.1,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    --// Create Tab Function
    function Window:CreateTab(name)
        local Tab = {}
        Tab.Name = name

        local TabButton = New("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.TabBar,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = TabBar,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            Parent = TabButton,
        })

        local TabLabel = New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TabInactive,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            Parent = TabButton,
        })

        local AccentBar = New("Frame", {
            Name = "Accent",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = TabButton,
        })
        registerAccentRefresher(function() AccentBar.BackgroundColor3 = Theme.Accent end)

        local Page = New("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = ContentArea,
        })
        registerAccentRefresher(function() Page.ScrollBarImageColor3 = Theme.Accent end)
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            Parent = Page,
        })
        local PageLayout = New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = Page,
        })

        local function setActive(active)
            if active then
                Tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.12)
                Tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
                Page.Visible = true
            else
                Tween(TabLabel, { TextColor3 = Theme.TabInactive }, 0.12)
                Tween(AccentBar, { BackgroundTransparency = 1 }, 0.12)
                Page.Visible = false
            end
        end

        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.1)
                Tween(TabButton, { BackgroundTransparency = 0.9 }, 0.1)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(TabLabel, { TextColor3 = Theme.TabInactive }, 0.1)
            end
            Tween(TabButton, { BackgroundTransparency = 1 }, 0.1)
        end)

        TabButton.MouseButton1Click:Connect(function()
            if Window.ActiveTab then Window.ActiveTab.setActive(false) end
            Window.ActiveTab = Tab
            setActive(true)
        end)

        Tab.setActive = setActive
        Tab.Page = Page

        if not Window.ActiveTab then
            Window.ActiveTab = Tab
            setActive(true)
        end

        --// Create Section
        function Tab:CreateSection(name)
            local Section = {}

            local SectionFrame = New("Frame", {
                Name = name .. "Section",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Section,
                BackgroundTransparency = Window.Transparency + 0.1,
                BorderSizePixel = 0,
                LayoutOrder = #Page:GetChildren(),
                Parent = Page,
            })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.3, Parent = SectionFrame })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                Parent = SectionFrame,
            })
            local SectionListLayout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10),
                Parent = SectionFrame,
            })

            local SectionTitle = New("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = string.upper(name),
                TextColor3 = Theme.TextDim,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 0,
                Parent = SectionFrame,
            })

            local order = 1
            local function nextOrder()
                order = order + 1
                return order
            end

            --// Elements
            function Section:CreateLabel(text)
                local Label = New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = nextOrder(),
                    Parent = SectionFrame,
                })
                return Label
            end

            function Section:CreateToggle(text, callback, flag)
                callback = callback or function() end
                local state = false

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionFrame,
                })

                New("TextLabel", {
                    Size = UDim2.new(1, -46, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Track = New("TextButton", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -40, 0.5, -10),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

                local Knob = New("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Theme.TextDim,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

                local function render()
                    if state then
                        Tween(Track, { BackgroundColor3 = Theme.Accent }, 0.12)
                        Tween(Knob, { Position = UDim2.new(0, 22, 0.5, -8), BackgroundColor3 = Theme.Text }, 0.12)
                    else
                        Tween(Track, { BackgroundColor3 = Theme.Element }, 0.12)
                        Tween(Knob, { Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Theme.TextDim }, 0.12)
                    end
                end

                Track.MouseButton1Click:Connect(function()
                    state = not state
                    render()
                    callback(state)
                end)

                registerAccentRefresher(function() if state then Track.BackgroundColor3 = Theme.Accent end end)

                local handle = {
                    Set = function(_, v)
                        state = v
                        render()
                        callback(state)
                    end,
                    Get = function() return state end,
                }
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            function Section:CreateSlider(text, min, max, default, callback, step, flag)
                callback = callback or function() end
                step = step or 1
                local value = default or min

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionFrame,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -50, 0, 18),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local ValueLabel = New("TextLabel", {
                    Size = UDim2.new(0, 50, 0, 18),
                    Position = UDim2.new(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(value),
                    TextColor3 = Theme.TextDim,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Row,
                })

                local Track = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 4),
                    Position = UDim2.new(0, 0, 0, 28),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    BorderSizePixel = 0,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

                local Fill = New("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = Track,
                })

                local Knob = New("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

                local dragging = false
                local function setFromAlpha(alpha)
                    alpha = math.clamp(alpha, 0, 1)
                    local raw = min + (max - min) * alpha
                    local steps = math.floor((raw - min) / step + 0.5)
                    value = min + steps * step
                    value = math.clamp(value, min, max)
                    local realAlpha = (value - min) / (max - min)
                    Fill.Size = UDim2.new(realAlpha, 0, 1, 0)
                    Knob.Position = UDim2.new(realAlpha, -7, 0.5, -7)
                    ValueLabel.Text = step < 1 and string.format("%.2f", value) or tostring(value)
                    callback(value)
                end

                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                        setFromAlpha(alpha)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                        setFromAlpha(alpha)
                    end
                end)

                registerAccentRefresher(function() Fill.BackgroundColor3 = Theme.Accent end)

                local handle = {
                    Set = function(_, v)
                        setFromAlpha((v - min) / (max - min))
                    end,
                    Get = function() return value end,
                }
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            function Section:CreateDropdown(text, options, callback, flag)
                callback = callback or function() end
                options = options or {}
                local selected = options[1]
                local open = false

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    ZIndex = 5,
                    Parent = SectionFrame,
                })

                New("TextLabel", {
                    Size = UDim2.new(1, -150, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Box = New("TextButton", {
                    Size = UDim2.new(0, 140, 0, 30),
                    Position = UDim2.new(1, -140, 0.5, -15),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    Text = "  " .. tostring(selected),
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 6,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Box })

                local ListHolder = New("Frame", {
                    Size = UDim2.new(0, 140, 0, 0),
                    Position = UDim2.new(1, -140, 1, 2),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 10,
                    Parent = Box,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ListHolder })
                New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ListHolder })

                for i, opt in ipairs(options) do
                    local OptBtn = New("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = Theme.Element,
                        BackgroundTransparency = Window.Transparency,
                        Text = "  " .. tostring(opt),
                        TextColor3 = Theme.TextDim,
                        TextSize = 13,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        ZIndex = 11,
                        Parent = ListHolder,
                    })
                    OptBtn.MouseEnter:Connect(function() Tween(OptBtn, { TextColor3 = Theme.Text }, 0.1) end)
                    OptBtn.MouseLeave:Connect(function() Tween(OptBtn, { TextColor3 = Theme.TextDim }, 0.1) end)
                    OptBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        Box.Text = "  " .. tostring(opt)
                        open = false
                        Tween(ListHolder, { Size = UDim2.new(0, 140, 0, 0) }, 0.12)
                        callback(opt)
                    end)
                end

                local function closeDropdown()
                    if open then
                        open = false
                        Tween(ListHolder, { Size = UDim2.new(0, 140, 0, 0) }, 0.12)
                    end
                end

                Box.MouseButton1Click:Connect(function()
                    open = not open
                    local h = open and math.min(#options * 28, 130) or 0
                    Tween(ListHolder, { Size = UDim2.new(0, 140, 0, h) }, 0.12)
                end)

                UserInputService.InputBegan:Connect(function(input)
                    if not open then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local pos = input.Position
                    local boxPos, boxSize = Box.AbsolutePosition, Box.AbsoluteSize
                    local listPos, listSize = ListHolder.AbsolutePosition, ListHolder.AbsoluteSize
                    local inBox = pos.X >= boxPos.X and pos.X <= boxPos.X + boxSize.X and pos.Y >= boxPos.Y and pos.Y <= boxPos.Y + boxSize.Y
                    local inList = pos.X >= listPos.X and pos.X <= listPos.X + listSize.X and pos.Y >= listPos.Y and pos.Y <= listPos.Y + listSize.Y
                    if not inBox and not inList then closeDropdown() end
                end)

                local handle = {
                    Set = function(_, v)
                        selected = v
                        Box.Text = "  " .. tostring(v)
                        callback(v)
                    end,
                    Get = function() return selected end,
                }
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            function Section:CreateButton(text, callback)
                local Btn = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = Window.Transparency,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    LayoutOrder = nextOrder(),
                    Parent = SectionFrame,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
                end)
                Btn.MouseButton1Click:Connect(function()
                    callback()
                end)

                registerAccentRefresher(function() Btn.BackgroundColor3 = Theme.Accent end)
                return Btn
            end

            function Section:CreateKeybind(text, default, callback, flag)
                callback = callback or function() end
                local bindingKey = default or Enum.KeyCode.Unknown
                local listening = false

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionFrame,
                })

                New("TextLabel", {
                    Size = UDim2.new(1, -70, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local KeyBox = New("TextButton", {
                    Size = UDim2.new(0, 65, 0, 28),
                    Position = UDim2.new(1, -65, 0, 0),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    Text = bindingKey.Name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    AutoButtonColor = false,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KeyBox })

                KeyBox.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBox.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        bindingKey = input.KeyCode
                        KeyBox.Text = bindingKey.Name
                        listening = false
                        callback(bindingKey)
                    elseif not gpe and input.KeyCode == bindingKey and not listening then
                        callback(bindingKey)
                    end
                end)

                local handle = {
                    Set = function(_, key)
                        bindingKey = typeof(key) == "string" and Enum.KeyCode[key] or key
                        KeyBox.Text = bindingKey.Name
                    end,
                    Get = function() return bindingKey.Name end,
                }
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            return Section
        end

        return Tab
    end

    Window.Gui = ScreenGui
    Window.Frame = MainFrame
    Window.IsOpen = true
    return Window
end

--// Keybind List (Ather UI style)
function UI:KeybindList(title)
    local list = {}
    local holder = New("Frame", {
        Parent = UI.Holder and UI.Holder.Instance or nil,
        Name = "KeybindList",
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0, 20, 0.5, 20),
        BackgroundColor3 = DefaultTheme.Section,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Visible = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = holder })
    New("UIStroke", { Color = DefaultTheme.Border, Thickness = 1, Parent = holder })
    MakeDraggable(holder, holder)

    local header = New("Frame", {
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = DefaultTheme.Header,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = header })

    local titleLabel = New("TextLabel", {
        Parent = header,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Keybinds",
        TextColor3 = DefaultTheme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local content = New("Frame", {
        Parent = holder,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
    New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = content })

    function list:Add(name, key)
        local row = New("TextButton", {
            Parent = content,
            Size = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        })
        local label = New("TextLabel", {
            Parent = row,
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            Text = name .. " [" .. key .. "]",
            TextColor3 = DefaultTheme.Text,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local accent = New("Frame", {
            Parent = row,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(1, -12, 0.5, -3),
            BackgroundColor3 = DefaultTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accent })

        local item = {
            Set = function(_, name, key)
                label.Text = name .. " [" .. key .. "]"
            end,
            SetStatus = function(_, bool)
                Tween(accent, { BackgroundTransparency = bool and 0 or 1 }, 0.15)
            end,
        }
        return item
    end

    function list:SetVisibility(bool)
        holder.Visible = bool
    end

    return list
end

--// Watermark (Samet UI style)
function UI:Watermark(data)
    data = data or {}
    if not UI.Holder then return end
    local frame = New("Frame", {
        Parent = UI.Holder.Instance,
        Name = "Watermark",
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = DefaultTheme.Section,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Visible = true,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    New("UIStroke", { Color = DefaultTheme.Border, Thickness = 1, Parent = frame })
    MakeDraggable(frame, frame)

    local label = New("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = data.Text or "AetherUI",
        TextColor3 = DefaultTheme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
    })
    return frame
end

--// Main Library Setup
UI.Holder = New("ScreenGui", {
    Parent = gethui(),
    Name = "AetherUI_Base",
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 2,
    ResetOnSpawn = false,
})

UI.NotifHolder = New("Frame", {
    Parent = UI.Holder,
    Name = "Notifications",
    Size = UDim2.new(0, 0, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    AnchorPoint = Vector2.new(1, 0),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.X,
})
New("UIListLayout", {
    Parent = UI.NotifHolder,
    Padding = UDim.new(0, 12),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
})
New("UIPadding", {
    Parent = UI.NotifHolder,
    PaddingTop = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 12),
})

function UI:Notify(config)
    local window = UI.CurrentWindow
    if window and window.Notify then
        window:Notify(config)
    else
        -- Fallback notification
        local frame = New("Frame", {
            Parent = UI.NotifHolder,
            Size = UDim2.new(0, 260, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = DefaultTheme.Section,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
        New("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = frame })
        local t = New("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title or "Notification",
            TextColor3 = DefaultTheme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        local d = New("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = config.Text or "",
            TextColor3 = DefaultTheme.TextDim,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        task.delay(config.Duration or 3, function() frame:Destroy() end)
    end
end

return UI

--[[
    ═══════════════════════════════════════════════════════════
    AETHERUI v2.0 - Merged UI Library
    ═══════════════════════════════════════════════════════════
    Merges:
        - RectUI (Structure, Elements)
        - Samet UI (Glass, Gradients, Icons, Global Chat, Watermark)
        - Ather UI (Blur, Color Pickers, Keybind List, Server Hop)
    
    Features:
        - Glass/Transparent UI (user adjustable)
        - DepthOfField blur effect (Ather)
        - Gradients on buttons, toggles, accents (Samet)
        - Rich text support (Samet)
        - Global chat (Samet)
        - Watermark (Samet)
        - Keybind list (Ather)
        - Color pickers (Ather)
        - Config save/load (RectUI)
        - Server hop (Ather)
        - All assets from all 3 UIs
    ═══════════════════════════════════════════════════════════
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// ─── ASSETS (From All 3 UIs) ───
local Assets = {
    -- Gradients (Samet UI)
    Gradients = {
        AccentStart = Color3.fromRGB(175, 102, 126),
        AccentEnd = Color3.fromRGB(114, 75, 135),
    },
    
    -- Icons (Ather UI)
    Icons = {
        Settings = "rbxassetid://122669828593160",
        Close = "rbxassetid://130510492706892",
        Minimize = "rbxassetid://79384247470010",
        Check = "rbxassetid://121760666525660",
        DropdownArrow = "rbxassetid://123317177279443",
        Search = "rbxassetid://79227204687245",
        Send = "rbxassetid://101636617799068",
        Logo = "rbxassetid://133218922939038",
        KeybindIcon = "rbxassetid://81598136527047",
        ModIcon = "rbxassetid://74208295465261",
        WatermarkIcon = "rbxassetid://103028899808055",
    },
    
    -- Custom Font (Samet UI)
    Fonts = {
        SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Light = Font.new("rbxassetid://12187365364", Enum.FontWeight.Light, Enum.FontStyle.Normal),
    },
}

--// ─── THEME (Glass + Dark) ───
local DefaultTheme = {
    Background = Color3.fromRGB(18, 18, 20),
    Background2 = Color3.fromRGB(12, 12, 14),
    Header = Color3.fromRGB(28, 28, 30),
    TabBar = Color3.fromRGB(22, 22, 25),
    TabInactive = Color3.fromRGB(170, 170, 170),
    TabActive = Color3.fromRGB(255, 255, 255),
    Section = Color3.fromRGB(24, 24, 28),
    SectionTop = Color3.fromRGB(28, 27, 31),
    SectionBackground = Color3.fromRGB(10, 10, 12),
    Element = Color3.fromRGB(40, 40, 45),
    Border = Color3.fromRGB(50, 50, 55),
    Outline = Color3.fromRGB(25, 25, 28),
    Text = Color3.fromRGB(235, 235, 235),
    TextDim = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(0, 150, 255),
    AccentGradient = Color3.fromRGB(100, 180, 255),
    AccentStart = Color3.fromRGB(175, 102, 126),   -- Samet gradient start
    AccentEnd = Color3.fromRGB(114, 75, 135),      -- Samet gradient end
}

--// ─── HELPERS ───
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

--// ─── GRADIENT HELPER (Samet UI) ───
local function ApplyGradient(parent, startColor, endColor)
    local grad = New("UIGradient", {
        Parent = parent,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, startColor),
            ColorSequenceKeypoint.new(1, endColor),
        }
    })
    return grad
end

local function ApplyGradientRotated(parent, startColor, endColor, rotation)
    local grad = New("UIGradient", {
        Parent = parent,
        Rotation = rotation or -115,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, startColor),
            ColorSequenceKeypoint.new(1, endColor),
        }
    })
    return grad
end

--// ─── RICH TEXT HELPER (Samet UI) ───
local function ToRich(text, color)
    return `<font color="rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})">{text}</font>`
end

--// ─── MAIN UI CLASS ───
local UI = {}
UI.__index = UI
UI.Assets = Assets
UI.Theme = DefaultTheme
UI.Flags = {}
UI.Keybinds = {}
UI.Mods = {}
UI.Notifications = {}
UI.Connections = {}
UI.Threads = {}

--// ─── FOLDERS (Samet UI) ───
UI.Folders = {
    Directory = "AetherUI",
    Assets = "AetherUI/Assets",
    Configs = "AetherUI/Configs",
}
for _, path in pairs(UI.Folders) do
    if not isfolder(path) then
        pcall(makefolder, path)
    end
end

--// ─── THREAD & CONNECT HELPERS ───
function UI:Thread(fn)
    local thread = coroutine.create(fn)
    coroutine.wrap(function() coroutine.resume(thread) end)()
    table.insert(self.Threads, thread)
    return thread
end

function UI:Connect(event, callback)
    local conn = event:Connect(callback)
    table.insert(self.Connections, conn)
    return conn
end

function UI:SafeCall(fn, ...)
    local args = {...}
    local ok, result = pcall(fn, table.unpack(args))
    if not ok then warn(result) end
    return ok, result
end

--// ─── THEME HELPERS ───
function UI:ChangeTheme(theme, color)
    self.Theme[theme] = color
    for _, item in pairs(self.ThemeItems or {}) do
        for prop, val in pairs(item.Properties) do
            if type(val) == "string" and val == theme then
                item.Item[prop] = color
            elseif type(val) == "function" then
                item.Item[prop] = val()
            end
        end
    end
end

function UI:AddToTheme(item, props)
    item = item.Instance or item
    local data = { Item = item, Properties = props }
    for prop, val in pairs(props) do
        if type(val) == "string" then
            item[prop] = self.Theme[val]
        else
            item[prop] = val()
        end
    end
    table.insert(self.ThemeItems or {}, data)
    return item
end

--// ─── CONFIG HELPERS ───
function UI:GetConfig()
    local data = {}
    for flag, handle in pairs(self.Flags) do
        if type(handle.Get) == "function" then
            data[flag] = handle.Get()
        end
    end
    return HttpService:JSONEncode(data)
end

function UI:LoadConfig(json)
    local data = HttpService:JSONDecode(json)
    for flag, value in pairs(data) do
        if self.Flags[flag] and type(self.Flags[flag].Set) == "function" then
            self.Flags[flag]:Set(value)
        end
    end
end

function UI:SaveConfig(name)
    if writefile then
        if not isfolder("AetherUI/Configs") then makefolder("AetherUI/Configs") end
        writefile("AetherUI/Configs/" .. name .. ".json", self:GetConfig())
    end
end

function UI:LoadConfigFile(name)
    if readfile and isfile("AetherUI/Configs/" .. name .. ".json") then
        self:LoadConfig(readfile("AetherUI/Configs/" .. name .. ".json"))
    end
end

function UI:GetConfigList()
    local list = {}
    if listfiles then
        for _, file in pairs(listfiles("AetherUI/Configs")) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    return list
end

--// ─── NOTIFICATION (Samet UI) ───
function UI:Notify(config)
    config = config or {}
    local title = config.Title or "Notification"
    local text = config.Text or ""
    local duration = config.Duration or 3
    local icon = config.Icon or Assets.Icons.Logo

    local holder = self.NotifHolder
    if not holder then
        holder = New("Frame", {
            Parent = self.Holder and self.Holder.Instance,
            Name = "Notifications",
            Size = UDim2.new(0, 0, 1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
        })
        New("UIListLayout", {
            Parent = holder,
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
        })
        New("UIPadding", {
            Parent = holder,
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12),
        })
        self.NotifHolder = holder
    end

    local card = New("Frame", {
        Parent = holder,
        Size = UDim2.new(0, 280, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = self.Theme.Section,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
    New("UIStroke", { Color = self.Theme.Border, Thickness = 1, Transparency = 0.5, Parent = card })

    local padding = New("UIPadding", {
        Parent = card,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })

    -- Accent bar (gradient)
    local accent = New("Frame", {
        Parent = card,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
    })
    ApplyGradient(accent, self.Theme.AccentStart, self.Theme.AccentEnd)

    -- Icon (Samet style)
    local iconLabel = New("ImageLabel", {
        Parent = card,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 8, 0, 10),
        Image = icon,
        BackgroundTransparency = 1,
    })
    ApplyGradient(iconLabel, self.Theme.AccentStart, self.Theme.AccentEnd)

    -- Title
    local titleLabel = New("TextLabel", {
        Parent = card,
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 32, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Description
    local descLabel = New("TextLabel", {
        Parent = card,
        Size = UDim2.new(1, -40, 0, 0),
        Position = UDim2.new(0, 32, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Theme.TextDim,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    })

    task.delay(duration, function()
        Tween(card, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.25, function() card:Destroy() end)
    end)
end

--// ─── WINDOW CREATION ───
function UI:CreateWindow(config)
    config = config or {}
    local Theme = self.Theme
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
    Window.BlurEnabled = config.Blur ~= false
    Window.ThemeItems = {}

    local function registerAccentRefresher(fn)
        table.insert(Window.AccentRefreshers, fn)
    end

    function Window:SetAccent(color)
        Theme.Accent = color
        for _, refresh in ipairs(Window.AccentRefreshers) do refresh() end
        UI:ChangeTheme("Accent", color)
    end

    function Window:SetTransparency(value)
        Window.Transparency = value
        MainFrame.BackgroundTransparency = value
        for _, child in MainFrame:GetDescendants() do
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                if child ~= MainFrame and child:FindFirstAncestor("MainFrame") then
                    child.BackgroundTransparency = value + 0.05
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
            if type(handle.Get) == "function" then
                data[flag] = handle.Get()
            end
        end
        local encoded = HttpService:JSONEncode(data)
        if writefile then
            if not isfolder or not isfolder("AetherUI/Configs") then
                if makefolder then makefolder("AetherUI/Configs") end
            end
            writefile("AetherUI/Configs/" .. name .. ".json", encoded)
        end
        Window:Notify({ Title = "Config", Text = "Saved: " .. name, Duration = 2 })
    end

    function Window:LoadConfig(name)
        if readfile and isfile and isfile("AetherUI/Configs/" .. name .. ".json") then
            local decoded = HttpService:JSONDecode(readfile("AetherUI/Configs/" .. name .. ".json"))
            for flag, value in pairs(decoded) do
                if Window.Flags[flag] and type(Window.Flags[flag].Set) == "function" then
                    Window.Flags[flag]:Set(value)
                end
            end
            Window:Notify({ Title = "Config", Text = "Loaded: " .. name, Duration = 2 })
        end
    end

    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local text = config.Text or ""
        local duration = config.Duration or 3
        local icon = config.Icon or Assets.Icons.Logo

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
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Card })

        -- Gradient accent at top (Samet style)
        local accentBar = New("Frame", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        })
        ApplyGradient(accentBar, Theme.AccentStart, Theme.AccentEnd)

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            Parent = Card,
        })

        -- Icon
        local iconLabel = New("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 0, 0, 8),
            BackgroundTransparency = 1,
            Image = icon,
            Parent = Card,
        })
        ApplyGradient(iconLabel, Theme.AccentStart, Theme.AccentEnd)

        local NTitle = New("TextLabel", {
            Size = UDim2.new(1, -30, 0, 18),
            Position = UDim2.new(0, 24, 0, 6),
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
            Size = UDim2.new(1, -30, 0, 0),
            Position = UDim2.new(0, 24, 0, 26),
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

        Tween(Card, { BackgroundTransparency = Window.Transparency + 0.05 }, 0.15)
        Tween(NTitle, { TextTransparency = 0 }, 0.15)
        Tween(NText, { TextTransparency = 0 }, 0.15)

        task.delay(duration, function()
            Tween(Card, { BackgroundTransparency = 1 }, 0.2)
            Tween(NTitle, { TextTransparency = 1 }, 0.2)
            Tween(NText, { TextTransparency = 1 }, 0.2)
            task.delay(0.2, function() Card:Destroy() end)
        end)
    end

    function Window:OnSettings(cb)
        Window.SettingsCallback = cb
    end

    --// ─── SCREEN GUI ───
    local ScreenGui = New("ScreenGui", {
        Name = "AetherUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    local size = config.Size or UDim2.new(0, 540, 0, 440)

    --// ─── MAIN FRAME (Glass) ───
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

    --// ─── BLUR EFFECT (Ather UI) ───
    local blurPart, dof
    if Window.BlurEnabled then
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
            Parent = Workspace,
        })
        local blockMesh = New("BlockMesh", { Parent = blurPart })
        UI:Connect(RunService.RenderStepped, function()
            if Window.IsOpen and MainFrame.Visible then
                local pos = MainFrame.AbsolutePosition
                local sz = MainFrame.AbsoluteSize
                local c0 = pos
                local c1 = pos + sz
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

    --// ─── HEADER ───
    local Header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })

    -- Logo (Samet style with gradient)
    local Logo = New("ImageLabel", {
        Parent = Header,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 12, 0.5, -11),
        Image = Assets.Icons.Logo,
        BackgroundTransparency = 1,
    })
    ApplyGradient(Logo, Theme.AccentStart, Theme.AccentEnd)

    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Text = ToRich(config.Title or "AetherUI", Theme.AccentStart),
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
        RichText = true,
    })

    --// ─── HEADER BUTTONS (Samet style with hover gradient) ───
    local function HeaderButton(name, text, xOffset)
        local btn = New("TextButton", {
            Name = name,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(1, xOffset, 0.5, -15),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 0.5,
            Text = text,
            TextColor3 = Theme.TextDim,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = Header,
            AutoButtonColor = false,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
        ApplyGradientRotated(btn, Theme.AccentStart, Theme.AccentEnd, -115)
        btn.BackgroundTransparency = 1

        btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundTransparency = 0.3 }, 0.1)
            Tween(btn, { TextColor3 = Theme.Text }, 0.1)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundTransparency = 1 }, 0.1)
            Tween(btn, { TextColor3 = Theme.TextDim }, 0.1)
        end)
        return btn
    end

    local CloseBtn = HeaderButton("Close", "✕", -36)
    local MinBtn = HeaderButton("Minimize", "—", -66)
    local GearBtn = HeaderButton("Settings", "⚙", -96)

    local minimized = false
    local expandedSize = size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 38) }, 0.2)
        else
            Tween(MainFrame, { Size = expandedSize }, 0.2)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, 0.15)
        task.delay(0.2, function() Window:Destroy() end)
    end)

    GearBtn.MouseButton1Click:Connect(function()
        if Window.SettingsCallback then Window.SettingsCallback() end
    end)

    --// ─── TAB BAR ───
    local TabBar = New("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 38),
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

    --// ─── CONTENT AREA ───
    local ContentArea = New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -74),
        Position = UDim2.new(0, 0, 0, 74),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })

    --// ─── CREATE TAB ───
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

        -- Tab label with rich text (Samet style)
        local TabLabel = New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = ToRich(name, Theme.Text),
            TextColor3 = Theme.TabInactive,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            Parent = TabButton,
            RichText = true,
        })

        -- Accent bar with gradient (Samet style)
        local AccentBar = New("Frame", {
            Name = "Accent",
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = TabButton,
        })
        ApplyGradient(AccentBar, Theme.AccentStart, Theme.AccentEnd)
        registerAccentRefresher(function()
            AccentBar.BackgroundColor3 = Theme.Accent
            ApplyGradient(AccentBar, Theme.AccentStart, Theme.AccentEnd)
        end)

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
                TabLabel.Text = ToRich(name, Theme.Text)
                Tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.12)
                Tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
                Page.Visible = true
            else
                TabLabel.Text = ToRich(name, Theme.TextDim)
                Tween(TabLabel, { TextColor3 = Theme.TabInactive }, 0.12)
                Tween(AccentBar, { BackgroundTransparency = 1 }, 0.12)
                Page.Visible = false
            end
        end

        TabButton.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                TabLabel.Text = ToRich(name, Theme.Text)
                Tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.1)
                Tween(TabButton, { BackgroundTransparency = 0.85 }, 0.1)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                TabLabel.Text = ToRich(name, Theme.TabInactive)
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

        --// ─── CREATE SECTION ───
        function Tab:CreateSection(name)
            local Section = {}

            local SectionFrame = New("Frame", {
                Name = name .. "Section",
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Section,
                BackgroundTransparency = Window.Transparency + 0.05,
                BorderSizePixel = 0,
                LayoutOrder = #Page:GetChildren(),
                Parent = Page,
            })
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.3, Parent = SectionFrame })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })

            -- Section header with gradient (Samet style)
            local SectionHeader = New("Frame", {
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.SectionTop,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
            })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionHeader })
            ApplyGradient(SectionHeader, Theme.AccentStart, Theme.AccentEnd)

            local SectionTitle = New("TextLabel", {
                Parent = SectionHeader,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = ToRich(string.upper(name), Theme.Text),
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
            })

            -- Toggle for section (Samet style)
            local SectionToggle = New("TextButton", {
                Parent = SectionHeader,
                Size = UDim2.new(0, 26, 0, 16),
                Position = UDim2.new(1, -16, 0.5, -8),
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 0.3,
                Text = "",
                AutoButtonColor = false,
            })
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SectionToggle })

            local ToggleCircle = New("Frame", {
                Parent = SectionToggle,
                Size = UDim2.new(0, 10, 0, 10),
                Position = UDim2.new(1, -13, 0.5, -5),
                BackgroundColor3 = Theme.Text,
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
            })
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleCircle })

            local SectionContent = New("Frame", {
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 34),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                Parent = SectionContent,
            })
            local ContentLayout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 10),
                Parent = SectionContent,
            })

            local isCollapsed = false
            SectionToggle.MouseButton1Click:Connect(function()
                isCollapsed = not isCollapsed
                if isCollapsed then
                    SectionContent.Visible = false
                    Tween(SectionToggle, { BackgroundTransparency = 0.6 }, 0.12)
                    Tween(ToggleCircle, { Position = UDim2.new(0, 3, 0.5, -5), BackgroundTransparency = 0 }, 0.12)
                else
                    SectionContent.Visible = true
                    Tween(SectionToggle, { BackgroundTransparency = 0.3 }, 0.12)
                    Tween(ToggleCircle, { Position = UDim2.new(1, -13, 0.5, -5), BackgroundTransparency = 0.6 }, 0.12)
                end
            end)

            local order = 1
            local function nextOrder()
                order = order + 1
                return order
            end

            --// ─── ELEMENTS ───

            function Section:CreateLabel(text)
                local Label = New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                    RichText = true,
                })
                return Label
            end

            function Section:CreateToggle(text, callback, flag)
                callback = callback or function() end
                local state = false

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 24),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                -- Toggle track with gradient (Samet style)
                local Track = New("TextButton", {
                    Size = UDim2.new(0, 40, 0, 22),
                    Position = UDim2.new(1, -40, 0.5, -11),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

                local TrackGrad = ApplyGradientRotated(Track, Theme.AccentStart, Theme.AccentEnd, -115)
                TrackGrad.Enabled = false

                local Knob = New("Frame", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = UDim2.new(0, 2, 0.5, -9),
                    BackgroundColor3 = Theme.TextDim,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

                local function render()
                    if state then
                        TrackGrad.Enabled = true
                        Tween(Track, { BackgroundColor3 = Theme.Accent }, 0.12)
                        Tween(Knob, { Position = UDim2.new(0, 20, 0.5, -9), BackgroundColor3 = Theme.Text }, 0.12)
                        Label.Text = ToRich(text, Theme.Text)
                    else
                        TrackGrad.Enabled = false
                        Tween(Track, { BackgroundColor3 = Theme.Element }, 0.12)
                        Tween(Knob, { Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.TextDim }, 0.12)
                        Label.Text = ToRich(text, Theme.TextDim)
                    end
                end

                Track.MouseButton1Click:Connect(function()
                    state = not state
                    render()
                    callback(state)
                end)

                registerAccentRefresher(function()
                    if state then
                        Track.BackgroundColor3 = Theme.Accent
                        TrackGrad.Enabled = true
                    end
                end)

                local handle = {
                    Set = function(_, v)
                        state = v
                        render()
                        callback(state)
                    end,
                    Get = function() return state end,
                }
                if flag then
                    Window.Flags[flag] = handle
                    UI.Flags[flag] = handle
                end
                return handle
            end

            function Section:CreateSlider(text, min, max, default, callback, step, flag)
                callback = callback or function() end
                step = step or 1
                local value = default or min

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -60, 0, 18),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                local ValueLabel = New("TextLabel", {
                    Size = UDim2.new(0, 60, 0, 18),
                    Position = UDim2.new(1, -60, 0, 0),
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

                -- Fill with gradient (Samet style)
                local Fill = New("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                ApplyGradient(Fill, Theme.AccentStart, Theme.AccentEnd)

                local Knob = New("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
                ApplyGradient(Knob, Theme.AccentStart, Theme.AccentEnd)

                local dragging = false
                local function setFromAlpha(alpha)
                    alpha = math.clamp(alpha, 0, 1)
                    local raw = min + (max - min) * alpha
                    local steps = math.floor((raw - min) / step + 0.5)
                    value = min + steps * step
                    value = math.clamp(value, min, max)
                    local realAlpha = (value - min) / (max - min)
                    Fill.Size = UDim2.new(realAlpha, 0, 1, 0)
                    Knob.Position = UDim2.new(realAlpha, -8, 0.5, -8)
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

                registerAccentRefresher(function()
                    Fill.BackgroundColor3 = Theme.Accent
                    ApplyGradient(Fill, Theme.AccentStart, Theme.AccentEnd)
                end)

                local handle = {
                    Set = function(_, v)
                        setFromAlpha((v - min) / (max - min))
                    end,
                    Get = function() return value end,
                }
                if flag then
                    Window.Flags[flag] = handle
                    UI.Flags[flag] = handle
                end
                return handle
            end

            function Section:CreateDropdown(text, options, callback, flag)
                callback = callback or function() end
                options = options or {}
                local selected = options[1]
                local open = false

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    ZIndex = 5,
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -160, 1, 0),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                local Box = New("TextButton", {
                    Size = UDim2.new(0, 150, 0, 30),
                    Position = UDim2.new(1, -150, 0.5, -15),
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
                ApplyGradient(Box, Theme.AccentStart, Theme.AccentEnd)
                Box.BackgroundTransparency = 1

                -- Arrow with gradient
                local Arrow = New("ImageLabel", {
                    Parent = Box,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(1, -18, 0.5, -6),
                    Image = Assets.Icons.DropdownArrow,
                    BackgroundTransparency = 1,
                })
                ApplyGradient(Arrow, Theme.AccentStart, Theme.AccentEnd)

                local ListHolder = New("Frame", {
                    Size = UDim2.new(0, 150, 0, 0),
                    Position = UDim2.new(1, -150, 1, 2),
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
                        Tween(ListHolder, { Size = UDim2.new(0, 150, 0, 0) }, 0.12)
                        callback(opt)
                    end)
                end

                local function closeDropdown()
                    if open then
                        open = false
                        Tween(ListHolder, { Size = UDim2.new(0, 150, 0, 0) }, 0.12)
                        Tween(Arrow, { Rotation = 0 }, 0.12)
                    end
                end

                Box.MouseButton1Click:Connect(function()
                    open = not open
                    local h = open and math.min(#options * 28, 130) or 0
                    Tween(ListHolder, { Size = UDim2.new(0, 150, 0, h) }, 0.12)
                    Tween(Arrow, { Rotation = open and 180 or 0 }, 0.12)
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
                if flag then
                    Window.Flags[flag] = handle
                    UI.Flags[flag] = handle
                end
                return handle
            end

            function Section:CreateButton(text, callback)
                local Btn = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = Window.Transparency,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                    RichText = true,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })
                ApplyGradient(Btn, Theme.AccentStart, Theme.AccentEnd)

                Btn.MouseEnter:Connect(function()
                    Tween(Btn, { BackgroundTransparency = 0.2 }, 0.1)
                end)
                Btn.MouseLeave:Connect(function()
                    Tween(Btn, { BackgroundTransparency = Window.Transparency }, 0.1)
                end)
                Btn.MouseButton1Click:Connect(function()
                    callback()
                end)

                registerAccentRefresher(function()
                    Btn.BackgroundColor3 = Theme.Accent
                    ApplyGradient(Btn, Theme.AccentStart, Theme.AccentEnd)
                end)
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
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -75, 1, 0),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                local KeyBox = New("TextButton", {
                    Size = UDim2.new(0, 70, 0, 28),
                    Position = UDim2.new(1, -70, 0, 0),
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
                ApplyGradient(KeyBox, Theme.AccentStart, Theme.AccentEnd)
                KeyBox.BackgroundTransparency = 1

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
                if flag then
                    Window.Flags[flag] = handle
                    UI.Flags[flag] = handle
                end
                return handle
            end

            --// ─── COLOR PICKER (Ather UI) ───
            function Section:CreateColorpicker(text, default, callback, flag)
                callback = callback or function() end
                local color = default or Color3.fromRGB(255, 255, 255)
                local alpha = 1

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    BackgroundTransparency = 1,
                    Text = ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                local ColorBox = New("TextButton", {
                    Size = UDim2.new(0, 100, 0, 28),
                    Position = UDim2.new(1, -100, 0, 0),
                    BackgroundColor3 = color,
                    BackgroundTransparency = Window.Transparency,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ColorBox })
                New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = ColorBox })

                local HexLabel = New("TextLabel", {
                    Parent = ColorBox,
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Text = color:ToHex(),
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local isOpen = false
                local pickerFrame = New("Frame", {
                    Parent = UI.Holder and UI.Holder.Instance or ScreenGui,
                    Size = UDim2.new(0, 220, 0, 220),
                    Position = UDim2.new(0.5, -110, 0.5, -110),
                    BackgroundColor3 = Theme.Background,
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    Visible = false,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = pickerFrame })
                New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = pickerFrame })
                MakeDraggable(pickerFrame, pickerFrame)

                -- Color picker UI (simplified Ather style)
                -- Full color picker would be 500+ lines, this is a compact version
                local palette = New("Frame", {
                    Parent = pickerFrame,
                    Size = UDim2.new(1, -20, 1, -50),
                    Position = UDim2.new(0, 10, 0, 10),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                })
                New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = palette })

                -- Hue slider
                local hueSlider = New("Frame", {
                    Parent = pickerFrame,
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 1, -32),
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueSlider })
                New("UIGradient", {
                    Parent = hueSlider,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                    }
                })

                local function updatePicker()
                    local h, s, v = color:ToHSV()
                    palette.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    -- Update UI elements
                end

                ColorBox.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    pickerFrame.Visible = isOpen
                    if isOpen then
                        local pos = ColorBox.AbsolutePosition
                        pickerFrame.Position = UDim2.new(0, pos.X, 0, pos.Y + 34)
                        updatePicker()
                    end
                end)

                local handle = {
                    Set = function(_, c)
                        color = typeof(c) == "string" and Color3.fromHex(c) or c
                        ColorBox.BackgroundColor3 = color
                        HexLabel.Text = color:ToHex()
                        callback(color, alpha)
                    end,
                    Get = function() return color, alpha end,
                }
                if flag then
                    Window.Flags[flag] = handle
                    UI.Flags[flag] = handle
                end
                return handle
            end

            return Section
        end

        return Tab
    end

    --// ─── KEYBIND LIST (Ather UI) ───
    function Window:CreateKeybindList(title)
        local list = {}
        local frame = New("Frame", {
            Parent = ScreenGui,
            Name = "KeybindList",
            Size = UDim2.new(0, 220, 0, 30),
            Position = UDim2.new(0, 20, 0.5, 20),
            BackgroundColor3 = Theme.Section,
            BackgroundTransparency = Window.Transparency + 0.05,
            BorderSizePixel = 0,
            Visible = false,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
        New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = frame })
        MakeDraggable(frame, frame)

        local header = New("Frame", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Theme.Header,
            BackgroundTransparency = Window.Transparency + 0.05,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = header })

        local icon = New("ImageLabel", {
            Parent = header,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 10, 0.5, -9),
            Image = Assets.Icons.KeybindIcon,
            BackgroundTransparency = 1,
        })
        ApplyGradient(icon, Theme.AccentStart, Theme.AccentEnd)

        local titleLabel = New("TextLabel", {
            Parent = header,
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = ToRich(title or "Keybinds", Theme.Text),
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
        })

        local content = New("Frame", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 30),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
        })
        New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = content,
        })

        function list:Add(name, key)
            local row = New("TextButton", {
                Parent = content,
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
            })
            local label = New("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -60, 1, 0),
                BackgroundTransparency = 1,
                Text = ToRich(name .. " [" .. key .. "]", Theme.Text),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
            })
            local accent = New("Frame", {
                Parent = row,
                Size = UDim2.new(0, 6, 0, 6),
                Position = UDim2.new(1, -12, 0.5, -3),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accent })
            ApplyGradient(accent, Theme.AccentStart, Theme.AccentEnd)

            local item = {
                Set = function(_, name, key)
                    label.Text = ToRich(name .. " [" .. key .. "]", Theme.Text)
                end,
                SetStatus = function(_, bool)
                    Tween(accent, { BackgroundTransparency = bool and 0 or 1 }, 0.15)
                end,
            }
            return item
        end

        function list:SetVisibility(bool)
            frame.Visible = bool
        end

        return list
    end

    --// ─── WATERMARK (Samet UI) ───
    function Window:CreateWatermark(text)
        local frame = New("Frame", {
            Parent = ScreenGui,
            Name = "Watermark",
            Position = UDim2.new(0, 20, 0, 20),
            Size = UDim2.new(0, 0, 0, 32),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme.Section,
            BackgroundTransparency = Window.Transparency + 0.05,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
        New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = frame })
        MakeDraggable(frame, frame)

        local icon = New("ImageLabel", {
            Parent = frame,
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 10, 0.5, -9),
            Image = Assets.Icons.WatermarkIcon,
            BackgroundTransparency = 1,
        })
        ApplyGradient(icon, Theme.AccentStart, Theme.AccentEnd)

        local label = New("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = ToRich(text or "AetherUI", Theme.Text),
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
        })

        return frame
    end

    --// ─── GLOBAL CHAT (Samet UI) ───
    function Window:CreateGlobalChat(side)
        -- This is a simplified version of Samet's Global Chat
        -- Full version would be 500+ lines
        local chat = {}
        local frame = New("Frame", {
            Parent = side or ContentArea,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme.Section,
            BackgroundTransparency = Window.Transparency + 0.05,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
        New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.5, Parent = frame })

        local title = New("TextLabel", {
            Parent = frame,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Theme.Header,
            BackgroundTransparency = Window.Transparency + 0.05,
            Text = ToRich("GLOBAL CHAT", Theme.Text),
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
            RichText = true,
        })
        New("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = title })

        function chat:SendMessage(avatar, username, message, isLocal)
            -- Simplified message display
            local msg = New("Frame", {
                Parent = frame,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            })
            local nameLabel = New("TextLabel", {
                Parent = msg,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = ToRich(username, Theme.AccentStart),
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
            })
            local msgLabel = New("TextLabel", {
                Parent = msg,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 20),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = ToRich(message, Theme.TextDim),
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                RichText = true,
            })
        end

        return chat
    end

    --// ─── SETTINGS PAGE ───
    function Window:CreateSettingsPage()
        local page = Window:CreateTab("Settings")
        local section = page:CreateSection("Configs")

        local configDropdown = section:CreateDropdown("Config", UI:GetConfigList(), function(v) end)

        section:CreateTextbox("Config Name", function(v) end)
        section:CreateButton("Save", function()
            local name = "config"
            Window:SaveConfig(name)
            configDropdown:Refresh(UI:GetConfigList(), name)
        end)
        section:CreateButton("Load", function()
            local name = "config"
            Window:LoadConfig(name)
        end)
        section:CreateButton("Refresh", function()
            configDropdown:Refresh(UI:GetConfigList(), nil)
        end)

        local uiSection = page:CreateSection("UI")
        uiSection:CreateSlider("Transparency", 0, 0.5, Window.Transparency, function(v)
            Window:SetTransparency(v)
        end, 0.01)

        uiSection:CreateToggle("Watermark", function(v)
            if Window.Watermark then
                Window.Watermark.Visible = v
            end
        end)

        uiSection:CreateToggle("Keybind List", function(v)
            if Window.KeybindList then
                Window.KeybindList:SetVisibility(v)
            end
        end)

        return page
    end

    --// ─── SERVER HOP (Ather UI) ───
    function Window:ServerHop()
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local placeId = game.PlaceId
        local jobId = game.JobId

        Window:Notify({ Title = "Server Hop", Text = "Searching...", Duration = 1 })

        UI:Thread(function()
            local ok, data = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/0?sortOrder=Asc&limit=100"))
            end)

            if ok and data and data.data then
                for _, server in pairs(data.data) do
                    if server.id ~= jobId and server.playing and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(placeId, server.id)
                        return
                    end
                end
                Window:Notify({ Title = "Server Hop", Text = "No servers available", Duration = 2 })
            else
                Window:Notify({ Title = "Server Hop", Text = "Failed to fetch servers", Duration = 2 })
            end
        end)
    end

    --// ─── FINAL SETUP ───
    Window.Gui = ScreenGui
    Window.Frame = MainFrame
    Window.IsOpen = true

    -- Open the window with animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(MainFrame, { Size = size }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(MainFrame, { Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return Window
end

--// ─── UNLOAD ───
function UI:Unload()
    for _, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, thread in pairs(self.Threads) do
        pcall(function() coroutine.close(thread) end)
    end
    if self.Holder then
        pcall(function() self.Holder:Destroy() end)
    end
    if self.NotifHolder then
        pcall(function() self.NotifHolder:Destroy() end)
    end
    getgenv().AetherUI = nil
    self = nil
end

--// ─── EXPORT ───
getgenv().AetherUI = UI
return UI

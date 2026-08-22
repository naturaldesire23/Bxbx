-- PortalVisuals_UI_With_API.lua
-- Полная версия с экспортом API для расширения

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Очистка
if _G.PortalVisuals and _G.PortalVisuals._cleanup then
    _G.PortalVisuals._cleanup()
end

-- ============================================================
-- ГЛОБАЛЬНОЕ ХРАНИЛИЩЕ СОСТОЯНИЙ
-- ============================================================
_G.PortalVisuals = setmetatable({}, {
    __index = function(_, k)
        return rawget(_G.PortalVisuals, "_enabled_" .. k) or false
    end,
    __newindex = function(t, k, v)
        if type(k) ~= "string" then return end
        rawset(_G.PortalVisuals, "_enabled_" .. k, v)
        if v then
            if _G.PortalVisuals._enableFuncs and _G.PortalVisuals._enableFuncs[k] then
                task.spawn(_G.PortalVisuals._enableFuncs[k])
            end
        else
            if _G.PortalVisuals._disableFuncs and _G.PortalVisuals._disableFuncs[k] then
                task.spawn(_G.PortalVisuals._disableFuncs[k])
            end
        end
        if _G.PortalVisuals._listeners and _G.PortalVisuals._listeners[k] then
            for _, listener in ipairs(_G.PortalVisuals._listeners[k]) do
                task.spawn(listener, v)
            end
        end
    end
})

_G.PortalVisuals._enableFuncs = {}
_G.PortalVisuals._disableFuncs = {}
_G.PortalVisuals._listeners = {}
_G.PortalVisuals._keybinds = {}

-- ============================================================
-- ТЕМЫ
-- ============================================================
local Themes = {
    Light = {
        GlassBg = Color3.fromRGB(245, 248, 252), GlassLeft = Color3.fromRGB(240, 244, 250),
        GlassCard = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(0, 122, 255),
        Text = Color3.fromRGB(15, 20, 30), TextSoft = Color3.fromRGB(80, 90, 110),
        TextMuted = Color3.fromRGB(140, 150, 170), Online = Color3.fromRGB(50, 200, 100),
        TrackOff = Color3.fromRGB(200, 205, 215), TrackOn = Color3.fromRGB(0, 122, 255),
        StatValue = Color3.fromRGB(0, 100, 200), Stroke = Color3.fromRGB(255, 255, 255),
        Shine = Color3.fromRGB(255, 255, 255), Glow = Color3.fromRGB(100, 180, 255),
        Stars = false
    },
    Dark = {
        GlassBg = Color3.fromRGB(20, 22, 28), GlassLeft = Color3.fromRGB(25, 27, 35),
        GlassCard = Color3.fromRGB(35, 38, 48), Accent = Color3.fromRGB(0, 150, 255),
        Text = Color3.fromRGB(240, 245, 255), TextSoft = Color3.fromRGB(180, 190, 210),
        TextMuted = Color3.fromRGB(120, 130, 150), Online = Color3.fromRGB(50, 220, 120),
        TrackOff = Color3.fromRGB(60, 65, 80), TrackOn = Color3.fromRGB(0, 150, 255),
        StatValue = Color3.fromRGB(80, 170, 255), Stroke = Color3.fromRGB(60, 65, 80),
        Shine = Color3.fromRGB(255, 255, 255), Glow = Color3.fromRGB(0, 100, 200),
        Stars = false
    },
    Forest = {
        GlassBg = Color3.fromRGB(15, 30, 18), GlassLeft = Color3.fromRGB(20, 35, 22),
        GlassCard = Color3.fromRGB(28, 55, 35), Accent = Color3.fromRGB(50, 210, 75),
        Text = Color3.fromRGB(210, 245, 220), TextSoft = Color3.fromRGB(130, 175, 140),
        TextMuted = Color3.fromRGB(80, 125, 90), Online = Color3.fromRGB(70, 230, 100),
        TrackOff = Color3.fromRGB(45, 75, 50), TrackOn = Color3.fromRGB(50, 210, 75),
        StatValue = Color3.fromRGB(60, 200, 85), Stroke = Color3.fromRGB(40, 80, 48),
        Shine = Color3.fromRGB(160, 220, 170), Glow = Color3.fromRGB(25, 130, 45),
        Stars = false
    },
    Purple = {
        GlassBg = Color3.fromRGB(22, 18, 35), GlassLeft = Color3.fromRGB(28, 22, 45),
        GlassCard = Color3.fromRGB(40, 30, 65), Accent = Color3.fromRGB(160, 80, 255),
        Text = Color3.fromRGB(235, 225, 255), TextSoft = Color3.fromRGB(170, 150, 210),
        TextMuted = Color3.fromRGB(110, 90, 150), Online = Color3.fromRGB(120, 220, 140),
        TrackOff = Color3.fromRGB(55, 40, 80), TrackOn = Color3.fromRGB(160, 80, 255),
        StatValue = Color3.fromRGB(140, 100, 255), Stroke = Color3.fromRGB(60, 45, 90),
        Shine = Color3.fromRGB(200, 180, 255), Glow = Color3.fromRGB(90, 40, 180),
        Stars = false
    },
    Sunset = {
        GlassBg = Color3.fromRGB(35, 20, 18), GlassLeft = Color3.fromRGB(42, 25, 20),
        GlassCard = Color3.fromRGB(60, 32, 28), Accent = Color3.fromRGB(255, 140, 50),
        Text = Color3.fromRGB(255, 235, 220), TextSoft = Color3.fromRGB(210, 165, 140),
        TextMuted = Color3.fromRGB(160, 115, 95), Online = Color3.fromRGB(100, 220, 120),
        TrackOff = Color3.fromRGB(80, 45, 35), TrackOn = Color3.fromRGB(255, 140, 50),
        StatValue = Color3.fromRGB(255, 160, 70), Stroke = Color3.fromRGB(90, 50, 40),
        Shine = Color3.fromRGB(255, 200, 160), Glow = Color3.fromRGB(255, 100, 40),
        Stars = false
    },
    Cosmos = {
        GlassBg = Color3.fromRGB(6, 8, 20), GlassLeft = Color3.fromRGB(10, 12, 28),
        GlassCard = Color3.fromRGB(18, 22, 45), Accent = Color3.fromRGB(140, 200, 255),
        Text = Color3.fromRGB(220, 235, 255), TextSoft = Color3.fromRGB(150, 170, 210),
        TextMuted = Color3.fromRGB(80, 100, 150), Online = Color3.fromRGB(80, 230, 160),
        TrackOff = Color3.fromRGB(35, 40, 70), TrackOn = Color3.fromRGB(140, 200, 255),
        StatValue = Color3.fromRGB(120, 190, 255), Stroke = Color3.fromRGB(40, 55, 100),
        Shine = Color3.fromRGB(200, 220, 255), Glow = Color3.fromRGB(60, 100, 200),
        Stars = true, StarColor = Color3.fromRGB(200, 220, 255), StarCount = 80
    },
    Nebula = {
        GlassBg = Color3.fromRGB(10, 5, 22), GlassLeft = Color3.fromRGB(16, 8, 32),
        GlassCard = Color3.fromRGB(30, 12, 55), Accent = Color3.fromRGB(220, 110, 255),
        Text = Color3.fromRGB(240, 220, 255), TextSoft = Color3.fromRGB(185, 150, 220),
        TextMuted = Color3.fromRGB(120, 80, 160), Online = Color3.fromRGB(100, 230, 180),
        TrackOff = Color3.fromRGB(55, 25, 80), TrackOn = Color3.fromRGB(220, 110, 255),
        StatValue = Color3.fromRGB(200, 120, 255), Stroke = Color3.fromRGB(80, 35, 120),
        Shine = Color3.fromRGB(230, 180, 255), Glow = Color3.fromRGB(140, 50, 200),
        Stars = true, StarColor = Color3.fromRGB(255, 200, 255), StarCount = 100
    }
}

local Theme = Themes.Dark
local ThemeRegistry = {}
local ThemeListeners = {}
local ActiveStars = {}

local function RegisterThemeObject(Obj, Property, Key)
    table.insert(ThemeRegistry, {Object = Obj, Property = Property, Key = Key})
end

local function ClearStars()
    for _, star in ipairs(ActiveStars) do
        if star and star.Parent then star:Destroy() end
    end
    table.clear(ActiveStars)
end

local StarContainer = nil

local function SpawnStars(count, color)
    ClearStars()
    if not StarContainer then return end
    for i = 1, count do
        local star = Instance.new("Frame")
        star.BackgroundColor3 = color
        star.BorderSizePixel = 0
        local size = math.random(1, 3)
        star.Size = UDim2.new(0, size, 0, size)
        star.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        star.BackgroundTransparency = math.random(20, 70) / 100
        star.ZIndex = 1
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = star
        star.Parent = StarContainer
        table.insert(ActiveStars, star)
        task.spawn(function()
            local baseAlpha = star.BackgroundTransparency
            while star and star.Parent do
                local target = math.clamp(baseAlpha + math.random(-30, 30) / 100, 0.1, 0.9)
                TweenService:Create(star, TweenInfo.new(math.random(10, 25) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = target}):Play()
                task.wait(math.random(15, 35) / 10)
            end
        end)
    end
end

local function SetTheme(Name)
    local New = Themes[Name]
    if not New then return end
    Theme = New
    for _, Entry in ipairs(ThemeRegistry) do
        if Entry.Object and Entry.Object.Parent then
            TweenService:Create(Entry.Object, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {[Entry.Property] = New[Entry.Key]}):Play()
        end
    end
    for _, listener in pairs(ThemeListeners) do
        if listener then task.spawn(listener, New) end
    end
    if New.Stars and New.StarCount and New.StarColor then
        task.delay(0.1, function() SpawnStars(New.StarCount, New.StarColor) end)
    else
        ClearStars()
    end
end

-- ============================================================
-- УТИЛИТЫ
-- ============================================================
local Utility = {}
function Utility:Create(Class, Props)
    local Obj = Instance.new(Class)
    for K, V in pairs(Props) do
        if K ~= "Parent" then Obj[K] = V end
    end
    if Props.Parent then Obj.Parent = Props.Parent end
    return Obj
end

function Utility:Tween(Obj, Props, Dur, Style, Dir)
    local T = TweenService:Create(Obj, TweenInfo.new(Dur or 0.6, Style or Enum.EasingStyle.Quint, Dir or Enum.EasingDirection.Out), Props)
    T:Play()
    return T
end

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

local ScreenGui = Utility:Create("ScreenGui", {
    Name = "PortalFinal",
    Parent = CoreGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999
})

local WatermarkGui = Utility:Create("ScreenGui", {
    Name = "PortalWatermark",
    Parent = CoreGui,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100000
})

-- ============================================================
-- WATERMARK
-- ============================================================
local WMCard = Utility:Create("Frame", {
    Name = "Card",
    Parent = WatermarkGui,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 4),
    Size = UDim2.new(0, 300, 0, 32),
    BackgroundColor3 = Theme.GlassBg,
    BackgroundTransparency = 0.92,
    BorderSizePixel = 0,
    ZIndex = 100
})
RegisterThemeObject(WMCard, "BackgroundColor3", "GlassBg")
Utility:Create("UICorner", {Parent = WMCard, CornerRadius = UDim.new(0, 12)})

local WMStroke = Utility:Create("UIStroke", {Parent = WMCard, Color = Theme.Stroke, Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
RegisterThemeObject(WMStroke, "Color", "Stroke")

local WMDot = Utility:Create("Frame", {Parent = WMCard, BackgroundColor3 = Color3.fromRGB(0, 200, 100), BorderSizePixel = 0, Position = UDim2.new(0, 10, 0.5, -3), Size = UDim2.new(0, 6, 0, 6), ZIndex = 103})
Utility:Create("UICorner", {Parent = WMDot, CornerRadius = UDim.new(1, 0)})

local WMLogo = Utility:Create("TextLabel", {Parent = WMCard, BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(0, 82, 1, 0), Font = Enum.Font.GothamBold, Text = "Portal Visuals", TextColor3 = Theme.Text, TextSize = 12, TextTransparency = 0.05, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102})
RegisterThemeObject(WMLogo, "TextColor3", "Text")

local WMSep = Utility:Create("TextLabel", {Parent = WMCard, BackgroundTransparency = 1, Position = UDim2.new(0, 104, 0, 0), Size = UDim2.new(0, 10, 1, 0), Font = Enum.Font.GothamMedium, Text = "|", TextColor3 = Theme.TextMuted, TextSize = 12, TextTransparency = 0.3, ZIndex = 102})
RegisterThemeObject(WMSep, "TextColor3", "TextMuted")

local WMStats = Utility:Create("TextLabel", {Parent = WMCard, BackgroundTransparency = 1, Position = UDim2.new(0, 114, 0, 0), Size = UDim2.new(1, -122, 1, 0), Font = Enum.Font.GothamMedium, Text = "... ms | ... FPS", TextColor3 = Theme.Text, TextSize = 12, TextTransparency = 0.1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102})
RegisterThemeObject(WMStats, "TextColor3", "Text")

task.spawn(function()
    local FPS = 0
    local Frames = 0
    local Last = tick()
    while WatermarkGui and WatermarkGui.Parent do
        RunService.RenderStepped:Wait()
        Frames = Frames + 1
        local Now = tick()
        if Now - Last >= 1 then
            FPS = Frames
            Frames = 0
            Last = Now
            local ok, val = pcall(function() return Stats.PerformanceStats.Ping:GetValue() end)
            local Ping = ok and math.floor(val) or 0
            WMStats.Text = tostring(Ping) .. " ms | " .. tostring(FPS) .. " FPS"
        end
    end
end)

-- ============================================================
-- ОСНОВНОЕ МЕНЮ
-- ============================================================
local Main = Utility:Create("Frame", {
    Name = "Main",
    Parent = ScreenGui,
    BackgroundColor3 = Theme.GlassBg,
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, -360, 0.5, -280),
    Size = UDim2.new(0, 720, 0, 560),
    Active = true,
    Visible = false,
    ClipsDescendants = true
})
RegisterThemeObject(Main, "BackgroundColor3", "GlassBg")

Utility:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 42)})
local MainStroke = Utility:Create("UIStroke", {Parent = Main, Color = Theme.Stroke, Thickness = 2, Transparency = 0.5})

StarContainer = Utility:Create("Frame", {
    Parent = Main,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    ZIndex = 0,
    ClipsDescendants = true
})

local BackgroundImage = Utility:Create("ImageLabel", {
    Parent = Main,
    Name = "BackgroundAsset",
    BackgroundTransparency = 1,
    Image = "",
    ImageTransparency = 1,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0)
})

local function UpdateBackgroundSize()
    if not Main or not BackgroundImage then return end
    local s = Main.AbsoluteSize
    if s.X == 0 or s.Y == 0 then return end
    BackgroundImage.Size = UDim2.new(0, s.X, 0, s.Y)
    BackgroundImage.Position = UDim2.new(0, 0, 0, 0)
end

local layoutConn
layoutConn = RunService.Heartbeat:Connect(function()
    if Main.AbsoluteSize.X > 0 then
        UpdateBackgroundSize()
        layoutConn:Disconnect()
    end
end)

Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateBackgroundSize)

local function NormalizeAssetId(raw)
    local s = tostring(raw):match("^%s*(.-)%s*$")
    if s == "" or s == "0" then return nil end
    if s:match("^rbxassetid://%d+$") then return s end
    if s:match("^%d+$") then return "rbxassetid://" .. s end
    local id = s:match("(%d+)")
    if id and #id >= 6 then return "rbxassetid://" .. id end
    return nil
end

local function SetBackgroundAsset(raw)
    local uri = NormalizeAssetId(raw)
    if not uri then
        Utility:Tween(BackgroundImage, {ImageTransparency = 1}, 0.4, Enum.EasingStyle.Quint)
        task.delay(0.45, function() BackgroundImage.Image = "" end)
        return
    end
    BackgroundImage.Image = uri
    UpdateBackgroundSize()
    Utility:Tween(BackgroundImage, {ImageTransparency = 0.45}, 0.4, Enum.EasingStyle.Quint)
end

local SetBackgroundMedia = SetBackgroundAsset

local InnerContainer = Utility:Create("Frame", {Parent = Main, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 2})
local Shine = Utility:Create("Frame", {Parent = InnerContainer, BackgroundColor3 = Theme.Shine, BackgroundTransparency = 0.92, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 0.45), ZIndex = 10})
Utility:Create("UIGradient", {Parent = Shine, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.35, 0.85), NumberSequenceKeypoint.new(1, 1)})})

local LeftPanel = Utility:Create("Frame", {Parent = InnerContainer, BackgroundColor3 = Theme.GlassLeft, BackgroundTransparency = 0.88, BorderSizePixel = 0, Size = UDim2.new(0, 220, 1, 0), Active = true, ZIndex = 3})
RegisterThemeObject(LeftPanel, "BackgroundColor3", "GlassLeft")
Utility:Create("UICorner", {Parent = LeftPanel, CornerRadius = UDim.new(0, 42)})

local Separator = Utility:Create("Frame", {
    Parent = LeftPanel,
    BackgroundColor3 = Theme.Stroke,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -2, 0, 20),
    Size = UDim2.new(0, 2, 1, -40),
    ZIndex = 4
})
RegisterThemeObject(Separator, "BackgroundColor3", "Stroke")

local Title = Utility:Create("TextLabel", {Parent = LeftPanel, BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 28), Size = UDim2.new(1, -40, 0, 30), Font = Enum.Font.GothamBlack, Text = "Portal Visuals", TextColor3 = Theme.Text, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
RegisterThemeObject(Title, "TextColor3", "Text")
local SubTitle = Utility:Create("TextLabel", {Parent = LeftPanel, BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 58), Size = UDim2.new(1, -40, 0, 14), Font = Enum.Font.Gotham, Text = "RECOVERY ENV", TextColor3 = Theme.TextMuted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5})
RegisterThemeObject(SubTitle, "TextColor3", "TextMuted")

local TabsHolder = Utility:Create("Frame", {Parent = LeftPanel, BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 110), Size = UDim2.new(1, -56, 0, 160), ZIndex = 5})
local Tabs = {}
local CurrentTab = nil
local Pages = {}

local function AddTab(Name, Page)
    local Btn = Utility:Create("TextButton", {Parent = TabsHolder, Name = Name, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, #Tabs * 58), Size = UDim2.new(1, -56, 0, 48), Font = Enum.Font.GothamBold, Text = Name, TextColor3 = Theme.TextSoft, TextSize = 16, AutoButtonColor = false, ZIndex = 6})
    RegisterThemeObject(Btn, "TextColor3", "TextSoft")
    local Ind = Utility:Create("Frame", {Parent = Btn, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Position = UDim2.new(0, -12, 0.5, -4), Size = UDim2.new(0, 6, 0, 8), BackgroundTransparency = 1, ZIndex = 7})
    RegisterThemeObject(Ind, "BackgroundColor3", "Accent")
    Utility:Create("UICorner", {Parent = Ind, CornerRadius = UDim.new(1, 0)})
    table.insert(Tabs, {Name = Name, Button = Btn, Indicator = Ind, Page = Page})
    Pages[Name] = Page
    Btn.MouseEnter:Connect(function()
        if CurrentTab ~= Name then Utility:Tween(Btn, {TextColor3 = Theme.Text}, 0.4, Enum.EasingStyle.Sine) end
    end)
    Btn.MouseLeave:Connect(function()
        if CurrentTab ~= Name then Utility:Tween(Btn, {TextColor3 = Theme.TextSoft}, 0.4, Enum.EasingStyle.Sine) end
    end)
    Btn.MouseButton1Click:Connect(function()
        if CurrentTab == Name then return end
        for _, T in ipairs(Tabs) do
            if T.Name == CurrentTab then
                Utility:Tween(T.Button, {TextColor3 = Theme.TextSoft}, 0.5, Enum.EasingStyle.Quint)
                Utility:Tween(T.Indicator, {BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Quint)
                if T.Page then T.Page.Visible = false end
            end
        end
        CurrentTab = Name
        Utility:Tween(Btn, {TextColor3 = Theme.Text}, 0.5, Enum.EasingStyle.Quint)
        Utility:Tween(Ind, {BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Quint)
        if Page then
            Page.CanvasPosition = Vector2.new(0, 0)
            Page.Visible = true
            Page.Position = UDim2.new(0, 80, 0, 0)
            Utility:Tween(Page, {Position = UDim2.new(0, 0, 0, 0)}, 0.5, Enum.EasingStyle.Quint)
        end
    end)
end

local ProfileBtn = Utility:Create("TextButton", {Parent = LeftPanel, Name = "Profile", BackgroundTransparency = 1, Position = UDim2.new(0, 28, 1, -76), Size = UDim2.new(1, -56, 0, 54), Text = "", AutoButtonColor = false, ZIndex = 5})
local AvatarBg = Utility:Create("Frame", {Parent = ProfileBtn, BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.6, Size = UDim2.new(0, 42, 0, 42), ZIndex = 6})
RegisterThemeObject(AvatarBg, "BackgroundColor3", "GlassCard")
Utility:Create("UICorner", {Parent = AvatarBg, CornerRadius = UDim.new(1, 0)})
local AvatarStroke = Utility:Create("UIStroke", {Parent = AvatarBg, Color = Theme.Stroke, Thickness = 1.5, Transparency = 0.5})
RegisterThemeObject(AvatarStroke, "Color", "Stroke")
local AvatarImg = Utility:Create("ImageLabel", {Parent = AvatarBg, BackgroundTransparency = 1, Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(1, -4, 1, -4), Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png", ZIndex = 7})
Utility:Create("UICorner", {Parent = AvatarImg, CornerRadius = UDim.new(1, 0)})
local ProfileName = Utility:Create("TextLabel", {Parent = ProfileBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 54, 0, 2), Size = UDim2.new(1, -64, 0, 20), Font = Enum.Font.GothamBold, Text = "@" .. LocalPlayer.Name, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
RegisterThemeObject(ProfileName, "TextColor3", "Text")
local ProfileStatus = Utility:Create("TextLabel", {Parent = ProfileBtn, BackgroundTransparency = 1, Position = UDim2.new(0, 54, 0, 24), Size = UDim2.new(1, -64, 0, 14), Font = Enum.Font.Gotham, Text = "Online", TextColor3 = Theme.Online, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
RegisterThemeObject(ProfileStatus, "TextColor3", "Online")
ProfileBtn.MouseEnter:Connect(function()
    Utility:Tween(AvatarBg, {BackgroundTransparency = 0.3}, 0.3, Enum.EasingStyle.Sine)
    Utility:Tween(AvatarStroke, {Transparency = 0.3}, 0.3, Enum.EasingStyle.Sine)
end)
ProfileBtn.MouseLeave:Connect(function()
    Utility:Tween(AvatarBg, {BackgroundTransparency = 0.6}, 0.3, Enum.EasingStyle.Sine)
    Utility:Tween(AvatarStroke, {Transparency = 0.5}, 0.3, Enum.EasingStyle.Sine)
end)

local ContentArea = Utility:Create("Frame", {Parent = InnerContainer, BackgroundTransparency = 1, Position = UDim2.new(0, 220, 0, 0), Size = UDim2.new(1, -220, 1, 0), ClipsDescendants = true, ZIndex = 3})

local function CreatePage(Name)
    local Page = Utility:Create("ScrollingFrame", {Parent = ContentArea, Name = Name.."Page", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.TextMuted, Visible = false, ZIndex = 4})
    RegisterThemeObject(Page, "ScrollBarImageColor3", "TextMuted")
    local List = Utility:Create("UIListLayout", {Parent = Page, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder})
    Utility:Create("UIPadding", {Parent = Page, PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20)})
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 40)
    end)
    return Page
end

local MainPage = CreatePage("Main")
local VisualsPage = CreatePage("Visuals")
local SettingsPage = CreatePage("Settings")
AddTab("Main", MainPage)
AddTab("Visuals", VisualsPage)
AddTab("Settings", SettingsPage)

local function CreateSection(Parent, TitleText)
    local Section = Utility:Create("Frame", {Parent = Parent, BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.78, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #Parent:GetChildren() + 1, ZIndex = 5})
    RegisterThemeObject(Section, "BackgroundColor3", "GlassCard")
    Utility:Create("UICorner", {Parent = Section, CornerRadius = UDim.new(0, 30)})
    Utility:Create("UIStroke", {Parent = Section, Color = Theme.Stroke, Thickness = 1.5, Transparency = 0.6})
    local ShineS = Utility:Create("Frame", {Parent = Section, BackgroundColor3 = Theme.Shine, BackgroundTransparency = 0.88, Size = UDim2.new(1, 0, 0, 0.5), ZIndex = 6})
    Utility:Create("UIGradient", {Parent = ShineS, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.65), NumberSequenceKeypoint.new(1, 1)})})
    local Ind = Utility:Create("Frame", {Parent = Section, BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 18, 0, 18), Size = UDim2.new(0, 4, 0, 20), ZIndex = 7})
    RegisterThemeObject(Ind, "BackgroundColor3", "Accent")
    Utility:Create("UICorner", {Parent = Ind, CornerRadius = UDim.new(1, 0)})
    Utility:Create("TextLabel", {Parent = Section, BackgroundTransparency = 1, Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(1, -50, 0, 56), Font = Enum.Font.GothamBold, Text = TitleText, TextColor3 = Theme.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7})
    local Content = Utility:Create("Frame", {Parent = Section, BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 56), Size = UDim2.new(1, -36, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 7})
    Utility:Create("UIListLayout", {Parent = Content, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    Utility:Create("UIPadding", {Parent = Content, PaddingBottom = UDim.new(0, 16)})
    return Content
end

local function CreateToggle(Parent, LabelText, EffectName, DefaultState)
    local Frame = Utility:Create("Frame", {Parent = Parent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = #Parent:GetChildren() + 1})
    local Label = Utility:Create("TextLabel", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1, -120, 1, 0), Font = Enum.Font.Gotham, Text = LabelText, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    RegisterThemeObject(Label, "TextColor3", "Text")
    local Default = DefaultState or false
    local Track = Utility:Create("Frame", {Parent = Frame, BackgroundColor3 = Default and Theme.TrackOn or Theme.TrackOff, BorderSizePixel = 0, Position = UDim2.new(1, -50, 0.5, -13), Size = UDim2.new(0, 50, 0, 26), ZIndex = 6})
    RegisterThemeObject(Track, "BackgroundColor3", Default and "TrackOn" or "TrackOff")
    Utility:Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
    local Thumb = Utility:Create("Frame", {Parent = Track, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Position = Default and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11), Size = UDim2.new(0, 22, 0, 22), ZIndex = 7})
    Utility:Create("UICorner", {Parent = Thumb, CornerRadius = UDim.new(1, 0)})
    local Enabled = Default
    local Debounce = false
    local function UpdateVisual()
        if Enabled then
            Utility:Tween(Track, {BackgroundColor3 = Theme.TrackOn}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Utility:Tween(Thumb, {Position = UDim2.new(1, -24, 0.5, -11)}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            Utility:Tween(Track, {BackgroundColor3 = Theme.TrackOff}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Utility:Tween(Thumb, {Position = UDim2.new(0, 2, 0.5, -11)}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end
    Track.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        if Debounce then return end
        Debounce = true
        Enabled = not Enabled
        _G.PortalVisuals[EffectName] = Enabled
        UpdateVisual()
        task.wait(0.5)
        Debounce = false
    end)
    table.insert(ThemeListeners, function() UpdateVisual() end)
    return Frame, {SetState = function(val) Enabled = val; UpdateVisual() end}
end

local function CreateSlider(Parent, LabelText, Min, Max, Default, Callback)
    local Frame = Utility:Create("Frame", {Parent = Parent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = #Parent:GetChildren() + 1})
    local Label = Utility:Create("TextLabel", {Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 4, 0, 0), Size = UDim2.new(0.5, -4, 0, 20), Font = Enum.Font.Gotham, Text = LabelText, TextColor3 = Theme.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7})
    RegisterThemeObject(Label, "TextColor3", "TextMuted")
    local ValueLabel = Utility:Create("TextLabel", {Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0.5, 4, 0, 0), Size = UDim2.new(0.5, -8, 0, 20), Font = Enum.Font.GothamBold, Text = tostring(Default), TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7})
    RegisterThemeObject(ValueLabel, "TextColor3", "Text")
    local Track = Utility:Create("Frame", {Parent = Frame, BackgroundColor3 = Theme.TrackOff, BorderSizePixel = 0, Position = UDim2.new(0, 4, 0, 24), Size = UDim2.new(1, -8, 0, 6), ZIndex = 7})
    RegisterThemeObject(Track, "BackgroundColor3", "TrackOff")
    Utility:Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
    local Fill = Utility:Create("Frame", {Parent = Track, BackgroundColor3 = Theme.TrackOn, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0), ZIndex = 8})
    RegisterThemeObject(Fill, "BackgroundColor3", "TrackOn")
    Utility:Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
    local Thumb = Utility:Create("Frame", {Parent = Track, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Position = UDim2.new((Default - Min) / (Max - Min), -8, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), ZIndex = 9})
    Utility:Create("UICorner", {Parent = Thumb, CornerRadius = UDim.new(1, 0)})
    Utility:Create("UIStroke", {Parent = Thumb, Color = Theme.TrackOn, Thickness = 1.5})
    local dragging = false
    local function updateSlider(val)
        local clamped = math.clamp(val, Min, Max)
        local alpha = (clamped - Min) / (Max - Min)
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        Thumb.Position = UDim2.new(alpha, -8, 0.5, -8)
        ValueLabel.Text = string.format("%.2f", clamped)
        if Callback then Callback(clamped) end
    end
    local function inputToVal(input)
        local abs = input.Position.X - Track.AbsolutePosition.X
        local alpha = math.clamp(abs / Track.AbsoluteSize.X, 0, 1)
        return Min + (Max - Min) * alpha
    end
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(inputToVal(input))
        end
    end)
    Thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inputToVal(input))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return Frame
end

local function CreateTextBox(Parent, LabelText, Placeholder, DefaultText, Callback)
    local Frame = Utility:Create("Frame", {Parent = Parent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = #Parent:GetChildren() + 1})
    local Label = Utility:Create("TextLabel", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(0.4, -4, 1, 0), Font = Enum.Font.Gotham, Text = LabelText, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    RegisterThemeObject(Label, "TextColor3", "Text")
    local Box = Utility:Create("TextBox", {Parent = Frame, BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.new(0.4, 0, 0.5, -15), Size = UDim2.new(0.6, 0, 0, 30), Font = Enum.Font.GothamBold, PlaceholderText = Placeholder, Text = DefaultText or "", TextColor3 = Theme.Text, TextSize = 13, ZIndex = 6})
    RegisterThemeObject(Box, "BackgroundColor3", "GlassCard")
    RegisterThemeObject(Box, "TextColor3", "Text")
    Utility:Create("UICorner", {Parent = Box, CornerRadius = UDim.new(0, 14)})
    Utility:Create("UIStroke", {Parent = Box, Color = Theme.Stroke, Thickness = 1.5, Transparency = 0.6})
    Box.FocusLost:Connect(function()
        if Callback then Callback(Box.Text) end
    end)
    return Frame
end

local function CreateKeybind(Parent, LabelText, DefaultKey, Callback)
    local Frame = Utility:Create("Frame", {Parent = Parent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = #Parent:GetChildren() + 1})
    local Label = Utility:Create("TextLabel", {Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1, -120, 1, 0), Font = Enum.Font.Gotham, Text = LabelText, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6})
    RegisterThemeObject(Label, "TextColor3", "Text")
    local CurrentKey = DefaultKey
    local KeyBtn = Utility:Create("TextButton", {Parent = Frame, BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.new(1, -110, 0.5, -15), Size = UDim2.new(0, 100, 0, 30), Font = Enum.Font.GothamBold, Text = CurrentKey.Name, TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false, ZIndex = 6})
    RegisterThemeObject(KeyBtn, "BackgroundColor3", "GlassCard")
    RegisterThemeObject(KeyBtn, "TextColor3", "Text")
    Utility:Create("UICorner", {Parent = KeyBtn, CornerRadius = UDim.new(0, 14)})
    Utility:Create("UIStroke", {Parent = KeyBtn, Color = Theme.Accent, Thickness = 1.5, Transparency = 0.4})
    local waiting = false
    KeyBtn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting = true
        KeyBtn.Text = "..."
        Utility:Tween(KeyBtn, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.1}, 0.3)
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if _G.PortalVisuals._keybinds[CurrentKey] then
                    _G.PortalVisuals._keybinds[CurrentKey] = nil
                end
                CurrentKey = input.KeyCode
                KeyBtn.Text = CurrentKey.Name
                _G.PortalVisuals._keybinds[CurrentKey] = Callback
            end
            if conn then conn:Disconnect() end
            waiting = false
            Utility:Tween(KeyBtn, {BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.4}, 0.3)
        end)
    end)
    _G.PortalVisuals._keybinds[CurrentKey] = Callback
    return Frame
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local bind = _G.PortalVisuals._keybinds[input.KeyCode]
        if bind then
            task.spawn(bind, input.KeyCode)
        end
    end
end)

local NotifyGui = Utility:Create("ScreenGui", {
    Name = "PortalNotifications",
    Parent = CoreGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 9999
})

local NotifyHolder = Utility:Create("Frame", {
    Parent = NotifyGui,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -20, 1, -20),
    AnchorPoint = Vector2.new(1, 1),
    Size = UDim2.new(0, 320, 0, 600),
    ZIndex = 200,
    ClipsDescendants = false
})

Utility:Create("UIListLayout", {
    Parent = NotifyHolder,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    FillDirection = Enum.FillDirection.Vertical
})

local NotifyCount = 0

local function Notify(title, body, duration)
    duration = duration or 3
    NotifyCount = NotifyCount + 1
    local order = NotifyCount

    local CARD_W = 300
    local CARD_H = 72

    local Wrapper = Utility:Create("Frame", {
        Parent = NotifyHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, CARD_W, 0, CARD_H),
        LayoutOrder = order,
        ClipsDescendants = false
    })

    local Card = Utility:Create("Frame", {
        Parent = Wrapper,
        BackgroundColor3 = Theme.GlassCard,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(0, CARD_W, 0, CARD_H),
        Position = UDim2.new(0, CARD_W + 20, 0, 0),
        ClipsDescendants = true,
        ZIndex = 201
    })
    Utility:Create("UICorner", {Parent = Card, CornerRadius = UDim.new(0, 14)})

    local AccentBar = Utility:Create("Frame", {
        Parent = Card,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
        ZIndex = 203
    })
    Utility:Create("UICorner", {Parent = AccentBar, CornerRadius = UDim.new(0, 4)})

    local ProgressBg = Utility:Create("Frame", {
        Parent = Card,
        BackgroundColor3 = Theme.TrackOff,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 1, -4),
        Size = UDim2.new(1, -8, 0, 2),
        ZIndex = 203
    })
    Utility:Create("UICorner", {Parent = ProgressBg, CornerRadius = UDim.new(1, 0)})

    local ProgressFill = Utility:Create("Frame", {
        Parent = ProgressBg,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 204
    })
    Utility:Create("UICorner", {Parent = ProgressFill, CornerRadius = UDim.new(1, 0)})

    local TitleLabel = Utility:Create("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 10),
        Size = UDim2.new(1, -24, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202
    })

    local BodyLabel = Utility:Create("TextLabel", {
        Parent = Card,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 33),
        Size = UDim2.new(1, -24, 0, 28),
        Font = Enum.Font.Gotham,
        Text = body,
        TextColor3 = Theme.TextSoft,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 202
    })

    Utility:Create("UIStroke", {
        Parent = Card,
        Color = Theme.Stroke,
        Thickness = 1,
        Transparency = 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

    TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 1, 0)}):Play()

    local dismissed = false
    local function Dismiss()
        if dismissed then return end
        dismissed = true
        TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, CARD_W + 20, 0, 0), BackgroundTransparency = 1}):Play()
        TweenService:Create(TitleLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        TweenService:Create(BodyLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
        task.delay(0.3, function()
            TweenService:Create(Wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(0, CARD_W, 0, 0)}):Play()
            task.delay(0.3, function()
                Wrapper:Destroy()
            end)
        end)
    end

    Card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dismiss()
        end
    end)

    task.delay(duration, Dismiss)
end

-- ============================================================
-- СТАНДАРТНЫЕ ВКЛАДКИ
-- ============================================================
local MContent = CreateSection(MainPage, "Actions")

local function RandomFunction()
    local randomNum = math.random(1, 100)
    Notify("Random Function", "Triggered: " .. tostring(randomNum), 3)
end

CreateKeybind(MContent, "Trigger Random Function", Enum.KeyCode.R, function()
    RandomFunction()
end)

local VContent = CreateSection(VisualsPage, "Visual Options")
local _, RainToggle = CreateToggle(VContent, "Enable Rain Particles", "RainEffect", false)

CreateKeybind(VContent, "Toggle Rain Bind", Enum.KeyCode.T, function()
    local newState = not _G.PortalVisuals.RainEffect
    _G.PortalVisuals.RainEffect = newState
    RainToggle.SetState(newState)
    Notify("Rain Visual", newState and "Enabled" or "Disabled", 3)
end)

CreateSlider(VContent, "Rain Intensity", 10, 100, 45, function(val) print("Rain set to: " .. val) end)

local SContent = CreateSection(SettingsPage, "Settings Options")
CreateTextBox(SContent, "Custom Webhook", "URL...", "", function(text) print("Webhook set: " .. text) end)
CreateSlider(SContent, "Max Particle Count", 100, 1000, 500, function(val) print("Particle cap: " .. val) end)

-- ============================================================
-- МЕНЮ КЛЮЧ
-- ============================================================
local MenuKey = Enum.KeyCode.K
local IsOpen = true
local blurTween = nil
local menuTween = nil

local function ToggleUI()
    if blurTween then blurTween:Cancel() end
    if menuTween then menuTween:Cancel() end
    IsOpen = not IsOpen
    if IsOpen then
        Main.Visible = true
        blurTween = Utility:Tween(Blur, {Size = 20}, 0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        menuTween = Utility:Tween(Main, {Size = UDim2.new(0, 720, 0, 560), Position = UDim2.new(0.5, -360, 0.5, -280), BackgroundTransparency = 0.82}, 0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        UpdateBackgroundSize()
    else
        blurTween = Utility:Tween(Blur, {Size = 0}, 0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        menuTween = Utility:Tween(Main, {Size = UDim2.new(0, 720, 0, 0), BackgroundTransparency = 1}, 0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        menuTween.Completed:Connect(function() if not IsOpen then Main.Visible = false end end)
    end
end

_G.PortalVisuals._keybinds[MenuKey] = ToggleUI

-- ============================================================
-- НАСТРОЙКИ (РАСШИРЕННЫЕ)
-- ============================================================
local BGSection = CreateSection(SettingsPage, "Background Asset")
CreateTextBox(BGSection, "Asset ID", "e.g. 12345678", "", function(text) SetBackgroundAsset(text) end)
CreateTextBox(BGSection, "Media URL / ID", "rbxassetid or numeric ID", "", function(text) SetBackgroundMedia(text) end)

local ThemeSection = CreateSection(SettingsPage, "Theme Switcher")
for name, _ in pairs(Themes) do
    local Frame = Utility:Create("Frame", {Parent = ThemeSection, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = #ThemeSection:GetChildren() + 1})
    local hasStar = Themes[name].Stars
    local label = hasStar and ("✦ " .. name) or name
    local Btn = Utility:Create("TextButton", {Parent = Frame, BackgroundColor3 = Theme.GlassCard, BackgroundTransparency = 0.6, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, Text = label, TextColor3 = Theme.Text, TextSize = 14, AutoButtonColor = false, ZIndex = 6})
    RegisterThemeObject(Btn, "BackgroundColor3", "GlassCard")
    RegisterThemeObject(Btn, "TextColor3", "Text")
    Utility:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 20)})
    Utility:Create("UIStroke", {Parent = Btn, Color = Theme.Stroke, Thickness = 1.5, Transparency = 0.6})
    Btn.MouseButton1Click:Connect(function()
        SetTheme(name)
        Notify("Theme", name .. " applied", 2)
    end)
end

local MenuKeybindFrame = CreateKeybind(SContent, "Toggle Menu Key", Enum.KeyCode.J, function(key)
    _G.PortalVisuals._keybinds[MenuKey] = nil
    MenuKey = key
    _G.PortalVisuals._keybinds[MenuKey] = ToggleUI
end)

-- ============================================================
-- ЗАПУСК
-- ============================================================
Main.Visible = true
Main.Size = UDim2.new(0, 720, 0, 0)
Utility:Tween(Blur, {Size = 20}, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
Utility:Tween(Main, {Size = UDim2.new(0, 720, 0, 560), Position = UDim2.new(0.5, -360, 0.5, -280), BackgroundTransparency = 0.82}, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

if Tabs[1] then
    CurrentTab = Tabs[1].Name
    Tabs[1].Button.TextColor3 = Theme.Text
    Tabs[1].Indicator.BackgroundTransparency = 0
    if Tabs[1].Page then Tabs[1].Page.Visible = true end
end

-- ============================================================
-- ЭКСПОРТ API ДЛЯ РАСШИРЕНИЯ
-- ============================================================
_G.PortalVisuals._addTab = function(name)
    local page = CreatePage(name)
    AddTab(name, page)
    return page
end

_G.PortalVisuals._createSection = function(parent, title)
    return CreateSection(parent, title)
end

_G.PortalVisuals._toggle = function(parent, label, key, default)
    local frame, control = CreateToggle(parent, label, key, default)
    return frame, control
end

_G.PortalVisuals._slider = function(parent, label, min, max, default, callback)
    return CreateSlider(parent, label, min, max, default, callback)
end

_G.PortalVisuals._textbox = function(parent, label, placeholder, default, callback)
    return CreateTextBox(parent, label, placeholder, default, callback)
end

_G.PortalVisuals._keybind = function(parent, label, defaultKey, callback)
    return CreateKeybind(parent, label, defaultKey, callback)
end

_G.PortalVisuals._notify = function(title, body, duration)
    Notify(title, body, duration)
end

_G.PortalVisuals._settingsPage = SettingsPage
_G.PortalVisuals._mainPage = MainPage
_G.PortalVisuals._visualsPage = VisualsPage

-- ============================================================
-- ОЧИСТКА
-- ============================================================
_G.PortalVisuals._cleanup = function()
    ClearStars()
    if layoutConn then layoutConn:Disconnect() end
    if ScreenGui then ScreenGui:Destroy() end
    if WatermarkGui then WatermarkGui:Destroy() end
    if Blur then Blur:Destroy() end
    if NotifyGui then NotifyGui:Destroy() end
    table.clear(_G.PortalVisuals._keybinds)
end

task.delay(1.4, function()
    Notify("Portal Visuals", "Recovery Engine Initialized", 4)
end)

print("=== PortalVisuals UI Loaded ===")
print("API exported to _G.PortalVisuals")
print("Available methods: _addTab, _createSection, _toggle, _slider, _textbox, _keybind, _notify")

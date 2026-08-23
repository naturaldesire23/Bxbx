-- PortalVisuals_Lib.lua  v2.0
-- UI Library — loadstring-compatible, full public API
-- Usage:
--   local PV = loadstring(game:HttpGet("YOUR_RAW_URL"))()
--   local win = PV.new("My Hub")
--   local tab = win:Tab("Combat")
--   local sec = tab:Section("Aimbot")
--   sec:Toggle("Silent Aim", "SilentAim", false)
--   sec:Slider("FOV", 1, 360, 90, function(v) ... end)

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- INTERNAL STATE CLEANUP
-- ============================================================
if _G._PortalVisualsLib and _G._PortalVisualsLib._cleanup then
    pcall(_G._PortalVisualsLib._cleanup)
end
_G._PortalVisualsLib = {}
local _lib = _G._PortalVisualsLib

-- ============================================================
-- THEMES
-- ============================================================
local Themes = {
    Dark = {
        GlassBg   = Color3.fromRGB(20, 22, 28),    GlassLeft = Color3.fromRGB(25, 27, 35),
        GlassCard  = Color3.fromRGB(35, 38, 48),    Accent    = Color3.fromRGB(0, 150, 255),
        Text       = Color3.fromRGB(240, 245, 255),  TextSoft  = Color3.fromRGB(180, 190, 210),
        TextMuted  = Color3.fromRGB(120, 130, 150),  Online    = Color3.fromRGB(50, 220, 120),
        TrackOff   = Color3.fromRGB(60, 65, 80),     TrackOn   = Color3.fromRGB(0, 150, 255),
        StatValue  = Color3.fromRGB(80, 170, 255),   Stroke    = Color3.fromRGB(60, 65, 80),
        Shine      = Color3.fromRGB(255, 255, 255),  Glow      = Color3.fromRGB(0, 100, 200),
        Stars = false
    },
    Light = {
        GlassBg   = Color3.fromRGB(245, 248, 252),  GlassLeft = Color3.fromRGB(240, 244, 250),
        GlassCard  = Color3.fromRGB(255, 255, 255),  Accent    = Color3.fromRGB(0, 122, 255),
        Text       = Color3.fromRGB(15, 20, 30),     TextSoft  = Color3.fromRGB(80, 90, 110),
        TextMuted  = Color3.fromRGB(140, 150, 170),  Online    = Color3.fromRGB(50, 200, 100),
        TrackOff   = Color3.fromRGB(200, 205, 215),  TrackOn   = Color3.fromRGB(0, 122, 255),
        StatValue  = Color3.fromRGB(0, 100, 200),    Stroke    = Color3.fromRGB(210, 215, 225),
        Shine      = Color3.fromRGB(255, 255, 255),  Glow      = Color3.fromRGB(100, 180, 255),
        Stars = false
    },
    Forest = {
        GlassBg   = Color3.fromRGB(15, 30, 18),     GlassLeft = Color3.fromRGB(20, 35, 22),
        GlassCard  = Color3.fromRGB(28, 55, 35),     Accent    = Color3.fromRGB(50, 210, 75),
        Text       = Color3.fromRGB(210, 245, 220),  TextSoft  = Color3.fromRGB(130, 175, 140),
        TextMuted  = Color3.fromRGB(80, 125, 90),    Online    = Color3.fromRGB(70, 230, 100),
        TrackOff   = Color3.fromRGB(45, 75, 50),     TrackOn   = Color3.fromRGB(50, 210, 75),
        StatValue  = Color3.fromRGB(60, 200, 85),    Stroke    = Color3.fromRGB(40, 80, 48),
        Shine      = Color3.fromRGB(160, 220, 170),  Glow      = Color3.fromRGB(25, 130, 45),
        Stars = false
    },
    Purple = {
        GlassBg   = Color3.fromRGB(22, 18, 35),     GlassLeft = Color3.fromRGB(28, 22, 45),
        GlassCard  = Color3.fromRGB(40, 30, 65),     Accent    = Color3.fromRGB(160, 80, 255),
        Text       = Color3.fromRGB(235, 225, 255),  TextSoft  = Color3.fromRGB(170, 150, 210),
        TextMuted  = Color3.fromRGB(110, 90, 150),   Online    = Color3.fromRGB(120, 220, 140),
        TrackOff   = Color3.fromRGB(55, 40, 80),     TrackOn   = Color3.fromRGB(160, 80, 255),
        StatValue  = Color3.fromRGB(140, 100, 255),  Stroke    = Color3.fromRGB(60, 45, 90),
        Shine      = Color3.fromRGB(200, 180, 255),  Glow      = Color3.fromRGB(90, 40, 180),
        Stars = false
    },
    Sunset = {
        GlassBg   = Color3.fromRGB(35, 20, 18),     GlassLeft = Color3.fromRGB(42, 25, 20),
        GlassCard  = Color3.fromRGB(60, 32, 28),     Accent    = Color3.fromRGB(255, 140, 50),
        Text       = Color3.fromRGB(255, 235, 220),  TextSoft  = Color3.fromRGB(210, 165, 140),
        TextMuted  = Color3.fromRGB(160, 115, 95),   Online    = Color3.fromRGB(100, 220, 120),
        TrackOff   = Color3.fromRGB(80, 45, 35),     TrackOn   = Color3.fromRGB(255, 140, 50),
        StatValue  = Color3.fromRGB(255, 160, 70),   Stroke    = Color3.fromRGB(90, 50, 40),
        Shine      = Color3.fromRGB(255, 200, 160),  Glow      = Color3.fromRGB(255, 100, 40),
        Stars = false
    },
    Cosmos = {
        GlassBg   = Color3.fromRGB(6, 8, 20),       GlassLeft = Color3.fromRGB(10, 12, 28),
        GlassCard  = Color3.fromRGB(18, 22, 45),     Accent    = Color3.fromRGB(140, 200, 255),
        Text       = Color3.fromRGB(220, 235, 255),  TextSoft  = Color3.fromRGB(150, 170, 210),
        TextMuted  = Color3.fromRGB(80, 100, 150),   Online    = Color3.fromRGB(80, 230, 160),
        TrackOff   = Color3.fromRGB(35, 40, 70),     TrackOn   = Color3.fromRGB(140, 200, 255),
        StatValue  = Color3.fromRGB(120, 190, 255),  Stroke    = Color3.fromRGB(40, 55, 100),
        Shine      = Color3.fromRGB(200, 220, 255),  Glow      = Color3.fromRGB(60, 100, 200),
        Stars = true, StarColor = Color3.fromRGB(200, 220, 255), StarCount = 80
    },
    Nebula = {
        GlassBg   = Color3.fromRGB(10, 5, 22),      GlassLeft = Color3.fromRGB(16, 8, 32),
        GlassCard  = Color3.fromRGB(30, 12, 55),     Accent    = Color3.fromRGB(220, 110, 255),
        Text       = Color3.fromRGB(240, 220, 255),  TextSoft  = Color3.fromRGB(185, 150, 220),
        TextMuted  = Color3.fromRGB(120, 80, 160),   Online    = Color3.fromRGB(100, 230, 180),
        TrackOff   = Color3.fromRGB(55, 25, 80),     TrackOn   = Color3.fromRGB(220, 110, 255),
        StatValue  = Color3.fromRGB(200, 120, 255),  Stroke    = Color3.fromRGB(80, 35, 120),
        Shine      = Color3.fromRGB(230, 180, 255),  Glow      = Color3.fromRGB(140, 50, 200),
        Stars = true, StarColor = Color3.fromRGB(255, 200, 255), StarCount = 100
    }
}

-- ============================================================
-- UTILITY
-- ============================================================
local function Create(Class, Props)
    local obj = Instance.new(Class)
    for k, v in pairs(Props) do
        if k ~= "Parent" then obj[k] = v end
    end
    if Props.Parent then obj.Parent = Props.Parent end
    return obj
end

local function Tween(obj, props, dur, style, dir)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.6, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

-- ============================================================
-- WINDOW CONSTRUCTOR
-- ============================================================
local PortalVisuals = {}
PortalVisuals.__index = PortalVisuals
PortalVisuals.Themes = Themes

function PortalVisuals.new(title, options)
    options = options or {}

    local self = setmetatable({}, PortalVisuals)

    self._theme          = Themes[options.theme or "Dark"] or Themes.Dark
    self._themeReg       = {}
    self._themeListeners = {}
    self._stars          = {}
    self._keybinds       = {}
    self._tabs           = {}
    self._currentTab     = nil
    self._isOpen         = true
    self._flags          = {}

    local W, H = (options.size and options.size[1]) or 720,
                 (options.size and options.size[2]) or 560

    -- ── ScreenGui ─────────────────────────────────────────────
    self._gui = Create("ScreenGui", {
        Name = "PortalVisuals_" .. title,
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999
    })

    -- ── Blur ──────────────────────────────────────────────────
    self._blur = Create("BlurEffect", {Size = 0, Parent = Lighting})

    -- ── Watermark ─────────────────────────────────────────────
    if options.watermark ~= false then
        self:_buildWatermark(title)
    end

    -- ── Notification layer ────────────────────────────────────
    self:_buildNotifyLayer()

    -- ── Main window ───────────────────────────────────────────
    self:_buildMainWindow(title, options.subtitle or "", W, H)

    -- ── Menu keybind ──────────────────────────────────────────
    local menuKey = options.menuKey or Enum.KeyCode.K
    self._menuKey = menuKey
    self._keybinds[menuKey] = function() self:Toggle() end

    self._inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local cb = self._keybinds[input.KeyCode]
            if cb then task.spawn(cb, input.KeyCode) end
        end
    end)

    -- open animation
    self._mainFrame.Visible = true
    self._mainFrame.Size = UDim2.new(0, W, 0, 0)
    Tween(self._blur,      {Size = 20},                              1.2)
    Tween(self._mainFrame, {Size = UDim2.new(0, W, 0, H)},          1.2)

    task.delay(1.5, function()
        self:Notify("Portal Visuals", title .. " initialized", 4)
    end)

    _lib._cleanup = function() self:Destroy() end

    return self
end

-- ============================================================
-- THEME INTERNALS
-- ============================================================
function PortalVisuals:_reg(obj, prop, key)
    table.insert(self._themeReg, {Object = obj, Property = prop, Key = key})
end

function PortalVisuals:_clearStars()
    for _, s in ipairs(self._stars) do if s and s.Parent then s:Destroy() end end
    table.clear(self._stars)
end

function PortalVisuals:_spawnStars(count, color)
    self:_clearStars()
    if not self._starContainer then return end
    for _ = 1, count do
        local star = Create("Frame", {
            Parent = self._starContainer,
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Size = UDim2.new(0, math.random(1,3), 0, math.random(1,3)),
            Position = UDim2.new(math.random(0,100)/100, 0, math.random(0,100)/100, 0),
            BackgroundTransparency = math.random(20,70)/100,
            ZIndex = 1
        })
        Create("UICorner", {Parent = star, CornerRadius = UDim.new(1,0)})
        table.insert(self._stars, star)
        task.spawn(function()
            local base = star.BackgroundTransparency
            while star and star.Parent do
                local target = math.clamp(base + math.random(-30,30)/100, 0.1, 0.9)
                Tween(star, {BackgroundTransparency = target}, math.random(15,35)/10, Enum.EasingStyle.Sine)
                task.wait(math.random(15,35)/10)
            end
        end)
    end
end

-- ============================================================
-- PUBLIC: SetTheme
-- ============================================================
function PortalVisuals:SetTheme(name)
    local new = Themes[name]
    if not new then return end
    self._theme = new
    for _, entry in ipairs(self._themeReg) do
        if entry.Object and entry.Object.Parent then
            Tween(entry.Object, {[entry.Property] = new[entry.Key]}, 0.6)
        end
    end
    for _, cb in pairs(self._themeListeners) do
        if cb then task.spawn(cb, new) end
    end
    if new.Stars and new.StarCount and new.StarColor then
        task.delay(0.1, function() self:_spawnStars(new.StarCount, new.StarColor) end)
    else
        self:_clearStars()
    end
    self:Notify("Theme", name .. " applied", 2)
end

-- ============================================================
-- WATERMARK
-- ============================================================
function PortalVisuals:_buildWatermark(title)
    local T = self._theme
    local wmGui = Create("ScreenGui", {
        Name = "PortalWM_" .. title,
        Parent = CoreGui,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100000
    })
    self._wmGui = wmGui

    local card = Create("Frame", {
        Parent = wmGui,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 4),
        Size = UDim2.new(0, 300, 0, 32),
        BackgroundColor3 = T.GlassBg,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        ZIndex = 100
    })
    self:_reg(card, "BackgroundColor3", "GlassBg")
    Create("UICorner",  {Parent = card, CornerRadius = UDim.new(0, 12)})
    local stroke = Create("UIStroke", {Parent = card, Color = T.Stroke, Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    self:_reg(stroke, "Color", "Stroke")

    local dot = Create("Frame", {Parent = card, BackgroundColor3 = Color3.fromRGB(0,200,100), BorderSizePixel = 0, Position = UDim2.new(0,10,0.5,-3), Size = UDim2.new(0,6,0,6), ZIndex = 103})
    Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})

    -- dot pulse
    task.spawn(function()
        while dot and dot.Parent do
            Tween(dot, {BackgroundTransparency = 0.5, Size = UDim2.new(0,8,0,8), Position = UDim2.new(0,9,0.5,-4)}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
            Tween(dot, {BackgroundTransparency = 0, Size = UDim2.new(0,6,0,6), Position = UDim2.new(0,10,0.5,-3)}, 0.8, Enum.EasingStyle.Sine)
            task.wait(0.8)
        end
    end)

    local logo = Create("TextLabel", {Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0,22,0,0), Size = UDim2.new(0,82,1,0), Font = Enum.Font.GothamBold, Text = title, TextColor3 = T.Text, TextSize = 12, TextTransparency = 0.05, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102})
    self:_reg(logo, "TextColor3", "Text")

    local sep = Create("TextLabel", {Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0,104,0,0), Size = UDim2.new(0,10,1,0), Font = Enum.Font.GothamMedium, Text = "|", TextColor3 = T.TextMuted, TextSize = 12, TextTransparency = 0.3, ZIndex = 102})
    self:_reg(sep, "TextColor3", "TextMuted")

    local stats = Create("TextLabel", {Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0,114,0,0), Size = UDim2.new(1,-122,1,0), Font = Enum.Font.GothamMedium, Text = "... ms | ... FPS", TextColor3 = T.Text, TextSize = 12, TextTransparency = 0.1, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102})
    self:_reg(stats, "TextColor3", "Text")

    task.spawn(function()
        local fps, frames, last = 0, 0, tick()
        while wmGui and wmGui.Parent do
            RunService.RenderStepped:Wait()
            frames = frames + 1
            local now = tick()
            if now - last >= 1 then
                fps = frames; frames = 0; last = now
                local ok, val = pcall(function() return Stats.PerformanceStats.Ping:GetValue() end)
                stats.Text = (ok and math.floor(val) or 0) .. " ms | " .. fps .. " FPS"
            end
        end
    end)
end

-- ============================================================
-- NOTIFICATION LAYER  (pill/badge style matching screenshot)
-- ============================================================
function PortalVisuals:_buildNotifyLayer()
    local notifyGui = Create("ScreenGui", {
        Name = "PortalNotify",
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
        IgnoreGuiInset = true
    })
    self._notifyGui = notifyGui

    -- pills stack bottom-right, newest at top of stack
    local holder = Create("Frame", {
        Parent = notifyGui,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 340, 1, -32),
        ZIndex = 200,
        ClipsDescendants = false
    })
    self._notifyHolder = holder
    self._notifyCount  = 0

    local layout = Create("UIListLayout", {
        Parent = holder,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        FillDirection = Enum.FillDirection.Vertical
    })
end

-- ============================================================
-- PUBLIC: Notify  — pill badge style
-- ============================================================
function PortalVisuals:Notify(title, body, duration)
    duration = duration or 3
    local T = self._theme
    self._notifyCount = self._notifyCount + 1
    local order = 99999 - self._notifyCount  -- newest on top (lowest layout order = top in bottom-align)

    local PILL_H = 44

    -- wrapper drives height for list layout collapse animation
    local wrapper = Create("Frame", {
        Parent = self._notifyHolder,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, PILL_H),
        LayoutOrder = order,
        ClipsDescendants = false
    })

    -- pill card — matches the screenshot: dark rounded rect, green dot, title, body
    local pill = Create("Frame", {
        Parent = wrapper,
        BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        -- start off-screen right, slide in
        Position = UDim2.new(0, 380, 0, 0),
        ClipsDescendants = false,
        ZIndex = 210
    })
    Create("UICorner", {Parent = pill, CornerRadius = UDim.new(0, 12)})
    Create("UIStroke",  {Parent = pill, Color = T.Stroke, Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})

    -- left accent stripe
    local stripe = Create("Frame", {
        Parent = pill,
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        ZIndex = 211
    })
    Create("UICorner", {Parent = stripe, CornerRadius = UDim.new(0, 12)})

    -- green status dot (matches screenshot)
    local dot = Create("Frame", {
        Parent = pill,
        BackgroundColor3 = T.Online,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0.5, -4),
        Size = UDim2.new(0, 8, 0, 8),
        ZIndex = 212
    })
    Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})

    -- dot pulse animation
    task.spawn(function()
        while dot and dot.Parent do
            Tween(dot, {BackgroundTransparency = 0.5, Size = UDim2.new(0,10,0,10), Position = UDim2.new(0,13,0.5,-5)}, 0.6, Enum.EasingStyle.Sine)
            task.wait(0.6)
            Tween(dot, {BackgroundTransparency = 0, Size = UDim2.new(0,8,0,8), Position = UDim2.new(0,14,0.5,-4)}, 0.6, Enum.EasingStyle.Sine)
            task.wait(0.6)
        end
    end)

    -- title
    local titleLbl = Create("TextLabel", {
        Parent = pill,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 6),
        Size = UDim2.new(1, -44, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = T.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 212
    })

    -- body
    local bodyLbl = Create("TextLabel", {
        Parent = pill,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 24),
        Size = UDim2.new(1, -44, 0, 14),
        Font = Enum.Font.Gotham,
        Text = body,
        TextColor3 = T.TextSoft,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 212
    })

    -- close button (×)
    local closeBtn = Create("TextButton", {
        Parent = pill,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -28, 0, 0),
        Size = UDim2.new(0, 28, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = T.TextMuted,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 213
    })

    -- progress bar at bottom of pill
    local progressBg = Create("Frame", {
        Parent = pill,
        BackgroundColor3 = T.TrackOff,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 4, 1, -3),
        Size = UDim2.new(1, -8, 0, 2),
        ZIndex = 213
    })
    Create("UICorner", {Parent = progressBg, CornerRadius = UDim.new(1, 0)})

    local progressFill = Create("Frame", {
        Parent = progressBg,
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 214
    })
    Create("UICorner", {Parent = progressFill, CornerRadius = UDim.new(1, 0)})

    -- slide in
    Tween(pill, {Position = UDim2.new(0, 0, 0, 0)}, 0.45, Enum.EasingStyle.Quint)

    -- progress drain
    Tween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true

        -- slide out + fade
        Tween(pill, {Position = UDim2.new(0, 360, 0, 0), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(titleLbl, {TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
        Tween(bodyLbl,  {TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint)

        -- collapse wrapper height so others slide up
        task.delay(0.3, function()
            Tween(wrapper, {Size = UDim2.new(1, 0, 0, 0)}, 0.28, Enum.EasingStyle.Quint)
            task.delay(0.3, function() wrapper:Destroy() end)
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    pill.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then dismiss() end
    end)
    task.delay(duration, dismiss)
end

-- ============================================================
-- MAIN WINDOW BUILD
-- ============================================================
function PortalVisuals:_buildMainWindow(title, subtitle, W, H)
    local T = self._theme

    -- ── Outer clip frame (handles UICorner clipping) ──────────
    -- ClipsDescendants lives here so the background image fills
    -- all the way to the rounded corners without the old bleed bug.
    local clipFrame = Create("Frame", {
        Name = "Clip",
        Parent = self._gui,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, W, 0, H),
        Visible = false,
        -- NO Active, NO dragging
        ClipsDescendants = true,
        ZIndex = 1
    })
    Create("UICorner", {Parent = clipFrame, CornerRadius = UDim.new(0, 42)})
    self._clipFrame = clipFrame

    -- ── Main visual frame (no ClipsDescendants — bg image lives here) ──
    local main = Create("Frame", {
        Name = "Main",
        Parent = clipFrame,
        BackgroundColor3 = T.GlassBg,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 2
    })
    self:_reg(main, "BackgroundColor3", "GlassBg")
    self._mainFrame = clipFrame  -- toggle/size ops target the clip frame

    -- outer stroke on clip frame
    local outerStroke = Create("UIStroke", {Parent = clipFrame, Color = T.Stroke, Thickness = 2, Transparency = 0.5})
    self:_reg(outerStroke, "Color", "Stroke")

    -- ── Background image (fills full window, no gap) ──────────
    -- Sits at ZIndex 2 inside main, everything else at 3+
    local bgImg = Create("ImageLabel", {
        Parent = main,
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 2
    })
    self._bgImg = bgImg

    -- ── Star container ────────────────────────────────────────
    local starContainer = Create("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 3,
        ClipsDescendants = false
    })
    self._starContainer = starContainer

    -- ── Inner UI container ─────────────────────────────────────
    local inner = Create("Frame", {
        Parent = main,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 4
    })

    -- ── Shine overlay ─────────────────────────────────────────
    local shine = Create("Frame", {
        Parent = inner,
        BackgroundColor3 = T.Shine,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0.45),
        ZIndex = 10
    })
    Create("UIGradient", {Parent = shine, Rotation = 90, Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.35, 0.85),
        NumberSequenceKeypoint.new(1, 1)
    })})

    -- ── Left panel ────────────────────────────────────────────
    local left = Create("Frame", {
        Parent = inner,
        BackgroundColor3 = T.GlassLeft,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 1, 0),
        ZIndex = 5
    })
    self:_reg(left, "BackgroundColor3", "GlassLeft")
    Create("UICorner", {Parent = left, CornerRadius = UDim.new(0, 42)})

    local sep = Create("Frame", {
        Parent = left,
        BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -2, 0, 20),
        Size = UDim2.new(0, 2, 1, -40),
        ZIndex = 6
    })
    self:_reg(sep, "BackgroundColor3", "Stroke")

    local titleLbl = Create("TextLabel", {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 28),
        Size = UDim2.new(1, -40, 0, 30),
        Font = Enum.Font.GothamBlack,
        Text = title,
        TextColor3 = T.Text,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    })
    self:_reg(titleLbl, "TextColor3", "Text")

    local subLbl = Create("TextLabel", {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 58),
        Size = UDim2.new(1, -40, 0, 14),
        Font = Enum.Font.Gotham,
        Text = subtitle:upper(),
        TextColor3 = T.TextMuted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7
    })
    self:_reg(subLbl, "TextColor3", "TextMuted")

    -- ── Tab buttons holder ─────────────────────────────────────
    local tabsHolder = Create("Frame", {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 90),
        Size = UDim2.new(1, -56, 1, -200),
        ZIndex = 7
    })
    self._tabsHolder = tabsHolder
    self._tabsLayout = Create("UIListLayout", {
        Parent = tabsHolder,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    -- ── Profile section ───────────────────────────────────────
    self:_buildProfile(left)

    -- ── Content area ──────────────────────────────────────────
    local contentArea = Create("Frame", {
        Parent = inner,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 220, 0, 0),
        Size = UDim2.new(1, -220, 1, 0),
        ClipsDescendants = true,
        ZIndex = 5
    })
    self._contentArea = contentArea

    -- ── Stars init ────────────────────────────────────────────
    if T.Stars and T.StarCount and T.StarColor then
        task.delay(0.2, function() self:_spawnStars(T.StarCount, T.StarColor) end)
    end
end

-- ============================================================
-- PROFILE
-- ============================================================
function PortalVisuals:_buildProfile(parent)
    local T = self._theme
    local container = Create("Frame", {
        Parent = parent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 1, -76),
        Size = UDim2.new(1, -32, 0, 60),
        ZIndex = 7
    })

    local avatarBg = Create("Frame", {
        Parent = container,
        BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 0.6,
        Position = UDim2.new(0, 0, 0.5, -21),
        Size = UDim2.new(0, 42, 0, 42),
        ZIndex = 8
    })
    self:_reg(avatarBg, "BackgroundColor3", "GlassCard")
    Create("UICorner", {Parent = avatarBg, CornerRadius = UDim.new(1, 0)})
    local avatarStroke = Create("UIStroke", {Parent = avatarBg, Color = T.Stroke, Thickness = 1.5, Transparency = 0.5})
    self:_reg(avatarStroke, "Color", "Stroke")

    local avatarImg = Create("ImageLabel", {
        Parent = avatarBg,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=420&height=420&format=png",
        ZIndex = 9
    })
    Create("UICorner", {Parent = avatarImg, CornerRadius = UDim.new(1, 0)})

    local nameLbl = Create("TextLabel", {
        Parent = container,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 52, 0, 8),
        Size = UDim2.new(1, -52, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = "@" .. LocalPlayer.Name,
        TextColor3 = T.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    self:_reg(nameLbl, "TextColor3", "Text")

    -- online status with dot
    local statusRow = Create("Frame", {Parent = container, BackgroundTransparency = 1, Position = UDim2.new(0,52,0,31), Size = UDim2.new(1,-52,0,14), ZIndex = 8})
    local sDot = Create("Frame", {Parent = statusRow, BackgroundColor3 = T.Online, BorderSizePixel = 0, Size = UDim2.new(0,6,0,6), Position = UDim2.new(0,0,0.5,-3), ZIndex = 9})
    self:_reg(sDot, "BackgroundColor3", "Online")
    Create("UICorner", {Parent = sDot, CornerRadius = UDim.new(1,0)})
    local sLbl = Create("TextLabel", {Parent = statusRow, BackgroundTransparency = 1, Position = UDim2.new(0,10,0,0), Size = UDim2.new(1,-10,1,0), Font = Enum.Font.Gotham, Text = "Online", TextColor3 = T.Online, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9})
    self:_reg(sLbl, "TextColor3", "Online")
end

-- ============================================================
-- PUBLIC: Toggle open/close
-- ============================================================
function PortalVisuals:Toggle()
    self._isOpen = not self._isOpen
    local clip = self._clipFrame
    local s = clip.AbsoluteSize

    if self._isOpen then
        clip.Visible = true
        Tween(self._blur, {Size = 20}, 0.9)
        Tween(clip, {Size = UDim2.new(0, s.X, 0, 560)}, 0.9)
    else
        Tween(self._blur, {Size = 0}, 0.7)
        local t = Tween(clip, {Size = UDim2.new(0, s.X, 0, 0)}, 0.7)
        t.Completed:Connect(function() if not self._isOpen then clip.Visible = false end end)
    end
end

-- ============================================================
-- PUBLIC: SetBackground  (fixed — image fills entire window)
-- ============================================================
function PortalVisuals:SetBackground(raw)
    local s = tostring(raw):match("^%s*(.-)%s*$")
    local uri

    if s == "" or s == nil then
        Tween(self._bgImg, {ImageTransparency = 1}, 0.4)
        task.delay(0.45, function() self._bgImg.Image = "" end)
        return
    end

    if s:match("^rbxassetid://%d+$") then
        uri = s
    elseif s:match("^%d+$") then
        uri = "rbxassetid://" .. s
    else
        local id = s:match("(%d+)")
        if id and #id >= 6 then uri = "rbxassetid://" .. id end
    end

    if not uri then
        Tween(self._bgImg, {ImageTransparency = 1}, 0.4)
        task.delay(0.45, function() self._bgImg.Image = "" end)
        return
    end

    -- preload then fade in so you don't see the "no image" flash
    local content = game:GetService("ContentProvider")
    self._bgImg.Image = uri
    self._bgImg.ImageTransparency = 1
    task.spawn(function()
        pcall(function() content:PreloadAsync({self._bgImg}) end)
        Tween(self._bgImg, {ImageTransparency = 0.35}, 0.5)
    end)
end

-- ============================================================
-- PUBLIC: ClearBackground
-- ============================================================
function PortalVisuals:ClearBackground()
    Tween(self._bgImg, {ImageTransparency = 1}, 0.4)
    task.delay(0.45, function() self._bgImg.Image = "" end)
end

-- ============================================================
-- PUBLIC: SetMenuKey
-- ============================================================
function PortalVisuals:SetMenuKey(keyCode)
    self._keybinds[self._menuKey] = nil
    self._menuKey = keyCode
    self._keybinds[keyCode] = function() self:Toggle() end
end

-- ============================================================
-- PUBLIC: Tab
-- ============================================================
function PortalVisuals:Tab(name)
    local T = self._theme

    local page = Create("ScrollingFrame", {
        Parent = self._contentArea,
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        ScrollBarImageTransparency = 0.5,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ZIndex = 6
    })
    self:_reg(page, "ScrollBarImageColor3", "Accent")

    local pageLayout = Create("UIListLayout", {Parent = page, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder})
    Create("UIPadding", {Parent = page, PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22), PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20)})
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 40)
    end)

    local idx = #self._tabs
    local btn = Create("TextButton", {
        Parent = self._tabsHolder,
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42),
        Font = Enum.Font.GothamBold,
        Text = "  " .. name,
        TextColor3 = T.TextSoft,
        TextSize = 14,
        AutoButtonColor = false,
        LayoutOrder = idx,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8
    })
    self:_reg(btn, "TextColor3", "TextSoft")

    -- active indicator dot
    local ind = Create("Frame", {
        Parent = btn,
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, -10, 0.5, -4),
        Size = UDim2.new(0, 5, 0, 8),
        BackgroundTransparency = 1,
        ZIndex = 9
    })
    self:_reg(ind, "BackgroundColor3", "Accent")
    Create("UICorner", {Parent = ind, CornerRadius = UDim.new(1, 0)})

    -- hover bg
    local hoverBg = Create("Frame", {
        Parent = btn,
        BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 7
    })
    Create("UICorner", {Parent = hoverBg, CornerRadius = UDim.new(0, 10)})

    local tabData = {Name = name, Button = btn, Indicator = ind, Page = page, HoverBg = hoverBg}
    table.insert(self._tabs, tabData)

    local win = self
    local function activate()
        if win._currentTab == name then return end
        for _, t in ipairs(win._tabs) do
            if t.Name == win._currentTab then
                Tween(t.Button,    {TextColor3 = win._theme.TextSoft},  0.4)
                Tween(t.Indicator, {BackgroundTransparency = 1},         0.3)
                Tween(t.HoverBg,   {BackgroundTransparency = 1},         0.3)
                t.Page.Visible = false
            end
        end
        win._currentTab = name
        Tween(btn,     {TextColor3 = win._theme.Text},  0.4)
        Tween(ind,     {BackgroundTransparency = 0},     0.3)
        Tween(hoverBg, {BackgroundTransparency = 0.88},  0.3)
        page.CanvasPosition = Vector2.new(0, 0)
        page.Visible = true
        page.Position = UDim2.new(0, 30, 0, 0)
        Tween(page, {Position = UDim2.new(0, 0, 0, 0)}, 0.45)
    end

    btn.MouseEnter:Connect(function()
        if win._currentTab ~= name then
            Tween(btn,     {TextColor3 = win._theme.Text},  0.25, Enum.EasingStyle.Sine)
            Tween(hoverBg, {BackgroundTransparency = 0.93}, 0.25, Enum.EasingStyle.Sine)
        end
    end)
    btn.MouseLeave:Connect(function()
        if win._currentTab ~= name then
            Tween(btn,     {TextColor3 = win._theme.TextSoft}, 0.25, Enum.EasingStyle.Sine)
            Tween(hoverBg, {BackgroundTransparency = 1},        0.25, Enum.EasingStyle.Sine)
        end
    end)
    btn.MouseButton1Click:Connect(activate)

    if #self._tabs == 1 then
        win._currentTab = name
        btn.TextColor3 = T.Text
        ind.BackgroundTransparency = 0
        hoverBg.BackgroundTransparency = 0.88
        page.Visible = true
    end

    local Tab = {}
    Tab._page = page
    Tab._win  = win

    function Tab:Section(sectionTitle)
        return win:_buildSection(page, sectionTitle)
    end

    return Tab
end

-- ============================================================
-- SECTION BUILDER
-- ============================================================
function PortalVisuals:_buildSection(parent, sectionTitle)
    local T = self._theme

    local section = Create("Frame", {
        Parent = parent,
        BackgroundColor3 = T.GlassCard,
        BackgroundTransparency = 0.75,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #parent:GetChildren() + 1,
        ZIndex = 7,
        ClipsDescendants = false
    })
    self:_reg(section, "BackgroundColor3", "GlassCard")
    Create("UICorner", {Parent = section, CornerRadius = UDim.new(0, 28)})
    local sectionStroke = Create("UIStroke", {Parent = section, Color = T.Stroke, Thickness = 1, Transparency = 0.55})
    self:_reg(sectionStroke, "Color", "Stroke")

    -- shine
    local shineS = Create("Frame", {Parent = section, BackgroundColor3 = T.Shine, BackgroundTransparency = 0.9, Size = UDim2.new(1, 0, 0, 0.5), ZIndex = 8, ClipsDescendants = true})
    Create("UICorner", {Parent = shineS, CornerRadius = UDim.new(0, 28)})
    Create("UIGradient", {Parent = shineS, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.65), NumberSequenceKeypoint.new(1,1)})})

    -- accent bar
    local accent = Create("Frame", {Parent = section, BackgroundColor3 = T.Accent, Position = UDim2.new(0, 18, 0, 16), Size = UDim2.new(0, 3, 0, 22), ZIndex = 9})
    self:_reg(accent, "BackgroundColor3", "Accent")
    Create("UICorner", {Parent = accent, CornerRadius = UDim.new(1, 0)})

    Create("TextLabel", {
        Parent = section,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -50, 0, 54),
        Font = Enum.Font.GothamBold,
        Text = sectionTitle,
        TextColor3 = T.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 9
    })

    local content = Create("Frame", {
        Parent = section,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 54),
        Size = UDim2.new(1, -32, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 9,
        ClipsDescendants = false
    })
    Create("UIListLayout", {Parent = content, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
    Create("UIPadding",    {Parent = content, PaddingBottom = UDim.new(0, 16)})

    local Sec = {}
    Sec._content = content
    local win = self

    -- ── TOGGLE ────────────────────────────────────────────────
    function Sec:Toggle(label, flagName, default, callback)
        local T2 = win._theme
        local frame = Create("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,38), LayoutOrder = #content:GetChildren()+1})
        local lbl   = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,-60,1,0), Font = Enum.Font.Gotham, Text = label, TextColor3 = T2.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})
        win:_reg(lbl, "TextColor3", "Text")

        local enabled = default or false
        win._flags[flagName] = enabled

        local track = Create("Frame", {Parent = frame, BackgroundColor3 = enabled and T2.TrackOn or T2.TrackOff, BorderSizePixel = 0, Position = UDim2.new(1,-52,0.5,-13), Size = UDim2.new(0,50,0,26), ZIndex = 10})
        win:_reg(track, "BackgroundColor3", enabled and "TrackOn" or "TrackOff")
        Create("UICorner", {Parent = track, CornerRadius = UDim.new(1,0)})
        local thumb = Create("Frame", {Parent = track, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Position = enabled and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11), Size = UDim2.new(0,22,0,22), ZIndex = 11})
        Create("UICorner", {Parent = thumb, CornerRadius = UDim.new(1,0)})

        local debounce = false
        local function setEnabled(v)
            enabled = v
            win._flags[flagName] = v
            if v then
                Tween(track, {BackgroundColor3 = win._theme.TrackOn},  0.45, Enum.EasingStyle.Quart)
                Tween(thumb, {Position = UDim2.new(1,-24,0.5,-11)},   0.45, Enum.EasingStyle.Quart)
            else
                Tween(track, {BackgroundColor3 = win._theme.TrackOff}, 0.45, Enum.EasingStyle.Quart)
                Tween(thumb, {Position = UDim2.new(0,2,0.5,-11)},     0.45, Enum.EasingStyle.Quart)
            end
            if callback then task.spawn(callback, v) end
        end

        local btn = Create("TextButton", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "", ZIndex = 12, AutoButtonColor = false})
        btn.MouseButton1Click:Connect(function()
            if debounce then return end
            debounce = true
            setEnabled(not enabled)
            task.wait(0.45)
            debounce = false
        end)

        return {Set = setEnabled, Get = function() return enabled end}
    end

    -- ── SLIDER ────────────────────────────────────────────────
    function Sec:Slider(label, min, max, default, callback)
        local T2 = win._theme
        local frame = Create("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,52), LayoutOrder = #content:GetChildren()+1})

        local lbl    = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0,0,0,0), Size = UDim2.new(0.65,-4,0,20), Font = Enum.Font.Gotham, Text = label, TextColor3 = T2.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})
        win:_reg(lbl, "TextColor3", "TextMuted")
        local valLbl = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Position = UDim2.new(0.65,0,0,0), Size = UDim2.new(0.35,-2,0,20), Font = Enum.Font.GothamBold, Text = string.format("%.2f", default), TextColor3 = T2.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 10})
        win:_reg(valLbl, "TextColor3", "Text")

        local trackFrame = Create("Frame", {Parent = frame, BackgroundColor3 = T2.TrackOff, BorderSizePixel = 0, Position = UDim2.new(0,0,0,28), Size = UDim2.new(1,0,0,6), ZIndex = 10})
        win:_reg(trackFrame, "BackgroundColor3", "TrackOff")
        Create("UICorner", {Parent = trackFrame, CornerRadius = UDim.new(1,0)})

        local fillF = Create("Frame", {Parent = trackFrame, BackgroundColor3 = T2.TrackOn, BorderSizePixel = 0, Size = UDim2.new((default-min)/(max-min),0,1,0), ZIndex = 11})
        win:_reg(fillF, "BackgroundColor3", "TrackOn")
        Create("UICorner", {Parent = fillF, CornerRadius = UDim.new(1,0)})

        local thumbF = Create("Frame", {Parent = trackFrame, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Position = UDim2.new((default-min)/(max-min),-8,0.5,-8), Size = UDim2.new(0,16,0,16), ZIndex = 12})
        Create("UICorner", {Parent = thumbF, CornerRadius = UDim.new(1,0)})
        -- thumb shadow ring
        Create("UIStroke", {Parent = thumbF, Color = T2.Accent, Thickness = 2, Transparency = 0.6})

        local dragging = false
        local function update(val)
            local v = math.clamp(math.round((val - min) / ((max - min) / 100)) * ((max - min) / 100) + min, min, max)
            local a = (v - min) / (max - min)
            fillF.Size = UDim2.new(a, 0, 1, 0)
            thumbF.Position = UDim2.new(a, -8, 0.5, -8)
            valLbl.Text = string.format("%.2f", v)
            if callback then callback(v) end
        end
        local function inputToVal(input)
            local abs = input.Position.X - trackFrame.AbsolutePosition.X
            return min + (max - min) * math.clamp(abs / trackFrame.AbsoluteSize.X, 0, 1)
        end

        trackFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; update(inputToVal(input))
            end
        end)
        thumbF.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(inputToVal(input)) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)

        return {Set = update}
    end

    -- ── TEXTBOX ───────────────────────────────────────────────
    function Sec:TextBox(label, placeholder, default, callback)
        local T2 = win._theme
        local frame = Create("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,38), LayoutOrder = #content:GetChildren()+1})
        local lbl   = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(0.4,-6,1,0), Font = Enum.Font.Gotham, Text = label, TextColor3 = T2.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})
        win:_reg(lbl, "TextColor3", "Text")
        local box = Create("TextBox", {Parent = frame, BackgroundColor3 = T2.GlassCard, BackgroundTransparency = 0.55, BorderSizePixel = 0, Position = UDim2.new(0.4,0,0.5,-15), Size = UDim2.new(0.6,0,0,30), Font = Enum.Font.GothamBold, PlaceholderText = placeholder, PlaceholderColor3 = T2.TextMuted, Text = default or "", TextColor3 = T2.Text, TextSize = 13, ZIndex = 10, ClearTextOnFocus = false})
        win:_reg(box, "BackgroundColor3", "GlassCard")
        win:_reg(box, "TextColor3", "Text")
        Create("UICorner", {Parent = box, CornerRadius = UDim.new(0,14)})
        Create("UIStroke",  {Parent = box, Color = T2.Stroke, Thickness = 1.5, Transparency = 0.55})

        box.Focused:Connect(function()
            Tween(box, {BackgroundTransparency = 0.35}, 0.2, Enum.EasingStyle.Sine)
        end)
        box.FocusLost:Connect(function()
            Tween(box, {BackgroundTransparency = 0.55}, 0.2, Enum.EasingStyle.Sine)
            if callback then callback(box.Text) end
        end)
        return {Get = function() return box.Text end, Set = function(v) box.Text = v end}
    end

    -- ── KEYBIND ───────────────────────────────────────────────
    function Sec:Keybind(label, defaultKey, callback)
        local T2 = win._theme
        local frame = Create("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,38), LayoutOrder = #content:GetChildren()+1})
        local lbl   = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,-118,1,0), Font = Enum.Font.Gotham, Text = label, TextColor3 = T2.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})
        win:_reg(lbl, "TextColor3", "Text")
        local currentKey = defaultKey

        local keyBtn = Create("TextButton", {Parent = frame, BackgroundColor3 = T2.GlassCard, BackgroundTransparency = 0.45, BorderSizePixel = 0, Position = UDim2.new(1,-110,0.5,-15), Size = UDim2.new(0,100,0,30), Font = Enum.Font.GothamBold, Text = currentKey.Name, TextColor3 = T2.Text, TextSize = 12, AutoButtonColor = false, ZIndex = 10})
        win:_reg(keyBtn, "BackgroundColor3", "GlassCard")
        win:_reg(keyBtn, "TextColor3", "Text")
        Create("UICorner", {Parent = keyBtn, CornerRadius = UDim.new(0,14)})
        Create("UIStroke",  {Parent = keyBtn, Color = T2.Accent, Thickness = 1.5, Transparency = 0.5})

        win._keybinds[currentKey] = callback
        local waiting = false
        keyBtn.MouseButton1Click:Connect(function()
            if waiting then return end
            waiting = true
            keyBtn.Text = "Press key..."
            Tween(keyBtn, {BackgroundColor3 = win._theme.Accent, BackgroundTransparency = 0.1}, 0.3)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    win._keybinds[currentKey] = nil
                    currentKey = input.KeyCode
                    keyBtn.Text = currentKey.Name
                    win._keybinds[currentKey] = callback
                    if conn then conn:Disconnect() end
                    waiting = false
                    Tween(keyBtn, {BackgroundColor3 = win._theme.GlassCard, BackgroundTransparency = 0.45}, 0.3)
                end
            end)
        end)

        return {Get = function() return currentKey end}
    end

    -- ── BUTTON ────────────────────────────────────────────────
    function Sec:Button(label, callback)
        local T2 = win._theme
        local btn = Create("TextButton", {
            Parent = content,
            BackgroundColor3 = T2.Accent,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,36),
            Font = Enum.Font.GothamBold,
            Text = label,
            TextColor3 = T2.Text,
            TextSize = 13,
            AutoButtonColor = false,
            LayoutOrder = #content:GetChildren()+1,
            ZIndex = 10
        })
        win:_reg(btn, "BackgroundColor3", "Accent")
        win:_reg(btn, "TextColor3", "Text")
        Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0,18)})

        btn.MouseEnter:Connect(function()  Tween(btn, {BackgroundTransparency = 0.1},  0.2, Enum.EasingStyle.Sine) end)
        btn.MouseLeave:Connect(function()  Tween(btn, {BackgroundTransparency = 0.3},  0.2, Enum.EasingStyle.Sine) end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.6}, 0.08, Enum.EasingStyle.Sine)
            task.delay(0.12, function() Tween(btn, {BackgroundTransparency = 0.3}, 0.2, Enum.EasingStyle.Sine) end)
            if callback then task.spawn(callback) end
        end)
    end

    -- ── LABEL ─────────────────────────────────────────────────
    function Sec:Label(text)
        local T2 = win._theme
        local lbl = Create("TextLabel", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22), Font = Enum.Font.Gotham, Text = text, TextColor3 = T2.TextMuted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #content:GetChildren()+1, ZIndex = 10, TextWrapped = true})
        win:_reg(lbl, "TextColor3", "TextMuted")
        return {Set = function(v) lbl.Text = v end}
    end

    -- ── DROPDOWN ──────────────────────────────────────────────
    function Sec:Dropdown(label, options, default, callback)
        local T2 = win._theme
        local selected = default or options[1]
        local open = false

        local frame = Create("Frame", {
            Parent = content,
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,38),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #content:GetChildren()+1,
            ZIndex = 10,
            ClipsDescendants = false
        })

        local header = Create("TextButton", {
            Parent = frame,
            BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Size = UDim2.new(1,0,0,36),
            Font = Enum.Font.GothamBold,
            Text = "  ▾  " .. selected,
            TextColor3 = T2.Text,
            TextSize = 13,
            AutoButtonColor = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 11
        })
        win:_reg(header, "BackgroundColor3", "GlassCard")
        win:_reg(header, "TextColor3", "Text")
        Create("UICorner", {Parent = header, CornerRadius = UDim.new(0,18)})
        Create("UIStroke",  {Parent = header, Color = T2.Stroke, Thickness = 1, Transparency = 0.5})

        -- dropdown renders in a high-ZIndex frame so it doesn't get clipped
        local dropdown = Create("Frame", {
            Parent = frame,
            BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            Position = UDim2.new(0,0,0,40),
            Size = UDim2.new(1,0,0,0),
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 50
        })
        win:_reg(dropdown, "BackgroundColor3", "GlassCard")
        Create("UICorner",    {Parent = dropdown, CornerRadius = UDim.new(0,18)})
        Create("UIStroke",    {Parent = dropdown, Color = T2.Stroke, Thickness = 1, Transparency = 0.5})
        Create("UIListLayout",{Parent = dropdown, Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder})
        Create("UIPadding",   {Parent = dropdown, PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6)})

        local totalH = 12
        for i, opt in ipairs(options) do
            local isSelected = opt == selected
            local optBtn = Create("TextButton", {
                Parent = dropdown,
                BackgroundColor3 = T2.GlassCard,
                BackgroundTransparency = isSelected and 0.3 or 0.85,
                BorderSizePixel = 0,
                Size = UDim2.new(1,0,0,30),
                Font = Enum.Font.Gotham,
                Text = "  " .. opt,
                TextColor3 = isSelected and T2.Text or T2.TextSoft,
                TextSize = 12,
                AutoButtonColor = false,
                LayoutOrder = i,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 51
            })
            win:_reg(optBtn, "TextColor3", isSelected and "Text" or "TextSoft")
            Create("UICorner", {Parent = optBtn, CornerRadius = UDim.new(0,12)})
            totalH = totalH + 32

            optBtn.MouseEnter:Connect(function() Tween(optBtn, {BackgroundTransparency = 0.5}, 0.15, Enum.EasingStyle.Sine) end)
            optBtn.MouseLeave:Connect(function() Tween(optBtn, {BackgroundTransparency = opt == selected and 0.3 or 0.85}, 0.15, Enum.EasingStyle.Sine) end)

            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                header.Text = "  ▾  " .. selected
                if callback then task.spawn(callback, selected) end
                Tween(dropdown, {Size = UDim2.new(1,0,0,0)}, 0.28)
                task.delay(0.3, function() dropdown.Visible = false end)
                open = false
            end)
        end

        header.MouseButton1Click:Connect(function()
            open = not open
            if open then
                dropdown.Visible = true
                dropdown.Size = UDim2.new(1,0,0,0)
                Tween(dropdown, {Size = UDim2.new(1,0,0,totalH)}, 0.32, Enum.EasingStyle.Quint)
            else
                Tween(dropdown, {Size = UDim2.new(1,0,0,0)}, 0.28)
                task.delay(0.3, function() dropdown.Visible = false end)
            end
        end)

        return {Get = function() return selected end}
    end

    -- ── COLOR PICKER ──────────────────────────────────────────
    function Sec:ColorPicker(label, default, callback)
        local T2 = win._theme
        local current = default or Color3.fromRGB(255,255,255)
        local frame = Create("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,38), LayoutOrder = #content:GetChildren()+1, ZIndex = 10, ClipsDescendants = false})
        local lbl   = Create("TextLabel", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,-60,1,0), Font = Enum.Font.Gotham, Text = label, TextColor3 = T2.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})
        win:_reg(lbl, "TextColor3", "Text")

        local swatch = Create("TextButton", {Parent = frame, BackgroundColor3 = current, BorderSizePixel = 0, Position = UDim2.new(1,-50,0.5,-13), Size = UDim2.new(0,44,0,26), Text = "", AutoButtonColor = false, ZIndex = 10})
        Create("UICorner", {Parent = swatch, CornerRadius = UDim.new(0,10)})
        Create("UIStroke",  {Parent = swatch, Color = T2.Stroke, Thickness = 1.5, Transparency = 0.4})

        local pickerOpen = false
        local popup = Create("Frame", {
            Parent = frame,
            BackgroundColor3 = T2.GlassCard,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            Position = UDim2.new(1,-210,0,42),
            Size = UDim2.new(0,200,0,0),
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 60
        })
        win:_reg(popup, "BackgroundColor3", "GlassCard")
        Create("UICorner", {Parent = popup, CornerRadius = UDim.new(0,16)})
        Create("UIStroke",  {Parent = popup, Color = T2.Stroke, Thickness = 1.5, Transparency = 0.4})

        local hueBar = Create("Frame", {Parent = popup, BackgroundTransparency = 0, BorderSizePixel = 0, Position = UDim2.new(0,10,0,10), Size = UDim2.new(1,-20,0,18), ZIndex = 61})
        Create("UICorner", {Parent = hueBar, CornerRadius = UDim.new(0,9)})
        Create("UIGradient", {Parent = hueBar, Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,0,0))
        })})

        local h, s, v = Color3.toHSV(current)
        local hueThumb = Create("Frame", {Parent = hueBar, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Position = UDim2.new(h,-5,0.5,-9), Size = UDim2.new(0,10,0,18), ZIndex = 62})
        Create("UICorner", {Parent = hueThumb, CornerRadius = UDim.new(1,0)})

        local hexBox = Create("TextBox", {Parent = popup, BackgroundColor3 = T2.GlassCard, BackgroundTransparency = 0.5, BorderSizePixel = 0, Position = UDim2.new(0,10,0,38), Size = UDim2.new(1,-20,0,26), Font = Enum.Font.GothamBold, Text = string.format("#%02X%02X%02X", math.floor(current.R*255), math.floor(current.G*255), math.floor(current.B*255)), TextColor3 = T2.Text, TextSize = 12, ZIndex = 61, ClearTextOnFocus = false})
        win:_reg(hexBox, "BackgroundColor3", "GlassCard")
        win:_reg(hexBox, "TextColor3", "Text")
        Create("UICorner", {Parent = hexBox, CornerRadius = UDim.new(0,10)})

        local function applyColor(c)
            current = c
            swatch.BackgroundColor3 = c
            h, s, v = Color3.toHSV(c)
            hueThumb.Position = UDim2.new(h,-5,0.5,-9)
            hexBox.Text = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
            if callback then task.spawn(callback, c) end
        end

        local hueDragging = false
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                hueDragging = true
                local a = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                applyColor(Color3.fromHSV(a, 1, 1))
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local a = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                applyColor(Color3.fromHSV(a, 1, 1))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = false end
        end)

        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#","")
            if #hex == 6 then
                local r = tonumber(hex:sub(1,2),16)
                local g = tonumber(hex:sub(3,4),16)
                local b = tonumber(hex:sub(5,6),16)
                if r and g and b then applyColor(Color3.fromRGB(r,g,b)) end
            end
        end)

        swatch.MouseButton1Click:Connect(function()
            pickerOpen = not pickerOpen
            if pickerOpen then
                popup.Visible = true
                popup.Size = UDim2.new(0,200,0,0)
                Tween(popup, {Size = UDim2.new(0,200,0,74)}, 0.32)
            else
                Tween(popup, {Size = UDim2.new(0,200,0,0)}, 0.28)
                task.delay(0.3, function() popup.Visible = false end)
            end
        end)

        return {Get = function() return current end, Set = applyColor}
    end

    return Sec
end

-- ============================================================
-- PUBLIC: Destroy
-- ============================================================
function PortalVisuals:Destroy()
    self:_clearStars()
    if self._inputConn  then self._inputConn:Disconnect() end
    if self._gui        then self._gui:Destroy() end
    if self._wmGui      then self._wmGui:Destroy() end
    if self._notifyGui  then self._notifyGui:Destroy() end
    if self._blur       then self._blur:Destroy() end
    table.clear(self._keybinds)
    table.clear(self._themeReg)
end

-- ============================================================
-- BUILT-IN SETTINGS TAB
-- ============================================================
function PortalVisuals:AddSettingsTab()
    local tab = self:Tab("Settings")

    local bgSec = tab:Section("Background")
    local bgCtrl = bgSec:TextBox("Asset ID", "numeric ID or rbxassetid://...", "", function(v)
        if v == "" then self:ClearBackground() else self:SetBackground(v) end
    end)
    bgSec:Button("Clear Background", function() self:ClearBackground() end)

    local thSec = tab:Section("Theme")
    local themeNames = {}
    for name in pairs(Themes) do table.insert(themeNames, name) end
    table.sort(themeNames)
    thSec:Dropdown("Select Theme", themeNames, self._currentThemeName or "Dark", function(name)
        self._currentThemeName = name
        self:SetTheme(name)
    end)

    local keySec = tab:Section("Keybind")
    keySec:Keybind("Toggle Menu", self._menuKey, function() end)

    return tab
end

-- ============================================================
-- RETURN
-- ============================================================
return PortalVisuals

--[[
══════════════════════════════════════════════════════════════
  QUICK REFERENCE  v2.0
══════════════════════════════════════════════════════════════

  local PV  = loadstring(game:HttpGet("YOUR_RAW_URL"))()

  local win = PV.new("My Hub", {
      theme     = "Dark",
      subtitle  = "v2.0",
      menuKey   = Enum.KeyCode.K,
      watermark = true,
      size      = {720, 560},
  })

  local tab = win:Tab("Combat")
  local sec = tab:Section("Aimbot")

  local tog = sec:Toggle("Silent Aim", "SilentAim", false, function(v) end)
  local sld = sec:Slider("FOV", 1, 360, 90, function(v) end)
  local txt = sec:TextBox("Webhook", "URL...", "", function(v) end)
              sec:Keybind("Toggle Key", Enum.KeyCode.F, function() end)
              sec:Button("Fire Now", function() end)
  local lbl = sec:Label("Some info text")
  local drp = sec:Dropdown("Mode", {"Rage","Legit"}, "Legit", function(v) end)
  local clr = sec:ColorPicker("Color", Color3.fromRGB(255,0,0), function(v) end)

  win:AddSettingsTab()

  -- Programmatic control
  tog.Set(true)
  sld.Set(45)
  lbl.Set("New text")
  drp.Get()
  clr.Get()
  win:SetTheme("Cosmos")
  win:SetBackground("12345678")    -- or "rbxassetid://12345678"
  win:ClearBackground()
  win:SetMenuKey(Enum.KeyCode.RightAlt)
  win:Notify("Title", "Body", 3)
  win:Toggle()
  win:Destroy()

  Changes from v1.0:
  - Notifications: pill/badge style (dot + title + body + progress bar + × close)
  - Background: clip frame separation fixes top/bottom corner bleed
  - Background: ContentProvider preload before fade-in eliminates flash
  - Background: ClearBackground() API added
  - Dragging: removed entirely — window stays locked
  - Slider: thumb has accent ring, snaps to step
  - Tabs: hover background added, text alignment left
  - Watermark: dot pulses
  - Settings tab: theme via dropdown instead of one button per theme
  - Keybind: "Press key..." feedback text instead of "..."
  - TextBox: focus highlight, ClearTextOnFocus disabled
══════════════════════════════════════════════════════════════
--]]

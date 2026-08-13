--[[
    StreamUI Library
    A clean, self-contained Roblox GUI library for use inside Roblox Studio.

    - Parents to the LocalPlayer's PlayerGui (NOT CoreGui)
    - No getgenv(), no writefile/readfile, no executor-only APIs
    - Config is kept in-memory by default; hook up DataStoreService yourself
      if you want settings to persist between sessions (see bottom of file
      for a commented example).

    Usage (from a LocalScript):
        local StreamUI = require(path.to.this.module)
        local Window = StreamUI:CreateWindow("My Game")
        local Tab = Window:CreateTab("Main")
        Tab:CreateToggle({ Title = "Enable Thing", Default = false, Callback = function(v) end })
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME PRESETS (switchable at runtime from the Settings tab)
-- ============================================================
local ThemePresets = {
    Vanilla = {
        Background      = Color3.fromRGB(250, 247, 240),
        SecondaryBg     = Color3.fromRGB(242, 238, 228),
        TertiaryBg      = Color3.fromRGB(232, 227, 214),
        Border          = Color3.fromRGB(214, 207, 190),
        TextPrimary     = Color3.fromRGB(30, 28, 24),
        TextSecondary   = Color3.fromRGB(100, 94, 84),
        TextDisabled    = Color3.fromRGB(165, 158, 145),
        Accent          = Color3.fromRGB(60, 55, 45),
        Enabled         = Color3.fromRGB(60, 175, 95),
        Disabled        = Color3.fromRGB(222, 216, 202),
        Success         = Color3.fromRGB(60, 175, 95),
        Error           = Color3.fromRGB(210, 90, 80),
        Warning         = Color3.fromRGB(215, 165, 60),
    },
    Midnight = {
        Background      = Color3.fromRGB(24, 24, 27),
        SecondaryBg     = Color3.fromRGB(32, 32, 36),
        TertiaryBg      = Color3.fromRGB(42, 42, 47),
        Border          = Color3.fromRGB(58, 58, 64),
        TextPrimary     = Color3.fromRGB(240, 240, 242),
        TextSecondary   = Color3.fromRGB(165, 165, 172),
        TextDisabled    = Color3.fromRGB(110, 110, 116),
        Accent          = Color3.fromRGB(200, 200, 205),
        Enabled         = Color3.fromRGB(70, 200, 120),
        Disabled        = Color3.fromRGB(55, 55, 60),
        Success         = Color3.fromRGB(70, 200, 120),
        Error           = Color3.fromRGB(230, 90, 90),
        Warning         = Color3.fromRGB(230, 180, 70),
    },
    Ocean = {
        Background      = Color3.fromRGB(240, 246, 250),
        SecondaryBg     = Color3.fromRGB(226, 237, 245),
        TertiaryBg      = Color3.fromRGB(208, 224, 236),
        Border          = Color3.fromRGB(176, 200, 218),
        TextPrimary     = Color3.fromRGB(18, 32, 42),
        TextSecondary   = Color3.fromRGB(70, 95, 115),
        TextDisabled    = Color3.fromRGB(140, 160, 175),
        Accent          = Color3.fromRGB(20, 110, 170),
        Enabled         = Color3.fromRGB(30, 160, 130),
        Disabled        = Color3.fromRGB(198, 214, 226),
        Success         = Color3.fromRGB(30, 160, 130),
        Error           = Color3.fromRGB(215, 90, 85),
        Warning         = Color3.fromRGB(220, 165, 55),
    },
    Forest = {
        Background      = Color3.fromRGB(244, 247, 240),
        SecondaryBg     = Color3.fromRGB(233, 238, 226),
        TertiaryBg      = Color3.fromRGB(219, 227, 208),
        Border          = Color3.fromRGB(191, 203, 176),
        TextPrimary     = Color3.fromRGB(26, 32, 20),
        TextSecondary   = Color3.fromRGB(85, 98, 72),
        TextDisabled    = Color3.fromRGB(150, 160, 138),
        Accent          = Color3.fromRGB(60, 100, 50),
        Enabled         = Color3.fromRGB(70, 160, 80),
        Disabled        = Color3.fromRGB(210, 220, 198),
        Success         = Color3.fromRGB(70, 160, 80),
        Error           = Color3.fromRGB(205, 95, 80),
        Warning         = Color3.fromRGB(210, 165, 60),
    },
    Monochrome = {
        Background      = Color3.fromRGB(18, 18, 18),
        SecondaryBg     = Color3.fromRGB(28, 28, 28),
        TertiaryBg      = Color3.fromRGB(40, 40, 40),
        Border          = Color3.fromRGB(60, 60, 60),
        TextPrimary     = Color3.fromRGB(245, 245, 245),
        TextSecondary   = Color3.fromRGB(170, 170, 170),
        TextDisabled    = Color3.fromRGB(105, 105, 105),
        Accent          = Color3.fromRGB(220, 220, 220),
        Enabled         = Color3.fromRGB(230, 230, 230),
        Disabled        = Color3.fromRGB(55, 55, 55),
        Success         = Color3.fromRGB(200, 200, 200),
        Error           = Color3.fromRGB(210, 100, 100),
        Warning         = Color3.fromRGB(200, 180, 120),
    },
    Apex = {
        Background      = Color3.fromRGB(20, 16, 14),
        SecondaryBg     = Color3.fromRGB(30, 24, 20),
        TertiaryBg      = Color3.fromRGB(42, 32, 24),
        Border          = Color3.fromRGB(90, 55, 30),
        TextPrimary     = Color3.fromRGB(250, 240, 230),
        TextSecondary   = Color3.fromRGB(210, 165, 130),
        TextDisabled    = Color3.fromRGB(140, 105, 85),
        Accent          = Color3.fromRGB(255, 140, 30),
        Enabled         = Color3.fromRGB(255, 140, 30),
        Disabled        = Color3.fromRGB(55, 45, 40),
        Success         = Color3.fromRGB(255, 160, 60),
        Error           = Color3.fromRGB(220, 90, 70),
        Warning         = Color3.fromRGB(240, 180, 70),
    },
}

-- Order shown in the Settings tab's theme dropdown
local THEME_NAMES = { "Vanilla", "Midnight", "Ocean", "Forest", "Monochrome", "Apex" }

-- Which decoration style each theme uses (see createDecoCluster below)
local DECO_STYLES = {
    Vanilla    = "flower",
    Midnight   = "stars",
    Ocean      = "bubbles",
    Forest     = "flower",
    Monochrome = "dots",
    Apex       = "embers",
}

-- `Theme` is mutated in place (never reassigned) so anything that captured
-- a reference to it keeps working after a theme switch.
local Theme = {}
for k, v in pairs(ThemePresets.Vanilla) do
    Theme[k] = v
end

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- ============================================================
-- THEME REGISTRY (lets a Settings-tab theme picker live-update
-- every already-built element, not just new ones)
-- ============================================================
local Registry = {}
local ThemeListeners = {}

local function themed(inst, prop, role)
    Registry[#Registry + 1] = { inst = inst, prop = prop, role = role }
    inst[prop] = Theme[role]
    return inst
end

local function onThemeChange(fn)
    ThemeListeners[#ThemeListeners + 1] = fn
end

local function RefreshTheme()
    for _, entry in ipairs(Registry) do
        if entry.inst and entry.inst.Parent then
            entry.inst[entry.prop] = Theme[entry.role]
        end
    end
    for _, fn in ipairs(ThemeListeners) do
        pcall(fn)
    end
end

local CurrentThemeName = "Vanilla"

local function SetTheme(name)
    local preset = ThemePresets[name]
    if not preset then return end
    CurrentThemeName = name
    for k, v in pairs(preset) do
        Theme[k] = v
    end
    RefreshTheme()
end

-- ============================================================
-- HELPERS
-- ============================================================
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

local function corner(radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function stroke(color, thickness)
    return new("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- Builds a 4-corner "scan bracket" icon entirely out of Frames (no ImageLabel,
-- no asset id) so it can never show up as a broken/missing-image square.
-- Returns the CanvasGroup container (fade the whole icon via GroupTransparency)
-- and the list of bar Frames (for the color-cycle tween).
local function createScanIcon(parent, size, color)
    color = color or Color3.fromRGB(255, 255, 255)
    local thickness = 2
    local armLen = math.floor(size * 0.4)

    local Icon = new("CanvasGroup", {
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        Parent = parent,
    })

    local bars = {}
    local anchors = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) }
    for _, anchor in ipairs(anchors) do
        local h = new("Frame", {
            AnchorPoint = anchor,
            Position = UDim2.new(anchor.X, 0, anchor.Y, 0),
            Size = UDim2.fromOffset(armLen, thickness),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = Icon,
        }, { corner(1) })
        local v = new("Frame", {
            AnchorPoint = anchor,
            Position = UDim2.new(anchor.X, 0, anchor.Y, 0),
            Size = UDim2.fromOffset(thickness, armLen),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = Icon,
        }, { corner(1) })
        table.insert(bars, h)
        table.insert(bars, v)
    end

    return Icon, bars
end

-- Slow, endless colour breathing across every bar of a createScanIcon()
-- result. Tracks its own tweens per-bar so a theme switch can cleanly
-- restart the animation with new colors instead of stacking tweens.
local IconTweens = setmetatable({}, { __mode = "k" })
local function cycleIconColor(bars, toColor)
    toColor = toColor or Color3.fromRGB(150, 150, 150)
    for _, bar in ipairs(bars) do
        if IconTweens[bar] then
            IconTweens[bar]:Cancel()
        end
        local t = TweenService:Create(
            bar,
            TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { BackgroundColor3 = toColor }
        )
        IconTweens[bar] = t
        t:Play()
    end
end

-- Purely decorative little flower made of Frames (a center dot + a ring of
-- petal dots) -- no image assets, so it can never show up broken. Returns
-- the container plus the petal/center instances so they can be themed.
local function createFlower(parent, petalSize, petalColor, centerColor)
    petalSize = petalSize or 8
    local centerSize = petalSize * 0.9
    local radius = petalSize * 1.1
    local boxSize = (radius + petalSize) * 2

    local Flower = new("Frame", {
        Size = UDim2.fromOffset(boxSize, boxSize),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local mid = boxSize / 2
    local petals = {}
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2
        local px = mid + math.cos(angle) * radius - petalSize / 2
        local py = mid + math.sin(angle) * radius - petalSize / 2
        local petal = new("Frame", {
            Size = UDim2.fromOffset(petalSize, petalSize),
            Position = UDim2.fromOffset(px, py),
            BackgroundColor3 = petalColor,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = Flower,
        }, { corner(math.floor(petalSize / 2)) })
        table.insert(petals, petal)
    end

    local center = new("Frame", {
        Size = UDim2.fromOffset(centerSize, centerSize),
        Position = UDim2.fromOffset(mid - centerSize / 2, mid - centerSize / 2),
        BackgroundColor3 = centerColor,
        BorderSizePixel = 0,
        Parent = Flower,
    }, { corner(math.floor(centerSize / 2)) })

    return Flower, petals, center
end

-- ============================================================
-- DECORATION STYLES (one look per theme, see DECO_STYLES above)
-- All are drawn from plain Frames -- no image assets, so nothing
-- can ever show up as a broken/missing square.
-- ============================================================

-- "stars" -- a small scatter of rotated-square sparkles (Midnight)
local function createStars(parent, size)
    local box = size * 4.5
    local Container = new("Frame", { Size = UDim2.fromOffset(box, box), BackgroundTransparency = 1, Parent = parent })
    local spots = { { 0, 0 }, { 1.6, 0.4 }, { 0.7, 1.6 } }
    for i, spot in ipairs(spots) do
        local s = size * (0.55 + (i * 0.15))
        local star = new("Frame", {
            Size = UDim2.fromOffset(s, s),
            Position = UDim2.fromOffset(spot[1] * size, spot[2] * size),
            Rotation = 45,
            BackgroundColor3 = Theme.Enabled,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = Container,
        }, { corner(2) })
        themed(star, "BackgroundColor3", "Enabled")
    end
    return Container
end

-- "bubbles" -- a loose cluster of soft circles (Ocean)
local function createBubbles(parent, size)
    local box = size * 5
    local Container = new("Frame", { Size = UDim2.fromOffset(box, box), BackgroundTransparency = 1, Parent = parent })
    local sizes = { size * 1.4, size * 0.9, size * 0.6 }
    for i, s in ipairs(sizes) do
        local bub = new("Frame", {
            Size = UDim2.fromOffset(s, s),
            Position = UDim2.fromOffset((i - 1) * size * 1.1, (i - 1) * size * 0.7),
            BackgroundColor3 = Theme.Enabled,
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            Parent = Container,
        }, { corner(math.floor(s / 2)) })
        themed(bub, "BackgroundColor3", "Enabled")
    end
    return Container
end

-- "dots" -- a minimal, evenly-spaced dot grid (Monochrome)
local function createDots(parent, size)
    local Container = new("Frame", { Size = UDim2.fromOffset(size * 4, size * 2), BackgroundTransparency = 1, Parent = parent })
    for i = 0, 3 do
        local dot = new("Frame", {
            Size = UDim2.fromOffset(size * 0.45, size * 0.45),
            Position = UDim2.fromOffset(i * size, (i % 2) * size * 0.6),
            BackgroundColor3 = Theme.TextDisabled,
            BorderSizePixel = 0,
            Parent = Container,
        }, { corner(2) })
        themed(dot, "BackgroundColor3", "TextDisabled")
    end
    return Container
end

-- "embers" -- warm orange sparks fading toward the edges (Apex)
local function createEmbers(parent, size)
    local box = size * 5
    local Container = new("Frame", { Size = UDim2.fromOffset(box, box), BackgroundTransparency = 1, Parent = parent })
    for i = 1, 4 do
        local s = size * (0.4 + (i % 3) * 0.3)
        local ember = new("Frame", {
            Size = UDim2.fromOffset(s, s),
            Position = UDim2.fromOffset((i - 1) * size * 1.2, (i % 2) * size * 1.3),
            BackgroundColor3 = Theme.Enabled,
            BackgroundTransparency = 0.25 + (i * 0.08),
            BorderSizePixel = 0,
            Parent = Container,
        }, { corner(math.floor(s / 2)) })
        themed(ember, "BackgroundColor3", "Enabled")
    end
    return Container
end

-- "flower" -- petals + center dot (Vanilla, Forest)
local function createFlowerDeco(parent, size)
    local Flower, petals, center = createFlower(parent, size, Theme.Enabled, Theme.Border)
    for _, p in ipairs(petals) do
        themed(p, "BackgroundColor3", "Enabled")
    end
    themed(center, "BackgroundColor3", "Border")
    return Flower
end

local DecoBuilders = {
    flower  = createFlowerDeco,
    stars   = createStars,
    bubbles = createBubbles,
    dots    = createDots,
    embers  = createEmbers,
}

local function makeDraggable(dragHandle, target, onTap)
    local dragging = false
    local moved = false
    local dragStart, startPos
    local lastInputPos

    local function applyPosition()
        if not dragging or not lastInputPos then return end
        local delta = lastInputPos - dragStart
        if delta.Magnitude > 4 then
            moved = true
        end
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            lastInputPos = input.Position
            startPos = target.Position

            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    endConn:Disconnect()
                    if not moved and onTap then
                        onTap()
                    end
                end
            end)
        end
    end)

    -- Listen globally (not just on dragHandle) so the drag keeps tracking
    -- even if the finger/cursor moves off the handle's bounds mid-drag.
    -- Only the latest input position is recorded here -- the actual move
    -- happens on RenderStepped below, once per rendered frame, so the
    -- drag stays smooth even if input events arrive unevenly.
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            lastInputPos = input.Position
        end
    end)

    RunService.RenderStepped:Connect(applyPosition)
end

-- ============================================================
-- LIBRARY
-- ============================================================
local StreamUI = {}
StreamUI.__index = StreamUI

function StreamUI:CreateWindow(title)
    -- clean up any previous instance so re-running the script doesn't stack windows
    local existing = PlayerGui:FindFirstChild("StreamUI")
    if existing then existing:Destroy() end

    local ScreenGui = new("ScreenGui", {
        Name = "StreamUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui,
    })

    -- Anything that needs to float above the scrollable tab content
    -- (like an open dropdown list) gets parented here instead, so it
    -- never gets clipped by a ScrollingFrame's bounds.
    local Overlay = new("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = ScreenGui,
    })

    local FULL_SIZE = UDim2.fromOffset(480, 320)
    local FULL_POS = UDim2.new(0.5, -240, 0.5, -160)
    local MINI_SIZE = UDim2.fromOffset(50, 40)
    local MINI_POS = UDim2.new(0, 10, 0, 10)

    local Main = new("Frame", {
        Name = "Main",
        Size = FULL_SIZE,
        Position = FULL_POS,
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = ScreenGui,
    })
    themed(Main, "BackgroundColor3", "Background")
    corner(10).Parent = Main
    themed(stroke(Theme.Border, 1), "Color", "Border").Parent = Main

    -- Apex theme only: an orange -> black diagonal gradient wash across
    -- the window, layered on top of the flat background color.
    local ApexGradient = new("Frame", {
        Name = "ApexGradient",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 140, 30),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 0,
        Visible = false,
        Parent = Main,
    }, { corner(10) })
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 30)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 60, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 6)),
        }),
        Rotation = 115,
        Parent = ApexGradient,
    })
    onThemeChange(function()
        ApexGradient.Visible = (CurrentThemeName == "Apex")
    end)

    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.SecondaryBg,
        Parent = Main,
    }, { corner(10) })
    themed(TopBar, "BackgroundColor3", "SecondaryBg")

    -- square off the bottom corners of the top bar so it blends with Main
    local topBarBlend = new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.SecondaryBg,
        BorderSizePixel = 0,
        Parent = TopBar,
    })
    themed(topBarBlend, "BackgroundColor3", "SecondaryBg")

    local accentLine = new("Frame", {
        Name = "AccentLine",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.fromOffset(0, 40),
        BackgroundColor3 = Theme.Enabled,
        BorderSizePixel = 0,
        Parent = Main,
    })
    themed(accentLine, "BackgroundColor3", "Enabled")

    local LogoBadge = new("Frame", {
        Name = "LogoBadge",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Theme.TertiaryBg,
        Parent = TopBar,
    }, { corner(14) })
    themed(LogoBadge, "BackgroundColor3", "TertiaryBg")

    local LogoIcon, LogoBars = createScanIcon(LogoBadge, 16)
    LogoIcon.Position = UDim2.new(0.5, -8, 0.5, -8)

    local function applyBadgeTheme(bars)
        for _, bar in ipairs(bars) do
            bar.BackgroundColor3 = Theme.TextPrimary
        end
        cycleIconColor(bars, Theme.TextSecondary)
    end
    applyBadgeTheme(LogoBars)
    onThemeChange(function() applyBadgeTheme(LogoBars) end)

    local TitleLabel = new("TextLabel", {
        Text = title or "StreamUI",
        Font = FONT_BOLD,
        TextSize = 15,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 0),
        Size = UDim2.new(0, 180, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })
    themed(TitleLabel, "TextColor3", "TextPrimary")

    local MinimizeBtn = new("TextButton", {
        Text = "—",
        Font = FONT_BOLD,
        TextSize = 16,
        TextColor3 = Theme.TextPrimary,
        BackgroundColor3 = Theme.TertiaryBg,
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -34, 0.5, -12),
        Parent = TopBar,
    }, { corner(6) })
    themed(MinimizeBtn, "TextColor3", "TextPrimary")
    themed(MinimizeBtn, "BackgroundColor3", "TertiaryBg")

    makeDraggable(TopBar, Main)

    local TabBar = new("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(0, 120, 1, -58),
        Position = UDim2.fromOffset(0, 50),
        BackgroundColor3 = Theme.SecondaryBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Main,
    }, { corner(8) })
    themed(TabBar, "BackgroundColor3", "SecondaryBg")
    themed(TabBar, "ScrollBarImageColor3", "Border")

    local TabList = new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    TabList.Parent = TabBar
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
        Parent = TabBar,
    })

    local PageHolder = new("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, -136, 1, -58),
        Position = UDim2.fromOffset(128, 50),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local MiniBadge = new("Frame", {
        Name = "MiniBadge",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.TertiaryBg,
        Visible = false,
        Parent = Main,
    }, { corner(14) })
    themed(MiniBadge, "BackgroundColor3", "TertiaryBg")

    local MiniIcon, MiniBars = createScanIcon(MiniBadge, 20)
    MiniIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
    MiniIcon.GroupTransparency = 1
    applyBadgeTheme(MiniBars)
    onThemeChange(function() applyBadgeTheme(MiniBars) end)

    local MiniBadgeButton = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = MiniBadge,
    })

    -- ---------------- DECORATIONS (theme-matched) ----------------
    -- Purely cosmetic, sits behind the row content (ZIndex 0) so it only
    -- shows through empty space and never covers a control. Rebuilt
    -- whenever the theme changes, and hidden while minimized.
    local DecoContainers = {}
    local isMinimized = false

    local function clearDecorations()
        for _, c in ipairs(DecoContainers) do
            if c and c.Parent then c:Destroy() end
        end
        DecoContainers = {}
    end

    local DECO_SPOTS = {
        { x = 360, y = 258, size = 8 },
        { x = 390, y = 275, size = 6 },
        { x = 150, y = 265, size = 6 },
    }

    local function buildDecorations()
        clearDecorations()
        local builder = DecoBuilders[DECO_STYLES[CurrentThemeName] or "flower"]
        if not builder then return end
        for _, spot in ipairs(DECO_SPOTS) do
            local container = builder(Main, spot.size)
            container.Position = UDim2.fromOffset(spot.x, spot.y)
            container.ZIndex = 0
            container.Visible = not isMinimized
            table.insert(DecoContainers, container)
        end
    end

    buildDecorations()
    onThemeChange(buildDecorations)

    local function setDecorationsVisible(visible)
        for _, c in ipairs(DecoContainers) do
            c.Visible = visible
        end
    end

    local function toggleMinimize()
        isMinimized = not isMinimized

        if isMinimized then
            -- MINIMIZE: shrink to a small logo badge in the top-left, Quint out over 0.4s
            tween(Main, { Size = MINI_SIZE, Position = MINI_POS }, 0.4)
            TabBar.Visible = false
            PageHolder.Visible = false
            TopBar.Visible = false
            accentLine.Visible = false
            setDecorationsVisible(false)

            MiniBadge.Visible = true
            MiniIcon.GroupTransparency = 1
            tween(MiniIcon, { GroupTransparency = 0 }, 0.4)

            MinimizeBtn.Text = "+"
        else
            -- EXPAND: grow back to the full window, centered, Quint out over 0.4s
            tween(Main, { Size = FULL_SIZE, Position = FULL_POS }, 0.4)
            tween(MiniIcon, { GroupTransparency = 1 }, 0.2)

            task.delay(0.2, function()
                MiniBadge.Visible = false
                TabBar.Visible = true
                PageHolder.Visible = true
                TopBar.Visible = true
                accentLine.Visible = true
                setDecorationsVisible(true)
            end)

            MinimizeBtn.Text = "—"
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(toggleMinimize)
    makeDraggable(MiniBadgeButton, Main, function()
        if isMinimized then toggleMinimize() end
    end)

    local Window = setmetatable({ _tabs = {}, _pages = {}, _selectors = {}, ScreenGui = ScreenGui }, { __index = StreamUI })

    onThemeChange(function()
        for i, page in ipairs(Window._pages) do
            if page.Visible and Window._selectors[i] then
                Window._selectors[i]()
            end
        end
    end)

    -- ---------------- TAB ----------------
    -- `nameOrConfig` accepts either a plain string ("Main") or a table
    -- { Name = "Main", Icon = "rbxassetid://..." } if you want a tab icon.
    function Window:CreateTab(nameOrConfig)
        local name, icon
        if type(nameOrConfig) == "table" then
            name, icon = nameOrConfig.Name, nameOrConfig.Icon
        else
            name = nameOrConfig
        end

        local TabButton = new("TextButton", {
            Text = "",
            Font = FONT,
            TextSize = 13,
            TextColor3 = Theme.TextSecondary,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(1, 0, 0, 30),
            AutoButtonColor = false,
            Parent = TabBar,
        }, { corner(6) })

        local TabRow = new("Frame", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Parent = TabButton,
        })
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }).Parent = TabRow

        local TabLabel = new("TextLabel", {
            Text = name,
            Font = FONT,
            TextSize = 13,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, icon and -24 or 0, 1, 0),
            TextXAlignment = icon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
            LayoutOrder = 2,
            Parent = TabRow,
        })

        local TabIcon
        if icon then
            TabIcon = new("ImageLabel", {
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Image = icon,
                ImageColor3 = Theme.TextSecondary,
                LayoutOrder = 1,
                Parent = TabRow,
            })
        end

        local Page = new("ScrollingFrame", {
            Name = name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = PageHolder,
        })
        local PageList = new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        PageList.Parent = Page

        local function selectTab()
            for _, p in pairs(self._pages) do p.Visible = false end
            for _, b in pairs(self._tabs) do
                b.Instance.BackgroundColor3 = Theme.Background
                b.Label.TextColor3 = Theme.TextSecondary
                if b.Icon then b.Icon.ImageColor3 = Theme.TextSecondary end
            end
            Page.Visible = true
            TabButton.BackgroundColor3 = Theme.TertiaryBg
            TabLabel.TextColor3 = Theme.TextPrimary
            if TabIcon then TabIcon.ImageColor3 = Theme.TextPrimary end
        end

        TabButton.MouseButton1Click:Connect(selectTab)
        table.insert(self._tabs, { Instance = TabButton, Label = TabLabel, Icon = TabIcon })
        table.insert(self._pages, Page)
        table.insert(self._selectors, selectTab)

        if #self._pages == 1 then selectTab() end

        local Tab = {}

        -- row wrapper shared by all elements
        local function baseRow(height)
            local row = new("Frame", {
                Size = UDim2.new(1, -8, 0, height),
                BackgroundColor3 = Theme.SecondaryBg,
                Parent = Page,
            }, { corner(6), new("UIPadding", {
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            }) })
            themed(row, "BackgroundColor3", "SecondaryBg")
            return row
        end

        -- ---------------- TOGGLE ----------------
        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local Row = baseRow(34)

            themed(new("TextLabel", {
                Text = cfg.Title or "Toggle",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextPrimary")

            local Switch = new("TextButton", {
                Text = "",
                Size = UDim2.fromOffset(38, 20),
                Position = UDim2.new(1, -38, 0.5, -10),
                BackgroundColor3 = cfg.Default and Theme.Enabled or Theme.Disabled,
                AutoButtonColor = false,
                Parent = Row,
            }, { corner(10) })

            local Knob = new("Frame", {
                Size = UDim2.fromOffset(16, 16),
                Position = cfg.Default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Theme.Background,
                Parent = Switch,
            }, { corner(8) })

            local state = cfg.Default or false
            local function animateToggle(value)
                state = value
                TweenService:Create(Switch, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = state and Theme.Enabled or Theme.Disabled,
                }):Play()
                TweenService:Create(Knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                }):Play()
                if cfg.Callback then cfg.Callback(state) end
            end

            -- Switch/knob colors depend on current on/off state, so they
            -- can't be a plain themed() copy -- recompute on theme switch.
            onThemeChange(function()
                Switch.BackgroundColor3 = state and Theme.Enabled or Theme.Disabled
                Knob.BackgroundColor3 = Theme.Background
            end)

            Switch.MouseButton1Click:Connect(function()
                animateToggle(not state)
            end)

            if cfg.Callback then cfg.Callback(state) end
            return { Set = function(_, v) Switch.MouseButton1Click:Fire() end }
        end

        -- ---------------- SLIDER ----------------
        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local min, max = cfg.Min or 0, cfg.Max or 100
            local value = cfg.Default or min

            local Row = baseRow(44)

            themed(new("TextLabel", {
                Text = cfg.Title or "Slider",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextPrimary")

            local ValueLabel = themed(new("TextLabel", {
                Text = tostring(value),
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(50, 20),
                Position = UDim2.new(1, -50, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Row,
            }), "TextColor3", "TextSecondary")

            local Track = new("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.fromOffset(0, 28),
                BackgroundColor3 = Theme.TertiaryBg,
                Parent = Row,
            }, { corner(3) })
            themed(Track, "BackgroundColor3", "TertiaryBg")

            local Fill = new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Enabled,
                Parent = Track,
            }, { corner(3) })
            themed(Fill, "BackgroundColor3", "Enabled")

            local dragging = false
            local function setFromX(x)
                local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * rel)
                Fill.Size = UDim2.new(rel, 0, 1, 0)
                ValueLabel.Text = tostring(value)
                if cfg.Callback then cfg.Callback(value) end
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    setFromX(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            if cfg.Callback then cfg.Callback(value) end
        end

        -- ---------------- DROPDOWN ----------------
        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local options = cfg.Options or {}
            local selected = cfg.Default

            local Row = baseRow(34)

            themed(new("TextLabel", {
                Text = cfg.Title or "Dropdown",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextPrimary")

            local Selector = new("TextButton", {
                Text = (selected or "Select") .. "  v",
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundColor3 = Theme.TertiaryBg,
                Size = UDim2.new(0.5, -4, 0, 24),
                Position = UDim2.new(0.5, 4, 0.5, -12),
                Parent = Row,
            }, { corner(6) })
            themed(Selector, "TextColor3", "TextSecondary")
            themed(Selector, "BackgroundColor3", "TertiaryBg")

            -- Rendered on the Overlay (a direct child of ScreenGui) instead of
            -- inside the scrollable page, so it floats on top and is never
            -- clipped/cut off by the page's ScrollingFrame bounds.
            local ListFrame = new("Frame", {
                Size = UDim2.fromOffset(0, 0),
                BackgroundColor3 = Theme.Background,
                Visible = false,
                ZIndex = 60,
                Parent = Overlay,
            }, { corner(6) })
            themed(ListFrame, "BackgroundColor3", "Background")
            themed(stroke(Theme.Border, 1), "Color", "Border").Parent = ListFrame

            local ListLayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
            ListLayout.Parent = ListFrame

            -- Invisible full-screen button behind the list so tapping
            -- anywhere else closes the dropdown.
            local Catcher = new("TextButton", {
                Text = "",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Visible = false,
                ZIndex = 55,
                Parent = Overlay,
            })

            local function closeList()
                ListFrame.Visible = false
                Catcher.Visible = false
            end

            local function openList()
                local pos = Selector.AbsolutePosition
                local size = Selector.AbsoluteSize
                ListFrame.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 2)
                ListFrame.Size = UDim2.fromOffset(size.X, math.min(#options, 5) * 24)
                ListFrame.Visible = true
                Catcher.Visible = true
            end

            Catcher.MouseButton1Click:Connect(closeList)

            for _, opt in ipairs(options) do
                local OptButton = new("TextButton", {
                    Text = opt,
                    Font = FONT,
                    TextSize = 12,
                    TextColor3 = Theme.TextPrimary,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 24),
                    ZIndex = 60,
                    Parent = ListFrame,
                })
                themed(OptButton, "TextColor3", "TextPrimary")
                themed(OptButton, "BackgroundColor3", "Background")
                OptButton.MouseButton1Click:Connect(function()
                    selected = opt
                    Selector.Text = opt .. "  v"
                    closeList()
                    if cfg.Callback then cfg.Callback(opt) end
                end)
            end

            Selector.MouseButton1Click:Connect(function()
                if ListFrame.Visible then
                    closeList()
                else
                    openList()
                end
            end)

            if cfg.Callback and selected then cfg.Callback(selected) end
        end

        -- ---------------- BUTTON ----------------
        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local Row = baseRow(34)
            local Btn = new("TextButton", {
                Text = cfg.Title or "Button",
                Font = FONT_BOLD,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = Row,
            })
            themed(Btn, "TextColor3", "TextPrimary")
            Btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)
        end

        -- ---------------- KEYBIND ----------------
        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local currentKey = cfg.Default or Enum.KeyCode.Unknown
            local listening = false

            local Row = baseRow(34)

            themed(new("TextLabel", {
                Text = cfg.Title or "Keybind",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextPrimary")

            local KeyButton = new("TextButton", {
                Text = currentKey.Name,
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundColor3 = Theme.TertiaryBg,
                Size = UDim2.fromOffset(70, 22),
                Position = UDim2.new(1, -70, 0.5, -11),
                Parent = Row,
            }, { corner(6) })
            themed(KeyButton, "TextColor3", "TextSecondary")
            themed(KeyButton, "BackgroundColor3", "TertiaryBg")

            KeyButton.MouseButton1Click:Connect(function()
                listening = true
                KeyButton.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input, processed)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    KeyButton.Text = currentKey.Name
                    listening = false
                elseif not processed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                    if cfg.Callback then cfg.Callback() end
                end
            end)
        end

        -- ---------------- TEXTBOX ----------------
        function Tab:CreateTextbox(cfg)
            cfg = cfg or {}
            local Row = baseRow(34)

            themed(new("TextLabel", {
                Text = cfg.Title or "Textbox",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextPrimary")

            local Box = new("TextBox", {
                Text = cfg.Default or "",
                PlaceholderText = cfg.Placeholder or "Enter text...",
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextPrimary,
                PlaceholderColor3 = Theme.TextDisabled,
                BackgroundColor3 = Theme.TertiaryBg,
                ClearTextOnFocus = false,
                Size = UDim2.new(0.6, -4, 0, 24),
                Position = UDim2.new(0.4, 4, 0.5, -12),
                Parent = Row,
            }, { corner(6), new("UIPadding", {
                PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
            }) })
            themed(Box, "TextColor3", "TextPrimary")
            themed(Box, "PlaceholderColor3", "TextDisabled")
            themed(Box, "BackgroundColor3", "TertiaryBg")

            Box.FocusLost:Connect(function(enterPressed)
                if cfg.Callback then
                    cfg.Callback(Box.Text, enterPressed)
                end
            end)

            return {
                Set = function(_, text) Box.Text = text end,
                Get = function() return Box.Text end,
            }
        end

        -- ---------------- LABEL ----------------
        function Tab:CreateLabel(text)
            local Row = baseRow(26)
            themed(new("TextLabel", {
                Text = text or "",
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            }), "TextColor3", "TextSecondary")
        end

        return Tab
    end

    -- ---------------- SETTINGS TAB (built-in theme picker) ----------------
    do
        local SettingsTab = Window:CreateTab("Settings")
        SettingsTab:CreateLabel("Appearance")
        SettingsTab:CreateDropdown({
            Title = "Theme",
            Options = THEME_NAMES,
            Default = "Vanilla",
            Callback = function(name)
                SetTheme(name)
            end,
        })
    end

    -- ---------------- NOTIFICATION ----------------
    function Window:Notify(title, text, duration)
        local NotifHolder = ScreenGui:FindFirstChild("Notifications") or new("Frame", {
            Name = "Notifications",
            Size = UDim2.fromOffset(260, 0),
            Position = UDim2.new(1, -270, 0, 10),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = ScreenGui,
        }, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

        local Notif = new("Frame", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0,
            Parent = NotifHolder,
        }, {
            corner(8), stroke(Theme.Border, 1),
            new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingRight = UDim.new(0, 10) }),
        })

        new("TextLabel", {
            Text = title or "Notice",
            Font = FONT_BOLD,
            TextSize = 13,
            TextColor3 = Theme.TextPrimary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Notif,
        })
        new("TextLabel", {
            Text = text or "",
            Font = FONT,
            TextSize = 12,
            TextColor3 = Theme.TextSecondary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            Position = UDim2.fromOffset(0, 20),
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Notif,
        })

        task.delay(duration or 3, function()
            tween(Notif, { BackgroundTransparency = 1 }, 0.3)
            task.wait(0.3)
            Notif:Destroy()
        end)
    end

    return Window
end

return StreamUI

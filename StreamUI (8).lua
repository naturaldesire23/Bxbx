-- ╔══════════════════════════════════════╗
-- ║        COMET SS UI LIBRARY           ║
-- ║        Version 2.0 | Roblox          ║
-- ╚══════════════════════════════════════╝

local Comet = {}
Comet.__index = Comet

-- ─── SERVICES ─────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ─── THEME PRESETS ────────────────────────────────────────
local Themes = {
    Comet   = { Accent = Color3.fromHex("#6C63FF"), BG = Color3.fromHex("#1A1C2E"), Panel = Color3.fromHex("#22253A"), Border = Color3.fromHex("#2A2E45") },
    Crimson = { Accent = Color3.fromHex("#FF4A4A"), BG = Color3.fromHex("#0F1923"), Panel = Color3.fromHex("#1A1F2E"), Border = Color3.fromHex("#25202F") },
    Neon    = { Accent = Color3.fromHex("#00FFCC"), BG = Color3.fromHex("#0D1117"), Panel = Color3.fromHex("#111820"), Border = Color3.fromHex("#162028") },
    Gold    = { Accent = Color3.fromHex("#F59E0B"), BG = Color3.fromHex("#18181B"), Panel = Color3.fromHex("#1F1F23"), Border = Color3.fromHex("#2A2A2E") },
    Ice     = { Accent = Color3.fromHex("#38BDF8"), BG = Color3.fromHex("#0A0E1A"), Panel = Color3.fromHex("#0F1520"), Border = Color3.fromHex("#15202E") },
    Grape   = { Accent = Color3.fromHex("#C084FC"), BG = Color3.fromHex("#1A0D2E"), Panel = Color3.fromHex("#21103A"), Border = Color3.fromHex("#2D1548") },
    Matrix  = { Accent = Color3.fromHex("#4ADE80"), BG = Color3.fromHex("#0D1F0D"), Panel = Color3.fromHex("#111F11"), Border = Color3.fromHex("#1A2E1A") },
    Mono    = { Accent = Color3.fromHex("#E2E8F0"), BG = Color3.fromHex("#1C1C1C"), Panel = Color3.fromHex("#242424"), Border = Color3.fromHex("#2E2E2E") },
}

-- ─── DEFAULTS ─────────────────────────────────────────────
local Config = {
    Theme        = "Comet",
    ToggleKey    = Enum.KeyCode.RightShift,
    Transparency = 0.08,
    BlurAmount   = 10,
}

-- ─── UTILITY ──────────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function MakeCorner(radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function MakePadding(t, b, l, r)
    return Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft   = UDim.new(0, l or 8),
        PaddingRight  = UDim.new(0, r or 8),
    })
end

local function MakeStroke(color, thickness, transparency)
    return Create("UIStroke", {
        Color        = color,
        Thickness    = thickness or 1,
        Transparency = transparency or 0.7,
    })
end

local function MakeListLayout(dir, padding, ha, va)
    return Create("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, padding or 4),
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = va or Enum.VerticalAlignment.Top,
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
end

-- ─── DRAGGABLE ────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─── RIPPLE EFFECT ────────────────────────────────────────
local function Ripple(parent, accent)
    local ripple = Create("Frame", {
        Size            = UDim2.new(0, 0, 0, 0),
        Position        = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint     = Vector2.new(0.5, 0.5),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.6,
        ZIndex          = parent.ZIndex + 10,
        Parent          = parent,
    }, { MakeCorner(999) })

    Tween(ripple, { Size = UDim2.new(1.5, 0, 1.5, 0), BackgroundTransparency = 1 }, 0.45)
    game:GetService("Debris"):AddItem(ripple, 0.5)
end

-- ─── TOAST NOTIFICATION ───────────────────────────────────
local ToastGui

local function ShowToast(screenGui, message, duration)
    if ToastGui then ToastGui:Destroy() end
    duration = duration or 2.5
    local theme = Themes[Config.Theme]

    ToastGui = Create("Frame", {
        Size             = UDim2.new(0, 240, 0, 34),
        Position         = UDim2.new(0.5, -120, 1, -60),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.05,
        ZIndex           = 999,
        Parent           = screenGui,
    }, {
        MakeCorner(7),
        MakeStroke(theme.Accent, 1, 0.4),
        MakePadding(0, 0, 12, 12),
        Create("Frame", {
            Size             = UDim2.new(0, 5, 0, 5),
            Position         = UDim2.new(0, 12, 0.5, -2.5),
            BackgroundColor3 = theme.Accent,
            ZIndex           = 1000,
        }, { MakeCorner(99) }),
        Create("TextLabel", {
            Size             = UDim2.new(1, -28, 1, 0),
            Position         = UDim2.new(0, 26, 0, 0),
            BackgroundTransparency = 1,
            Text             = message,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 1000,
        }),
    })

    ToastGui.Position = UDim2.new(0.5, -120, 1, 20)
    Tween(ToastGui, { Position = UDim2.new(0.5, -120, 1, -60) }, 0.3)

    task.delay(duration, function()
        if ToastGui then
            Tween(ToastGui, { Position = UDim2.new(0.5, -120, 1, 20) }, 0.25)
            task.delay(0.3, function()
                if ToastGui then ToastGui:Destroy() end
            end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- ─── WINDOW ───────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════

function Comet.new(options)
    options = options or {}
    local theme = Themes[options.Theme or Config.Theme]
    Config.Theme = options.Theme or Config.Theme

    local self = setmetatable({}, Comet)
    self.Theme   = theme
    self.Tabs    = {}
    self.Visible = true
    self.ToggleKey = options.ToggleKey or Config.ToggleKey

    -- ScreenGui
    local screenGui = Create("ScreenGui", {
        Name            = options.Name or "CometUI",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        Parent          = (syn and syn.protect_gui) and syn.protect_gui(Instance.new("ScreenGui")) or LocalPlayer:WaitForChild("PlayerGui"),
    })
    -- re-parent if protectable
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    end

    self.ScreenGui = screenGui

    -- Background blur
    self.BlurEffect = Create("BlurEffect", {
        Size   = 0,
        Parent = game:GetService("Lighting"),
    })

    -- ─── BACKGROUND IMAGE SUPPORT ─────────────────────────
    self.BgFrame = Create("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = theme.BG,
        BackgroundTransparency = 0,
        ZIndex                 = 1,
        Visible                = false,
        Parent                 = screenGui,
    })

    self.BgImage = Create("ImageLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScaleType              = Enum.ScaleType.Crop,
        ImageTransparency      = 0.3,
        ZIndex                 = 2,
        Visible                = false,
        Parent                 = screenGui,
    })

    -- ─── MAIN WINDOW FRAME ────────────────────────────────
    local window = Create("Frame", {
        Name             = "Window",
        Size             = UDim2.new(0, options.Width or 560, 0, options.Height or 400),
        Position         = UDim2.new(0.5, -(options.Width or 560)/2, 0.5, -(options.Height or 400)/2),
        BackgroundColor3 = theme.BG,
        BackgroundTransparency = Config.Transparency,
        ZIndex           = 10,
        Parent           = screenGui,
    }, {
        MakeCorner(10),
        MakeStroke(theme.Accent, 1, 0.6),
    })
    self.Window = window

    -- ─── TITLEBAR ─────────────────────────────────────────
    local titleBar = Create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.1,
        ZIndex           = 11,
        Parent           = window,
    }, {
        MakeCorner(10),
        MakePadding(0, 0, 10, 10),
    })

    -- Bottom cover for titlebar corners
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.1,
        ZIndex           = 11,
        Parent           = titleBar,
    })

    -- Logo dot
    Create("Frame", {
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = UDim2.new(0, 10, 0.5, -9),
        BackgroundColor3 = theme.Accent,
        ZIndex           = 12,
        Parent           = titleBar,
    }, {
        MakeCorner(5),
        Create("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "C",
            TextColor3             = Color3.new(1,1,1),
            TextSize               = 10,
            Font                   = Enum.Font.GothamBold,
            ZIndex                 = 13,
        })
    })

    -- Title
    Create("TextLabel", {
        Name             = "Title",
        Size             = UDim2.new(0, 200, 1, 0),
        Position         = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Text             = options.Title or "Comet SS",
        TextColor3       = Color3.fromHex("#E2E8F0"),
        TextSize         = 13,
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 12,
        Parent           = titleBar,
    })

    -- Subtitle
    Create("TextLabel", {
        Name             = "Subtitle",
        Size             = UDim2.new(0, 200, 1, 0),
        Position         = UDim2.new(0, 36 + 95, 0, 0),
        BackgroundTransparency = 1,
        Text             = options.Subtitle or "Executor",
        TextColor3       = theme.Accent,
        TextSize         = 11,
        Font             = Enum.Font.GothamMedium,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 12,
        Parent           = titleBar,
    })

    -- Window Controls (close + minimize)
    local controlsFrame = Create("Frame", {
        Size             = UDim2.new(0, 54, 0, 20),
        Position         = UDim2.new(1, -64, 0.5, -10),
        BackgroundTransparency = 1,
        ZIndex           = 12,
        Parent           = titleBar,
    })

    -- Minimize Button
    local minBtn = Create("TextButton", {
        Size             = UDim2.new(0, 24, 0, 20),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.3,
        Text             = "─",
        TextColor3       = Color3.fromHex("#94A3B8"),
        TextSize         = 10,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 13,
        Parent           = controlsFrame,
    }, { MakeCorner(5) })
    self.MinimizeBtn = minBtn

    -- Close Button
    local closeBtn = Create("TextButton", {
        Size             = UDim2.new(0, 24, 0, 20),
        Position         = UDim2.new(0, 28, 0, 0),
        BackgroundColor3 = Color3.fromHex("#2A1A1A"),
        BackgroundTransparency = 0.2,
        Text             = "✕",
        TextColor3       = Color3.fromHex("#94A3B8"),
        TextSize         = 10,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 13,
        Parent           = controlsFrame,
    }, { MakeCorner(5) })
    self.CloseBtn = closeBtn

    -- Button hover effects
    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, { BackgroundColor3 = Color3.fromHex("#F59E0B"), TextColor3 = Color3.new(1,1,1) })
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, { BackgroundColor3 = theme.Border, TextColor3 = Color3.fromHex("#94A3B8") })
    end)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromHex("#F87171"), TextColor3 = Color3.new(1,1,1) })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromHex("#2A1A1A"), TextColor3 = Color3.fromHex("#94A3B8") })
    end)

    -- Minimize logic
    local minimized = false
    local originalSize = window.Size

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            originalSize = window.Size
            Tween(window, { Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 36) })
            ShowToast(screenGui, "Minimized")
        else
            Tween(window, { Size = originalSize })
            ShowToast(screenGui, "Restored")
        end
    end)

    -- Close logic
    closeBtn.MouseButton1Click:Connect(function()
        Tween(window, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.2)
        task.delay(0.25, function()
            self.Visible = false
            window.Visible = false
        end)
        ShowToast(screenGui, "UI Closed — press " .. tostring(self.ToggleKey) .. " to reopen")
    end)

    MakeDraggable(titleBar, window)

    -- ─── TABS BAR ─────────────────────────────────────────
    local tabBar = Create("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(1, 0, 0, 32),
        Position         = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.3,
        ZIndex           = 11,
        Parent           = window,
    }, {
        Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0.7,
            ZIndex           = 12,
        }),
        Create("UIListLayout", {
            FillDirection       = Enum.FillDirection.Horizontal,
            Padding             = UDim.new(0, 2),
            VerticalAlignment   = Enum.VerticalAlignment.Center,
            SortOrder           = Enum.SortOrder.LayoutOrder,
        }),
        MakePadding(0, 0, 6, 6),
    })
    self.TabBar = tabBar

    -- ─── CONTENT FRAME ────────────────────────────────────
    local content = Create("Frame", {
        Name             = "Content",
        Size             = UDim2.new(1, 0, 1, -68),
        Position         = UDim2.new(0, 0, 0, 68),
        BackgroundTransparency = 1,
        ZIndex           = 11,
        Parent           = window,
        ClipsDescendants = true,
    })
    self.Content = content

    -- ─── STATUS BAR ───────────────────────────────────────
    local statusBar = Create("Frame", {
        Name             = "StatusBar",
        Size             = UDim2.new(1, 0, 0, 22),
        Position         = UDim2.new(0, 0, 1, -22),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.1,
        ZIndex           = 11,
        Parent           = window,
    }, { MakeCorner(10), MakePadding(0, 0, 10, 10) })

    -- Trim top corners of status bar
    Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 0.1,
        ZIndex           = 11,
        Parent           = statusBar,
    })

    local statusDot = Create("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 10, 0.5, -3),
        BackgroundColor3 = Color3.fromHex("#4ADE80"),
        ZIndex           = 12,
        Parent           = statusBar,
    }, { MakeCorner(99) })
    self.StatusDot = statusDot

    self.StatusLabel = Create("TextLabel", {
        Size             = UDim2.new(1, -24, 1, 0),
        Position         = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1,
        Text             = "Attached  •  Comet SS v2.0",
        TextColor3       = Color3.fromHex("#475569"),
        TextSize         = 10,
        Font             = Enum.Font.GothamMedium,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 12,
        Parent           = statusBar,
    })

    content.Size = UDim2.new(1, 0, 1, -90)

    -- ─── TOGGLE KEY ───────────────────────────────────────
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self.Visible = not self.Visible
            window.Visible = self.Visible
            if self.Visible then
                Tween(window, { Size = originalSize or window.Size })
                minimized = false
            end
        end
    end)

    self.ScreenGui     = screenGui
    self._activeTab    = nil
    self._tabButtons   = {}
    self._tabPanes     = {}

    return self
end

-- ═══════════════════════════════════════════════════════════
-- ─── ADD TAB ──────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════

function Comet:AddTab(name, icon)
    local theme = self.Theme
    local tabIndex = #self._tabButtons + 1

    -- Tab button
    local tabBtn = Create("TextButton", {
        Name             = name .. "Tab",
        Size             = UDim2.new(0, 0, 1, -6),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = theme.Panel,
        BackgroundTransparency = 1,
        Text             = "",
        ZIndex           = 12,
        LayoutOrder      = tabIndex,
        Parent           = self.TabBar,
    }, {
        MakeCorner(5),
        MakePadding(0, 0, 8, 8),
        Create("UIListLayout", {
            FillDirection       = Enum.FillDirection.Horizontal,
            Padding             = UDim.new(0, 5),
            VerticalAlignment   = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder           = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- Tab icon (optional asset id)
    if icon then
        Create("ImageLabel", {
            Size                   = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Image                  = (type(icon) == "number") and ("rbxassetid://" .. icon) or icon,
            ImageColor3            = Color3.fromHex("#94A3B8"),
            ZIndex                 = 13,
            LayoutOrder            = 1,
            Parent                 = tabBtn,
        })
    end

    local tabLabel = Create("TextLabel", {
        Size                   = UDim2.new(0, 0, 1, 0),
        AutomaticSize          = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text                   = name,
        TextColor3             = Color3.fromHex("#94A3B8"),
        TextSize               = 11,
        Font                   = Enum.Font.GothamMedium,
        ZIndex                 = 13,
        LayoutOrder            = 2,
        Parent                 = tabBtn,
    })

    local tabUnderline = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 1,
        ZIndex           = 13,
        Parent           = tabBtn,
    }, { MakeCorner(2) })

    -- Tab pane (scrollable)
    local pane = Create("ScrollingFrame", {
        Name                  = name .. "Pane",
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible               = false,
        ZIndex                = 11,
        ScrollBarThickness    = 3,
        ScrollBarImageColor3  = theme.Accent,
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        Parent                = self.Content,
    }, {
        MakeListLayout(nil, 5),
        MakePadding(8, 8, 8, 8),
    })

    -- Tab click
    tabBtn.MouseButton1Click:Connect(function()
        self:_selectTab(name)
        Ripple(tabBtn, theme.Accent)
    end)

    tabBtn.MouseEnter:Connect(function()
        if self._activeTab ~= name then
            Tween(tabLabel, { TextColor3 = Color3.fromHex("#E2E8F0") })
            Tween(tabBtn, { BackgroundTransparency = 0.7 })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self._activeTab ~= name then
            Tween(tabLabel, { TextColor3 = Color3.fromHex("#94A3B8") })
            Tween(tabBtn, { BackgroundTransparency = 1 })
        end
    end)

    self._tabButtons[name] = { btn = tabBtn, label = tabLabel, underline = tabUnderline, icon = icon }
    self._tabPanes[name]   = pane
    table.insert(self.Tabs, name)

    -- Auto-select first tab
    if #self.Tabs == 1 then self:_selectTab(name) end

    -- Return section builder
    return self:_makeTabAPI(name, pane)
end

function Comet:_selectTab(name)
    self._activeTab = name
    local theme = self.Theme

    for tabName, data in pairs(self._tabButtons) do
        local active = tabName == name
        Tween(data.label, { TextColor3 = active and theme.Accent or Color3.fromHex("#94A3B8") })
        Tween(data.btn,   { BackgroundTransparency = active and 0.6 or 1, BackgroundColor3 = active and theme.Accent or theme.Panel })
        Tween(data.underline, { BackgroundTransparency = active and 0 or 1 })
        if data.icon then
            local img = data.btn:FindFirstChildOfClass("ImageLabel")
            if img then Tween(img, { ImageColor3 = active and theme.Accent or Color3.fromHex("#94A3B8") }) end
        end
    end

    for paneName, pane in pairs(self._tabPanes) do
        pane.Visible = paneName == name
    end
end

-- ═══════════════════════════════════════════════════════════
-- ─── TAB ELEMENT API ──────────────────────────────────────
-- ═══════════════════════════════════════════════════════════

function Comet:_makeTabAPI(tabName, pane)
    local api  = {}
    local theme = self.Theme

    -- ─── SECTION ──────────────────────────────────────────
    function api:AddSection(name)
        local sectionLabel = Create("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text             = name:upper(),
            TextColor3       = Color3.fromHex("#475569"),
            TextSize         = 10,
            Font             = Enum.Font.GothamBold,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 12,
            Parent           = pane,
        })
        return api
    end

    -- ─── BUTTON ───────────────────────────────────────────
    function api:AddButton(label, description, callback)
        local row = Create("TextButton", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            Text             = "",
            ZIndex           = 12,
            Parent           = pane,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(0, 0, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(0.6, 0, 0.55, 0),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        if description then
            Create("TextLabel", {
                Size             = UDim2.new(0.6, 0, 0.4, 0),
                Position         = UDim2.new(0, 0, 0.55, 0),
                BackgroundTransparency = 1,
                Text             = description,
                TextColor3       = Color3.fromHex("#475569"),
                TextSize         = 10,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
                Parent           = row,
            })
        end

        local execLabel = Create("TextLabel", {
            Size             = UDim2.new(0, 60, 0, 22),
            Position         = UDim2.new(1, -68, 0.5, -11),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0.1,
            Text             = "Execute",
            TextColor3       = Color3.new(1,1,1),
            TextSize         = 10,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(5) })

        row.MouseEnter:Connect(function()
            Tween(row, { BackgroundTransparency = 0.1 })
        end)
        row.MouseLeave:Connect(function()
            Tween(row, { BackgroundTransparency = 0.3 })
        end)

        row.MouseButton1Click:Connect(function()
            Ripple(row, theme.Accent)
            if callback then callback() end
        end)

        return api
    end

    -- ─── TOGGLE ───────────────────────────────────────────
    function api:AddToggle(label, description, default, callback)
        local value = default or false

        local row = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            ZIndex           = 12,
            Parent           = pane,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(0, 0, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(0.7, 0, 0.55, 0),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        if description then
            Create("TextLabel", {
                Size             = UDim2.new(0.7, 0, 0.4, 0),
                Position         = UDim2.new(0, 0, 0.55, 0),
                BackgroundTransparency = 1,
                Text             = description,
                TextColor3       = Color3.fromHex("#475569"),
                TextSize         = 10,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
                Parent           = row,
            })
        end

        -- Toggle track
        local track = Create("TextButton", {
            Size             = UDim2.new(0, 34, 0, 18),
            Position         = UDim2.new(1, -42, 0.5, -9),
            BackgroundColor3 = value and theme.Accent or theme.Border,
            Text             = "",
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(99) })

        local thumb = Create("Frame", {
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new(0, value and 18 or 2, 0.5, -6),
            BackgroundColor3 = Color3.new(1,1,1),
            ZIndex           = 14,
            Parent           = track,
        }, { MakeCorner(99) })

        local function setToggle(v)
            value = v
            Tween(track, { BackgroundColor3 = v and theme.Accent or theme.Border })
            Tween(thumb, { Position = UDim2.new(0, v and 18 or 2, 0.5, -6) })
            if callback then callback(v) end
        end

        track.MouseButton1Click:Connect(function()
            setToggle(not value)
            Ripple(track, theme.Accent)
        end)

        return { Set = setToggle, Get = function() return value end }
    end

    -- ─── SLIDER ───────────────────────────────────────────
    function api:AddSlider(label, description, min, max, default, callback)
        local value = default or min
        min = min or 0
        max = max or 100

        local row = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 48),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            ZIndex           = 12,
            Parent           = pane,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(0, 0, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(0.7, 0, 0, 16),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        local valueLabel = Create("TextLabel", {
            Size             = UDim2.new(0.3, 0, 0, 16),
            BackgroundTransparency = 1,
            Text             = tostring(value),
            TextColor3       = theme.Accent,
            TextSize         = 11,
            Font             = Enum.Font.GothamBold,
            TextXAlignment   = Enum.TextXAlignment.Right,
            ZIndex           = 13,
            Parent           = row,
        })

        if description then
            Create("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 12),
                Position         = UDim2.new(0, 0, 0, 18),
                BackgroundTransparency = 1,
                Text             = description,
                TextColor3       = Color3.fromHex("#475569"),
                TextSize         = 10,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
                Parent           = row,
            })
        end

        local trackBg = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 4),
            Position         = UDim2.new(0, 0, 1, -10),
            BackgroundColor3 = theme.Border,
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(99) })

        local trackFill = Create("Frame", {
            Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = theme.Accent,
            ZIndex           = 14,
            Parent           = trackBg,
        }, { MakeCorner(99) })

        local thumb = Create("TextButton", {
            Size             = UDim2.new(0, 12, 0, 12),
            Position         = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
            BackgroundColor3 = Color3.new(1,1,1),
            Text             = "",
            ZIndex           = 15,
            Parent           = trackBg,
        }, { MakeCorner(99) })

        local dragging = false
        thumb.MouseButton1Down:Connect(function() dragging = true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        RunService.RenderStepped:Connect(function()
            if dragging then
                local rel = (Mouse.X - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X
                rel = math.clamp(rel, 0, 1)
                value = math.floor(min + (max - min) * rel)
                trackFill.Size = UDim2.new(rel, 0, 1, 0)
                thumb.Position = UDim2.new(rel, -6, 0.5, -6)
                valueLabel.Text = tostring(value)
                if callback then callback(value) end
            end
        end)

        return { Get = function() return value end }
    end

    -- ─── DROPDOWN ─────────────────────────────────────────
    function api:AddDropdown(label, description, options, default, callback)
        local selected = default or options[1]
        local isOpen   = false

        local wrapper = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            ZIndex           = 12,
            ClipsDescendants = false,
            Parent           = pane,
        })

        local row = Create("TextButton", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            Text             = "",
            ZIndex           = 12,
            Parent           = wrapper,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(0, 0, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(0.55, 0, 0.55, 0),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        if description then
            Create("TextLabel", {
                Size             = UDim2.new(0.55, 0, 0.4, 0),
                Position         = UDim2.new(0, 0, 0.55, 0),
                BackgroundTransparency = 1,
                Text             = description,
                TextColor3       = Color3.fromHex("#475569"),
                TextSize         = 10,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 13,
                Parent           = row,
            })
        end

        local selectedLabel = Create("TextLabel", {
            Size             = UDim2.new(0, 120, 0, 22),
            Position         = UDim2.new(1, -128, 0.5, -11),
            BackgroundColor3 = theme.Border,
            BackgroundTransparency = 0.3,
            Text             = selected,
            TextColor3       = theme.Accent,
            TextSize         = 11,
            Font             = Enum.Font.GothamMedium,
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(5), MakePadding(0, 0, 6, 6) })

        local arrow = Create("TextLabel", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(1, -20, 0.5, -7),
            BackgroundTransparency = 1,
            Text             = "▾",
            TextColor3       = Color3.fromHex("#94A3B8"),
            TextSize         = 10,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 14,
            Parent           = selectedLabel,
        })

        -- Dropdown list
        local dropList = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, #options * 28 + 6),
            Position         = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.05,
            Visible          = false,
            ZIndex           = 50,
            Parent           = wrapper,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Accent, 1, 0.5),
            MakePadding(3, 3, 3, 3),
            MakeListLayout(nil, 2),
        })

        for _, opt in ipairs(options) do
            local optBtn = Create("TextButton", {
                Size             = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = opt == selected and theme.Accent or theme.Border,
                BackgroundTransparency = opt == selected and 0.6 or 0.7,
                Text             = opt,
                TextColor3       = opt == selected and theme.Accent or Color3.fromHex("#94A3B8"),
                TextSize         = 11,
                Font             = Enum.Font.GothamMedium,
                ZIndex           = 51,
                Parent           = dropList,
            }, { MakeCorner(5) })

            optBtn.MouseButton1Click:Connect(function()
                selected = opt
                selectedLabel.Text = opt
                isOpen = false
                dropList.Visible = false
                Tween(arrow, { Rotation = 0 })
                -- Reset all opt colors
                for _, c in ipairs(dropList:GetChildren()) do
                    if c:IsA("TextButton") then
                        Tween(c, {
                            BackgroundTransparency = c.Text == selected and 0.6 or 0.7,
                            TextColor3 = c.Text == selected and theme.Accent or Color3.fromHex("#94A3B8"),
                        })
                    end
                end
                if callback then callback(selected) end
            end)
        end

        row.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            dropList.Visible = isOpen
            Tween(arrow, { Rotation = isOpen and 180 or 0 })
        end)

        return { Get = function() return selected end }
    end

    -- ─── INPUT ────────────────────────────────────────────
    function api:AddInput(label, description, placeholder, callback)
        local row = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 48),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            ZIndex           = 12,
            Parent           = pane,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(6, 6, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        local inputBox = Create("TextBox", {
            Size             = UDim2.new(1, 0, 0, 22),
            Position         = UDim2.new(0, 0, 1, -22),
            BackgroundColor3 = theme.BG,
            BackgroundTransparency = 0.3,
            PlaceholderText  = placeholder or "Enter text...",
            PlaceholderColor3 = Color3.fromHex("#475569"),
            Text             = "",
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 11,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(5), MakePadding(0, 0, 7, 7) })

        inputBox.Focused:Connect(function()
            Tween(inputBox, { BackgroundColor3 = theme.Panel })
            -- stroke accent on focus
        end)
        inputBox.FocusLost:Connect(function(enter)
            Tween(inputBox, { BackgroundColor3 = theme.BG })
            if callback then callback(inputBox.Text, enter) end
        end)

        return { Get = function() return inputBox.Text end }
    end

    -- ─── KEYBIND ──────────────────────────────────────────
    function api:AddKeybind(label, description, default, callback)
        local key    = default or Enum.KeyCode.Unknown
        local listen = false

        local row = Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.3,
            ZIndex           = 12,
            Parent           = pane,
        }, {
            MakeCorner(7),
            MakeStroke(theme.Border, 1, 0.5),
            MakePadding(0, 0, 10, 10),
        })

        Create("TextLabel", {
            Size             = UDim2.new(0.6, 0, 0.55, 0),
            BackgroundTransparency = 1,
            Text             = label,
            TextColor3       = Color3.fromHex("#E2E8F0"),
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = row,
        })

        local keyBtn = Create("TextButton", {
            Size             = UDim2.new(0, 80, 0, 22),
            Position         = UDim2.new(1, -88, 0.5, -11),
            BackgroundColor3 = theme.Border,
            BackgroundTransparency = 0.3,
            Text             = tostring(key.Name),
            TextColor3       = theme.Accent,
            TextSize         = 11,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 13,
            Parent           = row,
        }, { MakeCorner(5) })

        keyBtn.MouseButton1Click:Connect(function()
            listen = true
            keyBtn.Text = "..."
            Tween(keyBtn, { BackgroundColor3 = theme.Accent, TextColor3 = Color3.new(1,1,1) })
        end)

        UserInputService.InputBegan:Connect(function(input, processed)
            if listen and not processed and input.UserInputType == Enum.UserInputType.Keyboard then
                listen = false
                key = input.KeyCode
                keyBtn.Text = key.Name
                Tween(keyBtn, { BackgroundColor3 = theme.Border, TextColor3 = theme.Accent })
                if callback then callback(key) end
            end
        end)

        return { Get = function() return key end }
    end

    -- ─── LABEL ────────────────────────────────────────────
    function api:AddLabel(text)
        Create("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = theme.Panel,
            BackgroundTransparency = 0.5,
            Text             = text,
            TextColor3       = Color3.fromHex("#94A3B8"),
            TextSize         = 11,
            Font             = Enum.Font.Gotham,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 12,
            Parent           = pane,
        }, { MakeCorner(7), MakePadding(0, 0, 10, 10) })
        return api
    end

    -- ─── SEPARATOR ────────────────────────────────────────
    function api:AddSeparator()
        Create("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.fromHex("#2A2E45"),
            BackgroundTransparency = 0.3,
            ZIndex           = 12,
            Parent           = pane,
        })
        return api
    end

    return api
end

-- ═══════════════════════════════════════════════════════════
-- ─── SETTINGS TAB (built-in) ──────────────────────────────
-- ═══════════════════════════════════════════════════════════

function Comet:AddSettingsTab()
    local settings = self:AddTab("Settings", 10709750000)
    local theme     = self.Theme

    settings:AddSection("Theme")
    for themeName, _ in pairs(Themes) do
        settings:AddButton(themeName, "Switch to " .. themeName .. " theme", function()
            Config.Theme = themeName
            self.Theme   = Themes[themeName]
            ShowToast(self.ScreenGui, "Theme set to " .. themeName)
        end)
    end

    settings:AddSection("Background")
    local bgInput = settings:AddInput(
        "Background Asset ID or URL",
        "Paste rbxassetid://XXXXX or https://",
        "rbxassetid://10709752035",
        nil
    )
    settings:AddButton("Apply Background", "Set the background image", function()
        local val = bgInput.Get()
        if val and val ~= "" then
            local url = val
            if not val:find("http") then
                url = val:match("^rbxassetid://") and val or ("rbxassetid://" .. val)
            end
            self.BgImage.Image   = url
            self.BgImage.Visible = true
            self.BgFrame.Visible = true
            ShowToast(self.ScreenGui, "Background applied")
        end
    end)
    settings:AddButton("Remove Background", nil, function()
        self.BgImage.Visible = false
        self.BgFrame.Visible = false
        ShowToast(self.ScreenGui, "Background removed")
    end)

    local blurSlider = settings:AddSlider("Blur Amount", "Background blur strength", 0, 24, 0, function(v)
        self.BlurEffect.Size = v
    end)

    settings:AddSection("Window")
    settings:AddToggle("Show Minimize Button", nil, true, function(v)
        self.MinimizeBtn.Visible = v
    end)
    settings:AddToggle("Show Close Button", nil, true, function(v)
        self.CloseBtn.Visible = v
    end)
    settings:AddDropdown("Opacity", "Window background opacity", {"0%","15%","30%","50%"}, "15%", function(v)
        local map = {["0%"]=1,["15%"]=0.08,["30%"]=0.3,["50%"]=0.5}
        self.Window.BackgroundTransparency = map[v] or 0.08
    end)

    settings:AddSection("Toggle Key")
    settings:AddKeybind("Open / Close Window", "Keybind to toggle the UI", self.ToggleKey, function(key)
        self.ToggleKey = key
        ShowToast(self.ScreenGui, "Toggle key set to " .. key.Name)
    end)

    return settings
end

-- ═══════════════════════════════════════════════════════════
-- ─── NOTIFY (public API) ──────────────────────────────────
-- ═══════════════════════════════════════════════════════════

function Comet:Notify(message, duration)
    ShowToast(self.ScreenGui, message, duration)
end

return Comet

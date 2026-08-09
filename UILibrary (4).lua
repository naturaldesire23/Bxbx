--[[
    UILibrary.lua
    A standalone, self-contained Roblox UI framework (executor-safe, no
    external dependencies beyond a free MIT/ISC-licensed icon set). No
    gameplay logic - pure UI.

    ARCHITECTURE
      UI.new(opts)                      -> Window
      Window:create_tab(name, icon)     -> Tab           (sidebar entry)
      Tab:create_module(opts)           -> Module         (toggleable card)
      Module:create_button(opts)
      Module:create_slider(opts)
      Module:create_dropdown(opts)
      Module:create_textbox(opts)
      UI:Notify(opts)                   -> toast notification

    USAGE
        local UI = loadstring(readfile("UILibrary.lua"))()
        local Window = UI.new({ Title = "My Script" })

        local Tab = Window:create_tab("Main", "house")

        local Combat = Tab:create_module({ Title = "Auto Something", Description = "Does a thing automatically" })
        Combat:create_button({ Text = "Run Once", Callback = function() print("ran") end })
        Combat:create_slider({ Text = "Strength", Min = 0, Max = 100, Default = 50, Callback = function(v) print(v) end })
        Combat:create_dropdown({ Text = "Mode", Options = {"A","B","C"}, Default = "A", Callback = function(v) print(v) end })
        Combat:create_textbox({ Text = "Name", Placeholder = "type here...", Callback = function(v) print(v) end })

        Combat.Toggled:Connect(function(state) print("module on:", state) end)

        UI:Notify({ Title = "Loaded", Description = "Everything is ready.", Type = "success" })
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--=========================================================
-- THEME
--=========================================================
local Theme = {
    Background   = Color3.fromRGB(15, 15, 20),
    GradTop      = Color3.fromRGB(35, 32, 45),
    GradMid      = Color3.fromRGB(20, 18, 26),
    GradBottom   = Color3.fromRGB(6, 6, 8),

    Sidebar      = Color3.fromRGB(20, 19, 26),
    Module       = Color3.fromRGB(24, 24, 30),
    Control      = Color3.fromRGB(32, 31, 40),

    Purple       = Color3.fromRGB(168, 85, 247),
    PurpleDim    = Color3.fromRGB(120, 65, 180),

    Text         = Color3.fromRGB(255, 255, 255),
    TextDim      = Color3.fromRGB(150, 150, 160),
    Border       = Color3.fromRGB(70, 70, 78),

    Success      = Color3.fromRGB(80, 210, 130),
    Warning      = Color3.fromRGB(240, 175, 60),
    Error        = Color3.fromRGB(230, 90, 90),
    Info         = Color3.fromRGB(168, 85, 247),

    Font         = Enum.Font.Gotham,
    FontBold     = Enum.Font.GothamBold,
}

--=========================================================
-- HELPERS
--=========================================================
local function create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

local function corner(r) return create("UICorner", { CornerRadius = UDim.new(0, r or 6) }) end

local function stroke(color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(a, b, c, d)
    b = b or a; c = c or a; d = d or b
    return create("UIPadding", {
        PaddingTop = UDim.new(0, a), PaddingRight = UDim.new(0, b),
        PaddingBottom = UDim.new(0, c), PaddingLeft = UDim.new(0, d),
    })
end

local QUINT = Enum.EasingStyle.Quint

local function tween(inst, props, duration, style, direction)
    local t = TweenService:Create(inst, TweenInfo.new(duration or 0.3, style or QUINT, direction or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- lightweight signal (no RBXScriptSignal dependency needed)
local function newSignal()
    local listeners = {}
    return {
        Connect = function(_, fn) listeners[#listeners + 1] = fn end,
        Fire = function(_, ...)
            for _, fn in ipairs(listeners) do task.spawn(fn, ...) end
        end,
    }
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            tween(target, { Position = goal }, 0.08, Enum.EasingStyle.Quad)
        end
    end)
end

--=========================================================
-- LUCIDE ICON LOOKUP (free, MIT/ISC-licensed icon set, fetched at runtime)
--=========================================================
local IconMap, IconMapAttempted = nil, false
local function loadIconMap()
    if IconMapAttempted then return IconMap end
    IconMapAttempted = true
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json"))
    end)
    IconMap = (ok and type(result) == "table") and (result.icons or result) or false
    return IconMap
end
local function resolveIcon(icon)
    if not icon or icon == "" then return nil end
    if icon:sub(1, 12) == "rbxassetid:/" or icon:sub(1, 4) == "http" then
        return { Image = icon }
    end
    local map = loadIconMap()
    local entry = map and map[icon]
    if entry then
        local id = entry.id or entry.Id or entry.assetId
        local off = entry.imageRectOffset or entry.ImageRectOffset or entry.offset
        local sz = entry.imageRectSize or entry.ImageRectSize or entry.size
        if id then
            return {
                Image = "rbxassetid://" .. tostring(id),
                RectOffset = off and Vector2.new(off[1] or off.X or 0, off[2] or off.Y or 0),
                RectSize = sz and Vector2.new(sz[1] or sz.X or 0, sz[2] or sz.Y or 0),
            }
        end
    end
    return nil
end

--=========================================================
-- ROOT GUI
--=========================================================
local ScreenGui = create("ScreenGui", {
    Name = "UILibraryGui", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
local okParent = pcall(function() ScreenGui.Parent = CoreGui end)
if not okParent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

--=========================================================
-- NOTIFICATIONS (toast, top of screen, max 3 visible, type colors)
--=========================================================
local NotifGui = create("ScreenGui", {
    Name = "UILibraryNotifications", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
})
pcall(function() NotifGui.Parent = CoreGui end)
if not NotifGui.Parent then NotifGui.Parent = ScreenGui end

local NotifHolder = create("Frame", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 16),
    Size = UDim2.fromOffset(320, 600),
    Parent = NotifGui,
})
create("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
}).Parent = NotifHolder

local activeNotifs = {}
local TYPE_COLORS = { success = Theme.Success, warning = Theme.Warning, error = Theme.Error, info = Theme.Info }

local function Notify(opts)
    opts = opts or {}
    local kind = TYPE_COLORS[(opts.Type or "info"):lower()] or Theme.Info
    local duration = opts.Duration or 3

    -- enforce max 3 visible: drop the oldest
    if #activeNotifs >= 3 then
        local oldest = table.remove(activeNotifs, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end

    local card = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = NotifHolder,
    }, { corner(8), stroke(Theme.Border, 1, 0.4) })

    create("Frame", {
        BackgroundColor3 = kind, BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0), Parent = card,
    }, { corner(2) })

    local TextCol = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    })
    create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }).Parent = TextCol
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }).Parent = TextCol

    create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
        Font = Theme.FontBold, Text = opts.Title or "Notification",
        TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1, Parent = TextCol,
    })
    if opts.Description and opts.Description ~= "" then
        create("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Theme.Font, Text = opts.Description, TextWrapped = true,
            TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2, Parent = TextCol,
        })
    end

    tween(card, { BackgroundTransparency = 0 }, 0.25)
    activeNotifs[#activeNotifs + 1] = card

    task.delay(duration, function()
        for i, c in ipairs(activeNotifs) do
            if c == card then table.remove(activeNotifs, i) break end
        end
        if card.Parent then
            tween(card, { BackgroundTransparency = 1 }, 0.25)
            task.wait(0.27)
            card:Destroy()
        end
    end)
end

--=========================================================
-- UI / WINDOW
--=========================================================
local UI = {}
UI.ScreenGui = ScreenGui
UI.Theme = Theme
UI.Notify = Notify

function UI.new(opts)
    opts = opts or {}
    local title = opts.Title or "Window"
    local fullSize = UDim2.fromOffset(620, 460)
    local miniSize = UDim2.fromOffset(100, 30)
    local headerHeight = 30
    local sidebarWidth = 120
    local gutter = 8

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = fullSize,
        BackgroundColor3 = Theme.Background,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, { corner(12), stroke(Theme.Purple, 1.5, 0.28) })

    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.GradTop),
            ColorSequenceKeypoint.new(0.5, Theme.GradMid),
            ColorSequenceKeypoint.new(1, Theme.GradBottom),
        }),
        Rotation = 90,
    }).Parent = Main

    local UIScaleObj = create("UIScale", { Scale = 1 })
    UIScaleObj.Parent = Main

    -- Header (drag handle, title, minimize)
    local Header = create("Frame", {
        Name = "Header", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, headerHeight), Parent = Main,
    })

    local TitleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Theme.FontBold, Text = title,
        TextColor3 = Theme.Text, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    local MinimizeBtn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = Theme.Control,
        Font = Theme.FontBold, Text = "\226\128\147",
        TextColor3 = Theme.Text, TextSize = 14,
        AutoButtonColor = false,
        Parent = Header,
    }, { corner(5) })

    makeDraggable(Header, Main)

    -- Body: sidebar + content
    local Body = create("Frame", {
        Name = "Body", BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, headerHeight),
        Size = UDim2.new(1, 0, 1, -headerHeight),
        Parent = Main,
    })

    local Sidebar = create("ScrollingFrame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 0.35,
        Position = UDim2.new(0, gutter, 0, 0),
        Size = UDim2.new(0, sidebarWidth, 1, -gutter),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Purple,
        Parent = Body,
    }, { corner(8) })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }).Parent = Sidebar
    padding(8).Parent = Sidebar

    local ContentArea = create("Frame", {
        Name = "ContentArea", BackgroundTransparency = 1,
        Position = UDim2.new(0, sidebarWidth + gutter * 2, 0, 0),
        Size = UDim2.new(1, -(sidebarWidth + gutter * 3), 1, -gutter),
        Parent = Body,
    })

    -- minimize / restore
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tween(Main, { Size = miniSize }, 0.5)
            Body.Visible = false
        else
            tween(Main, { Size = fullSize }, 0.5)
            task.delay(0.05, function() Body.Visible = true end)
        end
    end)

    local currentTab = nil

    local function defaultIcon(parent)
        local box = create("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.TextDim, Parent = parent }, { corner(4) })
        return box
    end

    function Window:create_tab(name, icon)
        local Tab = {}
        Tab.Modules = {}

        local TabButton = create("TextButton", {
            Size = UDim2.fromOffset(100, 35),
            BackgroundColor3 = Theme.Purple, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false,
            Parent = Sidebar,
        }, { corner(8) })

        local IconHolder = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.fromOffset(16, 16),
            Parent = TabButton,
        })
        local resolved = resolveIcon(icon)
        local iconImg
        if resolved then
            iconImg = create("ImageLabel", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Image = resolved.Image,
                ImageRectOffset = resolved.RectOffset or Vector2.new(0, 0),
                ImageRectSize = resolved.RectSize or Vector2.new(0, 0),
                ImageColor3 = Theme.TextDim,
                Parent = IconHolder,
            })
        else
            iconImg = defaultIcon(IconHolder)
        end

        local TabLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -36, 1, 0),
            Font = Theme.Font, Text = name,
            TextColor3 = Theme.TextDim, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton,
        })

        local Page = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            Parent = ContentArea,
        })

        local LeftSection = create("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.24, 0, 0, 0),
            Size = UDim2.fromOffset(280, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Purple,
            Parent = Page,
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }).Parent = LeftSection

        local RightSection = create("ScrollingFrame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.76, 0, 0, 0),
            Size = UDim2.fromOffset(280, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Purple,
            Parent = Page,
        })
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }).Parent = RightSection

        local function selectTab()
            if currentTab then
                currentTab.Page.Visible = false
                tween(currentTab.Button, { BackgroundTransparency = 1 }, 0.3, QUINT)
                tween(currentTab.Label, { TextColor3 = Theme.TextDim }, 0.3, QUINT)
                if currentTab.Icon and currentTab.Icon:IsA("ImageLabel") then
                    tween(currentTab.Icon, { ImageColor3 = Theme.TextDim }, 0.3, QUINT)
                elseif currentTab.Icon then
                    tween(currentTab.Icon, { BackgroundColor3 = Theme.TextDim }, 0.3, QUINT)
                end
            end
            Page.Visible = true
            tween(TabButton, { BackgroundTransparency = 0.85 }, 0.3, QUINT)
            tween(TabLabel, { TextColor3 = Theme.Text }, 0.3, QUINT)
            if iconImg:IsA("ImageLabel") then
                tween(iconImg, { ImageColor3 = Theme.Purple }, 0.3, QUINT)
            else
                tween(iconImg, { BackgroundColor3 = Theme.Purple }, 0.3, QUINT)
            end
            currentTab = { Page = Page, Button = TabButton, Label = TabLabel, Icon = iconImg }
        end

        TabButton.MouseButton1Click:Connect(selectTab)
        if not currentTab then selectTab() end

        -- MODULE: toggleable card that expands to reveal controls
        function Tab:create_module(o)
            o = o or {}
            local side = (o.Side == "right") and RightSection or LeftSection
            local Module = {}
            Module.Toggled = newSignal()

            local state = o.Default or false

            local Card = create("Frame", {
                BackgroundColor3 = Theme.Module,
                Size = UDim2.new(1, 0, 0, 65),
                ClipsDescendants = true,
                Parent = side,
            }, { corner(8), stroke(Theme.Border, 1, 0.5) })

            local HeaderBtn = create("TextButton", {
                BackgroundTransparency = 1, Text = "",
                Size = UDim2.new(1, 0, 0, 65),
                Parent = Card,
            })
            padding(10, 12).Parent = HeaderBtn

            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -54, 0, 18),
                Font = Theme.FontBold, Text = o.Title or "Module",
                TextColor3 = Theme.Text, TextTransparency = 0.05, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = HeaderBtn,
            })
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 20),
                Size = UDim2.new(1, -54, 0, 14),
                Font = Theme.Font, Text = o.Description or "",
                TextColor3 = Theme.TextDim, TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = HeaderBtn,
            })

            local Switch = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0, 9),
                Size = UDim2.fromOffset(40, 24),
                BackgroundColor3 = Color3.fromRGB(45, 45, 50),
                Parent = HeaderBtn,
            }, { corner(12) })
            local Knob = create("Frame", {
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(140, 140, 150),
                Parent = Switch,
            }, { corner(9) })

            -- Body: sub-controls live here, auto-sized, revealed when on
            local ControlBody = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 65),
                Size = UDim2.new(1, -24, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Card,
            })
            local BodyList = create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            BodyList.Parent = ControlBody
            create("UIPadding", { PaddingBottom = UDim.new(0, 12) }).Parent = ControlBody

            local function resize()
                local target = state and (65 + BodyList.AbsoluteContentSize.Y) or 65
                tween(Card, { Size = UDim2.new(1, 0, 0, target) }, 0.3, QUINT)
            end

            local function applyVisual(fire)
                tween(Switch, { BackgroundColor3 = state and Theme.Purple or Color3.fromRGB(45, 45, 50) }, 0.3, QUINT)
                tween(Knob, {
                    Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
                    BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 140, 150),
                }, 0.3, QUINT)
                resize()
                if fire then
                    Module.Toggled:Fire(state)
                    if o.Callback then task.spawn(o.Callback, state) end
                end
            end

            HeaderBtn.MouseButton1Click:Connect(function()
                state = not state
                applyVisual(true)
            end)

            BodyList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if state then resize() end
            end)

            if state then applyVisual(false) end

            function Module:Set(v) state = v; applyVisual(true) end
            function Module:Get() return state end

            function Module:create_button(bo)
                bo = bo or {}
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Control,
                    Font = Theme.FontBold, Text = bo.Text or "Button",
                    TextColor3 = Theme.Text, TextSize = 12,
                    AutoButtonColor = false,
                    Parent = ControlBody,
                }, { corner(6) })
                Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Theme.PurpleDim }, 0.15) end)
                Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Theme.Control }, 0.15) end)
                Btn.MouseButton1Click:Connect(function()
                    if bo.Callback then task.spawn(bo.Callback) end
                end)
                return Btn
            end

            function Module:create_slider(so)
                so = so or {}
                local min, max = so.Min or 0, so.Max or 100
                local value = math.clamp(so.Default or min, min, max)
                local decimals = so.Decimals or 0

                local Wrap = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = ControlBody })

                create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 16),
                    Font = Theme.Font, Text = so.Text or "Slider",
                    TextColor3 = Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Wrap,
                })
                local ValueLabel = create("TextLabel", {
                    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(46, 16),
                    Font = Theme.FontBold, Text = tostring(value),
                    TextColor3 = Theme.Purple, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = Wrap,
                })

                local Track = create("Frame", {
                    Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 4),
                    BackgroundColor3 = Theme.Control, Parent = Wrap,
                }, { corner(2) })
                local Fill = create("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Purple, Parent = Track,
                }, { corner(2) })
                local KnobBtn = create("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Track,
                }, { corner(7) })

                local dragging = false
                local function setFromAlpha(alpha)
                    alpha = math.clamp(alpha, 0, 1)
                    local raw = min + (max - min) * alpha
                    local mult = 10 ^ decimals
                    value = math.floor(raw * mult + 0.5) / mult
                    Fill.Size = UDim2.new(alpha, 0, 1, 0)
                    KnobBtn.Position = UDim2.new(alpha, 0, 0.5, 0)
                    ValueLabel.Text = tostring(value)
                    if so.Callback then task.spawn(so.Callback, value) end
                end
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromAlpha((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        setFromAlpha((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
                    end
                end)

                return { Set = function(_, v) setFromAlpha((v - min) / (max - min)) end, Get = function() return value end }
            end

            function Module:create_dropdown(dopt)
                dopt = dopt or {}
                local options = dopt.Options or {}
                local selected = dopt.Default or options[1]
                local open = false

                local Box = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Control,
                    Text = "  " .. tostring(selected) .. "   \226\150\190",
                    TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false, Parent = ControlBody,
                }, { corner(6) })

                local ListFrame = create("Frame", {
                    BackgroundColor3 = Theme.Control,
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false, ZIndex = 10,
                    Parent = Box,
                }, { corner(6), stroke(Theme.Border, 1, 0.4) })
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListFrame
                padding(4).Parent = ListFrame

                local function rebuild()
                    for _, c in ipairs(ListFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local OptBtn = create("TextButton", {
                            BackgroundColor3 = Theme.Module,
                            Size = UDim2.new(1, 0, 0, 25),
                            Text = "  " .. tostring(opt),
                            TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                            Font = Theme.Font, TextSize = 12, AutoButtonColor = false, ZIndex = 11,
                            Parent = ListFrame,
                        }, { corner(4) })
                        OptBtn.MouseEnter:Connect(function() tween(OptBtn, { BackgroundColor3 = Theme.PurpleDim }, 0.12) end)
                        OptBtn.MouseLeave:Connect(function() tween(OptBtn, { BackgroundColor3 = Theme.Module }, 0.12) end)
                        OptBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            Box.Text = "  " .. tostring(opt) .. "   \226\150\190"
                            open = false
                            ListFrame.Visible = false
                            if dopt.Callback then task.spawn(dopt.Callback, selected) end
                        end)
                    end
                end
                rebuild()

                Box.MouseButton1Click:Connect(function()
                    open = not open
                    ListFrame.Visible = open
                end)

                return {
                    Set = function(_, v) selected = v; Box.Text = "  " .. tostring(v) .. "   \226\150\190" end,
                    Get = function() return selected end,
                    Refresh = function(_, newOptions) options = newOptions or options; rebuild() end,
                }
            end

            function Module:create_textbox(txo)
                txo = txo or {}
                local Box = create("TextBox", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.Control,
                    Text = txo.Default or "",
                    PlaceholderText = txo.Placeholder or "",
                    TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextDim,
                    Font = Theme.Font, TextSize = 12,
                    ClearTextOnFocus = false,
                    Parent = ControlBody,
                }, { corner(6), padding(0, 10) })

                Box.FocusLost:Connect(function(enterPressed)
                    if txo.Callback then task.spawn(txo.Callback, Box.Text, enterPressed) end
                end)

                return { Set = function(_, v) Box.Text = v end, Get = function() return Box.Text end }
            end

            Tab.Modules[#Tab.Modules + 1] = Module
            return Module
        end

        Window.Tabs[#Window.Tabs + 1] = Tab
        return Tab
    end

    Window.Main = Main
    Window.UIScale = UIScaleObj
    return Window
end

return UI

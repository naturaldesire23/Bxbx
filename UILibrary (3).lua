--[[
    UILibrary.lua
    A standalone, self-contained UI library for Roblox (executor or plugin-side).
    No external dependencies beyond a public, MIT/ISC-licensed icon set. No
    gameplay logic. Just UI.

    Visual features:
      - Gray -> black gradients throughout (window, tabs, buttons, cards)
      - Consistent rounded corners (inner panels are inset and rounded on
        their own so no sharp corners poke through the rounded outer frame)
      - Toggles turn green when switched on
      - ONE cube-shaped button, docked on the left side of the top bar -
        orange gradient with a bold "A" - is the only show/hide control.
        Click it: the whole window hides and a matching floating cube
        appears on the left edge of the screen. Click that cube: the
        window comes back and the floating cube disappears. There is no
        separate close/minimize button.
      - Real tab icons: pass a Lucide icon name ("home", "settings",
        "search", etc. - https://lucide.dev/icons), a raw
        "rbxassetid://...", or leave it blank for an auto gradient icon.

    USAGE:
        local Library = loadstring(readfile("UILibrary.lua"))()
        local Window = Library:CreateWindow({ Title = "My Window", Size = UDim2.fromOffset(560, 400) })

        local Tab1 = Window:CreateTab("Main", "house")
        local Section1 = Tab1:CreateSection("Left")

        Section1:CreateButton({ Text = "Click me", Callback = function() print("clicked") end })
        Section1:CreateToggle({ Text = "Enable thing", Default = false, Callback = function(state) print(state) end })
        Section1:CreateSlider({ Text = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) print(v) end })
        Section1:CreateDropdown({ Text = "Mode", Options = {"A","B","C"}, Default = "A", Callback = function(v) print(v) end })
        Section1:CreateTextbox({ Text = "Name", Placeholder = "type here...", Callback = function(v) print(v) end })
        Section1:CreateKeybind({ Text = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() print("bound") end })

        Library:Notify({ Title = "Hello", Text = "This is a notification", Duration = 3 })
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--=========================================================
-- THEME
--=========================================================
local Theme = {
    Background      = Color3.fromRGB(18, 18, 21),
    Surface         = Color3.fromRGB(28, 28, 33),
    SurfaceRaised   = Color3.fromRGB(38, 38, 44),
    Border          = Color3.fromRGB(58, 58, 66),
    Accent          = Color3.fromRGB(255, 140, 45),   -- orange, ties to the cube button
    AccentDim       = Color3.fromRGB(190, 100, 30),
    On              = Color3.fromRGB(70, 210, 120),   -- green "enabled" color
    OnDim           = Color3.fromRGB(45, 150, 85),
    Text            = Color3.fromRGB(242, 242, 247),
    TextDim         = Color3.fromRGB(162, 162, 174),
    Danger          = Color3.fromRGB(230, 90, 90),
    Font            = Enum.Font.Gotham,
    FontBold        = Enum.Font.GothamBold,
    -- gray -> black gradient stops, used everywhere for a consistent look
    GradTop         = Color3.fromRGB(86, 86, 94),
    GradBottom      = Color3.fromRGB(9, 9, 11),
    -- orange gradient stops for the cube button
    CubeTop         = Color3.fromRGB(255, 176, 80),
    CubeBottom      = Color3.fromRGB(200, 90, 20),
    -- corner radii, kept consistent across the whole UI
    RadiusOuter     = 16,
    RadiusPanel     = 10,
    RadiusControl   = 7,
}

--=========================================================
-- HELPERS
--=========================================================
local function create(class, props, children)
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
    return create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.RadiusControl) })
end

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
        PaddingTop = UDim.new(0, a),
        PaddingRight = UDim.new(0, b),
        PaddingBottom = UDim.new(0, c),
        PaddingLeft = UDim.new(0, d),
    })
end

-- Reusable gray -> black diagonal gradient
local function gradient(rotation, topColor, bottomColor)
    return create("UIGradient", {
        Color = ColorSequence.new(topColor or Theme.GradTop, bottomColor or Theme.GradBottom),
        Rotation = rotation or 100,
    })
end

local function tween(inst, props, duration, style, direction)
    local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--=========================================================
-- LUCIDE ICON LOOKUP (free, MIT/ISC-licensed icon set)
-- Ported for Roblox by the community: github.com/frappedevs/lucideblox
-- Fetched once at runtime and cached; falls back gracefully if offline.
--=========================================================
local IconMap = nil
local IconMapAttempted = false

local function loadIconMap()
    if IconMapAttempted then return IconMap end
    IconMapAttempted = true
    local ok, result = pcall(function()
        local raw = game:HttpGet("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")
        return HttpService:JSONDecode(raw)
    end)
    if ok and type(result) == "table" then
        IconMap = result.icons or result
    else
        IconMap = false
    end
    return IconMap
end

local function resolveIcon(icon)
    if not icon or icon == "" then return nil end
    if icon:sub(1, 12) == "rbxassetid:/" or icon:sub(1, 7) == "http://" or icon:sub(1, 8) == "https://" then
        return { Image = icon, RectOffset = nil, RectSize = nil }
    end
    local map = loadIconMap()
    if map and map[icon] then
        local entry = map[icon]
        local assetId = entry.id or entry.Id or entry.assetId
        local offset = entry.imageRectOffset or entry.ImageRectOffset or entry.offset
        local size = entry.imageRectSize or entry.ImageRectSize or entry.size
        if assetId then
            return {
                Image = "rbxassetid://" .. tostring(assetId),
                RectOffset = offset and Vector2.new(offset[1] or offset.X or 0, offset[2] or offset.Y or 0) or nil,
                RectSize = size and Vector2.new(size[1] or size.X or 0, size[2] or size.Y or 0) or nil,
            }
        end
    end
    return nil
end

--=========================================================
-- ROOT GUI
--=========================================================
local ScreenGui = create("ScreenGui", {
    Name = "UILibraryGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
})

local ok = pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ok then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--=========================================================
-- NOTIFICATIONS
--=========================================================
local NotifHolder = create("Frame", {
    Name = "Notifications",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -16, 1, -16),
    Size = UDim2.fromOffset(300, 500),
    Parent = ScreenGui,
})
create("UIListLayout", {
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, {}).Parent = NotifHolder

local function Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"
    local text = opts.Text or ""
    local duration = opts.Duration or 3

    local card = create("Frame", {
        BackgroundColor3 = Theme.SurfaceRaised,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = NotifHolder,
    }, { corner(Theme.RadiusPanel), stroke(Theme.Border, 1, 0.3), gradient(100) })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }).Parent = card

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })
    layout.Parent = card

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
    }).Parent = card

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
    }).Parent = card

    card.BackgroundTransparency = 1
    for _, d in ipairs(card:GetDescendants()) do
        if d:IsA("TextLabel") then d.TextTransparency = 1 end
    end
    tween(card, { BackgroundTransparency = 0 }, 0.2)
    for _, d in ipairs(card:GetDescendants()) do
        if d:IsA("TextLabel") then tween(d, { TextTransparency = 0 }, 0.2) end
    end

    task.delay(duration, function()
        tween(card, { BackgroundTransparency = 1 }, 0.2)
        for _, d in ipairs(card:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.2) end
        end
        task.wait(0.22)
        card:Destroy()
    end)
end

--=========================================================
-- CUBE VISUAL (shared by the in-bar button and the floating one)
-- Orange gradient square with a bold "A" centered, plus a gentle
-- breathing/pulse animation for a bit of life.
--=========================================================
local function paintCube(cubeFrame, letterSize)
    gradient(135, Theme.CubeTop, Theme.CubeBottom).Parent = cubeFrame
    create("UIStroke", {
        Color = Color3.fromRGB(255, 200, 140),
        Thickness = 1.5,
        Transparency = 0.35,
        Parent = cubeFrame,
    })
    local Letter = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Theme.FontBold,
        Text = "A",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = letterSize or 18,
        Parent = cubeFrame,
    })
    return Letter
end

local function pulse(cubeFrame, baseSize)
    task.spawn(function()
        while cubeFrame.Parent do
            tween(cubeFrame, { Size = baseSize + UDim2.fromOffset(3, 3) }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
            if not cubeFrame.Parent then break end
            tween(cubeFrame, { Size = baseSize }, 0.9, Enum.EasingStyle.Sine)
            task.wait(0.9)
        end
    end)
end

--=========================================================
-- FLOATING CUBE (shown when the window is hidden; click to reopen)
--=========================================================
local function createFloatingCube(onClick)
    local size = UDim2.fromOffset(46, 46)
    local Cube = create("Frame", {
        Name = "FloatingCube",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 20, 0.5, 0),
        Size = size,
        BackgroundColor3 = Theme.CubeBottom,
        Visible = false,
        Parent = ScreenGui,
    }, { corner(13) })
    paintCube(Cube, 20)
    pulse(Cube, size)

    local Click = create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = Cube,
    })
    Click.MouseButton1Click:Connect(function()
        if onClick then onClick() end
    end)

    makeDraggable(Cube, Cube)

    return Cube
end

--=========================================================
-- LIBRARY / WINDOW
--=========================================================
local Library = {}
Library.ScreenGui = ScreenGui
Library.Theme = Theme
Library.Notify = Notify

function Library:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "Window"
    local size = opts.Size or UDim2.fromOffset(560, 400)
    local topBarHeight = 40
    local gutter = 8

    local Window = {}
    Window.Tabs = {}

    local Main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        Size = size,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, { corner(Theme.RadiusOuter), stroke(Theme.Border, 1, 0.2) })
    gradient(115).Parent = Main

    local FloatingCube = createFloatingCube(function()
        Main.Visible = true
        FloatingCube.Visible = false
    end)

    local TopBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, topBarHeight),
        Parent = Main,
    }, { corner(Theme.RadiusOuter) })
    gradient(90, Color3.fromRGB(56, 56, 62), Color3.fromRGB(20, 20, 22)).Parent = TopBar
    -- square off TopBar's own bottom corners so only the TOP matches Main's curve
    create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -Theme.RadiusOuter),
        Size = UDim2.new(1, 0, 0, Theme.RadiusOuter),
        Parent = TopBar,
    }, { gradient(90, Color3.fromRGB(56, 56, 62), Color3.fromRGB(20, 20, 22)) })

    -- the ONE toggle button: docked left, cube-shaped, orange, letter "A".
    -- This is the only way to hide/show the window - there is no separate
    -- close or minimize button.
    local ToggleBtn = create("TextButton", {
        Name = "ToggleButton",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(26, 26),
        BackgroundColor3 = Theme.CubeBottom,
        Text = "",
        AutoButtonColor = false,
        Parent = TopBar,
    }, { corner(8) })
    paintCube(ToggleBtn, 13)

    ToggleBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
        FloatingCube.Visible = true
    end)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 0),
        Size = UDim2.new(1, -54, 1, 0),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

    makeDraggable(TopBar, Main)

    -- Body: inset by `gutter` so inner panels get their own rounded corners
    -- instead of poking sharp corners through Main's rounded outer edge.
    local Body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, gutter, 0, topBarHeight + gutter),
        Size = UDim2.new(1, -gutter * 2, 1, -(topBarHeight + gutter * 2)),
        Parent = Main,
    })

    local TabBar = create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(0, 136, 1, 0),
        Parent = Body,
    }, { corner(Theme.RadiusPanel), stroke(Theme.Border, 1, 0.3) })
    gradient(90, Color3.fromRGB(46, 46, 52), Color3.fromRGB(13, 13, 15)).Parent = TabBar
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }).Parent = TabBar
    padding(8).Parent = TabBar

    local ContentArea = create("Frame", {
        Name = "ContentArea",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 136 + gutter, 0, 0),
        Size = UDim2.new(1, -(136 + gutter), 1, 0),
        Parent = Body,
    })

    local currentTab = nil

    local function defaultIcon(parent)
        local Box = create("Frame", {
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = parent,
        }, { corner(4) })
        gradient(45, Theme.GradTop, Theme.GradBottom).Parent = Box
        return Box
    end

    function Window:CreateTab(name, icon)
        local Tab = {}
        Tab.Sections = {}

        local TabButton = create("TextButton", {
            BackgroundColor3 = Theme.SurfaceRaised,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Theme.Font,
            Text = "",
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            AutoButtonColor = false,
            Parent = TabBar,
        }, { corner(Theme.RadiusControl) })
        gradient(90, Color3.fromRGB(52, 52, 58), Color3.fromRGB(17, 17, 19)).Parent = TabButton

        local IconHolder = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, -8),
            Size = UDim2.fromOffset(16, 16),
            Parent = TabButton,
        })

        local resolved = resolveIcon(icon)
        if resolved then
            create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Image = resolved.Image,
                ImageRectOffset = resolved.RectOffset or Vector2.new(0, 0),
                ImageRectSize = resolved.RectSize or Vector2.new(0, 0),
                ImageColor3 = Theme.TextDim,
                Parent = IconHolder,
            })
        else
            defaultIcon(IconHolder)
        end

        local TabLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 32, 0, 0),
            Size = UDim2.new(1, -38, 1, 0),
            Font = Theme.Font,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton,
        })

        local Page = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            Parent = ContentArea,
        })
        padding(12).Parent = Page

        create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
        }).Parent = Page

        local function selectTab()
            if currentTab then
                currentTab.Page.Visible = false
                tween(currentTab.Button, { BackgroundColor3 = Theme.SurfaceRaised }, 0.15)
                tween(currentTab.Label, { TextColor3 = Theme.TextDim }, 0.15)
            end
            Page.Visible = true
            tween(TabButton, { BackgroundColor3 = Theme.Accent }, 0.15)
            tween(TabLabel, { TextColor3 = Theme.Text }, 0.15)
            currentTab = { Page = Page, Button = TabButton, Label = TabLabel }
        end

        TabButton.MouseButton1Click:Connect(selectTab)
        if not currentTab then selectTab() end

        function Tab:CreateSection(name)
            local Section = {}

            local Col = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -6, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Page,
            })
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
            }).Parent = Col

            if name then
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Theme.FontBold,
                    Text = name,
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Col,
                })
            end

            local Holder = create("Frame", {
                BackgroundColor3 = Theme.Surface,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Col,
            }, { corner(Theme.RadiusPanel), stroke(Theme.Border, 1, 0.3) })
            gradient(100, Color3.fromRGB(48, 48, 54), Color3.fromRGB(11, 11, 13)).Parent = Holder
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            }).Parent = Holder

            local function row(height)
                local Row = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, height or 40),
                    Parent = Holder,
                })
                padding(9, 12).Parent = Row
                return Row
            end

            function Section:CreateButton(o)
                o = o or {}
                local Row = row(40)
                local Btn = create("TextButton", {
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Theme.Font,
                    Text = o.Text or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    AutoButtonColor = false,
                    Parent = Row,
                }, { corner(Theme.RadiusControl) })
                gradient(90, Color3.fromRGB(58, 58, 64), Color3.fromRGB(19, 19, 21)).Parent = Btn
                Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Theme.AccentDim }, 0.12) end)
                Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Theme.SurfaceRaised }, 0.12) end)
                Btn.MouseButton1Click:Connect(function()
                    if o.Callback then task.spawn(o.Callback) end
                end)
                return Btn
            end

            function Section:CreateToggle(o)
                o = o or {}
                local state = o.Default or false
                local Row = row(36)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 1, 0),
                    Font = Theme.Font,
                    Text = o.Text or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Switch = create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(38, 20),
                    BackgroundColor3 = state and Theme.On or Theme.SurfaceRaised,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Row,
                }, { corner(10) })

                local Knob = create("Frame", {
                    Size = UDim2.fromOffset(16, 16),
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Theme.Text,
                    Parent = Switch,
                }, { corner(8) })

                local function set(newState, fire)
                    state = newState
                    tween(Switch, { BackgroundColor3 = state and Theme.On or Theme.SurfaceRaised }, 0.15)
                    tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
                    if fire and o.Callback then task.spawn(o.Callback, state) end
                end

                Switch.MouseButton1Click:Connect(function() set(not state, true) end)
                if o.Callback and o.CallOnInit then task.spawn(o.Callback, state) end

                return { Set = function(_, v) set(v, true) end, Get = function() return state end }
            end

            function Section:CreateSlider(o)
                o = o or {}
                local min = o.Min or 0
                local max = o.Max or 100
                local value = math.clamp(o.Default or min, min, max)
                local decimals = o.Decimals or 0

                local Row = row(46)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -50, 0, 16),
                    Font = Theme.Font,
                    Text = o.Text or "Slider",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local ValueLabel = create("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(50, 16),
                    Font = Theme.Font,
                    Text = tostring(value),
                    TextColor3 = Theme.TextDim,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = Row,
                })

                local Track = create("Frame", {
                    Position = UDim2.new(0, 0, 0, 26),
                    Size = UDim2.new(1, 0, 0, 6),
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Parent = Row,
                }, { corner(3) })

                local Fill = create("Frame", {
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Theme.Accent,
                    Parent = Track,
                }, { corner(3) })

                local dragging = false
                local function setFromAlpha(alpha)
                    alpha = math.clamp(alpha, 0, 1)
                    local raw = min + (max - min) * alpha
                    local mult = 10 ^ decimals
                    value = math.floor(raw * mult + 0.5) / mult
                    Fill.Size = UDim2.new(alpha, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    if o.Callback then task.spawn(o.Callback, value) end
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

                return { Set = function(_, v) setFromAlpha((v - min) / (max - min)) end, Get = function() return value end }
            end

            function Section:CreateDropdown(o)
                o = o or {}
                local options = o.Options or {}
                local selected = o.Default or options[1]
                local open = false

                local Row = row(36)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Font = Theme.Font,
                    Text = o.Text or "Dropdown",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Box = create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.55, 0, 0, 26),
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Text = "  " .. tostring(selected),
                    TextColor3 = Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Theme.Font,
                    TextSize = 12,
                    AutoButtonColor = false,
                    Parent = Row,
                    ZIndex = 5,
                }, { corner(Theme.RadiusControl) })

                local ListFrame = create("Frame", {
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Position = UDim2.new(0, 0, 1, 4),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Visible = false,
                    ZIndex = 10,
                    Parent = Box,
                }, { corner(Theme.RadiusControl), stroke(Theme.Border, 1, 0.3) })
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListFrame
                padding(4).Parent = ListFrame

                local function rebuild()
                    for _, c in ipairs(ListFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, opt in ipairs(options) do
                        local OptBtn = create("TextButton", {
                            BackgroundColor3 = Theme.Surface,
                            Size = UDim2.new(1, 0, 0, 26),
                            Text = "  " .. tostring(opt),
                            TextColor3 = Theme.Text,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Font = Theme.Font,
                            TextSize = 12,
                            AutoButtonColor = false,
                            ZIndex = 11,
                            Parent = ListFrame,
                        }, { corner(4) })
                        OptBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            Box.Text = "  " .. tostring(opt)
                            open = false
                            ListFrame.Visible = false
                            if o.Callback then task.spawn(o.Callback, selected) end
                        end)
                    end
                end
                rebuild()

                Box.MouseButton1Click:Connect(function()
                    open = not open
                    ListFrame.Visible = open
                end)

                return {
                    Set = function(_, v) selected = v; Box.Text = "  " .. tostring(v) end,
                    Get = function() return selected end,
                    Refresh = function(_, newOptions, newDefault)
                        options = newOptions or options
                        if newDefault then selected = newDefault; Box.Text = "  " .. tostring(selected) end
                        rebuild()
                    end,
                }
            end

            function Section:CreateTextbox(o)
                o = o or {}
                local Row = row(36)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Font = Theme.Font,
                    Text = o.Text or "Textbox",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Box = create("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.6, 0, 0, 26),
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Text = o.Default or "",
                    PlaceholderText = o.Placeholder or "",
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.TextDim,
                    Font = Theme.Font,
                    TextSize = 12,
                    ClearTextOnFocus = false,
                    Parent = Row,
                }, { corner(Theme.RadiusControl), padding(0, 8) })

                Box.FocusLost:Connect(function(enterPressed)
                    if o.Callback then task.spawn(o.Callback, Box.Text, enterPressed) end
                end)

                return { Set = function(_, v) Box.Text = v end, Get = function() return Box.Text end }
            end

            function Section:CreateKeybind(o)
                o = o or {}
                local bound = o.Default or Enum.KeyCode.Unknown
                local listening = false

                local Row = row(36)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Font = Theme.Font,
                    Text = o.Text or "Keybind",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                })

                local Box = create("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.4, 0, 0, 26),
                    BackgroundColor3 = Theme.SurfaceRaised,
                    Text = bound.Name,
                    TextColor3 = Theme.Text,
                    Font = Theme.Font,
                    TextSize = 12,
                    AutoButtonColor = false,
                    Parent = Row,
                }, { corner(Theme.RadiusControl) })

                Box.MouseButton1Click:Connect(function()
                    listening = true
                    Box.Text = "..."
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        bound = input.KeyCode
                        Box.Text = bound.Name
                        listening = false
                        if o.Callback then task.spawn(o.Callback, bound) end
                    elseif not gpe and input.KeyCode == bound and o.OnPress then
                        task.spawn(o.OnPress)
                    end
                end)

                return { Set = function(_, kc) bound = kc; Box.Text = kc.Name end, Get = function() return bound end }
            end

            function Section:CreateLabel(text)
                local Row = row(24)
                local Lbl = create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Theme.Font,
                    Text = text or "",
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = Row,
                })
                return { Set = function(_, t) Lbl.Text = t end }
            end

            Tab.Sections[#Tab.Sections + 1] = Section
            return Section
        end

        Window.Tabs[#Window.Tabs + 1] = Tab
        return Tab
    end

    Window.Main = Main
    Window.FloatingCube = FloatingCube
    return Window
end

return Library

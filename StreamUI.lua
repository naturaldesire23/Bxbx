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

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME (white background / black text / green = "on")
-- ============================================================
local Theme = {
    Background      = Color3.fromRGB(255, 255, 255),
    SecondaryBg     = Color3.fromRGB(245, 245, 245),
    TertiaryBg      = Color3.fromRGB(235, 235, 235),
    Border          = Color3.fromRGB(210, 210, 210),

    TextPrimary     = Color3.fromRGB(20, 20, 20),
    TextSecondary   = Color3.fromRGB(90, 90, 90),
    TextDisabled    = Color3.fromRGB(160, 160, 160),

    Accent          = Color3.fromRGB(30, 30, 30),   -- neutral accent (headers, sliders track)
    Enabled         = Color3.fromRGB(30, 180, 90),  -- green = ON
    Disabled        = Color3.fromRGB(225, 225, 225),-- grey = OFF

    Success         = Color3.fromRGB(30, 180, 90),
    Error           = Color3.fromRGB(220, 70, 70),
    Warning         = Color3.fromRGB(230, 170, 20),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

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

local function makeDraggable(dragHandle, target)
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
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
    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
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
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = PlayerGui,
    })

    local Main = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(480, 320),
        Position = UDim2.new(0.5, -240, 0.5, -160),
        BackgroundColor3 = Theme.Background,
        Parent = ScreenGui,
    }, { corner(10), stroke(Theme.Border, 1) })

    local TopBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.SecondaryBg,
        Parent = Main,
    }, { corner(10) })

    -- square off the bottom corners of the top bar so it blends with Main
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Theme.SecondaryBg,
        BorderSizePixel = 0,
        Parent = TopBar,
    })

    local TitleLabel = new("TextLabel", {
        Text = title or "StreamUI",
        Font = FONT_BOLD,
        TextSize = 15,
        TextColor3 = Theme.TextPrimary,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar,
    })

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

    makeDraggable(TopBar, Main)

    local TabBar = new("Frame", {
        Name = "TabBar",
        Size = UDim2.new(0, 120, 1, -50),
        Position = UDim2.fromOffset(0, 50),
        BackgroundColor3 = Theme.SecondaryBg,
        Parent = Main,
    }, { corner(8) })

    local TabList = new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    TabList.Parent = TabBar
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
        Parent = TabBar,
    })

    local PageHolder = new("Frame", {
        Name = "PageHolder",
        Size = UDim2.new(1, -136, 1, -50),
        Position = UDim2.fromOffset(128, 50),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local isOpen = true
    MinimizeBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        tween(Main, { Size = isOpen and UDim2.fromOffset(480, 320) or UDim2.fromOffset(480, 40) }, 0.2)
        TabBar.Visible = isOpen
        PageHolder.Visible = isOpen
    end)

    local Window = setmetatable({ _tabs = {}, _pages = {}, ScreenGui = ScreenGui }, { __index = StreamUI })

    -- ---------------- TAB ----------------
    function Window:CreateTab(name)
        local TabButton = new("TextButton", {
            Text = name,
            Font = FONT,
            TextSize = 13,
            TextColor3 = Theme.TextSecondary,
            BackgroundColor3 = Theme.Background,
            Size = UDim2.new(1, 0, 0, 30),
            AutoButtonColor = false,
            Parent = TabBar,
        }, { corner(6) })

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
                b.BackgroundColor3 = Theme.Background
                b.TextColor3 = Theme.TextSecondary
            end
            Page.Visible = true
            TabButton.BackgroundColor3 = Theme.TertiaryBg
            TabButton.TextColor3 = Theme.TextPrimary
        end

        TabButton.MouseButton1Click:Connect(selectTab)
        table.insert(self._tabs, TabButton)
        table.insert(self._pages, Page)

        if #self._pages == 1 then selectTab() end

        local Tab = {}

        -- row wrapper shared by all elements
        local function baseRow(height)
            return new("Frame", {
                Size = UDim2.new(1, -8, 0, height),
                BackgroundColor3 = Theme.SecondaryBg,
                Parent = Page,
            }, { corner(6), new("UIPadding", {
                PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
            }) })
        end

        -- ---------------- TOGGLE ----------------
        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local Row = baseRow(34)

            new("TextLabel", {
                Text = cfg.Title or "Toggle",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })

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
            Switch.MouseButton1Click:Connect(function()
                state = not state
                tween(Switch, { BackgroundColor3 = state and Theme.Enabled or Theme.Disabled }, 0.15)
                tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) }, 0.15)
                if cfg.Callback then cfg.Callback(state) end
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

            new("TextLabel", {
                Text = cfg.Title or "Slider",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })

            local ValueLabel = new("TextLabel", {
                Text = tostring(value),
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(50, 20),
                Position = UDim2.new(1, -50, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = Row,
            })

            local Track = new("Frame", {
                Size = UDim2.new(1, 0, 0, 6),
                Position = UDim2.fromOffset(0, 28),
                BackgroundColor3 = Theme.TertiaryBg,
                Parent = Row,
            }, { corner(3) })

            local Fill = new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Enabled,
                Parent = Track,
            }, { corner(3) })

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
            Row.ClipsDescendants = false

            new("TextLabel", {
                Text = cfg.Title or "Dropdown",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })

            local Selector = new("TextButton", {
                Text = (selected or "Select") .. "  ▾",
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundColor3 = Theme.TertiaryBg,
                Size = UDim2.new(0.5, -4, 0, 24),
                Position = UDim2.new(0.5, 4, 0.5, -12),
                Parent = Row,
            }, { corner(6) })

            local ListFrame = new("Frame", {
                Size = UDim2.new(0.5, -4, 0, math.min(#options, 5) * 24),
                Position = UDim2.new(0.5, 4, 1, 2),
                BackgroundColor3 = Theme.Background,
                Visible = false,
                ZIndex = 5,
                Parent = Row,
            }, { corner(6), stroke(Theme.Border, 1) })

            local ListLayout = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
            ListLayout.Parent = ListFrame

            for _, opt in ipairs(options) do
                local OptButton = new("TextButton", {
                    Text = opt,
                    Font = FONT,
                    TextSize = 12,
                    TextColor3 = Theme.TextPrimary,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 24),
                    ZIndex = 5,
                    Parent = ListFrame,
                })
                OptButton.MouseButton1Click:Connect(function()
                    selected = opt
                    Selector.Text = opt .. "  ▾"
                    ListFrame.Visible = false
                    if cfg.Callback then cfg.Callback(opt) end
                end)
            end

            Selector.MouseButton1Click:Connect(function()
                ListFrame.Visible = not ListFrame.Visible
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

            new("TextLabel", {
                Text = cfg.Title or "Keybind",
                Font = FONT,
                TextSize = 13,
                TextColor3 = Theme.TextPrimary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -80, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })

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

        -- ---------------- LABEL ----------------
        function Tab:CreateLabel(text)
            local Row = baseRow(26)
            new("TextLabel", {
                Text = text or "",
                Font = FONT,
                TextSize = 12,
                TextColor3 = Theme.TextSecondary,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Row,
            })
        end

        return Tab
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

--[[
    OPTIONAL: persisting settings with DataStoreService instead of writefile.

    local DataStoreService = game:GetService("DataStoreService")
    local store = DataStoreService:GetDataStore("StreamUI_Settings")

    local function saveConfig(userId, config)
        pcall(function() store:SetAsync(tostring(userId), config) end)
    end

    local function loadConfig(userId, default)
        local ok, result = pcall(function() return store:GetAsync(tostring(userId)) end)
        if ok and result then return result end
        return default
    end
]]

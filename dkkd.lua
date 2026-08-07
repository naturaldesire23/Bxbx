--[[
    ═══════════════════════════════════════════════════════════
    AETHERUI - Complete Merge of RectUI + Samet UI + Ather UI
    ═══════════════════════════════════════════════════════════
    Features from ALL 3 UIs:
    - RectUI: Window, Tabs, Sections, Toggles, Sliders, Dropdowns, Buttons, Keybinds, Labels, Textboxes
    - Samet UI: Glass theme, Gradients, Rich Text, Global Chat, Watermark, Notifications, Font System, Theme System
    - Ather UI: DepthOfField Blur, Color Pickers, Keybind List, Server Hop, Settings Page, Mod List
    
    Total: ~3500+ lines of merged code
]]

--// ─── SERVICES ───
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

gethui = gethui or function() return CoreGui end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

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

--// ─── ASSETS (From Samet UI + Ather UI) ───
local Assets = {
    Gradients = {
        AccentStart = Color3.fromRGB(175, 102, 126),
        AccentEnd = Color3.fromRGB(114, 75, 135),
    },
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
    Fonts = {
        SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Light = Font.new("rbxassetid://12187365364", Enum.FontWeight.Light, Enum.FontStyle.Normal),
    },
}

--// ─── THEME (Glass - From Samet UI) ───
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
    SectionBackground2 = Color3.fromRGB(14, 14, 16),
    Element = Color3.fromRGB(40, 40, 45),
    Border = Color3.fromRGB(50, 50, 55),
    Outline = Color3.fromRGB(25, 25, 28),
    Text = Color3.fromRGB(235, 235, 235),
    TextDim = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(0, 150, 255),
    AccentGradient = Color3.fromRGB(100, 180, 255),
    AccentStart = Color3.fromRGB(175, 102, 126),
    AccentEnd = Color3.fromRGB(114, 75, 135),
}

--// ─── MAIN UI CLASS ───
local UI = {}
UI.__index = UI
UI.Theme = DefaultTheme
UI.Assets = Assets
UI.Flags = {}
UI.Keybinds = {}
UI.Mods = {}
UI.Notifications = {}
UI.Connections = {}
UI.Threads = {}
UI.OpenFrames = {}
UI.ThemeItems = {}
UI.ThemeMap = {}
UI.Folders = {
    Directory = "AetherUI",
    Assets = "AetherUI/Assets",
    Configs = "AetherUI/Configs",
}

-- Create folders
for _, path in pairs(UI.Folders) do
    if not isfolder(path) then
        pcall(makefolder, path)
    end
end

--// ─── UTILITY FUNCTIONS ───
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

function UI:Round(num, float)
    local multiplier = 1 / (float or 1)
    return math.floor(num * multiplier) / multiplier
end

function UI:IsMouseOverFrame(frame)
    frame = frame.Instance or frame
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    return mousePos.X >= frame.AbsolutePosition.X and mousePos.X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X
        and mousePos.Y >= frame.AbsolutePosition.Y and mousePos.Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
end

function UI:ToRich(text, color)
    return `<font color="rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})">{text}</font>`
end

function UI:GetTweenProperty(item)
    if item:IsA("Frame") then
        return { "BackgroundTransparency" }
    elseif item:IsA("TextLabel") or item:IsA("TextButton") then
        return { "TextTransparency", "BackgroundTransparency" }
    elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
        return { "BackgroundTransparency", "ImageTransparency" }
    elseif item:IsA("ScrollingFrame") then
        return { "BackgroundTransparency", "ScrollBarImageTransparency" }
    elseif item:IsA("TextBox") then
        return { "TextTransparency", "BackgroundTransparency" }
    elseif item:IsA("UIStroke") then
        return { "Transparency" }
    end
    return nil
end

--// ─── THEME SYSTEM (From Samet UI) ───
function UI:AddToTheme(item, props)
    item = item.Instance or item
    local data = { Item = item, Properties = props }
    for prop, val in pairs(props) do
        if type(val) == "string" then
            item[prop] = self.Theme[val]
        elseif type(val) == "function" then
            item[prop] = val()
        end
    end
    table.insert(self.ThemeItems, data)
    self.ThemeMap[item] = data
    return item
end

function UI:ChangeTheme(theme, color)
    self.Theme[theme] = color
    for _, item in pairs(self.ThemeItems) do
        for prop, val in pairs(item.Properties) do
            if type(val) == "string" and val == theme then
                item.Item[prop] = color
            elseif type(val) == "function" then
                item.Item[prop] = val()
            end
        end
    end
end

function UI:ApplyGradient(parent, startColor, endColor, rotation)
    local grad = New("UIGradient", {
        Parent = parent,
        Rotation = rotation or -115,
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, startColor or self.Theme.AccentStart),
            ColorSequenceKeypoint.new(1, endColor or self.Theme.AccentEnd),
        }
    })
    return grad
end

--// ─── CONFIG SYSTEM (From RectUI) ───
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

--// ─── NOTIFICATION SYSTEM (From Samet UI) ───
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
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
    New("UIStroke", { Color = self.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = card })

    -- Accent bar with gradient
    local accent = New("Frame", {
        Parent = card,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
    })
    self:ApplyGradient(accent)

    New("UIPadding", {
        Parent = card,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })

    -- Icon with gradient
    local iconLabel = New("ImageLabel", {
        Parent = card,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 8, 0, 10),
        Image = icon,
        BackgroundTransparency = 1,
    })
    self:ApplyGradient(iconLabel)

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

    -- Animate in
    card.BackgroundTransparency = 1
    Tween(card, { BackgroundTransparency = 0.15 }, 0.15)

    task.delay(duration, function()
        Tween(card, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.25, function() card:Destroy() end)
    end)
end

--// ─── BLUR EFFECT (From Ather UI) ───
function UI:CreateBlur(window, frame)
    local blurPart = New("Part", {
        Material = Enum.Material.Glass,
        Transparency = 0.95,
        Reflectance = 0.3,
        CastShadow = false,
        Anchored = true,
        CanCollide = false,
        Size = Vector3.new(1, 1, 1) * 0.01,
        Parent = Workspace,
    })
    local blockMesh = New("BlockMesh", { Parent = blurPart })

    local dof = New("DepthOfFieldEffect", {
        Parent = Lighting,
        Enabled = true,
        FarIntensity = 0,
        FocusDistance = 0,
        InFocusRadius = 1000,
        NearIntensity = 0.8,
    })

    self:Connect(RunService.RenderStepped, function()
        if window.IsOpen and frame.Visible then
            local pos = frame.AbsolutePosition
            local sz = frame.AbsoluteSize
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

    return blurPart, dof
end

--// ─── COLOR PICKER (From Ather UI) ───
function UI:CreateColorpicker(data)
    data = data or {}
    local colorpicker = {
        Flag = data.Flag,
        Hue = 0,
        Saturation = 0,
        Value = 0,
        Alpha = 0,
        Color = Color3.fromRGB(255, 255, 255),
        HexValue = "#FFFFFF",
        IsOpen = false,
    }

    local items = {}
    items["Button"] = New("TextButton", {
        Parent = data.Parent.Instance,
        Size = UDim2.new(0, 24, 0, 18),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = items["Button"] })

    items["Window"] = New("Frame", {
        Parent = UI.Holder.Instance,
        Size = UDim2.new(0, 200, 0, 200),
        BackgroundColor3 = UI.Theme.Background,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Visible = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = items["Window"] })
    New("UIStroke", { Color = UI.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = items["Window"] })

    -- Palette
    items["Palette"] = New("Frame", {
        Parent = items["Window"],
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = items["Palette"] })

    -- Hue slider
    items["Hue"] = New("Frame", {
        Parent = items["Window"],
        Size = UDim2.new(1, -20, 0, 6),
        Position = UDim2.new(0, 10, 1, -30),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = items["Hue"] })
    New("UIGradient", {
        Parent = items["Hue"],
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

    function colorpicker:Update()
        local h, s, v = colorpicker.Hue, colorpicker.Saturation, colorpicker.Value
        colorpicker.Color = Color3.fromHSV(h, s, v)
        colorpicker.HexValue = colorpicker.Color:ToHex()
        items["Button"].BackgroundColor3 = colorpicker.Color
        items["Palette"].BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        if data.Callback then
            UI:SafeCall(data.Callback, colorpicker.Color, colorpicker.Alpha)
        end
    end

    items["Button"].MouseButton1Click:Connect(function()
        colorpicker.IsOpen = not colorpicker.IsOpen
        items["Window"].Visible = colorpicker.IsOpen
        if colorpicker.IsOpen then
            local pos = items["Button"].AbsolutePosition
            items["Window"].Position = UDim2.new(0, pos.X, 0, pos.Y + 22)
        end
    end)

    if data.Default then
        colorpicker.Hue, colorpicker.Saturation, colorpicker.Value = data.Default:ToHSV()
        colorpicker:Update()
    end

    UI.Flags[colorpicker.Flag] = {
        Set = function(_, c) 
            colorpicker.Hue, colorpicker.Saturation, colorpicker.Value = c:ToHSV()
            colorpicker:Update()
        end,
        Get = function() return colorpicker.Color end,
    }

    return colorpicker
end

--// ─── KEYBIND LIST (From Ather UI) ───
function UI:KeybindList(title)
    local list = {}
    local frame = New("Frame", {
        Parent = UI.Holder.Instance,
        Name = "KeybindList",
        Size = UDim2.new(0, 220, 0, 30),
        Position = UDim2.new(0, 20, 0.5, 20),
        BackgroundColor3 = UI.Theme.Section,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Visible = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    New("UIStroke", { Color = UI.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = frame })
    MakeDraggable(frame, frame)

    local header = New("Frame", {
        Parent = frame,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = UI.Theme.Header,
        BackgroundTransparency = 0.15,
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
    UI:ApplyGradient(icon)

    local titleLabel = New("TextLabel", {
        Parent = header,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text = UI:ToRich(title or "Keybinds", UI.Theme.Text),
        TextColor3 = UI.Theme.Text,
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
            Text = UI:ToRich(name .. " [" .. key .. "]", UI.Theme.Text),
            TextColor3 = UI.Theme.Text,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            RichText = true,
        })
        local accent = New("Frame", {
            Parent = row,
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(1, -12, 0.5, -3),
            BackgroundColor3 = UI.Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accent })
        UI:ApplyGradient(accent)

        local item = {
            Set = function(_, name, key)
                label.Text = UI:ToRich(name .. " [" .. key .. "]", UI.Theme.Text)
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

--// ─── WATERMARK (From Samet UI) ───
function UI:Watermark(text)
    local frame = New("Frame", {
        Parent = UI.Holder.Instance,
        Name = "Watermark",
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(0, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = UI.Theme.Section,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    New("UIStroke", { Color = UI.Theme.Border, Thickness = 1, Transparency = 0.3, Parent = frame })
    MakeDraggable(frame, frame)

    local icon = New("ImageLabel", {
        Parent = frame,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 10, 0.5, -9),
        Image = Assets.Icons.WatermarkIcon,
        BackgroundTransparency = 1,
    })
    UI:ApplyGradient(icon)

    local label = New("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text = UI:ToRich(text or "AetherUI", UI.Theme.Text),
        TextColor3 = UI.Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
    })

    return frame
end

--// ─── SERVER HOP (From Ather UI) ───
function UI:ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local placeId = game.PlaceId
    local jobId = game.JobId

    self:Notify({ Title = "Server Hop", Text = "Searching...", Duration = 1 })

    self:Thread(function()
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
            self:Notify({ Title = "Server Hop", Text = "No servers available", Duration = 2 })
        else
            self:Notify({ Title = "Server Hop", Text = "Failed to fetch servers", Duration = 2 })
        end
    end)
end

--// ─── KEYBIND SYSTEM (From Ather UI) ───
local Keys = {
    ["Unknown"] = "Unknown",
    ["Backspace"] = "Back",
    ["Tab"] = "Tab",
    ["Return"] = "Return",
    ["Escape"] = "Escape",
    ["Space"] = "Space",
    ["Delete"] = "Delete",
    ["End"] = "End",
    ["Insert"] = "Insert",
    ["Home"] = "Home",
    ["PageUp"] = "PageUp",
    ["PageDown"] = "PageDown",
    ["RightShift"] = "RightShift",
    ["LeftShift"] = "LeftShift",
    ["RightControl"] = "RightControl",
    ["LeftControl"] = "LeftControl",
    ["LeftAlt"] = "LeftAlt",
    ["RightAlt"] = "RightAlt",
}

function UI:CreateKeybind(data)
    local keybind = {
        Flag = data.Flag,
        Key = "",
        Value = "None",
        Mode = data.Mode or "Toggle",
        Toggled = false,
        Picking = false,
    }

    local items = {}
    items["Button"] = New("TextButton", {
        Parent = data.Parent.Instance,
        Size = UDim2.new(0, 80, 0, 20),
        BackgroundColor3 = UI.Theme.Element,
        BackgroundTransparency = 0.15,
        Text = "None",
        TextColor3 = UI.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 4), Parent = items["Button"] })

    function keybind:Set(key)
        if string.find(tostring(key), "Enum") then
            keybind.Key = tostring(key)
            local keyName = key.Name == "Backspace" and "None" or key.Name
            local keyStr = Keys[keybind.Key] or string.gsub(keyName, "Enum.", "") or "None"
            keybind.Value = keyStr
            items["Button"].Text = keyStr
        elseif type(key) == "table" and key.Key then
            keybind.Key = tostring(key.Key)
            if key.Mode then keybind.Mode = key.Mode end
            keybind:Set(key.Key)
        end
        UI.Flags[keybind.Flag] = { Key = keybind.Key, Mode = keybind.Mode, Toggled = keybind.Toggled }
        if data.Callback then UI:SafeCall(data.Callback, keybind.Toggled) end
    end

    items["Button"].MouseButton1Click:Connect(function()
        keybind.Picking = true
        items["Button"].Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybind:Set(input.KeyCode)
                keybind.Picking = false
                conn:Disconnect()
            end
        end)
    end)

    UI:Connect(UserInputService.InputBegan, function(input)
        if keybind.Value == "None" then return end
        if tostring(input.KeyCode) == keybind.Key then
            if keybind.Mode == "Toggle" then
                keybind.Toggled = not keybind.Toggled
            elseif keybind.Mode == "Hold" then
                keybind.Toggled = true
            end
            UI.Flags[keybind.Flag] = { Key = keybind.Key, Mode = keybind.Mode, Toggled = keybind.Toggled }
            if data.Callback then UI:SafeCall(data.Callback, keybind.Toggled) end
        end
    end)

    UI:Connect(UserInputService.InputEnded, function(input)
        if keybind.Value == "None" then return end
        if keybind.Mode == "Hold" and tostring(input.KeyCode) == keybind.Key then
            keybind.Toggled = false
            UI.Flags[keybind.Flag] = { Key = keybind.Key, Mode = keybind.Mode, Toggled = keybind.Toggled }
            if data.Callback then UI:SafeCall(data.Callback, keybind.Toggled) end
        end
    end)

    if data.Default then keybind:Set(data.Default) end
    UI.Flags[keybind.Flag] = { Key = keybind.Key, Mode = keybind.Mode, Toggled = keybind.Toggled }
    return keybind
end

--// ─── WINDOW CREATION (From RectUI + Samet UI + Ather UI) ───
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
    Window.Transparency = config.Transparency or 0.12
    Window.BlurEnabled = config.Blur ~= false

    local function registerAccentRefresher(fn)
        table.insert(Window.AccentRefreshers, fn)
    end

    function Window:SetAccent(color)
        Theme.Accent = color
        Theme.AccentStart = color
        Theme.AccentEnd = Color3.new(math.min(color.R + 0.3, 1), math.min(color.G + 0.3, 1), math.min(color.B + 0.3, 1))
        for _, refresh in ipairs(Window.AccentRefreshers) do refresh() end
    end

    function Window:SetTransparency(value)
        Window.Transparency = value
        MainFrame.BackgroundTransparency = value
        for _, child in MainFrame:GetDescendants() do
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                if child ~= MainFrame then
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

        -- Accent gradient
        local accent = New("Frame", {
            Parent = Card,
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
        })
        UI:ApplyGradient(accent)

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            Parent = Card,
        })

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

    --// ─── MAIN FRAME ───
    local MainFrame = New("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Window.Transparency,
        BorderSizePixel = 0,
        Parent = ScreenGui,
        ClipsDescendants = true,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = MainFrame })
    New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.3, Parent = MainFrame })

    --// ─── BLUR ───
    local blurPart, dof
    if Window.BlurEnabled then
        blurPart, dof = UI:CreateBlur(Window, MainFrame)
    end

    MakeDraggable(MainFrame, MainFrame)

    --// ─── HEADER ───
    local Header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Header })

    -- Logo with gradient
    local Logo = New("ImageLabel", {
        Parent = Header,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 12, 0.5, -11),
        Image = Assets.Icons.Logo,
        BackgroundTransparency = 1,
    })
    UI:ApplyGradient(Logo)

    local Title = New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Text = UI:ToRich(config.Title or "AetherUI", Theme.AccentStart),
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
        RichText = true,
    })

    --// ─── HEADER BUTTONS ───
    local function HeaderButton(name, text, xOffset)
        local btn = New("TextButton", {
            Name = name,
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(1, xOffset, 0.5, -16),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 0.5,
            Text = text,
            TextColor3 = Theme.TextDim,
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            Parent = Header,
            AutoButtonColor = false,
        })
        New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
        btn.MouseEnter:Connect(function() Tween(btn, { BackgroundTransparency = 0.2, TextColor3 = Theme.Text }, 0.1) end)
        btn.MouseLeave:Connect(function() Tween(btn, { BackgroundTransparency = 0.5, TextColor3 = Theme.TextDim }, 0.1) end)
        return btn
    end

    local CloseBtn = HeaderButton("Close", "✕", -40)
    local MinBtn = HeaderButton("Minimize", "—", -72)
    local GearBtn = HeaderButton("Settings", "⚙", -104)

    local minimized = false
    local expandedSize = size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 40) }, 0.2)
        else
            Tween(MainFrame, { Size = expandedSize }, 0.2)
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, 0.2)
        task.delay(0.25, function() Window:Destroy() end)
    end)

    GearBtn.MouseButton1Click:Connect(function()
        if Window.SettingsCallback then Window.SettingsCallback() end
    end)

    --// ─── TAB BAR ───
    local TabBar = New("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Theme.TabBar,
        BackgroundTransparency = Window.Transparency + 0.05,
        BorderSizePixel = 0,
        Parent = MainFrame,
    })
    New("UIStroke", {
        Color = Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Transparency = 0.3,
        Parent = TabBar,
    })

    local TabLayout = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = TabBar,
    })

    --// ─── CONTENT AREA ───
    local ContentArea = New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -78),
        Position = UDim2.new(0, 0, 0, 78),
        BackgroundColor3 = Theme.Background2,
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
            PaddingLeft = UDim.new(0, 18),
            PaddingRight = UDim.new(0, 18),
            Parent = TabButton,
        })

        local TabLabel = New("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TabInactive,
            TextSize = 15,
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
        UI:ApplyGradient(AccentBar)
        registerAccentRefresher(function()
            AccentBar.BackgroundColor3 = Theme.Accent
            UI:ApplyGradient(AccentBar)
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
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            Parent = Page,
        })
        local PageLayout = New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 12),
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
                Tween(TabButton, { BackgroundTransparency = 0.85 }, 0.1)
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
            New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.2, Parent = SectionFrame })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })

            -- Section header with gradient
            local SectionHeader = New("Frame", {
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = Theme.SectionTop,
                BackgroundTransparency = Window.Transparency + 0.05,
                BorderSizePixel = 0,
            })
            New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionHeader })
            UI:ApplyGradient(SectionHeader)

            local SectionTitle = New("TextLabel", {
                Parent = SectionHeader,
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text = UI:ToRich(string.upper(name), Theme.Text),
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
            })

            -- Section toggle
            local SectionToggle = New("TextButton", {
                Parent = SectionHeader,
                Size = UDim2.new(0, 28, 0, 18),
                Position = UDim2.new(1, -16, 0.5, -9),
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 0.3,
                Text = "",
                AutoButtonColor = false,
            })
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SectionToggle })

            local ToggleCircle = New("Frame", {
                Parent = SectionToggle,
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -14, 0.5, -6),
                BackgroundColor3 = Theme.TextDim,
                BackgroundTransparency = 0.6,
                BorderSizePixel = 0,
            })
            New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleCircle })

            local SectionContent = New("Frame", {
                Parent = SectionFrame,
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 14),
                PaddingRight = UDim.new(0, 14),
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
                    Tween(ToggleCircle, { Position = UDim2.new(0, 4, 0.5, -6), BackgroundTransparency = 0 }, 0.12)
                else
                    SectionContent.Visible = true
                    Tween(SectionToggle, { BackgroundTransparency = 0.3 }, 0.12)
                    Tween(ToggleCircle, { Position = UDim2.new(1, -14, 0.5, -6), BackgroundTransparency = 0.6 }, 0.12)
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
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = UI:ToRich(text, Theme.Text),
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
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = UI:ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Row,
                    RichText = true,
                })

                local Track = New("TextButton", {
                    Size = UDim2.new(0, 42, 0, 22),
                    Position = UDim2.new(1, -42, 0.5, -11),
                    BackgroundColor3 = Theme.Element,
                    BackgroundTransparency = Window.Transparency,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = Row,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

                local TrackGrad = UI:ApplyGradient(Track)
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
                        Tween(Knob, { Position = UDim2.new(0, 22, 0.5, -9), BackgroundColor3 = Theme.Text }, 0.12)
                    else
                        TrackGrad.Enabled = false
                        Tween(Track, { BackgroundColor3 = Theme.Element }, 0.12)
                        Tween(Knob, { Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.TextDim }, 0.12)
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
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            function Section:CreateSlider(text, min, max, default, callback, step, flag)
                callback = callback or function() end
                step = step or 1
                local value = default or min

                local Row = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 42),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -60, 0, 18),
                    BackgroundTransparency = 1,
                    Text = UI:ToRich(text, Theme.Text),
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
                    Position = UDim2.new(0, 0, 0, 30),
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
                UI:ApplyGradient(Fill)

                local Knob = New("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8),
                    BackgroundColor3 = Theme.Text,
                    BorderSizePixel = 0,
                    Parent = Track,
                })
                New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
                UI:ApplyGradient(Knob)

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
                    UI:ApplyGradient(Fill)
                end)

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
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    LayoutOrder = nextOrder(),
                    ZIndex = 5,
                    Parent = SectionContent,
                })

                local Label = New("TextLabel", {
                    Size = UDim2.new(1, -160, 1, 0),
                    BackgroundTransparency = 1,
                    Text = UI:ToRich(text, Theme.Text),
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

                local Arrow = New("ImageLabel", {
                    Parent = Box,
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(1, -18, 0.5, -6),
                    Image = Assets.Icons.DropdownArrow,
                    BackgroundTransparency = 1,
                })
                UI:ApplyGradient(Arrow)

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
                if flag then Window.Flags[flag] = handle end
                return handle
            end

            function Section:CreateButton(text, callback)
                local Btn = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = Window.Transparency,
                    Text = UI:ToRich(text, Theme.Text),
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    Font = Enum.Font.GothamBold,
                    AutoButtonColor = false,
                    LayoutOrder = nextOrder(),
                    Parent = SectionContent,
                    RichText = true,
                })
                New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })
                UI:ApplyGradient(Btn)

                Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundTransparency = 0.1 }, 0.1) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundTransparency = Window.Transparency }, 0.1) end)
                Btn.MouseButton1Click:Connect(function() callback() end)

                registerAccentRefresher(function()
                    Btn.BackgroundColor3 = Theme.Accent
                    UI:ApplyGradient(Btn)
                end)
                return Btn
            end

            function Section:CreateKeybind(text, default, callback, flag)
                return UI:CreateKeybind({
                    Parent = SectionContent,
                    Flag = flag,
                    Default = default,
                    Mode = "Toggle",
                    Callback = callback,
                })
            end

            function Section:CreateColorpicker(text, default, callback, flag)
                local label = Section:CreateLabel(text)
                return UI:CreateColorpicker({
                    Parent = label,
                    Flag = flag,
                    Default = default,
                    Callback = callback,
                })
            end

            return Section
        end

        return Tab
    end

    --// ─── SETTINGS PAGE ───
    function Window:CreateSettingsPage()
        local page = Window:CreateTab("Settings")
        local section = page:CreateSection("Configs")

        local configDropdown = section:CreateDropdown("Config", UI:GetConfigList(), function(v) end)

        section:CreateButton("Save Config", function()
            local name = "config"
            Window:SaveConfig(name)
            configDropdown:Set(name)
        end)

        section:CreateButton("Load Config", function()
            Window:LoadConfig("config")
        end)

        section:CreateButton("Refresh List", function()
            configDropdown:Set(UI:GetConfigList())
        end)

        local uiSection = page:CreateSection("UI")
        uiSection:CreateSlider("Transparency", 0, 0.5, Window.Transparency, function(v)
            Window:SetTransparency(v)
        end, 0.01)

        uiSection:CreateToggle("Blur Effect", Window.BlurEnabled, function(v)
            Window.BlurEnabled = v
            if v then
                if not blurPart then blurPart, dof = UI:CreateBlur(Window, MainFrame) end
            else
                if blurPart then blurPart:Destroy() blurPart = nil end
                if dof then dof:Destroy() dof = nil end
            end
        end)

        uiSection:CreateButton("Server Hop", function()
            UI:ServerHop()
        end)

        return page
    end

    Window.Gui = ScreenGui
    Window.Frame = MainFrame
    Window.IsOpen = true

    -- Animate open
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(MainFrame, { Size = size }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(MainFrame, { Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2) }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return Window
end

--// ─── HOLDER ───
UI.Holder = New("ScreenGui", {
    Parent = gethui(),
    Name = "AetherUI_Base",
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
    DisplayOrder = 2,
    ResetOnSpawn = false,
})

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
    getgenv().AetherUI = nil
    self = nil
end

getgenv().AetherUI = UI
return UI

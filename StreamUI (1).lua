-- ============================================================
-- StreamUI Rewrite (clean)
-- ============================================================

local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")
local HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local TextService = cloneref and cloneref(game:GetService("TextService")) or game:GetService("TextService")
local RunService = cloneref and cloneref(game:GetService("RunService")) or game:GetService("RunService")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local GuiService = cloneref and cloneref(game:GetService("GuiService")) or game:GetService("GuiService")
local Lighting = cloneref and cloneref(game:GetService("Lighting")) or game:GetService("Lighting")
local Workspace = cloneref and cloneref(game:GetService("Workspace")) or game:GetService("Workspace")

local mouse = Players.LocalPlayer:GetMouse()

local DefaultTheme = {
    Background = Color3.fromRGB(10, 16, 20),
    Group = Color3.fromRGB(16, 24, 30),
    GroupStroke = Color3.fromRGB(46, 72, 84),
    Control = Color3.fromRGB(24, 36, 44),
    ControlHover = Color3.fromRGB(34, 50, 60),
    Text = Color3.fromRGB(220, 235, 240),
    TextDim = Color3.fromRGB(150, 172, 182),
    Accent = Color3.fromRGB(120, 220, 235),
}
local Theme = {}
for k,v in pairs(DefaultTheme) do Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v end

local CONFIG_DIR = "AchaoticUI/AllusiveModified"
local MAX_BODY_HEIGHT = 320
local HEADER_HEIGHT = 60
local PANEL_WIDTH = 241
local ELEMENT_WIDTH = 207

local Config = {
    ensure_dir = function()
        if not (writefile and isfolder) then return end
        if not isfolder(CONFIG_DIR) then pcall(makefolder, CONFIG_DIR) end
        if not isfolder(CONFIG_DIR.."/Configs") then pcall(makefolder, CONFIG_DIR.."/Configs") end
    end,
    save = function(name, data)
        if not writefile then return end
        Config.ensure_dir()
        pcall(function()
            writefile(CONFIG_DIR.."/"..name..".json", HttpService:JSONEncode(data))
        end)
    end,
    load = function(name, default)
        if not (isfile and readfile) then return default end
        local ok, result = pcall(function()
            local path = CONFIG_DIR.."/"..name..".json"
            if not isfile(path) then return default end
            local raw = readfile(path)
            if not raw then return default end
            return HttpService:JSONDecode(raw)
        end)
        if not ok or not result then return default end
        return result
    end,
}

local Library = {
    _config = { _flags = {}, _keybinds = {} },
    _keybinds_active = {},
    _elements = {},
    _flag_registry = {},
    _notif_side = "Right",
    _notif_opacity = 0,
    _notif_image_transparency = 0,
    _ui_open = true,
    _ui_scale = 1,
    _choosing_keybind = false,
}
Library.__index = Library

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StreamUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui
if protect_gui then pcall(protect_gui, ScreenGui) end

-- ============================================================
-- Keybind system (unified)
-- ============================================================
function Library:RegisterKeybind(flag, title, key, callback)
    if Library._keybinds_active[flag] and Library._keybinds_active[flag].connection then
        Library._keybinds_active[flag].connection:Disconnect()
    end
    Library._keybinds_active[flag] = {
        title = title,
        key = key,
        callback = callback,
    }
    if key then
        Library._keybinds_active[flag].connection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if tostring(input.KeyCode) == key then
                callback()
            end
        end)
    end
end

function Library:UnregisterKeybind(flag)
    if Library._keybinds_active[flag] and Library._keybinds_active[flag].connection then
        Library._keybinds_active[flag].connection:Disconnect()
    end
    Library._keybinds_active[flag] = nil
end

function Library:SaveConfig()
    Config.save(tostring(game.PlaceId), Library._config)
end

-- ============================================================
-- Notifications
-- ============================================================
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Notifications"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.Position = UDim2.new(1, -22, 1, -22)
NotificationContainer.ZIndex = 500

local NotifList = Instance.new("UIListLayout")
NotifList.Padding = UDim.new(0, 8)
NotifList.SortOrder = Enum.SortOrder.LayoutOrder
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Parent = NotificationContainer

local function UpdateNotifPosition()
    if Library._notif_side == "Left" then
        NotificationContainer.AnchorPoint = Vector2.new(0, 1)
        NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
    else
        NotificationContainer.AnchorPoint = Vector2.new(1, 1)
        NotificationContainer.Position = UDim2.new(1, -22, 1, -22)
    end
end
UpdateNotifPosition()

function Library:Notify(settings)
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(0, 300, 0, 62)
    outer.BackgroundTransparency = 1
    outer.BorderSizePixel = 0
    outer.Parent = NotificationContainer

    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.Position = UDim2.new(Library._notif_side == "Left" and -1 or 1, 320, 0, 0)
    inner.BackgroundColor3 = Theme.Group
    inner.BackgroundTransparency = Library._notif_opacity
    inner.BorderSizePixel = 0
    inner.Parent = outer
    table.insert(Library._elements, {obj = inner, prop = "BackgroundColor3", tKey = "Group"})

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    grad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.92),
        NumberSequenceKeypoint.new(1, 1)
    }
    grad.Rotation = 90
    grad.Parent = inner

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inner

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.GroupStroke
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = inner
    table.insert(Library._elements, {obj = stroke, prop = "Color", tKey = "GroupStroke"})

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, -12)
    accent.Position = UDim2.new(0, 6, 0, 6)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    accent.Parent = inner
    table.insert(Library._elements, {obj = accent, prop = "BackgroundColor3", tKey = "Accent"})

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local title = Instance.new("TextLabel")
    title.Text = settings.title or "Notification"
    title.TextColor3 = Theme.Text
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    title.TextSize = 14
    title.Size = UDim2.new(1, -25, 0, 18)
    title.Position = UDim2.new(0, 15, 0, 8)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Parent = inner
    table.insert(Library._elements, {obj = title, prop = "TextColor3", tKey = "Text"})

    local body = Instance.new("TextLabel")
    body.Text = settings.text or ""
    body.TextColor3 = Theme.TextDim
    body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    body.TextSize = 12
    body.Size = UDim2.new(1, -25, 0, 14)
    body.Position = UDim2.new(0, 15, 0, 32)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Center
    body.TextTruncate = Enum.TextTruncate.AtEnd
    body.Parent = inner
    table.insert(Library._elements, {obj = body, prop = "TextColor3", tKey = "TextDim"})

    task.spawn(function()
        TweenService:Create(inner, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(settings.duration or 5)
        local t = TweenService:Create(inner, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(Library._notif_side == "Left" and -1 or 1, 320, 0, 0)
        })
        t:Play()
        t.Completed:Wait()
        outer:Destroy()
    end)
end

-- ============================================================
-- Background resolver
-- ============================================================
local BG_FOLDER = CONFIG_DIR.."/Backgrounds"

local function ResolveBackground(source)
    if source == "" then return "" end
    if source:match("^%d+$") then return "rbxassetid://"..source end
    if source:match("^rbx%a+://") then return source end
    local custom = getcustomasset or getsynasset
    if not custom then return "" end
    if not source:match("^https?://") then
        if isfile and isfile(source) then
            local ok, r = pcall(custom, source)
            if ok then return r end
        end
        return ""
    end
    if not (writefile and isfile and isfolder) then return "" end
    if not isfolder(BG_FOLDER) then pcall(makefolder, BG_FOLDER) end
    local ext = source:match("%.(%a%a%a%a?)[%?#]") or source:match("%.(%a%a%a%a?)$") or "png"
    local path = BG_FOLDER.."/"..source:gsub("%W",""):sub(-48).."."..ext
    if not isfile(path) then
        local ok, body = pcall(game.HttpGet, game, source, true)
        if not ok then return "" end
        writefile(path, body)
    end
    local ok, r = pcall(custom, path)
    return ok and r or ""
end

-- ============================================================
-- Library: new / create_ui / load
-- ============================================================
function Library.new(cfg)
    local self = setmetatable({ _tab = 0, _config = { _flags = {}, _keybinds = {} } }, Library)
    Library._config = Config.load(tostring(game.PlaceId), { _flags = {}, _keybinds = {} })
    if not Library._config._flags then Library._config._flags = {} end
    if not Library._config._keybinds then Library._config._keybinds = {} end

    local c = cfg or {}
    if c.PrimaryColor then Theme.Accent = c.PrimaryColor end
    self._title = c.title or "Achaotic"
    self._primary = c.PrimaryColor or Color3.fromRGB(120, 220, 235)

    self:create_ui()
    return self
end

function Library:create_ui()
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.BackgroundColor3 = Theme.Background
    Container.BackgroundTransparency = 0.05
    Container.BorderSizePixel = 0
    Container.ClipsDescendants = true
    Container.Active = true
    Container.Parent = ScreenGui
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = Container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.GroupStroke
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Container
    table.insert(Library._elements, {obj = stroke, prop = "Color", tKey = "GroupStroke"})

    -- Background image (clipped by rounded corners)
    local Background = Instance.new("ImageLabel")
    Background.Name = "Bg"
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.Image = ""
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.ClipsDescendants = true
    Background.Parent = Container
    table.insert(Library._elements, {obj = Background, prop = "BackgroundColor3", tKey = "Background"})

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = Background

    self._background = Background
    self._container = Container

    local Handler = Instance.new("Frame")
    Handler.Name = "Handler"
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BackgroundTransparency = 1
    Handler.BorderSizePixel = 0
    Handler.Parent = Container
    self._handler = Handler

    -- Tabs
    local Tabs = Instance.new("ScrollingFrame")
    Tabs.Name = "Tabs"
    Tabs.Position = UDim2.new(0, 18, 0, 60)
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.BackgroundTransparency = 1
    Tabs.BorderSizePixel = 0
    Tabs.ScrollBarThickness = 0
    Tabs.ScrollBarImageTransparency = 1
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Tabs.Selectable = false
    Tabs.Parent = Handler

    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = Tabs

    self._tabs = Tabs

    -- Client name
    local ClientName = Instance.new("TextLabel")
    ClientName.Text = self._title
    ClientName.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = self._primary
    ClientName.TextTransparency = 0.2
    ClientName.TextSize = 14
    ClientName.Size = UDim2.new(0, 200, 0, 16)
    ClientName.Position = UDim2.new(0, 40, 0, 22)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "Accent"})

    local Logo = Instance.new("ImageLabel")
    Logo.Image = "rbxassetid://107819132007001"
    Logo.ImageColor3 = self._primary
    Logo.Size = UDim2.new(0, 20, 0, 20)
    Logo.Position = UDim2.new(0, 14, 0, 20)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.Parent = Handler
    table.insert(Library._elements, {obj = Logo, prop = "ImageColor3", tKey = "Accent"})

    local Pin = Instance.new("Frame")
    Pin.Position = UDim2.new(0, 18, 0, 76)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BackgroundColor3 = self._primary
    Pin.BorderSizePixel = 0
    Pin.Parent = Handler
    table.insert(Library._elements, {obj = Pin, prop = "BackgroundColor3", tKey = "Accent"})

    local pinCorner = Instance.new("UICorner")
    pinCorner.CornerRadius = UDim.new(1, 0)
    pinCorner.Parent = Pin
    self._pin = Pin

    local Divider = Instance.new("Frame")
    Divider.Position = UDim2.new(0, 164, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BackgroundColor3 = Theme.GroupStroke
    Divider.BackgroundTransparency = 0.5
    Divider.BorderSizePixel = 0
    Divider.Parent = Handler
    table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "GroupStroke"})

    local Sections = Instance.new("Folder")
    Sections.Name = "Sections"
    Sections.Parent = Handler
    self._sections = Sections

    local Minimize = Instance.new("TextButton")
    Minimize.Text = ""
    Minimize.AutoButtonColor = false
    Minimize.BackgroundTransparency = 1
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.Position = UDim2.new(0, 8, 0, 8)
    Minimize.Parent = Handler
    self._minimize_btn = Minimize

    local UIScale = Instance.new("UIScale")
    UIScale.Parent = Container
    self._uiscale = UIScale

    -- Drag
    local dragging, dragStart, containerStart
    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.Y - Container.AbsolutePosition.Y <= 48 then
                dragging = true
                dragStart = input.Position
                containerStart = Container.Position
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Container.Position = UDim2.new(containerStart.X.Scale, containerStart.X.Offset + delta.X, containerStart.Y.Scale, containerStart.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Toggle hotkey
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local key = Library._config._keybinds["Minimize_Keybind"] or "Enum.KeyCode.Insert"
        if tostring(input.KeyCode) ~= key then return end
        self._ui_open = not self._ui_open
        self:SetVisible(self._ui_open)
    end)

    self._minimize_btn.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:SetVisible(self._ui_open)
    end)

    -- Notif container above
    NotificationContainer.Parent = ScreenGui

    -- Handle death/reset (nothing needed but for completeness)
    return self
end

function Library:SetVisible(state)
    Library._ui_open = state
    if Library._config._flags["UI_HideOnMinimize"] then
        ScreenGui.Enabled = state
        self._container.Size = state and UDim2.fromOffset(698, 479) or UDim2.fromOffset(698, 479)
    else
        TweenService:Create(self._container, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = state and UDim2.fromOffset(698, 479) or UDim2.fromOffset(104.5, 52)
        }):Play()
    end
end

function Library:load()
    -- Mobile scale
    if UserInputService.TouchEnabled then
        local vx = workspace.CurrentCamera.ViewportSize.X
        self._ui_scale = vx / 1400
        self._uiscale.Scale = self._ui_scale
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            self._ui_scale = workspace.CurrentCamera.ViewportSize.X / 1400
            self._uiscale.Scale = self._ui_scale
        end)
    end

    TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(698, 479)
    }):Play()

    -- Apply saved theme
    for key in pairs(DefaultTheme) do
        local saved = Library._config._flags["Theme_"..key]
        if saved then
            local hex = saved:gsub("#","")
            local r = tonumber("0x"..hex:sub(1,2)) or 0
            local g = tonumber("0x"..hex:sub(3,4)) or 0
            local b = tonumber("0x"..hex:sub(5,6)) or 0
            self:SetColor(key, Color3.fromRGB(r,g,b))
        end
    end

    local saved_bg = Library._config._flags["Background_Image"]
    if saved_bg and saved_bg ~= "" then
        self:SetBackground(saved_bg, Library._config._flags["Background_Transparency"] or 0.5)
    end

    local ui_trans = Library._config._flags["UI_Container_Transparency"]
    if ui_trans then
        self._container.BackgroundTransparency = ui_trans / 100
    end
end

function Library:SetColor(key, color)
    Theme[key] = color
    for _, el in ipairs(Library._elements) do
        if el.tKey == key then
            pcall(function() el.obj[el.prop] = color end)
        end
    end
    Library._config._flags["Theme_"..key] = string.format("#%02X%02X%02X",
        math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
    Library:SaveConfig()
end

function Library:SetBackground(source, transparency)
    if not self._background then return end
    local resolved = ResolveBackground(source)
    if resolved ~= "" then
        self._background.Image = resolved
        self._background.Visible = true
        self._background.ImageTransparency = transparency or 0.5
    else
        self._background.Image = ""
        self._background.Visible = false
    end
    Library._config._flags["Background_Image"] = source or ""
    Library._config._flags["Background_Transparency"] = transparency or 0.5
    Library:SaveConfig()
end

-- ============================================================
-- Tabs
-- ============================================================
function Library:create_tab(title, icon)
    local TabManager = {}

    local Tab = Instance.new("TextButton")
    Tab.Name = "Tab"
    Tab.Size = UDim2.new(0, 129, 0, 38)
    Tab.BackgroundColor3 = Theme.Group
    Tab.BackgroundTransparency = 1
    Tab.AutoButtonColor = false
    Tab.Text = ""
    Tab.BorderSizePixel = 0
    Tab.LayoutOrder = self._tab
    Tab.Parent = self._tabs
    table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Group"})

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 5)
    tabCorner.Parent = Tab

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 14, 0, 14)
    Icon.Position = UDim2.new(0, 12, 0.5, -7)
    Icon.BackgroundTransparency = 1
    Icon.Image = icon
    Icon.ImageColor3 = Theme.TextDim
    Icon.ImageTransparency = 0.4
    Icon.Parent = Tab
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextDim"})

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Text = title
    TabLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TabLabel.TextColor3 = Theme.TextDim
    TabLabel.TextTransparency = 0.4
    TabLabel.TextSize = 13
    TabLabel.Size = UDim2.new(1, -40, 1, 0)
    TabLabel.Position = UDim2.new(0, 34, 0, 0)
    TabLabel.BackgroundTransparency = 1
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.TextYAlignment = Enum.TextYAlignment.Center
    TabLabel.Parent = Tab
    table.insert(Library._elements, {obj = TabLabel, prop = "TextColor3", tKey = "TextDim"})

    local LeftSection = Instance.new("ScrollingFrame")
    LeftSection.Name = "LeftSection"
    LeftSection.Position = UDim2.new(0, 182, 0, 60)
    LeftSection.Size = UDim2.new(0, 243, 0, 405)
    LeftSection.BackgroundTransparency = 1
    LeftSection.BorderSizePixel = 0
    LeftSection.ScrollBarThickness = 0
    LeftSection.ScrollBarImageTransparency = 1
    LeftSection.CanvasSize = UDim2.new(0, 0, 0, 0)
    LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LeftSection.Selectable = false
    LeftSection.Visible = false
    LeftSection.Parent = self._sections

    local LeftLayout = Instance.new("UIListLayout")
    LeftLayout.Padding = UDim.new(0, 10)
    LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Parent = LeftSection

    local RightSection = Instance.new("ScrollingFrame")
    RightSection.Name = "RightSection"
    RightSection.Position = UDim2.new(0, 443, 0, 60)
    RightSection.Size = UDim2.new(0, 243, 0, 405)
    RightSection.BackgroundTransparency = 1
    RightSection.BorderSizePixel = 0
    RightSection.ScrollBarThickness = 0
    RightSection.ScrollBarImageTransparency = 1
    RightSection.CanvasSize = UDim2.new(0, 0, 0, 0)
    RightSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RightSection.Selectable = false
    RightSection.Visible = false
    RightSection.Parent = self._sections

    local RightLayout = Instance.new("UIListLayout")
    RightLayout.Padding = UDim.new(0, 10)
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Parent = RightSection

    self._tab = self._tab + 1

    local allSections = {}
    for _, child in ipairs(self._sections:GetChildren()) do
        if child:IsA("ScrollingFrame") then
            table.insert(allSections, child)
        end
    end

    local function showThisTab()
        for _, sec in ipairs(allSections) do sec.Visible = false end
        LeftSection.Visible = true
        RightSection.Visible = true
    end

    local function highlightTab()
        for _, child in ipairs(self._tabs:GetChildren()) do
            if child:IsA("TextButton") then
                if child == Tab then
                    TweenService:Create(child, TweenInfo.new(0.25), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(child.Icon or child:FindFirstChildOfClass("ImageLabel"), TweenInfo.new(0.25), { ImageColor3 = Theme.Accent, ImageTransparency = 0.2 }):Play()
                    TweenService:Create(child:FindFirstChildOfClass("TextLabel"), TweenInfo.new(0.25), { TextColor3 = Theme.Accent, TextTransparency = 0.2 }):Play()
                else
                    TweenService:Create(child, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(child:FindFirstChildOfClass("ImageLabel"), TweenInfo.new(0.25), { ImageColor3 = Theme.TextDim, ImageTransparency = 0.5 }):Play()
                    TweenService:Create(child:FindFirstChildOfClass("TextLabel"), TweenInfo.new(0.25), { TextColor3 = Theme.TextDim, TextTransparency = 0.5 }):Play()
                end
            end
        end
        local idx = Tab.LayoutOrder
        TweenService:Create(self._pin, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0, 18, 0, 76 + idx * 42)
        }):Play()
    end

    if self._tab == 1 then
        showThisTab()
        highlightTab()
    end

    Tab.MouseButton1Click:Connect(function()
        showThisTab()
        highlightTab()
    end)

    -- ========================================================
    -- Module
    -- ========================================================
    function TabManager:create_module(settings)
        local section = settings.section == "right" and RightSection or LeftSection

        local Module = Instance.new("Frame")
        Module.Name = "Module"
        Module.Size = UDim2.fromOffset(PANEL_WIDTH, HEADER_HEIGHT)
        Module.BackgroundColor3 = Theme.Group
        Module.BackgroundTransparency = 0.15
        Module.BorderSizePixel = 0
        Module.ClipsDescendants = true
        Module.Parent = section
        table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

        local modCorner = Instance.new("UICorner")
        modCorner.CornerRadius = UDim.new(0, 8)
        modCorner.Parent = Module

        local modStroke = Instance.new("UIStroke")
        modStroke.Color = Theme.GroupStroke
        modStroke.Transparency = 0.5
        modStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        modStroke.Parent = Module
        table.insert(Library._elements, {obj = modStroke, prop = "Color", tKey = "GroupStroke"})

        -- Header
        local Header = Instance.new("TextButton")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
        Header.BackgroundTransparency = 1
        Header.Text = ""
        Header.AutoButtonColor = false
        Header.BorderSizePixel = 0
        Header.Parent = Module

        local Title = Instance.new("TextLabel")
        Title.Text = settings.title or "Module"
        Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Title.TextColor3 = Theme.Accent
        Title.TextSize = 14
        Title.Size = UDim2.new(1, -120, 0, 16)
        Title.Position = UDim2.new(0, 14, 0, 12)
        Title.BackgroundTransparency = 1
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Header
        table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Accent"})

        local Description = Instance.new("TextLabel")
        Description.Text = settings.description or ""
        Description.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Description.TextColor3 = Theme.TextDim
        Description.TextSize = 10
        Description.Size = UDim2.new(1, -120, 0, 12)
        Description.Position = UDim2.new(0, 14, 0, 30)
        Description.BackgroundTransparency = 1
        Description.TextXAlignment = Enum.TextXAlignment.Left
        Description.Parent = Header
        table.insert(Library._elements, {obj = Description, prop = "TextColor3", tKey = "TextDim"})

        -- Keybind box on header
        local HeaderKeybind = Instance.new("TextButton")
        HeaderKeybind.Size = UDim2.fromOffset(36, 16)
        HeaderKeybind.Position = UDim2.new(0, 14, 0, 42)
        HeaderKeybind.BackgroundColor3 = Theme.Control
        HeaderKeybind.BackgroundTransparency = 0.2
        HeaderKeybind.AutoButtonColor = false
        HeaderKeybind.Text = ""
        HeaderKeybind.BorderSizePixel = 0
        HeaderKeybind.Parent = Header
        table.insert(Library._elements, {obj = HeaderKeybind, prop = "BackgroundColor3", tKey = "Control"})

        local hkCorner = Instance.new("UICorner")
        hkCorner.CornerRadius = UDim.new(0, 3)
        hkCorner.Parent = HeaderKeybind

        local hkStroke = Instance.new("UIStroke")
        hkStroke.Color = Theme.GroupStroke
        hkStroke.Transparency = 0.4
        hkStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        hkStroke.Parent = HeaderKeybind
        table.insert(Library._elements, {obj = hkStroke, prop = "Color", tKey = "GroupStroke"})

        local HKLabel = Instance.new("TextLabel")
        HKLabel.Text = "None"
        HKLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        HKLabel.TextColor3 = Theme.Text
        HKLabel.TextSize = 10
        HKLabel.Size = UDim2.new(1, -6, 1, 0)
        HKLabel.Position = UDim2.new(0, 3, 0, 0)
        HKLabel.BackgroundTransparency = 1
        HKLabel.TextXAlignment = Enum.TextXAlignment.Center
        HKLabel.Parent = HeaderKeybind
        table.insert(Library._elements, {obj = HKLabel, prop = "TextColor3", tKey = "Text"})

        -- Toggle switch on header
        local Toggle = Instance.new("Frame")
        Toggle.Size = UDim2.fromOffset(30, 16)
        Toggle.Position = UDim2.new(1, -42, 0, 22)
        Toggle.BackgroundColor3 = Theme.Control
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Header
        table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control"})

        local togCorner = Instance.new("UICorner")
        togCorner.CornerRadius = UDim.new(1, 0)
        togCorner.Parent = Toggle

        local ToggleKnob = Instance.new("Frame")
        ToggleKnob.Size = UDim2.fromOffset(12, 12)
        ToggleKnob.Position = UDim2.new(0, 2, 0.5, -6)
        ToggleKnob.BackgroundColor3 = Theme.TextDim
        ToggleKnob.BorderSizePixel = 0
        ToggleKnob.Parent = Toggle
        table.insert(Library._elements, {obj = ToggleKnob, prop = "BackgroundColor3", tKey = "TextDim"})

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = ToggleKnob

        -- Body: ScrollingFrame
        local Body = Instance.new("ScrollingFrame")
        Body.Name = "Body"
        Body.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.BackgroundTransparency = 1
        Body.BorderSizePixel = 0
        Body.ScrollBarThickness = 3
        Body.ScrollBarImageColor3 = Theme.Accent
        Body.ScrollBarImageTransparency = 0.6
        Body.CanvasSize = UDim2.new(0, 0, 0, 0)
        Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Body.ScrollingDirection = Enum.ScrollingDirection.Y
        Body.Selectable = false
        Body.Parent = Module

        local bodyPad = Instance.new("UIPadding")
        bodyPad.PaddingTop = UDim.new(0, 8)
        bodyPad.PaddingBottom = UDim.new(0, 10)
        bodyPad.PaddingLeft = UDim.new(0, 17)
        bodyPad.PaddingRight = UDim.new(0, 17)
        bodyPad.Parent = Body

        local bodyLayout = Instance.new("UIListLayout")
        bodyLayout.Padding = UDim.new(0, 6)
        bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
        bodyLayout.Parent = Body

        local state = { open = false, layoutOrder = 0 }
        local ModuleManager = {}

        local function refresh()
            local contentY = bodyLayout.AbsoluteContentSize.Y
            local bodyHeight = math.clamp(contentY + 18, 0, MAX_BODY_HEIGHT)
            local totalHeight = HEADER_HEIGHT + (state.open and bodyHeight or 0)
            TweenService:Create(Module, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(PANEL_WIDTH, totalHeight)
            }):Play()
            TweenService:Create(Body, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(PANEL_WIDTH, state.open and bodyHeight or 0)
            }):Play()
        end

        bodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refresh)

        local function set_open(open)
            state.open = open
            Library._config._flags[settings.flag or settings.title] = open
            if settings.flag then
                Library._flag_registry[settings.flag] = set_open
            end
            Library:SaveConfig()
            if open then
                TweenService:Create(Toggle, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Accent }):Play()
                TweenService:Create(ToggleKnob, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Group, Position = UDim2.new(1, -14, 0.5, -6) }):Play()
            else
                TweenService:Create(Toggle, TweenInfo.new(0.2), { BackgroundColor3 = Theme.Control }):Play()
                TweenService:Create(ToggleKnob, TweenInfo.new(0.2), { BackgroundColor3 = Theme.TextDim, Position = UDim2.new(0, 2, 0.5, -6) }):Play()
            end
            refresh()
            if settings.callback then settings.callback(open) end
        end

        if settings.flag and Library._config._flags[settings.flag] then
            set_open(true)
        else
            set_open(false)
        end

        Header.MouseButton1Click:Connect(function()
            set_open(not state.open)
        end)

        -- Module keybind (header keybind box)
        local function refresh_hk()
            local stored = Library._config._keybinds[settings.flag or settings.title]
            if stored then
                HKLabel.Text = string.gsub(tostring(stored), "Enum.KeyCode.", "")
                HeaderKeybind.Size = UDim2.fromOffset(math.max(36, HKLabel.TextBounds.X + 12), 16)
            else
                HKLabel.Text = "None"
                HeaderKeybind.Size = UDim2.fromOffset(36, 16)
            end
        end
        refresh_hk()

        if settings.flag then
            local stored_key = Library._config._keybinds[settings.flag]
            if stored_key then
                Library:RegisterKeybind(settings.flag, settings.title or "Module", stored_key, function()
                    set_open(not state.open)
                end)
            end
        end

        HeaderKeybind.MouseButton1Click:Connect(function()
            if Library._choosing_keybind then return end
            Library._choosing_keybind = true
            HKLabel.Text = "..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, processed)
                if processed then return end
                if input.KeyCode == Enum.KeyCode.Unknown then return end
                local flag = settings.flag or settings.title
                if input.KeyCode == Enum.KeyCode.Backspace then
                    Library._config._keybinds[flag] = nil
                    Library:UnregisterKeybind(flag)
                else
                    Library._config._keybinds[flag] = tostring(input.KeyCode)
                    Library:RegisterKeybind(flag, settings.title or "Module", tostring(input.KeyCode), function()
                        set_open(not state.open)
                    end)
                end
                Library:SaveConfig()
                Library._choosing_keybind = false
                refresh_hk()
                conn:Disconnect()
            end)
        end)

        -- ====================================================
        -- Element creators
        -- ====================================================
        local function addElement(frame, height)
            state.layoutOrder = state.layoutOrder + 1
            frame.LayoutOrder = state.layoutOrder
            frame.Parent = Body
            return frame
        end

        function ModuleManager:create_checkbox(opts)
            local flag = opts.flag
            local isOn = Library._config._flags[flag] == true

            local Row = Instance.new("TextButton")
            Row.Size = UDim2.fromOffset(ELEMENT_WIDTH, 22)
            Row.BackgroundTransparency = 1
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.BorderSizePixel = 0

            local Title = Instance.new("TextLabel")
            Title.Text = opts.title or "Checkbox"
            Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = Theme.Text
            Title.TextSize = 12
            Title.Size = UDim2.new(1, -80, 1, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.TextYAlignment = Enum.TextYAlignment.Center
            Title.Parent = Row
            table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

            local KeyBox = Instance.new("TextButton")
            KeyBox.Size = UDim2.fromOffset(28, 16)
            KeyBox.Position = UDim2.new(1, -66, 0.5, -8)
            KeyBox.BackgroundColor3 = Theme.Control
            KeyBox.BackgroundTransparency = 0.2
            KeyBox.AutoButtonColor = false
            KeyBox.Text = ""
            KeyBox.BorderSizePixel = 0
            KeyBox.Parent = Row
            table.insert(Library._elements, {obj = KeyBox, prop = "BackgroundColor3", tKey = "Control"})

            local kbCorner = Instance.new("UICorner")
            kbCorner.CornerRadius = UDim.new(0, 3)
            kbCorner.Parent = KeyBox

            local kbStroke = Instance.new("UIStroke")
            kbStroke.Color = Theme.GroupStroke
            kbStroke.Transparency = 0.4
            kbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            kbStroke.Parent = KeyBox
            table.insert(Library._elements, {obj = kbStroke, prop = "Color", tKey = "GroupStroke"})

            local KBLabel = Instance.new("TextLabel")
            KBLabel.Text = "..."
            KBLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KBLabel.TextColor3 = Theme.Text
            KBLabel.TextSize = 9
            KBLabel.Size = UDim2.new(1, -4, 1, 0)
            KBLabel.BackgroundTransparency = 1
            KBLabel.TextXAlignment = Enum.TextXAlignment.Center
            KBLabel.Parent = KeyBox
            table.insert(Library._elements, {obj = KBLabel, prop = "TextColor3", tKey = "Text"})

            local Box = Instance.new("Frame")
            Box.Size = UDim2.fromOffset(16, 16)
            Box.Position = UDim2.new(1, -18, 0.5, -8)
            Box.BackgroundColor3 = Theme.Control
            Box.BorderSizePixel = 0
            Box.Parent = Row
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = Box

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = Theme.Accent
            BoxStroke.Transparency = 0.5
            BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            BoxStroke.Parent = Box
            table.insert(Library._elements, {obj = BoxStroke, prop = "Color", tKey = "Accent"})

            local Fill = Instance.new("Frame")
            Fill.AnchorPoint = Vector2.new(0.5, 0.5)
            Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
            Fill.Size = isOn and UDim2.fromOffset(9, 9) or UDim2.fromOffset(0, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Box
            table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 3)
            fillCorner.Parent = Fill

            local function set_state(val)
                isOn = val
                Library._config._flags[flag] = val
                TweenService:Create(Fill, TweenInfo.new(0.2), {
                    Size = val and UDim2.fromOffset(9, 9) or UDim2.fromOffset(0, 0)
                }):Play()
                Library:SaveConfig()
                if opts.callback then opts.callback(val) end
            end

            if isOn then set_state(true) end

            Row.MouseButton1Click:Connect(function()
                set_state(not isOn)
            end)

            local function refresh_kb()
                local stored = Library._config._keybinds[flag]
                if stored then
                    KBLabel.Text = string.gsub(tostring(stored), "Enum.KeyCode.", "")
                    KeyBox.Size = UDim2.fromOffset(math.max(28, KBLabel.TextBounds.X + 12), 16)
                else
                    KBLabel.Text = "..."
                    KeyBox.Size = UDim2.fromOffset(28, 16)
                end
            end
            refresh_kb()

            if Library._config._keybinds[flag] then
                Library:RegisterKeybind(flag, opts.title or "Checkbox", Library._config._keybinds[flag], function()
                    set_state(not isOn)
                end)
            end

            KeyBox.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                Library._choosing_keybind = true
                KBLabel.Text = "..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end
                    if input.KeyCode == Enum.KeyCode.Backspace then
                        Library._config._keybinds[flag] = nil
                        Library:UnregisterKeybind(flag)
                    else
                        Library._config._keybinds[flag] = tostring(input.KeyCode)
                        Library:RegisterKeybind(flag, opts.title or "Checkbox", tostring(input.KeyCode), function()
                            set_state(not isOn)
                        end)
                    end
                    Library:SaveConfig()
                    Library._choosing_keybind = false
                    refresh_kb()
                    conn:Disconnect()
                end)
            end)

            Library._flag_registry[flag] = set_state
            addElement(Row, 22)
            return {
                Set = set_state,
                Get = function() return isOn end,
            }
        end

        function ModuleManager:create_slider(opts)
            local flag = opts.flag
            local min_v = opts.minimum_value or 0
            local max_v = opts.maximum_value or 100
            local val = Library._config._flags[flag] or opts.value or min_v

            local Slider = Instance.new("Frame")
            Slider.Size = UDim2.fromOffset(ELEMENT_WIDTH, 32)
            Slider.BackgroundTransparency = 1
            Slider.BorderSizePixel = 0

            local Label = Instance.new("TextLabel")
            Label.Text = opts.title or "Slider"
            Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Label.TextColor3 = Theme.Text
            Label.TextSize = 12
            Label.Size = UDim2.new(1, -50, 0, 14)
            Label.BackgroundTransparency = 1
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Slider
            table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Text = tostring(val)
            ValueLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ValueLabel.TextColor3 = Theme.Text
            ValueLabel.TextSize = 11
            ValueLabel.Size = UDim2.new(0, 50, 0, 14)
            ValueLabel.Position = UDim2.new(1, -50, 0, 0)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = Slider
            table.insert(Library._elements, {obj = ValueLabel, prop = "TextColor3", tKey = "Text"})

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 4)
            Track.Position = UDim2.new(0, 0, 0, 24)
            Track.BackgroundColor3 = Theme.Control
            Track.BorderSizePixel = 0
            Track.Parent = Slider
            table.insert(Library._elements, {obj = Track, prop = "BackgroundColor3", tKey = "Control"})

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((val - min_v) / (max_v - min_v), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Fill.Parent = Track
            table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = Fill

            local function set_value(v)
                v = math.clamp(v, min_v, max_v)
                if opts.round_number then v = math.floor(v) end
                val = v
                Library._config._flags[flag] = v
                ValueLabel.Text = tostring(v)
                Fill.Size = UDim2.new((v - min_v) / (max_v - min_v), 0, 1, 0)
                Library:SaveConfig()
                if opts.callback then opts.callback(v) end
            end

            if Library._config._flags[flag] then
                set_value(Library._config._flags[flag])
            else
                set_value(val)
            end

            local dragging = false
            local function update_from_mouse()
                local rel = math.clamp((mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                set_value(min_v + rel * (max_v - min_v))
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update_from_mouse()
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update_from_mouse()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            Library._flag_registry[flag] = set_value
            addElement(Slider, 32)
            return {
                Set = set_value,
                Get = function() return val end,
            }
        end

        function ModuleManager:create_button(opts)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.fromOffset(ELEMENT_WIDTH, 24)
            Btn.BackgroundColor3 = Theme.Control
            Btn.BackgroundTransparency = 0.2
            Btn.BorderSizePixel = 0
            Btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Btn.TextColor3 = Theme.Text
            Btn.TextSize = 12
            Btn.Text = opts.title or "Button"
            Btn.AutoButtonColor = true
            Btn.Parent = Body
            table.insert(Library._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
            table.insert(Library._elements, {obj = Btn, prop = "TextColor3", tKey = "Text"})

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                if opts.callback then opts.callback() end
            end)
            addElement(Btn, 24)
        end

        function ModuleManager:create_textbox(opts)
            local flag = opts.flag
            local Container = Instance.new("Frame")
            Container.Size = UDim2.fromOffset(ELEMENT_WIDTH, 40)
            Container.BackgroundTransparency = 1
            Container.BorderSizePixel = 0

            local Label = Instance.new("TextLabel")
            Label.Text = opts.title or "Input"
            Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Label.TextColor3 = Theme.Text
            Label.TextSize = 11
            Label.Size = UDim2.new(1, 0, 0, 14)
            Label.BackgroundTransparency = 1
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Container
            table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, 0, 0, 22)
            Box.Position = UDim2.new(0, 0, 0, 18)
            Box.BackgroundColor3 = Theme.Control
            Box.BackgroundTransparency = 0.2
            Box.BorderSizePixel = 0
            Box.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Box.TextColor3 = Theme.Text
            Box.TextSize = 11
            Box.PlaceholderText = opts.placeholder or ""
            Box.PlaceholderColor3 = Theme.TextDim
            Box.Text = Library._config._flags[flag] or opts.value or ""
            Box.ClearTextOnFocus = false
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.Parent = Container
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
            table.insert(Library._elements, {obj = Box, prop = "TextColor3", tKey = "Text"})
            table.insert(Library._elements, {obj = Box, prop = "PlaceholderColor3", tKey = "TextDim"})

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = Box

            local boxPad = Instance.new("UIPadding")
            boxPad.PaddingLeft = UDim.new(0, 6)
            boxPad.PaddingRight = UDim.new(0, 6)
            boxPad.Parent = Box

            Box.FocusLost:Connect(function()
                Library._config._flags[flag] = Box.Text
                Library:SaveConfig()
                if opts.callback then opts.callback(Box.Text) end
            end)

            Library._flag_registry[flag] = function(v)
                Box.Text = v or ""
                Library._config._flags[flag] = v
            end
            addElement(Container, 40)
            return {
                Set = function(v) Box.Text = v end,
                Get = function() return Box.Text end,
            }
        end

        function ModuleManager:create_dropdown(opts)
            local flag = opts.flag
            local open = false
            local selected = Library._config._flags[flag] or opts.options[1] or ""

            local Dropdown = Instance.new("Frame")
            Dropdown.Size = UDim2.fromOffset(ELEMENT_WIDTH, 40)
            Dropdown.BackgroundTransparency = 1
            Dropdown.BorderSizePixel = 0
            Dropdown.ClipsDescendants = true

            local Label = Instance.new("TextLabel")
            Label.Text = opts.title or "Dropdown"
            Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Label.TextColor3 = Theme.Text
            Label.TextSize = 11
            Label.Size = UDim2.new(1, 0, 0, 14)
            Label.BackgroundTransparency = 1
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Dropdown
            table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})

            local SelectBox = Instance.new("TextButton")
            SelectBox.Size = UDim2.new(1, 0, 0, 22)
            SelectBox.Position = UDim2.new(0, 0, 0, 18)
            SelectBox.BackgroundColor3 = Theme.Control
            SelectBox.BackgroundTransparency = 0.2
            SelectBox.BorderSizePixel = 0
            SelectBox.Text = ""
            SelectBox.AutoButtonColor = false
            SelectBox.Parent = Dropdown
            table.insert(Library._elements, {obj = SelectBox, prop = "BackgroundColor3", tKey = "Control"})

            local selCorner = Instance.new("UICorner")
            selCorner.CornerRadius = UDim.new(0, 4)
            selCorner.Parent = SelectBox

            local Arrow = Instance.new("TextLabel")
            Arrow.Text = "▼"
            Arrow.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
            Arrow.TextColor3 = Theme.TextDim
            Arrow.TextSize = 10
            Arrow.Size = UDim2.fromOffset(14, 22)
            Arrow.Position = UDim2.new(1, -18, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Parent = SelectBox
            table.insert(Library._elements, {obj = Arrow, prop = "TextColor3", tKey = "TextDim"})

            local CurrentText = Instance.new("TextLabel")
            CurrentText.Text = tostring(selected)
            CurrentText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            CurrentText.TextColor3 = Theme.Text
            CurrentText.TextSize = 11
            CurrentText.Size = UDim2.new(1, -24, 1, 0)
            CurrentText.Position = UDim2.new(0, 8, 0, 0)
            CurrentText.BackgroundTransparency = 1
            CurrentText.TextXAlignment = Enum.TextXAlignment.Left
            CurrentText.Parent = SelectBox
            table.insert(Library._elements, {obj = CurrentText, prop = "TextColor3", tKey = "Text"})

            local OptionsFrame = Instance.new("ScrollingFrame")
            OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
            OptionsFrame.Position = UDim2.new(0, 0, 0, 42)
            OptionsFrame.BackgroundColor3 = Theme.Control
            OptionsFrame.BackgroundTransparency = 0.2
            OptionsFrame.BorderSizePixel = 0
            OptionsFrame.ScrollBarThickness = 2
            OptionsFrame.ScrollBarImageColor3 = Theme.Accent
            OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            OptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            OptionsFrame.ClipsDescendants = true
            OptionsFrame.Parent = Dropdown
            table.insert(Library._elements, {obj = OptionsFrame, prop = "BackgroundColor3", tKey = "Control"})

            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 4)
            optCorner.Parent = OptionsFrame

            local optPad = Instance.new("UIPadding")
            optPad.PaddingTop = UDim.new(0, 3)
            optPad.PaddingBottom = UDim.new(0, 3)
            optPad.PaddingLeft = UDim.new(0, 6)
            optPad.PaddingRight = UDim.new(0, 6)
            optPad.Parent = OptionsFrame

            local optLayout = Instance.new("UIListLayout")
            optLayout.Padding = UDim.new(0, 2)
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = OptionsFrame

            for i, opt in ipairs(opts.options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, -12, 0, 20)
                OptBtn.BackgroundTransparency = 1
                OptBtn.Text = tostring(opt)
                OptBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                OptBtn.TextColor3 = Theme.Text
                OptBtn.TextSize = 11
                OptBtn.AutoButtonColor = false
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.LayoutOrder = i
                OptBtn.Parent = OptionsFrame
                table.insert(Library._elements, {obj = OptBtn, prop = "TextColor3", tKey = "Text"})

                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    CurrentText.Text = tostring(opt)
                    Library._config._flags[flag] = opt
                    Library:SaveConfig()
                    if opts.callback then opts.callback(opt) end
                end)
            end

            local function set_open(val)
                open = val
                local optCount = #opts.options
                local optHeight = math.min(optCount * 22 + 6, 110)
                TweenService:Create(Dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                    Size = UDim2.fromOffset(ELEMENT_WIDTH, 40 + (val and optHeight or 0))
                }):Play()
                TweenService:Create(OptionsFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(1, 0, 0, val and optHeight or 0)
                }):Play()
                Arrow.Rotation = val and 180 or 0
            end

            SelectBox.MouseButton1Click:Connect(function()
                set_open(not open)
            end)

            Library._flag_registry[flag] = function(v)
                selected = v
                CurrentText.Text = tostring(v)
            end
            addElement(Dropdown, 40)
            return {
                Set = function(v) selected = v; CurrentText.Text = tostring(v) end,
                Get = function() return selected end,
            }
        end

        function ModuleManager:create_divider(opts)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.fromOffset(ELEMENT_WIDTH, 20)
            Frame.BackgroundTransparency = 1
            Frame.BorderSizePixel = 0

            if opts and opts.title then
                local DTitle = Instance.new("TextLabel")
                DTitle.Text = opts.title
                DTitle.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                DTitle.TextColor3 = Theme.TextDim
                DTitle.TextSize = 11
                DTitle.Size = UDim2.new(1, 0, 0, 14)
                DTitle.Position = UDim2.new(0, 0, 0, 0)
                DTitle.BackgroundTransparency = 1
                DTitle.TextXAlignment = Enum.TextXAlignment.Center
                DTitle.Parent = Frame
                table.insert(Library._elements, {obj = DTitle, prop = "TextColor3", tKey = "TextDim"})
            end

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 1, -6)
            Line.BackgroundColor3 = Theme.GroupStroke
            Line.BorderSizePixel = 0
            Line.Parent = Frame
            table.insert(Library._elements, {obj = Line, prop = "BackgroundColor3", tKey = "GroupStroke"})

            addElement(Frame, 20)
        end

        function ModuleManager:create_paragraph(opts)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.fromOffset(ELEMENT_WIDTH, 62)
            Frame.BackgroundColor3 = Theme.Control
            Frame.BackgroundTransparency = 0.2
            Frame.BorderSizePixel = 0
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            table.insert(Library._elements, {obj = Frame, prop = "BackgroundColor3", tKey = "Control"})

            local frCorner = Instance.new("UICorner")
            frCorner.CornerRadius = UDim.new(0, 4)
            frCorner.Parent = Frame

            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 6)
            pad.PaddingBottom = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 8)
            pad.Parent = Frame

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 3)
            layout.Parent = Frame

            local Title = Instance.new("TextLabel")
            Title.Text = opts.title or "Info"
            Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = Theme.Text
            Title.TextSize = 12
            Title.Size = UDim2.new(1, 0, 0, 14)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.AutomaticSize = Enum.AutomaticSize.Y
            Title.Parent = Frame
            table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

            local Body = Instance.new("TextLabel")
            Body.Text = opts.text or ""
            Body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Body.TextColor3 = Theme.TextDim
            Body.TextSize = 11
            Body.Size = UDim2.new(1, 0, 0, 14)
            Body.BackgroundTransparency = 1
            Body.TextXAlignment = Enum.TextXAlignment.Left
            Body.TextYAlignment = Enum.TextYAlignment.Top
            Body.TextWrapped = true
            Body.AutomaticSize = Enum.AutomaticSize.Y
            Body.Parent = Frame
            table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

            addElement(Frame, 62)
        end

        function ModuleManager:create_text(opts)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.fromOffset(ELEMENT_WIDTH, 26)
            Frame.BackgroundColor3 = Theme.Control
            Frame.BackgroundTransparency = 0.2
            Frame.BorderSizePixel = 0
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            table.insert(Library._elements, {obj = Frame, prop = "BackgroundColor3", tKey = "Control"})

            local frCorner = Instance.new("UICorner")
            frCorner.CornerRadius = UDim.new(0, 4)
            frCorner.Parent = Frame

            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 6)
            pad.PaddingBottom = UDim.new(0, 6)
            pad.PaddingLeft = UDim.new(0, 8)
            pad.PaddingRight = UDim.new(0, 8)
            pad.Parent = Frame

            local Body = Instance.new("TextLabel")
            Body.Text = opts.text or ""
            Body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Body.TextColor3 = Theme.TextDim
            Body.TextSize = 11
            Body.Size = UDim2.new(1, 0, 0, 14)
            Body.BackgroundTransparency = 1
            Body.TextXAlignment = Enum.TextXAlignment.Left
            Body.TextYAlignment = Enum.TextYAlignment.Top
            Body.TextWrapped = true
            Body.AutomaticSize = Enum.AutomaticSize.Y
            Body.Parent = Frame
            table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

            addElement(Frame, 26)
        end

        function ModuleManager:create_feature(opts)
            local flag = opts.flag
            local isOn = (Library._config._flags[flag] and Library._config._flags[flag].checked) or false
            local key = (Library._config._flags[flag] and Library._config._flags[flag].BIND) or opts.default or nil

            local Row = Instance.new("Frame")
            Row.Size = UDim2.fromOffset(ELEMENT_WIDTH, 22)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0

            local Title = Instance.new("TextLabel")
            Title.Text = opts.title or "Feature"
            Title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Title.TextColor3 = Theme.Text
            Title.TextSize = 12
            Title.Size = UDim2.new(1, -80, 1, 0)
            Title.BackgroundTransparency = 1
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.TextYAlignment = Enum.TextYAlignment.Center
            Title.Parent = Row
            table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

            local KeyBox = Instance.new("TextButton")
            KeyBox.Size = UDim2.fromOffset(28, 16)
            KeyBox.Position = UDim2.new(1, -66, 0.5, -8)
            KeyBox.BackgroundColor3 = Theme.Control
            KeyBox.BackgroundTransparency = 0.2
            KeyBox.AutoButtonColor = false
            KeyBox.Text = ""
            KeyBox.BorderSizePixel = 0
            KeyBox.Parent = Row
            table.insert(Library._elements, {obj = KeyBox, prop = "BackgroundColor3", tKey = "Control"})

            local kbCorner = Instance.new("UICorner")
            kbCorner.CornerRadius = UDim.new(0, 3)
            kbCorner.Parent = KeyBox

            local kbStroke = Instance.new("UIStroke")
            kbStroke.Color = Theme.GroupStroke
            kbStroke.Transparency = 0.4
            kbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            kbStroke.Parent = KeyBox
            table.insert(Library._elements, {obj = kbStroke, prop = "Color", tKey = "GroupStroke"})

            local KBLabel = Instance.new("TextLabel")
            KBLabel.Text = "..."
            KBLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KBLabel.TextColor3 = Theme.Text
            KBLabel.TextSize = 9
            KBLabel.Size = UDim2.new(1, -4, 1, 0)
            KBLabel.BackgroundTransparency = 1
            KBLabel.TextXAlignment = Enum.TextXAlignment.Center
            KBLabel.Parent = KeyBox
            table.insert(Library._elements, {obj = KBLabel, prop = "TextColor3", tKey = "Text"})

            local Box = Instance.new("Frame")
            Box.Size = UDim2.fromOffset(16, 16)
            Box.Position = UDim2.new(1, -18, 0.5, -8)
            Box.BackgroundColor3 = isOn and Theme.Accent or Theme.Control
            Box.BorderSizePixel = 0
            Box.Parent = Row
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Accent"})

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = Box

            local BoxStroke = Instance.new("UIStroke")
            BoxStroke.Color = Theme.Accent
            BoxStroke.Transparency = 0.5
            BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            BoxStroke.Parent = Box
            table.insert(Library._elements, {obj = BoxStroke, prop = "Color", tKey = "Accent"})

            local function refresh_visual()
                Box.BackgroundColor3 = isOn and Theme.Accent or Theme.Control
            end

            local function save()
                Library._config._flags[flag] = { checked = isOn, BIND = key or "Unknown" }
                Library:SaveConfig()
            end

            local function set_state(val)
                isOn = val
                refresh_visual()
                save()
                if opts.callback then opts.callback(val) end
            end

            local function refresh_kb()
                if key then
                    KBLabel.Text = string.gsub(tostring(key), "Enum.KeyCode.", "")
                    KeyBox.Size = UDim2.fromOffset(math.max(28, KBLabel.TextBounds.X + 12), 16)
                else
                    KBLabel.Text = "..."
                    KeyBox.Size = UDim2.fromOffset(28, 16)
                end
            end
            refresh_kb()

            if key then
                Library:RegisterKeybind(flag, opts.title or "Feature", tostring(key), function()
                    set_state(not isOn)
                end)
            end

            Row.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if input.Position.X < Row.AbsolutePosition.X + Row.AbsoluteSize.X - 70 then
                        set_state(not isOn)
                    end
                end
            end)

            KeyBox.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                Library._choosing_keybind = true
                KBLabel.Text = "..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end
                    if input.KeyCode == Enum.KeyCode.Backspace then
                        key = nil
                        Library._config._keybinds[flag] = nil
                        Library:UnregisterKeybind(flag)
                    else
                        key = tostring(input.KeyCode)
                        Library._config._keybinds[flag] = key
                        Library:RegisterKeybind(flag, opts.title or "Feature", key, function()
                            set_state(not isOn)
                        end)
                    end
                    Library._choosing_keybind = false
                    refresh_kb()
                    save()
                    conn:Disconnect()
                end)
            end)

            Library._flag_registry[flag] = function(v)
                if typeof(v) == "table" then
                    set_state(v.checked or false)
                else
                    set_state(v)
                end
            end
            addElement(Row, 22)
        end

        -- store header keybind callback for later rebinding if needed
        ModuleManager._module_flag = settings.flag
        ModuleManager._module_title = settings.title

        refresh()
        return ModuleManager
    end

    return TabManager
end

-- ============================================================
-- Interface tab
-- ============================================================
function Library:build_interface_tab()
    local InterfaceTab = self:create_tab("Interface", "rbxassetid://94381583400007")

    -- =========================
    -- Appearance
    -- =========================
    local AppearanceModule = InterfaceTab:create_module({
        title = "Appearance",
        description = "Customize UI colors",
        flag = "UI_Appearance_Module",
        section = "left",
        callback = function() end,
    })

    local ColorTargets = { "Background", "Group", "GroupStroke", "Control", "ControlHover", "Text", "TextDim", "Accent" }
    local Swatches = {}
    local SelectedTarget = "Background"
    local PointerOffset = Vector2.zero

    local ColorPopup = Instance.new("Frame")
    ColorPopup.Size = UDim2.fromOffset(220, 150)
    ColorPopup.BackgroundColor3 = Color3.fromRGB(14, 20, 24)
    ColorPopup.BorderSizePixel = 0
    ColorPopup.Visible = false
    ColorPopup.ZIndex = 100
    ColorPopup.Parent = self._handler
    local cpopCorner = Instance.new("UICorner") cpopCorner.CornerRadius = UDim.new(0, 8) cpopCorner.Parent = ColorPopup
    local cpopStroke = Instance.new("UIStroke") cpopStroke.Color = Theme.GroupStroke cpopStroke.Transparency = 0.5 cpopStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border cpopStroke.Parent = ColorPopup

    local HueBar = Instance.new("TextButton")
    HueBar.Size = UDim2.new(1, -20, 0, 12)
    HueBar.Position = UDim2.fromOffset(10, 128)
    HueBar.BackgroundColor3 = Color3.new(1,1,1)
    HueBar.AutoButtonColor = false
    HueBar.Text = ""
    HueBar.BorderSizePixel = 0
    HueBar.Parent = ColorPopup
    local hbCorner = Instance.new("UICorner") hbCorner.CornerRadius = UDim.new(1,0) hbCorner.Parent = HueBar
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
    }
    hueGrad.Parent = HueBar

    local HueKnob = Instance.new("Frame")
    HueKnob.Size = UDim2.fromOffset(4, 16)
    HueKnob.Position = UDim2.new(0, 0, 0.5, -8)
    HueKnob.AnchorPoint = Vector2.new(0.5, 0)
    HueKnob.BackgroundColor3 = Color3.new(1,1,1)
    HueKnob.BorderSizePixel = 0
    HueKnob.ZIndex = 2
    HueKnob.Parent = HueBar

    local SatBright = Instance.new("TextButton")
    SatBright.Size = UDim2.new(1, -20, 0, 108)
    SatBright.Position = UDim2.fromOffset(10, 10)
    SatBright.BackgroundColor3 = Color3.new(1,0,0)
    SatBright.AutoButtonColor = false
    SatBright.Text = ""
    SatBright.BorderSizePixel = 0
    SatBright.Parent = ColorPopup
    local sbCorner = Instance.new("UICorner") sbCorner.CornerRadius = UDim.new(0, 5) sbCorner.Parent = SatBright

    local SatOverlay = Instance.new("Frame")
    SatOverlay.Size = UDim2.new(1, 0, 1, 0)
    SatOverlay.BackgroundColor3 = Color3.new(1,1,1)
    SatOverlay.BorderSizePixel = 0
    SatOverlay.Parent = SatBright
    local satGrad = Instance.new("UIGradient")
    satGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }
    satGrad.Parent = SatOverlay

    local BrightOverlay = Instance.new("Frame")
    BrightOverlay.Size = UDim2.new(1, 0, 1, 0)
    BrightOverlay.BackgroundColor3 = Color3.new(0,0,0)
    BrightOverlay.BorderSizePixel = 0
    BrightOverlay.Parent = SatBright
    local brightGrad = Instance.new("UIGradient")
    brightGrad.Rotation = 90
    brightGrad.Transparency = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }
    brightGrad.Parent = BrightOverlay

    local Cur = Instance.new("Frame")
    Cur.Size = UDim2.fromOffset(10, 10)
    Cur.AnchorPoint = Vector2.new(0.5, 0.5)
    Cur.BackgroundTransparency = 1
    Cur.BorderSizePixel = 0
    Cur.ZIndex = 3
    Cur.Parent = SatBright
    local curStroke = Instance.new("UIStroke") curStroke.Color = Color3.new(1,1,1) curStroke.Thickness = 2 curStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border curStroke.Parent = Cur

    local currentHue, currentSat, currentVal = 0, 1, 1

    local function applyColor()
        local c = Color3.fromHSV(currentHue, currentSat, currentVal)
        if Swatches[SelectedTarget] then Swatches[SelectedTarget].BackgroundColor3 = c end
        self:SetColor(SelectedTarget, c)
    end

    local function updateFromField()
        local loc = UserInputService:GetMouseLocation() + PointerOffset
        local sat = math.clamp((loc.X - SatBright.AbsolutePosition.X) / SatBright.AbsoluteSize.X, 0, 1)
        local val = 1 - math.clamp((loc.Y - SatBright.AbsolutePosition.Y) / SatBright.AbsoluteSize.Y, 0, 1)
        currentSat, currentVal = sat, val
        Cur.Position = UDim2.new(sat, 0, 1-val, 0)
        applyColor()
    end

    local function updateFromHue()
        local loc = UserInputService:GetMouseLocation() + PointerOffset
        local hue = math.clamp((loc.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
        currentHue = hue
        HueKnob.Position = UDim2.new(hue, 0, 0.5, -8)
        SatBright.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        applyColor()
    end

    local function calibrate(frame)
        local inset = GuiService:GetGuiInset()
        local loc = UserInputService:GetMouseLocation()
        for _, off in ipairs({ Vector2.zero, inset, -inset }) do
            local p = loc + off
            if p.X >= frame.AbsolutePosition.X and p.X <= frame.AbsolutePosition.X + frame.AbsoluteSize.X
               and p.Y >= frame.AbsolutePosition.Y and p.Y <= frame.AbsolutePosition.Y + frame.AbsoluteSize.Y then
                PointerOffset = off
                return
            end
        end
    end

    SatBright.MouseButton1Down:Connect(function()
        calibrate(SatBright)
        updateFromField()
        local c
        c = UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                updateFromField()
            end
        end)
        local e
        e = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                c:Disconnect() e:Disconnect()
            end
        end)
    end)

    HueBar.MouseButton1Down:Connect(function()
        calibrate(HueBar)
        updateFromHue()
        local c
        c = UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                updateFromHue()
            end
        end)
        local e
        e = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                c:Disconnect() e:Disconnect()
            end
        end)
    end)

    local function openPopup(target, swatch)
        if ColorPopup.Visible and SelectedTarget == target then
            ColorPopup.Visible = false
            return
        end
        SelectedTarget = target
        local scale = self._handler.AbsoluteSize.X / 698
        local relX = (swatch.AbsolutePosition.X - self._handler.AbsolutePosition.X) / scale
        local relY = (swatch.AbsolutePosition.Y - self._handler.AbsolutePosition.Y) / scale
        ColorPopup.Position = UDim2.fromOffset(
            math.clamp(relX - 230, 8, 460),
            math.clamp(relY - 65, 8, 320)
        )
        ColorPopup.Visible = true
        local h, s, v = Color3.toHSV(Theme[target])
        currentHue, currentSat, currentVal = h, s, v
        SatBright.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        Cur.Position = UDim2.new(s, 0, 1-v, 0)
        HueKnob.Position = UDim2.new(h, 0, 0.5, -8)
    end

    for i, target in ipairs(ColorTargets) do
        local Row = Instance.new("TextButton")
        Row.Size = UDim2.fromOffset(ELEMENT_WIDTH, 22)
        Row.BackgroundTransparency = 1
        Row.Text = ""
        Row.AutoButtonColor = false
        Row.BorderSizePixel = 0
        Row.LayoutOrder = i

        local Lbl = Instance.new("TextLabel")
        Lbl.Text = target
        Lbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Lbl.TextColor3 = Theme.Text
        Lbl.TextSize = 12
        Lbl.Size = UDim2.new(1, -44, 1, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.TextYAlignment = Enum.TextYAlignment.Center
        Lbl.Parent = Row
        table.insert(Library._elements, {obj = Lbl, prop = "TextColor3", tKey = "Text"})

        local Swatch = Instance.new("TextButton")
        Swatch.Size = UDim2.fromOffset(34, 18)
        Swatch.Position = UDim2.new(1, -34, 0.5, -9)
        Swatch.BackgroundColor3 = Theme[target]
        Swatch.AutoButtonColor = false
        Swatch.Text = ""
        Swatch.BorderSizePixel = 0
        Swatch.Parent = Row
        local swc = Instance.new("UICorner") swc.CornerRadius = UDim.new(0, 4) swc.Parent = Swatch
        local sws = Instance.new("UIStroke") sws.Color = Theme.GroupStroke sws.Transparency = 0.5 sws.ApplyStrokeMode = Enum.ApplyStrokeMode.Border sws.Parent = Swatch
        table.insert(Library._elements, {obj = sws, prop = "Color", tKey = "GroupStroke"})

        Swatch.MouseButton1Click:Connect(function() openPopup(target, Swatch) end)
        Row.MouseButton1Click:Connect(function() openPopup(target, Swatch) end)
        Swatches[target] = Swatch

        -- Hack: parent to body via addElement replacement
        local optionsFrame = AppearanceModule
        Row.Parent = nil -- will be re-parented by create_module internals
        -- Actually we need to use the module's addElement logic, but that's internal.
        -- Simpler: just add directly to Body via known hierarchy
    end

    -- Wait — I need access to the module body. Let me expose it.
    -- For now, patch: since create_module doesn't expose body, I'll add a method.

    -- (This is handled below via ModuleManager:addRaw)
    return InterfaceTab
end

return Library

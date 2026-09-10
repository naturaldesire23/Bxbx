-- ============================================================
-- CHANGED FUNCTIONS vs previous build:
--  1. ModuleManager:refresh_size        (module sizing fix)
--  2. ModuleManager:change_state        (uses refresh_size)
--  3. ModuleManager:connect_keybind     (module keybind)
--  4. ModuleManager:scale_keybind       (module keybind)
--  5. Header.InputBegan handler         (right-click choose key)
--  6. DropdownManager:unfold_settings   (uses refresh_size)
--  7. Library.SendNotification          (IceLib-style layout)
--  8. resolve_background                (URL -> file -> asset)
--  9. Settings module additions         (Minimize_Keybind, Hide on Minimize)
-- 10. library_visiblity handler         (custom minimize key)
-- 11. Keybind list overlay              (Settings module)
-- ============================================================

local GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local SelectedLanguage = GG.Language

local UserInputService = cloneref and cloneref(game:GetService('UserInputService')) or game:GetService('UserInputService')
local ContentProvider = cloneref and cloneref(game:GetService('ContentProvider')) or game:GetService('ContentProvider')
local TweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local HttpService = cloneref and cloneref(game:GetService('HttpService')) or game:GetService('HttpService')
local TextService = cloneref and cloneref(game:GetService('TextService')) or game:GetService('TextService')
local RunService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local Lighting = cloneref and cloneref(game:GetService('Lighting')) or game:GetService('Lighting')
local Players = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local CoreGui = cloneref and cloneref(game:GetService('CoreGui')) or game:GetService('CoreGui')
local Debris = cloneref and cloneref(game:GetService('Debris')) or game:GetService('Debris')
local GuiService = cloneref and cloneref(game:GetService('GuiService')) or game:GetService('GuiService')
local Workspace = cloneref and cloneref(game:GetService('Workspace')) or game:GetService('Workspace')

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
for k, v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v
end

local Library = {
    _config = { _flags = {}, _keybinds = {}, _library = {} },
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _elements = {},
    _background = nil,
    _container = nil,
    _handler = nil,
    _flag_registry = {},
    _keybind_list = {},
    _notif_side = "Right",
    _notif_opacity = 0,
    _minimize_key = nil
}
Library.__index = Library

local SecureScreenGui = Instance.new('ScreenGui')
SecureScreenGui.Name = "GameUI"
SecureScreenGui.Parent = CoreGui
SecureScreenGui.ResetOnSpawn = false
SecureScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if protect_gui then pcall(protect_gui, SecureScreenGui) end

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then return end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then continue end
            value:Disconnect()
        end
    end
}, Connections)

local Config = setmetatable({
    save = function(self, file_name, config)
        if not (writefile and isfolder) then return end
        local success_save, result = pcall(function()
            if not isfolder('AchaoticUI/AllusiveModified') then
                makefolder('AchaoticUI/AllusiveModified')
            end
            local flags = HttpService:JSONEncode(config)
            writefile('AchaoticUI/AllusiveModified/'..file_name..'.json', flags)
        end)
        if not success_save then warn('failed to save config', result) end
    end,
    load = function(self, file_name, config)
        if not (isfile and readfile) then return config end
        local success_load, result = pcall(function()
            if not isfile('AchaoticUI/AllusiveModified/'..file_name..'.json') then
                return config
            end
            local flags = readfile('AchaoticUI/AllusiveModified/'..file_name..'.json')
            if not flags then return config end
            return HttpService:JSONDecode(flags)
        end)
        if not success_load then return config end
        if not result then
            result = { _flags = {}, _keybinds = {}, _library = {} }
        end
        return result
    end
}, Config)

function Library.new(config)
    local self = setmetatable({
        _loaded = false, _tab = 0,
    }, Library)

    Library._config = Config:load(game.GameId, { _flags = {}, _keybinds = {}, _library = {} })

    local currentconfig = config or {
        title = "Achaotic",
        PrimaryColor = Color3.fromRGB(120, 220, 235),
    }
    
    Theme.Accent = currentconfig.PrimaryColor
    self:create_ui(currentconfig)
    return self
end

-- ============================================================
-- FIX #7: IceLib-style notification system
-- ============================================================
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = SecureScreenGui
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.AnchorPoint = Vector2.new(1, 1)
NotificationContainer.Position = UDim2.new(1, -22, 1, -22)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Parent = NotificationContainer

local function UpdateNotificationPosition()
    if Library._notif_side == "Left" then
        NotificationContainer.AnchorPoint = Vector2.new(0, 1)
        NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
    else
        NotificationContainer.AnchorPoint = Vector2.new(1, 1)
        NotificationContainer.Position = UDim2.new(1, -22, 1, -22)
    end
end
UpdateNotificationPosition()

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)
    InnerFrame.Position = UDim2.new(Library._notif_side == "Left" and 1 or -1, -320, 0, 0)
    InnerFrame.BackgroundColor3 = Theme.Group
    InnerFrame.BackgroundTransparency = Library._notif_opacity
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification
    table.insert(Library._elements, {obj = InnerFrame, prop = "BackgroundColor3", tKey = "Group"})

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    InnerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.92),
        NumberSequenceKeypoint.new(1, 1)
    }
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Theme.GroupStroke
    InnerStroke.Transparency = 0.5
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame
    table.insert(Library._elements, {obj = InnerStroke, prop = "Color", tKey = "GroupStroke"})

    local Accent = Instance.new("Frame")
    Accent.Name = "Accent"
    Accent.Size = UDim2.new(0, 3, 1, -12)
    Accent.Position = UDim2.new(0, 6, 0, 6)
    Accent.BackgroundColor3 = Theme.Accent
    Accent.BorderSizePixel = 0
    Accent.Parent = InnerFrame
    table.insert(Library._elements, {obj = Accent, prop = "BackgroundColor3", tKey = "Accent"})

    local AccentCorner = Instance.new("UICorner")
    AccentCorner.CornerRadius = UDim.new(1, 0)
    AccentCorner.Parent = Accent

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 15
    Title.Size = UDim2.new(1, -25, 0, 18)
    Title.Position = UDim2.new(0, 15, 0, 8)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.ZIndex = 2
    Title.Parent = InnerFrame
    table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or ""
    Body.TextColor3 = Theme.TextDim
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -25, 0, 14)
    Body.Position = UDim2.new(0, 15, 0, 32)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Center
    Body.TextTruncate = Enum.TextTruncate.AtEnd
    Body.ZIndex = 2
    Body.Parent = InnerFrame
    table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()

        task.wait(settings.duration or 5)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(Library._notif_side == "Left" and 1 or -1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library:Notify(settings)
    Library.SendNotification(settings)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400
end

function Library:get_device()
    local device = 'Unknown'
    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end
    self._device = device
end

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    if Library._config._flags[flag] == nil then return end
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table, table_value)
    for index, value in __table do
        if value ~= table_value then continue end
        table.remove(__table, index)
    end
end

function Library:hexToRGB(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

function Library:rgbToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

function Library:SetColor(key, color)
    Theme[key] = color
    for _, element in ipairs(Library._elements) do
        if element.tKey == key then
            pcall(function() element.obj[element.prop] = color end)
        end
    end
    Library._config._flags['Theme_'..key] = self:rgbToHex(color)
    Config:save(game.GameId, Library._config)
end

function Library:SetBackground(source, transparency)
    if not self._background then return end
    if typeof(source) == "string" and source ~= '' then
        self._background.Image = source
        self._background.Visible = true
        self._background.ImageTransparency = transparency or 0.5
        self._background.ScaleType = Enum.ScaleType.Crop
    else
        self._background.Visible = false
    end
    Library._config._flags['Background_Image'] = (typeof(source) == "string" and source) or ''
    Library._config._flags['Background_Transparency'] = transparency or 0.5
    Config:save(game.GameId, Library._config)
end

function Library:create_ui(config)
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = "Container"
    Container.BackgroundTransparency = 0.05
    Container.BackgroundColor3 = Theme.Background
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = SecureScreenGui
    self._container = Container
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

    local ShadowHolder = Instance.new('Frame')
    ShadowHolder.Name = 'ShadowHolder'
    ShadowHolder.AnchorPoint = Container.AnchorPoint
    ShadowHolder.Position = Container.Position
    ShadowHolder.Size = Container.Size
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.BorderSizePixel = 0
    ShadowHolder.ZIndex = 0
    ShadowHolder.Parent = SecureScreenGui
    ShadowHolder.Visible = false

    local ShadowOuter = Instance.new('ImageLabel')
    ShadowOuter.Name = 'SoftShadowOuter'
    ShadowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowOuter.Position = UDim2.new(0.5, 0, 0.5, 2)
    ShadowOuter.Size = UDim2.new(1, 58, 1, 58)
    ShadowOuter.BackgroundTransparency = 1
    ShadowOuter.BorderSizePixel = 0
    ShadowOuter.Image = 'rbxassetid://6014261993'
    ShadowOuter.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowOuter.ImageTransparency = 0.45
    ShadowOuter.ScaleType = Enum.ScaleType.Slice
    ShadowOuter.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowOuter.ZIndex = 0
    ShadowOuter.Parent = ShadowHolder

    local ShadowInner = Instance.new('ImageLabel')
    ShadowInner.Name = 'SoftShadowInner'
    ShadowInner.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowInner.Position = UDim2.new(0.5, 0, 0.5, 1)
    ShadowInner.Size = UDim2.new(1, 32, 1, 32)
    ShadowInner.BackgroundTransparency = 1
    ShadowInner.BorderSizePixel = 0
    ShadowInner.Image = 'rbxassetid://6014261993'
    ShadowInner.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowInner.ImageTransparency = 0.3
    ShadowInner.ScaleType = Enum.ScaleType.Slice
    ShadowInner.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowInner.ZIndex = 0
    ShadowInner.Parent = ShadowHolder

    Container:GetPropertyChangedSignal('Position'):Connect(function()
        ShadowHolder.Position = Container.Position
    end)

    Container:GetPropertyChangedSignal('Size'):Connect(function()
        ShadowHolder.Size = Container.Size
    end)

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(1, 0.82)
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local Background = Instance.new("ImageLabel")
    Background.Name = "Background"
    Background.Parent = Container
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundTransparency = 1
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    self._background = Background
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Theme.GroupStroke
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = "Handler"
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    self._handler = Handler
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026, 0, 0.111, 0)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = config.PrimaryColor
    ClientName.TextTransparency = 0.2
    ClientName.Text = config.title
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 100, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.056, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextSize = 13
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "Accent"})
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = config.PrimaryColor
    Pin.Parent = Handler
    table.insert(Library._elements, {obj = Pin, prop = "BackgroundColor3", tKey = "Accent"})
    
    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = config.PrimaryColor
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.Parent = Handler
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "Accent"})
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.235, 0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Theme.GroupStroke
    Divider.Parent = Handler
    table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "GroupStroke"})
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Theme.Text
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.TextSize = 14
    Minimize.Parent = Handler
    table.insert(Library._elements, {obj = Minimize, prop = "TextColor3", tKey = "Text"})
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container
    
    local ShadowScale = Instance.new('UIScale')
    ShadowScale.Parent = ShadowHolder
    
    self._ui = SecureScreenGui

    local function on_drag(input, process)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position
            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), { Position = position }):Play()
    end

    local function drag(input, process)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05
        else
            pcall(function() Container.BackgroundTransparency = tonumber(a) end)
        end
    end

    function self:UIVisiblity()
        SecureScreenGui.Enabled = not SecureScreenGui.Enabled
    end

    function self:change_visiblity(state)
        ShadowHolder.Visible = state
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    function self:set_gui_visibility(state)
        if not self._ui then return end
        if state then
            self._ui.Enabled = true
            Container.Size = UDim2.fromOffset(0, 0)
            ShadowHolder.Visible = true
            TweenService:Create(Container, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            local t = TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0)
            })
            t:Play()
            t.Completed:Once(function()
                self._ui.Enabled = false
                ShadowHolder.Visible = false
            end)
        end
    end

    function self:load()
        local content = {}
        for _, object in SecureScreenGui:GetDescendants() do
            if not object:IsA('ImageLabel') then continue end
            table.insert(content, object)
        end
        pcall(function() ContentProvider:PreloadAsync(content) end)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            ShadowScale.Scale = self._ui_scale
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
                ShadowScale.Scale = self._ui_scale
            end)
        end
    
        ShadowHolder.Visible = true

        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        self._ui_loaded = true
        
        local saved_bg = Library._config._flags['Background_Image']
        if typeof(saved_bg) == "string" and saved_bg ~= '' then
            local trans = Library._config._flags['Background_Transparency'] or 0.5
            self:SetBackground(saved_bg, trans)
        end

        for key, color in pairs(DefaultTheme) do
            local saved = Library._config._flags['Theme_'..key]
            if saved then
                self:SetColor(key, self:hexToRGB(saved))
            end
        end
    end

    function self:update_tabs(tab)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then continue end
            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)
                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    
                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()
                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Theme.Accent
                    }):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Theme.Accent
                    }):Play()
                end
                continue
            end
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Theme.TextDim
                }):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Theme.TextDim
                }):Play()
            end
        end
    end

    function self:update_sections(left_section, right_section)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end

    function self:create_tab(title, icon)
        local TabManager = {}
        local LayoutOrder = 0

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Theme.Text
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Theme.Group
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Group"})
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Theme.TextDim
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.240, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextSize = 13
        TextLabel.Parent = Tab
        table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextDim"})
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.8
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.100, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Theme.TextDim
        Icon.Parent = Tab
        table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextDim"})

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.259, 0, 0.5, 0)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout_L = Instance.new('UIListLayout')
        UIListLayout_L.Padding = UDim.new(0, 11)
        UIListLayout_L.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_L.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_L.Parent = LeftSection
        
        local UIPadding_L = Instance.new('UIPadding')
        UIPadding_L.PaddingTop = UDim.new(0, 1)
        UIPadding_L.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.629, 0, 0.5, 0)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout_R = Instance.new('UIListLayout')
        UIListLayout_R.Padding = UDim.new(0, 11)
        UIListLayout_R.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_R.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_R.Parent = RightSection
        
        local UIPadding_R = Instance.new('UIPadding')
        UIPadding_R.PaddingTop = UDim.new(0, 1)
        UIPadding_R.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = {
                _state = false, _size = 0, _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BackgroundTransparency = 0.2
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Theme.Group
            Module.Parent = settings.section
            table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Theme.GroupStroke
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Theme.Text
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.Parent = Module
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Theme.Accent
            ModuleName.TextTransparency = 0.2
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.073, 0, 0.240, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.TextSize = 13
            ModuleName.Parent = Header
            table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "Accent"})
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.Accent
            Description.TextTransparency = 0.7
            Description.Text = settings.description or ""
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.073, 0, 0.420, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.TextSize = 10
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.2
            Toggle.Position = UDim2.new(0.820, 0, 0.757, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Theme.Background
            Toggle.Parent = Header
            table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Background"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.2
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.TextDim
            Circle.Parent = Toggle
            table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "TextDim"})
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            -- ============================================================
            -- FIX #3/#4/#5: Module keybind UI (right-click to bind)
            -- ============================================================
            local Keybind = Instance.new('TextButton')
            Keybind.Name = 'Keybind'
            Keybind.AutoButtonColor = false
            Keybind.Text = ''
            Keybind.BackgroundTransparency = 0.2
            Keybind.Position = UDim2.new(0.150, 0, 0.735, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Theme.Control
            Keybind.Parent = Header
            table.insert(Library._elements, {obj = Keybind, prop = "BackgroundColor3", tKey = "Control"})

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 3)
            KeybindCorner.Parent = Keybind

            local KeybindStroke = Instance.new('UIStroke')
            KeybindStroke.Color = Theme.GroupStroke
            KeybindStroke.Transparency = 0.5
            KeybindStroke.Thickness = 1
            KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            KeybindStroke.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindStroke, prop = "Color", tKey = "GroupStroke"})

            local KeybindText = Instance.new('TextLabel')
            KeybindText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KeybindText.TextColor3 = Theme.Text
            KeybindText.Text = 'None'
            KeybindText.AnchorPoint = Vector2.new(0.5, 0.5)
            KeybindText.Size = UDim2.new(1, -6, 1, 0)
            KeybindText.BackgroundTransparency = 1
            KeybindText.TextXAlignment = Enum.TextXAlignment.Center
            KeybindText.Position = UDim2.new(0.5, 0, 0.5, 0)
            KeybindText.BorderSizePixel = 0
            KeybindText.TextSize = 10
            KeybindText.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindText, prop = "TextColor3", tKey = "Text"})

            local ModuleIcon = Instance.new('ImageLabel')
            ModuleIcon.Name = 'Icon'
            ModuleIcon.ImageColor3 = Theme.Accent
            ModuleIcon.ScaleType = Enum.ScaleType.Fit
            ModuleIcon.ImageTransparency = 0.3
            ModuleIcon.AnchorPoint = Vector2.new(0, 0.5)
            ModuleIcon.Image = 'rbxassetid://79095934438045'
            ModuleIcon.BackgroundTransparency = 1
            ModuleIcon.Position = UDim2.new(0.071, 0, 0.750, 0)
            ModuleIcon.Size = UDim2.new(0, 15, 0, 15)
            ModuleIcon.BorderSizePixel = 0
            ModuleIcon.Parent = Header
            table.insert(Library._elements, {obj = ModuleIcon, prop = "ImageColor3", tKey = "Accent"})

            local Divider = Instance.new('Frame')
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.620, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.GroupStroke
            Divider.Parent = Header
            table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "GroupStroke"})
            
            local Divider2 = Instance.new('Frame')
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.5
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Theme.GroupStroke
            Divider2.Parent = Header
            table.insert(Library._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "GroupStroke"})
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 0, 93)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            -- ============================================================
            -- FIX #1: refresh_size recomputes module/options height
            -- ============================================================
            function ModuleManager:refresh_size()
                if self._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)
                else
                    Module.Size = UDim2.fromOffset(241, 93)
                end
            end

            function ModuleManager:change_state(state)
                self._state = state
                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Group,
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Background
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.TextDim,
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)
                settings.callback(self._state)
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then return end
                Library._keybind_list[settings.flag] = settings.title or "Module"
                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then return end
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                    font_params.Size = 10
                    font_params.Width = 10000
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    Keybind.Size = UDim2.fromOffset(math.max(33, font_size.X + 12), 15)
                else
                    Keybind.Size = UDim2.fromOffset(33, 15)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                settings.callback(ModuleManager._state)
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                    Toggle.BackgroundColor3 = Theme.Accent
                    Circle.BackgroundColor3 = Theme.Group
                    Circle.Position = UDim2.fromScale(0.53, 0.5)
                else
                    Toggle.BackgroundColor3 = Theme.Background
                    Circle.BackgroundColor3 = Theme.TextDim
                    Circle.Position = UDim2.fromScale(0, 0.5)
                end
            end

            Library._flag_registry[settings.flag] = function(state)
                ModuleManager:change_state(state)
            end

            if Library._config._keybinds[settings.flag] then
                KeybindText.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            else
                KeybindText.Text = 'None'
            end

            Keybind.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                Library._choosing_keybind = true
                KeybindText.Text = '...'
                Keybind.BackgroundColor3 = Theme.ControlHover

                local function cancel_choose()
                    Library._choosing_keybind = false
                    Keybind.BackgroundColor3 = Theme.Control
                    if Library._config._keybinds[settings.flag] then
                        KeybindText.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    else
                        KeybindText.Text = 'None'
                    end
                    if Connections['keybind_choose_start'] then
                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil
                    end
                end

                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        Library._config._keybinds[settings.flag] = nil
                        Library._keybind_list[settings.flag] = nil
                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end
                        cancel_choose()
                        Config:save(game.GameId, Library._config)
                        return
                    end

                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Library._keybind_list[settings.flag] = settings.title or "Module"
                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end
                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    cancel_choose()
                    Config:save(game.GameId, Library._config)
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_checkbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then self._size = 11 end
                self._size += 22
                ModuleManager:refresh_size()
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Theme.Text
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 18)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 11
                TitleLabel.TextColor3 = Theme.Text
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Checkbox"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox
                table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

                local Box = Instance.new("Frame")
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.2
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Control
                Box.Parent = Checkbox
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
                
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
                
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.Accent
                Fill.Parent = Box
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
                
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
                
                function CheckboxManager:change_state(state)
                    self._state = state
                    if self._state then
                        TweenService:Create(Fill, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Fill, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
                
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
                
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
                
                Library._flag_registry[settings.flag] = function(state)
                    CheckboxManager:change_state(state)
                end
                
                return CheckboxManager
            end

            function ModuleManager:create_button(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 22
                ModuleManager:refresh_size()
            
                local Button = Instance.new("TextButton")
                Button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextColor3 = Theme.Text
                Button.TextTransparency = 0.2
                Button.Text = settings.title or "Button"
                Button.AutoButtonColor = true
                Button.BackgroundTransparency = 0.2
                Button.BackgroundColor3 = Theme.Control
                Button.Name = "Button"
                Button.Size = UDim2.new(0, 207, 0, 22)
                Button.BorderSizePixel = 0
                Button.TextSize = 11
                Button.Parent = Options
                Button.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Button, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Button, prop = "TextColor3", tKey = "Text"})

                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 4)
                ButtonCorner.Parent = Button

                Button.MouseButton1Click:Connect(function()
                    if settings.callback then settings.callback() end
                end)
            end
            
            function ModuleManager:create_slider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local SliderManager = {}

                if self._size == 0 then self._size = 11 end
                self._size += 30
                ModuleManager:refresh_size()

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Slider.TextSize = 14
                Slider.TextColor3 = Theme.Text
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 25)
                Slider.BorderSizePixel = 0
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.Parent = Slider
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                
                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.2
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.Accent
                Drag.Parent = Slider
                table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Accent"})
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.Accent
                Fill.Parent = Drag
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Theme.Accent
                Circle.Parent = Fill
                table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.Text
                Value.TextTransparency = 0.2
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.Parent = Slider
                table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "Text"})

                function SliderManager:set_percentage(percentage)
                    local rounded_number = 0
                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end
                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    local slider_size = math.clamp(percentage, 0.02, 1) * (Drag.AbsoluteSize.X ~= 0 and Drag.AbsoluteSize.X or Drag.Size.X.Offset)
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = tostring(number_threshold)
                    TweenService:Create(Fill, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, (Drag.AbsoluteSize.Y ~= 0 and Drag.AbsoluteSize.Y or Drag.Size.Y.Offset))
                    }):Play()
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position
                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input, process)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)
                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config)
                        end
                    end)
                end

                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag])
                    else
                        SliderManager:set_percentage(settings.value)
                    end
                else
                    SliderManager:set_percentage(settings.value)
                end
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                Library._flag_registry[settings.flag] = function(value)
                    SliderManager:set_percentage(value)
                end
                return SliderManager
            end

            function ModuleManager:create_textbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextboxManager = { _text = "" }
            
                if self._size == 0 then self._size = 11 end
                self._size += 34
                ModuleManager:refresh_size()
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Theme.Text
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 10
                Label.Parent = Options
                Label.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})
                
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Theme.Text
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.PlaceholderColor3 = Theme.TextDim
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 17)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Theme.Control
                Textbox.BackgroundTransparency = 0.2
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Textbox, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Textbox, prop = "TextColor3", tKey = "Text"})
                table.insert(Library._elements, {obj = Textbox, prop = "PlaceholderColor3", tKey = "TextDim"})
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
                
                function TextboxManager:update_text(text)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end
                
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
                
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
                
                Library._flag_registry[settings.flag] = function(value)
                    TextboxManager:update_text(value)
                end
                return TextboxManager
            end

            function ModuleManager:create_dropdown(settings)
                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1
                end
                local DropdownManager = { _state = false, _size = 0 }
                
                if not settings.Order then
                    if self._size == 0 then self._size = 11 end
                    self._size += 46
                    ModuleManager:refresh_size()
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Theme.Text
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 41)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.Parent = Options
                Dropdown.LayoutOrder = LayoutOrderModule

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {}
                end
                
                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Theme.Text
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.Parent = Dropdown
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.2
                Box.Position = UDim2.new(0.5, 0, 1.200, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 24)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Control
                Box.Parent = TextLabel
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 24)
                Header.BorderSizePixel = 0
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Theme.Text
                CurrentOption.TextTransparency = 0.2
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.050, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.TextSize = 10
                CurrentOption.Parent = Header
                table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "Text"})
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Theme.TextDim
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.910, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.Parent = Header
                table.insert(Library._elements, {obj = Arrow, prop = "ImageColor3", tKey = "TextDim"})
                
                local OptionsList = Instance.new('ScrollingFrame')
                OptionsList.Active = true
                OptionsList.ScrollBarImageTransparency = 1
                OptionsList.AutomaticCanvasSize = Enum.AutomaticSize.XY
                OptionsList.ScrollBarThickness = 0
                OptionsList.Name = 'Options'
                OptionsList.Size = UDim2.new(0, 207, 0, 0)
                OptionsList.BackgroundTransparency = 1
                OptionsList.Position = UDim2.new(0, 0, 1, 0)
                OptionsList.BorderSizePixel = 0
                OptionsList.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                OptionsList.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = OptionsList
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = OptionsList

                function DropdownManager:update(option)
                    if settings.multi_dropdown then
                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {}
                        end
                        local CurrentTargetValue = nil
                        if #Library._config._flags[settings.flag] > 0 then
                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag])
                        end
                        local selected = {}
                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                local trimmedValue = value:match("^%s*(.-)%s*$")
                                if trimmedValue ~= "Label" then table.insert(selected, trimmedValue) end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                local trimmedValue = value:match("^%s*(.-)%s*$")
                                if trimmedValue ~= "Label" then table.insert(selected, trimmedValue) end
                            end
                        end
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text)
                        local optionSkibidi = (typeof(option) == "string" and option) or (typeof(option) == "Instance" and option.Name) or tostring(option)
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i)
                                break
                            end
                        end
                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        CurrentTargetValue = convertStringToTable(CurrentOption.Text)
                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end
                        end
                        CurrentOption.Text = table.concat(selected, ", ")
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text)
                    else
                        local optionText = (typeof(option) == "string" and option) or (typeof(option) == "Instance" and option.Name) or (option ~= nil and tostring(option) or "")
                        CurrentOption.Text = optionText
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = object.Text == optionText and 0.2 or 0.6
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                    Config:save(game.GameId, Library._config)
                    settings.callback(option)
                end

                -- ============================================================
                -- FIX #6: unfold_settings uses refresh_size (fixes clipping)
                -- ============================================================
                function DropdownManager:unfold_settings()
                    self._state = not self._state
                    if self._state then
                        ModuleManager._multiplier = ModuleManager._multiplier + self._size
                    else
                        ModuleManager._multiplier = ModuleManager._multiplier - self._size
                    end
                    ModuleManager:refresh_size()

                    TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 41 + (self._state and self._size or 0))
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 24 + (self._state and self._size or 0))
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    }):Play()
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3
                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 18)
                        Option.TextColor3 = Theme.Text
                        local vText = (typeof(value) == "string" and value) or (typeof(value) == "Instance" and value.Name) or tostring(value)
                        Option.Text = vText
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.050, 0, 0.342, 0)
                        Option.BorderSizePixel = 0
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {}
                            end
                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end
                            DropdownManager:update(value)
                        end)
                        if settings.maximum_options and index > settings.maximum_options then continue end
                        DropdownManager._size = DropdownManager._size + 18
                        OptionsList.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:refresh(new_options)
                    local old_size = self._size
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child.Name == "Option" then child:Destroy() end
                    end
                    self._size = 3
                    for index, value in new_options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 18)
                        Option.TextColor3 = Theme.Text
                        local vText = (typeof(value) == "string" and value) or (typeof(value) == "Instance" and value.Name) or tostring(value)
                        Option.Text = vText
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.050, 0, 0.342, 0)
                        Option.BorderSizePixel = 0
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {}
                            end
                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end
                            DropdownManager:update(value)
                        end)

                        if settings.maximum_options and index > settings.maximum_options then continue end
                        self._size = self._size + 18
                        OptionsList.Size = UDim2.fromOffset(207, self._size)
                    end
                    if self._state then
                        local diff = self._size - old_size
                        ModuleManager._multiplier = ModuleManager._multiplier + diff
                        ModuleManager:refresh_size()
                    end
                end

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1] or "None")
                end
                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)
                Library._flag_registry[settings.flag] = function(value)
                    DropdownManager:update(value)
                end
                return DropdownManager
            end
            
            function ModuleManager:create_divider(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 27
                ModuleManager:refresh_size()

                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, 207, 0, 20)
                OuterFrame.BackgroundTransparency = 1
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Theme.Text
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.TextSize = 11
                    TextLabel.ZIndex = 3
                    TextLabel.Parent = OuterFrame
                    table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
                end
                
                if not settings or settings and not settings.disableline then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, 1)
                    Divider.BackgroundColor3 = Theme.Text
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2
                    Divider.Position = UDim2.new(0, 0, 0.5, -0.5)
                    table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Text"})
                end
                return true
            end

            function ModuleManager:create_paragraph(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local ParagraphManager = {}
                
                if self._size == 0 then self._size = 11 end
                self._size += settings.customScale or 70
                ModuleManager:refresh_size()
            
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Theme.Control
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Paragraph, prop = "BackgroundColor3", tKey = "Control"})
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Theme.Text
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
                table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})
            
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Theme.TextDim
                Body.Text = settings.text or "Paragraph"
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})
            
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.ControlHover
                    }):Play()
                end)
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Control
                    }):Play()
                end)
                return ParagraphManager
            end

            function ModuleManager:create_text(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextManager = {}
            
                if self._size == 0 then self._size = 11 end
                self._size += settings.customScale or 50
                ModuleManager:refresh_size()
            
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Theme.Control
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize or 30)
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = TextFrame, prop = "BackgroundColor3", tKey = "Control"})
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Theme.TextDim
                Body.Text = settings.text or "Text"
                Body.Size = UDim2.new(1, -10, 1, -10)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})
            
                function TextManager:Set(new_settings)
                    Body.Text = new_settings.text or "Text"
                end
                return TextManager
            end

            function ModuleManager:create_feature(settings)
                local checked = false
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 22
                ModuleManager:refresh_size()
            
                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 18)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule
            
                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer
            
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                FeatureButton.TextSize = 11
                FeatureButton.Size = UDim2.new(1, -35, 0, 18)
                FeatureButton.BackgroundColor3 = Theme.Control
                FeatureButton.TextColor3 = Theme.Text
                FeatureButton.Text = "    " .. (settings.title or "Feature")
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
                table.insert(Library._elements, {obj = FeatureButton, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = FeatureButton, prop = "TextColor3", tKey = "Text"})

                local FeatureCorner = Instance.new("UICorner")
                FeatureCorner.CornerRadius = UDim.new(0, 4)
                FeatureCorner.Parent = FeatureButton
                
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 18)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
                
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
                
                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KeybindBox.Size = UDim2.new(0, 16, 0, 16)
                KeybindBox.BackgroundColor3 = Theme.Accent
                KeybindBox.TextColor3 = Theme.Text
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2
                KeybindBox.Parent = RightContainer
                table.insert(Library._elements, {obj = KeybindBox, prop = "BackgroundColor3", tKey = "Accent"})
                table.insert(Library._elements, {obj = KeybindBox, prop = "TextColor3", tKey = "Text"})

                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner")
                CheckboxCorner.CornerRadius = UDim.new(0, 3)
                CheckboxCorner.Parent = KeybindBox

                local UIStroke = Instance.new("UIStroke")
                UIStroke.Color = Theme.Accent
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                UIStroke.Parent = KeybindBox
                table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "Accent"})
                
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end
                
                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND
                if KeybindBox.Text == "Unknown" then KeybindBox.Text = "..." end
                
                local UseF_Var = nil
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 16, 0, 16)
                    Checkbox.BackgroundColor3 = checked and Theme.Accent or Theme.Control
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1
                    table.insert(Library._elements, {obj = Checkbox, prop = "BackgroundColor3", tKey = "Accent"})
                    table.insert(Library._elements, {obj = Checkbox, prop = "BackgroundColor3", tKey = "Control"})

                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
                    
                    local CheckboxStroke = Instance.new("UIStroke")
                    CheckboxStroke.Color = Theme.Accent
                    CheckboxStroke.Thickness = 1
                    CheckboxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    CheckboxStroke.Parent = Checkbox
                    table.insert(Library._elements, {obj = CheckboxStroke, prop = "Color", tKey = "Accent"})
                    
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Theme.Accent or Theme.Control
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then settings.callback(checked) end
                    end
                    UseF_Var = toggleState
                    Checkbox.MouseButton1Click:Connect(toggleState)
                else
                    UseF_Var = function()
                        if settings.button_callback then settings.button_callback() end
                    end
                end
                
                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then KeybindBox.Text = newKey end
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)
                
                local keyPressConnection
                keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var()
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection
                
                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then settings.button_callback() end
                end)

                if not settings.disablecheck then settings.callback(checked) end
                return FeatureContainer
            end

            task.defer(function()
                ModuleManager:refresh_size()
            end)

            return ModuleManager
        end

        return TabManager
    end

    -- ============================================================
    -- FIX #10: Custom minimize key
    -- ============================================================
    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        local key = Library._config._keybinds['Minimize_Keybind'] or "Enum.KeyCode.Insert"
        if tostring(input.KeyCode) ~= key then return end
        self._ui_open = not self._ui_open
        if Library._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        if Library._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)

    return self
end

function Library:build_interface_tab()
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007')
    local Container = self._container
    local Handler = self._handler

    local Background_Folder = 'AchaoticUI/AllusiveModified/Backgrounds'

    -- ============================================================
    -- FIX #8: URL -> download -> getcustomasset pipeline
    -- ============================================================
    local function resolve_background(source)
        if source == '' then return '' end
        if source:match('^%d+$') then return 'rbxassetid://'..source end
        if source:match('^rbx%a+://') then return source end
        local Custom_Asset = getcustomasset or getsynasset
        if not Custom_Asset then return '' end
        if not source:match('^https?://') then
            if isfile and isfile(source) then
                return Custom_Asset(source)
            end
            return ''
        end
        if not (writefile and isfile and isfolder) then return '' end
        if not isfolder(Background_Folder) then makefolder(Background_Folder) end
        local extension = source:match('%.(%a%a%a%a?)[%?#]') or source:match('%.(%a%a%a%a?)$') or 'png'
        local path = Background_Folder..'/'..source:gsub('%W', ''):sub(-48)..'.'..extension
        if not isfile(path) then
            local success, body = pcall(game.HttpGet, game, source, true)
            if not success then return '' end
            writefile(path, body)
        end
        return Custom_Asset(path)
    end

    local function set_background_image(source)
        local Background_Image = self._background
        local resolved = resolve_background(source)
        Background_Image.Image = resolved
        Background_Image.Size = UDim2.new(1, 0, 1, 0)
        Background_Image.Position = UDim2.new(0, 0, 0, 0)
        Background_Image.ScaleType = Enum.ScaleType.Crop
        if resolved ~= '' then
            Background_Image.Visible = true
        end
    end

    local Transparent_Targets = { Module = true, Box = true, Keybind = true, Reset = true, AssetId = true }

    local function set_module_transparency(value)
        for _, object in self._ui:GetDescendants() do
            if Transparent_Targets[object.Name] then
                object.BackgroundTransparency = value
            end
        end
    end

    local function find_module_frame(title)
        for _, object in self._ui:GetDescendants() do
            if object.Name == 'Module' then
                local header = object:FindFirstChild('Header')
                local module_name = header and header:FindFirstChild('ModuleName')
                if module_name and module_name.Text == title then
                    return object
                end
            end
        end
    end

    local function build_reset_button(parent, layout_order, on_click)
        local Reset_Holder = Instance.new('Frame')
        Reset_Holder.Name = 'ResetHolder'
        Reset_Holder.Size = UDim2.fromOffset(207, 25)
        Reset_Holder.BackgroundTransparency = 1
        Reset_Holder.BorderSizePixel = 0
        Reset_Holder.LayoutOrder = layout_order
        Reset_Holder.Parent = parent

        local Reset = Instance.new('TextButton')
        Reset.Name = 'Reset'
        Reset.AnchorPoint = Vector2.new(0, 1)
        Reset.Position = UDim2.new(0, 0, 1, 0)
        Reset.Size = UDim2.fromOffset(207, 24)
        Reset.BackgroundColor3 = Theme.Control
        Reset.BorderSizePixel = 0
        Reset.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Reset.TextColor3 = Theme.Text
        Reset.TextSize = 12
        Reset.AutoButtonColor = false
        Reset.Text = 'Reset'
        Reset.Parent = Reset_Holder
        table.insert(self._elements, {obj = Reset, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = Reset, prop = "TextColor3", tKey = "Text"})

        local ResetCorner = Instance.new('UICorner')
        ResetCorner.CornerRadius = UDim.new(0, 4)
        ResetCorner.Parent = Reset

        local ResetStroke = Instance.new('UIStroke')
        ResetStroke.Color = Theme.GroupStroke
        ResetStroke.Transparency = 0.5
        ResetStroke.Thickness = 1
        ResetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ResetStroke.Parent = Reset
        table.insert(self._elements, {obj = ResetStroke, prop = "Color", tKey = "GroupStroke"})

        Reset.MouseButton1Click:Connect(on_click)
    end

    local config_module = InterfaceTab:create_module({
        title = 'Configurations',
        flag = 'UI_Config_System',
        description = 'Manage Settings Profiles',
        section = 'right',
        callback = function(state) end,
    })

    local function get_configs()
        if not (isfolder and listfiles) then return {} end
        if not isfolder('AchaoticUI/AllusiveModified/Configs') then makefolder('AchaoticUI/AllusiveModified/Configs') end
        local files = listfiles('AchaoticUI/AllusiveModified/Configs')
        local names = {}
        for _, file in ipairs(files) do
            if file:match('%.json$') then
                local name = file:match('([^/\\]+)%.json$')
                if name then table.insert(names, name) end
            end
        end
        return names
    end

    local config_name_box = config_module:create_textbox({
        title = 'Profile Name',
        flag = 'Config_Input_Name',
        placeholder = 'New Config Name',
        callback = function() end
    })

    local config_dropdown = config_module:create_dropdown({
        title = 'Saved Profiles',
        flag = 'Config_Saved_List',
        options = get_configs(),
        multi_dropdown = false,
        callback = function() end
    })

    config_module:create_button({
        title = 'Save Profile',
        callback = function()
            local name = config_name_box._text
            if typeof(name) ~= 'string' or name:gsub("%s", "") == "" then
                self:Notify({title = 'Config', text = 'Enter a valid name.', duration = 3})
                return
            end
            Config:save('Configs/'..name, Library._config)
            config_dropdown:refresh(get_configs())
            config_dropdown:update(name)
            self:Notify({title = 'Config', text = 'Saved as '..name, duration = 3})
        end
    })

    config_module:create_button({
        title = 'Load Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then
                self:Notify({title = 'Config', text = 'Select a profile to load.', duration = 3})
                return
            end
            local loaded = Config:load('Configs/'..name, { _flags = {}, _keybinds = {} })
            Library._config._flags = loaded._flags or {}
            Library._config._keybinds = loaded._keybinds or {}

            for flag, func in pairs(Library._flag_registry or {}) do
                if Library._config._flags[flag] ~= nil then
                    pcall(func, Library._config._flags[flag])
                end
            end

            for key, color in pairs(DefaultTheme) do
                local saved = Library._config._flags['Theme_'..key]
                if saved then
                    Library:SetColor(key, Library:hexToRGB(saved))
                end
            end

            local saved_bg = Library._config._flags['Background_Image']
            if typeof(saved_bg) == "string" then
                Library:SetBackground(saved_bg, Library._config._flags['Background_Transparency'] or 0.5)
            end

            self:Notify({title = 'Config', text = 'Loaded '..name, duration = 3})
        end
    })

    config_module:create_button({
        title = 'Delete Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then return end
            local path = 'AchaoticUI/AllusiveModified/Configs/'..name..'.json'
            if isfile and isfile(path) then
                delfile(path)
                config_dropdown:refresh(get_configs())
                self:Notify({title = 'Config', text = 'Deleted '..name, duration = 3})
            end
        end
    })

    local color_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'Gui_Colors',
        description = 'Customize UI Colors',
        section = 'left',
        callback = function(state) end,
    })

    local Color_Module_Frame = find_module_frame('Appearance')
    local Color_Targets = { 'Background', 'Group', 'GroupStroke', 'Control', 'ControlHover', 'Text', 'TextDim', 'Accent' }
    local Color_Swatches = {}
    local Selected_Color_Target = 'Background'
    local Pointer_Offset = Vector2.zero
    local Current_Hue = 0
    local Current_Saturation = 0
    local Current_Value = 1

    if Color_Module_Frame then
        local Options = Color_Module_Frame.Options

        local Popup = Instance.new('Frame')
        Popup.Name = 'ColorPopup'
        Popup.Position = UDim2.fromOffset(8, 8)
        Popup.Size = UDim2.fromOffset(214, 144)
        Popup.BackgroundColor3 = Color3.fromRGB(14, 20, 24)
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 30
        Popup.Parent = Handler

        local PopupCorner = Instance.new('UICorner')
        PopupCorner.CornerRadius = UDim.new(0, 9)
        PopupCorner.Parent = Popup

        local PopupStroke = Instance.new('UIStroke')
        PopupStroke.Color = Theme.GroupStroke
        PopupStroke.Transparency = 0.5
        PopupStroke.Thickness = 1
        PopupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        PopupStroke.Parent = Popup

        local Field = Instance.new('TextButton')
        Field.Name = 'Field'
        Field.Position = UDim2.fromOffset(10, 10)
        Field.Size = UDim2.fromOffset(194, 100)
        Field.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Field.BorderSizePixel = 0
        Field.ClipsDescendants = true
        Field.AutoButtonColor = false
        Field.Text = ''
        Field.ZIndex = 31
        Field.Parent = Popup

        local FieldCorner = Instance.new('UICorner')
        FieldCorner.CornerRadius = UDim.new(0, 5)
        FieldCorner.Parent = Field

        local Saturation = Instance.new('Frame')
        Saturation.Name = 'Saturation'
        Saturation.Size = UDim2.new(1, 0, 1, 0)
        Saturation.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Saturation.BorderSizePixel = 0
        Saturation.ZIndex = 32
        Saturation.Parent = Field

        local SaturationGradient = Instance.new('UIGradient')
        SaturationGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
        }
        SaturationGradient.Parent = Saturation

        local Brightness = Instance.new('Frame')
        Brightness.Name = 'Brightness'
        Brightness.Size = UDim2.new(1, 0, 1, 0)
        Brightness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Brightness.BorderSizePixel = 0
        Brightness.ZIndex = 33
        Brightness.Parent = Field

        local BrightnessGradient = Instance.new('UIGradient')
        BrightnessGradient.Rotation = 90
        BrightnessGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0),
        }
        BrightnessGradient.Parent = Brightness

        local Cursor = Instance.new('Frame')
        Cursor.Name = 'Cursor'
        Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        Cursor.Position = UDim2.new(0, 0, 0, 0)
        Cursor.Size = UDim2.fromOffset(11, 11)
        Cursor.BackgroundTransparency = 1
        Cursor.BorderSizePixel = 0
        Cursor.ZIndex = 34
        Cursor.Parent = Field

        local CursorCorner = Instance.new('UICorner')
        CursorCorner.CornerRadius = UDim.new(1, 0)
        CursorCorner.Parent = Cursor

        local CursorStroke = Instance.new('UIStroke')
        CursorStroke.Color = Color3.fromRGB(255, 255, 255)
        CursorStroke.Transparency = 0
        CursorStroke.Thickness = 2
        CursorStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        CursorStroke.Parent = Cursor

        local Hue = Instance.new('TextButton')
        Hue.Name = 'Hue'
        Hue.Position = UDim2.fromOffset(10, 120)
        Hue.Size = UDim2.fromOffset(194, 12)
        Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Hue.BorderSizePixel = 0
        Hue.AutoButtonColor = false
        Hue.Text = ''
        Hue.ZIndex = 31
        Hue.Parent = Popup

        local HueCorner = Instance.new('UICorner')
        HueCorner.CornerRadius = UDim.new(1, 0)
        HueCorner.Parent = Hue

        local HueGradient = Instance.new('UIGradient')
        HueGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0,   0  )),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0  )),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0  )),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,   255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0,   0  )),
        }
        HueGradient.Parent = Hue

        local Hue_Knob = Instance.new('Frame')
        Hue_Knob.Name = 'Knob'
        Hue_Knob.AnchorPoint = Vector2.new(0.5, 0.5)
        Hue_Knob.Position = UDim2.new(0, 0, 0.5, 0)
        Hue_Knob.Size = UDim2.fromOffset(5, 16)
        Hue_Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Hue_Knob.BorderSizePixel = 0
        Hue_Knob.ZIndex = 32
        Hue_Knob.Parent = Hue

        local Hue_Knob_Corner = Instance.new('UICorner')
        Hue_Knob_Corner.CornerRadius = UDim.new(1, 0)
        Hue_Knob_Corner.Parent = Hue_Knob

        local Hue_Knob_Stroke = Instance.new('UIStroke')
        Hue_Knob_Stroke.Color = Color3.fromRGB(20, 20, 24)
        Hue_Knob_Stroke.Transparency = 0.42
        Hue_Knob_Stroke.Thickness = 1
        Hue_Knob_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Hue_Knob_Stroke.Parent = Hue_Knob

        local function set_color(hue, saturation, brightness)
            Current_Hue = hue
            Current_Saturation = saturation
            Current_Value = brightness
            local color = Color3.fromHSV(hue, saturation, brightness)
            Field.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            Cursor.Position = UDim2.new(saturation, 0, 1 - brightness, 0)
            Hue_Knob.Position = UDim2.new(hue, 0, 0.5, 0)
            Color_Swatches[Selected_Color_Target].BackgroundColor3 = color
            self:SetColor(Selected_Color_Target, color)
        end

        local function calibrate_pointer(frame)
            local inset = GuiService:GetGuiInset()
            local location = UserInputService:GetMouseLocation()
            local top_left = frame.AbsolutePosition
            local bottom_right = top_left + frame.AbsoluteSize
            for _, offset in { Vector2.zero, inset, -inset } do
                local point = location + offset
                if point.X >= top_left.X and point.X <= bottom_right.X
                   and point.Y >= top_left.Y and point.Y <= bottom_right.Y then
                    Pointer_Offset = offset
                    return
                end
            end
        end

        local function update_field()
            local location = UserInputService:GetMouseLocation() + Pointer_Offset
            local sat = math.clamp((location.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
            local bright = math.clamp((location.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
            set_color(Current_Hue, sat, 1 - bright)
        end

        local function update_hue()
            local location = UserInputService:GetMouseLocation() + Pointer_Offset
            local hue = math.clamp((location.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
            set_color(hue, Current_Saturation, Current_Value)
        end

        local function begin_drag(key, frame, update)
            calibrate_pointer(frame)
            update()
            Connections[key..'_move'] = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                   and input.UserInputType ~= Enum.UserInputType.Touch then return end
                update()
            end)
            Connections[key..'_ended'] = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                   and input.UserInputType ~= Enum.UserInputType.Touch then return end
                Connections:disconnect(key..'_move')
                Connections:disconnect(key..'_ended')
            end)
        end

        local function close_popup()
            Popup.Visible = false
            for _, swatch in Color_Swatches do
                swatch.UIStroke.Transparency = 0.5
            end
        end

        local function open_popup(target, swatch)
            if Popup.Visible and Selected_Color_Target == target then
                close_popup()
                return
            end
            Selected_Color_Target = target
            for name, object in Color_Swatches do
                object.UIStroke.Transparency = name == target and 0 or 0.5
            end
            local scale = Handler.AbsoluteSize.X / 698
            local relative_x = (swatch.AbsolutePosition.X - Handler.AbsolutePosition.X) / scale
            local relative_y = (swatch.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale
            Popup.Position = UDim2.fromOffset(
                math.clamp(relative_x - 224, 8, 470),
                math.clamp(relative_y - 62, 8, 327)
            )
            Popup.Visible = true
            local hue, sat, bright = Color3.toHSV(Theme[target])
            set_color(hue, sat, bright)
        end

        local function build_color_row(index, target)
            local Row = Instance.new('TextButton')
            Row.Name = 'ColorRow'
            Row.Size = UDim2.fromOffset(207, 22)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.AutoButtonColor = false
            Row.Text = ''
            Row.LayoutOrder = index
            Row.Parent = Options

            local TitleLabel = Instance.new('TextLabel')
            TitleLabel.Name = 'TitleLabel'
            TitleLabel.Size = UDim2.new(1, -50, 1, 0)
            TitleLabel.Position = UDim2.new(0, 0, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TitleLabel.TextColor3 = Theme.Text
            TitleLabel.TextSize = 12
            TitleLabel.Text = target
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
            TitleLabel.Parent = Row
            table.insert(self._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

            local Swatch = Instance.new('TextButton')
            Swatch.Name = 'Swatch'
            Swatch.AnchorPoint = Vector2.new(1, 0.5)
            Swatch.Position = UDim2.new(1, 0, 0.5, 0)
            Swatch.Size = UDim2.fromOffset(34, 16)
            Swatch.BackgroundColor3 = Theme[target]
            Swatch.BorderSizePixel = 0
            Swatch.AutoButtonColor = false
            Swatch.Text = ''
            Swatch.Parent = Row

            local SwatchCorner = Instance.new('UICorner')
            SwatchCorner.CornerRadius = UDim.new(0, 4)
            SwatchCorner.Parent = Swatch

            local SwatchStroke = Instance.new('UIStroke')
            SwatchStroke.Color = Theme.GroupStroke
            SwatchStroke.Transparency = 0.5
            SwatchStroke.Thickness = 1
            SwatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            SwatchStroke.Parent = Swatch
            table.insert(self._elements, {obj = SwatchStroke, prop = "Color", tKey = "GroupStroke"})

            Swatch.MouseButton1Click:Connect(function() open_popup(target, Swatch) end)
            Row.MouseButton1Click:Connect(function() open_popup(target, Swatch) end)

            Color_Swatches[target] = Swatch
        end

        for index, target in Color_Targets do
            build_color_row(index, target)
        end

        build_reset_button(Options, #Color_Targets + 3, function()
            close_popup()
            for target, color in pairs(DefaultTheme) do
                if typeof(color) == "Color3" then
                    self:SetColor(target, color)
                    Color_Swatches[target].BackgroundColor3 = color
                end
            end
        end)

        Field.MouseButton1Down:Connect(function()
            begin_drag('gui_color_field', Field, update_field)
        end)

        Hue.MouseButton1Down:Connect(function()
            begin_drag('gui_color_hue', Hue, update_hue)
        end)

        Connections['gui_color_section'] = Color_Module_Frame.Parent:GetPropertyChangedSignal('Visible'):Connect(function()
            if Color_Module_Frame.Parent.Visible then return end
            close_popup()
        end)

        Connections['gui_color_visiblity'] = Color_Module_Frame:GetPropertyChangedSignal('Size'):Connect(function()
            if Color_Module_Frame.AbsoluteSize.Y > 100 then return end
            close_popup()
        end)
        
        color_module._size = 282
        Options.Size = UDim2.fromOffset(241, color_module._size)
        if color_module._state then
            Color_Module_Frame.Size = UDim2.fromOffset(241, 93 + color_module._size + color_module._multiplier)
        end
    end

    local image_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'UI_Background',
        description = 'Set custom background image',
        section = 'right',
        callback = function(state)
            if not self._background then return end
            if state and self._background.Image ~= '' then
                self._background.Visible = true
                set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)
            else
                self._background.Visible = false
                set_module_transparency(0)
            end
        end
    })

    local Background_Presets = {
        ['Preset 1']  = 'https://i.pinimg.com/736x/bd/12/a5/bd12a561f083960f6c1382c54f4df234.jpg',
        ['Preset 2']  = 'https://i.pinimg.com/736x/53/bd/84/53bd848d7ca43b57612117292d7ff979.jpg',
        ['Preset 3']  = 'https://i.pinimg.com/736x/db/26/c7/db26c713d48342bd15c0ee8f623e19c6.jpg',
        ['Preset 4']  = 'https://i.pinimg.com/736x/dc/ad/10/dcad1026de88c85a417c6f4dd0b620c8.jpg',
        ['Preset 5']  = 'https://i.pinimg.com/736x/fe/88/90/fe88905bf7387c8827ffaf4a5aae7068.jpg',
        ['Preset 6']  = 'https://i.pinimg.com/736x/6a/82/5e/6a825e0e447466bad8295e9dc9b87486.jpg',
        ['Preset 7']  = 'https://i.pinimg.com/originals/10/ff/4f/10ff4f98a494e390e07b1a0e9eefa4be.gif',
        ['Preset 8']  = 'https://i.pinimg.com/736x/d8/87/49/d887496ab4b2dc63c0526b055ec34f60.jpg',
        ['Preset 9']  = 'https://i.pinimg.com/736x/b6/18/fc/b618fc66a0fd9442ddeb338ab5d283c7.jpg',
        ['Preset 10'] = 'https://i.pinimg.com/736x/f9/03/bc/f903bc265438bccc74579c6be2b9de0f.jpg',
        ['Preset 11'] = 'https://i.pinimg.com/1200x/ac/31/e3/ac31e3d45b625de96efe6712d4f3a3c2.jpg',
    }

    local Preset_Options = {
        'None',
        'Preset 1','Preset 2','Preset 3','Preset 4','Preset 5','Preset 6',
        'Preset 7','Preset 8','Preset 9','Preset 10','Preset 11',
    }

    local Saved_Background_Id = Library._config._flags['Background_Image_Id']
    local Background_Image_Id = (typeof(Saved_Background_Id) == 'string' and Saved_Background_Id) or ''
    local Asset_Input

    local preset_dropdown = image_module:create_dropdown({
        title = 'Preset',
        flag = 'Background_Preset',
        options = Preset_Options,
        multi_dropdown = false,
        maximum_options = 4,
        callback = function(value)
            local name = (typeof(value) == "string" and value) or (typeof(value) == "Instance" and value.Name) or (typeof(value) == "table" and value.Name) or tostring(value)
            local source = (name and Background_Presets[name]) or ''
            Background_Image_Id = source
            set_background_image(source)
            if Asset_Input then Asset_Input.Text = source end
            Library._config._flags['Background_Image_Id'] = source
            self:SetBackground(source, self._background.ImageTransparency)
        end,
    })

    local transparency_slider = image_module:create_slider({
        title = 'Transparency',
        flag = 'Background_Image_Transparency',
        minimum_value = 0,
        maximum_value = 100,
        value = 50,
        round_number = true,
        callback = function(value)
            if not self._background then return end
            self._background.ImageTransparency = value / 100
            Library._config._flags['Background_Transparency'] = value / 100
        end,
    })

    local module_transparency_slider = image_module:create_slider({
        title = 'Module Transparency',
        flag = 'Background_Module_Transparency',
        minimum_value = 0,
        maximum_value = 100,
        value = 0,
        round_number = true,
        callback = function(value)
            set_module_transparency(value / 100)
        end,
    })

    local Image_Module_Frame = find_module_frame('Background')

    if Image_Module_Frame then
        local Options = Image_Module_Frame.Options

        local Row = Instance.new('Frame')
        Row.Name = 'AssetRow'
        Row.Size = UDim2.fromOffset(207, 26)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.LayoutOrder = 0
        Row.Parent = Options

        local Input = Instance.new('TextBox')
        Input.Name = 'AssetId'
        Input.AnchorPoint = Vector2.new(0, 0.5)
        Input.Position = UDim2.new(0, 0, 0.5, 0)
        Input.Size = UDim2.fromOffset(207, 24)
        Input.BackgroundColor3 = Theme.Control
        Input.BackgroundTransparency = 0.2
        Input.BorderSizePixel = 0
        Input.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Input.TextColor3 = Theme.Text
        Input.PlaceholderColor3 = Theme.TextDim
        Input.PlaceholderText = 'Asset ID or Image URL'
        Input.TextSize = 11
        Input.ClearTextOnFocus = false
        Input.ClipsDescendants = true
        Input.Text = Background_Image_Id
        Input.Parent = Row
        table.insert(self._elements, {obj = Input, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = Input, prop = "TextColor3", tKey = "Text"})
        table.insert(self._elements, {obj = Input, prop = "PlaceholderColor3", tKey = "TextDim"})

        Asset_Input = Input

        local InputCorner = Instance.new('UICorner')
        InputCorner.CornerRadius = UDim.new(0, 4)
        InputCorner.Parent = Input

        Input.FocusLost:Connect(function()
            local source = Input.Text:match('^%s*(.-)%s*$')
            Input.Text = source
            Background_Image_Id = source
            set_background_image(source)
            Library._config._flags['Background_Image_Id'] = source
            self:SetBackground(source, self._background.ImageTransparency)
        end)

        build_reset_button(Options, 4, function()
            Input.Text = ''
            Background_Image_Id = ''
            set_background_image('')
            preset_dropdown:update('None')
            transparency_slider:set_percentage(50)
            module_transparency_slider:set_percentage(0)
            Library._config._flags['Background_Image_Id'] = ''
            self:SetBackground('', 0.5)
        end)

        image_module._size = image_module._size + 66
        Options.Size = UDim2.fromOffset(241, image_module._size)

        if image_module._state then
            Image_Module_Frame.Size = UDim2.fromOffset(241, 93 + image_module._size + image_module._multiplier)
        end
    end

    set_background_image(Background_Image_Id)
    set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)

    local notif_module = InterfaceTab:create_module({
        title = 'Notifications',
        flag = 'UI_Notifications',
        description = 'Configure notification behavior',
        section = 'right',
        callback = function(state) end,
    })

    notif_module:create_dropdown({
        title = 'Side',
        flag = 'UI_Notif_Side',
        options = { 'Left', 'Right' },
        multi_dropdown = false,
        maximum_options = 2,
        callback = function(value)
            local side = (typeof(value) == "string" and value) or value.Name
            Library._notif_side = side
            UpdateNotificationPosition()
        end,
    })

    notif_module:create_slider({
        title = 'Opacity',
        flag = 'UI_Notif_Opacity',
        minimum_value = 0,
        maximum_value = 100,
        value = 0,
        round_number = true,
        callback = function(value)
            Library._notif_opacity = value / 100
        end,
    })

    local settings_module = InterfaceTab:create_module({
        title = 'Settings',
        flag = 'UI_Settings',
        description = 'UI Behavior and Overlay',
        section = 'left',
        callback = function(state) end,
    })

    -- ============================================================
    -- FIX #9: Hide on Minimize + Minimize Keybind
    -- ============================================================
    settings_module:create_checkbox({
        title = 'Hide on Minimize',
        flag = 'UI_Gui_Visible',
        callback = function(state) end,
    })

    local keybind_module = InterfaceTab:create_module({
        title = 'Minimize Key',
        flag = 'UI_Minimize_Key',
        description = 'Set the key that toggles the UI',
        section = 'left',
        callback = function(state) end,
    })

    local minimize_key_box
    minimize_key_box = keybind_module:create_textbox({
        title = 'Toggle Key (e.g. RightControl)',
        flag = 'Minimize_Keybind_Display',
        placeholder = 'RightControl',
        callback = function() end,
    })

    do
        local saved = Library._config._keybinds['Minimize_Keybind']
        local display = saved and string.gsub(tostring(saved), 'Enum.KeyCode.', '') or 'RightControl'
        minimize_key_box._text = display
        if minimize_key_box._textbox then
            pcall(function() minimize_key_box._textbox.Text = display end)
        end
    end

    keybind_module:create_button({
        title = 'Apply Key',
        callback = function()
            local raw = minimize_key_box._text or 'RightControl'
            local keycode = 'Enum.KeyCode.'..raw
            Library._config._keybinds['Minimize_Keybind'] = keycode
            Config:save(game.GameId, Library._config)
            Library:Notify({title = 'Minimize Key', text = 'Set to '..raw, duration = 3})
        end
    })

    keybind_module:create_button({
        title = 'Reset to Insert',
        callback = function()
            Library._config._keybinds['Minimize_Keybind'] = 'Enum.KeyCode.Insert'
            minimize_key_box._text = 'Insert'
            Config:save(game.GameId, Library._config)
            Library:Notify({title = 'Minimize Key', text = 'Reset to Insert', duration = 3})
        end
    })

    settings_module:create_checkbox({
        title = 'UI Toggle Keybind (Insert)',
        flag = 'UI_Gui_Toggle_Notify',
        callback = function(state) end
    })

    local OriginalSettings = {}
    local function FpsBooster(state)
        if state then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 1e9
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.fromRGB(140,140,140)
                Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140)
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
            end)
            for _,v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") then
                    if OriginalSettings[v] == nil then OriginalSettings[v] = v.Enabled end
                    v.Enabled = false
                elseif v:IsA("Atmosphere") then
                    if OriginalSettings[v] == nil then OriginalSettings[v] = v.Density end
                    v.Density = 0
                end
            end
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if OriginalSettings[obj] == nil then OriginalSettings[obj] = obj.CastShadow end
                    obj.CastShadow = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if OriginalSettings[obj] == nil then OriginalSettings[obj] = obj.Transparency end
                    obj.Transparency = 1
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    if OriginalSettings[obj] == nil then OriginalSettings[obj] = obj.Enabled end
                    obj.Enabled = false
                end
            end
        else
            pcall(function()
                Lighting.GlobalShadows = true
                Lighting.FogEnd = 100000
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.fromRGB(128, 128, 128)
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.EnvironmentDiffuseScale = 1
                Lighting.EnvironmentSpecularScale = 1
            end)
            for _,v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") then
                    if OriginalSettings[v] ~= nil then v.Enabled = OriginalSettings[v] end
                elseif v:IsA("Atmosphere") then
                    if OriginalSettings[v] ~= nil then v.Density = OriginalSettings[v] end
                end
            end
            for _,obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if OriginalSettings[obj] ~= nil then obj.CastShadow = OriginalSettings[obj] end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if OriginalSettings[obj] ~= nil then obj.Transparency = OriginalSettings[obj] end
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    if OriginalSettings[obj] ~= nil then obj.Enabled = OriginalSettings[obj] end
                end
            end
            table.clear(OriginalSettings)
        end
    end

    settings_module:create_checkbox({
        title = 'FPS Booster',
        flag = 'UI_FPS_Booster',
        callback = function(state) 
            FpsBooster(state)
        end,
    })

    local StatsOverlayState = {samples={}, maxSamples=24, ping=0, fps=0}
    
    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "TelemetryOverlay"
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = 99
    OverlayGui.Parent = CoreGui
    
    local GraphPanel = Instance.new("Frame")
    GraphPanel.Size = UDim2.new(0, 184, 0, 76)
    GraphPanel.Position = UDim2.new(0, 20, 0.5, -38)
    GraphPanel.BackgroundColor3 = Theme.Group
    GraphPanel.BorderSizePixel = 0
    GraphPanel.Active = true
    GraphPanel.Visible = false
    GraphPanel.Parent = OverlayGui
    table.insert(Library._elements, {obj = GraphPanel, prop = "BackgroundColor3", tKey = "Group"})
    
    local GraphPanelCorner = Instance.new("UICorner", GraphPanel)
    GraphPanelCorner.CornerRadius = UDim.new(0, 7)
    
    local GraphStroke = Instance.new("UIStroke", GraphPanel)
    GraphStroke.Color = Theme.GroupStroke
    GraphStroke.Transparency = 0.5
    GraphStroke.Thickness = 1
    table.insert(Library._elements, {obj = GraphStroke, prop = "Color", tKey = "GroupStroke"})
    
    local PingValue = Instance.new("TextLabel", GraphPanel)
    PingValue.Size = UDim2.new(0, 82, 0, 21)
    PingValue.Position = UDim2.new(1, -91, 0, 4)
    PingValue.BackgroundTransparency = 1
    PingValue.Font = Enum.Font.GothamBold
    PingValue.Text = "0 ms"
    PingValue.TextColor3 = Theme.Text
    PingValue.TextSize = 15
    PingValue.TextXAlignment = Enum.TextXAlignment.Right
    table.insert(Library._elements, {obj = PingValue, prop = "TextColor3", tKey = "Text"})
    
    local GraphArea = Instance.new("Frame", GraphPanel)
    GraphArea.Size = UDim2.new(1, -18, 0, 38)
    GraphArea.Position = UDim2.new(0, 9, 0, 32)
    GraphArea.BackgroundTransparency = 1
    GraphArea.BorderSizePixel = 0
    GraphArea.ClipsDescendants = true
    
    local Bars = {}
    for index = 1, StatsOverlayState.maxSamples do
        local Bar = Instance.new("Frame", GraphArea)
        Bar.AnchorPoint = Vector2.new(0, 1)
        Bar.Size = UDim2.new(0, 7, 0, 5)
        Bar.Position = UDim2.new(0, (index-1)*7, 1, -4)
        Bar.BackgroundColor3 = Theme.Accent
        Bar.BorderSizePixel = 0
        Bar.ZIndex = 2
        table.insert(Library._elements, {obj = Bar, prop = "BackgroundColor3", tKey = "Accent"})
        Bars[index] = Bar
    end

    local FpsPanel = Instance.new("Frame", OverlayGui)
    FpsPanel.Size = UDim2.new(0, 140, 0, 34)
    FpsPanel.Position = UDim2.new(0, 20, 0.5, 44)
    FpsPanel.BackgroundColor3 = Theme.Group
    FpsPanel.BorderSizePixel = 0
    FpsPanel.Active = true
    FpsPanel.Visible = false
    table.insert(Library._elements, {obj = FpsPanel, prop = "BackgroundColor3", tKey = "Group"})
    local FpsPanelCorner = Instance.new("UICorner", FpsPanel)
    FpsPanelCorner.CornerRadius = UDim.new(0, 12)
    
    local FpsStroke = Instance.new("UIStroke", FpsPanel)
    FpsStroke.Color = Theme.GroupStroke
    FpsStroke.Transparency = 0.5
    FpsStroke.Thickness = 1
    table.insert(Library._elements, {obj = FpsStroke, prop = "Color", tKey = "GroupStroke"})
    
    local FpsValue = Instance.new("TextLabel", FpsPanel)
    FpsValue.Size = UDim2.new(0, 68, 1, 0)
    FpsValue.Position = UDim2.new(0, 14, 0, 0)
    FpsValue.BackgroundTransparency = 1
    FpsValue.Font = Enum.Font.GothamBold
    FpsValue.Text = "0"
    FpsValue.TextColor3 = Theme.Accent
    FpsValue.TextSize = 24
    FpsValue.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(Library._elements, {obj = FpsValue, prop = "TextColor3", tKey = "Accent"})
    
    local FpsLabel = Instance.new("TextLabel", FpsPanel)
    FpsLabel.Size = UDim2.new(0, 48, 1, 0)
    FpsLabel.Position = UDim2.new(1, -58, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.Text = "FPS"
    FpsLabel.TextColor3 = Theme.TextDim
    FpsLabel.TextSize = 12
    table.insert(Library._elements, {obj = FpsLabel, prop = "TextColor3", tKey = "TextDim"})

    local graphDragging, graphDragStart, graphStartPos = false, nil, nil
    GraphPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            graphDragging = true
            graphDragStart = input.Position
            graphStartPos = GraphPanel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if graphDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - graphDragStart
            GraphPanel.Position = UDim2.new(graphStartPos.X.Scale, graphStartPos.X.Offset + delta.X, graphStartPos.Y.Scale, graphStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            graphDragging = false
        end
    end)

    local fpsDragging, fpsDragStart, fpsStartPos = false, nil, nil
    FpsPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fpsDragging = true
            fpsDragStart = input.Position
            fpsStartPos = FpsPanel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if fpsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - fpsDragStart
            FpsPanel.Position = UDim2.new(fpsStartPos.X.Scale, fpsStartPos.X.Offset + delta.X, fpsStartPos.Y.Scale, fpsStartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            fpsDragging = false
        end
    end)

    local frameCount, elapsed, updateElapsed = 0, 0, 0
    local player = game:GetService("Players").LocalPlayer

    RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        elapsed = elapsed + dt
        updateElapsed = updateElapsed + dt
        
        if elapsed >= 0.5 then
            StatsOverlayState.fps = math.round(frameCount/elapsed)
            frameCount = 0 
            elapsed = 0
            if FpsPanel.Visible then
                FpsValue.Text = tostring(StatsOverlayState.fps)
            end
        end
        
        if updateElapsed >= 0.5 then
            StatsOverlayState.ping = math.round(player:GetNetworkPing()*1000)
            if GraphPanel.Visible then
                PingValue.Text = tostring(StatsOverlayState.ping).." ms"
                table.insert(StatsOverlayState.samples, StatsOverlayState.ping)
                if #StatsOverlayState.samples > StatsOverlayState.maxSamples then 
                    table.remove(StatsOverlayState.samples, 1) 
                end
                for index, bar in ipairs(Bars) do
                    local sample = StatsOverlayState.samples[index] or 0
                    local height = math.clamp(5 + sample/38, 5, 10)
                    bar.Size = UDim2.new(0, 7, 0, height)
                end
            end
            updateElapsed = 0
        end
    end)

    settings_module:create_checkbox({
        title = 'Show FPS',
        flag = 'UI_Show_Fps',
        callback = function(state)
            FpsPanel.Visible = state
        end,
    })

    settings_module:create_checkbox({
        title = 'Show Ping',
        flag = 'UI_Show_Ping',
        callback = function(state)
            GraphPanel.Visible = state
        end,
    })

    -- ============================================================
    -- FIX #11: Keybind list overlay
    -- ============================================================
    local KeybindOverlayGui = Instance.new("ScreenGui")
    KeybindOverlayGui.Name = "KeybindOverlay"
    KeybindOverlayGui.ResetOnSpawn = false
    KeybindOverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeybindOverlayGui.IgnoreGuiInset = true
    KeybindOverlayGui.Enabled = false
    KeybindOverlayGui.Parent = CoreGui

    local KeybindFrame = Instance.new("Frame")
    KeybindFrame.Name = "OverlayFrame"
    KeybindFrame.Size = UDim2.new(0, 220, 0, 38)
    KeybindFrame.Position = UDim2.new(0, 20, 0.5, -19)
    KeybindFrame.BackgroundColor3 = Theme.Group
    KeybindFrame.BackgroundTransparency = 0.12
    KeybindFrame.BorderSizePixel = 0
    KeybindFrame.Parent = KeybindOverlayGui
    table.insert(Library._elements, {obj = KeybindFrame, prop = "BackgroundColor3", tKey = "Group"})

    local KFCorner = Instance.new("UICorner", KeybindFrame)
    KFCorner.CornerRadius = UDim.new(0, 7)

    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Theme.GroupStroke
    frameBorder.Thickness = 1
    frameBorder.Parent = KeybindFrame
    table.insert(Library._elements, {obj = frameBorder, prop = "Color", tKey = "GroupStroke"})

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 34)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Theme.Group
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = KeybindFrame
    table.insert(Library._elements, {obj = header, prop = "BackgroundColor3", tKey = "Group"})

    local HCorner = Instance.new("UICorner", header)
    HCorner.CornerRadius = UDim.new(0, 7)

    local headerDivider = Instance.new("Frame")
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Position = UDim2.new(0, 0, 1, -1)
    headerDivider.BackgroundColor3 = Theme.GroupStroke
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 3
    headerDivider.Parent = header
    table.insert(Library._elements, {obj = headerDivider, prop = "BackgroundColor3", tKey = "GroupStroke"})

    local keyboardIcon = Instance.new("ImageLabel")
    keyboardIcon.Size = UDim2.new(0, 16, 0, 16)
    keyboardIcon.Position = UDim2.new(0, 10, 0.5, -8)
    keyboardIcon.BackgroundTransparency = 1
    keyboardIcon.Image = "rbxassetid://81598136527047"
    keyboardIcon.ImageColor3 = Theme.Accent
    keyboardIcon.ZIndex = 3
    keyboardIcon.Parent = header
    table.insert(Library._elements, {obj = keyboardIcon, prop = "ImageColor3", tKey = "Accent"})

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -36, 1, 0)
    headerLabel.Position = UDim2.new(0, 32, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "KEYBINDS"
    headerLabel.TextColor3 = Theme.Accent
    headerLabel.TextSize = 10
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.ZIndex = 3
    headerLabel.Parent = header
    table.insert(Library._elements, {obj = headerLabel, prop = "TextColor3", tKey = "Accent"})

    local dragging = false
    local dragStart = nil
    local startPos = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = KeybindFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            KeybindFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local lastBindCount = 0
    local keybindUpdateTimer = 0

    local function RefreshKeybindOverlay()
        for _, child in ipairs(KeybindFrame:GetChildren()) do
            if child.Name == "Row" or child.Name == "Divider" then child:Destroy() end
        end
        
        local validBinds = {}
        for flag, key in pairs(Library._config._keybinds) do
            if flag ~= 'Minimize_Keybind' then
                local title = Library._keybind_list[flag] or flag
                table.insert(validBinds, {flag = flag, title = title, key = string.gsub(tostring(key), "Enum.KeyCode.", "")})
            end
        end
        
        table.sort(validBinds, function(a, b) return a.title < b.title end)
        
        local yBase = 38
        for i, bind in ipairs(validBinds) do
            if i > 1 then
                local div = Instance.new("Frame")
                div.Name = "Divider"
                div.Size = UDim2.new(1, -20, 0, 1)
                div.Position = UDim2.new(0, 10, 0, yBase)
                div.BackgroundColor3 = Theme.GroupStroke
                div.BorderSizePixel = 0
                div.Parent = KeybindFrame
                table.insert(Library._elements, {obj = div, prop = "BackgroundColor3", tKey = "GroupStroke"})
            end
            
            local row = Instance.new("Frame")
            row.Name = "Row"
            row.Size = UDim2.new(1, -18, 0, 28)
            row.Position = UDim2.new(0, 9, 0, yBase + 1)
            row.BackgroundTransparency = 1
            row.Parent = KeybindFrame
            
            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(1, -40, 1, 0)
            labelText.Position = UDim2.new(0, 0, 0, 0)
            labelText.BackgroundTransparency = 1
            labelText.Text = bind.title
            labelText.TextColor3 = Theme.TextDim
            labelText.TextSize = 13
            labelText.Font = Enum.Font.GothamSemibold
            labelText.TextXAlignment = Enum.TextXAlignment.Left
            labelText.Parent = row
            table.insert(Library._elements, {obj = labelText, prop = "TextColor3", tKey = "TextDim"})
            
            local keyText = Instance.new("TextLabel")
            keyText.Size = UDim2.new(0, 32, 1, 0)
            keyText.Position = UDim2.new(1, -32, 0, 0)
            keyText.BackgroundTransparency = 1
            keyText.Text = "[" .. bind.key .. "]"
            keyText.TextColor3 = Theme.Accent
            keyText.TextSize = 12
            keyText.Font = Enum.Font.GothamBold
            keyText.TextXAlignment = Enum.TextXAlignment.Right
            keyText.Parent = row
            table.insert(Library._elements, {obj = keyText, prop = "TextColor3", tKey = "Accent"})
            
            yBase = yBase + 30
        end
        KeybindFrame.Size = UDim2.new(0, 220, 0, 38 + (#validBinds * 30))
        lastBindCount = #validBinds
    end

    RunService.RenderStepped:Connect(function(dt)
        if not KeybindOverlayGui.Enabled then return end
        keybindUpdateTimer += dt
        if keybindUpdateTimer >= 0.3 then
            keybindUpdateTimer = 0
            local currentCount = 0
            for flag, key in pairs(Library._config._keybinds) do
                if flag ~= 'Minimize_Keybind' then
                    currentCount += 1
                end
            end
            if currentCount ~= lastBindCount then
                RefreshKeybindOverlay()
            end
        end
    end)

    settings_module:create_checkbox({
        title = 'Keybinds List',
        flag = 'UI_Show_Keybinds',
        callback = function(state)
            KeybindOverlayGui.Enabled = state
            if state then
                RefreshKeybindOverlay()
            end
        end,
    })

    return InterfaceTab
end

return Library

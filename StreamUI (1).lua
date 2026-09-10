-- ═══════════════════════════════════════════════════════════════
--  Ailon UI — full library with built-in Interface tab
--  Original Ailon layout preserved. All Blade Ball game logic removed.
--  Includes: Configurations, Appearance, Background (URL+preset),
--  UI Transparency, Settings, Notifications, Minimize Key.
-- ═══════════════════════════════════════════════════════════════

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))
local GuiService = cloneref(game:GetService('GuiService'))
local Workspace = cloneref(game:GetService('Workspace'))

local mouse = Players.LocalPlayer:GetMouse()
local LocalPlayer = Players.LocalPlayer

local old_ailon = CoreGui:FindFirstChild('ailon')
if old_ailon then Debris:AddItem(old_ailon, 0) end

if not isfolder("ailon") then makefolder("ailon") end
if not isfolder("ailon/Configs") then makefolder("ailon/Configs") end
if not isfolder("ailon/Backgrounds") then makefolder("ailon/Backgrounds") end

local function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

local function convertTableToString(inputTable)
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

local Util = setmetatable({
    map = function(self, value, in_minimum, in_maximum, out_minimum, out_maximum)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self, location, distance)
        local unit_ray = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self)
        local viewport_size_Y = Workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object)
    local self = setmetatable({ _object = object, _folder = nil, _frame = nil, _root = nil }, AcrylicBlur)
    self:setup()
    return self
end

function AcrylicBlur:create_folder()
    local old_folder = Workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old_folder then Debris:AddItem(old_folder, 0) end
    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = Workspace.CurrentCamera
    self._folder = folder
end

function AcrylicBlur:create_depth_of_fields()
    local dof = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    dof.FarIntensity = 0
    dof.FocusDistance = 0.05
    dof.InFocusRadius = 0.1
    dof.NearIntensity = 1
    dof.Name = 'AcrylicBlur'
    dof.Parent = Lighting
    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then continue end
        if object == dof then continue end
        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)
        object.FarIntensity = 0
    end
end

function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object
    self._frame = frame
end

function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder
    local mesh = Instance.new('SpecialMesh')
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Offset = Vector3.new(0, 0, -0.000001)
    mesh.Parent = part
    self._root = part
end

function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    self:create_frame()
    self:render(0.001)
    self:check_quality_level()
end

function AcrylicBlur:render(distance)
    local positions = { top_left = Vector2.new(), top_right = Vector2.new(), bottom_right = Vector2.new() }
    local function update_positions(size, position)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end
    local function update()
        local tl, tr, br = positions.top_left, positions.top_right, positions.bottom_right
        local tl3 = Util:viewport_point_to_world(tl, distance)
        local tr3 = Util:viewport_point_to_world(tr, distance)
        local br3 = Util:viewport_point_to_world(br, distance)
        if not self._root then return end
        local w = (tr3 - tl3).Magnitude
        local h = (tr3 - br3).Magnitude
        self._root.CFrame = CFrame.fromMatrix((tl3 + br3) / 2,
            Workspace.CurrentCamera.CFrame.XVector,
            Workspace.CurrentCamera.CFrame.YVector,
            Workspace.CurrentCamera.CFrame.ZVector)
        local mesh = self._root:FindFirstChildOfClass('SpecialMesh')
        if mesh then mesh.Scale = Vector3.new(w, h, 0) end
    end
    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        update_positions(size, position)
        task.spawn(update)
    end
    Connections['cframe_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = Workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)
    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    task.spawn(update)
end

function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value
    if quality_level < 8 then self:change_visiblity(false) end
    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local gs = UserSettings().GameSettings
        self:change_visiblity(gs.SavedQualityLevel.Value >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state)
    self._root.Transparency = state and 0.98 or 1
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local ok, result = pcall(function()
            writefile('ailon/'..file_name..'.json', HttpService:JSONEncode(config))
        end)
        if not ok then warn('failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local ok, result = pcall(function()
            if not isfile('ailon/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('ailon/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not ok then warn('failed to load config', result) end
        if not result then result = { _flags = {}, _keybinds = {}, _library = {} } end
        return result
    end
}, Config)

local DefaultTheme = {
    Background = Color3.fromRGB(0, 0, 0),
    Group = Color3.fromRGB(10, 10, 10),
    GroupStroke = Color3.fromRGB(100, 100, 100),
    Control = Color3.fromRGB(30, 30, 30),
    ControlHover = Color3.fromRGB(50, 50, 50),
    Divider = Color3.fromRGB(60, 60, 60),
    Text = Color3.fromRGB(200, 200, 200),
    TextDim = Color3.fromRGB(150, 150, 150),
    TextSoft = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(255, 255, 255),
    Gradient = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
}

local Theme = {}
for k, v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v
end

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {}, _library = {} }),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _flag_registry = {},
    _keybind_registry = {},
    _elements = {},
    _notif_side = "Right",
    _notif_opacity = 0.0,
    _keybind_list = {},
    _background = nil,
    _container = nil,
    _handler = nil
}
Library.__index = Library
Library.Connections = Connections

function Library.new()
    local self = setmetatable({ _tab = 0 }, Library)
    self:create_ui()
    return self
end

-- ═══════════════════════════════════════════════════════════════
--  Notifications
-- ═══════════════════════════════════════════════════════════════
local NotificationHost = Instance.new("ScreenGui")
NotificationHost.Name = "ailonNotifications"
NotificationHost.ResetOnSpawn = false
NotificationHost.IgnoreGuiInset = true
NotificationHost.DisplayOrder = 101
NotificationHost.Parent = CoreGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = NotificationHost
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.FillDirection = Enum.FillDirection.Vertical
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 8)
UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout_Notif.Parent = NotificationContainer

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
    InnerFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    InnerFrame.BackgroundTransparency = Library._notif_opacity
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification
    table.insert(Library._elements, {obj = InnerFrame, prop = "BackgroundColor3", tKey = "Group"})

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = Theme.Gradient
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Theme.GroupStroke
    InnerStroke.Transparency = 0.55
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
        TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(settings.duration or 5)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(Library._notif_side == "Left" and 1 or -1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library:get_screen_scale()
    self._ui_scale = Workspace.CurrentCamera.ViewportSize.X / 1400
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

function Library:remove_table_value(t, value)
    for i, v in t do
        if v ~= value then continue end
        table.remove(t, i)
    end
end

function Library:hexToRGB(hex)
    hex = hex:gsub("#","")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
end

function Library:rgbToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
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

function Library:GetColor(key)
    return Theme[key]
end

-- ═══════════════════════════════════════════════════════════════
--  Background resolution (URL + rbxassetid + local file)
-- ═══════════════════════════════════════════════════════════════
local function resolve_background(source)
    if not source or source == '' then return '' end
    source = tostring(source):match('^%s*(.-)%s*$')
    if source == '' then return '' end
    if source:match('^%d+$')      then return 'rbxassetid://'..source end
    if source:match('^rbx%a+://') then return source end

    local Custom_Asset = getcustomasset or getsynasset
    if not Custom_Asset then return '' end

    if source:match('^https?://') then
        if not (writefile and isfile and isfolder) then return '' end
        if not isfolder('ailon/Backgrounds') then makefolder('ailon/Backgrounds') end
        local extension = source:match('%.(%a%a%a%a?)[%?#]')
                    or source:match('%.(%a%a%a%a?)$')
                    or 'png'
        local path = 'ailon/Backgrounds/'..source:gsub('%W',''):sub(-48)..'.'..extension
        if not isfile(path) then
            local ok, body = pcall(game.HttpGet, game, source, true)
            if not ok then return '' end
            writefile(path, body)
        end
        local ok, result = pcall(Custom_Asset, path)
        if ok and result then return result end
        return ''
    end

    if isfile(source) then
        local ok, result = pcall(Custom_Asset, source)
        if ok and result then return result end
    end
    return ''
end

function Library:SetBackground(source, transparency)
    if not self._background then return end
    local resolved = resolve_background(source)
    if resolved ~= '' then
        self._background.Image = resolved
        self._background.Visible = true
    else
        self._background.Image = ''
        self._background.Visible = false
    end
    if transparency ~= nil then
        self._background.ImageTransparency = transparency
    end
    Library._config._flags['Background_Image'] = type(source) == "string" and source or ''
    Library._config._flags['Background_Transparency'] = transparency or 0.5
    Config:save(game.GameId, Library._config)
end

function Library:SaveConfig()
    pcall(function()
        if writefile then
            local data = { Theme = {} }
            for k, v in pairs(Theme) do
                if typeof(v) == "Color3" then
                    data.Theme[k] = self:rgbToHex(v)
                end
            end
            writefile("ailon/UI_Config.json", HttpService:JSONEncode(data))
        end
    end)
end

function Library:LoadConfig()
    pcall(function()
        if isfile and isfile("ailon/UI_Config.json") then
            local saved = readfile("ailon/UI_Config.json")
            if saved then
                local data = HttpService:JSONDecode(saved)
                if data.Theme then
                    for k, v in pairs(data.Theme) do
                        if DefaultTheme[k] then
                            self:SetColor(k, self:hexToRGB(v))
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  UI Construction
-- ═══════════════════════════════════════════════════════════════
function Library:create_ui()
    local old = CoreGui:FindFirstChild('ailon')
    if old then Debris:AddItem(old, 0) end

    local ailon = Instance.new('ScreenGui')
    ailon.ResetOnSpawn = false
    ailon.Name = 'ailon'
    ailon.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ailon.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05
    Container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = ailon
    self._container = Container
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

    local ContainerGradient = Instance.new('UIGradient')
    ContainerGradient.Color = Theme.Gradient
    ContainerGradient.Rotation = 45
    ContainerGradient.Parent = Container

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Theme.GroupStroke
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.Parent = Container
    self._background = Background

    local BgCorner = Instance.new('UICorner')
    BgCorner.CornerRadius = UDim.new(0, 12)
    BgCorner.Parent = Background

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 680, 0, 460)
    Handler.BorderSizePixel = 0
    Handler.ZIndex = 1
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
    Tabs.ZIndex = 2
    Tabs.Parent = Handler

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(200, 200, 200)
    ClientName.Text = 'Ailon'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 45, 0, 18)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.07, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextSize = 16
    ClientName.ZIndex = 2
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "Text"})

    local ClientNameGradient = Instance.new('UIGradient')
    ClientNameGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
    }
    ClientNameGradient.Parent = ClientName

    task.spawn(function()
        while ClientName and ClientName.Parent do
            ClientNameGradient.Offset = Vector2.new(math.sin(os.clock() * 1.5), 0)
            task.wait()
        end
    end)

    local TopDivider = Instance.new('Frame')
    TopDivider.Name = 'TopDivider'
    TopDivider.Size = UDim2.new(0.85, 0, 0, 1)
    TopDivider.Position = UDim2.new(0.5, 0, 0, 36)
    TopDivider.AnchorPoint = Vector2.new(0.5, 0)
    TopDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TopDivider.BorderSizePixel = 0
    TopDivider.ZIndex = 2
    TopDivider.Parent = Handler
    table.insert(Library._elements, {obj = TopDivider, prop = "BackgroundColor3", tKey = "Divider"})

    local TopDividerGradient = Instance.new('UIGradient')
    TopDividerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    TopDividerGradient.Parent = TopDivider

    local SideDivider = Instance.new('Frame')
    SideDivider.Name = 'SideDivider'
    SideDivider.Size = UDim2.new(0, 2, 0, 340)
    SideDivider.Position = UDim2.new(0.235, 0, 0.5, 0)
    SideDivider.AnchorPoint = Vector2.new(0.5, 0.5)
    SideDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SideDivider.BorderSizePixel = 0
    SideDivider.ZIndex = 2
    SideDivider.Parent = Handler
    table.insert(Library._elements, {obj = SideDivider, prop = "BackgroundColor3", tKey = "Divider"})

    local SideDividerCorner = Instance.new('UICorner')
    SideDividerCorner.CornerRadius = UDim.new(1, 0)
    SideDividerCorner.Parent = SideDivider

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://138719305710506'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 24, 0, 24)
    Icon.ZIndex = 2
    Icon.Parent = Handler
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "Text"})

    local IconGradient = Instance.new('UIGradient')
    IconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
    }
    IconGradient.Parent = Icon

    task.spawn(function()
        while Icon and Icon.Parent do
            IconGradient.Offset = Vector2.new(math.sin(os.clock() * 1.5), 0)
            task.wait()
        end
    end)

    local Minimize = Instance.new('TextButton')
    Minimize.Name = 'Minimize'
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.02, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.ZIndex = 3
    Minimize.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    self._ui = ailon

    local function on_drag(input)
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
        Container.Position = UDim2.new(
            self._container_position.X.Scale, self._container_position.X.Offset + delta.X,
            self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
    end
    local function drag(input)
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
        ailon.Enabled = not ailon.Enabled
    end

    function self:change_visiblity(state)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    function self:load()
        local content = {}
        for _, object in ailon:GetDescendants() do
            if not object:IsA('ImageLabel') then continue end
            table.insert(content, object)
        end
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections['ui_scale'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end

        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(680, 460)
        }):Play()

        AcrylicBlur.new(Container)

        -- restore theme + bg
        for key, _ in pairs(DefaultTheme) do
            local saved = Library._config._flags['Theme_'..key]
            if saved then self:SetColor(key, self:hexToRGB(saved)) end
        end
        local saved_bg = Library._config._flags['Background_Image']
        if typeof(saved_bg) == "string" and saved_bg ~= '' then
            self:SetBackground(saved_bg, Library._config._flags['Background_Transparency'] or 0.5)
        end

        self._ui_loaded = true
    end

    function self:update_tabs(tab)
        for _, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then continue end
            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()
                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Color3.fromRGB(200, 200, 200)
                    }):Play()
                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Color3.fromRGB(200, 200, 200)
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
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
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

    function self:create_tab(title, icon, visible)
        if visible == nil then visible = true end
        local TabManager = {}

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        Tab.ZIndex = 2
        Tab.Parent = Tabs
        Tab.Visible = visible
        Tab.LayoutOrder = self._tab
        table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Group"})

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Tab

        local TabGradient = Instance.new('UIGradient')
        TabGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
        }
        TabGradient.Rotation = 90
        TabGradient.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.24, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextSize = 13
        TextLabel.ZIndex = 3
        TextLabel.Parent = Tab
        table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})

        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel

        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.8
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.1, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon or ''
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.ZIndex = 3
        Icon.Parent = Tab
        table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextDim"})

        Tab.MouseEnter:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.4}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.4}):Play()
            end
        end)
        Tab.MouseLeave:Connect(function()
            if Tab.BackgroundTransparency ~= 0.5 then
                TweenService:Create(TextLabel, TweenInfo.new(0.3), {TextTransparency = 0.7}):Play()
                TweenService:Create(Icon, TweenInfo.new(0.3), {ImageTransparency = 0.8}):Play()
            end
        end)

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 374)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.259, 0, 0.5, 0)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.ZIndex = 2
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
        RightSection.Size = UDim2.new(0, 243, 0, 374)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.629, 0, 0.5, 0)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.ZIndex = 2
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

        function TabManager:SetVisible(state)
            Tab.Visible = state
        end

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = { _state = false, _locked = false, _size = 0, _multiplier = 0 }

            local SectionFrame = (settings.section == 'right') and RightSection or LeftSection

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            Module.ZIndex = 2
            Module.Parent = SectionFrame
            table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(100, 100, 100)
            UIStroke.Transparency = 0.7
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.ZIndex = 3
            Header.Parent = Module

            local LockButton = Instance.new('ImageButton')
            LockButton.Name = 'LockButton'
            LockButton.Size = UDim2.new(0, 13, 0, 13)
            LockButton.AnchorPoint = Vector2.new(1, 0)
            LockButton.Position = UDim2.new(1, -6, 0, 6)
            LockButton.BackgroundTransparency = 1
            LockButton.Image = 'rbxassetid://12060512624'
            LockButton.ImageColor3 = Color3.fromRGB(150, 150, 150)
            LockButton.ZIndex = 10
            LockButton.Parent = Header
            table.insert(Library._elements, {obj = LockButton, prop = "ImageColor3", tKey = "TextDim"})

            local function updateLockVisual()
                if ModuleManager._locked then
                    LockButton.ImageColor3 = Color3.fromRGB(255, 65, 65)
                else
                    LockButton.ImageColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
            local function setModuleInteractable(state)
                for _, desc in ipairs(Module:GetDescendants()) do
                    if desc == LockButton then continue end
                    if desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextBox") then
                        desc.Active = state
                        desc.Selectable = state
                        if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                            desc.AutoButtonColor = state
                        end
                    end
                end
            end
            LockButton.MouseButton1Click:Connect(function()
                ModuleManager._locked = not ModuleManager._locked
                updateLockVisual()
                setModuleInteractable(not ModuleManager._locked)
            end)
            LockButton.MouseEnter:Connect(function()
                TweenService:Create(LockButton, TweenInfo.new(0.15), {
                    ImageColor3 = ModuleManager._locked and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(220, 220, 220)
                }):Play()
            end)
            LockButton.MouseLeave:Connect(updateLockVisual)
            updateLockVisual()

            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(200, 200, 200)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.7
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.071, 0, 0.82, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.ZIndex = 4
            Icon.Parent = Header
            table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "Text"})

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(200, 200, 200)
            ModuleName.TextTransparency = 0.2
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.073, 0, 0.24, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.TextSize = 13
            ModuleName.ZIndex = 4
            ModuleName.Parent = Header
            table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "Text"})

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(200, 200, 200)
            Description.TextTransparency = 0.7
            Description.Text = settings.description or ''
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.073, 0, 0.42, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.TextSize = 10
            Description.ZIndex = 4
            Description.Parent = Header
            table.insert(Library._elements, {obj = Description, prop = "TextColor3", tKey = "Text"})

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.7
            Toggle.Position = UDim2.new(0.82, 0, 0.757, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.ZIndex = 4
            Toggle.Parent = Header
            table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Background"})

            local ToggleCorner = Instance.new('UICorner')
            ToggleCorner.CornerRadius = UDim.new(1, 0)
            ToggleCorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.2
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.ZIndex = 5
            Circle.Parent = Toggle
            table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})

            local CircleCorner = Instance.new('UICorner')
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle

            local Keybind = Instance.new('TextButton')
            Keybind.Name = 'Keybind'
            Keybind.AutoButtonColor = false
            Keybind.Text = ''
            Keybind.BackgroundTransparency = 0.7
            Keybind.Position = UDim2.new(0.15, 0, 0.735, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
            Keybind.ZIndex = 4
            Keybind.Parent = Header
            table.insert(Library._elements, {obj = Keybind, prop = "BackgroundColor3", tKey = "Accent"})

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 3)
            KeybindCorner.Parent = Keybind

            local KeybindText = Instance.new('TextLabel')
            KeybindText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KeybindText.TextColor3 = Color3.fromRGB(209, 222, 255)
            KeybindText.Text = 'None'
            KeybindText.AnchorPoint = Vector2.new(0.5, 0.5)
            KeybindText.Size = UDim2.new(0, 25, 0, 13)
            KeybindText.BackgroundTransparency = 1
            KeybindText.TextXAlignment = Enum.TextXAlignment.Center
            KeybindText.Position = UDim2.new(0.5, 0, 0.5, 0)
            KeybindText.TextSize = 10
            KeybindText.ZIndex = 5
            KeybindText.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindText, prop = "TextColor3", tKey = "Text"})

            local Divider = Instance.new('Frame')
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Divider.ZIndex = 4
            Divider.Parent = Header
            table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})

            local Divider2 = Instance.new('Frame')
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.5
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            Divider2.ZIndex = 4
            Divider2.Parent = Header
            table.insert(Library._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "Divider"})

            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.ZIndex = 3
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout_Opts = Instance.new('UIListLayout')
            UIListLayout_Opts.Padding = UDim.new(0, 5)
            UIListLayout_Opts.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_Opts.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Opts.Parent = Options

            function ModuleManager:refresh_size()
                Module.Size = UDim2.fromOffset(241, self._state and (93 + self._size + self._multiplier) or 93)
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)
            end

            function ModuleManager:change_state(state)
                self._state = state
                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(160, 160, 160),
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)
                if settings.callback then settings.callback(self._state) end
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then return end
                Library._keybind_list[settings.flag] = settings.title or "Module"
                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
                    if ModuleManager._locked then return end
                    if process then return end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then return end
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty)
                if Library._config._keybinds[settings.flag] and not empty then
                    local s = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    local fp = Instance.new('GetTextBoundsParams')
                    fp.Text = s
                    fp.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    fp.Size = 10
                    fp.Width = 10000
                    local fs = TextService:GetTextBoundsAsync(fp)
                    Keybind.Size = UDim2.fromOffset(fs.X + 6, 15)
                    KeybindText.Size = UDim2.fromOffset(fs.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    KeybindText.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library._config._flags[settings.flag] == nil then
                Library._config._flags[settings.flag] = false
            end
            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                if settings.callback then settings.callback(ModuleManager._state) end
                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                    Circle.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                    Circle.Position = UDim2.fromScale(0.53, 0.5)
                end
            end

            if Library._config._keybinds[settings.flag] then
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
                KeybindText.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
            end

            Library._keybind_registry[settings.flag] = function(key)
                if key then
                    KeybindText.Text = string.gsub(tostring(key), 'Enum.KeyCode.', '')
                    Library._keybind_list[settings.flag] = settings.title or "Module"
                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                    end
                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                else
                    KeybindText.Text = 'None'
                    Library._keybind_list[settings.flag] = nil
                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end
                    ModuleManager:scale_keybind(true)
                end
            end

            Keybind.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                Library._choosing_keybind = true
                KeybindText.Text = '...'
                Keybind.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

                local choose_conn, cancel_conn
                local function finish()
                    Library._choosing_keybind = false
                    Keybind.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
                    if Library._config._keybinds[settings.flag] then
                        KeybindText.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    else
                        KeybindText.Text = 'None'
                    end
                    if choose_conn then choose_conn:Disconnect() end
                    if cancel_conn then cancel_conn:Disconnect() end
                end

                task.defer(function()
                    choose_conn = UserInputService.InputBegan:Connect(function(input, process)
                        if process then return end
                        if input.KeyCode == Enum.KeyCode.Unknown then return end
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[settings.flag] = nil
                            Library._keybind_list[settings.flag] = nil
                            if Connections[settings.flag..'_keybind'] then
                                Connections[settings.flag..'_keybind']:Disconnect()
                                Connections[settings.flag..'_keybind'] = nil
                            end
                        else
                            Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                            Library._keybind_list[settings.flag] = settings.title or "Module"
                            if Connections[settings.flag..'_keybind'] then
                                Connections[settings.flag..'_keybind']:Disconnect()
                                Connections[settings.flag..'_keybind'] = nil
                            end
                            ModuleManager:connect_keybind()
                            ModuleManager:scale_keybind()
                        end
                        Config:save(game.GameId, Library._config)
                        finish()
                    end)
                    cancel_conn = UserInputService.InputBegan:Connect(function(input, process)
                        if process then return end
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            finish()
                        end
                    end)
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local PM = {}
                if self._size == 0 then self._size = 11 end
                self._size += s.customScale or 70
                ModuleManager:refresh_size()

                local P = Instance.new('Frame')
                P.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                P.BackgroundTransparency = 0.1
                P.Size = UDim2.new(0, 207, 0, 30)
                P.BorderSizePixel = 0
                P.AutomaticSize = Enum.AutomaticSize.Y
                P.ZIndex = 4
                P.Parent = Options
                P.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = P, prop = "BackgroundColor3", tKey = "Control"})

                local PC = Instance.new('UICorner')
                PC.CornerRadius = UDim.new(0, 4)
                PC.Parent = P

                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(210, 210, 210)
                Title.Text = s.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.ZIndex = 5
                Title.Parent = P
                table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
                Body.Text = s.text or "Paragraph"
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.ZIndex = 5
                Body.Parent = P
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

                P.MouseEnter:Connect(function()
                    TweenService:Create(P, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
                end)
                P.MouseLeave:Connect(function()
                    TweenService:Create(P, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
                end)

                return PM
            end

            function ModuleManager:create_checkbox(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local CM = { _state = false }
                if self._size == 0 then self._size = 11 end
                self._size += 20
                ModuleManager:refresh_size()

                local Checkbox = Instance.new("TextButton")
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.ZIndex = 4
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 11
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = s.title or "Checkbox"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.ZIndex = 5
                TitleLabel.Parent = Checkbox
                table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.ZIndex = 5
                KeybindBox.Parent = Checkbox

                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 6)
                KeybindCorner.Parent = KeybindBox

                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[s.flag]
                    and string.gsub(tostring(Library._config._keybinds[s.flag]), "Enum.KeyCode.", "")
                    or "..."
                KeybindLabel.ZIndex = 6
                KeybindLabel.Parent = KeybindBox

                local Box = Instance.new("Frame")
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Box.ZIndex = 5
                Box.Parent = Checkbox
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Accent"})

                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 6)
                BoxCorner.Parent = Box

                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.ZIndex = 6
                Fill.Parent = Box
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill

                function CM:change_state(state)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[s.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    if s.callback then s.callback(self._state) end
                end

                if Library._config._flags[s.flag] == nil then
                    Library._config._flags[s.flag] = false
                end
                if Library:flag_type(s.flag, "boolean") then
                    CM:change_state(Library._config._flags[s.flag])
                end

                Checkbox.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    CM:change_state(not CM._state)
                end)

                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if ModuleManager._locked then return end
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[s.flag] = nil
                            Library._keybind_list[s.flag] = nil
                            KeybindLabel.Text = "..."
                            if Connections[s.flag .. "_keybind"] then
                                Connections[s.flag .. "_keybind"]:Disconnect()
                                Connections[s.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
                        chooseConnection:Disconnect()
                        Library._config._keybinds[s.flag] = tostring(keyInput.KeyCode)
                        Library._keybind_list[s.flag] = s.title or "Checkbox"
                        Config:save(game.GameId, Library._config)
                        if Connections[s.flag .. "_keybind"] then
                            Connections[s.flag .. "_keybind"]:Disconnect()
                            Connections[s.flag .. "_keybind"] = nil
                        end
                        Library._choosing_keybind = false
                        KeybindLabel.Text = string.gsub(tostring(Library._config._keybinds[s.flag]), "Enum.KeyCode.", "")
                    end)
                end)

                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if ModuleManager._locked then return end
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[s.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CM:change_state(not CM._state)
                        end
                    end
                end)
                Connections[s.flag .. "_keypress"] = keyPressConnection

                Library._flag_registry[s.flag] = function(state) CM:change_state(state) end
                return CM
            end

            function ModuleManager:create_button(s)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 29
                ModuleManager:refresh_size()

                local Holder = Instance.new('Frame')
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Btn = Instance.new('TextButton')
                Btn.AnchorPoint = Vector2.new(0, 1)
                Btn.Position = UDim2.new(0, 0, 1, 0)
                Btn.Size = UDim2.fromOffset(207, 22)
                Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                Btn.BorderSizePixel = 0
                Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                Btn.TextSize = 12
                Btn.AutoButtonColor = false
                Btn.Text = s.title or 'Button'
                Btn.ZIndex = 5
                Btn.Parent = Holder
                table.insert(Library._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Btn, prop = "TextColor3", tKey = "Text"})

                local Corner = Instance.new('UICorner')
                Corner.CornerRadius = UDim.new(0, 4)
                Corner.Parent = Btn

                local Stroke = Instance.new('UIStroke')
                Stroke.Color = Color3.fromRGB(100, 100, 100)
                Stroke.Transparency = 0.72
                Stroke.Thickness = 1
                Stroke.Parent = Btn
                table.insert(Library._elements, {obj = Stroke, prop = "Color", tKey = "GroupStroke"})

                Btn.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    if s.callback then s.callback() end
                end)
            end

            function ModuleManager:create_textbox(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local TM = { _text = "" }
                if self._size == 0 then self._size = 11 end
                self._size += 32
                ModuleManager:refresh_size()

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextTransparency = 0.2
                Label.Text = s.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 10
                Label.ZIndex = 5
                Label.Parent = Options
                Label.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})

                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.PlaceholderText = s.placeholder or "Enter text..."
                Textbox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
                Textbox.Text = Library._config._flags[s.flag] or ""
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.ZIndex = 5
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Textbox, prop = "TextColor3", tKey = "Text"})
                table.insert(Library._elements, {obj = Textbox, prop = "PlaceholderColor3", tKey = "TextDim"})

                local UC = Instance.new('UICorner')
                UC.CornerRadius = UDim.new(0, 4)
                UC.Parent = Textbox

                function TM:update_text(text)
                    self._text = text
                    Library._config._flags[s.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    if s.callback then s.callback(self._text) end
                end

                if Library:flag_type(s.flag, 'string') then
                    TM:update_text(Library._config._flags[s.flag])
                end

                Textbox.FocusLost:Connect(function()
                    if ModuleManager._locked then return end
                    TM:update_text(Textbox.Text)
                end)

                Library._flag_registry[s.flag] = function(v) Textbox.Text = v or '' end
                return TM
            end

            function ModuleManager:create_divider(s)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 27
                ModuleManager:refresh_size()

                local Outer = Instance.new('Frame')
                Outer.Size = UDim2.new(0, 207, 0, 20)
                Outer.BackgroundTransparency = 1
                Outer.ZIndex = 4
                Outer.Parent = Options
                Outer.LayoutOrder = LayoutOrderModule

                if s and s.showtopic then
                    local T = Instance.new('TextLabel')
                    T.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    T.TextColor3 = Color3.fromRGB(255, 255, 255)
                    T.Text = s.title
                    T.Size = UDim2.new(0, 153, 0, 13)
                    T.Position = UDim2.new(0.5, 0, 0.5, 0)
                    T.BackgroundTransparency = 1
                    T.TextXAlignment = Enum.TextXAlignment.Center
                    T.AnchorPoint = Vector2.new(0.5, 0.5)
                    T.TextSize = 11
                    T.ZIndex = 5
                    T.Parent = Outer
                    table.insert(Library._elements, {obj = T, prop = "TextColor3", tKey = "Text"})
                end

                if not s or not s.disableline then
                    local D = Instance.new('Frame')
                    D.Size = UDim2.new(1, 0, 0, 1)
                    D.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    D.BorderSizePixel = 0
                    D.Position = UDim2.new(0, 0, 0.5, -0.5)
                    D.ZIndex = 5
                    D.Parent = Outer
                    local G = Instance.new('UIGradient')
                    G.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                    G.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    }
                    G.Parent = D
                    local DC = Instance.new('UICorner')
                    DC.CornerRadius = UDim.new(0, 2)
                    DC.Parent = D
                end
            end

            function ModuleManager:create_slider(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local SM = {}
                if self._size == 0 then self._size = 11 end
                self._size += 27
                ModuleManager:refresh_size()

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.ZIndex = 4
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = s.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 5
                TextLabel.Parent = Slider
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Drag.ZIndex = 5
                Drag.Parent = Slider
                table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Accent"})

                local DGC = Instance.new('UICorner')
                DGC.CornerRadius = UDim.new(1, 0)
                DGC.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Fill.ZIndex = 6
                Fill.Parent = Drag
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

                local FC = Instance.new('UICorner')
                FC.CornerRadius = UDim.new(0, 3)
                FC.Parent = Fill

                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                }
                UIGradient.Parent = Fill

                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.ZIndex = 7
                Circle.Parent = Fill
                table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})

                local CC = Instance.new('UICorner')
                CC.CornerRadius = UDim.new(1, 0)
                CC.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.2
                Value.Text = '50'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.ZIndex = 5
                Value.Parent = Slider
                table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "Text"})

                function SM:set_percentage(percentage)
                    local rounded
                    if s.round_number then
                        rounded = math.floor(percentage)
                    else
                        rounded = math.floor(percentage * 10) / 10
                    end
                    percentage = (percentage - s.minimum_value) / (s.maximum_value - s.minimum_value)
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local val = math.clamp(rounded, s.minimum_value, s.maximum_value)
                    Library._config._flags[s.flag] = val
                    Value.Text = tostring(val)
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
                    if s.callback then s.callback(val) end
                end

                function SM:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = s.minimum_value + (s.maximum_value - s.minimum_value) * mouse_position
                    self:set_percentage(percentage)
                end

                function SM:input()
                    SM:update()
                    Connections['slider_drag_'..s.flag] = mouse.Move:Connect(function() SM:update() end)
                    Connections['slider_input_'..s.flag] = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        Connections:disconnect('slider_drag_'..s.flag)
                        Connections:disconnect('slider_input_'..s.flag)
                        Config:save(game.GameId, Library._config)
                    end)
                end

                if Library:flag_type(s.flag, 'number') and not s.ignoresaved then
                    SM:set_percentage(Library._config._flags[s.flag])
                else
                    SM:set_percentage(s.value or s.minimum_value)
                end

                Slider.MouseButton1Down:Connect(function()
                    if ModuleManager._locked then return end
                    SM:input()
                end)

                Library._flag_registry[s.flag] = function(v) SM:set_percentage(v) end
                return SM
            end

            function ModuleManager:create_dropdown(s)
                if not s.Order then LayoutOrderModule = LayoutOrderModule + 1 end
                local DM = { _state = false, _size = 0 }
                if not s.Order then
                    if self._size == 0 then self._size = 11 end
                    self._size += 44
                    ModuleManager:refresh_size()
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.ZIndex = 4
                Dropdown.Parent = Options
                Dropdown.LayoutOrder = LayoutOrderModule

                if not Library._config._flags[s.flag] then
                    Library._config._flags[s.flag] = {}
                end

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = s.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 5
                TextLabel.Parent = Dropdown
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(0.5, 0, 1.2, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Box.ZIndex = 5
                Box.Parent = TextLabel
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})

                local BCorner = Instance.new('UICorner')
                BCorner.CornerRadius = UDim.new(0, 6)
                BCorner.Parent = Box

                local Header = Instance.new('Frame')
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.ZIndex = 6
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.2
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.05, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.TextSize = 10
                CurrentOption.ZIndex = 7
                CurrentOption.Parent = Header
                table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "Text"})

                local Arrow = Instance.new('ImageLabel')
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Color3.fromRGB(150, 150, 150)
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.ZIndex = 7
                Arrow.Parent = Header
                table.insert(Library._elements, {obj = Arrow, prop = "ImageColor3", tKey = "TextDim"})

                local OptionsList = Instance.new('ScrollingFrame')
                OptionsList.Active = true
                OptionsList.ScrollBarImageTransparency = 1
                OptionsList.AutomaticCanvasSize = Enum.AutomaticSize.XY
                OptionsList.ScrollBarThickness = 0
                OptionsList.Size = UDim2.new(0, 207, 0, 0)
                OptionsList.BackgroundTransparency = 1
                OptionsList.Position = UDim2.new(0, 0, 1, 0)
                OptionsList.BorderSizePixel = 0
                OptionsList.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                OptionsList.ZIndex = 6
                OptionsList.Parent = Box

                local OL = Instance.new('UIListLayout')
                OL.SortOrder = Enum.SortOrder.LayoutOrder
                OL.Parent = OptionsList

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = OptionsList

                function DM:update(option)
                    if s.multi_dropdown then
                        if not Library._config._flags[s.flag] then Library._config._flags[s.flag] = {} end
                        local selected = {}
                        for _, v in pairs(Library._config._flags[s.flag]) do
                            table.insert(selected, tostring(v))
                        end
                        CurrentOption.Text = table.concat(selected, ", ")
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = table.find(selected, object.Text) and 0.2 or 0.6
                            end
                        end
                        Library._config._flags[s.flag] = selected
                    else
                        CurrentOption.Text = (typeof(option) == "string" and option) or (option and option.Name) or ""
                        for _, object in OptionsList:GetChildren() do
                            if object.Name == "Option" then
                                object.TextTransparency = object.Text == CurrentOption.Text and 0.2 or 0.6
                            end
                        end
                        Library._config._flags[s.flag] = option
                    end
                    if s.callback then s.callback(option) end
                    Config:save(game.GameId, Library._config)
                end

                function DM:unfold_settings()
                    self._state = not self._state
                    local extra = self._state and self._size or 0
                    if self._state then
                        ModuleManager._multiplier = ModuleManager._multiplier + self._size
                    else
                        ModuleManager._multiplier = ModuleManager._multiplier - self._size
                    end
                    ModuleManager:refresh_size()
                    TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 39 + extra)
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 22 + extra)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    }):Play()
                end

                function DM:refresh(new_options)
                    local old_size = self._size
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child.Name == 'Option' then child:Destroy() end
                    end
                    self._size = 3
                    for index, value in new_options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.TextTransparency = 0.6
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Text = tostring(value)
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.ZIndex = 8
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})
                        Option.MouseButton1Click:Connect(function() DM:update(value) end)
                        if s.maximum_options and index > s.maximum_options then continue end
                        self._size = self._size + 16
                        OptionsList.Size = UDim2.fromOffset(207, self._size)
                    end
                    if self._state then
                        local diff = self._size - old_size
                        ModuleManager._multiplier = ModuleManager._multiplier + diff
                        ModuleManager:refresh_size()
                    end
                end

                if #s.options > 0 then
                    DM._size = 3
                    for index, value in s.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.TextTransparency = 0.6
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Text = (typeof(value) == "string" and value) or value.Name
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.ZIndex = 8
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})

                        Option.MouseButton1Click:Connect(function()
                            if ModuleManager._locked then return end
                            if not Library._config._flags[s.flag] then Library._config._flags[s.flag] = {} end
                            if s.multi_dropdown then
                                if table.find(Library._config._flags[s.flag], value) then
                                    Library:remove_table_value(Library._config._flags[s.flag], value)
                                else
                                    table.insert(Library._config._flags[s.flag], value)
                                end
                            end
                            DM:update(value)
                        end)
                        if s.maximum_options and index > s.maximum_options then continue end
                        DM._size = DM._size + 16
                        OptionsList.Size = UDim2.fromOffset(207, DM._size)
                    end
                end

                if Library:flag_type(s.flag, 'string') then
                    DM:update(Library._config._flags[s.flag])
                else
                    DM:update(s.options[1])
                end

                Dropdown.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    DM:unfold_settings()
                end)

                Library._flag_registry[s.flag] = function(v) DM:update(v) end
                return DM
            end

            function ModuleManager:create_feature(s)
                local checked = false
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 20
                ModuleManager:refresh_size()

                local FC = Instance.new("Frame")
                FC.Size = UDim2.new(0, 207, 0, 16)
                FC.BackgroundTransparency = 1
                FC.ZIndex = 4
                FC.Parent = Options
                FC.LayoutOrder = LayoutOrderModule

                local Layout = Instance.new("UIListLayout")
                Layout.FillDirection = Enum.FillDirection.Horizontal
                Layout.SortOrder = Enum.SortOrder.LayoutOrder
                Layout.Parent = FC

                local Btn = Instance.new("TextButton")
                Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Btn.TextSize = 11
                Btn.Size = UDim2.new(1, -35, 0, 16)
                Btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                Btn.TextColor3 = Color3.fromRGB(210, 210, 210)
                Btn.Text = "    " .. (s.title or "Feature")
                Btn.AutoButtonColor = false
                Btn.TextXAlignment = Enum.TextXAlignment.Left
                Btn.TextTransparency = 0.2
                Btn.ZIndex = 5
                Btn.Parent = FC
                table.insert(Library._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Btn, prop = "TextColor3", tKey = "Text"})

                local RC = Instance.new("Frame")
                RC.Size = UDim2.new(0, 45, 0, 16)
                RC.BackgroundTransparency = 1
                RC.ZIndex = 5
                RC.Parent = FC

                local RL = Instance.new("UIListLayout")
                RL.Padding = UDim.new(0.1, 0)
                RL.FillDirection = Enum.FillDirection.Horizontal
                RL.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RL.SortOrder = Enum.SortOrder.LayoutOrder
                RL.Parent = RC

                local KBBox = Instance.new("TextLabel")
                KBBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KBBox.Size = UDim2.new(0, 15, 0, 15)
                KBBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                KBBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                KBBox.TextSize = 11
                KBBox.BackgroundTransparency = 1
                KBBox.LayoutOrder = 2
                KBBox.ZIndex = 5
                KBBox.Parent = RC
                table.insert(Library._elements, {obj = KBBox, prop = "BackgroundColor3", tKey = "Accent"})

                local KBButton = Instance.new("TextButton")
                KBButton.Size = UDim2.new(1, 0, 1, 0)
                KBButton.BackgroundTransparency = 1
                KBButton.TextTransparency = 1
                KBButton.ZIndex = 6
                KBButton.Parent = KBBox

                local KBCorner = Instance.new("UICorner", KBBox)
                KBCorner.CornerRadius = UDim.new(0, 3)

                local KBStroke = Instance.new("UIStroke", KBBox)
                KBStroke.Color = Color3.fromRGB(255, 255, 255)
                KBStroke.Thickness = 1
                KBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                if not Library._config._flags[s.flag] then
                    Library._config._flags[s.flag] = { checked = false, BIND = s.default or "Unknown" }
                end
                checked = Library._config._flags[s.flag].checked
                KBBox.Text = Library._config._flags[s.flag].BIND
                if KBBox.Text == "Unknown" then KBBox.Text = "..." end

                local UseF = nil
                if not s.disablecheck then
                    local Cb = Instance.new("TextButton")
                    Cb.Size = UDim2.new(0, 15, 0, 15)
                    Cb.BackgroundColor3 = checked and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,20,20)
                    Cb.Text = ""
                    Cb.ZIndex = 5
                    Cb.Parent = RC
                    Cb.LayoutOrder = 1

                    local CbStroke = Instance.new("UIStroke", Cb)
                    CbStroke.Color = Color3.fromRGB(255, 255, 255)
                    CbStroke.Thickness = 1
                    CbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

                    local CbCorner = Instance.new("UICorner")
                    CbCorner.CornerRadius = UDim.new(0, 3)
                    CbCorner.Parent = Cb

                    local function toggleState()
                        checked = not checked
                        Cb.BackgroundColor3 = checked and Color3.fromRGB(255,255,255) or Color3.fromRGB(20,20,20)
                        Library._config._flags[s.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if s.callback then s.callback(checked) end
                    end
                    UseF = toggleState
                    Cb.MouseButton1Click:Connect(function()
                        if ModuleManager._locked then return end
                        toggleState()
                    end)
                else
                    UseF = function() if s.button_callback then s.button_callback() end end
                end

                KBButton.MouseButton1Click:Connect(function()
                    KBBox.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            Library._config._flags[s.flag].BIND = input.KeyCode.Name
                            if input.KeyCode.Name ~= "Unknown" then
                                KBBox.Text = input.KeyCode.Name
                            end
                            Config:save(game.GameId, Library._config)
                            conn:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[s.flag].BIND = "Unknown"
                            KBBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            conn:Disconnect()
                        end
                    end)
                end)

                local keyPress = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[s.flag].BIND then
                            UseF()
                        end
                    end
                end)
                Connections["keybind_press_" .. s.flag] = keyPress

                Btn.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    if s.button_callback then s.button_callback() end
                end)

                if not s.disablecheck and s.callback then s.callback(checked) end
                return FC
            end

            return ModuleManager
        end

        return TabManager
    end

    -- ═══════════════════════════════════════════════════════════════
    --  Visibility listener (reads Minimize_Keybind)
    -- ═══════════════════════════════════════════════════════════════
    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        if process then return end
        local key = Library._config._keybinds['Minimize_Keybind'] or "Enum.KeyCode.Insert"
        if tostring(input.KeyCode) ~= key then return end
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

-- ═══════════════════════════════════════════════════════════════
--  INTERFACE TAB
-- ═══════════════════════════════════════════════════════════════
function Library:build_interface_tab()
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007', true)

    local Container = self._ui.Container
    local Handler = Container.Handler

    local Custom_Asset = getcustomasset or getsynasset
    local Background_Folder = 'ailon/Backgrounds'

    if Custom_Asset and not isfolder(Background_Folder) then
        makefolder(Background_Folder)
    end

    local function resolve_background(source)
        if not source or source == '' then return '' end
        source = tostring(source):match('^%s*(.-)%s*$')
        if source == '' then return '' end
        if source:match('^%d+$')      then return 'rbxassetid://'..source end
        if source:match('^rbx%a+://') then return source end
        if not Custom_Asset           then return '' end
        if not source:match('^https?://') then
            return (isfile(source) and Custom_Asset(source)) or ''
        end
        local extension = source:match('%.(%a%a%a%a?)[%?#]')
                    or source:match('%.(%a%a%a%a?)$')
                    or 'png'
        local path = Background_Folder..'/'..source:gsub('%W',''):sub(-48)..'.'..extension
        if not isfile(path) then
            local ok, body = pcall(game.HttpGet, game, source, true)
            if not ok then return '' end
            writefile(path, body)
        end
        local ok, result = pcall(Custom_Asset, path)
        if ok and result then return result end
        return ''
    end

    local function set_background_image(source)
        local bg = self._background
        if not bg then return end
        local resolved = resolve_background(source)
        if resolved ~= '' then
            bg.Image = resolved
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Position = UDim2.new(0, 0, 0, 0)
            bg.ScaleType = Enum.ScaleType.Crop
            bg.Visible = true
        else
            bg.Image = ''
            bg.Visible = false
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
        Reset_Holder.Size = UDim2.fromOffset(207, 23)
        Reset_Holder.BackgroundTransparency = 1
        Reset_Holder.BorderSizePixel = 0
        Reset_Holder.LayoutOrder = layout_order
        Reset_Holder.Parent = parent

        local Reset = Instance.new('TextButton')
        Reset.Name = 'Reset'
        Reset.AnchorPoint = Vector2.new(0, 1)
        Reset.Position = UDim2.new(0, 0, 1, 0)
        Reset.Size = UDim2.fromOffset(207, 22)
        Reset.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Reset.BorderSizePixel = 0
        Reset.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Reset.TextColor3 = Color3.fromRGB(255, 255, 255)
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
        ResetStroke.Color = Color3.fromRGB(100, 100, 100)
        ResetStroke.Transparency = 0.72
        ResetStroke.Thickness = 1
        ResetStroke.Parent = Reset
        table.insert(self._elements, {obj = ResetStroke, prop = "Color", tKey = "GroupStroke"})

        Reset.MouseButton1Click:Connect(on_click)
    end

    -- ─── Configurations ─────────────────────────────────────
    local config_module = InterfaceTab:create_module({
        title = 'Configurations',
        flag = 'UI_Config_System',
        description = 'Save and load profiles',
        section = 'right',
        callback = function() end,
    })

    local function get_configs()
        if not (isfolder and listfiles) then return {} end
        local dir = 'ailon/Configs'
        if not isfolder(dir) then makefolder(dir) end
        local names = {}
        for _, f in ipairs(listfiles(dir)) do
            local n = f:match('([^/\\]+)%.json$')
            if n then table.insert(names, n) end
        end
        return names
    end

    local name_box = config_module:create_textbox({
        title = 'Profile Name',
        flag = 'Config_Input_Name',
        placeholder = 'New Config Name',
        value = '',
        callback = function() end,
    })

    local list_drop = config_module:create_dropdown({
        title = 'Saved Profiles',
        flag = 'Config_Saved_List',
        options = get_configs(),
        multi_dropdown = false,
        callback = function() end,
    })

    config_module:create_button({
        title = 'Save Profile',
        callback = function()
            local name = name_box._text or Library._config._flags['Config_Input_Name']
            if typeof(name) ~= 'string' or name:gsub("%s","") == "" then
                Library.SendNotification({title = 'Config', text = 'Enter a valid name.', duration = 3})
                return
            end
            Config:save('Configs/'..name, Library._config)
            list_drop:refresh(get_configs())
            list_drop:update(name)
            Library.SendNotification({title = 'Config', text = 'Saved as '..name, duration = 3})
        end,
    })

    config_module:create_button({
        title = 'Load Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then
                Library.SendNotification({title = 'Config', text = 'Select a profile.', duration = 3})
                return
            end
            local loaded = Config:load('Configs/'..name, { _flags = {}, _keybinds = {} })
            for flag in pairs(Library._flag_registry) do
                Library._config._flags[flag] = nil
            end
            for key in pairs(DefaultTheme) do
                Library._config._flags['Theme_'..key] = nil
            end
            Library._config._flags['Background_Image'] = nil
            Library._config._flags['Background_Transparency'] = nil
            Library._config._flags['Background_Image_Id'] = nil
            for k, v in pairs(loaded._flags or {}) do
                Library._config._flags[k] = v
            end
            Library._config._keybinds = loaded._keybinds or {}
            for flag, fn in pairs(Library._flag_registry) do
                if Library._config._flags[flag] ~= nil then
                    pcall(fn, Library._config._flags[flag])
                end
            end
            for key, _ in pairs(DefaultTheme) do
                local s = Library._config._flags['Theme_'..key]
                if s then Library:SetColor(key, Library:hexToRGB(s)) end
            end
            local s = Library._config._flags['Background_Image']
            if typeof(s) == "string" and s ~= '' then
                set_background_image(s)
                if self._background then
                    self._background.ImageTransparency = Library._config._flags['Background_Transparency'] or 0.5
                end
            end
            Library.SendNotification({title = 'Config', text = 'Loaded '..name, duration = 3})
        end,
    })

    config_module:create_button({
        title = 'Delete Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then return end
            local path = 'ailon/Configs/'..name..'.json'
            if isfile and isfile(path) then
                delfile(path)
                list_drop:refresh(get_configs())
                Library.SendNotification({title = 'Config', text = 'Deleted '..name, duration = 3})
            end
        end,
    })

    -- ─── Appearance ─────────────────────────────────────────
    local color_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'Gui_Colors',
        description = 'Customize UI colors',
        section = 'left',
        callback = function() end,
    })

    local color_frame = find_module_frame('Appearance')
    local Color_Targets = { 'Background', 'Group', 'Control', 'Accent', 'Text', 'TextDim' }
    local Swatches = {}
    local Selected = 'Background'
    local Ptr_Offset = Vector2.zero
    local H, S, V = 0, 0, 1

    if color_frame then
        local Opts = color_frame.Options

        local Popup = Instance.new('Frame')
        Popup.Name = 'ColorPopup'
        Popup.Size = UDim2.fromOffset(207, 180)
        Popup.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 30
        Popup.Parent = Handler
        Instance.new('UICorner', Popup).CornerRadius = UDim.new(0, 7)
        local PS = Instance.new('UIStroke', Popup); PS.Color = Color3.fromRGB(70,70,70); PS.Transparency = 0.4

        local Field = Instance.new('TextButton')
        Field.Position = UDim2.fromOffset(8, 10)
        Field.Size = UDim2.fromOffset(145, 145)
        Field.BackgroundColor3 = Color3.fromRGB(255,0,0)
        Field.BorderSizePixel = 0
        Field.ClipsDescendants = true
        Field.AutoButtonColor = false
        Field.Text = ''
        Field.ZIndex = 31
        Field.Parent = Popup
        Instance.new('UICorner', Field).CornerRadius = UDim.new(0, 5)

        local Sat = Instance.new('Frame')
        Sat.Size = UDim2.new(1,0,1,0)
        Sat.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Sat.BorderSizePixel = 0
        Sat.ZIndex = 32
        Sat.Parent = Field
        Instance.new('UICorner', Sat).CornerRadius = UDim.new(0, 5)
        local SG = Instance.new('UIGradient', Sat)
        SG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}

        local Bri = Instance.new('Frame')
        Bri.Size = UDim2.new(1,0,1,0)
        Bri.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Bri.BorderSizePixel = 0
        Bri.ZIndex = 33
        Bri.Parent = Field
        Instance.new('UICorner', Bri).CornerRadius = UDim.new(0, 5)
        local BG = Instance.new('UIGradient', Bri)
        BG.Rotation = 90
        BG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}

        local Cursor = Instance.new('Frame')
        Cursor.AnchorPoint = Vector2.new(0.5,0.5)
        Cursor.Size = UDim2.fromOffset(11,11)
        Cursor.BackgroundTransparency = 1
        Cursor.BorderSizePixel = 0
        Cursor.ZIndex = 34
        Cursor.Parent = Field
        Instance.new('UICorner', Cursor).CornerRadius = UDim.new(1,0)
        local CS = Instance.new('UIStroke', Cursor); CS.Color = Color3.fromRGB(255,255,255); CS.Thickness = 2

        local Hue = Instance.new('TextButton')
        Hue.Position = UDim2.fromOffset(159, 10)
        Hue.Size = UDim2.fromOffset(14, 145)
        Hue.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Hue.BorderSizePixel = 0
        Hue.AutoButtonColor = false
        Hue.Text = ''
        Hue.ZIndex = 31
        Hue.Parent = Popup
        Instance.new('UICorner', Hue).CornerRadius = UDim.new(0, 4)
        local HG = Instance.new('UIGradient', Hue)
        HG.Rotation = 90
        local kp = {}
        for i = 0, 6 do kp[i+1] = ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6,1,1)) end
        HG.Color = ColorSequence.new(kp)

        local HKnob = Instance.new('Frame')
        HKnob.AnchorPoint = Vector2.new(0.5,0.5)
        HKnob.Size = UDim2.fromOffset(14, 3)
        HKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        HKnob.BorderSizePixel = 0
        HKnob.ZIndex = 32
        HKnob.Parent = Hue
        Instance.new('UICorner', HKnob).CornerRadius = UDim.new(1,0)

        local HexBox = Instance.new('TextBox')
        HexBox.Position = UDim2.fromOffset(8, 160)
        HexBox.Size = UDim2.fromOffset(165, 14)
        HexBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
        HexBox.BackgroundTransparency = 0.3
        HexBox.BorderSizePixel = 0
        HexBox.TextColor3 = Color3.fromRGB(220,220,220)
        HexBox.PlaceholderText = 'FF0000'
        HexBox.PlaceholderColor3 = Color3.fromRGB(150,150,150)
        HexBox.TextSize = 10
        HexBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        HexBox.ClearTextOnFocus = false
        HexBox.ZIndex = 31
        HexBox.Parent = Popup
        Instance.new('UICorner', HexBox).CornerRadius = UDim.new(0, 4)

        local function colorToHex(c)
            return string.format("%02X%02X%02X", math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
        end
        local function hexToColor(hex)
            hex = hex:gsub("#","")
            if #hex ~= 6 then return nil end
            local r = tonumber(hex:sub(1,2), 16)
            local g = tonumber(hex:sub(3,4), 16)
            local b = tonumber(hex:sub(5,6), 16)
            if not (r and g and b) then return nil end
            return Color3.fromRGB(r, g, b)
        end

        local function applyColor(h, sat, v, skipHex)
            H, S, V = h, sat, v
            local color = Color3.fromHSV(h, sat, v)
            Field.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            Cursor.Position = UDim2.new(math.clamp(sat, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)
            HKnob.Position = UDim2.new(0.5, 0, math.clamp(h, 0, 0.9999), 0)
            if Swatches[Selected] then
                Swatches[Selected].BackgroundColor3 = color
            end
            if not skipHex then HexBox.Text = colorToHex(color) end
            Library:SetColor(Selected, color)
        end

        local function calibrate(fr)
            local inset = GuiService:GetGuiInset()
            local loc = UserInputService:GetMouseLocation()
            local tl = fr.AbsolutePosition
            local br = tl + fr.AbsoluteSize
            for _, off in ipairs({Vector2.zero, inset, -inset}) do
                local p = loc + off
                if p.X >= tl.X and p.X <= br.X and p.Y >= tl.Y and p.Y <= br.Y then
                    Ptr_Offset = off
                    return
                end
            end
        end

        local function updateField()
            local loc = UserInputService:GetMouseLocation() + Ptr_Offset
            local sat = math.clamp((loc.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
            local v = 1 - math.clamp((loc.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
            applyColor(H, sat, v)
        end

        local function updateHue()
            local loc = UserInputService:GetMouseLocation() + Ptr_Offset
            local hue = math.clamp((loc.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 0.9999)
            applyColor(hue, S, V)
        end

        local function drag(key, fr, fn)
            calibrate(fr); fn()
            Connections[key..'_m'] = UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then fn() end
            end)
            Connections[key..'_e'] = UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    Connections:disconnect(key..'_m'); Connections:disconnect(key..'_e')
                end
            end)
        end

        local function closePopup()
            Popup.Visible = false
            for _, sw in pairs(Swatches) do
                local st = sw:FindFirstChildOfClass('UIStroke')
                if st then st.Transparency = 0.5 end
            end
        end

        local function openPopup(target, sw)
            if Popup.Visible and Selected == target then closePopup() return end
            Selected = target
            for n, o in pairs(Swatches) do
                local st = o:FindFirstChildOfClass('UIStroke')
                if st then st.Transparency = n == target and 0 or 0.5 end
            end
            local sc = Handler.AbsoluteSize.X / 680
            local rx = (sw.AbsolutePosition.X - Handler.AbsolutePosition.X) / sc
            local ry = (sw.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / sc
            Popup.Position = UDim2.fromOffset(
                math.clamp(rx - 220, 8, 460),
                math.clamp(ry - 62, 8, 320)
            )
            Popup.Visible = true
            local hue, sat, bright = Color3.toHSV(Theme[target])
            applyColor(hue, sat, bright)
        end

        Field.MouseButton1Down:Connect(function() drag('gui_color_field', Field, updateField) end)
        Hue.MouseButton1Down:Connect(function() drag('gui_color_hue', Hue, updateHue) end)

        for i, target in ipairs(Color_Targets) do
            local Row = Instance.new('TextButton')
            Row.Size = UDim2.fromOffset(207, 22)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.AutoButtonColor = false
            Row.Text = ''
            Row.ZIndex = 4
            Row.LayoutOrder = i
            Row.Parent = Opts

            local T = Instance.new('TextLabel')
            T.Size = UDim2.new(1,-50,1,0)
            T.BackgroundTransparency = 1
            T.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
            T.TextColor3 = Color3.fromRGB(255,255,255)
            T.TextSize = 12
            T.Text = target
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.TextYAlignment = Enum.TextYAlignment.Center
            T.ZIndex = 5
            T.Parent = Row
            table.insert(self._elements, {obj = T, prop = "TextColor3", tKey = "Text"})

            local Sw = Instance.new('TextButton')
            Sw.AnchorPoint = Vector2.new(1, 0.5)
            Sw.Position = UDim2.new(1, 0, 0.5, 0)
            Sw.Size = UDim2.fromOffset(34, 16)
            Sw.BackgroundColor3 = Theme[target]
            Sw.BorderSizePixel = 0
            Sw.AutoButtonColor = false
            Sw.Text = ''
            Sw.ZIndex = 5
            Sw.Parent = Row

            local SC = Instance.new('UICorner'); SC.CornerRadius = UDim.new(0, 4); SC.Parent = Sw
            local SS = Instance.new('UIStroke'); SS.Color = Color3.fromRGB(100,100,100); SS.Transparency = 0.5; SS.Parent = Sw
            table.insert(self._elements, {obj = SS, prop = "Color", tKey = "GroupStroke"})

            Sw.MouseButton1Click:Connect(function() openPopup(target, Sw) end)
            Row.MouseButton1Click:Connect(function() openPopup(target, Sw) end)

            Swatches[target] = Sw
        end

        build_reset_button(Opts, #Color_Targets + 3, function()
            closePopup()
            for target, color in pairs(DefaultTheme) do
                if typeof(color) == "Color3" then
                    Library:SetColor(target, color)
                    if Swatches[target] then Swatches[target].BackgroundColor3 = color end
                end
            end
        end)

        color_module._size = 282
        Opts.Size = UDim2.fromOffset(241, color_module._size)
        if color_module._state then
            color_frame.Size = UDim2.fromOffset(241, 93 + color_module._size + color_module._multiplier)
        end
    end

    -- ─── Background ─────────────────────────────────────────
    local image_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'Background_Image',
        description = 'Set background image',
        section = 'right',
        callback = function(state)
            if not self._background then return end
            self._background.Visible = state and self._background.Image ~= ''
            set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)
        end,
    })

    local Presets = {
        ['None'] = '',
        ['Preset 1'] = 'https://i.pinimg.com/736x/bd/12/a5/bd12a561f083960f6c1382c54f4df234.jpg',
        ['Preset 2'] = 'https://i.pinimg.com/736x/53/bd/84/53bd848d7ca43b57612117292d7ff979.jpg',
        ['Preset 3'] = 'https://i.pinimg.com/736x/db/26/c7/db26c713d48342bd15c0ee8f623e19c6.jpg',
        ['Preset 4'] = 'https://i.pinimg.com/736x/dc/ad/10/dcad1026de88c85a417c6f4dd0b620c8.jpg',
        ['Preset 5'] = 'https://i.pinimg.com/736x/fe/88/90/fe88905bf7387c8827ffaf4a5aae7068.jpg',
    }

    local saved_id = Library._config._flags['Background_Image_Id'] or ''
    local bg_id = typeof(saved_id) == 'string' and saved_id or ''
    local Asset_Input

    local preset_drop = image_module:create_dropdown({
        title = 'Preset',
        flag = 'Background_Preset',
        options = { 'None', 'Preset 1', 'Preset 2', 'Preset 3', 'Preset 4', 'Preset 5' },
        multi_dropdown = false,
        maximum_options = 6,
        callback = function(value)
            local name = (typeof(value) == 'string' and value) or value.Name
            local src = Presets[name] or ''
            bg_id = src
            if Asset_Input then Asset_Input.Text = src end
            set_background_image(src)
            Library._config._flags['Background_Image_Id'] = src
        end,
    })

    local trans_slider = image_module:create_slider({
        title = 'Image Transparency',
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

    local module_trans_slider = image_module:create_slider({
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

    local bg_frame = find_module_frame('Background')
    if bg_frame then
        local Row = Instance.new('Frame')
        Row.Name = 'AssetRow'
        Row.Size = UDim2.fromOffset(207, 24)
        Row.BackgroundTransparency = 1
        Row.ZIndex = 4
        Row.LayoutOrder = 0
        Row.Parent = bg_frame.Options

        local Input = Instance.new('TextBox')
        Input.Name = 'AssetId'
        Input.AnchorPoint = Vector2.new(0, 0.5)
        Input.Position = UDim2.new(0, 0, 0.5, 0)
        Input.Size = UDim2.fromOffset(207, 22)
        Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Input.BackgroundTransparency = 0.2
        Input.BorderSizePixel = 0
        Input.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Input.TextColor3 = Color3.fromRGB(255,255,255)
        Input.PlaceholderColor3 = Color3.fromRGB(150,150,150)
        Input.PlaceholderText = 'Asset ID or Image URL'
        Input.TextSize = 11
        Input.ClearTextOnFocus = false
        Input.Text = bg_id
        Input.ZIndex = 5
        Input.Parent = Row
        table.insert(self._elements, {obj = Input, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = Input, prop = "TextColor3", tKey = "Text"})
        table.insert(self._elements, {obj = Input, prop = "PlaceholderColor3", tKey = "TextDim"})

        Asset_Input = Input

        local IC = Instance.new('UICorner'); IC.CornerRadius = UDim.new(0,4); IC.Parent = Input

        Input.FocusLost:Connect(function()
            local src = Input.Text:match('^%s*(.-)%s*$')
            Input.Text = src
            bg_id = src
            set_background_image(src)
            Library._config._flags['Background_Image_Id'] = src
        end)

        build_reset_button(bg_frame.Options, 4, function()
            Input.Text = ''
            bg_id = ''
            set_background_image('')
            pcall(function() preset_drop:update('None') end)
            trans_slider:set_percentage(50)
            module_trans_slider:set_percentage(0)
            Library._config._flags['Background_Image_Id'] = ''
        end)

        image_module._size = image_module._size + 60
        bg_frame.Options.Size = UDim2.fromOffset(241, image_module._size)
        if image_module._state then
            bg_frame.Size = UDim2.fromOffset(241, 93 + image_module._size + image_module._multiplier)
        end
    end

    set_background_image(bg_id)
    set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)

    -- ─── UI Transparency ────────────────────────────────────
    local ui_trans_module = InterfaceTab:create_module({
        title = 'UI Transparency',
        flag = 'UI_Transparency_Module',
        description = 'Container + module opacity',
        section = 'left',
        callback = function() end,
    })

    ui_trans_module:create_slider({
        title = 'Container Opacity',
        flag = 'UI_Container_Transparency',
        minimum_value = 0,
        maximum_value = 100,
        value = 5,
        round_number = true,
        callback = function(value)
            if self._container then
                self._container.BackgroundTransparency = value / 100
            end
        end,
    })

    -- ─── Settings ───────────────────────────────────────────
    local settings_module = InterfaceTab:create_module({
        title = 'Settings',
        flag = 'UI_Settings',
        description = 'UI Behavior',
        section = 'left',
        callback = function() end,
    })

    settings_module:create_checkbox({
        title = 'Hide on Minimize',
        flag = 'UI_Gui_Visible',
        callback = function(state) end,
    })

    -- ─── Notifications ──────────────────────────────────────
    local notif_module = InterfaceTab:create_module({
        title = 'Notifications',
        flag = 'UI_Notifications',
        description = 'Side and opacity',
        section = 'right',
        callback = function() end,
    })

    notif_module:create_dropdown({
        title = 'Side',
        flag = 'UI_Notif_Side',
        options = { 'Left', 'Right' },
        multi_dropdown = false,
        maximum_options = 2,
        callback = function(value)
            local side = (typeof(value) == 'string' and value) or value.Name
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

    -- ─── Minimize Key ───────────────────────────────────────
    local min_module = InterfaceTab:create_module({
        title = 'Minimize Key',
        flag = 'UI_Minimize_Key',
        description = 'Press-to-bind toggle key',
        section = 'left',
        callback = function() end,
    })

    local min_frame = find_module_frame('Minimize Key')

    if min_frame then
        local Row = Instance.new('Frame')
        Row.Size = UDim2.fromOffset(207, 22)
        Row.BackgroundTransparency = 1
        Row.ZIndex = 4
        Row.LayoutOrder = 0
        Row.Parent = min_frame.Options

        local Lbl = Instance.new('TextLabel')
        Lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Lbl.TextSize = 11
        Lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        Lbl.Text = 'Toggle UI Key'
        Lbl.Size = UDim2.new(0, 120, 1, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.ZIndex = 5
        Lbl.Parent = Row
        table.insert(self._elements, {obj = Lbl, prop = "TextColor3", tKey = "Text"})

        local min_keybox = Instance.new('TextButton')
        min_keybox.Name = 'Keybox'
        min_keybox.AnchorPoint = Vector2.new(1, 0.5)
        min_keybox.Position = UDim2.new(1, 0, 0.5, 0)
        min_keybox.Size = UDim2.fromOffset(60, 20)
        min_keybox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        min_keybox.BorderSizePixel = 0
        min_keybox.AutoButtonColor = false
        min_keybox.Text = ''
        min_keybox.ZIndex = 4
        min_keybox.Parent = Row
        table.insert(self._elements, {obj = min_keybox, prop = "BackgroundColor3", tKey = "Control"})

        local MC = Instance.new('UICorner'); MC.CornerRadius = UDim.new(0,3); MC.Parent = min_keybox
        local MS = Instance.new('UIStroke'); MS.Color = Color3.fromRGB(100,100,100); MS.Transparency = 0.5; MS.Thickness = 1; MS.Parent = min_keybox
        table.insert(self._elements, {obj = MS, prop = "Color", tKey = "GroupStroke"})

        local MT = Instance.new('TextLabel')
        MT.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        MT.TextColor3 = Color3.fromRGB(255, 255, 255)
        MT.TextSize = 10
        MT.BackgroundTransparency = 1
        MT.Size = UDim2.new(1, -6, 1, 0)
        MT.Position = UDim2.new(0, 3, 0, 0)
        MT.TextXAlignment = Enum.TextXAlignment.Center
        MT.ZIndex = 5
        MT.Parent = min_keybox
        table.insert(self._elements, {obj = MT, prop = "TextColor3", tKey = "Text"})

        min_module._size = min_module._size + 26
        min_frame.Options.Size = UDim2.fromOffset(241, min_module._size)
        if min_module._state then
            min_frame.Size = UDim2.fromOffset(241, 93 + min_module._size + min_module._multiplier)
        end

        local function refresh()
            local k = Library._config._keybinds['Minimize_Keybind']
            MT.Text = k and k:gsub('Enum.KeyCode.', '') or 'Insert'
        end
        refresh()

        local listening = false
        min_keybox.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            MT.Text = '...'
            min_keybox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

            local bind_c, cancel_c
            local function done()
                listening = false
                min_keybox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                refresh()
                if bind_c then bind_c:Disconnect() end
                if cancel_c then cancel_c:Disconnect() end
            end

            task.defer(function()
                bind_c = UserInputService.InputBegan:Connect(function(i, p)
                    if p then return end
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    if i.KeyCode == Enum.KeyCode.Unknown then return end
                    if i.KeyCode == Enum.KeyCode.Backspace then
                        Library._config._keybinds['Minimize_Keybind'] = nil
                        Library._keybind_list['Minimize_Keybind'] = nil
                    else
                        Library._config._keybinds['Minimize_Keybind'] = tostring(i.KeyCode)
                        Library._keybind_list['Minimize_Keybind'] = 'Toggle UI'
                    end
                    Config:save(game.GameId, Library._config)
                    done()
                end)
                cancel_c = UserInputService.InputBegan:Connect(function(i, p)
                    if p then return end
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then done() end
                end)
            end)
        end)
    end

    return InterfaceTab
end

-- ═══════════════════════════════════════════════════════════════
--  Auto-build interface tab on new()
-- ═══════════════════════════════════════════════════════════════
local _orig_new = Library.new
function Library.new()
    local self = _orig_new()
    self:build_interface_tab()
    return self
end

return Library

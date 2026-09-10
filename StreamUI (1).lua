-- ═══════════════════════════════════════════════════════════════
--  AilonLib — core UI library
--  Base: Ailon UI (Achaotic/IceLib lineage), game logic stripped.
--  Provides: window, tabs, modules, all widgets, notifications,
--  theme system, config save/load, AcrylicBlur, module lock,
--  per-module scroll indicator.
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

-- ─── Helpers ────────────────────────────────────────────────
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

-- ─── AcrylicBlur ────────────────────────────────────────────
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
        local tl = positions.top_left
        local tr = positions.top_right
        local br = positions.bottom_right
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

-- ─── Config ─────────────────────────────────────────────────
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

-- ─── Theme ──────────────────────────────────────────────────
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

-- ─── Library ────────────────────────────────────────────────
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
Library.Theme = Theme
Library.DefaultTheme = DefaultTheme

function Library.new()
    local self = setmetatable({ _tab = 0 }, Library)
    self:create_ui()
    return self
end

-- ─── Notifications ──────────────────────────────────────────
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
    InnerStroke.Color = Color3.fromRGB(60, 60, 60)
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
    Title.TextColor3 = Theme.TextSoft
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
    table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "TextSoft"})

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

-- ─── Utilities ──────────────────────────────────────────────
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
    if self._container then
        local grad = self._container:FindFirstChildOfClass("UIGradient")
        if grad and key == "Gradient" then grad.Color = color end
    end
    Library._config._flags['Theme_'..key] = self:rgbToHex(color)
    Config:save(game.GameId, Library._config)
end

function Library:GetColor(key)
    return Theme[key]
end

-- ─── Background (URL + preset support) ──────────────────────
local function resolve_background(source)
    if not source or source == '' then return '' end
    source = tostring(source):match('^%s*(.-)%s*$')
    if source == '' then return '' end
    if source:match('^%d+$') then return 'rbxassetid://'..source end
    if source:match('^rbx%a+://') then return source end

    local Custom_Asset = getcustomasset or getsynasset
    if not Custom_Asset then return '' end

    if source:match('^https?://') then
        if not (writefile and isfile and isfolder) then return '' end
        if not isfolder('ailon/Backgrounds') then makefolder('ailon/Backgrounds') end
        local ext = source:match('%.(%a%a%a%a?)[%?#]') or source:match('%.(%a%a%a%a?)$') or 'png'
        local path = 'ailon/Backgrounds/'..source:gsub('%W',''):sub(-48)..'.'..ext
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

-- ─── UI Construction ────────────────────────────────────────
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
    table.insert(Library._elements, {obj = ContainerGradient, prop = "Color", tKey = "Gradient"})

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(60, 60, 60)
    UIStroke.Transparency = 0.55
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

    -- Background image (Interface tab controls this)
    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
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
    ClientName.Text = 'ailon'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 60, 0, 18)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.07, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextSize = 16
    ClientName.ZIndex = 2
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "TextSoft"})

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
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextSoft"})

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
    self._handler = Handler

    -- Dragging
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
        Library._ui_open = state
        if state then
            TweenService:Create(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end

    function self:set_gui_visibility(state)
        if not self._ui then return end
        if state then
            self._ui.Enabled = true
            Container.Size = UDim2.fromOffset(0, 0)
            TweenService:Create(Container, TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
        else
            local t = TweenService:Create(Container, TweenInfo.new(0.24, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0)
            })
            t:Play()
            t.Completed:Once(function()
                self._ui.Enabled = false
            end)
        end
    end

    function self:load()
        self:get_device()
        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections['ui_scale'] = Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end

        TweenService:Create(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(680, 460)
        }):Play()

        AcrylicBlur.new(Container)

        -- restore theme + background
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
                    TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()
                    TweenService:Create(object.TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Theme.TextSoft
                    }):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0,
                        ImageColor3 = Theme.TextSoft
                    }):Play()
                end
                continue
            end
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(object.TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.4,
                    TextColor3 = Theme.TextDim
                }):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.5,
                    ImageColor3 = Theme.TextDim
                }):Play()
            end
        end
    end

    function self:update_sections(left, right)
        for _, object in Sections:GetChildren() do
            object.Visible = (object == left or object == right)
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
        Tab.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Tab.ZIndex = 2
        Tab.Parent = Tabs
        Tab.Visible = visible
        Tab.LayoutOrder = self._tab
        table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Control"})

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Theme.TextDim
        TextLabel.TextTransparency = 0.4
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.24, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextSize = 13
        TextLabel.ZIndex = 3
        TextLabel.Parent = Tab
        table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextDim"})

        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.5
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.1, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon or ''
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.BorderSizePixel = 0
        Icon.ZIndex = 3
        Icon.Parent = Tab
        table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextDim"})

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.Size = UDim2.new(0, 243, 0, 395)
        LeftSection.Selectable = false
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 203, 0, 67)
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
        RightSection.ScrollBarImageTransparency = 1
        RightSection.Size = UDim2.new(0, 243, 0, 395)
        RightSection.Selectable = false
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
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
            Module.BackgroundTransparency = 0.3
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Theme.Group
            Module.ZIndex = 2
            Module.Parent = SectionFrame
            table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

            local ModuleListLayout = Instance.new('UIListLayout')
            ModuleListLayout.Padding = UDim.new(0, 2)
            ModuleListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ModuleListLayout.Parent = Module

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 9)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Theme.GroupStroke
            UIStroke.Transparency = 0.72
            UIStroke.Thickness = 1
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

            local Header = Instance.new('TextButton')
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.ZIndex = 3
            Header.Parent = Module

            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Theme.TextSoft
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.3
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.055, 0, 0.82, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.ZIndex = 4
            Icon.Parent = Header
            table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextSoft"})

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Theme.TextSoft
            ModuleName.TextTransparency = 0
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 180, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.12, 0, 0.24, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.TextSize = 13
            ModuleName.ZIndex = 4
            ModuleName.Parent = Header
            table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "TextSoft"})

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.TextDim
            Description.TextTransparency = 0
            Description.Text = settings.description or ''
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 180, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.12, 0, 0.42, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.TextSize = 10
            Description.ZIndex = 4
            Description.Parent = Header
            table.insert(Library._elements, {obj = Description, prop = "TextColor3", tKey = "TextDim"})

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0
            Toggle.Position = UDim2.new(0, 221, 0, 76)
            Toggle.AnchorPoint = Vector2.new(1, 0.5)
            Toggle.Size = UDim2.new(0, 30, 0, 16)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Theme.Control
            Toggle.ZIndex = 4
            Toggle.Parent = Header
            table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control"})

            local ToggleCorner = Instance.new('UICorner')
            ToggleCorner.CornerRadius = UDim.new(1, 0)
            ToggleCorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Theme.TextDim
            Circle.ZIndex = 5
            Circle.Parent = Toggle
            table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "TextDim"})

            local CircleCorner = Instance.new('UICorner')
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle

            local Keybind = Instance.new('TextButton')
            Keybind.Name = 'Keybind'
            Keybind.AutoButtonColor = false
            Keybind.Text = ''
            Keybind.BackgroundTransparency = 0
            Keybind.Position = UDim2.new(0, 14, 0, 67)
            Keybind.Size = UDim2.new(0, 38, 0, 16)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Theme.Control
            Keybind.ZIndex = 4
            Keybind.Parent = Header
            table.insert(Library._elements, {obj = Keybind, prop = "BackgroundColor3", tKey = "Control"})

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 2)
            KeybindCorner.Parent = Keybind

            local KeybindStroke = Instance.new('UIStroke')
            KeybindStroke.Color = Theme.GroupStroke
            KeybindStroke.Transparency = 0.68
            KeybindStroke.Thickness = 1
            KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            KeybindStroke.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindStroke, prop = "Color", tKey = "GroupStroke"})

            local KeybindText = Instance.new('TextLabel')
            KeybindText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KeybindText.TextColor3 = Theme.TextSoft
            KeybindText.Text = 'None'
            KeybindText.Size = UDim2.new(1, -10, 1, 0)
            KeybindText.Position = UDim2.new(0, 5, 0, 0)
            KeybindText.BackgroundTransparency = 1
            KeybindText.TextXAlignment = Enum.TextXAlignment.Center
            KeybindText.TextYAlignment = Enum.TextYAlignment.Center
            KeybindText.TextSize = 10
            KeybindText.ZIndex = 5
            KeybindText.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindText, prop = "TextColor3", tKey = "TextSoft"})

            local LockButton = Instance.new('ImageButton')
            LockButton.Name = 'LockButton'
            LockButton.Size = UDim2.new(0, 13, 0, 13)
            LockButton.AnchorPoint = Vector2.new(1, 0)
            LockButton.Position = UDim2.new(1, -6, 0, 6)
            LockButton.BackgroundTransparency = 1
            LockButton.Image = 'rbxassetid://12060512624'
            LockButton.ImageColor3 = Theme.TextDim
            LockButton.ZIndex = 10
            LockButton.Parent = Header
            table.insert(Library._elements, {obj = LockButton, prop = "ImageColor3", tKey = "TextDim"})

            local Divider = Instance.new('Frame')
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.72
            Divider.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.Divider
            Divider.ZIndex = 4
            Divider.Parent = Header
            table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "Divider"})

            local Divider2 = Instance.new('Frame')
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.72
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Theme.Divider
            Divider2.ZIndex = 4
            Divider2.Parent = Header
            table.insert(Library._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "Divider"})

            local Options = Instance.new('ScrollingFrame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 2)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.ZIndex = 3
            Options.Parent = Module
            Options.ScrollBarThickness = 2
            Options.ScrollBarImageTransparency = 0.5
            Options.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Options.CanvasSize = UDim2.new(0, 0, 0, 0)
            Options.ClipsDescendants = true

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout_Opts = Instance.new('UIListLayout')
            UIListLayout_Opts.Padding = UDim.new(0, 7)
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
                    TweenService:Create(Module, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Group,
                        Position = UDim2.new(1, -14, 0.5, 0)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Control
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.TextDim,
                        Position = UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                if settings.callback then settings.callback(self._state) end
                Config:save(game.GameId, Library._config)
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then return end
                Library._keybind_list[settings.flag] = settings.title or "Module"
                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if self._locked then return end
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then return end
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty)
                if Library._config._keybinds[settings.flag] and not empty then
                    local s = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    local fp = Instance.new('GetTextBoundsParams')
                    fp.Text = s
                    fp.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                    fp.Size = 10
                    fp.Width = 10000
                    local fs = TextService:GetTextBoundsAsync(fp)
                    Keybind.Size = UDim2.fromOffset(math.max(38, fs.X + 12), 16)
                else
                    Keybind.Size = UDim2.fromOffset(38, 16)
                end
            end

            if Library._config._flags[settings.flag] == nil then
                Library._config._flags[settings.flag] = false
            end
            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                if settings.callback then settings.callback(ModuleManager._state) end
                if ModuleManager._state then
                    Toggle.BackgroundColor3 = Theme.Accent
                    Circle.BackgroundColor3 = Theme.Group
                    Circle.Position = UDim2.new(1, -14, 0.5, 0)
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
                Keybind.BackgroundColor3 = Theme.ControlHover

                local choose_conn, cancel_conn
                local function finish()
                    Library._choosing_keybind = false
                    Keybind.BackgroundColor3 = Theme.Control
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
                if ModuleManager._locked then return end
                ModuleManager:change_state(not ModuleManager._state)
            end)

            -- Lock toggle
            local function updateLockVisual()
                LockButton.ImageColor3 = ModuleManager._locked and Color3.fromRGB(255, 65, 65) or Theme.TextDim
            end
            local function setInteractable(state)
                for _, d in ipairs(Module:GetDescendants()) do
                    if d == LockButton then continue end
                    if d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("TextBox") then
                        d.Active = state
                        d.Selectable = state
                        if d:IsA("TextButton") or d:IsA("ImageButton") then
                            d.AutoButtonColor = state
                        end
                    end
                end
            end
            LockButton.MouseButton1Click:Connect(function()
                ModuleManager._locked = not ModuleManager._locked
                updateLockVisual()
                setInteractable(not ModuleManager._locked)
            end)
            updateLockVisual()

            -- ── Widgets ──────────────────────────────────────
            function ModuleManager:create_checkbox(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local CM = { _state = false }
                if self._size == 0 then self._size = 11 end
                self._size += 28
                ModuleManager:refresh_size()

                local Row = Instance.new("TextButton")
                Row.Name = "ToggleRow"
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.Text = ""
                Row.AutoButtonColor = false
                Row.ZIndex = 4
                Row.Parent = Options
                Row.LayoutOrder = LayoutOrderModule

                local Label = Instance.new("TextLabel")
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextSize = 12
                Label.TextColor3 = Theme.TextSoft
                Label.Text = s.title or "Toggle"
                Label.Size = UDim2.new(1, -64, 1, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.ZIndex = 5
                Label.Parent = Row
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "TextSoft"})

                local KeybindBox = Instance.new("TextButton")
                KeybindBox.Size = UDim2.fromOffset(16, 16)
                KeybindBox.Position = UDim2.new(1, -38, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(1, 0.5)
                KeybindBox.BackgroundColor3 = Theme.Control
                KeybindBox.AutoButtonColor = false
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Text = ""
                KeybindBox.ZIndex = 5
                KeybindBox.Parent = Row
                table.insert(Library._elements, {obj = KeybindBox, prop = "BackgroundColor3", tKey = "Control"})

                local KBCorner = Instance.new("UICorner")
                KBCorner.CornerRadius = UDim.new(0, 2)
                KBCorner.Parent = KeybindBox

                local KBStroke = Instance.new("UIStroke")
                KBStroke.Color = Theme.GroupStroke
                KBStroke.Transparency = 0.72
                KBStroke.Thickness = 1
                KBStroke.Parent = KeybindBox
                table.insert(Library._elements, {obj = KBStroke, prop = "Color", tKey = "GroupStroke"})

                local KBLabel = Instance.new("TextLabel")
                KBLabel.Size = UDim2.new(1, -4, 1, 0)
                KBLabel.Position = UDim2.new(0, 2, 0, 0)
                KBLabel.BackgroundTransparency = 1
                KBLabel.TextColor3 = Theme.TextSoft
                KBLabel.TextSize = 9
                KBLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KBLabel.Text = "..."
                KBLabel.ZIndex = 6
                KBLabel.Parent = KeybindBox
                table.insert(Library._elements, {obj = KBLabel, prop = "TextColor3", tKey = "TextSoft"})

                local Toggle = Instance.new("Frame")
                Toggle.Size = UDim2.fromOffset(31, 17)
                Toggle.Position = UDim2.new(1, 0, 0.5, 0)
                Toggle.AnchorPoint = Vector2.new(1, 0.5)
                Toggle.BackgroundColor3 = Theme.Control
                Toggle.BorderSizePixel = 0
                Toggle.ZIndex = 5
                Toggle.Parent = Row
                table.insert(Library._elements, {obj = Toggle, prop = "BackgroundColor3", tKey = "Control"})

                local ToggleStroke = Instance.new("UIStroke")
                ToggleStroke.Color = Theme.GroupStroke
                ToggleStroke.Transparency = 0.62
                ToggleStroke.Thickness = 1
                ToggleStroke.Parent = Toggle
                table.insert(Library._elements, {obj = ToggleStroke, prop = "Color", tKey = "GroupStroke"})

                local ToggleCorner = Instance.new("UICorner")
                ToggleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCorner.Parent = Toggle

                local Knob = Instance.new("Frame")
                Knob.Size = UDim2.fromOffset(13, 13)
                Knob.Position = UDim2.new(0, 2, 0.5, 0)
                Knob.AnchorPoint = Vector2.new(0, 0.5)
                Knob.BackgroundColor3 = Theme.TextDim
                Knob.BorderSizePixel = 0
                Knob.ZIndex = 6
                Knob.Parent = Toggle
                table.insert(Library._elements, {obj = Knob, prop = "BackgroundColor3", tKey = "TextDim"})

                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(1, 0)
                KnobCorner.Parent = Knob

                local function resize_kb()
                    local txt = KBLabel.Text
                    if txt == '...' then KeybindBox.Size = UDim2.fromOffset(16, 16) return end
                    local fp = Instance.new('GetTextBoundsParams')
                    fp.Text = txt
                    fp.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                    fp.Size = 9
                    fp.Width = 10000
                    local fs = TextService:GetTextBoundsAsync(fp)
                    KeybindBox.Size = UDim2.fromOffset(math.max(16, fs.X + 10), 16)
                end

                function CM:change_state(state)
                    self._state = state
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Theme.Accent or Theme.Control
                    }):Play()
                    TweenService:Create(Knob, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = state and Theme.Group or Theme.TextDim,
                        Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    }):Play()
                    Library._config._flags[s.flag] = self._state
                    if s.callback then s.callback(self._state) end
                    Config:save(game.GameId, Library._config)
                end

                if Library._config._flags[s.flag] == nil then
                    Library._config._flags[s.flag] = false
                end
                if Library:flag_type(s.flag, "boolean") then
                    CM._state = Library._config._flags[s.flag]
                    if CM._state then
                        Toggle.BackgroundColor3 = Theme.Accent
                        Knob.BackgroundColor3 = Theme.Group
                        Knob.Position = UDim2.new(1, -15, 0.5, 0)
                    end
                    if s.callback then s.callback(CM._state) end
                end

                if Library._config._keybinds[s.flag] then
                    KBLabel.Text = string.gsub(tostring(Library._config._keybinds[s.flag]), "Enum.KeyCode.", "")
                    Library._keybind_list[s.flag] = s.title or "Toggle"
                end
                resize_kb()

                Library._keybind_registry[s.flag] = function(key)
                    if key then
                        KBLabel.Text = string.gsub(tostring(key), "Enum.KeyCode.", "")
                        Library._keybind_list[s.flag] = s.title or "Toggle"
                    else
                        KBLabel.Text = "..."
                        Library._keybind_list[s.flag] = nil
                    end
                    resize_kb()
                end

                KeybindBox.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KBLabel.Text = "..."
                    local conn, cancel
                    local function finish()
                        Library._choosing_keybind = false
                        if Library._config._keybinds[s.flag] then
                            KBLabel.Text = string.gsub(tostring(Library._config._keybinds[s.flag]), "Enum.KeyCode.", "")
                        else
                            KBLabel.Text = "..."
                        end
                        resize_kb()
                        if conn then conn:Disconnect() end
                        if cancel then cancel:Disconnect() end
                    end
                    task.defer(function()
                        conn = UserInputService.InputBegan:Connect(function(input, processed)
                            if processed then return end
                            if input.KeyCode == Enum.KeyCode.Unknown then return end
                            if input.KeyCode == Enum.KeyCode.Backspace then
                                Library._config._keybinds[s.flag] = nil
                                Library._keybind_list[s.flag] = nil
                            else
                                Library._config._keybinds[s.flag] = tostring(input.KeyCode)
                                Library._keybind_list[s.flag] = s.title or "Toggle"
                            end
                            Config:save(game.GameId, Library._config)
                            finish()
                        end)
                        cancel = UserInputService.InputBegan:Connect(function(input, processed)
                            if processed then return end
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then finish() end
                        end)
                    end)
                end)

                Row.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    CM:change_state(not CM._state)
                end)

                Connections[s.flag .. "_row_keybind"] = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed or Library._choosing_keybind then return end
                    if ModuleManager._locked then return end
                    local stored = Library._config._keybinds[s.flag]
                    if stored and tostring(input.KeyCode) == stored then
                        CM:change_state(not CM._state)
                    end
                end)

                Library._flag_registry[s.flag] = function(state) CM:change_state(state) end
                return CM
            end

            function ModuleManager:create_slider(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local SM = {}
                if self._size == 0 then self._size = 11 end
                self._size += 40
                ModuleManager:refresh_size()

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 33)
                Slider.BorderSizePixel = 0
                Slider.ZIndex = 4
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 12
                TextLabel.TextColor3 = Theme.TextSoft
                TextLabel.Text = s.title
                TextLabel.Size = UDim2.new(0, 160, 0, 14)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 5
                TextLabel.Parent = Slider
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextSoft"})

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0
                Drag.Position = UDim2.new(0.5, 0, 0.94, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 6)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.Group
                Drag.ZIndex = 5
                Drag.Parent = Slider
                table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Group"})

                local DGCorner = Instance.new('UICorner')
                DGCorner.CornerRadius = UDim.new(1, 0)
                DGCorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 6)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.Accent
                Fill.ZIndex = 6
                Fill.Parent = Drag
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

                local FCorner = Instance.new('UICorner')
                FCorner.CornerRadius = UDim.new(0, 3)
                FCorner.Parent = Fill

                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.Size = UDim2.new(0, 10, 0, 10)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Theme.Accent
                Circle.ZIndex = 7
                Circle.Parent = Fill
                table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "Accent"})

                local CCorner = Instance.new('UICorner')
                CCorner.CornerRadius = UDim.new(1, 0)
                CCorner.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.TextSoft
                Value.Text = '50'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.ZIndex = 5
                Value.Parent = Slider
                table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "TextSoft"})

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
                    TweenService:Create(Fill, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
                    if s.callback then s.callback(val) end
                    Config:save(game.GameId, Library._config)
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

            function ModuleManager:create_dual_slider(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local SM = { _min = s.minimum_value, _max = s.maximum_value }
                if Library._config._flags[s.flag] then
                    local saved = Library._config._flags[s.flag]
                    if type(saved) == "table" and #saved >= 2 then
                        SM._min = saved[1]; SM._max = saved[2]
                    end
                end
                if self._size == 0 then self._size = 11 end
                self._size += 40
                ModuleManager:refresh_size()

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Size = UDim2.new(0, 207, 0, 33)
                Slider.BorderSizePixel = 0
                Slider.ZIndex = 4
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextSize = 12
                Label.TextColor3 = Theme.TextSoft
                Label.Text = s.title
                Label.Size = UDim2.new(0, 160, 0, 14)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.ZIndex = 5
                Label.Parent = Slider
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "TextSoft"})

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0
                Drag.Position = UDim2.new(0.5, 0, 0.94, 0)
                Drag.Size = UDim2.new(0, 207, 0, 6)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.Group
                Drag.ZIndex = 5
                Drag.Parent = Slider
                table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Group"})
                Instance.new("UICorner", Drag).CornerRadius = UDim.new(1, 0)

                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Size = UDim2.new(0, 0, 0, 6)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Theme.Accent
                Fill.ZIndex = 6
                Fill.Parent = Drag
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})
                Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

                local MinCircle = Instance.new('Frame')
                MinCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                MinCircle.Size = UDim2.new(0, 10, 0, 10)
                MinCircle.BackgroundColor3 = Theme.Accent
                MinCircle.BorderSizePixel = 0
                MinCircle.ZIndex = 7
                MinCircle.Parent = Drag
                table.insert(Library._elements, {obj = MinCircle, prop = "BackgroundColor3", tKey = "Accent"})
                Instance.new("UICorner", MinCircle).CornerRadius = UDim.new(1, 0)

                local MaxCircle = MinCircle:Clone()
                MaxCircle.ZIndex = 7
                MaxCircle.Parent = Drag

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.TextSoft
                Value.Size = UDim2.new(0, 80, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.ZIndex = 5
                Value.Parent = Slider
                table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "TextSoft"})

                function SM:update_visuals()
                    local range = s.maximum_value - s.minimum_value
                    local minP = (self._min - s.minimum_value) / range
                    local maxP = (self._max - s.minimum_value) / range
                    Fill.Position = UDim2.new(minP, 0, 0.5, 0)
                    Fill.Size = UDim2.new(maxP - minP, 0, 1, 0)
                    MinCircle.Position = UDim2.new(minP, 0, 0.5, 0)
                    MaxCircle.Position = UDim2.new(maxP, 0, 0.5, 0)
                    Value.Text = string.format("%d - %d", math.floor(self._min), math.floor(self._max))
                    Library._config._flags[s.flag] = {math.floor(self._min), math.floor(self._max)}
                    if s.callback then s.callback({self._min, self._max}) end
                end

                function SM:input(isMin)
                    local conn
                    conn = mouse.Move:Connect(function()
                        local p = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                        local v = s.minimum_value + (s.maximum_value - s.minimum_value) * p
                        if isMin then
                            self._min = math.clamp(v, s.minimum_value, self._max)
                        else
                            self._max = math.clamp(v, self._min, s.maximum_value)
                        end
                        self:update_visuals()
                    end)
                    Connections['dual_input_'..s.flag] = UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                        conn:Disconnect()
                        Connections:disconnect('dual_input_'..s.flag)
                        Config:save(game.GameId, Library._config)
                    end)
                end

                Slider.MouseButton1Down:Connect(function()
                    if ModuleManager._locked then return end
                    local p = math.clamp((mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset, 0, 1)
                    local v = s.minimum_value + (s.maximum_value - s.minimum_value) * p
                    SM:input(math.abs(v - SM._min) < math.abs(v - SM._max))
                end)

                SM:update_visuals()
                return SM
            end

            function ModuleManager:create_dropdown(s)
                if not s.Order then LayoutOrderModule = LayoutOrderModule + 1 end
                local DM = { _state = false, _size = 0 }
                if not s.Order then
                    if self._size == 0 then self._size = 11 end
                    self._size += 53
                    ModuleManager:refresh_size()
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 210, 0, 45)
                Dropdown.BorderSizePixel = 0
                Dropdown.ZIndex = 4
                Dropdown.Parent = Options
                Dropdown.LayoutOrder = (not s.Order) and LayoutOrderModule or s.OrderValue

                if not Library._config._flags[s.flag] then
                    Library._config._flags[s.flag] = {}
                end

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Theme.TextSoft
                TextLabel.Text = s.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 5
                TextLabel.Parent = Dropdown
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextSoft"})

                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0
                Box.Position = UDim2.new(0.5, 0, 1.3, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 210, 0, 28)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Control
                Box.ZIndex = 5
                Box.Parent = TextLabel
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})

                local BCorner = Instance.new('UICorner')
                BCorner.CornerRadius = UDim.new(0, 5)
                BCorner.Parent = Box

                local BStroke = Instance.new('UIStroke')
                BStroke.Color = Theme.GroupStroke
                BStroke.Transparency = 0.48
                BStroke.Thickness = 1
                BStroke.Parent = Box
                table.insert(Library._elements, {obj = BStroke, prop = "Color", tKey = "GroupStroke"})

                local Header = Instance.new('Frame')
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Size = UDim2.new(0, 210, 0, 28)
                Header.ZIndex = 6
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Theme.TextSoft
                CurrentOption.Size = UDim2.new(0, 164, 0, 16)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0, 10, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.TextSize = 11
                CurrentOption.ZIndex = 7
                CurrentOption.Parent = Header
                table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "TextSoft"})

                local Arrow = Instance.new('ImageLabel')
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Theme.TextDim
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(1, -16, 0.5, 0)
                Arrow.Size = UDim2.new(0, 9, 0, 9)
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

                local OptionsLayout = Instance.new('UIListLayout')
                OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptionsLayout.Parent = OptionsList

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, 4)
                UIPadding.PaddingLeft = UDim.new(0, 11)
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
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
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
                    TweenService:Create(Dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 45 + extra)
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(210, 28 + extra)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = self._state and 180 or 0
                    }):Play()
                end

                function DM:refresh(new_options)
                    local old_size = self._size
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child.Name == 'Option' then child:Destroy() end
                    end
                    self._size = 8
                    for index, value in new_options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.TextTransparency = 0.5
                        Option.TextSize = 11
                        Option.Size = UDim2.new(0, 184, 0, 19)
                        Option.TextColor3 = Theme.TextSoft
                        Option.Text = tostring(value)
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.ZIndex = 8
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "TextSoft"})
                        Option.MouseButton1Click:Connect(function() DM:update(value) end)
                        if s.maximum_options and index > s.maximum_options then continue end
                        self._size = self._size + 19
                        OptionsList.Size = UDim2.fromOffset(210, self._size)
                    end
                    if self._state then
                        local diff = self._size - old_size
                        ModuleManager._multiplier = ModuleManager._multiplier + diff
                        ModuleManager:refresh_size()
                    end
                end

                if #s.options > 0 then
                    DM._size = 8
                    for index, value in s.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.TextTransparency = 0.5
                        Option.TextSize = 11
                        Option.Size = UDim2.new(0, 184, 0, 19)
                        Option.TextColor3 = Theme.TextSoft
                        Option.Text = (typeof(value) == "string" and value) or value.Name
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.ZIndex = 8
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "TextSoft"})

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
                        DM._size = DM._size + 19
                        OptionsList.Size = UDim2.fromOffset(210, DM._size)
                    end
                end

                if Library:flag_type(s.flag, 'string') or Library:flag_type(s.flag, 'table') then
                    DM:update(Library._config._flags[s.flag])
                elseif s.options[1] then
                    DM:update(s.options[1])
                end

                Dropdown.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    DM:unfold_settings()
                end)

                Library._flag_registry[s.flag] = function(v) DM:update(v) end
                return DM
            end

            function ModuleManager:create_textbox(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local TM = { _text = "" }
                if self._size == 0 then self._size = 11 end
                self._size += 32
                ModuleManager:refresh_size()

                local Holder = Instance.new('Frame')
                Holder.Size = UDim2.fromOffset(207, 23)
                Holder.BackgroundTransparency = 1
                Holder.LayoutOrder = LayoutOrderModule
                Holder.Parent = Options

                local Box = Instance.new('TextBox')
                Box.AnchorPoint = Vector2.new(0, 1)
                Box.Position = UDim2.new(0, 0, 1, 0)
                Box.Size = UDim2.fromOffset(207, 22)
                Box.BackgroundColor3 = Theme.Control
                Box.BorderSizePixel = 0
                Box.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Box.TextColor3 = Theme.TextSoft
                Box.TextSize = 12
                Box.PlaceholderText = s.placeholder or ''
                Box.PlaceholderColor3 = Theme.TextDim
                Box.ClearTextOnFocus = false
                Box.ZIndex = 5
                Box.Parent = Holder
                table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Box, prop = "TextColor3", tKey = "TextSoft"})
                table.insert(Library._elements, {obj = Box, prop = "PlaceholderColor3", tKey = "TextDim"})

                local Corner = Instance.new('UICorner')
                Corner.CornerRadius = UDim.new(0, 4)
                Corner.Parent = Box

                local Stroke = Instance.new('UIStroke')
                Stroke.Color = Theme.GroupStroke
                Stroke.Transparency = 0.72
                Stroke.Thickness = 1
                Stroke.Parent = Box
                table.insert(Library._elements, {obj = Stroke, prop = "Color", tKey = "GroupStroke"})

                if Library._config._flags[s.flag] ~= nil then
                    Box.Text = Library._config._flags[s.flag]
                else
                    Box.Text = s.value or ''
                end

                Box.FocusLost:Connect(function()
                    if ModuleManager._locked then return end
                    TM._text = Box.Text
                    Library._config._flags[s.flag] = Box.Text
                    if s.callback then s.callback(Box.Text) end
                    Config:save(game.GameId, Library._config)
                end)

                Library._flag_registry[s.flag] = function(v) Box.Text = v or '' end
                return Box
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
                Btn.BackgroundColor3 = Theme.Control
                Btn.BorderSizePixel = 0
                Btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Btn.TextColor3 = Theme.TextSoft
                Btn.TextSize = 12
                Btn.AutoButtonColor = false
                Btn.Text = s.title or 'Button'
                Btn.ZIndex = 5
                Btn.Parent = Holder
                table.insert(Library._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Btn, prop = "TextColor3", tKey = "TextSoft"})

                local Corner = Instance.new('UICorner')
                Corner.CornerRadius = UDim.new(0, 4)
                Corner.Parent = Btn

                local Stroke = Instance.new('UIStroke')
                Stroke.Color = Theme.GroupStroke
                Stroke.Transparency = 0.72
                Stroke.Thickness = 1
                Stroke.Parent = Btn
                table.insert(Library._elements, {obj = Stroke, prop = "Color", tKey = "GroupStroke"})

                Btn.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    if s.callback then s.callback() end
                end)
            end

            function ModuleManager:create_divider(s)
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 27
                ModuleManager:refresh_size()

                local Outer = Instance.new('Frame')
                Outer.Size = UDim2.new(0, 207, 0, 20)
                Outer.BackgroundTransparency = 1
                Outer.LayoutOrder = LayoutOrderModule
                Outer.ZIndex = 4
                Outer.Parent = Options

                if s and s.showtopic then
                    local T = Instance.new('TextLabel')
                    T.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    T.TextColor3 = Theme.TextSoft
                    T.Text = s.title
                    T.Size = UDim2.new(0, 153, 0, 13)
                    T.Position = UDim2.new(0.5, 0, 0.5, 0)
                    T.BackgroundTransparency = 1
                    T.TextXAlignment = Enum.TextXAlignment.Center
                    T.AnchorPoint = Vector2.new(0.5, 0.5)
                    T.TextSize = 11
                    T.ZIndex = 5
                    T.Parent = Outer
                    table.insert(Library._elements, {obj = T, prop = "TextColor3", tKey = "TextSoft"})
                end

                if not s or not s.disableline then
                    local D = Instance.new('Frame')
                    D.Size = UDim2.new(1, 0, 0, 1)
                    D.BackgroundColor3 = Theme.TextSoft
                    D.BorderSizePixel = 0
                    D.Position = UDim2.new(0, 0, 0.5, -0.5)
                    D.ZIndex = 5
                    D.Parent = Outer
                    table.insert(Library._elements, {obj = D, prop = "BackgroundColor3", tKey = "TextSoft"})
                    local G = Instance.new('UIGradient')
                    G.Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    }
                    G.Parent = D
                end
            end

            function ModuleManager:create_paragraph(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local PM = {}
                if self._size == 0 then self._size = 11 end
                self._size += s.customScale or 70
                ModuleManager:refresh_size()

                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Theme.Control
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.ZIndex = 4
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Paragraph, prop = "BackgroundColor3", tKey = "Control"})

                local PCorner = Instance.new('UICorner')
                PCorner.CornerRadius = UDim.new(0, 4)
                PCorner.Parent = Paragraph

                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Theme.TextSoft
                Title.Text = s.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.ZIndex = 5
                Title.Parent = Paragraph
                table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "TextSoft"})

                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Theme.TextDim
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
                Body.Parent = Paragraph
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

                return PM
            end

            function ModuleManager:create_colorpicker(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local CPM = { _color = s.default or Color3.fromRGB(255, 0, 0), _h = 0, _s = 1, _v = 1 }
                do
                    local h, sat, v = Color3.toHSV(CPM._color)
                    CPM._h = h; CPM._s = sat; CPM._v = v
                end
                if Library._config._flags[s.flag] then
                    local sv = Library._config._flags[s.flag]
                    if type(sv) == "table" and sv.R then
                        local c = Color3.fromRGB(sv.R, sv.G, sv.B)
                        CPM._color = c
                        local h, sat, v = Color3.toHSV(c)
                        CPM._h = h; CPM._s = sat; CPM._v = v
                    end
                end
                if self._size == 0 then self._size = 11 end
                self._size += 32
                ModuleManager:refresh_size()

                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(0, 207, 0, 22)
                Row.BackgroundTransparency = 1
                Row.LayoutOrder = LayoutOrderModule
                Row.ZIndex = 4
                Row.Parent = Options

                local Label = Instance.new("TextLabel")
                Label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Theme.TextSoft
                Label.Text = s.title or "Color"
                Label.Size = UDim2.new(1, -30, 1, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 11
                Label.ZIndex = 5
                Label.Parent = Row
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "TextSoft"})

                local Swatch = Instance.new("TextButton")
                Swatch.Size = UDim2.new(0, 22, 0, 22)
                Swatch.Position = UDim2.new(1, -22, 0, 0)
                Swatch.BackgroundColor3 = CPM._color
                Swatch.BorderSizePixel = 0
                Swatch.Text = ""
                Swatch.AutoButtonColor = false
                Swatch.ZIndex = 5
                Swatch.Parent = Row
                Instance.new("UICorner", Swatch).CornerRadius = UDim.new(0, 5)
                local SS = Instance.new("UIStroke", Swatch)
                SS.Color = Theme.GroupStroke
                SS.Transparency = 0.5
                table.insert(Library._elements, {obj = SS, prop = "Color", tKey = "GroupStroke"})

                local POPUP_H = 180
                local popupOpen = false

                local Popup = Instance.new("Frame")
                Popup.Size = UDim2.new(0, 207, 0, 0)
                Popup.BackgroundColor3 = Theme.Background
                Popup.BorderSizePixel = 0
                Popup.ClipsDescendants = true
                Popup.LayoutOrder = LayoutOrderModule
                Popup.ZIndex = 5
                Popup.Parent = Options
                Instance.new("UICorner", Popup).CornerRadius = UDim.new(0, 7)
                local PS = Instance.new("UIStroke", Popup)
                PS.Color = Theme.GroupStroke
                PS.Transparency = 0.4
                table.insert(Library._elements, {obj = Popup, prop = "BackgroundColor3", tKey = "Background"})

                local Inner = Instance.new("Frame")
                Inner.Size = UDim2.new(1, 0, 0, POPUP_H)
                Inner.BackgroundTransparency = 1
                Inner.Parent = Popup

                local SQ = 145
                local SvSquare = Instance.new("TextButton")
                SvSquare.Size = UDim2.new(0, SQ, 0, SQ)
                SvSquare.Position = UDim2.new(0, 8, 0, 10)
                SvSquare.BackgroundColor3 = Color3.fromHSV(CPM._h, 1, 1)
                SvSquare.BorderSizePixel = 0
                SvSquare.Text = ""
                SvSquare.AutoButtonColor = false
                SvSquare.ZIndex = 6
                SvSquare.Parent = Inner
                Instance.new("UICorner", SvSquare).CornerRadius = UDim.new(0, 5)

                local WhiteGrad = Instance.new("Frame")
                WhiteGrad.Size = UDim2.new(1, 0, 1, 0)
                WhiteGrad.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                WhiteGrad.BorderSizePixel = 0
                WhiteGrad.Parent = SvSquare
                Instance.new("UICorner", WhiteGrad).CornerRadius = UDim.new(0, 5)
                local WG = Instance.new("UIGradient", WhiteGrad)
                WG.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
                WG.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                }

                local BlackGrad = Instance.new("Frame")
                BlackGrad.Size = UDim2.new(1, 0, 1, 0)
                BlackGrad.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                BlackGrad.BorderSizePixel = 0
                BlackGrad.Parent = SvSquare
                Instance.new("UICorner", BlackGrad).CornerRadius = UDim.new(0, 5)
                local BG = Instance.new("UIGradient", BlackGrad)
                BG.Color = ColorSequence.new(Color3.fromRGB(0,0,0))
                BG.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                }
                BG.Rotation = 90

                local Picker = Instance.new("Frame")
                Picker.Size = UDim2.new(0, 10, 0, 10)
                Picker.AnchorPoint = Vector2.new(0.5, 0.5)
                Picker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Picker.BorderSizePixel = 0
                Picker.ZIndex = 7
                Picker.Position = UDim2.new(CPM._s, 0, 1 - CPM._v, 0)
                Picker.Parent = SvSquare
                Instance.new("UICorner", Picker).CornerRadius = UDim.new(1, 0)
                local PStk = Instance.new("UIStroke", Picker)
                PStk.Color = Color3.fromRGB(0,0,0)
                PStk.Thickness = 1.5

                local HueStrip = Instance.new("TextButton")
                HueStrip.Size = UDim2.new(0, 14, 0, SQ)
                HueStrip.Position = UDim2.new(0, 8 + SQ + 6, 0, 10)
                HueStrip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueStrip.BorderSizePixel = 0
                HueStrip.Text = ""
                HueStrip.AutoButtonColor = false
                HueStrip.ZIndex = 6
                HueStrip.Parent = Inner
                Instance.new("UICorner", HueStrip).CornerRadius = UDim.new(0, 4)

                local HueGrad = Instance.new("UIGradient", HueStrip)
                HueGrad.Rotation = 90
                local kp = {}
                for i = 0, 6 do
                    kp[i+1] = ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1))
                end
                HueGrad.Color = ColorSequence.new(kp)

                local HueCursor = Instance.new("Frame")
                HueCursor.Size = UDim2.new(1, 4, 0, 3)
                HueCursor.Position = UDim2.new(0, -2, CPM._h, -1)
                HueCursor.AnchorPoint = Vector2.new(0, 0.5)
                HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueCursor.BorderSizePixel = 0
                HueCursor.ZIndex = 7
                HueCursor.Parent = HueStrip
                Instance.new("UICorner", HueCursor).CornerRadius = UDim.new(1, 0)

                local BottomRow = Instance.new("Frame")
                BottomRow.Size = UDim2.new(1, -16, 0, 22)
                BottomRow.Position = UDim2.new(0, 8, 0, 10 + SQ + 8)
                BottomRow.BackgroundTransparency = 1
                BottomRow.Parent = Inner

                local PreviewSwatch = Instance.new("Frame")
                PreviewSwatch.Size = UDim2.new(0, 22, 0, 22)
                PreviewSwatch.BackgroundColor3 = CPM._color
                PreviewSwatch.BorderSizePixel = 0
                PreviewSwatch.ZIndex = 6
                PreviewSwatch.Parent = BottomRow
                Instance.new("UICorner", PreviewSwatch).CornerRadius = UDim.new(0, 5)

                local HexBox = Instance.new("TextBox")
                HexBox.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                HexBox.TextColor3 = Theme.TextSoft
                HexBox.PlaceholderText = "FF0000"
                HexBox.Text = ""
                HexBox.TextSize = 10
                HexBox.Size = UDim2.new(1, -34, 1, 0)
                HexBox.Position = UDim2.new(0, 30, 0, 0)
                HexBox.BackgroundColor3 = Theme.Control
                HexBox.BackgroundTransparency = 0.3
                HexBox.BorderSizePixel = 0
                HexBox.ClearTextOnFocus = false
                HexBox.ZIndex = 6
                HexBox.Parent = BottomRow
                Instance.new("UICorner", HexBox).CornerRadius = UDim.new(0, 4)

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
                    CPM._h = h; CPM._s = sat; CPM._v = v
                    local color = Color3.fromHSV(h, sat, v)
                    CPM._color = color
                    SvSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    Picker.Position = UDim2.new(math.clamp(sat, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)
                    HueCursor.Position = UDim2.new(0, -2, math.clamp(h, 0, 0.9999), -1)
                    Swatch.BackgroundColor3 = color
                    PreviewSwatch.BackgroundColor3 = color
                    if not skipHex then HexBox.Text = colorToHex(color) end
                    Library._config._flags[s.flag] = {
                        R = math.round(color.R * 255),
                        G = math.round(color.G * 255),
                        B = math.round(color.B * 255)
                    }
                    if s.callback then s.callback(color) end
                    Config:save(game.GameId, Library._config)
                end

                function CPM:set_color(color)
                    local h, sat, v = Color3.toHSV(color)
                    applyColor(h, sat, v)
                end

                applyColor(CPM._h, CPM._s, CPM._v)

                local svDragging = false
                local function updateSV()
                    local rx = math.clamp((mouse.X - SvSquare.AbsolutePosition.X) / SvSquare.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((mouse.Y - SvSquare.AbsolutePosition.Y) / SvSquare.AbsoluteSize.Y, 0, 1)
                    applyColor(CPM._h, rx, 1 - ry)
                end
                SvSquare.MouseButton1Down:Connect(function()
                    if ModuleManager._locked then return end
                    svDragging = true; updateSV()
                end)
                Connections["sv_move_"..s.flag] = UserInputService.InputChanged:Connect(function(inp)
                    if svDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                        updateSV()
                    end
                end)
                Connections["sv_end_"..s.flag] = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        svDragging = false
                    end
                end)

                local hueDragging = false
                local function updateHue()
                    local ry = math.clamp((mouse.Y - HueStrip.AbsolutePosition.Y) / HueStrip.AbsoluteSize.Y, 0, 0.9999)
                    applyColor(ry, CPM._s, CPM._v)
                end
                HueStrip.MouseButton1Down:Connect(function()
                    if ModuleManager._locked then return end
                    hueDragging = true; updateHue()
                end)
                Connections["hue_move_"..s.flag] = UserInputService.InputChanged:Connect(function(inp)
                    if hueDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                        updateHue()
                    end
                end)
                Connections["hue_end_"..s.flag] = UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = false
                    end
                end)

                HexBox.FocusLost:Connect(function()
                    if ModuleManager._locked then
                        HexBox.Text = colorToHex(CPM._color); return
                    end
                    local color = hexToColor(HexBox.Text)
                    if color then
                        local h, sat, v = Color3.toHSV(color)
                        applyColor(h, sat, v, true)
                    else
                        HexBox.Text = colorToHex(CPM._color)
                    end
                end)

                Swatch.MouseButton1Click:Connect(function()
                    if ModuleManager._locked then return end
                    popupOpen = not popupOpen
                    if popupOpen then
                        self._size += POPUP_H
                        ModuleManager:refresh_size()
                        TweenService:Create(Popup, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, POPUP_H)
                        }):Play()
                    else
                        self._size -= POPUP_H
                        ModuleManager:refresh_size()
                        TweenService:Create(Popup, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                            Size = UDim2.fromOffset(207, 0)
                        }):Play()
                    end
                end)

                return CPM
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
                Btn.BackgroundColor3 = Theme.Control
                Btn.TextColor3 = Theme.TextSoft
                Btn.Text = "    " .. (s.title or "Feature")
                Btn.AutoButtonColor = false
                Btn.TextXAlignment = Enum.TextXAlignment.Left
                Btn.ZIndex = 5
                Btn.Parent = FC
                table.insert(Library._elements, {obj = Btn, prop = "BackgroundColor3", tKey = "Control"})
                table.insert(Library._elements, {obj = Btn, prop = "TextColor3", tKey = "TextSoft"})

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
                KBBox.BackgroundColor3 = Theme.Accent
                KBBox.TextColor3 = Theme.TextSoft
                KBBox.TextSize = 11
                KBBox.BackgroundTransparency = 1
                KBBox.LayoutOrder = 2
                KBBox.ZIndex = 5
                KBBox.Parent = RC
                table.insert(Library._elements, {obj = KBBox, prop = "BackgroundColor3", tKey = "Accent"})
                table.insert(Library._elements, {obj = KBBox, prop = "TextColor3", tKey = "TextSoft"})

                local KBButton = Instance.new("TextButton")
                KBButton.Size = UDim2.new(1, 0, 1, 0)
                KBButton.BackgroundTransparency = 1
                KBButton.Text = ""
                KBButton.ZIndex = 6
                KBButton.Parent = KBBox

                Instance.new("UICorner", KBBox).CornerRadius = UDim.new(0, 3)
                local KBStroke = Instance.new("UIStroke", KBBox)
                KBStroke.Color = Theme.Accent
                KBStroke.Thickness = 1
                table.insert(Library._elements, {obj = KBStroke, prop = "Color", tKey = "Accent"})

                if not Library._config._flags[s.flag] then
                    Library._config._flags[s.flag] = { checked = false }
                end
                checked = Library._config._flags[s.flag].checked
                local savedKey = Library._config._keybinds[s.flag]
                KBBox.Text = savedKey and string.gsub(savedKey, "Enum.KeyCode.", "") or "..."

                local UseF
                if not s.disablecheck then
                    local Cb = Instance.new("TextButton")
                    Cb.Size = UDim2.new(0, 15, 0, 15)
                    Cb.BackgroundColor3 = checked and Theme.Accent or Theme.Control
                    Cb.Text = ""
                    Cb.ZIndex = 5
                    Cb.Parent = RC
                    Cb.LayoutOrder = 1
                    table.insert(Library._elements, {obj = Cb, prop = "BackgroundColor3", tKey = "Accent"})

                    local CbStroke = Instance.new("UIStroke", Cb)
                    CbStroke.Color = Theme.Accent
                    CbStroke.Thickness = 1
                    table.insert(Library._elements, {obj = CbStroke, prop = "Color", tKey = "Accent"})

                    Instance.new("UICorner", Cb).CornerRadius = UDim.new(0, 3)

                    local function toggle()
                        checked = not checked
                        Cb.BackgroundColor3 = checked and Theme.Accent or Theme.Control
                        Library._config._flags[s.flag].checked = checked
                        if s.callback then s.callback(checked) end
                        Config:save(game.GameId, Library._config)
                    end
                    UseF = toggle
                    Cb.MouseButton1Click:Connect(function()
                        if ModuleManager._locked then return end
                        toggle()
                    end)
                else
                    UseF = function() if s.button_callback then s.button_callback() end end
                end

                KBButton.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KBBox.Text = "..."
                    local conn
                    task.defer(function()
                        conn = UserInputService.InputBegan:Connect(function(input, processed)
                            if processed then return end
                            if input.KeyCode == Enum.KeyCode.Unknown then return end
                            if input.KeyCode == Enum.KeyCode.Backspace then
                                Library._config._keybinds[s.flag] = nil
                                Library._keybind_list[s.flag] = nil
                                KBBox.Text = "..."
                            else
                                Library._config._keybinds[s.flag] = tostring(input.KeyCode)
                                Library._keybind_list[s.flag] = s.title or "Feature"
                                KBBox.Text = input.KeyCode.Name
                            end
                            Config:save(game.GameId, Library._config)
                            Library._choosing_keybind = false
                            if conn then conn:Disconnect() end
                        end)
                    end)
                end)

                local keyPress = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if Library._config._keybinds[s.flag] and tostring(input.KeyCode) == Library._config._keybinds[s.flag] then
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

            task.defer(function() ModuleManager:refresh_size() end)
            return ModuleManager
        end

        return TabManager
    end

    -- ─── Visibility handler (reads Minimize_Keybind) ────────
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

return Library

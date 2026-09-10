getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled", CheckboxDisabled = "Disabled",
        SliderValue = "Value", DropdownSelect = "Select",
        DropdownNone = "None", DropdownSelected = "Selected",
        ButtonClick = "Click", TextboxEnter = "Enter",
        ModuleEnabled = "Enabled", ModuleDisabled = "Disabled",
        TabGeneral = "General", TabSettings = "Settings",
        Loading = "Loading...", Error = "Error", Success = "Success"
    }
}

local SelectedLanguage = getgenv().GG.Language

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

local DefaultTheme = {
    Background = Color3.fromRGB(12, 13, 15),
    Group = Color3.fromRGB(22, 28, 38),
    GroupStroke = Color3.fromRGB(52, 66, 89),
    Control = Color3.fromRGB(32, 38, 51),
    ControlHover = Color3.fromRGB(42, 50, 66),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(161, 208, 42),
}

local Library = {
    _config = nil,
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
    _notif_opacity = 0.1,
}
Library.__index = Library

function Library:RandomString() : string
	return string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))..string.char(math.random(60,120))
end

local UIACProtection = protect_gui or protectgui or (syn and syn.protect_gui) or function() end
local UIName = Library:RandomString()

local SecureScreenGui = Instance.new('ScreenGui')
SecureScreenGui.Name = UIName
SecureScreenGui.Parent = (gethui and gethui()) or CoreGui
SecureScreenGui.ResetOnSpawn = false
SecureScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

UIACProtection(SecureScreenGui)

function Library:Hook()
	if hookfunc or hookfunction then
		local hooking = hookfunc or hookfunction or function() end
		hooking(game:GetService('ContentProvider').PreloadAsync, function() return 1 end)
		hooking(game:GetService('ContentProvider').Preload, function() return 2 end)
		hooking(game:GetService('ContentProvider').GetAssetFetchStatus, function() return 3 end)
	end
end
Library:Hook()

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

local CONFIG_DIR = "AchaoticUI/AllusiveModified"
if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
if not isfolder(CONFIG_DIR.."/Configs") then makefolder(CONFIG_DIR.."/Configs") end

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
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y
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
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old_folder then Debris:AddItem(old_folder, 0) end
    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera
    self._folder = folder
end

function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting
    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then continue end
        if object == depth_of_fields then continue end
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
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)
    specialMesh.Parent = part
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
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right
        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)
        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude
        if not self._root then return end
        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end
    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        update_positions(size, position)
        task.spawn(update)
    end
    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)
    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    task.spawn(update)
end

function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value
    if quality_level < 8 then self:change_visiblity(false) end
    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value
        self:change_visiblity(quality_level >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state)
    self._root.Transparency = state and 0.98 or 1
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local ok, result = pcall(function()
            writefile(CONFIG_DIR..'/'..file_name..'.json', HttpService:JSONEncode(config))
        end)
        if not ok then warn('failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local ok, result = pcall(function()
            local path = CONFIG_DIR..'/'..file_name..'.json'
            if not isfile(path) then
                self:save(file_name, config)
                return config
            end
            local flags = readfile(path)
            if not flags then
                self:save(file_name, config)
                return config
            end
            return HttpService:JSONDecode(flags)
        end)
        if not ok then warn('failed to load config', result) end
        if not result then result = { _flags = {}, _keybinds = {}, _library = {} } end
        return result
    end
}, Config)

Library._config = Config:load(game.GameId, { _flags = {}, _keybinds = {}, _library = {} })

function Library.new(config)
    local self = setmetatable({ _loaded = false, _tab = 0 }, Library)
    local currentconfig = config or {
        title = "Achaotic",
        PrimaryColor = Color3.fromRGB(161, 208, 42),
    }
    self:create_ui(currentconfig)
    return self
end

-- Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.Parent = SecureScreenGui
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.ZIndex = 500

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

local function UpdateNotificationPosition()
    if Library._notif_side == "Left" then
        NotificationContainer.AnchorPoint = Vector2.new(0, 0)
        NotificationContainer.Position = UDim2.new(0, 10, 0, 10)
    else
        NotificationContainer.AnchorPoint = Vector2.new(0, 0)
        NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
    end
end
UpdateNotificationPosition()

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
    InnerFrame.BackgroundTransparency = math.clamp(Library._notif_opacity, 0, 1)
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Color3.fromRGB(210, 210, 210)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.AutomaticSize = Enum.AutomaticSize.Y
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Color3.fromRGB(180, 180, 180)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = InnerFrame

    task.spawn(function()
        wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()
        wait(settings.duration or 5)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function() Notification:Destroy() end)
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
    for _, el in ipairs(Library._elements) do
        if el.tKey == key then
            pcall(function() el.obj[el.prop] = color end)
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
    Container.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = SecureScreenGui
    self._container = Container
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(52, 66, 89)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

    -- Background image (added by the interface tab)
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
    local BgCorner = Instance.new('UICorner')
    BgCorner.CornerRadius = UDim.new(0, 10)
    BgCorner.Parent = Background

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = "Handler"
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
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
    ClientName.ZIndex = 2
    ClientName.Parent = Handler
    table.insert(Library._elements, {obj = ClientName, prop = "TextColor3", tKey = "Accent"})

    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = config.PrimaryColor
    Pin.ZIndex = 2
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
    Icon.ZIndex = 2
    Icon.Parent = Handler
    table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "Accent"})

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.235, 0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
    Divider.ZIndex = 2
    Divider.Parent = Handler
    table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "GroupStroke"})

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.TextSize = 14
    Minimize.ZIndex = 2
    Minimize.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

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

    function self:load()
        local content = {}
        for _, object in SecureScreenGui:GetDescendants() do
            if not object:IsA('ImageLabel') then continue end
            table.insert(content, object)
        end
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end

        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
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
                        TextColor3 = config.PrimaryColor
                    }):Play()
                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = config.PrimaryColor
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
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
        Tab.ZIndex = 2
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        table.insert(Library._elements, {obj = Tab, prop = "BackgroundColor3", tKey = "Group"})

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.240, 0, 0.5, 0)
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
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.ZIndex = 3
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
        LeftSection.ZIndex = 2
        LeftSection.Parent = Sections

        local UIListLayout_L = Instance.new('UIListLayout')
        UIListLayout_L.Padding = UDim.new(0, 11)
        UIListLayout_L.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_L.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_L.Parent = LeftSection

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

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
        RightSection.ZIndex = 2
        RightSection.Parent = Sections

        local UIListLayout_R = Instance.new('UIListLayout')
        UIListLayout_R.Padding = UDim.new(0, 11)
        UIListLayout_R.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_R.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_R.Parent = RightSection

        local UIPadding2 = Instance.new('UIPadding')
        UIPadding2.PaddingTop = UDim.new(0, 1)
        UIPadding2.Parent = RightSection

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
            local ModuleManager = { _state = false, _size = 0, _multiplier = 0 }

            local SectionFrame = (settings.section == 'right') and RightSection or LeftSection

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
            Module.ZIndex = 2
            Module.Parent = SectionFrame
            table.insert(Library._elements, {obj = Module, prop = "BackgroundColor3", tKey = "Group"})

            local ModuleListLayout = Instance.new('UIListLayout')
            ModuleListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ModuleListLayout.Parent = Module

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(52, 66, 89)
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.ZIndex = 3
            Header.Parent = Module

            local ModIcon = Instance.new('ImageLabel')
            ModIcon.ImageColor3 = config.PrimaryColor
            ModIcon.ScaleType = Enum.ScaleType.Fit
            ModIcon.ImageTransparency = 0.7
            ModIcon.AnchorPoint = Vector2.new(0, 0.5)
            ModIcon.Image = 'rbxassetid://79095934438045'
            ModIcon.BackgroundTransparency = 1
            ModIcon.Position = UDim2.new(0.071, 0, 0.82, 0)
            ModIcon.Name = 'Icon'
            ModIcon.Size = UDim2.new(0, 15, 0, 15)
            ModIcon.BorderSizePixel = 0
            ModIcon.ZIndex = 4
            ModIcon.Parent = Header
            table.insert(Library._elements, {obj = ModIcon, prop = "ImageColor3", tKey = "Accent"})

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = config.PrimaryColor
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
            table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "Accent"})

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = config.PrimaryColor
            Description.TextTransparency = 0.7
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.073, 0, 0.42, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.TextSize = 10
            Description.ZIndex = 4
            Description.Parent = Header

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.7
            Toggle.Position = UDim2.new(0.82, 0, 0.757, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.ZIndex = 4
            Toggle.Parent = Header

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
            Circle.BackgroundColor3 = Color3.fromRGB(66, 80, 115)
            Circle.ZIndex = 5
            Circle.Parent = Toggle

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle

            local Keybind = Instance.new('TextButton')
Keybind.Name = 'Keybind'
Keybind.Text = ''
Keybind.AutoButtonColor = false
Keybind.BackgroundTransparency = 0.7
Keybind.Position = UDim2.new(0.15, 0, 0.735, 0)
Keybind.Size = UDim2.new(0, 33, 0, 15)
Keybind.BorderSizePixel = 0
Keybind.BackgroundColor3 = config.PrimaryColor
Keybind.ZIndex = 4
Keybind.Parent = Header
            table.insert(Library._elements, {obj = Keybind, prop = "BackgroundColor3", tKey = "Accent"})

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind

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

            local Divider = Instance.new('Frame')
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider.ZIndex = 4
            Divider.Parent = Header
            table.insert(Library._elements, {obj = Divider, prop = "BackgroundColor3", tKey = "GroupStroke"})

            local Divider2 = Instance.new('Frame')
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.5
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider2.ZIndex = 4
            Divider2.Parent = Header
            table.insert(Library._elements, {obj = Divider2, prop = "BackgroundColor3", tKey = "GroupStroke"})

            local Options = Instance.new('ScrollingFrame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
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

            local UIListLayout_Opt = Instance.new('UIListLayout')
            UIListLayout_Opt.Padding = UDim.new(0, 5)
            UIListLayout_Opt.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_Opt.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Opt.Parent = Options

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
                        BackgroundColor3 = config.PrimaryColor
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = config.PrimaryColor,
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
                        BackgroundColor3 = Color3.fromRGB(66, 80, 115),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end
                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)
                settings.callback(self._state)
            end

            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then return end
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
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    KeybindText.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    KeybindText.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = Library._config._flags[settings.flag]
                settings.callback(ModuleManager._state)
                if ModuleManager._state then
                    Toggle.BackgroundColor3 = config.PrimaryColor
                    Circle.BackgroundColor3 = config.PrimaryColor
                    Circle.Position = UDim2.fromScale(0.53, 0.5)
                    Module.Size = UDim2.fromOffset(241, 93)
                else
                    Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    Circle.BackgroundColor3 = Color3.fromRGB(66, 80, 115)
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
                Keybind.BackgroundColor3 = Color3.fromRGB(42, 50, 66)

                local choose_conn, cancel_conn

                local function finish()
                    Library._choosing_keybind = false
                    Keybind.BackgroundColor3 = config.PrimaryColor
                    if Library._config._keybinds[settings.flag] then
                        KeybindText.Text = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    else
                        KeybindText.Text = 'None'
                    end
                    if choose_conn then choose_conn:Disconnect() end
                    if cancel_conn then cancel_conn:Disconnect() end
                end

                choose_conn = UserInputService.InputBegan:Connect(function(input, process)
                    if process then return end
                    if input.KeyCode == Enum.KeyCode.Unknown then return end
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

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local ParagraphManager = {}
                if self._size == 0 then self._size = 11 end
                self._size += settings.customScale or 70
                ModuleManager:refresh_size()

                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30)
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y
                Paragraph.ZIndex = 3
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Paragraph, prop = "BackgroundColor3", tKey = "Control"})

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph

                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(210, 210, 210)
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.ZIndex = 4
                Title.Parent = Paragraph
                table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
                Body.Text = settings.text or "Paragraph"
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.ZIndex = 4
                Body.Parent = Paragraph
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(42, 50, 66)
                    }):Play()
                end)
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(32, 38, 51)
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
                TextFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize or 30)
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y
                TextFrame.ZIndex = 3
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = TextFrame, prop = "BackgroundColor3", tKey = "Control"})

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame

                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
                Body.Text = settings.text or "Text"
                Body.Size = UDim2.new(1, -10, 1, -10)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.ZIndex = 4
                Body.Parent = TextFrame
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(42, 50, 66)
                    }):Play()
                end)
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    Body.Text = new_settings.text or "Text"
                end
                return TextManager
            end

            function ModuleManager:create_textbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local TextboxManager = { _text = "" }
                if self._size == 0 then self._size = 11 end
                self._size += 32
                ModuleManager:refresh_size()

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 10
                Label.ZIndex = 4
                Label.Parent = Options
                Label.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "Text"})

                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = config.PrimaryColor
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.ZIndex = 4
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Textbox, prop = "TextColor3", tKey = "Text"})

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

                Library._flag_registry[settings.flag] = function(v)
                    TextboxManager:update_text(v)
                end
                return TextboxManager
            end

            function ModuleManager:create_checkbox(settings)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
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
                Checkbox.ZIndex = 3
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TitleLabel.TextSize = 11
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Checkbox"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.ZIndex = 4
                TitleLabel.Parent = Checkbox
                table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

                local Box = Instance.new("Frame")
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = config.PrimaryColor
                Box.ZIndex = 4
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
                Fill.BackgroundColor3 = config.PrimaryColor
                Fill.ZIndex = 5
                Fill.Parent = Box
                table.insert(Library._elements, {obj = Fill, prop = "BackgroundColor3", tKey = "Accent"})

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill

                function CheckboxManager:change_state(state)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.7 }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(9, 9) }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.9 }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(0, 0) }):Play()
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
                self._size += 26
                ModuleManager:refresh_size()

                local Button = Instance.new("TextButton")
                Button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextTransparency = 0.2
                Button.Text = settings.title or "Button"
                Button.AutoButtonColor = true
                Button.BackgroundTransparency = 0.2
                Button.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                Button.Name = "Button"
                Button.Size = UDim2.new(0, 207, 0, 26)
                Button.BorderSizePixel = 0
                Button.TextSize = 11
                Button.ZIndex = 4
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
                self._size += 27
                ModuleManager:refresh_size()

                local Slider = Instance.new('TextButton')
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.ZIndex = 3
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 4
                TextLabel.Parent = Slider
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = config.PrimaryColor
                Drag.ZIndex = 4
                Drag.Parent = Slider
                table.insert(Library._elements, {obj = Drag, prop = "BackgroundColor3", tKey = "Accent"})

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag

                local Fill = Instance.new('Frame')
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = config.PrimaryColor
                Fill.ZIndex = 5
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
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.ZIndex = 6
                Circle.Parent = Fill

                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.2
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.TextSize = 10
                Value.ZIndex = 4
                Value.Parent = Slider
                table.insert(Library._elements, {obj = Value, prop = "TextColor3", tKey = "Text"})

                function SliderManager:set_percentage(percentage)
                    local rounded_number
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
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
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
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function() SliderManager:update() end)
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
                Slider.MouseButton1Down:Connect(function() SliderManager:input() end)

                Library._flag_registry[settings.flag] = function(v) SliderManager:set_percentage(v) end
                return SliderManager
            end

            function ModuleManager:create_dropdown(settings)
                if not settings.Order then LayoutOrderModule = LayoutOrderModule + 1 end
                local DropdownManager = { _state = false, _size = 0 }

                if not settings.Order then
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
                Dropdown.ZIndex = 3
                Dropdown.Parent = Options
                Dropdown.LayoutOrder = LayoutOrderModule

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {}
                end

                local TextLabel = Instance.new('TextLabel')
                TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TextLabel.TextSize = 11
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 4
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
                Box.BackgroundColor3 = config.PrimaryColor
                Box.ZIndex = 4
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
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.ZIndex = 4
                Header.Parent = Box

                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.2
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.05, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.TextSize = 10
                CurrentOption.ZIndex = 5
                CurrentOption.Parent = Header
                table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "Text"})

                local Arrow = Instance.new('ImageLabel')
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Color3.fromRGB(180, 180, 180)
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.ZIndex = 5
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
                OptionsList.ZIndex = 5
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

                function DropdownManager:unfold_settings()
                    self._state = not self._state
                    if self._state then
                        ModuleManager._multiplier = ModuleManager._multiplier + self._size
                    else
                        ModuleManager._multiplier = ModuleManager._multiplier - self._size
                    end
                    ModuleManager:refresh_size()

                    TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 39 + (self._state and self._size or 0))
                    }):Play()
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(207, 22 + (self._state and self._size or 0))
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Text = (typeof(value) == "string" and value) or value.Name
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.05, 0, 0.342, 0)
                        Option.BorderSizePixel = 0
                        Option.ZIndex = 6
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
                        DropdownManager._size = DropdownManager._size + 16
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
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Text = tostring(value)
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.05, 0, 0.342, 0)
                        Option.BorderSizePixel = 0
                        Option.ZIndex = 6
                        Option.Parent = OptionsList
                        table.insert(Library._elements, {obj = Option, prop = "TextColor3", tKey = "Text"})

                        Option.MouseButton1Click:Connect(function()
                            DropdownManager:update(value)
                        end)

                        if settings.maximum_options and index > settings.maximum_options then continue end
                        self._size = self._size + 16
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
                Dropdown.MouseButton1Click:Connect(function() DropdownManager:unfold_settings() end)
                Library._flag_registry[settings.flag] = function(v) DropdownManager:update(v) end
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
                OuterFrame.ZIndex = 3
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    TextLabel.TextSize = 11
                    TextLabel.ZIndex = 4
                    TextLabel.Parent = OuterFrame
                end

                if not settings or (settings and not settings.disableline) then
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, 1)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.ZIndex = 4
                    Divider.Position = UDim2.new(0, 0, 0.5, -0.5)
                    Divider.Parent = OuterFrame
                end
                return true
            end

            function ModuleManager:create_feature(settings)
                local checked = false
                LayoutOrderModule = LayoutOrderModule + 1
                if self._size == 0 then self._size = 11 end
                self._size += 20
                ModuleManager:refresh_size()

                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.ZIndex = 3
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule

                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer

                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                FeatureButton.TextSize = 11
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                FeatureButton.TextColor3 = Color3.fromRGB(210, 210, 210)
                FeatureButton.Text = "    " .. (settings.title or "Feature")
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.ZIndex = 4
                FeatureButton.Parent = FeatureContainer
                table.insert(Library._elements, {obj = FeatureButton, prop = "BackgroundColor3", tKey = "Control"})

                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.ZIndex = 4
                RightContainer.Parent = FeatureContainer

                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer

                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = config.PrimaryColor
                KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2
                KeybindBox.ZIndex = 5
                KeybindBox.Parent = RightContainer

                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.Text = ""
                KeybindButton.ZIndex = 5
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = config.PrimaryColor
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "Accent"})

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = { checked = false }
                end
                checked = Library._config._flags[settings.flag].checked
                local savedKey = Library._config._keybinds[settings.flag]
                KeybindBox.Text = savedKey and string.gsub(savedKey, "Enum.KeyCode.", "") or "..."

                local UseF_Var = nil
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and config.PrimaryColor or Color3.fromRGB(32, 38, 51)
                    Checkbox.Text = ""
                    Checkbox.ZIndex = 5
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1
                    table.insert(Library._elements, {obj = Checkbox, prop = "BackgroundColor3", tKey = "Control"})

                    local UIStroke2 = Instance.new("UIStroke", Checkbox)
                    UIStroke2.Color = config.PrimaryColor
                    UIStroke2.Thickness = 1
                    UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    table.insert(Library._elements, {obj = UIStroke2, prop = "Color", tKey = "Accent"})

                    local CheckboxCorner2 = Instance.new("UICorner")
                    CheckboxCorner2.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner2.Parent = Checkbox

                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and config.PrimaryColor or Color3.fromRGB(32, 38, 51)
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then settings.callback(checked) end
                    end
                    UseF_Var = toggleState
                    Checkbox.MouseButton1Click:Connect(toggleState)
                else
                    UseF_Var = function() if settings.button_callback then settings.button_callback() end end
                end

                KeybindButton.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KeybindBox.Text = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.KeyCode == Enum.KeyCode.Unknown then return end
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            Library._config._keybinds[settings.flag] = nil
                            Library._keybind_list[settings.flag] = nil
                            KeybindBox.Text = "..."
                        else
                            Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                            Library._keybind_list[settings.flag] = settings.title or "Feature"
                            KeybindBox.Text = input.KeyCode.Name
                        end
                        Config:save(game.GameId, Library._config)
                        Library._choosing_keybind = false
                        if conn then conn:Disconnect() end
                    end)
                end)

                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if Library._config._keybinds[settings.flag] and tostring(input.KeyCode) == Library._config._keybinds[settings.flag] then
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

            task.defer(function() ModuleManager:refresh_size() end)
            return ModuleManager
        end

        return TabManager
    end

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
    local saved_tab = self._tab
    self._tab = 9999
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007')
    self._tab = saved_tab + 1

    local Handler = self._handler

    -- ── Configurations ───────────────────────────────────────
    local config_module = InterfaceTab:create_module({
        title = 'Configurations',
        flag = 'UI_Config_System',
        description = 'Save and load profiles',
        section = 'right',
        callback = function() end,
    })

    local function get_configs()
        if not (isfolder and listfiles) then return {} end
        local dir = CONFIG_DIR..'/Configs'
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
            local name = name_box._text
            if typeof(name) ~= 'string' or name:gsub("%s","") == "" then
                self:Notify({title = 'Config', text = 'Enter a valid name.', duration = 3})
                return
            end
            Config:save('Configs/'..name, Library._config)
            list_drop:refresh(get_configs())
            list_drop:update(name)
            self:Notify({title = 'Config', text = 'Saved '..name, duration = 3})
        end,
    })

    config_module:create_button({
        title = 'Load Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then
                self:Notify({title = 'Config', text = 'Select a profile.', duration = 3})
                return
            end
            local loaded = Config:load('Configs/'..name, { _flags = {}, _keybinds = {} })

            -- wipe registry-known flags so old profile values don't bleed
            for flag in pairs(Library._flag_registry) do
                Library._config._flags[flag] = nil
            end
            -- also wipe theme/bg keys
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
            if typeof(s) == "string" then
                Library:SetBackground(s, Library._config._flags['Background_Transparency'] or 0.5)
            end

            self:Notify({title = 'Config', text = 'Loaded '..name, duration = 3})
        end,
    })

    config_module:create_button({
        title = 'Delete Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then return end
            local path = CONFIG_DIR..'/Configs/'..name..'.json'
            if isfile and isfile(path) then
                delfile(path)
                list_drop:refresh(get_configs())
                self:Notify({title = 'Config', text = 'Deleted '..name, duration = 3})
            end
        end,
    })

    -- ── Appearance (color picker) ────────────────────────────
    local color_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'Gui_Colors',
        description = 'Customize UI colors',
        section = 'left',
        callback = function() end,
    })

    -- find the module frame in the section
    local function find_module(title)
        for _, o in ipairs(Handler.Sections:GetDescendants()) do
            if o.Name == 'Module' then
                local h = o:FindFirstChild('Header')
                local n = h and h:FindFirstChild('ModuleName')
                if n and n.Text == title then return o end
            end
        end
    end

    local color_frame = find_module('Appearance')
    local Color_Targets = { 'Background', 'Group', 'GroupStroke', 'Control', 'ControlHover', 'Text', 'TextDim', 'Accent' }
    local Swatches = {}
    local Selected = 'Background'
    local Ptr_Offset = Vector2.zero
    local H, S, V = 0, 0, 1

    if color_frame then
        local Opts = color_frame.Options

        local Popup = Instance.new('Frame')
        Popup.Name = 'ColorPopup'
        Popup.Size = UDim2.fromOffset(214, 144)
        Popup.BackgroundColor3 = Color3.fromRGB(14, 20, 24)
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 30
        Popup.Parent = Handler
        local PC = Instance.new('UICorner'); PC.CornerRadius = UDim.new(0,9); PC.Parent = Popup
        local PS = Instance.new('UIStroke'); PS.Color = Color3.fromRGB(52,66,89); PS.Parent = Popup

        local Field = Instance.new('TextButton')
        Field.Position = UDim2.fromOffset(10,10)
        Field.Size = UDim2.fromOffset(194,100)
        Field.BackgroundColor3 = Color3.fromRGB(255,0,0)
        Field.BorderSizePixel = 0
        Field.ClipsDescendants = true
        Field.AutoButtonColor = false
        Field.Text = ''
        Field.ZIndex = 31
        Field.Parent = Popup
        local FC = Instance.new('UICorner'); FC.CornerRadius = UDim.new(0,5); FC.Parent = Field

        local Sat = Instance.new('Frame')
        Sat.Size = UDim2.new(1,0,1,0)
        Sat.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Sat.BorderSizePixel = 0
        Sat.ZIndex = 32
        Sat.Parent = Field
        local SG = Instance.new('UIGradient')
        SG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}
        SG.Parent = Sat

        local Bri = Instance.new('Frame')
        Bri.Size = UDim2.new(1,0,1,0)
        Bri.BackgroundColor3 = Color3.fromRGB(0,0,0)
        Bri.BorderSizePixel = 0
        Bri.ZIndex = 33
        Bri.Parent = Field
        local BG = Instance.new('UIGradient')
        BG.Rotation = 90
        BG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}
        BG.Parent = Bri

        local Cursor = Instance.new('Frame')
        Cursor.AnchorPoint = Vector2.new(0.5,0.5)
        Cursor.Size = UDim2.fromOffset(11,11)
        Cursor.BackgroundTransparency = 1
        Cursor.BorderSizePixel = 0
        Cursor.ZIndex = 34
        Cursor.Parent = Field
        local CC = Instance.new('UICorner'); CC.CornerRadius = UDim.new(1,0); CC.Parent = Cursor
        local CS = Instance.new('UIStroke'); CS.Color = Color3.fromRGB(255,255,255); CS.Thickness = 2; CS.Parent = Cursor

        local Hue = Instance.new('TextButton')
        Hue.Position = UDim2.fromOffset(10, 120)
        Hue.Size = UDim2.fromOffset(194, 12)
        Hue.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Hue.BorderSizePixel = 0
        Hue.AutoButtonColor = false
        Hue.Text = ''
        Hue.ZIndex = 31
        Hue.Parent = Popup
        local HC = Instance.new('UICorner'); HC.CornerRadius = UDim.new(1,0); HC.Parent = Hue
        local HG = Instance.new('UIGradient')
        HG.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
        }
        HG.Parent = Hue

        local Knob = Instance.new('Frame')
        Knob.AnchorPoint = Vector2.new(0.5,0.5)
        Knob.Size = UDim2.fromOffset(5,16)
        Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Knob.BorderSizePixel = 0
        Knob.ZIndex = 32
        Knob.Parent = Hue
        local KC = Instance.new('UICorner'); KC.CornerRadius = UDim.new(1,0); KC.Parent = Knob

        local function apply(h,s,v)
            H,S,V = h,s,v
            local c = Color3.fromHSV(h,s,v)
            Field.BackgroundColor3 = Color3.fromHSV(h,1,1)
            Cursor.Position = UDim2.new(s,0,1-v,0)
            Knob.Position = UDim2.new(h,0,0.5,0)
            Swatches[Selected].BackgroundColor3 = c
            self:SetColor(Selected, c)
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
            local s = math.clamp((loc.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
            local v = 1 - math.clamp((loc.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
            apply(H, s, v)
        end

        local function updateHue()
            local loc = UserInputService:GetMouseLocation() + Ptr_Offset
            local h = math.clamp((loc.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
            apply(h, S, V)
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
            for _, sw in ipairs(Swatches) do
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
            local sc = Handler.AbsoluteSize.X / 698
            local rx = (sw.AbsolutePosition.X - Handler.AbsolutePosition.X) / sc
            local ry = (sw.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / sc
            Popup.Position = UDim2.fromOffset(
                math.clamp(rx - 224, 8, 470),
                math.clamp(ry - 62, 8, 327)
            )
            Popup.Visible = true
            local h,s,v = Color3.toHSV(DefaultTheme[target])
            apply(h,s,v)
        end

        Field.MouseButton1Down:Connect(function() drag('field', Field, updateField) end)
        Hue.MouseButton1Down:Connect(function() drag('hue', Hue, updateHue) end)

        for i, target in ipairs(Color_Targets) do
            local Row = Instance.new('TextButton')
            Row.Size = UDim2.fromOffset(207, 24)
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
            T.ZIndex = 5
            T.Parent = Row

            local Sw = Instance.new('TextButton')
            Sw.AnchorPoint = Vector2.new(1,0.5)
            Sw.Position = UDim2.new(1,0,0.5,0)
            Sw.Size = UDim2.fromOffset(34,18)
            Sw.BackgroundColor3 = DefaultTheme[target]
            Sw.BorderSizePixel = 0
            Sw.AutoButtonColor = false
            Sw.Text = ''
            Sw.ZIndex = 5
            Sw.Parent = Row
            local SC = Instance.new('UICorner'); SC.CornerRadius = UDim.new(0,4); SC.Parent = Sw
            local SS = Instance.new('UIStroke'); SS.Color = Color3.fromRGB(52,66,89); SS.Transparency = 0.5; SS.Parent = Sw

            Sw.MouseButton1Click:Connect(function() openPopup(target, Sw) end)
            Row.MouseButton1Click:Connect(function() openPopup(target, Sw) end)

            Swatches[target] = Sw
        end

        local ResetRow = Instance.new('TextButton')
        ResetRow.Size = UDim2.fromOffset(207, 26)
        ResetRow.BackgroundColor3 = Color3.fromRGB(32,38,51)
        ResetRow.TextColor3 = Color3.fromRGB(255,255,255)
        ResetRow.TextSize = 12
        ResetRow.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        ResetRow.Text = 'Reset'
        ResetRow.AutoButtonColor = false
        ResetRow.ZIndex = 4
        ResetRow.LayoutOrder = #Color_Targets + 3
        ResetRow.Parent = Opts
        local RC = Instance.new('UICorner'); RC.CornerRadius = UDim.new(0,4); RC.Parent = ResetRow
        table.insert(Library._elements, {obj = ResetRow, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(Library._elements, {obj = ResetRow, prop = "TextColor3", tKey = "Text"})
        ResetRow.MouseButton1Click:Connect(function()
            closePopup()
            for k, v in pairs(DefaultTheme) do
                self:SetColor(k, v)
                if Swatches[k] then Swatches[k].BackgroundColor3 = v end
            end
        end)

        color_module._size = 282
        Opts.Size = UDim2.fromOffset(241, color_module._size)
        if color_module._state then
            color_frame.Size = UDim2.fromOffset(241, 93 + color_module._size + color_module._multiplier)
        end
    end

    -- ── Background ───────────────────────────────────────────
    local bg_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'UI_Background',
        description = 'Custom background image',
        section = 'right',
        callback = function(state)
            if not self._background then return end
            self._background.Visible = state and self._background.Image ~= ''
        end,
    })

    local Presets = {
        ['None'] = '',
        ['Preset 1'] = 'rbxassetid://130856415047448',
        ['Preset 2'] = 'rbxassetid://116035002211409',
        ['Preset 3'] = 'rbxassetid://136977985711277',
        ['Preset 4'] = 'rbxassetid://119507933448984',
        ['Preset 5'] = 'rbxassetid://80397454951960',
    }

    local saved_id = Library._config._flags['Background_Image_Id'] or ''
    local bg_id = typeof(saved_id) == 'string' and saved_id or ''
    local Asset_Input

    local preset_drop = bg_module:create_dropdown({
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
            self:SetBackground(src, Library._config._flags['Background_Transparency'] or 0.5)
            Library._config._flags['Background_Image_Id'] = src
        end,
    })

    local trans_slider = bg_module:create_slider({
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

    -- Asset ID / URL textbox (built manually so we can hook FocusLost)
    local bg_frame = find_module('Background')
    if bg_frame then
        local Row = Instance.new('Frame')
        Row.Name = 'AssetRow'
        Row.Size = UDim2.fromOffset(207, 28)
        Row.BackgroundTransparency = 1
        Row.ZIndex = 4
        Row.LayoutOrder = 0
        Row.Parent = bg_frame.Options

        local Input = Instance.new('TextBox')
        Input.Name = 'AssetId'
        Input.AnchorPoint = Vector2.new(0, 0.5)
        Input.Position = UDim2.new(0, 0, 0.5, 0)
        Input.Size = UDim2.fromOffset(207, 26)
        Input.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
        Input.BackgroundTransparency = 0.2
        Input.BorderSizePixel = 0
        Input.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Input.TextColor3 = Color3.fromRGB(255, 255, 255)
        Input.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
        Input.PlaceholderText = 'Asset ID or rbxassetid://'
        Input.TextSize = 11
        Input.ClearTextOnFocus = false
        Input.Text = bg_id
        Input.ZIndex = 5
        Input.Parent = Row
        table.insert(Library._elements, {obj = Input, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(Library._elements, {obj = Input, prop = "TextColor3", tKey = "Text"})

        Asset_Input = Input

        local InputCorner = Instance.new('UICorner')
        InputCorner.CornerRadius = UDim.new(0, 4)
        InputCorner.Parent = Input

        Input.FocusLost:Connect(function()
            local src = Input.Text:match('^%s*(.-)%s*$')
            Input.Text = src
            bg_id = src
            self:SetBackground(src, Library._config._flags['Background_Transparency'] or 0.5)
            Library._config._flags['Background_Image_Id'] = src
        end)

        -- reset button
        local ResetRow = Instance.new('TextButton')
        ResetRow.Size = UDim2.fromOffset(207, 26)
        ResetRow.BackgroundColor3 = Color3.fromRGB(32,38,51)
        ResetRow.TextColor3 = Color3.fromRGB(255,255,255)
        ResetRow.TextSize = 12
        ResetRow.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        ResetRow.Text = 'Reset'
        ResetRow.AutoButtonColor = false
        ResetRow.ZIndex = 4
        ResetRow.LayoutOrder = 4
        ResetRow.Parent = bg_frame.Options
        local RC = Instance.new('UICorner'); RC.CornerRadius = UDim.new(0,4); RC.Parent = ResetRow
        table.insert(Library._elements, {obj = ResetRow, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(Library._elements, {obj = ResetRow, prop = "TextColor3", tKey = "Text"})
        ResetRow.MouseButton1Click:Connect(function()
            Input.Text = ''
            bg_id = ''
            preset_drop:update('None')
            trans_slider:set_percentage(50)
            Library._config._flags['Background_Image_Id'] = ''
            self:SetBackground('', 0.5)
        end)

        bg_module._size = bg_module._size + 60
        bg_frame.Options.Size = UDim2.fromOffset(241, bg_module._size)
        if bg_module._state then
            bg_frame.Size = UDim2.fromOffset(241, 93 + bg_module._size + bg_module._multiplier)
        end
    end

    -- ── Notifications ────────────────────────────────────────
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
        value = 10,
        round_number = true,
        callback = function(value)
            Library._notif_opacity = math.clamp(value / 100, 0, 1)
            for _, notif in ipairs(NotificationContainer:GetChildren()) do
                local inner = notif:FindFirstChild("InnerFrame")
                if inner then inner.BackgroundTransparency = Library._notif_opacity end
            end
        end,
    })

    -- ── Minimize Key ─────────────────────────────────────────
    local min_module = InterfaceTab:create_module({
        title = 'Minimize Key',
        flag = 'UI_Minimize_Key',
        description = 'Press-to-bind toggle key',
        section = 'left',
        callback = function() end,
    })

    local min_frame = find_module('Minimize Key')
    local min_keybox

    if min_frame then
        local Row = Instance.new('Frame')
        Row.Size = UDim2.fromOffset(207, 26)
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
        table.insert(Library._elements, {obj = Lbl, prop = "TextColor3", tKey = "Text"})

        min_keybox = Instance.new('TextButton')
        min_keybox.Name = 'Keybox'
        min_keybox.AnchorPoint = Vector2.new(1, 0.5)
        min_keybox.Position = UDim2.new(1, 0, 0.5, 0)
        min_keybox.Size = UDim2.fromOffset(60, 20)
        min_keybox.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
        min_keybox.BorderSizePixel = 0
        min_keybox.AutoButtonColor = false
        min_keybox.Text = ''
        min_keybox.ZIndex = 4
        min_keybox.Parent = Row
        table.insert(Library._elements, {obj = min_keybox, prop = "BackgroundColor3", tKey = "Control"})

        local MC = Instance.new('UICorner'); MC.CornerRadius = UDim.new(0,3); MC.Parent = min_keybox
        local MS = Instance.new('UIStroke'); MS.Color = Color3.fromRGB(52,66,89); MS.Transparency = 0.5; MS.Thickness = 1; MS.Parent = min_keybox
        table.insert(Library._elements, {obj = MS, prop = "Color", tKey = "GroupStroke"})

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
        table.insert(Library._elements, {obj = MT, prop = "TextColor3", tKey = "Text"})

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
            min_keybox.BackgroundColor3 = Color3.fromRGB(42,50,66)

            local bind_c, cancel_c
            local function done()
                listening = false
                min_keybox.BackgroundColor3 = Color3.fromRGB(32,38,51)
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

return Library

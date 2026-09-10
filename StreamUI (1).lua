-- ═══════════════════════════════════════════════════════════════
--  Ailon UI — full library with built-in Interface tab
--  Interface tab forced last. Layout preserved.
--  Fix: minimize fully hides Handler content so lines don't leak.
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
if not isfolder("ailon/Icons") then makefolder("ailon/Icons") end

local function convertStringToTable(s)
    local r = {}
    for v in string.gmatch(s, "([^,]+)") do
        table.insert(r, v:match("^%s*(.-)%s*$"))
    end
    return r
end

local Connections = setmetatable({
    disconnect = function(self, c)
        if not self[c] then return end
        self[c]:Disconnect()
        self[c] = nil
    end,
    disconnect_all = function(self)
        for _, v in self do
            if typeof(v) == 'function' then continue end
            v:Disconnect()
        end
    end
}, Connections)

local Util = setmetatable({
    map = function(self, value, in_min, in_max, out_min, out_max)
        return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
    end,
    viewport_point_to_world = function(self, location, distance)
        local r = Workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return r.Origin + r.Direction * distance
    end,
    get_offset = function(self)
        local h = Workspace.CurrentCamera.ViewportSize.Y
        return self:map(h, 0, 2560, 8, 56)
    end
}, Util)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(o)
    local self = setmetatable({_object=o,_folder=nil,_frame=nil,_root=nil}, AcrylicBlur)
    self:setup()
    return self
end

function AcrylicBlur:create_folder()
    local old = Workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old then Debris:AddItem(old, 0) end
    local f = Instance.new('Folder')
    f.Name = 'AcrylicBlur'
    f.Parent = Workspace.CurrentCamera
    self._folder = f
end

function AcrylicBlur:create_depth_of_fields()
    local dof = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    dof.FarIntensity = 0
    dof.FocusDistance = 0.05
    dof.InFocusRadius = 0.1
    dof.NearIntensity = 1
    dof.Name = 'AcrylicBlur'
    dof.Parent = Lighting
    for _, o in Lighting:GetChildren() do
        if not o:IsA('DepthOfFieldEffect') then continue end
        if o == dof then continue end
        Connections[o] = o:GetPropertyChangedSignal('FarIntensity'):Connect(function() o.FarIntensity = 0 end)
        o.FarIntensity = 0
    end
end

function AcrylicBlur:create_frame()
    local f = Instance.new('Frame')
    f.Size = UDim2.new(1,0,1,0)
    f.Position = UDim2.new(0.5,0,0.5,0)
    f.AnchorPoint = Vector2.new(0.5,0.5)
    f.BackgroundTransparency = 1
    f.Parent = self._object
    self._frame = f
end

function AcrylicBlur:create_root()
    local p = Instance.new('Part')
    p.Name = 'Root'
    p.Color = Color3.new(0,0,0)
    p.Material = Enum.Material.Glass
    p.Size = Vector3.new(1,1,0)
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.Locked = true
    p.CastShadow = false
    p.Transparency = 0.98
    p.Parent = self._folder
    local m = Instance.new('SpecialMesh')
    m.MeshType = Enum.MeshType.Brick
    m.Offset = Vector3.new(0,0,-0.000001)
    m.Parent = p
    self._root = p
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
    local pos = {tl=Vector2.new(),tr=Vector2.new(),br=Vector2.new()}
    local function up(size, position)
        pos.tl = position
        pos.tr = position + Vector2.new(size.X, 0)
        pos.br = position + size
    end
    local function update()
        local tl3 = Util:viewport_point_to_world(pos.tl, distance)
        local tr3 = Util:viewport_point_to_world(pos.tr, distance)
        local br3 = Util:viewport_point_to_world(pos.br, distance)
        if not self._root then return end
        local w = (tr3 - tl3).Magnitude
        local h = (tr3 - br3).Magnitude
        self._root.CFrame = CFrame.fromMatrix((tl3+br3)/2,
            Workspace.CurrentCamera.CFrame.XVector,
            Workspace.CurrentCamera.CFrame.YVector,
            Workspace.CurrentCamera.CFrame.ZVector)
        local m = self._root:FindFirstChildOfClass('SpecialMesh')
        if m then m.Scale = Vector3.new(w,h,0) end
    end
    local function on_change()
        local o = Util:get_offset()
        local s = self._frame.AbsoluteSize - Vector2.new(o,o)
        local p = self._frame.AbsolutePosition + Vector2.new(o/2,o/2)
        up(s,p)
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
    local gs = UserSettings().GameSettings
    if gs.SavedQualityLevel.Value < 8 then self:change_visiblity(false) end
    Connections['quality_level'] = gs:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        self:change_visiblity(UserSettings().GameSettings.SavedQualityLevel.Value >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state)
    self._root.Transparency = state and 0.98 or 1
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local ok, err = pcall(function()
            writefile('ailon/'..file_name..'.json', HttpService:JSONEncode(config))
        end)
        if not ok then warn('failed to save config', err) end
    end,
    load = function(self, file_name, config)
        local ok, result = pcall(function()
            local path = 'ailon/'..file_name..'.json'
            if not isfile(path) then
                self:save(file_name, config)
                return config
            end
            local data = readfile(path)
            if not data then
                self:save(file_name, config)
                return config
            end
            return HttpService:JSONDecode(data)
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
for k,v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R,v.G,v.B) or v
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
    local self = setmetatable({ _tab = 0, _interface_built = false }, Library)
    self:create_ui()
    self:build_interface_tab()
    self._interface_built = true
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
    InnerFrame.BackgroundColor3 = Theme.Group
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
    table.insert(Library._elements, {obj = InnerGradient, prop = "Color", tKey = "Gradient"})

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

function Library:resolve_asset(source, folder)
    if not source or source == '' then return '' end
    source = tostring(source):match('^%s*(.-)%s*$')
    if source == '' then return '' end
    if source:match('^%d+$') then return 'rbxassetid://'..source end
    if source:match('^rbx%a+://') then return source end
    local Custom_Asset = getcustomasset or getsynasset
    if not Custom_Asset then return '' end
    local dir = 'ailon/'..(folder or 'Icons')
    if not isfolder(dir) then pcall(makefolder, dir) end
    if source:match('^https?://') then
        if not (writefile and isfile) then return '' end
        local ext = source:match('%.(%a%a%a%a?)[%?#]') or source:match('%.(%a%a%a%a?)$') or 'png'
        local path = dir..'/'..source:gsub('%W',''):sub(-48)..'.'..ext
        if not isfile(path) then
            local ok, body = pcall(game.HttpGet, game, source, true)
            if not ok then return '' end
            pcall(writefile, path, body)
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

local function resolve_background(source)
    if not source or source == '' then return '' end
    source = tostring(source):match('^%s*(.-)%s*$')
    if source == '' then return '' end
    if source:match('^%d+$') then return 'rbxassetid://'..source end
    if source:match('^rbx%a+://') then return source end
    local Custom_Asset = getcustomasset or getsynasset
    if not Custom_Asset then return '' end
    if source:match('^https?://') then
        if not (writefile and isfile) then return '' end
        if not isfolder('ailon/Backgrounds') then makefolder('ailon/Backgrounds') end
        local ext = source:match('%.(%a%a%a%a?)[%?#]') or source:match('%.(%a%a%a%a?)$') or 'png'
        local path = 'ailon/Backgrounds/'..source:gsub('%W',''):sub(-48)..'.'..ext
        if not isfile(path) then
            local ok, body = pcall(game.HttpGet, game, source, true)
            if not ok then return '' end
            pcall(writefile, path, body)
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

-- ═══════════════════════════════════════════════════════════════
--  UI Construction
-- ═══════════════════════════════════════════════════════════════
function Library:create_ui()
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
    Container.BackgroundColor3 = Theme.Background
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
    ClientName.TextColor3 = Theme.Text
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
    TopDivider.BackgroundColor3 = Theme.Divider
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
    SideDivider.BackgroundColor3 = Theme.Divider
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
    Icon.Name = 'Icon'
    Icon.ImageColor3 = Theme.Text
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://138719305710506'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Size = UDim2.new(0, 24, 0, 24)
    Icon.ZIndex = 2
    Icon.Visible = false
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

    -- FIX: minimize now hides Handler so its children don't leak lines
    function self:change_visiblity(state)
        Library._ui_open = state
        if state then
            Handler.Visible = true
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(680, 460)
            }):Play()
        else
            local t = TweenService:Create(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            })
            t:Play()
            t.Completed:Once(function()
                if not Library._ui_open then
                    Handler.Visible = false
                end
            end)
        end
    end

    function self:set_gui_visibility(state)
        if not self._ui then return end
        if state then
            self._ui.Enabled = true
            Handler.Visible = true
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
                Handler.Visible = false
            end)
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
                        TextColor3 = Theme.Text
                    }):Play()
                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()
                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Theme.Text
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
                    TextColor3 = Theme.TextSoft
                }):Play()
                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Theme.TextSoft
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
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.BackgroundColor3 = Theme.Group
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
        TextLabel.TextColor3 = Theme.TextSoft
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
        table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextSoft"})

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
            Module.Size = UDim2.new(0, 241, 0, 100)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Theme.Group
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
            UIStroke.Color = Theme.GroupStroke
            UIStroke.Transparency = 0.7
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            table.insert(Library._elements, {obj = UIStroke, prop = "Color", tKey = "GroupStroke"})

            local Header = Instance.new('TextButton')
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 100)
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
            LockButton.ImageColor3 = Theme.TextDim
            LockButton.ZIndex = 10
            LockButton.Parent = Header
            table.insert(Library._elements, {obj = LockButton, prop = "ImageColor3", tKey = "TextDim"})

            local function updateLockVisual()
                LockButton.ImageColor3 = ModuleManager._locked and Color3.fromRGB(255,65,65) or Theme.TextDim
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
                    ImageColor3 = ModuleManager._locked and Color3.fromRGB(255,100,100) or Color3.fromRGB(220,220,220)
                }):Play()
            end)
            LockButton.MouseLeave:Connect(updateLockVisual)
            updateLockVisual()

            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Theme.TextSoft
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.7
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.055, 0, 0.78, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.ZIndex = 4
            Icon.Parent = Header
            table.insert(Library._elements, {obj = Icon, prop = "ImageColor3", tKey = "TextSoft"})

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Theme.TextSoft
            ModuleName.TextTransparency = 0.2
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 180, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.12, 0, 0.22, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.TextSize = 13
            ModuleName.ZIndex = 4
            ModuleName.Parent = Header
            table.insert(Library._elements, {obj = ModuleName, prop = "TextColor3", tKey = "TextSoft"})

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Theme.TextDim
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
            Toggle.BackgroundTransparency = 0.7
            Toggle.Position = UDim2.new(0.82, 0, 0.79, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Theme.Background
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
            Circle.BackgroundColor3 = Theme.Accent
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
            Keybind.Position = UDim2.new(0.14, 0, 0.78, 0)
            Keybind.Size = UDim2.new(0, 40, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Theme.Accent
            Keybind.ZIndex = 4
            Keybind.Parent = Header
            table.insert(Library._elements, {obj = Keybind, prop = "BackgroundColor3", tKey = "Accent"})

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 3)
            KeybindCorner.Parent = Keybind

            local KeybindText = Instance.new('TextLabel')
            KeybindText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KeybindText.TextColor3 = Theme.TextSoft
            KeybindText.Text = 'None'
            KeybindText.AnchorPoint = Vector2.new(0.5, 0.5)
            KeybindText.Size = UDim2.new(0, 30, 0, 13)
            KeybindText.BackgroundTransparency = 1
            KeybindText.TextXAlignment = Enum.TextXAlignment.Center
            KeybindText.Position = UDim2.new(0.5, 0, 0.5, 0)
            KeybindText.TextSize = 10
            KeybindText.ZIndex = 5
            KeybindText.Parent = Keybind
            table.insert(Library._elements, {obj = KeybindText, prop = "TextColor3", tKey = "TextSoft"})

            local Divider = Instance.new('Frame')
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.68, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Theme.Divider
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
            Divider2.BackgroundColor3 = Theme.Divider
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
                Module.Size = UDim2.fromOffset(241, self._state and (100 + self._size + self._multiplier) or 100)
                Options.Size = UDim2.fromOffset(241, self._size + self._multiplier)
            end

            function ModuleManager:change_state(state)
                self._state = state
                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 100 + self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, self._size + self._multiplier)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent,
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 100)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Background
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Theme.Accent,
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
                    Keybind.Size = UDim2.fromOffset(math.max(40, fs.X + 14), 15)
                    KeybindText.Size = UDim2.fromOffset(fs.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(40, 15)
                    KeybindText.Size = UDim2.fromOffset(30, 13)
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
                    Circle.BackgroundColor3 = Theme.Accent
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
                Keybind.BackgroundColor3 = Theme.ControlHover

                local choose_conn, cancel_conn
                local function finish()
                    Library._choosing_keybind = false
                    Keybind.BackgroundColor3 = Theme.Accent
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

            function ModuleManager:create_paragraph(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local PM = {}
                if self._size == 0 then self._size = 11 end
                self._size += s.customScale or 70
                ModuleManager:refresh_size()

                local P = Instance.new('Frame')
                P.BackgroundColor3 = Theme.Control
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
                Title.TextColor3 = Theme.Text
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
                Body.Parent = P
                table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

                P.MouseEnter:Connect(function()
                    TweenService:Create(P, TweenInfo.new(0.3), {BackgroundColor3 = Theme.ControlHover}):Play()
                end)
                P.MouseLeave:Connect(function()
                    TweenService:Create(P, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Control}):Play()
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
                TitleLabel.TextColor3 = Theme.TextSoft
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = s.title or "Checkbox"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.ZIndex = 5
                TitleLabel.Parent = Checkbox
                table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "TextSoft"})

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Theme.Accent
                KeybindBox.BorderSizePixel = 0
                KeybindBox.ZIndex = 5
                KeybindBox.Parent = Checkbox
                table.insert(Library._elements, {obj = KeybindBox, prop = "BackgroundColor3", tKey = "Accent"})

                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 6)
                KeybindCorner.Parent = KeybindBox

                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Theme.Background
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[s.flag]
                    and string.gsub(tostring(Library._config._keybinds[s.flag]), "Enum.KeyCode.", "")
                    or "..."
                KeybindLabel.ZIndex = 6
                KeybindLabel.Parent = KeybindBox
                table.insert(Library._elements, {obj = KeybindLabel, prop = "TextColor3", tKey = "Background"})

                local Box = Instance.new("Frame")
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Accent
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
                Fill.BackgroundColor3 = Theme.Accent
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

            function ModuleManager:create_textbox(s)
                LayoutOrderModule = LayoutOrderModule + 1
                local TM = { _text = "" }
                if self._size == 0 then self._size = 11 end
                self._size += 32
                ModuleManager:refresh_size()

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Theme.TextSoft
                Label.TextTransparency = 0.2
                Label.Text = s.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 10
                Label.ZIndex = 5
                Label.Parent = Options
                Label.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Label, prop = "TextColor3", tKey = "TextSoft"})

                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Theme.TextSoft
                Textbox.PlaceholderText = s.placeholder or "Enter text..."
                Textbox.PlaceholderColor3 = Theme.TextDim
                Textbox.Text = Library._config._flags[s.flag] or ""
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Theme.Accent
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.ZIndex = 5
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
                table.insert(Library._elements, {obj = Textbox, prop = "BackgroundColor3", tKey = "Accent"})
                table.insert(Library._elements, {obj = Textbox, prop = "TextColor3", tKey = "TextSoft"})
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
                TextLabel.TextColor3 = Theme.TextSoft
                TextLabel.TextTransparency = 0.2
                TextLabel.Text = s.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.ZIndex = 5
                TextLabel.Parent = Slider
                table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "TextSoft"})

                local Drag = Instance.new('Frame')
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.9
                Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Theme.Accent
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
                Fill.BackgroundColor3 = Theme.Accent
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
                Circle.BackgroundColor3 = Theme.TextSoft
                Circle.ZIndex = 7
                Circle.Parent = Fill
                table.insert(Library._elements, {obj = Circle, prop = "BackgroundColor3", tKey = "TextSoft"})

                local CC = Instance.new('UICorner')
                CC.CornerRadius = UDim.new(1, 0)
                CC.Parent = Circle

                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Theme.TextSoft
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
                TextLabel.TextColor3 = Theme.TextSoft
                TextLabel.TextTransparency = 0.2
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
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(0.5, 0, 1.2, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Theme.Control
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
                CurrentOption.TextColor3 = Theme.TextSoft
                CurrentOption.TextTransparency = 0.2
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.05, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.TextSize = 10
                CurrentOption.ZIndex = 7
                CurrentOption.Parent = Header
                table.insert(Library._elements, {obj = CurrentOption, prop = "TextColor3", tKey = "TextSoft"})

                local Arrow = Instance.new('ImageLabel')
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.ImageColor3 = Theme.TextDim
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.ZIndex = 7
                Arrow.Parent = Header
                table.insert(Library._elements, {obj = Arrow, prop = "ImageColor3", tKey = "TextDim"})

                local OptionsList = Instance.new('ScrollingFrame')
                OptionsList.Active = true
                OptionsList.ScrollBarImageTransparency = 1
                OptionsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
                OptionsList.ScrollBarThickness = 0
                OptionsList.Size = UDim2.new(0, 207, 0, 0)
                OptionsList.BackgroundTransparency = 1
                OptionsList.Position = UDim2.new(0, 0, 1, 0)
                OptionsList.BorderSizePixel = 0
                OptionsList.CanvasSize = UDim2.new(0, 0, 0, 0)
                OptionsList.ZIndex = 6
                OptionsList.Parent = Box

                local OL = Instance.new('UIListLayout')
                OL.SortOrder = Enum.SortOrder.LayoutOrder
                OL.Parent = OptionsList

                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, 2)
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

                local function build_option(value, index, is_refresh)
                    local Option = Instance.new('TextButton')
                    Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    Option.TextTransparency = 0.6
                    Option.AnchorPoint = Vector2.new(0, 0.5)
                    Option.TextSize = 10
                    Option.Size = UDim2.new(0, 186, 0, 16)
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

                    if s.maximum_options and index > s.maximum_options then return end
                    if not is_refresh then
                        DM._size = DM._size + 16
                        OptionsList.Size = UDim2.fromOffset(207, DM._size)
                    end
                end

                function DM:refresh(new_options)
                    local old_size = self._size
                    for _, child in ipairs(OptionsList:GetChildren()) do
                        if child.Name == 'Option' then child:Destroy() end
                    end
                    self._size = 3
                    for index, value in new_options do
                        build_option(value, index, true)
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
                        build_option(value, index, false)
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
                Btn.BackgroundColor3 = Theme.Control
                Btn.TextColor3 = Theme.TextSoft
                Btn.Text = "    " .. (s.title or "Feature")
                Btn.AutoButtonColor = false
                Btn.TextXAlignment = Enum.TextXAlignment.Left
                Btn.TextTransparency = 0.2
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
                KBBox.TextColor3 = Theme.Background
                KBBox.TextSize = 11
                KBBox.BackgroundTransparency = 1
                KBBox.LayoutOrder = 2
                KBBox.ZIndex = 5
                KBBox.Parent = RC
                table.insert(Library._elements, {obj = KBBox, prop = "BackgroundColor3", tKey = "Accent"})
                table.insert(Library._elements, {obj = KBBox, prop = "TextColor3", tKey = "Background"})

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
                    Library._config._flags[s.flag] = { checked = false, BIND = s.default or "Unknown" }
                end
                checked = Library._config._flags[s.flag].checked
                KBBox.Text = Library._config._flags[s.flag].BIND
                if KBBox.Text == "Unknown" then KBBox.Text = "..." end

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

            return ModuleManager
        end

        return TabManager
    end

    -- ═══════════════════════════════════════════════════════════
    --  Visibility handler (reads Minimize_Keybind)
    -- ═══════════════════════════════════════════════════════════
    local function toggle_ui()
        self._ui_open = not self._ui_open
        if Library._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
        else
            self:change_visiblity(self._ui_open)
        end
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        if process then return end
        local key = Library._config._keybinds['Minimize_Keybind'] or "Enum.KeyCode.Insert"
        if tostring(input.KeyCode) ~= key then return end
        toggle_ui()
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(toggle_ui)

    return self
end

-- ═══════════════════════════════════════════════════════════════
--  INTERFACE TAB
-- ═══════════════════════════════════════════════════════════════
function Library:build_interface_tab()
    local saved_tab = self._tab
    self._tab = 9999
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007', true)
    self._tab = saved_tab + 1

    local Container = self._ui.Container
    local Handler = Container.Handler

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

    local function set_module_transparency(value)
        for _, object in self._ui:GetDescendants() do
            if object.Name == 'Module' then
                object.BackgroundTransparency = value
            end
            if object.Name == 'Box' then
                object.BackgroundTransparency = math.clamp(value + 0.7, 0, 1)
            end
        end
    end

    -- ─── Configurations (RIGHT) ─────────────────────────────
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

    local initial_configs = get_configs()
    if #initial_configs == 0 then
        initial_configs = { "No profiles yet" }
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
        options = initial_configs,
        multi_dropdown = false,
        maximum_options = 10,
        callback = function() end,
    })

    config_module:create_button({
        title = 'Save Profile',
        callback = function()
            local name = Library._config._flags['Config_Input_Name']
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
            if typeof(name) ~= 'string' or name == '' or name == 'No profiles yet' then
                Library.SendNotification({title = 'Config', text = 'Select a profile.', duration = 3})
                return
            end
            local loaded = Config:load('Configs/'..name, { _flags = {}, _keybinds = {}, _library = {} })
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
            local bgSource = Library._config._flags['Background_Image']
            if typeof(bgSource) == "string" and bgSource ~= '' then
                local resolved = resolve_background(bgSource)
                if self._background and resolved ~= '' then
                    self._background.Image = resolved
                    self._background.Visible = true
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
            if typeof(name) ~= 'string' or name == '' or name == 'No profiles yet' then return end
            local path = 'ailon/Configs/'..name..'.json'
            if isfile and isfile(path) then
                delfile(path)
                local remaining = get_configs()
                if #remaining == 0 then remaining = { "No profiles yet" } end
                list_drop:refresh(remaining)
                Library.SendNotification({title = 'Config', text = 'Deleted '..name, duration = 3})
            end
        end,
    })

    -- ─── Appearance (LEFT) ──────────────────────────────────
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
        Popup.BackgroundColor3 = Theme.Background
        Popup.BorderSizePixel = 0
        Popup.Visible = false
        Popup.ZIndex = 30
        Popup.Parent = Handler
        Instance.new('UICorner', Popup).CornerRadius = UDim.new(0, 7)
        local PS = Instance.new('UIStroke', Popup)
        PS.Color = Theme.GroupStroke
        PS.Transparency = 0.4
        table.insert(self._elements, {obj = Popup, prop = "BackgroundColor3", tKey = "Background"})

        local Field = Instance.new('TextButton')
        Field.Position = UDim2.fromOffset(8, 10)
        Field.Size = UDim2.fromOffset(145, 145)
        Field.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Field.BorderSizePixel = 0
        Field.ClipsDescendants = true
        Field.AutoButtonColor = false
        Field.Text = ''
        Field.ZIndex = 31
        Field.Parent = Popup
        Instance.new('UICorner', Field).CornerRadius = UDim.new(0, 5)

        local Sat = Instance.new('Frame')
        Sat.Size = UDim2.new(1, 0, 1, 0)
        Sat.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sat.BorderSizePixel = 0
        Sat.ZIndex = 32
        Sat.Parent = Field
        Instance.new('UICorner', Sat).CornerRadius = UDim.new(0, 5)
        local SG = Instance.new('UIGradient', Sat)
        SG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}

        local Bri = Instance.new('Frame')
        Bri.Size = UDim2.new(1, 0, 1, 0)
        Bri.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Bri.BorderSizePixel = 0
        Bri.ZIndex = 33
        Bri.Parent = Field
        Instance.new('UICorner', Bri).CornerRadius = UDim.new(0, 5)
        local BG = Instance.new('UIGradient', Bri)
        BG.Rotation = 90
        BG.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}

        local Cursor = Instance.new('Frame')
        Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
        Cursor.Size = UDim2.fromOffset(11, 11)
        Cursor.BackgroundTransparency = 1
        Cursor.BorderSizePixel = 0
        Cursor.ZIndex = 34
        Cursor.Parent = Field
        Instance.new('UICorner', Cursor).CornerRadius = UDim.new(1, 0)
        local CS = Instance.new('UIStroke', Cursor)
        CS.Color = Color3.fromRGB(255, 255, 255)
        CS.Thickness = 2

        local Hue = Instance.new('TextButton')
        Hue.Position = UDim2.fromOffset(159, 10)
        Hue.Size = UDim2.fromOffset(14, 145)
        Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Hue.BorderSizePixel = 0
        Hue.AutoButtonColor = false
        Hue.Text = ''
        Hue.ZIndex = 31
        Hue.Parent = Popup
        Instance.new('UICorner', Hue).CornerRadius = UDim.new(0, 4)
        local HG = Instance.new('UIGradient', Hue)
        HG.Rotation = 90
        local kp = {}
        for i = 0, 6 do
            kp[i+1] = ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1))
        end
        HG.Color = ColorSequence.new(kp)

        local HKnob = Instance.new('Frame')
        HKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        HKnob.Size = UDim2.fromOffset(14, 3)
        HKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HKnob.BorderSizePixel = 0
        HKnob.ZIndex = 32
        HKnob.Parent = Hue
        Instance.new('UICorner', HKnob).CornerRadius = UDim.new(1, 0)

        local HexBox = Instance.new('TextBox')
        HexBox.Position = UDim2.fromOffset(8, 160)
        HexBox.Size = UDim2.fromOffset(165, 14)
        HexBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        HexBox.BackgroundTransparency = 0.3
        HexBox.BorderSizePixel = 0
        HexBox.TextColor3 = Color3.fromRGB(220, 220, 220)
        HexBox.PlaceholderText = 'FF0000'
        HexBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
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
            if Swatches[Selected] then Swatches[Selected].BackgroundColor3 = color end
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
            T.Size = UDim2.new(1, -50, 1, 0)
            T.BackgroundTransparency = 1
            T.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
            T.TextColor3 = Color3.fromRGB(255, 255, 255)
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
            local SS = Instance.new('UIStroke'); SS.Color = Theme.GroupStroke; SS.Transparency = 0.5; SS.Parent = Sw

            Sw.MouseButton1Click:Connect(function() openPopup(target, Sw) end)
            Row.MouseButton1Click:Connect(function() openPopup(target, Sw) end)

            Swatches[target] = Sw
        end

        local ResetHolder = Instance.new('Frame')
        ResetHolder.Size = UDim2.fromOffset(207, 23)
        ResetHolder.BackgroundTransparency = 1
        ResetHolder.LayoutOrder = #Color_Targets + 3
        ResetHolder.Parent = Opts

        local ResetBtn = Instance.new('TextButton')
        ResetBtn.AnchorPoint = Vector2.new(0, 1)
        ResetBtn.Position = UDim2.new(0, 0, 1, 0)
        ResetBtn.Size = UDim2.fromOffset(207, 22)
        ResetBtn.BackgroundColor3 = Theme.Control
        ResetBtn.BorderSizePixel = 0
        ResetBtn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        ResetBtn.TextColor3 = Theme.TextSoft
        ResetBtn.TextSize = 12
        ResetBtn.Text = 'Reset'
        ResetBtn.AutoButtonColor = false
        ResetBtn.Parent = ResetHolder
        table.insert(self._elements, {obj = ResetBtn, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = ResetBtn, prop = "TextColor3", tKey = "TextSoft"})
        Instance.new('UICorner', ResetBtn).CornerRadius = UDim.new(0, 4)

        ResetBtn.MouseButton1Click:Connect(function()
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
            color_frame.Size = UDim2.fromOffset(241, 100 + color_module._size + color_module._multiplier)
        end
    end

    -- ─── Background (RIGHT) ─────────────────────────────────
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
            self:SetBackground(src, Library._config._flags['Background_Transparency'] or 0.5)
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
        Input.BackgroundColor3 = Theme.Control
        Input.BackgroundTransparency = 0.2
        Input.BorderSizePixel = 0
        Input.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Input.TextColor3 = Theme.TextSoft
        Input.PlaceholderColor3 = Theme.TextDim
        Input.PlaceholderText = 'Asset ID, rbxassetid://, or URL'
        Input.TextSize = 11
        Input.ClearTextOnFocus = false
        Input.Text = bg_id
        Input.ZIndex = 5
        Input.Parent = Row
        table.insert(self._elements, {obj = Input, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = Input, prop = "TextColor3", tKey = "TextSoft"})
        table.insert(self._elements, {obj = Input, prop = "PlaceholderColor3", tKey = "TextDim"})

        Asset_Input = Input
        Instance.new('UICorner', Input).CornerRadius = UDim.new(0, 4)

        Input.FocusLost:Connect(function()
            local src = Input.Text:match('^%s*(.-)%s*$')
            Input.Text = src
            bg_id = src
            self:SetBackground(src, Library._config._flags['Background_Transparency'] or 0.5)
            Library._config._flags['Background_Image_Id'] = src
            for pname, psrc in pairs(Presets) do
                if psrc == src then
                    pcall(function() preset_drop:update(pname) end)
                    break
                end
            end
        end)

        local ResetHolder = Instance.new('Frame')
        ResetHolder.Size = UDim2.fromOffset(207, 23)
        ResetHolder.BackgroundTransparency = 1
        ResetHolder.LayoutOrder = 4
        ResetHolder.Parent = bg_frame.Options

        local ResetBtn = Instance.new('TextButton')
        ResetBtn.AnchorPoint = Vector2.new(0, 1)
        ResetBtn.Position = UDim2.new(0, 0, 1, 0)
        ResetBtn.Size = UDim2.fromOffset(207, 22)
        ResetBtn.BackgroundColor3 = Theme.Control
        ResetBtn.BorderSizePixel = 0
        ResetBtn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        ResetBtn.TextColor3 = Theme.TextSoft
        ResetBtn.TextSize = 12
        ResetBtn.Text = 'Reset'
        ResetBtn.AutoButtonColor = false
        ResetBtn.Parent = ResetHolder
        table.insert(self._elements, {obj = ResetBtn, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(self._elements, {obj = ResetBtn, prop = "TextColor3", tKey = "TextSoft"})
        Instance.new('UICorner', ResetBtn).CornerRadius = UDim.new(0, 4)

        ResetBtn.MouseButton1Click:Connect(function()
            Input.Text = ''
            bg_id = ''
            pcall(function() preset_drop:update('None') end)
            trans_slider:set_percentage(50)
            module_trans_slider:set_percentage(0)
            Library._config._flags['Background_Image_Id'] = ''
            self:SetBackground('', 0.5)
        end)

        image_module._size = image_module._size + 60
        bg_frame.Options.Size = UDim2.fromOffset(241, image_module._size)
        if image_module._state then
            bg_frame.Size = UDim2.fromOffset(241, 100 + image_module._size + image_module._multiplier)
        end
    end

    self:SetBackground(bg_id, Library._config._flags['Background_Transparency'] or 0.5)
    set_module_transparency((Library._config._flags['Background_Module_Transparency'] or 0) / 100)

    -- ─── UI Transparency (LEFT) ─────────────────────────────
    local ui_trans_module = InterfaceTab:create_module({
        title = 'UI Transparency',
        flag = 'UI_Transparency_Module',
        description = 'Container opacity',
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

    -- ─── Settings (LEFT) ────────────────────────────────────
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

    -- ─── Notifications (RIGHT) ──────────────────────────────
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

    -- ─── Overlays (RIGHT) ──────────────────────────────────
    local overlay_module = InterfaceTab:create_module({
        title = 'Overlays',
        flag = 'UI_Overlays',
        description = 'FPS, Ping, Keybinds list',
        section = 'right',
        callback = function() end,
    })

    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "ailon_Overlay"
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = 99
    OverlayGui.Parent = CoreGui

    local FpsPanel = Instance.new("Frame", OverlayGui)
    FpsPanel.Size = UDim2.new(0, 140, 0, 34)
    FpsPanel.Position = UDim2.new(0, 20, 0.5, -60)
    FpsPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    FpsPanel.BackgroundTransparency = 0.12
    FpsPanel.BorderSizePixel = 0
    FpsPanel.Active = true
    FpsPanel.Visible = false
    Instance.new("UICorner", FpsPanel).CornerRadius = UDim.new(0, 10)
    local FPStroke = Instance.new("UIStroke", FpsPanel)
    FPStroke.Color = Color3.fromRGB(60, 60, 60)
    FPStroke.Transparency = 0.5

    local FpsValue = Instance.new("TextLabel", FpsPanel)
    FpsValue.Size = UDim2.new(0, 68, 1, 0)
    FpsValue.Position = UDim2.new(0, 14, 0, 0)
    FpsValue.BackgroundTransparency = 1
    FpsValue.Font = Enum.Font.GothamBold
    FpsValue.Text = "0"
    FpsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsValue.TextSize = 24
    FpsValue.TextXAlignment = Enum.TextXAlignment.Left

    local FpsLabel = Instance.new("TextLabel", FpsPanel)
    FpsLabel.Size = UDim2.new(0, 48, 1, 0)
    FpsLabel.Position = UDim2.new(1, -58, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.Text = "FPS"
    FpsLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
    FpsLabel.TextSize = 12

    local PingPanel = Instance.new("Frame", OverlayGui)
    PingPanel.Size = UDim2.new(0, 140, 0, 34)
    PingPanel.Position = UDim2.new(0, 20, 0.5, -20)
    PingPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
    PingPanel.BackgroundTransparency = 0.12
    PingPanel.BorderSizePixel = 0
    PingPanel.Active = true
    PingPanel.Visible = false
    Instance.new("UICorner", PingPanel).CornerRadius = UDim.new(0, 10)
    local PPStroke = Instance.new("UIStroke", PingPanel)
    PPStroke.Color = Color3.fromRGB(60, 60, 60)
    PPStroke.Transparency = 0.5

    local PingValue = Instance.new("TextLabel", PingPanel)
    PingValue.Size = UDim2.new(0, 90, 1, 0)
    PingValue.Position = UDim2.new(0, 14, 0, 0)
    PingValue.BackgroundTransparency = 1
    PingValue.Font = Enum.Font.GothamBold
    PingValue.Text = "0 ms"
    PingValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    PingValue.TextSize = 18
    PingValue.TextXAlignment = Enum.TextXAlignment.Left

    local PingLabel = Instance.new("TextLabel", PingPanel)
    PingLabel.Size = UDim2.new(0, 48, 1, 0)
    PingLabel.Position = UDim2.new(1, -58, 0, 0)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Font = Enum.Font.GothamBold
    PingLabel.Text = "PING"
    PingLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
    PingLabel.TextSize = 12

    local function make_draggable(frame)
        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
    make_draggable(FpsPanel)
    make_draggable(PingPanel)

    local KBGui = Instance.new("ScreenGui")
    KBGui.Name = "ailon_Keybinds"
    KBGui.ResetOnSpawn = false
    KBGui.IgnoreGuiInset = true
    KBGui.Enabled = false
    KBGui.Parent = CoreGui

    local KBFrame = Instance.new("Frame")
    KBFrame.Size = UDim2.new(0, 220, 0, 38)
    KBFrame.Position = UDim2.new(0, 20, 0.5, -19)
    KBFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    KBFrame.BackgroundTransparency = 0.12
    KBFrame.BorderSizePixel = 0
    KBFrame.Active = true
    KBFrame.Parent = KBGui
    Instance.new("UICorner", KBFrame).CornerRadius = UDim.new(0, 8)
    local KFStroke = Instance.new("UIStroke", KBFrame)
    KFStroke.Color = Color3.fromRGB(60, 60, 60)
    KFStroke.Transparency = 0.5

    local KBHeader = Instance.new("Frame", KBFrame)
    KBHeader.Size = UDim2.new(1, 0, 0, 34)
    KBHeader.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    KBHeader.BorderSizePixel = 0
    KBHeader.ZIndex = 2
    Instance.new("UICorner", KBHeader).CornerRadius = UDim.new(0, 8)

    local KBHeaderLabel = Instance.new("TextLabel", KBHeader)
    KBHeaderLabel.Size = UDim2.new(1, -20, 1, 0)
    KBHeaderLabel.Position = UDim2.new(0, 12, 0, 0)
    KBHeaderLabel.BackgroundTransparency = 1
    KBHeaderLabel.Text = "KEYBINDS"
    KBHeaderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    KBHeaderLabel.TextSize = 11
    KBHeaderLabel.Font = Enum.Font.GothamBold
    KBHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    KBHeaderLabel.ZIndex = 3

    make_draggable(KBHeader)

    local function refresh_keybinds()
        for _, child in ipairs(KBFrame:GetChildren()) do
            if child.Name == "Row" or child.Name == "Divider" then child:Destroy() end
        end
        local binds = {}
        for flag, key in pairs(Library._config._keybinds) do
            local title = Library._keybind_list[flag]
            if title then
                table.insert(binds, {title = title, key = string.gsub(tostring(key), "Enum.KeyCode.", "")})
            end
        end
        table.sort(binds, function(a, b) return a.title < b.title end)
        local y = 40
        for i, b in ipairs(binds) do
            if i > 1 then
                local div = Instance.new("Frame", KBFrame)
                div.Name = "Divider"
                div.Size = UDim2.new(1, -20, 0, 1)
                div.Position = UDim2.new(0, 10, 0, y)
                div.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                div.BorderSizePixel = 0
            end
            local row = Instance.new("Frame", KBFrame)
            row.Name = "Row"
            row.Size = UDim2.new(1, -18, 0, 26)
            row.Position = UDim2.new(0, 9, 0, y + 1)
            row.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", row)
            lbl.Size = UDim2.new(1, -50, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = b.title
            lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
            lbl.TextSize = 12
            lbl.Font = Enum.Font.GothamSemibold
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            local keyLbl = Instance.new("TextLabel", row)
            keyLbl.Size = UDim2.new(0, 44, 1, 0)
            keyLbl.Position = UDim2.new(1, -44, 0, 0)
            keyLbl.BackgroundTransparency = 1
            keyLbl.Text = "[" .. b.key .. "]"
            keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            keyLbl.TextSize = 11
            keyLbl.Font = Enum.Font.GothamBold
            keyLbl.TextXAlignment = Enum.TextXAlignment.Right
            y = y + 28
        end
        KBFrame.Size = UDim2.new(0, 220, 0, 40 + (#binds * 28))
    end

    local lastKBRefresh = 0
    RunService.RenderStepped:Connect(function()
        if not KBGui.Enabled then return end
        if tick() - lastKBRefresh > 0.5 then
            lastKBRefresh = tick()
            refresh_keybinds()
        end
    end)

    local frameCount, elapsed, pingElapsed = 0, 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        elapsed = elapsed + dt
        pingElapsed = pingElapsed + dt
        if elapsed >= 0.5 then
            local fps = math.round(frameCount / elapsed)
            frameCount = 0
            elapsed = 0
            if FpsPanel.Visible then FpsValue.Text = tostring(fps) end
        end
        if pingElapsed >= 0.5 then
            local ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
            if PingPanel.Visible then PingValue.Text = tostring(ping).." ms" end
            pingElapsed = 0
        end
    end)

    overlay_module:create_checkbox({
        title = 'Show FPS',
        flag = 'UI_Show_Fps',
        callback = function(state) FpsPanel.Visible = state end,
    })

    overlay_module:create_checkbox({
        title = 'Show Ping',
        flag = 'UI_Show_Ping',
        callback = function(state) PingPanel.Visible = state end,
    })

    overlay_module:create_checkbox({
        title = 'Keybinds List',
        flag = 'UI_Show_Keybinds',
        callback = function(state)
            KBGui.Enabled = state
            if state then refresh_keybinds() end
        end,
    })

    -- ─── Minimize Key (LEFT) ────────────────────────────────
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
        Lbl.TextColor3 = Theme.TextSoft
        Lbl.Text = 'Toggle UI Key'
        Lbl.Size = UDim2.new(0, 120, 1, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.ZIndex = 5
        Lbl.Parent = Row
        table.insert(self._elements, {obj = Lbl, prop = "TextColor3", tKey = "TextSoft"})

        local min_keybox = Instance.new('TextButton')
        min_keybox.Name = 'Keybox'
        min_keybox.AnchorPoint = Vector2.new(1, 0.5)
        min_keybox.Position = UDim2.new(1, 0, 0.5, 0)
        min_keybox.Size = UDim2.fromOffset(60, 20)
        min_keybox.BackgroundColor3 = Theme.Control
        min_keybox.BorderSizePixel = 0
        min_keybox.AutoButtonColor = false
        min_keybox.Text = ''
        min_keybox.ZIndex = 4
        min_keybox.Parent = Row
        table.insert(self._elements, {obj = min_keybox, prop = "BackgroundColor3", tKey = "Control"})

        local MC = Instance.new('UICorner'); MC.CornerRadius = UDim.new(0, 3); MC.Parent = min_keybox
        local MS = Instance.new('UIStroke'); MS.Color = Theme.GroupStroke; MS.Transparency = 0.5; MS.Thickness = 1; MS.Parent = min_keybox
        table.insert(self._elements, {obj = MS, prop = "Color", tKey = "GroupStroke"})

        local MT = Instance.new('TextLabel')
        MT.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        MT.TextColor3 = Theme.TextSoft
        MT.TextSize = 10
        MT.BackgroundTransparency = 1
        MT.Size = UDim2.new(1, -6, 1, 0)
        MT.Position = UDim2.new(0, 3, 0, 0)
        MT.TextXAlignment = Enum.TextXAlignment.Center
        MT.ZIndex = 5
        MT.Parent = min_keybox
        table.insert(self._elements, {obj = MT, prop = "TextColor3", tKey = "TextSoft"})

        min_module._size = min_module._size + 26
        min_frame.Options.Size = UDim2.fromOffset(241, min_module._size)
        if min_module._state then
            min_frame.Size = UDim2.fromOffset(241, 100 + min_module._size + min_module._multiplier)
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
            min_keybox.BackgroundColor3 = Theme.ControlHover

            local bind_c, cancel_c
            local function done()
                listening = false
                min_keybox.BackgroundColor3 = Theme.Control
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

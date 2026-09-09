-- Achaotic UI Library (Cleaned, No Game Logic, No Hardcoded Colors, Transparency Adjusted, Options Parent Fixed)
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

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()

local old_Achaotic = CoreGui:FindFirstChild('Achaotic')
if old_Achaotic then Debris:AddItem(old_Achaotic, 0) end

pcall(function()
    if getgenv()._Achaotic_Cleanup then
        getgenv()._Achaotic_Cleanup()
        getgenv()._Achaotic_Cleanup = nil
    end
end)

if not isfolder("Achaotic") then makefolder("Achaotic") end

local Connections = setmetatable({}, {
    __index = {
        disconnect = function(self, key)
            if self[key] then
                self[key]:Disconnect()
                self[key] = nil
            end
        end,
        disconnect_all = function(self)
            for k, v in pairs(self) do
                if type(v) ~= 'function' then
                    pcall(v.Disconnect, v)
                    self[k] = nil
                end
            end
        end
    }
})

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

local Config = setmetatable({
    save = function(self, file_name, config)
        local success, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Achaotic/'..file_name..'.json', flags)
        end)
        if not success then warn('Failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfile('Achaotic/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('Achaotic/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success then warn('Failed to load config', result) end
        if not result then result = { _flags = {}, _keybinds = {}, _library = {} } end
        return result
    end
}, Config)

local DefaultTheme = {
    Background = Color3.fromRGB(12, 13, 15),
    Group = Color3.fromRGB(22, 28, 38),
    GroupStroke = Color3.fromRGB(52, 66, 89),
    Control = Color3.fromRGB(32, 38, 51),
    ControlHover = Color3.fromRGB(42, 50, 66),
    Text = Color3.fromRGB(210, 210, 210),
    TextDim = Color3.fromRGB(180, 180, 180),
    Accent = Color3.fromRGB(161, 208, 42),
}

local Theme = {}
for k, v in pairs(DefaultTheme) do
    Theme[k] = typeof(v) == "Color3" and Color3.new(v.R, v.G, v.B) or v
end

local Library = {
    _config = Config:load(game.GameId),
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
    _tab = 0,
    _flag_registry = {},
    _keybind_registry = {},
    _keybind_list = {}
}
Library.__index = Library
Library.Connections = Connections

function Library.new(config)
    local self = setmetatable({
        _loaded = false,
        _tab = 0
    }, Library)
    
    local currentconfig = config or {}
    currentconfig.title = currentconfig.title or "Achaotic"
    currentconfig.PrimaryColor = currentconfig.PrimaryColor or Theme.Accent
    
    Theme.Accent = currentconfig.PrimaryColor
    
    self:create_ui(currentconfig)
    return self
end

-- Notification System
local NotificationHost = Instance.new("ScreenGui")
NotificationHost.Name = "AchaoticNotifications"
NotificationHost.ResetOnSpawn = false
NotificationHost.IgnoreGuiInset = true
NotificationHost.DisplayOrder = 101
NotificationHost.Parent = CoreGui

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "NotificationContainer"
NotificationContainer.Size = UDim2.new(0, 320, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.Parent = NotificationHost

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.FillDirection = Enum.FillDirection.Vertical
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 10)
UIListLayout_Notif.Parent = NotificationContainer

function Library:Notify(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 72)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer
    Notification.AutomaticSize = Enum.AutomaticSize.Y

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 72)
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)
    InnerFrame.BackgroundColor3 = Theme.Background
    InnerFrame.BackgroundTransparency = 0.2
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y
    table.insert(Library._elements, {obj = InnerFrame, prop = "BackgroundColor3", tKey = "Background"})

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Theme.GroupStroke
    InnerStroke.Transparency = 0.5
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame
    table.insert(Library._elements, {obj = InnerStroke, prop = "Color", tKey = "GroupStroke"})

    local Title = Instance.new("TextLabel")
    Title.Text = tostring(settings.title or "Notification Title")
    Title.TextColor3 = Theme.Text
    Title.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 15
    Title.Size = UDim2.new(1, -10, 0, 22)
    Title.Position = UDim2.new(0, 7, 0, 7)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.AutomaticSize = Enum.AutomaticSize.Y
    Title.Parent = InnerFrame
    table.insert(Library._elements, {obj = Title, prop = "TextColor3", tKey = "Text"})

    local Body = Instance.new("TextLabel")
    Body.Text = tostring(settings.text or "This is the body of the notification.")
    Body.TextColor3 = Theme.TextDim
    Body.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 13
    Body.Size = UDim2.new(1, -16, 0, 34)
    Body.Position = UDim2.new(0, 7, 0, 30)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = InnerFrame
    table.insert(Library._elements, {obj = Body, prop = "TextColor3", tKey = "TextDim"})

    task.spawn(function()
        wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 12
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()

        local duration = settings.duration or 5
        wait(duration)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenOut:Play()

        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
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
    
    self._config._flags['Background_Image'] = (typeof(source) == "string" and source) or ''
    self._config._flags['Background_Transparency'] = transparency or 0.5
    Config:save(game.GameId, Library._config)
end

function Library:SetColor(key, color)
    Theme[key] = color
    for _, element in ipairs(Library._elements or {}) do
        if element.tKey == key then
            pcall(function()
                element.obj[element.prop] = color
            end)
        end
    end
    self._config._flags['Theme_'..key] = self:rgbToHex(color)
    Config:save(game.GameId, Library._config)
end

function Library:GetColor(key)
    return Theme[key]
end

function Library:create_ui(config)
    local old_UI = CoreGui:FindFirstChild('Achaotic')
    if old_UI then Debris:AddItem(old_UI, 0) end

    local AchaoticGui = Instance.new('ScreenGui')
    AchaoticGui.ResetOnSpawn = false
    AchaoticGui.Name = 'Achaotic'
    AchaoticGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    AchaoticGui.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.2
    Container.BackgroundColor3 = Theme.Background
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = AchaoticGui
    table.insert(Library._elements, {obj = Container, prop = "BackgroundColor3", tKey = "Background"})

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
    Handler.Name = 'Handler'
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Theme.Background
    Handler.Parent = Container
    table.insert(Library._elements, {obj = Handler, prop = "BackgroundColor3", tKey = "Background"})
    
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
    
    local UIListLayout_Tabs = Instance.new('UIListLayout')
    UIListLayout_Tabs.Padding = UDim.new(0, 4)
    UIListLayout_Tabs.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_Tabs.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Theme.Accent
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
    Pin.BackgroundColor3 = Theme.Accent
    Pin.Parent = Handler
    table.insert(Library._elements, {obj = Pin, prop = "BackgroundColor3", tKey = "Accent"})
    
    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin
    
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
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = AchaoticGui
    self._container = Container
    self._tabs = Tabs
    self._sections = Sections
    self._pin = Pin
    self._handler = Handler
    self._uiscale = UIScale

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
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), { Position = position }):Play()
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

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightControl then
            self._ui_open = not self._ui_open
            self:change_visiblity(self._ui_open)
        end
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)
end

function Library:change_visiblity(state)
    Library._ui_open = state
    if self._container then
        if state then
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
end

function Library:load()
    local content = {}
    for _, object in self._ui:GetDescendants() do
        if object:IsA('ImageLabel') then
            table.insert(content, object)
        end
    end
    ContentProvider:PreloadAsync(content)
    
    self:get_device()

    if self._device == 'Mobile' or self._device == 'Unknown' then
        self:get_screen_scale()
        if self._uiscale then
            self._uiscale.Scale = self._ui_scale
        end
        Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            self:get_screen_scale()
            if self._uiscale then
                self._uiscale.Scale = self._ui_scale
            end
        end)
    end

    if self._container then
        TweenService:Create(self._container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()
    end

    local saved_bg = self._config._flags['Background_Image']
    if typeof(saved_bg) == "string" and saved_bg ~= '' then
        local trans = self._config._flags['Background_Transparency'] or 0.5
        self:SetBackground(saved_bg, trans)
    end

    for key, color in pairs(DefaultTheme) do
        local saved = self._config._flags['Theme_'..key]
        if saved then
            self:SetColor(key, self:hexToRGB(saved))
        end
    end

    self._ui_loaded = true
end

function Library:update_tabs(tab)
    for _, object in self._tabs:GetChildren() do
        if object.Name ~= 'Tab' then continue end

        if object == tab then
            if object.BackgroundTransparency ~= 0.5 then
                local offset = object.LayoutOrder * (0.113 / 1.3)

                TweenService:Create(self._pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
        else
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
end

function Library:update_sections(left_section, right_section)
    for _, object in self._sections:GetChildren() do
        if object == left_section or object == right_section then
            object.Visible = true
        else
            object.Visible = false
        end
    end
end

function Library:create_tab(title, icon)
    local TabManager = {}

    local font_params = Instance.new('GetTextBoundsParams')
    font_params.Text = title
    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    font_params.Size = 13
    font_params.Width = 10000

    local font_size = TextService:GetTextBoundsAsync(font_params)
    local first_tab = not self._tabs:FindFirstChild('Tab')

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
    Tab.Parent = self._tabs
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
    LeftSection.Parent = self._sections
    
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
    RightSection.Parent = self._sections
    
    local UIListLayout_R = Instance.new('UIListLayout')
    UIListLayout_R.Padding = UDim.new(0, 11)
    UIListLayout_R.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout_R.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_R.Parent = RightSection
    
    local UIPadding_R = Instance.new('UIPadding')
    UIPadding_R.PaddingTop = UDim.new(0, 1)
    UIPadding_R.Parent = RightSection

    self._tab = self._tab + 1

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
            _state = false,
            _size = 0,
            _multiplier = 0
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
        Description.Text = settings.description or ''
        Description.Name = 'Description'
        Description.Size = UDim2.new(0, 205, 0, 13)
        Description.AnchorPoint = Vector2.new(0, 0.5)
        Description.Position = UDim2.new(0.073, 0, 0.420, 0)
        Description.BackgroundTransparency = 1
        Description.TextXAlignment = Enum.TextXAlignment.Left
        Description.TextSize = 10
        Description.Parent = Header
        table.insert(Library._elements, {obj = Description, prop = "TextColor3", tKey = "Accent"})
        
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
        Options.Position = UDim2.new(0, 0, 1, 0)
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

        function ModuleManager:change_state(state)
            self._state = state
            if self._state then
                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Accent
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Group,
                    Position = UDim2.fromScale(0.53, 0.5)
                }):Play()
            else
                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.Background
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Theme.TextDim,
                    Position = UDim2.fromScale(0, 0.5)
                }):Play()
            end
            Library._config._flags[settings.flag] = self._state
            Config:save(game.GameId, Library._config)
            settings.callback(self._state)
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

        Library._flag_registry = Library._flag_registry or {}
        Library._flag_registry[settings.flag] = function(state)
            ModuleManager:change_state(state)
        end

        Header.MouseButton1Click:Connect(function()
            ModuleManager:change_state(not ModuleManager._state)
        end)

        function ModuleManager:create_checkbox(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local CheckboxManager = { _state = false }
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 20
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
            local Checkbox = Instance.new("TextButton")
            Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Checkbox.TextColor3 = Theme.Text
            Checkbox.Text = ""
            Checkbox.AutoButtonColor = false
            Checkbox.BackgroundTransparency = 1
            Checkbox.Name = "Checkbox"
            Checkbox.Size = UDim2.new(0, 207, 0, 15)
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
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.2
                    }):Play()
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(9, 9)
                    }):Play()
                else
                    TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.2
                    }):Play()
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
            
            Library._flag_registry = Library._flag_registry or {}
            Library._flag_registry[settings.flag] = function(state)
                CheckboxManager:change_state(state)
            end
            
            return CheckboxManager
        end

        function ModuleManager:create_button(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 20
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
            local Button = Instance.new("TextButton")
            Button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Button.TextColor3 = Theme.Text
            Button.TextTransparency = 0.2
            Button.Text = settings.title or "Button"
            Button.AutoButtonColor = true
            Button.BackgroundTransparency = 0.2
            Button.BackgroundColor3 = Theme.Control
            Button.Name = "Button"
            Button.Size = UDim2.new(0, 207, 0, 20)
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
            self._size = self._size + 27

            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            local Slider = Instance.new('TextButton')
            Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Slider.TextSize = 14
            Slider.TextColor3 = Theme.Text
            Slider.Text = ''
            Slider.AutoButtonColor = false
            Slider.BackgroundTransparency = 1
            Slider.Name = 'Slider'
            Slider.Size = UDim2.new(0, 207, 0, 22)
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
            TextLabel.Position = UDim2.new(0, 0, 0.050, 0)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Parent = Slider
            table.insert(Library._elements, {obj = TextLabel, prop = "TextColor3", tKey = "Text"})
            
            local Drag = Instance.new('Frame')
            Drag.AnchorPoint = Vector2.new(0.5, 1)
            Drag.BackgroundTransparency = 0.2
            Drag.Position = UDim2.new(0.5, 0, 0.950, 0)
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

                TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(slider_size, (Drag.AbsoluteSize.Y ~= 0 and Drag.AbsoluteSize.Y or Drag.Size.Y.Offset))
                }):Play()

                settings.callback(number_threshold)
            end

            function SliderManager:update()
                local success, mouse_location = pcall(function() return UserInputService:GetMouseLocation() end)
                local mouse_x = (success and mouse_location and mouse_location.X) or (mouse and mouse.X) or 0
                local drag_width = (Drag.AbsoluteSize and Drag.AbsoluteSize.X) or Drag.Size.X.Offset
                if drag_width == 0 then drag_width = Drag.Size.X.Offset end
                local mouse_position = (mouse_x - Drag.AbsolutePosition.X) / drag_width
                local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                self:set_percentage(percentage)
            end

            function SliderManager:input()
                SliderManager:update()
                Connections['slider_drag_'..settings.flag] = UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        SliderManager:update()
                    end
                end)
                Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input)
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

            Library._flag_registry = Library._flag_registry or {}
            Library._flag_registry[settings.flag] = function(value)
                SliderManager:set_percentage(value)
            end

            return SliderManager
        end

        function ModuleManager:create_textbox(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local TextboxManager = { _text = "" }
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 32
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)
            
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
            Textbox.PlaceholderText = tostring(settings.placeholder or "Enter text...")
            Textbox.PlaceholderColor3 = Theme.TextDim
            Textbox.Text = tostring(Library._config._flags[settings.flag] or "")
            Textbox.Name = 'Textbox'
            Textbox.Size = UDim2.new(0, 207, 0, 15)
            Textbox.BorderSizePixel = 0
            Textbox.TextSize = 10
            Textbox.BackgroundColor3 = Theme.Accent
            Textbox.BackgroundTransparency = 0.2
            Textbox.ClearTextOnFocus = false
            Textbox.Parent = Options
            Textbox.LayoutOrder = LayoutOrderModule
            table.insert(Library._elements, {obj = Textbox, prop = "BackgroundColor3", tKey = "Accent"})
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
            
            Library._flag_registry = Library._flag_registry or {}
            Library._flag_registry[settings.flag] = function(value)
                TextboxManager:update_text(value)
            end
            
            return TextboxManager
        end

        function ModuleManager:create_dropdown(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            local DropdownManager = { _state = false, _size = 0 }
            
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 44
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end
            Options.Size = UDim2.fromOffset(241, self._size)

            local Dropdown = Instance.new('TextButton')
            Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Dropdown.TextColor3 = Theme.Text
            Dropdown.Text = ''
            Dropdown.AutoButtonColor = false
            Dropdown.BackgroundTransparency = 1
            Dropdown.Name = 'Dropdown'
            Dropdown.Size = UDim2.new(0, 207, 0, 39)
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
            Box.Size = UDim2.new(0, 207, 0, 22)
            Box.BorderSizePixel = 0
            Box.BackgroundColor3 = Theme.Accent
            Box.Parent = TextLabel
            table.insert(Library._elements, {obj = Box, prop = "BackgroundColor3", tKey = "Accent"})
            
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
                            if trimmedValue ~= "Label" then
                                table.insert(selected, trimmedValue)
                            end
                        end
                    else
                        for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                            local trimmedValue = value:match("^%s*(.-)%s*$")
                            if trimmedValue ~= "Label" then
                                table.insert(selected, trimmedValue)
                            end
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
                    CurrentOption.Text = (typeof(option) == "string" and option) or (typeof(option) == "Instance" and option.Name) or tostring(option)
                    for _, object in OptionsList:GetChildren() do
                        if object.Name == "Option" then
                            object.TextTransparency = object.Text == CurrentOption.Text and 0.2 or 0.6
                        end
                    end
                    Library._config._flags[settings.flag] = option
                end

                Config:save(game.GameId, Library._config)
                settings.callback(option)
            end

            function DropdownManager:unfold_settings()
                self._state = not self._state
                local extra = self._state and self._size or 0

                if self._state then
                    ModuleManager._multiplier = ModuleManager._multiplier + self._size
                else
                    ModuleManager._multiplier = ModuleManager._multiplier - self._size
                end

                TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                }):Play()

                TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                }):Play()

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
                    Option.TextColor3 = Theme.Text
                    Option.Text = (typeof(value) == "string" and value) or value.Name
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
                    Option.TextColor3 = Theme.Text
                    Option.Text = (typeof(value) == "string" and value) or value.Name
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
                    self._size = self._size + 16
                    OptionsList.Size = UDim2.fromOffset(207, self._size)
                end
                if self._state then
                    local diff = self._size - old_size
                    ModuleManager._multiplier = ModuleManager._multiplier + diff
                    Module.Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                    Module.Options.Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                    Dropdown.Size = UDim2.fromOffset(207, 39 + self._size)
                    Box.Size = UDim2.fromOffset(207, 22 + self._size)
                end
            end

            if Library:flag_type(settings.flag, 'string') then
                DropdownManager:update(Library._config._flags[settings.flag])
            else
                DropdownManager:update(settings.options[1])
            end

            Dropdown.MouseButton1Click:Connect(function()
                DropdownManager:unfold_settings()
            end)

            Library._flag_registry = Library._flag_registry or {}
            Library._flag_registry[settings.flag] = function(value)
                DropdownManager:update(value)
            end

            return DropdownManager
        end

        function ModuleManager:create_divider(settings)
            LayoutOrderModule = LayoutOrderModule + 1
            if self._size == 0 then self._size = 11 end
            self._size = self._size + 27
            
            if ModuleManager._state then
                Module.Size = UDim2.fromOffset(241, 93 + self._size)
            end

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

        return ModuleManager
    end

    return TabManager
end

function Library:build_interface_tab()
    local InterfaceTab = self:create_tab('Interface', 'rbxassetid://94381583400007')

    local Container = self._container
    local Handler = self._handler

    local Custom_Asset = getcustomasset or getsynasset
    local Background_Folder = 'Achaotic/Backgrounds'

    if Custom_Asset and not isfolder(Background_Folder) then
        makefolder(Background_Folder)
    end

    local function resolve_background(source)
        if source == '' then return '' end
        if source:match('^%d+$')        then return 'rbxassetid://'..source end
        if source:match('^rbx%a+://')   then return source end
        if not Custom_Asset             then return '' end
        if not source:match('^https?://') then
            return (isfile(source) and Custom_Asset(source)) or ''
        end

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
    end

    local function set_module_transparency(value)
        for _, object in self._ui:GetDescendants() do
            if object.Name == 'Container' or object.Name == 'Handler' then continue end
            if object:IsA('Frame') or object:IsA('TextButton') or object:IsA('TextBox') then
                if object.BackgroundTransparency == 1 then continue end
                object.BackgroundTransparency = value
            end
        end
    end

    -- Configurations
    local config_module = InterfaceTab:create_module({
        title = 'Configurations',
        flag = 'UI_Config_System',
        description = 'Manage Settings Profiles',
        section = 'right',
        callback = function(state) end,
    })

    local function get_configs()
        if not isfolder('Achaotic/Configs') then makefolder('Achaotic/Configs') end
        if not listfiles then return {} end
        local files = listfiles('Achaotic/Configs')
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
            if not isfolder('Achaotic/Configs') then makefolder('Achaotic/Configs') end
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

            self:Notify({title = 'Config', text = 'Loaded '..name, duration = 3})
        end
    })

    config_module:create_button({
        title = 'Delete Profile',
        callback = function()
            local name = Library._config._flags['Config_Saved_List']
            if typeof(name) ~= 'string' or name == '' then return end
            local path = 'Achaotic/Configs/'..name..'.json'
            if isfile(path) then
                delfile(path)
                config_dropdown:refresh(get_configs())
                self:Notify({title = 'Config', text = 'Deleted '..name, duration = 3})
            end
        end
    })

    -- Appearance
    local color_module = InterfaceTab:create_module({
        title = 'Appearance',
        flag = 'Gui_Colors',
        description = 'Customize UI Colors',
        section = 'left',
        callback = function(state) end,
    })

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
        Popup.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
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
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
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
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
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
            local saturation = math.clamp((location.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
            local brightness = math.clamp((location.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
            set_color(Current_Hue, saturation, 1 - brightness)
        end

        local function update_hue()
            local location = UserInputService:GetMouseLocation() + Pointer_Offset
            local hue = math.clamp((location.X - Hue.AbsolutePosition.X) / Hue.AbsoluteSize.X, 0, 1)
            set_color(hue, Current_Saturation, Current_Value)
        end

        local function begin_drag(key, frame, update)
            calibrate_pointer(frame)
            update()

            self.Connections[key..'_move'] = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                   and input.UserInputType ~= Enum.UserInputType.Touch then return end
                update()
            end)

            self.Connections[key..'_ended'] = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                   and input.UserInputType ~= Enum.UserInputType.Touch then return end
                self.Connections:disconnect(key..'_move')
                self.Connections:disconnect(key..'_ended')
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
            table.insert(Library._elements, {obj = TitleLabel, prop = "TextColor3", tKey = "Text"})

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
            table.insert(Library._elements, {obj = SwatchStroke, prop = "Color", tKey = "GroupStroke"})

            Swatch.MouseButton1Click:Connect(function() open_popup(target, Swatch) end)
            Row.MouseButton1Click:Connect(function() open_popup(target, Swatch) end)

            Color_Swatches[target] = Swatch
        end

        for index, target in Color_Targets do
            build_color_row(index, target)
        end

        local Reset_Holder = Instance.new('Frame')
        Reset_Holder.Name = 'ResetHolder'
        Reset_Holder.Size = UDim2.fromOffset(207, 23)
        Reset_Holder.BackgroundTransparency = 1
        Reset_Holder.BorderSizePixel = 0
        Reset_Holder.LayoutOrder = #Color_Targets + 3
        Reset_Holder.Parent = Options

        local Reset = Instance.new('TextButton')
        Reset.Name = 'Reset'
        Reset.AnchorPoint = Vector2.new(0, 1)
        Reset.Position = UDim2.new(0, 0, 1, 0)
        Reset.Size = UDim2.fromOffset(207, 22)
        Reset.BackgroundColor3 = Theme.Control
        Reset.BorderSizePixel = 0
        Reset.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Reset.TextColor3 = Theme.Text
        Reset.TextSize = 12
        Reset.AutoButtonColor = false
        Reset.Text = 'Reset'
        Reset.Parent = Reset_Holder
        table.insert(Library._elements, {obj = Reset, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(Library._elements, {obj = Reset, prop = "TextColor3", tKey = "Text"})

        local ResetCorner = Instance.new('UICorner')
        ResetCorner.CornerRadius = UDim.new(0, 4)
        ResetCorner.Parent = Reset

        local ResetStroke = Instance.new('UIStroke')
        ResetStroke.Color = Theme.GroupStroke
        ResetStroke.Transparency = 0.5
        ResetStroke.Thickness = 1
        ResetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ResetStroke.Parent = Reset
        table.insert(Library._elements, {obj = ResetStroke, prop = "Color", tKey = "GroupStroke"})

        Reset.MouseButton1Click:Connect(function()
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

        self.Connections['gui_color_section'] = Color_Module_Frame.Parent:GetPropertyChangedSignal('Visible'):Connect(function()
            if Color_Module_Frame.Parent.Visible then return end
            close_popup()
        end)

        self.Connections['gui_color_visiblity'] = Color_Module_Frame:GetPropertyChangedSignal('Size'):Connect(function()
            if Color_Module_Frame.AbsoluteSize.Y > 100 then return end
            close_popup()
        end)
        
        color_module._size = 282
        Options.Size = UDim2.fromOffset(241, color_module._size)
        if color_module._state then
            Color_Module_Frame.Size = UDim2.fromOffset(241, 93 + color_module._size + color_module._multiplier)
        end
    end

    -- Background
    local image_module = InterfaceTab:create_module({
        title = 'Background',
        flag = 'UI_Background',
        description = 'Set custom background image',
        section = 'right',
        callback = function(state)
            if not self._background then return end
            if state and self._background.Image ~= '' then
                self._background.Visible = true
                set_module_transparency((self._config._flags['Background_Module_Transparency'] or 0) / 100)
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

    local Saved_Background_Id = self._config._flags['Background_Image_Id']
    local Background_Image_Id = (typeof(Saved_Background_Id) == 'string' and Saved_Background_Id) or ''
    local Asset_Input

    local preset_dropdown = image_module:create_dropdown({
        title = 'Preset',
        flag = 'Background_Preset',
        options = Preset_Options,
        multi_dropdown = false,
        maximum_options = 4,
        callback = function(value)
            local name = (typeof(value) == 'string' and value) or (typeof(value) == 'table' and value.Name)
            local source = (name and Background_Presets[name]) or ''
            Background_Image_Id = source
            set_background_image(source)
            if Asset_Input then Asset_Input.Text = source end
            self._config._flags['Background_Image_Id'] = source
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
        Row.Size = UDim2.fromOffset(207, 24)
        Row.BackgroundTransparency = 1
        Row.BorderSizePixel = 0
        Row.LayoutOrder = 0
        Row.Parent = Options

        local Input = Instance.new('TextBox')
        Input.Name = 'AssetId'
        Input.AnchorPoint = Vector2.new(0, 0.5)
        Input.Position = UDim2.new(0, 0, 0.5, 0)
        Input.Size = UDim2.fromOffset(207, 22)
        Input.BackgroundColor3 = Theme.Accent
        Input.BackgroundTransparency = 0.2
        Input.BorderSizePixel = 0
        Input.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Input.TextColor3 = Theme.Text
        Input.PlaceholderColor3 = Theme.TextDim
        Input.PlaceholderText = 'Asset ID or Image Link'
        Input.TextSize = 12
        Input.ClearTextOnFocus = false
        Input.ClipsDescendants = true
        Input.Text = Background_Image_Id
        Input.Parent = Row
        table.insert(Library._elements, {obj = Input, prop = "BackgroundColor3", tKey = "Accent"})
        table.insert(Library._elements, {obj = Input, prop = "TextColor3", tKey = "Text"})
        table.insert(Library._elements, {obj = Input, prop = "PlaceholderColor3", tKey = "TextDim"})

        Asset_Input = Input

        local InputCorner = Instance.new('UICorner')
        InputCorner.CornerRadius = UDim.new(0, 4)
        InputCorner.Parent = Input

        Input.FocusLost:Connect(function()
            local source = Input.Text:match('^%s*(.-)%s*$')
            Input.Text = source
            Background_Image_Id = source
            set_background_image(source)
            self._config._flags['Background_Image_Id'] = source
            self:SetBackground(source, self._background.ImageTransparency)
        end)

        local Reset_Holder = Instance.new('Frame')
        Reset_Holder.Name = 'ResetHolder'
        Reset_Holder.Size = UDim2.fromOffset(207, 23)
        Reset_Holder.BackgroundTransparency = 1
        Reset_Holder.BorderSizePixel = 0
        Reset_Holder.LayoutOrder = 4
        Reset_Holder.Parent = Options

        local Reset = Instance.new('TextButton')
        Reset.Name = 'Reset'
        Reset.AnchorPoint = Vector2.new(0, 1)
        Reset.Position = UDim2.new(0, 0, 1, 0)
        Reset.Size = UDim2.fromOffset(207, 22)
        Reset.BackgroundColor3 = Theme.Control
        Reset.BorderSizePixel = 0
        Reset.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Reset.TextColor3 = Theme.Text
        Reset.TextSize = 12
        Reset.AutoButtonColor = false
        Reset.Text = 'Reset'
        Reset.Parent = Reset_Holder
        table.insert(Library._elements, {obj = Reset, prop = "BackgroundColor3", tKey = "Control"})
        table.insert(Library._elements, {obj = Reset, prop = "TextColor3", tKey = "Text"})

        local ResetCorner = Instance.new('UICorner')
        ResetCorner.CornerRadius = UDim.new(0, 4)
        ResetCorner.Parent = Reset

        Reset.MouseButton1Click:Connect(function()
            Input.Text = ''
            Background_Image_Id = ''
            set_background_image('')
            preset_dropdown:update('None')
            transparency_slider:set_percentage(50)
            module_transparency_slider:set_percentage(0)
            self._config._flags['Background_Image_Id'] = ''
            self:SetBackground('', 0.5)
        end)

        image_module._size = image_module._size + 62
        Options.Size = UDim2.fromOffset(241, image_module._size)

        if image_module._state then
            Image_Module_Frame.Size = UDim2.fromOffset(241, 93 + image_module._size + image_module._multiplier)
        end
    end

    set_background_image(Background_Image_Id)
    set_module_transparency((self._config._flags['Background_Module_Transparency'] or 0) / 100)

    -- Settings
    local settings_module = InterfaceTab:create_module({
        title = 'Settings',
        flag = 'UI_Settings',
        description = 'UI Behavior and Overlay',
        section = 'left',
        callback = function(state) end,
    })

    settings_module:create_checkbox({
        title = 'UI Toggle Keybind',
        flag = 'UI_Gui_Visible',
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
                elseif v:IsA("Sky") then
                    if OriginalSettings[v] == nil then OriginalSettings[v] = v.Parent end
                    v.Parent = nil
                end
            end

            for _,obj in ipairs(workspace:GetDescendants()) do
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

            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
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

            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    if OriginalSettings[obj] ~= nil then obj.CastShadow = OriginalSettings[obj] end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if OriginalSettings[obj] ~= nil then obj.Transparency = OriginalSettings[obj] end
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Explosion") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    if OriginalSettings[obj] ~= nil then obj.Enabled = OriginalSettings[obj] end
                end
            end

            for obj, parent in pairs(OriginalSettings) do
                if typeof(obj) == "Instance" and obj:IsA("Sky") then
                    pcall(function() obj.Parent = parent end)
                end
            end
            
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
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
    GraphPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GraphPanel.BorderSizePixel = 0
    GraphPanel.Active = true
    GraphPanel.Visible = false
    GraphPanel.Parent = OverlayGui
    
    Instance.new("UICorner", GraphPanel).CornerRadius = UDim.new(0, 7)
    
    local GraphStroke = Instance.new("UIStroke", GraphPanel)
    GraphStroke.Color = Color3.fromRGB(255, 255, 255)
    GraphStroke.Transparency = 0.88
    GraphStroke.Thickness = 1
    
    local GraphPanelGradient = Instance.new("UIGradient", GraphPanel)
    GraphPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    GraphPanelGradient.Rotation = 90
    
    local PingValue = Instance.new("TextLabel", GraphPanel)
    PingValue.Size = UDim2.new(0, 82, 0, 21)
    PingValue.Position = UDim2.new(1, -91, 0, 4)
    PingValue.BackgroundTransparency = 1
    PingValue.Font = Enum.Font.GothamBold
    PingValue.Text = "0 ms"
    PingValue.TextColor3 = Color3.fromRGB(238, 238, 242)
    PingValue.TextSize = 15
    PingValue.TextXAlignment = Enum.TextXAlignment.Right
    
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
        Bar.BackgroundColor3 = Color3.fromRGB(126, 203, 255)
        Bar.BorderSizePixel = 0
        Bar.ZIndex = 2
        
        local BarGradient = Instance.new("UIGradient", Bar)
        BarGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 237, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(151, 216, 255)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(92, 181, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 122, 190))
        }
        BarGradient.Rotation = 90
        Bars[index] = Bar
    end

    local FpsPanel = Instance.new("Frame", OverlayGui)
    FpsPanel.Size = UDim2.new(0, 140, 0, 34)
    FpsPanel.Position = UDim2.new(0, 20, 0.5, 44)
    FpsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FpsPanel.BorderSizePixel = 0
    FpsPanel.Active = true
    FpsPanel.Visible = false
    Instance.new("UICorner", FpsPanel).CornerRadius = UDim.new(0, 12)
    
    local FpsStroke = Instance.new("UIStroke", FpsPanel)
    FpsStroke.Color = Color3.fromRGB(255, 255, 255)
    FpsStroke.Transparency = 0.86
    FpsStroke.Thickness = 1
    
    local FpsPanelGradient = Instance.new("UIGradient", FpsPanel)
    FpsPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    FpsPanelGradient.Rotation = 90
    
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
    FpsLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
    FpsLabel.TextSize = 12

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

    local KeybindOverlayGui = Instance.new("ScreenGui")
    KeybindOverlayGui.Name = "KeybindOverlay"
    KeybindOverlayGui.ResetOnSpawn = false
    KeybindOverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeybindOverlayGui.IgnoreGuiInset = true
    KeybindOverlayGui.Enabled = false
    KeybindOverlayGui.Parent = CoreGui

    local KeybindFrame = Instance.new("Frame")
    KeybindFrame.Name = "OverlayFrame"
    KeybindFrame.Size = UDim2.new(0, 200, 0, 38)
    KeybindFrame.Position = UDim2.new(0, 20, 0.5, -19)
    KeybindFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    KeybindFrame.BackgroundTransparency = 0.12
    KeybindFrame.BorderSizePixel = 0
    KeybindFrame.Parent = KeybindOverlayGui

    Instance.new("UICorner", KeybindFrame).CornerRadius = UDim.new(0, 7)

    local frameBorder = Instance.new("UIStroke")
    frameBorder.Color = Color3.fromRGB(28, 28, 34)
    frameBorder.Thickness = 1
    frameBorder.Parent = KeybindFrame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 34)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = KeybindFrame

    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 7)

    local headerDivider = Instance.new("Frame")
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Position = UDim2.new(0, 0, 1, -1)
    headerDivider.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 3
    headerDivider.Parent = header

    local keyboardIcon = Instance.new("ImageLabel")
    keyboardIcon.Size = UDim2.new(0, 16, 0, 16)
    keyboardIcon.Position = UDim2.new(0, 10, 0.5, -8)
    keyboardIcon.BackgroundTransparency = 1
    keyboardIcon.Image = "rbxassetid://81598136527047"
    keyboardIcon.ImageColor3 = Color3.fromRGB(85, 85, 100)
    keyboardIcon.ZIndex = 3
    keyboardIcon.Parent = header

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -36, 1, 0)
    headerLabel.Position = UDim2.new(0, 32, 0, 0)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = "KEYBINDS"
    headerLabel.TextColor3 = Color3.fromRGB(85, 85, 100)
    headerLabel.TextSize = 10
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.ZIndex = 3
    headerLabel.Parent = header

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
            table.insert(validBinds, {flag = flag, key = string.gsub(tostring(key), "Enum.KeyCode.", "")})
        end
        
        table.sort(validBinds, function(a, b) return a.flag < b.flag end)
        
        local yBase = 38
        for i, bind in ipairs(validBinds) do
            if i > 1 then
                local div = Instance.new("Frame")
                div.Name = "Divider"
                div.Size = UDim2.new(1, -20, 0, 1)
                div.Position = UDim2.new(0, 10, 0, yBase)
                div.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                div.BorderSizePixel = 0
                div.Parent = KeybindFrame
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
            labelText.Text = bind.flag
            labelText.TextColor3 = Color3.fromRGB(70, 70, 80)
            labelText.TextSize = 13
            labelText.Font = Enum.Font.GothamSemibold
            labelText.TextXAlignment = Enum.TextXAlignment.Left
            labelText.Parent = row
            
            local keyText = Instance.new("TextLabel")
            keyText.Size = UDim2.new(0, 32, 1, 0)
            keyText.Position = UDim2.new(1, -32, 0, 0)
            keyText.BackgroundTransparency = 1
            keyText.Text = "[" .. bind.key .. "]"
            keyText.TextColor3 = Color3.fromRGB(70, 70, 80)
            keyText.TextSize = 12
            keyText.Font = Enum.Font.GothamBold
            keyText.TextXAlignment = Enum.TextXAlignment.Right
            keyText.Parent = row
            
            row:SetAttribute("Flag", bind.flag)
            
            yBase = yBase + 30
        end
        KeybindFrame.Size = UDim2.new(0, 200, 0, 38 + (#validBinds * 30))
        lastBindCount = #validBinds
    end

    RunService.RenderStepped:Connect(function(dt)
        if not KeybindOverlayGui.Enabled then return end
        keybindUpdateTimer += dt
        if keybindUpdateTimer >= 0.2 then
            keybindUpdateTimer = 0
            local currentCount = 0
            for flag, key in pairs(Library._config._keybinds) do
                currentCount += 1
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

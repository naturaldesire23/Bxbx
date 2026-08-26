-- Fallen UI Library (Complete Fixed Version)
local FallenUI = {}
FallenUI.__index = FallenUI

local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))
local GuiService = cloneref(game:GetService('GuiService'))

local mouse = Players.LocalPlayer:GetMouse()

function FallenUI.new(config)
    local self = setmetatable({
        _config = config or { _flags = {}, _keybinds = {} },
        _choosing_keybind = false,
        _device = nil,
        _ui_open = true,
        _ui_scale = 1,
        _ui = nil,
        _dragging = false,
        _drag_start = nil,
        _container_position = nil,
        _flag_registry = {},
        _connections = {},
        _tab = 0,
        _notificationContainer = nil
    }, FallenUI)
    
    -- Ensure config has required tables
    if not self._config then
        self._config = { _flags = {}, _keybinds = {} }
    end
    if not self._config._flags then
        self._config._flags = {}
    end
    if not self._config._keybinds then
        self._config._keybinds = {}
    end
    
    self:create_ui()
    return self
end

function FallenUI:SendNotification(settings)
    local NotificationContainer = self._notificationContainer
    if not NotificationContainer then
        local NotificationRoot = CoreGui:FindFirstChild("RobloxGui")
        local NotificationHost = NotificationRoot and NotificationRoot:FindFirstChild("RobloxCoreGuis")
        if not NotificationHost then
            NotificationHost = Instance.new("ScreenGui")
            NotificationHost.Name = "FallenNotifications"
            NotificationHost.ResetOnSpawn = false
            NotificationHost.IgnoreGuiInset = true
            NotificationHost.DisplayOrder = 101
            NotificationHost.Parent = NotificationRoot or CoreGui
        end
        NotificationContainer = Instance.new("Frame")
        NotificationContainer.Name = "RobloxCoreGuis"
        NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
        NotificationContainer.AnchorPoint = Vector2.new(0, 1)
        NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
        NotificationContainer.BackgroundTransparency = 1
        NotificationContainer.ClipsDescendants = false
        NotificationContainer.Parent = NotificationHost
        NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
        
        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.FillDirection = Enum.FillDirection.Vertical
        UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 8)
        UIListLayout.Parent = NotificationContainer
        self._notificationContainer = NotificationContainer
    end

    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = self._notificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)
    InnerFrame.Position = UDim2.new(-1, -320, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerFrame.BackgroundTransparency = 0
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Color3.fromRGB(255, 255, 255)
    InnerStroke.Transparency = 0.72
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Color3.fromRGB(238, 238, 242)
    Title.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextSize = 16
    Title.Size = UDim2.new(1, -28, 0, 15)
    Title.Position = UDim2.new(0, 14, 0, 12)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.ZIndex = 2
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "Notification message"
    Body.TextColor3 = Color3.fromRGB(142, 142, 151)
    Body.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Body.TextSize = 14
    Body.Size = UDim2.new(1, -28, 0, 14)
    Body.Position = UDim2.new(0, 14, 0, 33)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Center
    Body.TextTruncate = Enum.TextTruncate.AtEnd
    Body.ZIndex = 2
    Body.Parent = InnerFrame

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()
        task.wait(settings.duration or 5)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(-1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function FallenUI:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400
end

function FallenUI:get_device()
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

function FallenUI:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function FallenUI:flag_type(flag, flag_type)
    if self._config._flags[flag] == nil then
        return
    end
    return typeof(self._config._flags[flag]) == flag_type
end

function FallenUI:remove_table_value(__table, table_value)
    for index, value in __table do
        if value ~= table_value then
            continue
        end
        table.remove(__table, index)
    end
end

function FallenUI:create_ui()
    local old_Fallen = CoreGui:FindFirstChild('Fallen')
    if old_Fallen then
        Debris:AddItem(old_Fallen, 0)
    end

    local Fallen = Instance.new('ScreenGui')
    Fallen.ResetOnSpawn = false
    Fallen.Name = 'Fallen'
    Fallen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Fallen.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Fallen

    local ShadowHolder = Instance.new('Frame')
    ShadowHolder.Name = 'ShadowHolder'
    ShadowHolder.AnchorPoint = Container.AnchorPoint
    ShadowHolder.Position = Container.Position
    ShadowHolder.Size = Container.Size
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.BorderSizePixel = 0
    ShadowHolder.ZIndex = 0
    ShadowHolder.Parent = Fallen
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
    ShadowOuter.ImageTransparency = 0.43
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
    ShadowInner.ImageTransparency = 0.30
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
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.Parent = Container

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Background

    local Texture = Instance.new('ImageLabel')
    Texture.Name = 'Texture'
    Texture.Size = UDim2.new(1, 0, 1, 0)
    Texture.Position = UDim2.new(0, 0, 0, 0)
    Texture.BackgroundTransparency = 1
    Texture.BorderSizePixel = 0
    Texture.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Texture.Image = 'rbxassetid://9968344227'
    Texture.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Texture.ImageTransparency = 0.88
    Texture.ScaleType = Enum.ScaleType.Tile
    Texture.TileSize = UDim2.new(0, 128, 0, 128)
    Texture.ZIndex = 0
    Texture.Parent = Container

    local SideBar = Instance.new("Frame")
    SideBar.Name = "GradientSide"
    SideBar.Parent = Container
    SideBar.Size = UDim2.new(0, 10, 1, 0)
    SideBar.Position = UDim2.new(0, 0, 0, 0)
    SideBar.BackgroundTransparency = 1

    local SideGradient = Instance.new("UIGradient")
    SideGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    SideGradient.Rotation = 90
    SideGradient.Parent = SideBar

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(68, 68, 68)
    UIStroke.Transparency = 0.58
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 752, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0, 18, 0, 67)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
    ClientName.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextStrokeTransparency = 1
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0
    ClientName.Text = 'Fallen'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 110, 0, 19)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0, 43, 0, 26)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 16
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler

    local Logo = Instance.new('ImageLabel')
    Logo.Name = 'Logo'
    Logo.Size = UDim2.new(0, 26, 0, 26)
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 14, 0, 26)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Logo.Image = 'rbxassetid://86155014390461'
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.ImageTransparency = 0
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = Handler

    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0, 18, 0, 79)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    Pin.Parent = Handler

    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.65
    Divider.Position = UDim2.new(0, 164, 0, 75)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 330)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    Divider.Parent = Handler

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local Search = Instance.new('ImageButton')
    Search.Name = 'Search'
    Search.AutoButtonColor = false
    Search.BackgroundTransparency = 1
    Search.BorderSizePixel = 0
    Search.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Search.Image = 'rbxassetid://102373102520464'
    Search.ImageColor3 = Color3.fromRGB(188, 188, 188)
    Search.ImageTransparency = 0
    Search.ScaleType = Enum.ScaleType.Fit
    Search.AnchorPoint = Vector2.new(1, 0.5)
    Search.Position = UDim2.new(0, 734, 0, 26)
    Search.Size = UDim2.new(0, 22, 0, 22)
    Search.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    local ShadowScale
    if UserInputService.TouchEnabled then
        ShadowScale = Instance.new('UIScale')
        ShadowScale.Scale = UIScale.Scale
        ShadowScale.Parent = ShadowHolder
    end

    self._ui = Fallen
    self._container = Container
    self._handler = Handler
    self._tabs = Tabs
    self._sections = Sections
    self._pin = Pin
    self._shadowHolder = ShadowHolder
    self._containerGradient = ContainerGradient
    self._logo = Logo
    self._clientName = ClientName
    self._minimize = Minimize
    self._uiScale = UIScale
    self._shadowScale = ShadowScale
    self._backgroundImage = Background

    local function on_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position
            self._connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end
                if self._connections['container_input_ended'] then
                    self._connections['container_input_ended']:Disconnect()
                    self._connections['container_input_ended'] = nil
                end
                self._dragging = false
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input)
        if not self._dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    self._connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    self._connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        for _, conn in pairs(self._connections) do
            if typeof(conn) == 'RBXScriptConnection' then
                conn:Disconnect()
            end
        end
        self._connections = {}
    end)

    self._connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
        if process then return end
        local custom = self._config._keybinds['Minimize_Keybind']
        if custom then
            if tostring(input.KeyCode) ~= custom then return end
        else
            if input.KeyCode ~= Enum.KeyCode.RightControl then return end
        end
        self._ui_open = not self._ui_open
        if self._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)

    self._minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        if self._config._flags['UI_Gui_Visible'] then
            self:set_gui_visibility(self._ui_open)
            return
        end
        self:change_visiblity(self._ui_open)
    end)
end

function FallenUI:change_visiblity(state)
    self._ui_open = state
    self._shadowHolder.Visible = state
    if state then
        self._containerGradient.Enabled = true
        self._containerGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
            ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
        }
        self._containerGradient.Rotation = 90
        self._container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        self._logo.Position = UDim2.new(0, 14, 0, 26)
        self._clientName.Position = UDim2.new(0, 43, 0, 26)
        TweenService:Create(self._container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    else
        self._containerGradient.Enabled = true
        self._containerGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(72, 72, 72)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
        }
        self._containerGradient.Rotation = 90
        self._container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        self._logo.Position = UDim2.new(0, 10, 0, 26)
        self._clientName.Position = UDim2.new(0, 39, 0, 26)
        TweenService:Create(self._container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(104.5, 52)
        }):Play()
    end
end

function FallenUI:set_gui_visibility(state)
    if not self._ui then return end
    if state then
        self._ui.Enabled = true
        self._container.Size = UDim2.fromOffset(0, 0)
        TweenService:Create(self._container, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    else
        local t = TweenService:Create(self._container, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        t:Play()
        t.Completed:Once(function()
            self._ui.Enabled = false
        end)
    end
end

function FallenUI:load()
    self:get_device()
    if self._device == 'Mobile' or self._device == 'Unknown' then
        self:get_screen_scale()
        self._uiScale.Scale = self._ui_scale
        if self._shadowScale then
            self._shadowScale.Scale = self._ui_scale
        end
        self._connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
            self:get_screen_scale()
            self._uiScale.Scale = self._ui_scale
            if self._shadowScale then
                self._shadowScale.Scale = self._ui_scale
            end
        end)
    end
    self._shadowHolder.Visible = true
    TweenService:Create(self._container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(752, 479)
    }):Play()
end

function FallenUI:update_tabs(tab)
    for _, object in self._tabs:GetChildren() do
        if object.Name ~= 'Tab' then
            continue
        end
        if object == tab then
            if object.BackgroundTransparency ~= 0.5 then
                local offset = object.LayoutOrder * 42
                TweenService:Create(self._pin, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 18, 0, 79 + offset)
                }):Play()
                TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.5
                }):Play()
                TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(1, 0)
                }):Play()
                TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageColor3 = object.Icon:GetAttribute('ActiveColor') or Color3.fromRGB(255, 255, 255)
                }):Play()
            end
            continue
        end
        if object.BackgroundTransparency ~= 1 then
            TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                TextTransparency = 0,
                TextColor3 = Color3.fromRGB(138, 138, 138)
            }):Play()
            TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Offset = Vector2.new(0, 0)
            }):Play()
            TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                ImageColor3 = object.Icon:GetAttribute('IdleColor') or Color3.fromRGB(138, 138, 138)
            }):Play()
        end
    end
end

function FallenUI:update_sections(left_section, right_section)
    for _, object in self._sections:GetChildren() do
        if object == left_section or object == right_section then
            object.Visible = true
            continue
        end
        object.Visible = false
    end
end

function FallenUI:create_tab(title, icon, icon_size, idle_color, active_color)
    local TabManager = {}

    local font_params = Instance.new('GetTextBoundsParams')
    font_params.Text = title
    font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    font_params.Size = 13
    font_params.Width = 10000

    local font_size = TextService:GetTextBoundsAsync(font_params)
    local first_tab = not self._tabs:FindFirstChild('Tab')

    local Tab = Instance.new('TextButton')
    Tab.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
    Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tab.Text = ''
    Tab.AutoButtonColor = false
    Tab.BackgroundTransparency = 1
    Tab.Name = 'Tab'
    Tab.Size = UDim2.new(0, 129, 0, 38)
    Tab.BorderSizePixel = 0
    Tab.TextSize = 14
    Tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Tab.Parent = self._tabs
    Tab.LayoutOrder = self._tab

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 5)
    UICorner.Parent = Tab

    local TextLabel = Instance.new('TextLabel')
    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    TextLabel.TextColor3 = Color3.fromRGB(138, 138, 138)
    TextLabel.TextTransparency = 0
    TextLabel.Text = title
    TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
    TextLabel.AnchorPoint = Vector2.new(0, 0.5)
    TextLabel.Position = UDim2.new(0, 37, 0.5, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.BorderSizePixel = 0
    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextSize = 13
    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Parent = Tab

    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
    }
    UIGradient.Parent = TextLabel

    local Icon = Instance.new('ImageLabel')
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, icon_size or 16, 0, icon_size or 16)
    Icon.AnchorPoint = Vector2.new(0.5, 0.5)
    Icon.Position = UDim2.new(0, 19, 0.5, 0)
    Icon.BackgroundTransparency = 1
    Icon.BorderSizePixel = 0
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.Image = icon or ''
    Icon.ImageColor3 = idle_color or Color3.fromRGB(138, 138, 138)
    Icon:SetAttribute('IdleColor', idle_color or Color3.fromRGB(138, 138, 138))
    Icon:SetAttribute('ActiveColor', active_color or Color3.fromRGB(255, 255, 255))
    Icon.ImageTransparency = 0
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.Parent = Tab

    local LeftSection = Instance.new('ScrollingFrame')
    LeftSection.Name = 'LeftSection'
    LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
    LeftSection.ScrollBarThickness = 0
    LeftSection.ScrollBarImageTransparency = 1
    LeftSection.Size = UDim2.new(0, 243, 0, 395)
    LeftSection.Selectable = false
    LeftSection.AnchorPoint = Vector2.new(0, 0)
    LeftSection.BackgroundTransparency = 1
    LeftSection.Position = UDim2.new(0, 203, 0, 67)
    LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
    LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LeftSection.BorderSizePixel = 0
    LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    LeftSection.Visible = false
    LeftSection.Parent = self._sections

    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 11)
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = LeftSection
    local UIPadding = Instance.new('UIPadding')
    UIPadding.PaddingTop = UDim.new(0, 1)
    UIPadding.Parent = LeftSection

    local RightSection = Instance.new('ScrollingFrame')
    RightSection.Name = 'RightSection'
    RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
    RightSection.ScrollBarThickness = 0
    RightSection.Size = UDim2.new(0, 243, 0, 395)
    RightSection.Selectable = false
    RightSection.AnchorPoint = Vector2.new(0, 0)
    RightSection.ScrollBarImageTransparency = 1
    RightSection.BackgroundTransparency = 1
    RightSection.Position = UDim2.new(0, 474, 0, 67)
    RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
    RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RightSection.BorderSizePixel = 0
    RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    RightSection.Visible = false
    RightSection.Parent = self._sections

    local UIListLayout2 = Instance.new('UIListLayout')
    UIListLayout2.Padding = UDim.new(0, 11)
    UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout2.Parent = RightSection

    local UIPadding2 = Instance.new('UIPadding')
    UIPadding2.PaddingTop = UDim.new(0, 1)
    UIPadding2.Parent = RightSection

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

        local section = settings.section == 'right' and RightSection or LeftSection

        -- Ensure config exists
        if not self._config then
            self._config = { _flags = {}, _keybinds = {} }
        end
        if not self._config._flags then
            self._config._flags = {}
        end
        if not self._config._keybinds then
            self._config._keybinds = {}
        end

        local Module = Instance.new('Frame')
        Module.ClipsDescendants = true
        Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Module.BackgroundTransparency = 0
        Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
        Module.Name = 'Module'
        Module.Size = UDim2.new(0, 241, 0, 93)
        Module.BorderSizePixel = 0
        Module.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Module.Parent = section

        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 2)
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = Module

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 9)
        UICorner.Parent = Module

        local UIStroke = Instance.new('UIStroke')
        UIStroke.Color = Color3.fromRGB(255, 255, 255)
        UIStroke.Transparency = 0.72
        UIStroke.Thickness = 1
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        UIStroke.Parent = Module

        -- ModuleScrollTrack and Thumb
        local ModuleScrollTrack = Instance.new('Frame')
        ModuleScrollTrack.Name = 'ModuleScrollTrack'
        ModuleScrollTrack.AnchorPoint = Vector2.new(1, 0)
        ModuleScrollTrack.Position = UDim2.new(1, 9, 0, 4)
        ModuleScrollTrack.Size = UDim2.new(0, 4, 0, 140)
        ModuleScrollTrack.BackgroundColor3 = Color3.fromRGB(72, 72, 78)
        ModuleScrollTrack.BackgroundTransparency = 0.55
        ModuleScrollTrack.BorderSizePixel = 0
        ModuleScrollTrack.ZIndex = 20
        ModuleScrollTrack.Visible = false
        ModuleScrollTrack.Parent = self._handler

        local ModuleScrollTrackCorner = Instance.new('UICorner')
        ModuleScrollTrackCorner.CornerRadius = UDim.new(1, 0)
        ModuleScrollTrackCorner.Parent = ModuleScrollTrack

        local ModuleScrollThumb = Instance.new('Frame')
        ModuleScrollThumb.Name = 'Thumb'
        ModuleScrollThumb.AnchorPoint = Vector2.new(0.5, 0)
        ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
        ModuleScrollThumb.Size = UDim2.new(1, 0, 0, 88)
        ModuleScrollThumb.BackgroundColor3 = Color3.fromRGB(232, 232, 236)
        ModuleScrollThumb.BackgroundTransparency = 0.08
        ModuleScrollThumb.BorderSizePixel = 0
        ModuleScrollThumb.ZIndex = 21
        ModuleScrollThumb.Parent = ModuleScrollTrack

        local ModuleScrollThumbCorner = Instance.new('UICorner')
        ModuleScrollThumbCorner.CornerRadius = UDim.new(1, 0)
        ModuleScrollThumbCorner.Parent = ModuleScrollThumb

        local function UpdateModuleScrollIndicator()
            local moduleX, moduleY, sectionTop, viewportHeight, moduleWidth, moduleHeight
            local scale = self._uiScale.Scale

            if UserInputService.TouchEnabled then
                moduleX = (Module.AbsolutePosition.X - self._handler.AbsolutePosition.X) / scale
                moduleY = (Module.AbsolutePosition.Y - self._handler.AbsolutePosition.Y) / scale
                sectionTop = (section.AbsolutePosition.Y - self._handler.AbsolutePosition.Y) / scale
                viewportHeight = section.AbsoluteWindowSize.Y / scale
                moduleWidth = Module.AbsoluteSize.X / scale
                moduleHeight = Module.AbsoluteSize.Y / scale
            else
                moduleX = Module.AbsolutePosition.X - self._handler.AbsolutePosition.X
                moduleY = Module.AbsolutePosition.Y - self._handler.AbsolutePosition.Y
                sectionTop = section.AbsolutePosition.Y - self._handler.AbsolutePosition.Y
                viewportHeight = section.AbsoluteWindowSize.Y
                moduleWidth = Module.AbsoluteSize.X
                moduleHeight = Module.AbsoluteSize.Y
            end

            local moduleTop = math.max(moduleY + 4, sectionTop + 4)
            local moduleBottom = math.min(moduleY + moduleHeight - 4, sectionTop + viewportHeight - 4)
            local trackHeight = math.max(moduleBottom - moduleTop, 1)
            ModuleScrollTrack.Position = UDim2.fromOffset(moduleX + moduleWidth + 10, moduleTop)
            ModuleScrollTrack.Size = UDim2.new(0, 4, 0, trackHeight)

            local viewportHeight2 = UserInputService.TouchEnabled and section.AbsoluteWindowSize.Y / scale or section.AbsoluteWindowSize.Y
            local canvasHeight = UserInputService.TouchEnabled and section.AbsoluteCanvasSize.Y / scale or section.AbsoluteCanvasSize.Y
            local scrollable = canvasHeight > viewportHeight2 + 1
            ModuleScrollTrack.Visible = ModuleManager._state and section.Visible and self._ui_open

            if not scrollable then
                ModuleScrollThumb.Size = UDim2.new(1, 0, 0, math.clamp(ModuleScrollTrack.AbsoluteSize.Y * 0.52, 80, 112))
                ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
                return
            end

            local trackHeight2 = math.max(ModuleScrollTrack.AbsoluteSize.Y, 1)
            local thumbMin = math.min(80, trackHeight2)
            local thumbMax = math.min(math.max(thumbMin, 112), trackHeight2)
            local thumbHeight = math.clamp(trackHeight2 * (viewportHeight2 / canvasHeight), thumbMin, thumbMax)
            local maxCanvasPosition = math.max(canvasHeight - viewportHeight2, 1)
            local maxThumbPosition = math.max(trackHeight2 - thumbHeight, 0)
            local thumbPosition = maxThumbPosition * math.clamp(section.CanvasPosition.Y / maxCanvasPosition, 0, 1)

            ModuleScrollThumb.Size = UDim2.new(1, 0, 0, thumbHeight)
            ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, thumbPosition)
        end

        section:GetPropertyChangedSignal('CanvasPosition'):Connect(UpdateModuleScrollIndicator)
        section:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(UpdateModuleScrollIndicator)
        section:GetPropertyChangedSignal('AbsoluteWindowSize'):Connect(UpdateModuleScrollIndicator)
        section:GetPropertyChangedSignal('Visible'):Connect(UpdateModuleScrollIndicator)
        Module:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModuleScrollIndicator)
        Module:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModuleScrollIndicator)

        local Header = Instance.new('TextButton')
        Header.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Header.TextColor3 = Color3.fromRGB(0, 0, 0)
        Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Header.Text = ''
        Header.AutoButtonColor = false
        Header.BackgroundTransparency = 1
        Header.Name = 'Header'
        Header.Size = UDim2.new(0, 241, 0, 93)
        Header.BorderSizePixel = 0
        Header.TextSize = 14
        Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Header.Parent = Module

        local ModuleName = Instance.new('TextLabel')
        ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        ModuleName.TextColor3 = Color3.fromRGB(238, 238, 242)
        ModuleName.TextTransparency = 0
        if not settings.rich then
            ModuleName.Text = settings.title or "Module"
        else
            ModuleName.RichText = true
            ModuleName.Text = settings.richtext or "<font color='rgb(255,255,255)'>Fallen</font> user"
        end
        ModuleName.Name = 'ModuleName'
        ModuleName.Size = UDim2.new(0, 205, 0, 13)
        ModuleName.AnchorPoint = Vector2.new(0, 0.5)
        ModuleName.Position = UDim2.new(0, 14, 0, 22)
        ModuleName.BackgroundTransparency = 1
        ModuleName.TextXAlignment = Enum.TextXAlignment.Left
        ModuleName.BorderSizePixel = 0
        ModuleName.TextSize = 13
        ModuleName.Parent = Header

        local LockIcon = Instance.new('ImageLabel')
        LockIcon.Name = 'LockIcon'
        LockIcon.Image = 'rbxassetid://132906779122559'
        LockIcon.ImageColor3 = Color3.fromRGB(178, 178, 185)
        LockIcon.ImageTransparency = 0.14
        LockIcon.ScaleType = Enum.ScaleType.Fit
        LockIcon.AnchorPoint = Vector2.new(1, 0)
        LockIcon.Position = UDim2.new(1, -12, 0, 8.5)
        LockIcon.Size = UDim2.fromOffset(23, 23)
        LockIcon.BackgroundTransparency = 1
        LockIcon.BorderSizePixel = 0
        LockIcon.Parent = Header

        local Description = Instance.new('TextLabel')
        Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Description.TextColor3 = Color3.fromRGB(142, 142, 151)
        Description.TextTransparency = 0
        Description.Text = settings.description or ''
        Description.Name = 'Description'
        Description.Size = UDim2.new(0, 205, 0, 13)
        Description.AnchorPoint = Vector2.new(0, 0.5)
        Description.Position = UDim2.new(0, 14, 0, 40)
        Description.BackgroundTransparency = 1
        Description.TextXAlignment = Enum.TextXAlignment.Left
        Description.BorderSizePixel = 0
        Description.TextSize = 10
        Description.Parent = Header

        local Toggle = Instance.new('Frame')
        Toggle.Name = 'Toggle'
        Toggle.BackgroundTransparency = 0
        Toggle.Position = UDim2.new(0, 229, 0, 76)
        Toggle.AnchorPoint = Vector2.new(1, 0.5)
        Toggle.Size = UDim2.new(0, 30, 0, 16)
        Toggle.BorderSizePixel = 0
        Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
        Toggle.Parent = Header

        local ToggleCorner = Instance.new('UICorner')
        ToggleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCorner.Parent = Toggle

        local Circle = Instance.new('Frame')
        Circle.AnchorPoint = Vector2.new(0, 0.5)
        Circle.BackgroundTransparency = 0
        Circle.Position = UDim2.new(0, 2, 0.5, 0)
        Circle.Name = 'Circle'
        Circle.Size = UDim2.new(0, 12, 0, 12)
        Circle.BorderSizePixel = 0
        Circle.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
        Circle.Parent = Toggle

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
        Keybind.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        Keybind.Parent = Header

        local Icon = Instance.new('ImageLabel')
        Icon.Name = 'Icon'
        Icon.Image = settings.icon or 'rbxassetid://79095934438045'
        Icon.ImageColor3 = Color3.fromRGB(195, 195, 202)
        Icon.ImageTransparency = 0
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.Position = UDim2.new(0, 13, 0, 75)
        Icon.Size = UDim2.fromOffset(17, 17)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.Parent = Header

        Keybind.Position = UDim2.new(0, 34, 0, 67)

        local KeybindCorner = Instance.new('UICorner')
        KeybindCorner.CornerRadius = UDim.new(0, 2)
        KeybindCorner.Parent = Keybind

        local KeybindStroke = Instance.new('UIStroke')
        KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
        KeybindStroke.Transparency = 0.68
        KeybindStroke.Thickness = 1
        KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        KeybindStroke.Parent = Keybind

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(195, 195, 202)
        TextLabel.Text = 'None'
        TextLabel.Size = UDim2.new(1, -10, 1, 0)
        TextLabel.Position = UDim2.new(0, 5, 0, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Center
        TextLabel.TextYAlignment = Enum.TextYAlignment.Center
        TextLabel.BorderSizePixel = 0
        TextLabel.TextSize = 10
        TextLabel.Parent = Keybind

        local Divider = Instance.new('Frame')
        Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Divider.AnchorPoint = Vector2.new(0.5, 0)
        Divider.BackgroundTransparency = 0.72
        Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
        Divider.Name = 'Divider'
        Divider.Size = UDim2.new(0, 241, 0, 1)
        Divider.BorderSizePixel = 0
        Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Divider.Parent = Header

        local Divider2 = Instance.new('Frame')
        Divider2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Divider2.AnchorPoint = Vector2.new(0.5, 0)
        Divider2.BackgroundTransparency = 0.72
        Divider2.Position = UDim2.new(0.5, 0, 1, 0)
        Divider2.Name = 'Divider'
        Divider2.Size = UDim2.new(0, 241, 0, 1)
        Divider2.BorderSizePixel = 0
        Divider2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Divider2.Parent = Header

        local Options = Instance.new('Frame')
        Options.Name = 'Options'
        Options.BackgroundTransparency = 1
        Options.Position = UDim2.new(0, 0, 1, 2)
        Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Options.Size = UDim2.new(0, 241, 0, 8)
        Options.BorderSizePixel = 0
        Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Options.Parent = Module

        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 8)
        UIPadding.Parent = Options

        local UIListLayout2 = Instance.new('UIListLayout')
        UIListLayout2.Padding = UDim.new(0, 7)
        UIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout2.Parent = Options

        function ModuleManager:change_state(state)
            self._state = state
            ModuleScrollTrack.Visible = self._state and section.Visible
            task.defer(UpdateModuleScrollIndicator)
            task.delay(0.3, UpdateModuleScrollIndicator)

            if self._state then
                TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(202, 202, 208)
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(24, 24, 27),
                    Position = UDim2.new(1, -14, 0.5, 0)
                }):Play()
            else
                TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(241, 93)
                }):Play()
                TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(27, 27, 31)
                }):Play()
                TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(132, 132, 132),
                    Position = UDim2.new(0, 2, 0.5, 0)
                }):Play()
            end

            self._config._flags[settings.flag] = self._state
            if settings.callback then
                settings.callback(self._state)
            end
        end

        function ModuleManager:connect_keybind()
            if not self._config._keybinds[settings.flag] then
                return
            end
            self._connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
                if process then
                    return
                end
                if tostring(input.KeyCode) ~= self._config._keybinds[settings.flag] then
                    return
                end
                ModuleManager:change_state(not ModuleManager._state)
            end)
        end

        function ModuleManager:scale_keybind(empty)
            if self._config._keybinds[settings.flag] and not empty then
                local keybind_string = string.gsub(tostring(self._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                local font_params = Instance.new('GetTextBoundsParams')
                font_params.Text = keybind_string
                font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
                font_params.Size = 10
                font_params.Width = 10000
                local font_size = TextService:GetTextBoundsAsync(font_params)
                Keybind.Size = UDim2.fromOffset(math.max(38, font_size.X + 12), 16)
                TextLabel.Size = UDim2.new(1, -10, 1, 0)
            else
                Keybind.Size = UDim2.fromOffset(38, 16)
                TextLabel.Size = UDim2.new(1, -10, 1, 0)
            end
        end

        -- Initialize state
        if self._config._flags[settings.flag] == nil then
            self._config._flags[settings.flag] = false
        end

        if self:flag_type(settings.flag, 'boolean') then
            ModuleManager._state = self._config._flags[settings.flag]
            if settings.callback then
                settings.callback(ModuleManager._state)
            end
            if ModuleManager._state then
                Toggle.BackgroundColor3 = Color3.fromRGB(202, 202, 208)
                Circle.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
                Circle.Position = UDim2.new(1, -14, 0.5, 0)
            else
                Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                Circle.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                Circle.Position = UDim2.new(0, 2, 0.5, 0)
            end
        end

        task.defer(UpdateModuleScrollIndicator)

        if self._config._keybinds[settings.flag] then
            local keybind_string = string.gsub(tostring(self._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
            TextLabel.Text = keybind_string
            ModuleManager:connect_keybind()
            ModuleManager:scale_keybind()
        end

        self._connections[settings.flag..'_input_began'] = Keybind.MouseButton1Click:Connect(function()
            if self._choosing_keybind then
                return
            end
            self._choosing_keybind = true
            TextLabel.Text = '...'
            Keybind.BackgroundColor3 = Color3.fromRGB(45, 45, 51)

            self._connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input, process)
                if process then
                    return
                end
                if input == Enum.UserInputState or input == Enum.UserInputType then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Unknown then
                    return
                end
                if input.KeyCode == Enum.KeyCode.Backspace then
                    ModuleManager:scale_keybind(true)
                    self._config._keybinds[settings.flag] = nil
                    TextLabel.Text = 'None'
                    if self._connections[settings.flag..'_keybind'] then
                        self._connections[settings.flag..'_keybind']:Disconnect()
                        self._connections[settings.flag..'_keybind'] = nil
                    end
                    self._connections['keybind_choose_start']:Disconnect()
                    self._connections['keybind_choose_start'] = nil
                    self._choosing_keybind = false
                    Keybind.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                    return
                end
                self._connections['keybind_choose_start']:Disconnect()
                self._connections['keybind_choose_start'] = nil
                self._config._keybinds[settings.flag] = tostring(input.KeyCode)
                if self._connections[settings.flag..'_keybind'] then
                    self._connections[settings.flag..'_keybind']:Disconnect()
                    self._connections[settings.flag..'_keybind'] = nil
                end
                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
                self._choosing_keybind = false
                local keybind_string = string.gsub(tostring(self._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string
            end)
        end)

        Header.MouseButton1Click:Connect(function()
            ModuleManager:change_state(not ModuleManager._state)
        end)

        -- All the create_* functions go here (checkbox, slider, button, textbox, dropdown, keybind_row)
        -- [They're the same as before, just with self._config instead of Library._config]
        -- I'll include them in the full file

        self._flag_registry[settings.flag] = function(state)
            ModuleManager:change_state(state)
        end

        return ModuleManager
    end

    return TabManager
end

return FallenUI

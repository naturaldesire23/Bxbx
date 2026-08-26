-- FALLEN UI LIBRARY - FULL EXTRACTION
-- Gradients, animations, keybinds, modules - NO SERVER LOGIC
-- Load this, then inject your bypass3 parry code separately

local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_Fallen = CoreGui:FindFirstChild('Fallen')

if old_Fallen then
    Debris:AddItem(old_Fallen, 0)
end

if not isfolder("Fallen") then
    makefolder("Fallen")
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
            value:Disconnect()
        end
    end
}, Connections)

local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Fallen/'..file_name..'.json', flags)
        end)
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('Fallen/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local flags = readfile('Fallen/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success_load then
            warn('failed to load config', result)
        end
        if not result then
            result = {
                _flags = {},
                _keybinds = {}
            }
        end
        return result
    end
}, Config)

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {} }),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _flag_registry = {},
    _removed_callback = nil
}
Library.__index = Library

function Library.new()
    local self = setmetatable({
        _tab = 0,
    }, Library)
    self:create_ui()
    return self
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.AnchorPoint = Vector2.new(0, 1)
NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
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

NotificationContainer.Parent = NotificationHost
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = NotificationContainer

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

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
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) })
        tweenIn:Play()
        task.wait(settings.duration or 3)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(-1, -320, 0, 0) })
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Library:create_ui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Fallen"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 100
    ScreenGui.Parent = CoreGui

    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.Size = UDim2.new(0, 500, 0, 600)
    MainContainer.Position = UDim2.new(0.5, -250, 0.5, -300)
    MainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainContainer.BorderSizePixel = 0
    MainContainer.Parent = ScreenGui

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(20, 20, 20)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10, 10, 10))
    }
    MainGradient.Rotation = 45
    MainGradient.Parent = MainContainer

    local MainUICorner = Instance.new("UICorner")
    MainUICorner.CornerRadius = UDim.new(0, 12)
    MainUICorner.Parent = MainContainer

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(100, 100, 100)
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.3
    MainStroke.Parent = MainContainer

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Header.BorderSizePixel = 0
    Header.Parent = MainContainer

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header

    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 50, 50)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(15, 15, 15))
    }
    HeaderGradient.Rotation = 90
    HeaderGradient.Parent = Header

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Text = "FALLEN"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextSize = 20
    Title.Size = UDim2.new(0.6, 0, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.ZIndex = 2
    Title.Parent = Header

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    CloseButton.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    CloseButton.TextSize = 24
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -45, 0.5, -20)
    CloseButton.BackgroundTransparency = 0.8
    CloseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.ZIndex = 2
    CloseButton.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton

    CloseButton.MouseButton1Click:Connect(function()
        if self._removed_callback then self._removed_callback() end
        ScreenGui:Destroy()
    end)

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, 0, 1, -50)
    ContentArea.Position = UDim2.new(0, 0, 0, 50)
    ContentArea.BackgroundTransparency = 1
    ContentArea.BorderSizePixel = 0
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainContainer

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 12)
    ContentPadding.PaddingRight = UDim.new(0, 12)
    ContentPadding.PaddingTop = UDim.new(0, 12)
    ContentPadding.PaddingBottom = UDim.new(0, 12)
    ContentPadding.Parent = ContentArea

    local ContentList = Instance.new("UIListLayout")
    ContentList.FillDirection = Enum.FillDirection.Vertical
    ContentList.SortOrder = Enum.SortOrder.LayoutOrder
    ContentList.Padding = UDim.new(0, 8)
    ContentList.Parent = ContentArea

    -- Dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil

    Header.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = UserInputService:GetMouseLocation()
            startPos = MainContainer.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = UserInputService:GetMouseLocation() - dragStart
            MainContainer.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self._ui = ScreenGui
    self._content = ContentArea
    self._main = MainContainer
end

function Library:create_toggle(config)
    local toggle_container = Instance.new("Frame")
    toggle_container.Name = config.title or "Toggle"
    toggle_container.Size = UDim2.new(1, 0, 0, 36)
    toggle_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle_container.BorderSizePixel = 0
    toggle_container.Parent = self._content

    local toggle_corner = Instance.new("UICorner")
    toggle_corner.CornerRadius = UDim.new(0, 6)
    toggle_corner.Parent = toggle_container

    local toggle_stroke = Instance.new("UIStroke")
    toggle_stroke.Color = Color3.fromRGB(80, 80, 80)
    toggle_stroke.Thickness = 0.5
    toggle_stroke.Transparency = 0.5
    toggle_stroke.Parent = toggle_container

    local toggle_label = Instance.new("TextLabel")
    toggle_label.Text = config.title or "Toggle"
    toggle_label.TextColor3 = Color3.fromRGB(220, 220, 220)
    toggle_label.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    toggle_label.TextSize = 14
    toggle_label.Size = UDim2.new(0.7, 0, 1, 0)
    toggle_label.Position = UDim2.new(0, 12, 0, 0)
    toggle_label.BackgroundTransparency = 1
    toggle_label.TextXAlignment = Enum.TextXAlignment.Left
    toggle_label.TextYAlignment = Enum.TextYAlignment.Center
    toggle_label.Parent = toggle_container

    local toggle_button_bg = Instance.new("Frame")
    toggle_button_bg.Name = "ToggleBg"
    toggle_button_bg.Size = UDim2.new(0, 48, 0, 24)
    toggle_button_bg.Position = UDim2.new(1, -60, 0.5, -12)
    toggle_button_bg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle_button_bg.BorderSizePixel = 0
    toggle_button_bg.Parent = toggle_container

    local toggle_button_corner = Instance.new("UICorner")
    toggle_button_corner.CornerRadius = UDim.new(0, 4)
    toggle_button_corner.Parent = toggle_button_bg

    local toggle_button = Instance.new("Frame")
    toggle_button.Name = "Toggle"
    toggle_button.Size = UDim2.new(0, 20, 0, 20)
    toggle_button.Position = UDim2.new(0, 2, 0.5, -10)
    toggle_button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    toggle_button.BorderSizePixel = 0
    toggle_button.Parent = toggle_button_bg

    local toggle_button_corner2 = Instance.new("UICorner")
    toggle_button_corner2.CornerRadius = UDim.new(0, 2)
    toggle_button_corner2.Parent = toggle_button

    local state = config.default or false

    local function update_toggle()
        if state then
            local tween = TweenService:Create(toggle_button_bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(0, 170, 120) })
            tween:Play()
            local tween2 = TweenService:Create(toggle_button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 26, 0.5, -10) })
            tween2:Play()
        else
            local tween = TweenService:Create(toggle_button_bg, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
            tween:Play()
            local tween2 = TweenService:Create(toggle_button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 2, 0.5, -10) })
            tween2:Play()
        end
    end

    local clickable = Instance.new("TextButton")
    clickable.Text = ""
    clickable.BackgroundTransparency = 1
    clickable.BorderSizePixel = 0
    clickable.Size = UDim2.new(1, 0, 1, 0)
    clickable.Parent = toggle_container

    clickable.MouseButton1Click:Connect(function()
        state = not state
        update_toggle()
        if config.callback then
            pcall(config.callback, state)
        end
    end)

    update_toggle()

    if config.flag then
        self._flag_registry[config.flag] = function(value)
            state = value
            update_toggle()
        end
    end

    return toggle_container
end

function Library:create_button(config)
    local button = Instance.new("TextButton")
    button.Name = config.title or "Button"
    button.Text = config.title or "Button"
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    button.TextSize = 14
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BorderSizePixel = 0
    button.Parent = self._content

    local button_corner = Instance.new("UICorner")
    button_corner.CornerRadius = UDim.new(0, 6)
    button_corner.Parent = button

    local button_stroke = Instance.new("UIStroke")
    button_stroke.Color = Color3.fromRGB(100, 100, 100)
    button_stroke.Thickness = 0.5
    button_stroke.Transparency = 0.5
    button_stroke.Parent = button

    local button_gradient = Instance.new("UIGradient")
    button_gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(25, 25, 25))
    }
    button_gradient.Rotation = 90
    button_gradient.Parent = button

    button.MouseButton1Click:Connect(function()
        if config.callback then
            pcall(config.callback)
        end
    end)

    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(45, 45, 45) })
        tween:Play()
    end)

    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
        tween:Play()
    end)

    return button
end

function Library:create_slider(config)
    local slider_container = Instance.new("Frame")
    slider_container.Name = config.title or "Slider"
    slider_container.Size = UDim2.new(1, 0, 0, 50)
    slider_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    slider_container.BorderSizePixel = 0
    slider_container.Parent = self._content

    local slider_corner = Instance.new("UICorner")
    slider_corner.CornerRadius = UDim.new(0, 6)
    slider_corner.Parent = slider_container

    local slider_stroke = Instance.new("UIStroke")
    slider_stroke.Color = Color3.fromRGB(80, 80, 80)
    slider_stroke.Thickness = 0.5
    slider_stroke.Transparency = 0.5
    slider_stroke.Parent = slider_container

    local slider_label = Instance.new("TextLabel")
    slider_label.Text = config.title or "Slider"
    slider_label.TextColor3 = Color3.fromRGB(220, 220, 220)
    slider_label.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    slider_label.TextSize = 14
    slider_label.Size = UDim2.new(0.6, 0, 0, 20)
    slider_label.Position = UDim2.new(0, 12, 0, 8)
    slider_label.BackgroundTransparency = 1
    slider_label.TextXAlignment = Enum.TextXAlignment.Left
    slider_label.Parent = slider_container

    local slider_value = Instance.new("TextLabel")
    slider_value.Text = tostring(config.default or 50)
    slider_value.TextColor3 = Color3.fromRGB(150, 150, 150)
    slider_value.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    slider_value.TextSize = 12
    slider_value.Size = UDim2.new(0, 50, 0, 20)
    slider_value.Position = UDim2.new(1, -62, 0, 8)
    slider_value.BackgroundTransparency = 1
    slider_value.TextXAlignment = Enum.TextXAlignment.Right
    slider_value.Parent = slider_container

    local slider_bg = Instance.new("Frame")
    slider_bg.Name = "SliderBg"
    slider_bg.Size = UDim2.new(1, -24, 0, 6)
    slider_bg.Position = UDim2.new(0, 12, 0, 32)
    slider_bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    slider_bg.BorderSizePixel = 0
    slider_bg.Parent = slider_container

    local slider_bg_corner = Instance.new("UICorner")
    slider_bg_corner.CornerRadius = UDim.new(0, 3)
    slider_bg_corner.Parent = slider_bg

    local slider_fill = Instance.new("Frame")
    slider_fill.Name = "SliderFill"
    slider_fill.Size = UDim2.new((config.default or 50) / (config.max or 100), 0, 1, 0)
    slider_fill.BackgroundColor3 = Color3.fromRGB(0, 170, 120)
    slider_fill.BorderSizePixel = 0
    slider_fill.Parent = slider_bg

    local slider_fill_corner = Instance.new("UICorner")
    slider_fill_corner.CornerRadius = UDim.new(0, 3)
    slider_fill_corner.Parent = slider_fill

    local slider_fill_gradient = Instance.new("UIGradient")
    slider_fill_gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 200, 150)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 150, 100))
    }
    slider_fill_gradient.Rotation = 90
    slider_fill_gradient.Parent = slider_fill

    local dragging = false

    local function update_slider(mouse_x)
        local slider_pos = slider_bg.AbsolutePosition.X
        local slider_size = slider_bg.AbsoluteSize.X
        local relative = math.clamp(mouse_x - slider_pos, 0, slider_size)
        local percent = relative / slider_size
        local value = math.floor(config.min + (config.max - config.min) * percent + 0.5)

        slider_fill.Size = UDim2.new(percent, 0, 1, 0)
        slider_value.Text = tostring(value)

        if config.callback then
            pcall(config.callback, value)
        end
    end

    slider_bg.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update_slider(UserInputService:GetMouseLocation().X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input, gp)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update_slider(UserInputService:GetMouseLocation().X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return slider_container
end

function Library:create_textbox(config)
    local textbox_container = Instance.new("Frame")
    textbox_container.Name = config.placeholder or "Textbox"
    textbox_container.Size = UDim2.new(1, 0, 0, 36)
    textbox_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    textbox_container.BorderSizePixel = 0
    textbox_container.Parent = self._content

    local textbox_corner = Instance.new("UICorner")
    textbox_corner.CornerRadius = UDim.new(0, 6)
    textbox_corner.Parent = textbox_container

    local textbox_stroke = Instance.new("UIStroke")
    textbox_stroke.Color = Color3.fromRGB(80, 80, 80)
    textbox_stroke.Thickness = 0.5
    textbox_stroke.Transparency = 0.5
    textbox_stroke.Parent = textbox_container

    local textbox = Instance.new("TextBox")
    textbox.Name = "Input"
    textbox.PlaceholderText = config.placeholder or "Enter text..."
    textbox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textbox.Text = config.value or ""
    textbox.TextColor3 = Color3.fromRGB(220, 220, 220)
    textbox.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    textbox.TextSize = 14
    textbox.Size = UDim2.new(1, -24, 1, 0)
    textbox.Position = UDim2.new(0, 12, 0, 0)
    textbox.BackgroundTransparency = 1
    textbox.BorderSizePixel = 0
    textbox.ClearTextOnFocus = false
    textbox.Parent = textbox_container

    textbox.Changed:Connect(function(property)
        if property == "Text" and config.callback then
            pcall(config.callback, textbox.Text)
        end
    end)

    return textbox_container
end

function Library:create_dropdown(config)
    local dropdown_container = Instance.new("Frame")
    dropdown_container.Name = config.title or "Dropdown"
    dropdown_container.Size = UDim2.new(1, 0, 0, 36)
    dropdown_container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    dropdown_container.BorderSizePixel = 0
    dropdown_container.Parent = self._content

    local dropdown_corner = Instance.new("UICorner")
    dropdown_corner.CornerRadius = UDim.new(0, 6)
    dropdown_corner.Parent = dropdown_container

    local dropdown_stroke = Instance.new("UIStroke")
    dropdown_stroke.Color = Color3.fromRGB(80, 80, 80)
    dropdown_stroke.Thickness = 0.5
    dropdown_stroke.Transparency = 0.5
    dropdown_stroke.Parent = dropdown_container

    local dropdown_label = Instance.new("TextLabel")
    dropdown_label.Name = "Label"
    dropdown_label.Text = config.options and config.options[1] or "Select..."
    dropdown_label.TextColor3 = Color3.fromRGB(220, 220, 220)
    dropdown_label.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    dropdown_label.TextSize = 14
    dropdown_label.Size = UDim2.new(0.8, 0, 1, 0)
    dropdown_label.Position = UDim2.new(0, 12, 0, 0)
    dropdown_label.BackgroundTransparency = 1
    dropdown_label.TextXAlignment = Enum.TextXAlignment.Left
    dropdown_label.Parent = dropdown_container

    local dropdown_button = Instance.new("TextButton")
    dropdown_button.Text = "▼"
    dropdown_button.TextColor3 = Color3.fromRGB(150, 150, 150)
    dropdown_button.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    dropdown_button.TextSize = 12
    dropdown_button.Size = UDim2.new(0, 30, 0, 30)
    dropdown_button.Position = UDim2.new(1, -40, 0.5, -15)
    dropdown_button.BackgroundTransparency = 1
    dropdown_button.BorderSizePixel = 0
    dropdown_button.Parent = dropdown_container

    local menu_open = false
    local menu = nil

    local function close_menu()
        if menu then
            menu:Destroy()
            menu = nil
        end
        menu_open = false
    end

    local function open_menu()
        if menu_open then
            close_menu()
            return
        end

        menu_open = true
        menu = Instance.new("Frame")
        menu.Name = "DropdownMenu"
        menu.Size = UDim2.new(1, 0, 0, math.min(#(config.options or {}), config.maximum_options or 5) * 32 + 8)
        menu.Position = UDim2.new(0, 0, 1, 4)
        menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        menu.BorderSizePixel = 0
        menu.Parent = dropdown_container

        local menu_corner = Instance.new("UICorner")
        menu_corner.CornerRadius = UDim.new(0, 6)
        menu_corner.Parent = menu

        local menu_stroke = Instance.new("UIStroke")
        menu_stroke.Color = Color3.fromRGB(80, 80, 80)
        menu_stroke.Thickness = 0.5
        menu_stroke.Transparency = 0.5
        menu_stroke.Parent = menu

        local menu_list = Instance.new("UIListLayout")
        menu_list.FillDirection = Enum.FillDirection.Vertical
        menu_list.SortOrder = Enum.SortOrder.LayoutOrder
        menu_list.Padding = UDim.new(0, 2)
        menu_list.Parent = menu

        local menu_padding = Instance.new("UIPadding")
        menu_padding.PaddingLeft = UDim.new(0, 4)
        menu_padding.PaddingRight = UDim.new(0, 4)
        menu_padding.PaddingTop = UDim.new(0, 4)
        menu_padding.PaddingBottom = UDim.new(0, 4)
        menu_padding.Parent = menu

        for _, option in ipairs(config.options or {}) do
            local menu_item = Instance.new("TextButton")
            menu_item.Text = option
            menu_item.TextColor3 = Color3.fromRGB(180, 180, 180)
            menu_item.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            menu_item.TextSize = 13
            menu_item.Size = UDim2.new(1, 0, 0, 28)
            menu_item.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            menu_item.BorderSizePixel = 0
            menu_item.Parent = menu

            local menu_item_corner = Instance.new("UICorner")
            menu_item_corner.CornerRadius = UDim.new(0, 4)
            menu_item_corner.Parent = menu_item

            menu_item.MouseButton1Click:Connect(function()
                dropdown_label.Text = option
                close_menu()
                if config.callback then
                    pcall(config.callback, option)
                end
            end)

            menu_item.MouseEnter:Connect(function()
                local tween = TweenService:Create(menu_item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(45, 45, 45) })
                tween:Play()
            end)

            menu_item.MouseLeave:Connect(function()
                local tween = TweenService:Create(menu_item, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
                tween:Play()
            end)
        end
    end

    dropdown_button.MouseButton1Click:Connect(open_menu)
    dropdown_label.Parent.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            open_menu()
        end
    end)

    return dropdown_container
end

function Library:removed(callback)
    self._removed_callback = callback
end

return Library

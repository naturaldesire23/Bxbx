-- ============================================================
-- AZURE UI LIBRARY (Full UI from your 18k script)
-- ============================================================
print("[UI] Loading Azure UI Library...")

local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local Debris = game:GetService('Debris')
local HttpService = game:GetService('HttpService')
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONNECTIONS MANAGER
-- ============================================================
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
}, {__index = {}})

-- ============================================================
-- UI LIBRARY
-- ============================================================
local Library = {
    _config = {},
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _notification_root = nil,
    _notification_holder = nil,
    _notification_active = {},
    _notification_helpers = {},
    _tab = 0,
    _firstTab = false,
}
Library.__index = Library

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
function Library:create_notification_root()
    if self._notification_root then return self._notification_root end

    local notification_root = Instance.new('ScreenGui')
    notification_root.Name = "AzureNotificationRoot"
    notification_root.ResetOnSpawn = false
    notification_root.IgnoreGuiInset = true
    notification_root.Parent = CoreGui

    local holder = Instance.new('Frame')
    holder.Name = "ToastHolder"
    holder.AnchorPoint = Vector2.new(0.5, 0)
    holder.Position = UDim2.new(0.5, 0, 0, 14)
    holder.Size = UDim2.new(0.82, 0, 1, -28)
    holder.BackgroundTransparency = 1
    holder.Parent = notification_root

    local size_constraint = Instance.new('UISizeConstraint', holder)
    size_constraint.MaxSize = Vector2.new(390, math.huge)

    local list_layout = Instance.new('UIListLayout', holder)
    list_layout.FillDirection = Enum.FillDirection.Vertical
    list_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list_layout.VerticalAlignment = Enum.VerticalAlignment.Top
    list_layout.Padding = UDim.new(0, 8)
    list_layout.SortOrder = Enum.SortOrder.LayoutOrder

    self._notification_root = notification_root
    self._notification_holder = holder
    self._notification_active = {}
    return notification_root
end

function Library:notify(settings)
    settings = settings or {}
    local root = self:create_notification_root()
    if not root then return end

    if #self._notification_active >= 3 and self._notification_active[1] then
        pcall(function()
            if self._notification_active[1].Parent then
                self._notification_active[1]:Destroy()
            end
            table.remove(self._notification_active, 1)
        end)
    end

    local card = Instance.new('Frame')
    card.Name = 'Toast'
    card.Size = UDim2.new(1, 0, 0, 50)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    card.BackgroundTransparency = 0.02
    card.BorderSizePixel = 0
    card.Position = UDim2.new(0, 0, 0, -10)
    card.Parent = self._notification_holder
    
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card

    local stroke = Instance.new('UIStroke')
    stroke.Color = Color3.fromRGB(80, 50, 180)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = card

    local icon = Instance.new('Frame')
    icon.Size = UDim2.new(0, 8, 0, 8)
    icon.Position = UDim2.new(0, 12, 0.5, -4)
    icon.BackgroundColor3 = Color3.fromRGB(80, 50, 180)
    icon.BorderSizePixel = 0
    icon.Parent = card
    local iconCorner = Instance.new('UICorner')
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local text = Instance.new('TextLabel')
    text.BackgroundTransparency = 1
    text.Size = UDim2.new(1, -30, 1, 0)
    text.Position = UDim2.new(0, 28, 0, 0)
    text.Text = settings.Title or "Notification"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 14
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = card

    if settings.Description then
        card.Size = UDim2.new(1, 0, 0, 70)
        text.Size = UDim2.new(1, -30, 0, 20)
        text.TextYAlignment = Enum.TextYAlignment.Top
        
        local desc = Instance.new('TextLabel')
        desc.BackgroundTransparency = 1
        desc.Size = UDim2.new(1, -30, 0, 20)
        desc.Position = UDim2.new(0, 28, 0, 25)
        desc.Text = settings.Description
        desc.TextColor3 = Color3.fromRGB(180, 180, 200)
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.Parent = card
    end

    table.insert(self._notification_active, card)

    task.delay(settings.Lifetime or 3, function()
        if card and card.Parent then
            card:Destroy()
            for i, v in ipairs(self._notification_active) do
                if v == card then
                    table.remove(self._notification_active, i)
                    break
                end
            end
        end
    end)
end

function Library.SendNotification(settings)
    if Library and Library.notify then
        return Library:notify(settings)
    end
end

-- ============================================================
-- MAIN UI CREATION
-- ============================================================
function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)

    self:create_notification_root()
    self:create_ui()

    return self
end

function Library:create_ui()
    local old_Azure = CoreGui:FindFirstChild('Azure')
    if old_Azure then Debris:AddItem(old_Azure, 0) end

    local AzureUI = Instance.new('ScreenGui')
    AzureUI.ResetOnSpawn = false
    AzureUI.Name = 'Azure'
    AzureUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    AzureUI.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = "Container"
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.ZIndex = 2
    Container.Parent = AzureUI

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(30, 30, 40)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(15, 15, 20)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10, 10, 15))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(60, 60, 80)
    UIStroke.Thickness = 1
    UIStroke.Transparency = 0.28
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.Size = UDim2.new(0, 600, 0, 450)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Parent = Container

    -- Tabs
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 120, 0, 380)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.02, 0, 0.08, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local TabListLayout = Instance.new('UIListLayout')
    TabListLayout.Padding = UDim.new(0, 4)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Parent = Tabs

    -- Title
    local titleText = Instance.new('TextLabel')
    titleText.Font = Enum.Font.GothamBold
    titleText.TextColor3 = Color3.fromRGB(200, 150, 255)
    titleText.Text = 'Azure'
    titleText.Name = "Title"
    titleText.Size = UDim2.new(0, 80, 0, 25)
    titleText.AnchorPoint = Vector2.new(0, 0.5)
    titleText.Position = UDim2.new(0.04, 0, 0.035, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.BorderSizePixel = 0
    titleText.TextSize = 22
    titleText.Parent = Handler

    -- Subtitle
    local subtitleText = Instance.new('TextLabel')
    subtitleText.Font = Enum.Font.Gotham
    subtitleText.TextColor3 = Color3.fromRGB(150, 150, 180)
    subtitleText.Text = 'Script Hub'
    subtitleText.Name = "Subtitle"
    subtitleText.Size = UDim2.new(0, 80, 0, 16)
    subtitleText.AnchorPoint = Vector2.new(0, 0.5)
    subtitleText.Position = UDim2.new(0.04, 0, 0.07, 0)
    subtitleText.BackgroundTransparency = 1
    subtitleText.TextXAlignment = Enum.TextXAlignment.Left
    subtitleText.BorderSizePixel = 0
    subtitleText.TextSize = 12
    subtitleText.Parent = Handler

    -- Divider line
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.03, 0, 0.095, 0)
    Divider.Size = UDim2.new(0.94, 0, 1, 0)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    Divider.Parent = Handler

    -- Sections container
    local Sections = Instance.new('Folder')
    Sections.Name = "Sections"
    Sections.Parent = Handler

    -- Minimize button
    local Minimize = Instance.new('TextButton')
    Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = "Minimize"
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.92, 0, 0.025, 0)
    Minimize.Size = UDim2.new(0, 30, 0, 30)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 20
    Minimize.Parent = Handler

    local minIcon = Instance.new('TextLabel')
    minIcon.Text = '−'
    minIcon.Size = UDim2.new(1, 0, 1, 0)
    minIcon.BackgroundTransparency = 1
    minIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    minIcon.Font = Enum.Font.GothamBold
    minIcon.TextSize = 20
    minIcon.TextXAlignment = Enum.TextXAlignment.Center
    minIcon.Parent = Minimize

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    self._ui = AzureUI

    -- Dragging
    local dragging = false
    local dragStart, startPosition

    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = Container.Position
            local changedConnection
            changedConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConnection then changedConnection:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Container.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)

    function self:change_visiblity(state)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(620, 460)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(100, 30)
            }):Play()
        end
    end

    function self:load()
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(620, 460)
        }):Play()
        self._ui_loaded = true
    end

    function self:create_tab(title)
        local TabManager = {}

        local Tab = Instance.new('TextButton')
        Tab.TextColor3 = Color3.fromRGB(150, 150, 170)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 100, 0, 35)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Tab

        local Icon = Instance.new('ImageLabel')
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.Position = UDim2.new(0.08, 0, 0.5, -8)
        Icon.BackgroundTransparency = 1
        Icon.Image = "rbxassetid://95259225424429"
        Icon.ImageColor3 = Color3.fromRGB(150, 150, 170)
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
        TextLabel.TextTransparency = 0.3
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, 70, 0, 20)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.28, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.TextSize = 14
        TextLabel.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = "LeftSection"
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 280, 0, 380)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.24, 0, 0.52, 0)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections

        local LeftLayout = Instance.new('UIListLayout')
        LeftLayout.Padding = UDim.new(0, 8)
        LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = "RightSection"
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 280, 0, 380)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(1, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.76, 0, 0.52, 0)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local RightLayout = Instance.new('UIListLayout')
        RightLayout.Padding = UDim.new(0, 8)
        RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightSection

        self._tab = self._tab + 1

        if not self._firstTab then
            self._firstTab = true
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        -- ============================================================
        -- MODULE CREATION FUNCTIONS
        -- ============================================================
        function TabManager:create_module(settings)
            local ModuleManager = {}

            local section = settings.section == "right" and RightSection or LeftSection

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BackgroundTransparency = 0.02
            Module.Size = UDim2.new(0, 260, 0, 65)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            Module.Parent = section

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 8)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(60, 60, 80)
            UIStroke.Transparency = 0.5
            UIStroke.Thickness = 1
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module

            local Header = Instance.new('TextButton')
            Header.TextColor3 = Color3.fromRGB(200, 200, 220)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 260, 0, 65)
            Header.BorderSizePixel = 0
            Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Header.Parent = Module

            local ModuleName = Instance.new('TextLabel')
            ModuleName.TextColor3 = Color3.fromRGB(220, 220, 240)
            ModuleName.TextTransparency = 0.2
            ModuleName.Text = settings.title or "Module"
            ModuleName.Name = "ModuleName"
            ModuleName.Size = UDim2.new(0, 200, 0, 20)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.05, 0, 0.3, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.TextSize = 14
            ModuleName.Parent = Header

            local Description = Instance.new('TextLabel')
            Description.TextColor3 = Color3.fromRGB(150, 150, 170)
            Description.TextTransparency = 0.5
            Description.Text = settings.description or ""
            Description.Name = "Description"
            Description.Size = UDim2.new(0, 200, 0, 16)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.P

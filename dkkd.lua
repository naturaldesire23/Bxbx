-- ============================================================
-- AZURE UI LIBRARY (100% Clean - No cloneref)
-- ============================================================
print("[UI] Loading Azure UI Library...")

-- ============================================================
-- SERVICES
-- ============================================================
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local Debris = game:GetService('Debris')
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CREATE UI FUNCTION
-- ============================================================
local function CreateAzureUI()
    print("[UI] Creating UI...")
    
    -- Clean old UI
    local oldUI = CoreGui:FindFirstChild("Azure")
    if oldUI then oldUI:Destroy() end
    
    local oldNotifs = CoreGui:FindFirstChild("AzureNotificationRoot")
    if oldNotifs then oldNotifs:Destroy() end
    
    -- Main ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "Azure"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = CoreGui
    print("[UI] ScreenGui created")
    
    -- Container
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    Container.BackgroundTransparency = 0.05
    Container.ClipsDescendants = true
    Container.Active = true
    Container.Parent = sg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = Container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 50, 180)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = Container
    
    -- Main Handler
    local Handler = Instance.new("Frame")
    Handler.Name = "Handler"
    Handler.Size = UDim2.new(0, 600, 0, 460)
    Handler.BackgroundTransparency = 1
    Handler.Parent = Container
    
    -- Left Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, 0)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
    Sidebar.BackgroundTransparency = 0.5
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = Handler
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Azure"
    Title.TextColor3 = Color3.fromRGB(200, 150, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 22
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Sidebar
    
    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(1, -20, 0, 16)
    Subtitle.Position = UDim2.new(0, 10, 0, 38)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Script Hub"
    Subtitle.TextColor3 = Color3.fromRGB(150, 150, 180)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 12
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Sidebar
    
    -- Divider
    local Divider = Instance.new("Frame")
    Divider.Name = "Divider"
    Divider.Size = UDim2.new(0.8, 0, 0, 1)
    Divider.Position = UDim2.new(0.1, 0, 0.12, 0)
    Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    Divider.BackgroundTransparency = 0.5
    Divider.BorderSizePixel = 0
    Divider.Parent = Sidebar
    
    -- Tabs container
    local TabsContainer = Instance.new("ScrollingFrame")
    TabsContainer.Name = "Tabs"
    TabsContainer.Size = UDim2.new(1, 0, 1, -90)
    TabsContainer.Position = UDim2.new(0, 0, 0, 90)
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.BorderSizePixel = 0
    TabsContainer.ScrollBarThickness = 0
    TabsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabsContainer.Parent = Sidebar
    
    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.Padding = UDim.new(0, 4)
    TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabsLayout.Parent = TabsContainer
    
    -- Main content area
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -130, 1, 0)
    Content.Position = UDim2.new(130, 0, 0, 0)
    Content.BackgroundTransparency = 1
    Content.Parent = Handler
    
    -- Sections container
    local Sections = Instance.new("Folder")
    Sections.Name = "Sections"
    Sections.Parent = Content
    
    -- Minimize button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "Minimize"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -40, 0, 8)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Handler
    
    -- State
    local uiOpen = true
    local tabs = {}
    local currentTab = nil
    
    -- ============================================================
    -- UI FUNCTIONS
    -- ============================================================
    local function Animate(object, properties, duration)
        duration = duration or 0.3
        local tween = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
        tween:Play()
        return tween
    end
    
    local function ChangeVisibility(state)
        uiOpen = state
        if state then
            Animate(Container, {Size = UDim2.fromOffset(620, 460)})
        else
            Animate(Container, {Size = UDim2.fromOffset(100, 30)})
        end
    end
    
    local function UpdateTabs(activeTab)
        for _, tab in pairs(tabs) do
            if tab.Button == activeTab then
                Animate(tab.Button, {BackgroundTransparency = 0.85, BackgroundColor3 = Color3.fromRGB(60, 40, 120)})
                tab.Button.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                tab.Button.TextLabel.TextTransparency = 0
            else
                Animate(tab.Button, {BackgroundTransparency = 1})
                tab.Button.TextLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
                tab.Button.TextLabel.TextTransparency = 0.3
            end
        end
    end
    
    local function UpdateSections(leftSection, rightSection)
        for _, child in pairs(Sections:GetChildren()) do
            child.Visible = (child == leftSection or child == rightSection)
        end
    end
    
    -- Dragging
    local dragging = false
    local dragStart, startPos
    
    Container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Container.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    MinBtn.MouseButton1Click:Connect(function()
        ChangeVisibility(not uiOpen)
    end)
    
    -- ============================================================
    -- PUBLIC API
    -- ============================================================
    local API = {}
    
    function API:Notify(settings)
        settings = settings or {}
        local notifGui = CoreGui:FindFirstChild("AzureNotificationRoot")
        if not notifGui then
            notifGui = Instance.new("ScreenGui")
            notifGui.Name = "AzureNotificationRoot"
            notifGui.ResetOnSpawn = false
            notifGui.IgnoreGuiInset = true
            notifGui.Parent = CoreGui
        end
        
        local holder = notifGui:FindFirstChild("ToastHolder")
        if not holder then
            holder = Instance.new("Frame")
            holder.Name = "ToastHolder"
            holder.AnchorPoint = Vector2.new(0.5, 0)
            holder.Position = UDim2.new(0.5, 0, 0, 14)
            holder.Size = UDim2.new(0.82, 0, 1, -28)
            holder.BackgroundTransparency = 1
            holder.Parent = notifGui
            
            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Top
            layout.Padding = UDim.new(0, 8)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = holder
        end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 50)
        card.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
        card.BackgroundTransparency = 0.05
        card.BorderSizePixel = 0
        card.Parent = holder
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card
        
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(80, 50, 180)
        cardStroke.Transparency = 0.4
        cardStroke.Thickness = 1
        cardStroke.Parent = card
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -20, 1, 0)
        text.Position = UDim2.new(0, 10, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = settings.Title or "Notification"
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 14
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.Parent = card
        
        if settings.Description then
            card.Size = UDim2.new(1, 0, 0, 70)
            text.Size = UDim2.new(1, -20, 0, 22)
            text.TextYAlignment = Enum.TextYAlignment.Top
            
            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(1, -20, 0, 22)
            desc.Position = UDim2.new(0, 10, 0, 26)
            desc.BackgroundTransparency = 1
            desc.Text = settings.Description
            desc.TextColor3 = Color3.fromRGB(180, 180, 200)
            desc.Font = Enum.Font.Gotham
            desc.TextSize = 12
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = card
        end
        
        -- Auto dismiss
        task.delay(settings.Lifetime or 3, function()
            if card then card:Destroy() end
        end)
    end
    
    function API:CreateTab(name)
        local tabData = {}
        
        local button = Instance.new("TextButton")
        button.Name = "Tab_" .. name
        button.Size = UDim2.new(0, 100, 0, 35)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = TabsContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = button
        
        local label = Instance.new("TextLabel")
        label.Name = "TextLabel"
        label.Size = UDim2.new(1, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(200, 200, 220)
        label.TextTransparency = 0.3
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = button
        
        tabData.Button = button
        tabData.Name = name
        
        -- Create sections
        local leftSection = Instance.new("ScrollingFrame")
        leftSection.Name = "LeftSection"
        leftSection.Size = UDim2.new(0, 280, 1, -10)
        leftSection.Position = UDim2.new(0.02, 0, 0, 5)
        leftSection.BackgroundTransparency = 1
        leftSection.BorderSizePixel = 0
        leftSection.ScrollBarThickness = 0
        leftSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
        leftSection.Visible = false
        leftSection.Parent = Sections
        
        local leftLayout = Instance.new("UIListLayout")
        leftLayout.Padding = UDim.new(0, 8)
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Parent = leftSection
        
        local rightSection = Instance.new("ScrollingFrame")
        rightSection.Name = "RightSection"
        rightSection.Size = UDim2.new(0, 280, 1, -10)
        rightSection.Position = UDim2.new(1, -282, 0, 5)
        rightSection.BackgroundTransparency = 1
        rightSection.BorderSizePixel = 0
        rightSection.ScrollBarThickness = 0
        rightSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
        rightSection.Visible = false
        rightSection.Parent = Sections
        
        local rightLayout = Instance.new("UIListLayout")
        rightLayout.Padding = UDim.new(0, 8)
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Parent = rightSection
        
        tabData.LeftSection = leftSection
        tabData.RightSection = rightSection
        
        if not currentTab then
            currentTab = button
            UpdateTabs(button)
            UpdateSections(leftSection, rightSection)
        end
        
        button.MouseButton1Click:Connect(function()
            currentTab = button
            UpdateTabs(button)
            UpdateSections(leftSection, rightSection)
        end)
        
        tabs[#tabs + 1] = tabData
        
        -- ============================================================
        -- MODULE CREATION
        -- ============================================================
        local moduleAPI = {}
        
        function moduleAPI:CreateModule(settings)
            local section = settings.section == "right" and rightSection or leftSection
            
            local module = Instance.new("Frame")
            module.Size = UDim2.new(0, 260, 0, 65)
            module.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            module.BackgroundTransparency = 0.05
            module.BorderSizePixel = 0
            module.ClipsDescendants = true
            module.Parent = section
            
            local modCorner = Instance.new("UICorner")
            modCorner.CornerRadius = UDim.new(0, 8)
            modCorner.Parent = module
            
            local modStroke = Instance.new("UIStroke")
            modStroke.Color = Color3.fromRGB(60, 60, 80)
            modStroke.Transparency = 0.5
            modStroke.Thickness = 1
            modStroke.Parent = module
            
            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 1, 0)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.Parent = module
            
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(0, 200, 0, 20)
            titleLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = settings.title or "Module"
            titleLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
            titleLabel.TextTransparency = 0.2
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 14
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = header
            
            local descLabel = Instance.new("TextLabel")
            descLabel.Size = UDim2.new(0, 200, 0, 16)
            descLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
            descLabel.BackgroundTransparency = 1
            descLabel.Text = settings.description or ""
            descLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            descLabel.TextTransparency = 0.5
            descLabel.Font = Enum.Font.Gotham
            descLabel.TextSize = 11
            descLabel.TextXAlignment = Enum.TextXAlignment.Left
            descLabel.Parent = header
            
            local toggle = Instance.new("Frame")
            toggle.Size = UDim2.new(0, 40, 0, 24)
            toggle.Position = UDim2.new(0.82, 0, 0.5, -12)
            toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            toggle.BackgroundTransparency = 0.7
            toggle.BorderSizePixel = 0
            toggle.Parent = header
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(1, 0)
            toggleCorner.Parent = toggle
            
            local circle = Instance.new("Frame")
            circle.Size = UDim2.new(0, 18, 0, 18)
            circle.Position = UDim2.new(0, 0, 0.5, -9)
            circle.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
            circle.BackgroundTransparency = 0.2
            circle.BorderSizePixel = 0
            circle.Parent = toggle
            
            local circleCorner = Instance.new("UICorner")
            circleCorner.CornerRadius = UDim.new(1, 0)
            circleCorner.Parent = circle
            
            local state = false
            
            local function Toggle()
                state = not state
                if state then
                    Animate(toggle, {BackgroundColor3 = Color3.fromRGB(80, 50, 180)})
                    Animate(circle, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.fromScale(0.53, 0.5)})
                else
                    Animate(toggle, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)})
                    Animate(circle, {BackgroundColor3 = Color3.fromRGB(100, 100, 120), Position = UDim2.fromScale(0, 0.5)})
                end
                if settings.callback then settings.callback(state) end
            end
            
            header.MouseButton1Click:Connect(Toggle)
            
            local moduleAPI2 = {}
            
            function moduleAPI2:CreateButton(btnSettings)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0, 240, 0, 30)
                btn.Position = UDim2.new(0, 10, 0, 72)
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
                btn.Text = btnSettings.title or "Button"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 13
                btn.Parent = module
                
                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn
                
                btn.MouseButton1Click:Connect(function()
                    if btnSettings.callback then btnSettings.callback() end
                end)
                
                return btn
            end
            
            function moduleAPI2:CreateSlider(sliderSettings)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 240, 0, 50)
                frame.Position = UDim2.new(0, 10, 0, 70)
                frame.BackgroundTransparency = 1
                frame.Parent = module
            

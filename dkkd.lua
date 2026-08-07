-- Merged & Optimized UI Library
-- Features: 50% Transparency, Glass Blur, Custom Assets, Gradient Accents, Backward Compatible

local Library = {}
do
    -- Services
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local Lighting = game:GetService("Lighting")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera

    -- Exact Theme Configuration from Script 3
    Library.Theme = {
        Accent = Color3.fromRGB(0, 116, 224),
        AccentGradient = Color3.fromRGB(0, 195, 255),
        Background = Color3.fromRGB(12, 12, 14),
        Background2 = Color3.fromRGB(10, 10, 12),
        Sidebar = Color3.fromRGB(15, 15, 18),
        Element = Color3.fromRGB(16, 16, 18),
        SectionTop = Color3.fromRGB(28, 27, 31),
        Text = Color3.fromRGB(235, 235, 235),
        Outline = Color3.fromRGB(25, 25, 28),
        Transparency = 0.2 -- Sleeker transparency to match the gradient style
    }

    -- Image Assets from Script 3
    Library.Assets = {
        Logo = "rbxassetid://120959262762131",
        Checkmark = "rbxassetid://121760666525660",
        SliderKnob = "rbxassetid://117786983271442",
        DropdownArrow = "rbxassetid://123317177279443",
        SettingsIcon = "rbxassetid://122669828593160",
        CloseIcon = "rbxassetid://130510492706892"
    }

    Library.Flags = {}
    Library.Connections = {}

    -- Helper: Create Instance
    function Library:Create(Class, Props)
        local Inst = Instance.new(Class)
        for K, V in pairs(Props) do
            Inst[K] = V
        end
        return Inst
    end

    -- Helper: Apply Accent Gradient
    function Library:ApplyAccentGradient(Obj)
        return self:Create("UIGradient", {
            Parent = Obj,
            Rotation = -115,
            Color = ColorSequence.new(self.Theme.Accent, self.Theme.AccentGradient)
        })
    end

    -- Helper: Tween
    function Library:Tween(Obj, Time, Props)
        local T = TweenService:Create(Obj, TweenInfo.new(Time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Props)
        T:Play()
        return T
    end

    -- Helper: Connect
    function Library:Connect(Signal, Callback)
        local C = Signal:Connect(Callback)
        table.insert(self.Connections, C)
        return C
    end

    -- Blur Effect
    function Library:Blurify(Frame, Strength)
        local Part = self:Create("Part", {
            Material = Enum.Material.Glass,
            Transparency = 1,
            Reflectance = 1,
            CastShadow = false,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            Size = Vector3.new(1, 1, 1) * 0.01,
            Color = Color3.fromRGB(0,0,0),
            Parent = Camera,
        })
        local BlockMesh = self:Create("BlockMesh", {Parent = Part})
        
        self:Connect(RunService.RenderStepped, function()
            if not Frame.Parent then Part:Destroy() return end
            if Frame.Visible then
                Part.Transparency = Strength or 0.97
                local C0 = Frame.AbsolutePosition
                local C1 = C0 + Frame.AbsoluteSize
                local R0 = Camera:ScreenPointToRay(C0.X, C0.Y, 1)
                local R1 = Camera:ScreenPointToRay(C1.X, C1.Y, 1)
                local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ)
                local Normal = Camera.CFrame.LookVector

                local function CalcPos(Position, Normal, Origin, Direction)
                    local V = Origin - Position
                    local Num = (Normal.X * V.X) + (Normal.Y * V.Y) + (Normal.Z * V.Z)
                    local Den = (Normal.X * Direction.X) + (Normal.Y * Direction.Y) + (Normal.Z * Direction.Z)
                    local A = -Num / Den
                    return Origin + (A * Direction)
                end

                local Pos0 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R0.Origin, R0.Direction))
                local Pos1 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R1.Origin, R1.Direction))
                local Size = Pos1 - Pos0
                local Center = (Pos0 + Pos1) / 2

                BlockMesh.Offset = Center
                BlockMesh.Scale = Size / 0.0101
                Part.CFrame = Camera.CFrame
            else
                Part.Transparency = 1
            end
        end)
    end

    -- Main GUI Holder
    Library.Gui = Library:Create("ScreenGui", {
        Name = "MergedUI",
        Parent = gethui and gethui() or CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    -- Make Frame Draggable
    function Library:Draggable(Frame)
        local Dragging, DragInput, DragStart, StartPos
        Frame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = Input.Position
                StartPos = Frame.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
                end)
            end
        end)
        Frame.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        self:Connect(UserInputService.InputChanged, function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - DragStart
                self:Tween(Frame, 0.1, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)})
            end
        end)
    end

    -- Notifications System
    local NotifGui = Library:Create("ScreenGui", {
        Name = "MergedNotifs",
        Parent = gethui and gethui() or CoreGui,
        ResetOnSpawn = false
    })
    local NotifHolder = Library:Create("Frame", {
        Parent = NotifGui,
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundTransparency = 1
    })
    Library:Create("UIListLayout", {Parent = NotifHolder, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right})

    function Library:Notify(Title, Desc, Duration)
        Duration = Duration or 5
        local Notif = Library:Create("Frame", {
            Parent = NotifHolder,
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = Library.Theme.Transparency,
            BorderSizePixel = 0
        })
        Library:Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)})
        local NotifStroke = Library:Create("UIStroke", {Parent = Notif, Color = Library.Theme.Accent, Transparency = 0.5})
        Library:ApplyAccentGradient(NotifStroke)

        Library:Create("TextLabel", {
            Parent = Notif,
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = Title,
            TextColor3 = Library.Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Create("TextLabel", {
            Parent = Notif,
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 28),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = Desc,
            TextColor3 = Library.Theme.Text,
            TextTransparency = 0.3,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        Notif.Size = UDim2.new(0, 0, 0, 60)
        Notif.Position = UDim2.new(1, 0, 0, 0)
        Library:Tween(Notif, 0.4, {Size = UDim2.new(1, 0, 0, 60)})

        task.delay(Duration, function()
            Library:Tween(Notif, 0.4, {Size = UDim2.new(0, 0, 0, 60)})
            task.wait(0.4)
            Notif:Destroy()
        end)
    end

    -- Window Creation
    function Library:Window(Data)
        local Window = {}
        Window.Tabs = {}

        local Main = Library:Create("Frame", {
            Parent = self.Gui,
            Size = UDim2.new(0, 650, 0, 450),
            Position = UDim2.new(0.5, -325, 0.5, -225),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = Library.Theme.Transparency,
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true
        })
        Library:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
        Library:Blurify(Main, 0.95)
        Library:Draggable(Main)

        local TopBar = Library:Create("Frame", {
            Parent = Main,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = Library.Theme.Background2,
            BackgroundTransparency = Library.Theme.Transparency,
            BorderSizePixel = 0
        })
        local TopLine = Library:Create("Frame", {
            Parent = TopBar,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        })
        Library:ApplyAccentGradient(TopLine)

        -- Custom Logo
        Library:Create("ImageLabel", {
            Parent = TopBar,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 10, 0.5, -12),
            BackgroundTransparency = 1,
            Image = Library.Assets.Logo
        })

        Library:Create("TextLabel", {
            Parent = TopBar,
            Size = UDim2.new(1, -150, 1, 0),
            Position = UDim2.new(0, 42, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = Data.Title or "Merged UI",
            TextColor3 = Library.Theme.Text,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        -- Close Button
        local CloseBtn = Library:Create("TextButton", {
            Parent = TopBar,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -34, 0.5, -14),
            BackgroundColor3 = Library.Theme.Element,
            BackgroundTransparency = 0.5,
            Text = "",
            AutoButtonColor = false,
            BorderSizePixel = 0
        })
        Library:Create("UICorner", {Parent = CloseBtn, CornerRadius = UDim.new(0, 6)})
        Library:Create("ImageLabel", {
            Parent = CloseBtn,
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0.5, -6, 0.5, -6),
            BackgroundTransparency = 1,
            Image = Library.Assets.CloseIcon,
            ImageColor3 = Library.Theme.Text
        })
        CloseBtn.MouseButton1Click:Connect(function()
            Library:Tween(Main, 0.3, {Size = UDim2.new(0, 650, 0, 0)}):
            wait(0.3)
            Main.Visible = false
        end)

        local SideBar = Library:Create("Frame", {
            Parent = Main,
            Size = UDim2.new(0, 150, 1, -40),
            Position = UDim2.new(0, 0, 0, 40),
            BackgroundColor3 = Library.Theme.Sidebar,
            BackgroundTransparency = Library.Theme.Transparency,
            BorderSizePixel = 0
        })
        local TabList = Library:Create("UIListLayout", {Parent = SideBar, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
        Library:Create("UIPadding", {Parent = SideBar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

        local ContentArea = Library:Create("Frame", {
            Parent = Main,
            Size = UDim2.new(1, -150, 1, -40),
            Position = UDim2.new(0, 150, 0, 40),
            BackgroundTransparency = 1
        })

        function Window:Show()
            Main.Visible = true
            Main.Size = UDim2.new(0, 650, 0, 0)
            Library:Tween(Main, 0.5, {Size = UDim2.new(0, 650, 0, 450)})
        end

        function Window:Tab(TabData)
            local Tab = {}
            
            local TabBtn = Library:Create("TextButton", {
                Parent = SideBar,
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundColor3 = Library.Theme.Element,
                BackgroundTransparency = 0.5,
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0
            })
            Library:Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
            Library:Create("TextLabel", {
                Parent = TabBtn,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = TabData.Name or "Tab",
                TextColor3 = Library.Theme.Text,
                TextSize = 14
            })

            local Page = Library:Create("ScrollingFrame", {
                Parent = ContentArea,
                Size = UDim2.new(1, -20, 1, -20),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = Library.Theme.Accent,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false
            })
            Library:Create("UIListLayout", {Parent = Page, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
            Library:Create("UIPadding", {Parent = Page, PaddingRight = UDim.new(0, 10)})

            TabBtn.MouseButton1Click:Connect(function()
                for _, t in pairs(Window.Tabs) do
                    t.Page.Visible = false
                    Library:Tween(t.Btn, 0.2, {BackgroundColor3 = Library.Theme.Element})
                end
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundColor3 = Library.Theme.Accent})
            end)

            function Tab:Section(SecData)
                local Section = {}
                
                local SecFrame = Library:Create("Frame", {
                    Parent = Page,
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Library.Theme.Sidebar,
                    BackgroundTransparency = Library.Theme.Transparency,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                Library:Create("UICorner", {Parent = SecFrame, CornerRadius = UDim.new(0, 6)})

                local SecLayout = Library:Create("UIListLayout", {Parent = SecFrame, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
                Library:Create("UIPadding", {Parent = SecFrame, PaddingTop = UDim.new(0, 30), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

                -- Section Top Accent
                local SecTopLine = Library:Create("Frame", {
                    Parent = SecFrame,
                    Size = UDim2.new(1, 0, 0, 2),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel = 0
                })
                Library:ApplyAccentGradient(SecTopLine)

                Library:Create("TextLabel", {
                    Parent = SecFrame,
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = SecData.Name or "Section",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local function UpdateSize()
                    Page.CanvasSize = UDim2.new(0, 0, 0, SecLayout.AbsoluteContentSize.Y + 40)
                end
                SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)

                function Section:Toggle(tData)
                    local Toggle = {Value = tData.Default or false}
                    
                    local TFrame = Library:Create("TextButton", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = Library.Theme.Element,
                        BackgroundTransparency = 0.5,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = TFrame, CornerRadius = UDim.new(0, 4)})
                    Library:Create("TextLabel", {
                        Parent = TFrame,
                        Size = UDim2.new(1, -50, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = tData.Name or "Toggle",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local Indicator = Library:Create("Frame", {
                        Parent = TFrame,
                        Size = UDim2.new(0, 18, 0, 18),
                        Position = UDim2.new(1, -28, 0.5, -9),
                        BackgroundColor3 = Library.Theme.Element,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})
                    local IndicatorStroke = Library:Create("UIStroke", {Parent = Indicator, Color = Library.Theme.Outline, Thickness = 1.5})
                    
                    local CheckImg = Library:Create("ImageLabel", {
                        Parent = Indicator,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0.5, -6, 0.5, -6),
                        BackgroundTransparency = 1,
                        Image = Library.Assets.Checkmark,
                        ImageTransparency = 1
                    })
                    Library:ApplyAccentGradient(IndicatorStroke)

                    function Toggle:Set(val)
                        Toggle.Value = val
                        if val then
                            Library:Tween(Indicator, 0.2, {BackgroundColor3 = Library.Theme.Accent})
                            Library:Tween(IndicatorStroke, 0.2, {Transparency = 1})
                            Library:Tween(CheckImg, 0.2, {ImageTransparency = 0})
                        else
                            Library:Tween(Indicator, 0.2, {BackgroundColor3 = Library.Theme.Element})
                            Library:Tween(IndicatorStroke, 0.2, {Transparency = 0})
                            Library:Tween(CheckImg, 0.2, {ImageTransparency = 1})
                        end
                        if tData.Callback then tData.Callback(val) end
                    end

                    TFrame.MouseButton1Click:Connect(function()
                        Toggle:Set(not Toggle.Value)
                    end)

                    if tData.Flag then Library.Flags[tData.Flag] = Toggle end
                    return Toggle
                end

                function Section:Button(bData)
                    local Btn = Library:Create("TextButton", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = Library.Theme.Element,
                        BackgroundTransparency = 0.5,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                    
                    local BtnText = Library:Create("TextLabel", {
                        Parent = Btn,
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = bData.Name or "Button",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14
                    })

                    Btn.MouseButton1Click:Connect(function()
                        Library:Tween(Btn, 0.1, {BackgroundColor3 = Library.Theme.Accent})
                        Library:Tween(BtnText, 0.1, {TextColor3 = Color3.fromRGB(255,255,255)})
                        task.wait(0.15)
                        Library:Tween(Btn, 0.1, {BackgroundColor3 = Library.Theme.Element})
                        Library:Tween(BtnText, 0.1, {TextColor3 = Library.Theme.Text})
                        if bData.Callback then bData.Callback() end
                    end)
                    return Btn
                end

                function Section:Slider(sData)
                    local Slider = {Value = sData.Default or sData.Min or 0}
                    
                    local SFrame = Library:Create("Frame", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 40),
                        BackgroundColor3 = Library.Theme.Element,
                        BackgroundTransparency = 0.5,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = SFrame, CornerRadius = UDim.new(0, 4)})
                    Library:Create("TextLabel", {
                        Parent = SFrame,
                        Size = UDim2.new(1, -50, 0, 20),
                        Position = UDim2.new(0, 10, 0, 5),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = sData.Name or "Slider",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local ValLabel = Library:Create("TextLabel", {
                        Parent = SFrame,
                        Size = UDim2.new(0, 40, 0, 20),
                        Position = UDim2.new(1, -50, 0, 5),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = tostring(Slider.Value),
                        TextColor3 = Library.Theme.Accent,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Right
                    })

                    local Track = Library:Create("Frame", {
                        Parent = SFrame,
                        Size = UDim2.new(1, -20, 0, 4),
                        Position = UDim2.new(0, 10, 0, 28),
                        BackgroundColor3 = Library.Theme.Outline,
                        BorderSizePixel = 0
                    })
                    local Fill = Library:Create("Frame", {
                        Parent = Track,
                        Size = UDim2.new((Slider.Value - (sData.Min or 0)) / ((sData.Max or 100) - (sData.Min or 0)), 0, 1, 0),
                        BackgroundColor3 = Library.Theme.Accent,
                        BorderSizePixel = 0
                    })
                    Library:ApplyAccentGradient(Fill)
                    
                    local Knob = Library:Create("ImageLabel", {
                        Parent = Fill,
                        Size = UDim2.new(0, 16, 0, 12),
                        Position = UDim2.new(1, -8, 0.5, -6),
                        BackgroundTransparency = 1,
                        Image = Library.Assets.SliderKnob
                    })

                    local Sliding = false
                    local function Update(Input)
                        local Percent = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                        Slider.Value = math.floor((sData.Min or 0) + (Percent * ((sData.Max or 100) - (sData.Min or 0))))
                        Fill.Size = UDim2.new(Percent, 0, 1, 0)
                        ValLabel.Text = tostring(Slider.Value)
                        if sData.Callback then sData.Callback(Slider.Value) end
                    end

                    Track.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Sliding = true
                            Update(Input)
                        end
                    end)
                    Library:Connect(UserInputService.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then Sliding = false end
                    end)
                    Library:Connect(UserInputService.InputChanged, function(Input)
                        if Sliding and Input.UserInputType == Enum.UserInputType.MouseMovement then
                            Update(Input)
                        end
                    end)

                    if sData.Flag then Library.Flags[sData.Flag] = Slider end
                    return Slider
                end

                function Section:Dropdown(dData)
                    local Dropdown = {Value = dData.Default or (dData.Options and dData.Options[1] or nil), Open = false}
                    
                    local DFrame = Library:Create("TextButton", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundColor3 = Library.Theme.Element,
                        BackgroundTransparency = 0.5,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = DFrame, CornerRadius = UDim.new(0, 4)})
                    Library:Create("TextLabel", {
                        Parent = DFrame,
                        Size = UDim2.new(0, 80, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = dData.Name or "Dropdown",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local ValLabel = Library:Create("TextLabel", {
                        Parent = DFrame,
                        Size = UDim2.new(1, -100, 1, 0),
                        Position = UDim2.new(0, 90, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.GothamBold,
                        Text = Dropdown.Value or "None",
                        TextColor3 = Library.Theme.Accent,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Right
                    })

                    local Arrow = Library:Create("ImageLabel", {
                        Parent = DFrame,
                        Size = UDim2.new(0, 12, 0, 8),
                        Position = UDim2.new(1, -20, 0.5, -4),
                        BackgroundTransparency = 1,
                        Image = Library.Assets.DropdownArrow,
                        ImageColor3 = Library.Theme.Text
                    })

                    local List = Library:Create("Frame", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 0),
                        BackgroundColor3 = Library.Theme.Sidebar,
                        BackgroundTransparency = Library.Theme.Transparency,
                        BorderSizePixel = 0,
                        ClipsDescendants = true
                    })
                    Library:Create("UICorner", {Parent = List, CornerRadius = UDim.new(0, 4)})
                    local ListLayout = Library:Create("UIListLayout", {Parent = List, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
                    Library:Create("UIPadding", {Parent = List, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

                    local function Refresh()
                        for _, child in pairs(List:GetChildren()) do
                            if child:IsA("TextButton") then child:Destroy() end
                        end
                        for _, opt in pairs(dData.Options) do
                            local Btn = Library:Create("TextButton", {
                                Parent = List,
                                Size = UDim2.new(1, 0, 0, 25),
                                BackgroundColor3 = opt == Dropdown.Value and Library.Theme.Accent or Library.Theme.Element,
                                BackgroundTransparency = 0.5,
                                Text = "",
                                AutoButtonColor = false,
                                BorderSizePixel = 0
                            })
                            Library:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                            Library:Create("TextLabel", {
                                Parent = Btn,
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundTransparency = 1,
                                Font = Enum.Font.Gotham,
                                Text = opt,
                                TextColor3 = Library.Theme.Text,
                                TextSize = 14
                            })
                            Btn.MouseButton1Click:Connect(function()
                                Dropdown.Value = opt
                                ValLabel.Text = opt
                                Refresh()
                                if dData.Callback then dData.Callback(opt) end
                                Dropdown.Open = false
                                Library:Tween(List, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                                Library:Tween(Arrow, 0.2, {Rotation = 0})
                            end)
                        end
                    end

                    DFrame.MouseButton1Click:Connect(function()
                        Dropdown.Open = not Dropdown.Open
                        if Dropdown.Open then
                            Refresh()
                            Library:Tween(List, 0.2, {Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)})
                            Library:Tween(Arrow, 0.2, {Rotation = 180})
                        else
                            Library:Tween(List, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                            Library:Tween(Arrow, 0.2, {Rotation = 0})
                        end
                    end)

                    if dData.Flag then Library.Flags[dData.Flag] = Dropdown end
                    return Dropdown
                end

                UpdateSize()
                
                -- Backward Compatibility for Sections
                Section.AddToggle = Section.Toggle
                Section.AddButton = Section.Button
                Section.AddSlider = Section.Slider
                Section.AddDropdown = Section.Dropdown
                Section.CreateToggle = Section.Toggle
                Section.CreateButton = Section.Button
                Section.CreateSlider = Section.Slider
                Section.CreateDropdown = Section.Dropdown
                
                return Section
            end

            -- Backward Compatibility for Tabs
            Tab.AddSection = Tab.Section
            Tab.CreateSection = Tab.Section

            table.insert(Window.Tabs, {Btn = TabBtn, Page = Page})
            if #Window.Tabs == 1 then
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundColor3 = Library.Theme.Accent})
            end

            return Tab
        end

        -- Backward Compatibility for Window
        Window.AddTab = Window.Tab
        Window.CreateTab = Window.Tab

        return Window
    end

    -- Config System
    function Library:SaveConfig(Name)
        local Config = {}
        for k, v in pairs(self.Flags) do
            if type(v) == "table" and v.Value ~= nil then
                Config[k] = v.Value
            end
        end
        if not isfolder("MergedUI_Configs") then makefolder("MergedUI_Configs") end
        writefile("MergedUI_Configs/" .. Name .. ".json", HttpService:JSONEncode(Config))
        self:Notify("Config", "Saved config: " .. Name, 3)
    end

    function Library:LoadConfig(Name)
        local Path = "MergedUI_Configs/" .. Name .. ".json"
        if isfile(Path) then
            local Config = HttpService:JSONDecode(readfile(Path))
            for k, v in pairs(Config) do
                if self.Flags[k] and self.Flags[k].Set then
                    self.Flags[k].Set(v)
                end
            end
            self:Notify("Config", "Loaded config: " .. Name, 3)
        end
    end
    
    -- Backward Compatibility for Library
    Library.CreateWindow = Library.Window
end

return Library

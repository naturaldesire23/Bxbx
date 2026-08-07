-- Merged & Optimized UI Library
-- Features: Acrylic Theme, Glass Blur, Custom Assets, Perfect Slider, Resizeable, Backward Compatible

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

    -- Acrylic Theme Configuration
    Library.Theme = {
        Background = Color3.fromRGB(12, 12, 12),
        Secondary = Color3.fromRGB(20, 20, 20),
        Border = Color3.fromRGB(39, 39, 39),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(93, 93, 93),
        Accent = Color3.fromRGB(255, 255, 255),
        Transparency = 0.05 -- Very solid, sleek look
    }

    -- Custom Image Assets
    Library.Assets = {
        Close = "rbxassetid://119943770201674",
        Minimize = "rbxassetid://82603981310445",
        Resize = "rbxassetid://120997033468887",
        DropdownArrow = "rbxassetid://105558791071013",
        ButtonIcon = "rbxassetid://10734898355",
        Notification = "rbxassetid://10709775704"
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

    -- Helper: Tween
    function Library:Tween(Obj, Time, Props)
        local T = TweenService:Create(Obj, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
        T:Play()
        return T
    end

    -- Helper: Connect
    function Library:Connect(Signal, Callback)
        local C = Signal:Connect(Callback)
        table.insert(self.Connections, C)
        return C
    end

    -- Blur Effect (Acrylic Style)
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
    function Library:Draggable(Frame, Handle)
        local Dragging, DragInput, DragStart, StartPos
        Handle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = Input.Position
                StartPos = Frame.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
                end)
            end
        end)
        Handle.InputChanged:Connect(function(Input)
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
        Size = UDim2.new(0, 220, 1, -20),
        Position = UDim2.new(1, -240, 0, 10),
        BackgroundTransparency = 1
    })
    Library:Create("UIListLayout", {Parent = NotifHolder, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right})

    function Library:Notify(Title, Desc, Duration)
        Duration = Duration or 5
        local Notif = Library:Create("Frame", {
            Parent = NotifHolder,
            Size = UDim2.new(1, 0, 0, 70),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ClipsDescendants = true
        })
        Library:Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 5)})
        Library:Create("UIStroke", {Parent = Notif, Color = Library.Theme.Border, Thickness = 1.5})

        Library:Create("TextLabel", {
            Parent = Notif,
            Size = UDim2.new(1, -50, 0, 20),
            Position = UDim2.new(0, 14, 0, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = Title,
            TextColor3 = Library.Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Create("TextLabel", {
            Parent = Notif,
            Size = UDim2.new(1, -50, 0, 20),
            Position = UDim2.new(0, 14, 0, 36),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = Desc,
            TextColor3 = Library.Theme.TextDark,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        Library:Create("ImageLabel", {
            Parent = Notif,
            Size = UDim2.new(0, 19, 0, 19),
            Position = UDim2.new(1, -33, 0, 25),
            BackgroundTransparency = 1,
            Image = Library.Assets.Notification,
            ImageColor3 = Library.Theme.Text
        })

        local TimerBar = Library:Create("Frame", {
            Parent = Notif,
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        })
        Library:Create("UICorner", {Parent = TimerBar, CornerRadius = UDim.new(1, 0)})

        Notif.Position = UDim2.new(1, 0, 0, 0)
        Library:Tween(Notif, 0.3, {Position = UDim2.new(0, 0, 0, 0)})
        Library:Tween(TimerBar, Duration, {Size = UDim2.new(0, 0, 0, 3)})

        task.delay(Duration, function()
            Library:Tween(Notif, 0.3, {Position = UDim2.new(1, 20, 0, 0)})
            task.wait(0.3)
            Notif:Destroy()
        end)
    end

    -- Window Creation
    function Library:Window(Data)
        local Window = {}
        Window.Tabs = {}

        local Main = Library:Create("Frame", {
            Parent = self.Gui,
            Size = UDim2.new(0, 690, 0, 446),
            Position = UDim2.new(0.5, -345, 0.5, -223),
            BackgroundColor3 = Library.Theme.Background,
            BackgroundTransparency = Library.Theme.Transparency,
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true
        })
        Library:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 5)})
        Library:Create("UIStroke", {Parent = Main, Color = Library.Theme.Border, Thickness = 1})
        Library:Blurify(Main, 0.95)

        local TopBar = Library:Create("Frame", {
            Parent = Main,
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundTransparency = 1
        })
        Library:Draggable(Main, TopBar)

        Library:Create("TextLabel", {
            Parent = TopBar,
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamSemibold,
            Text = Data.Title or "Acrylic UI",
            TextColor3 = Library.Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })

        -- Window Controls (Minimize, Close, Resize)
        local MinBtn = Library:Create("ImageLabel", {
            Parent = TopBar,
            Size = UDim2.new(0, 15, 0, 15),
            Position = UDim2.new(1, -35, 0.5, -7),
            BackgroundTransparency = 1,
            Image = Library.Assets.Minimize,
            ImageColor3 = Library.Theme.TextDark
        })
        local MinClick = Library:Create("TextButton", {
            Parent = MinBtn,
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(-0.3, 0, -0.3, 0),
            BackgroundTransparency = 1,
            Text = ""
        })
        MinClick.MouseButton1Click:Connect(function()
            if Main.Size.Y.Offset > 45 then
                Library:Tween(Main, 0.2, {Size = UDim2.new(0, Main.Size.X.Offset, 0, 45)})
            else
                Library:Tween(Main, 0.2, {Size = UDim2.new(0, Main.Size.X.Offset, 0, 446)})
            end
        end)

        local CloseBtn = Library:Create("ImageLabel", {
            Parent = TopBar,
            Size = UDim2.new(0, 15, 0, 15),
            Position = UDim2.new(1, -12, 0.5, -7),
            BackgroundTransparency = 1,
            Image = Library.Assets.Close,
            ImageColor3 = Library.Theme.TextDark
        })
        local CloseClick = Library:Create("TextButton", {
            Parent = CloseBtn,
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(-0.3, 0, -0.3, 0),
            BackgroundTransparency = 1,
            Text = ""
        })
        CloseClick.MouseButton1Click:Connect(function()
            Library:Tween(Main, 0.2, {Size = UDim2.new(0, 690, 0, 0)})
            task.wait(0.2)
            Main.Visible = false
        end)

        local ResizeBtn = Library:Create("ImageLabel", {
            Parent = Main,
            Size = UDim2.new(0, 62, 0, 60),
            Position = UDim2.new(1, -5, 1, -5),
            BackgroundTransparency = 1,
            Image = Library.Assets.Resize,
            ImageColor3 = Library.Theme.TextDark
        })
        local Resizing, StartPos, StartSize
        ResizeBtn.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Resizing = true
                StartPos = Input.Position
                StartSize = Main.AbsoluteSize
            end
        end)
        Library:Connect(UserInputService.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then Resizing = false end
        end)
        Library:Connect(UserInputService.InputChanged, function(Input)
            if Resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
                local Delta = Input.Position - StartPos
                local NewW = math.clamp(StartSize.X + Delta.X, 500, 1200)
                local NewH = math.clamp(StartSize.Y + Delta.Y, 300, 800)
                Main.Size = UDim2.new(0, NewW, 0, NewH)
            end
        end)

        Library:Create("Frame", {
            Parent = TopBar,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Library.Theme.Border,
            BorderSizePixel = 0
        })

        local SideBar = Library:Create("ScrollingFrame", {
            Parent = Main,
            Size = UDim2.new(0, 165, 1, -46),
            Position = UDim2.new(0, 0, 0, 46),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        Library:Create("UIListLayout", {Parent = SideBar, Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder})
        Library:Create("UIPadding", {Parent = SideBar, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

        local ContentArea = Library:Create("ScrollingFrame", {
            Parent = Main,
            Size = UDim2.new(1, -166, 1, -46),
            Position = UDim2.new(0, 166, 0, 46),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Border,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        Library:Create("UIListLayout", {Parent = ContentArea, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
        Library:Create("UIPadding", {Parent = ContentArea, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})

        function Window:Show()
            Main.Visible = true
            Main.Size = UDim2.new(0, 690, 0, 0)
            Library:Tween(Main, 0.4, {Size = UDim2.new(0, 690, 0, 446)})
        end

        function Window:Tab(TabData)
            local Tab = {}
            
            local TabBtn = Library:Create("TextButton", {
                Parent = SideBar,
                Size = UDim2.new(1, 0, 0, 35),
                BackgroundColor3 = Library.Theme.Secondary,
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0
            })
            Library:Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 5)})
            local TabStroke = Library:Create("UIStroke", {Parent = TabBtn, Color = Library.Theme.Border, Thickness = 1, Transparency = 1})
            
            Library:Create("TextLabel", {
                Parent = TabBtn,
                Size = UDim2.new(1, -15, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                Text = TabData.Name or "Tab",
                TextColor3 = Library.Theme.TextDark,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Page = Library:Create("Frame", {
                Parent = ContentArea,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false
            })
            Library:Create("UIListLayout", {Parent = Page, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})

            TabBtn.MouseButton1Click:Connect(function()
                for _, t in pairs(Window.Tabs) do
                    t.Page.Visible = false
                    Library:Tween(t.Btn, 0.2, {BackgroundTransparency = 1})
                    Library:Tween(t.Stroke, 0.2, {Transparency = 1})
                end
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundTransparency = 0.7})
                Library:Tween(TabStroke, 0.2, {Transparency = 0})
            end)

            function Tab:Section(SecData)
                local Section = {}
                
                local SecFrame = Library:Create("Frame", {
                    Parent = Page,
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Library.Theme.Secondary,
                    BackgroundTransparency = 0.05,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                Library:Create("UICorner", {Parent = SecFrame, CornerRadius = UDim.new(0, 5)})
                Library:Create("UIStroke", {Parent = SecFrame, Color = Library.Theme.Border, Thickness = 1})

                local SecLayout = Library:Create("UIListLayout", {Parent = SecFrame, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder})
                Library:Create("UIPadding", {Parent = SecFrame, PaddingTop = UDim.new(0, 25), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

                Library:Create("TextLabel", {
                    Parent = SecFrame,
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 10, 0, 5),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamSemibold,
                    Text = SecData.Name or "Section",
                    TextColor3 = Library.Theme.TextDark,
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
                        Size = UDim2.new(1, 0, 0, 39),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BackgroundTransparency = 0.05,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = TFrame, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = TFrame, Color = Library.Theme.Border, Thickness = 1})
                    Library:Create("TextLabel", {
                        Parent = TFrame,
                        Size = UDim2.new(1, -60, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = tData.Name or "Toggle",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local SwitchBg = Library:Create("Frame", {
                        Parent = TFrame,
                        Size = UDim2.new(0, 38, 0, 21),
                        Position = UDim2.new(1, -48, 0.5, -10),
                        BackgroundColor3 = Toggle.Value and Library.Theme.Accent or Color3.fromRGB(32, 32, 32),
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = SwitchBg, CornerRadius = UDim.new(1, 0)})
                    local Circle = Library:Create("Frame", {
                        Parent = SwitchBg,
                        Size = UDim2.new(0, 13, 0, 13),
                        Position = Toggle.Value and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 4, 0.5, -6),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})

                    function Toggle:Set(val)
                        Toggle.Value = val
                        Library:Tween(SwitchBg, 0.2, {BackgroundColor3 = val and Library.Theme.Accent or Color3.fromRGB(32, 32, 32)})
                        Library:Tween(Circle, 0.2, {Position = val and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 4, 0.5, -6)})
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
                        Size = UDim2.new(1, 0, 0, 39),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BackgroundTransparency = 0.05,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = Btn, Color = Library.Theme.Border, Thickness = 1})
                    Library:Create("TextLabel", {
                        Parent = Btn,
                        Size = UDim2.new(1, -40, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = bData.Name or "Button",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    Library:Create("ImageLabel", {
                        Parent = Btn,
                        Size = UDim2.new(0, 20, 0, 20),
                        Position = UDim2.new(1, -30, 0.5, -10),
                        BackgroundTransparency = 1,
                        Image = Library.Assets.ButtonIcon,
                        ImageColor3 = Library.Theme.Text
                    })

                    Btn.MouseButton1Click:Connect(function()
                        Library:Tween(Btn, 0.1, {BackgroundTransparency = 0.3})
                        task.wait(0.1)
                        Library:Tween(Btn, 0.1, {BackgroundTransparency = 0.05})
                        if bData.Callback then bData.Callback() end
                    end)
                    return Btn
                end

                function Section:Slider(sData)
                    local Slider = {Value = sData.Default or sData.Min or 0}
                    
                    local SFrame = Library:Create("Frame", {
                        Parent = SecFrame,
                        Size = UDim2.new(1, 0, 0, 46),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BackgroundTransparency = 0.05,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = SFrame, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = SFrame, Color = Library.Theme.Border, Thickness = 1})
                    Library:Create("TextLabel", {
                        Parent = SFrame,
                        Size = UDim2.new(1, -60, 0, 20),
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
                        Size = UDim2.new(0, 50, 0, 20),
                        Position = UDim2.new(1, -60, 0, 5),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = tostring(Slider.Value),
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Right
                    })

                    local Track = Library:Create("Frame", {
                        Parent = SFrame,
                        Size = UDim2.new(1, -20, 0, 7),
                        Position = UDim2.new(0, 10, 0, 29),
                        BackgroundColor3 = Color3.fromRGB(11, 11, 11),
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
                    local Fill = Library:Create("Frame", {
                        Parent = Track,
                        Size = UDim2.new((Slider.Value - (sData.Min or 0)) / ((sData.Max or 100) - (sData.Min or 0)), 0, 1, 0),
                        BackgroundColor3 = Library.Theme.Accent,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

                    local Sliding = false
                    local function Update(Input)
                        local Percent = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                        Slider.Value = math.floor((sData.Min or 0) + (Percent * ((sData.Max or 100) - (sData.Min or 0))))
                        Fill.Size = UDim2.new(Percent, 0, 1, 0)
                        ValLabel.Text = tostring(Slider.Value)
                        if sData.Callback then sData.Callback(Slider.Value) end
                    end

                    Track.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            Sliding = true
                            Update(Input)
                        end
                    end)
                    Library:Connect(UserInputService.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Sliding = false end
                    end)
                    Library:Connect(UserInputService.InputChanged, function(Input)
                        if Sliding and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
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
                        Size = UDim2.new(1, 0, 0, 39),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BackgroundTransparency = 0.05,
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = DFrame, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = DFrame, Color = Library.Theme.Border, Thickness = 1})
                    Library:Create("TextLabel", {
                        Parent = DFrame,
                        Size = UDim2.new(1, -150, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = dData.Name or "Dropdown",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 14,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })

                    local Display = Library:Create("Frame", {
                        Parent = DFrame,
                        Size = UDim2.new(0, 135, 0, 26),
                        Position = UDim2.new(1, -145, 0.5, -13),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BorderSizePixel = 0
                    })
                    Library:Create("UICorner", {Parent = Display, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = Display, Color = Library.Theme.Border, Thickness = 1})
                    local ValLabel = Library:Create("TextLabel", {
                        Parent = Display,
                        Size = UDim2.new(1, -30, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.Gotham,
                        Text = Dropdown.Value or "None",
                        TextColor3 = Library.Theme.Text,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left
                    })
                    local Arrow = Library:Create("ImageLabel", {
                        Parent = Display,
                        Size = UDim2.new(0, 10, 0, 10),
                        Position = UDim2.new(1, -20, 0.5, -5),
                        BackgroundTransparency = 1,
                        Image = Library.Assets.DropdownArrow,
                        ImageColor3 = Library.Theme.TextDark
                    })

                    local List = Library:Create("Frame", {
                        Parent = DFrame,
                        Size = UDim2.new(0, 135, 0, 0),
                        Position = UDim2.new(1, -145, 0, 32),
                        BackgroundColor3 = Library.Theme.Secondary,
                        BorderSizePixel = 0,
                        ClipsDescendants = true
                    })
                    Library:Create("UICorner", {Parent = List, CornerRadius = UDim.new(0, 5)})
                    Library:Create("UIStroke", {Parent = List, Color = Library.Theme.Border, Thickness = 1})
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
                                BackgroundColor3 = opt == Dropdown.Value and Library.Theme.Accent or Library.Theme.Background,
                                BackgroundTransparency = opt == Dropdown.Value and 0 or 0.5,
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
                                TextColor3 = opt == Dropdown.Value and Library.Theme.Background or Library.Theme.Text,
                                TextSize = 13
                            })
                            Btn.MouseButton1Click:Connect(function()
                                Dropdown.Value = opt
                                ValLabel.Text = opt
                                Refresh()
                                if dData.Callback then dData.Callback(opt) end
                                Dropdown.Open = false
                                Library:Tween(List, 0.2, {Size = UDim2.new(0, 135, 0, 0)})
                                Library:Tween(Arrow, 0.2, {Rotation = 0})
                            end)
                        end
                    end

                    DFrame.MouseButton1Click:Connect(function()
                        Dropdown.Open = not Dropdown.Open
                        if Dropdown.Open then
                            Refresh()
                            Library:Tween(List, 0.2, {Size = UDim2.new(0, 135, 0, ListLayout.AbsoluteContentSize.Y + 8)})
                            Library:Tween(Arrow, 0.2, {Rotation = 180})
                        else
                            Library:Tween(List, 0.2, {Size = UDim2.new(0, 135, 0, 0)})
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

            table.insert(Window.Tabs, {Btn = TabBtn, Page = Page, Stroke = TabStroke})
            if #Window.Tabs == 1 then
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundTransparency = 0.7})
                Library:Tween(TabStroke, 0.2, {Transparency = 0})
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
        if not isfolder("AcrylicConfigs") then makefolder("AcrylicConfigs") end
        writefile("AcrylicConfigs/" .. Name .. ".json", HttpService:JSONEncode(Config))
        self:Notify("Config Saved", "Saved as: " .. Name, 3)
    end

    function Library:LoadConfig(Name)
        local Path = "AcrylicConfigs/" .. Name .. ".json"
        if isfile(Path) then
            local Config = HttpService:JSONDecode(readfile(Path))
            for k, v in pairs(Config) do
                if self.Flags[k] and self.Flags[k].Set then
                    self.Flags[k].Set(v)
                end
            end
            self:Notify("Config Loaded", "Loaded: " .. Name, 3)
        end
    end
    
    -- Backward Compatibility for Library
    Library.CreateWindow = Library.Window
end

return Library

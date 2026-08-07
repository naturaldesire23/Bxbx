-- Merged & Optimized UI Library
-- Features: FluentPro Slate Theme, Gray/Black Gradients, Keybind Element, Perfect Dropdowns

local Library = {}
do
    -- Services
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local Workspace = game:GetService("Workspace")
    local Camera = Workspace.CurrentCamera

    -- SlateAnimated Theme Configuration (Gray & Black)
    Library.Theme = {
        Background = Color3.fromRGB(22, 24, 28),
        Secondary = Color3.fromRGB(28, 30, 35),
        Border = Color3.fromRGB(60, 64, 72),
        Text = Color3.fromRGB(235, 237, 240),
        TextDark = Color3.fromRGB(150, 155, 165),
        Accent = Color3.fromRGB(140, 150, 165),
        Transparency = 0.1
    }

    Library.Assets = {
        Close = "rbxassetid://119943770201674",
        Minimize = "rbxassetid://82603981310445",
        Resize = "rbxassetid://120997033468887",
        DropdownArrow = "rbxassetid://105558791071013",
        ButtonIcon = "rbxassetid://10734898355",
        Notification = "rbxassetid://10709775704",
        Background = "rbxassetid://6421296794"
    }

    Library.Flags = {}
    Library.Connections = {}

    function Library:Create(Class, Props)
        local Inst = Instance.new(Class)
        for K, V in pairs(Props) do Inst[K] = V end
        return Inst
    end

    -- Gray/Black Background Gradient
    function Library:ApplyBgGradient(Obj)
        return self:Create("UIGradient", {
            Parent = Obj, Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(35, 37, 42), Color3.fromRGB(18, 19, 22))
        })
    end

    -- Gray Stroke Gradient
    function Library:ApplyStrokeGradient(Obj)
        return self:Create("UIGradient", {
            Parent = Obj, Rotation = 0,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 54, 62)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 150, 165)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 54, 62))
            })
        })
    end

    function Library:Tween(Obj, Time, Props)
        local T = TweenService:Create(Obj, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
        T:Play()
        return T
    end

    function Library:Connect(Signal, Callback)
        local C = Signal:Connect(Callback)
        table.insert(self.Connections, C)
        return C
    end

    -- Blur Effect
    function Library:Blurify(Frame, Strength)
        local Part = self:Create("Part", {
            Material = Enum.Material.Glass, Transparency = 1, Reflectance = 1,
            CastShadow = false, Anchored = true, CanCollide = false, CanQuery = false,
            Size = Vector3.new(1, 1, 1) * 0.01, Color = Color3.fromRGB(0,0,0), Parent = Camera,
        })
        local BlockMesh = self:Create("BlockMesh", {Parent = Part})
        
        self:Connect(RunService.RenderStepped, function()
            if not Frame.Parent then Part:Destroy() return end
            if Frame.Visible then
                Part.Transparency = Strength or 0.97
                local C0, C1 = Frame.AbsolutePosition, Frame.AbsolutePosition + Frame.AbsoluteSize
                local R0 = Camera:ScreenPointToRay(C0.X, C0.Y, 1)
                local R1 = Camera:ScreenPointToRay(C1.X, C1.Y, 1)
                local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ)
                local Normal = Camera.CFrame.LookVector

                local function CalcPos(Pos, Norm, Orig, Dir)
                    local V = Orig - Pos
                    local Num = (Norm.X * V.X) + (Norm.Y * V.Y) + (Norm.Z * V.Z)
                    local Den = (Norm.X * Dir.X) + (Norm.Y * Dir.Y) + (Norm.Z * Dir.Z)
                    return Orig + ((-Num / Den) * Dir)
                end

                local P0 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R0.Origin, R0.Direction))
                local P1 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R1.Origin, R1.Direction))
                BlockMesh.Offset = (P0 + P1) / 2
                BlockMesh.Scale = (P1 - P0) / 0.0101
                Part.CFrame = Camera.CFrame
            else
                Part.Transparency = 1
            end
        end)
    end

    Library.Gui = Library:Create("ScreenGui", {
        Name = "MergedUI", Parent = gethui and gethui() or CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false
    })

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
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then DragInput = Input end
        end)
        self:Connect(UserInputService.InputChanged, function(Input)
            if Input == DragInput and Dragging then
                local Delta = Input.Position - DragStart
                self:Tween(Frame, 0.1, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)})
            end
        end)
    end

    -- Notifications
    local NotifGui = Library:Create("ScreenGui", {Name = "MergedNotifs", Parent = gethui and gethui() or CoreGui, ResetOnSpawn = false})
    local NotifHolder = Library:Create("Frame", {Parent = NotifGui, Size = UDim2.new(0, 240, 1, -20), Position = UDim2.new(1, -260, 0, 10), BackgroundTransparency = 1})
    Library:Create("UIListLayout", {Parent = NotifHolder, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right})

    function Library:Notify(Title, Desc, Duration)
        Duration = Duration or 5
        local Notif = Library:Create("Frame", {Parent = NotifHolder, Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 50})
        Library:Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)})
        local NStroke = Library:Create("UIStroke", {Parent = Notif, Thickness = 1.5, ZIndex = 50})
        Library:ApplyStrokeGradient(NStroke)
        Library:ApplyBgGradient(Notif)

        Library:Create("TextLabel", {Parent = Notif, Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = Title, TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 50})
        Library:Create("TextLabel", {Parent = Notif, Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 14, 0, 36), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = Desc, TextColor3 = Library.Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 50})
        local NotifIcon = Library:Create("ImageLabel", {Parent = Notif, Size = UDim2.new(0, 19, 0, 19), Position = UDim2.new(1, -33, 0, 25), BackgroundTransparency = 1, Image = Library.Assets.Notification, ZIndex = 50})
        Library:ApplyStrokeGradient(NotifIcon)

        local TimerBar = Library:Create("Frame", {Parent = Notif, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0, ZIndex = 50})
        Library:Create("UICorner", {Parent = TimerBar, CornerRadius = UDim.new(1, 0)})
        Library:ApplyStrokeGradient(TimerBar)

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
        Window.IsOpen = false

        local Main = Library:Create("Frame", {
            Parent = self.Gui, Size = UDim2.new(0, 850, 0, 480),
            Position = UDim2.new(0.5, -425, 0.5, -240), BackgroundTransparency = 0.1,
            BorderSizePixel = 0, Visible = false, ClipsDescendants = true
        })
        Library:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
        local MainStroke = Library:Create("UIStroke", {Parent = Main, Thickness = 1.5, ZIndex = 10})
        Library:ApplyStrokeGradient(MainStroke)
        Library:ApplyBgGradient(Main)
        Library:Blurify(Main, 0.95)

        local TopBar = Library:Create("Frame", {Parent = Main, Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, ZIndex = 10})
        Library:Draggable(Main, TopBar)

        Library:Create("TextLabel", {Parent = TopBar, Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = Data.Title or "Slate UI", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})

        -- Controls
        local MinBtn = Library:Create("ImageLabel", {Parent = TopBar, Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(1, -35, 0.5, -7), BackgroundTransparency = 1, Image = Library.Assets.Minimize, ImageColor3 = Library.Theme.Text, ZIndex = 10})
        local MinClick = Library:Create("TextButton", {Parent = MinBtn, Size = UDim2.new(1, 10, 1, 10), Position = UDim2.new(-0.3, 0, -0.3, 0), BackgroundTransparency = 1, Text = "", ZIndex = 11})
        MinClick.MouseButton1Click:Connect(function()
            if Main.Size.Y.Offset > 45 then Library:Tween(Main, 0.2, {Size = UDim2.new(0, Main.Size.X.Offset, 0, 45)}) else Library:Tween(Main, 0.2, {Size = UDim2.new(0, Main.Size.X.Offset, 0, 480)}) end
        end)

        local CloseBtn = Library:Create("ImageLabel", {Parent = TopBar, Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(1, -12, 0.5, -7), BackgroundTransparency = 1, Image = Library.Assets.Close, ImageColor3 = Library.Theme.Text, ZIndex = 10})
        local CloseClick = Library:Create("TextButton", {Parent = CloseBtn, Size = UDim2.new(1, 10, 1, 10), Position = UDim2.new(-0.3, 0, -0.3, 0), BackgroundTransparency = 1, Text = "", ZIndex = 11})
        CloseClick.MouseButton1Click:Connect(function() Library:Tween(Main, 0.2, {Size = UDim2.new(0, 850, 0, 0)}) task.wait(0.2) Main.Visible = false Window.IsOpen = false end)

        local ResizeBtn = Library:Create("ImageLabel", {Parent = Main, Size = UDim2.new(0, 62, 0, 60), Position = UDim2.new(1, -5, 1, -5), BackgroundTransparency = 1, Image = Library.Assets.Resize, ImageColor3 = Library.Theme.TextDark, ZIndex = 10})
        local Resizing, StartPos, StartSize
        ResizeBtn.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Resizing = true StartPos = Input.Position StartSize = Main.AbsoluteSize end end)
        Library:Connect(UserInputService.InputEnded, function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 then Resizing = false end end)
        Library:Connect(UserInputService.InputChanged, function(Input)
            if Resizing and Input.UserInputType == Enum.UserInputType.MouseMovement then
                Main.Size = UDim2.new(0, math.clamp(StartSize.X + (Input.Position - StartPos).X, 700, 1400), 0, math.clamp(StartSize.Y + (Input.Position - StartPos).Y, 300, 800))
            end
        end)

        Library:Create("Frame", {Parent = TopBar, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Library.Theme.Border, BorderSizePixel = 0, ZIndex = 10})

        local SideBar = Library:Create("ScrollingFrame", {Parent = Main, Size = UDim2.new(0, 165, 1, -46), Position = UDim2.new(0, 0, 0, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2})
        Library:Create("UIListLayout", {Parent = SideBar, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
        Library:Create("UIPadding", {Parent = SideBar, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})

        local ContentArea = Library:Create("ScrollingFrame", {Parent = Main, Size = UDim2.new(1, -166, 1, -46), Position = UDim2.new(0, 166, 0, 46), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Library.Theme.Border, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2})
        Library:Create("UIPadding", {Parent = ContentArea, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})

        function Window:Show()
            Main.Visible = true
            Main.Size = UDim2.new(0, 850, 0, 0)
            Window.IsOpen = true
            Library:Tween(Main, 0.4, {Size = UDim2.new(0, 850, 0, 480)})
        end

        function Window:Hide()
            Library:Tween(Main, 0.3, {Size = UDim2.new(0, 850, 0, 0)})
            task.wait(0.3)
            Main.Visible = false
            Window.IsOpen = false
        end

        function Window:Toggle()
            if Window.IsOpen then Window:Hide() else Window:Show() end
        end

        function Window:Tab(TabData)
            local Tab = {}
            
            local TabBtn = Library:Create("TextButton", {Parent = SideBar, Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Library.Theme.Secondary, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
            Library:Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
            local TabStroke = Library:Create("UIStroke", {Parent = TabBtn, Color = Library.Theme.Border, Thickness = 1, Transparency = 1, ZIndex = 2})
            
            local TextOffset = 10
            if TabData.Icon then
                TextOffset = 35
                local TabIcon = Library:Create("ImageLabel", {Parent = TabBtn, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundTransparency = 1, Image = TabData.Icon, ImageColor3 = Library.Theme.TextDark, ZIndex = 2})
            end

            Library:Create("TextLabel", {Parent = TabBtn, Size = UDim2.new(1, -TextOffset, 1, 0), Position = UDim2.new(0, TextOffset, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = TabData.Name or "Tab", TextColor3 = Library.Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

            local Page = Library:Create("Frame", {Parent = ContentArea, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 2})
            
            local GridLayout = Library:Create("UIGridLayout", {
                Parent = Page, CellSize = UDim2.new(0.5, -9, 0, 0), 
                CellPadding = UDim2.new(0, 12, 0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            GridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Page.Size = UDim2.new(1, 0, 0, GridLayout.AbsoluteContentSize.Y)
            end)

            TabBtn.MouseButton1Click:Connect(function()
                for _, t in pairs(Window.Tabs) do
                    t.Page.Visible = false
                    Library:Tween(t.Btn, 0.2, {BackgroundTransparency = 1})
                    Library:Tween(t.Stroke, 0.2, {Transparency = 1})
                end
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundTransparency = 0.5})
                Library:Tween(TabStroke, 0.2, {Transparency = 0})
            end)

            function Tab:Section(SecData)
                local Section = {}
                local Elements = {}
                
                local SecFrame = Library:Create("Frame", {Parent = Page, Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0, ZIndex = 2})
                Library:Create("UICorner", {Parent = SecFrame, CornerRadius = UDim.new(0, 6)})
                local SecStroke = Library:Create("UIStroke", {Parent = SecFrame, Thickness = 1, ZIndex = 2})
                Library:ApplyBgGradient(SecFrame)
                Library:ApplyStrokeGradient(SecStroke)

                local SecLayout = Library:Create("UIListLayout", {Parent = SecFrame, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
                Library:Create("UIPadding", {Parent = SecFrame, PaddingTop = UDim.new(0, 30), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})

                local SecTitle = Library:Create("TextLabel", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = SecData.Name or "Section", TextColor3 = Library.Theme.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

                local function UpdateSecSize()
                    SecFrame.Size = UDim2.new(SecFrame.Size.X.Scale, SecFrame.Size.X.Offset, 0, SecLayout.AbsoluteContentSize.Y + 30)
                end
                SecLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSecSize)

                function Section:Toggle(tData)
                    local Toggle = {Value = tData.Default or false}
                    local TFrame = Library:Create("TextButton", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Library.Theme.Background, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = TFrame, CornerRadius = UDim.new(0, 6)})
                    local TStroke = Library:Create("UIStroke", {Parent = TFrame, Thickness = 1, ZIndex = 2})
                    Library:ApplyBgGradient(TFrame)
                    Library:ApplyStrokeGradient(TStroke)
                    Library:Create("TextLabel", {Parent = TFrame, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = tData.Name or "Toggle", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

                    local SwitchBg = Library:Create("Frame", {Parent = TFrame, Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -50, 0.5, -11), BackgroundColor3 = Toggle.Value and Library.Theme.Accent or Color3.fromRGB(30, 30, 35), BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = SwitchBg, CornerRadius = UDim.new(1, 0)})
                    if Toggle.Value then Library:ApplyStrokeGradient(SwitchBg) end
                    
                    local Circle = Library:Create("Frame", {Parent = SwitchBg, Size = UDim2.new(0, 14, 0, 14), Position = Toggle.Value and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7), BackgroundColor3 = Library.Theme.Text, BorderSizePixel = 0, ZIndex = 3})
                    Library:Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})

                    function Toggle:Set(val)
                        Toggle.Value = val
                        if val then Library:ApplyStrokeGradient(SwitchBg) else if SwitchBg:FindFirstChildOfClass("UIGradient") then SwitchBg:FindFirstChildOfClass("UIGradient"):Destroy() end SwitchBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35) end
                        Library:Tween(Circle, 0.2, {Position = val and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 4, 0.5, -7)})
                        if tData.Callback then tData.Callback(val) end
                    end

                    TFrame.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.Value) end)
                    table.insert(Elements, TFrame)
                    if tData.Flag then Library.Flags[tData.Flag] = Toggle end
                    return Toggle
                end

                function Section:Button(bData)
                    local Btn = Library:Create("TextButton", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Library.Theme.Background, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
                    local BStroke = Library:Create("UIStroke", {Parent = Btn, Thickness = 1, ZIndex = 2})
                    Library:ApplyBgGradient(Btn)
                    Library:ApplyStrokeGradient(BStroke)
                    Library:Create("TextLabel", {Parent = Btn, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = bData.Name or "Button", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})
                    local BtnIcon = Library:Create("ImageLabel", {Parent = Btn, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10), BackgroundTransparency = 1, Image = Library.Assets.ButtonIcon, ImageColor3 = Library.Theme.Text, ZIndex = 2})

                    Btn.MouseButton1Click:Connect(function()
                        Library:Tween(Btn, 0.1, {Size = UDim2.new(1, -2, 0, 38)})
                        task.wait(0.1)
                        Library:Tween(Btn, 0.1, {Size = UDim2.new(1, 0, 0, 40)})
                        if bData.Callback then bData.Callback() end
                    end)
                    table.insert(Elements, Btn)
                    return Btn
                end

                function Section:Slider(sData)
                    local Slider = {Value = sData.Default or sData.Min or 0}
                    local SFrame = Library:Create("Frame", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = SFrame, CornerRadius = UDim.new(0, 6)})
                    local SStroke = Library:Create("UIStroke", {Parent = SFrame, Thickness = 1, ZIndex = 2})
                    Library:ApplyBgGradient(SFrame)
                    Library:ApplyStrokeGradient(SStroke)
                    Library:Create("TextLabel", {Parent = SFrame, Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = sData.Name or "Slider", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})
                    local ValLabel = Library:Create("TextLabel", {Parent = SFrame, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -60, 0, 8), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = tostring(Slider.Value), TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2})

                    local Track = Library:Create("Frame", {Parent = SFrame, Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 34), BackgroundColor3 = Color3.fromRGB(10, 10, 12), BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = Track, CornerRadius = UDim.new(1, 0)})
                    local Fill = Library:Create("Frame", {Parent = Track, Size = UDim2.new((Slider.Value - (sData.Min or 0)) / ((sData.Max or 100) - (sData.Min or 0)), 0, 1, 0), BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
                    Library:ApplyStrokeGradient(Fill)

                    local Sliding = false
                    local function Update(Input)
                        local Percent = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                        Slider.Value = math.floor((sData.Min or 0) + (Percent * ((sData.Max or 100) - (sData.Min or 0))))
                        Fill.Size = UDim2.new(Percent, 0, 1, 0)
                        ValLabel.Text = tostring(Slider.Value)
                        if sData.Callback then sData.Callback(Slider.Value) end
                    end

                    Track.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Sliding = true Update(Input) end end)
                    Library:Connect(UserInputService.InputEnded, function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Sliding = false end end)
                    Library:Connect(UserInputService.InputChanged, function(Input) if Sliding and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then Update(Input) end end)

                    table.insert(Elements, SFrame)
                    if sData.Flag then Library.Flags[sData.Flag] = Slider end
                    return Slider
                end

                function Section:Dropdown(dData)
                    local Dropdown = {Value = dData.Default or (dData.Options and dData.Options[1] or nil), Open = false}
                    local DFrame = Library:Create("TextButton", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Library.Theme.Background, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = DFrame, CornerRadius = UDim.new(0, 6)})
                    local DStroke = Library:Create("UIStroke", {Parent = DFrame, Thickness = 1, ZIndex = 2})
                    Library:ApplyBgGradient(DFrame)
                    Library:ApplyStrokeGradient(DStroke)
                    Library:Create("TextLabel", {Parent = DFrame, Size = UDim2.new(1, -160, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = dData.Name or "Dropdown", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

                    -- Widened to 140px so text fits perfectly
                    local Display = Library:Create("Frame", {Parent = DFrame, Size = UDim2.new(0, 140, 0, 26), Position = UDim2.new(1, -150, 0.5, -13), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = Display, CornerRadius = UDim.new(0, 5)})
                    local DispStroke = Library:Create("UIStroke", {Parent = Display, Thickness = 1, ZIndex = 2})
                    Library:ApplyStrokeGradient(DispStroke)
                    local ValLabel = Library:Create("TextLabel", {Parent = Display, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = Dropdown.Value or "None", TextColor3 = Library.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})
                    local Arrow = Library:Create("ImageLabel", {Parent = Display, Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -20, 0.5, -5), BackgroundTransparency = 1, Image = Library.Assets.DropdownArrow, ImageColor3 = Library.Theme.TextDark, ZIndex = 2})

                    local List = Library:Create("Frame", {Parent = Main, Size = UDim2.new(0, 140, 0, 0), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 20})
                    Library:Create("UICorner", {Parent = List, CornerRadius = UDim.new(0, 5)})
                    local ListStroke = Library:Create("UIStroke", {Parent = List, Thickness = 1, ZIndex = 20})
                    Library:ApplyStrokeGradient(ListStroke)
                    local ListLayout = Library:Create("UIListLayout", {Parent = List, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
                    Library:Create("UIPadding", {Parent = List, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

                    local function UpdateListPos()
                        List.Position = UDim2.new(0, Display.AbsolutePosition.X, 0, Display.AbsolutePosition.Y + Display.AbsoluteSize.Y + 2)
                    end

                    local function Refresh()
                        for _, child in pairs(List:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                        for _, opt in pairs(dData.Options) do
                            local Btn = Library:Create("TextButton", {Parent = List, Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = opt == Dropdown.Value and Library.Theme.Accent or Library.Theme.Background, BackgroundTransparency = 0.2, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 20})
                            Library:Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
                            if opt == Dropdown.Value then Library:ApplyStrokeGradient(Btn) end
                            Library:Create("TextLabel", {Parent = Btn, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = opt, TextColor3 = Library.Theme.Text, TextSize = 13, ZIndex = 20})
                            Btn.MouseButton1Click:Connect(function()
                                Dropdown.Value = opt ValLabel.Text = opt Refresh()
                                if dData.Callback then dData.Callback(opt) end
                                Dropdown.Open = false
                                Library:Tween(List, 0.2, {Size = UDim2.new(0, 140, 0, 0)})
                                Library:Tween(Arrow, 0.2, {Rotation = 0})
                            end)
                        end
                    end

                    DFrame.MouseButton1Click:Connect(function()
                        Dropdown.Open = not Dropdown.Open
                        if Dropdown.Open then
                            Refresh()
                            UpdateListPos()
                            Library:Tween(List, 0.2, {Size = UDim2.new(0, 140, 0, ListLayout.AbsoluteContentSize.Y + 8)})
                            Library:Tween(Arrow, 0.2, {Rotation = 180})
                        else
                            Library:Tween(List, 0.2, {Size = UDim2.new(0, 140, 0, 0)})
                            Library:Tween(Arrow, 0.2, {Rotation = 0})
                        end
                    end)

                    table.insert(Elements, DFrame)
                    if dData.Flag then Library.Flags[dData.Flag] = Dropdown end
                    return Dropdown
                end

                -- New Keybind Element
                function Section:Keybind(kData)
                    local Keybind = {Value = kData.Default or Enum.KeyCode.Unknown, Callback = kData.Callback or function() end}
                    local KFrame = Library:Create("TextButton", {Parent = SecFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Library.Theme.Background, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = KFrame, CornerRadius = UDim.new(0, 6)})
                    local KStroke = Library:Create("UIStroke", {Parent = KFrame, Thickness = 1, ZIndex = 2})
                    Library:ApplyBgGradient(KFrame)
                    Library:ApplyStrokeGradient(KStroke)
                    Library:Create("TextLabel", {Parent = KFrame, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = kData.Name or "Keybind", TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2})

                    local KeyBox = Library:Create("TextButton", {Parent = KFrame, Size = UDim2.new(0, 70, 0, 26), Position = UDim2.new(1, -80, 0.5, -13), BackgroundColor3 = Library.Theme.Background, Text = Keybind.Value.Name, Font = Enum.Font.GothamBold, TextColor3 = Library.Theme.Text, TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2})
                    Library:Create("UICorner", {Parent = KeyBox, CornerRadius = UDim.new(0, 5)})
                    local KBStroke = Library:Create("UIStroke", {Parent = KeyBox, Thickness = 1, ZIndex = 2})
                    Library:ApplyStrokeGradient(KBStroke)

                    local Listening = false
                    KeyBox.MouseButton1Click:Connect(function()
                        Listening = true
                        KeyBox.Text = "..."
                    end)
                    
                    Library:Connect(UserInputService.InputBegan, function(Input, GameProcessed)
                        if GameProcessed then return end
                        if Listening and Input.UserInputType == Enum.UserInputType.Keyboard then
                            Listening = false
                            Keybind.Value = Input.KeyCode
                            KeyBox.Text = Input.KeyCode.Name
                        elseif Input.KeyCode == Keybind.Value and not Listening then
                            if Keybind.Callback then Keybind.Callback() end
                        end
                    end)

                    table.insert(Elements, KFrame)
                    return Keybind
                end

                Section.AddToggle = Section.Toggle
                Section.AddButton = Section.Button
                Section.AddSlider = Section.Slider
                Section.AddDropdown = Section.Dropdown
                Section.AddKeybind = Section.Keybind
                Section.CreateToggle = Section.Toggle
                Section.CreateButton = Section.Button
                Section.CreateSlider = Section.Slider
                Section.CreateDropdown = Section.Dropdown
                Section.CreateKeybind = Section.Keybind
                
                return Section
            end

            Tab.AddSection = Tab.Section
            Tab.CreateSection = Tab.Section

            table.insert(Window.Tabs, {Btn = TabBtn, Page = Page, Stroke = TabStroke})
            if #Window.Tabs == 1 then
                Page.Visible = true
                Library:Tween(TabBtn, 0.2, {BackgroundTransparency = 0.5})
                Library:Tween(TabStroke, 0.2, {Transparency = 0})
            end

            return Tab
        end

        Window.AddTab = Window.Tab
        Window.CreateTab = Window.Tab

        return Window
    end

    function Library:SaveConfig(Name)
        local Config = {}
        for k, v in pairs(self.Flags) do if type(v) == "table" and v.Value ~= nil then Config[k] = v.Value end end
        if not isfolder("SlateConfigs") then makefolder("SlateConfigs") end
        writefile("SlateConfigs/" .. Name .. ".json", HttpService:JSONEncode(Config))
        self:Notify("Config Saved", "Saved as: " .. Name, 3)
    end

    function Library:LoadConfig(Name)
        local Path = "SlateConfigs/" .. Name .. ".json"
        if isfile(Path) then
            local Config = HttpService:JSONDecode(readfile(Path))
            for k, v in pairs(Config) do if self.Flags[k] and self.Flags[k].Set then self.Flags[k].Set(v) end end
            self:Notify("Config Loaded", "Loaded: " .. Name, 3)
        end
    end
    
    Library.CreateWindow = Library.Window
end

return Library

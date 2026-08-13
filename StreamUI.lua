-- StreamUI.lua
-- Full rewrite. Draggable, minimizable to cube on RCtrl, smooth tweens, proper tab layout.

local StreamUI = {}
StreamUI.__index = StreamUI

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local function Tween(obj, props, t, style, dir)
	style = style or Enum.EasingStyle.Quart
	dir = dir or Enum.EasingDirection.Out
	t = t or 0.25
	TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function New(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function Corner(r, parent)
	New("UICorner", {CornerRadius = UDim.new(0, r)}, parent)
end

local function Stroke(color, thick, parent)
	New("UIStroke", {Color = color, Thickness = thick, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, parent)
end

local function Gradient(c0, c1, rot, parent)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c0),
			ColorSequenceKeypoint.new(1, c1)
		}),
		Rotation = rot or -115
	}, parent)
end

-- Colors
local C = {
	BG       = Color3.fromRGB(10, 10, 12),
	BG2      = Color3.fromRGB(15, 15, 18),
	Panel    = Color3.fromRGB(18, 18, 22),
	Element  = Color3.fromRGB(24, 24, 29),
	Outline  = Color3.fromRGB(32, 32, 38),
	Text     = Color3.fromRGB(230, 230, 235),
	TextDim  = Color3.fromRGB(130, 130, 140),
	Accent   = Color3.fromRGB(0, 120, 230),
	Accent2  = Color3.fromRGB(0, 195, 255),
}

function StreamUI:CreateWindow(title)
	local W = setmetatable({}, StreamUI)
	W.Tabs = {}
	W.ActiveTab = nil
	W.MinKeybind = Enum.KeyCode.RightControl
	W.Minimized = false

	-- Root GUI
	local ScreenGui = New("ScreenGui", {
		Name = "StreamUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 10
	})
	pcall(function() ScreenGui.Parent = CoreGui end)
	if not ScreenGui.Parent then ScreenGui.Parent = LP.PlayerGui end

	W.ScreenGui = ScreenGui

	-- Minimize cube (hidden by default)
	local Cube = New("TextButton", {
		Name = "Cube",
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0.5, -24, 0, 20),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = C.Panel,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 20,
		Parent = ScreenGui
	})
	Corner(10, Cube)
	Stroke(C.Outline, 1.5, Cube)

	local CubeGrad = New("Frame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = Cube
	})

	local CubeIcon = New("ImageLabel", {
		Size = UDim2.new(0,22,0,22),
		Position = UDim2.new(0.5,-11,0.5,-11),
		BackgroundTransparency = 1,
		Image = "rbxassetid://100050851789190",
		ZIndex = 22,
		Parent = Cube
	})
	Gradient(C.Accent, C.Accent2, -115, CubeIcon)

	-- Draggable Cube
	do
		local drag, ds, sp = false, nil, nil
		Cube.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				drag = true
				ds = inp.Position
				sp = Cube.Position
				inp.Changed:Connect(function()
					if inp.UserInputState == Enum.UserInputState.End then drag = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local d = inp.Position - ds
				Cube.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
			end
		end)
	end

	-- Main Frame
	local Main = New("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 680, 0, 520),
		Position = UDim2.new(0.5, -340, 0.5, -260),
		BackgroundColor3 = C.BG,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = ScreenGui
	})
	Corner(8, Main)
	Stroke(C.Outline, 1, Main)
	W.Main = Main

	-- Topbar
	local Topbar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Main
	})
	Corner(8, Topbar)

	-- Fill bottom corners of topbar
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Topbar
	})

	-- Logo icon in topbar
	local Logo = New("ImageLabel", {
		Size = UDim2.new(0,20,0,20),
		Position = UDim2.new(0,14,0.5,-10),
		BackgroundTransparency = 1,
		Image = "rbxassetid://100050851789190",
		ZIndex = 4,
		Parent = Topbar
	})
	Gradient(C.Accent, C.Accent2, -115, Logo)

	New("TextLabel", {
		Size = UDim2.new(0,200,0,20),
		Position = UDim2.new(0,42,0.5,-10),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C.Text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = Topbar
	})

	-- Minimize button in topbar
	local MinBtn = New("TextButton", {
		Size = UDim2.new(0,28,0,28),
		Position = UDim2.new(1,-38,0.5,-14),
		BackgroundColor3 = C.Element,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
		Parent = Topbar
	})
	Corner(6, MinBtn)
	New("ImageLabel", {
		Size = UDim2.new(0,12,0,2),
		Position = UDim2.new(0.5,-6,0.5,-1),
		BackgroundColor3 = C.TextDim,
		BackgroundTransparency = 0,
		Image = "",
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = MinBtn
	})

	-- Drag main window
	do
		local drag, ds, sp = false, nil, nil
		Topbar.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				drag = true
				ds = inp.Position
				sp = Main.Position
				inp.Changed:Connect(function()
					if inp.UserInputState == Enum.UserInputState.End then drag = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local d = inp.Position - ds
				Tween(Main, {Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)}, 0.1)
			end
		end)
	end

	-- Tab sidebar (left panel)
	local Sidebar = New("Frame", {
		Size = UDim2.new(0, 170, 1, -44),
		Position = UDim2.new(0, 0, 0, 44),
		BackgroundTransparency = 0.35,
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Main
	})
	Corner(8, Sidebar)

	-- Fill right corners of sidebar
	New("Frame", {
		Size = UDim2.new(0, 8, 1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		BackgroundColor3 = C.BG2,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Sidebar
	})

	local TabList = New("Frame", {
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = Sidebar
	})
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = TabList
	})

	W.TabList = TabList

	-- Content area
	local ContentArea = New("Frame", {
		Size = UDim2.new(1, -178, 1, -52),
		Position = UDim2.new(0, 170, 0, 52),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = Main
	})
	W.ContentArea = ContentArea

	-- Separator line
	New("Frame", {
		Size = UDim2.new(0, 1, 1, -52),
		Position = UDim2.new(0, 169, 0, 52),
		BackgroundColor3 = C.Outline,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = Main
	})

	-- Minimize logic
	local function setMinimized(bool)
		W.Minimized = bool
		if bool then
			Tween(Main, {Size = UDim2.new(0, 680, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quint)
			task.delay(0.25, function()
				Main.Visible = false
				Cube.Visible = true
				Tween(Cube, {BackgroundTransparency = 0}, 0.2)
			end)
		else
			Cube.Visible = false
			Main.Visible = true
			Main.BackgroundTransparency = 1
			Tween(Main, {Size = UDim2.new(0, 680, 0, 520), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Quint)
		end
	end

	MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
	Cube.MouseButton1Click:Connect(function() setMinimized(false) end)

	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == W.MinKeybind then
			setMinimized(not W.Minimized)
		end
	end)

	W._setMinimized = setMinimized
	W.Cube = Cube

	return W
end

function StreamUI:CreateTab(name, icon)
	local W = self
	local T = {Elements = {}, Visible = false}

	-- Tab button
	local Btn = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = C.Element,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
		Parent = W.TabList
	})
	Corner(6, Btn)

	-- Accent bar (left side, shows when active)
	local AccentBar = New("Frame", {
		Size = UDim2.new(0, 3, 0.6, 0),
		Position = UDim2.new(0, 0, 0.2, 0),
		BackgroundTransparency = 1,
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = Btn
	})
	Corner(4, AccentBar)
	Gradient(C.Accent, C.Accent2, 90, AccentBar)

	-- Icon
	local IconImg = New("ImageLabel", {
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0, 12, 0.5, -8),
		BackgroundTransparency = 1,
		Image = icon and ("rbxassetid://" .. icon) or "",
		ImageColor3 = C.TextDim,
		ZIndex = 5,
		Parent = Btn
	})

	local Label = New("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 36, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = C.TextDim,
		TextSize = 13,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
		Parent = Btn
	})

	-- Content scroll frame
	local Content = New("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.new(0, 8, 0, 8),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
		Parent = W.ContentArea
	})

	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = Content
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0,4),
		PaddingBottom = UDim.new(0,4),
		Parent = Content
	})

	T.Content = Content
	T.Btn = Btn

	local function Activate()
		-- Deactivate all
		for _, ot in pairs(W.Tabs) do
			Tween(ot.Btn, {BackgroundTransparency = 1}, 0.18)
			ot.Content.Visible = false
			if ot._AccentBar then
				Tween(ot._AccentBar, {BackgroundTransparency = 1}, 0.18)
			end
			if ot._Icon then
				Tween(ot._Icon, {ImageColor3 = C.TextDim}, 0.18)
			end
			if ot._Label then
				Tween(ot._Label, {TextColor3 = C.TextDim}, 0.18)
			end
		end
		-- Activate this
		Tween(Btn, {BackgroundTransparency = 0.85}, 0.18)
		Content.Visible = true
		Tween(AccentBar, {BackgroundTransparency = 0}, 0.18)
		Tween(IconImg, {ImageColor3 = C.Accent2}, 0.18)
		Tween(Label, {TextColor3 = C.Text}, 0.18)
	end

	T._AccentBar = AccentBar
	T._Icon = IconImg
	T._Label = Label

	Btn.MouseButton1Click:Connect(Activate)

	-- Hover
	Btn.MouseEnter:Connect(function()
		if Content.Visible then return end
		Tween(Btn, {BackgroundTransparency = 0.92}, 0.12)
	end)
	Btn.MouseLeave:Connect(function()
		if Content.Visible then return end
		Tween(Btn, {BackgroundTransparency = 1}, 0.12)
	end)

	table.insert(W.Tabs, T)

	if #W.Tabs == 1 then
		Activate()
	end

	-- Helper: add element frame to content
	local function ElFrame(h)
		local f = New("Frame", {
			Size = UDim2.new(1, 0, 0, h),
			BackgroundTransparency = 1,
			ZIndex = 4,
			Parent = Content
		})
		return f
	end

	-- LABEL
	function T:Label(text)
		local f = ElFrame(22)
		New("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = C.TextDim,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = f
		})
		return T
	end

	-- TOGGLE
	function T:Toggle(name, default, callback)
		local val = default or false
		local f = ElFrame(34)
		local bg = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.Element,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, bg)

		New("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = bg
		})

		-- Switch
		local track = New("Frame", {
			Size = UDim2.new(0, 36, 0, 18),
			Position = UDim2.new(1, -46, 0.5, -9),
			BackgroundColor3 = C.Outline,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = bg
		})
		Corner(9, track)

		local thumb = New("Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(0, 3, 0.5, -6),
			BackgroundColor3 = C.TextDim,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = track
		})
		Corner(6, thumb)

		local function setVal(v)
			val = v
			if v then
				Tween(track, {BackgroundColor3 = C.Accent}, 0.2)
				Tween(thumb, {Position = UDim2.new(0, 21, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255)}, 0.2)
			else
				Tween(track, {BackgroundColor3 = C.Outline}, 0.2)
				Tween(thumb, {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = C.TextDim}, 0.2)
			end
			if callback then callback(v) end
		end

		setVal(val)

		local btn = New("TextButton", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 7,
			Parent = bg
		})
		btn.MouseButton1Click:Connect(function() setVal(not val) end)

		return T
	end

	-- SLIDER
	function T:Slider(name, min, max, default, callback)
		local val = default or min
		local f = ElFrame(48)
		local bg = New("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = C.Element,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, bg)

		New("TextLabel", {
			Size = UDim2.new(0.6,0,0,20),
			Position = UDim2.new(0,12,0,6),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = bg
		})

		local valLabel = New("TextLabel", {
			Size = UDim2.new(0.4,0,0,20),
			Position = UDim2.new(0.6,0,0,6),
			BackgroundTransparency = 1,
			Text = tostring(val),
			TextColor3 = C.Accent2,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
			Parent = bg
		})
		-- pad right
		New("UIPadding", {PaddingRight = UDim.new(0,12), Parent = valLabel})

		local track = New("Frame", {
			Size = UDim2.new(1,-24,0,6),
			Position = UDim2.new(0,12,1,-16),
			BackgroundColor3 = C.Outline,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = bg
		})
		Corner(3, track)

		local fill = New("Frame", {
			Size = UDim2.new((val-min)/(max-min),0,1,0),
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = track
		})
		Corner(3, fill)
		Gradient(C.Accent, C.Accent2, 0, fill)

		local knob = New("Frame", {
			Size = UDim2.new(0,12,0,12),
			Position = UDim2.new((val-min)/(max-min),0,0.5,-6),
			BackgroundColor3 = Color3.fromRGB(255,255,255),
			BorderSizePixel = 0,
			ZIndex = 7,
			Parent = track
		})
		Corner(6, knob)

		local sliding = false
		local function setSlider(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			val = math.floor(min + (max - min) * rel)
			local p = (val - min) / (max - min)
			Tween(fill, {Size = UDim2.new(p,0,1,0)}, 0.05)
			Tween(knob, {Position = UDim2.new(p, -6, 0.5, -6)}, 0.05)
			valLabel.Text = tostring(val)
			if callback then callback(val) end
		end

		track.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				sliding = true
				setSlider(inp.Position.X)
				inp.Changed:Connect(function()
					if inp.UserInputState == Enum.UserInputState.End then sliding = false end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
				setSlider(inp.Position.X)
			end
		end)

		return T
	end

	-- BUTTON
	function T:Button(name, callback)
		local f = ElFrame(34)
		local btn = New("TextButton", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = C.Element,
			Text = "",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, btn)

		local label = New("TextLabel", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.GothamSemibold,
			ZIndex = 5,
			Parent = btn
		})

		-- Accent overlay
		local overlay = New("Frame", {
			Size = UDim2.new(0,0,1,0),
			BackgroundTransparency = 0,
			BackgroundColor3 = C.Accent,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = btn
		})
		Corner(6, overlay)
		overlay.BackgroundTransparency = 1

		btn.MouseEnter:Connect(function()
			Tween(btn, {BackgroundColor3 = Color3.fromRGB(30,30,36)}, 0.15)
		end)
		btn.MouseLeave:Connect(function()
			Tween(btn, {BackgroundColor3 = C.Element}, 0.15)
		end)
		btn.MouseButton1Down:Connect(function()
			Tween(overlay, {BackgroundTransparency = 0.75, Size = UDim2.new(1,0,1,0)}, 0.1)
		end)
		btn.MouseButton1Up:Connect(function()
			Tween(overlay, {BackgroundTransparency = 1}, 0.2)
			if callback then callback() end
		end)

		return T
	end

	-- TEXTFIELD
	function T:TextField(name, placeholder, callback)
		local f = ElFrame(54)
		local bg = New("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = C.Element,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, bg)

		New("TextLabel", {
			Size = UDim2.new(1,0,0,20),
			Position = UDim2.new(0,12,0,4),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.TextDim,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = bg
		})

		local box = New("TextBox", {
			Size = UDim2.new(1,-24,0,22),
			Position = UDim2.new(0,12,0,24),
			BackgroundColor3 = C.BG,
			Text = "",
			PlaceholderText = placeholder or "",
			PlaceholderColor3 = C.TextDim,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			ZIndex = 5,
			Parent = bg
		})
		Corner(4, box)
		New("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = box})

		box.FocusLost:Connect(function()
			if callback then callback(box.Text) end
		end)

		return T
	end

	-- DROPDOWN
	function T:Dropdown(name, items, default, callback)
		local val = default
		local open = false

		local f = New("Frame", {
			Size = UDim2.new(1,0,0,34),
			BackgroundTransparency = 1,
			ZIndex = 4,
			Parent = Content
		})

		local bg = New("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = C.Element,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, bg)

		New("TextLabel", {
			Size = UDim2.new(0.5,0,1,0),
			Position = UDim2.new(0,12,0,0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = bg
		})

		local valLabel = New("TextLabel", {
			Size = UDim2.new(0.4,0,1,0),
			Position = UDim2.new(0.5,0,0,0),
			BackgroundTransparency = 1,
			Text = val or "-",
			TextColor3 = C.Accent2,
			TextSize = 12,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
			Parent = bg
		})
		New("UIPadding", {PaddingRight = UDim.new(0, 28), Parent = valLabel})

		local arrow = New("TextLabel", {
			Size = UDim2.new(0,20,1,0),
			Position = UDim2.new(1,-22,0,0),
			BackgroundTransparency = 1,
			Text = "▾",
			TextColor3 = C.TextDim,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			ZIndex = 5,
			Parent = bg
		})

		-- Dropdown list
		local listFrame = New("Frame", {
			Size = UDim2.new(1,0,0,0),
			Position = UDim2.new(0,0,1,4),
			BackgroundColor3 = C.Panel,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 10,
			Visible = false,
			Parent = f
		})
		Corner(6, listFrame)
		Stroke(C.Outline, 1, listFrame)

		local listLayout = New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = listFrame
		})
		New("UIPadding", {
			PaddingTop = UDim.new(0,4),
			PaddingBottom = UDim.new(0,4),
			Parent = listFrame
		})

		local fullH = #items * 26 + 8

		for _, item in ipairs(items) do
			local row = New("TextButton", {
				Size = UDim2.new(1,0,0,26),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 11,
				Parent = listFrame
			})
			local rowLabel = New("TextLabel", {
				Size = UDim2.new(1,-16,1,0),
				Position = UDim2.new(0,12,0,0),
				BackgroundTransparency = 1,
				Text = item,
				TextColor3 = C.TextDim,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 12,
				Parent = row
			})
			row.MouseEnter:Connect(function() Tween(rowLabel, {TextColor3 = C.Text}, 0.1) end)
			row.MouseLeave:Connect(function()
				if val ~= item then Tween(rowLabel, {TextColor3 = C.TextDim}, 0.1) end
			end)
			row.MouseButton1Click:Connect(function()
				val = item
				valLabel.Text = item
				open = false
				Tween(listFrame, {Size = UDim2.new(1,0,0,0)}, 0.2)
				Tween(arrow, {Rotation = 0}, 0.2)
				task.delay(0.2, function() listFrame.Visible = false end)
				if callback then callback(item) end
			end)
		end

		local mainBtn = New("TextButton", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 6,
			Parent = bg
		})
		mainBtn.MouseButton1Click:Connect(function()
			open = not open
			if open then
				listFrame.Visible = true
				f.Size = UDim2.new(1,0,0,34)
				Tween(listFrame, {Size = UDim2.new(1,0,0,fullH)}, 0.22)
				Tween(arrow, {Rotation = 180}, 0.22)
			else
				Tween(listFrame, {Size = UDim2.new(1,0,0,0)}, 0.18)
				Tween(arrow, {Rotation = 0}, 0.18)
				task.delay(0.18, function() listFrame.Visible = false end)
			end
		end)

		return T
	end

	-- KEYBIND
	function T:Keybind(name, default, callback)
		local key = default
		local picking = false

		local f = ElFrame(34)
		local bg = New("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundColor3 = C.Element,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = f
		})
		Corner(6, bg)

		New("TextLabel", {
			Size = UDim2.new(0.6,0,1,0),
			Position = UDim2.new(0,12,0,0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = C.Text,
			TextSize = 13,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = bg
		})

		local keyBtn = New("TextButton", {
			Size = UDim2.new(0,70,0,22),
			Position = UDim2.new(1,-82,0.5,-11),
			BackgroundColor3 = C.BG,
			Text = key and key.Name or "None",
			TextColor3 = C.Accent2,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = bg
		})
		Corner(4, keyBtn)

		local conn
		keyBtn.MouseButton1Click:Connect(function()
			if picking then return end
			picking = true
			keyBtn.Text = "..."
			keyBtn.TextColor3 = C.TextDim
			conn = UserInputService.InputBegan:Connect(function(inp, gp)
				if gp then return end
				if inp.UserInputType == Enum.UserInputType.Keyboard then
					key = inp.KeyCode
					keyBtn.Text = key.Name
					keyBtn.TextColor3 = C.Accent2
					picking = false
					conn:Disconnect()
					-- update min keybind if this is the Settings keybind
				end
			end)
		end)

		return T
	end

	return T
end

return StreamUI

--[[
	RectUI - Sharp-cornered Roblox UI Library
	Matches spec: 500x400 window, 34px header, 32px tab bar, sections, elements.
	Usage:
		local UI = loadstring(game:HttpGet("https://your.url/rectui.lua"))()
		local Window = UI:CreateWindow({ Title = "My Script" })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UI = {}

--// Default Theme (from spec)
local DefaultTheme = {
	Window = Color3.fromRGB(30, 30, 35),
	Header = Color3.fromRGB(40, 40, 45),
	TabBar = Color3.fromRGB(35, 35, 40),
	TabInactive = Color3.fromRGB(170, 170, 170),
	TabActive = Color3.fromRGB(255, 255, 255),
	Section = Color3.fromRGB(38, 38, 43),
	Element = Color3.fromRGB(50, 50, 55),
	Border = Color3.fromRGB(50, 50, 55),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(180, 180, 180),
	Accent = Color3.fromRGB(0, 150, 255),
}

--// Helpers
local function new(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function tween(inst, props, time, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function makeDraggable(handle, target)
	local dragging, dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// CreateWindow
function UI:CreateWindow(config)
	config = config or {}
	local Theme = DefaultTheme
	if config.Theme then
		for k, v in pairs(config.Theme) do
			Theme[k] = v
		end
	end

	local Window = {}
	Window.Theme = Theme
	Window.Tabs = {}
	Window.ActiveTab = nil
	Window.Flags = {}              -- flag name -> { Set, Get } for config save/load
	Window.AccentRefreshers = {}   -- functions to call after SetAccent so live elements repaint

	local function registerAccentRefresher(fn)
		table.insert(Window.AccentRefreshers, fn)
	end

	function Window:SetAccent(color)
		Theme.Accent = color
		for _, refresh in ipairs(Window.AccentRefreshers) do
			refresh()
		end
	end

	function Window:Destroy()
		if Window.Gui then
			Window.Gui:Destroy()
		end
	end

	function Window:SaveConfig(name)
		local ok, err = pcall(function()
			local data = {}
			for flag, handle in pairs(Window.Flags) do
				data[flag] = handle.Get()
			end
			local encoded = HttpService:JSONEncode(data)
			if writefile then
				if not isfolder or not isfolder("RectUI") then
					if makefolder then makefolder("RectUI") end
				end
				writefile("RectUI/" .. name .. ".json", encoded)
			end
		end)
		return ok, err
	end

	function Window:LoadConfig(name)
		local ok, err = pcall(function()
			if readfile and isfile and isfile("RectUI/" .. name .. ".json") then
				local decoded = HttpService:JSONDecode(readfile("RectUI/" .. name .. ".json"))
				for flag, value in pairs(decoded) do
					if Window.Flags[flag] then
						Window.Flags[flag].Set(nil, value)
					end
				end
			end
		end)
		return ok, err
	end

	function Window:Notify(config)
		config = config or {}
		local title = config.Title or "Notification"
		local text = config.Text or ""
		local duration = config.Duration or 3

		local NotifHolder = Window.NotifHolder
		if not NotifHolder then
			NotifHolder = new("Frame", {
				Name = "Notifications",
				Size = UDim2.new(0, 260, 1, -20),
				Position = UDim2.new(1, -270, 0, 10),
				BackgroundTransparency = 1,
				Parent = Window.Gui,
			})
			new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				Padding = UDim.new(0, 6),
				Parent = NotifHolder,
			})
			Window.NotifHolder = NotifHolder
		end

		local Card = new("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Section,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = NotifHolder,
		})
		new("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 1, Parent = Card })
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
			Parent = Card,
		})
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = Card })

		local NTitle = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.Text,
			TextTransparency = 1,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Card,
		})
		local NText = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = Theme.TextDim,
			TextTransparency = 1,
			TextSize = 12,
			TextWrapped = true,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = Card,
		})

		tween(Card, { BackgroundTransparency = 0 }, 0.15)
		for _, d in ipairs({ { NTitle, 0 }, { NText, 0 } }) do
			tween(d[1], { TextTransparency = d[2] }, 0.15)
		end

		task.delay(duration, function()
			tween(Card, { BackgroundTransparency = 1 }, 0.2)
			tween(NTitle, { TextTransparency = 1 }, 0.2)
			tween(NText, { TextTransparency = 1 }, 0.2)
			task.delay(0.2, function() Card:Destroy() end)
		end)
	end

	local ScreenGui = new("ScreenGui", {
		Name = "RectUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	local size = config.Size or UDim2.new(0, 500, 0, 400)

	local MainFrame = new("Frame", {
		Name = "Window",
		Size = size,
		Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 0), Parent = MainFrame })
	new("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = MainFrame })

	--// Header
	local Header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Theme.Header,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})

	local Title = new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = config.Title or "RectUI",
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Header,
	})

	-- Header buttons: gear, minimize, close (right to left)
	local function headerButton(name, text, xOffset)
		local btn = new("TextButton", {
			Name = name,
			Size = UDim2.new(0, 28, 0, 24),
			Position = UDim2.new(1, xOffset, 0.5, -12),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = Theme.TextDim,
			TextSize = 15,
			Font = Enum.Font.GothamBold,
			Parent = Header,
		})
		btn.MouseEnter:Connect(function() tween(btn, { TextColor3 = Theme.Text }, 0.1) end)
		btn.MouseLeave:Connect(function() tween(btn, { TextColor3 = Theme.TextDim }, 0.1) end)
		return btn
	end

	local CloseBtn = headerButton("Close", "✕", -32)
	local MinBtn = headerButton("Minimize", "—", -60)
	local GearBtn = headerButton("Settings", "⚙", -88)

	makeDraggable(Header, MainFrame)

	local minimized = false
	local expandedSize = size
	MinBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 34) }, 0.2)
		else
			tween(MainFrame, { Size = expandedSize }, 0.2)
		end
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		tween(MainFrame, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, 0.15)
		task.delay(0.15, function() ScreenGui:Destroy() end)
	end)

	GearBtn.MouseButton1Click:Connect(function()
		if Window.SettingsCallback then
			Window.SettingsCallback()
		end
	end)

	function Window:OnSettings(cb)
		Window.SettingsCallback = cb
	end

	--// Tab Bar
	local TabBar = new("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 34),
		BackgroundColor3 = Theme.TabBar,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})
	new("UIStroke", {
		Color = Theme.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = TabBar,
	})
	-- Only want bottom border; UIStroke draws all sides, acceptable visually for 1px sharp theme.

	local TabLayout = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabBar,
	})

	--// Content Area
	local ContentArea = new("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -66),
		Position = UDim2.new(0, 0, 0, 66),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})

	--// CreateTab
	function Window:CreateTab(name)
		local Tab = {}
		Tab.Name = name

		local TabButton = new("TextButton", {
			Name = name .. "Tab",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Theme.TabBar,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = TabBar,
		})
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			Parent = TabButton,
		})

		local TabLabel = new("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = Theme.TabInactive,
			TextSize = 14,
			Font = Enum.Font.Gotham,
			Parent = TabButton,
		})

		local AccentBar = new("Frame", {
			Name = "Accent",
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = TabButton,
		})
		registerAccentRefresher(function() AccentBar.BackgroundColor3 = Theme.Accent end)

		local Page = new("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = ContentArea,
		})
		registerAccentRefresher(function() Page.ScrollBarImageColor3 = Theme.Accent end)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			Parent = Page,
		})
		local PageLayout = new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			Parent = Page,
		})

		local function setActive(active)
			if active then
				tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.12)
				tween(AccentBar, { BackgroundTransparency = 0 }, 0.12)
				Page.Visible = true
			else
				tween(TabLabel, { TextColor3 = Theme.TabInactive }, 0.12)
				tween(AccentBar, { BackgroundTransparency = 1 }, 0.12)
				Page.Visible = false
			end
		end

		TabButton.MouseEnter:Connect(function()
			if Window.ActiveTab ~= Tab then
				tween(TabLabel, { TextColor3 = Theme.TabActive }, 0.1)
				tween(TabButton, { BackgroundTransparency = 0.9 }, 0.1)
			end
		end)
		TabButton.MouseLeave:Connect(function()
			if Window.ActiveTab ~= Tab then
				tween(TabLabel, { TextColor3 = Theme.TabInactive }, 0.1)
			end
			tween(TabButton, { BackgroundTransparency = 1 }, 0.1)
		end)

		TabButton.MouseButton1Click:Connect(function()
			if Window.ActiveTab then
				Window.ActiveTab.setActive(false)
			end
			Window.ActiveTab = Tab
			setActive(true)
		end)

		Tab.setActive = setActive
		Tab.Page = Page

		if not Window.ActiveTab then
			Window.ActiveTab = Tab
			setActive(true)
		end

		--// CreateSection
		function Tab:CreateSection(name)
			local Section = {}

			local SectionFrame = new("Frame", {
				Name = name .. "Section",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Section,
				BorderSizePixel = 0,
				LayoutOrder = #Page:GetChildren(),
				Parent = Page,
			})
			new("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				Parent = SectionFrame,
			})
			local SectionListLayout = new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				Parent = SectionFrame,
			})

			local SectionTitle = new("TextLabel", {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundTransparency = 1,
				Text = string.upper(name),
				TextColor3 = Theme.TextDim,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 0,
				Parent = SectionFrame,
			})

			local order = 1
			local function nextOrder()
				order = order + 1
				return order
			end

			--// Elements

			function Section:CreateLabel(text)
				local Label = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = nextOrder(),
					Parent = SectionFrame,
				})
				return Label
			end

			function Section:CreateToggle(text, callback, flag)
				callback = callback or function() end
				local state = false

				local Row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = nextOrder(),
					Parent = SectionFrame,
				})

				new("TextLabel", {
					Size = UDim2.new(1, -46, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Track = new("TextButton", {
					Size = UDim2.new(0, 36, 0, 18),
					Position = UDim2.new(1, -36, 0.5, -9),
					BackgroundColor3 = Theme.Element,
					Text = "",
					AutoButtonColor = false,
					Parent = Row,
				})

				local Knob = new("Frame", {
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 2, 0.5, -7),
					BackgroundColor3 = Theme.TextDim,
					BorderSizePixel = 0,
					Parent = Track,
				})

				local function render()
					if state then
						tween(Track, { BackgroundColor3 = Theme.Accent }, 0.12)
						tween(Knob, { Position = UDim2.new(0, 20, 0.5, -7), BackgroundColor3 = Theme.Text }, 0.12)
					else
						tween(Track, { BackgroundColor3 = Theme.Element }, 0.12)
						tween(Knob, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = Theme.TextDim }, 0.12)
					end
				end

				Track.MouseButton1Click:Connect(function()
					state = not state
					render()
					callback(state)
				end)

				registerAccentRefresher(function() render() end)

				local handle = {
					Set = function(_, v)
						state = v
						render()
						callback(state)
					end,
					Get = function() return state end,
				}
				if flag then Window.Flags[flag] = handle end
				return handle
			end

			function Section:CreateSlider(text, min, max, default, callback, step, flag)
				callback = callback or function() end
				step = step or 1
				local value = default or min

				local Row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					LayoutOrder = nextOrder(),
					Parent = SectionFrame,
				})

				local Label = new("TextLabel", {
					Size = UDim2.new(1, -40, 0, 16),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local ValueLabel = new("TextLabel", {
					Size = UDim2.new(0, 40, 0, 16),
					Position = UDim2.new(1, -40, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(value),
					TextColor3 = Theme.TextDim,
					TextSize = 13,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent = Row,
				})

				local Track = new("Frame", {
					Size = UDim2.new(1, 0, 0, 4),
					Position = UDim2.new(0, 0, 0, 24),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					Parent = Row,
				})

				local Fill = new("Frame", {
					Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = Track,
				})

				local Knob = new("Frame", {
					Size = UDim2.new(0, 12, 0, 12),
					Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
					BackgroundColor3 = Theme.Text,
					BorderSizePixel = 0,
					Parent = Track,
				})

				local dragging = false

				local function setFromAlpha(alpha)
					alpha = math.clamp(alpha, 0, 1)
					local raw = min + (max - min) * alpha
					local steps = math.floor((raw - min) / step + 0.5)
					value = min + steps * step
					value = math.clamp(value, min, max)
					local realAlpha = (value - min) / (max - min)
					Fill.Size = UDim2.new(realAlpha, 0, 1, 0)
					Knob.Position = UDim2.new(realAlpha, -6, 0.5, -6)
					ValueLabel.Text = step < 1 and string.format("%.2f", value) or tostring(value)
					callback(value)
				end

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
						setFromAlpha(alpha)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
						setFromAlpha(alpha)
					end
				end)

				registerAccentRefresher(function() Fill.BackgroundColor3 = Theme.Accent end)

				local handle = {
					Set = function(_, v)
						setFromAlpha((v - min) / (max - min))
					end,
					Get = function() return value end,
				}
				if flag then Window.Flags[flag] = handle end
				return handle
			end

			function Section:CreateDropdown(text, options, callback, flag)
				callback = callback or function() end
				options = options or {}
				local selected = options[1]
				local open = false

				local Row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = nextOrder(),
					ZIndex = 5,
					Parent = SectionFrame,
				})

				new("TextLabel", {
					Size = UDim2.new(1, -148, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local Box = new("TextButton", {
					Size = UDim2.new(0, 140, 0, 28),
					Position = UDim2.new(1, -140, 0.5, -14),
					BackgroundColor3 = Theme.Element,
					Text = "  " .. tostring(selected),
					TextColor3 = Theme.Text,
					TextSize = 13,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 6,
					Parent = Row,
				})

				local ListHolder = new("Frame", {
					Size = UDim2.new(0, 140, 0, 0),
					Position = UDim2.new(1, -140, 1, 2),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 10,
					Parent = Box,
				})
				new("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = ListHolder,
				})

				for i, opt in ipairs(options) do
					local OptBtn = new("TextButton", {
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundColor3 = Theme.Element,
						BackgroundTransparency = 0,
						Text = "  " .. tostring(opt),
						TextColor3 = Theme.TextDim,
						TextSize = 13,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false,
						ZIndex = 11,
						Parent = ListHolder,
					})
					OptBtn.MouseEnter:Connect(function()
						tween(OptBtn, { TextColor3 = Theme.Text }, 0.1)
					end)
					OptBtn.MouseLeave:Connect(function()
						tween(OptBtn, { TextColor3 = Theme.TextDim }, 0.1)
					end)
					OptBtn.MouseButton1Click:Connect(function()
						selected = opt
						Box.Text = "  " .. tostring(opt)
						open = false
						tween(ListHolder, { Size = UDim2.new(0, 140, 0, 0) }, 0.12)
						callback(opt)
					end)
				end

				local function closeDropdown()
					if open then
						open = false
						tween(ListHolder, { Size = UDim2.new(0, 140, 0, 0) }, 0.12)
					end
				end

				Box.MouseButton1Click:Connect(function()
					open = not open
					local h = open and math.min(#options * 26, 130) or 0
					tween(ListHolder, { Size = UDim2.new(0, 140, 0, h) }, 0.12)
				end)

				-- Close when clicking anywhere outside the box/list
				UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if not open then return end
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					local pos = input.Position
					local boxPos, boxSize = Box.AbsolutePosition, Box.AbsoluteSize
					local listPos, listSize = ListHolder.AbsolutePosition, ListHolder.AbsoluteSize
					local inBox = pos.X >= boxPos.X and pos.X <= boxPos.X + boxSize.X
						and pos.Y >= boxPos.Y and pos.Y <= boxPos.Y + boxSize.Y
					local inList = pos.X >= listPos.X and pos.X <= listPos.X + listSize.X
						and pos.Y >= listPos.Y and pos.Y <= listPos.Y + listSize.Y
					if not inBox and not inList then
						closeDropdown()
					end
				end)

				local handle = {
					Set = function(_, v)
						selected = v
						Box.Text = "  " .. tostring(v)
						callback(v)
					end,
					Get = function() return selected end,
				}
				if flag then Window.Flags[flag] = handle end
				return handle
			end

			function Section:CreateButton(text, callback)
				callback = callback or function() end

				local Btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = Theme.Accent,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.GothamBold,
					AutoButtonColor = false,
					LayoutOrder = nextOrder(),
					Parent = SectionFrame,
				})

				Btn.MouseEnter:Connect(function()
					tween(Btn, { BackgroundColor3 = Color3.new(
						math.min(Theme.Accent.R + 0.08, 1),
						math.min(Theme.Accent.G + 0.08, 1),
						math.min(Theme.Accent.B + 0.08, 1)
					) }, 0.1)
				end)
				Btn.MouseLeave:Connect(function()
					tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
				end)
				Btn.MouseButton1Click:Connect(function()
					callback()
				end)

				registerAccentRefresher(function() Btn.BackgroundColor3 = Theme.Accent end)

				return Btn
			end

			function Section:CreateKeybind(text, default, callback, flag)
				callback = callback or function() end
				local bindingKey = default or Enum.KeyCode.Unknown
				local listening = false

				local Row = new("Frame", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					LayoutOrder = nextOrder(),
					Parent = SectionFrame,
				})

				new("TextLabel", {
					Size = UDim2.new(1, -70, 1, 0),
					BackgroundTransparency = 1,
					Text = text,
					TextColor3 = Theme.Text,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = Row,
				})

				local KeyBox = new("TextButton", {
					Size = UDim2.new(0, 60, 0, 26),
					Position = UDim2.new(1, -60, 0, 0),
					BackgroundColor3 = Theme.Element,
					Text = bindingKey.Name,
					TextColor3 = Theme.Text,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextXAlignment = Enum.TextXAlignment.Center,
					AutoButtonColor = false,
					Parent = Row,
				})

				KeyBox.MouseButton1Click:Connect(function()
					listening = true
					KeyBox.Text = "..."
				end)

				UserInputService.InputBegan:Connect(function(input, gpe)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						bindingKey = input.KeyCode
						KeyBox.Text = bindingKey.Name
						listening = false
						callback(bindingKey)
					elseif not gpe and input.KeyCode == bindingKey and not listening then
						callback(bindingKey)
					end
				end)

				local handle = {
					Set = function(_, key)
						-- accepts either an Enum.KeyCode or its name as a string (config files store strings)
						bindingKey = typeof(key) == "string" and Enum.KeyCode[key] or key
						KeyBox.Text = bindingKey.Name
					end,
					Get = function() return bindingKey.Name end, -- string so it's JSON-safe for SaveConfig
				}
				if flag then Window.Flags[flag] = handle end
				return handle
			end

			return Section
		end

		return Tab
	end

	Window.Gui = ScreenGui
	Window.Frame = MainFrame
	return Window
end

return UI

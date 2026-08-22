-- ╔══════════════════════════════════════════════════╗
-- ║           COMET SS  ·  UI LIBRARY v3.1           ║
-- ║     Explicit layout · No AutomaticSize drift     ║
-- ║       Removed loadstring dependency for init     ║
-- ╚══════════════════════════════════════════════════╝

local CometLib = {}
CometLib.__index = CometLib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

local Icons = {
    Settings  = "rbxassetid://14007344336",
    Close     = "rbxassetid://10747384394",
    Minimize  = "rbxassetid://10734896206",
    Check     = "rbxassetid://10709790644",
    ChevronD  = "rbxassetid://10709790948",
    Circle    = "rbxassetid://10709798174",
    Shield    = "rbxassetid://10734951847",
    Eye       = "rbxassetid://10723346959",
    Gamepad   = "rbxassetid://10723395457",
    Sliders   = "rbxassetid://10734963400",
    Globe     = "rbxassetid://10709761530",
    Bell      = "rbxassetid://10709775704",
    Palette   = "rbxassetid://10734910430",
    Image     = "rbxassetid://10723415040",
    Monitor   = "rbxassetid://10734896881",
    Keyboard  = "rbxassetid://10723416765",
    User      = "rbxassetid://10747373176",
    Home      = "rbxassetid://10723407389",
    Zap       = "rbxassetid://10723345749",
    Star      = "rbxassetid://10734966248",
    Trash     = "rbxassetid://10747362393",
}

local Themes = {
    Comet   = { Accent="#6C63FF", BG="#111320", Panel="#181B2E", Card="#1E2238", Border="#2A2E4A", Text="#E2E8F0", Sub="#64748B" },
    Crimson = { Accent="#FF4A4A", BG="#0F1015", Panel="#18121A", Card="#20161E", Border="#3A202A", Text="#E2E8F0", Sub="#64748B" },
    Neon    = { Accent="#00FFCC", BG="#080D10", Panel="#0D1318", Card="#111920", Border="#1A3030", Text="#E2E8F0", Sub="#64748B" },
    Gold    = { Accent="#F59E0B", BG="#111008", Panel="#1A180D", Card="#201E12", Border="#38320E", Text="#E2E8F0", Sub="#64748B" },
    Ice     = { Accent="#38BDF8", BG="#080C12", Panel="#0D1218", Card="#111820", Border="#1A2A38", Text="#E2E8F0", Sub="#64748B" },
    Grape   = { Accent="#C084FC", BG="#0D0812", Panel="#150D1E", Card="#1C1028", Border="#30185A", Text="#E2E8F0", Sub="#64748B" },
    Matrix  = { Accent="#4ADE80", BG="#060D08", Panel="#0D1810", Card="#111E14", Border="#183020", Text="#E2E8F0", Sub="#64748B" },
    Mono    = { Accent="#CBD5E1", BG="#0F0F0F", Panel="#161616", Card="#1E1E1E", Border="#2E2E2E", Text="#E2E8F0", Sub="#64748B" },
}

local function H(hex) return Color3.fromHex(hex) end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function New(cls, props, children)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(children or {}) do c.Parent=o end
    return o
end

local function Corner(r) return New("UICorner",{CornerRadius=UDim.new(0,r or 8)}) end
local function Stroke(col, thick, trans) return New("UIStroke",{Color=H(col),Thickness=thick or 1,Transparency=trans or 0}) end
local function Pad(t,b,l,r) return New("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)}) end
local function ListV(gap) return New("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center}) end
local function ListH(gap) return New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,gap or 0),SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center}) end

local function MakeDraggable(handle, frame)
    local drag, start, startPos = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; start=i.Position; startPos=frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-start
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

local function Img(icon, size, parent, pos)
    return New("ImageLabel",{
        Image=icon, Size=UDim2.new(0,size,0,size),
        BackgroundTransparency=1, ImageColor3=Color3.new(1,1,1),
        ZIndex=20, Position=pos or UDim2.new(0,0,0,0),
        Parent=parent,
    })
end

local function Toast(gui, msg, theme)
    local existing = gui:FindFirstChild("__CometToast")
    if existing then existing:Destroy() end

    local frame = New("Frame",{
        Name="__CometToast",
        Size=UDim2.new(0,260,0,38),
        Position=UDim2.new(0.5,-130,1,10),
        BackgroundColor3=H(theme.Panel),
        ZIndex=200, Parent=gui,
    },{Corner(8), Stroke(theme.Accent,1,0.3), Pad(0,0,14,14)})

    New("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,0,0.5,-3),
        BackgroundColor3=H(theme.Accent),ZIndex=201,Parent=frame},{Corner(99)})

    New("TextLabel",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1,Text=msg,TextColor3=H(theme.Text),
        TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=201,Parent=frame})

    Tween(frame,{Position=UDim2.new(0.5,-130,1,-52)},0.25)
    task.delay(2.5,function()
        if frame and frame.Parent then
            Tween(frame,{Position=UDim2.new(0.5,-130,1,10)},0.2)
            task.delay(0.25,function() if frame and frame.Parent then frame:Destroy() end end)
        end
    end)
end

local W = 580
local H_ = 420
local TB = 38
local TAB = 34
local SB = 22
local CONTENT_H = H_ - TB - TAB - SB

function CometLib.new(opts)
    opts = opts or {}
    local self = setmetatable({}, CometLib)

    local themeName = opts.Theme or "Comet"
    self._themeName = themeName
    self._theme = Themes[themeName] or Themes.Comet
    local T = self._theme

    self._tabs      = {}
    self._tabBtns   = {}
    self._tabPanes  = {}
    self._activeTab = nil
    self.Visible    = true
    self.ToggleKey  = opts.ToggleKey or Enum.KeyCode.RightShift

    local gui = New("ScreenGui",{
        Name="CometUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    })
    
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self._gui = gui

    self._bgImg = New("ImageLabel",{
        Name="CometBG", Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, ScaleType=Enum.ScaleType.Crop,
        ImageTransparency=1, ZIndex=1, Visible=false, Parent=gui,
    })
    self._blur = New("BlurEffect",{Size=0,Parent=game:GetService("Lighting")})

    local win = New("Frame",{
        Name="CometWindow",
        Size=UDim2.new(0,W,0,H_),
        Position=UDim2.new(0.5,-W/2,0.5,-H_/2),
        BackgroundColor3=H(T.BG),
        BackgroundTransparency=0.06,
        ZIndex=10, Parent=gui,
        ClipsDescendants=true,
    },{Corner(12)})
    Stroke(T.Accent,1,0.55).Parent=win
    self._win = win

    local titlebar = New("Frame",{
        Size=UDim2.new(1,0,0,TB),
        Position=UDim2.new(0,0,0,0),
        BackgroundColor3=H(T.Panel),
        BackgroundTransparency=0.05,
        ZIndex=11, Parent=win,
    })
    New("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,1,-8),
        BackgroundColor3=H(T.Panel),BackgroundTransparency=0.05,ZIndex=11,Parent=titlebar})
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=H(T.Border),BackgroundTransparency=0.4,ZIndex=12,Parent=titlebar})

    MakeDraggable(titlebar, win)

    local logo = New("Frame",{
        Size=UDim2.new(0,20,0,20),
        Position=UDim2.new(0,12,0.5,-10),
        BackgroundColor3=H(T.Accent),ZIndex=12,Parent=titlebar,
    },{Corner(6)})
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="C",TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=13,Parent=logo})

    New("TextLabel",{
        Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,40,0,0),
        BackgroundTransparency=1, Text=opts.Title or "Comet SS",
        TextColor3=H(T.Text), TextSize=13, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12, Parent=titlebar,
    })
    New("TextLabel",{
        Size=UDim2.new(0,120,1,0), Position=UDim2.new(0,140,0,0),
        BackgroundTransparency=1, Text=opts.Subtitle or "Executor",
        TextColor3=H(T.Accent), TextSize=11, Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12, Parent=titlebar,
    })

    local minBtn = New("TextButton",{
        Size=UDim2.new(0,26,0,22),
        Position=UDim2.new(1,-62,0.5,-11),
        BackgroundColor3=H(T.Card),
        BackgroundTransparency=0.2,
        Text="", ZIndex=12, Parent=titlebar,
    },{Corner(6)})
    Img(Icons.Minimize,12,minBtn,UDim2.new(0.5,-6,0.5,-6))
    self._minBtn = minBtn

    local closeBtn = New("TextButton",{
        Size=UDim2.new(0,26,0,22),
        Position=UDim2.new(1,-32,0.5,-11),
        BackgroundColor3=H("#2A1414"),
        BackgroundTransparency=0.2,
        Text="", ZIndex=12, Parent=titlebar,
    },{Corner(6)})
    Img(Icons.Close,12,closeBtn,UDim2.new(0.5,-6,0.5,-6))
    self._closeBtn = closeBtn

    minBtn.MouseEnter:Connect(function() Tween(minBtn,{BackgroundColor3=H("#F59E0B"),BackgroundTransparency=0}) end)
    minBtn.MouseLeave:Connect(function() Tween(minBtn,{BackgroundColor3=H(T.Card),BackgroundTransparency=0.2}) end)
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn,{BackgroundColor3=H("#F87171"),BackgroundTransparency=0}) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn,{BackgroundColor3=H("#2A1414"),BackgroundTransparency=0.2}) end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(win,{Size=minimized and UDim2.new(0,W,0,TB) or UDim2.new(0,W,0,H_)},0.22)
        Toast(gui, minimized and "Minimized" or "Restored", T)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        self.Visible = false
        Tween(win,{BackgroundTransparency=1,Size=UDim2.new(0,W,0,0)},0.18)
        task.delay(0.2,function() win.Visible=false end)
        Toast(gui,"Closed · press "..self.ToggleKey.Name.." to reopen",T)
    end)

    local tabBar = New("Frame",{
        Size=UDim2.new(1,0,0,TAB),
        Position=UDim2.new(0,0,0,TB),
        BackgroundColor3=H(T.Panel),
        BackgroundTransparency=0.15,
        ZIndex=11, Parent=win,
    })
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=H(T.Border),BackgroundTransparency=0.3,ZIndex=12,Parent=tabBar})
    New("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,0,0),
        BackgroundColor3=H(T.Panel),BackgroundTransparency=0.15,ZIndex=11,Parent=tabBar})

    local tabScroll = New("ScrollingFrame",{
        Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,4,0,0),
        BackgroundTransparency=1, ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=12, Parent=tabBar,
        ScrollingDirection=Enum.ScrollingDirection.X,
    })
    New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,2),
        VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=tabScroll})
    self._tabScroll = tabScroll

    local content = New("Frame",{
        Size=UDim2.new(1,0,0,CONTENT_H),
        Position=UDim2.new(0,0,0,TB+TAB),
        BackgroundTransparency=1,
        ZIndex=11, Parent=win,
        ClipsDescendants=true,
    })
    self._content = content

    local sb = New("Frame",{
        Size=UDim2.new(1,0,0,SB),
        Position=UDim2.new(0,0,1,-SB),
        BackgroundColor3=H(T.Panel),
        BackgroundTransparency=0.1,
        ZIndex=11, Parent=win,
    })
    New("Frame",{Size=UDim2.new(1,0,0,8),BackgroundColor3=H(T.Panel),
        BackgroundTransparency=0.1,ZIndex=11,Parent=sb})
    New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=H(T.Border),
        BackgroundTransparency=0.4,ZIndex=12,Parent=sb})
    New("Frame",{Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,10,0.5,-3),
        BackgroundColor3=H("#4ADE80"),ZIndex=13,Parent=sb},{Corner(99)})
    self._statusLabel = New("TextLabel",{
        Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,22,0,0),
        BackgroundTransparency=1, Text="Attached  ·  Comet SS v3.1  ·  Theme: "..themeName,
        TextColor3=H(T.Sub), TextSize=10, Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13, Parent=sb,
    })

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.ToggleKey then
            self.Visible = not self.Visible
            win.Visible = self.Visible
            if self.Visible then
                win.BackgroundTransparency = 0.06
                Tween(win,{Size=UDim2.new(0,W,0,H_)},0.2)
                minimized = false
            end
        end
    end)

    return self
end

local TAB_W = 88

function CometLib:AddTab(name, iconId)
    local T   = self._theme
    local idx = #self._tabs + 1

    local btn = New("TextButton",{
        Name=name.."_Tab",
        Size=UDim2.new(0,TAB_W,0,TAB-6),
        BackgroundColor3=H(T.Panel),
        BackgroundTransparency=1,
        Text="", ZIndex=13,
        LayoutOrder=idx,
        Parent=self._tabScroll,
    },{Corner(6)})

    if iconId then
        New("ImageLabel",{
            Image=(type(iconId)=="number") and ("rbxassetid://"..iconId) or iconId,
            Size=UDim2.new(0,12,0,12),
            Position=UDim2.new(0,8,0.5,-6),
            BackgroundTransparency=1,
            ImageColor3=H(T.Sub),
            ZIndex=14, Parent=btn,
        })
    end

    local lx = iconId and 26 or 10
    local lw = iconId and (TAB_W - lx - 4) or (TAB_W - 20)
    local lbl = New("TextLabel",{
        Size=UDim2.new(0,lw,1,0),
        Position=UDim2.new(0,lx,0,0),
        BackgroundTransparency=1,
        Text=name, TextColor3=H(T.Sub),
        TextSize=11, Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=14, Parent=btn,
    })

    local uline = New("Frame",{
        Size=UDim2.new(1,-10,0,2),
        Position=UDim2.new(0,5,1,-2),
        BackgroundColor3=H(T.Accent),
        BackgroundTransparency=1,
        ZIndex=14, Parent=btn,
    },{Corner(2)})

    local pane = New("ScrollingFrame",{
        Name=name.."_Pane",
        Size=UDim2.new(1,0,1,-SB),
        Position=UDim2.new(0,0,0,0),
        BackgroundTransparency=1,
        ZIndex=12,
        ScrollBarThickness=3,
        ScrollBarImageColor3=H(T.Accent),
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=false,
        Parent=self._content,
    })
    New("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,5),
        SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Parent=pane})
    New("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),Parent=pane})

    New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,Parent=self._tabScroll})

    btn.MouseButton1Click:Connect(function() self:_select(name) end)
    btn.MouseEnter:Connect(function()
        if self._activeTab ~= name then
            Tween(btn,{BackgroundTransparency=0.7,BackgroundColor3=H(T.Card)})
            Tween(lbl,{TextColor3=H(T.Text)})
        end
    end)
    btn.MouseLeave:Connect(function()
        if self._activeTab ~= name then
            Tween(btn,{BackgroundTransparency=1})
            Tween(lbl,{TextColor3=H(T.Sub)})
        end
    end)

    self._tabBtns[name]  = {btn=btn, lbl=lbl, uline=uline, iconId=iconId}
    self._tabPanes[name] = pane
    table.insert(self._tabs, name)

    if #self._tabs == 1 then self:_select(name) end

    return self:_tabAPI(pane)
end

function CometLib:_select(name)
    self._activeTab = name
    local T = self._theme
    for n, d in pairs(self._tabBtns) do
        local active = n == name
        Tween(d.btn, {BackgroundColor3=active and H(T.Accent) or H(T.Panel), BackgroundTransparency=active and 0.75 or 1})
        Tween(d.lbl, {TextColor3=active and H(T.Accent) or H(T.Sub)})
        Tween(d.uline, {BackgroundTransparency=active and 0 or 1})
    end
    for n, p in pairs(self._tabPanes) do p.Visible = n==name end
end

local ELEM_H = 38
local ELEM_W = W - 28

function CometLib:_tabAPI(pane)
    local api  = {}
    local T    = self._theme
    local self_ = self

    local function ElemBase(h)
        return New("Frame",{
            Size=UDim2.new(1,0,0,h or ELEM_H),
            BackgroundColor3=H(T.Card),
            BackgroundTransparency=0.25,
            ZIndex=15, Parent=pane,
        },{Corner(8), Stroke(T.Border,1,0.5)})
    end

    function api:AddSection(text)
        New("TextLabel",{
            Size=UDim2.new(1,0,0,18),
            BackgroundTransparency=1,
            Text=text:upper(),
            TextColor3=H(T.Sub),TextSize=10,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=15,Parent=pane,
        })
        return api
    end

    function api:AddButton(label, desc, callback)
        local row = New("TextButton",{
            Size=UDim2.new(1,0,0,ELEM_H),
            BackgroundColor3=H(T.Card),
            BackgroundTransparency=0.25,
            Text="", ZIndex=15, Parent=pane,
        },{Corner(8), Stroke(T.Border,1,0.5)})

        New("TextLabel",{
            Size=UDim2.new(0,260,0,18),Position=UDim2.new(0,12,0,6),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        if desc then
            New("TextLabel",{
                Size=UDim2.new(0,260,0,14),Position=UDim2.new(0,12,0,22),
                BackgroundTransparency=1,Text=desc,
                TextColor3=H(T.Sub),TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
            })
        end

        local badge = New("Frame",{
            Size=UDim2.new(0,70,0,22),
            Position=UDim2.new(1,-80,0.5,-11),
            BackgroundColor3=H(T.Accent),
            BackgroundTransparency=0.15,
            ZIndex=16, Parent=row,
        },{Corner(6)})
        New("TextLabel",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="Execute",TextColor3=Color3.new(1,1,1),
            TextSize=10,Font=Enum.Font.GothamBold,ZIndex=17,Parent=badge,
        })

        row.MouseEnter:Connect(function() Tween(row,{BackgroundTransparency=0.05}) end)
        row.MouseLeave:Connect(function() Tween(row,{BackgroundTransparency=0.25}) end)
        row.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
        return api
    end

    function api:AddToggle(label, desc, default, callback)
        local val = default or false
        local row = ElemBase()

        New("TextLabel",{
            Size=UDim2.new(0,310,0,18),Position=UDim2.new(0,12,0,6),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        if desc then
            New("TextLabel",{
                Size=UDim2.new(0,310,0,14),Position=UDim2.new(0,12,0,22),
                BackgroundTransparency=1,Text=desc,
                TextColor3=H(T.Sub),TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
            })
        end

        local track = New("TextButton",{
            Size=UDim2.new(0,36,0,19),
            Position=UDim2.new(1,-46,0.5,-9.5),
            BackgroundColor3=val and H(T.Accent) or H(T.Border),
            Text="", ZIndex=16, Parent=row,
        },{Corner(99)})
        local thumb = New("Frame",{
            Size=UDim2.new(0,13,0,13),
            Position=UDim2.new(0,val and 20 or 2,0.5,-6.5),
            BackgroundColor3=Color3.new(1,1,1),
            ZIndex=17, Parent=track,
        },{Corner(99)})

        local function set(v)
            val=v
            Tween(track,{BackgroundColor3=v and H(T.Accent) or H(T.Border)})
            Tween(thumb,{Position=UDim2.new(0,v and 20 or 2,0.5,-6.5)})
            if callback then callback(v) end
        end

        track.MouseButton1Click:Connect(function() set(not val) end)
        return {Set=set, Get=function() return val end}
    end

    function api:AddSlider(label, desc, min_, max_, default, callback)
        local val = default or min_
        local row = ElemBase(48)

        New("TextLabel",{
            Size=UDim2.new(0,300,0,16),Position=UDim2.new(0,12,0,7),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        local valLbl = New("TextLabel",{
            Size=UDim2.new(0,60,0,16),Position=UDim2.new(1,-72,0,7),
            BackgroundTransparency=1,Text=tostring(val),
            TextColor3=H(T.Accent),TextSize=11,Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Right,ZIndex=16,Parent=row,
        })
        if desc then
            New("TextLabel",{
                Size=UDim2.new(0,300,0,12),Position=UDim2.new(0,12,0,22),
                BackgroundTransparency=1,Text=desc,
                TextColor3=H(T.Sub),TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
            })
        end

        local trackW = ELEM_W - 24
        local trackBg = New("Frame",{
            Size=UDim2.new(0,trackW,0,4),
            Position=UDim2.new(0,12,1,-12),
            BackgroundColor3=H(T.Border),ZIndex=16,Parent=row,
        },{Corner(99)})
        local fill = New("Frame",{
            Size=UDim2.new((val-min_)/(max_-min_),0,1,0),
            BackgroundColor3=H(T.Accent),ZIndex=17,Parent=trackBg,
        },{Corner(99)})
        local thumb = New("TextButton",{
            Size=UDim2.new(0,13,0,13),
            Position=UDim2.new((val-min_)/(max_-min_),-6.5,0.5,-6.5),
            BackgroundColor3=Color3.new(1,1,1),
            Text="",ZIndex=18,Parent=trackBg,
        },{Corner(99)})

        local drag=false
        thumb.MouseButton1Down:Connect(function() drag=true end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
        end)
        RunService.RenderStepped:Connect(function()
            if drag then
                local rel=math.clamp((Mouse.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
                val=math.round(min_+(max_-min_)*rel)
                fill.Size=UDim2.new(rel,0,1,0)
                thumb.Position=UDim2.new(rel,-6.5,0.5,-6.5)
                valLbl.Text=tostring(val)
                if callback then callback(val) end
            end
        end)
        return {Get=function() return val end}
    end

    function api:AddDropdown(label, desc, options, default, callback)
        local sel   = default or options[1]
        local open  = false

        local wrap = New("Frame",{
            Size=UDim2.new(1,0,0,ELEM_H),
            BackgroundTransparency=1, ZIndex=15,
            ClipsDescendants=false, Parent=pane,
        })

        local row = New("TextButton",{
            Size=UDim2.new(1,0,0,ELEM_H),
            BackgroundColor3=H(T.Card),
            BackgroundTransparency=0.25,
            Text="",ZIndex=15,Parent=wrap,
        },{Corner(8), Stroke(T.Border,1,0.5)})

        New("TextLabel",{
            Size=UDim2.new(0,220,0,18),Position=UDim2.new(0,12,0,6),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        if desc then
            New("TextLabel",{
                Size=UDim2.new(0,220,0,14),Position=UDim2.new(0,12,0,22),
                BackgroundTransparency=1,Text=desc,
                TextColor3=H(T.Sub),TextSize=10,Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
            })
        end

        local selBox = New("Frame",{
            Size=UDim2.new(0,130,0,24),
            Position=UDim2.new(1,-140,0.5,-12),
            BackgroundColor3=H(T.Border),
            BackgroundTransparency=0.3,
            ZIndex=16,Parent=row,
        },{Corner(6)})
        local selLbl = New("TextLabel",{
            Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1,Text=sel,
            TextColor3=H(T.Accent),TextSize=11,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17,Parent=selBox,
        })
        local arrow = New("TextLabel",{
            Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
            BackgroundTransparency=1,Text="▾",
            TextColor3=H(T.Sub),TextSize=11,Font=Enum.Font.GothamBold,
            ZIndex=17,Parent=selBox,
        })

        local listH = math.min(#options,6)*28+8
        local list = New("Frame",{
            Size=UDim2.new(1,0,0,listH),
            Position=UDim2.new(0,0,0,ELEM_H+3),
            BackgroundColor3=H(T.Panel),
            BackgroundTransparency=0.02,
            ZIndex=30,Visible=false,Parent=wrap,
        },{Corner(8), Stroke(T.Accent,1,0.4)})
        New("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,Padding=UDim.new(0,2),
            SortOrder=Enum.SortOrder.LayoutOrder,Parent=list})
        Pad(4,4,4,4).Parent=list

        for _, opt in ipairs(options) do
            local ob = New("TextButton",{
                Size=UDim2.new(1,0,0,26),
                BackgroundColor3=H(opt==sel and T.Accent or T.Card),
                BackgroundTransparency=opt==sel and 0.7 or 0.4,
                Text=opt,TextColor3=opt==sel and H(T.Accent) or H(T.Text),
                TextSize=11,Font=Enum.Font.GothamMedium,
                ZIndex=31,Parent=list,
            },{Corner(6)})
            ob.MouseEnter:Connect(function() if sel~=opt then Tween(ob,{BackgroundTransparency=0.15}) end end)
            ob.MouseLeave:Connect(function() if sel~=opt then Tween(ob,{BackgroundTransparency=0.4}) end end)
            ob.MouseButton1Click:Connect(function()
                sel=opt; selLbl.Text=opt; open=false; list.Visible=false
                Tween(arrow,{Rotation=0})
                for _,c in ipairs(list:GetChildren()) do
                    if c:IsA("TextButton") then
                        local a=c.Text==sel
                        Tween(c,{BackgroundColor3=H(a and T.Accent or T.Card),BackgroundTransparency=a and 0.7 or 0.4})
                        Tween(c,{TextColor3=H(a and T.Accent or T.Text)})
                    end
                end
                if callback then callback(sel) end
            end)
        end

        row.MouseButton1Click:Connect(function()
            open=not open; list.Visible=open
            Tween(arrow,{Rotation=open and 180 or 0})
            wrap.ZIndex=open and 40 or 15
        end)
        row.MouseEnter:Connect(function() Tween(row,{BackgroundTransparency=0.1}) end)
        row.MouseLeave:Connect(function() Tween(row,{BackgroundTransparency=0.25}) end)

        return {Get=function() return sel end}
    end

    function api:AddInput(label, desc, placeholder, callback)
        local row = ElemBase(48)
        New("TextLabel",{
            Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,12,0,7),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        local box = New("TextBox",{
            Size=UDim2.new(1,-24,0,20),Position=UDim2.new(0,12,1,-26),
            BackgroundColor3=H(T.BG),BackgroundTransparency=0.2,
            PlaceholderText=placeholder or "Type here...",
            PlaceholderColor3=H(T.Sub),
            Text="",TextColor3=H(T.Text),
            TextSize=11,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false,ZIndex=16,Parent=row,
        },{Corner(6), Pad(0,0,7,7)})
        box.Focused:Connect(function() Tween(box,{BackgroundTransparency=0.05}) end)
        box.FocusLost:Connect(function(enter)
            Tween(box,{BackgroundTransparency=0.2})
            if callback then callback(box.Text, enter) end
        end)
        return {Get=function() return box.Text end, Set=function(v) box.Text=v end}
    end

    function api:AddKeybind(label, desc, default, callback)
        local key=default or Enum.KeyCode.Unknown
        local listening=false
        local row = ElemBase()
        New("TextLabel",{
            Size=UDim2.new(0,300,0,18),Position=UDim2.new(0,12,0,10),
            BackgroundTransparency=1,Text=label,
            TextColor3=H(T.Text),TextSize=12,Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16,Parent=row,
        })
        local kb = New("TextButton",{
            Size=UDim2.new(0,84,0,22),Position=UDim2.new(1,-94,0.5,-11),
            BackgroundColor3=H(T.Border),BackgroundTransparency=0.2,
            Text=key.Name,TextColor3=H(T.Accent),
            TextSize=10,Font=Enum.Font.GothamBold,
            ZIndex=16,Parent=row,
        },{Corner(6)})
        kb.MouseButton1Click:Connect(function()
            listening=true; kb.Text="..."
            Tween(kb,{BackgroundColor3=H(T.Accent),TextColor3=Color3.new(1,1,1)})
        end)
        UserInputService.InputBegan:Connect(function(i, gpe)
            if listening and not gpe and i.UserInputType==Enum.UserInputType.Keyboard then
                listening=false; key=i.KeyCode; kb.Text=key.Name
                Tween(kb,{BackgroundColor3=H(T.Border),TextColor3=H(T.Accent)})
                if callback then callback(key) end
            end
        end)
        return {Get=function() return key end}
    end

    function api:AddLabel(text)
        New("TextLabel",{
            Size=UDim2.new(1,0,0,28),
            BackgroundColor3=H(T.Card),BackgroundTransparency=0.5,
            Text=text,TextColor3=H(T.Sub),TextSize=11,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=15,Parent=pane,
        },{Corner(7), Pad(0,0,12,12)})
        return api
    end

    function api:AddSeparator()
        New("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=H(T.Border),
            BackgroundTransparency=0.3,ZIndex=15,Parent=pane})
        return api
    end

    return api
end

function CometLib:AddSettingsTab()
    local T    = self._theme
    local stab = self:AddTab("Settings", Icons.Settings)

    stab:AddSection("Themes")
    local themeNames = {}
    for k in pairs(Themes) do table.insert(themeNames, k) end
    table.sort(themeNames)

    stab:AddDropdown("Color Theme","Pick a theme preset",themeNames,self._themeName,function(name)
        Toast(self._gui,"Theme '"..name.."' will apply on next load.\nSet Theme='"..name.."' in .new()",T)
        self._statusLabel.Text = "Theme: "..name.." (restart to apply)"
    end)

    stab:AddSection("Background Image")
    local bgInp = stab:AddInput("Asset ID or URL","rbxassetid://XXXXX or https://...","rbxassetid://10709752035",nil)
    stab:AddButton("Apply Background","Set window background image",function()
        local v = bgInp.Get()
        if v == "" then Toast(self._gui,"Paste an asset ID or URL first",T) return end
        local url = v:find("^http") and v or (v:find("^rbxassetid") and v or "rbxassetid://"..v)
        self._bgImg.Image = url
        self._bgImg.Visible = true
        Toast(self._gui,"Background applied",T)
    end)
    stab:AddSlider("Background Blur","Blur strength behind the UI",0,24,0,function(v)
        self._blur.Size = v
    end)
    stab:AddSlider("Image Transparency","Dim the background image",0,9,3,function(v)
        self._bgImg.ImageTransparency = v/10
    end)
    stab:AddButton("Remove Background",nil,function()
        self._bgImg.Visible=false
        self._blur.Size=0
        bgInp.Set("")
        Toast(self._gui,"Background removed",T)
    end)

    stab:AddSection("Window Controls")
    stab:AddToggle("Show Minimize Button",nil,true,function(v)
        self._minBtn.Visible=v
    end)
    stab:AddToggle("Show Close Button",nil,true,function(v)
        self._closeBtn.Visible=v
    end)
    stab:AddDropdown("Window Opacity",nil,{"100%","90%","80%","70%"},  "94%",function(v)
        local map={["100%"]=0,["90%"]=0.06,["80%"]=0.18,["70%"]=0.3}
        self._win.BackgroundTransparency = map[v] or 0.06
    end)

    stab:AddSection("Toggle Keybind")
    stab:AddKeybind("Open / Close","Press to rebind",self.ToggleKey,function(k)
        self.ToggleKey=k
        Toast(self._gui,"Toggle key set to "..k.Name,T)
    end)

    return stab
end

function CometLib:Notify(msg, duration)
    Toast(self._gui, msg, self._theme)
end

return CometLib

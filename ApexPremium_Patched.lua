-- ============================================================
-- PortalVisuals_Lib.lua  v3.1
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats            = game:GetService("Stats")
local CoreGui          = game:GetService("CoreGui")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

if _G._PortalVisualsLib and _G._PortalVisualsLib._cleanup then
    pcall(_G._PortalVisualsLib._cleanup)
end
_G._PortalVisualsLib = {}
local _lib = _G._PortalVisualsLib

local Themes = {
    Dark = {
        GlassBg  = Color3.fromRGB(20, 22, 28),   GlassLeft = Color3.fromRGB(25, 27, 35),
        GlassCard= Color3.fromRGB(35, 38, 48),   Accent    = Color3.fromRGB(0, 150, 255),
        Text     = Color3.fromRGB(240,245,255),  TextSoft  = Color3.fromRGB(180,190,210),
        TextMuted= Color3.fromRGB(120,130,150),  Online    = Color3.fromRGB(50,220,120),
        TrackOff = Color3.fromRGB(60, 65, 80),   TrackOn   = Color3.fromRGB(0, 150, 255),
        Stroke   = Color3.fromRGB(60, 65, 80),   Shine     = Color3.fromRGB(255,255,255),
        Stars    = false
    },
    Amethyst = {
        GlassBg  = Color3.fromRGB(20, 20, 20),   GlassLeft = Color3.fromRGB(30, 20, 45),
        GlassCard= Color3.fromRGB(40, 30, 65),   Accent    = Color3.fromRGB(97, 62, 167),
        Text     = Color3.fromRGB(240, 240, 240),TextSoft  = Color3.fromRGB(160, 140, 180),
        TextMuted= Color3.fromRGB(110, 90, 150),  Online    = Color3.fromRGB(120, 220, 140),
        TrackOff = Color3.fromRGB(55, 40, 80),   TrackOn   = Color3.fromRGB(97, 62, 167),
        Stroke   = Color3.fromRGB(60, 45, 90),   Shine     = Color3.fromRGB(200,180,255),
        Stars    = true, StarColor = Color3.fromRGB(255,200,255), StarCount = 60
    },
    Cosmos = {
        GlassBg  = Color3.fromRGB(6,8,20),      GlassLeft = Color3.fromRGB(10,12,28),
        GlassCard= Color3.fromRGB(18,22,45),    Accent    = Color3.fromRGB(140,200,255),
        Text     = Color3.fromRGB(220,235,255), TextSoft  = Color3.fromRGB(150,170,210),
        TextMuted= Color3.fromRGB(80,100,150),  Online    = Color3.fromRGB(80,230,160),
        TrackOff = Color3.fromRGB(35,40,70),    TrackOn   = Color3.fromRGB(140,200,255),
        Stroke   = Color3.fromRGB(40,55,100),   Shine     = Color3.fromRGB(200,220,255),
        Stars    = true, StarColor = Color3.fromRGB(200,220,255), StarCount = 80
    }
}

local LucideAssets = {
    ["settings"] = "rbxassetid://10734950309",
    ["image"] = "rbxassetid://10723415040",
    ["palette"] = "rbxassetid://10734910430",
    ["keyboard"] = "rbxassetid://10723416765",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["check"] = "rbxassetid://10709790644",
    ["x"] = "rbxassetid://10747384394",
    ["bell"] = "rbxassetid://10709775704",
    ["sword"] = "rbxassetid://10734975486",
    ["eye"] = "rbxassetid://10723346959",
    ["shield"] = "rbxassetid://10734951847",
    ["database"] = "rbxassetid://10709818996",
    ["power"] = "rbxassetid://10734930466"
}

local function Create(Class, Props)
    local obj = Instance.new(Class)
    for k, v in pairs(Props) do 
        if k ~= "Parent" then obj[k] = v end 
    end
    if Props.Parent then obj.Parent = Props.Parent end
    return obj
end

local function Tween(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(dur or 0.6, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end

local PortalVisuals = {}
PortalVisuals.__index = PortalVisuals
PortalVisuals.Themes  = Themes

function PortalVisuals.new(title, options)
    options = options or {}
    local self = setmetatable({}, PortalVisuals)

    self._theme     = Themes[options.theme or "Dark"] or Themes.Dark
    self._themeReg  = {}
    self._stars     = {}
    self._keybinds  = {} 
    self._tabs      = {}
    self._currentTab= nil
    self._isOpen    = true
    self._flags     = {}
    self._W         = (options.size and options.size[1]) or 720
    self._H         = (options.size and options.size[2]) or 560

    self._gui = Create("ScreenGui", {
        Name = "PortalVisuals_"..title, Parent = CoreGui,
        ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999, IgnoreGuiInset = true
    })

    self._blur = Create("BlurEffect", {Size = 0, Parent = Lighting})

    if options.watermark ~= false then self:_buildWatermark(title) end

    self:_buildNotifyLayer()
    self:_buildMainWindow(title, options.subtitle or "")

    local menuKey = options.menuKey or Enum.KeyCode.K
    self._menuKey  = menuKey
    self:Bind(menuKey, "$$menu$$", function() self:Toggle() end)

    self._inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local entry = self._keybinds[input.KeyCode]
        if entry then
            for _, cb in pairs(entry.callbacks) do 
                task.spawn(cb) 
            end
        end
    end)

    self._win.Visible = true
    self._win.Size = UDim2.new(0, self._W, 0, 0)
    Tween(self._blur, {Size = 20}, 1.2)
    Tween(self._win,  {Size = UDim2.new(0, self._W, 0, self._H)}, 1.2)

    task.delay(1.5, function() self:Notify("Portal Visuals", title.." initialized", 4) end)
    _lib._cleanup = function() self:Destroy() end
    return self
end

function PortalVisuals:Bind(key, id, fn)
    if not self._keybinds[key] then self._keybinds[key] = {callbacks={}} end
    self._keybinds[key].callbacks[id] = fn
end

function PortalVisuals:Unbind(key, id)
    local entry = self._keybinds[key]
    if entry then entry.callbacks[id] = nil end
end

function PortalVisuals:UnbindAll(key)
    self._keybinds[key] = nil
end

function PortalVisuals:_reg(obj, prop, key)
    table.insert(self._themeReg, {Object=obj, Property=prop, Key=key})
end

function PortalVisuals:_clearStars()
    for _, s in ipairs(self._stars) do if s and s.Parent then s:Destroy() end end
    table.clear(self._stars)
end

function PortalVisuals:_spawnStars(count, color)
    self:_clearStars()
    if not self._starContainer then return end
    for _ = 1, count do
        local star = Create("Frame", {
            Parent = self._starContainer,
            BackgroundColor3 = color, BorderSizePixel = 0,
            Size = UDim2.new(0,math.random(1,3),0,math.random(1,3)),
            Position = UDim2.new(math.random(0,100)/100,0,math.random(0,100)/100,0),
            BackgroundTransparency = math.random(20,70)/100, ZIndex = 3
        })
        Create("UICorner", {Parent=star, CornerRadius=UDim.new(1,0)})
        table.insert(self._stars, star)
        task.spawn(function()
            local base = star.BackgroundTransparency
            while star and star.Parent do
                Tween(star,{BackgroundTransparency=math.clamp(base+math.random(-30,30)/100,0.1,0.9)},math.random(15,35)/10,Enum.EasingStyle.Sine)
                task.wait(math.random(15,35)/10)
            end
        end)
    end
end

function PortalVisuals:SetTheme(name)
    local new = Themes[name]
    if not new then return end
    self._theme = new
    for _, e in ipairs(self._themeReg) do
        if e.Object and e.Object.Parent then
            Tween(e.Object, {[e.Property]=new[e.Key]}, 0.6)
        end
    end
    if new.Stars and new.StarCount and new.StarColor then
        task.delay(0.1, function() self:_spawnStars(new.StarCount, new.StarColor) end)
    else self:_clearStars() end
    self:Notify("Theme", name.." applied", 2)
end

function PortalVisuals:_buildWatermark(title)
    local T = self._theme
    local wmGui = Create("ScreenGui", {
        Name="PortalWM_"..title, Parent=CoreGui,
        ResetOnSpawn=false, IgnoreGuiInset=true,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=100000
    })
    self._wmGui = wmGui

    local card = Create("Frame", {
        Parent=wmGui, AnchorPoint=Vector2.new(0.5,0),
        Position=UDim2.new(0.5,0,0,4), Size=UDim2.new(0,300,0,32),
        BackgroundColor3=T.GlassBg, BackgroundTransparency=0.92,
        BorderSizePixel=0, ZIndex=100, ClipsDescendants=true
    })
    self:_reg(card,"BackgroundColor3","GlassBg")
    Create("UICorner",{Parent=card,CornerRadius=UDim.new(0,12)})
    local wStroke = Create("UIStroke",{Parent=card,Color=T.Stroke,Thickness=1,Transparency=0.6,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    self:_reg(wStroke,"Color","Stroke")

    local dot = Create("Frame",{Parent=card,BackgroundColor3=Color3.fromRGB(0,200,100),BorderSizePixel=0,Position=UDim2.new(0,10,0.5,-3),Size=UDim2.new(0,6,0,6),ZIndex=103})
    Create("UICorner",{Parent=dot,CornerRadius=UDim.new(1,0)})
    task.spawn(function()
        while dot and dot.Parent do
            Tween(dot,{BackgroundTransparency=0.5,Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,9,0.5,-4)},0.8,Enum.EasingStyle.Sine)
            task.wait(0.8)
            Tween(dot,{BackgroundTransparency=0,Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,10,0.5,-3)},0.8,Enum.EasingStyle.Sine)
            task.wait(0.8)
        end
    end)

    local logo = Create("TextLabel",{Parent=card,BackgroundTransparency=1,Position=UDim2.new(0,22,0,0),Size=UDim2.new(0,82,1,0),Font=Enum.Font.GothamBold,Text=title,TextColor3=T.Text,TextSize=12,TextTransparency=0.05,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=102})
    self:_reg(logo,"TextColor3","Text")
    local sep = Create("TextLabel",{Parent=card,BackgroundTransparency=1,Position=UDim2.new(0,104,0,0),Size=UDim2.new(0,10,1,0),Font=Enum.Font.GothamMedium,Text="|",TextColor3=T.TextMuted,TextSize=12,TextTransparency=0.3,ZIndex=102})
    self:_reg(sep,"TextColor3","TextMuted")
    local stats = Create("TextLabel",{Parent=card,BackgroundTransparency=1,Position=UDim2.new(0,114,0,0),Size=UDim2.new(1,-122,1,0),Font=Enum.Font.GothamMedium,Text="... ms | ... FPS",TextColor3=T.Text,TextSize=12,TextTransparency=0.1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=102})
    self:_reg(stats,"TextColor3","Text")

    task.spawn(function()
        local fps,frames,last=0,0,tick()
        while wmGui and wmGui.Parent do
            RunService.RenderStepped:Wait(); frames=frames+1
            local now=tick()
            if now-last>=1 then
                fps=frames; frames=0; last=now
                local ok,val=pcall(function() return Stats.PerformanceStats.Ping:GetValue() end)
                stats.Text=(ok and math.floor(val) or 0).." ms | "..fps.." FPS"
            end
        end
    end)
end

function PortalVisuals:_buildNotifyLayer()
    local notifyGui = Create("ScreenGui", {
        Name="PortalNotify", Parent=CoreGui,
        ResetOnSpawn=false, IgnoreGuiInset=true,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=99999
    })
    self._notifyGui    = notifyGui
    self._notifyCount  = 0

    local holder = Create("Frame", {
        Parent=notifyGui,
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-14,1,-14),
        Size=UDim2.new(0,320,1,-28),
        ClipsDescendants=true,
        ZIndex=200
    })
    self._notifyHolder = holder
    Create("UIListLayout",{
        Parent=holder, Padding=UDim.new(0,8),
        SortOrder=Enum.SortOrder.LayoutOrder,
        HorizontalAlignment=Enum.HorizontalAlignment.Right,
        VerticalAlignment=Enum.VerticalAlignment.Bottom,
        FillDirection=Enum.FillDirection.Vertical
    })
end

function PortalVisuals:Notify(title, body, duration)
    duration = duration or 3
    local T  = self._theme
    self._notifyCount = self._notifyCount + 1
    local PILL_H = 48

    local wrapper = Create("Frame",{
        Parent=self._notifyHolder, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,PILL_H), LayoutOrder=self._notifyCount,
        ClipsDescendants=true
    })

    local pill = Create("Frame",{
        Parent=wrapper, BackgroundColor3=T.GlassCard, BackgroundTransparency=0.06,
        BorderSizePixel=0, Size=UDim2.new(1,0,1,0),
        Position=UDim2.new(0,340,0,0), ClipsDescendants=true, ZIndex=210
    })
    Create("UICorner",{Parent=pill, CornerRadius=UDim.new(0,12)})
    Create("UIStroke",{Parent=pill, Color=T.Stroke, Thickness=1, Transparency=0.5, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})

    local stripe = Create("Frame",{Parent=pill,BackgroundColor3=T.Accent,BorderSizePixel=0,Position=UDim2.new(0,0,0,0),Size=UDim2.new(0,3,1,0),ZIndex=211})
    Create("UICorner",{Parent=stripe,CornerRadius=UDim.new(0,12)})
    self:_reg(stripe,"BackgroundColor3","Accent")

    local dot = Create("Frame",{Parent=pill,BackgroundColor3=T.Online,BorderSizePixel=0,Position=UDim2.new(0,13,0.5,-4),Size=UDim2.new(0,8,0,8),ZIndex=212})
    Create("UICorner",{Parent=dot,CornerRadius=UDim.new(1,0)})
    self:_reg(dot,"BackgroundColor3","Online")
    task.spawn(function()
        while dot and dot.Parent do
            Tween(dot,{BackgroundTransparency=0.5,Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,12,0.5,-5)},0.55,Enum.EasingStyle.Sine)
            task.wait(0.55)
            Tween(dot,{BackgroundTransparency=0,Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,13,0.5,-4)},0.55,Enum.EasingStyle.Sine)
            task.wait(0.55)
        end
    end)

    local titleLbl = Create("TextLabel",{Parent=pill,BackgroundTransparency=1,Position=UDim2.new(0,28,0,7),Size=UDim2.new(1,-54,0,16),Font=Enum.Font.GothamBold,Text=title,TextColor3=T.Text,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=212})
    local bodyLbl  = Create("TextLabel",{Parent=pill,BackgroundTransparency=1,Position=UDim2.new(0,28,0,25),Size=UDim2.new(1,-54,0,14),Font=Enum.Font.Gotham,Text=body,TextColor3=T.TextSoft,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=212})

    local closeBtn = Create("TextButton",{Parent=pill,BackgroundTransparency=1,Position=UDim2.new(1,-26,0,0),Size=UDim2.new(0,26,1,0),Font=Enum.Font.GothamBold,Text="×",TextColor3=T.TextMuted,TextSize=15,AutoButtonColor=false,ZIndex=213})

    local pgBg = Create("Frame",{Parent=pill,BackgroundColor3=T.TrackOff,BackgroundTransparency=0.5,BorderSizePixel=0,Position=UDim2.new(0,4,1,-3),Size=UDim2.new(1,-8,0,2),ZIndex=213})
    Create("UICorner",{Parent=pgBg,CornerRadius=UDim.new(1,0)})
    local pgFill = Create("Frame",{Parent=pgBg,BackgroundColor3=T.Accent,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),ZIndex=214})
    Create("UICorner",{Parent=pgFill,CornerRadius=UDim.new(1,0)})
    self:_reg(pgFill,"BackgroundColor3","Accent")

    Tween(pill,{Position=UDim2.new(0,0,0,0)},0.4,Enum.EasingStyle.Quint)
    Tween(pgFill,{Size=UDim2.new(0,0,1,0)},duration,Enum.EasingStyle.Linear)

    local dismissed = false
    local function dismiss()
        if dismissed then return end; dismissed = true
        Tween(pill,{Position=UDim2.new(0,340,0,0),BackgroundTransparency=1},0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        Tween(titleLbl,{TextTransparency=1},0.2)
        Tween(bodyLbl, {TextTransparency=1},0.2)
        task.delay(0.28,function()
            Tween(wrapper,{Size=UDim2.new(1,0,0,0)},0.25,Enum.EasingStyle.Quint)
            task.delay(0.28,function() if wrapper and wrapper.Parent then wrapper:Destroy() end end)
        end)
    end

    closeBtn.MouseButton1Click:Connect(dismiss)
    pill.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dismiss() end
    end)
    task.delay(duration, dismiss)
end

function PortalVisuals:_buildMainWindow(title, subtitle)
    local T = self._theme
    local W, H = self._W, self._H

    local win = Create("Frame", {
        Name = "PortalWin", Parent = self._gui,
        BackgroundColor3 = T.GlassBg, BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        Size = UDim2.new(0,W,0,H),
        Visible = false,
        ClipsDescendants = true, 
        ZIndex = 1
    })
    Create("UICorner",{Parent=win,CornerRadius=UDim.new(0,42)}) 
    local winStroke = Create("UIStroke",{Parent=win,Color=T.Stroke,Thickness=2,Transparency=0.5})
    self:_reg(winStroke,"Color","Stroke")
    self:_reg(win,"BackgroundColor3","GlassBg")
    self._win = win

    local bgImg = Create("ImageLabel",{
        Parent=win, BackgroundTransparency=1,
        Image="", ImageTransparency=1,
        ScaleType=Enum.ScaleType.Crop,
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        ZIndex=2
    })
    self._bgImg = bgImg

    local starContainer = Create("Frame",{
        Parent=win,BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,1,0),ZIndex=3,ClipsDescendants=false
    })
    self._starContainer = starContainer

    local inner = Create("Frame",{
        Parent=win,BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,1,0),ZIndex=4
    })

    local shine = Create("Frame",{
        Parent=inner,BackgroundColor3=T.Shine,BackgroundTransparency=0.92,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,0.45),ZIndex=5
    })
    Create("UIGradient",{Parent=shine,Rotation=90,Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(0.35,0.85),NumberSequenceKeypoint.new(1,1)
    })})

    local left = Create("Frame",{
        Parent=inner,BackgroundColor3=T.GlassLeft,BackgroundTransparency=0.88,
        BorderSizePixel=0,Size=UDim2.new(0,220,1,0),ZIndex=5
    })
    self:_reg(left,"BackgroundColor3","GlassLeft")
    
    local sep = Create("Frame",{
        Parent=left,BackgroundColor3=T.Stroke,BackgroundTransparency=0.3,
        BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),ZIndex=6
    })
    self:_reg(sep,"BackgroundColor3","Stroke")

    local titleLbl = Create("TextLabel",{
        Parent=left,BackgroundTransparency=1,
        Position=UDim2.new(0,24,0,28),Size=UDim2.new(1,-36,0,30),
        Font=Enum.Font.GothamBlack,Text=title,TextColor3=T.Text,
        TextSize=22,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7
    })
    self:_reg(titleLbl,"TextColor3","Text")

    local subLbl = Create("TextLabel",{
        Parent=left,BackgroundTransparency=1,
        Position=UDim2.new(0,24,0,56),Size=UDim2.new(1,-36,0,14),
        Font=Enum.Font.Gotham,Text=subtitle:upper(),TextColor3=T.TextMuted,
        TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7
    })
    self:_reg(subLbl,"TextColor3","TextMuted")

    local tabsHolder = Create("Frame",{
        Parent=left,BackgroundTransparency=1,
        Position=UDim2.new(0,14,0,88),Size=UDim2.new(1,-28,1,-190),ZIndex=7,
        ClipsDescendants=true
    })
    self._tabsHolder = tabsHolder
    Create("UIListLayout",{Parent=tabsHolder,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})

    self:_buildProfile(left)

    local contentArea = Create("Frame",{
        Parent=inner,BackgroundTransparency=1,
        Position=UDim2.new(0,220,0,0),Size=UDim2.new(1,-220,1,0),
        ClipsDescendants=true,ZIndex=5
    })
    self._contentArea = contentArea

    if T.Stars and T.StarCount and T.StarColor then
        task.delay(0.2,function() self:_spawnStars(T.StarCount,T.StarColor) end)
    end
end

function PortalVisuals:_buildProfile(parent)
    local T = self._theme
    local c = Create("Frame",{Parent=parent,BackgroundTransparency=1,Position=UDim2.new(0,14,1,-70),Size=UDim2.new(1,-28,0,56),ZIndex=7})

    local aBg = Create("Frame",{Parent=c,BackgroundColor3=T.GlassCard,BackgroundTransparency=0.55,Position=UDim2.new(0,0,0.5,-20),Size=UDim2.new(0,40,0,40),ZIndex=8})
    self:_reg(aBg,"BackgroundColor3","GlassCard")
    Create("UICorner",{Parent=aBg,CornerRadius=UDim.new(1,0)})
    local aStroke = Create("UIStroke",{Parent=aBg,Color=T.Stroke,Thickness=1.5,Transparency=0.5})
    self:_reg(aStroke,"Color","Stroke")
    local aImg = Create("ImageLabel",{Parent=aBg,BackgroundTransparency=1,Position=UDim2.new(0,2,0,2),Size=UDim2.new(1,-4,1,-4),Image="https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png",ZIndex=9})
    Create("UICorner",{Parent=aImg,CornerRadius=UDim.new(1,0)})

    local nLbl = Create("TextLabel",{Parent=c,BackgroundTransparency=1,Position=UDim2.new(0,50,0,6),Size=UDim2.new(1,-50,0,20),Font=Enum.Font.GothamBold,Text="@"..LocalPlayer.Name,TextColor3=T.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8})
    self:_reg(nLbl,"TextColor3","Text")

    local sRow = Create("Frame",{Parent=c,BackgroundTransparency=1,Position=UDim2.new(0,50,0,28),Size=UDim2.new(1,-50,0,14),ZIndex=8})
    local sDot = Create("Frame",{Parent=sRow,BackgroundColor3=T.Online,BorderSizePixel=0,Size=UDim2.new(0,6,0,6),Position=UDim2.new(0,0,0.5,-3),ZIndex=9})
    self:_reg(sDot,"BackgroundColor3","Online")
    Create("UICorner",{Parent=sDot,CornerRadius=UDim.new(1,0)})
    local sLbl = Create("TextLabel",{Parent=sRow,BackgroundTransparency=1,Position=UDim2.new(0,10,0,0),Size=UDim2.new(1,-10,1,0),Font=Enum.Font.Gotham,Text="Online",TextColor3=T.Online,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9})
    self:_reg(sLbl,"TextColor3","Online")
end

function PortalVisuals:Toggle()
    self._isOpen = not self._isOpen
    if self._isOpen then
        self._win.Visible = true
        Tween(self._blur,{Size=20},0.9)
        Tween(self._win, {Size=UDim2.new(0,self._W,0,self._H)},0.9)
    else
        Tween(self._blur,{Size=0},0.7)
        local t = Tween(self._win,{Size=UDim2.new(0,self._W,0,0)},0.7)
        t.Completed:Connect(function() if not self._isOpen then self._win.Visible=false end end)
    end
end

function PortalVisuals:SetBackground(raw)
    local s = tostring(raw):match("^%s*(.-)%s*$")
    local uri
    if s == "" then return self:ClearBackground() end
    if s:match("^rbxassetid://%d+$") then uri=s
    elseif s:match("^%d+$") then uri="rbxassetid://"..s
    else local id=s:match("(%d+)"); if id and #id>=6 then uri="rbxassetid://"..id end end
    if not uri then return self:ClearBackground() end

    self._bgImg.Image = uri
    self._bgImg.ImageTransparency = 1
    task.spawn(function()
        pcall(function() game:GetService("ContentProvider"):PreloadAsync({self._bgImg}) end)
        if self._bgImg and self._bgImg.Parent then
            Tween(self._bgImg,{ImageTransparency=0.3},0.5)
        end
    end)
end

function PortalVisuals:ClearBackground()
    Tween(self._bgImg,{ImageTransparency=1},0.4)
    task.delay(0.45,function() if self._bgImg and self._bgImg.Parent then self._bgImg.Image="" end end)
end

function PortalVisuals:SetMenuKey(keyCode)
    self:Unbind(self._menuKey,"$$menu$$")
    self._menuKey = keyCode
    self:Bind(keyCode,"$$menu$$",function() self:Toggle() end)
end

function PortalVisuals:Tab(name, iconId)
    local T = self._theme

    local page = Create("ScrollingFrame",{
        Parent=self._contentArea, Name=name.."Page",
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,1,0),CanvasSize=UDim2.new(0,0,0,0),
        ScrollBarThickness=3,ScrollBarImageColor3=T.Accent,
        ScrollBarImageTransparency=0.5,ScrollingDirection=Enum.ScrollingDirection.Y,
        Visible=false,ZIndex=6, ClipsDescendants=true
    })
    self:_reg(page,"ScrollBarImageColor3","Accent")
    local pageLayout = Create("UIListLayout",{Parent=page,Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
    Create("UIPadding",{Parent=page,PaddingLeft=UDim.new(0,18),PaddingRight=UDim.new(0,18),PaddingTop=UDim.new(0,18),PaddingBottom=UDim.new(0,18)})
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,pageLayout.AbsoluteContentSize.Y+36)
    end)

    local idx = #self._tabs
    local btn = Create("TextButton",{
        Parent=self._tabsHolder, Name=name,
        BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,40),Font=Enum.Font.GothamBold,
        Text="",TextColor3=T.TextSoft,TextSize=14,
        AutoButtonColor=false,LayoutOrder=idx,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=8, ClipsDescendants=true
    })
    self:_reg(btn,"TextColor3","TextSoft")

    local iconPadding = iconId and 28 or 0
    local btnText = Create("TextLabel", {
        Parent=btn, BackgroundTransparency=1, Size=UDim2.new(1, -iconPadding, 1, 0),
        Position=UDim2.new(0, iconPadding, 0, 0), Text=name, Font=Enum.Font.GothamBold,
        TextColor3=T.TextSoft, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=9
    })
    self:_reg(btnText, "TextColor3", "TextSoft")

    if iconId then
        local icon = Create("ImageLabel", {
            Parent=btn, BackgroundTransparency=1, Size=UDim2.new(0, 18, 0, 18),
            Position=UDim2.new(0, 8, 0.5, -9), Image=iconId, ImageColor3=T.TextSoft, ZIndex=9
        })
        self:_reg(icon, "ImageColor3", "TextSoft")
    end

    local ind = Create("Frame",{Parent=btn,BackgroundColor3=T.Accent,BorderSizePixel=0,Position=UDim2.new(0,-2,0.5,-5),Size=UDim2.new(0,4,0,10),BackgroundTransparency=1,ZIndex=9})
    self:_reg(ind,"BackgroundColor3","Accent")
    Create("UICorner",{Parent=ind,CornerRadius=UDim.new(1,0)})

    local hBg = Create("Frame",{Parent=btn,BackgroundColor3=T.GlassCard,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),ZIndex=7})
    Create("UICorner",{Parent=hBg,CornerRadius=UDim.new(0,10)})

    local tabData = {Name=name,Button=btn,Text=btnText,Indicator=ind,Page=page,HoverBg=hBg}
    table.insert(self._tabs,tabData)
    local win = self

    local function activate()
        if win._currentTab==name then return end
        for _,t in ipairs(win._tabs) do
            if t.Name==win._currentTab then
                Tween(t.Text,{TextColor3=win._theme.TextSoft},0.4)
                Tween(t.Indicator,{BackgroundTransparency=1},0.3)
                Tween(t.HoverBg,{BackgroundTransparency=1},0.3)
                t.Page.Visible=false
            end
        end
        win._currentTab=name
        Tween(btnText,{TextColor3=win._theme.Text},0.4)
        Tween(ind,{BackgroundTransparency=0},0.3)
        Tween(hBg,{BackgroundTransparency=0.88},0.3)
        page.CanvasPosition=Vector2.new(0,0)
        page.Visible=true
        page.Position=UDim2.new(0,24,0,0)
        Tween(page,{Position=UDim2.new(0,0,0,0)},0.4)
    end

    btn.MouseEnter:Connect(function() if win._currentTab~=name then Tween(btnText,{TextColor3=win._theme.Text},0.2,Enum.EasingStyle.Sine); Tween(hBg,{BackgroundTransparency=0.93},0.2,Enum.EasingStyle.Sine) end end)
    btn.MouseLeave:Connect(function() if win._currentTab~=name then Tween(btnText,{TextColor3=win._theme.TextSoft},0.2,Enum.EasingStyle.Sine); Tween(hBg,{BackgroundTransparency=1},0.2,Enum.EasingStyle.Sine) end end)
    btn.MouseButton1Click:Connect(activate)

    if #self._tabs==1 then
        win._currentTab=name
        btnText.TextColor3=T.Text; ind.BackgroundTransparency=0; hBg.BackgroundTransparency=0.88; page.Visible=true
    end

    local Tab={}; Tab._page=page; Tab._win=win
    function Tab:Section(sectionTitle) return win:_buildSection(page,sectionTitle) end
    return Tab
end

function PortalVisuals:_buildSection(parent, sectionTitle)
    local T = self._theme

    local section = Create("Frame",{
        Parent=parent,BackgroundColor3=T.GlassCard,BackgroundTransparency=0.75,
        BorderSizePixel=0,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        LayoutOrder=#parent:GetChildren()+1,ZIndex=7,ClipsDescendants=false
    })
    self:_reg(section,"BackgroundColor3","GlassCard")
    Create("UICorner",{Parent=section,CornerRadius=UDim.new(0,24)})
    local sStroke=Create("UIStroke",{Parent=section,Color=T.Stroke,Thickness=1,Transparency=0.55})
    self:_reg(sStroke,"Color","Stroke")

    local accentBar=Create("Frame",{Parent=section,BackgroundColor3=T.Accent,Position=UDim2.new(0,16,0,14),Size=UDim2.new(0,3,0,20),ZIndex=9})
    self:_reg(accentBar,"BackgroundColor3","Accent")
    Create("UICorner",{Parent=accentBar,CornerRadius=UDim.new(1,0)})

    Create("TextLabel",{Parent=section,BackgroundTransparency=1,Position=UDim2.new(0,30,0,0),Size=UDim2.new(1,-44,0,48),Font=Enum.Font.GothamBold,Text=sectionTitle,TextColor3=T.Text,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9})
    self:_reg(Create("Frame",{Parent=section,BackgroundColor3=T.Stroke,BackgroundTransparency=0.7,BorderSizePixel=0,Position=UDim2.new(0,16,0,46),Size=UDim2.new(1,-32,0,1),ZIndex=8}),"BackgroundColor3","Stroke")

    local content=Create("Frame",{Parent=section,BackgroundTransparency=1,Position=UDim2.new(0,14,0,52),Size=UDim2.new(1,-28,0,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=9,ClipsDescendants=false})
    Create("UIListLayout",{Parent=content,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    Create("UIPadding",{Parent=content,PaddingBottom=UDim.new(0,14)})

    local Sec={}; Sec._content=content; local win=self

    function Sec:Toggle(label,flagName,default,callback)
        local T2=win._theme
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),LayoutOrder=#content:GetChildren()+1})
        local lbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Size=UDim2.new(1,-58,1,0),Font=Enum.Font.Gotham,Text=label,TextColor3=T2.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
        win:_reg(lbl,"TextColor3","Text")
        local enabled=default or false; win._flags[flagName]=enabled

        local track=Create("Frame",{Parent=frame,BackgroundColor3=enabled and T2.TrackOn or T2.TrackOff,BorderSizePixel=0,Position=UDim2.new(1,-50,0.5,-12),Size=UDim2.new(0,48,0,24),ZIndex=10})
        Create("UICorner",{Parent=track,CornerRadius=UDim.new(1,0)})
        local thumb=Create("Frame",{Parent=track,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Position=enabled and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),Size=UDim2.new(0,20,0,20),ZIndex=11})
        Create("UICorner",{Parent=thumb,CornerRadius=UDim.new(1,0)})

        local debounce=false
        local function setEnabled(v)
            enabled=v; win._flags[flagName]=v
            Tween(track,{BackgroundColor3=v and win._theme.TrackOn or win._theme.TrackOff},0.4,Enum.EasingStyle.Quart)
            Tween(thumb,{Position=v and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)},0.4,Enum.EasingStyle.Quart)
            if callback then task.spawn(callback,v) end
        end

        local clickBtn=Create("TextButton",{Parent=frame,BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text="",ZIndex=12,AutoButtonColor=false})
        clickBtn.MouseButton1Click:Connect(function()
            if debounce then return end; debounce=true; setEnabled(not enabled); task.wait(0.4); debounce=false
        end)
        return {Set=setEnabled,Get=function() return enabled end}
    end

    function Sec:Slider(label,min,max,default,callback)
        local T2=win._theme
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,50),LayoutOrder=#content:GetChildren()+1})
        local lbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Position=UDim2.new(0,0,0,0),Size=UDim2.new(0.65,-4,0,20),Font=Enum.Font.Gotham,Text=label,TextColor3=T2.TextMuted,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
        win:_reg(lbl,"TextColor3","TextMuted")
        local valLbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Position=UDim2.new(0.65,0,0,0),Size=UDim2.new(0.35,0,0,20),Font=Enum.Font.GothamBold,Text=string.format("%.2f",default),TextColor3=T2.Text,TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=10})
        win:_reg(valLbl,"TextColor3","Text")

        local trackF=Create("Frame",{Parent=frame,BackgroundColor3=T2.TrackOff,BorderSizePixel=0,Position=UDim2.new(0,0,0,28),Size=UDim2.new(1,0,0,6),ZIndex=10})
        win:_reg(trackF,"BackgroundColor3","TrackOff")
        Create("UICorner",{Parent=trackF,CornerRadius=UDim.new(1,0)})
        local fillF=Create("Frame",{Parent=trackF,BackgroundColor3=T2.TrackOn,BorderSizePixel=0,Size=UDim2.new((default-min)/(max-min),0,1,0),ZIndex=11})
        win:_reg(fillF,"BackgroundColor3","TrackOn")
        Create("UICorner",{Parent=fillF,CornerRadius=UDim.new(1,0)})
        local thumbF=Create("Frame",{Parent=trackF,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Position=UDim2.new((default-min)/(max-min),-8,0.5,-8),Size=UDim2.new(0,16,0,16),ZIndex=12})
        Create("UICorner",{Parent=thumbF,CornerRadius=UDim.new(1,0)})

        local dragging=false
        local function update(val)
            local v=math.clamp(val,min,max); local a=(v-min)/(max-min)
            fillF.Size=UDim2.new(a,0,1,0); thumbF.Position=UDim2.new(a,-8,0.5,-8)
            valLbl.Text=string.format("%.2f",v)
            if callback then callback(v) end
        end
        local function inputToVal(i) return min+(max-min)*math.clamp((i.Position.X-trackF.AbsolutePosition.X)/trackF.AbsoluteSize.X,0,1) end
        trackF.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; update(inputToVal(i)) end end)
        thumbF.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(inputToVal(i)) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
        return {Set=update}
    end

    function Sec:TextBox(label,placeholder,default,callback)
        local T2=win._theme
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),LayoutOrder=#content:GetChildren()+1})
        local lbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Size=UDim2.new(0.4,-6,1,0),Font=Enum.Font.Gotham,Text=label,TextColor3=T2.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
        win:_reg(lbl,"TextColor3","Text")
        local box=Create("TextBox",{Parent=frame,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.55,BorderSizePixel=0,Position=UDim2.new(0.4,0,0.5,-14),Size=UDim2.new(0.6,0,0,28),Font=Enum.Font.Gotham,PlaceholderText=placeholder,PlaceholderColor3=T2.TextMuted,Text=default or "",TextColor3=T2.Text,TextSize=12,ZIndex=10,ClearTextOnFocus=false})
        win:_reg(box,"BackgroundColor3","GlassCard"); win:_reg(box,"TextColor3","Text")
        Create("UICorner",{Parent=box,CornerRadius=UDim.new(0,12)})
        Create("UIStroke",{Parent=box,Color=T2.Stroke,Thickness=1,Transparency=0.55})
        box.Focused:Connect(function() Tween(box,{BackgroundTransparency=0.3},0.2,Enum.EasingStyle.Sine) end)
        box.FocusLost:Connect(function() Tween(box,{BackgroundTransparency=0.55},0.2,Enum.EasingStyle.Sine); if callback then callback(box.Text) end end)
        return {Get=function() return box.Text end,Set=function(v) box.Text=v end}
    end

    function Sec:Keybind(label, defaultKey, callback)
        local T2=win._theme
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),LayoutOrder=#content:GetChildren()+1})
        local lbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Size=UDim2.new(1,-116,1,0),Font=Enum.Font.Gotham,Text=label,TextColor3=T2.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
        win:_reg(lbl,"TextColor3","Text")
        local currentKey=defaultKey
        local BIND_ID = "$$keybind_element_"..label.."$$"

        if callback then win:Bind(currentKey,BIND_ID,callback) end

        local keyBtn=Create("TextButton",{Parent=frame,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.45,BorderSizePixel=0,Position=UDim2.new(1,-108,0.5,-14),Size=UDim2.new(0,98,0,28),Font=Enum.Font.GothamBold,Text=currentKey.Name,TextColor3=T2.Text,TextSize=12,AutoButtonColor=false,ZIndex=10})
        win:_reg(keyBtn,"BackgroundColor3","GlassCard"); win:_reg(keyBtn,"TextColor3","Text")
        Create("UICorner",{Parent=keyBtn,CornerRadius=UDim.new(0,12)})
        Create("UIStroke",{Parent=keyBtn,Color=T2.Accent,Thickness=1,Transparency=0.55})

        local waiting=false
        keyBtn.MouseButton1Click:Connect(function()
            if waiting then return end; waiting=true
            keyBtn.Text="Press key..."
            Tween(keyBtn,{BackgroundColor3=win._theme.Accent,BackgroundTransparency=0.1},0.25)
            local conn
            conn=UserInputService.InputBegan:Connect(function(input,gpe)
                if gpe then return end
                if input.UserInputType~=Enum.UserInputType.Keyboard then return end
                win:Unbind(currentKey,BIND_ID)
                currentKey=input.KeyCode
                keyBtn.Text=currentKey.Name
                if callback then win:Bind(currentKey,BIND_ID,callback) end
                conn:Disconnect(); waiting=false
                Tween(keyBtn,{BackgroundColor3=win._theme.GlassCard,BackgroundTransparency=0.45},0.25)
            end)
        end)

        return {
            Get = function() return currentKey end,
            SetCallback = function(fn)
                callback = fn
                if callback then win:Bind(currentKey,BIND_ID,callback) else win:Unbind(currentKey,BIND_ID) end
            end,
            Clear = function() win:Unbind(currentKey,BIND_ID); callback=nil end
        }
    end

    function Sec:Button(label,callback)
        local T2=win._theme
        local btn=Create("TextButton",{Parent=content,BackgroundColor3=T2.Accent,BackgroundTransparency=0.3,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),Font=Enum.Font.GothamBold,Text=label,TextColor3=T2.Text,TextSize=13,AutoButtonColor=false,LayoutOrder=#content:GetChildren()+1,ZIndex=10})
        win:_reg(btn,"BackgroundColor3","Accent"); win:_reg(btn,"TextColor3","Text")
        Create("UICorner",{Parent=btn,CornerRadius=UDim.new(0,17)})
        btn.MouseEnter:Connect(function() Tween(btn,{BackgroundTransparency=0.1},0.18,Enum.EasingStyle.Sine) end)
        btn.MouseLeave:Connect(function() Tween(btn,{BackgroundTransparency=0.3},0.18,Enum.EasingStyle.Sine) end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn,{BackgroundTransparency=0.6},0.08); task.delay(0.12,function() Tween(btn,{BackgroundTransparency=0.3},0.18) end)
            if callback then task.spawn(callback) end
        end)
    end

    function Sec:Label(text)
        local T2=win._theme
        local lbl=Create("TextLabel",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,20),Font=Enum.Font.Gotham,Text=text,TextColor3=T2.TextMuted,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=#content:GetChildren()+1,ZIndex=10,TextWrapped=true})
        win:_reg(lbl,"TextColor3","TextMuted")
        return {Set=function(v) lbl.Text=v end}
    end

    function Sec:Dropdown(label,options,default,callback)
        local T2=win._theme; local selected=default or options[1]; local open=false
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=#content:GetChildren()+1,ZIndex=10,ClipsDescendants=false})
        local header=Create("TextButton",{Parent=frame,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.5,BorderSizePixel=0,Size=UDim2.new(1,0,0,34),Font=Enum.Font.GothamBold,Text="  ▾  "..selected,TextColor3=T2.Text,TextSize=13,AutoButtonColor=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11})
        win:_reg(header,"BackgroundColor3","GlassCard"); win:_reg(header,"TextColor3","Text")
        Create("UICorner",{Parent=header,CornerRadius=UDim.new(0,17)})
        Create("UIStroke",{Parent=header,Color=T2.Stroke,Thickness=1,Transparency=0.5})
        local dropdown=Create("Frame",{Parent=frame,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.06,BorderSizePixel=0,Position=UDim2.new(0,0,0,38),Size=UDim2.new(1,0,0,0),Visible=false,ClipsDescendants=true,ZIndex=50})
        win:_reg(dropdown,"BackgroundColor3","GlassCard")
        Create("UICorner",{Parent=dropdown,CornerRadius=UDim.new(0,17)})
        Create("UIStroke",{Parent=dropdown,Color=T2.Stroke,Thickness=1,Transparency=0.5})
        Create("UIListLayout",{Parent=dropdown,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
        Create("UIPadding",{Parent=dropdown,PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)})
        local totalH=10
        for i,opt in ipairs(options) do
            local isSel=opt==selected
            local ob=Create("TextButton",{Parent=dropdown,BackgroundColor3=T2.GlassCard,BackgroundTransparency=isSel and 0.3 or 0.85,BorderSizePixel=0,Size=UDim2.new(1,0,0,28),Font=Enum.Font.Gotham,Text="  "..opt,TextColor3=isSel and T2.Text or T2.TextSoft,TextSize=12,AutoButtonColor=false,LayoutOrder=i,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51})
            Create("UICorner",{Parent=ob,CornerRadius=UDim.new(0,12)})
            totalH=totalH+30
            ob.MouseEnter:Connect(function() Tween(ob,{BackgroundTransparency=0.5},0.12,Enum.EasingStyle.Sine) end)
            ob.MouseLeave:Connect(function() Tween(ob,{BackgroundTransparency=opt==selected and 0.3 or 0.85},0.12,Enum.EasingStyle.Sine) end)
            ob.MouseButton1Click:Connect(function()
                selected=opt; header.Text="  ▾  "..selected
                if callback then task.spawn(callback,selected) end
                Tween(dropdown,{Size=UDim2.new(1,0,0,0)},0.25); task.delay(0.26,function() dropdown.Visible=false end); open=false
            end)
        end
        header.MouseButton1Click:Connect(function()
            open=not open
            if open then dropdown.Visible=true; dropdown.Size=UDim2.new(1,0,0,0); Tween(dropdown,{Size=UDim2.new(1,0,0,totalH)},0.3,Enum.EasingStyle.Quint)
            else Tween(dropdown,{Size=UDim2.new(1,0,0,0)},0.25); task.delay(0.26,function() dropdown.Visible=false end) end
        end)
        return {Get=function() return selected end}
    end

    function Sec:ColorPicker(label,default,callback)
        local T2=win._theme; local current=default or Color3.fromRGB(255,255,255)
        local frame=Create("Frame",{Parent=content,BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),LayoutOrder=#content:GetChildren()+1,ZIndex=10,ClipsDescendants=false})
        local lbl=Create("TextLabel",{Parent=frame,BackgroundTransparency=1,Size=UDim2.new(1,-58,1,0),Font=Enum.Font.Gotham,Text=label,TextColor3=T2.Text,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=10})
        win:_reg(lbl,"TextColor3","Text")
        local swatch=Create("TextButton",{Parent=frame,BackgroundColor3=current,BorderSizePixel=0,Position=UDim2.new(1,-48,0.5,-12),Size=UDim2.new(0,42,0,24),Text="",AutoButtonColor=false,ZIndex=10})
        Create("UICorner",{Parent=swatch,CornerRadius=UDim.new(0,9)}); Create("UIStroke",{Parent=swatch,Color=T2.Stroke,Thickness=1.5,Transparency=0.4})
        local pickerOpen=false
        local popup=Create("Frame",{Parent=frame,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.06,BorderSizePixel=0,Position=UDim2.new(1,-206,0,40),Size=UDim2.new(0,196,0,0),Visible=false,ClipsDescendants=true,ZIndex=60})
        win:_reg(popup,"BackgroundColor3","GlassCard"); Create("UICorner",{Parent=popup,CornerRadius=UDim.new(0,14)}); Create("UIStroke",{Parent=popup,Color=T2.Stroke,Thickness=1,Transparency=0.4})
        local hueBar=Create("Frame",{Parent=popup,BackgroundTransparency=0,BorderSizePixel=0,Position=UDim2.new(0,8,0,8),Size=UDim2.new(1,-16,0,18),ZIndex=61})
        Create("UICorner",{Parent=hueBar,CornerRadius=UDim.new(0,9)})
        Create("UIGradient",{Parent=hueBar,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})})
        local h=Color3.toHSV(current)
        local hueThumb=Create("Frame",{Parent=hueBar,BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Position=UDim2.new(h,-5,0.5,-9),Size=UDim2.new(0,10,0,18),ZIndex=62})
        Create("UICorner",{Parent=hueThumb,CornerRadius=UDim.new(1,0)})
        local hexBox=Create("TextBox",{Parent=popup,BackgroundColor3=T2.GlassCard,BackgroundTransparency=0.5,BorderSizePixel=0,Position=UDim2.new(0,8,0,34),Size=UDim2.new(1,-16,0,26),Font=Enum.Font.GothamBold,Text=string.format("#%02X%02X%02X",math.floor(current.R*255),math.floor(current.G*255),math.floor(current.B*255)),TextColor3=T2.Text,TextSize=12,ZIndex=61,ClearTextOnFocus=false})
        win:_reg(hexBox,"BackgroundColor3","GlassCard"); win:_reg(hexBox,"TextColor3","Text"); Create("UICorner",{Parent=hexBox,CornerRadius=UDim.new(0,9)})
        local function applyColor(c)
            current=c; swatch.BackgroundColor3=c; h=Color3.toHSV(c)
            hueThumb.Position=UDim2.new(h,-5,0.5,-9)
            hexBox.Text=string.format("#%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
            if callback then task.spawn(callback,c) end
        end
        local hDrag=false
        hueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hDrag=true; applyColor(Color3.fromHSV(math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1),1,1)) end end)
        UserInputService.InputChanged:Connect(function(i) if hDrag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then applyColor(Color3.fromHSV(math.clamp((i.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1),1,1)) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hDrag=false end end)
        hexBox.FocusLost:Connect(function() local hex=hexBox.Text:gsub("#",""); if #hex==6 then local r,g,b=tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16); if r and g and b then applyColor(Color3.fromRGB(r,g,b)) end end end)
        swatch.MouseButton1Click:Connect(function()
            pickerOpen=not pickerOpen
            if pickerOpen then popup.Visible=true; popup.Size=UDim2.new(0,196,0,0); Tween(popup,{Size=UDim2.new(0,196,0,70)},0.3)
            else Tween(popup,{Size=UDim2.new(0,196,0,0)},0.25); task.delay(0.26,function() popup.Visible=false end) end
        end)
        return {Get=function() return current end,Set=applyColor}
    end

    return Sec
end

function PortalVisuals:Destroy()
    self:_clearStars()
    if self._inputConn then self._inputConn:Disconnect() end
    if self._gui       then self._gui:Destroy() end
    if self._wmGui     then self._wmGui:Destroy() end
    if self._notifyGui then self._notifyGui:Destroy() end
    if self._blur      then self._blur:Destroy() end
    table.clear(self._keybinds)
    table.clear(self._themeReg)
end

function PortalVisuals:AddSettingsTab()
    local tab=self:Tab("Settings", LucideAssets["settings"])
    
    local thSec=tab:Section("Theme")
    local names={}; for n in pairs(Themes) do table.insert(names,n) end; table.sort(names)
    thSec:Dropdown("Theme",names,"Dark",function(n) self:SetTheme(n) end)
    
    local bgSec=tab:Section("Background")
    bgSec:TextBox("Asset ID","numeric ID or rbxassetid://...","",function(v) if v=="" then self:ClearBackground() else self:SetBackground(v) end end)
    bgSec:Button("Clear",function() self:ClearBackground() end)
    
    local kSec=tab:Section("Keybind")
    kSec:Label("Current menu key: "..self._menuKey.Name)
    kSec:Keybind("Set Menu Key", self._menuKey, function() self:Toggle() end)
    return tab
end

return PortalVisuals

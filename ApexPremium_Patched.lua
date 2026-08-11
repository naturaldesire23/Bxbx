-- [[ APEX PREMIUM - FULL REMADE SCRIPT (UwU AP INTEGRATED) ]] --
-- [[ PATCHED: Token race condition, curve confidence, ping math, scheduler block ]] --

if game.CoreGui:FindFirstChild("ApexPremiumUI") then
    game.CoreGui.ApexPremiumUI:Destroy()
end

local Players = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local ReplicatedStorage = cloneref and cloneref(game:GetService('ReplicatedStorage')) or game:GetService('ReplicatedStorage')
local UserInputService = cloneref and cloneref(game:GetService('UserInputService')) or game:GetService('UserInputService')
local RunService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local TweenService = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local Stats = cloneref and cloneref(game:GetService('Stats')) or game:GetService('Stats')
local CoreGui = cloneref and cloneref(game:GetService('CoreGui')) or game:GetService('CoreGui')
local Lighting = cloneref and cloneref(game:GetService('Lighting')) or game:GetService('Lighting')
local Workspace = cloneref and cloneref(game:GetService('Workspace')) or game:GetService('Workspace')

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- LOADING UI
-- ============================================================
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "ApexLoading"
LoadingGui.ResetOnSpawn = false
LoadingGui.IgnoreGuiInset = true
LoadingGui.DisplayOrder = 9999
LoadingGui.Parent = CoreGui

local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Background.Parent = LoadingGui

local Title = Instance.new("TextLabel")
Title.Text = "Apex Premium"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 32
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Position = UDim2.new(0, 0, 0.4, 0)
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Parent = Background

local StatusText = Instance.new("TextLabel")
StatusText.Text = "Initializing..."
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 16
StatusText.TextColor3 = Color3.fromRGB(150, 150, 200)
StatusText.Position = UDim2.new(0, 0, 0.5, 30)
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.BackgroundTransparency = 1
StatusText.Parent = Background

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0, 300, 0, 10)
BarBg.Position = UDim2.new(0.5, -150, 0.5, 60)
BarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BarBg.BorderSizePixel = 0
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)
BarBg.Parent = Background

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
BarFill.Parent = BarBg

local function SetProgress(percent, text)
    pcall(function()
        BarFill.Size = UDim2.new(percent, 0, 1, 0)
        StatusText.Text = text
        task.wait(0.01)
    end)
end

SetProgress(0.1, "Booting core systems...")

-- ============================================================
-- SYSTEM INITIALIZATION & STATE
-- ============================================================
local System = {
    __properties = {
        __autoparry_enabled = false,
        __auto_spam_enabled = false,
        __manual_spam_enabled = false,
        __triggerbot_enabled = false,
        __animation_fix = false,
        __curve_mode = 1,
        __accuracy = 50,
        __divisor_multiplier = 1.1,
        __parries = 0,
        __parried = false,
        __first_parry_done = false,
        __spam_threshold = 300,
        __manual_spam_cps = 200,
        __fake_body_enabled = false,
        __fake_winstreak_enabled = false,
        __fake_winstreak_value = 100,
        __parry_cooldown_until = 0,  -- PATCH: replaces repeat/until scheduler block
        __connections = {}
    },
    __config = { __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'} },
    ball = {}, player = {}, curve = {}, parry = {}, detection = {}, autoparry = {}, auto_spam = {}, triggerbot = {}
}

local GlobalParryLocks = {}
local AutoSpamState = { lastBall = nil, lastFireTime = 0 }

-- ============================================================
-- FAST CURVE DETECTION SYSTEM (PATCHED)
-- ============================================================
local FastCurveDetection = {
    data = {},
    getThreshold = function(speed)
        if speed > 400 then return 3
        elseif speed > 300 then return 5
        elseif speed > 200 then return 8
        else return 12 end
    end,
}

function FastCurveDetection.detect(ball, currentTime)
    if not ball then return false end
    if not FastCurveDetection.data[ball] then
        FastCurveDetection.data[ball] = { positions = {}, velocities = {}, confidence = 0 }
    end
    local data = FastCurveDetection.data[ball]
    local zoomies = ball:FindFirstChild('zoomies')
    if not zoomies then return false end
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    if speed < 5 then return false end
    table.insert(data.positions, { pos = ball.Position, time = currentTime })
    table.insert(data.velocities, velocity)
    if #data.positions > 6 then table.remove(data.positions, 1) end
    if #data.velocities > 6 then table.remove(data.velocities, 1) end
    if #data.positions < 2 then return false end
    local v1 = data.velocities[#data.velocities - 1]
    local v2 = data.velocities[#data.velocities]
    if v1.Magnitude < 0.1 or v2.Magnitude < 0.1 then return false end
    local dotProduct = math.clamp(v1.Unit:Dot(v2.Unit), -1, 1)
    local angleBetween = math.deg(math.acos(dotProduct))
    local threshold = FastCurveDetection.getThreshold(speed)
    local timeDiff = data.positions[#data.positions].time - data.positions[#data.positions - 1].time
    if timeDiff < 0.001 then return false end
    local angularVelocity = angleBetween / timeDiff
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local distance = (hrp.Position - ball.Position).Magnitude
    local timeToImpact = distance / speed
    local predictedCurveAngle = angularVelocity * timeToImpact
    local isCurrentlyCurved = angleBetween > threshold
    local willCurveEnough = predictedCurveAngle > (threshold * 0.4)
    local isSharpCurve = angularVelocity > 100
    local isThreat = isCurrentlyCurved or willCurveEnough or isSharpCurve

    -- PATCH: Slower decay (was +0.4/-0.2), prevents false negatives on real curves
    if isThreat then
        data.confidence = math.min(data.confidence + 0.35, 1)
    else
        data.confidence = math.max(data.confidence - 0.08, 0)
    end

    data.lastAngle = angleBetween
    data.lastSpeed = speed
    data.threshold = threshold
    data.angularVelocity = angularVelocity
    data.predictedCurveAngle = predictedCurveAngle

    -- Backwards curve check
    local to_me = (hrp.Position - ball.Position).Unit
    local vel_unit = velocity.Unit
    local dot = to_me:Dot(vel_unit)
    if dot < -0.3 and #data.velocities >= 3 then
        local old_v1 = data.velocities[#data.velocities - 2]
        if old_v1.Magnitude > 0.1 then
            local old_dot = to_me:Dot(old_v1.Unit)
            if old_dot > 0.3 then
                data.isBackwardsCurve = true
            end
        end
    end
    -- PATCH: confidence floor lowered from 0.4 to 0.3
    if data.confidence < 0.3 then data.isBackwardsCurve = false end

    -- PATCH: detection threshold lowered from 0.4 to 0.3
    return data.confidence > 0.3
end

function FastCurveDetection.cleanup()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return end
    local activeBalls = {}
    for _, b in ipairs(balls:GetChildren()) do
        if b:GetAttribute("realBall") then activeBalls[b] = true end
    end
    for ball, _ in pairs(FastCurveDetection.data) do
        if not activeBalls[ball] then FastCurveDetection.data[ball] = nil end
    end
end

local ManualSpam = { enabled = false, cps = 200, accumulator = 0, connection = nil }
local ParryVisual = { active = false }

local function update_divisor()
    System.__properties.__divisor_multiplier = 0.75 + (System.__properties.__accuracy - 1) * (3 / 99)
end
update_divisor()

local Alive = workspace:FindFirstChild("Alive")
if not Alive then Alive = workspace:WaitForChild("Alive", 15) end

-- ============================================================
-- PARRY PATCH (BYPASS ANTICHEAT) - PATCHED: token race condition fixed
-- ============================================================
local _PARRY_PATCH = { keyTable = nil, transformFn = nil, netModule = nil, remoteId = nil, parryHash = nil, parryRemote = nil, ready = false }

pcall(function()
    local old_dinfo
    old_dinfo = hookfunction(getrenv().debug.info, function(f, t)
        if type(f) == "function" then return "[C]"
        elseif f == 4 and t == "s" then return "ReplicatedStorage.Controllers.SwordsController " end
        return old_dinfo(f, t)
    end)
    local old_gfenv
    old_gfenv = hookfunction(getrenv().getfenv, function(l)
        if l ~= nil and type(l) == "number" then
            if l >= 1 and l <= 10 then return old_gfenv(10) end
        end
        return old_gfenv(l)
    end)
end)

SetProgress(0.3, "Bypassing anticheat...")

task.spawn(function()
    pcall(function()
        local Controllers = ReplicatedStorage:WaitForChild("Controllers", 15)
        if not Controllers then return end
        local SC
        for _, child in ipairs(Controllers:GetChildren()) do
            if child.Name:sub(1, 16) == "SwordsController" then SC = child break end
        end
        if not SC then return end
        local PRY = SC:WaitForChild("PRY", 15)
        if not PRY then return end
        local Parry_Function = require(PRY)
        local getupvals = debug.getupvalues or getupvalues
        if not getupvals then return end
        local ups = getupvals(Parry_Function)
        if not ups or #ups < 8 then return end
        _PARRY_PATCH.keyTable = ups[3]
        _PARRY_PATCH.transformFn = ups[4]
        _PARRY_PATCH.netModule = ups[6]
        _PARRY_PATCH.remoteId = ups[7]
        _PARRY_PATCH.parryHash = ups[8]
        pcall(function() _PARRY_PATCH.parryRemote = _PARRY_PATCH.netModule:RemoteEvent(_PARRY_PATCH.remoteId) end)
        if _PARRY_PATCH.parryRemote then _PARRY_PATCH.ready = true end
    end)
end)

-- PATCH: Atomic snapshot of keyTable + keyIndex — prevents race condition on key rotation
function _PARRY_PATCH.fire(curveCFrame, screenPositions, mouseLocation)
    if not _PARRY_PATCH.ready then return false end
    local kt = _PARRY_PATCH.keyTable
    if not kt then return false end

    -- Snapshot both reads in one frame — key rotation can't slip between them now
    local keyTable = kt[1]
    local keyIndex = kt[3]
    if not keyTable or not keyIndex then return false end
    local currentKey = keyTable[keyIndex]
    if not currentKey then return false end

    local tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey, "TIME")
    if not tok or not transformed then
        tok, transformed = pcall(_PARRY_PATCH.transformFn, currentKey)
        if not tok or not transformed then return false end
    end

    local serverTime = workspace:GetServerTimeNow() * 100
    local timeStr = tostring(math.floor(serverTime))
    local tc = {}
    for i = 1, #timeStr do
        local ki = (i - 1) % #transformed + 1
        local kb = string.byte(transformed, ki)
        local tb = (string.byte(timeStr, i) + i) % 256
        tc[i] = string.char(bit32.bxor(tb, kb))
    end
    local token = table.concat(tc)

    pcall(function()
        _PARRY_PATCH.parryRemote:FireServer(
            _PARRY_PATCH.parryHash, currentKey, token,
            0.5, curveCFrame, screenPositions, mouseLocation, false
        )
    end)
    return true
end

local PF = nil
local SC = nil

pcall(function()
    if ReplicatedStorage:FindFirstChild("Controllers") then
        for _, child in ipairs(ReplicatedStorage.Controllers:GetChildren()) do
            if child.Name:match("^SwordsController%s*$") then SC = child end
        end
    end
    if LocalPlayer.PlayerGui:FindFirstChild("Hotbar") and LocalPlayer.PlayerGui.Hotbar:FindFirstChild("Block") then
        for _, v in next, getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated) do
            if SC and getfenv(v.Function).script == SC then
                PF = v.Function
                break
            end
        end
    end
end)

SetProgress(0.5, "Hooking parry logic...")

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function get_real_ball()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return nil end
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then ball.CanCollide = false return ball end
    end
    return nil
end

local function get_all_balls()
    local tbl = {}
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return tbl end
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then ball.CanCollide = false table.insert(tbl, ball) end
    end
    return tbl
end

local function get_closest_player()
    if not Alive then return nil end
    local closest, minDist = nil, math.huge
    for _, player in ipairs(Alive:GetChildren()) do
        if player ~= LocalPlayer.Character and player:FindFirstChild("HumanoidRootPart") then
            local dist = LocalPlayer:DistanceFromCharacter(player.HumanoidRootPart.Position)
            if dist < minDist then minDist = dist closest = player end
        end
    end
    return closest
end

local function get_closest_to_cursor()
    if not Alive then return nil end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then return nil end
    local closest_player, minimal_dot = nil, -math.huge
    local camera = workspace.CurrentCamera
    local success, mouse_location = pcall(function() return UserInputService:GetMouseLocation() end)
    if not success then return nil end
    local ray = camera:ScreenPointToRay(mouse_location.X, mouse_location.Y)
    local pointer = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
    for _, player in ipairs(Alive:GetChildren()) do
        if player ~= LocalPlayer.Character and player:FindFirstChild('HumanoidRootPart') then
            local direction = (player.HumanoidRootPart.Position - camera.CFrame.Position).Unit
            local dot = pointer.LookVector:Dot(direction)
            if dot > minimal_dot then minimal_dot = dot closest_player = player end
        end
    end
    return closest_player
end

-- ============================================================
-- PARRY LOGIC & VISUALS
-- ============================================================
function System.curve.get_cframe()
    local camera = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return camera.CFrame end
    local targetPart = get_closest_to_cursor()
    if targetPart and targetPart:FindFirstChild('HumanoidRootPart') then targetPart = targetPart.HumanoidRootPart end
    local target_pos = targetPart and targetPart.Position or (root.Position + camera.CFrame.LookVector * 100)
    local curve_functions = {
        function() return camera.CFrame end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))) end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0)) end,
        function() return CFrame.new(camera.CFrame.Position, root.Position + (root.Position - target_pos).Unit * 10000 + Vector3.new(0, 1000, 0)) end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0)) end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0)) end
    }
    return curve_functions[System.__properties.__curve_mode]()
end

function ShowParryEffect()
    if ParryVisual.active then return end
    ParryVisual.active = true
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flash.BackgroundTransparency = 0.7
    flash.ZIndex = 9999
    flash.Parent = CoreGui
    TweenService:Create(flash, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
    task.delay(0.2, function() flash:Destroy() ParryVisual.active = false end)
end

function System.parry.execute(force)
    if not force and System.__properties.__parries > 10000 then return false end
    if not LocalPlayer.Character then return false end
    local camera = workspace.CurrentCamera
    local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    if not success then return false end
    local vec2_mouse = {mouse.X, mouse.Y}
    local event_data = {}
    if Alive then
        for _, entity in ipairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local s, sp = pcall(function() return camera:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if s then event_data[entity.Name] = sp end
            end
        end
    end
    local curve_cframe = System.curve.get_cframe()
    if not System.__properties.__first_parry_done then
        pcall(function()
            for _, connection in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do connection:Fire() end
        end)
        System.__properties.__first_parry_done = true return true
    end
    local fired = _PARRY_PATCH.fire(curve_cframe, event_data, vec2_mouse)
    if fired then
        if System.__properties.__animation_fix and PF then pcall(PF) end
        System.__properties.__parries = System.__properties.__parries + 1
        task.delay(0.5, function() if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end end)
        pcall(ShowParryEffect)
        return true
    end
    return false
end

function System.parry.keypress()
    if System.__properties.__parries > 10000 then return false end
    if not LocalPlayer.Character then return false end
    if PF then pcall(PF) end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function() if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end end)
    return true
end

function System.parry.execute_action()
    return System.parry.execute()
end

-- ============================================================
-- AUTO PARRY (PATCHED: ping math fixed, scheduler block removed)
-- ============================================================
function System.autoparry.start()
    if System.__properties.__connections.__autoparry then System.__properties.__connections.__autoparry:Disconnect() end
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        local balls = get_all_balls()
        for _, ball in ipairs(balls) do
            if not ball then continue end
            local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then continue end

            ball:GetAttributeChangedSignal('target'):Once(function()
                System.__properties.__parried = false
            end)
            if System.__properties.__parried then continue end

            local ball_target = ball:GetAttribute('target')
            local vel = zoomies.VectorVelocity
            local speed = vel.Magnitude
            if speed < 1 then continue end

            local hrp = LocalPlayer.Character.PrimaryPart
            local dist = (hrp.Position - ball.Position).Magnitude

            -- PATCH: ping capped at 250ms — prevents window inversion on high ping
            local ping_ms = 0
            pcall(function() ping_ms = Stats.Network.ServerStatsItem['Data Ping']:GetValue() end)
            local ping_sec = math.clamp(ping_ms / 1000, 0, 0.25)

            -- PATCH: time_to_reach no longer subtracts ping — ping now expands the window instead
            local time_to_reach = dist / speed

            local isCurved = FastCurveDetection.detect(ball, tick())
            local curveData = FastCurveDetection.data[ball]

            -- PATCH: ping_sec added to window rather than subtracted from distance
            local trigger_window = 0.05 + (System.__properties.__divisor_multiplier * 0.03) + ping_sec

            if isCurved and curveData then
                trigger_window = trigger_window * 0.6
                if curveData.isBackwardsCurve then
                    trigger_window = trigger_window * 0.5
                end
            end

            if ball_target == LocalPlayer.Name and time_to_reach > 0 and time_to_reach <= trigger_window then
                local now = tick()
                -- PATCH: cooldown timestamp replaces repeat/until scheduler block
                if now >= System.__properties.__parry_cooldown_until then
                    if getgenv().AutoParryMode == "Keypress" then System.parry.keypress() else System.parry.execute_action() end
                    System.__properties.__parried = true
                    System.__properties.__parry_cooldown_until = now + 1.0
                end
            end
            -- PATCH: repeat/until block removed entirely — parried resets via AttributeChangedSignal
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end

function System.auto_spam.start()
    if System.__properties.__connections.__auto_spam then System.__properties.__connections.__auto_spam:Disconnect() end
    System.__properties.__connections.__auto_spam = RunService.PreSimulation:Connect(function(dt)
        if not System.__properties.__auto_spam_enabled then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local ball = get_real_ball()
        if not ball then return end
        local zoomies = ball:FindFirstChild('zoomies')
        if not zoomies then return end
        local velocity = zoomies.VectorVelocity
        local speed = velocity.Magnitude
        if speed < 20 then return end
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local distance = (hrp.Position - ball.Position).Magnitude
        local target = ball:GetAttribute('target')
        local currentTime = tick()
        local to_me = (hrp.Position - ball.Position).Unit
        local vel_unit = velocity.Unit
        local dot = to_me:Dot(vel_unit)
        local max_spam_distance = math.clamp(5 + (speed * 0.05), 5, 15)
        local is_approaching = dot > 0.0
        local isCurved = FastCurveDetection.detect(ball, currentTime)
        if isCurved then
            is_approaching = true
            max_spam_distance = max_spam_distance * 1.1
        end
        if AutoSpamState.lastBall ~= ball then
            AutoSpamState.lastBall = ball
            AutoSpamState.lastFireTime = 0
        end
        local should_spam = (
            (target == LocalPlayer.Name or target == nil) and
            distance <= max_spam_distance and
            is_approaching and
            distance > 2.5
        )
        if should_spam then
            local interval = 1 / System.__properties.__spam_threshold
            if currentTime - AutoSpamState.lastFireTime >= interval then
                AutoSpamState.lastFireTime = currentTime
                System.parry.execute(true)
            end
        end
    end)
end

function System.auto_spam.stop()
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
        System.__properties.__connections.__auto_spam = nil
    end
end

function EnableManualSpam(cps)
    cps = cps or 200
    ManualSpam.cps = math.clamp(cps, 1, 999)
    ManualSpam.enabled = true
    if ManualSpam.connection then ManualSpam.connection:Disconnect() ManualSpam.connection = nil end
    ManualSpam.connection = RunService.PreSimulation:Connect(function(dt)
        if not ManualSpam.enabled then return end
        if not LocalPlayer.Character then return end
        ManualSpam.accumulator = ManualSpam.accumulator + dt
        local interval = 1 / ManualSpam.cps
        if ManualSpam.accumulator >= interval then
            ManualSpam.accumulator = 0
            System.parry.execute(true)
        end
    end)
end

function DisableManualSpam()
    ManualSpam.enabled = false
    ManualSpam.accumulator = 0
    if ManualSpam.connection then ManualSpam.connection:Disconnect() ManualSpam.connection = nil end
end

function SetManualSpamCPS(cps) ManualSpam.cps = math.clamp(cps, 1, 999) end

function System.triggerbot.start()
    if System.__properties.__connections.__triggerbot then System.__properties.__connections.__triggerbot:Disconnect() end
    System.__properties.__connections.__triggerbot = RunService.PreSimulation:Connect(function()
        if not System.__properties.__triggerbot_enabled then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closest = get_closest_player()
        if not closest or not closest:FindFirstChild("HumanoidRootPart") then return end
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local closest_distance = (hrp.Position - closest.HumanoidRootPart.Position).Magnitude
        if closest_distance > 25 then return end
        for _, ball in ipairs(get_all_balls()) do
            local target = ball:GetAttribute('target')
            if target == closest.Name then
                local ball_dist = (hrp.Position - ball.Position).Magnitude
                if ball_dist <= 25 then
                    System.parry.execute()
                    break
                end
            end
        end
    end)
end

function System.triggerbot.stop()
    if System.__properties.__connections.__triggerbot then
        System.__properties.__connections.__triggerbot:Disconnect()
        System.__properties.__connections.__triggerbot = nil
    end
end

task.spawn(function()
    local balls = workspace:FindFirstChild('Balls')
    if balls then
        balls.ChildAdded:Connect(function(ball)
            if ball:IsA("BasePart") then
                ball:GetAttributeChangedSignal("target"):Connect(function()
                    if ball:GetAttribute("target") ~= LocalPlayer.Name then
                        System.__properties.__parried = false
                    end
                end)
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() FastCurveDetection.cleanup() end)
    end
end)

-- ============================================================
-- SEMI IMMORTALITY (METAMETHOD ONLY)
-- ============================================================
local semiImmortalActive = false
local semiImmortalCache = {CFrame = CFrame.new()}
local semiImmortalOldIndex = nil
local semiImmortalOldNewIndex = nil

function EnableSemiImmortal()
    if semiImmortalActive then return end
    semiImmortalActive = true
    local success, err = pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        semiImmortalOldIndex = mt.__index
        semiImmortalOldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if semiImmortalActive and not checkcaller() then
                local ok, result = pcall(function()
                    if key == "CFrame" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        if self == LocalPlayer.Character.HumanoidRootPart then return semiImmortalCache.CFrame or CFrame.new() end
                    end
                    if key == "Position" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        if self == LocalPlayer.Character.HumanoidRootPart then return (semiImmortalCache.CFrame or CFrame.new()).Position end
                    end
                end)
                if ok and result then return result end
            end
            return semiImmortalOldIndex(self, key)
        end)
        mt.__newindex = newcclosure(function(self, key, value)
            if semiImmortalActive and not checkcaller() then
                local ok = pcall(function()
                    if key == "CFrame" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        if self == LocalPlayer.Character.HumanoidRootPart then
                            semiImmortalCache.CFrame = value
                            return semiImmortalOldNewIndex(self, key, value)
                        end
                    end
                end)
                if ok then return end
            end
            return semiImmortalOldNewIndex(self, key, value)
        end)
        setreadonly(mt, true)
    end)
    if not success then warn("Semi-Immortality failed:", err) semiImmortalActive = false return end
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart:SetNetworkOwner(LocalPlayer)
        end
    end)
    local ownerConn
    ownerConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if semiImmortalActive then
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart:SetNetworkOwner(LocalPlayer)
                end
            end)
        end
    end)
    System.__properties.__connections.__immortal_owner = ownerConn
end

function DisableSemiImmortal()
    semiImmortalActive = false
    local mt = getrawmetatable(game)
    if mt then
        setreadonly(mt, false)
        if semiImmortalOldIndex then mt.__index = semiImmortalOldIndex semiImmortalOldIndex = nil end
        if semiImmortalOldNewIndex then mt.__newindex = semiImmortalOldNewIndex semiImmortalOldNewIndex = nil end
        setreadonly(mt, true)
    end
    if System.__properties.__connections.__immortal_owner then
        System.__properties.__connections.__immortal_owner:Disconnect()
        System.__properties.__connections.__immortal_owner = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp:SetNetworkOwner(nil) end) end
    end
end

-- ============================================================
-- WALK SPEED & FLY
-- ============================================================
local walkSpeedEnabled = false
local walkSpeedValue = 36

function EnableWalkSpeed(speed)
    walkSpeedEnabled = true
    walkSpeedValue = speed or 36
    if System.__properties.__connections.__walkspeed then System.__properties.__connections.__walkspeed:Disconnect() end
    System.__properties.__connections.__walkspeed = RunService.PreSimulation:Connect(function()
        if not walkSpeedEnabled then return end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = walkSpeedValue end
    end)
end

function DisableWalkSpeed()
    walkSpeedEnabled = false
    if System.__properties.__connections.__walkspeed then
        System.__properties.__connections.__walkspeed:Disconnect()
        System.__properties.__connections.__walkspeed = nil
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = 16 end
end

local flyEnabled = false
local flySpeed = 50
local flyBodyGyro, flyBodyVelocity

function EnableFly()
    if flyEnabled then return end
    flyEnabled = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then return end
    flyBodyGyro = Instance.new('BodyGyro')
    flyBodyGyro.P = 90000
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.Parent = hrp
    flyBodyVelocity = Instance.new('BodyVelocity')
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Parent = hrp
    humanoid.PlatformStand = true
    System.__properties.__connections.__fly = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not hrp or not hrp.Parent then return end
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
        flyBodyVelocity.Velocity = moveDir * flySpeed
        flyBodyGyro.CFrame = cam.CFrame
    end)
end

function DisableFly()
    flyEnabled = false
    if System.__properties.__connections.__fly then
        System.__properties.__connections.__fly:Disconnect()
        System.__properties.__connections.__fly = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if hrp then
            for _, v in ipairs(hrp:GetChildren()) do
                if v:IsA('BodyGyro') or v:IsA('BodyVelocity') then v:Destroy() end
            end
        end
        if humanoid then humanoid.PlatformStand = false end
    end
    flyBodyGyro, flyBodyVelocity = nil, nil
end

function SetFlySpeed(speed) flySpeed = speed end
function SetWalkSpeed(speed) walkSpeedValue = speed end

-- ============================================================
-- AVATAR COPIER
-- ============================================================
local avatarCopierActive = false
local avatarCopierTarget = nil
local avatarCopierConnection = nil
local originalAvatar = nil

local function getPlayerAvatar(player)
    local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(player.UserId) end)
    return ok and desc or nil
end

local function applyAvatar(desc)
    if not desc then return end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if not originalAvatar then originalAvatar = humanoid:GetAppliedDescription() end
    humanoid:ApplyDescription(desc)
end

local function startAvatarCopier(targetName)
    if avatarCopierActive then return end
    local targetPlayer = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(targetName:lower()) or player.DisplayName:lower():find(targetName:lower()) then
            targetPlayer = player break
        end
    end
    if not targetPlayer then return false end
    avatarCopierTarget = targetPlayer
    avatarCopierActive = true
    local desc = getPlayerAvatar(targetPlayer)
    if desc then applyAvatar(desc) end
    avatarCopierConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if avatarCopierActive and avatarCopierTarget then
            local desc = getPlayerAvatar(avatarCopierTarget)
            if desc then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:ApplyDescription(desc) end
            end
        end
    end)
    return true
end

function StopAvatarCopier()
    avatarCopierActive = false
    if avatarCopierConnection then avatarCopierConnection:Disconnect() avatarCopierConnection = nil end
    if originalAvatar and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ApplyDescription(originalAvatar) end
    end
    avatarCopierTarget = nil
    originalAvatar = nil
end

function CopyAvatar(playerName) return startAvatarCopier(playerName) end

-- ============================================================
-- FAKE HEADLESS & KORBLOX
-- ============================================================
local KORBLOX_MESH_ID = "rbxassetid://101851696"
local KORBLOX_TEX_ID = "rbxassetid://101851254"
local HEADLESS_MESH_ID = "rbxassetid://134082579"
local HEADLESS_TEX_ID = "rbxassetid://134082627"

local function applyFakeBody(char)
    if not System.__properties.__fake_body_enabled then return end
    if not char then return end
    task.spawn(function()
        local head = char:FindFirstChild("Head")
        local rleg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")
        if head then
            for _, v in ipairs(head:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
            local m = Instance.new("SpecialMesh")
            m.MeshType = Enum.MeshType.FileMesh
            m.MeshId = HEADLESS_MESH_ID
            m.TextureId = HEADLESS_TEX_ID
            m.Scale = Vector3.new(1.25, 1.25, 1.25)
            m.Parent = head
            head.Transparency = 0.1
        end
        if rleg then
            for _, v in ipairs(rleg:GetChildren()) do if v:IsA("SpecialMesh") then v:Destroy() end end
            local m = Instance.new("SpecialMesh")
            m.MeshType = Enum.MeshType.FileMesh
            m.MeshId = KORBLOX_MESH_ID
            m.TextureId = KORBLOX_TEX_ID
            m.Scale = Vector3.new(1, 1, 1)
            m.Parent = rleg
            rleg.Transparency = 0.1
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyFakeBody(char)
end)

if LocalPlayer.Character then
    task.spawn(function() task.wait(0.5) applyFakeBody(LocalPlayer.Character) end)
end

-- ============================================================
-- CUSTOM WINSTREAK SPOOFER
-- ============================================================
local originalWinstreakTexts = {}

local function applyFakeWinstreakToObj(gui)
    if not System.__properties.__fake_winstreak_enabled then return end
    if gui:IsA("TextLabel") then
        if gui.Name:lower():match("streak") or (gui.Text and gui.Text:lower():match("streak")) then
            if not originalWinstreakTexts[gui] then originalWinstreakTexts[gui] = gui.Text end
            gui.Text = "Winstreak: " .. tostring(System.__properties.__fake_winstreak_value)
        end
    end
end

getgenv().EnableFakeWinstreak = function()
    System.__properties.__fake_winstreak_enabled = true
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do applyFakeWinstreakToObj(gui) end
            System.__properties.__connections.__winstreak_monitor = playerGui.DescendantAdded:Connect(applyFakeWinstreakToObj)
        end
    end)
end

getgenv().DisableFakeWinstreak = function()
    System.__properties.__fake_winstreak_enabled = false
    if System.__properties.__connections.__winstreak_monitor then
        System.__properties.__connections.__winstreak_monitor:Disconnect()
        System.__properties.__connections.__winstreak_monitor = nil
    end
    pcall(function()
        for gui, text in pairs(originalWinstreakTexts) do
            if gui and gui.Parent then gui.Text = text end
        end
        originalWinstreakTexts = {}
    end)
end

getgenv().SetFakeWinstreakValue = function(val)
    System.__properties.__fake_winstreak_value = tonumber(val) or 0
    if System.__properties.__fake_winstreak_enabled then
        pcall(function()
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                for _, gui in ipairs(playerGui:GetDescendants()) do applyFakeWinstreakToObj(gui) end
            end
        end)
    end
end

-- ============================================================
-- SKIN CHANGER
-- ============================================================
local swordInstances = nil
local skinChangerController = nil
local _hookedFuncs = {}

local function getSwordModule()
    if swordInstances then return swordInstances end
    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if not shared then return end
        local instances = shared:FindFirstChild("ReplicatedInstances")
        if not instances then return end
        local swords = instances:FindFirstChild("Swords")
        if not swords then return end
        swordInstances = require(swords)
    end)
    return swordInstances
end

local function getSwordsController()
    if skinChangerController then return skinChangerController end
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    if controllers then
        for _, child in ipairs(controllers:GetChildren()) do
            if child.Name:match("SwordsController") then
                local ok, module = pcall(require, child)
                if ok and type(module) == "table" then
                    skinChangerController = module
                    return module
                end
            end
        end
    end
    pcall(function()
        local remote = ReplicatedStorage.Remotes:FindFirstChild("FireSwordInfo")
        if not remote then return end
        local ok, conns = pcall(getconnections, remote.OnClientEvent)
        if not ok or not conns then return end
        for _, v in ipairs(conns) do
            if v.Function and islclosure and islclosure(v.Function) then
                local ok2, up = pcall(getupvalues, v.Function)
                if ok2 and #up == 1 and type(up[1]) == "table" then
                    skinChangerController = up[1]
                    return up[1]
                end
            end
        end
    end)
    pcall(function()
        local controllers = ReplicatedStorage:FindFirstChild("Controllers")
        if not controllers then return end
        for _, child in ipairs(controllers:GetChildren()) do
            if child.Name:match("SwordsController") then
                local pry = child:FindFirstChild("PRY")
                if pry then
                    local parryFunc = require(pry)
                    local ups = getupvalues(parryFunc)
                    if ups and #ups >= 6 then
                        skinChangerController = ups[6]
                        return skinChangerController
                    end
                end
            end
        end
    end)
    return skinChangerController
end

local function getSlashName(swordName)
    local mod = getSwordModule()
    if not mod or not swordName or swordName == "" then return "SlashEffect" end
    local ok, sword = pcall(function() return mod:GetSword(swordName) end)
    return ok and sword and sword.SlashName or "SlashEffect"
end

local function setSword()
    if not getgenv().SkinChangerEnabled then return end
    if not LocalPlayer.Character then return end
    local mod = getSwordModule()
    if not mod then return end
    pcall(function()
        local f = rawget(mod, "EquipSwordTo")
        if type(f) == "function" then
            local ups = getupvalues(f)
            for i = 1, #ups do
                if type(ups[i]) == "boolean" then setupvalue(f, i, false) break end
            end
        end
    end)
    pcall(function() mod:EquipSwordTo(LocalPlayer.Character, getgenv().SwordModel) end)
    task.spawn(function()
        local controller = getSwordsController()
        if controller then
            pcall(function()
                if controller.SetSword then controller:SetSword(getgenv().SwordAnimation or getgenv().SwordModel) end
            end)
        end
    end)
    pcall(function()
        local targetSword = getgenv().SwordFX or getgenv().SwordModel
        local remote = ReplicatedStorage.Remotes:FindFirstChild("FireSwordInfo")
        if remote then remote:FireServer(targetSword) end
        if skinChangerController then
            skinChangerController.currentSword = targetSword
            skinChangerController.SwordFX = targetSword
        end
    end)
end

local function updateSword()
    if not getgenv().SkinChangerEnabled then return end
    getgenv().SlashName = getSlashName(getgenv().SwordFX or getgenv().SwordModel)
    setSword()
end

local function hookParrySuccess()
    pcall(function()
        local remote = ReplicatedStorage.Remotes:FindFirstChild("ParrySuccessAll")
        if not remote then return end
        local ok, conns = pcall(getconnections, remote.OnClientEvent)
        if not ok or not conns then return end
        for _, v in ipairs(conns) do
            local func = v.Function
            if func and not _hookedFuncs[func] then
                _hookedFuncs[func] = true
                v:Disable()
                local targetFunc = func
                local ourFunc = function(...)
                    local args = {...}
                    local isLocal = false
                    for _, arg in ipairs(args) do
                        if tostring(arg) == LocalPlayer.Name then isLocal = true break end
                    end
                    if isLocal and getgenv().SkinChangerEnabled then
                        local fxSword = getgenv().SwordFX or getgenv().SwordModel
                        for i, arg in ipairs(args) do
                            if type(arg) == "string" then
                                local isPlayerName = false
                                for _, player in ipairs(Players:GetPlayers()) do
                                    if arg == player.Name or arg == player.DisplayName then isPlayerName = true break end
                                end
                                if not isPlayerName then
                                    if arg:match("Slash") or arg == "Default" or arg:match("Effect") then
                                        args[i] = getgenv().SlashName or "SlashEffect"
                                    else
                                        args[i] = fxSword
                                    end
                                end
                            end
                        end
                    end
                    pcall(targetFunc, unpack(args))
                end
                remote.OnClientEvent:Connect(ourFunc)
            end
        end
    end)
end

local function startSkinMonitor()
    if System.__properties.__connections.__skin_monitor then return end
    System.__properties.__connections.__skin_monitor = RunService.Heartbeat:Connect(function()
        if not getgenv().SkinChangerEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local currentSword = LocalPlayer:GetAttribute("CurrentlyEquippedSword")
        local targetSword = getgenv().SwordModel
        if currentSword ~= targetSword then setSword() end
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Model") and v.Name ~= targetSword and v.Name ~= "HumanoidRootPart" then v:Destroy() end
        end
        local controller = getSwordsController()
        if controller then
            if controller.currentSword ~= targetSword then
                pcall(function()
                    if controller.SetSword then controller:SetSword(getgenv().SwordAnimation or targetSword) end
                    if controller.SwordFX then controller.SwordFX = targetSword end
                end)
            end
        end
        local remote = ReplicatedStorage.Remotes:FindFirstChild("FireSwordInfo")
        if remote then pcall(function() remote:FireServer(targetSword) end) end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(2)
    swordInstances = nil
    skinChangerController = nil
    _hookedFuncs = {}
    if getgenv().SkinChangerEnabled then
        getgenv().SkinChangerEnabled = false
        task.wait(0.1)
        getgenv().SkinChangerEnabled = true
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            pcall(function()
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
                end
            end)
        end
        task.wait(0.5)
        setSword()
        hookParrySuccess()
        task.spawn(function()
            local controller = getSwordsController()
            if controller then
                pcall(function()
                    if controller.SetSword then controller:SetSword(getgenv().SwordAnimation or getgenv().SwordModel) end
                end)
            end
            local remote = ReplicatedStorage.Remotes:FindFirstChild("FireSwordInfo")
            if remote then pcall(function() remote:FireServer(getgenv().SwordFX or getgenv().SwordModel) end) end
        end)
    end
end)

getgenv().EnableSkinChanger = function()
    getgenv().SkinChangerEnabled = true
    updateSword()
    startSkinMonitor()
    hookParrySuccess()
    if not System.__properties.__connections.__skin_death then
        System.__properties.__connections.__skin_death = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(2)
            if getgenv().SkinChangerEnabled then setSword() end
        end)
    end
end

getgenv().DisableSkinChanger = function()
    getgenv().SkinChangerEnabled = false
    if System.__properties.__connections.__skin_monitor then
        System.__properties.__connections.__skin_monitor:Disconnect()
        System.__properties.__connections.__skin_monitor = nil
    end
end

getgenv().SetSword = function(name)
    getgenv().SwordModel = name
    getgenv().SwordAnimation = name
    getgenv().SwordFX = name
    if getgenv().SkinChangerEnabled then updateSword() end
end

getgenv().SkinChangerEnabled = false
getgenv().SwordModel = ""
getgenv().SwordAnimation = ""
getgenv().SwordFX = ""
getgenv().SlashName = "SlashEffect"

task.spawn(function() task.wait(2) hookParrySuccess() end)

-- ============================================================
-- ABILITY EXPLOIT (THUNDER DASH)
-- ============================================================
local function apply_thunder_dash_exploit()
    local shared = ReplicatedStorage:FindFirstChild('Shared')
    if not shared then return end
    local abilities = shared:FindFirstChild("Abilities")
    if not abilities then return end
    local thunderDashModule = abilities:FindFirstChild("Thunder Dash")
    if not thunderDashModule then return end
    local ok, mod = pcall(require, thunderDashModule)
    if ok and mod then
        pcall(function()
            mod.cooldown = 0
            mod.cooldownReductionPerUpgrade = 0
        end)
    end
end

-- ============================================================
-- NAME SPOOF
-- ============================================================
local SpoofConfig = { FakeName = ".gg/Azure", FakeDisplay = ".gg/Azure", Badge = utf8.char(0xE000), BadgeAlt = "✓", UseAltBadge = false, Separator = " " }
local SpoofBadge = SpoofConfig.UseAltBadge and SpoofConfig.BadgeAlt or SpoofConfig.Badge
local RealName = LocalPlayer.Name
local RealDisplay = LocalPlayer.DisplayName
local TargetSpoofName = SpoofConfig.FakeName
local TargetSpoofDisplay = SpoofConfig.FakeDisplay .. SpoofConfig.Separator .. SpoofBadge

local function escapePattern(text) return text:gsub("([^%w])", "%%%1") end
local RealNameEscaped = escapePattern(RealName)
local RealDisplayEscaped = escapePattern(RealDisplay)

local function SpoofText(obj)
    if not getgenv().NameSpoofEnabled or not obj.Text or obj.Text == "" then return end
    local text = obj.Text
    if text:find(SpoofConfig.FakeDisplay .. SpoofConfig.Separator .. SpoofBadge) then return end
    local newText = text
    if newText:find(RealDisplayEscaped) then newText = newText:gsub(RealDisplayEscaped, TargetSpoofDisplay) end
    if newText:find(RealNameEscaped) then newText = newText:gsub(RealNameEscaped, TargetSpoofName) end
    if newText ~= obj.Text then obj.Text = newText end
end

local function MonitorSpoofObject(obj)
    if not getgenv().NameSpoofEnabled then return end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        SpoofText(obj)
        obj:GetPropertyChangedSignal("Text"):Connect(function() SpoofText(obj) end)
    end
end

CoreGui.DescendantAdded:Connect(MonitorSpoofObject)
LocalPlayer.PlayerGui.DescendantAdded:Connect(MonitorSpoofObject)

getgenv().EnableNameSpoof = function()
    getgenv().NameSpoofEnabled = true
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.DisplayName = TargetSpoofDisplay end
    end
    if not System.__properties.__connections.__name_spoof then
        System.__properties.__connections.__name_spoof = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.DisplayName ~= TargetSpoofDisplay then hum.DisplayName = TargetSpoofDisplay end
            end
        end)
    end
end

getgenv().DisableNameSpoof = function()
    getgenv().NameSpoofEnabled = false
    pcall(function()
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.DisplayName = RealDisplay end
        end
    end)
    if System.__properties.__connections.__name_spoof then
        System.__properties.__connections.__name_spoof:Disconnect()
        System.__properties.__connections.__name_spoof = nil
    end
end

getgenv().SetSpoofedName = function(name)
    SpoofConfig.FakeName = name
    SpoofConfig.FakeDisplay = name
    TargetSpoofName = name
    TargetSpoofDisplay = name .. SpoofConfig.Separator .. SpoofBadge
end

getgenv().NameSpoofEnabled = false

-- ============================================================
-- HIT SOUNDS
-- ============================================================
local hitSoundOptions = {'Medal', "Fatality", 'Skeet', "Switches", "Rust Headshot", "Neverlose Sound", 'Bubble', 'Laser', 'Steve', "Call of Duty", 'Bat', "TF2 Critical", 'Saber', "Bameware"}
local hitSoundIds = {
    Medal = 'rbxassetid://6607336718', Fatality = 'rbxassetid://6607113255', Skeet = 'rbxassetid://6607204501',
    Switches = 'rbxassetid://6607173363', ["Rust Headshot"] = 'rbxassetid://138750331387064', ["Neverlose Sound"] = 'rbxassetid://110168723447153',
    Bubble = 'rbxassetid://6534947588', Laser = 'rbxassetid://7837461331', Steve = 'rbxassetid://4965083997',
    ["Call of Duty"] = 'rbxassetid://5952120301', Bat = 'rbxassetid://3333907347', ["TF2 Critical"] = 'rbxassetid://296102734',
    Saber = 'rbxassetid://8415678813', Bameware = 'rbxassetid://3124331820'
}
local hitSoundFolder = Instance.new('Folder', workspace) hitSoundFolder.Name = "HitSounds"
local hitSound = Instance.new('Sound', hitSoundFolder) hitSound.Volume = 5 hitSound.SoundId = hitSoundIds.Medal
local hitSoundEnabled = false
local hitSoundConnection = nil

local function setupHitSound()
    if hitSoundConnection then hitSoundConnection:Disconnect() end
    local remote = ReplicatedStorage.Remotes:FindFirstChild("ParrySuccess")
    if remote then
        hitSoundConnection = remote.OnClientEvent:Connect(function()
            if hitSoundEnabled then hitSound:Play() end
        end)
    end
end

function EnableHitSounds() hitSoundEnabled = true setupHitSound() end
function DisableHitSounds()
    hitSoundEnabled = false
    if hitSoundConnection then hitSoundConnection:Disconnect() hitSoundConnection = nil end
end
function SetHitSound(name) if hitSoundIds[name] then hitSound.SoundId = hitSoundIds[name] end end
function SetHitSoundVolume(vol) hitSound.Volume = math.clamp(vol, 1, 10) end

-- ============================================================
-- ABILITY DETECTIONS
-- ============================================================
local abilityDetections = { infinity = false, deathslash = false, timehole = false, slashesoffury = false, phantom = false, pull = false }

task.spawn(function()
    local rs = ReplicatedStorage:WaitForChild("Remotes", 5)
    if rs then
        pcall(function()
            rs.InfinityBall.OnClientEvent:Connect(function(a, b)
                abilityDetections.infinity = b or false
                if b and getgenv().InfinityDetection and getgenv().InfinityNotify then
                    if Window then Window:Notify("Detection", "⚠️ Infinity active!", 2) end
                end
            end)
            rs.DeathBall.OnClientEvent:Connect(function(c, d)
                abilityDetections.deathslash = d or false
                if d and getgenv().DeathSlashDetection and getgenv().DeathSlashNotify then
                    if Window then Window:Notify("Detection", "⚠️ Death Slash active!", 2) end
                end
            end)
            rs.Phantom.OnClientEvent:Connect(function(a, b)
                if b and b.Name == LocalPlayer.Name then
                    abilityDetections.phantom = true
                    if getgenv().PhantomDetection and getgenv().PhantomNotify then
                        if Window then Window:Notify("Detection", "⚠️ Phantom attack on you!", 2) end
                    end
                    task.delay(2, function() abilityDetections.phantom = false end)
                end
            end)
        end)
    end
    pcall(function()
        local pkgIdx = ReplicatedStorage:WaitForChild("Packages", 5):WaitForChild("_Index", 5):WaitForChild("sleitnick_net@0.1.0", 5)
        local net = pkgIdx:WaitForChild("net", 5)
        if net then
            local thRemote = net:FindFirstChild("RE/TimeHoleActivate")
            if thRemote then
                thRemote.OnClientEvent:Connect(function(player)
                    if player == LocalPlayer then
                        abilityDetections.timehole = true
                        if getgenv().TimeHoleDetection and getgenv().TimeHoleNotify then
                            if Window then Window:Notify("Detection", "⚠️ Time Hole on you!", 2) end
                        end
                    end
                end)
            end
            local thDeactivate = net:FindFirstChild("RE/TimeHoleDeactivate")
            if thDeactivate then thDeactivate.OnClientEvent:Connect(function() abilityDetections.timehole = false end) end
            local sfRemote = net:FindFirstChild("RE/SlashesOfFuryActivate")
            if sfRemote then
                sfRemote.OnClientEvent:Connect(function(player)
                    if player == LocalPlayer then
                        abilityDetections.slashesoffury = true
                        if getgenv().SlashesOfFuryDetection and getgenv().SlashesOfFuryNotify then
                            if Window then Window:Notify("Detection", "⚠️ Slashes of Fury active!", 2) end
                        end
                    end
                end)
            end
            local sfEnd = net:FindFirstChild("RE/SlashesOfFuryEnd")
            if sfEnd then sfEnd.OnClientEvent:Connect(function() abilityDetections.slashesoffury = false end) end
            local pullRemote = net:FindFirstChild("RE/PlrPulled") or net:FindFirstChild("RE/PlrPulsed")
            if pullRemote then
                pullRemote.OnClientEvent:Connect(function(player)
                    if player == LocalPlayer then
                        abilityDetections.pull = true
                        if getgenv().PullDetection and getgenv().PullNotify then
                            if Window then Window:Notify("Detection", "⚠️ You got pulled!", 2) end
                        end
                        task.delay(2, function() abilityDetections.pull = false end)
                    end
                end)
            end
        end
    end)
end)

getgenv().InfinityDetection = false
getgenv().DeathSlashDetection = false
getgenv().TimeHoleDetection = false
getgenv().SlashesOfFuryDetection = false
getgenv().PhantomDetection = false
getgenv().PullDetection = false
getgenv().InfinityNotify = false
getgenv().DeathSlashNotify = false
getgenv().TimeHoleNotify = false
getgenv().SlashesOfFuryNotify = false
getgenv().PhantomNotify = false
getgenv().PullNotify = false

-- ============================================================
-- STAFF DETECTION
-- ============================================================
local GROUP_ID = 12836673
local MIN_RANK = 10
local modActionMode = "Notification"
local staffDetected = {}

local function kickSelf() LocalPlayer:Kick("Staff detected. Disconnecting to avoid ban.") end

local function showModNotification(player)
    if Window then Window:Notify("Staff Alert", "⚠️ " .. player.Name .. " (Staff) joined!", 5) end
end

local function checkPlayer(player)
    local ok, rank = pcall(function() return player:GetRankInGroup(GROUP_ID) end)
    if ok and rank >= MIN_RANK and not staffDetected[player.UserId] then
        staffDetected[player.UserId] = true
        if modActionMode == "Kick" then kickSelf() else showModNotification(player) end
    end
end

task.spawn(function()
    task.wait(5)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then checkPlayer(player) end
    end
    Players.PlayerAdded:Connect(function(player)
        task.wait(2)
        checkPlayer(player)
    end)
end)

-- ============================================================
-- VISUALS & OPTIMIZATION
-- ============================================================
local VisualsState = { Trail = {}, Stats = {}, Vis = {}, FPS = {} }

local function clear_ball_trail(ball)
    if not ball then return end
    local t = ball:FindFirstChild('Trail') if t then t:Destroy() end
    local e = ball:FindFirstChild('ParticleEmitter') if e then e:Destroy() end
    local g = ball:FindFirstChild("BallGlow") if g then g:Destroy() end
    local a0 = ball:FindFirstChild("Attachment0") if a0 then a0:Destroy() end
    local a1 = ball:FindFirstChild("Attachment1") if a1 then a1:Destroy() end
    VisualsState.Trail[ball] = nil
end

local function apply_ball_trail(ball)
    if not ball then return end
    if not getgenv().BallTrailEnabled then clear_ball_trail(ball) return end
    if VisualsState.Trail[ball] then return end
    VisualsState.Trail[ball] = true
    local trail = Instance.new('Trail')
    local a0 = Instance.new('Attachment', ball) a0.Position = Vector3.new(0, ball.Size.Y / 2, 0) a0.Name = "Attachment0"
    local a1 = Instance.new('Attachment', ball) a1.Position = Vector3.new(0, -ball.Size.Y / 2, 0) a1.Name = "Attachment1"
    trail.Attachment0 = a0 trail.Attachment1 = a1
    trail.Lifetime = 0.4
    trail.WidthScale = NumberSequence.new(0.5)
    trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
    trail.Parent = ball
    if getgenv().BallTrailParticle then
        local em = Instance.new('ParticleEmitter', ball)
        em.Rate = 100 em.Lifetime = NumberRange.new(0.5, 1) em.Speed = NumberRange.new(0, 1)
    end
    if getgenv().BallTrailGlow then
        local gl = Instance.new('PointLight', ball) gl.Range = 15 gl.Brightness = 2
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        local ball = get_real_ball()
        if ball then apply_ball_trail(ball) end
    end
end)

getgenv().BallTrailEnabled = false
getgenv().BallTrailParticle = false
getgenv().BallTrailGlow = false
getgenv().BallTrailColor = Color3.new(1, 1, 1)

local function applyNoRender()
    if not getgenv().No_Render then return end
    pcall(function()
        local clientFX = ReplicatedStorage:FindFirstChild("ClientFX")
        if clientFX then clientFX:Destroy() end
        local runtime = workspace:FindFirstChild("Runtime")
        if runtime then
            runtime.ChildAdded:Connect(function(child) if getgenv().No_Render then child:Destroy() end end)
            for _, child in ipairs(runtime:GetChildren()) do child:Destroy() end
        end
    end)
end

local function applyHideServerRendering()
    if not getgenv().HideServerRendering then return end
    pcall(function()
        local runtime = workspace:FindFirstChild("Runtime")
        if runtime then
            for _, child in ipairs(runtime:GetChildren()) do
                if child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam") then child:Destroy() end
            end
        end
    end)
end

local function applyLowGraphics()
    if not getgenv().LowGraphics then return end
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        workspace.QualityLevel = Enum.QualityLevel.Level01
    end)
end

local function applySkyOverride()
    if not getgenv()._ZX_SkyColor then return end
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(100, 100, 100)
        Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    end)
end

local function applyAtmosphere()
    pcall(function()
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmo.Density = getgenv()._ZX_AtmoDensity or 30
        atmo.Offset = getgenv()._ZX_AtmoOffset or 25
        atmo.Glare = getgenv()._ZX_AtmoGlare or 0
        atmo.Haze = getgenv()._ZX_AtmoHaze or 10
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
        cc.Saturation = (getgenv()._ZX_CCSaturation or 100) / 100
        cc.Contrast = (getgenv()._ZX_CCContrast or 100) / 100
        cc.Brightness = (getgenv()._ZX_CCBrightness or 100) / 100 - 1
        Lighting.Brightness = getgenv()._ZX_LBrightness or 20
        Lighting.ClockTime = getgenv()._ZX_LClockTime or 14
        Lighting.FogEnd = getgenv()._ZX_LFogEnd or 100000
        Lighting.GlobalShadows = getgenv()._ZX_LShadows or false
    end)
end

local function applyHitEffect()
    if not getgenv().HitEffectEnabled then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local p = Instance.new("Part")
        p.Anchored = true p.CanCollide = false p.Transparency = 1 p.CFrame = hrp.CFrame p.Parent = workspace
        local em = Instance.new("ParticleEmitter", p)
        em.Texture = "rbxassetid://243660364"
        em.Lifetime = NumberRange.new(0.2, 0.4) em.Speed = NumberRange.new(10, 20) em.Rate = 0
        em.SpreadAngle = Vector2.new(360, 360) em.Color = ColorSequence.new(Color3.fromRGB(255, 200, 0))
        em:Emit(30)
        game:GetService("Debris"):AddItem(p, 1)
    end)
end

task.spawn(function()
    local remote = ReplicatedStorage.Remotes:FindFirstChild("ParrySuccess")
    if remote then remote.OnClientEvent:Connect(function() applyHitEffect() end) end
end)

local function applyShieldSlashColor()
    if not (getgenv().ShieldChangerEnabled or getgenv().SlashChangerEnabled) then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local colors = {
            Blue = Color3.fromRGB(0, 100, 255), Red = Color3.fromRGB(255, 0, 0), Green = Color3.fromRGB(0, 255, 0),
            Yellow = Color3.fromRGB(255, 255, 0), Purple = Color3.fromRGB(150, 0, 255), Cyan = Color3.fromRGB(0, 255, 255),
            White = Color3.fromRGB(255, 255, 255), Orange = Color3.fromRGB(255, 150, 0), Pink = Color3.fromRGB(255, 100, 255)
        }
        local sC = colors[getgenv().ShieldColor or "Blue"]
        local lC = colors[getgenv().SlashColor or "Blue"]
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("ParticleEmitter") then
                if getgenv().ShieldChangerEnabled and p.Name:lower():match("shield") then p.Color = ColorSequence.new(sC) end
                if getgenv().SlashChangerEnabled and p.Name:lower():match("slash") then p.Color = ColorSequence.new(lC) end
            end
        end
    end)
end

-- ============================================================
-- BALL ESP & VISUALS
-- ============================================================
local ballESPEnabled = false
local ballESPLabel = nil
local ballESPTracer = nil
local ballESPConnection = nil

function EnableBallESP()
    ballESPEnabled = true
    if Drawing then
        ballESPLabel = Drawing.new("Text")
        ballESPLabel.Size = 16 ballESPLabel.Center = true ballESPLabel.Outline = true
        ballESPLabel.Color = Color3.fromRGB(255, 255, 0) ballESPLabel.Font = 2
        ballESPTracer = Drawing.new("Line")
        ballESPTracer.Thickness = 2 ballESPTracer.Transparency = 1 ballESPTracer.Color = Color3.fromRGB(0, 255, 100)
    end
    if ballESPConnection then ballESPConnection:Disconnect() end
    ballESPConnection = RunService.RenderStepped:Connect(function()
        if not ballESPEnabled then return end
        local ball = get_real_ball()
        if not ball then
            if ballESPLabel then ballESPLabel.Visible = false end
            if ballESPTracer then ballESPTracer.Visible = false end
            return
        end
        local cam = workspace.CurrentCamera
        local pos, onScreen = cam:WorldToViewportPoint(ball.Position)
        local target = ball:GetAttribute("target") or "None"
        local zoomies = ball:FindFirstChild("zoomies")
        local speed = zoomies and zoomies.VectorVelocity.Magnitude or 0
        if ballESPLabel and onScreen then
            ballESPLabel.Text = target .. " | " .. math.floor(speed) .. " speed"
            ballESPLabel.Position = Vector2.new(pos.X, pos.Y - 30)
            ballESPLabel.Visible = true
        elseif ballESPLabel then ballESPLabel.Visible = false end
        if ballESPTracer and onScreen and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            local pp, ps = cam:WorldToViewportPoint(LocalPlayer.Character.PrimaryPart.Position)
            if ps then
                ballESPTracer.From = Vector2.new(pp.X, pp.Y)
                ballESPTracer.To = Vector2.new(pos.X, pos.Y)
                ballESPTracer.Visible = true
            else ballESPTracer.Visible = false end
        elseif ballESPTracer then ballESPTracer.Visible = false end
    end)
end

function DisableBallESP()
    ballESPEnabled = false
    if ballESPConnection then ballESPConnection:Disconnect() end
    if ballESPLabel then ballESPLabel:Remove() end
    if ballESPTracer then ballESPTracer:Remove() end
    ballESPConnection, ballESPLabel, ballESPTracer = nil, nil, nil
end

local CurveDebug = { enabled = false, labels = {} }

function EnableCurveDebug()
    CurveDebug.enabled = true
    task.spawn(function()
        while CurveDebug.enabled do
            pcall(function()
                local balls = get_all_balls()
                for _, ball in ipairs(balls) do
                    local data = FastCurveDetection.data[ball]
                    if data then
                        local label = CurveDebug.labels[ball]
                        if not label and Drawing then
                            label = Drawing.new("Text")
                            label.Size = 12 label.Center = true label.Outline = true
                            label.Color = Color3.fromRGB(255, 255, 255) label.Font = 2
                            CurveDebug.labels[ball] = label
                        end
                        if label then
                            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(ball.Position)
                            if onScreen then
                                local status = "Normal"
                                local color = Color3.fromRGB(0, 255, 0)
                                if data.confidence > 0.3 then status = "CURVED!" color = Color3.fromRGB(255, 0, 0) end
                                label.Text = string.format("%s | A:%.1f | C:%.2f", status, data.lastAngle or 0, data.confidence or 0)
                                label.Position = Vector2.new(pos.X, pos.Y - 40)
                                label.Color = color label.Visible = true
                            else label.Visible = false end
                        end
                    end
                end
            end)
            task.wait(0.05)
        end
    end)
end

function DisableCurveDebug()
    CurveDebug.enabled = false
    for _, label in pairs(CurveDebug.labels) do pcall(function() label:Remove() end) end
    CurveDebug.labels = {}
end

local abilityESPEnabled = false
local abilityEspBillboards = {}
local abilityEspConnections = {}
local abilityEspPlayerAdded = nil

local function createAbilityESP(player)
    task.spawn(function()
        local char = player.Character
        while not char or not char.Parent do task.wait() char = player.Character end
        local head = char:WaitForChild('Head', 10)
        if not head or not abilityESPEnabled then return end
        local existing = head:FindFirstChild("AbilityESPGui")
        if existing then existing:Destroy() end
        local bb = Instance.new('BillboardGui', head)
        bb.Name = "AbilityESPGui" bb.Size = UDim2.new(0, 200, 0, 40) bb.StudsOffset = Vector3.new(0, 3.5, 0) bb.AlwaysOnTop = true
        local lbl = Instance.new('TextLabel', bb)
        lbl.Size = UDim2.new(1, 0, 1, 0) lbl.BackgroundTransparency = 1 lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 14 lbl.Font = Enum.Font.GothamBold lbl.RichText = true
        lbl.TextXAlignment = Enum.TextXAlignment.Center lbl.TextYAlignment = Enum.TextYAlignment.Center lbl.Visible = false
        abilityEspBillboards[player] = lbl
        local conn = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent then
                if conn then conn:Disconnect() end
                pcall(function() bb:Destroy() end)
                abilityEspBillboards[player] = nil
                return
            end
            if abilityESPEnabled then
                lbl.Visible = true
                local ability = player:GetAttribute("EquippedAbility")
                if ability then lbl.Text = '<b>' .. player.DisplayName .. ' [' .. ability .. ']' .. "</b>"
                else lbl.Text = '<b>' .. player.DisplayName .. "</b>" end
            else lbl.Visible = false end
        end)
        abilityEspConnections[player] = conn
    end)
end

function EnableAbilityESP()
    abilityESPEnabled = true
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then createAbilityESP(player) end
    end
    if not abilityEspPlayerAdded then
        abilityEspPlayerAdded = Players.PlayerAdded:Connect(function(player)
            if abilityESPEnabled then createAbilityESP(player) end
        end)
    end
end

function DisableAbilityESP()
    abilityESPEnabled = false
    if abilityEspPlayerAdded then abilityEspPlayerAdded:Disconnect() end
    for _, conn in pairs(abilityEspConnections) do conn:Disconnect() end
    for _, label in pairs(abilityEspBillboards) do
        if label and label.Parent then label.Parent:Destroy() end
    end
    abilityEspBillboards, abilityEspConnections = {}, {}
    abilityEspPlayerAdded = nil
end

local ballStatsGui = nil
local ballStatsVal = nil

function EnableBallStats()
    if ballStatsGui then return end
    local sg = Instance.new('ScreenGui', CoreGui) sg.Name = "BallStatsGui" sg.ResetOnSpawn = false
    local pan = Instance.new('Frame', sg) pan.Size = UDim2.new(0, 140, 0, 60) pan.Position = UDim2.new(0, 15, 0.5, -30)
    pan.BackgroundColor3 = Color3.fromRGB(20, 20, 30) pan.BackgroundTransparency = 0.2
    Instance.new('UICorner', pan).CornerRadius = UDim.new(0, 8)
    local title = Instance.new('TextLabel', pan) title.Size = UDim2.new(1, 0, 0, 20) title.BackgroundTransparency = 1
    title.Text = "BALL STATS" title.TextColor3 = Color3.fromRGB(255, 255, 255) title.Font = Enum.Font.GothamBold title.TextSize = 12
    ballStatsVal = Instance.new('TextLabel', pan) ballStatsVal.Size = UDim2.new(1, 0, 0, 25) ballStatsVal.Position = UDim2.new(0, 0, 0, 22)
    ballStatsVal.BackgroundTransparency = 1 ballStatsVal.Text = "0" ballStatsVal.TextColor3 = Color3.fromRGB(255, 255, 255)
    ballStatsVal.Font = Enum.Font.GothamBold ballStatsVal.TextSize = 16
    ballStatsGui = sg
    local peak = 0
    VisualsState.Stats.conn = RunService.RenderStepped:Connect(function()
        local ball = get_real_ball()
        local speed = 0
        if ball then speed = (ball.AssemblyLinearVelocity or Vector3.new()).Magnitude end
        if speed > peak then peak = speed end
        ballStatsVal.Text = string.format("%.1f", speed) .. " | Peak: " .. string.format("%.1f", peak)
    end)
end

function DisableBallStats()
    if VisualsState.Stats.conn then VisualsState.Stats.conn:Disconnect() end
    if ballStatsGui then ballStatsGui:Destroy() end
    ballStatsGui, ballStatsVal = nil, nil
end

local fpsPingGui = nil

function EnableFPSPing()
    if fpsPingGui then return end
    local sg = Instance.new('ScreenGui', CoreGui) sg.Name = "FpsPingGui" sg.ResetOnSpawn = false
    local fr = Instance.new('Frame', sg) fr.Size = UDim2.new(0, 100, 0, 40) fr.Position = UDim2.new(1, -110, 0, 15)
    fr.BackgroundColor3 = Color3.fromRGB(20, 20, 30) fr.BackgroundTransparency = 0.2
    Instance.new('UICorner', fr).CornerRadius = UDim.new(0, 8)
    local fps = Instance.new('TextLabel', fr) fps.Size = UDim2.new(0.5, 0, 1, 0) fps.BackgroundTransparency = 1 fps.TextColor3 = Color3.fromRGB(100, 255, 100) fps.Font = Enum.Font.Gotham fps.TextSize = 12
    local png = Instance.new('TextLabel', fr) png.Size = UDim2.new(0.5, 0, 1, 0) png.Position = UDim2.new(0.5, 0, 0, 0) png.BackgroundTransparency = 1 png.TextColor3 = Color3.fromRGB(100, 255, 100) png.Font = Enum.Font.Gotham png.TextSize = 12
    fpsPingGui = {gui = sg, fps = fps, png = png}
    local fc, el = 0, 0
    VisualsState.FPS.conn = RunService.RenderStepped:Connect(function(dt)
        fc = fc + 1 el = el + dt
        if el >= 0.5 then
            local s = math.round(fc / el)
            fps.Text = "FPS: " .. tostring(s)
            fc, el = 0, 0
        end
    end)
    task.spawn(function()
        while fpsPingGui and fpsPingGui.gui.Parent do
            local p = math.round(LocalPlayer:GetNetworkPing() * 1000)
            png.Text = "PING: " .. tostring(p)
            task.wait(0.5)
        end
    end)
end

function DisableFPSPing()
    if VisualsState.FPS.conn then VisualsState.FPS.conn:Disconnect() end
    if fpsPingGui then fpsPingGui.gui:Destroy() end
    fpsPingGui = nil
end

local visualiserModel = nil

function EnableVisualiser()
    if visualiserModel then return end
    visualiserModel = Instance.new('Model', workspace) visualiserModel.Name = "VisualiserModel"
    local edges = {}
    for i = 1, 128 do
        local edge = Instance.new('Part', visualiserModel) edge.Anchored = true edge.CanCollide = false edge.CastShadow = false
        edge.Material = Enum.Material.Neon edge.Color = Color3.fromRGB(100, 50, 200) edge.Transparency = 0.25
        edge.Size = Vector3.new(0.08, 0.08, 0.18)
        edges[i] = edge
    end
    VisualsState.Vis.conn = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        local speed = 0
        local ball = get_real_ball()
        if ball then speed = math.min((ball.AssemblyLinearVelocity or Vector3.new()).Magnitude, 350) / 6.5 end
        local radius = math.max(speed, 6.5) * 0.5
        local segLen = math.max(0.25, (2 * math.pi * radius) / 128)
        for i, edge in ipairs(edges) do
            local angle = (i - 1) * (2 * math.pi / 128)
            edge.Size = Vector3.new(0.05, 0.05, segLen)
            edge.CFrame = hrp.CFrame * CFrame.new(math.cos(angle) * radius, -3.0, math.sin(angle) * radius) * CFrame.Angles(0, angle + math.pi / 2, 0)
        end
    end)
end

function DisableVisualiser()
    if VisualsState.Vis.conn then VisualsState.Vis.conn:Disconnect() end
    if visualiserModel then visualiserModel:Destroy() end
    visualiserModel = nil
end

-- ============================================================
-- AUTOPLAY
-- ============================================================
local AutoPlayState = {
    enabled = false, connection = nil, elapsed = 0, control_point = nil, double_jumped = false, ball = nil,
}

local function auto_play_get_target_position()
    local ball = get_real_ball() or AutoPlayState.ball
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if not ball or not hrp then return nil end
    AutoPlayState.ball = ball
    local direction = (hrp.Position - ball.Position).Unit
    local zoomies = ball:FindFirstChild("zoomies")
    local speed = zoomies and zoomies.VectorVelocity.Magnitude or 0
    local distance = 15 + math.min(speed / 10, 20)
    local currentTime = os.time() / 1.5
    local sine = math.sin(currentTime) * 6
    local cosine = math.cos(currentTime) * 6
    local traversing = Vector3.new(sine, 0, cosine)
    return ball.Position + direction * distance + traversing
end

local function auto_play_step()
    if not AutoPlayState.enabled then return end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass('Humanoid')
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if not humanoid or not hrp or humanoid.Health <= 0 then return end
    if humanoid.FloorMaterial ~= Enum.Material.Air then AutoPlayState.double_jumped = false end
    local targetPosition = auto_play_get_target_position()
    if targetPosition then
        humanoid:MoveTo(targetPosition)
        local dist = (hrp.Position - targetPosition).Magnitude
        if dist > 20 then humanoid.WalkSpeed = 50
        elseif dist > 10 then humanoid.WalkSpeed = 36
        else humanoid.WalkSpeed = 24 end
    end
    if getgenv().AutoPlayJumpingEnabled and math.random(1, 100) <= (getgenv().AutoPlayJumpPercentage or 20) then
        if humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif not AutoPlayState.double_jumped and math.random(1, 100) <= (getgenv().AutoPlayDoubleJumpPercentage or 10) then
            local bodyVelocity = Instance.new('BodyVelocity')
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.new(0, 40, 0)
            bodyVelocity.Parent = hrp
            game:GetService('Debris'):AddItem(bodyVelocity, 0.1)
            AutoPlayState.double_jumped = true
        end
    end
end

local function startAutoPlay()
    AutoPlayState.enabled = true
    if AutoPlayState.connection then AutoPlayState.connection:Disconnect() AutoPlayState.connection = nil end
    AutoPlayState.connection = RunService.RenderStepped:Connect(auto_play_step)
end

-- ============================================================
-- ORBIT & LOOK AT BALL
-- ============================================================
local function applyOrbitBall()
    if not getgenv()._ZX_OrbitBall then return end
    local ball = get_real_ball()
    local char = LocalPlayer.Character
    if not ball or not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local radius = getgenv()._ZX_OrbitRadius or 14
    local speed = getgenv()._ZX_OrbitSpeed or 4
    local t = tick() * speed
    local targetPos = ball.Position + Vector3.new(math.cos(t) * radius, 0, math.sin(t) * radius)
    hrp.CFrame = CFrame.new(hrp.Position:Lerp(targetPos, 0.1), ball.Position)
end

local function applyLookAtBall()
    if not getgenv()._ZX_LookAtBall then return end
    local ball = get_real_ball()
    if not ball then return end
    local cam = workspace.CurrentCamera
    local targetPos = ball.Position
    if getgenv()._ZX_SmoothLook then
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, targetPos), 0.1)
    else
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        pcall(function() applyOrbitBall() applyLookAtBall() end)
    end
end)

-- ============================================================
-- AUTO VOTE & ANTI AFK
-- ============================================================
task.spawn(function()
    while true do
        task.wait(5)
        if getgenv().AutoVote then
            pcall(function()
                local remote = ReplicatedStorage.Remotes:FindFirstChild("UpdateVotes")
                if remote then remote:FireServer(math.random(1, 3)) end
            end)
        end
    end
end)

task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if getgenv().AutoPlayAntiAFK then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end)
end)

-- ============================================================
-- SOUND CONTROLLER
-- ============================================================
local SoundOptions = {
    ["Eeyuh"] = "rbxassetid://16190782181", ["Sour Grapes"] = "rbxassetid://117820392172291",
    ["Erwachen"] = "rbxassetid://124853612881772", ["Grasp the Light"] = "rbxassetid://89549155689397",
    ["Beyond the Shadows"] = "rbxassetid://120729792529978", ["Rise to the Horizon"] = "rbxassetid://72573266268313",
    ["Lo-fi Chill A"] = "rbxassetid://9043887091", ["Lo-fi Ambient"] = "rbxassetid://129775776987523",
    ["Tears in the Rain"] = "rbxassetid://129710845038263",
}
local SoundNames = { "Eeyuh", "Sour Grapes", "Erwachen", "Grasp the Light", "Beyond the Shadows", "Rise to the Horizon", "Lo-fi Chill A", "Lo-fi Ambient", "Tears in the Rain" }

local SoundState = { enabled = false, loop = false, volume = 3, selected = "Eeyuh" }
local currentSound = Instance.new("Sound")
currentSound.Volume = SoundState.volume currentSound.Looped = SoundState.loop currentSound.Parent = game:GetService("SoundService")

local function playSoundById(soundId) pcall(function() currentSound:Stop() currentSound.SoundId = soundId currentSound:Play() end) end
local function updateSound()
    if SoundState.enabled then playSoundById(SoundOptions[SoundState.selected] or SoundOptions.Eeyuh)
    else pcall(function() currentSound:Stop() end) end
end

getgenv().EnableSoundController = function(val) SoundState.enabled = val updateSound() end
getgenv().SetSoundLoop = function(val) SoundState.loop = val currentSound.Looped = val end
getgenv().SetSoundVolume = function(vol) SoundState.volume = math.clamp(vol, 1, 5) currentSound.Volume = SoundState.volume end
getgenv().SetSoundSong = function(name) if SoundOptions[name] then SoundState.selected = name if SoundState.enabled then updateSound() end end end

SetProgress(0.7, "Loading UI library...")

-- ============================================================
-- UI LOAD
-- ============================================================
local StreamUI = nil
local success, err = pcall(function()
    StreamUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/naturaldesire23/Bxbx/refs/heads/main/StreamUI.lua"))()
end)

if not success or not StreamUI then
    SetProgress(1.0, "UI Load Failed!")
    task.wait(1)
    LoadingGui:Destroy()
    LocalPlayer:Kick("UI Library failed to load. Check your internet or executor HttpGet support.")
    return
end

local Window = StreamUI:CreateWindow("Apex Premium")

SetProgress(0.9, "Building interface...")

local MainTab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://76499042599127" })
local DetectionsTab = Window:CreateTab({ Name = "Detections", Icon = "rbxassetid://10734951847" })
local PlayerTab = Window:CreateTab({ Name = "Player", Icon = "rbxassetid://126017907477623" })
local SkinTab = Window:CreateTab({ Name = "Skin Changer", Icon = "rbxassetid://10734966248" })
local VisTab = Window:CreateTab({ Name = "Visuals", Icon = "rbxassetid://10709781460" })
local ExploitsTab = Window:CreateTab({ Name = "Exploits", Icon = "rbxassetid://10734951847" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "rbxassetid://132243429647479" })

if MainTab then
    MainTab:CreateToggle({ Title = "Auto Parry", Default = false, Callback = function(v) System.__properties.__autoparry_enabled = v if v then System.autoparry.start() else System.autoparry.stop() end end })
    MainTab:CreateToggle({ Title = "Auto Spam", Default = false, Callback = function(v) System.__properties.__auto_spam_enabled = v if v then System.auto_spam.start() else System.auto_spam.stop() end end })
    MainTab:CreateToggle({ Title = "Manual Spam", Default = false, Callback = function(v) System.__properties.__manual_spam_enabled = v if v then EnableManualSpam(System.__properties.__manual_spam_cps) else DisableManualSpam() end end })
    MainTab:CreateSlider({ Title = "Manual Spam CPS", Min = 1, Max = 999, Default = 200, Callback = function(v) System.__properties.__manual_spam_cps = v if ManualSpam.enabled then SetManualSpamCPS(v) end end })
    MainTab:CreateToggle({ Title = "Triggerbot", Default = false, Callback = function(v) System.__properties.__triggerbot_enabled = v if v then System.triggerbot.start() else System.triggerbot.stop() end end })
    MainTab:CreateToggle({ Title = "Animation Fix", Default = false, Callback = function(v) System.__properties.__animation_fix = v end })
    MainTab:CreateDropdown({ Title = "Parry Mode", Options = { "Remote", "Keypress" }, Default = "Remote", Callback = function(v) getgenv().AutoParryMode = v end })
    MainTab:CreateDropdown({ Title = "Curve Mode", Options = System.__config.__curve_names, Default = System.__config.__curve_names[1], Callback = function(v) for i,name in ipairs(System.__config.__curve_names) do if name == v then System.__properties.__curve_mode = i break end end end })
    MainTab:CreateSlider({ Title = "Parry Accuracy", Min = 1, Max = 100, Default = 50, Callback = function(v) System.__properties.__accuracy = v update_divisor() end })
    MainTab:CreateSlider({ Title = "Auto Spam CPS", Min = 50, Max = 500, Default = 300, Callback = function(v) System.__properties.__spam_threshold = v end })
end

if DetectionsTab then
    DetectionsTab:CreateLabel("═ Ability Detections ═")
    DetectionsTab:CreateToggle({Title="Infinity Detection",Default=false,Callback=function(v) getgenv().InfinityDetection=v end})
    DetectionsTab:CreateToggle({Title="Infinity Notify",Default=false,Callback=function(v) getgenv().InfinityNotify=v end})
    DetectionsTab:CreateToggle({Title="Death Slash Detection",Default=false,Callback=function(v) getgenv().DeathSlashDetection=v end})
    DetectionsTab:CreateToggle({Title="Death Slash Notify",Default=false,Callback=function(v) getgenv().DeathSlashNotify=v end})
    DetectionsTab:CreateToggle({Title="Time Hole Detection",Default=false,Callback=function(v) getgenv().TimeHoleDetection=v end})
    DetectionsTab:CreateToggle({Title="Time Hole Notify",Default=false,Callback=function(v) getgenv().TimeHoleNotify=v end})
    DetectionsTab:CreateToggle({Title="Slashes of Fury Detection",Default=false,Callback=function(v) getgenv().SlashesOfFuryDetection=v end})
    DetectionsTab:CreateToggle({Title="Slashes of Fury Notify",Default=false,Callback=function(v) getgenv().SlashesOfFuryNotify=v end})
    DetectionsTab:CreateToggle({Title="Phantom Detection",Default=false,Callback=function(v) getgenv().PhantomDetection=v end})
    DetectionsTab:CreateToggle({Title="Phantom Notify",Default=false,Callback=function(v) getgenv().PhantomNotify=v end})
    DetectionsTab:CreateToggle({Title="Pull Detection",Default=false,Callback=function(v) getgenv().PullDetection=v end})
    DetectionsTab:CreateToggle({Title="Pull Notify",Default=false,Callback=function(v) getgenv().PullNotify=v end})
    DetectionsTab:CreateButton({Title="Check Detection Status",Callback=function() local m="Infinity: "..tostring(abilityDetections.infinity).."\nDeathSlash: "..tostring(abilityDetections.deathslash).."\nTimeHole: "..tostring(abilityDetections.timehole).."\nSlashesOfFury: "..tostring(abilityDetections.slashesoffury).."\nPhantom: "..tostring(abilityDetections.phantom).."\nPull: "..tostring(abilityDetections.pull) Window:Notify("Detection Status",m,5) end})
    DetectionsTab:CreateLabel("═ Staff Detection ═")
    DetectionsTab:CreateDropdown({Title="Staff Action Mode",Options={"Notification","Kick"},Default="Notification",Callback=function(v) modActionMode=v end})
end

if PlayerTab then
    PlayerTab:CreateToggle({Title="Fly",Default=false,Callback=function(v) if v then EnableFly() else DisableFly() end end})
    PlayerTab:CreateSlider({Title="Fly Speed",Min=10,Max=200,Default=50,Callback=function(v) SetFlySpeed(v) end})
    PlayerTab:CreateToggle({Title="Walk Speed",Default=false,Callback=function(v) if v then EnableWalkSpeed() else DisableWalkSpeed() end end})
    PlayerTab:CreateSlider({Title="Walk Speed Value",Min=16,Max=100,Default=36,Callback=function(v) SetWalkSpeed(v) end})
    PlayerTab:CreateToggle({Title="Semi Immortality",Default=false,Callback=function(v) if v then EnableSemiImmortal() else DisableSemiImmortal() end end})
    PlayerTab:CreateToggle({Title="Fake Headless & Korblox",Default=false,Callback=function(v) System.__properties.__fake_body_enabled=v if v then if LocalPlayer.Character then applyFakeBody(LocalPlayer.Character) end else if LocalPlayer.Character then local rl=LocalPlayer.Character:FindFirstChild("Right Leg") or LocalPlayer.Character:FindFirstChild("RightLowerLeg") if rl then rl.Transparency=0 end local h=LocalPlayer.Character:FindFirstChild("Head") if h then h.Transparency=0 end end end end})
    PlayerTab:CreateToggle({Title="Name Spoof",Default=false,Callback=function(v) if v then getgenv().EnableNameSpoof() else getgenv().DisableNameSpoof() end end})
    PlayerTab:CreateTextbox({Title="Fake Name",Placeholder="Enter fake name...",Default=".gg/Azure",Callback=function(t,e) if t~="" then getgenv().SetSpoofedName(t) end end})
    PlayerTab:CreateToggle({Title="Fake Winstreak",Default=false,Callback=function(v) if v then getgenv().EnableFakeWinstreak() else getgenv().DisableFakeWinstreak() end end})
    PlayerTab:CreateSlider({Title="Fake Winstreak Value",Min=1,Max=9999,Default=100,Callback=function(v) getgenv().SetFakeWinstreakValue(v) end})
    PlayerTab:CreateLabel("═ Avatar Copier ═")
    PlayerTab:CreateTextbox({Title="Copy Avatar From",Placeholder="Enter player name...",Default="",Callback=function(t,e) if t~="" then local s=CopyAvatar(t) if s then Window:Notify("Avatar Copier","Copying: "..t,3) else Window:Notify("Avatar Copier","Player not found!",2) end end end})
    PlayerTab:CreateButton({Title="Stop Copying",Callback=function() StopAvatarCopier() Window:Notify("Avatar Copier","Stopped!",2) end})
    PlayerTab:CreateLabel("═ Automation ═")
    PlayerTab:CreateToggle({Title="Auto Play",Default=false,Callback=function(v) if v then startAutoPlay() else AutoPlayState.enabled = false end end})
    PlayerTab:CreateToggle({Title="Auto Play Jumping",Default=false,Callback=function(v) getgenv().AutoPlayJumpingEnabled=v end})
    PlayerTab:CreateToggle({Title="Anti-AFK",Default=false,Callback=function(v) getgenv().AutoPlayAntiAFK=v end})
    PlayerTab:CreateToggle({Title="Auto Vote",Default=false,Callback=function(v) getgenv().AutoVote=v end})
end

if SkinTab then
    SkinTab:CreateToggle({Title="Enable Skin Changer",Default=false,Callback=function(v) if v then getgenv().EnableSkinChanger() else getgenv().DisableSkinChanger() end end})
    SkinTab:CreateTextbox({Title="Sword Name",Placeholder="Enter sword name...",Default="",Callback=function(t,e) if t~="" then getgenv().SetSword(t) end end})
end

if VisTab then
    VisTab:CreateToggle({Title="Ball Trail",Default=false,Callback=function(v) getgenv().BallTrailEnabled=v if not v then local b=workspace:FindFirstChild('Balls') if b then for _,x in ipairs(b:GetChildren()) do clear_ball_trail(x) end end end end})
    VisTab:CreateToggle({Title="Ball Stats",Default=false,Callback=function(v) if v then EnableBallStats() else DisableBallStats() end end})
    VisTab:CreateToggle({Title="FPS / Ping",Default=false,Callback=function(v) if v then EnableFPSPing() else DisableFPSPing() end end})
    VisTab:CreateToggle({Title="Visualiser",Default=false,Callback=function(v) if v then EnableVisualiser() else DisableVisualiser() end end})
    VisTab:CreateToggle({Title="Ball ESP",Default=false,Callback=function(v) if v then EnableBallESP() else DisableBallESP() end end})
    VisTab:CreateToggle({Title="Ability ESP",Default=false,Callback=function(v) if v then EnableAbilityESP() else DisableAbilityESP() end end})
    VisTab:CreateToggle({Title="Curve Debug",Default=false,Callback=function(v) if v then EnableCurveDebug() else DisableCurveDebug() end end})
    VisTab:CreateLabel("═ Camera & Ball ═")
    VisTab:CreateToggle({Title="Orbit Ball",Default=false,Callback=function(v) getgenv()._ZX_OrbitBall=v end})
    VisTab:CreateSlider({Title="Orbit Radius",Min=5,Max=30,Default=14,Callback=function(v) getgenv()._ZX_OrbitRadius=v end})
    VisTab:CreateToggle({Title="Look At Ball",Default=false,Callback=function(v) getgenv()._ZX_LookAtBall=v end})
    VisTab:CreateToggle({Title="Smooth Look",Default=false,Callback=function(v) getgenv()._ZX_SmoothLook=v end})
    VisTab:CreateLabel("═ Graphics & Lighting ═")
    VisTab:CreateToggle({Title="No Render (Hide FX)",Default=false,Callback=function(v) getgenv().No_Render=v applyNoRender() end})
    VisTab:CreateToggle({Title="Hide Server Rendering",Default=false,Callback=function(v) getgenv().HideServerRendering=v applyHideServerRendering() end})
    VisTab:CreateToggle({Title="Hit Effect",Default=false,Callback=function(v) getgenv().HitEffectEnabled=v end})
    VisTab:CreateToggle({Title="Low Graphics",Default=false,Callback=function(v) getgenv().LowGraphics=v applyLowGraphics() end})
    VisTab:CreateToggle({Title="Sky Color Override",Default=false,Callback=function(v) getgenv()._ZX_SkyColor=v applySkyOverride() end})
    VisTab:CreateButton({Title="Apply Atmosphere/CC",Callback=function() applyAtmosphere() Window:Notify("Visuals","Atmosphere applied!",2) end})
    VisTab:CreateLabel("═ Shield/Slash Color ═")
    VisTab:CreateToggle({Title="Shield Changer",Default=false,Callback=function(v) getgenv().ShieldChangerEnabled=v applyShieldSlashColor() end})
    VisTab:CreateDropdown({Title="Shield Color",Options={"Blue","Red","Green","Yellow","Purple","Cyan","White","Orange","Pink"},Default="Blue",Callback=function(v) getgenv().ShieldColor=v applyShieldSlashColor() end})
    VisTab:CreateToggle({Title="Slash Changer",Default=false,Callback=function(v) getgenv().SlashChangerEnabled=v applyShieldSlashColor() end})
    VisTab:CreateDropdown({Title="Slash Color",Options={"Blue","Red","Green","Yellow","Purple","Cyan","White","Orange","Pink"},Default="Blue",Callback=function(v) getgenv().SlashColor=v applyShieldSlashColor() end})
end

if ExploitsTab then
    ExploitsTab:CreateToggle({Title="Thunder Dash No Cooldown",Default=false,Callback=function(v) getgenv().AbilityExploit=v getgenv().ThunderDashNoCooldown=v if v then if not System.__properties.__connections.__tdash then System.__properties.__connections.__tdash=RunService.Heartbeat:Connect(function() if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then apply_thunder_dash_exploit() end end) end else if System.__properties.__connections.__tdash then System.__properties.__connections.__tdash:Disconnect() System.__properties.__connections.__tdash=nil end end end})
    ExploitsTab:CreateToggle({Title="Hit Sounds",Default=false,Callback=function(v) if v then EnableHitSounds() else DisableHitSounds() end end})
    ExploitsTab:CreateDropdown({Title="Hit Sound",Options=hitSoundOptions,Default="Medal",Callback=function(v) SetHitSound(v) end})
    ExploitsTab:CreateSlider({Title="Hit Sound Volume",Min=1,Max=10,Default=5,Callback=function(v) SetHitSoundVolume(v) end})
    ExploitsTab:CreateLabel("═ Sound Controller ═")
    ExploitsTab:CreateToggle({Title="Enable Music",Default=false,Callback=function(v) getgenv().EnableSoundController(v) end})
    ExploitsTab:CreateToggle({Title="Loop Song",Default=false,Callback=function(v) getgenv().SetSoundLoop(v) end})
    ExploitsTab:CreateSlider({Title="Music Volume",Min=1,Max=5,Default=3,Callback=function(v) getgenv().SetSoundVolume(v) end})
    ExploitsTab:CreateDropdown({Title="Select Song",Options=SoundNames,Default="Eeyuh",Callback=function(v) getgenv().SetSoundSong(v) end})
    ExploitsTab:CreateButton({Title="Check Detections",Callback=function() local m="Infinity: "..tostring(abilityDetections.infinity).."\nDeathSlash: "..tostring(abilityDetections.deathslash).."\nPhantom: "..tostring(abilityDetections.phantom) Window:Notify("Detections",m,5) end})
end

if SettingsTab then
    local uiScale=nil local streamGui
    for _,g in ipairs(CoreGui:GetChildren()) do if g:IsA("ScreenGui") and(g.Name:match("Stream") or g.Name:match("Apex")) then streamGui=g break end end
    if streamGui then uiScale=streamGui:FindFirstChild("UIScale") or Instance.new("UIScale") uiScale.Parent=streamGui uiScale.Scale=1.0 end
    SettingsTab:CreateSlider({Title="UI Scale",Min=50,Max=150,Default=100,Callback=function(v) if uiScale then uiScale.Scale=v/100 end end})
    SettingsTab:CreateButton({Title="Status",Callback=function()
        print("========================================")
        print("[Apex Premium] Status")
        print("  Parry Patch Ready: "..(_PARRY_PATCH.ready and "YES" or "NO"))
        print("  Auto Parry: "..(System.__properties.__autoparry_enabled and "ON" or "OFF"))
        print("  Auto Spam: "..(System.__properties.__auto_spam_enabled and "ON" or "OFF"))
        print("  Manual Spam: "..(ManualSpam.enabled and "ON" or "OFF"))
        print("  Triggerbot: "..(System.__properties.__triggerbot_enabled and "ON" or "OFF"))
        print("  Fly: "..(flyEnabled and "ON" or "OFF"))
        print("  Walk Speed: "..(walkSpeedEnabled and "ON" or "OFF"))
        print("  Semi Immortal: "..(semiImmortalActive and "ON" or "OFF"))
        print("  Avatar Copier: "..(avatarCopierActive and "ON" or "OFF"))
        print("  Fake Winstreak: "..(System.__properties.__fake_winstreak_enabled and "ON" or "OFF"))
        print("========================================")
    end})
end

getgenv().AutoParryMode = "Remote"
update_divisor()
SetProgress(1.0, "Loaded!")
task.wait(1)
LoadingGui:Destroy()
Window:Notify("Loaded", "Apex Premium Ready!", 3)

--// Garden Tower Defense - Optimized Macro System v2.1
local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Rain-Design/Libraries/main/Shaman/Library.lua'))()
local Flags = Library.Flags

local Players      = game:GetService("Players")
local plr          = Players.LocalPlayer
local rs           = game:GetService("ReplicatedStorage")
local remotes      = rs:WaitForChild("RemoteFunctions")
local Workspace    = game:GetService("Workspace")
local RunService   = game:GetService("RunService")

-- Compatibility
local isFile = writefile and readfile and isfolder and makefolder and listfiles and delfile
local canHook = hookmetamethod ~= nil

-- Settings
local Settings = {
    MacroEnabled      = false,
    PositionOffset    = 2,
    UsePositionOffset = true,
    AutoWalk          = false,
    AutoUpgrade       = true,
    UpgradeDelay      = 125,
    MacroPaused       = false,

    AutoDifficulty    = "dif_normal",
    AutoMap           = "map_dojo",
    AutoSkipWaves     = true,
    TickSpeed         = 3,
    AutoRestart       = true,
    RestartDelay      = 12,
}

-- Recorder
local Recorder = {
    IsRecording = false,
    StartTime   = 0,
    Actions     = {},
    MacroName   = "MyMacro",
    LastMoney   = 0,
}

-- Global state
_G.myUnitIDs          = _G.myUnitIDs or {}
_G.trackingEnabled    = false
_G.upgradeLoopRunning = false
_G.autoWalkConnection = nil
_G.recordedUnits      = {}
_G.macroThread        = nil

-- Error log
local ErrorLog = {}
local function logError(ctx, err)
    local msg = string.format("[%s] %s", ctx, tostring(err))
    table.insert(ErrorLog, {time = os.time(), msg = msg})
    warn(msg)
end

-- UI
local Window          = Library:Window({Text = "GTD Macro v2"})
local FarmTab         = Window:Tab({Text = "Farm"})
local AntiBanTab      = Window:Tab({Text = "Anti-Ban"})
local RecorderTab     = Window:Tab({Text = "Recorder"})
local AutoPlayTab     = Window:Tab({Text = "Auto Play"})

local FarmSection     = FarmTab:Section({Text = "Auto Farm"})
local UpgradeSection  = FarmTab:Section({Text = "Upgrades", Side = "Right"})
local AntiBanSection  = AntiBanTab:Section({Text = "Humanization"})
local MovementSection = AntiBanTab:Section({Text = "Movement", Side = "Right"})
local RecorderSection = RecorderTab:Section({Text = "Recording"})
local SavedMacrosSec  = RecorderTab:Section({Text = "Saved Macros", Side = "Right"})
local GameSection     = AutoPlayTab:Section({Text = "Game Settings"})
local RestartSection  = AutoPlayTab:Section({Text = "Restart Settings", Side = "Right"})

local StatusLabel, RecorderStatusLabel, ErrorLabel

--------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------
local function getMoney()
    local ok, val = pcall(function()
        return plr:GetAttribute("Cash") or (plr:FindFirstChild("Cash") and plr.Cash.Value) or 0
    end)
    return ok and val or 0
end

local function getEntities()
    local ok, ent = pcall(function()
        return Workspace:WaitForChild("Map"):WaitForChild("Entities")
    end)
    return ok and ent or nil
end

local function getRandomOffset()
    if not Settings.UsePositionOffset then return Vector3.new() end
    local o = Settings.PositionOffset
    return Vector3.new(
        math.random(-o*10, o*10)/10,
        0,
        math.random(-o*10, o*10)/10
    )
end

local function getUnitID(unit)
    for _ = 1, 10 do
        local ok, id = pcall(function()
            for _, v in ipairs(unit:GetDescendants()) do
                if (v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue"))
                    and v.Name:lower():find("id") then
                    return v.Value
                end
            end
            for n, v in pairs(unit:GetAttributes()) do
                if n:lower():find("id") then return v end
            end
        end)
        if ok and id then return id end
        task.wait(0.2)
    end
    return nil
end

local function safeInvoke(remote, ...)
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    if not ok then logError("Remote", res) end
    return ok and res or nil
end

local function detectGameEnd()
    local ok, gui = pcall(function() return plr.PlayerGui:FindFirstChild("GameGuiNoInset") end)
    if not ok or not gui then return false end
    local defeat = gui:FindFirstChild("DefeatScreen") or gui:FindFirstChild("Defeat")
    local victory = gui:FindFirstChild("VictoryScreen") or gui:FindFirstChild("Victory")
    return (defeat and defeat.Visible) or (victory and victory.Visible)
end

--------------------------------------------------------------------
-- Auto Walk
--------------------------------------------------------------------
local function startAutoWalk()
    if _G.autoWalkConnection then stopAutoWalk() end
    local cd, walking = 0, false
    _G.autoWalkConnection = RunService.Heartbeat:Connect(function(dt)
        if not Settings.AutoWalk or not _G.trackingEnabled then return end
        cd = cd - dt
        local ok = pcall(function()
            local char = plr.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if cd <= 0 then
                if not walking then
                    walking = true
                    local dur = math.random(30,80)/10
                    local tx = math.random(-50,50)
                    local tz = math.random(-50,50)
                    hum:MoveTo(hrp.Position + Vector3.new(tx,0,tz))
                    cd = dur
                else
                    walking = false
                    local dur = math.random(20,50)/10
                    hum:MoveTo(hrp.Position)
                    cd = dur
                end
            end
        end)
        if not ok then stopAutoWalk() end
    end)
end

local function stopAutoWalk()
    if _G.autoWalkConnection then
        _G.autoWalkConnection:Disconnect()
        _G.autoWalkConnection = nil
    end
    pcall(function()
        local char = plr.Character
        if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            char.Humanoid:MoveTo(char.HumanoidRootPart.Position)
        end
    end)
end

--------------------------------------------------------------------
-- Unit tracking
--------------------------------------------------------------------
local function setupUnitTracking()
    local ents = getEntities()
    if not ents then return end

    ents.ChildAdded:Connect(function(child)
        task.spawn(function()
            if not child or not child.Parent or not child.Name:find("unit_") then return end
            task.wait(1)
            local id = getUnitID(child)
            if id then
                if _G.trackingEnabled then
                    table.insert(_G.myUnitIDs, id)
                    warn("tracked unit:", id)
                end
                if Recorder.IsRecording then
                    table.insert(_G.recordedUnits, id)
                    warn("recorder tracked:", id)
                end
            end
        end)
    end)

    ents.ChildRemoved:Connect(function(child)
        if not child or not child.Name:find("unit_") then return end
        task.spawn(function()
            local id = getUnitID(child)
            if id then
                for i = #_G.myUnitIDs, 1, -1 do
                    if _G.myUnitIDs[i] == id then table.remove(_G.myUnitIDs, i) end
                end
            end
        end)
    end)
end

--------------------------------------------------------------------
-- Game setup
--------------------------------------------------------------------
local function setupGame()
    task.spawn(function()
        pcall(function() safeInvoke(remotes.PlaceDifficultyVote, Settings.AutoDifficulty) end)
        task.wait(0.5)
        pcall(function() safeInvoke(remotes.ChangeTickSpeed, Settings.TickSpeed) end)

        if Settings.AutoSkipWaves then
            task.wait(6)
            task.spawn(function()
                while _G.trackingEnabled do
                    pcall(function() safeInvoke(remotes.SkipWave, "y") end)
                    task.wait(1)
                end
            end)
        end
        warn("game setup complete")
    end)
end

--------------------------------------------------------------------
-- Unit costs
--------------------------------------------------------------------
local unitCosts = {
    unit_tomato_rainbow = 100,
    unit_metal_flower   = 2250,
    unit_golem_dragon   = 5000,
    unit_eyeball        = 4500,
    unit_punch_potato   = 2500,
    unit_lucky_plant    = 1500,
    unit_eye_petal      = 5500,
    unit_confusion_plant= 1000,
}
local function getUnitCost(t) return unitCosts[t] or 0 end

--------------------------------------------------------------------
-- Money monitoring (recording)
--------------------------------------------------------------------
local function startMoneyMonitoring()
    if not Recorder.IsRecording then return end
    task.spawn(function()
        Recorder.LastMoney = getMoney()
        while Recorder.IsRecording do
            task.wait(0.1)
            local cur = getMoney()
            if cur ~= Recorder.LastMoney then
                local diff = Recorder.LastMoney - cur
                if diff > 0 then
                    local t = tick() - Recorder.StartTime
                    warn(string.format("cost $%d @ %.1fs", diff, t))
                end
                Recorder.LastMoney = cur
            end
        end
    end)
end

--------------------------------------------------------------------
-- Recorder hook
--------------------------------------------------------------------
if canHook then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}

        if method == "InvokeServer" and Recorder.IsRecording then
            -- PLACE
            if self.Name == "PlaceUnit" then
                local unit, data = args[1], args[2]
                task.defer(function()
                    pcall(function()
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {
                            time   = t,
                            type   = "place",
                            unit   = unit,
                            cframe = data.CF,
                            position = Vector3.new(data.Position.X, data.Position.Y, data.Position.Z),
                            rotation = data.Rotation,
                            cost   = getUnitCost(unit),
                            cashBefore = Recorder.LastMoney
                        }
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded place %s @ %.1fs", unit, t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)

            -- UPGRADE
            elseif self.Name == "UpgradeUnit" then
                local uid = args[1]
                task.defer(function()
                    pcall(function()
                        local idx = table.find(_G.recordedUnits, uid)
                        if not idx then return end
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {
                            time   = t,
                            type   = "upgrade",
                            unitIndex = idx,
                            cashBefore = Recorder.LastMoney
                        }
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded upgrade #%d @ %.1fs", idx, t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)

            -- SELL
            elseif self.Name == "SellUnit" then
                local uid = args[1]
                task.defer(function()
                    pcall(function()
                        local idx = table.find(_G.recordedUnits, uid)
                        if not idx then return end
                        local t = math.floor((tick() - Recorder.StartTime)*10)/10
                        local rec = {time = t, type = "sell", unitIndex = idx}
                        table.insert(Recorder.Actions, rec)
                        warn(string.format("recorded sell #%d @ %.1fs", idx, t))
                        if RecorderStatusLabel then
                            RecorderStatusLabel:Set({
                                Text = string.format("Recording... (%d)", #Recorder.Actions),
                                Color = Color3.fromRGB(255,100,100)
                            })
                        end
                    end)
                end)
            end
        end
        return old(self, ...)
    end)
end

--------------------------------------------------------------------
-- Recorder controls
--------------------------------------------------------------------
local function startRecording()
    Recorder.IsRecording = true
    Recorder.StartTime   = tick()
    Recorder.Actions     = {}
    _G.recordedUnits     = {}
    Recorder.LastMoney   = getMoney()
    warn("recording started")
    if RecorderStatusLabel then
        RecorderStatusLabel:Set({Text = "Recording... (0)", Color = Color3.fromRGB(255,100,100)})
    end
    startMoneyMonitoring()
end

local function stopRecording()
    Recorder.IsRecording = false
    warn("recording stopped - actions:", #Recorder.Actions)
    if RecorderStatusLabel then
        RecorderStatusLabel:Set({Text = string.format("Stopped (%d)", #Recorder.Actions), Color = Color3.fromRGB(255,200,0)})
    end
end

local function saveRecording()
    if not isFile then warn("no file I/O"); return end
    if #Recorder.Actions == 0 then
        warn("nothing to save")
        if RecorderStatusLabel then RecorderStatusLabel:Set({Text = "No actions!", Color = Color3.fromRGB(255,0,0)}) end
        return
    end
    local name = Recorder.MacroName == "" and ("Macro_"..os.time()) or Recorder.MacroName:gsub("[^%w_-]", "_")
    local data = {name = name, actions = Recorder.Actions, createdAt = os.date("%Y-%m-%d %H:%M:%S"), version = 2}
    local script = "return "..tableToString(data)

    pcall(function()
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy/Macros") then makefolder("SimpleSpy/Macros") end
    end)

    local ok, err = pcall(function() writefile("SimpleSpy/Macros/"..name..".lua", script) end)
    if ok then
        warn("saved:", name)
        if RecorderStatusLabel then RecorderStatusLabel:Set({Text = "Saved: "..name, Color = Color3.fromRGB(0,255,100)}) end
        task.wait(1); loadSavedMacros()
    else
        warn("save error:", err)
        if RecorderStatusLabel then RecorderStatusLabel:Set({Text = "Save failed!", Color = Color3.fromRGB(255,0,0)}) end
    end
end

local function tableToString(t, indent)
    indent = indent or ""
    local s = "{\n"
    for k,v in pairs(t) do
        s = s .. indent .. "    "
        if type(k)=="string" then s = s..'["'..k..'"] = ' else s = s.."["..k.."] = " end
        if type(v)=="table" then
            s = s .. tableToString(v, indent.."    ")
        elseif type(v)=="string" then
            s = s..'"'..v..'"'
        elseif typeof(v)=="Vector3" then
            s = s..string.format("Vector3.new(%.10f, %.10f, %.10f)", v.X, v.Y, v.Z)
        elseif typeof(v)=="CFrame" then
            local c = {v:GetComponents()}
            s = s..string.format("CFrame.new(%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f)", unpack(c))
        else
            s = s..tostring(v)
        end
        s = s..",\n"
    end
    return s..indent.."}"
end

local function loadSavedMacros()
    if not isFile then return end
    pcall(function()
        for _,c in pairs(SavedMacrosSec:GetDescendants()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end)
    pcall(function()
        if not isfolder("SimpleSpy") then makefolder("SimpleSpy") end
        if not isfolder("SimpleSpy/Macros") then makefolder("SimpleSpy/Macros") end
    end)

    local ok, files = pcall(listfiles, "SimpleSpy/Macros")
    if not ok or not files then
        SavedMacrosSec:Label({Text = "No macros yet", Color = Color3.fromRGB(150,150,150)})
        return
    end

    local cnt = 0
    for _,f in ipairs(files) do
        if f:match("%.lua$") then
            cnt = cnt + 1
            local name = f:match("([^/\\]+)%.lua$")
            SavedMacrosSec:Button({
                Text = "Play "..name,
                Tooltip = "Play this macro",
                Callback = function() playMacro(f) end
            })
            SavedMacrosSec:Button({
                Text = "Delete",
                Tooltip = "Delete "..name,
                Callback = function()
                    pcall(delfile, f)
                    task.wait(0.2)
                    loadSavedMacros()
                end
            })
        end
    end
    if cnt == 0 then
        SavedMacrosSec:Label({Text = "No macros yet", Color = Color3.fromRGB(150,150,150)})
    end
end

--------------------------------------------------------------------
-- Macro playback
--------------------------------------------------------------------
local function playMacro(file)
    if not isFile then return end
    local ok, script = pcall(readfile, file)
    if not ok then warn("cannot read file"); return end
    local data = loadstring(script)()
    warn("playing:", data.name, "#actions:", #data.actions)

    _G.myUnitIDs          = {}
    _G.trackingEnabled    = true
    _G.upgradeLoopRunning = false
    _G.recordedUnits      = {}
    Settings.MacroPaused  = false

    setupGame()

    _G.macroThread = coroutine.create(function()
        for i, act in ipairs(data.actions) do
            local prev = data.actions[i-1]
            task.wait(act.time - (prev and prev.time or 0))
            while Settings.MacroPaused do task.wait(0.5) end
            if not _G.trackingEnabled then break end

            if act.type == "place" then
                local off = getRandomOffset()
                local cf  = act.cframe + off
                local payload = {
                    Valid    = true,
                    Rotation = act.rotation,
                    CF       = cf,
                    Position = Vector3.new(cf.X, cf.Y, cf.Z)
                }
                local waited = 0
                while getMoney() < act.cost and waited < 120 do
                    task.wait(1); waited = waited + 1
                end
                if getMoney() >= act.cost then
                    local id = safeInvoke(remotes.PlaceUnit, act.unit, payload)
                    if id then table.insert(_G.recordedUnits, id); warn("placed", act.unit) end
                else
                    warn("timeout (place)", act.unit)
                end

            elseif act.type == "upgrade" then
                local uid = _G.recordedUnits[act.unitIndex]
                if uid then
                    local cost = act.cashBefore and (act.cashBefore - getMoney()) or Settings.UpgradeDelay
                    local waited = 0
          
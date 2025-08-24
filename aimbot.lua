local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local espObjects = {}
local connections = {}
local gui = nil
local FOVCircle = nil
local aimKeyButton = nil
local mainConnection = nil

local Config = {
    FOV_Size = 150, ShowFOV = true, TeamCheck = true, WallCheck = true,
    ESP = true, ESPBorder = false, ESPName = false, ESPHealth = false,
    ESPHighlight = true,
    Aimbot = true, SafeAim = false,
    SafeAimLevel = "Medium",
    SafeAimStrength = 0.5,
    AimbotKey = Enum.UserInputType.MouseButton2,
    ToggleKey = Enum.KeyCode.P, HideKey = Enum.KeyCode.H, DeleteKey = Enum.KeyCode.Delete,
    Smoothing = 0.3, AimPart = "Head", TargetPriority = "Auto",
    Debug = false
}

local SafeAimPresets = {
    Low =    { strength = 0.15, smoothing = 0.12, maxOffset = 0.25 },
    Medium = { strength = 0.5,  smoothing = 0.30, maxOffset = 0.6  },
    High =   { strength = 0.9,  smoothing = 0.55, maxOffset = 1.2  }
}

local State = {
    enabled = true, guiVisible = true, aiming = false, waitingForKey = false,
    currentTarget = nil, targetLocked = false, scriptRunning = true
}

local destroyed = false

local AimKey = { kind = "UserInputType", value = Config.AimbotKey }
local function setAimKeyFromInputObj(k)
    if typeof(k) == "EnumItem" then
        local s = tostring(k)
        if s:match("MouseButton") then
            AimKey.kind = "UserInputType"; AimKey.value = k
        else
            AimKey.kind = "KeyCode"; AimKey.value = k
        end
    else
        AimKey.kind = "UserInputType"; AimKey.value = Enum.UserInputType.MouseButton2
    end
end
setAimKeyFromInputObj(Config.AimbotKey)

local function isAimbotInputMatch(input)
    if not input then return false end
    if AimKey.kind == "UserInputType" then
        return input.UserInputType == AimKey.value
    else
        return input.KeyCode == AimKey.value
    end
end

local function safeDisconnect(conn)
    if not conn then return end
    pcall(function()
        local t = typeof(conn)
        if t == "RBXScriptConnection" and conn.Disconnect then
            conn:Disconnect()
            return
        end
        if t == "Instance" then
            if conn.Destroy then conn:Destroy() end
            return
        end
        if type(conn) == "table" then
            if conn.Remove then
                pcall(function() conn:Remove() end)
                return
            end
            if conn.Destroy then
                pcall(function() conn:Destroy() end)
                return
            end
        end
        if type(conn) == "function" then
            pcall(conn)
        end
    end)
end

local function cleanup()
    if destroyed then return end
    destroyed = true

    State.scriptRunning = false
    State.enabled = false
    State.guiVisible = false
    State.aiming = false
    State.targetLocked = false
    State.currentTarget = nil

    if gui then
        pcall(function() gui.Enabled = false end)
        pcall(function()
            if gui.Parent then gui:Destroy() end
        end)
        gui = nil
    end

    if FOVCircle then
        pcall(function()
            if FOVCircle.Remove then
                FOVCircle:Remove()
            else
                FOVCircle.Visible = false
            end
        end)
        FOVCircle = nil
    end

    if type(espObjects) == "table" then
        for player, d in pairs(espObjects) do
            if d then
                safeDisconnect(d.connection)
                safeDisconnect(d.charConnection)
                safeDisconnect(d.removeConn)
                if d.billboard and d.billboard.Parent then
                    pcall(function() d.billboard:Destroy() end)
                end
                if d.highlight and d.highlight.Parent then
                    pcall(function() d.highlight:Destroy() end)
                end
            end
            espObjects[player] = nil
        end
    end
    espObjects = {}

    if type(connections) == "table" then
        for i = #connections, 1, -1 do
            local c = connections[i]
            safeDisconnect(c)
            connections[i] = nil
        end
    end
    connections = {}

    if mainConnection then
        safeDisconnect(mainConnection)
        mainConnection = nil
    end

    aimKeyButton = nil

    pcall(function()
        if typeof(script) == "Instance" and script.Destroy then
            script:Destroy()
        end
    end)

    print("Aimbot cleaned up.")
end

local function isEnemy(p)
    if not Config.TeamCheck then return true end
    if not LocalPlayer.Team then return true end
    if p.Team and p.Team == LocalPlayer.Team then return false end
    if p.TeamColor and LocalPlayer.TeamColor and p.TeamColor == LocalPlayer.TeamColor then return false end
    if p.Character then
        local candidates = {"Team", "team", "Faction", "faction", "factionName"}
        for _, name in ipairs(candidates) do
            local v = p.Character:FindFirstChild(name)
            if v and v:IsA("StringValue") then
                if LocalPlayer.Team and tostring(v.Value) == tostring(LocalPlayer.Team.Name) then
                    return false
                end
            end
        end
    end
    return true
end

local function hasLineOfSight(part)
    if not Config.WallCheck then return true end
    if not Camera then Camera = workspace.CurrentCamera end
    if not Camera then return true end
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local rp = RaycastParams.new()
    rp.FilterDescendantsInstances = {LocalPlayer.Character}
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local res = workspace:Raycast(origin, dir, rp)
    if not res then return true end
    local inst = res.Instance
    if inst and inst:IsDescendantOf(part.Parent) then return true end
    return false
end

local function getTargetPart(char)
    if not char then return nil end
    local lookup = {
        Head = {"Head"},
        Torso = {"Torso", "UpperTorso"},
        LeftArm = {"LeftUpperArm", "LeftLowerArm", "Left Arm", "LeftArm"},
        RightArm = {"RightUpperArm", "RightLowerArm", "Right Arm", "RightArm"},
        LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftLeg"},
        RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightLeg"}
    }

    local desired = tostring(Config.AimPart or "Head")
    local names = lookup[desired] or {desired}
    for _, n in ipairs(names) do
        local p = char:FindFirstChild(n)
        if p then return p end
    end

    local fallbacks = {"Head", "UpperTorso", "Torso"}
    for _, n in ipairs(fallbacks) do
        if char:FindFirstChild(n) then return char:FindFirstChild(n) end
    end

    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("BasePart") then return v end
    end
    return nil
end

local function isTargetValid(player)
    if not player or not player.Character then return false end
    local tp = getTargetPart(player.Character); local hum = player.Character:FindFirstChild("Humanoid")
    if not tp or not hum or hum.Health <= 0 or not isEnemy(player) then return false end
    local sp, onScreen = Camera:WorldToViewportPoint(tp.Position)
    if not onScreen then return false end
    local sp2, _ = Camera:WorldToViewportPoint(tp.Position)
    local md = (Vector2.new(sp2.X, sp2.Y) - UserInputService:GetMouseLocation()).Magnitude
    return md <= Config.FOV_Size and hasLineOfSight(tp)
end

local function compositeScore(player)
    local tp = getTargetPart(player.Character); local hum = player.Character:FindFirstChild("Humanoid")
    local sp, _ = Camera:WorldToViewportPoint(tp.Position); local mouse = UserInputService:GetMouseLocation()
    local mouseDist = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
    local mouseNorm = math.clamp(mouseDist / math.max(Config.FOV_Size, 1), 0, 1)
    local worldDist = (tp.Position - Camera.CFrame.Position).Magnitude
    local distNorm = math.clamp(worldDist / 1000, 0, 1)
    if Config.SafeAim then
        return mouseNorm * 0.6 + distNorm * 0.4
    end
    local healthNorm = 1
    if hum and hum.MaxHealth and hum.MaxHealth > 0 then healthNorm = math.clamp(hum.Health / hum.MaxHealth, 0, 1) end
    return mouseNorm * 0.5 + healthNorm * 0.3 + distNorm * 0.2
end

local function getClosestTarget()
    if not State.scriptRunning then return nil end
    if Config.SafeAim and State.targetLocked and State.currentTarget then
        if isTargetValid(State.currentTarget) then
            return State.currentTarget
        else
            State.targetLocked = false; State.currentTarget = nil
        end
    end

    local best, bestScore = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and isTargetValid(p) then
            local score = compositeScore(p)
            if score < bestScore then bestScore = score; best = p end
        end
    end

    if best and Config.SafeAim then
        State.currentTarget = best; State.targetLocked = true
    end
    return best
end

local function humanizedOffset()
    local preset = SafeAimPresets[Config.SafeAimLevel] or SafeAimPresets.Medium
    local maxOffset = preset.maxOffset or 0.6
    local strength = math.clamp(preset.strength or 0.5, 0, 1)
    local r = maxOffset * strength
    return Vector3.new((math.random()-0.5)*2*r, (math.random()-0.5)*2*r, (math.random()-0.5)*2*r)
end

local function aimAt(target)
    if not State.scriptRunning or not target or not target.Character or not Camera then return end
    local tp = getTargetPart(target.Character); if not tp then return end
    local targetPos = tp.Position
    if Config.SafeAim then
        local off = humanizedOffset()
        local preset = SafeAimPresets[Config.SafeAimLevel] or SafeAimPresets.Medium
        local smoothingFactor = math.clamp(preset.smoothing or Config.Smoothing or 0.3, 0, 1)
        targetPos = targetPos + off * (1 - smoothingFactor)
    end
    local camPos = Camera.CFrame.Position
    local dir = (targetPos - camPos)
    if dir.Magnitude <= 0 then return end
    dir = dir.Unit
    local newCf = CFrame.lookAt(camPos, camPos + dir)
    local s = math.clamp(tonumber(Config.Smoothing) or 0.3, 0, 1)
    local ok, err = pcall(function()
        if s <= 0 then Camera.CFrame = newCf else Camera.CFrame = Camera.CFrame:Lerp(newCf, s) end
    end)
    if (not ok) and Config.Debug then warn("Aim failed:", err) end
end

local espObjects = {}
local connections = {}
local gui, FOVCircle, aimKeyButton, mainConnection

local okDraw, circle = pcall(function() return Drawing.new("Circle") end)
if okDraw and circle then
    FOVCircle = circle
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.8
    FOVCircle.Visible = false
end

local function waitForParts(character, names, timeout)
    local start = tick()
    while tick() - start < timeout do
        if not character or not character.Parent then return false end
        local ok = true
        for _, n in ipairs(names) do
            if not character:FindFirstChild(n) then ok = false; break end
        end
        if ok then return true end
        task.wait(0.05)
    end
    return false
end

local function createESP(player)
    if player == LocalPlayer then return end
    if espObjects[player] and espObjects[player].settingUp then return end
    espObjects[player] = espObjects[player] or {}
    espObjects[player].settingUp = true

    local function cleanupOld()
        if espObjects[player] then
            safeDisconnect(espObjects[player].connection)
            safeDisconnect(espObjects[player].charConnection)
            safeDisconnect(espObjects[player].removeConn)
            if espObjects[player].billboard then pcall(function() espObjects[player].billboard:Destroy() end) end
            if espObjects[player].highlight then pcall(function() espObjects[player].highlight:Destroy() end) end
            espObjects[player] = nil
        end
    end

    local function setupESP(character)
        if not State.scriptRunning or not character then cleanupOld(); return end
        local ok = waitForParts(character, {"Humanoid", "HumanoidRootPart"}, 2)
        local head = character:FindFirstChild("Head")
        if not head then ok = ok or waitForParts(character, {"Head"}, 1) end
        if not ok and not (character:FindFirstChild("Humanoid") and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))) then
            espObjects[player] = espObjects[player] or {}
            espObjects[player].settingUp = false
            return
        end

        if espObjects[player] then
            safeDisconnect(espObjects[player].connection)
            if espObjects[player].billboard then pcall(function() espObjects[player].billboard:Destroy() end) end
            if espObjects[player].highlight then pcall(function() espObjects[player].highlight:Destroy() end) end
            espObjects[player] = espObjects[player] or {}
        end

        local hum = character:FindFirstChild("Humanoid"); head = character:FindFirstChild("Head")
        local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if not hum or not root then
            espObjects[player].settingUp = false
            return
        end

        local parentPart = head or root

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_"..player.Name
        billboard.Parent = parentPart
        billboard.Size = UDim2.new(0,400,0,400)
        billboard.StudsOffset = Vector3.new(0,1,0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = Config.ESP

        local borderFrame = Instance.new("Frame"); borderFrame.Name = "ESP_Border"; borderFrame.Parent = billboard
        borderFrame.BackgroundTransparency = 1; borderFrame.BorderSizePixel = 0
        local stroke = Instance.new("UIStroke"); stroke.Parent = borderFrame; stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(255,0,0)

        local nameLabel = Instance.new("TextLabel"); nameLabel.Name="Name"; nameLabel.Parent=billboard
        nameLabel.BackgroundTransparency = 1; nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
        nameLabel.TextScaled = false; nameLabel.TextSize = 18; nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.4; nameLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center

        local healthLabel = Instance.new("TextLabel"); healthLabel.Name="Health"; healthLabel.Parent=billboard
        healthLabel.BackgroundTransparency = 1; healthLabel.TextColor3 = Color3.fromRGB(0,255,0)
        healthLabel.TextScaled = false; healthLabel.TextSize = 16; healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextStrokeTransparency = 0.4; healthLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        healthLabel.TextXAlignment = Enum.TextXAlignment.Center

        local highlightInstance
        local function createOrDestroyHighlight()
            if Config.ESPHighlight then
                if not highlightInstance then
                    local okh, h = pcall(function() return Instance.new("Highlight") end)
                    if okh and h then
                        highlightInstance = Instance.new("Highlight")
                        highlightInstance.Name = "ESP_Highlight_"..player.Name
                        highlightInstance.Adornee = character
                        highlightInstance.Parent = workspace
                        highlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlightInstance.FillTransparency = 1
                        highlightInstance.OutlineTransparency = 0
                        highlightInstance.OutlineColor = Color3.fromRGB(255,165,0)
                    end
                end
            else
                if highlightInstance then pcall(function() highlightInstance:Destroy() end); highlightInstance = nil end
            end
        end

        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not State.scriptRunning or not character.Parent or not hum.Parent then
                safeDisconnect(conn); pcall(function() billboard:Destroy() end); if highlightInstance then pcall(function() highlightInstance:Destroy() end) end; return
            end

            billboard.Enabled = Config.ESP
            local shouldShow = State.enabled and isEnemy(player) and Config.ESP

            nameLabel.Visible = Config.ESPName and shouldShow
            healthLabel.Visible = Config.ESPHealth and shouldShow

            if shouldShow and Config.ESPName then nameLabel.Text = player.Name end

            if shouldShow and Config.ESPHealth then
                local hp = math.max(0, math.floor(hum.Health)); local maxHp = math.max(1, math.floor(hum.MaxHealth or 100))
                healthLabel.Text = tostring(hp).."/"..tostring(maxHp)
                local pct = hp / maxHp
                local col = (pct>0.6 and Color3.fromRGB(0,255,0)) or (pct>0.3 and Color3.fromRGB(255,255,0)) or Color3.fromRGB(255,0,0)
                healthLabel.TextColor3 = col
                stroke.Color = col
            end

            if Config.ESPHighlight then
                if not highlightInstance then createOrDestroyHighlight() end
                if highlightInstance then highlightInstance.Enabled = shouldShow end
            else
                if highlightInstance then createOrDestroyHighlight() end
            end

            if not shouldShow then
                borderFrame.Visible = false
                nameLabel.Visible = false; healthLabel.Visible = false
                return
            end

            local headTop = (character:FindFirstChild("Head") and (character.Head.Position + Vector3.new(0,0.45,0))) or (root.Position + Vector3.new(0,1,0))
            local feet = root.Position - Vector3.new(0,1,0)
            local topScreen = Camera:WorldToViewportPoint(headTop)
            local botScreen = Camera:WorldToViewportPoint(feet)
            local hgt = math.max(24, math.abs(botScreen.Y - topScreen.Y))
            local wid = math.clamp(math.floor(hgt * 0.45), 18, 400)
            local bx = math.floor(200 - wid/2)
            local by = math.floor(200 - hgt/2)

            borderFrame.Size = UDim2.new(0, wid, 0, hgt); borderFrame.Position = UDim2.new(0, bx, 0, by); borderFrame.Visible = Config.ESPBorder and shouldShow

            if nameLabel.Visible then
                nameLabel.Size = UDim2.new(0, wid, 0, 20)
                nameLabel.Position = UDim2.new(0, bx, 0, math.max(0, by-22))
            end
            if healthLabel.Visible then
                healthLabel.Size = UDim2.new(0, wid, 0, 18)
                healthLabel.Position = UDim2.new(0, bx, 0, math.min(380, by+hgt+2))
            end
        end)

        local removeConn = player.CharacterRemoving:Connect(function()
            safeDisconnect(conn)
            if billboard then pcall(function() billboard:Destroy() end) end
            if highlightInstance then pcall(function() highlightInstance:Destroy() end) end
            espObjects[player] = nil
        end)

        espObjects[player] = {
            billboard = billboard,
            connection = conn,
            charConnection = nil,
            highlight = highlightInstance,
            removeConn = removeConn,
            settingUp = false
        }
    end

    local charConn = player.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        pcall(setupESP, char)
    end)

    if player.Character then
        task.spawn(function() pcall(setupESP, player.Character) end)
    end

    espObjects[player] = espObjects[player] or {}
    espObjects[player].charConnection = charConn
    espObjects[player].settingUp = false
end

local function createGUI()
    gui = Instance.new("ScreenGui"); gui.Name = "AimbotGUI"; gui.Parent = CoreGui; gui.ResetOnSpawn = false

    local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,320,0,560); frame.Position = UDim2.new(0,12,0.08,0)
    frame.BackgroundColor3 = Color3.fromRGB(24,24,24); frame.BorderSizePixel = 0; frame.Parent = gui
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(45,45,45); stroke.Thickness = 1

    local title = Instance.new("TextLabel"); title.Size = UDim2.new(1,0,0,40); title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1; title.Text = "🎯 Aimbot + ESP v2"; title.Font = Enum.Font.GothamBold; title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1); title.Parent = frame

    local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1,-12,1,-58); scroll.Position = UDim2.new(0,6,0,46)
    scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 6; scroll.Parent = frame

    local y = 8
    local function addToggle(name, key)
        local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 32); btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = (Config[key] and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)); btn.Text = name..": "..(Config[key] and "ON" or "OFF")
        btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.Gotham; btn.TextSize = 14; btn.Parent = scroll
        local uc = Instance.new("UICorner", btn); uc.CornerRadius = UDim.new(0,6)
        btn.MouseButton1Click:Connect(function()
            if not State.scriptRunning then return end
            Config[key] = not Config[key]
            btn.BackgroundColor3 = (Config[key] and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0))
            btn.Text = name..": "..(Config[key] and "ON" or "OFF")
        end)
        y = y + 40
    end

    addToggle("ESP","ESP"); addToggle("FOV Circle","ShowFOV"); addToggle("Aimbot","Aimbot"); addToggle("Safe Aim","SafeAim")

    aimKeyButton = Instance.new("TextButton"); aimKeyButton.Size = UDim2.new(1,-10,0,32); aimKeyButton.Position = UDim2.new(0,5,0,y)
    local initialLabel = (AimKey.kind == "KeyCode" and tostring(AimKey.value.Name)) or tostring(AimKey.value.Name)
    aimKeyButton.Text = "Aim Key: "..initialLabel; aimKeyButton.Font = Enum.Font.Gotham; aimKeyButton.TextSize = 14; aimKeyButton.Parent = scroll
    local uc2 = Instance.new("UICorner", aimKeyButton); uc2.CornerRadius = UDim.new(0,6)
    aimKeyButton.MouseButton1Click:Connect(function() if not State.scriptRunning then return end; State.waitingForKey = true; aimKeyButton.Text = "Press key..."; aimKeyButton.BackgroundColor3 = Color3.fromRGB(255,165,0) end)
    y = y + 40

    addToggle("Team Check","TeamCheck"); addToggle("Wall Check","WallCheck")
    addToggle("ESP Border","ESPBorder"); addToggle("ESP Name","ESPName"); addToggle("ESP Health","ESPHealth")
    addToggle("ESP Highlight","ESPHighlight")

    local aimParts = {"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}
    local partIdx = 1
    for i, v in ipairs(aimParts) do if v == Config.AimPart then partIdx = i; break end end
    local aimPartBtn = Instance.new("TextButton"); aimPartBtn.Size = UDim2.new(1,-10,0,32); aimPartBtn.Position = UDim2.new(0,5,0,y)
    aimPartBtn.Text = "Aim Part: "..tostring(aimParts[partIdx]); aimPartBtn.Font = Enum.Font.Gotham; aimPartBtn.TextSize = 14; aimPartBtn.Parent = scroll
    local ucPart = Instance.new("UICorner", aimPartBtn); ucPart.CornerRadius = UDim.new(0,6)
    aimPartBtn.MouseButton1Click:Connect(function()
        partIdx = partIdx + 1
        if partIdx > #aimParts then partIdx = 1 end
        Config.AimPart = aimParts[partIdx]
        aimPartBtn.Text = "Aim Part: "..tostring(Config.AimPart)
    end)
    y = y + 40

    local safeLevels = {"Low","Medium","High"}
    local safeIdx = 2
    for i,v in ipairs(safeLevels) do if v == Config.SafeAimLevel then safeIdx = i; break end end
    local safeBtn = Instance.new("TextButton"); safeBtn.Size = UDim2.new(1,-10,0,32); safeBtn.Position = UDim2.new(0,5,0,y)
    safeBtn.Text = "SafeAim Level: "..tostring(safeLevels[safeIdx]); safeBtn.Font = Enum.Font.Gotham; safeBtn.TextSize = 14; safeBtn.Parent = scroll
    local ucSafe = Instance.new("UICorner", safeBtn); ucSafe.CornerRadius = UDim.new(0,6)
    safeBtn.MouseButton1Click:Connect(function()
        safeIdx = safeIdx + 1
        if safeIdx > #safeLevels then safeIdx = 1 end
        Config.SafeAimLevel = safeLevels[safeIdx]
        local preset = SafeAimPresets[Config.SafeAimLevel] or SafeAimPresets.Medium
        Config.SafeAimStrength = preset.strength
        safeBtn.Text = "SafeAim Level: "..tostring(Config.SafeAimLevel)
    end)
    y = y + 40

    local function addSlider(name, key, min, max, precision)
        precision = precision or 2
        local container = Instance.new("Frame"); container.Size = UDim2.new(1,-10,0,48); container.Position = UDim2.new(0,5,0,y); container.BackgroundTransparency = 1; container.Parent = scroll
        local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.6,0,1,0); label.Position = UDim2.new(0,0,0,0)
        label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.TextSize = 14; label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container

        local bar = Instance.new("Frame"); bar.Size = UDim2.new(0.38,0,0,12); bar.Position = UDim2.new(0.61,0,0,18)
        bar.BackgroundColor3 = Color3.fromRGB(50,50,50); bar.BorderSizePixel = 0; bar.Parent = container
        local barCorner = Instance.new("UICorner", bar); barCorner.CornerRadius = UDim.new(0,6)

        local fill = Instance.new("Frame"); fill.Size = UDim2.new(0.5,0,1,0); fill.Position = UDim2.new(0,0,0,0); fill.BackgroundColor3 = Color3.fromRGB(200,200,200); fill.BorderSizePixel = 0; fill.Parent = bar
        local fillCorner = Instance.new("UICorner", fill); fillCorner.CornerRadius = UDim.new(0,6)

        local knob = Instance.new("ImageButton"); knob.Size = UDim2.new(0,12,0,12); knob.Position = UDim2.new(0.5,-6,0,0)
        knob.BackgroundTransparency = 1; knob.Parent = bar

        local function updateUI()
            local v = Config[key]
            local pct = (v - min) / math.max(0.0001, max - min)
            pct = math.clamp(pct, 0, 1)
            fill.Size = UDim2.new(pct,0,1,0)
            knob.Position = UDim2.new(pct, -6, 0, 0)
            local disp = math.floor(v * (10^precision)) / (10^precision)
            label.Text = name..": "..tostring(disp)
        end
        if Config[key] == nil then Config[key] = min end
        updateUI()

        local dragging = false
        knob.MouseButton1Down:Connect(function()
            if not State.scriptRunning then return end
            dragging = true
            local changeConn
            changeConn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local absPos = bar.AbsolutePosition
                    local absSize = bar.AbsoluteSize
                    local mx = UserInputService:GetMouseLocation().X
                    local rel = math.clamp((mx - absPos.X) / absSize.X, 0, 1)
                    local val = min + (max - min) * rel
                    Config[key] = val
                    updateUI()
                end
            end)
            local upConn
            upConn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    safeDisconnect(changeConn); safeDisconnect(upConn)
                end
            end)
        end)

        y = y + 56
    end

    addSlider("FOV Size", "FOV_Size", 50, 600, 0)
    addSlider("Smoothing", "Smoothing", 0.0, 1.0, 2)

    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local startPos = inp.Position
            local guiStart = frame.Position
            local connMove
            connMove = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = m.Position - startPos
                    frame.Position = UDim2.new(guiStart.X.Scale, guiStart.X.Offset + delta.X, guiStart.Y.Scale, guiStart.Y.Offset + delta.Y)
                end
            end)
            local connUp
            connUp = UserInputService.InputEnded:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseButton1 then
                    safeDisconnect(connMove); safeDisconnect(connUp)
                end
            end)
        end
    end)

    local hideKeys = {Enum.KeyCode.H, Enum.KeyCode.G, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift, Enum.KeyCode.LeftAlt}
    local hideIdx = 1
    for i,k in ipairs(hideKeys) do if k == Config.HideKey then hideIdx = i; break end end
    local hideBtn = Instance.new("TextButton"); hideBtn.Size = UDim2.new(1,-10,0,32); hideBtn.Position = UDim2.new(0,5,0,y)
    hideBtn.Text = "Hide Key: "..tostring(hideKeys[hideIdx].Name); hideBtn.Font = Enum.Font.Gotham; hideBtn.TextSize = 14; hideBtn.Parent = scroll
    local uc4 = Instance.new("UICorner", hideBtn); uc4.CornerRadius = UDim.new(0,6)
    hideBtn.MouseButton1Click:Connect(function()
        hideIdx = hideIdx + 1
        if hideIdx > #hideKeys then hideIdx = 1 end
        Config.HideKey = hideKeys[hideIdx]
        hideBtn.Text = "Hide Key: "..tostring(hideKeys[hideIdx].Name)
    end)
    y = y + 40

    local destroy = Instance.new("TextButton"); destroy.Size = UDim2.new(1,-10,0,40); destroy.Position = UDim2.new(0,5,0,y); destroy.Text = "🗑️ DESTROY SCRIPT"
    destroy.Font = Enum.Font.Gotham; destroy.TextSize = 14; destroy.Parent = scroll; local uc3 = Instance.new("UICorner", destroy); uc3.CornerRadius = UDim.new(0,6)
    destroy.MouseButton1Click:Connect(function()
        if destroy then
            pcall(function() destroy.Text = "Destroying..." end)
        end
        cleanup()
    end)
    y = y + 48

    scroll.CanvasSize = UDim2.new(0,0,0,y)
end

local function handleInput()
    connections[#connections+1] = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not State.scriptRunning then return end
        if State.waitingForKey then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                Config.AimbotKey = input.KeyCode; setAimKeyFromInputObj(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                Config.AimbotKey = input.UserInputType; setAimKeyFromInputObj(input.UserInputType)
            elseif input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                Config.AimbotKey = input.KeyCode; setAimKeyFromInputObj(input.KeyCode)
            end
            if aimKeyButton then
                local label = (AimKey.kind == "KeyCode" and tostring(AimKey.value.Name)) or tostring(AimKey.value.Name)
                aimKeyButton.Text = "Aim: "..label; aimKeyButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
            State.waitingForKey = false; return
        end

        if input.KeyCode == Config.ToggleKey then State.enabled = not State.enabled
        elseif input.KeyCode == Config.HideKey then State.guiVisible = not State.guiVisible
        elseif input.KeyCode == Config.DeleteKey then cleanup(); return
        elseif isAimbotInputMatch(input) then
            State.aiming = true
        end
    end)

    connections[#connections+1] = UserInputService.InputEnded:Connect(function(input, gp)
        if gp or not State.scriptRunning or State.waitingForKey then return end
        if isAimbotInputMatch(input) then
            State.aiming = false
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createESP(p)
    end
end
connections[#connections+1] = Players.PlayerAdded:Connect(function(p)
    if State.scriptRunning then
        createESP(p)
    end
end)
connections[#connections+1] = Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        safeDisconnect(espObjects[p].connection); safeDisconnect(espObjects[p].charConnection); safeDisconnect(espObjects[p].removeConn)
        if espObjects[p].billboard then pcall(function() espObjects[p].billboard:Destroy() end) end
        if espObjects[p].highlight then pcall(function() espObjects[p].highlight:Destroy() end) end
        espObjects[p] = nil
    end
end)

mainConnection = RunService.Heartbeat:Connect(function()
    if not State.scriptRunning then safeDisconnect(mainConnection); return end
    local m = UserInputService:GetMouseLocation()
    if FOVCircle then
        pcall(function()
            FOVCircle.Position = Vector2.new(m.X, m.Y)
            FOVCircle.Radius = Config.FOV_Size
            FOVCircle.Visible = State.enabled and Config.ShowFOV
        end)
    end
    if gui then pcall(function() gui.Enabled = State.guiVisible end) end
    if State.enabled and Config.Aimbot and State.aiming then
        local t = getClosestTarget()
        if t then aimAt(t) end
    end
end)

createGUI(); handleInput()
print("🎯 Aimbot + ESP v2 Loaded (AimPart cleaned, cleanup fixed)")

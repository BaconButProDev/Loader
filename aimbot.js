local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local Config = {
    FOV_Size = 150, ShowFOV = true, TeamCheck = true, WallCheck = true,
    ESP = true, ESPBorder = false, ESPName = false, ESPHealth = false,
    ESPHighlight = true,
    Aimbot = true, SafeAim = true, SafeAimStrength = 0.5,
    AimbotKey = Enum.UserInputType.MouseButton2,
    ToggleKey = Enum.KeyCode.P, HideKey = Enum.KeyCode.H, DeleteKey = Enum.KeyCode.Delete,
    Smoothing = 0.3, AimPart = "Head", TargetPriority = "Auto",
    Debug = false
}

local State = {
    enabled = true, guiVisible = true, aiming = false, waitingForKey = false,
    currentTarget = nil, targetLocked = false, scriptRunning = true
}

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
        if typeof(conn) == "RBXScriptConnection" and conn.Disconnect then
            conn:Disconnect()
        elseif typeof(conn) == "Instance" and conn.Destroy then
            conn:Destroy()
        else
            if type(conn) == "function" then
                pcall(conn)
            end
        end
    end)
end

local function cleanup()
    State.scriptRunning = false
    if gui then pcall(function() gui:Destroy() end); gui = nil end
    if FOVCircle then pcall(function() FOVCircle:Remove() end); FOVCircle = nil end
    for _, d in pairs(espObjects) do
        safeDisconnect(d.connection); safeDisconnect(d.charConnection)
        if d.billboard then pcall(function() d.billboard:Destroy() end) end
        if d.highlight then pcall(function() d.highlight:Destroy() end) end
    end
    espObjects = {}
    for _, c in pairs(connections) do safeDisconnect(c) end
    connections = {}
    safeDisconnect(mainConnection); mainConnection = nil
    State.currentTarget = nil; State.targetLocked = false; State.aiming = false
    task.wait(0.1);
    pcall(function() script:Destroy() end)
end

local function isEnemy(p)
    return not Config.TeamCheck or not LocalPlayer.Team or not p.Team or p.Team ~= LocalPlayer.Team
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
    local parts = {
        Head = char:FindFirstChild("Head"),
        Torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"),
        ["Left Leg"] = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg"),
        ["Right Leg"] = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
    }
    local tp = parts[Config.AimPart] or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
    return tp
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
            local hum = p.Character:FindFirstChild("Humanoid"); local score
            if Config.TargetPriority == "Mouse" then
                local tp = getTargetPart(p.Character); local sp, _ = Camera:WorldToViewportPoint(tp.Position)
                score = (Vector2.new(sp.X, sp.Y) - UserInputService:GetMouseLocation()).Magnitude
            elseif Config.TargetPriority == "Distance" then
                local tp = getTargetPart(p.Character); score = (tp.Position - Camera.CFrame.Position).Magnitude
            elseif Config.TargetPriority == "Health" then
                score = hum and hum.Health or math.huge
            else score = compositeScore(p) end
            if score < bestScore then bestScore = score; best = p end
        end
    end

    if best and Config.SafeAim then
        State.currentTarget = best; State.targetLocked = true
    end
    return best
end

local function humanizedOffset()
    local maxOffset = 0.6
    local strength = math.clamp(Config.SafeAimStrength or 0.5, 0, 1)
    local r = maxOffset * strength
    return Vector3.new((math.random()-0.5)*2*r, (math.random()-0.5)*2*r, (math.random()-0.5)*2*r)
end

local function aimAt(target)
    if not State.scriptRunning or not target or not target.Character or not Camera then return end
    local tp = getTargetPart(target.Character); if not tp then return end
    local targetPos = tp.Position
    if Config.SafeAim then
        local off = humanizedOffset(); local smoothingFactor = math.clamp(Config.Smoothing or 0.3, 0, 1)
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
if okDraw and circle then FOVCircle = circle; FOVCircle.Thickness = 2; FOVCircle.Filled = false; FOVCircle.Transparency = 0.8 end

local function createESP(player)
    if player == LocalPlayer then return end

    if espObjects[player] then
        safeDisconnect(espObjects[player].connection)
        safeDisconnect(espObjects[player].charConnection)
        if espObjects[player].billboard then pcall(function() espObjects[player].billboard:Destroy() end) end
        if espObjects[player].highlight then pcall(function() espObjects[player].highlight:Destroy() end) end
        espObjects[player] = nil
    end

    local function setupESP(character)
        if not State.scriptRunning or not character then return end
        task.wait(0.12)

        if espObjects[player] then
            safeDisconnect(espObjects[player].connection)
            if espObjects[player].billboard then pcall(function() espObjects[player].billboard:Destroy() end) end
            if espObjects[player].highlight then pcall(function() espObjects[player].highlight:Destroy() end) end
            espObjects[player] = nil
        end

        local hum = character:FindFirstChild("Humanoid"); local head = character:FindFirstChild("Head")
        local root = character:FindFirstChild("HumanoidRootPart")
        if not hum or not head or not root then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_"..player.Name
        billboard.Parent = head
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
                    local ok, h = pcall(function() return Instance.new("Highlight") end)
                    if ok and h then
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

            local headTop = head.Position + Vector3.new(0,0.45,0)
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

        espObjects[player] = {billboard = billboard, connection = conn, charConnection = nil, highlight = highlightInstance}
    end

    local charConn = player.CharacterAdded:Connect(function(char)
        task.wait(0.05)
        setupESP(char)
    end)
    if player.Character then
        task.spawn(function() setupESP(player.Character) end)
    end
    espObjects[player] = espObjects[player] or {}
    espObjects[player].charConnection = charConn
end

local function createGUI()
    gui = Instance.new("ScreenGui"); gui.Name = "AimbotGUI"; gui.Parent = CoreGui; gui.ResetOnSpawn = false

    local frame = Instance.new("Frame"); frame.Size = UDim2.new(0,320,0,520); frame.Position = UDim2.new(0,12,0.08,0)
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
    destroy.MouseButton1Click:Connect(cleanup)
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
        safeDisconnect(espObjects[p].connection); safeDisconnect(espObjects[p].charConnection)
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
print("🎯 Aimbot + ESP v2 Loaded (SafeAim improved)")

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local camera      = Workspace.CurrentCamera
local screenSize  = camera.ViewportSize

-- Scale helpers
local UI_SCALE = math.min(
    math.clamp(screenSize.X / 1280, 0.55, 1.2),
    math.clamp(screenSize.Y / 720,  0.55, 1.2)
)
local function S(n) return math.round(n * UI_SCALE) end

local FRAME_W, FRAME_H = S(320), S(460)

-- Colors
local C = {
    BG        = Color3.fromRGB(14, 14, 20),
    TOPBAR    = Color3.fromRGB(20, 20, 30),
    PANEL     = Color3.fromRGB(24, 26, 38),
    PANEL2    = Color3.fromRGB(28, 30, 44),
    ACCENT    = Color3.fromRGB(0, 200, 255),
    TOGGLE_ON = Color3.fromRGB(0, 200, 100),
    TOGGLE_OFF= Color3.fromRGB(50, 52, 70),
    KNOB      = Color3.fromRGB(255, 255, 255),
    BTN_ACT   = Color3.fromRGB(80, 80, 120),
    BTN_TELE  = Color3.fromRGB(100, 50, 200),
    TEXT      = Color3.fromRGB(235, 238, 250),
    SUBTEXT   = Color3.fromRGB(130, 135, 165),
    CLOSE     = Color3.fromRGB(220, 50, 60),
    TAB_ACT   = Color3.fromRGB(0, 170, 220),
    TAB_INACT = Color3.fromRGB(30, 32, 48),
    STROKE    = Color3.fromRGB(40, 44, 66),
    WHITE     = Color3.fromRGB(255, 255, 255),
    FLOAT     = Color3.fromRGB(0, 170, 220),
    CLOSET    = Color3.fromRGB(180, 100, 255),
}

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ESP colors
local HIGHLIGHT_COLOR = Color3.fromRGB(0, 255, 170)
local BEAST_COLOR     = Color3.fromRGB(255, 40, 40)
local SURVIVOR_COLOR  = Color3.fromRGB(0, 170, 255)
local EXITDOOR_COLOR  = Color3.fromRGB(255, 220, 0)
local CLOSET_COLOR    = Color3.fromRGB(180, 100, 255)

-- ESP state
local espEnabled, beastEspEnabled, survivorEspEnabled = false, false, false
local exitDoorEspEnabled, closetEspEnabled = false, false

local activeHighlights   = {}
local beastHighlights    = {}
local survivorHighlights = {}
local exitDoorHighlights = {}
local closetHighlights   = {}

-- Auto computer state
local autoComputerEnabled = false
local autoComputerLoop    = nil
local autoComputerFired   = false

-- Speed / noclip state
local safeSpeedEnabled = false
local SPEED_NORMAL, SPEED_JUMP = 19, 8
local speedLoop   = nil
local jumpCooldown = false

local noclipEnabled = false
local noclipConn    = nil

local currentKeybind = Enum.KeyCode.RightShift
local currentCompIndex, currentExitIndex = 1, 1

-- ─────────────────── Helpers ────────────────────────────────────────────────

local function getChar()   return LocalPlayer.Character end
local function getHRP()    local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()    local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

local function makeHighlight(name, adornee, fillColor, parent)
    if adornee:FindFirstChild(name) then return end
    local h = Instance.new("Highlight")
    h.Name              = name
    h.Adornee           = adornee
    h.FillColor         = fillColor
    h.FillTransparency  = 0.35
    h.OutlineColor      = C.WHITE
    h.OutlineTransparency = 0
    h.Parent            = parent or adornee
    return h
end

local function removeTag(obj, tag, tbl)
    if obj and obj:FindFirstChild(tag) then obj[tag]:Destroy() end
    if tbl then tbl[obj] = nil end
end

-- ─────────────────── Auto Computer ──────────────────────────────────────────

local function findTimingCircle()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild("TimingCircle", true)
end

local function isPinInBase(pin, base)
    local pinAngle  = pin.Rotation % 360
    local baseStart = base.Rotation % 360
    local radius    = math.max((base.Parent and base.Parent.AbsoluteSize.X / 2) or 100, 1)
    local arcWidth  = math.max((base.AbsoluteSize.X / (2 * math.pi * radius)) * 360, 5)
    local baseEnd   = (baseStart + arcWidth) % 360
    if baseStart <= baseEnd then
        return pinAngle >= baseStart and pinAngle <= baseEnd
    end
    return pinAngle >= baseStart or pinAngle <= baseEnd
end

local function fireEKey()
    pcall(function()
        keyclick(0x45)
    end)
end

local function startAutoComputer()
    if autoComputerLoop then return end
    autoComputerFired = false
    autoComputerLoop = task.spawn(function()
        local lastVisible = false
        while autoComputerEnabled do
            local tc = findTimingCircle()
            local nowVisible = tc ~= nil and tc.Visible ~= false
            if not nowVisible then
                autoComputerFired = false
                lastVisible = false
                task.wait(0.1)
                continue
            end
            if nowVisible and not lastVisible then autoComputerFired = false end
            lastVisible = nowVisible
            local base = tc:FindFirstChild("TimingBase", true)
            local pin  = tc:FindFirstChild("TimingPin", true)
            if base and pin and not autoComputerFired then
                pcall(function()
                    if isPinInBase(pin, base) then
                        autoComputerFired = true
                        pcall(fireEKey)
                        task.wait(1.5)
                    end
                end)
            end
            task.wait(0.03)
        end
        autoComputerLoop = nil
    end)
end

local function stopAutoComputer()
    autoComputerEnabled = false
    autoComputerFired   = false
    autoComputerLoop    = nil
end

-- ─────────────────── Computer ESP ───────────────────────────────────────────

local function isComputerUnfinished(model)
    if not model or not model:IsA("Model") then return false end
    local screen = model:FindFirstChild("Screen", true)
    if screen and screen:IsA("BasePart") then
        local r, g, b = math.floor(screen.Color.R*255), math.floor(screen.Color.G*255), math.floor(screen.Color.B*255)
        return math.abs(r-13) <= 15 and math.abs(g-105) <= 15 and math.abs(b-172) <= 15
    end
    return false
end

local function applyHighlight(obj)
    if not (obj:IsA("Model") and obj.Name == "ComputerTable") then return end
    if isComputerUnfinished(obj) then
        local h = makeHighlight("ComputerTableESP", obj, HIGHLIGHT_COLOR)
        if h then activeHighlights[obj] = h end
    else
        removeTag(obj, "ComputerTableESP", activeHighlights)
    end
end

local computerCheckLoop = nil
local function enableESP()
    espEnabled = true
    for _, obj in ipairs(Workspace:GetDescendants()) do task.defer(applyHighlight, obj) end
    if not computerCheckLoop then
        computerCheckLoop = task.spawn(function()
            while espEnabled do
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "ComputerTable" then applyHighlight(obj) end
                end
                task.wait(1)
            end
            computerCheckLoop = nil
        end)
    end
end

local function disableESP()
    espEnabled = false
    for obj in pairs(activeHighlights) do removeTag(obj, "ComputerTableESP", activeHighlights) end
    activeHighlights = {}
end

-- ─────────────────── Player ESP helpers ─────────────────────────────────────

local function isBeast(player)
    for _, container in ipairs({player.Character, player:FindFirstChild("Backpack")}) do
        if container and (container:FindFirstChild("Hammer") or container:FindFirstChild("BeastPowers")) then
            return true
        end
    end
    return false
end

local function applyBeastHighlight(player)
    local char = player.Character
    if not char then return end
    if isBeast(player) then
        local h = makeHighlight("BeastESP", char, BEAST_COLOR)
        if h then beastHighlights[player] = h end
    else
        removeTag(char, "BeastESP", beastHighlights)
    end
end

local function applySurvivorHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if not isBeast(player) then
        local h = makeHighlight("SurvivorESP", char, SURVIVOR_COLOR)
        if h then survivorHighlights[player] = h end
    else
        removeTag(char, "SurvivorESP", survivorHighlights)
    end
end

local function removeBeastHighlight(p)    removeTag(p.Character, "BeastESP",    beastHighlights);    beastHighlights[p] = nil    end
local function removeSurvivorHighlight(p) removeTag(p.Character, "SurvivorESP", survivorHighlights); survivorHighlights[p] = nil end

local function updatePlayerESP(player)
    if beastEspEnabled    then applyBeastHighlight(player)    else removeBeastHighlight(player) end
    if survivorEspEnabled then applySurvivorHighlight(player) else removeSurvivorHighlight(player) end
end

local function refreshPlayerESPs()
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESP(p) end
end

local refreshConn = nil
local function updateRefreshLoop()
    local anyActive = beastEspEnabled or survivorEspEnabled
    if anyActive and not refreshConn then
        refreshConn = RunService.Heartbeat:Connect(refreshPlayerESPs)
    elseif not anyActive and refreshConn then
        refreshConn:Disconnect() refreshConn = nil
    end
end

local function enableBeastESP()     beastEspEnabled = true;  refreshPlayerESPs(); updateRefreshLoop() end
local function disableBeastESP()
    beastEspEnabled = false
    for p in pairs(beastHighlights) do removeBeastHighlight(p) end
    beastHighlights = {}
    updateRefreshLoop()
end

local function enableSurvivorESP()  survivorEspEnabled = true;  refreshPlayerESPs(); updateRefreshLoop() end
local function disableSurvivorESP()
    survivorEspEnabled = false
    for p in pairs(survivorHighlights) do removeSurvivorHighlight(p) end
    survivorHighlights = {}
    updateRefreshLoop()
end

local function setupPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        updatePlayerESP(player)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(p) removeBeastHighlight(p) removeSurvivorHighlight(p) end)

-- ─────────────────── Exit Door / Closet ESP ─────────────────────────────────

local function makeWorldESP(name, color, tbl)
    return {
        apply = function(obj)
            if obj:IsA("Model") and obj.Name == name then
                local h = makeHighlight(name.."ESP", obj, color)
                if h then tbl[obj] = h end
            end
        end,
        remove = function(obj) removeTag(obj, name.."ESP", tbl) end,
        enable = function(self)
            for _, obj in ipairs(Workspace:GetDescendants()) do task.defer(self.apply, obj) end
        end,
        disable = function(self)
            for obj in pairs(tbl) do self.remove(obj) end
            for k in pairs(tbl) do tbl[k] = nil end
        end,
    }
end

local exitESP   = makeWorldESP("ExitDoor", EXITDOOR_COLOR, exitDoorHighlights)
local closetESP = makeWorldESP("Closet",   CLOSET_COLOR,   closetHighlights)

local function enableExitDoorESP()  exitDoorEspEnabled = true;  exitESP:enable()   end
local function disableExitDoorESP() exitDoorEspEnabled = false; exitESP:disable()  end
local function enableClosetESP()    closetEspEnabled = true;    closetESP:enable() end
local function disableClosetESP()   closetEspEnabled = false;   closetESP:disable()end

Workspace.DescendantAdded:Connect(function(obj)
    if espEnabled      then task.defer(applyHighlight, obj) end
    if closetEspEnabled   and obj:IsA("Model") and obj.Name == "Closet"    then task.defer(closetESP.apply, obj) end
    if exitDoorEspEnabled and obj:IsA("Model") and obj.Name == "ExitDoor"  then task.defer(exitESP.apply, obj) end
end)

-- ─────────────────── Teleport ────────────────────────────────────────────────

-- Đếm số hướng open (không trúng tường) từ một vị trí candidate
-- Candidate nào có nhiều open space nhất thì chọn → tránh bị kẹt tường
local PROBE_DIRS = {
    Vector3.new( 1, 0,  0),
    Vector3.new(-1, 0,  0),
    Vector3.new( 0, 0,  1),
    Vector3.new( 0, 0, -1),
}
local PROBE_DIST = 2.5  -- khoảng cách probe từ candidate ra 4 hướng

local function scoreOpenSpace(pos, rayParams)
    local score = 0
    for _, d in ipairs(PROBE_DIRS) do
        if not Workspace:Raycast(pos, d * PROBE_DIST, rayParams) then
            score = score + 1
        end
    end
    return score
end

local function findSafePositionInFront(targetCF)
    local char = getChar()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return targetCF end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- 4 hướng quanh target × 3 khoảng cách = 12 ứng viên
    local dirs = {targetCF.LookVector, -targetCF.LookVector, targetCF.RightVector, -targetCF.RightVector}
    local bestCF, bestScore = nil, -1

    for _, dist in ipairs({3.5, 4.5, 5.5}) do
        for _, dir in ipairs(dirs) do
            local origin = targetCF.Position + Vector3.new(0, 1.5, 0)
            local cand   = origin + dir * dist

            -- Kiểm tra không có tường giữa target và candidate
            if not Workspace:Raycast(origin, dir * dist, rayParams) then
                -- Kiểm tra có sàn phía dưới
                local down = Workspace:Raycast(cand + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), rayParams)
                if down then
                    local landPos = down.Position + Vector3.new(0, 3, 0)
                    local score   = scoreOpenSpace(landPos, rayParams)
                    if score > bestScore then
                        bestScore = score
                        -- Nhân vật nhìn về phía computer (ngược dir)
                        bestCF = CFrame.new(landPos, landPos - dir)
                    end
                end
            end
        end
    end

    return bestCF or (targetCF * CFrame.new(0, 5, 0))
end

local function safeTeleportTo(targetCF)
    local hrp = getHRP()
    if hrp then hrp.CFrame = findSafePositionInFront(targetCF) end
end

local function collectModels(name, filter)
    local results = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name and (not filter or filter(obj)) then
            table.insert(results, obj)
        end
    end
    table.sort(results, function(a, b) return a:GetDebugId() < b:GetDebugId() end)
    return results
end

local function teleportCyclic(list, getTargetCF, indexVar)
    if #list == 0 then return indexVar end
    if indexVar > #list then indexVar = 1 end
    local cf = getTargetCF(list[indexVar])
    if cf then safeTeleportTo(cf) end
    indexVar = indexVar % #list + 1
    return indexVar
end

local function getScreenCF(model)
    local s = model:FindFirstChild("Screen", true)
    if s and s:IsA("BasePart") then return s.CFrame end
    local p = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    return p and p.CFrame
end

local function teleportToExitDoor()
    local doors = collectModels("ExitDoor")
    currentExitIndex = teleportCyclic(doors, function(m)
        local p = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
        return p and p.CFrame
    end, currentExitIndex)
end

local function teleportToUnfinishedComputer()
    local comps = collectModels("ComputerTable", isComputerUnfinished)
    currentCompIndex = teleportCyclic(comps, getScreenCF, currentCompIndex)
end

-- ─────────────────── Speed ───────────────────────────────────────────────────

local function setSpeed(val)
    local hum = getHum()
    if hum then hum.WalkSpeed = val end
end

local function isJumping()
    local hum = getHum()
    if not hum then return false end
    local st = hum:GetState()
    return st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall
end

local function startSafeSpeed()
    if speedLoop then return end
    speedLoop = task.spawn(function()
        while safeSpeedEnabled do
            if isJumping() and not jumpCooldown and isBeast(LocalPlayer) then
                jumpCooldown = true
                setSpeed(SPEED_JUMP)
                task.delay(1, function()
                    if safeSpeedEnabled then setSpeed(SPEED_NORMAL) end
                    jumpCooldown = false
                end)
            elseif not isJumping() and not jumpCooldown then
                setSpeed(SPEED_NORMAL)
            end
            task.wait(0.1)
        end
        speedLoop = nil
    end)
end

local function stopSafeSpeed()
    safeSpeedEnabled = false
    jumpCooldown = false
    speedLoop = nil
end

-- ─────────────────── Noclip (R6 safe) ───────────────────────────────────────

-- R6 chỉ có 6 parts; tay/chân mặc định CanCollide = false.
-- Chỉ HumanoidRootPart và Torso mới có collision thật sự.
-- Nếu ta set tất cả = true khi tắt noclip thì tay sẽ bị xuyên bất thường.
local R6_COLLISION_PARTS = {
    HumanoidRootPart = true,
    Torso            = true,
    Head             = true,
    -- Left Arm / Right Arm / Left Leg / Right Leg: mặc định false → giữ false
}

local function enableNoclip()
    noclipEnabled = true
    noclipConn = RunService.Stepped:Connect(function()
        local char = getChar()
        if not char then return end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function disableNoclip()
    noclipEnabled = false
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end

    -- Restore đúng theo R6: chỉ bật collision cho HRP/Torso/Head
    local char = getChar()
    if char then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = R6_COLLISION_PARTS[part.Name] == true
            end
        end
    end

    -- Reset velocity: tránh lean / trượt nghiêng sau khi tắt noclip
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

-- ─────────────────── Misc ────────────────────────────────────────────────────

local function resetCharacter()
    local hum = getHum()
    local char = getChar()
    if hum then hum.Health = 0 elseif char then char:BreakJoints() end
end

-- ─────────────────── GUI ─────────────────────────────────────────────────────

local GUI_NAME   = "BaconHubV4"
local GUI_PARENT = (RunService:IsStudio() and LocalPlayer.PlayerGui) or CoreGui

if GUI_PARENT:FindFirstChild(GUI_NAME) then GUI_PARENT[GUI_NAME]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = GUI_NAME
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = GUI_PARENT

-- Float button
local floatBtn = Instance.new("TextButton")
floatBtn.Size             = UDim2.new(0, S(44), 0, S(44))
floatBtn.Position         = UDim2.new(0, S(16), 0.5, 0)
floatBtn.BackgroundColor3 = C.FLOAT
floatBtn.Text             = "B"
floatBtn.TextColor3       = C.WHITE
floatBtn.TextSize         = S(18)
floatBtn.Font             = Enum.Font.GothamBold
floatBtn.ZIndex           = 10
floatBtn.Parent           = screenGui
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(0, S(12))
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = C.WHITE floatStroke.Thickness = 1.5 floatStroke.Transparency = 0.6

do -- Float button drag
    local dragStart, startPos, isDragging
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
            dragStart  = input.Position
            startPos   = floatBtn.Position
        end
    end)
    floatBtn.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > 6 then isDragging = true end
            if isDragging then
                floatBtn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    floatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = nil
        end
    end)
    local function toggleShadow()
        if not isDragging then
            local s = screenGui:FindFirstChild("__shadow")
            if s then s.Visible = not s.Visible end
        end
        isDragging = false
    end
    floatBtn.MouseButton1Up:Connect(toggleShadow)
    floatBtn.TouchTap:Connect(function()
        local s = screenGui:FindFirstChild("__shadow")
        if s then s.Visible = not s.Visible end
    end)
end

-- Shadow / main frame
local shadow = Instance.new("Frame")
shadow.Name                 = "__shadow"
shadow.Size                 = UDim2.new(0, FRAME_W + S(6), 0, FRAME_H + S(6))
shadow.Position             = UDim2.new(0.5, -math.floor((FRAME_W+S(6))/2), 0.5, -math.floor((FRAME_H+S(6))/2))
shadow.BackgroundColor3     = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel      = 0
shadow.Active               = true
shadow.Draggable            = true
shadow.ZIndex               = 5
shadow.Parent               = screenGui
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, S(12))

local mainFrame = Instance.new("Frame", shadow)
mainFrame.Size            = UDim2.new(0, FRAME_W, 0, FRAME_H)
mainFrame.Position        = UDim2.new(0, S(3), 0, S(3))
mainFrame.BackgroundColor3= C.BG
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex          = 5
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, S(10))
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = C.STROKE mainStroke.Thickness = 1.2

-- Top bar
local topBar = Instance.new("Frame", mainFrame)
topBar.Size             = UDim2.new(1, 0, 0, S(38))
topBar.BackgroundColor3 = C.TOPBAR
topBar.BorderSizePixel  = 0
topBar.ZIndex           = 6
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, S(10))
local topCover = Instance.new("Frame", topBar)
topCover.Size             = UDim2.new(1, 0, 0, S(10))
topCover.Position         = UDim2.new(0, 0, 1, -S(10))
topCover.BackgroundColor3 = C.TOPBAR
topCover.BorderSizePixel  = 0
topCover.ZIndex           = 6

local titleLabel = Instance.new("TextLabel", topBar)
titleLabel.Size              = UDim2.new(1, -S(70), 1, 0)
titleLabel.Position          = UDim2.new(0, S(14), 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text              = "Bacon Hub"
titleLabel.TextColor3        = C.ACCENT
titleLabel.TextSize          = S(13)
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
titleLabel.ZIndex            = 7

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size             = UDim2.new(0, S(24), 0, S(24))
closeBtn.Position         = UDim2.new(1, -S(30), 0, S(7))
closeBtn.BackgroundColor3 = C.CLOSE
closeBtn.Text             = "x"
closeBtn.TextColor3       = C.WHITE
closeBtn.TextSize         = S(12)
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.ZIndex           = 7
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, S(6))

-- Tab bar
local TAB_H  = S(30)
local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
tabBar.Position         = UDim2.new(0, 0, 0, S(38))
tabBar.BackgroundColor3 = C.TOPBAR
tabBar.BorderSizePixel  = 0
tabBar.ZIndex           = 6
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder

local TAB_NAMES = {"Main", "ESP", "Teleport", "Local", "Settings"}
local tabButtons, tabPages = {}, {}

for i, name in ipairs(TAB_NAMES) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size             = UDim2.new(1/#TAB_NAMES, 0, 1, 0)
    btn.BackgroundColor3 = C.TAB_INACT
    btn.Text             = name
    btn.TextColor3       = C.SUBTEXT
    btn.TextSize         = S(9)
    btn.Font             = Enum.Font.GothamSemibold
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = i
    btn.ZIndex           = 7
    tabButtons[i] = btn
end

local divider = Instance.new("Frame", mainFrame)
divider.Size             = UDim2.new(1, 0, 0, 1)
divider.Position         = UDim2.new(0, 0, 0, S(38) + TAB_H)
divider.BackgroundColor3 = C.STROKE
divider.BorderSizePixel  = 0
divider.ZIndex           = 6

local CONTENT_Y  = S(38) + TAB_H + 1
local contentArea = Instance.new("Frame", mainFrame)
contentArea.Size               = UDim2.new(1, 0, 1, -CONTENT_Y)
contentArea.Position           = UDim2.new(0, 0, 0, CONTENT_Y)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants   = true
contentArea.ZIndex             = 6

local function makePage()
    local page = Instance.new("ScrollingFrame", contentArea)
    page.Size                  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency= 1
    page.BorderSizePixel       = 0
    page.ScrollBarThickness    = S(3)
    page.ScrollBarImageColor3  = C.ACCENT
    page.CanvasSize            = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    page.Visible               = false
    page.ZIndex                = 6
    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft = UDim.new(0,S(10)) pad.PaddingRight = UDim.new(0,S(10))
    pad.PaddingTop  = UDim.new(0,S(10)) pad.PaddingBottom = UDim.new(0,S(10))
    local list = Instance.new("UIListLayout", page)
    list.Padding    = UDim.new(0, S(7))
    list.SortOrder  = Enum.SortOrder.LayoutOrder
    return page
end

for i = 1, #TAB_NAMES do tabPages[i] = makePage() end

local currentTab = 0
local function switchTab(idx)
    if currentTab == idx then return end
    currentTab = idx
    for i, btn in ipairs(tabButtons) do
        local active = (i == idx)
        btn.BackgroundColor3 = active and C.TAB_ACT   or C.TAB_INACT
        btn.TextColor3       = active and C.WHITE     or C.SUBTEXT
    end
    for i, pg in ipairs(tabPages) do pg.Visible = (i == idx) end
end
for i, btn in ipairs(tabButtons) do btn.MouseButton1Click:Connect(function() switchTab(i) end) end

-- ─────────────────── Widget factories ────────────────────────────────────────

local TOGGLE_W = S(42) local TOGGLE_H = S(22) local KNOB_PAD = S(3)

local function addToggle(page, title, desc, onEnable, onDisable)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1, 0, 0, S(56))
    frame.BackgroundColor3 = C.PANEL frame.BorderSizePixel = 0 frame.ZIndex = 7
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, S(7))

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -(TOGGLE_W+S(20)), 0, S(18))
    lbl.Position = UDim2.new(0, S(10), 0, S(6))
    lbl.BackgroundTransparency = 1 lbl.Text = title lbl.TextColor3 = C.TEXT
    lbl.TextSize = S(11) lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.ZIndex = 8

    if desc and desc ~= "" then
        local sub = Instance.new("TextLabel", frame)
        sub.Size = UDim2.new(1, -(TOGGLE_W+S(20)), 0, S(14))
        sub.Position = UDim2.new(0, S(10), 0, S(26))
        sub.BackgroundTransparency = 1 sub.Text = desc sub.TextColor3 = C.SUBTEXT
        sub.TextSize = S(9) sub.Font = Enum.Font.Gotham
        sub.TextXAlignment = Enum.TextXAlignment.Left sub.ZIndex = 8
    end

    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0, TOGGLE_W, 0, TOGGLE_H)
    track.Position = UDim2.new(1, -(TOGGLE_W+S(10)), 0.5, -math.floor(TOGGLE_H/2))
    track.BackgroundColor3 = C.TOGGLE_OFF track.BorderSizePixel = 0 track.ZIndex = 8
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, TOGGLE_H)

    local knob = Instance.new("Frame", track)
    local KNOB_SZ = TOGGLE_H - KNOB_PAD*2
    knob.Size = UDim2.new(0, KNOB_SZ, 0, KNOB_SZ)
    knob.Position = UDim2.new(0, KNOB_PAD, 0, KNOB_PAD)
    knob.BackgroundColor3 = C.KNOB knob.BorderSizePixel = 0 knob.ZIndex = 9
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local KNOB_ON_X = TOGGLE_W - KNOB_SZ - KNOB_PAD
    local isOn = false

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0) btn.BackgroundTransparency = 1 btn.Text = "" btn.ZIndex = 10
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        track.BackgroundColor3 = isOn and C.TOGGLE_ON or C.TOGGLE_OFF
        knob.Position = UDim2.new(0, isOn and KNOB_ON_X or KNOB_PAD, 0, KNOB_PAD)
        if isOn then onEnable() else onDisable() end
    end)
    return frame
end

local function addAction(page, title, desc, color, onClick)
    local frame = Instance.new("Frame", page)
    frame.Size = UDim2.new(1, 0, 0, S(56))
    frame.BackgroundColor3 = C.PANEL frame.BorderSizePixel = 0 frame.ZIndex = 7
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, S(7))

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -S(16), 0, S(18))
    lbl.Position = UDim2.new(0, S(10), 0, S(6))
    lbl.BackgroundTransparency = 1 lbl.Text = title lbl.TextColor3 = C.TEXT
    lbl.TextSize = S(11) lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left lbl.ZIndex = 8

    if desc and desc ~= "" then
        local sub = Instance.new("TextLabel", frame)
        sub.Size = UDim2.new(1, -S(16), 0, S(12))
        sub.Position = UDim2.new(0, S(10), 0, S(24))
        sub.BackgroundTransparency = 1 sub.Text = desc sub.TextColor3 = C.SUBTEXT
        sub.TextSize = S(9) sub.Font = Enum.Font.Gotham
        sub.TextXAlignment = Enum.TextXAlignment.Left sub.ZIndex = 8
    end

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, S(90), 0, S(22))
    btn.Position = UDim2.new(1, -S(100), 0.5, -S(11))
    btn.BackgroundColor3 = color btn.Text = "RUN"
    btn.TextColor3 = C.WHITE btn.TextSize = S(9) btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, S(6))
    btn.MouseButton1Click:Connect(onClick)
    return frame
end

-- ─────────────────── Pages ───────────────────────────────────────────────────

-- Main
local infoLabel = Instance.new("TextLabel", tabPages[1])
infoLabel.Size = UDim2.new(1, 0, 0, S(28)) infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Bacon Hub v4.0" infoLabel.TextColor3 = C.SUBTEXT infoLabel.TextSize = S(10)
infoLabel.Font = Enum.Font.Gotham infoLabel.TextWrapped = true
infoLabel.TextXAlignment = Enum.TextXAlignment.Center infoLabel.ZIndex = 7

addToggle(tabPages[1], "Auto Computer", "Tu dong bam khi kim do cham vung trang",
    function() autoComputerEnabled = true startAutoComputer() end, stopAutoComputer)

-- ESP
addToggle(tabPages[2], "ESP Computer Table", "Hien thi may tinh chua xong",   enableESP,          disableESP)
addToggle(tabPages[2], "ESP The Beast",       "Hien thi Hammer / BeastPowers", enableBeastESP,     disableBeastESP)
addToggle(tabPages[2], "ESP Survivors",       "Hien thi nguoi choi con lai",   enableSurvivorESP,  disableSurvivorESP)
addToggle(tabPages[2], "ESP Exit Door",       "Hien thi cua thoat",            enableExitDoorESP,  disableExitDoorESP)
addToggle(tabPages[2], "ESP Closet",          "Hien thi tu go an nap",         enableClosetESP,    disableClosetESP)

-- Teleport
addAction(tabPages[3], "Teleport Exit Door", "Luan chuyen cac cong thoat hiem", C.BTN_TELE, teleportToExitDoor)
addAction(tabPages[3], "Teleport Computer",  "Teleport truoc man hinh computer", C.BTN_TELE, teleportToUnfinishedComputer)

-- Local
addToggle(tabPages[4], "Safe Speed", "Beast: nhay->8, dat->19 | Khac: 19",
    function() safeSpeedEnabled = true startSafeSpeed() end, stopSafeSpeed)
addToggle(tabPages[4], "Noclip",     "Di xuyen tuong / san", enableNoclip, disableNoclip)
addAction(tabPages[4], "Reset Character", "Reset nhan vat", C.BTN_ACT, resetCharacter)

-- Settings – keybind
local keybindFrame = Instance.new("Frame", tabPages[5])
keybindFrame.Size = UDim2.new(1, 0, 0, S(56))
keybindFrame.BackgroundColor3 = C.PANEL keybindFrame.BorderSizePixel = 0 keybindFrame.ZIndex = 7
Instance.new("UICorner", keybindFrame).CornerRadius = UDim.new(0, S(7))

local keybindTitle = Instance.new("TextLabel", keybindFrame)
keybindTitle.Size = UDim2.new(0.55, 0, 0, S(18)) keybindTitle.Position = UDim2.new(0, S(10), 0, S(8))
keybindTitle.BackgroundTransparency = 1 keybindTitle.Text = "Toggle GUI Key"
keybindTitle.TextColor3 = C.TEXT keybindTitle.TextSize = S(11) keybindTitle.Font = Enum.Font.GothamSemibold
keybindTitle.TextXAlignment = Enum.TextXAlignment.Left keybindTitle.ZIndex = 8

local keybindSub = Instance.new("TextLabel", keybindFrame)
keybindSub.Size = UDim2.new(0.55, 0, 0, S(14)) keybindSub.Position = UDim2.new(0, S(10), 0, S(28))
keybindSub.BackgroundTransparency = 1 keybindSub.Text = "Mac dinh: RightShift"
keybindSub.TextColor3 = C.SUBTEXT keybindSub.TextSize = S(9) keybindSub.Font = Enum.Font.Gotham
keybindSub.TextXAlignment = Enum.TextXAlignment.Left keybindSub.ZIndex = 8

local keybindBtn = Instance.new("TextButton", keybindFrame)
keybindBtn.Size = UDim2.new(0, S(100), 0, S(26)) keybindBtn.Position = UDim2.new(1, -S(110), 0.5, -S(13))
keybindBtn.BackgroundColor3 = C.PANEL2 keybindBtn.Text = "RightShift"
keybindBtn.TextColor3 = C.ACCENT keybindBtn.TextSize = S(9) keybindBtn.Font = Enum.Font.GothamBold
keybindBtn.ZIndex = 9
Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, S(6))
local kbStroke = Instance.new("UIStroke", keybindBtn)
kbStroke.Color = C.ACCENT kbStroke.Thickness = 1

local waitingForKey = false
keybindBtn.MouseButton1Click:Connect(function()
    if waitingForKey then return end
    waitingForKey = true keybindBtn.Text = "..." keybindBtn.TextColor3 = C.WHITE
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        currentKeybind = input.KeyCode
        keybindBtn.Text = input.KeyCode.Name keybindBtn.TextColor3 = C.ACCENT
        waitingForKey = false conn:Disconnect()
    end)
end)

-- ─────────────────── Global input / close ────────────────────────────────────

local guiVisible = true
local function toggleGui()
    guiVisible = not guiVisible
    shadow.Visible = guiVisible
end

closeBtn.MouseButton1Click:Connect(function()
    disableESP() disableBeastESP() disableSurvivorESP() disableExitDoorESP() disableClosetESP()
    stopSafeSpeed() stopAutoComputer()
    if noclipEnabled then disableNoclip() end
    if refreshConn then refreshConn:Disconnect() end
    screenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or waitingForKey then return end
    if input.KeyCode == currentKeybind then toggleGui() end
end)

switchTab(1)

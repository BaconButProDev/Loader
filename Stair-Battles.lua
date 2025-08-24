local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("AutoFarmGui") then
    CoreGui.AutoFarmGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFarmGui"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 210)
Frame.Position = UDim2.new(0.5, -120, 0.22, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.BackgroundTransparency = 1
Title.Text = "Enhanced Auto Farm"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Parent = Frame

local function makeBtn(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.84, 0, 0, 30)
    b.Position = UDim2.new(0.08, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(150,0,0)
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Text = text
    b.Parent = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local BlockBtn = makeBtn("Auto Block: OFF", 46)
local StairBtn = makeBtn("Auto Build Stair: OFF", 84)
local MoneyBtn = makeBtn("Auto Money: OFF", 122)
local WinBtn = makeBtn("Auto Win: OFF", 160)

local UIS = game:GetService("UserInputService")
do
    local dragging, dragStart, startPos
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart"), char
end

local function myBase()
    local ff = workspace:FindFirstChild("FunctionalFolder")
    if not ff then return nil end
    local tname = (LocalPlayer.Team and LocalPlayer.Team.Name or ""):lower()
    local baseName = (tname:find("red") and "RedBase") or (tname:find("blue") and "BlueBase") or nil
    if not baseName then return nil end
    return ff:FindFirstChild(baseName)
end

local function haveBlocksTool()
    local char = getCharacter()
    if not char then return nil end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("block") then return v end
    end
    for _,v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("block") then return v end
    end
    return nil
end

local function equipBlocksTool()
    local char = getCharacter()
    if not char then return nil end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    
    for _,v in ipairs(backpack:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("block") then
            v.Parent = char
            return v
        end
    end
    for _,v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and v.Name:lower():find("block") then return v end
    end
    return nil
end

local function quickTP(hrp, newPos, bursts)
    if not hrp then return end
    local rot = hrp.CFrame - hrp.Position
    bursts = bursts or 6
    for _=1,bursts do
        hrp.CFrame = rot + newPos
        RunService.Heartbeat:Wait()
    end
end

local AutoBlock, AutoStair, AutoMoney, AutoWin = false, false, false, false

local function doAutoBlock()
    if not AutoBlock then return end
    local hrp = getHRP()
    if not hrp then return end

    if haveBlocksTool() then return end

    local base = myBase()
    if not base then return end
    local giver = base:FindFirstChild("BlockGiver")
    if not giver then return end

    local oldPos = hrp.Position
    local rot = hrp.CFrame - hrp.Position

    quickTP(hrp, giver.Position + Vector3.new(0,3,0), 8)

    local t = 0
    while t < 1.8 do
        if haveBlocksTool() then break end
        RunService.Heartbeat:Wait()
        t += 0.05
    end

    hrp.CFrame = rot + oldPos
end

local function collectBlocks(blocksFolder)
    local map, asc = {}, {}
    for _,b in ipairs(blocksFolder:GetChildren()) do
        if b:IsA("BasePart") then
            local n = tonumber(b.Name)
            if n then
                map[n] = b
                table.insert(asc, n)
            end
        end
    end
    table.sort(asc, function(a,b) return a < b end)
    local desc = {}
    for i=#asc,1,-1 do table.insert(desc, asc[i]) end
    local maxNum = asc[#asc] or 0
    return map, asc, desc, maxNum
end

local function nearestLowerPresent(map, asc, wantNum)
    if not wantNum or wantNum < 1 then return nil end
    local best = nil
    for i=#asc,1,-1 do
        local n = asc[i]
        if n <= wantNum then best = n; break end
    end
    if best and map[best] then return best end
    return nil
end

local function findFirstGap(asc)
    for i=1,#asc-1 do
        local a, b = asc[i], asc[i+1]
        if b > a + 1 then
            return a, a+1, b
        end
    end
    return nil, nil, nil
end

_G.__stairBackAnchor = _G.__stairBackAnchor or nil
_G.__stairPrevMax = _G.__stairPrevMax or 0
_G.__lastStairAction = _G.__lastStairAction or 0
_G.__stairStuckTimer = _G.__stairStuckTimer or 0
_G.__stairLastMax = _G.__stairLastMax or 0

local function doAutoStair()
    if not AutoStair then return end
    local hrp = getHRP()
    if not hrp then return end

    local currentTime = tick()

    equipBlocksTool()
    if not haveBlocksTool() then
        pcall(doAutoBlock)
        equipBlocksTool()
        if not haveBlocksTool() then return end
    end

    local base = myBase()
    if not base then return end
    local blocksFolder = base:FindFirstChild("Blocks")
    local ff = workspace:FindFirstChild("FunctionalFolder")
    if not ff then return end

    if not blocksFolder or #blocksFolder:GetChildren() == 0 then
        local start = ff:FindFirstChild("StartStair")
        if start then
            local oldPos = hrp.Position
            local rot = hrp.CFrame - hrp.Position
            quickTP(hrp, start.Position + Vector3.new(0,3,0), 8)
            local t = 0
            while t < 1.5 do
                if blocksFolder and #blocksFolder:GetChildren() > 0 then break end
                RunService.Heartbeat:Wait()
                t += 0.05
            end
            hrp.CFrame = rot + oldPos
        end
        return
    end

    local map, asc, desc, maxNum = collectBlocks(blocksFolder)

    if maxNum > 504 then
        if _G.__stairLastMax == maxNum then
            _G.__stairStuckTimer = _G.__stairStuckTimer + 0.12
            if _G.__stairStuckTimer > 3 then
                AutoStair = false
                StairBtn.Text = "Auto Build Stair: OFF"
                StairBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
                return
            end
        else
            _G.__stairStuckTimer = 0
            _G.__stairLastMax = maxNum
        end
    else
        _G.__stairStuckTimer = 0
        _G.__stairLastMax = maxNum
    end

    local lowerAnchor, firstMissing, upperNum = findFirstGap(asc)
    if firstMissing then
        local anchorNum = lowerAnchor
        if not map[anchorNum] then
            anchorNum = nearestLowerPresent(map, asc, anchorNum) or asc[1]
        end
        local anchorPart = map[anchorNum]
        if not anchorPart then return end

        local targetPos = anchorPart.Position
        if math.abs(firstMissing - anchorNum) > 50 then
            targetPos = targetPos + Vector3.new(0, 10, 0)
        end

        local beforeCount = #blocksFolder:GetChildren()
        quickTP(hrp, targetPos + Vector3.new(0,3,0), 8)

        local t, placed = 0, false
        while t < 1.6 do
            if #blocksFolder:GetChildren() > beforeCount then
                placed = true; break
            end
            local maybe = blocksFolder:FindFirstChild(tostring(firstMissing))
            if maybe and maybe:IsA("BasePart") then
                placed = true; break
            end
            RunService.Heartbeat:Wait()
            t += 0.05
        end

        if currentTime - _G.__lastStairAction > 0.25 then
            _G.__stairBackAnchor = math.max(1, (_G.__stairBackAnchor or firstMissing) - 1)
            _G.__lastStairAction = currentTime
        end
        return
    end

    local desiredStart = math.max(1, maxNum - 15)
    if _G.__stairBackAnchor == nil or maxNum ~= _G.__stairPrevMax then
        _G.__stairBackAnchor = desiredStart
        _G.__stairPrevMax = maxNum
    end

    if not map[_G.__stairBackAnchor] then
        local found = nearestLowerPresent(map, asc, _G.__stairBackAnchor)
        if found then
            _G.__stairBackAnchor = found
        else
            _G.__stairBackAnchor = asc[1] or 1
        end
    end

    local anchorPart = map[_G.__stairBackAnchor]
    if not anchorPart then return end

    local targetPos = anchorPart.Position
    if math.abs(maxNum - _G.__stairBackAnchor) > 50 then
        targetPos = targetPos + Vector3.new(0, 10, 0)
    end

    local beforeCount = #blocksFolder:GetChildren()
    quickTP(hrp, targetPos + Vector3.new(0,3,0), 8)

    local t, placed = 0, false
    while t < 1.4 do
        if #blocksFolder:GetChildren() > beforeCount then
            placed = true; break
        end
        RunService.Heartbeat:Wait()
        t += 0.05
    end

    if currentTime - _G.__lastStairAction > 0.25 then
        if placed then
            _G.__stairBackAnchor = math.max(1, _G.__stairBackAnchor - 1)
        else
            _G.__stairBackAnchor = math.max(1, _G.__stairBackAnchor - 1)
        end
        _G.__lastStairAction = currentTime
    end
end

local function doAutoMoney()
    if not AutoMoney then return end
    local hrp = getHRP()
    if not hrp then return end
    
    local ff = workspace:FindFirstChild("FunctionalFolder")
    if not ff then return end
    local obbyFolder = ff:FindFirstChild("ObbyFolder")
    if not obbyFolder then return end

    for _,o in ipairs(obbyFolder:GetChildren()) do
        local goal = o:FindFirstChild("GoalPart")
        if goal and goal:IsA("BasePart") then
            quickTP(hrp, goal.Position + Vector3.new(0,3,0), 6)
        end
    end
end

local function doAutoWin()
    if not AutoWin then return end
    local hrp = getHRP()
    if not hrp then return end
    
    local base = myBase()
    if not base then return end
    local blocksFolder = base:FindFirstChild("Blocks")
    if not blocksFolder then return end

    local blockCount = 0
    for _,b in ipairs(blocksFolder:GetChildren()) do
        if b:IsA("BasePart") then
            local n = tonumber(b.Name)
            if n then blockCount = math.max(blockCount, n) end
        end
    end

    if blockCount >= 450 then
        local ff = workspace:FindFirstChild("FunctionalFolder")
        if not ff then return end
        local trophy = ff:FindFirstChild("Trophy")
        if not trophy then return end
        local touchPart = trophy:FindFirstChild("TouchPart")
        if touchPart and touchPart:IsA("BasePart") then
            quickTP(hrp, touchPart.Position + Vector3.new(0,3,0), 8)
            AutoWin = false
            WinBtn.Text = "Auto Win: OFF"
            WinBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
        end
    end
end

local function setBtn(b, on)
    b.BackgroundColor3 = on and Color3.fromRGB(0,170,0) or Color3.fromRGB(150,0,0)
end

BlockBtn.MouseButton1Click:Connect(function()
    AutoBlock = not AutoBlock
    BlockBtn.Text = "Auto Block: " .. (AutoBlock and "ON" or "OFF")
    setBtn(BlockBtn, AutoBlock)
end)

StairBtn.MouseButton1Click:Connect(function()
    AutoStair = not AutoStair
    StairBtn.Text = "Auto Build Stair: " .. (AutoStair and "ON" or "OFF")
    setBtn(StairBtn, AutoStair)
    if AutoStair then
        _G.__stairStuckTimer = 0
    end
end)

MoneyBtn.MouseButton1Click:Connect(function()
    AutoMoney = not AutoMoney
    MoneyBtn.Text = "Auto Money: " .. (AutoMoney and "ON" or "OFF")
    setBtn(MoneyBtn, AutoMoney)
end)

WinBtn.MouseButton1Click:Connect(function()
    AutoWin = not AutoWin
    WinBtn.Text = "Auto Win: " .. (AutoWin and "ON" or "OFF")
    setBtn(WinBtn, AutoWin)
end)

local function onCharacterAdded(character)
    _G.__stairBackAnchor = nil
    _G.__stairPrevMax = 0
    _G.__lastStairAction = 0
    _G.__stairStuckTimer = 0
    _G.__stairLastMax = 0
    
    character:WaitForChild("HumanoidRootPart")
    task.wait(1)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

task.spawn(function()
    while true do
        if AutoBlock and getCharacter() then 
            pcall(doAutoBlock) 
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while true do
        if AutoStair and getCharacter() then 
            pcall(doAutoStair) 
        end
        task.wait(0.12)
    end
end)

task.spawn(function()
    while true do
        if AutoMoney and getCharacter() then 
            pcall(doAutoMoney) 
        end
        task.wait(0.08)
    end
end)

task.spawn(function()
    while true do
        if AutoWin and getCharacter() then 
            pcall(doAutoWin) 
        end
        task.wait(0.5)
    end
end)

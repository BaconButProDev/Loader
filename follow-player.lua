local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("FollowGui") then
    PlayerGui.FollowGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FollowGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 280)
Frame.Position = UDim2.new(0.5, -150, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Text = "👣 Follow Player"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local dragging, dragInput, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
Frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TextBox = Instance.new("TextBox")
TextBox.PlaceholderText = "Nhập tên / display name..."
TextBox.Size = UDim2.new(1, -20, 0, 30)
TextBox.Position = UDim2.new(0, 10, 0, 40)
TextBox.Text = ""
TextBox.TextSize = 16
TextBox.TextColor3 = Color3.fromRGB(0,0,0)
TextBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
TextBox.Parent = Frame
Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 8)

local BehindBox = Instance.new("TextBox")
BehindBox.PlaceholderText = "Behind (studs)"
BehindBox.Size = UDim2.new(0.5, -15, 0, 30)
BehindBox.Position = UDim2.new(0, 10, 0, 80)
BehindBox.Text = "3"
BehindBox.TextSize = 16
BehindBox.TextColor3 = Color3.fromRGB(0,0,0)
BehindBox.BackgroundColor3 = Color3.fromRGB(255,255,255)
BehindBox.Parent = Frame
Instance.new("UICorner", BehindBox).CornerRadius = UDim.new(0, 8)

local UnderBtn = Instance.new("TextButton")
UnderBtn.Text = "Under: OFF"
UnderBtn.Size = UDim2.new(0.5, -15, 0, 30)
UnderBtn.Position = UDim2.new(0.5, 5, 0, 80)
UnderBtn.TextColor3 = Color3.fromRGB(255,255,255)
UnderBtn.Font = Enum.Font.GothamBold
UnderBtn.TextSize = 16
UnderBtn.BackgroundColor3 = Color3.fromRGB(100,100,200)
UnderBtn.Parent = Frame
Instance.new("UICorner", UnderBtn).CornerRadius = UDim.new(0, 8)

local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Text = "Noclip: ON"
NoclipBtn.Size = UDim2.new(0.5, -15, 0, 30)
NoclipBtn.Position = UDim2.new(0, 10, 0, 120)
NoclipBtn.TextColor3 = Color3.fromRGB(255,255,255)
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.TextSize = 16
NoclipBtn.BackgroundColor3 = Color3.fromRGB(0,200,100)
NoclipBtn.Parent = Frame
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0, 8)

local SafeHPBtn = Instance.new("TextButton")
SafeHPBtn.Text = "Safe HP: OFF"
SafeHPBtn.Size = UDim2.new(0.5, -15, 0, 30)
SafeHPBtn.Position = UDim2.new(0.5, 5, 0, 120)
SafeHPBtn.TextColor3 = Color3.fromRGB(255,255,255)
SafeHPBtn.Font = Enum.Font.GothamBold
SafeHPBtn.TextSize = 16
SafeHPBtn.BackgroundColor3 = Color3.fromRGB(100,100,200)
SafeHPBtn.Parent = Frame
Instance.new("UICorner", SafeHPBtn).CornerRadius = UDim.new(0, 8)

local StartBtn = Instance.new("TextButton")
StartBtn.Text = "▶ Start Follow"
StartBtn.Size = UDim2.new(1, -20, 0, 30)
StartBtn.Position = UDim2.new(0, 10, 0, 160)
StartBtn.TextColor3 = Color3.fromRGB(255,255,255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 16
StartBtn.BackgroundColor3 = Color3.fromRGB(50,150,250)
StartBtn.Parent = Frame
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

local StopBtn = Instance.new("TextButton")
StopBtn.Text = "⏹ Stop Follow"
StopBtn.Size = UDim2.new(1, -20, 0, 30)
StopBtn.Position = UDim2.new(0, 10, 0, 200)
StopBtn.TextColor3 = Color3.fromRGB(255,255,255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 16
StopBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
StopBtn.Parent = Frame
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)

local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Text = "❌ Delete GUI"
DeleteBtn.Size = UDim2.new(1, -20, 0, 30)
DeleteBtn.Position = UDim2.new(0, 10, 0, 240)
DeleteBtn.TextColor3 = Color3.fromRGB(255,255,255)
DeleteBtn.Font = Enum.Font.GothamBold
DeleteBtn.TextSize = 16
DeleteBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
DeleteBtn.Parent = Frame
Instance.new("UICorner", DeleteBtn).CornerRadius = UDim.new(0, 8)

local connection, noclipConnection, safeHPConnection
local UnderMode = false
local NoclipMode = true
local SafeHP = false

UnderBtn.MouseButton1Click:Connect(function()
    UnderMode = not UnderMode
    UnderBtn.Text = "Under: " .. (UnderMode and "ON" or "OFF")
    UnderBtn.BackgroundColor3 = UnderMode and Color3.fromRGB(0,200,100) or Color3.fromRGB(100,100,200)
end)

NoclipBtn.MouseButton1Click:Connect(function()
    NoclipMode = not NoclipMode
    NoclipBtn.Text = "Noclip: " .. (NoclipMode and "ON" or "OFF")
    NoclipBtn.BackgroundColor3 = NoclipMode and Color3.fromRGB(0,200,100) or Color3.fromRGB(100,100,200)
end)

SafeHPBtn.MouseButton1Click:Connect(function()
    SafeHP = not SafeHP
    SafeHPBtn.Text = "Safe HP: " .. (SafeHP and "ON" or "OFF")
    SafeHPBtn.BackgroundColor3 = SafeHP and Color3.fromRGB(0,200,100) or Color3.fromRGB(100,100,200)
end)

local function startNoclip()
    if noclipConnection or not NoclipMode then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end
local function stopNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function startSafeHP()
    if safeHPConnection or not SafeHP then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        safeHPConnection = hum.HealthChanged:Connect(function(hp)
            if hp > 0 and hp <= hum.MaxHealth * 0.3 then
                -- teleport spawn point (thay đổi tuỳ game)
                local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildWhichIsA("SpawnLocation")
                if spawn then
                    LocalPlayer.Character:MoveTo(spawn.Position + Vector3.new(0,5,0))
                else
                    LocalPlayer.Character:MoveTo(Vector3.new(0,50,0)) -- fallback
                end
            end
        end)
    end
end
local function stopSafeHP()
    if safeHPConnection then
        safeHPConnection:Disconnect()
        safeHPConnection = nil
    end
end

local function followPlayer(player)
    if connection then connection:Disconnect() end
    connection = RunService.RenderStepped:Connect(function()
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHRP = myChar.HumanoidRootPart
                if UnderMode then
                    local underPos = hrp.Position - Vector3.new(0, 5, 0)
                    myHRP.CFrame = CFrame.new(underPos, hrp.Position) * CFrame.Angles(math.rad(90), 0, 0)
                else
                    local dist = tonumber(BehindBox.Text) or 3
                    local backPos = hrp.Position - (hrp.CFrame.LookVector * dist)
                    myHRP.CFrame = CFrame.new(backPos, hrp.Position)
                end
            end
        end
    end)
    startNoclip()
    startSafeHP()
end

StartBtn.MouseButton1Click:Connect(function()
    local input = string.lower(TextBox.Text)
    if input == "" then return end
    local targetPlayer
    for _, plr in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(plr.Name), input) or string.find(string.lower(plr.DisplayName), input) then
            targetPlayer = plr
            break
        end
    end
    if targetPlayer then
        followPlayer(targetPlayer)
        StartBtn.Text = "✅ Following: " .. targetPlayer.DisplayName
    else
        StartBtn.Text = "❌ Không tìm thấy"
        task.delay(1.5, function() StartBtn.Text = "▶ Start Follow" end)
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    if connection then connection:Disconnect() end
    stopNoclip()
    stopSafeHP()
    StartBtn.Text = "▶ Start Follow"
end)

DeleteBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

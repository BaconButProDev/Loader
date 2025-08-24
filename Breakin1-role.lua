local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("RoleGui") then
    PlayerGui.RoleGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RoleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Frame chính
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 380)
Frame.Position = UDim2.new(0.35, 0, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Role Selector"
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Parent = Frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local function createButton(name, yPos, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.8, 0, 0, 30)
    Button.Position = UDim2.new(0.1, 0, 0, yPos)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Text = name
    Button.TextScaled = true
    Button.Font = Enum.Font.SourceSansBold
    Button.Parent = Frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = Button

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end)
    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)

    Button.MouseButton1Click:Connect(callback)
end

local gap = 40

createButton("Bat", gap * 1, function()
    local args = {"Bat", false, false}
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("MakeRole"):FireServer(unpack(args))
end)

createButton("Medkit", gap * 2, function()
    local args = {"MedKit", false, false}
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("MakeRole"):FireServer(unpack(args))
end)

createButton("Swat", gap * 3, function()
    local A_1 = "SwatGun"
    local A_2 = true
    local Event = game:GetService("ReplicatedStorage").RemoteEvents.OutsideRole
    Event:FireServer(A_1, A_2)
end)

createButton("Police", gap * 4, function()
    local A_1 = "Gun"
    local A_2 = true
    local Event = game:GetService("ReplicatedStorage").RemoteEvents.OutsideRole
    Event:FireServer(A_1, A_2)
end)

createButton("Sword", gap * 5, function()
    local A_1 = "Sword"
    local A_2 = true
    local Event = game:GetService("ReplicatedStorage").RemoteEvents.OutsideRole
    Event:FireServer(A_1, A_2)
end)

createButton("Lollipop", gap * 6, function()
    local args = {"Lollipop", true, false}
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("MakeRole"):FireServer(unpack(args))
end)

createButton("TeddyBloxpin", gap * 7, function()
    local args = {"TeddyBloxpin", true, false}
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("MakeRole"):FireServer(unpack(args))
end)

createButton("Chips", gap * 8, function()
    local args = {"Chips", true, false}
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("MakeRole"):FireServer(unpack(args))
end)

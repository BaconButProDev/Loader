local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("CustomLoader") then
    PlayerGui.CustomLoader:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 260)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local function trySetZ(obj, z)
    if pcall(function() return obj.ZIndex end) then
        obj.ZIndex = z
    end
end

trySetZ(MainFrame, 100)

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(100, 255, 150)
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "🚀 Script Loader"
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextStrokeTransparency = 0.8
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame
trySetZ(Title, 110)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "❌"
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
trySetZ(CloseBtn, 110)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
    wait(0.6)
    ScreenGui:Destroy()
end)

local function createButton(text, posY)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.8, 0, 0, 50)
    Button.Position = UDim2.new(0.1, 0, posY, 0)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.Text = text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 16
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextStrokeTransparency = 0.8

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1.5
    Stroke.Color = Color3.fromRGB(150, 150, 255)
    Stroke.Parent = Button

    Button.Parent = MainFrame
    trySetZ(Button, 105)
    return Button
end

local AimbotBtn = createButton("🎯 Load Aimbot Script", 0.20)
local PlaneBtn = createButton("✈️ Load Build a Plane Script", 0.40)
local LuckyBlockBtn = createButton("🟨 Load Lucky Block Script", 0.60)
local BreakinBtn = createButton("🏠 Load Break In Roles Script", 0.80)

local function closeGui()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
    wait(0.6)
    ScreenGui:Destroy()
end

AimbotBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/aimbot.lua"))()
    closeGui()
end)

PlaneBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/auto-buy.lua"))()
    closeGui()
end)

LuckyBlockBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/lucky-block.lua"))()
    closeGui()
end)

BreakinBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/Breakin1-role.lua"))()
    closeGui()
end)

MainFrame.Size = UDim2.new(0,0,0,0)
local tweenIn = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.new(0,350,0,300)})
tweenIn:Play()

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Xóa GUI cũ nếu có
if PlayerGui:FindFirstChild("CustomLoader") then
    PlayerGui.CustomLoader:Destroy()
end

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- MainFrame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.35, 0, 0.55, 0) -- chiếm 35% ngang, 55% dọc (PC & mobile đều fit)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(100, 255, 150)
Stroke.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Text = "🚀 Script Loader"
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextStrokeTransparency = 0.8
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Close Btn
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "❌"
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

-- Scroll container (để chứa nút, không bị chật)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

-- Layout + Padding
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0,10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = ScrollFrame

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0,5)
Padding.PaddingBottom = UDim.new(0,5)
Padding.Parent = ScrollFrame

-- Close function
local function closeGui()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
    wait(0.6)
    ScreenGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(closeGui)

-- Create Button
local function createButton(text, url)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.9, 0, 0, 45)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.Text = text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 18
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextStrokeTransparency = 0.8

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 1.5
    Stroke.Color = Color3.fromRGB(150, 150, 255)
    Stroke.Parent = Button

    Button.Parent = ScrollFrame

    Button.MouseButton1Click:Connect(function()
        loadstring(game:HttpGet(url))()
        closeGui()
    end)

    return Button
end

-- Các script
createButton("🎯 Load Aimbot Script", "https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/aimbot.lua")
createButton("✈️ Load Build a Plane Script", "https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/auto-buy.lua")
createButton("🟨 Load Lucky Block Script", "https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/lucky-block.lua")
createButton("🏠 Load Break In Roles Script", "https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/Breakin1-role.lua")
createButton("🪜 Load Stairs Battles Script", "https://raw.githubusercontent.com/BaconButProDev/Loader/refs/heads/main/Stair-Battles.lua")

-- Tween In
MainFrame.Size = UDim2.new(0,0,0,0)
local tweenIn = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.new(0.35,0,0.55,0)})
tweenIn:Play()

-- Drag
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
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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

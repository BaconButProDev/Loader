local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remote = ReplicatedStorage:WaitForChild("SpawnLuckyBlock")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function tween(inst, props, time, style, dir)
    return TweenService:Create(inst, TweenInfo.new(time or 0.22, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local theme = {
    panel = Color3.fromRGB(45, 47, 60),
    text = Color3.fromRGB(235,235,235),
    button = Color3.fromRGB(60, 63, 80),
    buttonHover = Color3.fromRGB(85, 90, 110),
    accent = Color3.fromRGB(255,200,40),
    shadow = Color3.fromRGB(0,0,0),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuckyBlockGuiFixed"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 300, 0, 260)
Shadow.Position = UDim2.new(0.5, -150, 0.5, -130)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundColor3 = theme.shadow
Shadow.BackgroundTransparency = 0.9
Shadow.BorderSizePixel = 0
Shadow.Parent = ScreenGui
local ShadowCorner = Instance.new("UICorner", Shadow)
ShadowCorner.CornerRadius = UDim.new(0, 16)

local Frame = Instance.new("Frame")
Frame.Name = "Panel"
Frame.Size = UDim2.new(0, 320, 0, 260)
Frame.Position = UDim2.new(0.5, -160, 0.5, -130)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = theme.panel
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner", Frame)
FrameCorner.CornerRadius = UDim.new(0, 14)

local UIGrad = Instance.new("UIGradient", Frame)
UIGrad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, theme.panel), ColorSequenceKeypoint.new(1, Color3.fromRGB(38,38,48)) }
UIGrad.Rotation = 270

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Thickness = 1
Stroke.Transparency = 0.75
Stroke.Color = theme.accent

local TitleBar = Instance.new("Frame", Frame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -24, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Lucky Block Spawner"
Title.TextColor3 = theme.text
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", TitleBar)
Sub.Size = UDim2.new(1, -24, 0, 16)
Sub.Position = UDim2.new(0, 12, 1, -18)
Sub.BackgroundTransparency = 1
Sub.Text = ""
Sub.TextColor3 = Color3.fromRGB(200,200,200)
Sub.TextSize = 12
Sub.Font = Enum.Font.Gotham

local Body = Instance.new("Frame", Frame)
Body.Name = "Body"
Body.Size = UDim2.new(1, -28, 1, -120)
Body.Position = UDim2.new(0, 14, 0, 58)
Body.BackgroundTransparency = 1

local List = Instance.new("UIListLayout", Body)
List.FillDirection = Enum.FillDirection.Vertical
List.SortOrder = Enum.SortOrder.LayoutOrder
List.Padding = UDim.new(0, 12)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center
List.VerticalAlignment = Enum.VerticalAlignment.Top

local function makeButton(name, text, layoutOrder)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.95, 0, 0, 48)
    btn.BackgroundColor3 = theme.button
    btn.Text = text
    btn.TextColor3 = theme.text
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = layoutOrder or 1
    btn.Parent = Body

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 12)

    local uiScale = Instance.new("UIScale", btn)
    uiScale.Scale = 1

    btn.MouseEnter:Connect(function()
        TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = 1.03}):Play()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = theme.buttonHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Scale = 1}):Play()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = theme.button}):Play()
    end)

    return btn
end

local Button50 = makeButton("Button50", "Spawn 50 Tools", 1)
local Button200 = makeButton("Button200", "Spawn 200 Tools", 2)

local InputFrame = Instance.new("Frame", Body)
InputFrame.Size = UDim2.new(0.95, 0, 0, 48)
InputFrame.BackgroundColor3 = Color3.fromRGB(22,22,28)
InputFrame.BorderSizePixel = 0
InputFrame.LayoutOrder = 3
local InputCorner = Instance.new("UICorner", InputFrame)
InputCorner.CornerRadius = UDim.new(0, 10)

local TextBox = Instance.new("TextBox", InputFrame)
TextBox.PlaceholderText = "Enter amount"
TextBox.Text = ""
TextBox.Size = UDim2.new(0.72, -8, 1, 0)
TextBox.Position = UDim2.new(0, 8, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.TextColor3 = theme.text
TextBox.Font = Enum.Font.Gotham
TextBox.TextSize = 16
TextBox.ClearTextOnFocus = false
TextBox.TextXAlignment = Enum.TextXAlignment.Left

local SpawnCustomBtn = Instance.new("TextButton", InputFrame)
SpawnCustomBtn.Size = UDim2.new(0.26, 0, 0.84, 0)
SpawnCustomBtn.Position = UDim2.new(0.74, 0, 0.08, 0)
SpawnCustomBtn.AnchorPoint = Vector2.new(0,0)
SpawnCustomBtn.Text = "Spawn"
SpawnCustomBtn.Font = Enum.Font.GothamBold
SpawnCustomBtn.TextScaled = true
SpawnCustomBtn.BackgroundColor3 = theme.button
SpawnCustomBtn.TextColor3 = theme.text
SpawnCustomBtn.BorderSizePixel = 0
local cornerSC = Instance.new("UICorner", SpawnCustomBtn)
cornerSC.CornerRadius = UDim.new(0, 8)

local Credits = Instance.new("TextLabel", Frame)
Credits.Size = UDim2.new(1, -24, 0, 18)
Credits.Position = UDim2.new(0, 12, 1, -28)
Credits.BackgroundTransparency = 1
Credits.Text = "Made By: Bacon But Pro"
Credits.TextColor3 = Color3.fromRGB(200, 200, 200)
Credits.TextScaled = false
Credits.Font = Enum.Font.Gotham
Credits.TextSize = 12
Credits.TextXAlignment = Enum.TextXAlignment.Left

local function spawnLuckyBlock(times)
    times = math.clamp(tonumber(times) or 0, 1, 1000)
    for i = 1, times do
        Remote:FireServer()
        task.wait(0.05)
    end
end

Button50.MouseButton1Click:Connect(function()
    spawnLuckyBlock(50)
end)
Button200.MouseButton1Click:Connect(function()
    spawnLuckyBlock(200)
end)
SpawnCustomBtn.MouseButton1Click:Connect(function()
    local n = tonumber(TextBox.Text)
    if not n then
        local orig = TextBox.Position
        tween(TextBox, {Position = UDim2.new(orig.X.Scale, orig.X.Offset + 6, orig.Y.Scale, orig.Y.Offset)}, 0.04):Play()
        task.delay(0.04, function() tween(TextBox, {Position = orig}, 0.04):Play() end)
        return
    end
    spawnLuckyBlock(math.clamp(n, 1, 1000))
end)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 140, 0, 38)
ToggleButton.AnchorPoint = Vector2.new(0, 1)
ToggleButton.Position = UDim2.new(0, 10, 1, -10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
ToggleButton.TextColor3 = theme.text
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui
local ToggleCorner = Instance.new("UICorner", ToggleButton)
ToggleCorner.CornerRadius = UDim.new(0, 10)

local guiVisible = true
ToggleButton.Text = "Hide Gui"

local originalPos = Frame.Position
local hiddenPos = UDim2.new(-0.8, -160, 0.5, -130)

local function setGuiVisible(visible)
    guiVisible = visible
    if visible then
        Frame.Visible = true
        Shadow.Visible = true
        Frame.Position = hiddenPos
        Shadow.Position = hiddenPos
        tween(Frame, {Position = originalPos}, 0.28, Enum.EasingStyle.Back):Play()
        tween(Shadow, {Position = originalPos}, 0.28, Enum.EasingStyle.Back):Play()
        ToggleButton.Text = "Hide Gui"
    else
        local t = tween(Frame, {Position = hiddenPos}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        local s = tween(Shadow, {Position = hiddenPos}, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        t:Play(); s:Play()
        t.Completed:Connect(function()
            Frame.Visible = false
            Shadow.Visible = false
        end)
        ToggleButton.Text = "Open Gui"
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    setGuiVisible(not guiVisible)
end)

Frame:GetPropertyChangedSignal("Position"):Connect(function()
    if Frame.Visible then
        TweenService:Create(Shadow, TweenInfo.new(0.06), {Position = Frame.Position}):Play()
    end
end)
Shadow.Position = Frame.Position

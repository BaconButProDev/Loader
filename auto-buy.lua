local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local BuyBlockRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShopEvents"):WaitForChild("BuyBlock")
local BuyToolRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShopEvents"):WaitForChild("BuyTool")

local blockItems = {
    "fuel_1", "block_1", "wing_1", "propeller_1",
    "seat_1", "block_reinforced", "fuel_2", "tail_1",
    "wing_2", "block_metal", "fuel_3", "propeller_2",
    "balloon", "boost_1", "missile_1", "shield",
    "tail_2", "propeller_4"
}
local toolItems = { "Paint" }

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "AutoBuyGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 100, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0.5, 100)
OpenButton.Text = "HIDE GUI"
OpenButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.TextScaled = true
OpenButton.Parent = ScreenGui
OpenButton.Active = true
OpenButton.Draggable = true

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 300)
Frame.Position = UDim2.new(0.5, -175, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Frame.BorderSizePixel = 0
Frame.Visible = true
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 15)

local UIStroke = Instance.new("UIStroke", Frame)
UIStroke.Color = Color3.fromRGB(70, 130, 255)
UIStroke.Thickness = 2

local UIGradient = Instance.new("UIGradient", Frame)
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
}
UIGradient.Rotation = 45

local DropShadow = Instance.new("Frame", Frame)
DropShadow.Name = "Shadow"
DropShadow.Size = UDim2.new(1, 10, 1, 10)
DropShadow.Position = UDim2.new(0, -5, 0, -5)
DropShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DropShadow.BackgroundTransparency = 0.7
DropShadow.ZIndex = Frame.ZIndex - 1
local ShadowCorner = Instance.new("UICorner", DropShadow)
ShadowCorner.CornerRadius = UDim.new(0, 15)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "✨ Auto Buy GUI ✨"
Title.Font = Enum.Font.SourceSansBold
Title.TextColor3 = Color3.fromRGB(70, 130, 255)
Title.TextSize = 25
Title.Parent = Frame

local TitleGradient = Instance.new("UIGradient", Title)
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 130, 255))
}

local MadeBy = Instance.new("TextLabel")
MadeBy.Size = UDim2.new(1, 0, 0, 25)
MadeBy.Position = UDim2.new(0, 0, 0, 40)
MadeBy.BackgroundTransparency = 1
MadeBy.Text = "🚀 Made By Bacon But Pro"
MadeBy.Font = Enum.Font.SourceSans
MadeBy.TextColor3 = Color3.fromRGB(180, 180, 180)
MadeBy.TextSize = 18
MadeBy.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 45)
ToggleButton.Position = UDim2.new(0.1, 0, 0.25, 0)
ToggleButton.Text = "🔥 Auto Buy: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 16
ToggleButton.Parent = Frame

local ToggleCorner = Instance.new("UICorner", ToggleButton)
ToggleCorner.CornerRadius = UDim.new(0, 12)

local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1
ToggleStroke.Transparency = 0.8

local PrefixLabel = Instance.new("TextLabel")
PrefixLabel.Size = UDim2.new(0.8, 0, 0, 25)
PrefixLabel.Position = UDim2.new(0.1, 0, 0.48, 0)
PrefixLabel.BackgroundTransparency = 1
PrefixLabel.Text = "⌨️ Set prefix key to hide/show GUI:"
PrefixLabel.Font = Enum.Font.SourceSans
PrefixLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PrefixLabel.TextSize = 16
PrefixLabel.Parent = Frame

local PrefixBox = Instance.new("TextBox")
PrefixBox.Size = UDim2.new(0.8, 0, 0, 40)
PrefixBox.Position = UDim2.new(0.1, 0, 0.58, 0)
PrefixBox.Text = "p"
PrefixBox.PlaceholderText = "Set Prefix Key"
PrefixBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PrefixBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PrefixBox.Font = Enum.Font.SourceSans
PrefixBox.TextSize = 14
PrefixBox.Parent = Frame

local PrefixCorner = Instance.new("UICorner", PrefixBox)
PrefixCorner.CornerRadius = UDim.new(0, 10)

local PrefixStroke = Instance.new("UIStroke", PrefixBox)
PrefixStroke.Color = Color3.fromRGB(100, 100, 100)
PrefixStroke.Thickness = 1

local DeleteButton = Instance.new("TextButton")
DeleteButton.Size = UDim2.new(0.8, 0, 0, 45)
DeleteButton.Position = UDim2.new(0.1, 0, 0.77, 0)
DeleteButton.Text = "🗑️ DELETE GUI"
DeleteButton.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteButton.Font = Enum.Font.SourceSansBold
DeleteButton.TextSize = 16
DeleteButton.Parent = Frame

local DeleteCorner = Instance.new("UICorner", DeleteButton)
DeleteCorner.CornerRadius = UDim.new(0, 12)

local DeleteStroke = Instance.new("UIStroke", DeleteButton)
DeleteStroke.Color = Color3.fromRGB(255, 100, 100)
DeleteStroke.Thickness = 1
DeleteStroke.Transparency = 0.5

local TweenService = game:GetService("TweenService")

local autoBuyEnabled = false
local prefixKey = Enum.KeyCode.P

Frame.Size = UDim2.new(0, 0, 0, 0)
Frame.BackgroundTransparency = 1

local function showGUIAnimated()
    Frame.Visible = true
    local sizeTween = TweenService:Create(Frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 350, 0, 300)
    })
    local transparencyTween = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    sizeTween:Play()
    transparencyTween:Play()
end

local function hideGUIAnimated()
    local sizeTween = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0)
    })
    local transparencyTween = TweenService:Create(Frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    sizeTween:Play()
    transparencyTween:Play()
    sizeTween.Completed:Connect(function()
        Frame.Visible = false
    end)
end

showGUIAnimated()

local autoBuyConnection
autoBuyConnection = task.spawn(function()
    while true do
        if autoBuyEnabled then
            for _, item in ipairs(blockItems) do
                BuyBlockRemote:FireServer(item)
            end
            for _, tool in ipairs(toolItems) do
                BuyToolRemote:FireServer(tool)
            end
        end
        task.wait(0.2)
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    autoBuyEnabled = not autoBuyEnabled
    local buttonTween
    if autoBuyEnabled then
        ToggleButton.Text = "⚡ Auto Buy: ON"
        buttonTween = TweenService:Create(ToggleButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        })
    else
        ToggleButton.Text = "🔥 Auto Buy: OFF"
        buttonTween = TweenService:Create(ToggleButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        })
    end
    buttonTween:Play()
end)

DeleteButton.MouseButton1Click:Connect(function()
    autoBuyEnabled = false
    if autoBuyConnection then
        task.cancel(autoBuyConnection)
    end
    ScreenGui:Destroy()
    script:Destroy()
end)

PrefixBox.FocusLost:Connect(function()
    local input = string.lower(PrefixBox.Text)
    if #input == 1 then
        local keyCode = Enum.KeyCode[string.upper(input)]
        if keyCode then
            prefixKey = keyCode
        end
    end
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == prefixKey then
        if Frame.Visible then
            hideGUIAnimated()
            OpenButton.Text = "SHOW GUI"
        else
            showGUIAnimated()
            OpenButton.Text = "HIDE GUI"
        end
    end
end)

OpenButton.MouseButton1Click:Connect(function()
    if Frame.Visible then
        hideGUIAnimated()
        OpenButton.Text = "SHOW GUI"
    else
        showGUIAnimated()
        OpenButton.Text = "HIDE GUI"
    end
end)

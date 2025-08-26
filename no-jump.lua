local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

if CoreGui:FindFirstChild("AutoWinGUI") then
    CoreGui.AutoWinGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoWinGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 65)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
}
UIGradient.Rotation = 45
UIGradient.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = MainFrame

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 10, 1, 10)
Shadow.Position = UDim2.new(0, -5, 0, -5)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.7
Shadow.ZIndex = MainFrame.ZIndex - 1
Shadow.Parent = MainFrame

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 20)
ShadowCorner.Parent = Shadow

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 15)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 15)
HeaderFix.Position = UDim2.new(0, 0, 1, -15)
HeaderFix.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🚀 Auto Win Pro"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

local AutoWinButton = Instance.new("TextButton")
AutoWinButton.Size = UDim2.new(0, 240, 0, 45)
AutoWinButton.Position = UDim2.new(0.5, -120, 0, 55)
AutoWinButton.Text = "🎯 Auto Win: OFF"
AutoWinButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
AutoWinButton.TextColor3 = Color3.new(1, 1, 1)
AutoWinButton.Font = Enum.Font.GothamBold
AutoWinButton.TextSize = 18
AutoWinButton.Parent = MainFrame

local AutoWinCorner = Instance.new("UICorner")
AutoWinCorner.CornerRadius = UDim.new(0, 10)
AutoWinCorner.Parent = AutoWinButton

local AutoWinGradient = Instance.new("UIGradient")
AutoWinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 80, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
}
AutoWinGradient.Rotation = 45
AutoWinGradient.Parent = AutoWinButton

local FastAutoWinButton = Instance.new("TextButton")
FastAutoWinButton.Size = UDim2.new(0, 240, 0, 45)
FastAutoWinButton.Position = UDim2.new(0.5, -120, 0, 110)
FastAutoWinButton.Text = "⚡ Fast Auto Win: OFF"
FastAutoWinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 220)
FastAutoWinButton.TextColor3 = Color3.new(1, 1, 1)
FastAutoWinButton.Font = Enum.Font.GothamBold
FastAutoWinButton.TextSize = 18
FastAutoWinButton.Parent = MainFrame

local FastAutoWinCorner = Instance.new("UICorner")
FastAutoWinCorner.CornerRadius = UDim.new(0, 10)
FastAutoWinCorner.Parent = FastAutoWinButton

local FastAutoWinGradient = Instance.new("UIGradient")
FastAutoWinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 240)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 200))
}
FastAutoWinGradient.Rotation = 45
FastAutoWinGradient.Parent = FastAutoWinButton

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, 0, 0, 25)
Credit.Position = UDim2.new(0, 0, 1, -25)
Credit.BackgroundTransparency = 1
Credit.Text = "Made By Bacon But Pro 🥓"
Credit.TextColor3 = Color3.fromRGB(150, 150, 170)
Credit.Font = Enum.Font.Gotham
Credit.TextSize = 14
Credit.Parent = MainFrame

local function createButtonAnimation(button)
    local originalSize = button.Size
    local hoverSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 5, originalSize.Y.Scale, originalSize.Y.Offset + 2)
    
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = hoverSize})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = originalSize})
        tween:Play()
    end)
end

createButtonAnimation(AutoWinButton)
createButtonAnimation(FastAutoWinButton)
createButtonAnimation(CloseButton)

local autoWinEnabled = false
local fastAutoWinEnabled = false

local function toggleAutoWin()
    autoWinEnabled = not autoWinEnabled
    fastAutoWinEnabled = false
    
    if autoWinEnabled then
        AutoWinButton.Text = "🎯 Auto Win: ON"
        AutoWinButton.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
        AutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 220, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 60))
        }
        FastAutoWinButton.Text = "⚡ Fast Auto Win: OFF"
        FastAutoWinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 220)
        FastAutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 200))
        }
    else
        AutoWinButton.Text = "🎯 Auto Win: OFF"
        AutoWinButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        AutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 80, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
        }
    end
end

local function toggleFastAutoWin()
    fastAutoWinEnabled = not fastAutoWinEnabled
    autoWinEnabled = false
    
    if fastAutoWinEnabled then
        FastAutoWinButton.Text = "⚡ Fast Auto Win: ON"
        FastAutoWinButton.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
        FastAutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 220, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 60))
        }
        AutoWinButton.Text = "🎯 Auto Win: OFF"
        AutoWinButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        AutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 80, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
        }
    else
        FastAutoWinButton.Text = "⚡ Fast Auto Win: OFF"
        FastAutoWinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 220)
        FastAutoWinGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 240)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 200))
        }
    end
end

AutoWinButton.MouseButton1Click:Connect(toggleAutoWin)
FastAutoWinButton.MouseButton1Click:Connect(toggleFastAutoWin)

CloseButton.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.05 + 0.14, 0, 0.2 + 0.1, 0)
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)

MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.05 + 0.14, 0, 0.2 + 0.1, 0)

local entranceTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 280, 0, 200),
    Position = UDim2.new(0.05, 0, 0.2, 0)
})
entranceTween:Play()

task.spawn(function()
    while ScreenGui.Parent do
        if (autoWinEnabled or fastAutoWinEnabled) and LocalPlayer.Character then
            pcall(function()
                local leaderstats = LocalPlayer:WaitForChild("leaderstats", 1)
                if leaderstats then
                    local stageValue = leaderstats:FindFirstChild("Stage")
                    if stageValue then
                        local stage = stageValue.Value
                        local checkpoints = workspace:FindFirstChild("Checkpoints")
                        
                        if checkpoints then
                            local nextStage = checkpoints:FindFirstChild(tostring(stage + 1))
                            
                            if nextStage and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = nextStage.CFrame + Vector3.new(0, 5, 0)
                            end
                        end
                    end
                end
            end)
        end
        
        if fastAutoWinEnabled then
            task.wait(0.00000003)
        elseif autoWinEnabled then
            task.wait(0.4)
        else
            task.wait(1)
        end
    end
end)

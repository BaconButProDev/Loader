local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BlobsTpGui"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
}
Gradient.Rotation = 45
Gradient.Parent = MainFrame

local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 6, 1, 6)
Shadow.Position = UDim2.new(0, -3, 0, -3)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.7
Shadow.ZIndex = MainFrame.ZIndex - 1
Shadow.Parent = MainFrame

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 12)
ShadowCorner.Parent = Shadow

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🎯 Blobs Teleporter"
Title.TextColor3 = Color3.fromRGB(100, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0.9, 0, 0, 3)
StatusFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 2)
StatusCorner.Parent = StatusFrame

local InputLabel = Instance.new("TextLabel")
InputLabel.Size = UDim2.new(0.9, 0, 0, 20)
InputLabel.Position = UDim2.new(0.05, 0, 0.32, 0)
InputLabel.BackgroundTransparency = 1
InputLabel.Text = "Minimum Blob Value:"
InputLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
InputLabel.Font = Enum.Font.Gotham
InputLabel.TextSize = 14
InputLabel.TextXAlignment = Enum.TextXAlignment.Left
InputLabel.Parent = MainFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0.9, 0, 0, 35)
InputBox.Position = UDim2.new(0.05, 0, 0.42, 0)
InputBox.PlaceholderText = "Enter minimum value (e.g: 20)"
InputBox.Text = ""
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
InputBox.BorderSizePixel = 0
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.9, 0, 0, 40)
ToggleButton.Position = UDim2.new(0.05, 0, 0.62, 0)
ToggleButton.Text = "🔴 OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
ToggleButton.BorderSizePixel = 0
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, 0, 0, 25)
Credit.Position = UDim2.new(0, 0, 0.85, 0)
Credit.BackgroundTransparency = 1
Credit.Text = "✨ Made By Bacon But Pro"
Credit.TextColor3 = Color3.fromRGB(255, 215, 0)
Credit.Font = Enum.Font.GothamSemibold
Credit.TextSize = 12
Credit.Parent = MainFrame

local isEnabled = false
local minValue = 20
local teleportCoroutine

local function animateButton(button, scale)
    local originalSize = button.Size
    local newSize = UDim2.new(originalSize.X.Scale * scale, originalSize.X.Offset * scale, 
                             originalSize.Y.Scale * scale, originalSize.Y.Offset * scale)
    local tween = TweenService:Create(button, TweenInfo.new(0.1), {Size = newSize})
    tween:Play()
    tween.Completed:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {Size = originalSize}):Play()
    end)
end

local function updateToggleButton()
    if isEnabled then
        ToggleButton.Text = "🟢 ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        StatusFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    else
        ToggleButton.Text = "🔴 OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        StatusFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function teleportBlobs()
    while isEnabled do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local blobsFolder = Workspace:FindFirstChild("Blobs")

            if blobsFolder then
                for _, blob in ipairs(blobsFolder:GetChildren()) do
                    if not isEnabled then break end
                    
                    if blob:IsA("BasePart") or blob:IsA("Model") then
                        local blobName = tonumber(blob.Name)
                        if blobName and blobName >= minValue and blobName ~= 50 and blobName ~= 60 then
                            local safe = true
                            local blobPosition = blob:IsA("Model") and blob:FindFirstChild("HumanoidRootPart") and blob.HumanoidRootPart.Position or blob.Position
                            
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                                    local dist = (plr.Character.HumanoidRootPart.Position - blobPosition).Magnitude
                                    if dist < 20 then
                                        safe = false
                                        break
                                    end
                                end
                            end

                            if safe then
                                local targetCFrame = blob:IsA("Model") and blob:FindFirstChild("HumanoidRootPart") and blob.HumanoidRootPart.CFrame or blob.CFrame
                                hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.3)
    end
end

local function startTeleporting()
    if teleportCoroutine then
        coroutine.close(teleportCoroutine)
    end
    teleportCoroutine = coroutine.create(teleportBlobs)
    coroutine.resume(teleportCoroutine)
end

ToggleButton.MouseButton1Click:Connect(function()
    animateButton(ToggleButton, 0.95)
    
    local inputVal = tonumber(InputBox.Text)
    if inputVal then
        minValue = inputVal
    end
    
    isEnabled = not isEnabled
    updateToggleButton()
    
    if isEnabled then
        startTeleporting()
    else
        if teleportCoroutine then
            coroutine.close(teleportCoroutine)
            teleportCoroutine = nil
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if isEnabled then
        startTeleporting()
    end
end)

InputBox.FocusLost:Connect(function()
    local val = tonumber(InputBox.Text)
    if not val or val < 1 then
        InputBox.Text = tostring(minValue)
    else
        minValue = val
    end
end)

ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
end)

ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

updateToggleButton()

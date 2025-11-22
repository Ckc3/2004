
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local SkyTextEnabled = false
local SkyTextGui = nil
local SkyTextLabel = nil
local RainbowConnection = nil


local SkyTextMessage = "©2004 runs you"


local function CreateSkyText()
    if SkyTextGui then
        SkyTextGui:Destroy()
    end
    

    SkyTextGui = Instance.new("BillboardGui")
    SkyTextGui.Name = "SkyText_" .. Player.Name
    SkyTextGui.Size = UDim2.new(0, 500, 0, 100)
    SkyTextGui.StudsOffset = Vector3.new(0, 8, 0) 
    SkyTextGui.AlwaysOnTop = true
    SkyTextGui.Adornee = HumanoidRootPart
    SkyTextGui.MaxDistance = 10000
    SkyTextGui.Parent = workspace 
    

    SkyTextLabel = Instance.new("TextLabel")
    SkyTextLabel.Name = "SkyTextLabel"
    SkyTextLabel.Size = UDim2.new(1, 0, 1, 0)
    SkyTextLabel.BackgroundTransparency = 1
    SkyTextLabel.Text = SkyTextMessage
    SkyTextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    SkyTextLabel.TextSize = 50
    SkyTextLabel.Font = Enum.Font.GothamBold
    SkyTextLabel.TextStrokeTransparency = 0.5
    SkyTextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    SkyTextLabel.TextScaled = false
    SkyTextLabel.Parent = SkyTextGui
    
    print("[Sky Text] Created with message: " .. SkyTextMessage)
end


local function StartRainbowEffect()
    if not SkyTextLabel then return end
    
    if RainbowConnection then
        RainbowConnection:Disconnect()
    end
    
    local hue = 0
    RainbowConnection = RunService.Heartbeat:Connect(function()
        if SkyTextLabel then
            hue = (hue + 0.5) % 360
            local color = Color3.fromHSV(hue / 360, 1, 1)
            SkyTextLabel.TextColor3 = color
        end
    end)
end


local function UpdateSkyText()
    if not SkyTextEnabled then return end
    if not Character or not HumanoidRootPart then return end
    
    if SkyTextGui then
        SkyTextGui.Adornee = HumanoidRootPart
    else
        CreateSkyText()
        StartRainbowEffect()
    end
end


local function EnableSkyText()
    if SkyTextEnabled then return end
    
    SkyTextEnabled = true
    print("[Sky Text] Enabled")
    
    CreateSkyText()
    StartRainbowEffect()
    

    RunService.Heartbeat:Connect(UpdateSkyText)
end


local function DisableSkyText()
    if not SkyTextEnabled then return end
    
    SkyTextEnabled = false
    print("[Sky Text] Disabled")
    
    if RainbowConnection then
        RainbowConnection:Disconnect()
        RainbowConnection = nil
    end
    
    if SkyTextGui then
        SkyTextGui:Destroy()
        SkyTextGui = nil
        SkyTextLabel = nil
    end
end


local function SetMessage(message)
    SkyTextMessage = message or "©2004 runs you"
    if SkyTextLabel then
        SkyTextLabel.Text = SkyTextMessage
    end
    print("[Sky Text] Message set to: " .. SkyTextMessage)
end


local function ToggleSkyText()
    if SkyTextEnabled then
        DisableSkyText()
    else
        EnableSkyText()
    end
end


Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if SkyTextEnabled then
        wait(1)
        CreateSkyText()
        StartRainbowEffect()
    end
end)


return {
    Enable = EnableSkyText,
    Disable = DisableSkyText,
    Toggle = ToggleSkyText,
    SetMessage = SetMessage,
    IsEnabled = function() return SkyTextEnabled end,
    GetMessage = function() return SkyTextMessage end
}


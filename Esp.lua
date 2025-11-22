

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPEnabled = false
local ESPObjects = {}


local function CreateESP(targetPlayer)
    if ESPObjects[targetPlayer] then return end
    
    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return end
    
    local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHumanoidRootPart then return end
    

    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Name = "ESP_" .. targetPlayer.Name
    BillboardGui.Size = UDim2.new(0, 200, 0, 50)
    BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
    BillboardGui.AlwaysOnTop = true
    BillboardGui.Adornee = targetHumanoidRootPart
    BillboardGui.Parent = targetHumanoidRootPart
    

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "NameLabel"
    NameLabel.Size = UDim2.new(1, 0, 1, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = targetPlayer.Name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 18
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextStrokeTransparency = 0.5
    NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    NameLabel.Parent = BillboardGui
    

    local Highlight = Instance.new("Highlight")
    Highlight.Name = "ESP_Highlight"
    Highlight.FillTransparency = 1
    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    Highlight.OutlineTransparency = 0
    Highlight.Adornee = targetCharacter
    Highlight.Parent = targetCharacter
    
    ESPObjects[targetPlayer] = {
        BillboardGui = BillboardGui,
        Highlight = Highlight,
        Character = targetCharacter
    }
end


local function RemoveESP(targetPlayer)
    if ESPObjects[targetPlayer] then
        if ESPObjects[targetPlayer].BillboardGui then
            ESPObjects[targetPlayer].BillboardGui:Destroy()
        end
        if ESPObjects[targetPlayer].Highlight then
            ESPObjects[targetPlayer].Highlight:Destroy()
        end
        ESPObjects[targetPlayer] = nil
    end
end


local function UpdateESP()
    if not ESPEnabled then return end
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player then
            if otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if not ESPObjects[otherPlayer] then
                    CreateESP(otherPlayer)
                else
                    -- Update if character changed
                    if ESPObjects[otherPlayer].Character ~= otherPlayer.Character then
                        RemoveESP(otherPlayer)
                        CreateESP(otherPlayer)
                    end
                end
            else
                RemoveESP(otherPlayer)
            end
        end
    end
end


local function EnableESP()
    if ESPEnabled then return end
    
    ESPEnabled = true
    print("[ESP] Enabled")
    

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            CreateESP(otherPlayer)
        end
    end
    

    Players.PlayerAdded:Connect(function(newPlayer)
        if ESPEnabled and newPlayer.Character then
            CreateESP(newPlayer)
        end
    end)
    

    RunService.Heartbeat:Connect(UpdateESP)
end


local function DisableESP()
    if not ESPEnabled then return end
    
    ESPEnabled = false
    print("[ESP] Disabled")
    

    for targetPlayer, _ in pairs(ESPObjects) do
        RemoveESP(targetPlayer)
    end
end


local function ToggleESP()
    if ESPEnabled then
        DisableESP()
    else
        EnableESP()
    end
end


Players.PlayerRemoving:Connect(function(removedPlayer)
    RemoveESP(removedPlayer)
end)


return {
    Enable = EnableESP,
    Disable = DisableESP,
    Toggle = ToggleESP,
    IsEnabled = function() return ESPEnabled end
}


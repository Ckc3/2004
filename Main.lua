

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")

-- Player
local Player = Players.LocalPlayer

-- Colors
local PRIMARY_COLOR = Color3.fromRGB(15, 15, 25)
local ACCENT_COLOR = Color3.fromRGB(255, 255, 255)

-- Create ScreenGui (in CoreGui so it works in pause menu)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FoggyGlassGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999 -- High priority to show over pause menu
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Load modules
local LockOn = nil
local ESP = nil

-- Lock On System (Embedded)
local RunService = game:GetService("RunService")
local LockOnTarget = nil
local LockOnEnabled = false
local LockOnConnection = nil

local function FindTargetInView()
    local Character = Player.Character
    if not Character then return nil end
    local Camera = workspace.CurrentCamera
    if not Camera then return nil end
    
    local cameraCFrame = Camera.CFrame
    local cameraLookVector = cameraCFrame.LookVector
    local cameraPosition = cameraCFrame.Position
    
    local closestPlayer = nil
    local closestDistance = math.huge
    local maxAngle = math.rad(25)
    local maxDistance = 300
    
    if LockOnTarget and LockOnTarget.Character then
        local targetCharacter = LockOnTarget.Character
        local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
        local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
        
        if targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
            local targetHead = targetCharacter:FindFirstChild("Head")
            local targetPosition = targetHead and targetHead.Position or targetRootPart.Position
            targetPosition = targetPosition + Vector3.new(0, -0.3, 0)
            
            local directionToTarget = (targetPosition - cameraPosition)
            local distance = directionToTarget.Magnitude
            
            if distance <= maxDistance then
                directionToTarget = directionToTarget.Unit
                local dotProduct = cameraLookVector:Dot(directionToTarget)
                local angle = math.acos(math.clamp(dotProduct, -1, 1))
                
                if angle <= maxAngle then
                    return LockOnTarget
                else
                    LockOnTarget = nil
                end
            else
                LockOnTarget = nil
            end
        else
            LockOnTarget = nil
        end
    end
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= Player and otherPlayer.Character then
            local targetCharacter = otherPlayer.Character
            local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
            local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            
            if targetHumanoid and targetRootPart and targetHumanoid.Health > 0 then
                local targetHead = targetCharacter:FindFirstChild("Head")
                local targetPosition = targetHead and targetHead.Position or targetRootPart.Position
                targetPosition = targetPosition + Vector3.new(0, -0.3, 0)
                
                local directionToTarget = (targetPosition - cameraPosition)
                local distance = directionToTarget.Magnitude
                
                if distance <= maxDistance then
                    directionToTarget = directionToTarget.Unit
                    local dotProduct = cameraLookVector:Dot(directionToTarget)
                    local angle = math.acos(math.clamp(dotProduct, -1, 1))
                    
                    if angle <= maxAngle then
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = otherPlayer
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function UpdateLockOn()
    if not LockOnEnabled then return end
    
    local success, err = pcall(function()
        local Camera = workspace.CurrentCamera
        if not Camera then return end
        
        local currentTarget = FindTargetInView()
        
        if currentTarget and currentTarget.Character then
            local targetCharacter = currentTarget.Character
            local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
            
            if targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
                LockOnTarget = currentTarget
                
                local targetHead = targetCharacter:FindFirstChild("Head")
                local targetPosition = targetHead and targetHead.Position or targetRootPart.Position
                targetPosition = targetPosition + Vector3.new(0, -0.3, 0)
                
                local cameraPosition = Camera.CFrame.Position
                local direction = (targetPosition - cameraPosition)
                local distance = direction.Magnitude
                
                if distance > 0.1 then
                    direction = direction.Unit
                    local currentCFrame = Camera.CFrame
                    local targetCFrame = CFrame.lookAt(cameraPosition, cameraPosition + direction)
                    local smoothness = 0.3
                    local newCFrame = currentCFrame:Lerp(targetCFrame, smoothness)
                    Camera.CFrame = newCFrame
                    
                    local Character = Player.Character
                    if Character then
                        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                        if HumanoidRootPart then
                            local characterPosition = HumanoidRootPart.Position
                            local bodyDirection = (targetPosition - characterPosition)
                            bodyDirection = Vector3.new(bodyDirection.X, 0, bodyDirection.Z).Unit
                            
                            if bodyDirection.Magnitude > 0.1 then
                                local bodyCFrame = CFrame.lookAt(characterPosition, characterPosition + bodyDirection)
                                local currentBodyCFrame = HumanoidRootPart.CFrame
                                local newBodyCFrame = currentBodyCFrame:Lerp(bodyCFrame, 0.2)
                                HumanoidRootPart.CFrame = CFrame.new(newBodyCFrame.Position, newBodyCFrame.Position + newBodyCFrame.LookVector)
                            end
                        end
                    end
                end
            else
                LockOnTarget = nil
            end
        else
            LockOnTarget = nil
        end
    end)
    
    if not success then
        warn("[Lock On] Update error: " .. tostring(err))
    end
end

local function ToggleLockOn()
    print("[Lock On] Toggle called, current state: " .. tostring(LockOnEnabled))
    if LockOnEnabled then
        LockOnEnabled = false
        LockOnTarget = nil
        if LockOnConnection then
            LockOnConnection:Disconnect()
            LockOnConnection = nil
        end
        print("[Lock On] Disabled")
    else
        LockOnEnabled = true
        if LockOnConnection then
            LockOnConnection:Disconnect()
            LockOnConnection = nil
        end
        print("[Lock On] Enabling...")
        LockOnConnection = RunService.Heartbeat:Connect(UpdateLockOn)
        print("[Lock On] Enabled - Connection created. Look at a player to lock on to their head")
        print("[Lock On] Connection active: " .. tostring(LockOnConnection and "YES" or "NO"))
    end
end

local function LoadLockOn()
    return {
        Toggle = ToggleLockOn,
        IsEnabled = function() return LockOnEnabled end,
        GetTarget = function() return LockOnTarget end
    }
end

-- Load ESP from GitHub
local function LoadESP()
    if not ESP then
        local success, result = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Ckc3/2004/refs/heads/main/Esp.lua"))()
        end)
        if success and result then
            ESP = result
            print("[ESP] Loaded from GitHub")
        else
            warn("Failed to load ESP from GitHub")
        end
    end
    return ESP
end

-- Main Container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 700, 0, 550)
MainFrame.Position = UDim2.new(0, 50, 0, 50)
MainFrame.BackgroundColor3 = PRIMARY_COLOR
MainFrame.BackgroundTransparency = 0.85 -- More foggy
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 24)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = ACCENT_COLOR
MainStroke.Transparency = 0.9 -- More foggy
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 100)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = ACCENT_COLOR
TopBar.BackgroundTransparency = 0.95 -- More foggy
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 24)
TopBarCorner.Parent = TopBar

-- Avatar
local AvatarFrame = Instance.new("ImageLabel")
AvatarFrame.Name = "AvatarFrame"
AvatarFrame.Size = UDim2.new(0, 70, 0, 70)
AvatarFrame.Position = UDim2.new(0, 15, 0, 15)
AvatarFrame.BackgroundColor3 = PRIMARY_COLOR
AvatarFrame.BackgroundTransparency = 0.8
AvatarFrame.BorderSizePixel = 0
AvatarFrame.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=150&height=150&format=png"
AvatarFrame.Parent = TopBar

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 12)
AvatarCorner.Parent = AvatarFrame

-- Player Name
local PlayerNameLabel = Instance.new("TextLabel")
PlayerNameLabel.Name = "PlayerName"
PlayerNameLabel.Size = UDim2.new(0, 300, 0, 25)
PlayerNameLabel.Position = UDim2.new(0, 100, 0, 20)
PlayerNameLabel.BackgroundTransparency = 1
PlayerNameLabel.Text = Player.Name
PlayerNameLabel.TextColor3 = ACCENT_COLOR
PlayerNameLabel.TextTransparency = 0.1
PlayerNameLabel.TextSize = 20
PlayerNameLabel.Font = Enum.Font.GothamBold
PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerNameLabel.Parent = TopBar

-- Game Name
local GameNameLabel = Instance.new("TextLabel")
GameNameLabel.Name = "GameName"
GameNameLabel.Size = UDim2.new(0, 300, 0, 20)
GameNameLabel.Position = UDim2.new(0, 100, 0, 45)
GameNameLabel.BackgroundTransparency = 1
GameNameLabel.Text = "Loading..."
GameNameLabel.TextColor3 = ACCENT_COLOR
GameNameLabel.TextTransparency = 0.3
GameNameLabel.TextSize = 16
GameNameLabel.Font = Enum.Font.Gotham
GameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
GameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
GameNameLabel.Parent = TopBar

-- Fetch Game Name
spawn(function()
    local success, gameInfo = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and gameInfo then
        GameNameLabel.Text = gameInfo.Name
    else
        GameNameLabel.Text = "Roblox Game"
    end
end)

-- Player ID
local PlayerIDLabel = Instance.new("TextLabel")
PlayerIDLabel.Name = "PlayerID"
PlayerIDLabel.Size = UDim2.new(0, 300, 0, 18)
PlayerIDLabel.Position = UDim2.new(0, 100, 0, 68)
PlayerIDLabel.BackgroundTransparency = 1
PlayerIDLabel.Text = "ID: " .. Player.UserId
PlayerIDLabel.TextColor3 = ACCENT_COLOR
PlayerIDLabel.TextTransparency = 0.4
PlayerIDLabel.TextSize = 14
PlayerIDLabel.Font = Enum.Font.Gotham
PlayerIDLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerIDLabel.Parent = TopBar

-- CLOSE BUTTON
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 40)
CloseButton.Position = UDim2.new(1, -50, 0, 10)
CloseButton.BackgroundColor3 = ACCENT_COLOR
CloseButton.BackgroundTransparency = 0.85
CloseButton.BorderSizePixel = 0
CloseButton.Text = "×"
CloseButton.TextColor3 = ACCENT_COLOR
CloseButton.TextTransparency = 0.1
CloseButton.TextSize = 32
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseButton

-- SIDEBAR (LEFT - CATEGORIES)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 180, 1, -100)
Sidebar.Position = UDim2.new(0, 0, 0, 100)
Sidebar.BackgroundColor3 = ACCENT_COLOR
Sidebar.BackgroundTransparency = 0.96 -- More foggy
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 10)
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 15)
SidebarPadding.PaddingLeft = UDim.new(0, 15)
SidebarPadding.PaddingRight = UDim.new(0, 15)
SidebarPadding.Parent = Sidebar

-- CONTENT AREA (RIGHT - BUTTONS)
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -180, 1, -100)
ContentArea.Position = UDim2.new(0, 180, 0, 100)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Categories Data
local Categories = {
    {
        Name = "Combat",
        Buttons = {
            {Name = "Lock On", Icon = "◉", Script = "lockon"},
            {Name = "ESP", Icon = "◯", Script = "esp"},
            {Name = "Aimbot", Icon = "◐"}
        }
    },
    {
        Name = "Movement",
        Buttons = {
            {Name = "Speed", Icon = "▶"},
            {Name = "Fly", Icon = "▲"},
            {Name = "NoClip", Icon = "◐"}
        }
    },
    {
        Name = "Utility",
        Buttons = {
            {Name = "Teleport", Icon = "●"},
            {Name = "Infinite Jump", Icon = "◈"},
            {Name = "Auto Farm", Icon = "◊"}
        }
    },
    {
        Name = "Visual",
        Buttons = {
            {Name = "Fullbright", Icon = "◉"},
            {Name = "FOV Changer", Icon = "◯"},
            {Name = "Camera Zoom", Icon = "◐"}
        }
    }
}


local CategoryButtons = {}
local ActiveCategory = 1

for i, category in ipairs(Categories) do
    local CategoryButton = Instance.new("TextButton")
    CategoryButton.Name = category.Name .. "Button"
    CategoryButton.Size = UDim2.new(1, 0, 0, 50)
    CategoryButton.BackgroundColor3 = ACCENT_COLOR
    CategoryButton.BackgroundTransparency = i == 1 and 0.90 or 0.96
    CategoryButton.BorderSizePixel = 0
    CategoryButton.Text = category.Name
    CategoryButton.TextColor3 = ACCENT_COLOR
    CategoryButton.TextTransparency = i == 1 and 0.15 or 0.4
    CategoryButton.TextSize = 17
    CategoryButton.Font = Enum.Font.GothamSemibold
    CategoryButton.LayoutOrder = i
    CategoryButton.Parent = Sidebar
    
    local CategoryButtonCorner = Instance.new("UICorner")
    CategoryButtonCorner.CornerRadius = UDim.new(0, 12)
    CategoryButtonCorner.Parent = CategoryButton
    
    local CategoryButtonStroke = Instance.new("UIStroke")
    CategoryButtonStroke.Color = ACCENT_COLOR
    CategoryButtonStroke.Transparency = i == 1 and 0.8 or 0.92
    CategoryButtonStroke.Thickness = 1
    CategoryButtonStroke.Parent = CategoryButton
    
    CategoryButton.MouseEnter:Connect(function()
        if ActiveCategory ~= i then
            TweenService:Create(CategoryButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.92, TextTransparency = 0.25}):Play()
            TweenService:Create(CategoryButtonStroke, TweenInfo.new(0.2), {Transparency = 0.85}):Play()
        end
    end)
    
    CategoryButton.MouseLeave:Connect(function()
        if ActiveCategory ~= i then
            TweenService:Create(CategoryButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.96, TextTransparency = 0.4}):Play()
            TweenService:Create(CategoryButtonStroke, TweenInfo.new(0.2), {Transparency = 0.92}):Play()
        end
    end)
    
    CategoryButtons[i] = CategoryButton
end


local ContentFrames = {}

for i, category in ipairs(Categories) do
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = category.Name .. "Content"
    ContentFrame.Size = UDim2.new(1, -20, 1, -20)
    ContentFrame.Position = UDim2.new(0, 10, 0, 10)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 5
    ContentFrame.ScrollBarImageColor3 = ACCENT_COLOR
    ContentFrame.ScrollBarImageTransparency = 0.7
    ContentFrame.Visible = i == 1
    ContentFrame.Parent = ContentArea
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 15)
    ContentLayout.Parent = ContentFrame
    
    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = ContentFrame
    

    for j, buttonData in ipairs(category.Buttons) do
        local FeatureButton = Instance.new("TextButton")
        FeatureButton.Name = buttonData.Name .. "Button"
        FeatureButton.Size = UDim2.new(1, 0, 0, 60)
        FeatureButton.BackgroundColor3 = ACCENT_COLOR
        FeatureButton.BackgroundTransparency = 0.92 -- More foggy
        FeatureButton.BorderSizePixel = 0
        FeatureButton.Text = buttonData.Icon .. "  " .. buttonData.Name
        FeatureButton.TextColor3 = ACCENT_COLOR
        FeatureButton.TextTransparency = 0.2
        FeatureButton.TextSize = 19
        FeatureButton.Font = Enum.Font.GothamSemibold
        FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
        FeatureButton.LayoutOrder = j
        FeatureButton.Parent = ContentFrame
        
        local FeatureButtonCorner = Instance.new("UICorner")
        FeatureButtonCorner.CornerRadius = UDim.new(0, 14)
        FeatureButtonCorner.Parent = FeatureButton
        
        local FeatureButtonStroke = Instance.new("UIStroke")
        FeatureButtonStroke.Color = ACCENT_COLOR
        FeatureButtonStroke.Transparency = 0.92
        FeatureButtonStroke.Thickness = 1
        FeatureButtonStroke.Parent = FeatureButton
        
        local FeatureButtonPadding = Instance.new("UIPadding")
        FeatureButtonPadding.PaddingLeft = UDim.new(0, 25)
        FeatureButtonPadding.Parent = FeatureButton
        

        FeatureButton.MouseEnter:Connect(function()
            TweenService:Create(FeatureButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.88, TextTransparency = 0.1}):Play()
            TweenService:Create(FeatureButtonStroke, TweenInfo.new(0.2), {Transparency = 0.88}):Play()
        end)
        
        FeatureButton.MouseLeave:Connect(function()
            TweenService:Create(FeatureButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.92, TextTransparency = 0.2}):Play()
            TweenService:Create(FeatureButtonStroke, TweenInfo.new(0.2), {Transparency = 0.92}):Play()
        end)
        

        local function UpdateButtonStatus()
            if buttonData.Script == "lockon" then
                local lockOnModule = LoadLockOn()
                if lockOnModule then
                    if lockOnModule.IsEnabled() then
                        FeatureButton.Text = "◉  Lock On [ON]"
                    else
                        FeatureButton.Text = "◉  Lock On [OFF]"
                    end
                end
            elseif buttonData.Script == "esp" then
                local espModule = LoadESP()
                if espModule then
                    if espModule.IsEnabled() then
                        FeatureButton.Text = "◯  ESP [ON]"
                    else
                        FeatureButton.Text = "◯  ESP [OFF]"
                    end
                end
            end
        end
        

        spawn(function()
            wait(0.1)
            UpdateButtonStatus()
        end)
        

        FeatureButton.MouseButton1Click:Connect(function()
            print("[" .. category.Name .. "] " .. buttonData.Name .. " activated!")
            

            if buttonData.Script == "lockon" then
                local lockOnModule = LoadLockOn()
                if lockOnModule then
                    lockOnModule.Toggle()
                    spawn(function()
                        wait(0.05)
                        UpdateButtonStatus()
                    end)
                end
            end
            

            if buttonData.Script == "esp" then
                local espModule = LoadESP()
                if espModule then
                    espModule.Toggle()
                    spawn(function()
                        wait(0.05)
                        UpdateButtonStatus()
                    end)
                end
            end
            
        end)
    end
    
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    ContentFrames[i] = ContentFrame
end


for i, button in ipairs(CategoryButtons) do
    button.MouseButton1Click:Connect(function()
        if ActiveCategory ~= i then
            ContentFrames[ActiveCategory].Visible = false
            
            TweenService:Create(CategoryButtons[ActiveCategory], TweenInfo.new(0.2), {BackgroundTransparency = 0.96, TextTransparency = 0.4}):Play()
            local oldStroke = CategoryButtons[ActiveCategory]:FindFirstChild("UIStroke")
            if oldStroke then
                TweenService:Create(oldStroke, TweenInfo.new(0.2), {Transparency = 0.92}):Play()
            end
            
            ActiveCategory = i
            ContentFrames[ActiveCategory].Visible = true
            
            TweenService:Create(CategoryButtons[ActiveCategory], TweenInfo.new(0.2), {BackgroundTransparency = 0.90, TextTransparency = 0.15}):Play()
            local newStroke = CategoryButtons[ActiveCategory]:FindFirstChild("UIStroke")
            if newStroke then
                TweenService:Create(newStroke, TweenInfo.new(0.2), {Transparency = 0.8}):Play()
            end
        end
    end)
end


CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.8, TextTransparency = 0}):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.85, TextTransparency = 0.1}):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)


local Dragging = false
local DragStart = nil
local StartPos = nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local closePos = CloseButton.AbsolutePosition
        local closeSize = CloseButton.AbsoluteSize
        

        if mousePos.X >= closePos.X and mousePos.X <= closePos.X + closeSize.X and mousePos.Y >= closePos.Y and mousePos.Y <= closePos.Y + closeSize.Y then
            return
        end
        
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
                if connection then connection:Disconnect() end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and Dragging then
        local Delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + Delta.Y
        )
    end
end)

print("GUI Loaded Successfully!")

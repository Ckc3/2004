
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LockOnTarget = nil
local LockOnEnabled = false
local LockOnConnection = nil


local function FindTargetInView()
    local Character = Player.Character
    if not Character then return nil end
    
    if not Camera then return nil end
    
    local cameraCFrame = Camera.CFrame
    local cameraLookVector = cameraCFrame.LookVector
    local cameraPosition = cameraCFrame.Position
    
    local closestPlayer = nil
    local closestDistance = math.huge
    local maxAngle = math.rad(20) -
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
end


local function EnableLockOn()
    if LockOnEnabled then return end
    
    LockOnEnabled = true
    print("[Lock On] Enabled - Look at a player to lock on to their head")
    

    if LockOnConnection then
        LockOnConnection:Disconnect()
    end
    
    LockOnConnection = RunService.Heartbeat:Connect(UpdateLockOn)
end


local function DisableLockOn()
    if not LockOnEnabled then return end
    
    LockOnEnabled = false
    LockOnTarget = nil
    print("[Lock On] Disabled")
    
    if LockOnConnection then
        LockOnConnection:Disconnect()
        LockOnConnection = nil
    end
end


local function ToggleLockOn()
    if LockOnEnabled then
        DisableLockOn()
    else
        EnableLockOn()
    end
end


Player.CharacterAdded:Connect(function(newCharacter)
    if LockOnEnabled then
        -- Restart lock on after respawn
        DisableLockOn()
        EnableLockOn()
    end
end)


return {
    Enable = EnableLockOn,
    Disable = DisableLockOn,
    Toggle = ToggleLockOn,
    IsEnabled = function() return LockOnEnabled end,
    GetTarget = function() return LockOnTarget end
}

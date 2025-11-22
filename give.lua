

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterGear = game:GetService("StarterGear")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Backpack = Player:FindFirstChild("Backpack")

local ItemsGiven = {}
local ItemsCount = 0

print("[Give Items] Starting item collection...")


local function GiveTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    

  if ItemsGiven[tool.Name] then return false end
    
    local success, result = pcall(function()
        local toolClone = tool:Clone()
        

      if Backpack then
            toolClone.Parent = Backpack
            ItemsGiven[tool.Name] = true
            ItemsCount = ItemsCount + 1
            print("[Give Items] Added tool to Backpack: " .. tool.Name)
            return true
        end
        

      if Character then
            toolClone.Parent = Character
            ItemsGiven[tool.Name] = true
            ItemsCount = ItemsCount + 1
            print("[Give Items] Added tool to Character: " .. tool.Name)
            return true
        end
        

      toolClone.Parent = StarterGear
        ItemsGiven[tool.Name] = true
        ItemsCount = ItemsCount + 1
        print("[Give Items] Added tool to StarterGear: " .. tool.Name)
        return true
    end)
    
    if not success then
        warn("[Give Items] Failed to give tool: " .. tool.Name .. " - " .. tostring(result))
    end
    
    return success
end


local function TryRemoteEventGive(itemName)
    local remotes = {
        ReplicatedStorage:FindFirstChild("GiveItem"),
        ReplicatedStorage:FindFirstChild("GetItem"),
        ReplicatedStorage:FindFirstChild("PurchaseItem"),
        ReplicatedStorage:FindFirstChild("EquipItem"),
        ReplicatedStorage:FindFirstChild("AddItem"),
        ReplicatedStorage:FindFirstChild("BuyItem"),
        ReplicatedStorage:FindFirstChild("GiveTool"),
        ReplicatedStorage:FindFirstChild("GetTool"),
    }
    
    for _, remote in ipairs(remotes) do
        if remote and remote:IsA("RemoteEvent") then
            local success = pcall(function()
                remote:FireServer(itemName)
                print("[Give Items] Fired RemoteEvent: " .. remote.Name .. " with " .. itemName)
            end)
            if success then
                return true
            end
        end
    end
    
    return false
end


local function SearchForTools()
    local locations = {
        ReplicatedStorage,
        ServerStorage,
        workspace,
        game,
    }
    
    local toolFolders = {
        "Tools",
        "Weapons",
        "Items",
        "Guns",
        "Swords",
        "Equipment",
        "Gear",
        "Shop",
        "Store",
    }
    
    for _, location in ipairs(locations) do

    for _, tool in ipairs(location:GetDescendants()) do
            if tool:IsA("Tool") then
                GiveTool(tool)
            end
        end
        

    for _, folderName in ipairs(toolFolders) do
            local folder = location:FindFirstChild(folderName)
            if folder then
                for _, tool in ipairs(folder:GetDescendants()) do
                    if tool:IsA("Tool") then
                        GiveTool(tool)
                    end
                end
            end
        end
    end
end


local function SearchForItemModules()
    local locations = {
        ReplicatedStorage,
        ServerStorage,
    }
    
    local moduleFolders = {
        "Items",
        "Tools",
        "Weapons",
        "Modules",
        "Data",
        "Shop",
    }
    
    for _, location in ipairs(locations) do
        for _, folderName in ipairs(moduleFolders) do
            local folder = location:FindFirstChild(folderName)
            if folder then
                for _, module in ipairs(folder:GetChildren()) do
                    if module:IsA("ModuleScript") then
                        local success, result = pcall(function()
                            local moduleData = require(module)
                            if type(moduleData) == "table" then

                  local itemName = moduleData.Name or moduleData.ItemName or module.Name
                                if itemName then
                                    TryRemoteEventGive(itemName)
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end


local function TryRemoteFunctionGive()
    local remoteFunctions = {
        ReplicatedStorage:FindFirstChild("GiveItem"),
        ReplicatedStorage:FindFirstChild("GetItem"),
        ReplicatedStorage:FindFirstChild("PurchaseItem"),
    }
    
    for _, remoteFunc in ipairs(remoteFunctions) do
        if remoteFunc and remoteFunc:IsA("RemoteFunction") then

      local commonItems = {"Sword", "Gun", "Tool", "Weapon", "Item"}
            for _, itemName in ipairs(commonItems) do
                pcall(function()
                    remoteFunc:InvokeServer(itemName)
                end)
            end
        end
    end
end


local function SearchStarterItems()
    for _, tool in ipairs(StarterGear:GetChildren()) do
        if tool:IsA("Tool") then
            GiveTool(tool)
        end
    end
    
    local starterPack = StarterPlayer:FindFirstChild("StarterPack")
    if starterPack then
        for _, tool in ipairs(starterPack:GetChildren()) do
            if tool:IsA("Tool") then
                GiveTool(tool)
            end
        end
    end
end


local function GiveAllItems()
    print("[Give Items] Searching for items...")
    

  SearchForTools()
    

  SearchStarterItems()
    

  SearchForItemModules()
    TryRemoteFunctionGive()
    

  wait(1)
    SearchForTools()
    
    print("[Give Items] Complete! Gave " .. ItemsCount .. " items.")
    

  if ItemsCount > 0 then
        print("[Give Items] Items given:")
        for itemName, _ in pairs(ItemsGiven) do
            print("  - " .. itemName)
        end
    else
        warn("[Give Items] No items found. This game might use a custom item system.")
        print("[Give Items] Try checking the game's shop or inventory system manually.")
    end
end


Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Backpack = Player:FindFirstChild("Backpack")
    

    if ItemsCount > 0 then
        wait(1)
        for itemName, _ in pairs(ItemsGiven) do

        local found = false
            for _, location in ipairs({ReplicatedStorage, ServerStorage, workspace}) do
                local tool = location:FindFirstChild(itemName, true)
                if tool and tool:IsA("Tool") then
                    GiveTool(tool)
                    found = true
                    break
                end
            end
        end
    end
end)


local module = {
    GiveAll = GiveAllItems,
    GiveTool = GiveTool,
    GetItemsGiven = function() return ItemsGiven end,
    GetItemsCount = function() return ItemsCount end
}


spawn(function()
    wait(0.5) 
    GiveAllItems()
end)

return module


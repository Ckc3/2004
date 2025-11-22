

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local TargetAmount = 500000
local MoneyEnabled = false
local CurrencyConnections = {}
local PersistenceConnection = nil

print("[Money] Starting money hack...")

local function SetMoney(amount)
    local success = false
    

  local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local currencyNames = {"Coins", "Money", "Cash", "Gold", "Gems", "Diamonds", "Robux", "Points", "Currency", "Bucks", "Dollars"}
        
        for _, currencyName in ipairs(currencyNames) do
            local currency = leaderstats:FindFirstChild(currencyName)
            if currency then
                if currency:IsA("IntValue") or currency:IsA("NumberValue") or currency:IsA("StringValue") then
                    currency.Value = amount
                    print("[Money] Set " .. currencyName .. " to " .. amount)
                    success = true
                elseif currency:IsA("Folder") then
                    local value = currency:FindFirstChild("Value")
                    if value then
                        value.Value = amount
                        print("[Money] Set " .. currencyName .. " to " .. amount)
                        success = true
                    end
                end
            end
        end
    end
    

  if not success then
        local currencyNames = {"Coins", "Money", "Cash", "Gold", "Gems", "Diamonds", "Points", "Currency"}
        for _, currencyName in ipairs(currencyNames) do
            local currency = Player:FindFirstChild(currencyName)
            if currency and (currency:IsA("IntValue") or currency:IsA("NumberValue")) then
                currency.Value = amount
                print("[Money] Set " .. currencyName .. " to " .. amount)
                success = true
            end
        end
    end
    

  if not success then
        local remotes = {}
        

    local remoteNames = {
            "UpdateMoney", "SetMoney", "AddMoney", "GiveMoney", "ChangeMoney",
            "UpdateCoins", "SetCoins", "AddCoins", "GiveCoins", "ChangeCoins",
            "UpdateCash", "SetCash", "AddCash", "GiveCash",
            "UpdateGold", "SetGold", "AddGold", "GiveGold",
            "UpdateCurrency", "SetCurrency", "AddCurrency"
        }
        

    for _, remoteName in ipairs(remoteNames) do
            local remote = ReplicatedStorage:FindFirstChild(remoteName)
            if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                table.insert(remotes, remote)
            end
        end
        

    for _, remoteName in ipairs(remoteNames) do
            local remote = Workspace:FindFirstChild(remoteName, true)
            if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                table.insert(remotes, remote)
            end
        end
        

    for _, remote in ipairs(remotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(amount)
                    print("[Money] Fired RemoteEvent: " .. remote.Name)
                    success = true
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(amount)
                    print("[Money] Invoked RemoteFunction: " .. remote.Name)
                    success = true
                end
            end)
        end
    end
    

  if not success then
        pcall(function()
            if _G and _G.PlayerData then
                if _G.PlayerData.Money then
                    _G.PlayerData.Money = amount
                    success = true
                elseif _G.PlayerData.Coins then
                    _G.PlayerData.Coins = amount
                    success = true
                end
            end
        end)
    end
    

  if not success then
        local modules = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("ModuleScript") then
                local name = obj.Name:lower()
                if name:find("money") or name:find("coin") or name:find("currency") or name:find("cash") or name:find("gold") then
                    table.insert(modules, obj)
                end
            end
        end
        
        for _, module in ipairs(modules) do
            pcall(function()
                local moduleTable = require(module)
                if moduleTable and type(moduleTable) == "table" then
                    if moduleTable.SetMoney then
                        moduleTable.SetMoney(Player, amount)
                        success = true
                    elseif moduleTable.AddMoney then
                        moduleTable.AddMoney(Player, amount)
                        success = true
                    elseif moduleTable.Money then
                        moduleTable.Money = amount
                        success = true
                    end
                end
            end)
        end
    end
    
    return success
end


local function FindCurrencyObjects()
    local currencies = {}
    

  local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        local currencyNames = {"Coins", "Money", "Cash", "Gold", "Gems", "Diamonds", "Robux", "Points", "Currency", "Bucks", "Dollars"}
        for _, currencyName in ipairs(currencyNames) do
            local currency = leaderstats:FindFirstChild(currencyName)
            if currency then
                if currency:IsA("IntValue") or currency:IsA("NumberValue") or currency:IsA("StringValue") then
                    table.insert(currencies, currency)
                elseif currency:IsA("Folder") then
                    local value = currency:FindFirstChild("Value")
                    if value then
                        table.insert(currencies, value)
                    end
                end
            end
        end
    end
    

  local currencyNames = {"Coins", "Money", "Cash", "Gold", "Gems", "Diamonds", "Points", "Currency"}
    for _, currencyName in ipairs(currencyNames) do
        local currency = Player:FindFirstChild(currencyName)
        if currency and (currency:IsA("IntValue") or currency:IsA("NumberValue")) then
            table.insert(currencies, currency)
        end
    end
    
    return currencies
end


local function StartPersistence()
    if PersistenceConnection then
        PersistenceConnection:Disconnect()
        PersistenceConnection = nil
    end
    

  for _, connection in pairs(CurrencyConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    CurrencyConnections = {}
    

  local currencies = FindCurrencyObjects()
    
    for _, currency in ipairs(currencies) do
        local connection = currency:GetPropertyChangedSignal("Value"):Connect(function()
            if MoneyEnabled and currency.Value ~= TargetAmount then
                wait(0.01) 
                pcall(function()
                    currency.Value = TargetAmount
                end)
            end
        end)
        table.insert(CurrencyConnections, connection)
    end
    

  PersistenceConnection = RunService.Heartbeat:Connect(function()
        if MoneyEnabled then
            pcall(function()
                local currencies = FindCurrencyObjects()
                for _, currency in ipairs(currencies) do
                    if currency.Value ~= TargetAmount then
                        currency.Value = TargetAmount
                    end
                end
            end)
        end
    end)
    
    print("[Money] Persistence enabled - money will be maintained at " .. TargetAmount)
end

local function GiveMoney()
    MoneyEnabled = true
    local success = SetMoney(TargetAmount)
    
    if success then
        print("[Money] Successfully set money to " .. TargetAmount)
        StartPersistence()
    else
        warn("[Money] Could not find money system. Trying alternative methods...")
        

    if not Player:FindFirstChild("leaderstats") then
            local leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"
            leaderstats.Parent = Player
            
            local coins = Instance.new("IntValue")
            coins.Name = "Coins"
            coins.Value = TargetAmount
            coins.Parent = leaderstats
            
            print("[Money] Created leaderstats with Coins = " .. TargetAmount)
            success = true
            StartPersistence()
        end
    end
    
    return success
end

local function StopPersistence()
    MoneyEnabled = false
    if PersistenceConnection then
        PersistenceConnection:Disconnect()
        PersistenceConnection = nil
    end
    for _, connection in pairs(CurrencyConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    CurrencyConnections = {}
    print("[Money] Persistence disabled")
end


Player.CharacterAdded:Connect(function()
    if MoneyEnabled then
        wait(2)
        StartPersistence()
    end
end)


spawn(function()
    while true do
        wait(1)
        if MoneyEnabled then

        local currencies = FindCurrencyObjects()
            if #currencies > #CurrencyConnections then
                StartPersistence()
            end
        end
    end
end)


return {
    Give = GiveMoney,
    SetAmount = function(amount)
        TargetAmount = amount
        if MoneyEnabled then
            SetMoney(amount)
            StartPersistence()
        end
        return SetMoney(amount)
    end,
    GetTargetAmount = function() return TargetAmount end,
    Stop = StopPersistence,
    IsEnabled = function() return MoneyEnabled end
}


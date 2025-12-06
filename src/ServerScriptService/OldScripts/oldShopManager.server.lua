ReplicatedStorage = game:GetService("ReplicatedStorage")
ServerStorage = game:GetService("ServerStorage")
ServerScriptService = game:GetService("ServerScriptService")

RerollEvent = ReplicatedStorage:WaitForChild("RerollEvent")
LootEvent = ReplicatedStorage:WaitForChild("LootEvent")
MoneyEvent = ReplicatedStorage:WaitForChild("MoneyEvent")
SelectionEvent = ReplicatedStorage:WaitForChild("SelectionEvent")

LootModule = require(ServerScriptService.LootModule)
PlayerDataModule = require(ServerScriptService.plrDataModule)
MoneyModule = require(ServerScriptService.MoneyModule)
WaveModule = require(ServerScriptService.WaveModule)
RerollModule = require(ServerScriptService.RerollModule)

local RerollCounts = {} -- Store reroll counts per player
local plrLootData = {} -- Store player data 
local CurrentWave = nil 

RerollEvent.OnServerEvent:Connect(function(Player)
    local UserId = Player.UserId
    if not RerollCounts[UserId]  then
        RerollCounts[UserId] = 0
    end
    -- Initialize count if player hasn't rerolled before
    if CurrentWave ~= WaveModule.Get() then
        for userId, _ in pairs(RerollCounts) do
            RerollCounts[userId] = 0
        end
        CurrentWave = WaveModule.Get()
    end
    
    -- Calculate the Reroll Price
    local Price = 3 * (WaveModule.Get() + RerollCounts[UserId])
    
    -- Check if player has enough money
    local PlayerStats = PlayerDataModule.fetchPlrStats(Player)
    if PlayerStats.Money.Value < Price then
        return
    end
    
    MoneyModule.Remove(Player, Price)
    -- Increment the reroll count
    RerollCounts[UserId] = RerollCounts[UserId] + 1
    local PlayerLoot = LootModule.GenerateReward(Player, 3)
    LootEvent:FireClient(Player, PlayerLoot)
    RerollEvent:FireClient(Player, Price + 3)
    -- Optional: Print or use the count
    --print(Player.Name .. " has rerolled " .. RerollCounts[UserId] .. " times")
end)
MoneyEvent.OnServerEvent:Connect(function(Player, Action)
    
    if Action == "get" then
        MoneyModule.Get(Player)
        --local PlayerStats = PlayerDataModule.fetchPlrStats(Player)
        --MoneyEvent:FireClient(Player, PlayerStats.Money, "get")   
    end
    
end)
SelectionEvent.OnServerEvent:Connect(function(Player, Selection)
    print("Recived Selection")
    plrLootData = LootModule.GetPlayerLoot(Player) 
    
    print(plrLootData)
    
    if plrLootData then 
        local plrFolder = ServerStorage.PlayerData:FindFirstChild(Player.Name .. " - " .. Player.UserId)
        local PlayerStats = plrFolder.Stats
        local PlayerAbilities = plrFolder.Abilities
        local plrLootList = plrLootData     
        local plrSelection = plrLootList[Selection]
        --if not plrFolder:FindFirstChild(plrSelection.id) then 
        --  local obj = Instance.new("IntValue")
        --  obj.Name = plrSelection.id
        --  obj.Value = 0
        --  obj.Parent = plrFolder
        --end
        if plrSelection.type == "stat" then
            PlayerStats[plrSelection.id].Value = plrSelection.amount + PlayerStats[plrSelection.id].Value
        elseif plrSelection.type == "spell" then
            if not PlayerAbilities:FindFirstChild(plrSelection.id) then 
                local obj = Instance.new("IntValue")
                obj.Name = plrSelection.id
                obj.Value = 0
                obj.Parent = PlayerAbilities   
            end
            PlayerAbilities[plrSelection.id].Value = plrSelection.amount + PlayerAbilities[plrSelection.id].Value
        end
        Player.Character.Humanoid.MaxHealth = PlayerStats.health.Value
        Player.Character.Humanoid.WalkSpeed = PlayerStats.speed.Value
        -- Heals player
        Player.Character.Humanoid.Health = PlayerStats.health.Value
        LootModule.RemovePlayerLoot(Player)
    end
end)
-- Clean up when player leaves to prevent memory leaks
game.Players.PlayerRemoving:Connect(function(Player)
    RerollCounts[Player.UserId] = nil
end)
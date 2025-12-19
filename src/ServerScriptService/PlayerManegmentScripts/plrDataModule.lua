--[[
    Player Data Module

    Purpose:
        Manages player statistics and data stored in ServerStorage.
        Provides utilities for fetching and organizing player stats.

    Structure:
        PlayerData is stored in ServerStorage under the format:
        ServerStorage.PlayerData["PlayerName - UserID"].Stats

    Usage:
        local plrData = require(path.to.plrDataModule)
        local stats = plrData.fetchPlrStatsTable(player)
        print(stats.health, stats.strength)

    Author: [Your Name]
    Last Updated: [Date]
--]]

local plrDataModule = {}

-- Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Type Definitions
export type PlayerStats = {
    health: number,
    speed: number,
    strength: number,
    armor: number,
    critRate: number,        -- Percentage (0-100)
    critDamage: number,      -- Percentage multiplier (e.g., 125 = 1.25x damage)
    healthRegen: number,     -- Health regenerated per tick/second
    cooldownReduction: number, -- Percentage (0-100)
    Income: number,          -- Income per interval
    Money: number,           -- Current money
}

-- Default player statistics (used when creating new player data)
plrDataModule.DefaultStats = {
    health = 100,
    speed = 16,
    strength = 0,
    armor = 0,
    critRate = 0,
    critDamage = 125,
    healthRegen = 0,
    cooldownReduction = 0,
    Income = 20,
    Money = 999999
}

-- EVENTS
local playerDataEvent = ReplicatedStorage:FindFirstChild("PlayerDataEvent") or Instance.new("RemoteEvent")
playerDataEvent.Name = "PlayerDataEvent"
playerDataEvent.Parent = ReplicatedStorage


--[[
    Retrieves a player's data folder from ServerStorage
    @param player Player - The player instance
    @return Folder | nil - The player's data folder, or nil if not found
]]
function plrDataModule.getPlayerFolder(player: Player): Folder?
    if not player then
        warn("getPlayerFolder: Invalid player provided")
        return nil
    end

    local folderName = player.Name .. " - " .. player.UserId
    local playerFolder = ServerStorage.PlayerData:FindFirstChild(folderName)

    if not playerFolder then
        warn("getPlayerFolder: Folder not found for", player.Name)
    end

    return playerFolder
end

--[[
    Fetches all children from a player's data folder
    @param player Player - The player instance
    @return {Instance} - Array of all instances in the player's folder
]]
function plrDataModule.fetchPlrData(player: Player): {Instance}
    local playerFolder = plrDataModule.getPlayerFolder(player)

    if not playerFolder then
        return {}
    end

    return playerFolder:GetChildren()
end

--[[
    Retrieves the Stats folder from a player's data
    @param player Player - The player instance
    @return Folder | nil - The player's Stats folder
]]
function plrDataModule.fetchPlrStats(player: Player): Folder?
    local playerFolder = plrDataModule.getPlayerFolder(player)

    if not playerFolder then
        return nil
    end

    local statsFolder = playerFolder:FindFirstChild("Stats")

    if not statsFolder then
        warn("fetchPlrStats: Stats folder not found for", player.Name)
    end

    return statsFolder
end

--[[
    Converts player stats from Instance format to a dictionary table
    @param player Player - The player instance
    @return PlayerStats - Dictionary table with stat names as keys and values
]]
function plrDataModule.fetchPlrStatsTable(player: Player): PlayerStats
    local playerStats = plrDataModule.fetchPlrStats(player)

    -- Return empty/default table if stats not found
    if not playerStats then
        warn("fetchPlrStatsTable: Could not fetch stats for", player.Name)
        return table.clone(plrDataModule.DefaultStats)
    end

    -- Build stats dictionary from IntValue children
    local statsTable = {}

    for _, stat in playerStats:GetChildren() do
        if stat:IsA("IntValue") or stat:IsA("NumberValue") then
            statsTable[stat.Name] = stat.Value
        end
    end

    return statsTable
end

function plrDataModule.StatReset(player: Player)
    local statsFolder = plrDataModule.fetchPlrStats(player)

    if not statsFolder then
        warn("StatReset: Stats folder not found for", player and player.Name)
        return
    end

    -- Reset each stat in the Stats folder back to its default value (if defined)
    for statName, defaultValue in pairs(plrDataModule.DefaultStats) do
        local statObject = statsFolder:FindFirstChild(statName)

        if statObject and (statObject:IsA("IntValue") or statObject:IsA("NumberValue")) then
            statObject.Value = defaultValue
        else
            -- Optional: warn if a default stat is missing in the folder
            if not statObject then
                warn("StatReset: Missing stat '" .. statName .. "' in Stats folder for", player.Name)
            end
        end
    end

    local plrStats = plrDataModule.fetchPlrStatsTable(player)
	print("Reset " .. player.Name .. " Stats")
	playerDataEvent:FireClient(player, plrStats)	

end

-- Player Items Manager

function plrDataModule.GetItemList(Player: Player): table
    local ItemTable = {}
    local PlayerFolder = plrDataModule.getPlayerFolder(Player)
    local ItemFolder = PlayerFolder:FindFirstChild("Items")

    for _, item in pairs(ItemFolder:GetChildren()) do 
        local itemName = item.Name
        local itemAmount = item.Value
        local Description = item.Description.Value
        
        ItemTable[itemName] = {itemAmount, Description}
        
    end
    
    return ItemTable
end

function plrDataModule.GetItem(Player: Player, TargetItem)
    local ItemList = plrDataModule.GetItemList(Player)

    if ItemList[TargetItem] == nil then
        ItemList[TargetItem] = {0, nil}
    end

    return ItemList[TargetItem]
end

function plrDataModule.ItemReset(Player: Player)
    local PlayerFolder = plrDataModule.getPlayerFolder(Player)
    local ItemFolder = PlayerFolder:FindFirstChild("Items")

    for _, Item in ipairs(ItemFolder:GetChildren()) do
        if Item.Name ~= "PrimaryAttack" then
            Item:Destroy()
        end
    end
end

-- Player Ability Manager 

function plrDataModule.GetAbilityList(Player: Player): table
    local ItemTable = {}
    local PlayerFolder = plrDataModule.getPlayerFolder(Player)
    local AbilityFolder = PlayerFolder:FindFirstChild("Abilities")

    for _, Ability in pairs(AbilityFolder:GetChildren()) do 
        local AbilityName = Ability.Name
        local AbilityAmount = Ability.Value
        
        ItemTable[AbilityName] = AbilityAmount
        
    end
    
    return ItemTable
end

function plrDataModule.GetAbility(Player: Player, TargetAbility)

    local AbilityList = plrDataModule.GetAbilityList(Player)

    if AbilityList[TargetAbility] then 
        return AbilityList[TargetAbility]
    end
end

function plrDataModule.AbilityReset(Player: Player)
    local PlayerFolder = plrDataModule.getPlayerFolder(Player)
    local AbilityFolder = PlayerFolder:FindFirstChild("Abilities")

    if not AbilityFolder then return end

    print(AbilityFolder:GetChildren())

    for _, Ability in ipairs(AbilityFolder:GetChildren()) do
        if Ability.Name ~= "PrimaryAttack" then
            Ability:Destroy()
        end
    end
end


return plrDataModule
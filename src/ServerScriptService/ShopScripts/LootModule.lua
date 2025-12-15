--[[
    Loot Generation Module
    
    This module handles random loot generation using a weighted probability system.
    
    Main Functions:
    - GenerateReward(player, rolls): Creates random loot drops based on weighted chances
    - GetPlayerLoot(player): Retrieves currently pending loot for a player
    - RemovePlayerLoot(player): Clears a player's pending loot data
    
    How It Works:
    1. Uses a weighted random system where each loot item has a weight value
    2. Higher weight = higher chance of being selected
    3. Generates specified number of rolls per reward generation
    4. Each roll produces an item with a random amount between min and max
    5. Sends loot data to client via LootEvent RemoteEvent
    
    Loot Types:
    - "stat": Player stat increases (health, speed, strength, armor, etc.)
    - "spell": Ability/spell unlocks (currently just Fireball)
    
    Loot Table Properties:
    - id: Name/identifier of the loot item
    - weight: Probability weight (higher = more common)
    - type: Category of loot ("stat" or "spell")
    - min/max: Range for random amount generation
    
    Usage Example:
    local loot = LootModule.GenerateReward(player, 3) -- Generate 3 random items
    
    Dependencies:
    - LootEvent: RemoteEvent in ReplicatedStorage for sending loot to clients
    
    Notes:
    - Uses os.clock() + player.UserId for seeding to reduce predictability
    - Stores pending loot in PlayerLootData table until claimed/removed
    - Automatically cleans up player loot data on disconnect
--]]

local LootModule = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Events
local LootEvent = ReplicatedStorage:WaitForChild("LootEvent")


-- Modules 
local Module = require(ServerScriptService:WaitForChild("ModuleLoader"))
local lootTable = Module.Get("LootTable")

-- Loot table configuration
-- Consider moving this to a ModuleScript if it gets large
local LOOT = lootTable.ALL_LOOT

-- Store pending loot for each player
-- Cleared when player leaves or loot is claimed
local PlayerLootData = {}

-- Pre-calculate total weight once (optimization)
local TOTAL_WEIGHT = 0
for _, item in ipairs(LOOT) do
    TOTAL_WEIGHT = TOTAL_WEIGHT + (item.weight or 0)
end

-- Calculate total weight of a loot table
local function totalWeight(lootTable)
    local sum = 0
    for _, v in ipairs(lootTable) do
        sum = sum + (v.weight or 0)
    end
    return sum
end

-- Pick a random item based on weighted probability
-- Uses the "roulette wheel" selection algorithm
local function pickWeighted(rand, lootTable)
    local total = totalWeight(lootTable)
    if total <= 0 then 
        warn("LootModule: Total weight is 0, cannot pick item")
        return nil 
    end
    
    local roll = rand:NextNumber() * total
    local accumulated = 0
    
    for index, item in ipairs(lootTable) do
        accumulated += item.weight
        if roll < accumulated then
            return item, index
        end
    end
    
    -- Fallback (floating point safety)
    return lootTable[#lootTable], #lootTable
end


-- Generates a reward for the player and returns the loot entry
-- Parameters:
--   player: The player receiving the loot
--   rolls: Number of items to generate (default 1)
-- Returns: Array of loot items or nil if generation fails
function LootModule.GenerateReward(player, rolls)
    if not player or not player:IsA("Player") then
        warn("LootModule.GenerateReward: Invalid player provided")
        return nil
    end
    
    rolls = rolls or 1
    if rolls <= 0 then
        warn("LootModule.GenerateReward: Rolls must be greater than 0")
        return nil
    end
    
    local lootTable = {}
    
    -- Create seed using high-precision clock and player ID
    local seed = math.floor(os.clock() * 1000) + player.UserId
    local rand = Random.new(seed)
    
    -- Generate each roll
    -- Create a temporary copy of the loot pool
    local availableLoot = table.clone(LOOT)

    for i = 1, rolls do
        if #availableLoot == 0 then
            warn("LootModule: No more unique loot to roll")
            break
        end

        local picked, pickedIndex = pickWeighted(rand, availableLoot)

        if not picked then
            warn(`LootModule: Failed to pick item for roll {i}`)
            continue
        end

        local result = {
            id = picked.id,
            type = picked.type,
            amount = rand:NextInteger(picked.min, picked.max),
            weight = picked.weight,
            description = picked.description,
            rollNumber = i
        }

        table.insert(lootTable, result)

        -- ❌ Remove the picked item so it can't be rolled again
        table.remove(availableLoot, pickedIndex)
    end

    
    -- Store pending loot for this player
    PlayerLootData[player] = lootTable
    
    -- Notify client about new loot
    local success, err = pcall(function()
        LootEvent:FireClient(player, lootTable)
    end)
    
    if not success then
        warn(`LootModule: Failed to fire loot event to client: {err}`)
    end
    
    return lootTable
end

-- Retrieve pending loot for a player
-- Returns: Loot table or nil if no pending loot
function LootModule.GetPlayerLoot(player)
    if not player or not player:IsA("Player") then
        warn("LootModule.GetPlayerLoot: Invalid player provided")
        return nil
    end
    
    return PlayerLootData[player]
end

-- Remove/clear pending loot for a player
function LootModule.RemovePlayerLoot(player)
    if not player then
        warn("LootModule.RemovePlayerLoot: Invalid player provided")
        return
    end
    
    PlayerLootData[player] = nil
end

-- Check if player has pending loot
function LootModule.HasPendingLoot(player)
    return PlayerLootData[player] ~= nil and #PlayerLootData[player] > 0
end

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
    LootModule.RemovePlayerLoot(player)
end)

return LootModule
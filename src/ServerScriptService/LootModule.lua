local LootModule = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Events

local LootEvent = ReplicatedStorage:FindFirstChild("LootEvent")

local LOOT = {
	{ id = "health",   weight = 100, type = "stat", min = 5, max = 10 },
	{ id = "speed",    weight = 100, type = "stat", min = 1, max = 3 },
	{ id = "strength", weight = 100, type = "stat", min = 3, max = 5 },
	{ id = "armor",    weight = 100, type = "stat", min = 1, max = 5 },
	{ id = "critRate", weight = 100, type = "stat", min = 5, max = 15 },
	{ id = "critDamage", weight = 100, type = "stat", min = 5, max = 15 },
	{ id = "healthRegen", weight = 100, type = "stat", min = 1, max = 2 },
	{ id = "cooldownReduction", weight = 100, type = "stat", min = 10, max = 25 },
	{ id = "Income", weight = 100, type = "stat", min = 10, max = 20 },
	{ id = "Fireball", weight = 100, type = "spell", min = 1, max = 1 },


}

local PlayerLootData = {} 


local function randRange()
	local seed = tick()
	local rand = Random.new(seed)
	
	
end 

local function totalWeight(table)
	local s = 0
	for _, v in ipairs(table) do s = s + (v.weight or 0) end
	return s
end

local function pickWeighted(rand, table)
	local t = totalWeight(table)
	if t <= 0 then return nil end
	local r = rand:NextNumber() * t  -- NextNumber returns [0,1)
	local acc = 0
	for _, v in ipairs(table) do
		acc = acc + v.weight
		if r < acc then
			return v
		end
	end
	-- fallback
	return table[#table]
end

-- Generates a reward for the player and returns the loot entry (doesn't actually apply it)
function LootModule.GenerateReward(player, rolls)
	local lootTable = {}
	
	local seed = tick() + (player and player.UserId or 0)
	local rand = Random.new(seed)
	
	for i = 1, rolls do
		-- Use a per-call Random seeded with tick() and the player's UserId to reduce predictability

		--print(seed)
		--print(rand)
		
		local picked = pickWeighted(rand, LOOT)
		if not picked then return nil end

		-- Build a simple result table to return to caller
		local result = {
			id = picked.id,
			type = picked.type,
			amount = rand:NextInteger(picked.min, picked.max),
			weight = picked.weight
		}
		
		table.insert(lootTable, result)
	end
	
	PlayerLootData[player] = lootTable
	--print(PlayerLootData[player])

	LootEvent:FireClient(player, lootTable)

	return lootTable
end

function LootModule.GetPlayerLoot(Player)
	
	return PlayerLootData[Player]
	
end

function LootModule.RemovePlayerLoot(Player)
	
	PlayerLootData[Player] = nil
	
end


return LootModule

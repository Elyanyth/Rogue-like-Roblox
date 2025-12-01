local plrStatModule = {}

local serverStorage = game:GetService("ServerStorage")

export type PlayerStats = {
	health: number,
	speed: number,
	strength: number,
	armor: number,
	critRate: number,
	critDamage: number,
	healthRegen: number,
	cooldownReduction: number,
}

-- Default stats table in correct Lua format
plrStatModule.DefaultStats = {
	health = 100,
	speed = 20,
	strength = 0,
	armor = 0,
	critRate = 0, -- percentage (0-100)
	critDamage = 125,
	healthRegen = 0,
	cooldownReduction = 0,
	Income = 20, 
	Money = 20
}


function plrStatModule.fetchPlrData(player)
	local plrData = serverStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
	return plrData:GetChildren()
end
	
function plrStatModule.fetchPlrStats(player)
	local plrData = serverStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
	local PlayerStats = plrData.Stats
	return PlayerStats
end

function plrStatModule.fetchPlrStatsTable(player)
	
	local plrData = serverStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
	local PlayerStats = plrData.Stats

	-- Create a table with Name = Value for each IntValue
	local StatsTable = {}
	for _, stat in ipairs(PlayerStats:GetChildren()) do
		if stat:IsA("IntValue") then
			StatsTable[stat.Name] = stat.Value
		end
	end

	return StatsTable
end

return plrStatModule

